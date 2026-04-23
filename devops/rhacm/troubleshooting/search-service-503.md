---
review:
  status: unreviewed
  notes: "Updated 2026-04-23 against ACM 2.16 docs (https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/search/acm-search). emptyDir default, PVC config YAML, SearchPVCNotPresent alert description, Search CR field names (database/queryapi/collector/indexer), and postgres envVar names all verified against source. PVC-resolves-OOMKill chain confirmed in production session 2026-04-23 — configuring dbStorage was sufficient to stop the crash loop without additional memory tuning. Memory envVar tuning is doc-aligned but not exercised in this session."
---

# Troubleshooting: Search Service 503 / SearchPVCNotPresent

Covers two related alerts that often appear together on a fresh RHACM install:

- **503 from Search UI:** "Unexpected error — Error occurred while contacting the search service. Response not successful: Received status code 503"
- **`SearchPVCNotPresent`:** Fires because the default postgres storage is `emptyDir` — no PVC is configured. This is expected on a new install and is resolved by configuring persistent storage.
- **`SearchPVCNotPresentCritical`:** Same root cause, elevated severity when critical conditions accompany the missing PVC.

The two problems interact: with `emptyDir` (the default), postgres has no persistent disk to spill data to and compensates by holding more in memory. This drives OOMKill under normal load. **Configuring the PVC alone is typically sufficient to stop the crash loop** — the memory tuning in Scenario B is for environments that still see pressure after persistent storage is in place.

---

## Step 1 — Identify the Failing Component

```bash
oc get pods -n open-cluster-management | grep search
```

| Pod prefix | Deployment key in CR | Role |
|---|---|---|
| `search-postgres` | `database` | PostgreSQL store — 503 if this is down |
| `search-api` | `queryapi` | GraphQL API — 503 if this is down |
| `search-indexer` | `indexer` | Index writer |
| `search-collector` | `collector` | Hub cluster collector |

```bash
# Recent events for search and storage
oc get events -n open-cluster-management \
  --sort-by=.lastTimestamp \
  | grep -i "search\|oom\|kill\|memory\|pvc"
```

---

## Scenario A — SearchPVCNotPresent (configure persistent storage)

Per ACM 2.16 docs: the default configuration uses an `emptyDir` volume for postgres data. The `SearchPVCNotPresent` alert is expected until you explicitly configure a PVC. On every pod restart the index is lost and must rebuild — this also increases memory pressure.

Configure persistent storage via the `Search` CR (the operator watches this and reconciles — direct deployment patches will be reverted):

```bash
oc edit search search-v2-operator -n open-cluster-management
```

Add `spec.dbStorage`:

```yaml
apiVersion: search.open-cluster-management.io/v1alpha1
kind: Search
metadata:
  name: search-v2-operator
  namespace: open-cluster-management
  labels:
    cluster.open-cluster-management.io/backup: ""
spec:
  dbStorage:
    size: 10Gi
    storageClassName: <your-storage-class>
```

The operator creates a PVC named `<storageClassName>-search-postgres-0` and mounts it to the postgres pod.

**Verify the PVC is created and bound:**

```bash
watch -n 5 'oc get pvc -n open-cluster-management | grep search'
# Pending → Bound
```

If the PVC stays `Pending`, check that the StorageClass can provision:

```bash
# Is there a default StorageClass?
oc get storageclass | grep -E "default|\(default\)"

# Does the StorageClass provisioner have healthy pods?
oc get pods -A | grep <provisioner-name>
```

**Storage sizing (from ACM docs):** Default is `10Gi`. `20Gi` is sufficient for approximately 200 managed clusters.

**Resizing an existing PVC:** The operator does not automatically resize a PVC after creation. Edit it directly:

```bash
oc edit pvc <storageClassName>-search-postgres-0 -n open-cluster-management
```

---

## Scenario B — search-postgres OOMKilled

With `emptyDir` (the default), postgres has no persistent disk to spill to and uses more memory. The combination of many clusters and emptyDir storage is the most common cause of OOMKill.

**Confirm the OOMKill:**

```bash
oc describe pod -n open-cluster-management \
  -l app=search-postgres \
  | grep -A 5 "Last State\|OOMKilled\|Exit Code"

oc top pod -n open-cluster-management | grep search-postgres
```

**Fix: tune postgres via the `Search` CR**

The correct way to tune postgres memory is a combination of:
1. `envVar` — postgres internal parameters (how much memory postgres allocates to itself)
2. `resources.limits.memory` — the container kill threshold

Both go under `spec.deployments.database`. Direct deployment patches are reverted by the operator.

```yaml
apiVersion: search.open-cluster-management.io/v1alpha1
kind: Search
metadata:
  name: search-v2-operator
  namespace: open-cluster-management
spec:
  deployments:
    database:
      envVar:
        - name: POSTGRESQL_EFFECTIVE_CACHE_SIZE
          value: 512MB
        - name: POSTGRESQL_SHARED_BUFFERS
          value: 256MB
        - name: WORK_MEM
          value: 64MB
      resources:
        limits:
          memory: 2Gi
        requests:
          memory: 512Mi
```

Apply with:

```bash
oc patch search search-v2-operator -n open-cluster-management \
  --type merge -p "$(cat <<'EOF'
spec:
  deployments:
    database:
      envVar:
        - name: POSTGRESQL_EFFECTIVE_CACHE_SIZE
          value: 512MB
        - name: POSTGRESQL_SHARED_BUFFERS
          value: 256MB
        - name: WORK_MEM
          value: 64MB
      resources:
        limits:
          memory: 2Gi
        requests:
          memory: 512Mi
EOF
)"
```

**Fix the PVC first (Scenario A).** In practice, configuring persistent storage is sufficient to stop the OOMKill loop on its own — postgres with `emptyDir` has nowhere to spill data except RAM, which is what drives the crash. The memory tuning below is for environments that still see pressure after the PVC is in place.

**Starting-point estimates** (actual usage depends on resource count and query patterns):

| Environment | Clusters | Suggested `limits.memory` |
|---|---|---|
| Small | < 10 | 512Mi–1Gi |
| Medium | 10–50 | 1Gi–2Gi |
| Large | 50–100 | 2Gi–4Gi |
| Very large | 100+ | 4Gi+ |

Watch after applying:

```bash
watch -n 30 'oc get pods -n open-cluster-management | grep search-postgres'
# RESTARTS column should stabilize
```

---

## Scenario C — search-api (queryapi) Not Running

The `search-api` pod (`queryapi` in the CR) is what the UI calls directly. If it's down, the UI returns 503 even if postgres is healthy.

```bash
oc logs -n open-cluster-management \
  -l app=search-api \
  --tail=100

oc describe pod -n open-cluster-management \
  -l app=search-api \
  | tail -30
```

Common causes:
- Postgres is not ready — `search-api` cannot connect; fix Scenario A/B first
- Resource pressure — check `oc describe node` for the node hosting the pod
- Image pull failure in disconnected environments

---

## Scenario D — Hub-Level MCH Degraded

If multiple search components are failing together, the issue may be at the hub level:

```bash
oc get multiclusterhub -n open-cluster-management

oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{range .status.components[*]}{.name}: {.status} — {.reason}{"\n"}{end}' \
  | grep -v ": Available"
```

If MCH shows `Degraded` or `Progressing`, see [mch-stuck-pending-upgrade.md](./mch-stuck-pending-upgrade.md).

---

## After Fixing — Validate

```bash
# All search pods running and RESTARTS stable
oc get pods -n open-cluster-management | grep search

# PVC is bound
oc get pvc -n open-cluster-management | grep search

# SearchPVCNotPresent alert should clear once PVC is bound
# (may take a few minutes for Prometheus to resample)
```

Test the UI: navigate to Search in the RHACM console and run `kind:StorageClass`. Results from multiple clusters confirm search is operational.

---

## First-Time Setup

If this is a new RHACM install, see [search-setup.md](../notes/search-setup.md) for the full first-time checklist including PVC configuration, addon status verification, and tuning reference.

---

## Reference

- [ACM 2.16 — Customizing the search service](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/search/acm-search#customizing-the-search-service)
- [ACM 2.16 — Updating klusterlet-addon-search deployments](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/search/acm-search#updating-klusterlet-addon-search-deployments)

---

*This content was created with AI assistance and updated against ACM 2.16 documentation. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

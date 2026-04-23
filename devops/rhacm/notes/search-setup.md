---
review:
  status: unreviewed
  notes: "Updated 2026-04-23 against ACM 2.16 docs (https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/search/acm-search). Default emptyDir behavior, addon auto-enablement, and Search CR field names verified against source. PVC config YAML taken directly from docs. Memory envVar names verified. Sizing numbers (20Gi/200 clusters) from docs."
---

# RHACM Search — Initial Setup

**Symptom on first use:** Search UI returns a 503 or "Error occurred while contacting the search service."

Per [ACM 2.16 docs](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/search/acm-search): search is configured by default on the hub cluster, and the `klusterlet-addon-search` addon is enabled automatically when you provision or manually import a managed cluster. A 503 on first use is usually a hub-side component problem or a missing PVC configuration, not a missing addon.

---

## Step 1 — Verify Hub-Side Search Pods

```bash
oc get pods -n open-cluster-management | grep search
```

All four should be `Running`:

| Pod prefix | Role |
|---|---|
| `search-api` | GraphQL API — what the UI calls (`search_api` in the CR) |
| `search-collector` | Indexes the hub cluster itself |
| `search-indexer` | Receives data from managed cluster collectors, writes to postgres |
| `search-postgres` | PostgreSQL backing store (`database` in the CR) |

If any are missing or crashlooping, check events:

```bash
oc get events -n open-cluster-management \
  --sort-by=.lastTimestamp | grep -i "search\|oom\|kill\|memory\|pvc"
```

See [search-service-503.md](../troubleshooting/search-service-503.md) for component-specific fixes.

---

## Step 2 — Configure Persistent Storage (Required for Production)

By default, search-postgres uses an **`emptyDir` volume** — data is lost on every pod restart and the index rebuilds from scratch. The `SearchPVCNotPresent` alert fires to flag this. For production, configure a PVC by adding `spec.dbStorage` to the `Search` CR:

```bash
oc edit search search-v2-operator -n open-cluster-management
```

Add the `dbStorage` section:

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

**Storage sizing (from docs):** Default is `10Gi`. `20Gi` is sufficient for approximately 200 managed clusters.

Once the PVC is bound, the `SearchPVCNotPresent` alert clears.

---

## Step 3 — Check the Per-Cluster Addon Status

The addon (`klusterlet-addon-search`) is enabled automatically on import/provision per ACM 2.16 docs. If some clusters are not being indexed, verify addon health:

```bash
# Check addon status across all clusters
oc get managedclusteraddon search-collector --all-namespaces
```

Clusters should show `AVAILABLE: True`. If a cluster shows `False` or is missing, check the klusterlet on that cluster:

```bash
# Describe the addon for a specific cluster
oc describe managedclusteraddon search-collector -n <cluster-name>
```

If the addon is genuinely missing (not just degraded), create it:

```bash
cat <<EOF | oc apply -f -
apiVersion: addon.open-cluster-management.io/v1alpha1
kind: ManagedClusterAddOn
metadata:
  name: search-collector
  namespace: <cluster-name>
spec:
  installNamespace: open-cluster-management-agent-addon
EOF
```

The pod on the managed cluster runs as `klusterlet-addon-search` in the `open-cluster-management-agent-addon` namespace.

---

## Step 4 — Verify Search Works

In the RHACM UI, go to **Search** and run:

```
kind:StorageClass
```

If results appear from multiple clusters, search is working. To find a specific storage class across all clusters:

```
kind:StorageClass name:px-rwx-block-vm
```

The `cluster` column shows which managed clusters have that resource.

---

## Tuning the Search Service

All tuning goes through the `search-v2-operator` Search CR. The operator watches it, reconciles changes, and updates pods — direct deployment patches will be reverted.

```bash
oc get search search-v2-operator -n open-cluster-management -o yaml
```

Four deployments are configurable: `collector`, `indexer`, `database` (postgres), `queryapi` (search-api).

**Tune postgres memory** — set postgres parameters via `envVar` alongside resource limits:

```yaml
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

**Tune the indexer** (if it's slow or OOMing with many clusters):

```yaml
spec:
  deployments:
    indexer:
      replicaCount: 3
      resources:
        limits:
          memory: 5Gi
        requests:
          memory: 1Gi
```

**Tune the managed cluster collector** memory (for resource-heavy clusters):

```bash
oc edit managedclusteraddon search-collector -n <cluster-name>
```

Add annotations:
```yaml
metadata:
  annotations:
    addon.open-cluster-management.io/search_memory_limit: 2048Mi
    addon.open-cluster-management.io/search_memory_request: 512Mi
```

---

## Reference

- [ACM 2.16 — Search](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/search/acm-search)
- [search-service-503.md](../troubleshooting/search-service-503.md) — search service down / postgres OOMKill / SearchPVCNotPresent

---

*This content was created with AI assistance and updated against ACM 2.16 documentation. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

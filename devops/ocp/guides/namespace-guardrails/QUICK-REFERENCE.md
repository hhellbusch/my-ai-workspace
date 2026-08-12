---
review:
  status: unreviewed
  notes: "AI-assisted quick reference companion to namespace-guardrails README. 2026-08-06."
---

# Namespace guardrails — quick reference

Companion to [README.md](README.md).

**Audience:** Platform operators applying or auditing namespace quotas on OpenShift.

**Purpose:** Fast lookup for quota keys, tier files, audit commands, and failure messages.

---

## Quota key cheat sheet

### Compute and storage

| Key | Limits |
|-----|--------|
| `requests.cpu` | Sum of CPU requests (non-terminal pods) |
| `limits.cpu` | Sum of CPU limits |
| `requests.memory` | Sum of memory requests |
| `limits.memory` | Sum of memory limits |
| `requests.storage` | Sum of PVC storage requests |
| `persistentvolumeclaims` | PVC count |

### Core object counts

| Key | Limits |
|-----|--------|
| `pods` | Non-terminal pods |
| `services` | Services |
| `services.nodeports` | NodePort allocations |
| `services.loadbalancers` | LoadBalancer services |
| `secrets` | Secrets |
| `configmaps` | ConfigMaps |

### Generic count syntax

```text
count/<resource>.<group>
```

Examples: `count/deployments.apps`, `count/cronjobs.batch`, `count/networkpolicies.networking.k8s.io`

### OpenShift

| Key | Limits |
|-----|--------|
| `openshift.io/imagestreams` | ImageStreams |
| `count/routes.route.openshift.io` | Routes |
| `count/buildconfigs.build.openshift.io` | BuildConfigs |

---

## Tier files

| Tier | File | Pods | ConfigMaps | Secrets |
|------|------|------|------------|---------|
| Small | [resourcequota-small.yaml](examples/resourcequota-small.yaml) | 20 | 25 | 25 |
| Medium | [resourcequota-medium.yaml](examples/resourcequota-medium.yaml) | 100 | 50 | 50 |
| Large | [resourcequota-large.yaml](examples/resourcequota-large.yaml) | 500 | 200 | 200 |

LimitRange defaults: [limitrange-defaults.yaml](examples/limitrange-defaults.yaml)

---

## Apply and inspect

```bash
# Apply tier to namespace
oc apply -f examples/limitrange-defaults.yaml -n <ns>
oc apply -f examples/resourcequota-medium.yaml -n <ns>

# Usage vs hard limits
oc describe quota -n <ns>
oc describe limitrange -n <ns>

# All quotas in cluster
oc get quota -A
oc describe quota -A
```

---

## ClusterResourceQuota

```bash
# Create aggregate cap for a user
oc create clusterresourcequota for-user \
  --project-annotation-selector openshift.io/requester=<email> \
  --hard pods=200,secrets=150,configmaps=150

# Project admin view
oc get appliedclusterresourcequota -n <ns>
```

Example YAML: [clusterresourcequota-user.yaml](examples/clusterresourcequota-user.yaml)

---

## Audit commands

```bash
# etcd health
oc get co etcd
oc get pods -n openshift-etcd

# API latency smoke test
time oc get nodes
time oc get pods -A --limit=50

# Per-namespace object snapshot
for ns in $(oc get ns -o jsonpath='{.items[*].metadata.name}'); do
  echo "$ns: pods=$(oc get pods -n $ns --no-headers 2>/dev/null | wc -l) \
cm=$(oc get cm -n $ns --no-headers 2>/dev/null | wc -l) \
secrets=$(oc get secrets -n $ns --no-headers 2>/dev/null | wc -l)"
done

# Event accumulation
oc get events -A --no-headers | wc -l
```

---

## etcd metrics (Prometheus)

| Metric | Use |
|--------|-----|
| `etcd_server_quota_backend_bytes` | Quota limit |
| `etcd_mvcc_db_total_size_in_use_in_bytes` | Actual usage |
| `etcd_mvcc_db_total_size_in_bytes` | Size including defrag-pending space |

Alerts: `low space`, `excessive database growth`

Default disk quota: 8 GiB per member (configurable 8–32 GiB via `Etcd` CR `spec.backendQuotaGiB`).

---

## Common errors

| Message | Likely cause | First step |
|---------|--------------|------------|
| `exceeded quota: <name>, requested: pods` | Pod count limit | `oc describe quota`; delete RS/Job debris |
| `exceeded quota: <name>, requested: configmaps` | CM limit | Audit Helm/operator ConfigMaps |
| `must specify requests.cpu` | Quota active, pod has no requests | Add LimitRange defaults |
| `etcdserver: request is too large` | Object > ~1.5 MB | Split Secret/CM; check Endpoints size |
| `Request entity too large` | API server request limit | Same as above |

---

## Red Hat tested per-namespace (500-node scenario)

Reference only — not tenant defaults:

| Object | Tested / ns |
|--------|-------------|
| Secrets | 20 |
| ConfigMaps | 10 |
| Services | 15 |
| NetworkPolicies | 6 |

Full table: [object maximums doc](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/scalability_and_performance/planning-your-environment-according-to-object-maximums) — OCP 4.19.

---

## Related

- [Full guide](README.md)
- [API slowness troubleshooting](../../troubleshooting/api-slowness-web-console/README.md)
- [Container density note](../../notes/container-density-overcommit.md)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

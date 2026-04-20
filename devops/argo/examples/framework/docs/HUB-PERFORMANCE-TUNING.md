# Hub Performance Tuning Guide

Scaling ArgoCD on a RHACM hub that manages hundreds of spoke clusters via
ApplicationSets. This guide covers the specific bottlenecks of the fleet
management framework and how to address them.

> **AI Disclosure:** This document was created with AI assistance.

---

## Table of Contents

1. [Understanding the Load Profile](#1-understanding-the-load-profile)
2. [Application Controller Sharding](#2-application-controller-sharding)
3. [Repo Server Scaling](#3-repo-server-scaling)
4. [Redis Cache Tuning](#4-redis-cache-tuning)
5. [ApplicationSet Controller](#5-applicationset-controller)
6. [RHACM-Specific Considerations](#6-rhacm-specific-considerations)
7. [Resource Limits and Requests](#7-resource-limits-and-requests)
8. [Monitoring and Alerts](#8-monitoring-and-alerts)
9. [Sizing Reference Table](#9-sizing-reference-table)
10. [Troubleshooting Performance Issues](#10-troubleshooting-performance-issues)

---

## 1. Understanding the Load Profile

### What Makes Fleet Management Expensive

This framework creates **N apps × M clusters** ArgoCD Applications. Each
Application requires:

- **Periodic manifest generation:** Helm template rendering with 6+ value
  files from the cascade
- **Periodic sync/diff:** Comparing rendered manifests against live cluster
  state via the Kubernetes API of each spoke
- **Git polling:** Checking the repo for changes (shared across apps pointing
  to the same repo + revision)

| Fleet Size | Apps | Clusters | Applications | Notes |
|------------|------|----------|--------------|-------|
| Small | 6 | 10 | 60 | Default ArgoCD config is fine |
| Medium | 10 | 50 | 500 | Start tuning repo-server and controller |
| Large | 15 | 100 | 1,500 | Sharding required |
| Very Large | 20 | 300 | 6,000 | Full tuning across all components |

### The Three Bottlenecks

```
┌─────────────────────────────────────────────────────────────┐
│                     ArgoCD Hub                              │
│                                                             │
│  ┌──────────────────┐  ┌───────────┐  ┌──────────────────┐ │
│  │  Application      │  │  Repo     │  │  Redis           │ │
│  │  Controller       │──│  Server   │──│  Cache            │ │
│  │                   │  │           │  │                  │ │
│  │  Bottleneck #1:   │  │  #2:      │  │  #3:             │ │
│  │  Reconciliation   │  │  Helm     │  │  Manifest        │ │
│  │  loop throughput  │  │  template │  │  cache hits      │ │
│  └──────────────────┘  └───────────┘  └──────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

1. **Application Controller** — Reconciles Applications one-by-one within
   each shard. More clusters = more sync cycles to complete.
2. **Repo Server** — Runs `helm template` for every Application on every
   reconciliation. The cascade (6+ value files) makes each render heavier
   than a typical single-values-file app.
3. **Redis** — Caches rendered manifests. Cache misses force re-rendering
   via the repo server. Under-sized cache = constant re-rendering.

---

## 2. Application Controller Sharding

The application controller processes Applications sequentially within a
shard. Sharding distributes Applications across multiple controller
replicas, each responsible for a subset.

### When to Shard

- Reconciliation queue depth consistently > 0 (visible in `argocd_app_reconcile` metrics)
- Applications show "Progressing" for extended periods
- Sync operations queue up and take minutes to start
- Cluster count exceeds ~50 with 10+ apps

### How to Shard (OpenShift GitOps Operator)

Edit the ArgoCD CR in `openshift-gitops`:

```yaml
apiVersion: argoproj.io/v1beta1
kind: ArgoCD
metadata:
  name: openshift-gitops
  namespace: openshift-gitops
spec:
  controller:
    sharding:
      enabled: true
      replicas: 3       # Start with 3, scale to cluster_count / 30-50
    resources:
      requests:
        cpu: "2"
        memory: "4Gi"
      limits:
        cpu: "4"
        memory: "8Gi"
    env:
      # Number of concurrent sync operations per shard
      - name: ARGOCD_CONTROLLER_STATUS_PROCESSORS
        value: "50"
      - name: ARGOCD_CONTROLLER_OPERATION_PROCESSORS
        value: "25"
      # Reconciliation timeout per app (increase for large cascades)
      - name: ARGOCD_RECONCILIATION_TIMEOUT
        value: "300"
```

### Shard Distribution Strategy

By default, ArgoCD uses round-robin by cluster. Since our framework generates
many apps per cluster, this naturally distributes the load.

For uneven fleets (some clusters have 20 apps, others have 3), consider the
`legacy` shard algorithm which distributes by Application count:

```yaml
    env:
      - name: ARGOCD_CONTROLLER_SHARDING_ALGORITHM
        value: "round-robin"  # or "legacy" for app-count-based
```

### Shard Count Guidelines

| Clusters | Apps per Cluster | Total Apps | Recommended Shards |
|----------|-----------------|------------|-------------------|
| 10-50 | 5-10 | 50-500 | 1-2 |
| 50-100 | 10-15 | 500-1,500 | 3-4 |
| 100-200 | 10-20 | 1,000-4,000 | 4-6 |
| 200-500 | 10-20 | 2,000-10,000 | 6-10 |

---

## 3. Repo Server Scaling

The repo server runs `helm template` for every manifest generation request.
In this framework, each render loads 6+ value files from the cascade. This
is CPU and memory intensive.

### Scaling Replicas

```yaml
spec:
  repo:
    replicas: 3          # Minimum 2 for HA, scale to match controller shards
    resources:
      requests:
        cpu: "2"
        memory: "2Gi"
      limits:
        cpu: "4"
        memory: "4Gi"
    env:
      # Parallelism limit per repo-server pod
      - name: ARGOCD_EXEC_TIMEOUT
        value: "180"     # Seconds — increase if template renders time out
      # Max combined manifest size for generated manifests
      - name: ARGOCD_MAX_GRPC_MESSAGE_SIZE
        value: "104857600"   # 100MB — needed for large fleets
```

### Helm Rendering Optimization

The repo server clones the Git repo once and caches it. However, each
`helm template` invocation is a fresh process. Key optimizations:

1. **Keep value files small.** Move large data structures (e.g. bare metal
   host inventories) to cluster-specific values only — do not duplicate them
   in group files.

2. **Minimize template complexity.** Avoid deeply nested `range` loops over
   large lists in `_helpers.tpl`. Pre-compute values where possible.

3. **Use `ignoreMissingValueFiles: true`.** This is already required by the
   framework. Without it, missing group files cause template failures instead
   of being skipped, which increases error-driven retries.

### Repo Server Timeout Symptoms

If you see these in Application status:

```
rpc error: code = DeadlineExceeded
ComparisonError: failed to generate manifests
```

Increase `ARGOCD_EXEC_TIMEOUT` and ensure repo-server has sufficient CPU.

---

## 4. Redis Cache Tuning

ArgoCD uses Redis to cache rendered manifests. A cache hit avoids a full
`helm template` re-render. For a large fleet, the cache is critical.

### Memory Sizing

Each cached manifest set is roughly 50-200KB (depending on app complexity).
For 1,500 Applications:

```
1,500 apps × 150KB average = ~225MB of cache data
```

With Redis overhead and key metadata, allocate 2-3x:

```yaml
spec:
  redis:
    resources:
      requests:
        memory: "512Mi"
      limits:
        memory: "1Gi"
```

For very large fleets (5,000+ apps), consider 2-4Gi.

### Cache Hit Rate Monitoring

The `argocd_redis_request_total` metric (with `hit`/`miss` labels) reveals
cache effectiveness. Target **>90% hit rate**. If below 90%:

- Redis memory limit is too low (evictions)
- `ARGOCD_RECONCILIATION_JITTER` is too high (too many simultaneous
  cache-miss renders)
- Value files are changing too frequently (every commit invalidates cache)

### HA Redis

For production hubs managing 100+ clusters, deploy Redis in HA mode:

```yaml
spec:
  ha:
    enabled: true
    resources:
      requests:
        memory: "256Mi"
      limits:
        memory: "512Mi"
  redis:
    resources:
      requests:
        memory: "1Gi"
      limits:
        memory: "2Gi"
```

---

## 5. ApplicationSet Controller

The ApplicationSet controller generates/updates Application resources when
cluster secrets change (e.g. a new cluster is onboarded or labels change).
It is less of a bottleneck than the app controller but still needs tuning at
scale.

### Key Settings

```yaml
spec:
  applicationSet:
    resources:
      requests:
        cpu: "500m"
        memory: "512Mi"
      limits:
        cpu: "2"
        memory: "1Gi"
    env:
      # How often the controller re-evaluates generators
      - name: ARGOCD_APPLICATIONSET_CONTROLLER_REQUEUEAFTERSECONDS
        value: "300"   # Default 180. Increase to reduce churn on large fleets.
      # Max number of concurrent Application creates/updates
      - name: ARGOCD_APPLICATIONSET_CONTROLLER_MAX_CONCURRENT_RECONCILIATIONS
        value: "10"
```

### Generator Performance

The `clusters` generator used by this framework performs a `List` on ArgoCD
cluster secrets. At 300+ clusters this is a cheap operation, but the
subsequent Application creation/update can be expensive if many Applications
change simultaneously (e.g. fleet-wide value change).

**Mitigation:** Stagger fleet-wide changes by promoting to environments
sequentially (lab → dev → staging → production) rather than merging to all
branches simultaneously.

---

## 6. RHACM-Specific Considerations

### Policy Controller Load

The `cluster-label-sync` chart creates one RHACM Policy per cluster. Each
Policy contains the label enforcement spec. The RHACM Policy controller on
the hub evaluates all policies periodically.

For 300+ clusters:

- Set Policy evaluation interval to 30-60 seconds (not the default 10s)
- Monitor `policy_governance_compliance_api_duration_seconds`
- Consider grouping clusters into multiple `ManagedClusterSets` if Policy
  evaluation becomes a bottleneck

### GitOps Cluster Registration

The `GitOpsCluster` resource and `Placement` control which spoke clusters
are registered with the hub ArgoCD. At scale:

- Ensure Placement uses label selectors (not cluster names) to avoid
  updating the Placement resource on every cluster onboard
- The ManagedClusterSet binding is namespace-scoped — one binding per
  ArgoCD namespace is sufficient

### Spoke API Server Load

Each ArgoCD Application performs periodic health checks and drift detection
against the spoke's API server. With 15 apps per cluster, that is 15
concurrent watchers per spoke. This is generally fine for OpenShift API
servers, but monitor:

- `apiserver_request_total` on spokes
- `etcd_request_duration_seconds` on spokes
- If spokes show API throttling, increase the controller's
  `ARGOCD_K8S_CLIENT_QPS` and `ARGOCD_K8S_CLIENT_BURST`

---

## 7. Resource Limits and Requests

### Recommended Baseline (50 clusters, 10 apps = 500 Applications)

```yaml
spec:
  controller:
    resources:
      requests: { cpu: "2", memory: "4Gi" }
      limits:   { cpu: "4", memory: "8Gi" }
  repo:
    replicas: 2
    resources:
      requests: { cpu: "1", memory: "1Gi" }
      limits:   { cpu: "2", memory: "2Gi" }
  redis:
    resources:
      requests: { memory: "256Mi" }
      limits:   { memory: "512Mi" }
  server:
    resources:
      requests: { cpu: "250m", memory: "256Mi" }
      limits:   { cpu: "1", memory: "512Mi" }
  applicationSet:
    resources:
      requests: { cpu: "250m", memory: "256Mi" }
      limits:   { cpu: "1", memory: "512Mi" }
```

### Recommended for Scale (200 clusters, 15 apps = 3,000 Applications)

```yaml
spec:
  controller:
    sharding:
      enabled: true
      replicas: 5
    resources:
      requests: { cpu: "4", memory: "8Gi" }
      limits:   { cpu: "8", memory: "16Gi" }
  repo:
    replicas: 5
    resources:
      requests: { cpu: "2", memory: "2Gi" }
      limits:   { cpu: "4", memory: "4Gi" }
  redis:
    resources:
      requests: { memory: "1Gi" }
      limits:   { memory: "2Gi" }
  ha:
    enabled: true
  server:
    replicas: 2
    resources:
      requests: { cpu: "500m", memory: "512Mi" }
      limits:   { cpu: "2", memory: "1Gi" }
  applicationSet:
    resources:
      requests: { cpu: "500m", memory: "512Mi" }
      limits:   { cpu: "2", memory: "1Gi" }
```

---

## 8. Monitoring and Alerts

### Key Metrics to Watch

| Metric | What It Tells You | Alert Threshold |
|--------|-------------------|-----------------|
| `argocd_app_reconcile_count` | Reconciliation throughput | Dropping trend |
| `argocd_app_reconcile_bucket` | Time per reconciliation | p99 > 60s |
| `argocd_app_sync_total` | Sync operations completed | N/A (informational) |
| `argocd_redis_request_total{status="miss"}` | Cache misses | Miss rate > 10% |
| `argocd_repo_pending_request_total` | Repo server queue depth | Sustained > 0 |
| `argocd_cluster_api_resource_objects` | Objects tracked per cluster | Sudden spikes |
| `argocd_cluster_api_resources` | API resource types per cluster | N/A |
| `process_resident_memory_bytes` | Memory usage per component | > 80% of limit |
| `go_goroutines` | Goroutine count (leak detection) | Sustained increase |

### Prometheus Rules

```yaml
groups:
  - name: argocd-fleet-performance
    rules:
      - alert: ArgoCD_ReconciliationSlow
        expr: |
          histogram_quantile(0.99,
            rate(argocd_app_reconcile_bucket[5m])
          ) > 120
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "ArgoCD reconciliation p99 > 2 minutes"
          description: "Consider adding controller shards or increasing repo-server replicas."

      - alert: ArgoCD_RedisCacheMissHigh
        expr: |
          rate(argocd_redis_request_total{status="miss"}[5m]) /
          rate(argocd_redis_request_total[5m]) > 0.1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "ArgoCD Redis cache miss rate > 10%"
          description: "Increase Redis memory limits or investigate frequent manifest changes."

      - alert: ArgoCD_RepoServerQueueBacklog
        expr: argocd_repo_pending_request_total > 0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "ArgoCD repo server has sustained pending requests"
          description: "Scale repo-server replicas or increase ARGOCD_EXEC_TIMEOUT."
```

### Grafana Dashboard

Import the official ArgoCD dashboard (ID: 14584) and add panels for:
- Reconciliation duration by shard (use `argocd_app_reconcile_bucket`)
- Cache hit/miss ratio over time
- Repo server pending requests
- Memory usage per component with limit overlay

---

## 9. Sizing Reference Table

| Fleet Profile | Clusters | Apps | Total | Controller | Shards | Repo Replicas | Redis Memory | Hub Nodes |
|--------------|----------|------|-------|------------|--------|--------------|-------------|-----------|
| Starter | 5-10 | 5 | 25-50 | 1 | 1 | 1 | 256Mi | 3 (default) |
| Small | 10-30 | 8 | 80-240 | 1 | 1 | 2 | 512Mi | 3 |
| Medium | 30-75 | 12 | 360-900 | 2 | 2 | 3 | 512Mi | 3+ |
| Large | 75-150 | 15 | 1,125-2,250 | 4 | 4 | 4 | 1Gi | 5+ |
| Enterprise | 150-300 | 20 | 3,000-6,000 | 6 | 6 | 6 | 2Gi | 5+ |
| Mega | 300+ | 20+ | 6,000+ | 8-10 | 8-10 | 8 | 4Gi | Dedicated infra |

Hub node recommendations assume the hub also runs RHACM. For dedicated
ArgoCD-only hubs (with RHACM on a separate cluster), reduce node count.

---

## 10. Troubleshooting Performance Issues

### Symptom: Applications stuck in "Progressing"

**Cause:** Controller cannot process the reconciliation queue fast enough.

**Investigation:**
```bash
# Check controller logs for queue depth
oc logs -n openshift-gitops deploy/openshift-gitops-application-controller | grep -i "queue\|reconcil"

# Check reconciliation metrics
oc exec -n openshift-gitops deploy/openshift-gitops-application-controller -- \
  curl -s localhost:8082/metrics | grep argocd_app_reconcile
```

**Fix:** Increase controller shards.

### Symptom: "rpc error: code = DeadlineExceeded" in Application status

**Cause:** Repo server `helm template` is timing out.

**Investigation:**
```bash
# Check repo server logs for slow renders
oc logs -n openshift-gitops deploy/openshift-gitops-repo-server | grep -i "timeout\|deadline\|slow"

# Check which app is causing the timeout (look for the app name in the error)
oc get applications -n openshift-gitops -o json | \
  jq '.items[] | select(.status.conditions[]? | .type == "ComparisonError") | .metadata.name'
```

**Fix:** Increase `ARGOCD_EXEC_TIMEOUT`, add repo-server replicas, or
optimize the offending chart's template complexity.

### Symptom: High memory usage on controller pods

**Cause:** Controller caches cluster state for all managed clusters. More
clusters = more memory.

**Investigation:**
```bash
# Check memory per shard
oc top pods -n openshift-gitops -l app.kubernetes.io/name=argocd-application-controller

# Check how many clusters/apps per shard
oc exec -n openshift-gitops deploy/openshift-gitops-application-controller -- \
  curl -s localhost:8082/metrics | grep argocd_cluster_info
```

**Fix:** Increase memory limits. Consider if some spoke clusters have
unusually large numbers of objects that inflate the controller's in-memory
cache.

### Symptom: Slow Git polling / "Repository not accessible"

**Cause:** Too many concurrent Git fetch operations, or Git server rate
limiting.

**Investigation:**
```bash
# Check repo server connection metrics
oc exec -n openshift-gitops deploy/openshift-gitops-repo-server -- \
  curl -s localhost:8084/metrics | grep argocd_git_request
```

**Fix:** Increase `ARGOCD_GIT_REQUEST_TIMEOUT`. Ensure the Git server can
handle the request rate. Consider using a Git mirror or cache proxy.

### Symptom: RHACM Policies taking minutes to evaluate

**Cause:** Too many cluster-label-sync Policies evaluating simultaneously.

**Investigation:**
```bash
# Check policy evaluation duration
oc logs -n open-cluster-management deploy/governance-policy-propagator | grep -i "duration\|slow"

# Count policies
oc get policies -A --no-headers | wc -l
```

**Fix:** Increase the Policy evaluation interval. Consider batching label
updates (promote labels in groups rather than one cluster at a time).

---

## Further Reading

- [ArgoCD Operator Manual: High Availability](https://argo-cd.readthedocs.io/en/stable/operator-manual/high_availability/)
- [ArgoCD Scaling Best Practices](https://argo-cd.readthedocs.io/en/stable/operator-manual/high_availability/#scaling)
- [OpenShift GitOps Operator Sizing](https://docs.openshift.com/gitops/latest/understanding_openshift_gitops/sizing-requirements-gitops.html)
- [RHACM Performance and Scaling](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.9/html/install/sizing)

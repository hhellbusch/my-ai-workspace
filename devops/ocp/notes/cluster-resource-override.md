# ClusterResourceOverride (CRO)

Cluster-level request/limit ratio policy for OpenShift — what the Operator does, when it helps packing, and where it bites.

**Audience:** Operators controlling container density on OpenShift 4.x.

**Purpose:** Decide whether ClusterResourceOverride belongs in a packing strategy vs. LimitRange alone or per-workload right-sizing.

**Related:** [Container density and overcommit](container-density-overcommit.md) · [Vertical Pod Autoscaler](vertical-pod-autoscaler.md)

---

## What it does

CRO installs a **mutating admission webhook** that rewrites container CPU/memory **requests** (and optionally CPU **limits**) based on cluster policy.

It does **not** change replica count — that is HPA's job.
It does **not** learn from usage — that is VPA's job.

On OpenShift, install the **ClusterResourceOverride Operator** from OperatorHub (commonly into `clusterresourceoverride-operator`).
Create a singleton `ClusterResourceOverride` CR named **`cluster`**.
The Operator watches that CR and ensures the admission webhook is running in the same namespace.

Overrides apply only to namespaces labeled for opt-in (see below).
They have **no effect** if the container has no limits — pair with a project `LimitRange` or explicit limits in the pod spec.

---

## Features

| Capability | Notes |
|------------|--------|
| `memoryRequestToLimitPercent` | Memory request = this % of memory limit (1–100). Default **50**. |
| `cpuRequestToLimitPercent` | CPU request = this % of CPU limit (1–100). Default **25**. |
| `limitCPUToMemoryPercent` | Derive CPU **limit** from memory limit first: **100% ≈ 1 CPU per 1Gi RAM**. Default **200**. Processed before CPU request override. |
| Namespace opt-in | Label `clusterresourceoverrides.admission.autoscaling.openshift.io/enabled: "true"` |
| Limit prerequisite | LimitRange defaults or pod-spec limits required |
| Status readiness | `status.mutatingWebhookConfigurationRef` populated when the webhook is registered |

Minimal CR:

```yaml
apiVersion: operator.autoscaling.openshift.io/v1
kind: ClusterResourceOverride
metadata:
  name: cluster
spec:
  podResourceOverride:
    spec:
      memoryRequestToLimitPercent: 50
      cpuRequestToLimitPercent: 25
      limitCPUToMemoryPercent: 200
```

Example with defaults and a container that already has `memory: 1Gi` limit:

- CPU limit becomes **2** cores (`limitCPUToMemoryPercent: 200`)
- Memory request → **512Mi**
- CPU request → **500m** (25% of 2 CPU)

Opt-in namespace:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: density-apps
  labels:
    clusterresourceoverrides.admission.autoscaling.openshift.io/enabled: "true"
```

Inspect webhook readiness:

```bash
oc get clusterresourceoverride cluster -o yaml
```

---

## Considerations and tradeoffs

| Dimension | Tradeoff |
|-----------|----------|
| **Density vs Guaranteed QoS** | CRO pushes `request < limit` (Burstable). Critical paths that need Guaranteed stay unlabeled or keep `request == limit` after mutation is disabled for that project |
| **Policy vs measurement** | CRO is a fixed ratio; VPA fits to observed usage. Use CRO for house policy, VPA for fine right-sizing |
| **CPU-from-memory derivation** | `limitCPUToMemoryPercent` is convenient for uniform apps; wrong for CPU-heavy / memory-light workloads |
| **GitOps visibility** | Admission mutates pods at create; Deployment YAML may still show pre-override requests unless you also encode the ratio in Git |
| **Blast radius** | One cluster CR; scope is controlled by which namespaces you label |

---

## Pitfalls

- **No limits on the container** — CRO is a no-op; pods keep developer-set (or missing) requests.
- **Forgetting the namespace label** — webhook ignores unlabeled projects; looks like "CRO is broken."
- **Labeling latency-sensitive prod too early** — sudden Burstable packing under node pressure can surprise SLOs.
- **Fighting Auto VPA** — both rewrite requests; CRO sets the initial ratio VPA then preserves. Prefer one clear owner for live mutation; often CRO + VPA `Off` (bake recommendations into Git).
- **Assuming `oc get deploy` shows admitted resources** — check the pod YAML after admission.
- **`limitCPUToMemoryPercent` on heterogeneous apps** — one memory→CPU rule for every labeled namespace is a blunt instrument.

---

## Best practices

1. **LimitRange first** in every density project so limits (and thus CRO) always apply.
2. **Start with non-prod / packable namespaces** labeled; expand after measuring contention and OOMs.
3. **Document the three percentages** as platform policy — change the CR deliberately, not ad hoc per app.
4. **Leave Guaranteed workloads unlabeled** (or in separate projects) when isolation matters more than density.
5. **Pair with VPA in `Off`** to discover whether the CRO ratio still matches reality; bake adjustments into Git.
6. **Do not enable Auto VPA + CPU HPA** on the same workload; CRO does not remove that conflict — see [VPA](vertical-pod-autoscaler.md).

---

## References

- [Cluster-level overcommit using the Cluster Resource Override Operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/nodes/working-with-clusters#nodes-cluster-resource-override_nodes-cluster-overcommit) — *Nodes*, working with clusters (OCP 4.18)
- [openshift/cluster-resource-override-admission-operator](https://github.com/openshift/cluster-resource-override-admission-operator) — Operator that deploys the mutating webhook
- Architecture: [container-density-overcommit.md](container-density-overcommit.md)

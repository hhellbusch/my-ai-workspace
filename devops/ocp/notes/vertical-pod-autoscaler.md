# Vertical Pod Autoscaler (VPA)

Right-sizing pod CPU and memory requests on OpenShift — what the Operator does, when it helps, and where it bites.

**Audience:** Operators and developers sizing workloads on OpenShift 4.x.

**Purpose:** Decide whether to use VPA (and in which mode) vs. manual right-sizing or HPA alone.

**Related:** [Container density and overcommit](container-density-overcommit.md) · [ClusterResourceOverride](cluster-resource-override.md)

---

## What it does

VPA adjusts **per-pod** CPU and memory **requests** (and typically preserves the request→limit ratio from the original container spec).
It does **not** change replica count — that is HPA's job.

On OpenShift, install the **Vertical Pod Autoscaler Operator** from OperatorHub into `openshift-vertical-pod-autoscaler`.
You then create a `VerticalPodAutoscaler` CR in the **same namespace** as the workload (`Deployment`, `StatefulSet`, `DaemonSet`, `Job`, `ReplicaSet`, `DeploymentConfig`, and some custom controllers).

Three controllers, managed via `VerticalPodAutoscalerController` named `default`:

| Component | Role |
|-----------|------|
| **Recommender** | Watches usage history; writes recommendations on the VPA status |
| **Admission plugin** | Mutating webhook — stamps recommended requests onto new pods |
| **Updater** | Evicts pods whose requests are outside recommendation bounds so controllers recreate them |

---

## Features

| Capability | Notes |
|------------|--------|
| Recommendation-only mode (`Off`) | Writes `status.recommendation`; changes nothing |
| Apply on create (`Initial`) | Admission stamps recommendations; no mid-life eviction |
| Apply continuously (`Auto` / `Recreate`) | Evicts and recreates when requests drift outside bounds |
| Per-container opt-out | `containerPolicies` with `mode: Off` for sidecars |
| Bound-aware updates | Uses `lowerBound` / `upperBound` vs `target` to decide when to act |
| PDB-aware eviction | Updater respects PodDisruptionBudgets |
| Cluster knobs | `minReplicas` (default 2), performance tuning, OOM memory bump-up, alternate recommenders |

Inspect recommendations:

```bash
oc get vpa <name> -o yaml
```

Look for `status.recommendation.containerRecommendations` (`target`, `lowerBound`, `upperBound`, `uncappedTarget`).

---

## Considerations and tradeoffs

| Dimension | Tradeoff |
|-----------|----------|
| **Accuracy vs disruption** | Auto modes improve fit over time but restart pods; `Off` is safe but requires a human/GitOps apply step |
| **Density vs headroom** | Tighter requests free cluster capacity; too tight increases OOM / CPU throttle risk under spikes the recommender smoothed away |
| **VPA vs HPA** | Complementary axes (size vs count). CPU-based HPA **plus** VPA auto-updating CPU requests creates a feedback loop |
| **GitOps vs live mutation** | Admission mutates pods at create time; the Deployment YAML may still show the old requests — source of truth can drift unless you bake recommendations back into Git |
| **Steady vs bursty** | Best for workloads with a stable usage shape; weak for rare spikes, batch jobs, or cold-start-heavy apps unless you understand the recommender's smoothing |
| **Replica floor** | By default VPA will not auto-evict workloads with fewer than `minReplicas` (2) pods — single-replica apps need manual restart or a deliberate `minReplicas: 1` (downtime risk) |

---

## Pitfalls

- **HPA + VPA Auto on the same CPU metric** — utilization swings as requests change; prefer VPA `Off` (or memory-only policies) when HPA owns CPU scale-out.
- **Assuming Deployment YAML matches running pods** — after admission mutation, `oc get deploy` and `oc get pod -o yaml` can disagree.
- **Deleting the VPA CR** — already-mutated pods keep their requests; **new** pods revert to the workload object's written requests.
- **DaemonSets and single-replica StatefulSets** — eviction can be disruptive or blocked by PDB / `minReplicas`; start in `Off`.
- **Sidecars and istio/service-mesh proxies** — without opt-out, VPA may undersize or thrash the sidecar.
- **Limits without requests (or wild ratios)** — VPA maintains the initial limit/request ratio; bad starting ratios get preserved.
- **Coexisting with ClusterResourceOverride** — CRO may stamp the request→limit ratio first; VPA then inherits that ratio. Prefer CRO for platform policy and VPA `Off` (bake into Git) when both are in play — see [container density](container-density-overcommit.md).
- **Insufficient metrics history** — early recommendations can be noisy; do not promote `Auto` after a few minutes of idle traffic.
- **`minReplicas: 1` for availability-critical apps** — updater can delete the only pod.

---

## Best practices

1. **Start in `Off`.** Collect recommendations across a representative load window, then either bake `target` into the Deployment (preferred under GitOps) or move to `Initial` / `Auto` deliberately.
2. **One VPA per workload object**, same namespace as the target.
3. **Do not pair Auto VPA with CPU HPA** on the same workload; memory-only VPA or recommendation-only + HPA is the usual escape hatch.
4. **Opt out sidecars** via `containerPolicies` when the main container is the sizing concern.
5. **Keep ≥2 replicas** (or a PDB that still allows rolling eviction) before enabling Auto/Recreate.
6. **Treat recommendations as evidence, not gospel** — cross-check with Prometheus/OOM events and known peak windows.
7. **Document the apply path** — who promotes recommendations into Git, and how often.

Minimal recommendation-only CR:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: myapp-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  updatePolicy:
    updateMode: "Off"
```

---

## References

- [Automatically adjust pod resource levels with the Vertical Pod Autoscaler](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/nodes/working-with-pods#nodes-pods-vertical-autoscaler-about_nodes-pods-vertical-autoscaler) — section 2.5, *Nodes* (OCP 4.18)
- [openshift/vertical-pod-autoscaler-operator](https://github.com/openshift/vertical-pod-autoscaler-operator) — Operator that deploys recommender, updater, and admission plugin
- Architecture: [container-density-overcommit.md](container-density-overcommit.md)

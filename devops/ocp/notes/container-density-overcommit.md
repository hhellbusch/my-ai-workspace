---
review:
  status: unreviewed
  notes: "Review block added 2026-08-06 when cross-linking namespace-guardrails guide. Content predates explicit review metadata."
---

# Container density and overcommit

How to pack more pods onto a large bare-metal OpenShift cluster without the density levers fighting each other.

**Audience:** Platform operators sizing CapEx-heavy bare-metal OCP fleets.

**Purpose:** Choose which density levers to use — and in what order — without breaking QoS expectations or autoscaler feedback loops.

**Related tool notes:** [ClusterResourceOverride](cluster-resource-override.md) · [Vertical Pod Autoscaler](vertical-pod-autoscaler.md)

---

## The problem

On bare metal, capacity is purchased up front.
Wasted request headroom is wasted CapEx.

Kubernetes schedules on **requests**, not limits.
Limits cap what a container may consume on the node.
The gap between request and limit is the overcommit ratio.

If developers set `request == limit` (Guaranteed QoS), packing is conservative.
If requests are missing or inflated, the scheduler either underfills nodes or over-promises.
Platform policy can normalize that — carefully.

---

## Layer map

| Lever | Mutates | Scope | When to use |
|-------|---------|-------|-------------|
| **LimitRange** | Default / min / max limits (and sometimes requests) on create | Per namespace | Always for multi-tenant density — CRO needs limits to exist |
| **ClusterResourceOverride (CRO)** | Request as % of limit; optional CPU limit from memory | Opt-in namespaces (label) | Cluster-wide density *policy* for labeled projects |
| **VPA** | Per-pod CPU/memory requests (preserves request→limit ratio) | Per workload CR | Right-size after you have real usage history |
| **HPA** | Replica count | Per workload | Scale out/in when load varies; do not dual-drive CPU with Auto VPA |
| **Node overcommit** | How the node treats CPU/memory overcommit | Per node / cluster defaults | Usually leave OpenShift defaults; disable only for hard isolation |

Flow in practice:

```
LimitRange (ensure limits)
  → CRO (set request/limit ratios on opt-in projects)
  → VPA (fit requests to observed usage; inherits ratio)
  → HPA (add/remove replicas)
  → scheduler places on requests; kubelet enforces limits
```

---

## Interaction rules

### CRO needs limits

CRO does nothing if a container has no memory/CPU limits.
Use a project `LimitRange` (defaults) or require limits in pod specs.
See [ClusterResourceOverride](cluster-resource-override.md).

### Opt-in namespaces only

CRO applies only where the namespace carries:

```yaml
clusterresourceoverrides.admission.autoscaling.openshift.io/enabled: "true"
```

Unlabeled projects are untouched — use that to keep latency-sensitive prod on Guaranteed sizing.

### VPA inherits the ratio CRO sets

VPA typically preserves the container's initial **request→limit ratio**.
If CRO first stamps `request = 25% of limit`, later VPA recommendations keep that ratio unless you change the written spec.
Order matters: set platform ratios (LimitRange + CRO), then right-size with VPA — preferably `Off` first and bake into Git.

### VPA Auto + CPU HPA fight

Both react to CPU utilization relative to requests.
When VPA changes requests, HPA's utilization math shifts.
Prefer VPA `Off` / memory-only policies when HPA owns CPU scale-out.
Details: [Vertical Pod Autoscaler](vertical-pod-autoscaler.md).

### Guaranteed QoS fights density

`request == limit` → Guaranteed.
Safe for critical paths; expensive for packing.
Burstable (`request < limit`) is the usual density default on shared bare-metal workers.

---

## Suggested adoption order (large bare-metal)

1. **Namespace defaults** — `LimitRange` (and `ResourceQuota` where multi-tenant caps matter) so every pod gets sane limits. For object-count and etcd guardrails beyond compute, see [namespace guardrails](../guides/namespace-guardrails/README.md).
2. **CRO on density tenants** — label non-prod / packable namespaces; leave critical namespaces unlabeled until measured.
3. **VPA in `Off`** — collect recommendations over a representative load window.
4. **Bake into Git** — promote `target` requests into Deployments (preferred under GitOps); use `Initial`/`Auto` only where live mutation is acceptable.
5. **HPA where load varies** — replica scaling for diurnal / event-driven demand; keep Auto VPA off the same CPU metric.

Measure before widening CRO: scheduling failure rates, node allocatable vs requested, OOM / throttle events, and app SLOs under contention.

---

## Explicit non-goals

This note does not cover:

- Deep kubelet / CRI-O node tuning
- NUMA topology or CPU pinning
- Storage thin-provisioning or CSI overcommit

Those affect density too, but they are different control planes.

---

## References

- [Configuring your cluster to place pods on overcommitted nodes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/nodes/working-with-clusters#nodes-cluster-overcommit) — chapter overview, *Nodes* (OCP 4.18)
- [Cluster-level overcommit using the Cluster Resource Override Operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/nodes/working-with-clusters#nodes-cluster-resource-override_nodes-cluster-overcommit) — CRO section, *Nodes* (OCP 4.18)
- [Automatically adjust pod resource levels with the Vertical Pod Autoscaler](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/nodes/working-with-pods#nodes-pods-vertical-autoscaler-about_nodes-pods-vertical-autoscaler) — section 2.5, *Nodes* (OCP 4.18)
- Tool notes: [cluster-resource-override.md](cluster-resource-override.md), [vertical-pod-autoscaler.md](vertical-pod-autoscaler.md)
- Namespace policy: [namespace guardrails](../guides/namespace-guardrails/README.md)

# Paths to consider — container density on bare-metal OCP

Landscape survey (2026-07-17). Not a how-to; a map of **control planes** that affect how densely you can pack pods without silent failure modes.

**Question:** For a CapEx-heavy bare-metal OpenShift cluster, what levers exist — and which ones interact?

**Working notes already in-repo:** [container-density-overcommit.md](../../devops/ocp/notes/container-density-overcommit.md) · [CRO](../../devops/ocp/notes/cluster-resource-override.md) · [VPA](../../devops/ocp/notes/vertical-pod-autoscaler.md)

---

## Path map (layers)

```text
1. Namespace policy     LimitRange, ResourceQuota, (optional) CRO label
2. Workload sizing      requests/limits, QoS class, PriorityClass
3. Autoscaling          VPA (size), HPA (count) — rarely both on same CPU metric
4. Scheduling           bin-packing / MostAllocated, topology, taints
5. Node capacity        allocatable, system-reserved, eviction thresholds, maxPods
6. Runtime pressure     eviction order, OOM, CPU throttle
7. Rebalancing          Descheduler (optional)
8. Capacity growth      Cluster Autoscaler — weak/absent on fixed BM fleets
```

CRO sits in layer 1–2 as **cluster policy that mutates request/limit ratios** for opted-in namespaces. It is necessary but not sufficient for "pack efficiently."

---

## Paths (what to learn / decide)

### P1 — Request vs limit vs quota (foundational)

| Idea | Why it matters |
|------|----------------|
| Scheduler places on **requests** | Density = sum(requests) vs node allocatable |
| Kubelet enforces **limits** | Burst / throttle / OOM live here |
| Overcommit ratio = limit ÷ request | CRO/LimitRange set this deliberately |
| **ResourceQuota** caps namespace totals | Does **not** stop node-level overcommit of limits |

**Decide:** What is the house request/limit ratio? Who may run Guaranteed (`request == limit`)?

**Sources:** K8s LimitRange, ResourceQuota; OCP overcommit chapter.

---

### P2 — ClusterResourceOverride (platform ratio policy)

| Idea | Why it matters |
|------|----------------|
| Mutating webhook; CR must be named `cluster` | Cluster-wide knobs, namespace opt-in |
| Needs limits (LimitRange or pod specs) | Silent no-op otherwise |
| `limitCPUToMemoryPercent` derives CPU from RAM | Blunt for heterogeneous apps |

**Decide:** Which namespaces get the label? Which stay Guaranteed / unlabeled?

**Sources:** OCP overcommit docs; CRO operator README.

---

### P3 — QoS classes and PriorityClass (who dies first)

| Idea | Why it matters |
|------|----------------|
| Guaranteed / Burstable / BestEffort | Eviction and OOM ranking under pressure |
| CRO/VPA packing → usually **Burstable** | Density trades isolation |
| PriorityClass ≠ QoS | Preemption vs node-pressure eviction are different axes |

**Decide:** Critical path = Guaranteed + high priority; packable apps = Burstable + lower priority.

**Sources:** K8s Pod QoS; Priority and Preemption.

---

### P4 — VPA and HPA (fit size vs scale count)

| Idea | Why it matters |
|------|----------------|
| VPA adjusts **requests** (often preserves ratio) | Right-size after CRO sets policy |
| HPA adjusts **replicas** | Absorb load without inflating every pod |
| Auto VPA + CPU HPA | Feedback loop — avoid |
| VPA respects LimitRange bounds | Platform defaults still constrain recommendations |

**Decide:** VPA `Off` → bake into Git first; HPA where load is variable.

**Sources:** OCP VPA/HPA docs; upstream VPA concepts.

---

### P5 — Node allocatable, reservation, eviction (physical truth)

| Idea | Why it matters |
|------|----------------|
| `Allocatable ≈ capacity − system-reserved − hard eviction` | Real packing budget |
| Eviction thresholds | Buffer before OOM; withheld from allocatable |
| Bare metal: large nodes, many pods | Memory pressure and reclaim behavior dominate |

**Decide:** Are system-reserved / eviction settings still defaults? Measured vs hoped?

**Sources:** OCP "Allocating resources for nodes."

---

### P6 — Pod density ceilings (`maxPods` / `podsPerCore`)

| Idea | Why it matters |
|------|----------------|
| Default often `maxPods: 250`, `podsPerCore: 10` | Lower of the two wins |
| Density can hit **pod count** before CPU/RAM | Especially small pods / sidecars |
| Raising maxPods stresses API QPS, CNI, iptables/nft, inotify | Not free on BM |

**Decide:** Is the bottleneck millicores, GiB, or pods-per-node?

**Sources:** OCP recommended host practices / managing max pods.

---

### P7 — Scheduler packing vs spreading

| Idea | Why it matters |
|------|----------------|
| Default scoring often spreads | Leaves stranded fragments |
| `MostAllocated` / bin-packing profiles | Higher utilization, hotter nodes |
| Affinity / topology / taints | Correctness over density |

**Decide:** Prefer pack-tight workers vs spread for noisy-neighbor isolation?

**Sources:** K8s scheduling / NodeResourcesFit; OCP scheduler profiles (verify version).

---

### P8 — Descheduler (rebalance after the fact)

| Idea | Why it matters |
|------|----------------|
| Scheduler is place-once | Nodes drift underutilized or overloaded |
| Strategies: Low/HighNodeUtilization | Optional density cleanup |

**Decide:** Worth the churn on BM, or fix placement + sizing first?

---

### P9 — Cluster / Machine Autoscaler (usually out of scope on fixed BM)

| Idea | Why it matters |
|------|----------------|
| HPA creates replicas; CA adds nodes | Cloud-shaped elasticity |
| Fixed bare-metal fleets | Often no CA — **density is the only scale lever** |

**Decide:** Confirm BM = fixed capacity → prioritize P1–P6 over CA.

---

### P10 — Observability and failure modes (close the loop)

| Signal | What it tells you |
|--------|-------------------|
| Requested vs allocatable (node) | Scheduling headroom |
| Actual usage vs request | CRO/VPA ratio quality |
| Throttle / OOM / eviction events | Too aggressive packing |
| Pending pods (FailedScheduling) | Hit request budget or maxPods |
| App SLO under contention | Business limit of density |

Without this path, the others are opinion.

---

## Suggested learning order (for this research)

1. **P1 + P5** — mental model of request/allocatable/eviction  
2. **P2 + P3** — CRO and QoS tradeoffs (already started in notes)  
3. **P4** — VPA/HPA coexistence rules  
4. **P6** — whether pod-count is the hidden ceiling  
5. **P7–P8** — only after sizing policy is stable  
6. **P9** — confirm BM assumptions; skip deep CA work if fixed fleet  
7. **P10** — metrics/dashboards that prove density is safe  

---

## Gaps called out by this survey (to deepen next)

- Exact OCP 4.18+ scheduler profile names for bin packing  
- Whether `limitCPUToMemoryPercent` is still recommended for mixed microservices  
- Interaction of CRO admission order with LimitRange min/max — **confirmed in docs:** request can be overridden below LimitRange min → pod forbidden (configure both with caution)  
- Descheduler Operator status on current OCP  
- Concrete Prometheus queries / dashboards for P10  
- OKD 4.18 moved some overcommit prose under *scheduling*; full CRO Operator install steps still clearest in RH Nodes book / openshift-docs adoc (ref-01/02)  

---

## Non-paths (explicitly deprioritized for now)

- NUMA / CPU Manager / Topology Manager (latency-sensitive islands)  
- Storage thin-provisioning / CSI overcommit  
- GPU packing (separate problem; see `research/openshift-gpu/`)

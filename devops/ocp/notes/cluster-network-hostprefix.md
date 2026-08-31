---
review:
  status: unreviewed
  notes: "Drafted 2026-08-31 from OCP 4.20 CIDR/hostPrefix/maxPods sizing discussion. Math is IPv4 arithmetic; day-2 immutability checked against CNO + product docs."
---

# Cluster network, hostPrefix, and pods per node

How OpenShift's pod IP pool, per-node subnet size, and kubelet `maxPods` fit together — and which knobs you can change after install.

**Audience:** Operators planning `install-config.yaml` networking, or deciding whether a `maxPods` bump needs a new cluster.

**Purpose:** Pick a `hostPrefix` and cluster CIDR that can hold the intended pods-per-node and node count, without mixing up the three address ranges.

---

## The three ranges

OpenShift uses three IPv4 pools that must not overlap.
Only two of them matter for "how many pods fit on a node."

| Range | `install-config.yaml` | What it addresses | Sizes |
|-------|----------------------|-------------------|--------|
| **Cluster network** | `networking.clusterNetwork[].cidr` | **Pod** IPs (the overlay) | The **big pool** for the whole cluster |
| **hostPrefix** | `networking.clusterNetwork[].hostPrefix` | How large a **slice** of that pool each **node** gets | Per-node pod subnet |
| **Service network** | `networking.serviceNetwork[]` | **Service** `ClusterIP`s, not pods | Unrelated to pods-per-node |

There is also `machineNetwork` (node/API/ingress on the physical fabric) and OVN-internal subnets (join, masquerade, transit).
Those must not overlap the pools above; they do not set pod density.
See [OVN-Kubernetes install-config](../examples/networking/ovn-kubernetes-install-config/README.md#network-subnet-planning) for overlap planning.

### Slash numbers

The number after `/` is **prefix length**.
**Smaller number = bigger block.**

```
/15  →  huge  (cluster-wide pod pool)
/23  →  512 addresses  (default per-node slice)
/20  →  4096 addresses (enough for 2500 pods on one node)
```

A **pod** on a node consumes one address from **that node's slice**, not from the service network.

---

## How the ranges interact

The cluster CIDR is carved into equal node slices.

```
cluster network  100.100.0.0/15          ← big pool
                 ├── node-a  /23
                 ├── node-b  /23
                 └── … as many /23s as the pool holds
```

Two formulas (IPv4):

```text
addresses per node  =  2^(32 − hostPrefix)
max nodes           =  2^(hostPrefix − clusterPrefix)
```

`clusterPrefix` is the slash on the cluster CIDR (`15` in `100.100.0.0/15`).

Check: `(addresses per node) × (max nodes)` equals the size of the cluster CIDR.

**Tradeoff:** shrinking `hostPrefix` (bigger per-node slice) **cuts** how many nodes fit in the same cluster CIDR.

Kubelet `maxPods` is a **fourth** limit, not an IP range.
The scheduler cannot place more pods on a node than `min(maxPods, usable IPs on that node's slice, CPU/memory requests)`.

| Lever | Default (OCP 4.20) | When it bites |
|-------|--------------------|---------------|
| `maxPods` | 250 | Tiny pods; CPU/RAM still free |
| `hostPrefix` | 23 (~512 addresses) | Raising `maxPods` toward 500+ |
| CPU / memory requests | Node allocatable | Typical on large-core hosts |
| Service CIDR | `/16` (~65k ClusterIPs) | Many Services, not many pods |

Do not set `maxPods` from core count (`podsPerCore × vCPU`).
On a 320-vCPU node that product is thousands of pods — past the IP slice and past a sensible blast radius.
Leave `podsPerCore` at `0` (disabled) unless you intend that cap.

---

## hostPrefix → IPs per node

Usable ≈ total minus 2 (network and broadcast).
Leave ~10–20 for platform pods (OVN, DNS, CSI, operators).
`maxPods` **includes** those platform pods.

| `hostPrefix` | Node slice | Addresses | Practical user pods (rough) | 2500 pods/node? | Typical use |
|-------------:|------------|----------:|----------------------------:|-----------------|-------------|
| 26 | `/26` | 64 | ~40 | No | Tiny / constrained |
| 25 | `/25` | 128 | ~100 | No | |
| 24 | `/24` | 256 | ~230 | No | Tight vs default `maxPods` 250 |
| **23** | **`/23`** | **512** | **~480** | **No** | **OCP default** |
| 22 | `/22` | 1,024 | ~990 | No | Common for ~500 pods/node |
| 21 | `/21` | 2,048 | ~2,000 | No | Short of 2500 |
| **20** | **`/20`** | **4,096** | **~4,000** | **Yes** | **Documented 2500-pod test** |
| 19 | `/19` | 8,192 | ~8,000 | Yes | Extra headroom; fewer nodes |

Red Hat's tested **2,500 pods per node** used `hostPrefix: 20` and `maxPods: 2500`.
See [Planning your environment according to object maximums](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/scalability_and_performance/planning-your-environment-according-to-object-maximums) — chapter 7.1, *Scalability and performance* (OCP 4.20).

A `/23` is the usual ceiling around **500** pods/node.
Red Hat's 500-pods-per-node work treated `/23` (~510 usable) as not quite enough for 500 **user** pods plus system pods, and used `hostPrefix: 22`.

---

## Cluster CIDR × hostPrefix → max nodes

Same `hostPrefix`, larger cluster CIDR → more node slices.
Same cluster CIDR, smaller `hostPrefix` → fewer nodes.

### If the cluster network is `/15` (example: `100.100.0.0/15`)

| `hostPrefix` | Addresses / node | Max nodes in that `/15` |
|-------------:|-----------------:|------------------------:|
| 23 | 512 | **256** |
| 22 | 1,024 | 128 |
| 21 | 2,048 | 64 |
| **20** | **4,096** | **32** |
| 19 | 8,192 | 16 |

`/15` + `hostPrefix: 20` is enough IPs for 2,500 pods **per node**, but only **32 nodes**.

### If you need more than 32 nodes *and* 2,500 pods/node

Widen the cluster CIDR at **install** (smaller slash).
Keep `hostPrefix: 20`.

| Cluster CIDR | `hostPrefix: 20` max nodes | Notes |
|--------------|---------------------------:|-------|
| `/15` | 32 | Example: `100.100.0.0/15` |
| `/14` | 64 | `100.100.0.0/14` is aligned; does not overlap `100.99.0.0/16` |
| `/13` | 128 | `100.100.0.0` is **not** a valid `/13` network address (that block is `100.96.0.0/13`, which **would** overlap `100.99.0.0/16`) |

CIDR expansion after install (OVN-Kubernetes only) can **lengthen the pool** (for example `/15` → `/14`) but **cannot** change `hostPrefix`.
The base network address stays the same; the new prefix must still be a valid supernet of the existing CIDR and must not collide with the service network or OVN internals.

Default OCP pool for comparison: `10.128.0.0/14` + `hostPrefix: 23` → **512** nodes × 512 addresses.

---

## What you can change after install (OCP 4.20, OVN-Kubernetes)

| Setting | Day-2? | Effect |
|---------|--------|--------|
| `maxPods` (KubeletConfig) | Yes — rolling drain/reboot | Pod **slots** on the node, not IPs |
| Cluster network **mask** (same base, smaller prefix) | Yes — more **node** slices | Does not enlarge each node's `/hostPrefix` subnet |
| **hostPrefix** | **No** | CNO: `modifying a clusterNetwork's hostPrefix value is unsupported` |
| Cluster network **base address** | **No** | |
| Service network CIDR | **No** | Size it at install |

Product wording: [Configuring the cluster network range](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/configuring_network_settings/configuring-cluster-network-range) — chapter 3, *Configuring network settings* (OCP 4.20): host prefix cannot be modified; CIDR mask may be expanded.

`maxPods` procedure: [Managing the maximum number of pods per node](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/nodes/working-with-nodes) — section 6.5, *Working with nodes* (OCP 4.20).
A `KubeletConfig` on the worker pool also hits **dependent** pools (infra); use a custom MCP if only some nodes should change.
See [MachineConfig pools](machine-config-pools.md).

---

## Worked example

Layout:

```yaml
networking:
  clusterNetwork:
  - cidr: 100.100.0.0/15
    hostPrefix: 23
  serviceNetwork:
  - 100.99.0.0/16
```

| Question | Answer |
|----------|--------|
| Pods per node from IPs? | `/23` → ~480 user pods practical; default `maxPods` 250 is the usual cap |
| Raise `maxPods` to 400? | IPs are fine; no CIDR change |
| Raise `maxPods` to 500? | At the `/23` edge; `/22` would be the comfortable IP size — **not changeable now** |
| 2,500 pods per node later? | Need `hostPrefix: 20` at **install**, plus `maxPods: 2500`. This `/15` then holds **32** nodes. More nodes → larger cluster CIDR at install |
| Change service `/16` for more pods? | No. Services ≠ pods |

`oc` check of what is live:

```bash
oc get network.config.openshift.io cluster -o jsonpath='{.spec.clusterNetwork}{"\n"}{.spec.serviceNetwork}{"\n"}'
oc describe node <node> | grep -A20 Allocatable
```

`Allocatable: pods:` is the kubelet cap (default 250), not the size of the node's IP slice.

---

## Choosing numbers

1. **Pods per node you might need** (including platform pods) → smallest `hostPrefix` whose address count is comfortably above that (table above). For 2,500, use **20**.
2. **How many nodes** → cluster CIDR must supply `2^(hostPrefix − clusterPrefix)` slices. If not, widen the cluster CIDR (smaller slash) at install.
3. **Service count** → `serviceNetwork` only. A `/16` is ~65k ClusterIPs; it does not grow with `maxPods`.
4. **Do not overlap** cluster, service, machine, and OVN-internal ranges.
5. After install, raise `maxPods` only if nodes hit the **pod-count** ceiling with CPU/RAM still free — and never above the IP slice.

CPU/memory packing vs `maxPods` is a different lever: [container density / overcommit](container-density-overcommit.md).

---

## Related

- [OVN-Kubernetes install-config](../examples/networking/ovn-kubernetes-install-config/README.md) — overlap checklist, `install-config.yaml` shape
- [Install-config immutability](install-config-immutability.md) — Frozen vs Day-2 catalog (FIPS, `networkType`, join subnet clashes)
- [Container density / overcommit](container-density-overcommit.md) — requests, CRO, VPA; not IP math
- [MachineConfig pools](machine-config-pools.md) — targeting a `KubeletConfig` without dragging infra nodes

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

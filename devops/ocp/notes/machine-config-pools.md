# MachineConfig and MachineConfigPool

How OpenShift rolls OS-level node configuration — and how to target the right nodes without surprises.

**Audience:** Operators writing `MachineConfig` or `MachineConfigPool` objects on OpenShift 4.x.

**Purpose:** Decide which pool a config belongs in, when to create a custom pool, and what to do when the same change must land on more than one pool type.

---

## What these objects do

| Object | Role |
|--------|------|
| **MachineConfig (MC)** | Declares node-level state: kernel args, files, systemd units, kubelet/CRI-O settings. Rendered into Ignition and applied by the Machine Config Operator (MCO). |
| **MachineConfigPool (MCP)** | Groups nodes that receive the same rendered config. Controls rollout parallelism (`maxUnavailable`), pause, and degraded status. |

MCPs manage **OS configuration**, not pod scheduling. Labels, taints, and affinity control where workloads run. MCP choices still matter because MCO **drains and reboots** nodes during rollout.

---

## Targeting rules

### Node roles vs MC roles

Two label systems — similar names, different objects:

| Label | On | Purpose |
|-------|-----|---------|
| `node-role.kubernetes.io/<name>` | **Node** | Node class in `oc get nodes` ROLES; **MCP `nodeSelector`** matches this |
| `machineconfiguration.openshift.io/role: <name>` | **MachineConfig** | Which configs merge into a pool's rendered MC |

Default mapping at install:

| Node role | MCP | MC roles in rendered config |
|-----------|-----|----------------------------|
| `node-role.kubernetes.io/master` | `master` | `master` (+ platform templates) |
| `node-role.kubernetes.io/worker` | `worker` | `worker` |
| `node-role.kubernetes.io/<custom>` | custom MCP (if defined) | `worker` + `<custom>` via `machineConfigSelector` |

```
Node                          MachineConfigPool              MachineConfig
────                          ─────────────────              ─────────────
node-role.../kafka      →     nodeSelector: kafka      ←     role: kafka-worker
                              selector: [worker, kafka-worker]     role: worker (inherited)
```

**Node role → pool membership.** **MC role → which config fragments compose that pool.** Workload placement (taints, affinity, `topology.kubernetes.io/zone`, app labels) is separate — do not conflate with node roles.

### Node role guidelines

Use `node-role.kubernetes.io/*` for **platform node class** and MCP boundaries — not as general-purpose app labels.

#### When to add a custom node role

| Stay on default `worker` | Add a custom node role |
|--------------------------|-------------------------|
| Same OS config as all workers | Different **MachineConfig** scope (kernel, files, systemd) |
| Taints/affinity enough for workload separation | Separate **MCP rollout** (`maxUnavailable`, `paused`, upgrade order) |
| Rack/zone metadata only | Node must leave the default `worker` pool |

If you only need “pods run here,” use **taints + affinity + topology labels** — not a new node role.

#### Rules

1. **One custom node role per node** — never stack two custom pool roles (e.g. `kafka` + `gpu-worker`) on one host.
2. **Create the MCP before labeling** — label without a matching MCP leaves the node in `worker` or **unmanaged**.
3. **Keep `worker` unless infra-only** — `worker` + custom is normal; drop `worker` only when the node should not run generic workloads (custom MCP still inherits worker MCs).
4. **Align names** — document the mapping between node role (`kafka`), MCP name (`kafka-worker`), and MC role (`kafka-worker`).
5. **No custom roles on control plane** — master nodes use `role: master` MCs only.
6. **Prefer install-time labels** for fixed node class (ACM BMAC annotations, BMH `spec.nodeLabels`, GitOps inventory) — day-2 role changes trigger MCP rollouts.
7. **Git as source of truth** — model roles in inventory; avoid ad-hoc `oc label` without updating declared state.

#### Label types (do not mix purposes)

| Type | Examples | Use for |
|------|----------|---------|
| Node role | `node-role.kubernetes.io/worker`, `.../infra` | MCP membership |
| Topology | `topology.kubernetes.io/zone`, `topology.kubernetes.io/region` | Rack/zone, Strimzi, MCO drain order |
| Workload | taints, `nvidia.com/gpu.present`, app labels | Scheduling |

#### Checklist before adding `node-role.kubernetes.io/<foo>`

1. Need different **OS-level** config on this class? If no → taints/labels only.
2. Need a **separate MCP**? If no → stay in `worker`.
3. MCP exists with `worker` in `machineConfigSelector`?
4. Will any node get **two custom** roles? If yes → redesign.
5. Naming consistent across node label, MCP name, and MC role?

#### Anti-patterns

| Anti-pattern | Why it hurts |
|--------------|--------------|
| Node role per app team | MCP sprawl; pool overlap risk |
| Label before MCP exists | Unmanaged or wrong pool |
| Rack/zone as node role | Conflates scheduling topology with OS config |
| `role: worker` MC to target three nodes | Reboots every worker — use custom pool |

See also: [Kafka labeling comparison](../examples/messaging/kafka/bare-metal-portworx/LABELING-COMPARISON.md) (rack labels vs dedicated node roles), [GPU node labeling](../gpu/vgpu-node-labeling.md) (inventory → Git → label).

### One role label per MachineConfig

Every `MachineConfig` carries exactly one pool-targeting label:

```yaml
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker   # single value only
```

The MCO does **not** support multiple `machineconfiguration.openshift.io/role` values on one `MachineConfig`. You cannot make one MC object target both `master` and `worker`, or both `worker` and a custom role.

### One pool per node

A node belongs to **at most one** MCP. How overlaps resolve:

| Situation | Result |
|-----------|--------|
| `worker` + one custom role, **custom MCP exists** | **Custom pool wins** (e.g. `worker,infra` → `infra` MCP). Node leaves `worker` pool counts; still inherits worker MCs via custom `machineConfigSelector`. |
| Custom role label, **no custom MCP** | Stays in **`worker`** pool. |
| Custom role only, **no matching MCP** | **Unmanaged** — MCO does not reconcile the node. |
| **Two custom pools** both match | **Error** — MCO cannot pick a pool. |
| **`master` + `worker`** on same node | **Error** — common in single-node dev clusters (CRC). |

#### Worker + custom (normal)

This is the expected path when carving out a subset of workers:

```bash
# Node may show both roles while transitioning
oc label node worker-2 node-role.kubernetes.io/kafka=

# worker MCP machine count drops; kafka-worker MCP gains the node
oc get mcp
```

Remove `node-role.kubernetes.io/worker` only when you want the node **infra-only for scheduling**. The custom pool still inherits worker MachineConfigs through `machineConfigSelector: [worker, <custom>]`.

#### Two custom pools on one node (failure)

If two MCPs both match the same node's labels, the MCO errors:

```text
Error finding pools for node: node worker-2 belongs to more than one MachineConfigPool
```

Example mistake — both pools select the same node:

```yaml
# kafka-worker MCP
nodeSelector:
  matchLabels:
    node-role.kubernetes.io/kafka: ""

# gpu-worker MCP — worker-2 has BOTH kafka and gpu labels
nodeSelector:
  matchLabels:
    node-role.kubernetes.io/gpu-worker: ""
```

```bash
oc label node worker-2 node-role.kubernetes.io/kafka=
oc label node worker-2 node-role.kubernetes.io/gpu-worker=   # now matches two custom MCPs
```

**Fix:** one custom role per node for MCP purposes. Split nodes across pools — do not stack custom pool labels on the same host.

#### Diagnose and recover

```bash
oc get nodes --show-labels | rg 'node-role.kubernetes.io'
oc get mcp -o custom-columns=NAME:.metadata.name,NODES:.status.machineCount,SELECTOR:.spec.nodeSelector
oc describe node <node>
oc logs -n openshift-machine-config-operator -l k8s-app=machine-config-controller --tail=100 \
  | rg -i 'more than one|machineconfigpool'
```

Recovery: remove the extra role label or narrow one MCP's `nodeSelector` so only one pool matches. Wait for MCO to reconcile; watch `oc get mcp -w`.

Design rule: **each node's labels must resolve to exactly one MCP.**

### Pools select configs; configs do not select pools

An MCP's `machineConfigSelector` decides which MCs are composed into that pool's rendered config. A custom pool typically selects MCs from **multiple roles**:

```yaml
spec:
  machineConfigSelector:
    matchExpressions:
      - key: machineconfiguration.openshift.io/role
        operator: In
        values:
          - worker
          - kafka-worker
```

That means:

- MCs labeled `worker` are **included** in the `kafka-worker` pool's rendered config (inheritance).
- MCs labeled `kafka-worker` apply **only** to nodes in that custom pool.
- The MC itself still has a single role label — inheritance is a **pool selector** feature, not multi-targeting on one MC.

---

## Default pools

OpenShift creates two MCPs at install time:

| Pool | Nodes | Notes |
|------|-------|-------|
| `master` | Control plane | Default and recommended `maxUnavailable` is `1` — do not raise for control plane pools. |
| `worker` | All workers not claimed by a more specific pool | Default for most compute nodes. |

Check status:

```bash
oc get machineconfigpool
oc get mcp worker -o yaml    # conditions: Updated, Updating, Degraded
oc get mcp worker -w         # watch rollout
```

---

## Custom pools

Use a custom MCP when a **subset of workers** needs OS-level config that must not touch other workers — kernel tuning, IOMMU, NVMe identity, container policy scoped to a node class.

Custom pools **must inherit from `worker`**. A pool that does not include `worker` in its `machineConfigSelector` is not supported by the MCO. Worker-pool changes (OS updates during cluster upgrade) still roll out to custom-pool nodes.

### Pattern

1. **Label nodes** with a custom node role:

   ```bash
   oc label node worker-2 node-role.kubernetes.io/kafka=
   ```

2. **Create the MCP** with both `worker` and the custom role in `machineConfigSelector`, plus a `nodeSelector` for the custom label:

   ```yaml
   apiVersion: machineconfiguration.openshift.io/v1
   kind: MachineConfigPool
   metadata:
     name: kafka-worker
   spec:
     machineConfigSelector:
       matchExpressions:
         - key: machineconfiguration.openshift.io/role
           operator: In
           values:
             - worker
             - kafka-worker
     nodeSelector:
       matchLabels:
         node-role.kubernetes.io/kafka: ""
     maxUnavailable: 1
   ```

3. **Create pool-specific MCs** with the custom role label:

   ```yaml
   metadata:
     labels:
       machineconfiguration.openshift.io/role: kafka-worker
     name: 99-kafka-kernel-tuning
   ```

### What changes when you add a custom pool

```
worker MCP       →  nodes WITHOUT node-role.kubernetes.io/kafka
kafka-worker MCP →  nodes WITH    node-role.kubernetes.io/kafka
```

Labeled nodes move **out of** the default `worker` pool. Each pool rolls out independently during upgrades.

### Custom pools on control plane nodes

A custom pool on a node that also has the `master` role is **not supported**. The MCO will not apply custom-pool MCs to control plane nodes. Keep custom pools on worker-class nodes only.

---

## Same config on master and worker

When identical OS-level change must land on both pool types, create **two** `MachineConfig` objects — same `spec`, different role labels and names:

```yaml
# 99-master-<purpose>.yaml
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-<purpose>

---
# 99-worker-<purpose>.yaml
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-<purpose>
```

Each pool rolls out on its own schedule. Expect two reboot waves.

### Define the config once (Helm or Kustomize)

The MCO requires two API objects, but you should not maintain duplicate `spec` blocks by hand — they will drift. Generate both MCs from one source:

| Tool | Pattern |
|------|---------|
| **Helm** | Template `metadata.labels` / `metadata.name` on a shared `spec`; `helm template` with `role: master` and `role: worker` (values or two releases). |
| **Kustomize** | Base `MachineConfig` with common `spec`; overlays patch only `metadata.name` and `machineconfiguration.openshift.io/role`. |

**Helm sketch:**

```yaml
# templates/machineconfig.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  name: 99-{{ .Values.role }}-{{ .Values.purpose }}
  labels:
    machineconfiguration.openshift.io/role: {{ .Values.role }}
spec:
  {{- toYaml .Values.machineConfigSpec | nindent 2 }}
```

```bash
# Render both (example values files or --set)
helm template mc ./chart -f values-master.yaml > 99-master-policy.yaml
helm template mc ./chart -f values-worker.yaml > 99-worker-policy.yaml
```

**Kustomize sketch:**

```
machineconfig-policy/
  base/kustomization.yaml      # common spec
  base/machineconfig.yaml      # spec only; name/role placeholders or patches
  overlays/master/kustomization.yaml   # patches role + name
  overlays/worker/kustomization.yaml
```

```bash
kustomize build overlays/master | oc apply -f -
kustomize build overlays/worker | oc apply -f -
```

Repo example of hand-duplicated master/worker MCs (good candidate to templatize): [`signature-policy-machineconfig.yaml`](../troubleshooting/image-signature-policy-mcp-deadlock/signature-policy-machineconfig.yaml).

---

## Rollout behavior

| Setting | Effect |
|---------|--------|
| `maxUnavailable: 1` (default) | One node cordoned, drained, updated, rebooted at a time per pool. Respects PDBs. |
| `maxUnavailable: N` | Up to N nodes in the pool update in parallel — faster, but more pods stacked on fewer nodes during drain. |
| `paused: true` | Stops rollout for **this pool only**. Other pools continue. |

**Update order within a pool:** MCO drains by `topology.kubernetes.io/zone` (alphabetical), oldest node first within each zone. Nodes without zone labels: oldest first cluster-wide.

**Reboot cost:** Kernel args, many file changes, and some systemd units trigger reboot. Plan maintenance windows accordingly.

**CVO vs MCO:** Cluster Version Operator (CVO) upgrades platform components and delivers new RHCOS payloads. MCO applies per-pool node updates (drain → reboot). Both can be active during a cluster upgrade; watch each independently.

---

## Speeding up rollouts

Parallelism is controlled on the **MCP** (`spec.maxUnavailable`, `spec.paused`) — not on individual `MachineConfig` objects. The MCO cordons and drains up to `maxUnavailable` nodes per pool at a time, then reboots them.

### Raise `maxUnavailable` within a pool

Default is `1` (sequential). Increase to drain multiple nodes in parallel:

```yaml
spec:
  maxUnavailable: 3       # integer — up to 3 nodes at once
  # or
  maxUnavailable: "25%"   # percentage of pool size
```

```bash
oc patch mcp worker --type=merge -p '{"spec":{"maxUnavailable":"25%"}}'
oc get mcp worker -w
```

| Tradeoff | Detail |
|----------|--------|
| Faster | More nodes update concurrently when spare capacity exists |
| Risk | More pods stacked on fewer schedulable nodes during drain |
| PDBs still apply | Eviction must find a home — if not, the pool stalls |
| Blast radius | A bad MC affects more nodes before you notice |

**Do not raise `maxUnavailable` on the `master` pool.** Keep control plane sequential.

#### Percentage math (`"25%"`, `"33%"`, etc.)

Percentage values use **round up** (ceiling), same as Kubernetes `IntOrString` elsewhere:

```
parallel = ceil(pool_size × percent / 100)
```

| Pool size | `25%` | `33%` | `50%` |
|----------:|------:|------:|------:|
| 3 | 1 | 1 | 2 |
| 4 | 1 | 2 | 2 |
| 5 | 2 | 2 | 3 |
| 6 | 2 | 2 | 3 |
| 8 | 2 | 3 | 4 |
| 10 | 3 | 4 | 5 |
| 12 | 3 | 4 | 6 |

On **3–4 nodes**, `"25%"` behaves like `maxUnavailable: 1` — you need a larger pool before percent buys parallelism. For a small pool where you want two nodes at once, use an integer (`maxUnavailable: 2`) and accept that half the pool may be down.

**Syntax:** percent must be a quoted string (`"25%"`). Integer form is unquoted (`2`). You cannot set `0` to stop rollouts — use `paused: true`.

**Unavailable count** includes any node not schedulable during the update (cordoned, draining, rebooting, `NotReady`) — not only nodes actively receiving the new MC.

```bash
oc get mcp worker -o jsonpath='maxUnavailable={.spec.maxUnavailable} machines={.status.machineCount}{"\n"}'
```

| Approach | When to use |
|----------|-------------|
| Integer (`2`, `3`) | Fixed parallelism as the pool grows |
| Percent (`"25%"`) | Scales with fleet size on large homogeneous worker pools |
| `1` | Default; quorum/stateful workloads |

### Pools already roll out in parallel with each other

MCO updates each MCP independently. During a cluster upgrade with defaults, you typically get one node updating per pool at the same time — e.g. one master, one worker, one per custom pool (`kafka-worker`, `gpu-worker`). Custom pools isolate blast radius; they do not speed a single pool, but they let pools progress concurrently.

### Canary pool (validate before fleet rollout)

For large worker fleets, pause the main pool and validate on a small custom MCP first:

1. Create a canary MCP with 1–2 nodes.
2. Set `paused: true` on the `worker` pool.
3. Apply MCs; wait for the canary pool to reach `UPDATED=True`.
4. Unpause `worker` (optionally with a higher `maxUnavailable` once validated).

```yaml
spec:
  paused: true
  maxUnavailable: 1
```

See [Performing a canary rollout update](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/updating_clusters/performing-a-cluster-update#update-using-custom-machine-config-pools) (section 3.4 of *Performing a cluster update*) in the Red Hat docs.

### Batch MC changes before rollout

Each MC edit triggers a new rendered config. Apply all MC objects first, then watch one MCP rollout — the MCO merges them into a single rendered config per pool. You pay one reboot cycle per node, not one per MC file.

### What actually limits speed

| Constraint | Effect |
|------------|--------|
| PDBs | High `maxUnavailable` means nothing if pods cannot reschedule |
| Node capacity | Draining several heavy nodes may leave nowhere for those pods |
| Zone order | MCO drains by zone (alphabetical), oldest first — not all zones at once |
| Stateful workloads | Kafka, etcd, Ceph — parallel drains can break ISR/quorum even when MCP allows it |
| Reboot-bound changes | Kernel args and many file changes — parallel means parallel reboots |

### When to keep `maxUnavailable: 1`

- Control plane (`master` pool)
- Quorum- or ISR-sensitive workloads (Kafka brokers, etcd, storage)
- Clusters near capacity with tight PDBs
- First application of an untested MC

```bash
oc get mcp -o custom-columns=\
NAME:.metadata.name,\
MAX:.spec.maxUnavailable,\
PAUSED:.spec.paused,\
UPDATING:.status.conditions[?(@.type==\"Updating\")].status,\
UPDATED:.status.conditions[?(@.type==\"Updated\")].status
```

---

## Common pitfalls

1. **Wrong role on a scoped change** — `role: worker` on kernel tuning meant for three nodes reboots **every** worker. Use a custom pool and `role: <custom>`.

2. **Forgot `worker` in custom pool selector** — Custom-pool nodes miss base worker MCs (kubelet, CRI-O, OS update path). Always include `worker` in `machineConfigSelector`.

3. **Node still in default worker pool** — Without the custom node role label, pool-specific MCs never apply to that node.

4. **Two custom pools on one node** — Stacking custom role labels (e.g. `kafka` + `gpu-worker`) without disjoint node sets causes MCO pool resolution errors. One custom MCP per node.

5. **Drain blocked by unrelated PDB** — MCO must evict all pods on a node during drain. A misconfigured PDB on a co-located workload stalls the entire pool update.

6. **Conflicting MCs on the same path** — Within a rendered config, the MCO merges MCs in lexicographic name order; later names override earlier ones for the same field (e.g. `99-worker-foo` overrides `50-worker-foo`). Since **OCP 4.15+**, MCs targeting a custom pool role override worker-role MCs for the same field regardless of name order. Avoid defining the same path in both `worker` and custom roles unless you intend the custom value to win.

7. **Ignition version mismatch** — Match `spec.config.ignition.version` to the cluster. Check an existing MC:

   ```bash
   oc get mc 00-worker -o jsonpath='{.spec.config.ignition.version}{"\n"}'
   ```

---

## Diagnostics

```bash
# Pool health
oc get mcp
oc describe mcp worker

# Which MCs a pool has rendered
oc get mcp worker -o jsonpath='{.status.configuration.name}{"\n"}'

# Pending or failed nodes
oc get mcp worker -o jsonpath='{range .status.nodeStatuses[*]}{.nodeName}{" "}{.currentConfig}{" "}{.desiredConfig}{"\n"}{end}'

# MCO controller logs
oc logs -n openshift-machine-config-operator -l k8s-app=machine-config-controller --tail=50
```

**Degraded** usually means: pending MC not yet rendered, drain timeout (PDB, stuck pod), or node `NotReady`. Start with `oc describe mcp <name>` and `oc describe node <node>`.

---

## Examples in this repo

| Example | What it demonstrates |
|---------|---------------------|
| [`messaging/kafka/bare-metal-portworx/manifests/common/machineconfig-kafka-tuning.yaml`](../examples/messaging/kafka/bare-metal-portworx/manifests/common/machineconfig-kafka-tuning.yaml) | Optional worker-wide kernel/sysctl tuning (`role: worker`) — kafka example uses shared workers |
| [`gpu/machineconfig-iommu-intel.yaml`](../gpu/machineconfig-iommu-intel.yaml) | `role: worker` vs custom `gpu-worker` pool (comments) |
| [`troubleshooting/image-signature-policy-mcp-deadlock/signature-policy-machineconfig.yaml`](../troubleshooting/image-signature-policy-mcp-deadlock/signature-policy-machineconfig.yaml) | Duplicate MC for `master` and `worker` |
| [`troubleshooting/nvme-host-nqn-duplicate/99-worker-nvme-host-identity.yaml`](../troubleshooting/nvme-host-nqn-duplicate/99-worker-nvme-host-identity.yaml) | Worker-scoped file + systemd fix |

For Kafka-specific MCP implications (ISR, shared-cluster drain coupling), see the MCP section in [`messaging/kafka/bare-metal-portworx/README.md`](../examples/messaging/kafka/bare-metal-portworx/README.md).

---

## Further reading

- [OpenShift 4 — Machine configuration overview](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/machine_configuration/machine-config-index)
- [Creating custom machine config pools](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/machine_configuration/machine-config-custom-mcp)
- [Canary rollout via custom MCPs](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/updating_clusters/performing-a-cluster-update#update-using-custom-machine-config-pools) — section 3.4, *Performing a cluster update*
- [MCO custom pools design doc](https://github.com/openshift/machine-config-operator/blob/master/docs/custom-pools.md)

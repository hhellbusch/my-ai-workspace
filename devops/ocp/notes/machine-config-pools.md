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

### One role label per MachineConfig

Every `MachineConfig` carries exactly one pool-targeting label:

```yaml
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker   # single value only
```

The MCO does **not** support multiple `machineconfiguration.openshift.io/role` values on one `MachineConfig`. You cannot make one MC object target both `master` and `worker`, or both `worker` and a custom role.

### One pool per node

A node belongs to **at most one** MCP. Pool assignment is not symmetric:

- A node with both `worker` and a custom role label (e.g. `worker,infra`) is managed by the **custom pool** — custom pools take priority over the default `worker` pool.
- If you add a custom role label but **do not** create the matching MCP, the MCO still treats the node as a worker.
- A node with only a custom role label and **no** matching MCP is **unmanaged** by the MCO.

When creating a custom pool, label nodes with the custom role first (they may keep `worker` temporarily). Remove `node-role.kubernetes.io/worker` only when you want the node infra-only for scheduling — the custom pool still inherits worker MachineConfigs via `machineConfigSelector`.

The MCO errors when it cannot resolve a single pool (e.g. a node matches multiple custom pools, or edge cases like single-node dev clusters with conflicting roles). Design labels so each node resolves to exactly one pool.

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

4. **Drain blocked by unrelated PDB** — MCO must evict all pods on a node during drain. A misconfigured PDB on a co-located workload stalls the entire pool update.

5. **Conflicting MCs on the same path** — Within a rendered config, the MCO merges MCs in lexicographic name order; later names override earlier ones for the same field (e.g. `99-worker-foo` overrides `50-worker-foo`). Since **OCP 4.15+**, MCs targeting a custom pool role override worker-role MCs for the same field regardless of name order. Avoid defining the same path in both `worker` and custom roles unless you intend the custom value to win.

6. **Ignition version mismatch** — Match `spec.config.ignition.version` to the cluster. Check an existing MC:

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
| [`kafka-bare-metal-portworx/manifests/common/machineconfigpool-kafka-worker.yaml`](../examples/kafka-bare-metal-portworx/manifests/common/machineconfigpool-kafka-worker.yaml) | Custom pool with `[worker, kafka-worker]` selector |
| [`kafka-bare-metal-portworx/manifests/common/machineconfig-kafka-tuning.yaml`](../examples/kafka-bare-metal-portworx/manifests/common/machineconfig-kafka-tuning.yaml) | Pool-scoped kernel/sysctl tuning (`role: kafka-worker`) |
| [`gpu/machineconfig-iommu-intel.yaml`](../gpu/machineconfig-iommu-intel.yaml) | `role: worker` vs custom `gpu-worker` pool (comments) |
| [`troubleshooting/image-signature-policy-mcp-deadlock/signature-policy-machineconfig.yaml`](../troubleshooting/image-signature-policy-mcp-deadlock/signature-policy-machineconfig.yaml) | Duplicate MC for `master` and `worker` |
| [`troubleshooting/nvme-host-nqn-duplicate/99-worker-nvme-host-identity.yaml`](../troubleshooting/nvme-host-nqn-duplicate/99-worker-nvme-host-identity.yaml) | Worker-scoped file + systemd fix |

For Kafka-specific MCP implications (ISR, shared-cluster drain coupling), see the MCP section in [`kafka-bare-metal-portworx/README.md`](../examples/kafka-bare-metal-portworx/README.md).

---

## Further reading

- [OpenShift 4 — Machine configuration overview](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/machine_configuration/machine-config-index)
- [Creating custom machine config pools](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/machine_configuration/machine-config-custom-mcp)
- [Canary rollout via custom MCPs](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/updating_clusters/performing-a-cluster-update#update-using-custom-machine-config-pools) — section 3.4, *Performing a cluster update*
- [MCO custom pools design doc](https://github.com/openshift/machine-config-operator/blob/master/docs/custom-pools.md)

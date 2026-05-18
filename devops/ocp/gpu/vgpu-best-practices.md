# OpenShift + NVIDIA vGPU — Best Practices

> **Status: Work in Progress**
>
> This document is being built iteratively from operational experience and
> research. Sections marked **[TODO]** are placeholders for areas not yet
> worked through in detail. Sections marked **[DRAFT]** reflect current
> thinking that hasn't been validated against production at scale.
>
> Source material: `research/gpu-gitops-workflow/README.md`
> Related runbooks: `vgpu-a40-profiles.md`, `vgpu-node-labeling.md`
> GitOps templates: `devops/argo/examples/helm-component-pattern/components/nvidia-gpu-operator/`

---

## Table of Contents

1. [Profile Selection](#1-profile-selection)
2. [Node Architecture and Workload Segregation](#2-node-architecture-and-workload-segregation)
3. [Node Labeling Strategy](#3-node-labeling-strategy)
4. [GitOps Workflow](#4-gitops-workflow)
5. [Licensing](#5-licensing)
6. [Capacity Planning](#6-capacity-planning)
7. [Profile Change Management](#7-profile-change-management)
8. [Monitoring and Observability](#8-monitoring-and-observability)
9. [Security](#9-security)
10. [Known Gaps and Open Questions](#10-known-gaps-and-open-questions)

---

## 1. Profile Selection

### Naming convention

NVIDIA Q-series profile names encode **framebuffer size in GB**: `A40-8Q` = 8 GB per
vGPU slice. The number is GB, not slice count. Full A40 table and series breakdown in
[`vgpu-a40-profiles.md`](vgpu-a40-profiles.md).

### Choosing a profile size

Match framebuffer to the VM workload's GPU memory requirement, not to VM count targets.
Start with the workload requirement and derive density from it — not the other way around.

| Workload type | Typical framebuffer need | Recommended profile (A40) |
|--------------|------------------------|--------------------------|
| Light ML inference (small models) | 4–6 GB | A40-6Q (8 VMs) |
| Moderate ML inference / dev | 8 GB | A40-8Q (6 VMs) |
| Large model inference / training | 12–24 GB | A40-12Q or A40-24Q |
| Full GPU (large training, simulation) | 48 GB | A40-48Q (1 VM, passthrough preferred) |
| Virtual desktop / office GPU | 2–4 GB | A40-4Q or A40-2Q |
| App streaming (RDSH, Citrix) | 1–2 GB | A-series (different license tier) |

### Series selection (Q vs B vs A vs C)

All series with the same number have the same framebuffer — the series letter changes
workload optimization, FPS cap, and license requirement:

| Series | Use case | License |
|--------|---------|---------|
| **Q** | Virtual workstations — default for GPU-enabled VMs | vWS |
| **B** | Virtual desktops — lower FPS cap (45 vs 60), cheaper license | vPC |
| **A** | App streaming / RDSH — no per-VM display, console only | vApps |
| **C** | Compute only — no display output, CUDA/ML workloads | vCS |

**The GPU Operator only enables Q and C profiles by default.** B and A series may
require additional configuration. When in doubt, use Q-series — it's the broadest
compatibility profile.

### One profile per node (equal-size mode)

By default, all vGPU slices on a node use the same profile (equal-size mode). Mixed-size
mode (different profiles on the same GPU) is supported but adds scheduling complexity.
Start with equal-size; adopt mixed-size only when node density requirements demand it.

---

## 2. Node Architecture and Workload Segregation

### Hard rule: one workload type per node

A GPU worker node runs exactly one of:
- GPU-accelerated **containers** (standard datacenter driver)
- GPU **passthrough** VMs (VFIO manager)
- **vGPU** VMs (vGPU manager + device manager)

These cannot be mixed on the same node. The GPU Operator enforces this via the
`nvidia.com/gpu.workload.config` label:

| Label value | Node type | What deploys |
|------------|-----------|-------------|
| `container` (default) | GPU containers | Datacenter driver, device plugin |
| `vm-passthrough` | GPU passthrough VMs | VFIO manager, sandbox device plugin |
| `vm-vgpu` | vGPU VMs | vGPU manager, vGPU device manager, sandbox device plugin |

**Set this label before installing the GPU Operator on a node.** Changing it later
requires redeploying the relevant DaemonSets and rebooting the node.

### Bare metal is required for GPU VMs

GPU passthrough and vGPU require IOMMU, which requires bare metal nodes. Virtual
worker nodes (e.g., nested VMs on a hypervisor) cannot host GPU-assigned VMs.
GPU-accelerated containers do not have this restriction.

### IOMMU first

IOMMU must be enabled in both BIOS and the kernel (`intel_iommu=on` or
`amd_iommu=on`) before the GPU Operator's VM components can function. On OpenShift,
this is done via a MachineConfig, which triggers a rolling node reboot.

**Apply IOMMU MachineConfig in a maintenance window before enabling vGPU in the
ClusterPolicy.** The reboot order matters: IOMMU → GPU Operator vGPU components →
node labels → vGPU profile ConfigMap.

### SR-IOV for Ampere and later

A40 and newer GPUs use SR-IOV for vGPU (not legacy mediated device framework).
SR-IOV must be enabled in BIOS alongside IOMMU. The GPU Operator handles the
virtual function creation, but BIOS configuration is a pre-provisioning step.

---

## 3. Node Labeling Strategy [DRAFT]

Two labels must be on every vGPU node:

| Label | Value | Set by |
|-------|-------|--------|
| `nvidia.com/gpu.workload.config` | `vm-vgpu` | NFD rule, BMH, Ansible, or RHACM |
| `nvidia.com/vgpu.config` | e.g. `a40-8q` | NFD rule, BMH, Ansible, or RHACM |

### Recommended layering

```
NFD NodeFeatureRule  →  default profile for each GPU model (catch-all)
BMH nodeLabels       →  per-node overrides at provision time (if nodes in repo)
Ansible              →  profile change execution on live nodes
RHACM Policy         →  drift enforcement across clusters
```

**GitOps owns the desired state** (via `vgpu-node-profiles` ConfigMap); the
execution layer reads from it. Never treat manual `oc label` as the source of truth.

Full comparison of all methods: [`vgpu-node-labeling.md`](vgpu-node-labeling.md).

### NFD rule as the default

Write an NFD NodeFeatureRule that matches on PCI device ID and applies your
cluster's default profile. This covers nodes added outside the GitOps provisioning
flow (e.g., reprovisioned nodes, emergency replacements).

The NFD rule sets the baseline. BMH labels or Ansible can override specific nodes
that need a different profile.

---

## 4. GitOps Workflow [DRAFT]

### Group / cluster split

vGPU infrastructure is enabled at the **group layer** for all GPU clusters. Hardware-
specific configuration belongs at the **cluster layer**:

| Config | Layer | Reason |
|--------|-------|--------|
| `sandboxWorkloads`, `sandboxDevicePlugin`, `vgpuDeviceManager` | Group | Safe defaults, no hardware knowledge needed |
| `vgpuManager.enabled`, image, version | Cluster | NGC image is GPU-model and driver-version specific |
| `profiles` (A40-8Q, etc.) | Cluster | Hardware-specific |
| `licensing.vaultPath` | Cluster | Environment-specific NLS server |
| `nodeProfiles.assignments` | Cluster | Node-specific |

### Wave ordering for initial vGPU enablement

When enabling vGPU on a cluster for the first time, the sync-wave order matters.
These steps cannot all happen in a single ArgoCD sync:

```
External (pre-GitOps):
  1. BIOS: enable IOMMU + SR-IOV
  2. MachineConfig: apply IOMMU kernel parameters → rolling node reboot
  3. Vault: pre-provision NLS license secret

ArgoCD sync wave 0:   NFD operator
ArgoCD sync wave 5:   NFD instance (labels GPU nodes with hardware info)
ArgoCD sync wave 10:  GPU Operator subscription
ArgoCD sync wave 15:  ClusterPolicy with vGPU fields enabled
                       ESO ExternalSecret for NLS license (vgpu-license.yaml)
                       vGPU profile ConfigMap (vgpu-configmap.yaml)

External (post-sync):
  Ansible: apply nvidia.com/gpu.workload.config + nvidia.com/vgpu.config labels
           (or rely on NFD rule from wave 15)

ArgoCD sync wave 20+: VM workloads (VirtualMachine CRs, etc.)
```

### Profile changes in GitOps

A profile change (e.g., moving from A40-8Q to A40-6Q) is just a ConfigMap update —
but it has an operational gate: **VMs using the old profile must be stopped first**.

Recommended pattern:
1. PR updating `profiles.default` and `nodeProfiles.assignments` in cluster values
2. Merge → ArgoCD syncs ConfigMap
3. vGPU Device Manager detects the label change and waits for devices to free
4. **Separately**: drain VMs via Ansible or manual stop
5. vGPU Device Manager applies the new profile automatically once devices are free

The gap: ArgoCD has no native mechanism for gating a sync on "no running VMs with
GPU attached." This is an open question — see [Section 10](#10-known-gaps-and-open-questions).

---

## 5. Licensing [DRAFT]

### Use ESO, not pre-provisioned secrets

NLS license tokens are sensitive and cluster-specific. Store them in Vault and
sync via External Secrets Operator — the same pattern used for BMC credentials.

Vault path convention: `secret/fleet/nls/<cluster-name>`
Expected keys: `server` (NLS URL), `token` (base64-encoded `.tok` file content)

The ESO ExternalSecret is rendered by `vgpu-license.yaml` when
`vgpu.licensing.vaultPath` is set in the cluster values.

### Token lifecycle

NLS tokens are tied to NVIDIA AI Enterprise entitlements. When a token expires
or is rotated:
1. Upload the new token to Vault at the same path
2. ESO refreshes the Secret automatically (default: 1h refresh interval)
3. The GPU Operator driver picks up the new token on its next license check

**[TODO]** Confirm token refresh behavior with the GPU Operator — whether a driver
restart is needed on token rotation, or if it re-reads the Secret automatically.

### One license server, many clusters

If NLS is a shared service (one server for multiple clusters), the `server` key in
Vault will be the same across all clusters, but each cluster may have a separate
token. Structure Vault paths per-cluster even if the server URL is identical — it
keeps the ability to rotate tokens independently.

---

## 6. Capacity Planning [TODO]

> This section is not yet written. Key questions to answer:
>
> - How to size a GPU node pool for a given number of VM workloads
> - Rule-of-thumb headroom for driver overhead and non-vGPU processes
> - When to add GPUs vs when to adjust profile sizes
> - Impact of mixed-size mode on schedulable capacity
> - How to model VRAM requirements for ML inference workloads

---

## 7. Profile Change Management [DRAFT]

### The VM drain constraint

The vGPU Device Manager will not change a node's profile while any VM has a vGPU
device attached. It blocks silently — the label change is applied, but the Device
Manager waits. Operators may not realize nothing has changed until they check logs.

Always verify the profile change applied after draining VMs:

```bash
oc logs -n nvidia-gpu-operator -l app=nvidia-vgpu-device-manager --tail=50
oc get node <node> -o json | jq '.status.allocatable | to_entries[] | select(.key | startswith("nvidia.com/"))'
```

### Planning a profile change

Profile changes affect all VMs on a node — they require a coordinated outage window
for that node, not just the VMs being moved. Key steps:

1. **Announce** the maintenance window to VM owners on the target node
2. **Stop/migrate** all VMs on the node
3. **Update** the cluster values file (profile + node assignments)
4. **Merge** the PR → ArgoCD syncs the ConfigMap
5. **Verify** the Device Manager applied the new profile
6. **Restart** VMs with updated `deviceName` in the VirtualMachine spec
7. **Confirm** VMs see the new vGPU in-guest (`nvidia-smi` inside the VM)

### VirtualMachine spec must match the profile

When a node's profile changes, every VM scheduled on that node needs its `deviceName`
updated to match the new profile resource name:

```yaml
# Before (A40-8Q):
domain:
  devices:
    gpus:
      - deviceName: nvidia.com/A40-8Q
        name: gpu1

# After (A40-6Q):
domain:
  devices:
    gpus:
      - deviceName: nvidia.com/A40-6Q
        name: gpu1
```

If the VM spec still references the old profile, it will fail to schedule — the old
resource no longer exists in `allocatable`.

---

## 8. Monitoring and Observability [TODO]

> This section is not yet written. Key questions to answer:
>
> - Which DCGM metrics are most useful for vGPU utilization visibility
> - Per-VM GPU utilization (framebuffer used, compute utilization)
> - How to distinguish vGPU device metrics from physical GPU metrics
> - Alerting thresholds: when is a node under/over-subscribed?
> - Dashboard patterns (Grafana, OpenShift monitoring stack)
> - How to correlate vGPU metrics with Prometheus/DCGM exporter

---

## 9. Security [TODO]

> This section is not yet written. Key questions to answer:
>
> - vGPU isolation guarantees between VMs (framebuffer isolation, compute isolation)
> - What happens if a VM crashes — does it release the vGPU device cleanly?
> - NLS token exposure — who has access to the Vault path?
> - NGC pull secret management (vgpuManager image pull)
> - Node-level access: can a VM guest access host GPU memory outside its slice?
> - Audit logging for vGPU device assignment

---

## 10. Known Gaps and Open Questions

These are unresolved design questions as of the current state of this work.
They feed the next iteration of this document.

### Operations

- **VM drain gate in GitOps**: There is no native ArgoCD mechanism to pause a sync
  until "no VMs are using vGPU on this node." Options under consideration: pre-sync
  hook Job that checks VMI status, manual approval gate in the ApplicationSet, or
  accepting that this step is always Ansible-mediated.

- **Mixed-size mode**: Running A40-8Q and A40-6Q devices on the same GPU simultaneously.
  NVIDIA supports this but the vGPU Device Manager ConfigMap format and node label
  semantics for mixed-size are not yet worked through in this repo's templates.

- **Token rotation behavior**: Unclear whether the GPU Operator driver re-reads the
  NLS Secret automatically on rotation or requires a DaemonSet restart.

### Architecture

- **Heterogeneous GPU clusters**: Clusters with A40s and A100s on different nodes.
  The NFD rule auto-labels by PCI device ID — this is clean. The question is how to
  manage separate profile ConfigMaps and whether the ClusterPolicy handles mixed GPU
  models transparently.

- **VFIO + vGPU on same cluster**: Some nodes doing passthrough, others doing vGPU.
  The GPU Operator supports this via `gpu.workload.config` labels, but the ClusterPolicy
  and values schema in this repo currently assumes one mode per cluster.

### Documentation

- **Capacity planning numbers**: No validated data yet on VRAM overhead per vGPU
  instance, driver reservation, or the practical upper limit on vGPU density before
  scheduling latency degrades.

- **Guest driver installation**: The in-VM NVIDIA vGPU guest driver installation is
  documented as a manual step. A standard mechanism for automating this (e.g., cloud-init,
  Ansible, a custom VM image) is not yet defined.

---

## Related

- [`vgpu-a40-profiles.md`](vgpu-a40-profiles.md) — A40 profile reference and runbook
- [`vgpu-node-labeling.md`](vgpu-node-labeling.md) — node label methods
- [`devops/argo/examples/helm-component-pattern/components/nvidia-gpu-operator/`](../../argo/examples/helm-component-pattern/components/nvidia-gpu-operator/README.md) — GitOps templates
- [`docs/ai-engineering/openshift-gpu-node-management.md`](../../../docs/ai-engineering/openshift-gpu-node-management.md) — full GPU node management guide
- [`research/gpu-gitops-workflow/README.md`](../../../research/gpu-gitops-workflow/README.md) — gap analysis that feeds this document
- [NVIDIA Grid vGPU User Guide](https://docs.nvidia.com/vgpu/latest/grid-vgpu-user-guide/)
- [NVIDIA GPU Operator + OpenShift Virtualization](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/openshift-virtualization.html)

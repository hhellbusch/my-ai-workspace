# GPU/GitOps Workflow — Research

**Purpose:** Assess current state of GPU management in the GitOps framework, identify gaps between deployed infrastructure and operational realities (vGPU profiles, licensing, VM specs, node labeling). Feeds a future best-practices document for OpenShift + NVIDIA vGPU management.

**Status:** In progress
**Output:** (pending — this assessment feeds the best-practices doc)

---

## 1. What We Have — Current State

### 1.1 Infrastructure Deployment

The GPU Operator stack is deployed via ArgoCD with a well-structured Helm-component pattern:

| Layer | Template | Location |
|-------|----------|----------|
| NFD operator | Subscription + OLM install | `components/nvidia-gpu-operator/operator/` |
| NFD instance | NodeFeatureDiscovery CR | `groups/gpu-enabled/values.yaml` |
| GPU Operator | Subscription + OLM install | `components/nvidia-gpu-operator/operator/` |
| ClusterPolicy | GPU driver, DCGM, MIG | `components/nvidia-gpu-operator/instance/` |
| Fleet rollout | ApplicationSet with non-prod → prod steps | `framework/hub/applicationsets/nvidia-gpu-operator.yaml` |
| Site overrides | Per-cluster driver version, MIG config | `clusters/site-gpu-1/values.yaml` |

The operator targets only GPU-labeled nodes (via NFD or `baremetal-hosts` app). InstallPlan approval defaults to Manual for production, Automatic for non-production. Upgrade safety is enforced: `maxParallelUpgrades: 1` by default.

### 1.2 What This Covers

- GPU hardware detection (NFD)
- Driver lifecycle management
- Device plugin registration
- DCGM metrics collection
- GPU driver upgrade strategy (rolling, one node at a time)
- MIG partitioning (for A100/H100 on OCP 4.20+)

### 1.3 What It Does Not Cover

The ClusterPolicy template has **zero vGPU-specific fields**. No vGPU Manager, no vGPU Device Manager, no licensing ConfigMap, no node labels for vGPU profiles, no VM GPU specs.

---

## 2. The vGPU Gap

vGPU management is a configuration problem, not a deployment problem. Once the GPU Operator is running, managing vGPU profiles is about:

1. **vGPU profiles** — which slice sizes (A40-8Q, A40-6Q, etc.) to create on which nodes
2. **Licensing** — NLS ConfigMap with license server credentials
3. **Node labeling** — `nvidia.com/vgpu.config=<profile>` per node
4. **VM specs** — `deviceName: nvidia.com/A40-8Q` in VirtualMachine CRs
5. **Profile changes** — the "stop VMs first" constraint

None of these are represented in the current ArgoCD/Helm templates. The ClusterPolicy template renders driver, toolkit, devicePlugin, dcgmExporter, gfd, nodeStatusExporter, sandboxWorkloads, and mig — but not vgpuManager, vgpuDeviceManager, vfioManager, or sandboxDevicePlugin.

### 2.1 Missing Templates

| Template | Status | Needs |
|----------|--------|-------|
| `vgpu-configmap.yaml` | ❌ | vGPU Device Manager ConfigMap (profiles) |
| `vgpu-node-labeler.yaml` | ❌ | Node labeling for vGPU profiles |
| `nmstate-machineconfig.yaml` | ❌ | IOMMU kernel parameter (required before vGPU) |
| `clusterpolicy.yaml` | ⚠️ | vGPU fields (vgpuManager, vgpuDeviceManager, etc.) |

### 2.2 Missing Values Sections

| Values file | Status | Needs |
|-------------|--------|-------|
| `groups/gpu-enabled/values.yaml` | ⚠️ | `vgpu.enabled`, profile definitions, node labels |
| `clusters/<name>/values.yaml` | ❌ | Per-cluster vGPU profile assignments |

### 2.3 Licensing

NLS licensing is a prerequisite for vGPU but has no template or Secret management in the repo. The GPU Operator expects a ConfigMap with license server credentials — this must be managed separately (ArgoCD Secret, external secrets, etc.).

---

## 3. What's Missing — The Open Questions

### 3.1 Architecture

- **How do we distinguish vGPU nodes from GPU-passthrough nodes?** The GPU Operator uses `nvidia.com/gpu.workload.config=vm-vgpu` vs `vm-passthrough` — but the current template has no mechanism for this.
- **Should vGPU configuration be a separate component** (like nfd-instance) or part of nvidia-gpu-operator-instance?
- **What about mixed-size mode?** NVIDIA docs describe GPU modes where different vGPU profiles can coexist on the same GPU — this adds complexity to node labeling.

### 3.2 GitOps Workflow

- **How do we handle the "stop VMs first" constraint?** A ConfigMap change in ArgoCD will trigger vGPU Device Manager to tear down devices. If VMs are using them, it blocks. Do we need:
  - A pre-sync hook that checks for running VMs?
  - A manual approval gate in the ApplicationSet?
  - A separate "profile change" workflow that's not part of the standard sync?
- **What's the rollout order for vGPU?** IOMMU MachineConfig → GPU Operator vGPU fields → vGPU ConfigMap → node labels → VM GPU specs. Each step requires node reboots or VM migrations. How do we sequence this in ArgoCD?

### 3.3 Operations

- **How do we manage license changes?** If the NLS server URL changes, the ConfigMap needs updating. Is this handled by ArgoCD or external?
- **What about profile rotation?** If you want to shift from A40-8Q to A40-6Q (more VMs, less VRAM), you change the ConfigMap — but this is a cluster-wide change on the node. Do you need per-node ConfigMaps?
- **What monitoring exists for vGPU utilization?** DCGM Exporter collects GPU metrics, but vGPU-specific metrics (per-VM GPU utilization, framebuffer utilization) need separate investigation.

### 3.4 Documentation

- **No "vGPU best practices" doc exists.** No Red Hat blog, no NVIDIA guide, no community resource covers OpenShift + vGPU management end-to-end. This research aims to fill that gap.
- **Current runbook** (`devops/ocp/gpu/vgpu-a40-profiles.md`) covers A40 profiles and configuration commands but not GitOps integration or operational strategy.

---

## 4. Related Work

| Repo/Dir | What it covers | vGPU coverage |
|----------|---------------|---------------|
| `devops/ocp/gpu/` | Operational YAMLs for GPU Operator | ❌ No vGPU ConfigMaps, no node labels |
| `devops/argo/examples/helm-component-pattern/components/nvidia-gpu-operator/` | ClusterPolicy + OLM subscription | ⚠️ Driver/MIG only, no vGPU fields |
| `devops/argo/examples/framework/apps/nvidia-gpu-operator/` | Fleet-wide GPU operator deployment | ⚠️ No vGPU |
| `devops/argo/examples/framework/hub/applicationsets/nvidia-gpu-operator.yaml` | Non-prod → prod rollout | ⚠️ No vGPU |
| `docs/ai-engineering/openshift-gpu-node-management.md` | GPU node management guide | ✅ vGPU section (manual commands) |
| `devops/ocp/gpu/vgpu-a40-profiles.md` | A40 vGPU profile runbook | ✅ Profile mapping, commands, troubleshooting |
| `research/nvidia-gpu-operator-ocp418/` | Installation impact analysis | ⚠️ Mentions vGPU Manager but no operational workflow |
| `research/openshift-gpu/` | NVIDIA GPU Operator + OCP Virt sources | ✅ Raw source material (scraped) |

---

## 5. Proposed Next Steps

1. **Draft vGPU template additions** — ClusterPolicy fields, ConfigMap, node labels (this assessment feeds this)
2. **Document the GitOps workflow** — how profile changes, IOMMU config, and VM specs fit into the existing ArgoCD sync waves
3. **Write best-practices document** — capacity planning, licensing strategy, profile lifecycle, monitoring
4. **Create ArgoCD templates** — implement the patterns from step 1 in the Helm-component structure

---

## 6. Open Questions

- [ ] Is vGPU configuration better as a separate component or part of nvidia-gpu-operator-instance?
- [ ] How do we handle the "stop VMs first" constraint in a GitOps workflow?
- [ ] What's the optimal sequence for IOMMU MachineConfig → ClusterPolicy update → ConfigMap → node labels?
- [ ] Do we need per-node ConfigMaps (one per profile) or a single ConfigMap with per-node selectors?
- [ ] How do we manage NLS licensing ConfigMaps across clusters?
- [ ] What vGPU-specific metrics should we monitor in DCGM/Prometheus?
- [ ] Should there be a "vGPU-enabled" group that enables vGPU fields in ClusterPolicy?

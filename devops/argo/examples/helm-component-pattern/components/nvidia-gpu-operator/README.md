# Component: nvidia-gpu-operator

GitOps component for deploying and configuring the NVIDIA GPU Operator on
bare-metal OpenShift clusters via the Helm-component pattern.

Split into two sub-charts following the operator/instance pattern:

| Sub-chart | Purpose |
|-----------|---------|
| `operator/` | OLM Subscription — installs the GPU Operator via OperatorHub |
| `instance/` | ClusterPolicy CR — configures driver, DCGM, MIG, vGPU behavior |

---

## Templates

### operator/
- OLM Subscription + OperatorGroup for the GPU Operator (`gpu-operator-certified`)

### instance/
| Template | What it renders |
|----------|----------------|
| `namespace.yaml` | `nvidia-gpu-operator` namespace |
| `clusterpolicy.yaml` | ClusterPolicy CR — driver, toolkit, devicePlugin, DCGM, MIG, vGPU |
| `vgpu-configmap.yaml` | vGPU Device Manager ConfigMap (profiles) — gated by `vgpu.enabled` |
| `vgpu-license.yaml` | ExternalSecret for NLS license token from Vault — gated by `vgpu.licensing.vaultPath` |
| `vgpu-nfd-rule.yaml` | NFD NodeFeatureRule for auto-labeling GPU nodes — gated by `vgpu.nfdRule.enabled` |
| `vgpu-node-labels.yaml` | Informational ConfigMap of node → profile assignments |

---

## GPU Modes

Three modes are supported, configured by enabling the relevant section in
`instance/values.yaml`. Modes are mutually exclusive per node — a node runs
one workload type only.

| Mode | Values key | Use case |
|------|-----------|---------|
| Time-slicing (default) | `devicePlugin.enabled: true` | Containers sharing GPU time |
| MIG partitioning | `mig.enabled: true` | Isolated GPU instances (A100/H100, OCP 4.20+) |
| vGPU | `vgpu.enabled: true` | GPU slices for OpenShift Virtualization VMs |

---

## vGPU Configuration

vGPU is opt-in. The group layer enables infrastructure components;
the cluster layer provides hardware-specific profile and licensing config.

**Group layer** (`groups/gpu-enabled/values.yaml`) enables:
- `sandboxWorkloads`, `sandboxDevicePlugin`, `vgpuDeviceManager`

**Cluster layer** (`clusters/<name>/values.yaml`) must provide:
- `vgpu.vgpuManager` — NGC image and version
- `vgpu.profiles` — profile name → vGPU type + count per GPU
- `vgpu.licensing.vaultPath` — Vault path for NLS token (creates ExternalSecret)
- `vgpu.nfdRule.gpuProfiles` — PCI device IDs for auto-labeling (optional)
- `vgpu.nodeProfiles.assignments` — node → profile map (informational)

See `clusters/site-a40-vgpu-1/values.yaml` for a complete A40 example.

### Node labeling

The `nvidia.com/vgpu.config` label on each node tells the vGPU Device Manager
which profile to create. Four methods are documented in
[`devops/ocp/gpu/vgpu-node-labeling.md`](../../../../../ocp/gpu/vgpu-node-labeling.md):

- **BMH nodeLabels** — applied at provision time (preferred when nodes are in this repo)
- **NFD NodeFeatureRule** — continuous, hardware-based auto-labeling (`vgpu-nfd-rule.yaml`)
- **RHACM ConfigurationPolicy** — continuous drift enforcement
- **Ansible** — post-provision or profile change execution

---

## Related

- [`devops/ocp/gpu/`](../../../../../ocp/gpu/) — operational YAMLs and runbooks
- [`devops/ocp/gpu/vgpu-a40-profiles.md`](../../../../../ocp/gpu/vgpu-a40-profiles.md) — A40 profile reference
- [`devops/ocp/gpu/vgpu-node-labeling.md`](../../../../../ocp/gpu/vgpu-node-labeling.md) — node label methods
- [NVIDIA GPU Operator + OpenShift Virtualization](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/openshift-virtualization.html)
- [NVIDIA Grid vGPU User Guide](https://docs.nvidia.com/vgpu/latest/grid-vgpu-user-guide/)

# Checkpoint — 2026-05-18

**In progress:** OpenShift + NVIDIA vGPU GitOps framework — building out
the full automation stack for A40 vGPU management on bare-metal OCP with
ArgoCD, ESO/Vault, and OpenShift Virtualization.

**Just completed (this session):**
- `vgpu-drain-check.yaml` — ArgoCD PreSync hook that blocks sync if any VMI
  has a GPU device attached; SA + ClusterRole + CRB at wave -2, Job at wave -1;
  all `BeforeHookCreation`; gated by `vgpu.drainCheck.enabled` (default true)
- `vgpu-best-practices.md` — 11-section best practices doc (WIP); §6/8/9 are
  TODO placeholders; §11 covers VM drain gate options and Windows guest driver
  installation approaches
- `machineconfig-iommu-intel.yaml` / `machineconfig-iommu-amd.yaml` — reference
  MachineConfigs for IOMMU enablement; include BIOS prerequisites, MachineConfigPool
  targeting guidance, verification commands
- `components/nvidia-gpu-operator/README.md` — component-level docs for the
  operator/instance split, all templates, GPU modes, vGPU group/cluster split
- All prior session work: ClusterPolicy vGPU fields, profile ConfigMap, ESO license,
  NFD rule, node labels, example cluster (site-a40-vgpu-1), group defaults,
  A40 profile runbook, node labeling reference

**Git state:** 72e8556 — clean, pushed to origin/main

---

## One known gap remaining

**NGC pull secret** — `vgpuManager` pulls its image from `nvcr.io/nvidia`, which
requires authentication. The values schema has the image reference but nothing
handles the pull secret. This will fail on first deploy with an ImagePullBackOff.

Recommended approach: same ESO pattern as the NLS license —
`secret/fleet/ngc/<cluster-name>` in Vault, ExternalSecret creates a
`kubernetes.io/dockerconfigjson` Secret, referenced in ClusterPolicy
`imagePullSecrets`. New template: `vgpu-ngc-pullsecret.yaml`.

---

## Key files

| File | What |
|------|------|
| `devops/ocp/gpu/vgpu-best-practices.md` | Master reference — start here |
| `devops/ocp/gpu/vgpu-a40-profiles.md` | A40 profile runbook |
| `devops/ocp/gpu/vgpu-node-labeling.md` | Node label methods |
| `devops/ocp/gpu/machineconfig-iommu-intel.yaml` | IOMMU MachineConfig (Intel) |
| `devops/ocp/gpu/machineconfig-iommu-amd.yaml` | IOMMU MachineConfig (AMD) |
| `components/nvidia-gpu-operator/instance/templates/vgpu-drain-check.yaml` | PreSync drain gate |
| `components/nvidia-gpu-operator/instance/templates/vgpu-license.yaml` | ESO NLS license |
| `components/nvidia-gpu-operator/instance/values.yaml` | Full vGPU values schema |
| `clusters/site-a40-vgpu-1/values.yaml` | Complete A40 cluster example |
| `groups/gpu-enabled/values.yaml` | vGPU enabled at group layer |

All paths relative to `devops/argo/examples/helm-component-pattern/` except
the `devops/ocp/gpu/` files which are at repo root.

---

## Key decisions made

- **Profile naming**: A40 number = framebuffer GB (A40-8Q = 8 GB, 6 VMs per GPU)
- **vGPU at group layer**: Infrastructure components safe to enable group-wide;
  `vgpuManager` stays false at group (NGC image is cluster-specific)
- **Licensing via ESO**: `secret/fleet/nls/<cluster-name>` in Vault
- **Drain gate**: Option B (PreSync hook) implemented as default; cluster-wide check,
  not node-specific — blocks if any VMI has GPU device attached
- **IOMMU**: Apply MachineConfig before GPU Operator vGPU components; triggers
  rolling node reboot via MCO — this is a pre-GitOps maintenance window step
- **Windows guest driver**: Four approaches documented (golden image, cloudbase-init,
  Ansible+WinRM, SCCM/Intune); none selected — deferred to later

## Still TODO in best practices

- §6 Capacity planning — needs real hardware data
- §8 Monitoring/DCGM — needs ops experience with the stack
- §9 Security — vGPU isolation guarantees; needs NVIDIA security doc review

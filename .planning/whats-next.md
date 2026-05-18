# Checkpoint — 2026-05-18

**In progress:** OpenShift + NVIDIA vGPU GitOps framework — complete for
first iteration. One known deploy-blocking gap remains.

**Just completed (this session):**

*vGPU framework:*
- `vgpu-drain-check.yaml` — ArgoCD PreSync hook blocking sync when VMIs have GPU devices
- `vgpu-best-practices.md` — 11-section doc (WIP); §11 covers drain gate options and Windows guest driver approaches
- `machineconfig-iommu-intel.yaml` / `machineconfig-iommu-amd.yaml` — IOMMU prereq artifacts
- `components/nvidia-gpu-operator/README.md` — component-level docs

*Meta / harness:*
- `AGENTS.md` — Project Brief Threshold rule (5+ files, multi-session, new dir, scope expansion)
- `.agents/skills/brief/SKILL.md` — new skill scaffolding BRIEF.md + whats-next.md
- `.agents/skills/start/SKILL.md` — brief gap check added to minimal mode
- Zanshin extension — checkpoint threshold now nudges for missing brief alongside checkpoint reminder
- Commit-guard redesigned — diff embedded in `block.reason` (no user-visible messages); Gate 0 blocks `git add && git commit` compound calls with a clear split instruction

**Git state:** 039df3b — clean, pushed to origin/main

---

## One known gap remaining

**NGC pull secret** — `vgpuManager` pulls from `nvcr.io/nvidia`, which
requires authentication. No pull secret mechanism exists in the templates.
First deploy will fail with ImagePullBackOff.

Recommended approach: same ESO pattern as the NLS license.
- Vault path: `secret/fleet/ngc/<cluster-name>` (or a shared `secret/fleet/ngc/shared`)
- Keys: `username` (typically `$oauthtoken`), `password` (NGC API key)
- ExternalSecret creates a `kubernetes.io/dockerconfigjson` Secret
- ClusterPolicy references it via `imagePullSecrets`
- New template: `vgpu-ngc-pullsecret.yaml`, gated by `vgpu.vgpuManager.enabled`

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

## Key decisions

- **Profile naming**: A40 number = framebuffer GB (A40-8Q = 8 GB, 6 VMs per GPU)
- **vGPU at group layer**: Infrastructure components safe to enable group-wide; `vgpuManager` stays false (NGC image is cluster-specific)
- **Licensing via ESO**: `secret/fleet/nls/<cluster-name>` in Vault
- **Drain gate**: PreSync hook (Option B) implemented; cluster-wide VMI check; disable via `vgpu.drainCheck.enabled: false` for non-profile syncs
- **IOMMU**: MachineConfig is a pre-GitOps maintenance window step — triggers rolling node reboot
- **Windows guest driver**: Four approaches documented in §11.2; none selected — deferred
- **Commit-guard**: Diff in block.reason (agent-space only); Gate 0 enforces split add/commit calls

## Still TODO in best practices

- §6 Capacity planning — needs real hardware data
- §8 Monitoring/DCGM — needs ops experience
- §9 Security — vGPU isolation guarantees

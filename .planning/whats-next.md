# Checkpoint — 2026-05-14

**In progress:** paude fork — ADC→proxy migration implemented, needs a real session build to verify.

**Just completed (this session):**

*paude fork (`hhellbusch/paude` `develop`):*
- Removed `PAUDE_VERTEX_AUTH_MODE` machinery (direct/proxy toggle, three functions, constants) from `shared.py`
- Replaced the old Vertex bearer-relay block in `containers/proxy/entrypoint.sh` with `GCP_ADC_JSON` handling — writes ADC to `/tmp/gcp-adc.json`, adds gcloud injector entry for `.googleapis.com`, exports `GOOGLE_APPLICATION_CREDENTIALS` for paude-proxy
- Updated `agents/pi.py` comments to reflect stub ADC model
- Removed corresponding tests from `test_shared.py`
- Pushed to `hhellbusch/paude` `develop`, submodule pointer updated

*zanshin-pi-extension:*
- Fixed commit-guard `sendUserMessage` mid-turn race — added `{ deliverAs: "followUp" }` to avoid "Agent is already processing" runtime error
- Pi package cache updated; `/reload` in next session picks it up

*Planning / backlog:*
- Scoping doc: `.planning/paude-integration/findings/2026-05-13-adc-proxy-migration-scope.md`
- Two backlog seeds added: "three-context gap" case study and "git as memory / detective work" case study

**Git state:** 99d9494 — clean, pushed to origin/main

---

## One thing needed from you

**Test the paude ADC migration** — requires a host-side build and new Pi+vertex session:
1. `cd` into your paude fork, `git pull` (or it's already at `develop` tip)
2. Build the paude image (`make build` or equivalent)
3. Launch a Pi+vertex session: `paude create --agent pi --provider vertex <name>`
4. Watch proxy logs for: `GCP ADC credential injection: ENABLED (.googleapis.com)` and `TOKEN_VEND host=oauth2.googleapis.com`
5. Confirm Vertex AI calls succeed (try a simple prompt in Pi)

If the proxy log shows the injection line but calls fail, check that `GOOGLE_CLOUD_LOCATION=global` resolves correctly — the endpoint will be `global-aiplatform.googleapis.com` which the `.googleapis.com` suffix pattern covers.

---

# Previous checkpoint — 2026-05-18

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

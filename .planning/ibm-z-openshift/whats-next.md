# What's next — IBM Z / LinuxONE OpenShift

*Handoff from 2026-07-22 session (updated).*

## Decision

**CIM-driven ABI on LPAR** with existing ACM hub.  
Runbook: [cim-abi-lpar.md](../../devops/ocp/ibm-z/cim-abi-lpar.md)

## Done

- `devops/ocp/ibm-z/` domain — mental model, provisioning, LPAR path comparison
- AOP code review + fork meta-analysis
- Fork: Phase 1 (`hcp_approve_agent`, etc.) + Phase 2a (`lpar_hipersockets_bastion`, `AGENTS.md`, `FORK.md`)
- [lpar-install-paths.md](../../devops/ocp/ibm-z/lpar-install-paths.md) — UPI/ABI/HCP trade-offs
- [cim-abi-lpar.md](../../devops/ocp/ibm-z/cim-abi-lpar.md) — hub CRs + AOP boot runbook

## Next actions

| Priority | Action |
|----------|--------|
| 1 | **Hub audit** — [cim-hub-setup.md](../../devops/rhacm/notes/cim-hub-setup.md) |
| 2 | **Push fork** — `git push origin refactor/phase-1-dry` |
| 3 | **Hub CRs** — ClusterDeployment + AgentClusterInstall + InfraEnv (`cpuArchitecture: s390x`) |
| 4 | **Configure `acm:` in inventory** + `host_vars` for each LPAR node |
| 5 | **Run** `playbooks/acm_abi_boot_lpar.yaml` on bastion |
| 6 | **Approve agents** on hub; watch `AgentClusterInstall` |

## Fork refactor focus (ABI + CIM)

- **Do:** `boot_LPAR`, ABI playbooks, `lpar_hipersockets_bastion`, #475 disk hints
- **Defer:** `boot_LPAR_hcp`, HCP KubeVirt, z/VM roles

## Suggested artifacts

| Priority | Artifact | Why |
|----------|----------|-----|
| High | `acm-on-s390x.md` | Version matrix, multi-arch hub notes |
| Medium | `networking-day1.md` | ~~OSA vs HiperSockets~~ → [lpar-networking-osa-vs-hipersockets.md](../../devops/ocp/ibm-z/lpar-networking-osa-vs-hipersockets.md) |
| Medium | Example GitOps bundle for Z InfraEnv | If hub is GitOps-driven |
| Low | `zcx-zos.md` | Only if z/OS colocation needed |

## Decisions

| Item | Choice |
|------|--------|
| Install path | CIM-driven ABI LPAR |
| Hub | Connected |
| Topology | **HA** (3 CP + workers) |
| LPAR networking | **Generic** — OSA or HiperSockets per host at lab time |

## Open questions

1. OSA vs HiperSockets for your specific CPC layout — see [lpar-networking-osa-vs-hipersockets.md](../../devops/ocp/ibm-z/lpar-networking-osa-vs-hipersockets.md)
2. Corporate proxy on hub install path (only if `ImageCreated` fails)

## Staleness

Re-check OCP / MCE version matrix when applying ImageSet names in runbook examples.

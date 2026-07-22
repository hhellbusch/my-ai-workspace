# What's next — IBM Z / LinuxONE OpenShift

*Handoff from 2026-07-22 session.*

## Done this session

- Created `devops/ocp/ibm-z/` domain with README, mental model, provisioning/automation guide, references
- Cross-linked from `devops/README.md` and `devops/ocp/README.md`

## Open questions to validate

1. **GitOps ZTP on s390x** — any supported `ClusterInstance` templates for Z, or strictly x86 BMC?
2. **ACM standalone cluster create** — full `AgentClusterInstall` flow on Z with current RHACM/MCE versions (doc version matrix)
3. **zCX for OpenShift** — worth a dedicated guide if z/OS integration is in scope
4. **Lab path** — no public s390x sandbox; document minimum hardware / partner lab options?

## Suggested next artifacts

| Priority | Artifact | Why |
|----------|----------|-----|
| High | `install-paths.md` | Compare LPAR vs z/VM vs RHEL KVM vs ABI step-by-step |
| High | `acm-on-s390x.md` | Import, Agent provisioning, hosted control planes — version matrix |
| Medium | `networking-day1.md` | OSA, bonding, VLAN-over-bond, HiperSockets — the Z-specific pain |
| Medium | Cross-link to `devops/rhacm/` | Fleet management angle once ACM guide exists |
| Low | `zcx-zos.md` | Only if z/OS colocation is a reader need |

## Staleness

Re-check Red Hat OCP 4.22+ and MCE 2.17+ docs when expanding hosted control planes content.

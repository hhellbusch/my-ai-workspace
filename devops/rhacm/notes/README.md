---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
---

# RHACM Notes

Informal RHACM quick references and working notes. These are operational references — configurations, port requirements, patterns used regularly — not structured troubleshooting guides (those live in `rhacm/troubleshooting/`).

## Contents

- **[networking-requirements-2.16.md](networking-requirements-2.16.md)** — Required network connectivity between the ACM hub cluster and managed clusters (ports, directions, situational requirements) based on ACM 2.16 docs
- **[acm-bare-metal-network-requirements.md](acm-bare-metal-network-requirements.md)** — ACM CIM bare-metal install: ports by phase (discovery, Ironic, hub import), blocked-port symptoms, generic firewall rule templates; doc-verified against OCP 4.20 + MCE + ACM 2.16
- **[search-setup.md](search-setup.md)** — First-time setup for RHACM Search: enabling the hub service, deploying the per-cluster collector addon, and verifying results
- **[production-readiness.md](production-readiness.md)** — Production hub checklist: search PVC, cluster backup, infra nodes, availability config, OLM approval, observability, sizing. Audit commands and effort/risk summary table.
- **[cim-hub-setup.md](cim-hub-setup.md)** — Enable CIM / Assisted Installer on the hub for on-prem cluster provisioning: `AgentServiceConfig`, `Provisioning` CR, corporate proxy, mirror/`osImages`, verification
- **[agent-install-preflight.md](agent-install-preflight.md)** — Preflight orchestration for ACM agent-based installs: ClusterCurator prehooks, Assisted Installer validations, agent approval gates, external pipelines
- **[bare-metal-cluster-destroy.md](bare-metal-cluster-destroy.md)** — RHACM/MCE destroy vs detach for bare-metal clusters; BMO deprovision vs full disk wipe; ClusterCurator destroy hooks
- **[greenfield-fleet-architecture.md](greenfield-fleet-architecture.md)** — Default stack and phased adoption for a new fleet: ACM + GitOps first, when to add AAP/AWX
- **[acm-ansible-integration.md](acm-ansible-integration.md)** — Native ACM→Ansible paths (ClusterCurator, PolicyAutomation, subscriptions), AAP vs AWX, prerequisites
- **[fleet-ad-hoc-data-gathering.md](fleet-ad-hoc-data-gathering.md)** — Strategies for host-level and API-level diagnostics across managed clusters (no fleet exec in ACM)
- **[bare-metal-lifecycle-hook-patterns.md](bare-metal-lifecycle-hook-patterns.md)** — Implementation patterns for preflight, BMH discovery, and install gates (AAP + ClusterCurator, Go, operators, CI) with pros/cons and examples
- **[../git-driven-configuration.md](../git-driven-configuration.md)** — RHACM hub and governance resources in Git; same PR/promotion flow as Argo CD; rebuild-from-scratch posture

## Adding New Notes

When adding a new note:
1. Use a descriptive filename with kebab-case
2. Link it from this README
3. If it grows into a full troubleshooting guide, move it to `rhacm/troubleshooting/` with the standard symptom → cause → fix structure

*AI-assisted content. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for review status details.*

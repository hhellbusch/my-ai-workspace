# ACM — Dell Gen17 / iDRAC10 — Agent-Based Install

> **Status:** In Progress
> **Started:** 2026-07-02
> **Owner:** hhellbusch

## Audience and Purpose

**Reader:** Platform engineer troubleshooting ACM bare-metal provisioning on Dell Gen17 hardware.
**Enables:** Scope boundary for collaborative troubleshooting; anchor for journal entries and eventual runbook / case study artifacts.

## Problem Statement

Provision OpenShift on Dell PowerEdge Gen17 servers (iDRAC10 BMC) through ACM using the Agent-Based Installer (ABI). Gen17 / iDRAC10 is new hardware; workspace has prior Dell bare-metal troubleshooting (iDRAC9-era, BMO/IPI) but nothing specific to Gen17 or iDRAC10. Goal is evidence-based progression from current failure state to successful cluster provision.

## Scope

- ACM hub prerequisites (CIM, `AgentServiceConfig`, networking, proxy/mirror)
- ABI workflow: manifest generation, boot media delivery, agent discovery, install orchestration
- Dell Gen17 / iDRAC10 specifics: Redfish virtual media, BMC addressing, firmware, console plugin settings
- Network path: install hosts ↔ hub assisted services
- Hardware discovery / validation failures on new-generation Dell platforms

**Out of scope (for now):**

- Post-install day-2 (policies, GitOps fleet layout) unless blocking provision
- Non-Dell hardware in the same cluster
- IPI with provisioning network / Metal³ day-0 (unless ABI path is abandoned)

## Success Criteria

- [ ] Hosts boot ABI media and register as `Agent` CRs on the ACM hub
- [ ] `AgentClusterInstall` requirements met; install proceeds without manual workarounds
- [ ] Cluster reaches `Provisioned` / importable in ACM
- [ ] Reproducible notes captured (journal → troubleshooting guide or case study)

## Constraints

- Dell Redfish virtual media: use `idrac-virtualmedia://` — not `redfish-virtualmedia://` (see OCP bare-metal IPI docs; applies to virtual-media boot patterns)
- OCP 4.20+ release notes: iDRAC10 tested for **IPI virtual media** on firmware 1.20.25.00, 1.20.60.50, 1.20.70.50 — **not tested with provisioning network**
- iDRAC virtual console plugin: HTML5 (not eHTML5) — known issue on earlier iDRAC generations; verify on iDRAC10
- Workspace prior Dell bare-metal session used Mellanox NIC inspection issues — watch for similar on Gen17

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Working artifact | Engineering journal in `.planning/acm-dell-gen17-abi/JOURNAL.md` | Session-persistent evidence log before polished docs |
| Install path | **ACM CIM / Assisted** — `InfraEnv` discovery ISO, `Agent` CRs, `AgentClusterInstall` | Confirmed 2026-07-02 |
| Leading hypothesis | ~~Proxy/cert~~ → **refined:** firewall blocking **Ironic install-phase** traffic (TCP 9999, 6385) | Network team observing drops on 9999/6385 while nodes boot |

## Related

- [cim-hub-setup.md](../../devops/rhacm/notes/cim-hub-setup.md) — hub CIM prerequisites
- [BARE-METAL-OPERATOR-INTEGRATION.md](../../devops/rhacm/examples/BARE-METAL-OPERATOR-INTEGRATION.md) — ACM bare-metal CR workflow
- [agent-install-rootfs-ssl-failure.md](../../devops/rhacm/troubleshooting/agent-install-rootfs-ssl-failure.md) — early-boot hub connectivity
- [bare-metal-node-inspection-timeout](../../devops/ocp/troubleshooting/bare-metal-node-inspection-timeout/) — prior Dell + Mellanox BMO session (Dec 2025)
- [OCP 4.20 release notes — iDRAC10](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/release_notes/ocp-4-20-release-notes)
- [Assisted Installer — booting discovery image (Redfish virtual media)](https://docs.redhat.com/en/documentation/assisted_installer_for_openshift_container_platform/2026/html/installing_openshift_container_platform_with_the_assisted_installer/assembly_booting-hosts-with-the-discovery-image)

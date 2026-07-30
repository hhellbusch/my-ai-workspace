# Bare Metal Dev Sandbox — Per-Developer Workspace PoC

> **Status:** In Progress
> **Started:** 2026-07-02

## Audience and Purpose

**Reader:** Platform engineer developing ACM bare-metal / BMC automation without dedicated hardware per developer.
**Enables:** Scope boundary for a fidelity-tiered sandbox PoC; anchor for iteration toward a reusable per-developer workspace pattern.

## Problem Statement

ACM + bare metal + iDRAC automation is hard to develop safely when each developer cannot own a dedicated node. Ambler-style sandboxes ([Development Sandboxes](https://agiledata.org/essays/sandboxes.html)) assume separable environments, but physical BMC-backed hosts are scarce. We need a **per-developer workspace** that validates automation locally (Redfish contract, Ansible playbooks) before promoting to shared hardware pools.

## Scope

**In scope (PoC v1):**

- Fidelity **Tier 0–1**: static/dynamic Redfish BMC emulation for per-developer automation work
- Reuse existing workspace Ansible patterns (`community.general.redfish_*`, Dell OpenManage where applicable)
- Document emulation boundary vs production Dell iDRAC behavior
- Runnable artifacts under `devops/bare-metal-dev-sandbox/`
- Promotion gate model (G0–G4) as design doc, implemented through README + CI-friendly checks

**Out of scope (PoC v1):**

- Shared ACM CIM hub provisioning (Tier 2+) — referenced, not built
- Full ABI discovery ISO → `Agent` registration on KVM (Phase 3+ spike)
- Hardware pool scheduler / reservation system
- Dell-proprietary `idrac-virtualmedia://` URI emulation fidelity
- Production deployment of multi-tenant lab infrastructure

## Success Criteria

- [ ] Developer can start a local Redfish BMC endpoint with one documented command
- [ ] Existing Redfish Ansible patterns run against the sandbox without code changes (or with documented vars only)
- [ ] `devops/bare-metal-dev-sandbox/README.md` states what is validated vs what still needs real iron
- [ ] Emulation gap list captured (production BMC deltas vs sushy)
- [ ] Phase 1 SUMMARY documents verify steps and blockers for Phase 2

## Constraints

- Prefer **free/open-source** tooling: sushy-tools, podman, libvirt where available
- Host may lack libvirt — static emulator must work without it; dynamic emulator is optional Phase 3
- Align with existing workspace Ansible Redfish examples under `devops/ansible/examples/`

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Project slug | `bare-metal-dev-sandbox` | Portable sandbox PoC, separate from live troubleshooting briefs |
| First fidelity tier | Static Redfish (sushy-static) | Runnable without libvirt or hardware |
| Artifact home | `devops/bare-metal-dev-sandbox/` | Matches workspace devops convention |
| BMC emulator | sushy-tools (`quay.io/metal3-io/sushy-tools`) | Metal³ ecosystem standard; same stack BMO CI uses |
| Per-dev isolation model | Logical BMC endpoint per developer (port/instance), not physical node | Resource constraint we're designing around |

## Related

- [004_validate_virtual_media_ejection](../../devops/ansible/examples/004_validate_virtual_media_ejection/) — Redfish Ansible patterns
- [sushy-tools dynamic emulator](https://docs.openstack.org/sushy-tools/latest/user/dynamic-emulator.html)
- [Ambler — Development Sandboxes](https://agiledata.org/essays/sandboxes.html)

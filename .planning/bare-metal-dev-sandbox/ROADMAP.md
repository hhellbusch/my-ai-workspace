# Roadmap: Bare Metal Dev Sandbox PoC

## Overview

Progressive fidelity tiers for per-developer bare metal automation workspaces. Each phase adds capability without requiring dedicated physical nodes. Phase 1 must run on a laptop with podman only.

## Fidelity tiers (target state)

| Tier | Validates | PoC phase |
|------|-----------|-----------|
| G0 | Lint, schema, playbook syntax | Phase 1 (ansible --syntax-check) |
| G1 | Redfish client ops vs emulated BMC | Phase 1–2 |
| G2 | ACM CR apply against dev hub | Out of PoC v1 |
| G3 | Discovery boot → Agent registered | Phase 4 spike |
| G4 | Full install on physical bare metal | Shared pool (not built here) |

## Phases

- [x] **Phase 1: Static Redfish sandbox** — sushy-static + minimal fixtures; Ansible smoke test
- [ ] **Phase 2: iDRAC characterization fixtures** — record/replay real Redfish responses (when hardware available)
- [ ] **Phase 3: Dynamic sushy + libvirt** — virtual BMC controlling KVM domains
- [ ] **Phase 4: ABI boot-chain spike** — discovery ISO via emulated virtual media (feasibility only)

## Phase Details

### Phase 1: Static Redfish sandbox
**Goal:** One-command local Redfish endpoint; prove Ansible redfish modules talk to it.
**Depends on:** Nothing
**Plans:** 1 plan

Plans:
- [x] 01-01: Scaffold `devops/bare-metal-dev-sandbox/`, static mockup tree, podman start script, smoke playbook

**Verify:**
- `curl http://127.0.0.1:8000/redfish/v1/` returns JSON
- `ansible-playbook smoke-redfish.yml` completes against sandbox inventory

**Key questions:**
- Which Redfish paths do our playbooks actually hit?
- Does `community.general.redfish_info` work against sushy-static mockups?
- What's the minimum fixture set for virtual media operations?

### Phase 2: iDRAC characterization fixtures
**Goal:** Capture real iDRAC10 Redfish responses as versioned fixtures; diff against sushy.
**Depends on:** Phase 1 (fixture layout established); access to a production-class BMC for characterization
**Plans:** 1 plan

Plans:
- [ ] 02-01: Characterization script + fixture README + gap matrix (sushy vs iDRAC10)

### Phase 3: Dynamic sushy + libvirt
**Goal:** Power cycle and boot-order changes affect a real libvirt domain.
**Depends on:** Phase 1; host with libvirt (`qemu:///system`)
**Plans:** 1 plan

Plans:
- [ ] 03-01: Dynamic emulator config, UEFI test domain, power/boot playbook loop

### Phase 4: ABI boot-chain spike
**Goal:** Document whether discovery ISO → Agent registration is feasible via emulated BMC + KVM.
**Depends on:** Phase 3; optional shared ACM dev hub
**Plans:** 1 plan

Plans:
- [ ] 04-01: Spike doc with pass/fail criteria; no production automation unless spike succeeds

## Milestone

**v1.0 (PoC complete):** Phases 1–2 done, Phase 3 attempted or documented as blocked, README is the handoff artifact for the team.

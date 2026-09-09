# AAP / Ansible SDLC — Peer draft

> **Status:** In Progress
> **Started:** 2026-09-09

## Audience and Purpose

**Reader:** The author, when deciding what to share next and what to implement after peer feedback.
**Enables:** Scope boundary for a discussion draft + example tree; not a production CaC rollout.

## Problem Statement

AAP CaC as practiced (CoP template, product folders, apply-only dispatch) covers the controller.
It does not join playbook releases, experiment isolation, or teardown of either AAP objects or the VMs/clusters those jobs create.
Peers need a concrete shape to react to — product folders, no env branches — before anyone restructures a live CaC repo.

## Scope

**In scope:**

- Peer-facing note under `devops/ansible/aap-sdlc/`
- Example tree that shows durable product CaC, experiment manifests (not copies), per-AAP inventories, and teardown order
- A localhost preview playbook that prints the rewritten object lists (no live AAP required)
- QA companion: tools, human/agent inner loop, GitHub/GitLab stubs

**Out of scope:**

- Wiring `infra.aap_configuration.dispatch` against a real controller
- Tag-cut → CaC MR bot
- `object_diff` / exclusive-mode implementation
- Changing any live customer CaC repository
- Research drawer of fetched Red Hat blogs (cite original URLs from the note)

## Success Criteria

- [ ] A peer can read `devops/ansible/aap-sdlc/README.md` without the rest of this workspace
- [ ] `ansible-playbook` on the preview playbook shows experiment org + feature-branch pin without copying durable YAML
- [ ] A peer new to QA can name which tool answers which question (lint vs Molecule vs lab job)

## Constraints

- Match existing CaC layout: **product folders**, not `config/dev|qa|prod`
- No Git env branches
- Prefer templating `organization` / `scm_revision` over copy-paste of durable lists
- JBGE: shape and argument, not a second CoP template

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Home | `devops/ansible/aap-sdlc/` | Practitioner reference + example, not a `docs/` essay |
| Isolation | Org-per-experiment in the example | Strongest GC given apply-only CaC |
| Env split | Inventory / group_vars per AAP | Product YAML stays one tree |
| Preview | Debug rewritten lists | Peers can run something without an AAP |

## Related

- [Ambler — Development Sandboxes](https://agiledata.org/essays/sandboxes.html)
- [redhat-cop/aap_configuration_template](https://github.com/redhat-cop/aap_configuration_template)
- [devops/ansible/aap-sdlc/README.md](../../devops/ansible/aap-sdlc/README.md)

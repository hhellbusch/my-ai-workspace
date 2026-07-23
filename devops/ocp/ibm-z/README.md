---
description: OpenShift on IBM Z and LinuxONE — vocabulary, deployment paths, provisioning automation
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
---

# OpenShift on IBM Z and LinuxONE

Reference material for OpenShift Container Platform on **s390x** — IBM Z, zSystems, and LinuxONE.
Built for peers who know x86 OpenShift or mainframe operations but not how the two intersect.

> **Audience:** Platform engineers and architects evaluating or operating OCP on s390x
> **Purpose:** Shared vocabulary, correct automation choices, and curated external sources to iterate on
> **Status:** Early draft — see [.planning/ibm-z-openshift/whats-next.md](../../../.planning/ibm-z-openshift/whats-next.md) for gaps

---

## Start here

| Guide | What you get |
|-------|----------------|
| [mental-model.md](mental-model.md) | Vocabulary (HMC, LPAR, z/VM, zCX), where OCP runs, deployment topology map |
| [lpar-install-paths.md](lpar-install-paths.md) | **UPI vs ABI vs HCP on LPAR** — trade-offs and ACM alignment |
| [cim-abi-lpar.md](cim-abi-lpar.md) | **CIM-driven ABI LPAR** — runbook (hub CRs + AOP boot); chosen path |
| [lpar-networking-osa-vs-hipersockets.md](lpar-networking-osa-vs-hipersockets.md) | OSA vs HiperSockets — generic day-1 networking primer |
| [provisioning-and-automation.md](provisioning-and-automation.md) | ACM, Metal3/Ironic, Agent-based install, Ansible — what works on Z and what does not |
| [ansible-openshift-provisioning-review.md](ansible-openshift-provisioning-review.md) | Code review of IBM AOP — DRY debt, remediation phases |
| [ansible-openshift-provisioning-fork.md](ansible-openshift-provisioning-fork.md) | Fork workflow and Phase 1 refactor status |
| [ansible-openshift-provisioning-forks-meta.md](ansible-openshift-provisioning-forks-meta.md) | Meta-analysis of ~65 GitHub forks — patterns, risks, contribution strategy |
| [references.md](references.md) | Canonical external docs, Redbooks, IBM Community posts |

---

## One-paragraph summary

OpenShift on IBM Z runs **Linux on s390x**, not z/OS.
Installs are **user-provisioned** (`platform: none`) — there is no x86-style installer-provisioned bare metal path.
**Metal3/Ironic/Bare Metal Operator do not provision LPARs.**
**ACM** helps via import, policy, and the **Assisted/Agent** installer path; **hosted control planes on Z** are supported in current OCP/MCE releases.
**HMC + PXE/PRM boot** (or IBM's Ansible provisioning project) sit below the OpenShift installer.

---

## Related in this repo

- [Disconnected install (Quay + oc-mirror)](../disconnected-install/) — mirror registry and `oc-mirror` workflow; relevant for air-gapped Z/ABI installs
- [Agent install preflight](../../rhacm/notes/agent-install-preflight.md) — ACM hub orchestration for agent-based installs
- [Fleet control spectrum](../../fleet-control-spectrum.md) — RHACM vs Argo CD when managing Z clusters from a hub
- [RHACM](../../rhacm/README.md) — hub setup, CIM, cluster import patterns
- [SNO KVM lab](../examples/labs/sno-kvm-lab/README.md) — conceptual parallel for the RHEL KVM-on-LPAR path (x86, different networking model)
- [KVM / libvirt](../../kvm/README.md) — host-side virtualization patterns on Fedora (not s390x-specific)

---

## Contributing / iterating

Project brief: [.planning/ibm-z-openshift/BRIEF.md](../../../.planning/ibm-z-openshift/BRIEF.md)

When adding guides, update this table and `references.md`.
Flag unverified claims inline — this domain is actively being explored.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

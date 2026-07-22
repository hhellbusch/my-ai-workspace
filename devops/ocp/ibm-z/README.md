---
description: OpenShift on IBM Z and LinuxONE — vocabulary, deployment paths, provisioning automation
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
| [provisioning-and-automation.md](provisioning-and-automation.md) | ACM, Metal3/Ironic, Agent-based install, Ansible — what works on Z and what does not |
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
- [SNO KVM lab](../examples/sno-kvm-lab/README.md) — conceptual parallel for the RHEL KVM-on-LPAR path (x86, different networking model)
- [KVM / libvirt](../../kvm/README.md) — host-side virtualization patterns on Fedora (not s390x-specific)

---

## Contributing / iterating

Project brief: [.planning/ibm-z-openshift/BRIEF.md](../../../.planning/ibm-z-openshift/BRIEF.md)

When adding guides, update this table and `references.md`.
Flag unverified claims inline — this domain is actively being explored.

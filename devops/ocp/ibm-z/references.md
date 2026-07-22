---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
---

# External references — OpenShift on IBM Z and LinuxONE

> **Audience:** Anyone extending this domain's guides
> **Purpose:** Canonical sources to verify against; prefer these over blog summaries when details matter

---

## Red Hat — install and platform

| Resource | URL | Notes |
|----------|-----|-------|
| Installing on IBM Z and LinuxONE (current) | https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/installing_on_ibm_z_and_ibm_linuxone/ | LPAR, z/VM, KVM paths; `platform: none` |
| Agent-based Installer | https://docs.openshift.com/container-platform/latest/installing/installing_with_agent_based_installer/preparing-to-install-with-agent-based-installer.html | s390x PXE vs ISO constraints |
| Hosted control planes — requirements | https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/hosted_control_planes/preparing-to-deploy-hosted-control-planes | Multi-arch matrix; IBM Z section |
| Implement multi-arch OCP with s390x LPAR (Red Hat Developer) | https://developers.redhat.com/learning/learn:openshift:implement-multi-architecture-openshift-cluster-s390x-lpar | LPAR boot, PRM, ignition |

---

## IBM — product and supported stack

| Resource | URL | Notes |
|----------|-----|-------|
| RHOCP on IBM Z docs hub | https://www.ibm.com/docs/en/rhocp-ibm-z | Supported operators/add-ons on s390x |
| zCX Foundation for Red Hat OpenShift | https://www.ibm.com/products/zcx-openshift | OCP on z/OS via zCX — separate path |
| Ansible-OpenShift-Provisioning | https://ibm.github.io/Ansible-OpenShift-Provisioning/ | HMC → LPAR → KVM → OCP |
| LinuxONE + RHOCP solution brief | https://www.ibm.com/downloads/documents/us-en/107a02e959c8f4bc | Business/availability positioning |

---

## IBM Redbooks and Redpapers

| Resource | URL | Notes |
|----------|-----|-------|
| OpenShift on zSystems and LinuxONE Cookbook (redp5711) | https://www.redbooks.ibm.com/redpapers/pdfs/redp5711.pdf | Architecture, deployment options, best practices (July 2024) |
| OpenShift Container Platform for IBM zCX (sg248528) | https://www.redbooks.ibm.com/redbooks/pdfs/sg248528.pdf | z/OS integration depth |

---

## Community posts (practical walkthroughs)

| Resource | URL | Notes |
|----------|-----|-------|
| ABI on s390x — bonding/VLAN (Neeraj Mishra, Feb 2026) | https://community.ibm.com/community/user/blogs/neeraj-mishra/2026/02/23/networking-with-bond-vlan-and-vlan-over-bond | Networking-first ABI; HMC boot steps |
| LPAR install for OpenShift Virtualization (Dominik Werle, Aug 2025) | https://community.ibm.com/community/user/blogs/dominik-werle/2025/08/07/openshift-on-ibm-z-installation-on-lpar-for-rhocpv | HA LPAR topology for RHOCV |

---

## RHACM / MCE

| Resource | URL | Notes |
|----------|-----|-------|
| Hosted control planes on IBM Z (OKD doc — architecture detail) | https://docs.okd.io/latest/hosted_control_planes/hcp-deploy/hcp-deploy-ibmz.html | InfraEnv s390x, LPAR agent steps |
| SiteConfig / ClusterInstance (RHACM 2.15+) | https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/multicluster_engine_operator_with_red_hat_advanced_cluster_management/siteconfig-intro | x86 BMC-centric; verify before Z use |
| GitOps ZTP | https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/edge_computing/ztp-deploying-far-edge-sites | Edge bare-metal model |

---

## In this repo

| Resource | Path |
|----------|------|
| Domain index | [README.md](README.md) |
| Mental model | [mental-model.md](mental-model.md) |
| LPAR install paths (UPI/ABI/HCP) | [lpar-install-paths.md](lpar-install-paths.md) |
| CIM ABI LPAR runbook | [cim-abi-lpar.md](cim-abi-lpar.md) |
| Provisioning and automation | [provisioning-and-automation.md](provisioning-and-automation.md) |
| AOP code review | [ansible-openshift-provisioning-review.md](ansible-openshift-provisioning-review.md) |
| AOP fork workflow | [ansible-openshift-provisioning-fork.md](ansible-openshift-provisioning-fork.md) |
| AOP fork meta-analysis | [ansible-openshift-provisioning-forks-meta.md](ansible-openshift-provisioning-forks-meta.md) |
| **Fork `AGENTS.md`** | https://github.com/hhellbusch/Ansible-OpenShift-Provisioning/blob/refactor/phase-1-dry/AGENTS.md |
| RHACM notes | [devops/rhacm/README.md](../../rhacm/README.md) |

---

## Staleness note

Re-check OCP and MCE version matrices when adding hosted-control-plane or ACM provisioning content.
IBM Z hardware support (z17, LinuxONE 5) may require minimum OCP patch levels — confirm in the current install guide before citing version numbers in new guides.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

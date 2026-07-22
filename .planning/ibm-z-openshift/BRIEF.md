# IBM Z / LinuxONE OpenShift Reference

> **State:** Active — initial domain scaffold, iterating with research
> **Started:** 2026-07-22

## Organizing question

How does OpenShift on IBM Z and LinuxONE actually work — vocabulary, deployment paths, and what automation (ACM, Metal3, Ansible) can and cannot do?

## Audience

Platform engineers and architects learning or evaluating OpenShift on s390x — peers who know x86 OpenShift or mainframe ops but not the intersection.

## What this enables

- Shared vocabulary when discussing Z/LinuxONE with RHACM, install, or mainframe teams
- Correct tool choice (Agent/ABI vs Metal3 vs Ansible vs zCX) before design commitments
- **CIM-driven ABI LPAR** runbook against existing hub infra
- Iteration surface: gaps and open questions live in `whats-next.md`

## Decision (2026-07-22)

**Install path:** CIM-driven **ABI on LPAR** with **connected** ACM hub. **Topology:** HA.

**Runbook:** [`cim-abi-lpar.md`](../../devops/ocp/ibm-z/cim-abi-lpar.md)  
**Infra automation:** private [AOP fork](https://github.com/hhellbusch/Ansible-OpenShift-Provisioning) for HMC/LPAR boot — not upstream PRs.

## Scope

**In:** `devops/ocp/ibm-z/` reference material — mental model, provisioning paths, external links.

**Out (for now):** Hands-on lab runbooks, z/OS zCX deep dive, RHOAI on s390x, Ansible playbook forks.

## Home

[`devops/ocp/ibm-z/README.md`](../../devops/ocp/ibm-z/README.md)

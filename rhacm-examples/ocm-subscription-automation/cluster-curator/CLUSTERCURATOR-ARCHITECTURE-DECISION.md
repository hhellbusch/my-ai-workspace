# ClusterCurator Architecture Decision

**Context**: Bare metal OpenShift clusters provisioned by Ansible (AAP), registered into RHACM, handed off to ArgoCD  
**Question**: Would ClusterCurator simplify this architecture?  
**Last Updated**: March 2026

---

## Current Architecture

```
AAP Ansible
├── Create cluster
├── Create BareMetalHosts (workers)
├── Provision Portworx storage
└── Bootstrap playbook
    ├── Register cluster into RHACM
    └── Hand off to ArgoCD
```

---

## The Core Question: Who Provisions the Cluster?

This is the architectural fork in the road. ClusterCurator's pre/post hooks are **designed to wrap Hive/Assisted Installer provisioning**. If Ansible is still the provisioner, ClusterCurator only helps on the edges.

```
Current:                              With ClusterCurator (fully):

AAP Ansible                           RHACM/Hive
├── Creates cluster          vs       ├── ClusterDeployment (provisions cluster)
├── Creates BareMetalHosts            ├── AgentClusterInstall
├── Provisions Portworx               └── ClusterCurator
└── Bootstrap → RHACM → ArgoCD           ├── prehook: AAP job (BareMetalHosts, network)
                                          ├── [Hive installs cluster]
                                          └── posthook: AAP job (Portworx, OCM, RHACM import)
                                                              → ArgoCD
```

---

## Honest Assessment

### Where ClusterCurator Helps (even now)

| Benefit | Detail |
|---|---|
| **AAP already deployed** | The hardest part of ClusterCurator setup is already done |
| **Single lifecycle record** | The `ClusterCurator` CRD in Git is a declarative record of what ran and when |
| **RHACM console visibility** | Hook status shows in the RHACM UI alongside cluster status |
| **Upgrade/destroy hooks** | Once set up, upgrade and decommission automation comes for free |
| **No custom trigger needed** | RHACM watches `ClusterCurator` — no external job trigger required |

### Where ClusterCurator Does Not Help (given current setup)

| Limitation | Detail |
|---|---|
| **Ansible creates the cluster** | ClusterCurator prehooks assume Hive is the provisioner — Ansible cluster creation sits outside this model |
| **Not a drop-in replacement** | Cluster provisioning must migrate to Hive/Assisted Installer to get full value |
| **More CRDs to manage** | `ClusterDeployment` + `AgentClusterInstall` + `InfraEnv` + `ClusterCurator` vs. one Ansible playbook |
| **BareMetalHost creation** | Currently Ansible does this — it would need to move to a prehook job template |

---

## Two Realistic Paths

### Path A — Minimal Change (Recommended for Now)

Keep the current architecture. Add OCM subscription as a task in the existing bootstrap playbook.

```
AAP Ansible (unchanged)
├── Create cluster
├── Create BareMetalHosts
├── Provision Portworx
└── Bootstrap playbook
    ├── Register into RHACM
    ├── Set OCM subscription  ← add this
    └── Hand off to ArgoCD
```

**Effort**: Low. **Risk**: None. **Benefit**: Immediate.

See [`../set-ocm-subscription.sh`](../set-ocm-subscription.sh) and [`../README.md`](../README.md) for the Ansible tasks to add.

---

### Path B — Full ClusterCurator Adoption (Future Architecture)

Migrate cluster provisioning to RHACM/Hive. Ansible becomes purely pre/post hook work called by ClusterCurator via AAP.

```
Git (GitOps)
└── ClusterDeployment + AgentClusterInstall + InfraEnv + ClusterCurator
        │
        ▼
RHACM Hub
├── ClusterCurator prehook → AAP Job Template: "pre-install"
│   ├── Validate DNS/network
│   ├── Configure NMState (static IPs)
│   ├── Reserve IPs in IPAM
│   └── Create CMDB record
│
├── Hive/Assisted Installer provisions cluster
│   └── BareMetalHosts created by installer
│
└── ClusterCurator posthook → AAP Job Template: "post-install"
    ├── Provision Portworx storage    ← moves here
    ├── Set OCM subscription          ← moves here
    ├── Configure LDAP auth
    ├── Notify teams
    └── ArgoCD picks up via RHACM label/annotation
```

**Effort**: Significant (weeks, not hours). **Risk**: Requires re-testing provisioning flow. **Benefit**: RHACM becomes the true control plane with a single pane of glass and GitOps-native cluster lifecycle.

---

## What Actually Gets Simpler in Path B

| Today | Path B |
|---|---|
| AAP job templates | AAP job templates (fewer, more focused) |
| Custom Ansible trigger mechanism | Git commit to cluster repo (ArgoCD syncs) |
| Playbook sequencing logic | ClusterCurator CRD (declarative) |
| Error recovery in playbook | RHACM UI shows hook status |
| "What stage is this cluster at?" | `ClusterCurator.status` tells you |

The biggest simplification is **removing the custom trigger mechanism** — whatever currently kicks off AAP for a new cluster. In Path B, a Git commit with the cluster manifests is the trigger, and RHACM/ArgoCD/ClusterCurator handle the rest.

---

## Recommendation

**Right now**: Add OCM subscription to the bootstrap playbook. One task block, zero architectural change.

**If evaluating Path B**: Validate on one non-production cluster first:
1. Convert provisioning to Hive/Assisted Installer
2. Create a `ClusterCurator` resource pointing at existing AAP job templates
3. Validate Portworx + OCM subscription + ArgoCD handoff all work via hooks
4. Standardize across all clusters once proven

**Key question to answer first**: Is the current Ansible cluster creation calling the Assisted Installer API, or is it fully custom (e.g., IPI with a static `install-config.yaml`)? If Assisted Installer is already being used, the migration to Hive is much smaller — Hive wraps the same Assisted Installer under the hood.

---

## Related Files

- [`../README.md`](../README.md) — OCM CLI and standalone script documentation
- [`../set-ocm-subscription.sh`](../set-ocm-subscription.sh) — Automation script
- [`./README.md`](./README.md) — ClusterCurator deep-dive with full CRD examples

---

## AI Disclosure

This document was created with AI assistance as part of DevOps automation research and documentation efforts.

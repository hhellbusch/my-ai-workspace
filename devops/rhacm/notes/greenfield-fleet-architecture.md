---
review:
  status: unreviewed
  notes: "AI-generated 2026-08-03. Synthesizes fleet-control-spectrum, RHACM examples, and ACM+AAP integration research for new fleet design."
---

# Greenfield Fleet Architecture — ACM, GitOps, and Ansible

> **Audience:** Platform architects standing up a new OpenShift fleet from scratch with RHACM on the hub.
> **Purpose:** Default technology choices and phased adoption — what to install first, what to defer, and where Ansible fits.

---

## Default posture

For a new fleet in 2026, a workable default is **GitOps-first with Ansible at the edges**:

```text
Git (source of truth)
       │
       ├── OpenShift GitOps (Argo CD)  — apps, platform charts, ZTP SiteConfigs
       ├── RHACM                       — provision, inventory, policies, placements
       └── (optional) AWX / AAP        — external systems + lifecycle hooks only
```

This aligns with the **center** position on [fleet-control-spectrum.md](../../fleet-control-spectrum.md): ACM for mandates and lifecycle, Argo for delivery.

**Not a license decision** — you can run ACM without AAP and Argo without Ansible.
Each tool owns a class of work; overlap is resolved by picking **one controller per resource kind**.

---

## Phase 1 — Core platform (no Ansible required)

### Hub stack

| Component | Role |
|-----------|------|
| **RHACM** (+ MCE, bundled since 2.5) | Fleet inventory, provisioning, governance |
| **OpenShift GitOps** | Application and platform delivery from Git |
| **Search** (default) | Fleet-wide resource discovery — [search-setup.md](search-setup.md) |
| **Cluster Proxy** + **ManagedServiceAccount** | Hub→spoke API when needed |

### Provisioning

Choose one primary path:

| Environment | Typical path |
|-------------|--------------|
| Bare metal / edge at scale | GitOps ZTP — `SiteConfig` + `PolicyGenTemplate` via Argo |
| Hub-driven on-prem | ACM CIM — [cim-hub-setup.md](cim-hub-setup.md) |
| Import existing clusters | Git-managed `ManagedCluster` + bootstrap — [CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md](../examples/CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md) |

Let **ACM/Hive/CIM provision** clusters.
Do not use Ansible as the primary cluster creator unless you accept losing ClusterCurator’s native lifecycle model — see [CLUSTERCURATOR-ARCHITECTURE-DECISION.md](../examples/ocm-subscription-automation/cluster-curator/CLUSTERCURATOR-ARCHITECTURE-DECISION.md).

### Day 1 / Day 2 configuration

| Concern | Owner |
|---------|-------|
| Platform operators, monitoring baseline | Argo CD (fleet repo / ApplicationSets) |
| Mandates (OAuth, kubelet, labels, pull secrets) | ACM Policies + PolicyGenerator in Git — [git-driven-configuration.md](../git-driven-configuration.md) |
| Secrets | ESO and/or ACM secret policies — [secret-management](../examples/secret-management/README.md) |
| Targeting | `ManagedCluster` labels → Placement + Argo cluster generator |

### What you can skip in Phase 1

- AAP / AWX
- ACM Applications (subscriptions) — use Argo CD
- PolicyAutomation
- ClusterCurator (until lifecycle hooks to external systems are defined)

---

## Phase 2 — Add automation controller at the edges (optional)

Introduce **AWX** (FOSS) or **AAP** (supported) when you can name **specific external integrations**:

| Trigger | Mechanism | Example |
|---------|-----------|---------|
| Post-install / post-upgrade | `ClusterCurator` posthook | OCM subscription, CMDB |
| Policy violation → external action | `PolicyAutomation` | ServiceNow, DNS update |
| Jinja + external data at provision time | AAP renders CRs → Git or hub apply | Redfish, Vault, IPAM → `AgentClusterInstall` |

Install **AAP Resource Operator** on hub (or dedicated cluster).
See [acm-ansible-integration.md](acm-ansible-integration.md) and hook implementation patterns in [bare-metal-lifecycle-hook-patterns.md](bare-metal-lifecycle-hook-patterns.md).

**Skip AAP** if:

- All post-provision work is Kubernetes objects (GitOps + policies suffice)
- External work is handled by CI (Tekton, GitHub Actions) on git events
- Fleet is small and `ansible-core` playbooks from CI are enough

---

## Phase 3 — Fleet operations maturity

| Maturity need | Tool |
|---------------|------|
| Ad-hoc host diagnostics (`nvme discover`, node data) | Ansible + `oc debug` per cluster — [fleet-ad-hoc-data-gathering.md](fleet-ad-hoc-data-gathering.md) |
| Repeatable fleet checks | Git-reviewed Job/DaemonSet via ManifestWork |
| Compliance evidence | ACM governance dashboard + policies in Git |
| Blue-green cluster upgrades | ACM provision new cluster + Argo migrate workloads — [library: RHACM + AAP talk](../../../library/automate-ocp-cluster-deployment-rhacm-aap.md) |

---

## Decision trees

### Do we need Ansible at all?

```
Any work that must touch systems OUTSIDE the Kubernetes API
when a cluster is born, upgraded, or goes non-compliant?
│
├─ NO  → Phase 1 only (ACM + GitOps)
│
└─ YES → Need enterprise support + audit UI for automation?
          ├─ YES → AAP + Resource Operator (minimal hooks)
          └─ NO  → AWX + Resource Operator, or CI + ansible-core
```

### ACM vs Argo for this concern?

Use the worksheet in [fleet-control-spectrum.md — Per-concern placement](../../fleet-control-spectrum.md#per-concern-placement-worksheet).

Quick rules:

- **Team app config** → Argo
- **Platform mandate** → ACM policy
- **Cluster birth/death** → ACM (CIM, ZTP, Curator)
- **External ticket/DNS on policy event** → PolicyAutomation → AAP
- **Fleet node shell command** → Neither natively — external Ansible or ManifestWork Job

---

## Anti-patterns for greenfield

| Avoid | Why |
|-------|-----|
| Ansible as sole cluster provisioner | Duplicates Hive/CIM; Curator hooks misaligned |
| ACM Applications for app delivery | Argo CD is the modern path |
| AAP “just in case” | Resource Operator, credentials, template quirks — operational cost |
| PolicyAutomation for K8s fixes | Use policy `enforce` first |
| Dual ownership of same object | Argo + ACM fighting over one `OAuth` or `Subscription` |
| Assuming fleet-wide `exec` in ACM | Use [fleet-ad-hoc-data-gathering.md](fleet-ad-hoc-data-gathering.md) patterns |

---

## Reference architecture diagram

```text
                    ┌─────────────────────────────────────┐
                    │  Git (fleet repo)                    │
                    │  · SiteConfig / policies / apps      │
                    └──────────────┬──────────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              ▼                    ▼                    ▼
        Argo CD              RHACM Hub           (optional)
        · ApplicationSets    · CIM / ZTP          AWX / AAP
        · Platform charts    · Policies           · Job Templates
        · Values cascade     · Placement          · Resource Operator
              │                    │                    │
              └────────────┬───────┴────────────────────┘
                           ▼
                    Managed clusters (spokes)
```

---

## Related reading

| Topic | Location |
|-------|----------|
| ACM ↔ Ansible integration detail | [acm-ansible-integration.md](acm-ansible-integration.md) |
| Bare metal hook patterns (preflight, BMH, Go) | [bare-metal-lifecycle-hook-patterns.md](bare-metal-lifecycle-hook-patterns.md) |
| Fleet ad-hoc data gathering | [fleet-ad-hoc-data-gathering.md](fleet-ad-hoc-data-gathering.md) |
| Fleet control spectrum | [fleet-control-spectrum.md](../../fleet-control-spectrum.md) |
| Git-driven RHACM | [git-driven-configuration.md](../git-driven-configuration.md) |
| ZTP with GitOps (Red Hat Developer) | [Implement ZTP with GitOps](https://developers.redhat.com/articles/2025/07/29/implement-zero-touch-provisioning-openshift-gitops) |
| VMware admins learning path (Phase 5 fleet) | [learning-path/vmware-admins](../../learning-path/vmware-admins/README.md) |
| Production hub checklist | [production-readiness.md](production-readiness.md) |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

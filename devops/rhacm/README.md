---
review:
  status: unreviewed
  notes: "AI-generated index 2026-04-23. Descriptions summarized from subdirectory READMEs and file contents. Needs read pass to confirm accuracy."
---

# RHACM

Reference material for Red Hat Advanced Cluster Management for Kubernetes. Organized into three directories by content type.

## Fleet control spectrum

How much fleet work lives in RHACM vs Argo CD is a posture choice, not a license choice.
See [Fleet control spectrum](../fleet-control-spectrum.md) for multiple decision axes and a reconsideration checklist when the solution leans GitOps-heavy.

**Git as source of truth for RHACM:** Hub policies, placements, and integration CRs belong in Git with the same PR and promotion flow as Argo CD apps.
See [Git-driven RHACM configuration](git-driven-configuration.md).

**Ideas & future work:** [fleet-management-ideas.md](../fleet-management-ideas.md) — framework and doc follow-ups for later review.

## Directories

### [`notes/`](./notes/)

Operational quick references — configurations, requirements, and setup guides used regularly.

| File | Contents |
|---|---|
| [production-readiness.md](./notes/production-readiness.md) | Production hub checklist: search PVC, cluster backup, infra nodes, availability config, OLM approval, observability, sizing. Audit commands and effort/risk table. |
| [search-setup.md](./notes/search-setup.md) | First-time Search setup: hub component verification, PVC configuration, per-cluster addon status, tuning reference. |
| [networking-requirements-2.16.md](./notes/networking-requirements-2.16.md) | Required ports and connectivity between hub and managed clusters, based on ACM 2.16 docs. |
| [cim-hub-setup.md](./notes/cim-hub-setup.md) | Enable on-prem cluster provisioning: CIM, `AgentServiceConfig`, corporate proxy, mirror config, audit commands. |
| [agent-install-preflight.md](./notes/agent-install-preflight.md) | Preflight orchestration for agent-based installs: ClusterCurator prehooks, Assisted Installer validation, agent approval gates. |

### [`troubleshooting/`](./troubleshooting/)

Diagnostic guides organized by symptom.

| File | Symptom |
|---|---|
| [search-service-503.md](./troubleshooting/search-service-503.md) | Search UI returns 503 — covers `SearchPVCNotPresent`, `search-postgres` OOMKill, and `search-api` failures. |
| [mch-stuck-pending-upgrade.md](./troubleshooting/mch-stuck-pending-upgrade.md) | `MultiClusterHub` stuck in `Updating` / `Pending` / `Installing` during hub upgrade. |
| [managed-cluster-lease-not-updated.md](./troubleshooting/managed-cluster-lease-not-updated.md) | Managed clusters showing Unknown — lease not updated by registration agent. |

### [`examples/`](./examples/)

Working configurations and patterns. All examples follow ACM 2.15+ best practices (`Placement` API, `ManagedClusterSet`, `ManagedClusterSetBinding`).

| Content | Description |
|---|---|
| [cluster-import-ansible/](./examples/cluster-import-ansible/) | Automated cluster import via Ansible |
| [gitops-cluster-integration/](./examples/gitops-cluster-integration/) | ArgoCD / GitOps integration with RHACM |
| [secret-management/](./examples/secret-management/) | Six patterns for distributing secrets across managed clusters |
| [ocm-subscription-automation/](./examples/ocm-subscription-automation/) | OCM subscription and ClusterCurator automation |
| [argocd-rbac/](./examples/argocd-rbac/) | ArgoCD RBAC configuration with RHACM |
| [distribute-yaml-to-all-clusters.md](./examples/distribute-yaml-to-all-clusters.md) | Three approaches to pushing resources to managed clusters — direct loop, RHACM Policy+Placement, and GitOps |
| [RHACM-2.15-BEST-PRACTICES.md](./examples/RHACM-2.15-BEST-PRACTICES.md) | ACM 2.15 best practices reference |
| [CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md](./examples/CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md) | Comparison of cluster import automation approaches |
| [BARE-METAL-OPERATOR-INTEGRATION.md](./examples/BARE-METAL-OPERATOR-INTEGRATION.md) | Bare metal operator integration patterns |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

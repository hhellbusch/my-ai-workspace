# Git-Driven RHACM Configuration

> **Audience:** Platform engineers treating the fleet hub as rebuildable infrastructure
> **Purpose:** Define RHACM hub and governance resources in Git with the same DevOps practices as Argo CD workload delivery — single source of truth, PR review, promotion, and drift correction

---

## Principle

Fleet management fails the rebuild test when RHACM configuration lives only in the console or in undocumented `oc apply` history.

**Target posture:** Every RHACM resource that defines how the fleet operates — placements, policies, GitOps integration, cluster sets — is declared in Git, reviewed in PRs, promoted through the same pipeline as application charts, and reconciled automatically on the hub.

Argo CD and RHACM are not two configuration channels.
Argo CD is the **delivery mechanism** for hub-side ACM resources; RHACM is the **enforcement and fleet control plane** for what reaches managed clusters.

```
                    ┌─────────────────────────────────────┐
                    │           Git repository           │
                    │                                     │
                    │  clusters/   apps/   hub/rhacm/    │
                    │  groups/     pipelines/            │
                    └──────────────────┬──────────────────┘
                                       │ PR → merge → promote
                                       ▼
                    ┌─────────────────────────────────────┐
                    │         Hub cluster                 │
                    │                                     │
                    │  Argo CD ──▶ hub/rhacm/* (ACM CRs)  │
                    │       │                             │
                    │       └──▶ ApplicationSets ──▶ spokes
                    │                                     │
                    │  RHACM ──▶ policies propagate ──▶  │
                    └─────────────────────────────────────┘
```

**Rebuild narrative:** Given a fresh hub cluster, OpenShift GitOps, and RHACM installed, applying the bootstrap Application(s) from Git should recreate fleet integration, label enforcement, governance policies, and app delivery — without manual console steps.

---

## On this page

- [What belongs in Git](#what-belongs-in-git)
- [Directory layout](#directory-layout)
- [Delivery patterns](#delivery-patterns)
- [Generated vs hand-authored](#generated-vs-hand-authored)
- [CI and promotion](#ci-and-promotion)
- [Argo CD and RHACM policy tracking](#argo-cd-and-rhacm-policy-tracking)
- [Framework coverage today](#framework-coverage-today)
- [Expanding governance without a second pipeline](#expanding-governance-without-a-second-pipeline)
- [Anti-patterns](#anti-patterns)
- [Related reading](#related-reading)

---

## What belongs in Git

| Class | Examples | Reconciled by | Target cluster |
|-------|----------|---------------|----------------|
| **Fleet integration** | `ManagedClusterSet`, `ManagedClusterSetBinding`, `GitOpsCluster`, fleet `Placement` | Argo CD on hub | Hub |
| **Cluster identity** | Labels, group membership, app opt-in/out in `cluster.yaml` | RHACM Policy (generated from Git) | Hub → `ManagedCluster` |
| **Governance** | `Policy`, `Placement`, `PlacementBinding`, `PolicyAutomation` | RHACM (desired state from Git via Argo) | Hub → spokes |
| **Spoke configuration** | Operators, monitoring, logging, team workloads | Argo CD ApplicationSets | Spokes |
| **Provisioning** (optional) | `AgentServiceConfig`, `InfraEnv`, ZTP `SiteConfig` / PGT | Argo CD + ACM | Hub + bare metal |

**Not in Git:** Secret values (use Vault + ESO or ACM `fromSecret` referencing hub secrets), ephemeral debug overrides, one-off `oc` hotfixes.

**Console rule:** If a change is not committed, it does not exist — including RHACM policies created from the Governance UI.

---

## Directory layout

Align with the [fleet framework](../argo/examples/framework/) monorepo shape.
RHACM hub resources live under `hub/rhacm/`, not scattered across runbooks.

```
hub/rhacm/
├── integration/              # Fleet ↔ Argo wiring (target: Argo-managed)
│   ├── managed-cluster-set.yaml
│   ├── placement.yaml
│   └── gitopscluster.yaml
├── cluster-labels/           # Helm chart: Policy per cluster from cluster.yaml
│   ├── Chart.yaml
│   ├── values.yaml           # Generated — see below
│   └── templates/
├── policies/                 # Platform mandates (expand in governance phase)
│   ├── baseline/               # e.g. oauth, nmstate, kubeadmin-removal
│   │   ├── placement.yaml
│   │   ├── placementbinding.yaml
│   │   └── policy.yaml
│   └── inform/                 # Drift detection only — types Argo does not own
└── README.md
```

Spoke-facing app charts stay in `apps/`; cluster-specific overrides stay in `clusters/<name>/`.
**Do not** duplicate the same object in `apps/` and `hub/rhacm/policies/` — one owner per resource kind (see [fleet control spectrum](../fleet-control-spectrum.md)).

---

## Delivery patterns

Three patterns cover most RHACM-as-code cases.
All three use the same Git workflow.

### 1. Static manifests — Argo Application on the hub

Plain YAML for integration CRs (`GitOpsCluster`, `Placement`, `ManagedClusterSet`).

- Argo `Application` destination: hub cluster (`https://kubernetes.default.svc`)
- Namespace: `openshift-gitops` or `open-cluster-management-global-set` as appropriate
- Sync wave: early (e.g. `-10` integration, `-5` label policies) so dependencies exist before ApplicationSets

**Today:** Files exist in [framework `hub/rhacm/`](../argo/examples/framework/hub/rhacm/) but comments still show `oc apply` — target state is an Argo-managed `Application` (e.g. `hub-rhacm-integration`) alongside [cluster-label-sync](../argo/examples/framework/hub/applicationsets/cluster-label-sync.yaml).

### 2. Generated policies — Helm chart from fleet inventory

When output scales with cluster count (label enforcement), generate from `clusters/*/cluster.yaml`:

```
clusters/<name>/cluster.yaml
       │  aggregate-cluster-config.sh (CI)
       ▼
hub/rhacm/cluster-labels/values.yaml
       │  Argo syncs Helm chart
       ▼
Policy + Placement + PlacementBinding per cluster
```

Documented in [cluster label sync](../argo/examples/framework/hub/rhacm/cluster-labels/README.md).

### 3. PolicyGenerator — kustomize plugin for policy bundles

For governance catalogs (baseline mandates, environment-specific bundles), use the [PolicyGenerator](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.11/html/governance/integrate-policy-generator) kustomize plugin:

- Author concise policy intent in Git
- CI renders full `Policy` / `Placement` / `PlacementBinding` manifests
- Argo CD applies rendered output to the hub

Fits platform mandates that are not naturally expressed as per-cluster Helm loops.
See also [distribute-yaml-to-all-clusters.md](examples/distribute-yaml-to-all-clusters.md) for the underlying Policy + Placement model.

---

## Generated vs hand-authored

| File | Edit how | CI enforcement |
|------|----------|----------------|
| `clusters/<name>/cluster.yaml` | Hand-authored in PR | Required |
| `hub/rhacm/cluster-labels/values.yaml` | **Generated** — run `aggregate-cluster-config.sh` | Drift check: regen must match commit |
| `hub/rhacm/integration/*.yaml` | Hand-authored | `helm lint` / YAML lint / kubeconform |
| `hub/rhacm/policies/**` | Hand-authored or PolicyGenerator output | Same as apps |

Mark generated files (e.g. `.gitattributes` `linguist-generated=true`) so reviewers know not to edit them directly.
Framework invariant: [GUIDELINES.md](../argo/examples/framework/GUIDELINES.md) — aggregation must run before merge.

---

## CI and promotion

RHACM configuration uses the **same** pipeline as application delivery:

| Gate | Applies to |
|------|------------|
| PR review + branch protection | All `hub/rhacm/` changes |
| YAML / Helm lint | Charts and static manifests |
| Aggregation drift check | `cluster.yaml` → `cluster-labels/values.yaml` |
| Promotion (`main` → env branches or trunk + RollingSync) | Hub and spoke together |
| Observable done | Policy compliance visible in ACM UI; Argo Application Synced |

**Promotion coupling:** A governance policy change should ride the same promotion train as the apps it gates.
Do not maintain a separate "policy promotion" process outside Git.

---

## Argo CD and RHACM policy tracking

When Argo CD deploys parent `Policy` resources, RHACM propagates child policies to managed clusters.
Without correct tracking configuration, Argo reports **OutOfSync** and may **prune** generated children.

**Required hub setting:** `application.resourceTrackingMethod: annotation` (or `annotation+label`) in `argocd-cm`.

See [ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md](../argo/examples/docs/patterns/ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md).

This is a prerequisite for treating policies as first-class Git-managed resources delivered by Argo — not an optional tuning step.

---

## Framework coverage today

The [Argo CD fleet framework](../argo/examples/framework/) already implements part of this model:

| Concern | In Git? | Delivered by Argo? | Notes |
|---------|---------|-------------------|-------|
| Cluster labels → `ManagedCluster` | Yes (`cluster.yaml`) | Yes (`cluster-label-sync` Application) | Full loop |
| Label aggregation | Yes (generated `values.yaml`) | — | CI enforced |
| `GitOpsCluster` / fleet `Placement` / `ManagedClusterSet` | Yes (`hub/rhacm/*.yaml`) | **Gap** — still documented as `oc apply` | Add hub integration Application |
| Platform governance policies | No | — | Governance phase target: `hub/rhacm/policies/` |
| Spoke Day 2 (monitoring, cert-manager, …) | Yes (`apps/`) | Yes (ApplicationSets) | Argo-heavy — correct for delivery axis |

**Implication for an Argo-heavy design:** You are already GitOps-first for spoke config.
Closing the gap means bringing **all** hub RHACM CRs under Argo sync and adding **governance policies in Git** — not moving spoke delivery to the ACM console.

---

## Expanding governance without a second pipeline

When adding ACM policies (Phase 4 / governance slice), keep one source of truth:

1. **Add policies under `hub/rhacm/policies/`** — not ad hoc `oc apply` or console creation.
2. **Start with `inform`** on types Argo does not manage; graduate to `enforce` for mandates.
3. **Wire a hub Argo Application** (or extend bootstrap) to sync `hub/rhacm/policies/` at sync wave `-5` or `-3`.
4. **Document ownership** — update the per-concern table in [fleet control spectrum](../fleet-control-spectrum.md); no dual deploy.
5. **Prove rebuild** — delete a test policy from the cluster; confirm Argo or self-heal restores from Git.

Policy content can differ by environment via the same value-cascade ideas (group overlays) or separate kustomize overlays per promotion branch — but the mechanism stays Git → Argo → RHACM.

---

## Anti-patterns

| Anti-pattern | Why it breaks SSOT |
|--------------|-------------------|
| Create policies in ACM Governance UI | No PR, no promotion, not rebuildable |
| `oc apply -f hub/rhacm/` outside Argo | Bypasses sync/audit; drift from Git |
| Edit `ManagedCluster` labels by hand | Overwritten by label-sync policy — or drifts if policy absent |
| Duplicate config in Argo app chart and ACM policy | Controller conflict; unclear owner |
| Separate policy repo with no linked promotion | Two truths; version skew at deploy time |
| Store secrets in policy YAML | Git exposure; use `fromSecret` / ESO |

---

## Related reading

| Topic | Location |
|-------|----------|
| RHACM vs Argo CD tradeoffs (axes) | [fleet-control-spectrum.md](../fleet-control-spectrum.md) |
| Label sync implementation | [framework hub/rhacm/cluster-labels](../argo/examples/framework/hub/rhacm/cluster-labels/README.md) |
| GitOpsCluster registration | [gitops-cluster-integration/](examples/gitops-cluster-integration/) |
| Policy + Placement model | [distribute-yaml-to-all-clusters.md](examples/distribute-yaml-to-all-clusters.md) |
| Argo tracking for ACM policies | [ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md](../argo/examples/docs/patterns/ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md) |
| Framework invariants | [GUIDELINES.md](../argo/examples/framework/GUIDELINES.md) |
| Ideas & future work (review log) | [fleet-management-ideas.md](../fleet-management-ideas.md) |
| PolicyGenerator (upstream) | [ACM governance — PolicyGenerator](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.11/html/governance/integrate-policy-generator) |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author.
See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

# For CoP maintainers: relationship to gitops-standards-repo-template

This document is for maintainers of [`redhat-cop/gitops-standards-repo-template`](https://github.com/redhat-cop/gitops-standards-repo-template) and people evaluating whether this pattern should become part of the CoP reference catalog.

See the [main README](../README.md) for the implementation guide and [architecture-opinions.md](./architecture-opinions.md) for the full design rationale.

---

## What is the same

- `components/`, `groups/`, `clusters/` directory structure — identical to gitops-standards
- Groups are composable — a cluster belongs to multiple groups; each group contributes only what it owns
- App of Apps pattern — root Application generates child Applications
- ApplicationSet explicitly not used (gitops-standards cites controller instability; this pattern cites compatibility and explicitness — same conclusion)
- `targetRevision` pinning for promotion workflows

---

## What is different

| | [gitops-standards-repo-template](https://github.com/redhat-cop/gitops-standards-repo-template) | This pattern |
|---|---|---|
| **Templating engine** | Kustomize (with optional Helm via HelmChartInflaterGenerator) | Pure Helm — see trade-offs below |
| **Group membership declaration** | In each cluster's `kustomization.yaml` `components:` list — distributed across cluster directories | In `clusters.yaml` — centralised in one file |
| **Central cluster inventory** | None — a cluster exists as a directory; fleet topology is implicit | `clusters.yaml` — explicit single file listing every cluster, its hub, groups, and shared attributes |
| **Shared attributes across components** | No built-in mechanism — each component handles its own values | `clusters.yaml` fields injected as `.Values.cluster.*` into every component; vault endpoint defined once, used by all |
| **Value merging** | Kustomize overlay/patch mechanism (additive for lists via patches) | Helm `mustMergeOverwrite` chain with named `component-<name>` keys; **lists require `extra*/concat` pattern** |
| **Multi-hub support** | Not addressed — single hub model | First-class: `currentHub` parameter filters `clusters.yaml`; one ArgoCD per hub |
| **Hub Application generation** | Root application derived from cluster-specific kustomization | `hub-bootstrap` Helm chart generates hub Applications from `clusters.yaml`; committed to Git by CI |
| **Local debugging** | `kustomize build clusters/hub/ --enable-helm` | `helm template charts/hub-clusters ...` |
| **Per-cluster `targetRevision`** | In kustomization file per component or per group | In `clusters.yaml` entry — one field pins all components for that cluster |

---

## The Helm vs Kustomize trade-off (full version)

The gitops-standards template uses Kustomize with Helm as an optional layer. This pattern inverts that: Helm is the primary engine throughout.

**Why Helm:** Kustomize patches operate on rendered YAML at the resource level (strategic merge patch, JSON patch); Helm values merging operates at the configuration data level before any resource is rendered. For composing shared default values across many clusters, Helm values merging is more natural and less verbose than writing patches.

**Full cost of choosing Helm:**

- Teams whose components need strategic-merge-patch semantics (e.g. merging into a complex resource like a `MachineConfig` or `ClusterLogging` CR) will find Helm templates less ergonomic — you must express the merge in template logic rather than as a patch.
- Teams with an existing Kustomize component library (e.g. `redhat-cop/gitops-catalog`) cannot reuse those bases directly without either wrapping them in a Helm chart or using `sourceType: kustomize` (see [convergence.md](./convergence.md)).
- Helm introduces a `helm template` render step that must happen before you can inspect what ArgoCD will apply — there is no equivalent of `kustomize build` that is universally familiar to platform engineers who know Kustomize.
- List merging requires the `extra*/concat` pattern (see architecture-opinions.md Opinion #4). Kustomize handles this natively via patches.

**Full cost of choosing Kustomize:**

- No mechanism for composing shared scalar values across multiple components without repeating them (Kustomize patches target resource fields, not a shared values layer).
- No equivalent of `.Values.cluster.vault.server` that injects the same value into every component without each component defining its own patch.
- Strategic merge patch for complex CRs can become verbose when the base is large.

The choice is not "Helm is better than Kustomize." It is: **if your primary pain is shared attributes across many components on many clusters, Helm values merging solves it more directly. If your primary pain is patching complex CRs or reusing an existing Kustomize component library, Kustomize solves it more directly.**

---

## Why a central `clusters.yaml`

gitops-standards declares group membership in each cluster's `kustomization.yaml`. This is flexible and keeps each cluster self-contained, but means there is no single file that shows the complete fleet topology.

This pattern adds `clusters.yaml` as an explicit fleet inventory. The cost is a coordination point on every cluster onboarding — in large teams this can cause merge conflicts; consider automating cluster additions via a script or CI step. The benefit is a single authoritative location for shared attributes that multiple components need (Vault endpoint, monitoring remote-write, etc.) — avoiding the repetition that emerges when the same value appears in multiple component configs across multiple cluster directories.

**The decision rule:** if a value is used by more than one component, it belongs in `clusters.yaml`.

---

## Choosing between them

Use **gitops-standards-repo-template** when:
- Your team is already comfortable with Kustomize
- Your components include complex CRs that benefit from strategic-merge-patch semantics
- You want to reuse `redhat-cop/gitops-catalog` Kustomize bases without extra wrapping
- Cluster self-containment is more important than a central fleet view
- You don't need shared attributes injected automatically across components

Use **this pattern** when:
- Your team works primarily in Helm
- You want a single file (`clusters.yaml`) as the authoritative fleet inventory
- Multiple components share cluster-level config (Vault, monitoring, certificates) and you want it defined once
- Multi-hub support (multiple ArgoCD instances managing different cluster subsets) is a requirement
- You need per-cluster `targetRevision` pinning across all components from one place

---

## Convergence path

These patterns are not mutually exclusive. For a sketch of how they could be used together in a single fleet — including `sourceType` per component to choose Helm or Kustomize engine — see [convergence.md](./convergence.md).

> **Note:** The convergence approach is aspirational and requires validation with the team. It is documented here to record the direction of thinking, not as a production-ready integration guide.

---

*AI-assisted content. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for review status details.*

# Architecture and design opinions

This document explains the problem this pattern solves, the principle that structures the solution, and the explicit design decisions ("opinions") baked into the implementation — with their full trade-offs.

See the [main README](../README.md) for the implementation guide.

---

## The problem

You have multiple OpenShift clusters. Each cluster needs a set of platform components — cert-manager, nmstate, kubevirt, logging, monitoring agents, etc. Most config is the same across clusters, but not all:

- Some clusters run OpenShift Virtualization; others don't
- Some are single-node edge clusters with reduced resource requests
- Each cluster points to a different Vault server, a different monitoring endpoint, a different ingress certificate
- Prod clusters use `Manual` InstallPlan approval; dev uses `Automatic`

The naive approach is one Argo CD Application per component per cluster, with hand-authored values. This works for two clusters. At ten clusters with eight components each, you have eighty hand-authored Application manifests. When a shared value changes — Vault endpoint, a channel upgrade — you update it in every relevant manifest. You miss some. Clusters drift.

The combinatorial alternative — a full Kustomize overlay or Helm values file per environment combination — explodes when a cluster belongs to multiple groups simultaneously (production + bare-metal + virt-enabled).

---

## The principle

Configuration should be layered, not duplicated.

```
component-all  ──mustMergeOverwrite──▶  component-virt-enabled  ──mustMergeOverwrite──▶  component-site-dc1
(fleet defaults)                         (group overrides)                                  (cluster overrides)
```

Each layer contributes only what it owns. The merge accumulates from broadest to narrowest. A cluster belongs to multiple groups; each group's contribution is merged in declared priority order; the cluster layer wins last. The result — the fully resolved Application values — is what Argo CD receives.

Cluster identity (name, server URL, Vault endpoint, monitoring endpoint) lives in `clusters.yaml` and is injected automatically into every component. No component needs to know where its cluster's Vault lives; that is not the component's concern.

---

## "Hub" — ArgoCD fleet topology, not RHACM

In this pattern, a **hub** is an ArgoCD instance plus the set of clusters it manages. Hub does not mean Red Hat Advanced Cluster Management (RHACM) — it is purely an ArgoCD fleet topology concept.

A typical fleet might have:
- `dev` hub: manages dev and test clusters
- `prod-a` hub: manages production clusters in region A
- `prod-b` hub: manages production clusters in region B

Each hub runs its own ArgoCD. The `hub-clusters` chart, when deployed as an Application on a hub, filters `clusters.yaml` by `hub: <name>` and generates component Applications only for that hub's clusters.

**RHACM is optional and complementary.** This pattern manages application configuration and component delivery. RHACM adds:
- Automated cluster registration and credential distribution to ArgoCD
- Policy-based compliance enforcement (separate from component delivery)
- Fleet-level visibility across all hubs

If you have RHACM: use it for cluster lifecycle and compliance; use this pattern for component delivery. If you don't have RHACM: this pattern works standalone — cluster registration is manual (import credentials into each ArgoCD instance).

---

## Opinions baked in

Every design has trade-offs. These are the choices made in this pattern and what they cost. Each opinion is grounded in a named software engineering principle.

---

**1. Groups are a general-purpose composition mechanism**
*Principle: Separation of Concerns + Composition over Inheritance*

A group is any named slice of configuration that more than one cluster shares. Groups can describe capability (`virt-enabled`, `edge-sno`), environment (`env-production`, `env-staging`), region (`region-us-east`), hardware type (`baremetal`), or any other axis that makes sense for your fleet. A cluster can belong to multiple groups simultaneously — there is no single inheritance axis.

The composition is what matters: rather than one monolithic config per cluster, you build each cluster's config by merging a stack of focused groups. A production bare-metal cluster running OCP Virt might belong to `[all, env-production, baremetal, virt-enabled]`. Each group contributes only what it knows about; no group needs to account for the concerns of another.

*Cost:* group names become a shared vocabulary across the team. Inconsistent naming (`prod`, `production`, `env-prod`) creates ambiguity about which group to use. Establish a naming convention early and document it in the groups directory.

---

**2. Helm as the primary templating engine**
*Principle: Single mechanism for the primary concern*

Helm values merging (`mustMergeOverwrite`) operates at the configuration data level — before any resource is rendered. For composing shared default values across many clusters, this is more natural and less verbose than Kustomize strategic-merge patches, which operate at the rendered YAML level.

*Full cost:*
- Components that need strategic-merge-patch semantics (e.g. merging into a complex CR like `MachineConfig` or `ClusterLogging`) are harder to express — the merge must be in template logic, not in a patch file.
- Existing `redhat-cop/gitops-catalog` Kustomize bases cannot be reused without wrapping or `sourceType: kustomize`.
- List merging requires the `extra*/concat` convention (see Opinion #4). Kustomize handles this natively.
- `helm template` is an extra step in every debugging workflow; `kustomize build` is more universally known on platform teams.
- Teams comfortable with Kustomize will find this pattern harder to adopt initially.

*When Helm is the right choice:* when shared attribute injection across many components is the primary pain. When Kustomize patching of complex CRs is the primary pain, invert the engine choice or use `sourceType: kustomize` per component.

---

**3. Components are opt-out at the fleet level, opt-in per group**
*Principle: Secure by Default + Explicit over Implicit*

`component-all` sets `enabled: false` for anything that isn't universally required. Groups opt components in. This means adding a new component to the registry does not automatically install it anywhere — it requires an explicit group or cluster override. Safer for destructive components (storage, networking operators). Same principle as deny-by-default in access control.

*Cost:* group files grow as the component list grows. A component that truly belongs on every cluster still needs an explicit `enabled: true` in `component-all`.

---

**4. `clusters.yaml` is the single authoritative cluster inventory**
*Principle: Single Source of Truth (SSOT) + DRY (Don't Repeat Yourself)*

Cluster metadata — name, server URL, hub assignment, group membership, vault endpoint, monitoring endpoint — lives in one file. `clusters/<name>/values.yaml` contains only component-level overrides. If a cluster needs no overrides, the file can be empty.

**What belongs in `clusters.yaml`** (guardrail: if more than one component uses a value, it belongs here):

| ✅ Belongs in `clusters.yaml` | ❌ Does not belong |
|---|---|
| Cluster API server URL | App-specific config only one component uses |
| Vault server endpoint | Secrets or credentials (use Vault/ESO) |
| Monitoring remote-write endpoint | Namespace-level config |
| Hub assignment | Config that varies within a cluster |
| Group membership | Highly volatile config (frequent PR noise) |
| Environment, region labels | Large binary or generated data |
| Any value shared across two or more components | |

*Cost:* `clusters.yaml` becomes a coordination point. Every cluster onboarding touches it. In large teams this can cause merge conflicts; automate cluster additions via a script or CI step where possible.

---

**5. `mustMergeOverwrite` over `mergeOverwrite` (deep merge)**
*Principle: Fail Fast + Principle of Least Surprise*

`mergeOverwrite` does a shallow top-level replacement — a group setting an `apps.nmstate` key replaces the entire map from the lower layer, silently losing sibling keys. `mustMergeOverwrite` recurses: only the keys explicitly set in the higher-priority layer are overridden. The Fail Fast principle applies to the type-conflict panic: a schema mistake (a key is a string in one layer and a map in another) causes an immediate render-time error rather than silently producing incorrect YAML that only fails when applied to the cluster.

*Cost:* all layers must agree on the type of every key they share. Mixed types that happen to work with `mergeOverwrite` will panic with `mustMergeOverwrite`.

**`mustMergeOverwrite` does not merge lists.** When two value layers both define the same YAML sequence (array), the higher-priority layer **replaces** the lower layer's list entirely. If a component needs to accumulate list entries across group and cluster layers (e.g. alerting silences, imagePullSecrets, CIDR allow-lists), use the **`extra*/concat` pattern**:

1. The primary array key (e.g. `cluster.alerting.silences: []`) holds the group-level baseline.
2. A companion `extra<Name>` key (e.g. `extraSilences: []`) holds cluster-specific additions.
3. The component template concatenates both: `concat .Values.cluster.alerting.silences .Values.extraSilences`.

A cluster that needs only to *add* entries uses `extraSilences`; a cluster that needs to *replace* the group baseline sets `cluster.alerting.silences` directly. The [`../../framework/`](../../framework/) pattern ships `scripts/lint-array-safety.sh` to enforce this in CI.

---

**6. Group priority order is explicit (`hubConfig.groupOrder`)**
*Principle: Make the Implicit Explicit + Principle of Least Surprise*

The order groups are loaded determines which wins when two groups set the same key. This order is declared explicitly in `clusters.yaml` under `hubConfig.<hub>.groupOrder` rather than derived from the order clusters are listed in the file. Cluster listing order is an implementation detail; merge priority is a policy decision.

*Cost:* adding a new group requires updating `hubConfig.groupOrder` for every hub that uses it, or the template falls back to implicit ordering with a warning annotation.

---

**7. One ArgoCD instance per hub, not one global instance**
*Principle: Bulkhead Pattern + Defence in Depth*

Each hub cluster runs its own ArgoCD scoped to the clusters it manages. A misconfiguration in the dev hub cannot affect prod clusters — the failure is contained to one compartment. Prod clusters require a separate credential, a separate ArgoCD instance, and a separate PR merged to a separate hub's scope before anything reaches them.

*Full cost:*
- Multiple ArgoCD instances to operate. Shared config (RBAC, repositories, projects) must be reproduced or templated across hubs.
- **No single pane of glass across hubs.** To see the sync status of all clusters across all hubs, you need either RHACM (which provides a fleet-level view) or a separate aggregation layer (e.g. ArgoCD ApplicationSet with multi-cluster targeting, or a custom dashboard). Without it, operators must log into each hub's ArgoCD UI independently to get a fleet-wide picture.
- Credential management scales with hub count — each hub needs credentials for all its managed clusters, and those credentials need rotation and access control.

*When this is worth the cost:* when blast-radius isolation between environments is a hard requirement (regulated industries, large orgs with strict prod/non-prod separation). When a single ArgoCD instance is acceptable, a single-hub topology works and simplifies operations significantly.

---

**8. Hub Applications are pre-rendered; component Applications are live-rendered**
*Principle: Apply Constraints at the Right Layer (Appropriate Consistency)*

Hub Applications change only when clusters are added, removed, moved between hubs, or when group membership changes. Pre-rendering them and committing to `hub/rendered/` makes every hub-level change visible as a plain diff. Component Applications change constantly — pre-rendering all of them would produce enormous Git churn on every shared group value change.

The principle: apply the stronger consistency guarantee (committed YAML, full audit trail) where the change rate is bounded and the diff is meaningful. Use live rendering where pre-rendering creates noise that drowns signal.

*Full cost:* component Application diffs are not visible in PRs — a PR that changes `groups/all/values.yaml` will not show the resulting Application objects in the diff. You see the values change, not the Application-level effect. `argocd-diff-preview` closes this gap for PR-level diffs (see [diffing-and-visibility.md](./diffing-and-visibility.md)), but it must be set up separately. This means the "PR visibility" benefit is fully realised only for teams that have integrated argocd-diff-preview into CI.

---

**9. No ApplicationSet**
*Principle: YAGNI + Minimise External Dependencies*

Applications are generated by Helm templates, not by an ApplicationSet controller. The generation logic is explicit, version-controlled in this repo, and testable offline with `helm template` — no running controller required. Pragmatic choice for compatibility with older ArgoCD versions and for keeping template bugs visible in CI rather than in a live controller.

*Cost:* no automatic cluster discovery — every cluster must be explicitly registered in `clusters.yaml`. If you want ApplicationSet-based auto-discovery instead, the ApplicationSet Git directory generator can replace the `hub-bootstrap` + `hub/rendered/` pattern; however you lose the static committed output that CI diff tooling depends on.

---

### Principles at a glance

| Opinion | Primary principle | Secondary principle |
|---|---|---|
| Groups = general-purpose composition | Separation of Concerns | Composition over Inheritance |
| Helm as primary engine | Single mechanism for primary concern | (trade-off: see full cost above) |
| Opt-out defaults, opt-in per group | Secure by Default | Explicit over Implicit |
| `clusters.yaml` as single identity source | Single Source of Truth | DRY |
| `mustMergeOverwrite` + type panics | Fail Fast | Principle of Least Surprise |
| Explicit group order | Make the Implicit Explicit | Principle of Least Surprise |
| One ArgoCD per hub | Bulkhead Pattern | Defence in Depth |
| Hybrid pre-render / live-render | Appropriate Consistency | (apply constraints where cost is low) |
| No ApplicationSet | YAGNI | Minimise External Dependencies |

---

## How the charts relate

Three Helm charts form a cascade. Each level generates Applications that ArgoCD then manages at the next level:

```
bootstrap-root.yaml          ← applied by hand ONCE on each hub cluster
  │  Watches: hub/rendered/hub-applications.yaml
  │
  └── hub-bootstrap          ← NOT run by ArgoCD; run by GitHub Action
        │  Input:  clusters.yaml
        │  Output: one Application per hub → hub/rendered/ (committed to Git)
        │
        └── hub-clusters     ← run by ArgoCD on each hub
              │  Input:  clusters.yaml + group values + cluster values
              │  Output: one Application per enabled component per cluster
              │
              └── components/<name>/   ← the actual platform components
                    Deployed by ArgoCD to each managed cluster
```

| Chart | Run by | Input | Output |
|---|---|---|---|
| `hub-bootstrap` | GitHub Action (CI) | `clusters.yaml` | One ArgoCD Application per hub, committed to `hub/rendered/` |
| `hub-clusters` | ArgoCD (on each hub) | `clusters.yaml` + group + cluster values | One Application per enabled component per cluster on that hub |
| `components/<name>/` | ArgoCD (on each managed cluster) | Values injected by `hub-clusters` | The actual Kubernetes resources on the cluster |

The key split: `hub-bootstrap` runs **once in CI** to solve the chicken-and-egg problem (ArgoCD needs an Application to render the chart, but the chart generates the Application). `hub-clusters` runs **live in ArgoCD** and re-renders whenever values change.

---

*AI-assisted content. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for review status details.*

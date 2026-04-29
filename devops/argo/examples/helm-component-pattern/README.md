# Helm component pattern — `mustMergeOverwrite` with named component keys

---

## The problem

You have multiple OpenShift clusters. Each cluster needs a set of platform components — cert-manager, nmstate, kubevirt, logging, monitoring agents, etc. Most config is the same across clusters, but not all:

- Some clusters run OpenShift Virtualization; others don't
- Some are single-node edge clusters with reduced resource requests
- Some clusters override a specific setting (e.g. `installPlanApproval: Manual` in production)
- New clusters need to be onboarded without copy-pasting config from an existing one

You want all of this managed by GitOps: every change goes through a pull request, ArgoCD applies it, and nothing is applied by hand.

**What goes wrong without a pattern:**

```
clusters/
  site-dc1/cert-manager.yaml      ← full config copy
  site-dc1/nmstate.yaml           ← full config copy
  site-edge-1/cert-manager.yaml   ← slightly different copy
  site-edge-1/nmstate.yaml        ← slightly different copy
  site-dc2/cert-manager.yaml      ← another copy ...
```

When you want to change the cert-manager channel across all production clusters, you update N files. When you add a new cluster, you copy-paste and manually adjust. Config drifts. Reviews miss changes buried in large diffs.

---

## The principle

Define each platform component **once**, with sensible defaults. Define **groups** that describe cluster types. Assign each cluster to groups. Merge the layers in priority order — later layers win.

```
component-all           ← baseline: every cluster gets cert-manager, channel: stable
component-virt-enabled  ← override: add kubevirt, bump nmstate to stable-4.16
component-edge-sno      ← override: reduce cert-manager resource requests
component-site-dc1      ← cluster override: cert-manager installPlanApproval: Manual
```

For a cluster in groups `[all, virt-enabled]` with a cluster-specific override, the merge order is:

```
component-all  ──mustMergeOverwrite──▶  component-virt-enabled  ──mustMergeOverwrite──▶  component-site-dc1
(lowest priority)                                                                          (highest priority)
```

Each layer **deep-merges** into the previous. A key set in `component-virt-enabled` only affects that key — it doesn't replace the entire map from `component-all`. The cluster layer is always last and always wins.

ArgoCD generates one Application object per enabled component per cluster. Config is resolved at render time; no per-cluster copy-paste.

---

## "Hub" — ArgoCD fleet topology, not RHACM

This pattern uses the word **hub** to mean: *a cluster where ArgoCD runs, which deploys applications to other (spoke) clusters*.

This is standard ArgoCD fleet terminology. **This pattern requires only ArgoCD** — no Red Hat Advanced Cluster Management (RHACM) is installed or used in this reference implementation.

```
Hub cluster (ArgoCD runs here)
  ├── Deploys to: site-dc1   (spoke)
  ├── Deploys to: site-dc2   (spoke)
  └── Deploys to: site-edge-1  (spoke)
```

**RHACM can be used alongside this pattern and makes some things easier.** RHACM automates the operational steps that this pattern leaves manual:

- Registering spoke clusters with the hub ArgoCD instance (cluster secrets, RBAC, kubeconfig)
- Propagating the ArgoCD namespace and service account to spoke clusters
- Cluster lifecycle (provisioning, decommissioning, upgrades)
- Policy enforcement across the fleet independent of ArgoCD

If RHACM is available, use it for cluster registration and let this pattern handle *what gets deployed* to each cluster. The two are complementary: RHACM manages the fleet topology; this pattern manages the application configuration that runs on it.

Multiple hub clusters are supported — `prod-a`, `prod-b`, and `dev` in this example. Each hub manages a subset of spoke clusters. All hubs read from the same Git repository.

---

## Opinions baked in

Every design has trade-offs. These are the choices made in this pattern and what they cost. Each opinion is grounded in a named software engineering principle — these are not arbitrary preferences.

---

**1. Groups are a general-purpose composition mechanism**
*Principle: Separation of Concerns + Composition over Inheritance*

A group is any named slice of configuration that more than one cluster shares. Groups can describe capability (`virt-enabled`, `edge-sno`), environment (`env-production`, `env-staging`), region (`region-us-east`), hardware type (`baremetal`), or any other axis that makes sense for your fleet. A cluster can belong to multiple groups simultaneously — there is no single inheritance axis.

The composition is what matters: rather than one monolithic config per cluster, you build each cluster's config by merging a stack of focused groups. A production bare-metal cluster running OCP Virt might belong to `[all, env-production, baremetal, virt-enabled]`. Each group contributes only what it knows about; no group needs to account for the concerns of another.

*Cost:* group names become a shared vocabulary across the team. Inconsistent naming (`prod`, `production`, `env-prod`) creates ambiguity about which group to use. Establish a naming convention early and document it in the groups directory.

---

**2. Components are opt-out at the fleet level, opt-in per group**
*Principle: Secure by Default + Explicit over Implicit*

`component-all` sets `enabled: false` for anything that isn't universally required. Groups opt components in. This means adding a new component to the registry does not automatically install it anywhere — it requires an explicit group or cluster override. Safer for destructive components (storage, networking operators). This is the same principle as deny-by-default in access control: you must explicitly grant, not explicitly deny.

*Cost:* group files grow as the component list grows. A component that truly belongs on every cluster still needs an explicit `enabled: true` in `component-all`.

---

**3. `clusters.yaml` owns cluster identity; cluster value files own only deviations**
*Principle: Single Source of Truth (SSOT) + DRY (Don't Repeat Yourself)*

Cluster metadata (name, server URL, hub assignment, group membership, vault endpoint, monitoring endpoint) lives in one file. `clusters/<name>/values.yaml` contains only component-level overrides — if a cluster needs no overrides, the file can be empty. Every attribute has exactly one authoritative location. When a Vault endpoint changes, one line in one file changes, and every component on every cluster in that hub picks it up.

*Cost:* `clusters.yaml` becomes a coordination point. Every cluster onboarding touches it. In large teams this can cause merge conflicts; consider automating the addition via a script or CI step.

---

**4. `mustMergeOverwrite` over `mergeOverwrite` (deep merge)**
*Principle: Fail Fast + Principle of Least Surprise*

`mergeOverwrite` does a shallow top-level replacement — a group setting an `apps.nmstate` key replaces the entire map from the lower layer, silently losing sibling keys. `mustMergeOverwrite` recurses: only the keys explicitly set in the higher-priority layer are overridden. The Fail Fast principle applies to the type-conflict panic: a schema mistake (a key is a string in one layer and a map in another) causes an immediate render-time error rather than silently producing incorrect YAML that only fails when applied to the cluster.

*Cost:* all layers must agree on the type of every key they share. Mixed types that happen to work with `mergeOverwrite` will panic with `mustMergeOverwrite`.

---

**5. Group priority order is explicit (`hubConfig.groupOrder`)**
*Principle: Make the Implicit Explicit + Principle of Least Surprise*

The order groups are loaded determines which wins when two groups set the same key. This order is declared explicitly in `clusters.yaml` under `hubConfig.<hub>.groupOrder` rather than derived from the order clusters are listed in the file. Cluster listing order is an implementation detail; merge priority is a policy decision. Making it explicit means a new engineer reading `clusters.yaml` can answer "which group wins?" without tracing through template logic.

*Cost:* adding a new group requires updating `hubConfig.groupOrder` for every hub that uses it, or the template falls back to implicit ordering with a warning annotation.

---

**6. One ArgoCD instance per hub, not one global instance**
*Principle: Bulkhead Pattern + Defence in Depth*

Each hub cluster runs its own ArgoCD scoped to the clusters it manages. There is no single "master" ArgoCD targeting all clusters across all environments. The Bulkhead pattern (from ship design: watertight compartments limit flooding) applied here means a misconfiguration in the dev hub cannot affect prod clusters — the failure is contained to one compartment. Defence in depth means prod clusters require a separate credential, a separate ArgoCD instance, and a separate PR merged to a separate hub's scope before anything reaches them.

*Cost:* multiple ArgoCD instances to operate. Shared config (RBAC, repositories, projects) must be reproduced or templated across hubs.

---

**7. Hub Applications are pre-rendered; component Applications are live-rendered**
*Principle: Apply Constraints at the Right Layer (Appropriate Consistency)*

Not every layer of a system needs the same consistency model. Hub Applications change rarely (only when clusters are added or moved between hubs) — pre-rendering them gives high auditability at low Git churn. Component Applications change constantly (group value updates, new components) — pre-rendering all of them would produce enormous Git diffs every time a shared group value changes. The principle is to apply the stronger consistency guarantee (committed YAML, full audit trail) where the cost is low and the benefit is high, and use the lighter model (live render) where strong consistency would create noise.

*Cost:* you cannot see exactly what component Applications will be created by reading Git alone — you need `helm template` locally or argocd-diff-preview on the PR. The `hub/rendered/` file serves as the argocd-diff-preview entry point (see [PR diff visibility](#pr-diff-visibility-with-argocd-diff-preview)).

---

**8. No ApplicationSet**
*Principle: YAGNI (You Aren't Gonna Need It) + Minimise External Dependencies*

Applications are generated by Helm templates, not by an ApplicationSet controller. The generation logic is explicit, version-controlled in this repo, and testable offline with `helm template` — no running controller required. This was a pragmatic choice for compatibility with older ArgoCD versions where ApplicationSet was not bundled, and it keeps the blast radius of a template bug contained to a CI failure rather than a live controller acting on the cluster.

*Cost:* no automatic cluster discovery — every cluster must be explicitly registered in `clusters.yaml`. See `hub/option-b-applicationset.yaml` for what an ApplicationSet bootstrap would look like.

---

### Principles at a glance

| Opinion | Primary principle | Secondary principle |
|---|---|---|
| Groups = general-purpose composition (capability, environment, region, …) | Separation of Concerns | Composition over Inheritance |
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
        └── hub-clusters-dev          ─┐
        └── hub-clusters-prod-a       ─┤ ← run by ArgoCD at sync time
        └── hub-clusters-prod-b       ─┘
              │  Input:  clusters.yaml + groups/ + clusters/
              │          filtered to clusters where hub == currentHub
              │  Output: one Application per enabled component per cluster
              │
              └── site-dc1-cert-manager
              └── site-dc1-nmstate
              └── site-dc1-kubevirt-hyperconverged
              └── site-edge-1-cert-manager  ...
```

| Chart | Run by | Input | Output |
|---|---|---|---|
| `hub-bootstrap` | GitHub Action (CI) | `clusters.yaml` | One `hub-clusters-<hub>` Application per hub — committed to `hub/rendered/` |
| `hub-clusters` | ArgoCD at sync time | `clusters.yaml` + group/cluster values | One component Application per enabled app per cluster |
| `cluster-apps` | Render script (Approach A alt) | cluster values file with `groups:` | One component Application per cluster — committed per cluster |

**Why two charts for the top two levels?** `hub-bootstrap` is never run by ArgoCD — it runs in CI because of the chicken-and-egg problem: ArgoCD needs a hub Application to exist before it can create Applications. The GitHub Action breaks this by rendering `hub-bootstrap` offline and committing the output. ArgoCD then manages `hub-clusters-*` live, no pre-rendered output needed at the cluster level.

---

## Folder layout

```
helm-component-pattern/
├── clusters.yaml              # Central cluster inventory: hub, groups, server, shared attributes
├── charts/
│   ├── cluster-apps/          # Approach A: per-cluster Application generator (render script)
│   ├── hub-clusters/          # Approach B: per-cluster Application generator (live ArgoCD render)
│   └── hub-bootstrap/         # Approach B: per-hub Application generator (GitHub Action only)
├── components/                # Individual platform component charts (the deployables)
│   ├── nmstate/
│   └── cert-manager/
├── groups/                    # Composable cluster profiles
│   ├── all/values.yaml        # component-all: fleet baseline (lowest priority)
│   ├── virt-enabled/values.yaml  # component-virt-enabled: enables OCP Virt
│   └── edge-sno/values.yaml   # component-edge-sno: resource tuning for SNO
├── clusters/                  # One directory per cluster — Approach B format (overrides only)
│   ├── site-dc1/values.yaml   # component-site-dc1: app overrides; no groups: or cluster: block
│   ├── site-edge-1/values.yaml
│   ├── site-dc2/values.yaml
│   └── site-dev-1/values.yaml
│   # In Approach A you would also have clusters/<name>/rendered/applications.yaml
│   # (pre-rendered by scripts/render-clusters.sh). Not present here — this repo uses Approach B.
├── hub/
│   ├── bootstrap-root.yaml           # The ONE Application applied by hand (watches hub/rendered/)
│   ├── rendered/
│   │   └── hub-applications.yaml     # Generated by hub-bootstrap chart — committed by GitHub Action
│   ├── option-a-applications.yaml    # Approach A alt: explicit Application per cluster
│   ├── option-b-applicationset.yaml  # Approach A alt: ApplicationSet auto-discovery
│   └── legacy/                       # Reference: hand-authored hub Applications (superseded)
│       ├── prod-a-hub-clusters.yaml
│       └── dev-hub-clusters.yaml
├── .github/workflows/
│   └── render-hub-applications.yml   # Renders hub-bootstrap chart → commits hub/rendered/
└── scripts/
    └── render-clusters.sh     # Approach A only: offline render → clusters/*/rendered/
```

---

## The `component-<name>` convention

Each values file stores its configuration under a key named `component-<name>`. Group files use `component-<groupName>`; cluster files use `component-<clusterName>`. When Helm loads multiple `--values` files, all `component-*` keys land as separate top-level entries in `.Values` — they never collide because each is namespaced by name. The template merges them in a controlled order using `mustMergeOverwrite`.

**Group files** look the same in both approaches:

```yaml
# groups/all/values.yaml
component-all:
  apps:
    nmstate:
      enabled: true
      channel: stable
    kubevirt-hyperconverged:
      enabled: false   # disabled by default; virt-enabled group enables it

# groups/virt-enabled/values.yaml
component-virt-enabled:
  apps:
    kubevirt-hyperconverged:
      enabled: true
      channel: stable
    nmstate:
      channel: stable-4.16   # override the all-group default
```

**Cluster files differ by approach** — this is the key schema difference:

```yaml
# Approach B (hub-clusters) — clusters/<name>/values.yaml
# App overrides only. Identity and group membership live in clusters.yaml.
component-site-dc1:
  apps:
    cert-manager:
      installPlanApproval: Manual   # production override

# Approach A (cluster-apps + render script) — clusters/<name>/values.yaml
# Must declare groups (for merge order) and cluster metadata (for destination).
groups:
  - all
  - virt-enabled
component-site-dc1:
  cluster:
    name: site-dc1
    server: https://api.site-dc1.example.com:6443
    environment: production
  apps:
    cert-manager:
      installPlanApproval: Manual
```

> **The files in `clusters/` in this repo use Approach B format.** If using Approach A, ensure cluster files include `groups:` and a `cluster:` block — `charts/cluster-apps` reads both. Without `groups:`, no group merging occurs and Applications are generated with un-merged group defaults.

---

## Resolution in the Helm templates

Both charts use the same `mustMergeOverwrite` model. The difference is where the merge inputs come from:

| Step | Approach A (`cluster-apps`) | Approach B (`hub-clusters`) |
|------|----------------------------|---------------------------|
| 1 | Read `groups:` from **cluster values file** | Read `groups:` from **`clusters.yaml`** entry |
| 2 | Merge `component-<group>` keys in declared order | Same — merge in `groups:` order from `clusters.yaml` |
| 3 | Merge `component-<clusterName>` last (highest priority) | Same |
| 4 | Cluster metadata from `component-<clusterName>.cluster` | Cluster metadata injected from `clusters.yaml` — overwrites any `cluster:` in component values |
| 5 | Write resolved values to `spec.source.helm.values` | Same |

**`mustMergeOverwrite` vs `mergeOverwrite`:**
- `mergeOverwrite` — shallow map replacement at the top level
- `mustMergeOverwrite` — deep map merge; a nested key in the source only updates that key, not the whole parent map. Panics on type conflicts (e.g. string vs map), catching schema errors at render time.

**`enabled: false` semantics:** Templates use `toString` comparison (`ne (toString ...) "false"`) rather than `default true`. Helm's `default` treats `false` as empty and would incorrectly re-enable a disabled component.

---

## Example: what site-dc1 resolves to (Approach B)

`site-dc1` belongs to groups `all` and `virt-enabled` (declared in `clusters.yaml`). The hub-clusters chart, when running on the `prod-a` hub:

| Step | Source | Effect |
|------|--------|--------|
| 1a | `component-all` | `nmstate` channel stable, `cert-manager` Automatic, `kubevirt` **disabled** |
| 1b | `component-virt-enabled` | `kubevirt` **enabled**, `nmstate` channel → stable-4.16 |
| 2  | `component-site-dc1` | `cert-manager` installPlanApproval → **Manual** |
| 3  | `clusters.yaml` entry | `cluster:` block injected (name, server, vault, monitoring) |

Result — three Applications, each with the `cluster:` block from `clusters.yaml`:

| Application | Key resolved values |
|-------------|---------------------|
| `site-dc1-nmstate` | channel: stable-4.16 |
| `site-dc1-cert-manager` | installPlanApproval: Manual, cluster.vault.server populated |
| `site-dc1-kubevirt-hyperconverged` | enabled: true |

`site-edge-1` (groups: `all`, `edge-sno`) resolves to two Applications — no kubevirt, cert-manager with reduced resource requests.

---

## Approach B — hub-clusters chart with multi-hub filtering and `clusters.yaml`

This approach eliminates the render script entirely. Argo CD calls `helm template` on the `charts/hub-clusters/` chart at sync time. The chart reads `clusters.yaml` (the single authoritative cluster inventory), filters by the `currentHub` parameter, and generates all component Applications live. No output is pre-committed to Git.

### `clusters.yaml` — the single source of truth for cluster identity

```yaml
# clusters.yaml
clusters:
  - name: site-dc1
    hub: prod-a               # which Argo CD hub instance manages this cluster
    environment: production
    region: us-east
    server: https://api.site-dc1.example.com:6443
    groups:                   # mustMergeOverwrite order (lowest → highest priority)
      - all
      - virt-enabled
    # Shared attributes — injected into every component Application's cluster: block
    vault:
      server: https://vault.prod-a.example.com
      clusterSecretStoreName: vault-backend
    monitoring:
      remoteWriteEndpoint: https://mimir.prod-a.example.com/api/v1/push
```

**What lives in `clusters.yaml`:** cluster identity (name, hub, server, environment, region), group membership, and shared operational attributes (vault endpoints, monitoring configuration, pull-secret references, etc.).

**What does NOT live in `clusters.yaml`:** component-level configuration (operator channels, resource limits, installPlanApproval). Those remain in `groups/` and `clusters/<name>/values.yaml`.

### The `cluster:` block in every component

The hub-clusters chart strips `groups:` from each `clusters.yaml` entry and injects the rest as the `cluster:` block in every generated Application's `spec.source.helm.values`:

```yaml
# Generated Application for site-dc1-cert-manager
spec:
  source:
    helm:
      values: |
        cluster:               # ← from clusters.yaml, not from cert-manager values
          name: site-dc1
          hub: prod-a
          environment: production
          vault:
            server: https://vault.prod-a.example.com
            clusterSecretStoreName: vault-backend
          monitoring:
            remoteWriteEndpoint: https://mimir.prod-a.example.com/api/v1/push
        channel: stable-v1     # ← from group/cluster component merge
        installPlanApproval: Manual
```

A component chart that needs the Vault endpoint uses `.Values.cluster.vault.server` — once, in its own template — rather than each cluster repeating this value per component. Shared attributes propagate automatically when updated in `clusters.yaml`.

### Multi-hub architecture

One `hub-clusters` Application per hub. Each Application sets `currentHub` as a Helm parameter. The chart filters `clusters.yaml` to only the clusters where `hub == currentHub`:

```
Git repository (clusters.yaml + groups/ + clusters/)
         │
         ├── prod-a hub cluster (hub-clusters-prod-a Application)
         │     currentHub=prod-a → renders site-dc1, site-edge-1
         │
         ├── prod-b hub cluster (hub-clusters-prod-b Application)
         │     currentHub=prod-b → renders site-dc2
         │
         └── dev hub cluster (hub-clusters-dev Application)
               currentHub=dev → renders site-dev-1
```

All hubs read from the same Git source. A change to `groups/all/values.yaml` affects every cluster on every hub when each hub's Application next syncs. A change to `hub: prod-b` in `clusters.yaml` moves a cluster from one hub's scope to another — no changes required to the hub Applications themselves.

### Cluster values files are now just overrides

With `clusters.yaml` owning identity and group membership, `clusters/<name>/values.yaml` shrinks to contain only component-level deviations from group defaults:

```yaml
# clusters/site-dc1/values.yaml — entire file
component-site-dc1:
  apps:
    cert-manager:
      installPlanApproval: Manual   # production override
```

If a cluster has no deviations, the file can be empty or omitted entirely.

### Hub Applications are also generated — `charts/hub-bootstrap/`

The hub Applications themselves (`hub-clusters-<hub>`) were previously hand-authored YAML that required manual updates whenever a cluster was added or a group changed. The `charts/hub-bootstrap/` chart generates them automatically from `clusters.yaml`.

For each distinct `hub:` value in `clusters.yaml`, the chart emits one Application. The `valueFiles` list is derived entirely from the cluster data — no manual maintenance required:

```yaml
# Generated output in hub/rendered/hub-applications.yaml (excerpt)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hub-clusters-prod-a
  annotations:
    hub-bootstrap/clusters: "site-dc1, site-edge-1"
    hub-bootstrap/groups: "all, virt-enabled, edge-sno"
spec:
  source:
    path: devops/argo/examples/helm-component-pattern/charts/hub-clusters
    helm:
      parameters:
        - name: currentHub
          value: prod-a
      valueFiles:
        - ../../clusters.yaml
        - ../../groups/all/values.yaml
        - ../../groups/virt-enabled/values.yaml   # ← derived from site-dc1's groups
        - ../../groups/edge-sno/values.yaml        # ← derived from site-edge-1's groups
        - ../../clusters/site-dc1/values.yaml
        - ../../clusters/site-edge-1/values.yaml
```

Adding a cluster to `clusters.yaml` regenerates this list automatically. The prod-b Application and its `site-dc2` entry appear with no extra configuration beyond the `clusters.yaml` entry.

### The full bootstrap chain

```
                              ┌─ applied by hand ONCE ─┐
                              │                         │
                    oc apply -f hub/bootstrap-root.yaml
                              │
                              ▼
               Application: hub-bootstrap-root
               Watches: hub/rendered/hub-applications.yaml
               (kept current by GitHub Action)
                              │
                              ▼
         ┌────────────────────┼────────────────────┐
         │                   │                    │
Application:           Application:          Application:
hub-clusters-dev       hub-clusters-prod-a    hub-clusters-prod-b
Runs: charts/hub-clusters  (same)            (same)
currentHub=dev        currentHub=prod-a     currentHub=prod-b
         │                   │                    │
         ▼                   ▼                    ▼
  site-dev-1:         site-dc1:             site-dc2:
  cert-manager        cert-manager          cert-manager
  nmstate             nmstate               nmstate
                      kubevirt              kubevirt
                      site-edge-1:
                      cert-manager
                      nmstate
```

### The GitHub Action breaks the chicken-and-egg

The hub Applications need to exist in Argo CD before Argo CD can manage them — but they should not be hand-maintained. The GitHub Action runs `helm template charts/hub-bootstrap --values clusters.yaml` and commits the rendered output to `hub/rendered/`. The bootstrap-root Application (applied once by hand) watches that directory. No render script is needed for the hub layer — the Action is the render step:

```yaml
# .github/workflows/render-hub-applications.yml — key step
- name: Render hub Applications
  run: |
    helm template hub-bootstrap charts/hub-bootstrap \
      --values clusters.yaml \
    > hub/rendered/hub-applications.yaml
```

Triggers: any change to `clusters.yaml`, `groups/**`, `clusters/**`, or either chart. The `[skip ci]` commit message prevents re-triggering the Action on the render commit itself.

When adding a cluster to a hub:
1. Add the entry to `clusters.yaml`
2. Optionally add `clusters/<name>/values.yaml` for component overrides
3. Merge PR → Action renders hub Applications → bootstrap-root picks up the change → hub-clusters creates the new cluster's component Applications

### Approach A vs Approach B — when to choose each

| | Approach A (render script + pre-rendered) | Approach B (hub-clusters, live render) |
|---|---|---|
| Render timing | Offline — developer runs the script | Live — Argo CD renders at sync time |
| Git diff on PR | Explicit — `clusters/*/rendered/` shows exact manifests | Implicit — must run `helm template` or use argocd-diff-preview to see output |
| Argo CD version | Any | Any (no ApplicationSet required for hub-clusters) |
| Multi-hub support | Per-hub bootstrap files + rendered dirs per cluster | Native — `currentHub` parameter filters `clusters.yaml` |
| `clusters.yaml` | Not required — cluster metadata in cluster values files | Required — single source of truth for cluster identity |
| Cluster values file | `cluster:` block + `groups:` + app overrides | App overrides only (identity/groups live in `clusters.yaml`) |
| Scale | Works; render script output grows with fleet | Scales naturally; chart handles any number of clusters |

---

## PR diff visibility with argocd-diff-preview

Approach B trades explicit rendered output for a live render. To regain the "what exactly changes in the cluster?" answer on every PR, the recommended complement is **argocd-diff-preview** by dag-andersen.

The tool spins up a temporary Argo CD instance, renders the current branch and the PR branch independently, and posts a desired-state-to-desired-state diff as a PR comment. Unlike a current-state diff, this shows only what the PR changes — no unrelated cluster drift, no pending reconciliations.

### Why `hub/rendered/hub-applications.yaml` is the bootstrapping anchor

argocd-diff-preview needs a **static Application file** as its entry point — a committed YAML file it can open, find `kind: Application` objects in, and then follow each Application's `source.path` to render what it would produce.

In a fully live-rendered system (no committed files at all), the tool has nothing to start from. `hub/rendered/hub-applications.yaml` solves this: it is a real, committed YAML file containing `hub-clusters-dev`, `hub-clusters-prod-a`, and `hub-clusters-prod-b` Application objects. The tool can:

```
1. Read hub/rendered/hub-applications.yaml
   → finds hub-clusters-prod-a
     source.path:   charts/hub-clusters
     helm.values:   currentHub=prod-a
     valueFiles:    clusters.yaml, groups/all/values.yaml, ...

2. Run helm template charts/hub-clusters ... (for both PR branch and base branch)
   → produces component Application objects (site-dc1-cert-manager, etc.)

3. Diff the two rendered outputs
   → posts exactly which component Applications changed, were added, or removed
```

This means the "partial rendered manifest" design at the hub layer — which exists to solve the chicken-and-egg bootstrapping problem — also provides a natural, stable entry point for CI diff tooling. The committed file serves two purposes.

**Running on OpenShift without cluster-admin:** deploy argocd-diff-preview into a dedicated namespace (e.g. `argocd-diff`) using a namespace-scoped Argo CD instance (the OpenShift GitOps operator supports this). CI uses only namespace-scoped credentials — no production Argo CD access required.

See the library entry: [`library/argocd-diff-preview.md`](../../../../library/argocd-diff-preview.md)

Reference videos:
- [https://www.youtube.com/watch?v=3aeP__qPSms](https://www.youtube.com/watch?v=3aeP__qPSms)
- [https://www.youtube.com/watch?v=fcajag5di68](https://www.youtube.com/watch?v=fcajag5di68)

---

## Hub bootstrap — Option A vs Option B

Two files in `hub/` cover different Argo CD environments. The render workflow and the `components/groups/clusters` structure are identical — only the bootstrap mechanism differs.

### Option A — explicit Applications (`hub/option-a-applications.yaml`)

One Argo CD `Application` object per cluster, all in a single file. No ApplicationSet controller required.

```yaml
# hub/option-a-applications.yaml — excerpt
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: site-dc1-rendered
  namespace: openshift-gitops
  annotations:
    helm-component-pattern/groups: "all, virt-enabled"   # human-readable, not functional
spec:
  source:
    path: devops/argo/examples/helm-component-pattern/clusters/site-dc1/rendered
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-gitops
  syncPolicy:
    automated: {prune: true, selfHeal: true}
```

**Onboarding a new cluster:** create `clusters/<name>/rendered/`, render, then add a new Application block to this file and apply it.

**When to choose:**
- Argo CD version < 2.0, or ApplicationSet controller not installed or disabled by policy
- Preference for explicit cluster registration — a cluster does not exist in Argo CD until someone adds it here; no implicit discovery
- Simpler mental model for teams new to GitOps

### Option B — ApplicationSet (`hub/option-b-applicationset.yaml`)

A single `ApplicationSet` with a Git directory generator that discovers every `clusters/*/rendered/` directory and generates one child `Application` per cluster automatically.

```yaml
# hub/option-b-applicationset.yaml — excerpt
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
spec:
  generators:
    - git:
        directories:
          - path: devops/argo/examples/helm-component-pattern/clusters/*/rendered
  template:
    spec:
      source:
        path: "{{path}}"    # resolved per discovered directory
```

**Onboarding a new cluster:** create `clusters/<name>/rendered/`, render, commit — the ApplicationSet auto-discovers the new directory without any change to the bootstrap file.

**When to choose:**
- Argo CD 2.x with ApplicationSet controller (ships by default with OpenShift GitOps operator)
- Fleet is growing; manual Application registration does not scale
- Prefer convention over configuration — the directory structure IS the cluster registry

### Side-by-side comparison

| | Option A — Applications | Option B — ApplicationSet |
|---|---|---|
| Argo CD version | Any (1.x, 2.x) | 2.0+ with ApplicationSet controller |
| Cluster registration | Manual — add Application block to `hub/option-a-applications.yaml` | Automatic — create `clusters/<name>/rendered/` directory |
| New cluster PR change | `clusters/<name>/rendered/applications.yaml` + `hub/option-a-applications.yaml` | `clusters/<name>/rendered/applications.yaml` only |
| Accidental cluster | Impossible — explicit registration required | Possible — a stray `rendered/` directory creates an Application |
| Audit trail | Application objects named and labelled per cluster in a single file | ApplicationSet template; child Application names are generated |
| Drift detection | Per-Application; each cluster's sync status is independent | Same; ApplicationSet creates standard Application objects |
| Render workflow | Identical | Identical |

**Both options** apply the same pre-rendered Application objects from `clusters/<name>/rendered/`. The choice only affects how those objects are registered with Argo CD.

---

## Render and deploy workflow

```
1. Edit a group or cluster values file.

2. Re-render the affected cluster(s):
   ./scripts/render-clusters.sh site-dc1
   # or render everything:
   ./scripts/render-clusters.sh

3. Review the diff:
   git diff clusters/site-dc1/rendered/applications.yaml
   # The diff shows exactly what Argo CD will apply — no template indirection.

4. Open a PR. CI validates the rendered YAML (kubeval, conftest, etc.)

5. Merge → Argo CD's ApplicationSet discovers rendered/ and applies the objects.
```

### Onboarding a new cluster (Approach A — render script)

```bash
# 1. Create the cluster directory
mkdir -p clusters/site-dc2/rendered

# 2. Write the values file — Approach A format requires groups: and cluster:
cat > clusters/site-dc2/values.yaml <<'EOF'
groups:
  - all
  - virt-enabled

component-site-dc2:
  cluster:
    name: site-dc2
    server: https://api.site-dc2.example.com:6443
    environment: production
  apps: {}   # no cluster-specific overrides; group defaults apply
EOF

# 3. Render
./scripts/render-clusters.sh site-dc2

# 4. Review, commit, and PR
git add clusters/site-dc2/
git diff --staged
```

### Onboarding a new cluster (Approach B — hub-clusters)

See the [Approach B section](#approach-b--hub-clusters-chart-with-multi-hub-filtering-and-clustersyaml) — cluster onboarding is done by adding to `clusters.yaml` and merging a PR.

---

## Adding a new component

1. Create `components/<name>/` with a `Chart.yaml`, `values.yaml`, and templates.
2. Add `<name>: {enabled: false, ...}` to `groups/all/values.yaml` under `component-all.apps` — disabled by default so existing clusters are not affected.
3. Enable it in the relevant group (`groups/<profile>/values.yaml`) or per cluster.
4. Re-render all clusters: `./scripts/render-clusters.sh`
5. Review diffs — only clusters in the enabling group or with cluster-level overrides will show a new Application.

---

## Differences from the ApplicationSet framework

| Aspect | [ApplicationSet framework](../framework/) | This pattern |
|--------|------------------------------------------|--------------|
| Value resolution | Argo CD cascades `valueFiles` at sync time | Helm resolves offline; baked into rendered Applications |
| Diff visibility | You see template changes; rendered output requires `helm template` locally | Every PR diff shows the exact Application YAML that will be applied |
| Group composition | N groups listed in ApplicationSet template `valueFiles` | `groups:` list in cluster values; render script builds `--values` flags |
| Merge mechanism | Helm's standard last-wins map replacement | `mustMergeOverwrite` — deep map merge, type-conflict detection |
| When to use | Simpler setups; Argo CD manages rendering | Auditable pre-rendered output preferred; CI validation of Application objects required |

---

*AI-assisted content. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for review status details.*

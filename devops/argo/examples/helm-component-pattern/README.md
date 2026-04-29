# Platform component delivery at fleet scale

*Composable group-based GitOps for OpenShift fleets — ArgoCD only, no RHACM required.*

---

## Who this is for

**Platform engineers and consultants** rolling out or managing a fleet of OpenShift clusters, looking for a structured GitOps-native way to manage platform components across clusters that share most config but differ in meaningful ways.

**CoP maintainers** — this pattern builds on the conventions established in [redhat-cop/gitops-standards-repo-template](https://github.com/redhat-cop/gitops-standards-repo-template). The folder structure and composable groups model are the same; the implementation choices differ. See [docs/cop-maintainers.md](docs/cop-maintainers.md) for a full comparison, trade-off analysis, and guidance on choosing between them.

---

## Further reading

| Document | Audience |
|---|---|
| [docs/architecture-opinions.md](docs/architecture-opinions.md) | The problem, the principle, the Hub concept, and the 9 design opinions with full trade-offs |
| [docs/cop-maintainers.md](docs/cop-maintainers.md) | CoP maintainers: relationship to gitops-standards, Helm vs Kustomize trade-offs, choosing between them |
| [docs/diffing-and-visibility.md](docs/diffing-and-visibility.md) | PR-level desired-state diffs, fleet-wide live-to-desired diffs, argocd-diff-preview integration |
| [docs/convergence.md](docs/convergence.md) | *(Aspirational)* How this pattern and gitops-standards could converge; `sourceType` per component; open questions |
| [docs/operator-management.md](docs/operator-management.md) | Operator installation via OLM, `operators-installer` integration, version pinning, operator+instance split |

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

For the full design rationale — including the problem statement, the principle, Hub topology explained, and all 9 opinions with their complete trade-offs — see **[docs/architecture-opinions.md](docs/architecture-opinions.md)**.

Brief summary of the key decisions:

| Opinion | One-line summary |
|---|---|
| Groups = general-purpose composition | Capability, environment, region — any axis that makes sense. Clusters compose multiple groups. |
| Opt-out defaults, opt-in per group | `component-all` disables everything. Groups explicitly enable. Safer than opt-in-by-default. |
| `clusters.yaml` as single identity source | One file = complete fleet topology. Shared attributes (Vault, monitoring) defined once, injected into all components. |
| `mustMergeOverwrite` over `mergeOverwrite` | Deep map merge with type-conflict panic. Lists require `extra*/concat` — see the Resolution section below. |
| Explicit group order (`hubConfig.groupOrder`) | Merge priority is a policy decision, not an ordering side-effect. |
| One ArgoCD per hub | Blast-radius isolation. No single point of failure across all environments. No cross-hub visibility without RHACM. |
| Hub pre-rendered; components live-rendered | Committed hub Applications enable CI diff tooling; component churn stays live. |
| No ApplicationSet | Generation in Helm templates — testable offline, no controller dependency. |

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

**Lists are not merged — they are replaced.** Neither `mergeOverwrite` nor `mustMergeOverwrite` concatenates YAML sequences across layers. The higher-priority layer's list wins outright. Components that need additive list behaviour (imagePullSecrets, CIDR ranges, alerting silences, etc.) must use the `extra*/concat` pattern from the [`../framework/`](../framework/) charts: define the base array under the primary key and a companion `extra<Name>: []` key for per-layer additions, then concatenate in the template with `concat .Values.<key> .Values.extra<Name>`.

**`enabled: false` semantics:** Templates use `toString` comparison (`ne (toString ...) "false"`) rather than `default true`. Helm's `default` treats `false` as empty and would incorrectly re-enable a disabled component.

### Silent failure modes and guardrails

`mustMergeOverwrite` panics on type conflicts — that is the loud failure. There are also quiet failures to be aware of:

| Failure mode | What happens | How to detect | Guardrail |
|---|---|---|---|
| **Typo in component key name** | `component-virt-enabeld` is ignored silently — no merge, no error | `helm template` output has fewer Applications than expected for that group | CI: after render, assert expected Application names are present (grep or a test script) |
| **Cluster in `clusters.yaml` with no values file** | Cluster gets only group-default values — may be correct or may be missing overrides | Render output has no cluster-level overrides; may be intentional | Convention: always create `clusters/<name>/values.yaml`, even if empty, as an explicit acknowledgement |
| **Group in cluster's `groups:` list with no values file** | Group is silently skipped — no merge, no error | Applications have only the lower-priority groups' values | CI: add a check that every group name in `clusters.yaml` has a corresponding `groups/<name>/values.yaml` |
| **Component key only in cluster file, not in any group** | Component is disabled by `component-all`'s `enabled: false` default; cluster override never fires | Application is not generated | Always define the component in `component-all` first (even as `enabled: false`), then enable in a group or cluster |
| **`clusters.yaml` entry with no `hub:` field** | Cluster is excluded from all hubs; no Applications generated | `helm template` with any hub produces no output for that cluster | Make `hub:` a required field; consider a CI lint step that validates `clusters.yaml` schema |

**Recommended CI assertions (Approach B):**

```bash
# After rendering hub-applications, verify expected hub names appear
helm template hub-bootstrap charts/hub-bootstrap \
  --values clusters.yaml ... \
  | grep "name: hub-clusters-" | sort

# After a full hub render, check that expected cluster Applications exist
helm template hub-clusters charts/hub-clusters \
  --values clusters.yaml --values groups/all/values.yaml \
  --set currentHub=prod-a ... \
  | grep "^  name:" | sort > rendered-apps.txt

# Diff against a known-good baseline or check for minimum expected names
grep "site-dc1-cert-manager\|site-dc1-nmstate" rendered-apps.txt || \
  { echo "MISSING EXPECTED APPLICATIONS"; exit 1; }
```

The `scripts/trace-value.sh` equivalent from `../framework/` is worth building for this pattern — a script that takes a cluster name and component name and traces which layer set each value, making merge order visible without inspecting template internals.

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

### `clusters.yaml` — the fleet inventory and what it centralises

`clusters.yaml` is the single file a reader goes to for a complete picture of the fleet: every cluster, which hub manages it, which groups it belongs to, and the shared attributes that propagate to every component deployed on it.

```yaml
# The full entry for a production virt cluster — everything in one place
- name: site-dc1
  hub: prod-a
  environment: production
  region: us-east
  server: https://api.site-dc1.example.com:6443
  groups:
    - all
    - virt-enabled
  vault:
    server: https://vault.prod-a.example.com          # used by cert-manager, ESO, ...
    clusterSecretStoreName: vault-backend              # used by any ESO-backed component
  monitoring:
    remoteWriteEndpoint: https://mimir.prod-a.example.com/api/v1/push  # used by node-exporter, kube-state-metrics, ...
```

Every field under `vault:` and `monitoring:` is injected as `.Values.cluster.vault.*` and `.Values.cluster.monitoring.*` into every component Application on that cluster. A component chart references `.Values.cluster.vault.server` once — it does not declare it per cluster.

**The centralisation rule:** if more than one component chart reads the same value, that value belongs in `clusters.yaml`, not in a group or cluster values file. See the guardrails in [Opinion #3](#opinions-baked-in) for the full decision table.

### Cluster values files are now just overrides

With `clusters.yaml` owning identity, group membership, and shared attributes, `clusters/<name>/values.yaml` shrinks to contain only component-level deviations from group defaults:

```yaml
# clusters/site-dc1/values.yaml — entire file
component-site-dc1:
  apps:
    cert-manager:
      installPlanApproval: Manual   # production override — this cluster only
```

If a cluster has no deviations, the file can be empty or omitted entirely. The pattern is intentionally asymmetric: `clusters.yaml` is always populated; cluster value files are often empty.

### `targetRevision` — three-level resolution

By default every component Application points to the same git ref as the hub Application (`main`, or whatever revision the hub Application uses). `targetRevision` can be overridden at three levels, evaluated in order — last one wins:

| Level | Set in | Typical use |
|---|---|---|
| **1 — Hub default** | Hub Application `spec.source.targetRevision` | Fleet baseline (usually `main`) |
| **2 — Group** | Group entry as an object in `groups:` | Pin an entire group (e.g. all edge clusters) to a release candidate |
| **3 — Cluster** | `targetRevision:` field on the cluster entry in `clusters.yaml` | Pin one specific cluster independent of its group |

#### Group-level pin

Groups in the `groups:` list can be plain strings (the default, no pin) or objects with a `targetRevision` field:

```yaml
# clusters.yaml
clusters:
  - name: site-edge-1
    hub: prod-a
    groups:
      - all                           # plain string — no pin
      - name: edge-sno
        targetRevision: release/v2.0-rc1   # all edge-sno clusters track the RC
```

Groups are walked in declaration order; a later group's `targetRevision` overrides an earlier one. The cluster entry's `targetRevision` (level 3) overrides both.

#### Cluster-level pin

```yaml
# clusters.yaml
clusters:
  - name: site-dev-1
    hub: dev
    targetRevision: feature/new-nmstate-config   # this cluster only
    groups: [all]
```

#### Typical promotion workflows

**Canary individual cluster** — test a branch on one cluster before merging to main:
```
main ──── site-dc1, site-dc2 (no pin)
          site-dev-1 → targetRevision: feature/cert-manager-upgrade
                     → tests pass → merge to main → all clusters upgrade
```

**Ring rollout via group** — roll a release to an entire group before the rest of the fleet:
```
groups:
  - all
  - name: edge-sno
    targetRevision: release/v2.0    # all edge clusters on the new release

site-dc1, site-dc2  →  main (fleet default)
site-edge-1, site-edge-2  →  release/v2.0 (via group)
```

**Emergency rollback** — hold one cluster back while a fix is prepared:
```yaml
- name: site-dc1
  targetRevision: release/v1.8.2   # pinned while investigating v1.9 issue
```

`targetRevision` is stripped from the `cluster:` metadata block before injection — component charts do not see it and cannot branch-test on it.

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

## Diffing and visibility

Approach B trades explicit rendered output for a live render. This creates two distinct visibility questions: "what will this PR change?" and "which clusters are currently out of sync across the fleet?"

For the full discussion — including argocd-diff-preview integration, the role of `hub/rendered/` as the CI entry point, fleet-wide live-to-desired diff approaches, and the two-layer visibility model — see **[docs/diffing-and-visibility.md](docs/diffing-and-visibility.md)**.

**Quick summary:** `hub/rendered/hub-applications.yaml` is the entry point for argocd-diff-preview. It is committed to Git by CI (via the `hub-bootstrap` render step) and provides a stable, static file that the diff tool uses to discover hub Applications and render component Applications from both the PR and base branches. The diff posted to the PR shows desired-state-to-desired-state changes — not live cluster drift. For fleet-wide live state visibility, RHACM Observability or Prometheus metric federation across hubs is needed.

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

See the [Approach B section](#approach-b--hub-clusters-chart-with-multi-hub-filtering-and-clustersyaml) below — cluster onboarding is done by adding to `clusters.yaml` and merging a PR.

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

## Converging with gitops-standards-repo-template

> **Aspirational — needs team validation.** This section sketches how the two patterns could converge. See **[docs/convergence.md](docs/convergence.md)** for the full working document, including open questions for the team.
| [docs/operator-management.md](docs/operator-management.md) | Operator installation via OLM, `operators-installer` integration, version pinning, operator+instance split |

The `hub-clusters` chart supports a `sourceType` field per component (`helm` default, `kustomize` option). This allows a mixed fleet where some components are Helm charts and some are Kustomize components, while `clusters.yaml` remains the single fleet inventory and `hub-clusters` remains the single Application generator.

See [docs/convergence.md](docs/convergence.md) for the full integration model, the `commonAnnotations` limitation, the ArgoCD multi-source sketch, and the migration path from gitops-standards-repo-template.
| [docs/operator-management.md](docs/operator-management.md) | Operator installation via OLM, `operators-installer` integration, version pinning, operator+instance split |

---

*AI-assisted content. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for review status details.*

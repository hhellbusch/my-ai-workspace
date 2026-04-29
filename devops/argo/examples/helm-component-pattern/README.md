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

For the full design rationale — including the problem statement, the principle, Hub topology explained, and all opinions with their complete trade-offs — see **[docs/architecture-opinions.md](docs/architecture-opinions.md)**.

Brief summary of the key decisions:

| Opinion | One-line summary |
|---|---|
| Groups = general-purpose composition | Capability, environment, region — any axis that makes sense. Clusters compose multiple groups. |
| Opt-out defaults, opt-in per group | `component-all` disables everything. Groups explicitly enable. Safer than opt-in-by-default. |
| `clusters.yaml` as single identity source | One file = complete fleet topology. Shared attributes (Vault, monitoring) defined once, injected into all components. |
| `mustMergeOverwrite` over `mergeOverwrite` | Deep map merge with type-conflict panic. Lists require `extra*/concat` — see the Resolution section below. |
| One ArgoCD per hub | Blast-radius isolation. No single point of failure across all environments. No cross-hub visibility without RHACM. |
| Hub pre-rendered; components live-rendered | Committed hub Applications enable CI diff tooling; component churn stays live. |
| No ApplicationSet | Generation in Helm templates — testable offline, no controller dependency. |
| componentRegistry enforces known apps | Only registered components generate Applications — prevents phantom apps from typos. |

---

## How the charts relate

Two Helm charts form a cascade. Each level generates Applications that ArgoCD then manages at the next level:

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
              └── site-dc1-nmstate-operator
              └── site-dc1-nmstate-instance
              └── site-dc1-kubevirt-hyperconverged
              └── site-edge-1-cert-manager  ...
```

| Chart | Run by | Input | Output |
|---|---|---|---|
| `hub-bootstrap` | GitHub Action (CI) | `clusters.yaml` | One `hub-clusters-<hub>` Application per hub — committed to `hub/rendered/` |
| `hub-clusters` | ArgoCD at sync time | `clusters.yaml` + group/cluster values | One component Application per enabled app per cluster; one AppProject per cluster |

**Why two charts for the top two levels?** `hub-bootstrap` is never run by ArgoCD — it runs in CI because of the chicken-and-egg problem: ArgoCD needs a hub Application to exist before it can create Applications. The GitHub Action breaks this by rendering `hub-bootstrap` offline and committing the output. ArgoCD then manages `hub-clusters-*` live, no pre-rendered output needed at the cluster level.

---

## Folder layout

```
helm-component-pattern/
├── clusters.yaml              # Central cluster inventory: hub, groups, server, shared attributes
├── charts/
│   ├── hub-clusters/          # Per-cluster Application + AppProject generator (live ArgoCD render)
│   └── hub-bootstrap/         # Per-hub Application generator (GitHub Action only)
├── components/                # Individual platform component charts (the deployables)
│   ├── nmstate/
│   │   ├── operator/          # OLM installation via operators-installer subchart
│   │   └── instance/          # NMState CR — activated after operator installs
│   └── cert-manager/
├── groups/                    # Composable cluster profiles
│   ├── all/values.yaml        # component-all: fleet baseline (lowest priority)
│   ├── virt-enabled/values.yaml  # component-virt-enabled: enables OCP Virt
│   └── edge-sno/values.yaml   # component-edge-sno: resource tuning for SNO
├── clusters/                  # One directory per cluster — app overrides only
│   ├── site-dc1/values.yaml   # component-site-dc1: overrides; identity lives in clusters.yaml
│   ├── site-edge-1/values.yaml
│   ├── site-dc2/values.yaml
│   └── site-dev-1/values.yaml
├── hub/
│   ├── bootstrap-root.yaml           # The ONE Application applied by hand (watches hub/rendered/)
│   └── rendered/
│       └── hub-applications.yaml     # Generated by hub-bootstrap — committed by GitHub Action
└── .github/workflows/
    └── render-hub-applications.yml   # Renders hub-bootstrap chart → commits hub/rendered/
```

---

## The `component-<name>` convention

Each values file stores its configuration under a key named `component-<name>`. Group files use `component-<groupName>`; cluster files use `component-<clusterName>`. When Helm loads multiple `--values` files, all `component-*` keys land as separate top-level entries in `.Values` — they never collide because each is namespaced by name. The template merges them in a controlled order using `mustMergeOverwrite`.

**Group files** enable components and provide value overrides. Structural defaults (path, syncWave) come from the `componentRegistry` in `charts/hub-clusters/values.yaml`:

```yaml
# groups/all/values.yaml
component-all:
  apps:
    nmstate-operator:
      enabled: true
      operators-installer:
        operators:
          - name: kubernetes-nmstate-operator
            channel: stable
    kubevirt-hyperconverged:
      enabled: false   # disabled by default; virt-enabled group enables it
```

**Cluster files contain only deviations from group defaults.** Identity and group membership live in `clusters.yaml`:

```yaml
# clusters/<name>/values.yaml — often just a few lines or empty
component-site-dc1:
  apps:
    cert-manager:
      installPlanApproval: Manual   # production override — this cluster only
```

---

## Resolution in the Helm templates

The `hub-clusters` chart resolves values through four steps for each cluster:

| Step | What happens |
|------|--------------|
| 1 | Read `groups:` from `clusters.yaml` for this cluster. Merge `component-<groupName>` keys in declaration order — later groups have higher priority. |
| 2 | Merge `component-<clusterName>` last — the cluster-specific values file always wins. |
| 3 | Inject cluster metadata from `clusters.yaml` as the authoritative `cluster:` block in every Application's helm values. |
| 4 | Iterate over `componentRegistry`. For each registered component that is enabled, emit an Application with the merged values and the resolved syncPolicy. |

**`mustMergeOverwrite` vs `mergeOverwrite`:**
- `mergeOverwrite` — shallow map replacement at the top level
- `mustMergeOverwrite` — deep map merge; a nested key in the source only updates that key, not the whole parent map. Panics on type conflicts (e.g. string vs map), catching schema errors at render time.

**Lists are not merged — they are replaced.** Neither `mergeOverwrite` nor `mustMergeOverwrite` concatenates YAML sequences across layers. The higher-priority layer's list wins outright. Components that need additive list behaviour (imagePullSecrets, CIDR ranges, alerting silences, etc.) must use the `extra*/concat` pattern from the [`../framework/`](../framework/) charts: define the base array under the primary key and a companion `extra<Name>: []` key for per-layer additions, then concatenate in the template with `concat .Values.<key> .Values.extra<Name>`.

**`enabled: false` semantics:** Templates use `toString` comparison (`ne (toString ...) "false"`) rather than `default true`. Helm's `default` treats `false` as empty and would incorrectly re-enable a disabled component.

### componentRegistry — preventing phantom Applications

The `componentRegistry` in `charts/hub-clusters/values.yaml` defines every component that can be deployed across the fleet. The template iterates over the registry rather than over group/cluster entries — a typo in a group file produces no Application because there is no registry entry for it.

The registry also provides structural defaults so group files stay clean:

```yaml
# charts/hub-clusters/values.yaml (excerpt)
componentRegistry:
  nmstate-operator:
    path: components/nmstate/operator   # group files don't need to repeat this
    syncWave: "0"
    description: "NMState Operator via OLM"
  cert-manager:
    path: components/cert-manager
    syncPolicy:
      automated:
        prune: false          # per-component override of global default
```

### Global sync defaults

`defaults.syncPolicy` in `charts/hub-clusters/values.yaml` provides the fleet-wide syncPolicy baseline. Merge chain (lowest → highest):

```
defaults.syncPolicy → componentRegistry.<name>.syncPolicy → group/cluster syncPolicy
```

### Silent failure modes and guardrails

`mustMergeOverwrite` panics on type conflicts — that is the loud failure. There are also quiet failures to be aware of:

| Failure mode | What happens | How to detect | Guardrail |
|---|---|---|---|
| **Typo in component key name** | `component-virt-enabeld` is ignored silently — no merge, no error | `helm template` output has fewer Applications than expected for that group | CI: after render, assert expected Application names are present |
| **Cluster in `clusters.yaml` with no values file** | Cluster gets only group-default values — may be correct or may be missing overrides | No cluster-level overrides in render output | Convention: always create `clusters/<name>/values.yaml`, even if empty |
| **Group in cluster's `groups:` with no values file** | Group is silently skipped | Applications have only lower-priority groups' values | CI: check every group name in `clusters.yaml` has a `groups/<name>/values.yaml` |
| **Component enabled in group but not in `componentRegistry`** | No Application generated — registry gates output | `helm template` produces no Application for that name | Add the component to `componentRegistry` before enabling it in a group |
| **`clusters.yaml` entry with no `hub:` field** | Cluster excluded from all hubs; no Applications generated | `helm template` with any hub produces no output for that cluster | Make `hub:` a required field; CI lint step validates `clusters.yaml` schema |

**Recommended CI assertions:**

```bash
# After rendering, check expected cluster Applications exist
helm template hub-clusters charts/hub-clusters \
  --values clusters.yaml --values groups/all/values.yaml \
  --set currentHub=prod-a ... \
  | grep "^  name:" | sort > rendered-apps.txt

grep "site-dc1-cert-manager\|site-dc1-nmstate" rendered-apps.txt || \
  { echo "MISSING EXPECTED APPLICATIONS"; exit 1; }
```

---

## Example: what site-dc1 resolves to

`site-dc1` belongs to groups `all` and `virt-enabled` (declared in `clusters.yaml`). The hub-clusters chart, when running on the `prod-a` hub:

| Step | Source | Effect |
|------|--------|--------|
| 1a | `component-all` | `nmstate-operator` channel stable, `cert-manager` Automatic, `kubevirt` **disabled** |
| 1b | `component-virt-enabled` | `kubevirt` **enabled**, `nmstate-operator` channel → stable-4.16 |
| 2  | `component-site-dc1` | `cert-manager` installPlanApproval → **Manual** |
| 3  | `clusters.yaml` entry | `cluster:` block injected (name, server, vault, monitoring) |

Result — four Applications, each with the `cluster:` block from `clusters.yaml`:

| Application | Key resolved values |
|-------------|---------------------|
| `site-dc1-nmstate-operator` | channel: stable-4.16, syncWave: 0 |
| `site-dc1-nmstate-instance` | syncWave: 5 (after operator) |
| `site-dc1-cert-manager` | installPlanApproval: Manual, prune: false, cluster.vault.server populated |
| `site-dc1-kubevirt-hyperconverged` | enabled: true |

`site-edge-1` (groups: `all`, `edge-sno`) resolves to three Applications — no kubevirt, cert-manager with reduced resource requests.

---

## `clusters.yaml` — the single source of truth for cluster identity

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

**The centralisation rule:** if more than one component chart reads the same value, that value belongs in `clusters.yaml`, not in a group or cluster values file. See the guardrails in [docs/architecture-opinions.md](docs/architecture-opinions.md) for the full decision table.

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

Hub clusters can also manage themselves — add an entry for the hub cluster with `server: https://kubernetes.default.svc` to have the same pipeline manage the hub's own platform components.

### Cluster values files are just overrides

With `clusters.yaml` owning identity, group membership, and shared attributes, `clusters/<name>/values.yaml` shrinks to contain only component-level deviations from group defaults:

```yaml
# clusters/site-dc1/values.yaml — entire file
component-site-dc1:
  apps:
    cert-manager:
      installPlanApproval: Manual   # production override — this cluster only
```

If a cluster has no deviations, the file can be empty or omitted entirely. The pattern is intentionally asymmetric: `clusters.yaml` is always populated; cluster value files are often empty.

---

## `targetRevision` — three-level resolution

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

#### Typical promotion workflows

**Canary individual cluster:**
```
main ──── site-dc1, site-dc2 (no pin)
          site-dev-1 → targetRevision: feature/cert-manager-upgrade
                     → tests pass → merge to main → all clusters upgrade
```

**Ring rollout via group:**
```
- name: edge-sno
  targetRevision: release/v2.0    # all edge clusters on the new release
```

**Emergency rollback:**
```yaml
- name: site-dc1
  targetRevision: release/v1.8.2   # pinned while investigating v1.9 issue
```

`targetRevision` is stripped from the `cluster:` metadata block before injection — component charts do not see it.

---

## AppProjects — per-cluster audit boundaries

When `appProject.enabled: true` in `charts/hub-clusters/values.yaml`, the chart generates one `AppProject` per managed cluster with destinations scoped to exactly that cluster's API server:

```yaml
# Generated for site-dc1:
spec:
  destinations:
    - server: https://api.site-dc1.example.com:6443
      namespace: "*"
```

Every Application references `spec.project: <clusterName>`. A misconfigured Application targeting the wrong cluster is rejected at the ArgoCD project level. Configure source repo restrictions and RBAC roles per-project in `appProject.sourceRepos` and `appProject.roles`.

---

## Hub Applications — `charts/hub-bootstrap/`

The hub Applications (`hub-clusters-<hub>`) are generated automatically from `clusters.yaml` by the `hub-bootstrap` chart. For each distinct `hub:` value, the chart emits one Application. The `valueFiles` list is derived entirely from the cluster data:

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
        - ../../groups/virt-enabled/values.yaml
        - ../../groups/edge-sno/values.yaml
        - ../../clusters/site-dc1/values.yaml
        - ../../clusters/site-edge-1/values.yaml
```

### The GitHub Action breaks the chicken-and-egg

The hub Applications need to exist in Argo CD before Argo CD can manage them — but they should not be hand-maintained. The GitHub Action runs `helm template charts/hub-bootstrap --values clusters.yaml` and commits the rendered output to `hub/rendered/`. The bootstrap-root Application (applied once by hand) watches that directory:

```yaml
# .github/workflows/render-hub-applications.yml — key step
- name: Render hub Applications
  run: |
    helm template hub-bootstrap charts/hub-bootstrap \
      --values clusters.yaml \
    > hub/rendered/hub-applications.yaml
```

Triggers: any change to `clusters.yaml`, `groups/**`, `clusters/**`, or either chart. The `[skip ci]` commit message prevents re-triggering the Action on the render commit itself.

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
Application:       Application:          Application:
hub-clusters-dev   hub-clusters-prod-a    hub-clusters-prod-b
currentHub=dev     currentHub=prod-a      currentHub=prod-b
     │                   │                    │
     ▼                   ▼                    ▼
site-dev-1:       site-dc1:             site-dc2:
cert-manager      cert-manager          cert-manager
nmstate           nmstate               nmstate
                  kubevirt              kubevirt
                  site-edge-1:
                  cert-manager
                  nmstate
```

---

## Diffing and visibility

The live-render model raises two distinct visibility questions: "what will this PR change?" and "which clusters are currently out of sync across the fleet?"

For the full discussion — including argocd-diff-preview integration, the role of `hub/rendered/` as the CI entry point, fleet-wide live-to-desired diff approaches, and the two-layer visibility model — see **[docs/diffing-and-visibility.md](docs/diffing-and-visibility.md)**.

**Quick summary:** `hub/rendered/hub-applications.yaml` is the entry point for argocd-diff-preview. It is committed to Git by CI and provides a stable static file the diff tool uses to discover hub Applications and render component Applications from both the PR and base branches. The diff posted to the PR shows desired-state-to-desired-state changes — not live cluster drift. For fleet-wide live state visibility, RHACM Observability or Prometheus metric federation across hubs is needed.

---

## Onboarding a new cluster

1. Add the entry to `clusters.yaml` — hub, server, groups, shared attributes:

```yaml
- name: site-dc3
  hub: prod-a
  environment: production
  region: us-west
  server: https://api.site-dc3.example.com:6443
  groups:
    - all
    - virt-enabled
  vault:
    server: https://vault.prod-a.example.com
    clusterSecretStoreName: vault-backend
  monitoring:
    remoteWriteEndpoint: https://mimir.prod-a.example.com/api/v1/push
```

2. Optionally create `clusters/site-dc3/values.yaml` for component overrides (or leave it empty).
3. Merge PR → GitHub Action re-renders hub Applications → bootstrap-root picks up the change → `hub-clusters-prod-a` creates the new cluster's component Applications.

No manual Application registration. No render script to run. The only file that requires human decision is `clusters.yaml`.

---

## Adding a new component

1. Create `components/<name>/` with a `Chart.yaml`, `values.yaml`, and templates.
   For operators, use the `operator/` + `instance/` split under `components/<name>/` — see [docs/operator-management.md](docs/operator-management.md).
2. Add the component to `componentRegistry` in `charts/hub-clusters/values.yaml` with `path`, `syncWave`, and any structural defaults.
3. Add `<name>: {enabled: false}` to `groups/all/values.yaml` under `component-all.apps` — disabled by default so existing clusters are not affected.
4. Enable it in the relevant group or per cluster.
5. Open a PR — only clusters in the enabling group or with cluster-level overrides will show a new Application in the diff.

---

## Converging with gitops-standards-repo-template

> **Aspirational — needs team validation.** See **[docs/convergence.md](docs/convergence.md)** for the full working document, including open questions for the team.

The `hub-clusters` chart supports a `sourceType` field per component (`helm` default, `kustomize` option). This allows a mixed fleet where some components are Helm charts and some are Kustomize components, while `clusters.yaml` remains the single fleet inventory and `hub-clusters` remains the single Application generator.

See [docs/convergence.md](docs/convergence.md) for the full integration model, the `commonAnnotations` limitation, the ArgoCD multi-source sketch, and the migration path from gitops-standards-repo-template.

---

*AI-assisted content. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for review status details.*

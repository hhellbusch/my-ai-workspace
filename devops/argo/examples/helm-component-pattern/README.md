# Helm component pattern — `mustMergeOverwrite` with named component keys

A GitOps framework for generating Argo CD Applications across a fleet of clusters. Configuration is composed from reusable groups using Helm's `mustMergeOverwrite`, and the resolved Applications are committed to Git so every change is visible as a diff before Argo CD applies it.

This is a different approach from the [ApplicationSet-based framework](../framework/README.md) in this repo. The key architectural distinction: **resolution happens offline in Helm, not at Argo CD sync time**. Argo CD receives pre-rendered Application objects with fully-resolved values baked in.

---

## Folder layout

```
helm-component-pattern/
├── charts/cluster-apps/       # Helm chart — generates Application objects
│   └── templates/
│       └── application.yaml   # mustMergeOverwrite resolution + Application template
├── components/                # Individual platform component charts (the deployables)
│   ├── nmstate/
│   └── cert-manager/
├── groups/                    # Composable cluster profiles
│   ├── all/values.yaml        # component-all:  fleet baseline (lowest priority)
│   ├── virt-enabled/values.yaml  # component-virt-enabled: enables OCP Virt
│   └── edge-sno/values.yaml   # component-edge-sno: resource tuning for SNO
├── clusters/                  # One directory per cluster
│   ├── site-dc1/
│   │   ├── values.yaml        # declares groups: + component-site-dc1: overrides
│   │   └── rendered/
│   │       └── applications.yaml   # pre-rendered Applications — committed to Git
│   └── site-edge-1/
│       ├── values.yaml
│       └── rendered/
│           └── applications.yaml
├── hub/
│   ├── option-a-applications.yaml    # explicit Application per cluster (any Argo CD version)
│   └── option-b-applicationset.yaml  # ApplicationSet auto-discovery (Argo CD 2.x+)
└── scripts/
    └── render-clusters.sh     # Reads groups from cluster values, runs helm template
```

---

## The `component-<name>` convention

Each values file (group or cluster) stores its configuration under a key named `component-<name>`:

```yaml
# groups/all/values.yaml
component-all:
  apps:
    nmstate:
      enabled: true
      channel: stable

# groups/virt-enabled/values.yaml
component-virt-enabled:
  apps:
    kubevirt-hyperconverged:
      enabled: true
      channel: stable
    nmstate:
      channel: stable-4.16   # override the all-group default

# clusters/site-dc1/values.yaml
groups:
  - all
  - virt-enabled
component-site-dc1:
  cluster:
    name: site-dc1
    server: https://api.site-dc1.example.com:6443
  apps:
    cert-manager:
      installPlanApproval: Manual   # cluster-level override
```

**Why named keys?** When Helm receives multiple `--values` files, all `component-*` keys end up as separate top-level entries in `.Values` — they never collide because each is namespaced by its own name. The template can then merge them in a controlled order.

---

## Resolution in the Helm template

The `charts/cluster-apps/templates/application.yaml` template merges all component keys using `mustMergeOverwrite`:

```
Step 1  Read the groups: list from the cluster values file.
        Merge each group's component-<name> in declaration order.
        (Declaration order = load order = priority order.)

Step 2  Merge the cluster-specific component-<clusterName> last.
        The cluster component is any component-* key not in the groups list.
        This key always wins — it is the highest-priority override.

Step 3  Extract cluster metadata and the resolved apps map.
        Generate one Application per app where enabled ≠ false.

Step 4  Write the resolved per-app values inline into spec.source.helm.values.
        Argo CD receives a single flat block — no further cascade at sync time.
```

**`mustMergeOverwrite` vs `mergeOverwrite`:**
- `mergeOverwrite` — shallow map replacement at the top level
- `mustMergeOverwrite` — deep map merge; a nested key in the source updates only that key in the destination, not the whole parent map. Also panics on type conflicts (e.g. string vs map), catching configuration errors at render time.

**`enabled: false` semantics:** The template uses `toString` comparison (`ne (toString ...) "false"`) rather than `default true`, because Helm's `default` function treats `false` as empty and would incorrectly enable a disabled component.

---

## Example: what site-dc1 resolves to

`site-dc1` belongs to `all` and `virt-enabled`. The render script invokes:

```bash
helm template site-dc1-apps charts/cluster-apps \
  --values groups/all/values.yaml \
  --values groups/virt-enabled/values.yaml \
  --values clusters/site-dc1/values.yaml
```

The `mustMergeOverwrite` chain:

| Step | Source | Effect |
|------|--------|--------|
| 1a | `component-all` | Sets `nmstate` stable, `cert-manager` stable-v1 Automatic, `kubevirt` **disabled** |
| 1b | `component-virt-enabled` | Sets `kubevirt` **enabled**, overrides `nmstate` channel to stable-4.16 |
| 2  | `component-site-dc1` | Sets `cert-manager` installPlanApproval to **Manual**; cluster metadata |

Result — three Applications generated:

| Application | Key resolved values |
|-------------|---------------------|
| `site-dc1-nmstate` | channel: stable-4.16 (virt-enabled group) |
| `site-dc1-cert-manager` | installPlanApproval: Manual (cluster override) |
| `site-dc1-kubevirt-hyperconverged` | enabled: true (virt-enabled group) |

**site-edge-1** (groups: `all`, `edge-sno`) resolves to two Applications: `nmstate` and `cert-manager` with reduced resource requests. `kubevirt-hyperconverged` is absent because `component-all` sets `enabled: false` and `edge-sno` does not override it.

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

### Onboarding a new cluster

```bash
# 1. Create the cluster directory
mkdir -p clusters/site-dc2/rendered

# 2. Write the values file
cat > clusters/site-dc2/values.yaml <<'EOF'
groups:
  - all
  - virt-enabled

component-site-dc2:
  cluster:
    name: site-dc2
    server: https://api.site-dc2.example.com:6443
    environment: production
EOF

# 3. Render
./scripts/render-clusters.sh site-dc2

# 4. Review, commit, and PR
git add clusters/site-dc2/
git diff --staged
```

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

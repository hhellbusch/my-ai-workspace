# Framework Requirements & Guidelines

This document captures the design intent, architectural decisions, constraints,
and conventions for the ArgoCD Fleet Management Framework. Its purpose is to
preserve context so that any contributor — human or AI — can extend, modify,
or troubleshoot the framework without violating its core invariants.

> **AI Disclosure:** This framework was designed and implemented with AI assistance.

---

## 1. Core Design Philosophy

### 1.1 Hub-and-Spoke, Single Pane of Glass

ArgoCD and RHACM run **exclusively on the hub cluster**. Spoke clusters have
no GitOps controller installed. This gives operators a single ArgoCD dashboard
per environment to monitor the entire fleet. All deployment decisions are made
centrally; spoke clusters only receive the rendered manifests.

### 1.2 Git Is the Only Source of Truth

Every piece of cluster configuration — group memberships, app opt-in/out state,
value overrides, promotion gates — lives in Git. There are **no** imperative
side-channels. If it is not committed, it does not exist.

Operator actions like `oc label` on a ManagedCluster are overwritten by RHACM
Policies generated from Git. This is intentional and by design.

### 1.3 Cascading Values with Cluster Sovereignty

The value resolution cascade provides layered defaults (fleet-wide, environment,
OCP version, infrastructure type, region) while preserving the cluster's final
say. A cluster-specific `values.yaml` can override anything from any group. This
balance allows fleet-wide consistency without removing per-cluster flexibility.

### 1.4 Declarative Opt-In/Out

Applications are deployed based on declarative labels, not procedural logic. An
operator enables or disables an app by editing a label in `cluster.yaml` and
committing. The system reacts — no scripts or manual intervention needed.

### 1.5 Progressive Change Control

Changes flow through environment stages via branch promotion (main → dev →
staging → production). Each stage can be validated independently. Production
never sees a change that has not passed through every prior gate.

---

## 2. Architectural Invariants (Do Not Violate)

These are hard constraints. Violating them breaks the framework's guarantees.

| # | Invariant |
|---|-----------|
| 1 | **No ArgoCD on spoke clusters.** All ArgoCD resources live in the hub's `openshift-gitops` namespace. |
| 2 | **`cluster.yaml` is the label source of truth.** ManagedCluster labels are set exclusively via the GitOps label sync pipeline, never manually. |
| 3 | **Cluster `values.yaml` has highest priority.** No group or app default can override a value explicitly set in `clusters/<name>/values.yaml`. |
| 4 | **The `cluster.*` namespace is shared.** Every value file — from app defaults through cluster overrides — writes under the `cluster` key. This is what makes cluster metadata universally accessible to all app templates via `.Values.cluster.*`. |
| 5 | **One ApplicationSet per app.** Each app has exactly one `applicationset.yaml` that uses the `clusters` generator. The hub app-of-apps discovers these automatically. |
| 6 | **`ignoreMissingValueFiles: true` is required.** Not every cluster belongs to every group. Missing group value files are silently skipped, which is correct behavior. |
| 7 | **`targetRevision` controls promotion.** Each hub cluster pins to its environment branch. Promotion is a PR merge between branches, not a value change. |
| 8 | **Secrets never go in Git.** BMC credentials, Vault tokens, TLS keys, and any sensitive material are stored in HashiCorp Vault and pulled onto clusters via External Secrets Operator. |
| 9 | **The label aggregation script must run before merge.** Any commit that changes a `cluster.yaml` must also include the regenerated `hub/rhacm/cluster-labels/values.yaml`. CI enforces this via drift detection. |
| 10 | **Arrays replace, maps merge.** Helm replaces arrays wholesale across value files. To accumulate array entries from multiple levels, use the `extraSilences` / `concat` pattern in the chart template — never rely on array merging. |

---

## 3. Value Cascade Contract

### 3.1 Resolution Order

```
Priority 1 (lowest):  apps/<app>/values.yaml              App chart defaults
Priority 2:           groups/all/values.yaml              Fleet-wide baseline
Priority 3:           groups/env-<env>/values.yaml        Environment group
Priority 4:           groups/ocp-<version>/values.yaml    OCP version group
Priority 5:           groups/infra-<type>/values.yaml     Infrastructure type
                      groups/region-<region>/values.yaml  Region (optional)
                      groups/<custom>/values.yaml         Custom group (optional)
Priority 6 (highest): clusters/<name>/values.yaml         Cluster-specific
```

This order is encoded in each ApplicationSet's `valueFiles` list and in the
`fleet-diff.sh` rendering script. Both must stay in sync.

### 3.2 The `cluster.*` Key Namespace

All value files write under the top-level `cluster` key. This convention means:

- App templates access cluster metadata as `.Values.cluster.name`,
  `.Values.cluster.features.monitoring.enabled`, etc.
- Groups can set defaults that clusters override at any depth.
- Apps never need to know which level set a value — they just read `.Values.cluster.*`.

Non-cluster-scoped keys (e.g. `vault.*`) are allowed at the top level for values
that are specific to a subsystem and not part of the shared cluster identity.

### 3.3 Map Merging vs Array Handling

- **Maps:** Helm deep-merges automatically. A group can set
  `cluster.features.monitoring.enabled: true` and a cluster can override
  `cluster.features.monitoring.retention: 15d` without affecting each other.
- **Arrays:** Helm replaces the entire array. To accumulate entries, define the
  full array at the group level in a primary key (e.g. `cluster.alerting.silences`)
  and provide an `extraSilences` key for cluster-level additions. The chart
  template uses `concat` to merge them.

### 3.4 Feature Flag Convention

Features follow a standard structure under `cluster.features`:

```yaml
cluster:
  features:
    <featureName>:
      enabled: false    # boolean gate — charts should check this
      # ... feature-specific configuration below
```

The `enabled` boolean is set to `false` in `groups/all/values.yaml` and
overridden to `true` by the appropriate group or cluster. Charts must gate
resource rendering on `.Values.cluster.features.<name>.enabled`.

---

## 4. Directory Structure Rules

### 4.1 Apps (`apps/<app-name>/`)

| File | Required | Purpose |
|------|----------|---------|
| `Chart.yaml` | Yes | Helm chart metadata. `name` must match directory name. |
| `values.yaml` | Yes | Lowest-priority defaults. Define every key the templates reference. |
| `applicationset.yaml` | Yes | Hub ApplicationSet. Must use `clusters` generator with label selector. |
| `templates/_helpers.tpl` | Yes | Must define common labels and any merge helpers the templates need. |
| `templates/*.yaml` | Yes | Kubernetes resource templates. Must use `.Values.cluster.*` for config. |

**Adding a new app:**
1. Copy an existing app directory.
2. Choose opt-in or opt-out model. Default to opt-in for new features.
3. If the app needs a feature flag, add a default `enabled: false` entry under
   `cluster.features` in `groups/all/values.yaml`.
4. Gate all template rendering on the feature flag using
   `{{- if .Values.cluster.features.<name>.enabled }}`.

### 4.2 Groups (`groups/<type>-<value>/`)

| Naming Pattern | Label Key | Examples |
|----------------|-----------|----------|
| `all/` | _(always applied)_ | `all/` |
| `env-*/` | `group.env` | `env-production/`, `env-non-production/` |
| `ocp-*/` | `group.ocp-version` | `ocp-4.14/`, `ocp-4.15/` |
| `infra-*/` | `group.infra` | `infra-baremetal/`, `infra-vsphere/` |
| `region-*/` | `group.region` | `region-us-east/`, `region-eu-west/` |
| `<custom>/` | `group.custom` | Any additional dimension |

Each group directory contains only a `values.yaml`. The directory name must
match the label value used in ApplicationSet `valueFiles` paths.

**Adding a new group:**
1. Create the directory: `mkdir -p groups/<type>-<value>/`.
2. Add a `values.yaml` under the `cluster` key.
3. Update `clusters/<name>/cluster.yaml` and `managedClusterLabels` for each
   cluster that should belong to the group.
4. Run the aggregation script.
5. If the group type is new (not env/ocp/infra/region/custom), update the
   ApplicationSet template's `valueFiles` list **and** `fleet-diff.sh`'s
   `render_app_cluster()` function to include the new group dimension.

### 4.3 Clusters (`clusters/<cluster-name>/`)

| File | Required | Purpose |
|------|----------|---------|
| `cluster.yaml` | Yes | Cluster identity, group memberships, app labels. Source of truth for RHACM labels. |
| `values.yaml` | Yes | Highest-priority value overrides. All keys under `cluster.*`. |

The directory name must match `cluster.name` inside `cluster.yaml`. CI validates
this. The `_template/` directory is the starting point for new clusters and must
not be renamed or removed.

### 4.4 Hub Resources (`hub/`)

- `bootstrap/hub-app-of-apps.yaml` — Apply once. Do not auto-sync this file;
  it is the bootstrap entry point.
- `applicationsets/` — Contains the hub app-of-apps target and the
  `cluster-label-sync.yaml` Application. Per-app ApplicationSets live in
  `apps/<app>/applicationset.yaml`, not here.
- `rhacm/` — ManagedClusterSet, Placement, GitOpsCluster, and the label-sync
  chart. The `cluster-labels/values.yaml` is auto-generated — do not edit manually.

### 4.5 Pipelines and Scripts

- `pipelines/github-actions/` — GitHub Actions workflows. Portable to Jenkins
  or GitLab by translating YAML syntax.
- `pipelines/promotion/` — Change control documentation (not automation).
- `scripts/` — CLI tools that work both locally and in CI.
- `automation/ansible/` — Playbooks and roles for external integrations.

---

## 5. Label Schema

Labels on `ManagedCluster` resources (and by extension, ArgoCD cluster secrets):

| Label | Values | Purpose |
|-------|--------|---------|
| `group.env` | `production`, `non-production` | Environment group selection |
| `group.ocp-version` | `4.14`, `4.15`, `4.16` | OCP version group selection |
| `group.infra` | `baremetal`, `vsphere`, `aws` | Infrastructure type group |
| `group.region` | `us-east`, `us-west`, `eu-west` | Regional group selection |
| `group.network` | `ovn-kubernetes`, `sdn` | Network type |
| `group.custom` | _(any)_ | Additional grouping dimension |
| `app.enabled/<app>` | `"true"` | Opt-in: deploy this app |
| `app.disabled/<app>` | `"true"` | Opt-out: exclude this app |

All label values are strings. Boolean-like values must be quoted (`"true"`) to
comply with Kubernetes label value constraints.

---

## 6. Change Control Rules

### 6.1 Branch Model

| Branch | Environment | Auto-sync | Gate |
|--------|-------------|-----------|------|
| `main` | Lab | Yes | CI passes |
| `release/dev` | Dev | Yes | CI + Helm lint |
| `release/staging` | Staging | Yes | CI + 1 reviewer |
| `release/production` | Production | Yes | CI + 2 reviewers |

### 6.2 Promotion Procedure

1. Merge to `main` (lab validation).
2. Create PR: `main` → `release/dev`.
3. Create PR: `release/dev` → `release/staging`.
4. Create PR: `release/staging` → `release/production`.

Each promotion is a PR. The `fleet-diff` workflow shows the rendered impact
before merge. Never skip a stage.

### 6.3 Emergency Hotfixes

Hotfixes branch directly from `release/production`, are merged to production
with expedited review, and are then **cherry-picked back** to `main` to prevent
regression on the next promotion.

### 6.4 Rollback

Revert the merge commit on the environment branch via `git revert`. This creates
a new forward commit rather than rewriting history.

---

## 7. Secrets Management Rules

| What | Where It Goes | How It Gets There |
|------|---------------|-------------------|
| BMC credentials (iDRAC) | Vault at `secret/fleet/bmc/<cluster>/<host>` | Ansible onboarding playbook |
| Cluster-specific secrets | Vault at `secret/fleet/<cluster>/*` | Manual or Ansible |
| Global shared secrets | Vault at `secret/fleet/global/*` | Manual |
| Vault auth for ESO | Vault Kubernetes auth role | Ansible onboarding playbook |

**Never commit:**
- Passwords, tokens, or API keys
- TLS private keys or certificates
- Vault tokens
- `.env` files or credential files

The External Secrets Operator on spoke clusters authenticates to Vault using
Kubernetes service account tokens. The Ansible onboarding role configures
the Vault auth role and policy per cluster.

---

## 8. Extending the Framework

### 8.1 Adding a New App

1. Create `apps/<app-name>/` with `Chart.yaml`, `values.yaml`,
   `applicationset.yaml`, and `templates/`.
2. Add a `cluster.features.<appName>.enabled: false` default in
   `groups/all/values.yaml`.
3. Choose opt-in (default) or opt-out model in the ApplicationSet.
4. Gate template rendering on the feature flag.
5. Add the app to the relevant cluster `cluster.yaml` files.
6. Run the aggregation script.

### 8.2 Adding a New Group Dimension

1. Create `groups/<type>-<value>/values.yaml`.
2. Add the new label key to the label schema (this document, the clusters
   README, and the per-app-template.yaml reference).
3. Add a new `valueFiles` entry in the ApplicationSet template at the
   appropriate priority position.
4. Update `fleet-diff.sh`'s `render_app_cluster()` to read the new group
   from `cluster.yaml` and include the value file.
5. Update the `_template/cluster.yaml` to include the new group field.

### 8.3 Onboarding a New Cluster

1. Copy `clusters/_template/` to `clusters/<cluster-name>/`.
2. Fill in `cluster.yaml` (identity, groups, apps, labels).
3. Fill in `values.yaml` (cluster-specific overrides).
4. Run the Ansible onboarding playbook for external integrations (Vault, CMDB).
5. Run the aggregation script.
6. Commit and open a PR. Promotion pipeline handles the rest.

### 8.4 Changing the Value Cascade Order

If you need to reorder priorities (e.g. make infra groups override OCP version
groups), you must update **all three** of these locations:

1. `hub/applicationsets/per-app-template.yaml` (reference template)
2. Every `apps/<app>/applicationset.yaml` (each app's live ApplicationSet)
3. `scripts/fleet-diff.sh` (the `render_app_cluster()` function)

---

## 9. Testing and Validation

### 9.1 CI Checks (Every PR)

| Check | Tool | Validates |
|-------|------|-----------|
| YAML syntax | `yamllint` | All YAML files are well-formed |
| Helm lint | `helm lint` | All charts pass linting |
| Helm template | `helm template` | All charts render without errors |
| Cluster config | `yq` + custom | `cluster.name` matches directory, required fields present, labels consistent |
| Label drift | `aggregate-cluster-config.sh` + `diff` | Committed `cluster-labels/values.yaml` matches regenerated output |
| Fleet diff | `fleet-diff.sh` | Rendered desired-state comparison posted as PR comment |

### 9.2 Local Validation

```bash
# Lint a chart
helm lint apps/<app-name>/

# Template a chart with a cluster's full cascade
helm template <app-name> apps/<app-name>/ \
  --values apps/<app-name>/values.yaml \
  --values groups/all/values.yaml \
  --values groups/env-production/values.yaml \
  --values clusters/example-prod-east-1/values.yaml

# Check label aggregation drift
bash pipelines/github-actions/aggregate-cluster-config.sh argo-examples/framework
diff hub/rhacm/cluster-labels/values.yaml /tmp/aggregated-output.yaml

# Full fleet diff between branches
bash scripts/fleet-diff.sh release/production main
```

### 9.3 What to Check After a Change

| Changed | Verify |
|---------|--------|
| App chart template | `helm template` renders, feature flag gates work |
| Group values | No unintended overrides on other clusters (use `fleet-diff.sh`) |
| Cluster values | Only the target cluster is affected (use `fleet-diff.sh --cluster`) |
| Labels in `cluster.yaml` | Aggregation script output is committed, CI passes |
| ApplicationSet selectors | Correct clusters match (check label schema) |
| New group dimension | All three cascade locations updated (see 8.2) |

---

## 10. Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| App directory | Lowercase kebab-case | `nvidia-gpu-operator` |
| Group directory | `<type>-<value>` lowercase | `env-production`, `ocp-4.15` |
| Cluster directory | Lowercase, matches cluster name | `example-prod-east-1` |
| ApplicationSet name | Same as app directory | `nvidia-gpu-operator` |
| Application name | `<app>-<cluster>` (templated) | `cert-manager-prod-east-1` |
| Feature flag key | camelCase under `cluster.features` | `cluster.features.certManager.enabled` |
| Label key | Dot-separated prefix + slash + name | `app.enabled/cert-manager` |
| Label value | Lowercase string, quoted if boolean | `"true"`, `production` |
| Helm chart name | Matches directory name in `Chart.yaml` | `name: baremetal-hosts` |
| Branch names | `release/<environment>` for env branches | `release/production` |

---

## 11. Common Pitfalls

| Pitfall | Why It Breaks | Prevention |
|---------|---------------|------------|
| Editing ManagedCluster labels manually via `oc` | RHACM Policy overwrites them on next reconciliation | Always edit `cluster.yaml` in Git |
| Forgetting to run aggregation after editing `cluster.yaml` | Label-sync chart is stale; labels do not update | CI drift check catches this |
| Adding array entries in a lower-priority group expecting merge | Helm replaces arrays, does not merge them | Use the `extra*` + `concat` pattern |
| Creating an app without a feature flag in `groups/all/` | No way to disable the app fleet-wide; surprise deployments | Always add `enabled: false` default |
| Using opt-out for a risky new feature | All clusters get it immediately | Default to opt-in for new apps |
| Editing `hub/rhacm/cluster-labels/values.yaml` manually | Next aggregation run overwrites manual edits | File is auto-generated; edit `cluster.yaml` instead |
| Committing secrets to the repository | Credential exposure; violates security model | Use Vault + ESO; CI should scan for secrets |
| Skipping a promotion stage | Untested changes reach higher environments | CI gates enforce stage ordering |
| Changing cascade order in template but not in `fleet-diff.sh` | Diff output does not match actual rendering | Update all three locations (see 8.4) |
| Setting `targetRevision` to a tag instead of a branch | Promotion model breaks; hubs cannot track branch changes | Always use branch names for `targetRevision` |

---

## 12. Technology Requirements

### 12.1 Platform

| Component | Minimum Version | Required For |
|-----------|-----------------|--------------|
| RHACM | 2.9+ | ManagedCluster, Placement, Policy, GitOpsCluster |
| OpenShift GitOps | 1.10+ | ArgoCD operator on hub |
| ArgoCD | 2.6+ | Multi-source Applications |
| ArgoCD | 2.10+ | `ignoreMissingValueFiles` |
| Helm | 3.10+ | Chart rendering, `helm template` |
| yq | 4.x | Cluster config aggregation script |

### 12.2 External Integrations

| System | Purpose | Integration Point |
|--------|---------|-------------------|
| HashiCorp Vault | Secret storage (BMC creds, cluster secrets) | Ansible onboarding + ESO |
| External Secrets Operator | Pull secrets from Vault to K8s | App chart (`external-secrets`) |
| Git hosting (GitHub/GitLab) | Source of truth, PRs, CI triggers | All workflows |
| CI/CD (GitHub Actions/Jenkins/GitLab CI) | Validation, promotion, onboarding | `pipelines/` |
| CMDB (optional) | Cluster inventory registration | Ansible onboarding role |

### 12.3 Local Development

| Tool | Purpose |
|------|---------|
| `git` | Version control |
| `helm` | Chart linting, rendering, local testing |
| `yq` | YAML processing, aggregation script |
| `ansible` | Running onboarding playbooks locally |
| `colordiff` (optional) | Colorized diff output |

---

## 13. Repository URL Placeholder

All files use `https://github.com/YOUR-ORG/YOUR-REPO.git` as the repository
URL and `argo-examples/framework` as the path prefix. When deploying:

1. Replace `YOUR-ORG/YOUR-REPO` globally with the actual repository.
2. If the framework is moved to a different path within the repo, update:
   - All ApplicationSet `repoURL` and `path` fields
   - `hub-app-of-apps.yaml` `path`
   - `fleet-diff.sh` `FRAMEWORK_REL_PATH`
   - `aggregate-cluster-config.sh` arguments

---

## Revision History

| Date | Change |
|------|--------|
| 2026-04-10 | Initial version |

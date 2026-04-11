# Framework Evaluation Report — v1

**Date:** 2026-04-11
**Scope:** `argo-examples/framework/` — full directory tree, all YAML, scripts, pipelines, docs
**Purpose:** Identify structural issues, operational risks, and maintenance concerns to inform the next framework revision.

> **AI Disclosure:** This evaluation was performed with AI assistance.

---

## Table of Contents

- [Executive Summary](#executive-summary)
- [Evaluation Dimensions](#evaluation-dimensions)
  - [1. Ease of Management](#1-ease-of-management)
  - [2. Operations (Day-2)](#2-operations-day-2)
  - [3. Maintenance](#3-maintenance)
  - [4. Sustainability (Long-term Viability)](#4-sustainability-long-term-viability)
- [Structural Issues Found](#structural-issues-found)
  - [S-1: App-of-Apps Does Not Discover Per-App ApplicationSets](#s-1-app-of-apps-does-not-discover-per-app-applicationsets)
  - [S-2: Cascade Order Inconsistency (infra group)](#s-2-cascade-order-inconsistency-infra-group)
  - [S-3: No preserveResourcesOnDeletion on ApplicationSets](#s-3-no-preserveresourcesondeletion-on-applicationsets)
  - [S-4: Nested Application Pattern Undocumented](#s-4-nested-application-pattern-undocumented)
  - [S-5: cluster-logging _helpers.tpl Duplicated Default](#s-5-cluster-logging-_helperstpl-duplicated-default)
- [Operational Risks](#operational-risks)
  - [O-1: No Progressive Rollout or Canary](#o-1-no-progressive-rollout-or-canary)
  - [O-2: Rollback Procedure Incomplete](#o-2-rollback-procedure-incomplete)
  - [O-3: Emergency Hotfix Cherry-Pick Fragility](#o-3-emergency-hotfix-cherry-pick-fragility)
  - [O-4: No Live Drift Detection](#o-4-no-live-drift-detection)
- [Maintenance Concerns](#maintenance-concerns)
  - [M-1: Cascade Order Encoded in Five Places](#m-1-cascade-order-encoded-in-five-places)
  - [M-2: Shared Helpers Not Centralized](#m-2-shared-helpers-not-centralized)
  - [M-3: Generated File Committed to Git](#m-3-generated-file-committed-to-git)
  - [M-4: Manual Aggregation Step](#m-4-manual-aggregation-step)
  - [M-5: Version Pinning Is Manual Across Groups](#m-5-version-pinning-is-manual-across-groups)
- [Sustainability Concerns](#sustainability-concerns)
  - [L-1: Hub Scaling at O(N×M)](#l-1-hub-scaling-at-onm)
  - [L-2: Single Monorepo Promotion Bottleneck](#l-2-single-monorepo-promotion-bottleneck)
  - [L-3: No Integration Testing](#l-3-no-integration-testing)
- [Prioritized Action Items](#prioritized-action-items)
- [What Works Well (Preserve in v2)](#what-works-well-preserve-in-v2)

---

## Executive Summary

The framework demonstrates strong architectural thinking: hub-and-spoke with no Argo on spokes, Git-driven labels, declarative opt-in/out, and a well-defined value cascade. The documentation is unusually comprehensive and the tooling (`fleet-diff.sh`, `trace-value.sh`, `create-app.sh`) adds genuine operational value.

However, the review found **one critical structural gap** (the app-of-apps does not actually discover per-app ApplicationSets as documented), **one critical safety gap** (no `preserveResourcesOnDeletion`), and several consistency issues between the reference template, the scaffolding tool, and the live ApplicationSets. These must be resolved before production fleet use.

The framework is well-suited for fleets of 10–30 clusters with 5–15 apps. Beyond that, the maintenance cost of keeping N ApplicationSets synchronized on cascade order, the hub scaling pressure of O(N×M) Applications, and the single-promotion-cadence monorepo model will need structural solutions.

---

## Evaluation Dimensions

### 1. Ease of Management

**Strengths:**

- `cluster.yaml` as the single source of truth for cluster identity and group membership is clean and operator-friendly. One file edit, one commit, the system reacts.
- Opt-in/opt-out via labels is intuitive and well-documented with worked examples in `groups/README.md`.
- `create-app.sh` scaffolds a new app correctly — `Chart.yaml`, `values.yaml`, `_helpers.tpl`, `applicationset.yaml`, and the feature flag in `groups/all/values.yaml` — reducing the chance of missing a convention.
- `trace-value.sh` provides "where does this value come from?" answers that most fleet frameworks lack entirely.

**Concerns:**

- The aggregation step (`aggregate-cluster-config.sh`) is a manual synchronization point on every cluster change. While CI catches drift, the workflow adds friction: edit → run script → commit generated file → push. A pre-commit hook, Makefile target, or CI auto-commit would reduce this.
- Onboarding a new cluster requires touching 3 files minimum (`cluster.yaml`, `values.yaml`, regenerated `cluster-labels/values.yaml`) plus optionally running Ansible. The GitHub Actions onboard workflow helps, but the manual path has enough steps to invite errors.

---

### 2. Operations (Day-2)

**Strengths:**

- `fleet-diff.sh` is a standout tool — fully-rendered desired-state diffs between any two Git refs, no live cluster needed. Invaluable for promotion confidence.
- The promotion model (main → dev → staging → production via PRs) with escalating CI gates and approval counts is well-structured.
- Sync waves are correctly ordered: label-sync at `-5`, bootstrap at `-10`, per-app at `0`, ensuring labels are in place before ApplicationSets evaluate.
- The Operator's Guide provides a learning path from "what is GitOps" through day-2 procedures, which recognizes the actual audience.

**Concerns:**

- No progressive rollout across the fleet. A bad chart change promoted to an environment hits all matching clusters simultaneously. See [O-1](#o-1-no-progressive-rollout-or-canary).
- Rollback documentation says "git revert the merge commit" without addressing partial rollback, verification, or the N×M blast radius. See [O-2](#o-2-rollback-procedure-incomplete).
- No mechanism to detect live cluster drift beyond ArgoCD's built-in sync status. See [O-4](#o-4-no-live-drift-detection).

---

### 3. Maintenance

**Strengths:**

- The 10 architectural invariants in `GUIDELINES.md` are the single most valuable maintenance asset. They preserve design intent across team changes and time.
- The array safety linter prevents the most common Helm values footgun (array replacement instead of merge).
- The CI validation matrix (yamllint, helm lint, helm template, array safety, cluster config validation, label drift detection) covers the important checks.
- The DevSpaces Containerfile provides a consistent, reproducible environment with all framework tools.

**Concerns:**

- The cascade order is encoded in 5 independent locations that must stay synchronized. See [M-1](#m-1-cascade-order-encoded-in-five-places).
- `_helpers.tpl` is copy-pasted across every app with only the name changed. See [M-2](#m-2-shared-helpers-not-centralized).
- The generated `cluster-labels/values.yaml` checked into Git creates noisy diffs and merge conflicts. See [M-3](#m-3-generated-file-committed-to-git).
- OCP version group pinning of chart versions is manual with no matrix or automation. See [M-5](#m-5-version-pinning-is-manual-across-groups).

---

### 4. Sustainability (Long-term Viability)

**Strengths:**

- The design composes RHACM, OpenShift GitOps, and Helm correctly without fighting the tools.
- The hub performance tuning guide shows awareness of the O(N×M) scaling challenge.
- The secret management model (Vault + ESO, never in Git) is correct for enterprise use.
- The documentation suite is comprehensive enough that a new team member could understand the system without oral tradition.

**Concerns:**

- At 30+ apps and 100+ clusters, hub Argo manages 3000+ Applications. See [L-1](#l-1-hub-scaling-at-onm).
- Single monorepo with single promotion cadence constrains independent team velocity. See [L-2](#l-2-single-monorepo-promotion-bottleneck).
- No integration testing beyond lint and template rendering. See [L-3](#l-3-no-integration-testing).

---

## Structural Issues Found

### S-1: App-of-Apps Does Not Discover Per-App ApplicationSets

**Severity:** Critical
**Files:** `hub/bootstrap/hub-app-of-apps.yaml`, `apps/*/applicationset.yaml`

The bootstrap Application syncs `hub/applicationsets/`, which contains only `cluster-label-sync.yaml` and the reference template `per-app-template.yaml` (which is explicitly marked "do not apply"). Per-app ApplicationSets live in `apps/<app>/applicationset.yaml`.

This means the app-of-apps does **not** automatically discover or apply per-app ApplicationSets, contrary to what Invariant #5 ("the hub app-of-apps discovers these automatically") and the `apps/README.md` documentation state.

**Impact:** Operators must manually `oc apply` each ApplicationSet, which breaks Invariant #2 ("Git is the only source of truth") and the automated sync model.

**Recommended fixes (choose one):**

1. **Move ApplicationSets:** Relocate `apps/<app>/applicationset.yaml` into `hub/applicationsets/<app>.yaml`. Keep the chart directories under `apps/` unchanged.
2. **Broaden the app-of-apps:** Change the bootstrap Application to use a Helm chart or Kustomize overlay that includes resources from both `hub/applicationsets/` and `apps/*/applicationset.yaml`.
3. **Second app-of-apps:** Add a second Application pointing at a directory that aggregates or symlinks all per-app ApplicationSets.

Option 1 is simplest and aligns with the existing directory convention documented in `GUIDELINES.md` section 4.4.

---

### S-2: Cascade Order Inconsistency (infra group)

**Severity:** High
**Files:** `hub/applicationsets/per-app-template.yaml`, `apps/*/applicationset.yaml`, `scripts/create-app.sh`

The `valueFiles` lists differ across these locations:

| Location | Includes `infra-*` group? |
|----------|--------------------------|
| `per-app-template.yaml` (reference) | No |
| `create-app.sh` (scaffolding) | Yes |
| `cert-manager/applicationset.yaml` | No |
| `cluster-monitoring/applicationset.yaml` | No |
| `cluster-logging/applicationset.yaml` | No |
| `external-secrets/applicationset.yaml` | No |
| `baremetal-hosts/applicationset.yaml` | Yes |
| `nvidia-gpu-operator/applicationset.yaml` | Yes |

A new contributor following the reference template would produce an ApplicationSet that misses infra group values. The scaffolding tool does include it, creating a second inconsistency.

**Recommended fix:** Audit all ApplicationSets and the reference template. Standardize on the `create-app.sh` cascade (which includes `infra-*`, `region-*`, and `custom`) as the canonical order. Update the reference template to match.

---

### S-3: No preserveResourcesOnDeletion on ApplicationSets

**Severity:** Critical
**Files:** All `applicationset.yaml` files

If an ApplicationSet generator returns zero results (e.g., a label typo removes all cluster matches, or a label-sync regression clears labels), the default behavior is to **delete all generated Applications**. This is a fleet-wide deletion event.

**Recommended fix:** Add to every ApplicationSet spec:

```yaml
spec:
  strategy:
    type: RollingSync
    rollingSync:
      steps:
        - matchExpressions:
            - key: env
              operator: In
              values:
                - non-production
        - matchExpressions:
            - key: env
              operator: In
              values:
                - production
  # Prevent deletion when generator returns empty
  templatePatch: |
    metadata:
      annotations:
        argocd.argoproj.io/managed-by: fleet-management
```

At minimum, add the ApplicationSet-level protection:

```yaml
spec:
  generators:
    - clusters:
        # ...existing config...
  # Do not delete Applications if generator produces no matches
  syncPolicy:
    preserveResourcesOnDeletion: true
```

Also update `create-app.sh` and `per-app-template.yaml` to include this by default.

---

### S-4: Nested Application Pattern Undocumented

**Severity:** Medium
**Files:** `apps/cert-manager/`

The `cert-manager` app uses a different architectural pattern from the other five apps. Its chart renders a **child Application** on the hub that targets the spoke cluster, rather than deploying resources directly to the spoke. This is visible in the ApplicationSet destination (`namespace: openshift-gitops` on the hub instead of a spoke namespace) and in the chart templates.

This creates a hidden second pattern. New contributors may copy `cert-manager` as a starting point and not understand why it differs from `cluster-monitoring`.

**Recommended fix:** Document the "hub-side Application" pattern explicitly in `apps/README.md` as a named variant. Add a comment at the top of `cert-manager/applicationset.yaml` explaining why this app uses a different destination pattern.

---

### S-5: cluster-logging _helpers.tpl Duplicated Default

**Severity:** Low
**Files:** `apps/cluster-logging/templates/_helpers.tpl`

The `cluster-logging.retentionDays` helper has a duplicated `default` call in its chain. This is cosmetic but may confuse readers and could mask an unintended default if the chain is modified later.

**Recommended fix:** Remove the duplicate `default` and verify the helper returns the expected value at all cascade levels.

---

## Operational Risks

### O-1: No Progressive Rollout or Canary

**Severity:** High

All six apps configure `syncPolicy.automated: { prune: true, selfHeal: true }`. A bad chart change promoted to an environment hits every matching cluster simultaneously. For a fleet of 50 production clusters, a broken `cluster-monitoring` chart (opt-out, deployed everywhere) takes down monitoring fleet-wide in a single sync cycle.

**Recommended fix (phased):**

1. **Short-term:** Introduce a `canary` label dimension. Promote changes to `canary: "true"` clusters first, verify, then remove the gate.
2. **Medium-term:** Use ApplicationSet `strategy.rollingSync` (ArgoCD 2.6+) with progressive steps gated on environment labels and optional manual approval between waves.
3. **Long-term:** Integrate with an external progressive delivery controller (e.g., Argo Rollouts for the ApplicationSets themselves).

---

### O-2: Rollback Procedure Incomplete

**Severity:** Medium

`GUIDELINES.md` section 6.4 says "revert the merge commit via `git revert`." This is correct but insufficient for fleet operations:

- No guidance on **partial rollback** (reverting one app's changes in a promotion that included multiple apps).
- No guidance on **verifying the revert** produces the expected fleet state before merging (use `fleet-diff.sh` for this).
- No guidance on the **blast radius** of N×M simultaneous Application re-syncs after a revert.

**Recommended fix:** Expand the rollback section in `pipelines/promotion/README.md` with:

1. Partial rollback procedure (revert specific file paths only).
2. Required `fleet-diff.sh` verification before merging the revert PR.
3. Guidance on staggering re-sync if the revert affects many clusters (pause auto-sync, verify per-environment).

---

### O-3: Emergency Hotfix Cherry-Pick Fragility

**Severity:** Medium

The hotfix procedure (branch from `release/production`, merge to production, cherry-pick back to `main`) creates divergence risk. If the cherry-pick conflicts or is forgotten, the next promotion either conflicts or regresses the fix.

**Recommended fix:** Add a CI check that compares `release/production` and `main` after any hotfix merge, flagging commits present in production but absent from main. Alternatively, adopt a "hotfix to main first, then fast-promote" model for fixes that are safe to promote through all environments.

---

### O-4: No Live Drift Detection

**Severity:** Low (ArgoCD provides basic sync status)

The framework can tell you what Git says the state should be, but there's no periodic reconciliation report comparing desired state across all clusters. ArgoCD's sync status covers individual Applications, but fleet-level dashboards or alerts ("5 clusters out of sync for > 30 minutes") are not part of the framework.

**Recommended fix:** Add a fleet health dashboard definition (Grafana JSON or PrometheusRule) that aggregates ArgoCD Application sync status across all fleet-managed Applications. Include alert thresholds for sustained out-of-sync states.

---

## Maintenance Concerns

### M-1: Cascade Order Encoded in Five Places

**Severity:** High

Per `GUIDELINES.md` section 8.4, changing cascade priority requires updating:

1. `hub/applicationsets/per-app-template.yaml`
2. Every `apps/<app>/applicationset.yaml`
3. `scripts/fleet-diff.sh` (`render_app_cluster()`)
4. `scripts/trace-value.sh`
5. `scripts/create-app.sh`

Today there are already inconsistencies (see [S-2](#s-2-cascade-order-inconsistency-infra-group)). At 20+ apps, this becomes a significant maintenance burden and source of subtle bugs.

**Recommended fix:** Generate ApplicationSets from a single source of truth. Options:

1. **Helm chart for ApplicationSets:** A parent chart that templates all `applicationset.yaml` files from a shared `valueFiles` list.
2. **Script-based generation:** Extend `create-app.sh` into an `update-all-applicationsets.sh` that regenerates the `valueFiles` block in every app from a canonical definition.
3. **Kustomize with patches:** Base ApplicationSet template + per-app patches for selector, destination, and chart path only.

Option 2 is lowest effort and fits the existing tooling pattern.

---

### M-2: Shared Helpers Not Centralized

**Severity:** Medium

Every app's `_helpers.tpl` contains the same fleet label template and `fleet.mergeOverwrite` helper, differing only in the app name. When the common label pattern needs to change (e.g., adding a new fleet-wide label), every app must be updated individually.

**Recommended fix:** Create a shared Helm library chart at `apps/_library/` (or `hub/library-chart/`) that defines common helpers. Each app chart declares it as a dependency in `Chart.yaml`. This is standard Helm practice for exactly this pattern.

---

### M-3: Generated File Committed to Git

**Severity:** Medium
**Files:** `hub/rhacm/cluster-labels/values.yaml`

This file is auto-generated by `aggregate-cluster-config.sh` and committed to the repo. At scale:

- Multiple simultaneous cluster onboarding PRs will conflict on this file.
- The file grows linearly with cluster count.
- It creates noisy diffs that obscure the actual change in a PR.

**Recommended fix (choose one):**

1. **CI-generated artifact:** Run aggregation in CI and inject the result into the ArgoCD Application via a `helm.parameters` override or ConfigMap, rather than committing it.
2. **Pre-commit hook auto-regeneration:** If it must stay in Git, add a pre-commit hook that regenerates it automatically so developers never manually handle it.
3. **Accept the tradeoff** but add `.gitattributes` to mark it as a generated file (suppresses diff in PRs on GitHub/GitLab).

---

### M-4: Manual Aggregation Step

**Severity:** Low

Every `cluster.yaml` change requires running `aggregate-cluster-config.sh` and committing the result. CI detects drift, but the developer experience is: edit, run script, commit two files, push.

**Recommended fix:** Add a pre-commit hook or GitHub Actions step that auto-runs aggregation and commits the result. The onboard workflow already does this; extend the pattern to the validate-pr workflow for any PR that touches `clusters/*/cluster.yaml`.

---

### M-5: Version Pinning Is Manual Across Groups

**Severity:** Low

OCP version groups pin specific chart versions for cert-manager and Prometheus operator. When a compatibility update is needed, someone must manually update `ocp-4.14/values.yaml`, `ocp-4.15/values.yaml`, etc.

**Recommended fix:** Create a compatibility matrix file (e.g., `groups/compatibility-matrix.yaml`) that maps OCP versions to component versions. Generate the per-group `values.yaml` files from this matrix, or at minimum use the matrix as a reference for manual updates with CI validation.

---

## Sustainability Concerns

### L-1: Hub Scaling at O(N×M)

**Severity:** Medium (becomes high at scale)

With A apps and C clusters, the hub manages A×C Applications. At 30 apps × 100 clusters = 3,000 Applications, the ArgoCD controller, repo-server, and Redis come under significant load. The hub performance tuning guide acknowledges this but the framework doesn't provide structural mitigations.

**Recommended fix (phased):**

1. **Short-term:** Apply the tuning recommendations in `docs/HUB-PERFORMANCE-TUNING.md` proactively.
2. **Medium-term:** Use ArgoCD controller sharding to distribute the Application load.
3. **Long-term:** Consider promoting high-churn or high-resource apps to dedicated ArgoCD instances, or evaluating ArgoCD's Application-in-any-namespace feature to distribute across namespaces.

---

### L-2: Single Monorepo Promotion Bottleneck

**Severity:** Medium (becomes high with multiple teams)

All apps, clusters, and configuration share one repo with one promotion cadence. Team A cannot promote their app change to production without also promoting everything else that has merged to main.

**Recommended fix:** This is an architectural decision with significant tradeoffs. Options:

1. **Accept and enforce discipline:** Require that main is always production-ready. This works well with small teams.
2. **Per-app branches:** Allow app-specific promotion paths. Increases complexity significantly.
3. **Multi-repo split:** Separate app charts from cluster configuration. Apps promote independently; the framework repo provides the skeleton.

Recommend starting with option 1 and revisiting when team count exceeds 3.

---

### L-3: No Integration Testing

**Severity:** Medium

CI validates YAML syntax, Helm rendering, and label consistency. There is no test that applies the rendered output to a real cluster and validates behavior.

**Recommended fix (phased):**

1. **Short-term:** Use `helm template` + `kubectl apply --dry-run=server` against a lab cluster in CI.
2. **Medium-term:** Maintain a dedicated "CI lab" cluster that receives every main merge and runs smoke tests (e.g., CRDs created, operators installed, Subscriptions healthy).
3. **Long-term:** Add a post-sync hook or Argo CD `PostSync` job per app that runs basic health checks.

---

## Prioritized Action Items

### P0 — Must Fix Before Production

| ID | Issue | Fix | Effort |
|----|-------|-----|--------|
| S-1 | App-of-apps doesn't discover `apps/*/applicationset.yaml` | Move ApplicationSets under `hub/applicationsets/` or restructure app-of-apps path | Low |
| S-3 | No `preserveResourcesOnDeletion` on ApplicationSets | Add `syncPolicy.preserveResourcesOnDeletion: true` to all ApplicationSets + scaffolding | Low |

### P1 — Fix Before Fleet Scale (>20 clusters)

| ID | Issue | Fix | Effort |
|----|-------|-----|--------|
| S-2 | Cascade order inconsistency (infra group) | Audit and align all ApplicationSets with `create-app.sh` | Medium |
| O-1 | No progressive rollout | Implement ApplicationSet `rollingSync` with env-based steps | Medium |
| M-1 | Cascade order in 5 places | Generate ApplicationSets from single source or add update script | Medium |

### P2 — Fix for Operational Maturity

| ID | Issue | Fix | Effort |
|----|-------|-----|--------|
| S-4 | Nested Application pattern undocumented | Document in `apps/README.md` | Low |
| O-2 | Rollback procedure incomplete | Expand `pipelines/promotion/README.md` | Low |
| O-3 | Hotfix cherry-pick fragility | Add CI divergence check or switch to "fast-promote" model | Medium |
| M-2 | Shared helpers not centralized | Create library chart | Medium |
| M-3 | Generated file in Git | Auto-regenerate in CI or mark as generated | Low |

### P3 — Address for Long-term Sustainability

| ID | Issue | Fix | Effort |
|----|-------|-----|--------|
| L-1 | Hub scaling at O(N×M) | Proactive tuning, then sharding | Medium–High |
| L-2 | Single promotion cadence | Enforce main-is-always-ready discipline | Process |
| L-3 | No integration testing | Server-side dry-run in CI, then lab cluster | High |
| O-4 | No live drift detection | Fleet health Grafana dashboard + alerts | Medium |
| M-4 | Manual aggregation step | Pre-commit hook or CI auto-commit | Low |
| M-5 | Manual version pinning | Compatibility matrix with CI validation | Low |
| S-5 | Duplicated default in cluster-logging helper | Remove duplicate | Trivial |

---

## What Works Well (Preserve in v2)

These are design decisions and artifacts that should be carried forward unchanged:

1. **Hub-and-spoke with no Argo on spokes.** Single pane of glass, central control. Correct for enterprise fleet management.

2. **`cluster.yaml` as cluster identity source of truth.** Clean, declarative, auditable. The label pipeline (Git → aggregate → RHACM Policy → ManagedCluster → Argo secret → ApplicationSet) is well-designed.

3. **The value cascade pattern.** Layered defaults with cluster sovereignty. The `cluster.*` shared namespace makes cluster metadata universally available to all charts without coordination.

4. **The 10 architectural invariants.** These preserve design intent across team turnover and are the single most valuable maintenance artifact.

5. **`fleet-diff.sh`.** Desired-state diffing without a live cluster. Invaluable for promotion reviews and "what would this change actually do?" questions.

6. **`trace-value.sh`.** "Where does this value come from?" debugging tool that most frameworks lack.

7. **`create-app.sh` scaffolding.** Lowers the bar for correct new app creation. Should be the **only** supported way to create a new app.

8. **Opt-in/opt-out via labels.** Simple, declarative, and the worked examples in `groups/README.md` are excellent onboarding material.

9. **The documentation suite.** README, GUIDELINES, Operator's Guide, Developer Environment, Hub Performance Tuning, per-directory READMEs. Unusually comprehensive for a DevOps framework.

10. **The `extra*` + `concat` array pattern with linter.** Correctly solves Helm's array replacement behavior and enforces the pattern via CI.

---

## Appendix: Files Reviewed

```
framework/README.md
framework/GUIDELINES.md
framework/hub/bootstrap/hub-app-of-apps.yaml
framework/hub/applicationsets/per-app-template.yaml
framework/hub/applicationsets/cluster-label-sync.yaml
framework/hub/rhacm/managed-cluster-set.yaml
framework/hub/rhacm/placement.yaml
framework/hub/rhacm/gitopscluster.yaml
framework/hub/rhacm/cluster-labels/Chart.yaml
framework/hub/rhacm/cluster-labels/values.yaml
framework/hub/rhacm/cluster-labels/templates/label-policy.yaml
framework/hub/rhacm/cluster-labels/README.md
framework/apps/*/applicationset.yaml (all 6)
framework/apps/*/Chart.yaml (all 6)
framework/apps/*/values.yaml (all 6)
framework/apps/*/templates/*.yaml (all 6)
framework/apps/*/templates/_helpers.tpl (all 6)
framework/apps/README.md
framework/clusters/_template/cluster.yaml
framework/clusters/_template/values.yaml
framework/clusters/example-prod-east-1/cluster.yaml
framework/clusters/example-prod-east-1/values.yaml
framework/clusters/example-nonprod-dev-1/cluster.yaml
framework/clusters/example-nonprod-dev-1/values.yaml
framework/clusters/README.md
framework/groups/all/values.yaml
framework/groups/env-production/values.yaml
framework/groups/env-non-production/values.yaml
framework/groups/ocp-4.14/values.yaml
framework/groups/ocp-4.15/values.yaml
framework/groups/infra-baremetal/values.yaml
framework/groups/README.md
framework/scripts/fleet-diff.sh
framework/scripts/trace-value.sh
framework/scripts/lint-array-safety.sh
framework/scripts/create-app.sh
framework/scripts/README.md
framework/pipelines/github-actions/validate-pr.yaml
framework/pipelines/github-actions/fleet-diff.yaml
framework/pipelines/github-actions/promote.yaml
framework/pipelines/github-actions/onboard-cluster.yaml
framework/pipelines/github-actions/aggregate-cluster-config.sh
framework/pipelines/README.md
framework/pipelines/promotion/README.md
framework/automation/ansible/onboard-cluster.yaml
framework/automation/ansible/inventory/localhost.yaml
framework/automation/ansible/roles/onboard-cluster/tasks/main.yaml
framework/automation/ansible/roles/onboard-cluster/defaults/main.yaml
framework/automation/ansible/roles/onboard-cluster/templates/external-secrets.yaml.j2
framework/automation/README.md
framework/devspaces/Containerfile
framework/devspaces/devfile.yaml
framework/docs/OPERATORS-GUIDE.md
framework/docs/DEVELOPER-ENVIRONMENT.md
framework/docs/HUB-PERFORMANCE-TUNING.md
```

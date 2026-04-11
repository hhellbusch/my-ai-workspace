# Adopting Trunk-Based Development

This guide walks you through setting up the ArgoCD Fleet Management Framework
with a trunk-based workflow where all environments track `main`. It is the
simplest way to adopt the framework and is recommended for teams that are new
to Git or GitOps.

> **AI Disclosure:** This document was created with AI assistance.

---

## Overview

In trunk-based development:

- There is **one branch**: `main`.
- All hubs (lab, dev, staging, production) sync from `main`.
- A change merged to `main` eventually reaches every cluster.
- Safety comes from **RollingSync**, **sync windows**, and **feature flags** —
  not from branch isolation.

```
Developer ──PR──▶ main ──▶ All Hubs ──▶ All Clusters
                             │
                   RollingSync: non-prod first, then prod
```

---

## Initial Setup

### 1. Bootstrap With a Single Hub

If you are starting fresh, begin with one hub cluster managing all your spoke
clusters. You do not need multiple hubs until your fleet grows.

Apply the bootstrap Application on your hub:

```bash
oc apply -f hub/bootstrap/hub-app-of-apps.yaml -n openshift-gitops
```

The `hub-app-of-apps.yaml` already ships with `targetRevision: main`. No
change is needed.

### 2. Verify ApplicationSets Point to `main`

Every ApplicationSet in `hub/applicationsets/` should have `targetRevision: main`
on both sources. This is the default. Confirm with:

```bash
grep -r 'targetRevision' hub/applicationsets/
```

Expected output — every line should show `main`:

```
hub/applicationsets/cert-manager.yaml:          targetRevision: main
hub/applicationsets/cert-manager.yaml:          targetRevision: main
hub/applicationsets/cluster-monitoring.yaml:    targetRevision: main
...
```

### 3. Configure Branch Protection on `main`

Since `main` is your only branch, protect it:

| Setting | Value |
|---------|-------|
| Required reviews | 1+ (your choice) |
| CI required | Yes |
| Force push | No |
| Delete | No |

You do not need branch protection on `release/*` branches because they do
not exist in trunk-based mode.

### 4. Set Up CI Validation

Use the trunk-based validation pipeline (`pipelines/github-actions/validate-trunk-pr.yaml`)
instead of the branch-per-environment variant. It runs the same checks but
only targets PRs to `main` and always includes the ArgoCD diff preview.

If you previously set up `validate-pr.yaml` (the multi-branch variant), you
can keep it — it works for `main` PRs too. The trunk-based variant is simply
streamlined.

---

## Day-to-Day Workflow

### Making a Change

```bash
# Create a feature branch
git checkout -b feat/update-monitoring-retention

# Edit files
vim groups/env-production/values.yaml

# Preview the impact locally
./scripts/fleet-diff.sh main feat/update-monitoring-retention

# Commit and push
git add -A && git commit -m "feat: increase production monitoring retention to 30d"
git push origin feat/update-monitoring-retention

# Open a PR
gh pr create --base main --title "Increase production monitoring retention"
```

### CI Validates the PR

The pipeline automatically runs:
- YAML lint
- Helm lint and template rendering
- Cluster config validation
- Array safety lint
- Cascade order lint
- Fleet-diff preview (posted as a PR comment or step summary)

### Review and Merge

A teammate reviews the PR, inspects the fleet-diff output, and approves.
Merging to `main` triggers ArgoCD sync on all hubs.

### RollingSync Provides Safety

After merge, ArgoCD does **not** update all clusters simultaneously:

1. **Wave 1:** Non-production clusters (`group.env: non-production`) sync first.
2. ArgoCD waits for all wave 1 Applications to report healthy.
3. **Wave 2:** Production clusters (`group.env: production`) sync.

If wave 1 fails, production clusters are not affected. You have time to
revert the commit on `main` before production is touched.

---

## Recommended: ArgoCD Sync Windows

Sync windows add time-based protection on top of RollingSync. They restrict
**when** ArgoCD is allowed to sync Applications to specific clusters.

### Example: Production Sync Window

Create a sync window on the ArgoCD AppProject (or per-Application) that only
allows syncs during your maintenance window:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: openshift-gitops
spec:
  syncWindows:
    # Allow syncs to production clusters only during weekday business hours
    - kind: allow
      schedule: '0 8 * * 1-5'    # 8:00 AM Monday-Friday
      duration: 10h               # Until 6:00 PM
      clusters:
        - prod-*
      manualSync: true            # Manual sync always allowed for emergencies
    # Deny syncs to production outside the window
    - kind: deny
      schedule: '0 18 * * *'     # 6:00 PM every day
      duration: 14h               # Until 8:00 AM next day
      clusters:
        - prod-*
      manualSync: true
```

With sync windows:
- Changes merged to `main` at 3 PM are synced to non-prod immediately and
  to production within the current window.
- Changes merged at 7 PM hit non-prod immediately but production waits
  until the next morning's window.

### Sync Window Strategies

| Strategy | Schedule | Risk Tolerance |
|----------|----------|----------------|
| **Always open** | No sync windows | Highest — changes deploy immediately |
| **Business hours only** | Allow 8 AM - 6 PM weekdays | Medium — overnight changes wait |
| **Maintenance window** | Allow Tuesday/Thursday 2-4 PM | Lower — batches changes into windows |
| **Manual only** | Deny all auto-sync | Lowest — every sync is explicit |

Start with "business hours only" and tighten if needed.

---

## Feature Flags for Gradual Rollout

Even without branch isolation, you can control which clusters receive a
change using feature flags already built into the framework.

### Deploy Code Without Activating It

1. Add a feature flag in `groups/all/values.yaml`:

```yaml
cluster:
  features:
    newWidget:
      enabled: false
```

2. Gate your templates on the flag:

```yaml
{{- if .Values.cluster.features.newWidget.enabled }}
# ... resources only deployed when enabled
{{- end }}
```

3. Merge to `main`. The code is deployed everywhere but the feature is off.

4. Enable for specific clusters by setting `enabled: true` in their
   `clusters/<name>/values.yaml` or in a group like `env-non-production`.

5. Once validated, enable fleet-wide in `groups/all/values.yaml`.

This gives you per-cluster or per-group rollout control without branches.

---

## Rollback

### Simple Revert

```bash
# Find the bad commit
git log --oneline -10

# Revert it
git revert <sha>
git push origin main
```

All hubs sync the revert. RollingSync ensures non-prod reverts first.

### Verify Before Pushing

Use fleet-diff to confirm the revert produces the expected state:

```bash
./scripts/fleet-diff.sh main revert-branch
```

### Emergency: Pause Auto-Sync

If a change is causing immediate harm and you need time to investigate:

```bash
# Pause auto-sync on the hub ArgoCD for the affected app
argocd app set cert-manager-prod-east-1 --sync-policy none

# Investigate, prepare revert, push to main

# Re-enable auto-sync
argocd app set cert-manager-prod-east-1 --sync-policy automated
```

---

## What You Don't Need

In trunk-based mode, these framework components are unused:

| Component | Status | Why |
|-----------|--------|-----|
| `pipelines/github-actions/promote.yaml` | Not needed | No branches to promote between |
| `release/dev`, `release/staging`, `release/production` branches | Do not create | All hubs track `main` |
| Hotfix cherry-picks | Not needed | Fixes go directly to `main` |
| Per-branch `targetRevision` overrides | Not needed | All `targetRevision` values stay `main` |

---

## Graduating to Branch-Per-Environment

Trunk-based is a starting point, not a ceiling. As your fleet and team grow,
you may want the additional safety of environment branches.

### When to Graduate

Consider switching to branch-per-environment when **two or more** of these
apply:

- [ ] Your fleet has grown beyond 10 clusters across multiple environments.
- [ ] Multiple teams (3+) contribute to the framework concurrently.
- [ ] Regulatory or compliance requirements mandate formal promotion gates
      with documented soak time.
- [ ] You have experienced incidents where a bad merge to `main` reached
      production despite RollingSync.
- [ ] Stakeholders require separate approval workflows for staging vs
      production promotions.
- [ ] You need the ability to soak changes in staging for days or weeks
      before production promotion.

### Migration Steps

1. **Create release branches from `main`:**

```bash
git checkout main
git checkout -b release/dev
git push origin release/dev
git checkout -b release/staging
git push origin release/staging
git checkout -b release/production
git push origin release/production
```

2. **Update each hub's bootstrap Application:**

On each hub cluster, update `hub-app-of-apps.yaml` to pin
`targetRevision` to the appropriate branch:

```yaml
# On the production hub:
spec:
  source:
    targetRevision: release/production
```

3. **Configure branch protection rules:**

| Branch | Required Reviews |
|--------|------------------|
| `main` | 0 |
| `release/dev` | 0 |
| `release/staging` | 1 |
| `release/production` | 2 |

4. **Enable the promotion pipeline:**

The `promote.yaml` GitHub Actions workflow creates cross-branch
promotion PRs. No changes needed — it works out of the box.

5. **Switch to the multi-branch validation pipeline:**

Replace or supplement `validate-trunk-pr.yaml` with `validate-pr.yaml`
to cover PRs to all four branches.

6. **Update team documentation and runbooks** to reflect the new
   promotion procedure.

The transition is incremental. You can run trunk-based and
branch-per-environment side by side during the migration by having some
hubs track `main` while others track release branches.

---

## Comparison with Branch-Per-Environment

| Aspect | Trunk-Based | Branch-Per-Environment |
|--------|-------------|------------------------|
| Branches | 1 | 4 |
| Promotion | Implicit (merge = deploy) | Explicit (PR between branches) |
| Environment isolation | None | Full |
| Primary safety net | RollingSync + sync windows | Branch isolation + RollingSync |
| Rollback scope | All environments | Per environment |
| Git skills needed | Basic (branch, PR, merge) | Intermediate (multi-branch PRs, cherry-pick) |
| CI complexity | Lower | Higher |
| Audit trail | PR to main | Promotion PRs per environment |

For a detailed comparison including GitHub Flow and GitFlow, see
[Git Workflows](GIT-WORKFLOWS.md).

---

## Further Reading

- [Git Workflows](GIT-WORKFLOWS.md) — full comparison of four workflows
- [Promotion Guide](../pipelines/promotion/README.md) — branch-per-environment
  procedure (for when you graduate)
- [Guidelines](../GUIDELINES.md) — framework invariants
- [ArgoCD Sync Windows](https://argo-cd.readthedocs.io/en/stable/user-guide/sync_windows/) —
  official ArgoCD documentation

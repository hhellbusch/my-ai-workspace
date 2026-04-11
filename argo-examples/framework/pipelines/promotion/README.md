# Change Control & Promotion

Changes flow through environment stages via Git branches. The procedure is
intentionally simple: **a change is promoted by merging a PR from one branch
to the next.**

## Environment Stages

```
  lab ──▶ dev ──▶ staging ──▶ production
  │       │       │            │
  │       │       │            └─ Release branch: release/production
  │       │       └──────────────  Release branch: release/staging
  │       └──────────────────────  Release branch: release/dev
  └──────────────────────────────  Default branch: main (= lab)
```

| Stage       | Git Branch            | Purpose                                  | Gate                         |
|-------------|-----------------------|------------------------------------------|------------------------------|
| **lab**     | `main`                | Experimental, rapid iteration            | CI passes                    |
| **dev**     | `release/dev`         | Developer integration, early validation  | CI + Helm lint + dry-run     |
| **staging** | `release/staging`     | Pre-production soak, acceptance testing  | CI + approval (1 reviewer)   |
| **production** | `release/production` | Live production fleet                  | CI + approval (2 reviewers)  |

## How ArgoCD Tracks Branches

Each environment's hub cluster has its ApplicationSets configured with a
`targetRevision` matching its release branch. The value is injected by the
hub bootstrap Application:

```yaml
# hub/bootstrap/hub-app-of-apps.yaml (on the production hub)
spec:
  source:
    targetRevision: release/production    # <-- this controls what production sees
```

All ApplicationSets within the framework inherit this — the `$cluster-values`
ref and the chart source both use the same targetRevision. Changes not yet
merged to `release/production` are invisible to production clusters.

## Promotion Procedure

### 1. Develop on `main` (lab)

```bash
git checkout main
# Make changes to apps/, groups/, clusters/
git add . && git commit -m "feat: add new alertmanager silence for XYZ"
git push origin main
```

The lab hub picks up changes automatically.

### 2. Promote to dev

```bash
# Open a PR: main → release/dev
gh pr create --base release/dev --head main \
  --title "Promote: add XYZ silence to dev" \
  --body "Changes tested in lab. Ready for dev integration."
```

CI runs Helm lint, schema validation, and dry-run diff.
After CI passes → merge the PR. Dev hub picks up changes.

### 3. Promote to staging

```bash
# Open a PR: release/dev → release/staging
gh pr create --base release/staging --head release/dev \
  --title "Promote: add XYZ silence to staging" \
  --body "Validated in dev for 48h. Ready for staging soak."
```

CI runs full validation + ArgoCD diff preview.
Requires **1 reviewer** approval. Merge → staging hub picks up changes.

### 4. Promote to production

```bash
# Open a PR: release/staging → release/production
gh pr create --base release/production --head release/staging \
  --title "Promote: add XYZ silence to production" \
  --body "Soaked in staging for 1 week. No regressions."
```

CI runs full validation + ArgoCD diff preview + impact analysis.
Requires **2 reviewer** approvals. Merge → production hub picks up changes.

## Per-Hub Bootstrap

Each hub cluster (one per environment stage) bootstraps from the same
framework but pinned to its release branch:

| Hub            | Bootstrap targetRevision    | Manages Clusters In   |
|----------------|-----------------------------|-----------------------|
| Hub Lab        | `main`                      | Lab clusters          |
| Hub Dev        | `release/dev`               | Dev clusters          |
| Hub Staging    | `release/staging`           | Staging clusters      |
| Hub Production | `release/production`        | Production clusters   |

## Emergency Hotfix

For critical production fixes that cannot wait for full promotion:

```bash
# Branch directly from release/production
git checkout -b hotfix/critical-fix release/production
# Make the minimal fix
git push origin hotfix/critical-fix
# PR directly to release/production (still requires 2 approvals)
gh pr create --base release/production --head hotfix/critical-fix \
  --title "HOTFIX: critical fix for XYZ"
# After merge to production, cherry-pick back to main
git checkout main && git cherry-pick <commit>
```

## Branch Protection Rules

Configure in GitHub/GitLab settings:

| Branch              | Required Reviews | CI Required | Force Push | Delete |
|---------------------|------------------|-------------|------------|--------|
| `main`              | 0                | Yes         | No         | No     |
| `release/dev`       | 0                | Yes         | No         | No     |
| `release/staging`   | 1                | Yes         | No         | No     |
| `release/production`| 2                | Yes         | No         | No     |

## Progressive Rollout Within Each Environment

All ApplicationSets use the `RollingSync` strategy. When a promotion PR is
merged, changes do not hit all clusters simultaneously — they roll out in
two waves:

1. **Non-production clusters** — all clusters with `group.env: non-production`
2. **Production clusters** — all clusters with `group.env: production`

ArgoCD waits for all Applications in step 1 to reach healthy sync before
proceeding to step 2. This provides automatic canary protection: if a change
breaks non-production clusters, production clusters are not affected.

This is separate from (and complementary to) the branch-based promotion
model. The branch model gates which environments see a change; the
RollingSync strategy provides additional safety _within_ each environment.

## Rollback

Rollback is a reverse promotion — revert the PR and merge:

```bash
# Revert the bad PR on release/production
gh pr create --base release/production \
  --head revert-bad-change \
  --title "Revert: roll back XYZ"
```

ArgoCD's automated sync picks up the revert immediately.

### Partial Rollback

If a promotion included changes to multiple apps, you can revert only
specific files:

```bash
git checkout release/production
git checkout -b revert-partial
# Revert only the problematic app's files
git checkout HEAD~1 -- apps/cluster-monitoring/ hub/applicationsets/cluster-monitoring.yaml
git commit -m "revert: roll back cluster-monitoring changes from promotion #42"
```

### Verifying a Rollback Before Merge

Always run `fleet-diff.sh` to confirm the revert produces the expected state:

```bash
# Compare the revert branch against current production
./scripts/fleet-diff.sh release/production revert-partial
```

### Large Blast Radius Reverts

If a revert affects many clusters (e.g., reverting a `groups/all/` change):

1. Pause auto-sync on the hub ArgoCD before merging the revert PR
2. Merge the revert
3. Verify the rendered diff is correct with `fleet-diff.sh`
4. Re-enable auto-sync — the RollingSync strategy will stagger the rollout

## Visual Summary

```
Developer ──push──▶ main (lab) ──PR──▶ release/dev ──PR──▶ release/staging ──PR──▶ release/production
                       │                   │                    │                       │
                    CI lint              CI lint              CI lint + diff          CI lint + diff
                                                             1 approval              2 approvals
                       │                   │                    │                       │
                    Lab Hub             Dev Hub            Staging Hub            Production Hub
                       │                   │                    │                       │
                    Lab clusters        Dev clusters       Staging clusters      Production clusters
```

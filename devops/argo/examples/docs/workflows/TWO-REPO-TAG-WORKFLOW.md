# Two-Repository Tagging Workflow

## Overview

When deploying with ArgoCD App of Apps pattern, you work with **TWO repositories**, each with their own tags:

1. **Application Repository** - Your app's source code
2. **Config Repository (This Repo)** - ArgoCD configuration

## The Two Tag Types

### Application Repo Tags
```
github.com/your-org/api-service
└── Tags: v1.2.3, v1.3.0, v1.3.1 (application versions)
```

### Config Repo Tags  
```
github.com/your-org/argocd-config  (THIS REPO)
└── Tags: deploy-prod-api-v1.2.3, deploy-prod-api-v1.3.0 (deployment states)
```

## Complete Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: Application Repository                                  │
│ (Your app's source code)                                         │
└─────────────────────────────────────────────────────────────────┘

Developer writes code
    ↓
Create release
    ↓
git tag v1.3.0
git push origin v1.3.0
    ↓
Application v1.3.0 is tagged and available

┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: Config Repository - THIS REPO                           │
│ (ArgoCD configuration)                                           │
└─────────────────────────────────────────────────────────────────┘

Create deployment branch
git checkout -b deploy/prod-api-v1.3.0
    ↓
Update values file to point to v1.3.0
vim charts/argocd-apps/values-production.yaml
  applications:
    - name: api
      targetRevision: v1.3.0  ← Points to app repo tag!
    ↓
Commit and push
git commit -m "Deploy API v1.3.0 to production"
git push origin deploy/prod-api-v1.3.0
    ↓
Open PR
gh pr create --title "🚀 Deploy API v1.3.0 to production"
    ↓
Get approval → Merge to main
    ↓
Pull latest main
git checkout main
git pull origin main
    ↓
Tag the config repo (captures the deployment state)
git tag -a deploy-prod-api-v1.3.0 -m "Deployed API v1.3.0 to prod"
git push origin deploy-prod-api-v1.3.0
    ↓
✅ Config repo now has tag that contains values pointing to v1.3.0!

┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: ArgoCD Deploys                                          │
└─────────────────────────────────────────────────────────────────┘

Root app (always watching main) detects change
    ↓
Reads values-production.yaml
    ↓
Sees targetRevision: v1.3.0
    ↓
Deploys from application repo tag v1.3.0
    ↓
✅ Application v1.3.0 now running in production
```

## Why Tag Both Repos?

### Application Repo Tags (v1.3.0)
- ✅ Marks stable release of application code
- ✅ Developers can check out specific versions
- ✅ Used by ArgoCD to deploy specific versions
- ✅ Semantic versioning for the application

### Config Repo Tags (deploy-prod-api-v1.3.0)
- ✅ Captures **what was deployed when**
- ✅ Shows the complete deployment configuration at that moment
- ✅ Makes rollback easy: "revert to this exact config state"
- ✅ Audit trail: "who deployed what version to prod"
- ✅ Can see diff between deployments

## Example: Full Lifecycle

### Day 1: Initial Deployment

**Application Repo:**
```bash
# In github.com/your-org/api-service
git tag v1.2.3
git push origin v1.2.3
```

**Config Repo (THIS REPO):**
```bash
# In github.com/your-org/argocd-config
git checkout -b deploy/prod-api-v1.2.3
vim charts/argocd-apps/values-production.yaml
# Set: targetRevision: v1.2.3

git commit -am "Deploy API v1.2.3 to production"
git push origin deploy/prod-api-v1.2.3

# Open PR, get approval, merge

git checkout main && git pull
git tag -a deploy-prod-api-v1.2.3 -m "Initial production deployment

Application: api-service
Version: v1.2.3
Deployed: 2024-01-15
Approved by: Tech Lead"

git push origin deploy-prod-api-v1.2.3
```

**Result:**
- Application repo has tag: `v1.2.3`
- Config repo has tag: `deploy-prod-api-v1.2.3`
- Tag `deploy-prod-api-v1.2.3` contains values file pointing to `v1.2.3`

### Day 7: New Deployment

**Application Repo:**
```bash
# New features developed
git tag v1.3.0
git push origin v1.3.0
```

**Config Repo:**
```bash
git checkout -b deploy/prod-api-v1.3.0
vim charts/argocd-apps/values-production.yaml
# Set: targetRevision: v1.3.0

git commit -am "Deploy API v1.3.0 to production"
# PR → Approval → Merge

git checkout main && git pull
git tag -a deploy-prod-api-v1.3.0 -m "Deploying new features

Application: api-service
Version: v1.3.0
Deployed: 2024-01-22
Changes: New search feature, performance improvements"

git push origin deploy-prod-api-v1.3.0
```

**Result:**
- Application repo has tags: `v1.2.3`, `v1.3.0`
- Config repo has tags: `deploy-prod-api-v1.2.3`, `deploy-prod-api-v1.3.0`

### Day 8: Emergency Rollback

**Config Repo:**
```bash
# Issues found in v1.3.0, need to rollback

# Check what we deployed before
git show deploy-prod-api-v1.2.3

git checkout -b rollback/api-to-v1.2.3
vim charts/argocd-apps/values-production.yaml
# Set: targetRevision: v1.2.3  (back to previous version)

git commit -am "ROLLBACK: API to v1.2.3 due to critical bug"
# Emergency PR → Fast-track approval → Merge

git checkout main && git pull
git tag -a rollback-prod-api-to-v1.2.3 -m "Emergency rollback

From: v1.3.0
To: v1.2.3
Reason: Critical bug in search feature
Incident: INC-12345"

git push origin rollback-prod-api-to-v1.2.3
```

**Result:**
- Application repo still has tags: `v1.2.3`, `v1.3.0` (unchanged)
- Config repo now has: 
  - `deploy-prod-api-v1.2.3`
  - `deploy-prod-api-v1.3.0`
  - `rollback-prod-api-to-v1.2.3` ← captures rollback state
- Production is now running v1.2.3 again

## Viewing Deployment History

### See all production deployments
```bash
git tag -l "deploy-prod-*"
# Output:
# deploy-prod-api-v1.2.3
# deploy-prod-api-v1.3.0
# deploy-prod-web-v2.1.0
# deploy-prod-monitoring-v3.0.0
```

### See what was in a specific deployment
```bash
git show deploy-prod-api-v1.3.0:charts/argocd-apps/values-production.yaml
# Shows the exact values file at that deployment
```

### Compare two deployments
```bash
git diff deploy-prod-api-v1.2.3..deploy-prod-api-v1.3.0
# Shows what changed between deployments
```

### See deployment timeline
```bash
git log --tags="deploy-prod-*" --date=short --pretty="format:%ad %d" --simplify-by-decoration
# 2024-01-22  (tag: deploy-prod-api-v1.3.0)
# 2024-01-15  (tag: deploy-prod-api-v1.2.3)
```

## Key Takeaways

1. **Application tags** mark code versions → `v1.3.0`
2. **Config tags** mark deployment states → `deploy-prod-api-v1.3.0`
3. **Config tags contain** the values files pointing to app versions
4. **Always tag config repo** after merging deployment PRs
5. **Use config tags** to track and rollback deployments

## Common Patterns

### Tagging Convention

```
# Production deployments
deploy-prod-<app>-<version>
Example: deploy-prod-api-v1.3.0

# Staging deployments  
deploy-staging-<app>-<version>
Example: deploy-staging-api-v1.3.0

# Rollbacks
rollback-<env>-<app>-to-<version>
Example: rollback-prod-api-to-v1.2.3

# Releases (multiple apps)
release-<date>-<env>
Example: release-2024-01-prod
```

## Questions?

**Q: Why not just tag the config repo with the same version as the app?**  
A: Because you might deploy the same app version multiple times (e.g., after a rollback and re-deploy), or deploy multiple apps in one change. Config tags capture the deployment event, not just the app version.

**Q: Do I need to tag every environment?**  
A: Recommended for production (mandatory), optional for staging, typically not needed for development.

**Q: Can I use the config tag to roll back?**  
A: Yes! Check out the tag, look at the values file, create a rollback PR with those values.

**Q: What if I forget to tag after deployment?**  
A: You can still tag later, but the timestamp will be different. Try to tag immediately after successful deployment for accurate audit trail.

## Summary

```
Application Repo        Config Repo (THIS REPO)
      ↓                          ↓
 Tag: v1.3.0            Tag: deploy-prod-api-v1.3.0
 (code version)         (deployment state containing
                         values pointing to v1.3.0)
```

Both tags are important, serve different purposes, and should be created!


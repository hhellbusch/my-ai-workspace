# Tagging Update Summary

## What Was Clarified

The documentation now clearly explains that there are **TWO types of tags** when using the ArgoCD App of Apps pattern:

1. **Application Repository Tags** (e.g., `v1.3.0`)
2. **Config Repository Tags** (e.g., `deploy-prod-api-v1.3.0`)

## Why This Matters

### The Problem
The user correctly pointed out that when deploying to production, the **config repository tag must contain the changes** that point to the application version being deployed.

### The Solution
**Tag the config repository AFTER merging the PR** that updates the values file.

## What Changed

### New Documentation Files

1. **TWO-REPO-TAG-WORKFLOW.md** ⭐ **NEW**
   - Complete explanation of the two-repository tagging model
   - Visual workflows showing both repos
   - Full lifecycle examples (deploy → rollback → re-deploy)
   - Commands for viewing deployment history
   - Best practices for config repo tagging

### Updated Files

2. **PR-WORKFLOW-GUIDE.md**
   - Added "Understanding Tags: Application vs Config Repository" section at the top
   - Updated "Deploy to Production" workflow to include config repo tagging after merge
   - Updated "Rollback Workflow" to include config repo tagging
   - Added "Config Repository Tagging Best Practices" section
   - Examples of viewing deployment history using tags
   - Using tags for rollback procedures

3. **APP-OF-APPS-PATTERN.md**
   - Added reference to TWO-REPO-TAG-WORKFLOW.md

4. **APP-OF-APPS-SUMMARY.md**
   - Added TWO-REPO-TAG-WORKFLOW.md to resources

5. **QUICK-REFERENCE.md**
   - Added TWO-REPO-TAG-WORKFLOW.md to resources with ⭐ marker

6. **ARGOCD-APP-OF-APPS-README.md**
   - Added TWO-REPO-TAG-WORKFLOW.md as #2 essential reading

## The Corrected Workflow

### Before (Unclear)
```bash
# Deploy to production
git checkout -b deploy/prod-api-v1.3.0
vim values-production.yaml  # Set targetRevision: v1.3.0
git push origin deploy/prod-api-v1.3.0
# PR → Merge → Done ❌ (Missing config repo tag!)
```

### After (Clear)
```bash
# Deploy to production
git checkout -b deploy/prod-api-v1.3.0
vim values-production.yaml  # Set targetRevision: v1.3.0
git push origin deploy/prod-api-v1.3.0
# PR → Merge → Monitor deployment

# IMPORTANT: Tag the config repo
git checkout main && git pull
git tag -a deploy-prod-api-v1.3.0 -m "Deployed API v1.3.0
This tag contains values file pointing to api:v1.3.0"
git push origin deploy-prod-api-v1.3.0
```

## Key Concepts Clarified

### Application Repo Tag (v1.3.0)
- **Where**: Application source code repository
- **What**: Specific version of application code
- **When**: Created by developers when releasing
- **Used by**: ArgoCD to pull the application code

### Config Repo Tag (deploy-prod-api-v1.3.0)
- **Where**: This ArgoCD configuration repository
- **What**: Deployment state (values file pointing to v1.3.0)
- **When**: Created AFTER PR merge that updates values
- **Used for**: Audit trail, rollback reference, deployment history

## Example Flow

```
Step 1: Application Repo
├─ Developers create tag: v1.3.0
└─ Application code is tagged and ready

Step 2: Config Repo - PR and Merge
├─ Create branch: deploy/prod-api-v1.3.0
├─ Update values file: targetRevision: v1.3.0
├─ Create PR
├─ Get approval
├─ Merge to main
└─ Values file now points to v1.3.0 ✅

Step 3: Config Repo - Tag After Merge ⭐ KEY STEP
├─ git checkout main && git pull
├─ git tag -a deploy-prod-api-v1.3.0
└─ git push origin deploy-prod-api-v1.3.0
    └─ This tag CONTAINS the values change! ✅

Step 4: ArgoCD Deploys
├─ Root app sees change on main
├─ Reads values file (pointing to v1.3.0)
└─ Deploys application from v1.3.0 tag
```

## Benefits of Config Repo Tagging

### 1. Complete Audit Trail
```bash
git tag -l "deploy-prod-*"
# deploy-prod-api-v1.2.3  (Jan 15)
# deploy-prod-api-v1.3.0  (Jan 22)
# rollback-prod-api-to-v1.2.3  (Jan 23)
```

### 2. Easy Rollback
```bash
# See what was deployed before
git show deploy-prod-api-v1.2.3:charts/argocd-apps/values-production.yaml

# Create rollback from that state
git checkout -b rollback/api-to-v1.2.3
# Copy values from that tag
```

### 3. Deployment Comparison
```bash
# See exactly what changed between deployments
git diff deploy-prod-api-v1.2.3..deploy-prod-api-v1.3.0
```

### 4. Compliance and Auditing
```bash
# Show all production deployments with dates
git log --tags="deploy-prod-*" --date=short \
  --pretty="format:%ad %d %s" --simplify-by-decoration
```

## Tag Naming Conventions

```bash
# Production deployments
deploy-prod-<app>-<version>

# Staging deployments
deploy-staging-<app>-<version>

# Development deployments (optional)
deploy-dev-<app>-<version>

# Rollbacks
rollback-<env>-<app>-to-<version>

# Release bundles (multiple apps)
release-<date>-<env>
```

## Updated Checklist

When deploying to production:

- [ ] Application repo has the version tag (e.g., `v1.3.0`)
- [ ] Create config repo deployment branch
- [ ] Update values file to point to application tag
- [ ] Create PR with full details
- [ ] Get required approvals
- [ ] Merge PR to main
- [ ] **Tag the config repo** ⭐ `deploy-prod-api-v1.3.0`
- [ ] Monitor deployment
- [ ] Verify application is running

## Documentation References

For complete details, see:

1. **[TWO-REPO-TAG-WORKFLOW.md](TWO-REPO-TAG-WORKFLOW.md)** - Complete guide
2. **[PR-WORKFLOW-GUIDE.md](PR-WORKFLOW-GUIDE.md)** - PR workflow with tagging
3. **[ARGOCD-APP-OF-APPS-README.md](ARGOCD-APP-OF-APPS-README.md)** - Getting started

## Summary

✅ **Application tags** mark code versions  
✅ **Config tags** mark deployment states and CONTAIN the values changes  
✅ **Always tag config repo** after merging deployment PRs  
✅ **Use config tags** for audit trail and rollback  

The documentation now makes this workflow crystal clear!


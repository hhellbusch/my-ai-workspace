# Pull Request Workflow Guide

## Overview

**IMPORTANT**: All changes to the `main` branch MUST go through pull requests. Direct pushes to `main` are not allowed.

This guide explains how to properly use PRs to deploy applications using the ArgoCD App of Apps pattern.

## Why Pull Requests?

✅ **Code Review**: Changes are reviewed before deployment  
✅ **Approval Process**: Production changes require explicit approval  
✅ **Audit Trail**: Clear history of who approved what changes  
✅ **Discussion**: Team can discuss changes before they go live  
✅ **CI/CD Integration**: Automated tests can run before merge  
✅ **Rollback Context**: PR provides context for understanding what changed

## Understanding Tags: Application vs Config Repository

**Important**: There are TWO types of tags in this workflow:

### Application Repository Tags
- **Location**: Your application's source code repository (e.g., `github.com/org/api`)
- **Purpose**: Mark specific versions of your application code
- **Example**: `v1.3.0` - The API application at version 1.3.0
- **Who Creates**: Development team when releasing new versions
- **Used In**: The `targetRevision` field in ArgoCD values files

### Config Repository Tags (This Repo)
- **Location**: This ArgoCD configuration repository
- **Purpose**: Mark specific deployment states showing which app versions are deployed
- **Example**: `deploy-prod-api-v1.3.0` - Config state deploying API v1.3.0 to production
- **Who Creates**: Operations/DevOps team after merging deployment PRs
- **Used For**: Audit trail, rollback reference, deployment history

### The Complete Flow

```
1. Application Repo:
   Developer tags code → git tag v1.3.0 → git push origin v1.3.0

2. Config Repo (THIS REPO):
   a. Update values file to point to v1.3.0
   b. Create PR, get approval, merge to main
   c. Tag the merged config → git tag deploy-prod-api-v1.3.0
   
   This tag contains the values file change that points to v1.3.0!
```

**Why Tag the Config Repo?**
- ✅ Capture the exact config state at deployment time
- ✅ Easy rollback: `git checkout deploy-prod-api-v1.2.3`
- ✅ Audit: See what was deployed when
- ✅ History: Track all production deployments  

## Branch Naming Conventions

Use descriptive branch names with prefixes:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `deploy/` | Deploying new versions | `deploy/prod-api-v1.2.3` |
| `rollback/` | Rolling back to previous version | `rollback/api-to-v1.2.2` |
| `release/` | Creating release from develop to main | `release/v1.2.3` |
| `add/` | Adding new applications | `add/monitoring-stack` |
| `remove/` | Removing applications | `remove/deprecated-service` |

## Standard Deployment Workflow

### 1. Deploy to Development

```bash
# Start from main
git checkout main
git pull origin main

# Create feature branch
git checkout -b deploy/dev-api-v1.3.0

# Update values file
vim charts/argocd-apps/values-development.yaml
# Change: targetRevision: v1.2.3 → targetRevision: v1.3.0

# Commit and push
git add charts/argocd-apps/values-development.yaml
git commit -m "Deploy API v1.3.0 to development

- Upgrading from v1.2.3 to v1.3.0
- Testing new features: X, Y, Z
- Expected to be in dev for 2 days of testing"

git push origin deploy/dev-api-v1.3.0

# Open PR
gh pr create \
  --title "Deploy API v1.3.0 to development" \
  --body "## Changes
- Deploying API version v1.3.0 to development environment
- Previous version: v1.2.3

## Testing Plan
- Functional testing of new features
- Performance testing
- Integration testing with other services

## Rollback Plan
If issues found, revert to v1.2.3

## Links
- [Release Notes](https://github.com/org/api/releases/tag/v1.3.0)
- [Changelog](https://github.com/org/api/blob/main/CHANGELOG.md)"

# Wait for approval and merge
# After merge, verify deployment in ArgoCD UI
```

### 2. Deploy to Staging

```bash
# After successful dev testing, deploy to staging
git checkout main
git pull origin main

git checkout -b deploy/staging-api-v1.3.0

vim charts/argocd-apps/values-staging.yaml
# Change: targetRevision: v1.2.3 → targetRevision: v1.3.0

git add charts/argocd-apps/values-staging.yaml
git commit -m "Deploy API v1.3.0 to staging

- Successfully tested in dev for 2 days
- Ready for staging validation
- Fixes: [list of fixes]
- New features: [list of features]"

git push origin deploy/staging-api-v1.3.0

gh pr create \
  --title "Deploy API v1.3.0 to staging" \
  --body "## Changes
- Deploying API version v1.3.0 to staging environment
- Previous version: v1.2.3
- Successfully tested in dev environment

## Dev Testing Results
✅ All functional tests passed
✅ Performance meets requirements
✅ Integration tests successful

## Staging Testing Plan
- UAT testing
- Load testing
- Security scan

## Rollback Plan
If issues found, revert to v1.2.3"

# Wait for approval and merge
```

### 3. Deploy to Production

```bash
# After successful staging validation
git checkout main
git pull origin main

git checkout -b deploy/prod-api-v1.3.0

vim charts/argocd-apps/values-production.yaml
# Change: targetRevision: v1.2.3 → targetRevision: v1.3.0

git add charts/argocd-apps/values-production.yaml
git commit -m "Deploy API v1.3.0 to production

- Tested in dev and staging
- All acceptance criteria met
- Approved by: [names]
- Deploy date: [date]"

git push origin deploy/prod-api-v1.3.0

gh pr create \
  --title "🚀 Deploy API v1.3.0 to production" \
  --body "## Changes
- Deploying API version v1.3.0 to production environment
- Previous version: v1.2.3

## Testing Summary
✅ Dev testing: 2 days, all tests passed
✅ Staging testing: 3 days, UAT approved
✅ Load testing: Passed
✅ Security scan: Passed

## Deployment Details
- **Deploy Window**: [date/time]
- **Expected Downtime**: None (rolling update)
- **Monitoring**: [dashboard links]

## Rollback Plan
If critical issues detected:
1. Create rollback PR to v1.2.3
2. Fast-track approval process
3. Expected rollback time: < 5 minutes

## Approvals Required
- [ ] Tech Lead
- [ ] Product Owner
- [ ] SRE On-Call

## Links
- [Release Notes](https://github.com/org/api/releases/tag/v1.3.0)
- [Changelog](https://github.com/org/api/blob/main/CHANGELOG.md)
- [Deployment Runbook](link)"

# Wait for required approvals
# Schedule merge for deployment window
# After merge, monitor closely

# IMPORTANT: Tag the config repo after successful deployment
git checkout main
git pull origin main
git tag -a deploy-prod-api-v1.3.0 -m "Production deployment of API v1.3.0

This tag captures the config state where:
- values-production.yaml points to api:v1.3.0
- Deployed on: $(date)
- Approved by: [names]"

git push origin deploy-prod-api-v1.3.0

# This tag allows you to easily:
# 1. See exactly what was deployed when
# 2. Roll back to this exact config state
# 3. Audit production deployments
```

## Rollback Workflow

If issues are detected after deployment:

```bash
# Create rollback branch
git checkout main
git pull origin main

git checkout -b rollback/api-to-v1.2.3

# Revert changes in values file
vim charts/argocd-apps/values-production.yaml
# Change: targetRevision: v1.3.0 → targetRevision: v1.2.3

git add charts/argocd-apps/values-production.yaml
git commit -m "ROLLBACK: API to v1.2.3

Critical issues found in v1.3.0:
- [Issue 1]
- [Issue 2]

Rolling back to known-good version v1.2.3"

git push origin rollback/api-to-v1.2.3

# Open urgent PR
gh pr create \
  --title "🚨 URGENT: Rollback API to v1.2.3" \
  --body "## Critical Issues
- [Description of issues]

## Rollback Details
- Rolling back from v1.3.0 to v1.2.3
- Known-good version: v1.2.3
- Reference previous deployment tag: deploy-prod-api-v1.2.3

## Incident
- Incident ticket: [link]
- On-call engineer: [name]

⚠️ **This is an urgent rollback. Fast-track approval requested.**"

# Get fast-track approval and merge
# Monitor rollback

# Tag the rollback in config repo
git checkout main
git pull origin main
git tag -a rollback-prod-api-to-v1.2.3 -m "Emergency rollback from v1.3.0 to v1.2.3

Reason: [critical issues]
Incident: [ticket link]
Rolled back on: $(date)"

git push origin rollback-prod-api-to-v1.2.3
```

## PR Best Practices

### PR Title Format

```
[Environment] Action: Component vX.Y.Z

Examples:
✅ "[Production] Deploy: API v1.3.0"
✅ "[Staging] Deploy: Web App v2.1.0"
✅ "[All Envs] Add: Monitoring Stack v1.0.0"
✅ "[Production] Rollback: API to v1.2.3"
```

### PR Description Template

```markdown
## Changes
Brief description of what's changing

## Previous Version
v1.2.3

## New Version
v1.3.0

## Testing
- [ ] Tested in dev
- [ ] Tested in staging
- [ ] All tests passed
- [ ] Performance validated

## Deployment Details
- Deploy window: [date/time]
- Expected impact: [none/minimal/maintenance window]
- Monitoring: [dashboard links]

## Rollback Plan
Clear instructions for rolling back if needed

## Links
- Release notes
- Changelog
- Related tickets
```

### Reviewers and Approvals

| Environment | Approvers | Count |
|-------------|-----------|-------|
| Development | Any team member | 1 |
| Staging | Team lead or senior engineer | 1 |
| Production | Tech lead + SRE | 2+ |

### Before Opening PR

```bash
# 1. Test Helm chart locally
./test-app-of-apps.sh

# 2. Validate syntax
helm template root-app ./charts/argocd-apps/ \
  -f ./charts/argocd-apps/values-production.yaml

# 3. Review diff
git diff main...HEAD

# 4. Ensure commit message is clear
git log -1

# 5. Push and open PR
git push origin your-branch-name
gh pr create
```

### After PR Merge

```bash
# 1. Watch ArgoCD sync
argocd app get root-app-production

# 2. Check child app status
argocd app get api-app

# 3. Monitor application
# - Check metrics dashboard
# - Review logs
# - Monitor error rates

# 4. If issues, create rollback PR immediately
```

## GitHub Branch Protection Rules

Recommended settings for `main` branch:

```yaml
Settings → Branches → Branch protection rules

✅ Require pull request reviews before merging
  - Required approving reviews: 1 (dev/staging) or 2+ (production)
  - Dismiss stale pull request approvals when new commits are pushed

✅ Require status checks to pass before merging
  - helm-lint
  - values-validation (if you have CI)

✅ Require conversation resolution before merging

✅ Include administrators (enforce for everyone)

✅ Allow force pushes: DISABLED

✅ Allow deletions: DISABLED
```

## Automated PR Checks (Optional)

Consider adding GitHub Actions to validate PRs:

```yaml
# .github/workflows/validate-pr.yml
name: Validate ArgoCD Values

on:
  pull_request:
    paths:
      - 'charts/argocd-apps/values-*.yaml'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Helm
        uses: azure/setup-helm@v3
      
      - name: Lint Helm Chart
        run: helm lint ./charts/argocd-apps/
      
      - name: Test Template Rendering
        run: |
          helm template root-app ./charts/argocd-apps/ \
            -f ./charts/argocd-apps/values-production.yaml
      
      - name: Validate YAML
        run: |
          yamllint charts/argocd-apps/values-*.yaml
```

## Emergency Procedures

### Emergency Rollback (Outside Normal Hours)

1. Create rollback branch
2. Open PR with "🚨 URGENT" in title
3. Tag on-call approvers in PR
4. Use fast-track approval (single approver if critical)
5. Merge immediately after approval
6. Notify team in incident channel

### Bypassing PR (EXTREME EMERGENCY ONLY)

If ArgoCD UI access is required to manually sync during an outage:

```bash
# Only use in absolute emergency when PR process would cause downtime
argocd app set root-app-production --sync-policy none
argocd app set api-app --revision v1.2.3
argocd app sync api-app

# Then immediately after:
# 1. Create PR to match the manual change
# 2. Document in incident report
# 3. Get post-merge approval
```

## Summary

✅ **Always use PRs** - No direct pushes to main  
✅ **Clear descriptions** - Explain what and why  
✅ **Test first** - Run `./test-app-of-apps.sh`  
✅ **Get approvals** - Especially for production  
✅ **Monitor after merge** - Watch ArgoCD sync  
✅ **Fast rollback** - Have rollback plan ready  

Remember: PRs provide safety, transparency, and accountability for your deployments!

## Config Repository Tagging Best Practices

### Tagging Production Deployments

**Always tag the config repository after successful production deployments.**

```bash
# After PR is merged and deployment verified
git checkout main
git pull origin main

# Create annotated tag with deployment details
git tag -a deploy-prod-<app>-<version> -m "Production deployment details

Application: <app-name>
Version: <version>
Deployed: $(date)
Approved by: <approvers>
PR: <pr-link>
Incident: <if applicable>"

git push origin deploy-prod-<app>-<version>
```

### Example Tag Names

| Tag Name | Purpose |
|----------|---------|
| `deploy-prod-api-v1.3.0` | API v1.3.0 deployed to production |
| `deploy-staging-web-v2.1.0` | Web app v2.1.0 deployed to staging |
| `rollback-prod-api-to-v1.2.3` | Emergency rollback of API |
| `release-2024-01` | Monthly release bundle |

### Viewing Deployment History

```bash
# List all production deployment tags
git tag -l "deploy-prod-*"

# See what was deployed when
git log --tags="deploy-prod-*" --simplify-by-decoration --pretty="format:%ai %d"

# View specific deployment details
git show deploy-prod-api-v1.3.0

# See what changed between deployments
git diff deploy-prod-api-v1.2.3..deploy-prod-api-v1.3.0
```

### Using Tags for Rollback

```bash
# Find the previous good deployment
git tag -l "deploy-prod-api-*" --sort=-version:refname | head -5

# Check out that config state
git checkout deploy-prod-api-v1.2.3

# See what values file looked like
cat charts/argocd-apps/values-production.yaml

# Create rollback branch from that state
git checkout -b rollback/api-to-v1.2.3
git checkout main -- .
# Manually set values file to match v1.2.3
# Then create PR
```

Remember: **Config repo tags capture the deployment configuration**, not the application code!


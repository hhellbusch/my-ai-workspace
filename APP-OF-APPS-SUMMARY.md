# ArgoCD App of Apps Pattern - Implementation Summary

## Overview

This workspace now contains a complete implementation of the **ArgoCD App of Apps pattern** where:

✅ **Root Application** always points to `main` branch  
✅ **Child Applications** have their target revisions (tags/branches/commits) controlled via Helm values  
✅ **Environment-specific** values files for different deployment scenarios  
✅ **Complete documentation** and examples

## What Was Created

### 1. Root Application Manifests

These are the entry points that get deployed to ArgoCD. Each always points to `main`.

- **`root-app.yaml`** - Default root application
- **`root-app-production.yaml`** - Production environment root app
- **`root-app-staging.yaml`** - Staging environment root app

**Key Feature**: All root apps have `targetRevision: main`

### 2. Helm Chart (charts/argocd-apps/)

The core of the App of Apps pattern - a Helm chart that generates child Application resources.

- **`Chart.yaml`** - Helm chart metadata
- **`templates/app-of-apps.yaml`** - Template that creates child Applications
- **`values.yaml`** - Default values with example applications
- **`values-production.yaml`** - Production app versions (stable tags)
- **`values-staging.yaml`** - Staging app versions (RC/develop)
- **`values-development.yaml`** - Development app versions (feature branches)
- **`README.md`** - Detailed chart documentation

### 3. Documentation

Comprehensive guides for using the pattern:

- **`APP-OF-APPS-PATTERN.md`** - Complete pattern documentation
  - Architecture explanation
  - Usage instructions
  - Workflow examples
  - Best practices
  - Troubleshooting guide

- **`QUICK-REFERENCE.md`** - Quick command reference
  - Common commands
  - Typical workflows
  - Troubleshooting steps
  - Examples

- **`ARCHITECTURE-DIAGRAM.md`** - Visual diagrams
  - System architecture
  - Component interactions
  - Flow diagrams
  - Environment comparison

- **`APP-OF-APPS-SUMMARY.md`** - This file

### 4. Testing Tools

- **`test-app-of-apps.sh`** - Automated test script
  - Validates Helm chart
  - Tests all environment configs
  - Compares environments
  - Generates preview manifests

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│  1. Deploy Root App (always points to main)            │
│     kubectl apply -f root-app-production.yaml           │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  2. Root App Deploys Helm Chart                         │
│     - Reads charts/argocd-apps/                         │
│     - Uses values-production.yaml                       │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  3. Helm Chart Creates Child Applications               │
│     - example-app (targetRevision: v1.2.3)             │
│     - another-app (targetRevision: develop)            │
│     - monitoring (targetRevision: v2.0.0)              │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  4. Child Apps Deploy Their Resources                   │
│     - Each from its own targetRevision                  │
│     - To its own namespace                              │
└─────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Test Locally

```bash
# Run the test script
./test-app-of-apps.sh

# Preview what will be deployed
helm template root-app ./charts/argocd-apps/ -f ./charts/argocd-apps/values-production.yaml
```

### 2. Deploy to ArgoCD

```bash
# Deploy the root app
kubectl apply -f root-app-production.yaml

# Check status
kubectl get application root-app-production -n argocd
```

### 3. Update Application Version

```bash
# Create a feature branch
git checkout -b deploy/prod-example-app-v1.3.0

# Edit the values file
vim charts/argocd-apps/values-production.yaml
# Change targetRevision: v1.2.3 -> v1.3.0

# Commit and push branch
git add charts/argocd-apps/values-production.yaml
git commit -m "Update example-app to v1.3.0"
git push origin deploy/prod-example-app-v1.3.0

# Open pull request
gh pr create --title "Deploy example-app v1.3.0 to production" \
  --body "Promoting example-app to v1.3.0"

# After PR approval and merge, ArgoCD will auto-sync
```

## Key Files Explained

### Root App Structure

```yaml
# root-app-production.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app-production
spec:
  source:
    repoURL: https://github.com/your-org/your-repo.git
    targetRevision: main  # ← ALWAYS MAIN
    path: charts/argocd-apps
    helm:
      valueFiles:
        - values-production.yaml  # ← Controls child versions
```

### Values File Structure

```yaml
# charts/argocd-apps/values-production.yaml
applications:
  - name: example-app
    targetRevision: v1.2.3  # ← Tag for production
    namespace: example-app
    path: apps/example-app
    enabled: true
    syncPolicy:
      automated: true
      prune: true
      selfHeal: true
```

### Template Structure

```yaml
# charts/argocd-apps/templates/app-of-apps.yaml
{{- range .Values.applications }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ .name }}
spec:
  source:
    repoURL: {{ $.Values.source.repoURL }}
    targetRevision: {{ .targetRevision }}  # ← From values
    path: {{ .path }}
  destination:
    namespace: {{ .namespace }}
{{- end }}
```

## Environment Strategy

### Production
- **Root App**: `main` branch
- **App Versions**: Semantic version tags (`v1.2.3`)
- **Sync Policy**: Automated or manual (for critical apps)
- **Values File**: `values-production.yaml`

### Staging
- **Root App**: `main` branch
- **App Versions**: Release candidates (`v1.3.0-rc1`) or `develop`
- **Sync Policy**: Automated
- **Values File**: `values-staging.yaml`

### Development
- **Root App**: `main` branch
- **App Versions**: Feature branches or `develop`
- **Sync Policy**: Automated
- **Values File**: `values-development.yaml`

## Promotion Workflow

```
1. Development
   └─ Push to feature/new-feature
   └─ Create branch: deploy/dev-my-feature
   └─ Update values-development.yaml
   └─ Open PR → Approve → Merge to main
   └─ Test in dev cluster

2. Staging
   └─ Merge feature to develop branch
   └─ Staging auto-deploys (values-staging.yaml points to develop)
   └─ Test in staging cluster

3. Release
   └─ Create tag v1.3.0
   └─ Create branch: deploy/prod-v1.3.0
   └─ Update values-production.yaml to use v1.3.0
   └─ Open PR → Approve → Merge to main
   └─ Deploy to production
```

## Advantages of This Pattern

### 1. Centralized Version Control
All application versions defined in one place (values files on `main`)

### 2. GitOps Best Practice
- Root app always points to `main` (stable)
- All changes tracked in Git
- Easy rollback via Git revert

### 3. Environment Flexibility
- Different environments deploy different versions
- Same app can be on `v1.2.3` in prod, `v1.3.0-rc1` in staging, `develop` in dev

### 4. Easy Updates
- Update version by changing one line in values file
- Create PR and get approval
- Merge to main
- ArgoCD handles the rest

### 5. Audit Trail
- Full history in Git
- Clear who changed what version when
- Easy to understand deployment state

### 6. Declarative
- Desired state defined in Git
- ArgoCD ensures actual state matches desired state

## Common Operations

### View Current Versions

```bash
# Check what's deployed
kubectl get applications -n argocd

# View specific app
argocd app get example-app
```

### Update an App

```bash
# Create branch
git checkout -b deploy/prod-example-app-v2.0.0

# Edit values file
vim charts/argocd-apps/values-production.yaml

# Commit and push
git commit -am "Update example-app to v2.0.0"
git push origin deploy/prod-example-app-v2.0.0

# Open PR
gh pr create --title "Deploy example-app v2.0.0 to production" \
  --body "Promoting example-app to v2.0.0"

# After PR approval and merge, changes deploy
```

### Rollback

```bash
# Create rollback branch
git checkout -b rollback/example-app-to-v1.2.3

# Option 1: Git revert
git revert HEAD

# Option 2: Manually change values back
vim charts/argocd-apps/values-production.yaml
# Change targetRevision back to v1.2.3

git commit -am "Rollback example-app to v1.2.3"
git push origin rollback/example-app-to-v1.2.3

# Open PR
gh pr create --title "Rollback example-app to v1.2.3" \
  --body "Rolling back due to issues"

# After PR approval and merge, rollback completes
```

### Add New Application

```bash
# Create feature branch
git checkout -b add-new-app

# Edit values file
vim charts/argocd-apps/values-production.yaml

# Add new app entry
applications:
  - name: new-app
    targetRevision: v1.0.0
    namespace: new-app
    path: apps/new-app
    enabled: true
    syncPolicy:
      automated: true
      prune: true
      selfHeal: true

# Commit and push
git commit -am "Add new-app to production"
git push origin add-new-app

# Open PR
gh pr create --title "Add new-app to production" \
  --body "Adding new application new-app"

# After PR approval and merge, new app deploys
```

## Troubleshooting

### Root App Not Syncing

```bash
argocd app get root-app-production
argocd app sync root-app-production --force
```

### Child App Not Updating

```bash
# Check if root app synced
argocd app get root-app-production

# Check child app
argocd app get example-app

# Force refresh
argocd app get example-app --refresh
argocd app sync example-app
```

### View Differences

```bash
# See what would change
argocd app diff root-app-production
argocd app diff example-app
```

## Next Steps

1. **Customize Repository URL**
   - Edit all root-app-*.yaml files
   - Update `source.repoURL` to your Git repository

2. **Update Values Files**
   - Edit `charts/argocd-apps/values-*.yaml`
   - Add your actual applications
   - Set appropriate target revisions

3. **Test Locally**
   - Run `./test-app-of-apps.sh`
   - Verify generated manifests

4. **Deploy Root App**
   - `kubectl apply -f root-app-production.yaml`

5. **Monitor**
   - Watch ArgoCD UI
   - Verify apps sync correctly

## Best Practices

✅ Always use pull requests (never push directly to `main`)  
✅ Require PR approvals for production changes  
✅ Use semantic versioning for production (v1.2.3)  
✅ Test in dev/staging before production  
✅ Test PRs locally with `./test-app-of-apps.sh` before opening  
✅ Use meaningful commit messages and PR descriptions  
✅ Review values changes like code changes  
✅ Keep track of known-good versions  
✅ Document breaking changes in PRs  
✅ Monitor sync status after PR merge  

❌ Never push directly to `main` (always use PRs)  
❌ Never change root app's targetRevision from `main`  
❌ Never use branch names in production (use tags)  
❌ Never deploy directly without testing first  
❌ Never skip lower environments  

## Additional Resources

- **Full Documentation**: `APP-OF-APPS-PATTERN.md`
- **Pull Request Workflow**: `PR-WORKFLOW-GUIDE.md` ⭐ **Start here for deployment workflow**
- **Two-Repo Tagging**: `TWO-REPO-TAG-WORKFLOW.md` ⭐ **Understanding application vs config tags**
- **Quick Reference**: `QUICK-REFERENCE.md`
- **Architecture Diagrams**: `ARCHITECTURE-DIAGRAM.md`
- **Chart README**: `charts/argocd-apps/README.md`
- **ArgoCD Docs**: https://argo-cd.readthedocs.io/

## Summary

You now have a complete, production-ready implementation of the ArgoCD App of Apps pattern with:

- ✅ Root apps that always point to `main`
- ✅ Child app versions controlled via Helm values
- ✅ Environment-specific configurations
- ✅ Complete documentation
- ✅ Testing tools
- ✅ Best practices guidance

**To get started**: Run `./test-app-of-apps.sh` to validate the setup, then customize the values files for your applications!


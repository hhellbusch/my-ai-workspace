# ArgoCD App of Apps Pattern

## Overview

This repository implements the ArgoCD **App of Apps** pattern where:

1. **Root App** - A single ArgoCD Application that always points to `main` branch
2. **Child Apps** - Multiple applications managed by the root app, each with their own target revision (tag, branch, or commit)
3. **Helm-based Configuration** - Target revisions for child apps are controlled via Helm values

## Pattern Benefits

- **Centralized Version Control**: All child app versions are defined in one place
- **Environment-Specific Deployments**: Different environments can deploy different versions
- **GitOps Best Practice**: Root app always points to main, ensuring consistency
- **Easy Rollbacks**: Change versions by updating values and syncing
- **Flexible Deployment**: Deploy different branches/tags per app

## Architecture

```
┌─────────────────────────────────────────────────┐
│  root-app (ALWAYS points to main)              │
│  Location: root-app.yaml                        │
│  Target: main branch                            │
└───────────────┬─────────────────────────────────┘
                │
                │ Deploys Helm Chart
                │ (charts/argocd-apps/)
                │
                ▼
┌───────────────────────────────────────────────────┐
│  Helm Values (Define Target Revisions)           │
│  - values.yaml (default)                          │
│  - values-production.yaml                         │
│  - values-staging.yaml                            │
│  - values-development.yaml                        │
└───────────────┬───────────────────────────────────┘
                │
                │ Creates Child Applications
                │
        ┌───────┴────────┬────────────────┐
        ▼                ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ example-app  │  │ another-app  │  │ monitoring   │
│ (v1.2.3)     │  │ (develop)    │  │ (v2.0.0)     │
└──────────────┘  └──────────────┘  └──────────────┘
```

## Directory Structure

```
.
├── root-app.yaml                          # Default root app
├── root-app-production.yaml               # Production root app
├── root-app-staging.yaml                  # Staging root app
│
├── charts/argocd-apps/                    # Helm chart (App of Apps)
│   ├── Chart.yaml                         # Helm chart metadata
│   ├── values.yaml                        # Default values
│   ├── values-production.yaml             # Production values
│   ├── values-staging.yaml                # Staging values
│   ├── values-development.yaml            # Development values
│   └── templates/
│       └── app-of-apps.yaml              # Template for child apps
│
├── apps/                                  # Application manifests
│   ├── example-app/
│   └── another-app/
│
└── infrastructure/                        # Infrastructure manifests
    └── monitoring/
```

## Usage

### 1. Deploy the Root App

The root app can be deployed using `kubectl`:

```bash
# Deploy default root app
kubectl apply -f root-app.yaml

# Or deploy environment-specific root app
kubectl apply -f root-app-production.yaml
```

### 2. Root App Configuration

The root app **always** points to `main`:

```yaml
spec:
  source:
    repoURL: https://github.com/your-org/your-repo.git
    targetRevision: main  # ALWAYS MAIN
    path: charts/argocd-apps
```

### 3. Controlling Child App Versions

Child app versions are controlled via Helm values:

```yaml
# In values.yaml or values-production.yaml
applications:
  - name: example-app
    targetRevision: v1.2.3  # Tag, branch, or commit SHA
    namespace: example-app
    path: apps/example-app
    enabled: true
```

### 4. Updating Versions

To update a child app version:

1. Create a feature branch
2. Edit the appropriate values file (e.g., `values-production.yaml`)
3. Change the `targetRevision` for the app
4. Commit and push the branch
5. Open a pull request to `main`
6. Get approval and merge
7. Root app will sync and update the child app

**Example:**

```bash
# 1. Create a feature branch
git checkout -b deploy/prod-example-app-v1.3.0

# 2. Update example-app to v1.3.0 in production
vim charts/argocd-apps/values-production.yaml
# Change targetRevision: v1.2.3 -> targetRevision: v1.3.0

# 3. Commit changes
git add charts/argocd-apps/values-production.yaml
git commit -m "Update example-app to v1.3.0 in production"

# 4. Push branch
git push origin deploy/prod-example-app-v1.3.0

# 5. Open pull request (using GitHub CLI or web UI)
gh pr create --title "Deploy example-app v1.3.0 to production" \
  --body "Promoting example-app to version v1.3.0 in production environment"

# 6. After PR approval and merge, ArgoCD will automatically sync the changes
```

## Environment Examples

### Production
- Root app points to: `main`
- Child apps use: Stable tagged versions (e.g., `v1.2.3`)
- Sync policy: Automated with manual approval option for infrastructure

### Staging
- Root app points to: `main`
- Child apps use: Release candidates or develop branch (e.g., `v1.3.0-rc1`, `develop`)
- Sync policy: Fully automated

### Development
- Root app points to: `main`
- Child apps use: Feature branches or develop (e.g., `feature/new-feature`, `develop`)
- Sync policy: Fully automated

## Key Features

### 1. Environment-Specific Values

Each environment uses different value files:

```yaml
# root-app-production.yaml
helm:
  valueFiles:
    - values-production.yaml

# root-app-staging.yaml
helm:
  valueFiles:
    - values-staging.yaml
```

### 2. Inline Value Overrides

You can also override values inline in the root app:

```yaml
# In root-app.yaml
helm:
  values: |
    applications:
      - name: example-app
        targetRevision: v1.2.3
```

### 3. Enabling/Disabling Apps

Control which apps are deployed per environment:

```yaml
applications:
  - name: example-app
    enabled: true  # Deploy this app
  
  - name: another-app
    enabled: false  # Skip this app
```

### 4. Sync Policies

Configure sync behavior per app:

```yaml
applications:
  - name: example-app
    syncPolicy:
      automated: true   # Auto-sync
      prune: true       # Auto-delete removed resources
      selfHeal: true    # Auto-sync on drift
```

## Workflow

### Promoting Changes Across Environments

1. **Develop** → Feature branch deployed to dev environment
2. **Test** → Merge to develop, automatically deployed to staging
3. **Release** → Create tag (e.g., v1.2.3)
4. **Production** → Update production values to use the new tag via PR

```bash
# 1. Create and test feature
git checkout -b feature/my-feature
# ... make changes to application code ...
git commit -am "Add new feature"
git push origin feature/my-feature

# Update dev environment to test the feature
git checkout -b deploy/dev-my-feature
vim charts/argocd-apps/values-development.yaml
# Set: targetRevision: feature/my-feature
git commit -am "Deploy feature/my-feature to dev"
git push origin deploy/dev-my-feature
# Open PR, get approval, merge to main

# 2. Merge feature to develop via PR
git checkout -b merge/feature-to-develop
git merge feature/my-feature
git push origin merge/feature-to-develop
gh pr create --base develop --title "Merge feature/my-feature" --body "Ready for staging"
# After PR merge, staging automatically picks up develop (values-staging.yaml points to develop)

# 3. Create release tag via PR
git checkout -b release/v1.2.3
git merge origin/develop
git push origin release/v1.2.3
gh pr create --title "Release v1.2.3" --body "Merging develop to main for v1.2.3 release"
# After PR approval and merge to main, create and push tag
git checkout main && git pull origin main
git tag v1.2.3
git push origin v1.2.3

# 4. Update production via PR
git checkout -b deploy/prod-v1.2.3
vim charts/argocd-apps/values-production.yaml
# Set: targetRevision: v1.2.3
git commit -am "Promote v1.2.3 to production"
git push origin deploy/prod-v1.2.3
# Open PR, get approval, merge to main
gh pr create --title "Deploy v1.2.3 to production" \
  --body "Promoting example-app to production version v1.2.3"
```

## Best Practices

### Git Workflow
1. **Use Pull Requests**: Never push directly to `main` - always create a branch and open a PR
2. **Branch Naming**: Use descriptive prefixes like `deploy/prod-app-v1.2.3` or `rollback/app-to-v1.2.2`
3. **PR Descriptions**: Include version, environment, testing performed, and link to changelog
4. **Require Approvals**: Set up branch protection requiring at least one approval for production
5. **Review Changes**: Treat values file changes with the same rigor as code changes

### Version Management
6. **Root App Always on Main**: Never change the root app's `targetRevision` from `main`
7. **Use Tags for Production**: Always use semantic version tags (e.g., `v1.2.3`) in production
8. **Use Branches for Dev/Staging**: develop, feature branches for testing
9. **Test in Lower Environments**: Test new versions in dev/staging before production
10. **Document Changes**: Include reason for version changes in commit messages

### Deployment Safety
11. **Test Locally First**: Run `./test-app-of-apps.sh` before opening PR
12. **Gradual Rollout**: Deploy to dev → staging → production with verification at each step
13. **Monitor After Merge**: Watch ArgoCD sync status after PR is merged
14. **Keep Rollback Ready**: Document previous working versions in case rollback needed

## Troubleshooting

### Child App Not Syncing

```bash
# Check root app status
kubectl get application root-app -n argocd

# Check child app status
kubectl get application example-app -n argocd

# View application details
argocd app get root-app
argocd app get example-app
```

### Force Sync

```bash
# Sync root app
argocd app sync root-app

# Sync child app
argocd app sync example-app
```

### View Helm Values

```bash
# See what values are being used
argocd app manifests root-app
```

## Advanced Configuration

### Multi-Cluster Deployment

Deploy different apps to different clusters:

```yaml
applications:
  - name: example-app
    targetRevision: v1.2.3
    destination:
      server: https://cluster-1.example.com  # Specific cluster
    
  - name: another-app
    targetRevision: v2.0.0
    destination:
      server: https://cluster-2.example.com  # Different cluster
```

### Helm Source for Child Apps

If child apps are also Helm charts:

```yaml
applications:
  - name: example-app
    targetRevision: v1.2.3
    path: apps/example-app
    helm:
      valueFiles:
        - values-production.yaml
      parameters:
        - name: image.tag
          value: v1.2.3
```

## Summary

This pattern provides:
- ✅ Centralized version control for all applications
- ✅ GitOps workflow with main as source of truth via pull requests
- ✅ Environment-specific configurations
- ✅ Easy version updates and rollbacks through PR workflow
- ✅ Full audit trail via Git history and PR reviews
- ✅ Flexible deployment strategies per app
- ✅ Approval process for production changes

## Related Documentation

- **PR Workflow Guide**: [PR-WORKFLOW-GUIDE.md](../workflows/PR-WORKFLOW-GUIDE.md) - Essential guide for deploying via PRs
- **Quick Reference**: [QUICK-REFERENCE.md](../getting-started/QUICK-REFERENCE.md) - Command cheat sheet
- **Two-Repo Tag Workflow**: [TWO-REPO-TAG-WORKFLOW.md](../workflows/TWO-REPO-TAG-WORKFLOW.md) - Understanding config vs app repo tags


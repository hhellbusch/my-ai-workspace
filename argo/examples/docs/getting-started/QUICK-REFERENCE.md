# ArgoCD App of Apps - Quick Reference

## Core Concept

```
Root App (main) → Helm Chart → Child Apps (various versions)
```

- **Root App**: Always points to `main` branch
- **Child Apps**: Versions controlled by Helm values in root app

---

## Common Commands

### Deploy Root App

```bash
# Production
kubectl apply -f root-app-production.yaml

# Staging
kubectl apply -f root-app-staging.yaml

# Development
kubectl apply -f root-app.yaml
```

### Preview Changes

```bash
# See what will be created
helm template root-app ./charts/argocd-apps/ -f ./charts/argocd-apps/values-production.yaml

# Test locally
./test-app-of-apps.sh
```

### Check Status

```bash
# Root app status
kubectl get application root-app-production -n argocd
argocd app get root-app-production

# All apps
kubectl get applications -n argocd

# Specific child app
argocd app get example-app
```

### Sync Applications

```bash
# Sync root app (will sync all children)
argocd app sync root-app-production

# Sync specific child app
argocd app sync example-app

# Force sync
argocd app sync root-app-production --force
```

### Update Application Version

```bash
# 1. Create a feature branch
git checkout -b deploy/prod-example-app-v1.3.0

# 2. Edit the values file
vim charts/argocd-apps/values-production.yaml
# Change targetRevision: v1.2.3 -> v1.3.0

# 3. Commit and push branch
git add charts/argocd-apps/values-production.yaml
git commit -m "Promote example-app to v1.3.0 in production"
git push origin deploy/prod-example-app-v1.3.0

# 4. Open pull request
gh pr create --title "Deploy example-app v1.3.0 to production" \
  --body "Promoting example-app to v1.3.0"

# 5. After PR approval and merge, ArgoCD will auto-sync
# Or manually sync:
argocd app sync root-app-production
```

---

## File Structure

| File | Purpose | Target Revision |
|------|---------|-----------------|
| `root-app.yaml` | Default root app | `main` |
| `root-app-production.yaml` | Production root app | `main` |
| `root-app-staging.yaml` | Staging root app | `main` |
| `charts/argocd-apps/values.yaml` | Default app versions | Various |
| `charts/argocd-apps/values-production.yaml` | Production app versions | Stable tags |
| `charts/argocd-apps/values-staging.yaml` | Staging app versions | RC/develop |
| `charts/argocd-apps/values-development.yaml` | Dev app versions | Feature branches |

---

## Values File Structure

```yaml
# charts/argocd-apps/values-production.yaml
applications:
  - name: example-app              # App name
    targetRevision: v1.2.3         # Version (tag/branch/commit)
    namespace: example-app         # K8s namespace
    path: apps/example-app         # Path in repo
    enabled: true                  # Deploy or skip
    syncPolicy:
      automated: true              # Auto-sync on changes
      prune: true                  # Delete removed resources
      selfHeal: true               # Fix drift
```

---

## Typical Workflow

### Promoting a Change Through Environments

```
1. Feature Branch → Dev Environment
   └─ Create branch: deploy/dev-my-feature
   └─ Update values-development.yaml: targetRevision: feature/new-feature
   └─ Open PR → Approve → Merge to main
   └─ Test in dev

2. Develop Branch → Staging Environment
   └─ Merge feature to develop branch
   └─ values-staging.yaml already points to: targetRevision: develop
   └─ Auto-deploys to staging
   └─ Test in staging

3. Create Release → Production Environment
   └─ Create tag: v1.3.0
   └─ Create branch: deploy/prod-v1.3.0
   └─ Update values-production.yaml: targetRevision: v1.3.0
   └─ Open PR → Approve → Merge to main
   └─ Deploy to production
```

---

## Environment Patterns

### Production
```yaml
targetRevision: v1.2.3          # Stable semantic version tag
syncPolicy:
  automated: true               # Auto-sync (or false for manual)
  prune: true
  selfHeal: true
```

### Staging
```yaml
targetRevision: v1.3.0-rc1      # Release candidate
# OR
targetRevision: develop         # Latest develop branch
syncPolicy:
  automated: true               # Usually auto-sync
```

### Development
```yaml
targetRevision: develop         # Develop branch
# OR
targetRevision: feature/xyz     # Feature branch
syncPolicy:
  automated: true               # Always auto-sync
```

---

## Troubleshooting

### App Not Syncing

```bash
# Check sync status
argocd app get root-app-production

# Check sync errors
kubectl describe application root-app-production -n argocd

# Force refresh
argocd app get root-app-production --refresh

# Force sync
argocd app sync root-app-production --force
```

### Child App Issues

```bash
# List all child apps
kubectl get applications -n argocd -l managed-by=root-app

# Check specific child
argocd app get example-app

# View diff
argocd app diff example-app

# Check logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Rollback

```bash
# 1. Find previous version in Git history
git log charts/argocd-apps/values-production.yaml

# 2. Create rollback branch
git checkout -b rollback/example-app-to-v1.2.3

# 3. Revert the change
git revert <commit-hash>
# Or manually edit values file back to previous version
vim charts/argocd-apps/values-production.yaml
# Change targetRevision back
git commit -am "Rollback example-app to v1.2.3"

# 4. Push and create PR
git push origin rollback/example-app-to-v1.2.3
gh pr create --title "Rollback example-app to v1.2.3" \
  --body "Rolling back due to issues in v1.3.0"

# 5. After PR approval and merge, sync
argocd app sync root-app-production
```

### Validate Before Deploy

```bash
# Run test script
./test-app-of-apps.sh

# Lint Helm chart
helm lint ./charts/argocd-apps/

# Dry run
helm template root-app ./charts/argocd-apps/ -f ./charts/argocd-apps/values-production.yaml \
  | kubectl apply --dry-run=client -f -
```

---

## ArgoCD UI Access

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access at: https://localhost:8080
# Username: admin
# Password: (from above command)
```

---

## Best Practices Checklist

- [ ] Root app always points to `main`
- [ ] All changes go through pull requests (never push directly to `main`)
- [ ] PRs require approval before merging
- [ ] Production uses semantic version tags (v1.2.3)
- [ ] Changes tested in dev/staging first
- [ ] Meaningful commit messages and PR descriptions
- [ ] Test locally with `./test-app-of-apps.sh` before opening PR
- [ ] Monitor sync status after PR merge
- [ ] Document breaking changes in PR descriptions

---

## Quick Tips

1. **One source of truth**: All versions in values files on `main` branch
2. **Use Pull Requests**: All changes must go through PR workflow with approvals
3. **Auto-sync carefully**: Consider manual sync for critical production apps
4. **Use tags for prod**: Never use branch names in production
5. **Test first**: Always validate in lower environments
6. **Test PRs locally**: Run `./test-app-of-apps.sh` before opening PR
7. **Monitor closely**: Watch sync status after PR is merged
8. **Rollback ready**: Keep track of known-good versions and document in PRs

---

## Examples

### Deploy new version to all environments

```bash
# 1. Create and push tag
git tag v2.0.0
git push origin v2.0.0

# 2. Deploy to dev via PR
git checkout -b deploy/dev-v2.0.0
vim charts/argocd-apps/values-development.yaml
# Set: targetRevision: v2.0.0
git commit -am "Deploy v2.0.0 to dev"
git push origin deploy/dev-v2.0.0
gh pr create --title "Deploy v2.0.0 to dev" --body "Testing v2.0.0 in development"
# After PR merge, test in dev

# 3. Deploy to staging via PR
git checkout main && git pull origin main
git checkout -b deploy/staging-v2.0.0
vim charts/argocd-apps/values-staging.yaml
# Set: targetRevision: v2.0.0
git commit -am "Deploy v2.0.0 to staging"
git push origin deploy/staging-v2.0.0
gh pr create --title "Deploy v2.0.0 to staging" --body "Testing v2.0.0 in staging"
# After PR merge, test in staging

# 4. Deploy to production via PR
git checkout main && git pull origin main
git checkout -b deploy/prod-v2.0.0
vim charts/argocd-apps/values-production.yaml
# Set: targetRevision: v2.0.0
git commit -am "Deploy v2.0.0 to production"
git push origin deploy/prod-v2.0.0
gh pr create --title "Deploy v2.0.0 to production" --body "Deploying v2.0.0 to production"
# After PR approval and merge, production updates
```

### Disable app in specific environment

```yaml
# In values-staging.yaml
applications:
  - name: experimental-feature
    enabled: false  # Disabled in staging
```

### Different version per environment

```yaml
# values-production.yaml
applications:
  - name: api
    targetRevision: v1.0.0

# values-staging.yaml
applications:
  - name: api
    targetRevision: v1.1.0-rc1

# values-development.yaml
applications:
  - name: api
    targetRevision: feature/new-api
```

---

## Resources

- **PR Workflow Guide**: [PR-WORKFLOW-GUIDE.md](../workflows/PR-WORKFLOW-GUIDE.md) ⭐ **Essential reading**
- **Two-Repo Tagging**: [TWO-REPO-TAG-WORKFLOW.md](../workflows/TWO-REPO-TAG-WORKFLOW.md) ⭐ **Understand tagging**
- Full documentation: [APP-OF-APPS-PATTERN.md](../patterns/APP-OF-APPS-PATTERN.md) (includes architecture diagrams)
- Chart README: [charts/argocd-apps/README.md](../../charts/argocd-apps/README.md)
- ArgoCD docs: https://argo-cd.readthedocs.io/


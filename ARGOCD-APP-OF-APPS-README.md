# ArgoCD App of Apps Pattern - Getting Started

## 🎯 Quick Start

This repository implements an ArgoCD **App of Apps** pattern where:
- **Root app** always points to `main` branch
- **Child apps** have versions controlled via Helm values
- **All changes** go through pull requests (no direct pushes to main)

## 📚 Documentation

### Essential Reading

1. **[PR-WORKFLOW-GUIDE.md](PR-WORKFLOW-GUIDE.md)** ⭐ **START HERE**
   - Complete guide to deploying via pull requests
   - Branch naming conventions
   - PR templates and examples
   - Rollback procedures

2. **[TWO-REPO-TAG-WORKFLOW.md](TWO-REPO-TAG-WORKFLOW.md)** ⭐ **IMPORTANT**
   - Understanding application vs config repository tags
   - Why you need to tag the config repo after deployments
   - Complete workflow examples
   - Deployment history and audit trail

3. **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)**
   - Common commands
   - Quick examples
   - Troubleshooting

### Detailed Documentation

4. **[APP-OF-APPS-PATTERN.md](APP-OF-APPS-PATTERN.md)**
   - Complete pattern explanation
   - Workflows and best practices
   - Advanced configuration

5. **[ARCHITECTURE-DIAGRAM.md](ARCHITECTURE-DIAGRAM.md)**
   - Visual diagrams
   - System architecture
   - Flow charts

6. **[APP-OF-APPS-SUMMARY.md](APP-OF-APPS-SUMMARY.md)**
   - Implementation summary
   - What was created
   - Key concepts

## 🚀 Deployment Workflow

### Development
```bash
# 1. Create branch
git checkout -b deploy/dev-my-app-v1.2.3

# 2. Update values-development.yaml
vim charts/argocd-apps/values-development.yaml

# 3. Create PR
gh pr create --title "Deploy my-app v1.2.3 to dev"

# 4. Get approval → Merge → Deploy
```

### Production
```bash
# 1. Create branch
git checkout -b deploy/prod-my-app-v1.2.3

# 2. Update values-production.yaml
vim charts/argocd-apps/values-production.yaml

# 3. Create PR with full details
gh pr create --title "🚀 Deploy my-app v1.2.3 to production"

# 4. Get required approvals → Merge → Deploy → Monitor
```

See **[PR-WORKFLOW-GUIDE.md](PR-WORKFLOW-GUIDE.md)** for complete examples.

## 📁 Repository Structure

```
.
├── root-app-production.yaml       # Production root app (points to main)
├── root-app-staging.yaml          # Staging root app (points to main)
├── root-app.yaml                  # Default root app (points to main)
│
├── charts/argocd-apps/            # Helm chart (App of Apps)
│   ├── values-production.yaml    # Production app versions
│   ├── values-staging.yaml       # Staging app versions
│   ├── values-development.yaml   # Development app versions
│   └── templates/                # Helm templates
│
├── apps/                          # Your applications
│   ├── example-app/
│   └── another-app/
│
└── infrastructure/                # Infrastructure components
    └── monitoring/
```

## ✅ Best Practices

- ✅ **Always use PRs** - Never push directly to `main`
- ✅ **Test locally first** - Run `./test-app-of-apps.sh`
- ✅ **Require approvals** - Especially for production
- ✅ **Use semantic versions** - Tags like v1.2.3 for production
- ✅ **Deploy progressively** - Dev → Staging → Production
- ✅ **Monitor after merge** - Watch ArgoCD sync status

## 🔧 Common Tasks

### Test Changes Locally
```bash
./test-app-of-apps.sh
```

### Deploy Root App
```bash
kubectl apply -f root-app-production.yaml
```

### Check Status
```bash
argocd app get root-app-production
kubectl get applications -n argocd
```

### Update App Version
See [PR-WORKFLOW-GUIDE.md](PR-WORKFLOW-GUIDE.md#standard-deployment-workflow)

### Rollback
See [PR-WORKFLOW-GUIDE.md](PR-WORKFLOW-GUIDE.md#rollback-workflow)

## 🆘 Support

- **Issues?** See [Troubleshooting](QUICK-REFERENCE.md#troubleshooting)
- **Questions?** Check [APP-OF-APPS-PATTERN.md](APP-OF-APPS-PATTERN.md)
- **PR help?** Read [PR-WORKFLOW-GUIDE.md](PR-WORKFLOW-GUIDE.md)

## 📊 Architecture Overview

```
Root App (main)
    ↓
Helm Chart (values-production.yaml)
    ↓
Child Apps:
  - example-app (v1.2.3)
  - another-app (v2.1.0)
  - monitoring (v2.0.0)
```

All controlled via PRs to `main` branch!

## 🎓 Learning Path

1. Read [PR-WORKFLOW-GUIDE.md](PR-WORKFLOW-GUIDE.md) (15 minutes)
2. Run `./test-app-of-apps.sh` to see it work
3. Try a test deployment to dev environment
4. Read [QUICK-REFERENCE.md](QUICK-REFERENCE.md) for commands
5. Explore [APP-OF-APPS-PATTERN.md](APP-OF-APPS-PATTERN.md) for deep dive

## ⚠️ Important Reminders

- ❌ **Never** push directly to `main`
- ❌ **Never** change root app's targetRevision from `main`
- ❌ **Never** use branch names in production (use tags)
- ✅ **Always** create PR for changes
- ✅ **Always** get approval before merging
- ✅ **Always** test in lower environments first

---

**Ready to deploy?** Start with [PR-WORKFLOW-GUIDE.md](PR-WORKFLOW-GUIDE.md)!


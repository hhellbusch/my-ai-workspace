# ArgoCD App of Apps Helm Chart

This Helm chart implements the **App of Apps pattern** where a root ArgoCD Application manages multiple child applications, with each child app's target revision (branch, tag, or commit) controlled via Helm values.

## Key Concept

- **Root App**: Always points to `main` branch
- **Child Apps**: Each can deploy from different branches/tags/commits
- **Version Control**: All child app versions defined in Helm values

## How It Works

1. Deploy a root ArgoCD Application (always pointing to `main`)
2. Root app deploys this Helm chart
3. Helm chart reads values to determine which apps to deploy and at what version
4. Child ArgoCD Applications are created with their specific target revisions

## Directory Structure

```
your-repo/
├── root-app.yaml                    # Root app (points to main)
├── root-app-production.yaml         # Production root app
├── root-app-staging.yaml            # Staging root app
│
├── charts/argocd-apps/              # This Helm chart
│   ├── Chart.yaml
│   ├── values.yaml                  # Default values
│   ├── values-production.yaml       # Production app versions
│   ├── values-staging.yaml          # Staging app versions
│   ├── values-development.yaml      # Development app versions
│   └── templates/
│       └── app-of-apps.yaml        # Child app template
│
├── apps/                            # Application manifests
│   ├── example-app/                # Deployed from tag v1.2.3
│   └── another-app/                # Deployed from develop branch
│
└── infrastructure/                  # Infrastructure manifests
    └── monitoring/                  # Deployed from tag v2.0.0
```

## Quick Start

### 1. Deploy the Root App

```bash
kubectl apply -f root-app-production.yaml
```

### 2. Root App Points to Main

```yaml
# root-app-production.yaml
spec:
  source:
    targetRevision: main  # Always main!
    path: charts/argocd-apps
    helm:
      valueFiles:
        - values-production.yaml
```

### 3. Control Child App Versions

```yaml
# values-production.yaml
applications:
  - name: example-app
    targetRevision: v1.2.3  # Deploy from tag
    namespace: example-app
    path: apps/example-app
    enabled: true
  
  - name: another-app
    targetRevision: develop  # Deploy from branch
    namespace: another-app
    path: apps/another-app
    enabled: true
```

## Configuration

### Basic Configuration

```yaml
# values.yaml
argocd:
  namespace: argocd      # Where ArgoCD is installed
  project: default       # ArgoCD project

source:
  repoURL: https://github.com/your-org/your-repo.git

destination:
  server: https://kubernetes.default.svc
```

### Application Configuration

```yaml
applications:
  - name: example-app              # Application name
    targetRevision: v1.2.3         # Git tag/branch/commit
    namespace: example-app         # Kubernetes namespace
    path: apps/example-app         # Path in repo
    enabled: true                  # Deploy this app
    syncPolicy:
      automated: true              # Auto-sync
      prune: true                  # Delete removed resources
      selfHeal: true               # Correct drift
```

## Environment-Specific Values

Use different value files per environment:

```bash
# Production - stable versions
helm template argocd-apps . -f values-production.yaml

# Staging - release candidates
helm template argocd-apps . -f values-staging.yaml

# Development - latest branches
helm template argocd-apps . -f values-development.yaml
```

## Example Usage

### Preview Generated Manifests

```bash
# See what will be created
helm template argocd-apps . -f values.yaml

# Or for a specific environment
helm template argocd-apps . -f values-production.yaml
```

### Manual Deployment (for testing)

```bash
# Deploy using kubectl
helm template argocd-apps . -f values.yaml | kubectl apply -f -
```

### Update Application Version

```bash
# 1. Create feature branch
git checkout -b deploy/prod-example-app-v1.3.0

# 2. Edit values file
vim charts/argocd-apps/values-production.yaml
# Change targetRevision: v1.2.3 -> targetRevision: v1.3.0

# 3. Commit and push branch
git add charts/argocd-apps/values-production.yaml
git commit -m "Update example-app to v1.3.0"
git push origin deploy/prod-example-app-v1.3.0

# 4. Open pull request
gh pr create --title "Deploy example-app v1.3.0 to production" \
  --body "Promoting example-app to v1.3.0"

# 5. After PR approval and merge, root app auto-syncs (if enabled)
# Or manually sync:
argocd app sync root-app-production
```

## Use Cases

### Deploy Different Versions Per Environment

```yaml
# Production: stable version
applications:
  - name: api
    targetRevision: v2.1.0

# Staging: release candidate
applications:
  - name: api
    targetRevision: v2.2.0-rc1

# Development: latest code
applications:
  - name: api
    targetRevision: develop
```

### Gradual Rollout

```yaml
# Deploy to dev first
applications:
  - name: api
    targetRevision: feature/new-feature  # Test feature

# Then staging
applications:
  - name: api
    targetRevision: v2.2.0-rc1  # Release candidate

# Finally production
applications:
  - name: api
    targetRevision: v2.2.0  # Stable release
```

### Enable/Disable Applications

```yaml
applications:
  - name: experimental-feature
    enabled: false  # Disabled in production
    targetRevision: develop

  - name: core-api
    enabled: true   # Always enabled
    targetRevision: v1.0.0
```

## Best Practices

1. **Root app always on main**: Never change root app's targetRevision
2. **Use tags for production**: Semantic versioning (v1.2.3)
3. **Use branches for dev/staging**: develop, feature branches
4. **Test in lower environments first**: dev → staging → production
5. **Document version changes**: Clear commit messages

## Advanced Features

### Per-App Sync Policies

```yaml
applications:
  - name: critical-app
    syncPolicy:
      automated: false  # Manual approval required
  
  - name: standard-app
    syncPolicy:
      automated: true   # Auto-deploy
```

### Custom Namespaces

```yaml
applications:
  - name: app-1
    namespace: team-a  # Deploy to team-a namespace
  
  - name: app-2
    namespace: team-b  # Deploy to team-b namespace
```

## Troubleshooting

```bash
# Check root app status
kubectl get application root-app-production -n argocd

# Check child apps
kubectl get applications -n argocd

# View application details
argocd app get root-app-production
argocd app get example-app

# Force sync
argocd app sync root-app-production
```

## More Information

See [APP-OF-APPS-PATTERN.md](../../APP-OF-APPS-PATTERN.md) in the repository root for comprehensive documentation.


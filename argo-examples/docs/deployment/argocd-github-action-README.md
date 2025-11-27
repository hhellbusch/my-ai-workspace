# ArgoCD App of Apps - GitHub Action Deployment

Automated deployment of ArgoCD applications to OpenShift using GitHub Actions and Helm.

## Overview

This setup automatically:
1. Scans the `argo-examples/apps/` directory for subdirectories
2. Generates an ArgoCD Application resource for each directory
3. Deploys them to your OpenShift cluster

## Quick Start

### 1. Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

- **`OPENSHIFT_SERVER`**: Your OpenShift API server URL
  - Example: `https://api.cluster.example.com:6443`
- **`OPENSHIFT_TOKEN`**: Service account token for authentication

### 2. Update Helm Values

Edit `argo-examples/charts/argocd-apps/values.yaml`:

```yaml
source:
  repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git  # ← Update this
  targetRevision: HEAD
  path: argo-examples/apps  # Updated path after restructuring
```

### 3. Add Your Applications

Create a directory under `argo-examples/apps/` for each application:

```
argo-examples/apps/
├── my-frontend/
│   ├── deployment.yaml
│   └── service.yaml
├── my-backend/
│   └── kustomization.yaml
└── my-database/
    └── helm-chart/
```

### 4. Push to Main Branch

The GitHub Action will automatically:
- Discover all directories in `apps/`
- Generate ArgoCD Application manifests
- Apply them to your OpenShift cluster

## How It Works

### Workflow Process

```
Push to main
    ↓
Scan argo-examples/apps/ directory
    ↓
Find directories: ["my-frontend", "my-backend", "my-database"]
    ↓
Pass to Helm: --set-json 'applications=["my-frontend", "my-backend", "my-database"]'
    ↓
Helm generates 3 ArgoCD Application resources
    ↓
Apply to OpenShift cluster via oc apply
```

### Generated ArgoCD Application

For each directory (e.g., `my-frontend`), an Application resource is created:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-frontend
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git
    targetRevision: HEAD
    path: argo-examples/apps/my-frontend
  destination:
    server: https://kubernetes.default.svc
    namespace: my-frontend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Customization

### Change App Discovery Path

Edit `.github/workflows/deploy-argocd-apps.yml`:

```yaml
- name: Generate directory list for Helm values
  run: |
    APP_DIRS_PATH="./argo-examples/apps"  # Default path after restructuring
    # Or change to: APP_DIRS_PATH="./my-custom-apps-path"
```

### Filter Directories

Add filtering logic to the workflow:

```bash
# Only include directories starting with "app-"
DIRS=$(find ${APP_DIRS_PATH} -mindepth 1 -maxdepth 1 -type d -name 'app-*' -exec basename {} \;)
```

### Customize ArgoCD Applications

Edit `argo-examples/charts/argocd-apps/templates/app-of-apps.yaml` to:
- Deploy all apps to the same namespace
- Add custom labels or annotations
- Change sync policy
- Add health checks

## Manual Testing

Test locally before pushing:

```bash
# Navigate to the argo-examples directory
cd argo-examples

# Discover directories
APP_DIRS=$(find ./apps -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | jq -R -s -c 'split("\n") | map(select(length > 0))')

# Generate manifests
helm template argocd-apps ./charts/argocd-apps \
  --set-json "applications=$APP_DIRS"

# Apply to cluster (if logged in)
helm template argocd-apps ./charts/argocd-apps \
  --set-json "applications=$APP_DIRS" \
  | oc apply -f -
```

## Troubleshooting

### Workflow fails at "Generate directory list"

- Ensure the `argo-examples/apps/` directory exists and contains subdirectories
- Check that `jq` is available (it's pre-installed on GitHub Actions ubuntu-latest)

### Applications not appearing in ArgoCD

- Verify ArgoCD namespace matches configuration (default: `argocd`)
- Check service account permissions
- View workflow logs for errors

### Connection to OpenShift fails

- Verify `OPENSHIFT_SERVER` secret is correct
- Ensure `OPENSHIFT_TOKEN` has sufficient permissions
- Check if token has expired

## File Structure

```
your-repo/
├── .github/
│   └── workflows/
│       └── deploy-argocd-apps.yml    # GitHub Action workflow
└── argo-examples/
    ├── charts/
    │   └── argocd-apps/              # Helm chart
    │       ├── Chart.yaml
    │       ├── values.yaml
    │       ├── templates/
    │       │   └── app-of-apps.yaml
    │       └── README.md
    └── apps/                         # Your applications
        ├── app1/
        ├── app2/
        └── app3/
```

## Next Steps

1. Customize the Helm chart templates for your needs
2. Add environment-specific values files (values-dev.yaml, values-prod.yaml)
3. Set up branch-specific deployments (dev branch → dev cluster)
4. Add validation steps to the GitHub Action
5. Implement dry-run mode for pull requests


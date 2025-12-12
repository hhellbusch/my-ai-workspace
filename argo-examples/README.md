# ArgoCD Examples

Comprehensive examples and patterns for deploying applications with ArgoCD using the App-of-Apps pattern.

## 📁 Directory Structure

```
argo-examples/
├── README.md                        # This file
│
├── root-app.yaml                    # Root ArgoCD Application (default)
├── root-app-production.yaml         # Production root app
├── root-app-staging.yaml            # Staging root app
├── hubs.yaml                        # Multi-cluster hub configuration
│
├── docs/                            # 📚 All documentation organized by topic
│   ├── README.md                    # Documentation guide
│   ├── getting-started/             # Setup and quick reference guides
│   ├── patterns/                    # Architecture and design patterns
│   ├── workflows/                   # CI/CD and deployment workflows
│   └── deployment/                  # Deployment strategies
│
├── github-workflows/                # 🔄 Example GitHub Actions workflows
│   ├── README.md                    # Workflow documentation
│   ├── SETUP.md                     # Setup instructions
│   ├── WORKFLOW-DIAGRAM.md          # Visual workflow diagrams
│   ├── argocd-diff-preview.yml      # PR diff preview (no cluster access)
│   ├── argocd-live-diff.yml         # Live cluster diff (requires access)
│   ├── deploy-argocd-apps.yml       # Deployment workflow
│   ├── test-workflow.yml            # Test workflow example
│   ├── test-oc-install.yml          # OpenShift CLI test
│   ├── test-diff-locally.sh         # Local testing script
│   └── .yamllint                    # YAML linting configuration
│
├── scripts/                         # 🔧 Test and utility scripts
│   ├── test.sh                      # Quick app discovery test
│   └── test-app-of-apps.sh         # Comprehensive Helm chart test
│
├── charts/                          # ⎈ Helm charts
│   └── argocd-apps/                # App-of-Apps Helm chart
│       ├── templates/
│       ├── values.yaml              # Default values
│       ├── values-production.yaml   # Production configuration
│       ├── values-staging.yaml      # Staging configuration
│       └── values-development.yaml  # Development configuration
│
├── apps/                            # 📦 Application manifests
│   ├── example-app/                # Example application
│   └── another-app/                # Another example app
│
└── infrastructure/                  # 🏗️  Infrastructure components
    └── monitoring/                  # Monitoring stack example
```

## 🚀 Quick Start

### 1. Run Tests

Test the Helm chart generation:

```bash
cd argo-examples
bash scripts/test-app-of-apps.sh
```

### 2. Read Documentation

Start with the setup guide:

```bash
# View getting started documentation
cat docs/getting-started/SETUP-GUIDE.md

# See all available documentation
ls -R docs/
```

### 3. Deploy (when ready)

```bash
# Deploy the production root app
kubectl apply -f root-app-production.yaml
```

## 📚 Documentation

All documentation is organized in the [`docs/`](docs/) directory:

- **[Getting Started](docs/getting-started/)** - Setup guides and quick reference
- **[Patterns](docs/patterns/)** - App-of-Apps pattern and architecture
- **[Workflows](docs/workflows/)** - CI/CD and PR-based deployments
- **[Deployment](docs/deployment/)** - Deployment strategies and examples

See [docs/README.md](docs/README.md) for a complete documentation guide.

## 🔄 GitHub Workflows

The [`github-workflows/`](github-workflows/) directory contains example GitHub Actions workflows for ArgoCD automation:

- **[argocd-diff-preview.yml](github-workflows/argocd-diff-preview.yml)** - Generate Helm template diffs on PRs (no cluster access needed)
- **[argocd-live-diff.yml](github-workflows/argocd-live-diff.yml)** - Show diffs against live cluster (requires ArgoCD access)
- **[deploy-argocd-apps.yml](github-workflows/deploy-argocd-apps.yml)** - Automated deployment workflow

**Note:** These are **example workflows** to copy into your own repositories. They are not active in this repository.

See [github-workflows/README.md](github-workflows/README.md) for setup instructions and [github-workflows/SETUP.md](github-workflows/SETUP.md) for detailed configuration.

## 🎯 Key Concepts

### App-of-Apps Pattern

A root ArgoCD Application that manages multiple child applications:
- **Root App** → Always points to `main` branch
- **Child Apps** → Each can deploy from different tags/branches
- **Version Control** → All versions defined in Helm values

### Multi-Environment Support

Different environments use different Helm value files:
- **Production** → Stable tags (`v1.2.3`)
- **Staging** → Release candidates (`v1.3.0-rc1`)
- **Development** → Latest branches (`develop`, `feature/xyz`)

## 🔧 Available Scripts

Run from the `argo-examples` directory:

```bash
# Quick app discovery test
bash scripts/test.sh

# Comprehensive Helm chart testing (all environments)
bash scripts/test-app-of-apps.sh
```

## 📖 Common Tasks

### View Generated Manifests

```bash
cd charts/argocd-apps
helm template argocd-apps . -f values-production.yaml
```

### Test Locally

```bash
# Generate and validate
helm template argocd-apps charts/argocd-apps/ -f charts/argocd-apps/values.yaml

# Dry-run apply
helm template argocd-apps charts/argocd-apps/ -f charts/argocd-apps/values.yaml \
  | kubectl apply --dry-run=client -f -
```

### Update Application Version

1. Edit the appropriate values file:
   ```bash
   vim charts/argocd-apps/values-production.yaml
   ```

2. Change the `targetRevision` for your app:
   ```yaml
   applications:
     - name: example-app
       targetRevision: v1.3.0  # Updated from v1.2.3
   ```

3. Commit and push to main branch

4. ArgoCD will sync automatically (if auto-sync is enabled)

## 🏗️ Project Structure Philosophy

- **Root Level** → Operational files (root apps, manifests)
- **docs/** → All documentation, organized by topic
- **scripts/** → Utilities and test scripts
- **charts/** → Helm chart definitions
- **apps/** → Application manifests
- **infrastructure/** → Infrastructure component manifests

## 🔗 Related Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Helm Documentation](https://helm.sh/docs/)

## 📝 Next Steps

1. Read the [Setup Guide](docs/getting-started/SETUP-GUIDE.md)
2. Understand the [App-of-Apps Pattern](docs/patterns/APP-OF-APPS-PATTERN.md)
3. Review the [Quick Reference](docs/getting-started/QUICK-REFERENCE.md)
4. Explore [Deployment Strategies](docs/deployment/)
5. Set up your own applications following the examples

## 💡 Tips

- Keep the root app always pointing to `main` branch
- Use semantic versioning for production deployments
- Test changes in development/staging before production
- Document any custom modifications in the `docs/` directory
- Run tests before committing changes


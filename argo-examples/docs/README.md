# ArgoCD Examples - Documentation

This directory contains organized documentation for ArgoCD deployment patterns and workflows.

## 📚 Documentation Structure

### 🚀 Getting Started
Start here if you're new to this setup:
- **[SETUP-GUIDE.md](getting-started/SETUP-GUIDE.md)** - Initial setup and configuration
- **[QUICK-REFERENCE.md](getting-started/QUICK-REFERENCE.md)** - Common commands and quick reference

### 🎯 Patterns
Learn about the architectural patterns used:
- **[APP-OF-APPS-PATTERN.md](patterns/APP-OF-APPS-PATTERN.md)** - Comprehensive App-of-Apps pattern guide with architecture diagrams

### 🔄 Workflows
CI/CD and deployment workflows:
- **[PR-WORKFLOW-GUIDE.md](workflows/PR-WORKFLOW-GUIDE.md)** - Pull request based deployment workflow
- **[TWO-REPO-TAG-WORKFLOW.md](workflows/TWO-REPO-TAG-WORKFLOW.md)** - Managing deployments across repositories

### 🚢 Deployment
Deployment strategies and configurations:
- **[argocd-github-action-README.md](deployment/argocd-github-action-README.md)** - GitHub Actions integration
- **[multi-cluster-deployment.md](deployment/multi-cluster-deployment.md)** - Multi-cluster deployment strategies
- **[acm-rename-local-cluster.md](deployment/acm-rename-local-cluster.md)** - Renaming local-cluster in OpenShift ACM (full guide)
- **[acm-rename-quick-ref.md](deployment/acm-rename-quick-ref.md)** - ACM rename quick reference card
- **[two-folder-example.md](deployment/two-folder-example.md)** - Managing apps and infrastructure separately

## 📖 Recommended Reading Order

### For Beginners:
1. [SETUP-GUIDE.md](getting-started/SETUP-GUIDE.md)
2. [APP-OF-APPS-PATTERN.md](patterns/APP-OF-APPS-PATTERN.md)
3. [QUICK-REFERENCE.md](getting-started/QUICK-REFERENCE.md)
4. [argocd-github-action-README.md](deployment/argocd-github-action-README.md)

### For Advanced Users:
1. [TWO-REPO-TAG-WORKFLOW.md](workflows/TWO-REPO-TAG-WORKFLOW.md)
2. [multi-cluster-deployment.md](deployment/multi-cluster-deployment.md)
3. [PR-WORKFLOW-GUIDE.md](workflows/PR-WORKFLOW-GUIDE.md)
4. [two-folder-example.md](deployment/two-folder-example.md)

## 🔗 Related Resources

- **Parent Directory**: `../` - Root app manifests and operational files
- **Helm Charts**: `../charts/argocd-apps/` - Helm chart implementation
- **Scripts**: `../scripts/` - Test and utility scripts
- **Example Apps**: `../apps/` - Example application manifests
- **Infrastructure**: `../infrastructure/` - Infrastructure component manifests

## 📝 Contributing

When adding new documentation:
1. Choose the appropriate category (getting-started, patterns, workflows, or deployment)
2. Follow the existing naming conventions (kebab-case or UPPERCASE)
3. Update this README with a link to your new document
4. Consider the recommended reading order when adding foundational content


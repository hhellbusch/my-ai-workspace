# Standalone ArgoCD Examples — Documentation

Documentation for the standalone ArgoCD examples (not the fleet management
framework, which has its own docs at [`../framework/docs/`](../framework/docs/)).

## Getting Started

Start here if you are new to ArgoCD:

- [SETUP-GUIDE.md](getting-started/SETUP-GUIDE.md) — Initial setup and configuration
- [QUICK-REFERENCE.md](getting-started/QUICK-REFERENCE.md) — Common commands cheat sheet

## Patterns

Architectural patterns used across the examples:

- [APP-OF-APPS-PATTERN.md](patterns/APP-OF-APPS-PATTERN.md) — Comprehensive App-of-Apps guide
- [MULTIPLE-SOURCES-PATTERN.md](patterns/MULTIPLE-SOURCES-PATTERN.md) — Multi-source Application pattern (ArgoCD 2.6+)

## Workflows

CI/CD and deployment workflows:

- [PR-WORKFLOW-GUIDE.md](workflows/PR-WORKFLOW-GUIDE.md) — Pull request based deployment
- [TWO-REPO-TAG-WORKFLOW.md](workflows/TWO-REPO-TAG-WORKFLOW.md) — Managing deployments across repositories

## Deployment

Deployment strategies and configurations:

- [argocd-github-action-README.md](deployment/argocd-github-action-README.md) — GitHub Actions integration
- [multi-cluster-deployment.md](deployment/multi-cluster-deployment.md) — Multi-cluster deployment strategies
- [acm-rename-local-cluster.md](deployment/acm-rename-local-cluster.md) — Renaming local-cluster in OpenShift ACM
- [acm-rename-quick-ref.md](deployment/acm-rename-quick-ref.md) — ACM rename quick reference
- [two-folder-example.md](deployment/two-folder-example.md) — Apps and infrastructure separation

## Reference

- [ARGOCD-DIFF-PREVIEW-APP-OF-APPS.md](ARGOCD-DIFF-PREVIEW-APP-OF-APPS.md) — Diff preview strategies for App-of-Apps
- [VALIDATION-REPORT.md](VALIDATION-REPORT.md) — Pipeline validation assessment
- [CHANGELOG-MULTIPLE-SOURCES.md](CHANGELOG-MULTIPLE-SOURCES.md) — Multi-source support changelog

## Recommended Reading Order

**Beginners:**
1. [SETUP-GUIDE.md](getting-started/SETUP-GUIDE.md)
2. [APP-OF-APPS-PATTERN.md](patterns/APP-OF-APPS-PATTERN.md)
3. [QUICK-REFERENCE.md](getting-started/QUICK-REFERENCE.md)
4. [argocd-github-action-README.md](deployment/argocd-github-action-README.md)

**Advanced:**
1. [MULTIPLE-SOURCES-PATTERN.md](patterns/MULTIPLE-SOURCES-PATTERN.md)
2. [TWO-REPO-TAG-WORKFLOW.md](workflows/TWO-REPO-TAG-WORKFLOW.md)
3. [multi-cluster-deployment.md](deployment/multi-cluster-deployment.md)
4. [PR-WORKFLOW-GUIDE.md](workflows/PR-WORKFLOW-GUIDE.md)

**Fleet management (separate docs):**
If you are managing multiple clusters, see the [Fleet Framework](../framework/README.md)
and the [Operator's Guide](../framework/docs/OPERATORS-GUIDE.md) instead.

## Related

- [Standalone examples](../) — Root app manifests, Helm charts, Application examples
- [Fleet framework](../framework/) — Hub-and-spoke fleet management system
- [GitHub workflows](../github-workflows/) — CI/CD workflow examples


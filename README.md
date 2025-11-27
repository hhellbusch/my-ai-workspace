# DevOps Examples Workspace

This repository contains practical, runnable examples for various DevOps tools and patterns.

## Directory Structure

```
gemini-workspace/
├── ansible-examples/     # Ansible playbooks and patterns
├── argo-examples/        # ArgoCD configurations and workflows
└── notes/               # Miscellaneous notes organized by topic
    └── gaming/          # Gaming-related notes
```

## 📁 Ansible Examples

Located in `ansible-examples/`. Contains runnable Ansible playbooks demonstrating best practices and common patterns.

**What's included:**
- Retry logic for flaky operations
- Error handling with block/rescue
- Conditional task execution
- Virtual media management (Dell iDRAC)
- Recovery and retry patterns

[View Ansible Examples →](ansible-examples/README.md)

## 📁 Argo CD Examples

Located in `argo-examples/`. Contains ArgoCD App-of-Apps patterns, multi-environment configurations, and GitHub Actions workflows.

**What's included:**
- App-of-Apps pattern implementation
- Multi-environment deployments (dev/staging/production)
- GitHub Actions integration
- Helm chart templates
- Tag-based deployment workflows
- Test scripts and utilities

**Directory structure:**
- `docs/` - All documentation organized by topic (getting-started, patterns, workflows, deployment)
- `scripts/` - Test and utility scripts
- `charts/` - Helm chart definitions
- `apps/` - Example application manifests
- `infrastructure/` - Infrastructure component manifests

**Key documentation:**
- [ArgoCD Examples Overview](argo-examples/README.md) - Main overview
- [Documentation Guide](argo-examples/docs/README.md) - Complete documentation index
- [Setup Guide](argo-examples/docs/getting-started/SETUP-GUIDE.md) - Getting started
- [Quick Reference](argo-examples/docs/getting-started/QUICK-REFERENCE.md) - Common commands
- [App-of-Apps Pattern](argo-examples/docs/patterns/APP-OF-APPS-PATTERN.md) - Pattern explanation

## Getting Started

### Prerequisites

**For Ansible examples:**
- Ansible 2.9+ installed
- Python 3.6+

**For ArgoCD examples:**
- kubectl configured
- Helm 3.x installed
- Access to a Kubernetes cluster (optional for testing)
- ArgoCD installed (optional for full deployment)

### Quick Start

**Ansible:**
```bash
cd ansible-examples/1_retry_on_timeout
ansible-playbook playbook.yml
```

**ArgoCD:**
```bash
cd argo-examples
# Test Helm chart generation
bash scripts/test-app-of-apps.sh

# Or quick app discovery test
bash scripts/test.sh
```

## Contributing

Each subdirectory contains its own README with detailed instructions for running the examples.

## License

These are example configurations for educational and reference purposes.


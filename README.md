# DevOps Examples Workspace

This repository contains practical, runnable examples for various DevOps tools and patterns, enhanced with an integrated meta-development system powered by [TÂCHES Claude Code Resources](https://github.com/glittercowboy/taches-cc-resources).

## 📖 For Users of This Repository

**Welcome!** This repository contains production-ready examples and troubleshooting guides for:

- **Ansible Automation** - 9 complete examples covering retry patterns, error handling, BMC operations, parallel execution, and more
- **OpenShift/Kubernetes** - 7 detailed troubleshooting guides for bare-metal clusters, CSR management, networking issues, and cluster recovery
- **ArgoCD/GitOps** - Application deployment patterns, multi-cluster configurations, and app-of-apps patterns
- **CoreOS/Ignition** - System configuration examples including virtual media ejection and automated setup

**Important Notes:**

- ✅ **All credentials are examples** - Passwords like "calvin", "password", "changeme" are placeholders for demonstration
- ✅ **All IP addresses are examples** - Uses RFC1918 private ranges (192.168.x.x, 10.x.x.x, 172.16.x.x)
- ✅ **All hostnames are generic** - master-0, server1, bastion.example.com, etc.
- 📝 **Adapt to your environment** - Copy `.example.yml` files, update with your credentials, never commit real secrets

**Getting Started:**

1. **Clone the repository**: `git clone <repo-url>`
2. **Explore examples**: Browse `ansible-examples/`, `ocp-troubleshooting/`, etc.
3. **Copy and customize**: Use `.example.yml` templates, update for your infrastructure
4. **Keep secrets safe**: Real inventory files and credentials should be in `.gitignore`

**Meta-Development System:**

This repository also includes a sophisticated AI-assisted development system (Skills, Commands, Agents). See the Meta-Development System section below for details. This is optional - the core examples work independently.

## 🧠 Meta-Development System

This workspace includes a sophisticated meta-development system with **Skills**, **Commands**, and **Agents** that provide AI-assisted development capabilities:

- **27 Commands** - Slash commands for planning, debugging, todo management, and thinking frameworks
- **7 Skills** - Autonomous workflows for creating skills, plans, prompts, and more
- **3 Agents** - Specialized auditors for quality assurance

**Quick Start:**
```bash
# Create a new skill
/create-agent-skill [description]

# Audit existing skill
/audit-skill path/to/SKILL.md

# Create a project plan
/create-plan [what to build]

# Debug with expert methodology
/debug
```

**Documentation:**
- [QUICKSTART.md](QUICKSTART.md) - **Start here!** Quick start with examples
- [INTEGRATION.md](INTEGRATION.md) - Complete integration and usage guide
- [skills/REGISTRY.md](skills/REGISTRY.md) - Available skills index
- [commands/README.md](commands/README.md) - Available commands reference
- [agents/REGISTRY.md](agents/REGISTRY.md) - Available agents reference
- [.cursorrules](.cursorrules) - System configuration

**Attribution:** The meta-development system is adapted from [TÂCHES CC Resources](https://github.com/glittercowboy/taches-cc-resources) by [@glittercowboy](https://github.com/glittercowboy). See original repository for updates and community resources.

## Directory Structure

```
gemini-workspace/
├── skills/              # Meta-development skills (7 total)
├── commands/            # Slash commands (27 total)
├── agents/              # Specialized subagents (3 total)
├── ansible-examples/    # Ansible playbooks and patterns
├── argo-examples/       # ArgoCD configurations and workflows
├── coreos-examples/     # CoreOS/Ignition configurations and patterns
├── ocp-troubleshooting/ # OpenShift troubleshooting guides
└── notes/              # Miscellaneous notes organized by topic
    └── gaming/         # Gaming-related notes
```

## 🧠 Meta-Development System

Located in `skills/`, `commands/`, and `agents/`. An integrated system for AI-assisted development.

**Key Features:**
- **Planning & Execution** - Create hierarchical project plans and execute them with `/create-plan` and `/run-plan`
- **Skill Creation** - Build new skills with `/create-agent-skill` and audit with `/audit-skill`
- **Expert Debugging** - Systematic investigation with `/debug`
- **Todo Management** - Capture context with `/add-to-todos`, resume with `/check-todos`
- **Thinking Frameworks** - Apply mental models with `/consider:first-principles`, `/consider:pareto`, etc.

**Quick Examples:**
```bash
# Create a skill for managing Docker containers
/create-agent-skill Create a skill for Docker container management

# Audit an existing skill
/audit-skill skills/manage-docker/SKILL.md

# Plan a new feature
/create-plan Build authentication system with JWT tokens

# Debug an issue systematically
/debug

# Capture a task for later
/add-to-todos Optimize database queries for user search
```

[View Meta-Development Documentation →](INTEGRATION.md)

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

## 📁 CoreOS Examples

Located in `coreos-examples/`. Contains Ignition configurations and patterns for RHEL CoreOS and Fedora CoreOS.

**What's included:**
- Auto-eject installation media after install
- Systemd service patterns
- Butane (YAML) to Ignition (JSON) examples
- Multiple deployment scenarios (physical, VMware, Redfish/BMC)
- Production-ready configurations with error handling

[View CoreOS Examples →](coreos-examples/README.md)

**Featured example:**
- [ISO Auto-Eject](coreos-examples/iso-eject-after-install/) - Automatically eject installation media after CoreOS completes installation

## 📁 OpenShift Troubleshooting

Located in `ocp-troubleshooting/`. Comprehensive troubleshooting guides for common OpenShift cluster issues.

**What's included:**
- Control plane component troubleshooting
- Step-by-step diagnostic procedures
- Automated diagnostic scripts
- Visual decision trees and flowcharts
- Quick reference guides
- Example outputs and resolution steps

[View OpenShift Troubleshooting Guides →](ocp-troubleshooting/README.md)

**Available guides:**
- [kube-controller-manager Crash Loop](ocp-troubleshooting/kube-controller-manager-crashloop/README.md) - Complete guide for diagnosing and fixing controller manager issues
- [Bare Metal Node Inspection Timeout](ocp-troubleshooting/bare-metal-node-inspection-timeout/README.md) - Troubleshooting nodes stuck in inspecting state during bare metal installation
- [CSR Management](ocp-troubleshooting/csr-management/README.md) - Certificate Signing Request approval and troubleshooting with real-world examples

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

**For CoreOS examples:**
- butane (for converting YAML to Ignition JSON)
- coreos-installer (for embedding Ignition in ISOs)
- RHEL CoreOS or Fedora CoreOS ISO

**For OpenShift troubleshooting:**
- oc CLI configured with cluster admin access
- jq (optional, for enhanced JSON parsing)
- Access to an OpenShift 4.x cluster

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

**CoreOS:**
```bash
cd coreos-examples/iso-eject-after-install
# Convert Butane YAML to Ignition JSON
butane --pretty --strict basic-eject.bu -o basic-eject.ign

# See QUICK-START.md for complete workflow
```

**OpenShift Troubleshooting:**
```bash
cd ocp-troubleshooting/kube-controller-manager-crashloop
# Run automated diagnostic script
./diagnostic-script.sh

# Or follow manual troubleshooting guide
cat README.md
```

## Contributing

Each subdirectory contains its own README with detailed instructions for running the examples.

## License

These are example configurations for educational and reference purposes.


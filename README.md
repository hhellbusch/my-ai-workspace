# DevOps Examples Workspace

This repository contains practical, runnable examples for various DevOps tools and patterns, enhanced with an integrated meta-development system powered by [TÂCHES Claude Code Resources](https://github.com/glittercowboy/taches-cc-resources).

## ⚠️ AI-Generated Content Notice

**The majority of content in this workspace was created with AI assistance (Claude Code).**

This disclosure is provided in the interest of transparency and to help you make informed decisions about using this content:

**What this means:**
- Most documentation, code examples, playbooks, and troubleshooting guides were generated or substantially modified with AI assistance
- Content represents AI-generated solutions based on prompts and requirements, not solely human expertise
- Examples may contain patterns or approaches that require validation for your specific use case

**Why additional scrutiny matters:**
- **Test before production**: All examples should be thoroughly tested in non-production environments
- **Verify accuracy**: Cross-reference configurations with official documentation for your tool versions
- **Validate logic**: Review conditional logic, error handling, and edge cases for your specific scenarios
- **Check currency**: AI training data has cutoff dates; verify that approaches align with current best practices

**How to use this content effectively:**
- Treat examples as **starting points and learning resources**, not authoritative references
- **Understand before copying**: Read through code to ensure you understand what it does
- **Adapt to your environment**: Customize configurations for your infrastructure and requirements
- **Verify credentials and endpoints**: Never use example credentials or IP addresses in production

**What makes this content valuable:**
- Demonstrates common patterns and solutions in a runnable format
- Provides well-structured examples following documented best practices
- Includes extensive documentation and explanations
- Offers a foundation for adaptation to specific needs

**Bottom line:** This workspace provides useful reference implementations and learning resources, but should be treated as AI-assisted documentation requiring human review and validation rather than production-ready code.

## 📖 For Users of This Repository

**Welcome!** This repository contains production-ready examples and troubleshooting guides for:

- **Ansible Automation** - 12 complete examples covering retry patterns, error handling, BMC operations, parallel execution, and more
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
2. **Explore examples**: Browse `ansible/examples/`, `ocp/troubleshooting/`, etc.
3. **Copy and customize**: Use `.example.yml` templates, update for your infrastructure
4. **Keep secrets safe**: Real inventory files and credentials should be in `.gitignore`

**Project Backlog:**

See [`BACKLOG.md`](BACKLOG.md) for what's currently in progress, what's coming next, and recent completed work.

**Meta-Development System:**

This repository also includes a sophisticated AI-assisted development system (Skills, Commands, Agents). See the Meta-Development System section below for details. This is optional - the core examples work independently.

## 🧠 Meta-Development System

This workspace includes a sophisticated meta-development system with **Skills**, **Commands**, and **Agents** that provide AI-assisted development capabilities:

- **23 Commands** - Slash commands for planning, debugging, quality gates, session management, and thinking frameworks
- **10 Skills** (+2 expertise) - Autonomous workflows for planning, research, debugging, and more
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
- [.cursor/skills/REGISTRY.md](.cursor/skills/REGISTRY.md) - Available skills index
- [.cursor/commands/README.md](.cursor/commands/README.md) - Available commands reference
- [.cursor/agents/REGISTRY.md](.cursor/agents/REGISTRY.md) - Available agents reference
- [.cursorrules](.cursorrules) - System configuration

**Attribution:** The meta-development system is adapted from [TÂCHES CC Resources](https://github.com/glittercowboy/taches-cc-resources) by [@glittercowboy](https://github.com/glittercowboy). See original repository for updates and community resources.

## Directory Structure

```
./
├── .cursor/
│   ├── skills/                # Meta-development skills (10 + 2 expertise)
│   ├── commands/              # Slash commands (21 total, including /review, /audit, /organize)
│   ├── agents/                # Specialized subagents
│   └── rules/                 # Always-applied conventions (repo structure, pre-commit review, cross-linking)
├── .planning/                 # Project briefs, roadmaps, style guides, phase plans
├── ansible/
│   ├── examples/              # Runnable Ansible playbooks and patterns (numbered)
│   └── troubleshooting/       # Ansible/AAP troubleshooting guides
├── argo/
│   ├── examples/              # ArgoCD configs, app-of-apps, GitOps workflows
│   └── labs/                  # Hands-on ArgoCD/GitOps lab exercises
├── coreos/
│   └── examples/              # CoreOS/Ignition/Butane configurations
├── docs/                      # Essays and guides (engineering + philosophy tracks)
├── examples/                  # Standalone scripts and artifacts referenced by docs
├── git-projects/              # External git repos for exploration/contribution (gitignored)
├── library/                   # Personal reference library (books, talks, articles with AI summaries)
├── notes/                     # Informal notes and quick references
├── ocp/
│   ├── examples/              # OpenShift configuration examples and templates
│   ├── troubleshooting/       # OpenShift troubleshooting guides
│   └── install/               # Local OCP install working directory (gitignored)
├── prompts/                   # Structured AI prompt templates for repeatable tasks
├── research/                  # Research workspaces (sources, findings, assessments)
├── rhacm/
│   └── examples/              # RHACM configurations
└── vault/
    └── integration/           # HashiCorp Vault integration patterns
```

See [`.cursor/rules/repo-structure.md`](.cursor/rules/repo-structure.md) for full conventions on where new content should go.

## 🧠 Meta-Development System

Located in `.cursor/skills/`, `.cursor/commands/`, and `.cursor/agents/`. An integrated system for AI-assisted development.

**Key Features:**
- **Planning & Execution** - Create hierarchical project plans and execute them with `/create-plan` and `/run-plan`
- **Skill Creation** - Build new skills with `/create-agent-skill` and audit with `/audit-skill`
- **Expert Debugging** - Systematic investigation with `/debug`
- **Project Backlog** - Track ideas, in-flight work, and completed items with `/backlog`
- **Thinking Frameworks** - Apply mental models with `/consider:first-principles`, `/consider:pareto`, etc.

**Quick Examples:**
```bash
# Create a skill for managing Docker containers
/create-agent-skill Create a skill for Docker container management

# Audit an existing skill
/audit-skill .cursor/skills/manage-docker/SKILL.md

# Plan a new feature
/create-plan Build authentication system with JWT tokens

# Debug an issue systematically
/debug

# Add to project backlog
/backlog add Optimize database queries for user search
```

[View Meta-Development Documentation →](INTEGRATION.md)

## 📁 Ansible

Located in `ansible/`. Playbooks, patterns, and troubleshooting for Ansible and AAP.

- [Examples](ansible/examples/README.md) — 13 runnable playbooks: retry logic, error handling, parallel execution, BMC operations, Dell memory validation
- [Troubleshooting](ansible/troubleshooting/README.md) — AAP 2.5 token 404 and other guides

## 📁 ArgoCD

Located in `argo/examples/`. App-of-Apps patterns, multi-environment configurations, Helm charts, and GitHub Actions workflows.

- [Overview](argo/examples/README.md) — Main index
- [Documentation](argo/examples/docs/README.md) — Getting started, patterns, workflows
- [Setup Guide](argo/examples/docs/getting-started/SETUP-GUIDE.md)
- [App-of-Apps Pattern](argo/examples/docs/patterns/APP-OF-APPS-PATTERN.md)

## 📁 CoreOS

Located in `coreos/examples/`. Ignition configurations and Butane patterns for RHEL CoreOS and Fedora CoreOS.

- [Examples](coreos/examples/README.md) — ISO auto-eject, systemd patterns, multi-deployment scenarios
- [ISO Auto-Eject](coreos/examples/iso-eject-after-install/) — Featured example

## 📁 OpenShift

Located in `ocp/`. Configuration examples, troubleshooting guides, and install working directory.

- [Examples](ocp/examples/README.md) — NAD configs, OVN-Kubernetes, SNO KVM lab
- [Troubleshooting](ocp/troubleshooting/README.md) — 13+ guides: API slowness, bare metal inspection, CSR management, kube-controller-manager crashes, and more
- [Debug Toolbox Container](ocp/troubleshooting/debug-toolbox-container/README.md) — Ephemeral debug containers for network troubleshooting

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
cd ansible/examples/001_retry_on_timeout
ansible-playbook playbook.yml
```

**ArgoCD:**
```bash
cd argo/examples
# Test Helm chart generation
bash scripts/test-app-of-apps.sh

# Or quick app discovery test
bash scripts/test.sh
```

**CoreOS:**
```bash
cd coreos/examples/iso-eject-after-install
# Convert Butane YAML to Ignition JSON
butane --pretty --strict basic-eject.bu -o basic-eject.ign

# See QUICK-START.md for complete workflow
```

**OpenShift Troubleshooting:**
```bash
cd ocp/troubleshooting/kube-controller-manager-crashloop
# Run automated diagnostic script
./diagnostic-script.sh

# Or follow manual troubleshooting guide
cat README.md
```

## Contributing

Each subdirectory contains its own README with detailed instructions for running the examples.

## License

These are example configurations for educational and reference purposes.


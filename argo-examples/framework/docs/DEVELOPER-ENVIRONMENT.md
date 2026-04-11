# Developer Environment Setup

How to get a working environment for operating the fleet management framework.
This guide is written for the majority case: **Windows workstations** in an
enterprise environment. Three paths are available — pick the one that fits
your situation.

> **AI Disclosure:** This document was created with AI assistance.

---

## Quick Decision Matrix

| Criteria | DevSpaces | WSL | Git Bash (minimal) |
|----------|-----------|-----|--------------------|
| Setup effort | Lowest (browser only) | Medium (one-time WSL enablement) | Lowest (installer) |
| AI assistant support | Full (Copilot CLI, Claude Code) | Full | Limited |
| Works from any machine | Yes (browser-based) | No (your PC only) | No (your PC only) |
| Offline capable | No | Yes | Yes (limited) |
| Full Linux terminal | Yes | Yes | Partial |
| Framework scripts work | All | All | Most (some limitations) |
| IT ticket required | No (if DevSpaces is available) | Yes (WSL enablement) | No |

**Recommendation for most operators:**
- Start with **DevSpaces** — zero setup, everything pre-installed, AI tools included
- If you need offline access or prefer a local environment, set up **WSL**
- Use **Git Bash** only as a stopgap while WSL is being enabled

---

## Path 1: OpenShift DevSpaces (Recommended)

DevSpaces gives you a full Linux development environment in your browser.
No installation. No IT tickets. The framework team provides a custom
workspace image with every tool pre-installed — including AI coding
assistants that can help you write YAML and debug issues.

### What You Get

- VS Code editor in the browser with a full terminal
- All CLI tools pre-installed: `helm`, `yq`, `oc`, `argocd`, `gh`, `git`
- AI coding assistants: GitHub Copilot CLI, Claude Code
- Shell completions and convenient aliases
- Your workspace persists between sessions
- Works from any machine — desktop, laptop, even a tablet

### Starting a Workspace

1. Open the DevSpaces dashboard in your browser (URL provided by your platform team)
2. Click **Create Workspace**
3. Enter the Git repository URL for the fleet framework
4. DevSpaces auto-detects the `devfile.yaml` and builds the workspace
5. Wait ~2 minutes for the workspace to start
6. You are dropped into VS Code with a terminal ready to go

### First-Time Setup Inside DevSpaces

When the workspace starts for the first time, it asks for your Git identity:

```bash
# This is prompted automatically — just type your name and email
Enter your full name: Jane Smith
Enter your company email: jane.smith@example.com
```

Then authenticate with GitHub:

```bash
# Run the setup command from the DevSpaces command palette, or in the terminal:
gh auth login
```

Follow the prompts to authenticate. This is stored persistently — you only do
it once.

### Using the AI Assistants

The DevSpaces image includes AI coding tools that help operators who are
learning YAML and GitOps. They are optional — use whichever you are
comfortable with.

#### GitHub Copilot CLI

Ask Copilot to suggest commands or explain things:

```bash
# Ask for a command suggestion
gh copilot suggest "how to check what monitoring retention is set for prod-east-1"

# Ask it to explain a command you found
gh copilot explain "helm template cert-manager apps/cert-manager/ --values groups/all/values.yaml"
```

To set up Copilot:

```bash
# One-time setup (requires GitHub Copilot license)
gh extension install github/gh-copilot
```

#### Claude Code

Claude Code is an AI assistant that understands the full codebase and can
help you write changes:

```bash
# Start an interactive session
claude

# Ask it to make a change for you
# "Enable cert-manager on cluster example-prod-east-1"
# "Add a new worker node to the bare metal inventory for prod-east-1"
# "What would change if I set monitoring retention to 30d for all production clusters?"
```

To set up Claude Code:

```bash
# One-time authentication
claude auth login
```

#### When to Use AI Assistants

| Task | AI Can Help With |
|------|-----------------|
| Writing YAML | "Add a new worker node entry to the baremetal inventory" |
| Understanding values | "Explain what cluster.features.gpu.mig.strategy does" |
| Debugging | "Why isn't cert-manager deploying to my cluster?" |
| Learning | "Explain the value cascade for this framework" |
| Commands | "How do I check if the aggregation script output matches?" |

The assistants see the same files you see. They do not have access to
live clusters or secrets.

### DevSpaces Quick Reference

```bash
# Pre-configured aliases (type these in the terminal)
fleet-diff release/production main           # Compare desired state
trace-value example-prod-east-1 cluster.features.monitoring.retention
lint-arrays                                   # Check array safety
create-app my-new-app                        # Scaffold a new app

# AI shortcuts
ask-copilot "how to enable an app on a cluster"
explain-copilot "yq '.cluster.groups.env' clusters/example-prod-east-1/cluster.yaml"
```

---

## Path 2: WSL (Windows Subsystem for Linux)

WSL gives you a full Linux environment on your Windows machine. It runs
natively — not in a VM — so performance is identical to real Linux. Once
enabled, all framework scripts work without modification.

### Prerequisites

Your enterprise has a procedure document for enabling WSL. Follow that
process first. Once WSL is active and you have a Linux distribution
installed (Ubuntu is recommended), continue below.

### Installing Framework Tools

Open your WSL terminal (search for "Ubuntu" in the Start menu) and run:

```bash
# Update package lists
sudo apt update && sudo apt upgrade -y

# Git (usually pre-installed)
sudo apt install -y git

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# yq
sudo wget -qO /usr/local/bin/yq \
  https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# GitHub CLI
(type -p wget >/dev/null || sudo apt install wget -y) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y

# colordiff (optional, for colorized diff output)
sudo apt install -y colordiff

# yamllint
pip3 install yamllint

# oc CLI (download from your OpenShift cluster's web console or mirror)
# Replace the URL with your enterprise mirror
curl -sSL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz \
  | sudo tar -xz -C /usr/local/bin oc kubectl

# ArgoCD CLI
sudo curl -sSL -o /usr/local/bin/argocd \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd
```

### Installing AI Assistants (Optional)

```bash
# GitHub Copilot CLI (requires GitHub Copilot license)
gh auth login
gh extension install github/gh-copilot

# Claude Code (requires Anthropic API access)
# Install Node.js first if not present
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
npm install -g @anthropic-ai/claude-code
claude auth login
```

### Verify Installation

```bash
# Run the verification checks
git --version
helm version --short
yq --version
gh --version
oc version --client 2>/dev/null || echo "oc: install from your OpenShift cluster"
argocd version --client 2>/dev/null || echo "argocd: optional"

# Clone the repo and test framework scripts
git clone https://github.com/YOUR-ORG/YOUR-REPO.git
cd YOUR-REPO/argo-examples/framework

# Test the trace tool
bash scripts/trace-value.sh --help
```

### Accessing Windows Files from WSL

Your Windows drives are mounted under `/mnt/`:

```bash
# Access your Windows desktop
ls /mnt/c/Users/YourName/Desktop/

# Access a specific Windows folder
cd /mnt/c/Users/YourName/Documents/projects/
```

**Important:** Always clone the Git repo inside the WSL filesystem (e.g.
`~/repos/`) rather than on the Windows filesystem (`/mnt/c/...`). Git
operations are significantly faster on the native WSL filesystem.

### VS Code Integration

VS Code natively supports WSL. Install the
[WSL extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl),
then:

```bash
# From your WSL terminal, inside the repo:
code .
```

This opens VS Code on Windows but connected to your WSL environment. The
terminal inside VS Code is a WSL terminal with all your Linux tools available.

---

## Path 3: Git Bash (Minimal / Stopgap)

If WSL is not yet enabled and DevSpaces is unavailable, Git for Windows
includes Git Bash — a minimal Unix-like shell. Most framework operations
work here, but some scripts have limitations.

### What Works in Git Bash

| Operation | Status | Notes |
|-----------|--------|-------|
| `git` operations | Full support | Clone, commit, push, branch, PR |
| `helm lint` / `helm template` | Full support | Install Helm for Windows |
| `yq` | Full support | Install yq Windows binary |
| Framework scripts (`fleet-diff.sh`, etc.) | Mostly works | Some edge cases with `mktemp` paths |
| `oc` / `kubectl` | Full support | Install Windows binaries |
| AI tools (Copilot CLI) | Works | Via `gh` Windows install |

### Installing Tools for Git Bash

1. **Git for Windows** — [git-scm.com](https://git-scm.com/download/win)
   (includes Git Bash)
2. **Helm** — Download the Windows binary from
   [helm.sh](https://helm.sh/docs/intro/install/) and add to PATH
3. **yq** — Download `yq_windows_amd64.exe` from
   [GitHub](https://github.com/mikefarah/yq/releases), rename to `yq.exe`,
   add to PATH
4. **GitHub CLI** — Download from [cli.github.com](https://cli.github.com/)

### Limitations

- `colordiff` is not available; diffs are uncolored
- Some `mktemp` and `/tmp` path behaviors differ
- `ansible-playbook` does not work natively (use DevSpaces or WSL for
  onboarding automation)
- Process substitution (`<(command)`) may not work in older Git Bash versions

For anything beyond basic Git operations and Helm linting, use DevSpaces or
WSL.

---

## Recommended Workflow by Role

| Role | Primary Environment | Reason |
|------|-------------------|--------|
| Operator (day-to-day changes) | DevSpaces | Zero setup, AI help for YAML, browser-based |
| Platform engineer | WSL | Full Linux, offline access, complex debugging |
| On-call / emergency | DevSpaces | Accessible from any machine, instant start |
| Code review only | GitHub/GitLab web UI | No local tools needed for review + approval |

---

## Setting Up the DevSpaces Image (Platform Team)

The custom DevSpaces image is defined in `devspaces/Containerfile`. To make
it available:

### Build and Push

```bash
# Build the image
podman build -t fleet-devspaces:latest -f devspaces/Containerfile .

# Tag for your internal registry
podman tag fleet-devspaces:latest registry.example.com/platform/fleet-devspaces:latest

# Push
podman push registry.example.com/platform/fleet-devspaces:latest
```

### Update the Devfile

Edit `devspaces/devfile.yaml` and set the `image` field to your registry path:

```yaml
components:
  - name: fleet-tools
    container:
      image: registry.example.com/platform/fleet-devspaces:latest
```

### Keeping the Image Updated

When new tool versions are released or AI assistants are updated:

1. Update the `ARG` version numbers in `devspaces/Containerfile`
2. Rebuild and push the image
3. Operators get the new tools on their next workspace restart

Consider automating this with a CI pipeline that rebuilds the image weekly
or on Containerfile changes.

### AI Tool Licensing

| Tool | License Required | How to Provision |
|------|-----------------|-----------------|
| GitHub Copilot CLI | GitHub Copilot (Individual, Business, or Enterprise) | GitHub org admin enables for users |
| Claude Code | Anthropic API key or Claude Pro/Team subscription | Operator runs `claude auth login` |

Both tools authenticate interactively — no secrets are baked into the
container image. Credentials are stored in the persistent volume and survive
workspace restarts.

---

## Troubleshooting

### DevSpaces workspace fails to start

- Check that the container image is accessible from the DevSpaces cluster
- Verify the image pull secret is configured if using a private registry
- Check DevSpaces operator logs: `oc logs -n devspaces deploy/devspaces-operator`

### WSL: "This distribution has no installed packages"

Run `sudo apt update` first. If DNS resolution fails, add to `/etc/resolv.conf`:

```
nameserver 8.8.8.8
```

(Your enterprise may have specific DNS servers to use instead.)

### Git Bash: Script fails with "syntax error near unexpected token"

Some framework scripts use Bash 4+ features. Git Bash ships with Bash 4.4+
so this is rare, but if it happens, check:

```bash
bash --version
```

If below 4.0, update Git for Windows to the latest version.

### AI tools: "unauthorized" or "API key not found"

```bash
# Re-authenticate GitHub Copilot
gh auth refresh
gh copilot --help

# Re-authenticate Claude Code
claude auth login
```

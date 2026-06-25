# ArgoCD Examples

Practical examples and a production-ready framework for deploying and managing
applications on OpenShift with ArgoCD. Content ranges from standalone reference
examples to a comprehensive fleet management system.

## What Is In This Directory

This directory contains four categories of content:

| Category | Path | Purpose |
|----------|------|---------|
| [Fleet Management Framework](#fleet-management-framework) | `framework/` | Production-ready hub-and-spoke system for managing a fleet of OpenShift clusters |
| [Fleet control spectrum](../../fleet-control-spectrum.md) | `devops/` | RHACM vs Argo CD tradeoffs across multiple axes; maps to the framework posture |
| [Helm Component Pattern](#helm-component-pattern) | `helm-component-pattern/` | Reference implementation: `mustMergeOverwrite` with named component keys, multi-hub App-of-Apps-of-Apps |
| [Standalone Examples](#standalone-argocd-examples) | `apps/`, `charts/`, `examples/` | Reference ArgoCD Application and Helm chart examples |
| [CI/CD & Tooling](#cicd-workflows--tooling) | `github-workflows/`, `scripts/` | Example GitHub Actions workflows and utility scripts |

## Directory Structure

```
argo/examples/
│
├── helm-component-pattern/                # Reference: mustMergeOverwrite App-of-Apps-of-Apps
│   ├── README.md                          #   Pattern explanation, schemas, resolution walkthrough
│   ├── clusters.yaml                      #   Central cluster inventory (hub, groups, metadata)
│   ├── charts/hub-clusters/               #   Per-hub root Application generator (multi-hub filter)
│   ├── charts/hub-bootstrap/             #   Hub-level Application generator (renders to hub/rendered/)
│   ├── charts/cluster-apps/              #   Per-cluster component Application generator
│   ├── groups/                            #   Group values files (component-<groupName> keys)
│   ├── clusters/                          #   Cluster override files (component-<clusterName> keys)
│   ├── components/                        #   Example component Helm charts (nmstate, cert-manager)
│   ├── hub/                               #   Bootstrap entry points (bootstrap-root.yaml, rendered/)
│   └── .github/workflows/                #   CI: render hub-applications on clusters.yaml change
│
├── framework/                             # Fleet management framework (RHACM + ArgoCD)
│   ├── README.md                          #   Architecture, value cascade, promotion model
│   ├── GUIDELINES.md                      #   Design invariants and extension rules
│   ├── apps/                              #   Fleet app charts (cert-manager, monitoring, GPU, etc.)
│   ├── clusters/                          #   Per-cluster config (identity, values, labels)
│   ├── groups/                            #   Group value files (env, OCP version, infra)
│   ├── hub/                               #   Hub bootstrap, ApplicationSets, RHACM resources
│   ├── pipelines/                         #   CI/CD workflows (validate, promote, onboard)
│   ├── automation/                        #   Ansible playbooks for onboarding
│   ├── scripts/                           #   CLI tools (fleet-diff, trace-value, create-app)
│   ├── devspaces/                         #   DevSpaces workspace with AI tooling
│   └── docs/                              #   Operator guide, performance tuning, dev environment
│
├── apps/                                  # Standalone ArgoCD Application examples
│   ├── example-app/                       #   Simple deployment manifest
│   ├── example-single-source.yaml         #   Traditional single-source Application
│   └── example-multiple-sources.yaml      #   Multi-source Application (ArgoCD 2.6+)
│
├── charts/                                # Standalone Helm chart examples
│   ├── argocd-apps/                       #   App-of-Apps chart (root app manages child apps)
│   └── alertmanager-silences/             #   Permanent Alertmanager silences via GitOps
│
├── examples/                              # Self-contained worked examples
│   └── operators-installer/               #   Declarative OLM operator management with ArgoCD
│
├── docs/                                  # Documentation for standalone examples
│   ├── README.md                          #   Documentation index
│   ├── getting-started/                   #   Setup guide and quick reference
│   ├── patterns/                          #   App-of-Apps, multi-source patterns
│   ├── workflows/                         #   PR-based deployment, two-repo workflows
│   └── deployment/                        #   Multi-cluster deployment, ACM rename
│
├── github-workflows/                      # Example GitHub Actions workflows
│   ├── README.md                          #   Workflow documentation
│   ├── deploy-argocd-apps.yml             #   Multi-cluster deployment
│   ├── argocd-diff-preview.yml            #   PR diff preview (no cluster access)
│   └── argocd-live-diff.yml               #   Live cluster diff
│
├── scripts/                               # Utility scripts for standalone examples
│   ├── diff-app-of-apps.sh               #   Offline App-of-Apps diff tool
│   ├── test-app-of-apps.sh               #   Helm chart validation
│   └── rename-local-cluster.sh            #   ACM local-cluster rename
│
├── infrastructure/                        # Infrastructure component examples
│   └── monitoring/prometheus.yaml         #   Prometheus configuration example
│
├── root-app.yaml                          # Root ArgoCD Application (App-of-Apps entry point)
├── root-app-production.yaml               # Production variant
├── root-app-staging.yaml                  # Staging variant
└── hubs.yaml                              # Multi-cluster hub definition (for workflows)
```

---

## Fleet Management Framework

**Path:** [`framework/`](framework/)

A complete hub-and-spoke GitOps system for managing a fleet of OpenShift clusters
using ArgoCD, RHACM, and Ansible. This is not a tutorial — it is a production-ready
reference architecture.

### Key Features

- **Hub-and-spoke:** ArgoCD runs only on the RHACM hub. No GitOps on spoke clusters.
- **Cascading values:** 6-tier priority system (app defaults → all → env → OCP version → infra → cluster).
- **Git-driven labels:** Cluster group memberships and app opt-in/out are managed entirely in Git.
- **Change control:** Branch-based promotion (lab → dev → staging → production) with CI gates.
- **Automated onboarding:** GitHub Actions + Ansible pipeline for new clusters (Vault, CMDB, DNS).
- **Bare metal support:** BareMetalHost management, GPU operators, BMC credentials via Vault/ESO.
- **Developer tooling:** fleet-diff, value trace, array safety linter, app scaffolding.
- **Windows-ready:** DevSpaces workspace with AI assistants for operators on Windows.

### Getting Started

```bash
# Read the architecture overview
cat framework/README.md

# Read the design guidelines
cat framework/GUIDELINES.md

# If you are an operator new to GitOps
cat framework/docs/OPERATORS-GUIDE.md

# If you are setting up your development environment
cat framework/docs/DEVELOPER-ENVIRONMENT.md
```

### Framework Documentation

| Document | Audience |
|----------|----------|
| [framework/README.md](framework/README.md) | Architecture, directory structure, conventions |
| [framework/GUIDELINES.md](framework/GUIDELINES.md) | Design invariants, cascade contract, extension rules |
| [framework/docs/OPERATORS-GUIDE.md](framework/docs/OPERATORS-GUIDE.md) | Learning path for operators (GitOps, Git, YAML, day-to-day ops) |
| [framework/docs/DEVELOPER-ENVIRONMENT.md](framework/docs/DEVELOPER-ENVIRONMENT.md) | DevSpaces, WSL, Git Bash setup for Windows |
| [framework/docs/HUB-PERFORMANCE-TUNING.md](framework/docs/HUB-PERFORMANCE-TUNING.md) | ArgoCD scaling for large fleets |
| [framework/scripts/README.md](framework/scripts/README.md) | CLI tools: fleet-diff, trace-value, lint, scaffold |

---

## Helm Component Pattern

**Path:** [`helm-component-pattern/`](helm-component-pattern/)

A fully-working reference implementation of an App-of-Apps-of-Apps architecture using Helm
`mustMergeOverwrite` for value inheritance. Unlike the fleet framework (which uses RHACM),
this pattern requires only ArgoCD itself and works with any Argo CD version that supports
Helm chart sources.

### When to use this instead of `framework/`

| | `framework/` | `helm-component-pattern/` |
|---|---|---|
| Cluster inventory | RHACM managed clusters | `clusters.yaml` in Git |
| Group membership | RHACM labels | `groups:` field in `clusters.yaml` |
| ApplicationSet required | Yes | No (Approach A uses plain Applications) |
| RHACM required | Yes | No |
| Value priority model | 6-tier cascade | `mustMergeOverwrite` chain, depth configurable |
| Hub count | One | Multiple (each hub manages a subset of clusters) |

### Key concepts

- **`component-<name>` keys** — each group or cluster file stores its config under a namespaced key, preventing collisions when Helm merges multiple value files.
- **`mustMergeOverwrite`** — deep map merge that catches type conflicts at render time. Group defaults set `enabled: false`; group or cluster overrides selectively enable.
- **`clusters.yaml`** — central cluster inventory. Cluster identity, hub assignment, groups, and shared attributes (Vault server, monitoring endpoint) live here, not scattered across cluster files.
- **`hubConfig.groupOrder`** — explicit group load order per hub. Prevents priority from silently depending on cluster listing order in `clusters.yaml`.
- **Two bootstrap approaches** — Approach A (plain Application per cluster, rendered by CI) or Approach B (hub-clusters chart filtered by hub, managed by ArgoCD itself).

### Getting Started

```bash
# Read the full explanation
cat helm-component-pattern/README.md

# See what hub-bootstrap generates
helm template hub-bootstrap helm-component-pattern/charts/hub-bootstrap \
  --values helm-component-pattern/clusters.yaml \
  --set source.repoURL=https://github.com/your-org/gitops \
  --set source.targetRevision=main

# See what a cluster resolves to (hub-clusters, prod-a hub)
helm template hub-clusters helm-component-pattern/charts/hub-clusters \
  --values helm-component-pattern/clusters.yaml \
  --values helm-component-pattern/groups/all/values.yaml \
  --values helm-component-pattern/groups/virt-enabled/values.yaml \
  --values helm-component-pattern/clusters/site-dc1/values.yaml \
  --set currentHub=prod-a
```

---

## Standalone ArgoCD Examples

Reference examples for common ArgoCD patterns. These are independent of the
fleet framework and useful for learning ArgoCD concepts or bootstrapping
smaller deployments.

### Application Examples (`apps/`)

| File | Pattern | ArgoCD Version |
|------|---------|---------------|
| [`example-single-source.yaml`](apps/example-single-source.yaml) | Traditional single-source Application | Any |
| [`example-multiple-sources.yaml`](apps/example-multiple-sources.yaml) | Multi-source Application (chart + values separation) | 2.6+ |
| [`example-app/`](apps/example-app/) | Simple Deployment manifest used as a child app target | Any |

### Helm Charts (`charts/`)

| Chart | Purpose | Docs |
|-------|---------|------|
| [`argocd-apps`](charts/argocd-apps/) | App-of-Apps pattern: root app manages child apps via Helm values | [README](charts/argocd-apps/README.md) |
| [`alertmanager-silences`](charts/alertmanager-silences/) | Manage permanent Alertmanager silences as code | [README](charts/alertmanager-silences/README.md) |

### Worked Examples (`examples/`)

| Example | Purpose | Docs |
|---------|---------|------|
| [`operators-installer`](examples/operators-installer/) | Declarative OLM operator management with pinned CSV versions | [README](examples/operators-installer/README.md) |

### Root Applications

These demonstrate how to bootstrap the App-of-Apps pattern:

```bash
# Default root app (points to main branch)
kubectl apply -f root-app.yaml

# Environment-specific variants
kubectl apply -f root-app-production.yaml
kubectl apply -f root-app-staging.yaml
```

---

## CI/CD Workflows & Tooling

### GitHub Actions Workflows (`github-workflows/`)

Production-ready workflow examples to copy into your own repositories:

| Workflow | Purpose | Cluster Access Required |
|----------|---------|------------------------|
| [`deploy-argocd-apps.yml`](github-workflows/deploy-argocd-apps.yml) | Multi-cluster deployment with dry-run, validation, health checks | Yes |
| [`argocd-diff-preview.yml`](github-workflows/argocd-diff-preview.yml) | PR diff preview via `helm template` | No |
| [`argocd-live-diff.yml`](github-workflows/argocd-live-diff.yml) | Diff against live cluster via `argocd app diff` | Yes |

See [`github-workflows/README.md`](github-workflows/README.md) for setup
instructions and workflow diagrams.

### Utility Scripts (`scripts/`)

| Script | Purpose |
|--------|---------|
| [`diff-app-of-apps.sh`](scripts/diff-app-of-apps.sh) | Offline diff for App-of-Apps (supports multi-source) |
| [`test-app-of-apps.sh`](scripts/test-app-of-apps.sh) | Validate the argocd-apps Helm chart across all environments |
| [`test.sh`](scripts/test.sh) | Quick app discovery sanity check |
| [`rename-local-cluster.sh`](scripts/rename-local-cluster.sh) | Rename ACM `local-cluster` to a real cluster name |

```bash
# Test the App-of-Apps chart
bash scripts/test-app-of-apps.sh

# Diff App-of-Apps between branches
bash scripts/diff-app-of-apps.sh main HEAD
```

---

## Documentation (`docs/`)

The `docs/` directory covers the standalone examples (not the fleet framework,
which has its own docs under `framework/docs/`).

| Section | Contents |
|---------|----------|
| [Getting Started](docs/getting-started/) | Setup guide, quick reference |
| [Patterns](docs/patterns/) | App-of-Apps pattern, multi-source pattern |
| [Workflows](docs/workflows/) | PR-based deployment, two-repo tag workflow |
| [Deployment](docs/deployment/) | Multi-cluster deployment, ACM rename, GitHub Actions integration |
| [Validation Report](docs/VALIDATION-REPORT.md) | Pipeline validation assessment |
| [Multi-Source Changelog](docs/CHANGELOG-MULTIPLE-SOURCES.md) | Changelog for multi-source support |

See [`docs/README.md`](docs/README.md) for the full reading order.

---

## How These Pieces Relate

```
                    ┌──────────────────────────────────┐
                    │      This Directory              │
                    │      (argo/examples/)             │
                    └──────┬─────────────┬─────────────┘
                           │             │
          ┌────────────────┼─────────────┼──────────────────┐
          │                │             │                   │
 ┌────────▼───────┐ ┌──────▼──────┐ ┌───▼──────────┐ ┌─────▼──────────┐
 │  Standalone     │ │  Helm       │ │  Fleet        │ │  CI/CD          │
 │  Examples       │ │  Component  │ │  Framework    │ │  Workflows      │
 │                 │ │  Pattern    │ │               │ │                 │
 │  "I want to     │ │             │ │  "I want to   │ │  "I want GitHub │
 │   learn ArgoCD  │ │  "I want    │ │   manage 100+ │ │   Actions for   │
 │   patterns"     │ │   multi-hub │ │   clusters    │ │   ArgoCD"       │
 │                 │ │   no RHACM" │ │   with RHACM" │ │                 │
 │  apps/          │ │             │ │               │ │  github-        │
 │  charts/        │ │  helm-      │ │  framework/   │ │  workflows/     │
 │  examples/      │ │  component- │ │               │ │  scripts/       │
 │  root-app*.yaml │ │  pattern/   │ │               │ │                 │
 └─────────────────┘ └─────────────┘ └───────────────┘ └────────────────┘
```

- **Standalone examples** — reference implementations of individual ArgoCD concepts. Start here to learn the building blocks.
- **Helm component pattern** — a complete multi-hub App-of-Apps-of-Apps using `mustMergeOverwrite`. ArgoCD only, no RHACM. Start here if you want the inheritance model without a full fleet management platform.
- **The fleet framework** — opinionated, production-ready system for large fleets. Uses RHACM for cluster inventory and label-driven group membership.
- **CI/CD workflows** — portable GitHub Actions examples that work with any of the above.

---

## Related Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Helm Documentation](https://helm.sh/docs/)
- [RHACM Documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

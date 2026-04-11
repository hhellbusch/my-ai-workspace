# ArgoCD Fleet Management Framework

A hub-and-spoke GitOps framework for managing a fleet of OpenShift clusters using
ArgoCD, RHACM, and Ansible. Everything is driven from Git — group memberships,
app opt-in/out, value cascading, change promotion, and cluster onboarding.

> **AI Disclosure:** This framework was designed and implemented with AI assistance.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     RHACM Hub Cluster                        │
│                                                             │
│  ┌──────────────┐   ┌──────────────────────────────────┐   │
│  │    RHACM     │──▶│         Hub ArgoCD               │   │
│  │  (Placement  │   │  (ApplicationSets per app)       │   │
│  │   + Policy)  │   │  (cluster-label-sync chart)      │   │
│  └──────────────┘   └──────────────┬─────────────────┘   │
│                                     │                       │
└─────────────────────────────────────│───────────────────────┘
                                      │ deploys to
         ┌────────────────────────────┼──────────────────────┐
         ▼                            ▼                       ▼
┌────────────────┐  ┌────────────────────┐  ┌──────────────────┐
│  Spoke Cluster │  │   Spoke Cluster    │  │  Spoke Cluster   │
│  prod-east-1   │  │  prod-west-1       │  │  nonprod-dev-1   │
│                │  │                    │  │                  │
│  (no ArgoCD)   │  │  (no ArgoCD)       │  │  (no ArgoCD)     │
└────────────────┘  └────────────────────┘  └──────────────────┘
```

**Key principle:** ArgoCD runs only on the RHACM hub. No GitOps controller on
spoke clusters. One pane of glass per environment.

## Change Control & Promotion

Changes flow through environment stages via Git branches. Promotion is a PR merge.

```
Developer ──push──▶ main (lab) ──PR──▶ release/dev ──PR──▶ release/staging ──PR──▶ release/production
                       │                   │                    │                       │
                    CI lint              CI lint              CI lint + diff          CI lint + diff
                                                             1 approval              2 approvals
                       │                   │                    │                       │
                    Lab Hub             Dev Hub            Staging Hub            Production Hub
```

| Stage       | Git Branch            | Gate                        |
|-------------|-----------------------|-----------------------------|
| **lab**     | `main`                | CI passes                   |
| **dev**     | `release/dev`         | CI + Helm lint + dry-run    |
| **staging** | `release/staging`     | CI + approval (1 reviewer)  |
| **production** | `release/production` | CI + approval (2 reviewers) |

Each hub cluster bootstraps from the same framework pinned to its release branch
via `targetRevision`. Changes not merged to `release/production` are invisible
to production clusters.

See `pipelines/promotion/README.md` for the full procedure, emergency hotfixes,
and rollback process.

## Value Resolution (Cascading Priority)

Values are resolved from lowest to highest priority. Later sources override earlier ones.

```
Priority 1 (lowest): App chart defaults          apps/<app>/values.yaml
Priority 2:          All-clusters group           groups/all/values.yaml
Priority 3:          Environment group            groups/env-<env>/values.yaml
Priority 4:          OCP version group            groups/ocp-<version>/values.yaml
Priority 5:          Additional groups            groups/<group-name>/values.yaml
Priority 6 (highest): Cluster-specific           clusters/<cluster-name>/values.yaml
```

### Cluster Values Namespace (`cluster.*`)

Every value file shares a common `cluster` key. This makes cluster metadata
accessible to _every_ app chart without extra configuration:

```yaml
cluster:
  name: prod-east-1
  environment: production
  region: us-east
  ocp:
    version: "4.15"
    infrastructure: baremetal
  networking:
    ingressDomain: prod-east-1.example.com
  storage:
    defaultStorageClass: ocs-storagecluster-ceph-rbd
  features:
    certManager:
      enabled: true
      issuer: letsencrypt-prod
    monitoring:
      enabled: true
      retention: 30d
```

### Map Merging with `mustMergeOverwrite`

Helm natively deep-merges maps across value files. For arrays, use
`mustMergeOverwrite` inside Helm templates — see `apps/cluster-monitoring/templates/_helpers.tpl`
for the full pattern.

## Directory Structure

```
framework/
├── README.md
├── hub/
│   ├── bootstrap/
│   │   └── hub-app-of-apps.yaml          # Root ArgoCD app — bootstrap entry point
│   ├── applicationsets/
│   │   ├── per-app-template.yaml         # Reference template for per-app ApplicationSets
│   │   └── cluster-label-sync.yaml       # Hub Application for GitOps label enforcement
│   └── rhacm/
│       ├── managed-cluster-set.yaml
│       ├── placement.yaml
│       ├── gitopscluster.yaml
│       └── cluster-labels/               # Helm chart: RHACM Policies for label enforcement
│           ├── Chart.yaml
│           ├── values.yaml               # Auto-generated by aggregate-cluster-config.sh
│           └── templates/
│               └── label-policy.yaml     # One Policy per cluster
├── clusters/
│   ├── README.md
│   ├── _template/
│   │   ├── cluster.yaml                  # Cluster identity + labels (source of truth)
│   │   └── values.yaml                   # Cluster-specific value overrides
│   ├── example-prod-east-1/
│   └── example-nonprod-dev-1/
├── groups/
│   ├── README.md
│   ├── all/values.yaml
│   ├── env-production/values.yaml
│   ├── env-non-production/values.yaml
│   ├── ocp-4.14/values.yaml
│   └── ocp-4.15/values.yaml
├── apps/
│   ├── README.md
│   ├── cert-manager/                     # Example: opt-in app
│   ├── cluster-monitoring/               # Example: opt-out app (on by default)
│   └── cluster-logging/                  # Example: opt-in app
├── scripts/
│   ├── README.md                          # Documentation for all CLI tools
│   ├── fleet-diff.sh                     # Desired-state diff between Git refs
│   ├── trace-value.sh                    # Value provenance trace through cascade
│   ├── lint-array-safety.sh             # Array merge safety linter
│   └── create-app.sh                    # App scaffolding generator
├── pipelines/
│   ├── promotion/
│   │   └── README.md                     # Change control procedure documentation
│   └── github-actions/
│       ├── validate-pr.yaml              # CI: lint, template, validate, diff preview
│       ├── fleet-diff.yaml               # CI: full fleet desired-state diff
│       ├── promote.yaml                  # Manual: one-click promotion between environments
│       ├── onboard-cluster.yaml          # Manual: automated cluster onboarding workflow
│       └── aggregate-cluster-config.sh   # Script: aggregates cluster labels for label-sync
├── devspaces/
│   ├── Containerfile                     # Custom DevSpaces image with AI tools
│   └── devfile.yaml                      # DevSpaces workspace definition
├── docs/
│   ├── OPERATORS-GUIDE.md                # Learning path for operators
│   ├── DEVELOPER-ENVIRONMENT.md          # Windows setup: DevSpaces, WSL, Git Bash
│   └── HUB-PERFORMANCE-TUNING.md        # ArgoCD scaling and tuning guide
└── automation/
    ├── README.md
    └── ansible/
        ├── onboard-cluster.yaml          # Playbook: full onboarding lifecycle
        ├── inventory/
        └── roles/
            └── onboard-cluster/          # Role: Vault, CMDB, DNS, notifications
```

## Git-Driven Group Membership

Cluster labels are managed **entirely in Git** — no manual `oc label` commands.

```
Git (cluster.yaml) → aggregate script → cluster-label-sync chart →
  RHACM Policy → ManagedCluster labels → ArgoCD cluster secret →
    ApplicationSet generator selects matching clusters
```

1. Edit `clusters/<name>/cluster.yaml` → update `managedClusterLabels`
2. Run `aggregate-cluster-config.sh` (or let CI do it)
3. Commit → the label-sync chart generates RHACM Policies
4. RHACM enforces labels on the `ManagedCluster` resource
5. ArgoCD ApplicationSets react to the label changes

## Application Opt-In / Opt-Out

Each app declares its deployment model in its ApplicationSet:

| Model        | Label                         | Example App          |
|--------------|-------------------------------|----------------------|
| **Opt-in**   | `app.enabled/<app>: "true"`   | cert-manager         |
| **Opt-out**  | `app.disabled/<app>: "true"`  | cluster-monitoring   |
| **Group-scoped** | `group.<type>: <value>`  | _(any group match)_  |

Labels are defined in `cluster.yaml` and enforced via GitOps (see above).

## Cluster Onboarding

### Automated (GitHub Actions)

```
GitHub Actions → Onboard New Cluster → fill form → creates PR
```

The pipeline:
1. Generates `cluster.yaml` and `values.yaml` from template
2. Runs the Ansible onboarding playbook (Vault secrets, CMDB, notifications)
3. Aggregates cluster labels into the label-sync chart
4. Commits and opens a PR on `main`

The PR flows through the normal promotion pipeline: lab → dev → staging → production.

### Manual (CLI)

```bash
cp -r clusters/_template clusters/my-cluster
vim clusters/my-cluster/cluster.yaml    # set groups + labels
vim clusters/my-cluster/values.yaml     # set cluster overrides
ansible-playbook automation/ansible/onboard-cluster.yaml -e cluster_name=my-cluster ...
bash pipelines/github-actions/aggregate-cluster-config.sh argo-examples/framework
git add . && git commit -m "feat: onboard my-cluster" && git push
```

See `automation/README.md` for full details including Jenkins/GitLab examples.

## CI/CD Pipelines

| Workflow              | Trigger           | What It Does                                    |
|-----------------------|-------------------|-------------------------------------------------|
| **Validate PR**       | Every PR          | YAML lint, Helm lint, cluster config validation, ArgoCD diff preview |
| **Promote**           | Manual dispatch   | Creates promotion PR between environment branches |
| **Onboard Cluster**   | Manual dispatch   | Full cluster onboarding lifecycle                |

Pipelines are provided as GitHub Actions workflows in `pipelines/github-actions/`.
The Ansible playbook is CI-agnostic — see `automation/README.md` for Jenkins and
GitLab CI examples.

## Fleet Diff — Desired State Comparison

Compare the fully-rendered desired state between any two Git references:

```bash
# What changes if I promote main to production?
./scripts/fleet-diff.sh release/production main

# Diff a single app across all clusters
./scripts/fleet-diff.sh release/staging main --app cluster-monitoring

# Diff a single cluster across all apps
./scripts/fleet-diff.sh release/production main --cluster example-prod-east-1
```

The script checks out the full tree at both refs, renders every app × cluster
combination through the complete value cascade, and produces a unified diff. No
live cluster or ArgoCD instance needed. See [scripts/README.md](scripts/README.md)
for details.

A GitHub Actions workflow (`pipelines/github-actions/fleet-diff.yaml`) runs this
automatically on PRs and posts the results as a comment. It can also be triggered
manually via workflow dispatch to compare any two refs on-demand.

## Documentation

| Document                                                 | Audience              | Contents                                      |
|----------------------------------------------------------|-----------------------|-----------------------------------------------|
| This README                                              | Platform engineers    | Architecture, directory structure, conventions |
| [Guidelines](GUIDELINES.md)                              | All contributors      | Design intent, invariants, cascade contract, extension rules, pitfalls |
| [Developer Environment](docs/DEVELOPER-ENVIRONMENT.md)   | All (esp. Windows)    | DevSpaces, WSL, Git Bash setup; AI assistant configuration |
| [Operator's Guide](docs/OPERATORS-GUIDE.md)              | Operators / sysadmins | Learning path: GitOps concepts, Git basics, YAML, day-to-day procedures, troubleshooting |
| [Hub Performance Tuning](docs/HUB-PERFORMANCE-TUNING.md) | Platform engineers    | ArgoCD scaling, sharding, repo-server, Redis, monitoring |
| [Scripts & CLI Tools](scripts/README.md)                 | All                   | fleet-diff, trace-value, lint-array-safety, create-app |
| [Promotion Guide](pipelines/promotion/README.md)        | All                   | Change control procedure, hotfix/rollback      |
| [Clusters README](clusters/README.md)                   | All                   | Cluster onboarding and label schema           |
| [Groups README](groups/README.md)                        | All                   | Value cascade and group types                 |
| [Apps README](apps/README.md)                            | Platform engineers    | App chart structure and opt-in/out models     |
| [Automation README](automation/README.md)                | Platform engineers    | Ansible onboarding and CI/CD examples         |

## Prerequisites

- RHACM 2.9+
- OpenShift GitOps (ArgoCD) 1.10+ on the hub cluster
- ArgoCD 2.6+ (for multi-source Applications)
- ArgoCD 2.10+ (for `ignoreMissingValueFiles`)
- Ansible (for onboarding automation)
- yq (for cluster config aggregation)

## Conventions

- All repo URLs use `https://github.com/YOUR-ORG/YOUR-REPO.git` — replace globally
- All `targetRevision` values default to `main` — each hub overrides to its release branch
- ArgoCD namespace is `openshift-gitops` (OpenShift GitOps operator default)
- RHACM policy namespace is `open-cluster-management-global-set`

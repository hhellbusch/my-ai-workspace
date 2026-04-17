# Pipelines

CI/CD pipelines for validating, promoting, and automating fleet management tasks.

## Available Pipelines

### GitHub Actions

| Workflow                  | File                           | Trigger         | Purpose                                       |
|---------------------------|--------------------------------|-----------------|-----------------------------------------------|
| **Validate Fleet Changes**| `validate-pr.yaml`             | Every PR        | Lint, Helm template, cluster config validation |
| **Promote to Environment**| `promote.yaml`                 | Manual dispatch | One-click promotion between environment stages |
| **Onboard New Cluster**   | `onboard-cluster.yaml`         | Manual dispatch | Full cluster onboarding lifecycle              |

### Scripts

| Script                        | Purpose                                                   |
|-------------------------------|-----------------------------------------------------------|
| `aggregate-cluster-config.sh` | Aggregates cluster labels into the label-sync chart values |

## Jenkins / GitLab CI

The GitHub Actions workflows serve as reference implementations. The core
logic is portable:

- **Validation**: `helm lint`, `helm template`, `yq` validation — runs anywhere
- **Promotion**: `git` and `gh pr create` — adapts to any Git platform
- **Onboarding**: Ansible playbook — CI-agnostic, runs from any runner

See `automation/README.md` for Jenkins and GitLab CI examples.

## Pipeline Architecture

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Onboard     │    │  Validate    │    │  Promote     │    │  ArgoCD      │
│  Cluster     │───▶│  PR          │───▶│  to Env      │───▶│  Sync        │
│  (manual)    │    │  (auto)      │    │  (manual)    │    │  (auto)      │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
       │                   │                   │                   │
  Creates PR         CI validates        Merges to            Hub ArgoCD
  on main            lint + template     release branch       deploys to
                     + diff preview                           spoke clusters
```

# Git Workflows for Fleet Management

This guide compares four Git branching strategies and explains how each maps
to the ArgoCD Fleet Management Framework. It is written for operators and
platform engineers who may be new to Git-based change control.

> **AI Disclosure:** This document was created with AI assistance.

---

## Quick Summary

| Workflow | Branches | Promotion | Complexity | Best For |
|----------|----------|-----------|------------|----------|
| **Trunk-Based** | 1 (`main`) | Merge to main = deploy everywhere | Lowest | Small teams, learning GitOps |
| **GitHub Flow** | 1 + short-lived feature branches | Merge to main = deploy | Low | Teams comfortable with PRs |
| **Branch-Per-Environment** | 4 long-lived branches | PR between branches | Moderate | Regulated / large fleets |
| **GitFlow (nvie)** | 5+ long-lived branches | Merge through develop/release/main | Highest | Software product releases |

---

## 1. Trunk-Based Development

**All environments track `main`.** There is one branch. Everyone commits (or
merges PRs) to `main`, and every hub cluster syncs from `main`.

```
                    ┌─────────────┐
Developer ──PR──▶   │    main     │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
          Lab Hub      Staging Hub   Production Hub
              │            │            │
          Lab clusters  Staging      Production
                        clusters     clusters
```

### How It Works

1. Create a branch from `main` (e.g. `feat/add-silence`).
2. Make changes, push, open a PR to `main`.
3. CI validates: Helm lint, YAML lint, cluster config, fleet-diff preview.
4. Reviewer approves. Merge.
5. All hubs sync the new commit automatically.

### Safety Mechanisms

Trunk-based relies on **non-branch** safety controls:

- **RollingSync** — non-production clusters sync before production clusters
  within each hub (already built into every ApplicationSet).
- **ArgoCD Sync Windows** — restrict when production clusters can sync.
  For example, allow syncs only during maintenance windows or business hours.
- **Feature flags** — `cluster.features.<app>.enabled` lets you deploy code
  to `main` without activating it on all clusters.
- **PR review** — all changes require a PR with CI passing before merge.

### Rollback

Revert the merge commit on `main`:

```bash
git revert <merge-commit-sha>
git push origin main
```

All hubs pick up the revert on their next sync cycle.

### When to Use

- You are just starting with GitOps and want the simplest possible workflow.
- Your team is small (1-5 people).
- You are comfortable with RollingSync as your primary safety net.
- You plan to add branch-based promotion later as your fleet grows.

### Risks

- A bad merge to `main` affects all environments simultaneously (mitigated by
  RollingSync — non-prod clusters fail first, blocking production).
- No environment-level soak time unless you add sync windows or manual gates.

---

## 2. GitHub Flow

**One long-lived branch (`main`) plus short-lived feature branches.**
Conceptually identical to trunk-based for this framework, but emphasizes
stricter PR discipline.

```
  feat/add-silence ──────┐
                         ▼
  fix/cert-renewal ──▶ main ──▶ All Hubs
                         ▲
  feat/gpu-labels ───────┘
```

### How It Differs from Trunk-Based

| Aspect | Trunk-Based | GitHub Flow |
|--------|-------------|-------------|
| Direct commits to `main` | Allowed (for small fixes) | Discouraged |
| Feature branch lifetime | Hours | Hours to a few days |
| PR reviews | Recommended | Required |
| Deploy trigger | Merge to `main` | Merge to `main` |

For this framework, GitHub Flow and trunk-based produce the same ArgoCD
behavior. The difference is team process, not technical configuration.

### When to Use

- You want trunk-based simplicity but with enforced PR reviews.
- Your team is learning Git and PRs are a helpful forcing function.

---

## 3. Branch-Per-Environment (Framework Default)

**Four long-lived branches, one per environment stage.** Promotion is a PR
merge from one branch to the next. Each hub cluster pins its `targetRevision`
to its environment branch.

```
main (lab) ──PR──▶ release/dev ──PR──▶ release/staging ──PR──▶ release/production
    │                  │                     │                       │
 Lab Hub           Dev Hub             Staging Hub            Production Hub
    │                  │                     │                       │
 Lab clusters      Dev clusters        Staging clusters      Production clusters
```

### How It Works

1. Develop and test on `main`. The lab hub syncs automatically.
2. Open a PR: `main` → `release/dev`. CI validates. Merge.
3. Open a PR: `release/dev` → `release/staging`. 1 reviewer approves. Merge.
4. Open a PR: `release/staging` → `release/production`. 2 reviewers approve. Merge.

Each hub only sees changes that have been explicitly promoted to its branch.
Production never syncs a commit that hasn't been validated in staging.

### Safety Mechanisms

Everything from trunk-based, **plus:**

- **Branch isolation** — production cannot see un-promoted changes.
- **Graduated approvals** — staging requires 1 reviewer, production requires 2.
- **Soak time** — changes sit in staging for an agreed period (e.g. 1 week)
  before promotion to production.
- **Fleet-diff preview** — CI generates a rendered diff showing exactly what
  changes when a promotion PR is merged.

### Rollback

Revert the merge commit on the affected environment branch:

```bash
git checkout release/production
git revert <merge-commit-sha>
git push origin release/production
```

The production hub syncs the revert. Other environments are unaffected.

### When to Use

- You manage a large fleet (10+ clusters) across multiple environments.
- Regulatory or organizational policy requires formal promotion gates.
- Multiple teams contribute to the framework and need isolation.
- You need documented soak time between environments.

### Risks

- **Branch drift** — if branches diverge (e.g. a hotfix on production not
  cherry-picked to main), future promotions can have unexpected conflicts.
- **Merge complexity** — four branches means more PRs, more CI runs, and more
  opportunities for confusion.
- **Cherry-pick burden** — hotfixes must be cherry-picked back to `main` to
  avoid regression on the next promotion.

### Git Skills Required

Operators need to understand:
- Branches and how they relate to environments
- Creating PRs between specific branches (not just to `main`)
- Cherry-picking commits for hotfixes
- Resolving merge conflicts between branches

---

## 4. GitFlow (nvie)

**Five or more long-lived branches with specific roles.** Originally designed
by Vincent Driessen for software product releases with version numbers.

```
  feature/* ──▶ develop ──▶ release/* ──▶ main ──▶ hotfix/* ──▶ main
                                │                      │
                                └──▶ develop ◀─────────┘
```

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code with tags |
| `develop` | Integration branch for next release |
| `release/*` | Release stabilization (bug fixes only) |
| `feature/*` | New features, branched from develop |
| `hotfix/*` | Emergency fixes from main |

### Why It's Not Recommended for This Framework

GitFlow was designed for **software products** with versioned releases
(v1.2.0, v1.3.0). Infrastructure-as-code and fleet management have different
needs:

| GitFlow Assumption | Fleet Management Reality |
|--------------------|--------------------------|
| Discrete release versions | Continuous delivery; no version numbers |
| Multiple supported versions | One active state per environment |
| Feature freeze periods | Changes flow continuously |
| Release stabilization branches | Soak time in staging serves this purpose |

The branch-per-environment model used by this framework is a **simplified
adaptation** of the same idea — environment branches instead of version
branches — without the overhead of develop, feature, and release branches.

### When It Might Apply

- You are also shipping a software product (not just infrastructure) from the
  same repository.
- Organizational standards mandate GitFlow regardless of project type.

---

## Comparison Matrix

| Criterion | Trunk-Based | GitHub Flow | Branch-Per-Env | GitFlow |
|-----------|:-----------:|:-----------:|:--------------:|:-------:|
| **Git complexity** | Minimal | Low | Moderate | High |
| **Branches to manage** | 1 | 1 | 4 | 5+ |
| **Environment isolation** | None (by branch) | None (by branch) | Full | Full |
| **Promotion is explicit** | No | No | Yes | Yes |
| **Soak time enforced** | Manual | Manual | By branch gate | By branch gate |
| **Rollback scope** | All envs | All envs | Per env | Per env |
| **Hotfix complexity** | Low (revert on main) | Low | Medium (cherry-pick) | High |
| **Risk of branch drift** | None | None | Medium | High |
| **CI pipeline complexity** | Simple | Simple | Moderate | High |
| **Learning curve** | Lowest | Low | Moderate | Steep |
| **RollingSync helps** | Primary safety net | Primary safety net | Additional safety | Additional safety |
| **Sync windows needed** | Recommended | Recommended | Optional | Optional |

---

## Choosing a Workflow

### Start Here

```
Q: Is your team new to Git or GitOps?
  Yes → Start with Trunk-Based. Graduate later.
  No  ↓

Q: Do you need per-environment isolation and formal promotion gates?
  Yes → Branch-Per-Environment.
  No  ↓

Q: Do you have regulatory requirements for change control documentation?
  Yes → Branch-Per-Environment (promotion PRs serve as audit trail).
  No  → GitHub Flow (trunk-based with enforced PR reviews).
```

### Graduating from Trunk-Based to Branch-Per-Environment

See [Adopting Trunk-Based Development](ADOPTING-TRUNK-BASED.md) for the
step-by-step guide, including the graduation checklist that tells you when
it's time to add environment branches.

---

## How Each Workflow Maps to the Framework

The framework's core components — value cascade, RollingSync, label-driven
opt-in/out, cluster onboarding — are **identical** regardless of which Git
workflow you choose. The only things that change are:

| Component | Trunk-Based | Branch-Per-Environment |
|-----------|-------------|------------------------|
| `hub-app-of-apps.yaml` `targetRevision` | `main` (all hubs) | Branch per hub |
| ApplicationSet `targetRevision` | `main` (all sources) | Branch per hub |
| `promote.yaml` pipeline | Not used | Creates cross-branch PRs |
| `validate-pr.yaml` branches | `main` only | `main` + `release/*` |
| `fleet-diff.sh` typical usage | `HEAD~N..HEAD` | `release/staging..main` |
| Branch protection rules | `main` only | `main` + 3 release branches |
| Hotfix procedure | Revert on `main` | Branch from production, cherry-pick back |

---

## Further Reading

- [Adopting Trunk-Based Development](ADOPTING-TRUNK-BASED.md) — setup guide
  and graduation path
- [Promotion Guide](../pipelines/promotion/README.md) — branch-per-environment
  promotion procedure
- [Guidelines](../GUIDELINES.md) — framework invariants and conventions
- [trunkbaseddevelopment.com](https://trunkbaseddevelopment.com/) — canonical
  reference for trunk-based development
- [nvie.com/posts/a-successful-git-branching-model](https://nvie.com/posts/a-successful-git-branching-model/) —
  original GitFlow post by Vincent Driessen
- [docs.github.com/en/get-started/using-git/github-flow](https://docs.github.com/en/get-started/using-git/github-flow) —
  GitHub Flow documentation

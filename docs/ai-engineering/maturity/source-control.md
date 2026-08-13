---
review:
  status: unreviewed
  notes: "Source control deep dive — v2 axis iteration; levels reconciled with trailhead; DORA/Accelerate validation."
---

# Source Control — maturity deep dive

> **Audience:** Teams assessing collaboration, auditability, and change history — Git or equivalent, including **platform and policy** repos, not only application code.
>
> **Purpose:** Refresh the 2016 "central server" wording for distributed version control; map deck lineage to 2026 levels; link repo evidence and external research (Fowler, DORA/Accelerate).

**Related:** [Deployment & release](deployment-and-release.md) · [Trailhead](../software-systems-maturity.md#source-control) · [DORA, Accelerate, and AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md)

---

## What this axis answers

*Can we collaborate on change, know what changed when and why, and recover from mistakes — for application code, infrastructure, and fleet configuration?*

Source control is the foundation for [deployment maturity](deployment-and-release.md): without it, GitOps is impossible; with it alone, you are not yet at deployment level 3.

The 2016 deck framed this as **document control for computer code** — a subset of software configuration management (SCM). That framing still holds for **systems engineering**: cluster policy, hub config, and runbooks belong in the same audit trail as services when they drive production behavior.

---

## Levels

| Level | Posture |
|---|---|
| **0** | No VCS, or critical work outside VCS |
| **1** | Shared remote; regular commits; basic clone/pull/push |
| **2** | Branching model agreed; meaningful commit messages |
| **3** | Protected main; PR/MR review before merge |
| **4** | CI on every change; hooks (lint, test, sign) |
| **5** | History repair (`rebase -i`, revert strategy); monorepo or multi-repo governance documented |

**Distributed Git:** the 2016 deck said "central versioning server" — still true for the **shared remote**, but every clone holds full history. Level 2+ assumes team agreement on **trunk-based vs release branches**, not tool choice alone.

**DORA/Accelerate alignment:** *Accelerate* treats **version control** and **trunk-based development** as technical capabilities correlated with delivery performance (lead time, deployment frequency, change failure rate, MTTR). Those map roughly to **level 1–3+** here — DORA measures outcomes; this axis locates practice gaps. See [DORA, Accelerate, and AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md).

---

## Deck lineage (2016 → 2026)

| 2016 deck tier | 2026 level | What changed in wording |
|---|---|---|
| Not used | **0–1** | Level 0 names work outside VCS explicitly |
| Used (central server, regular commits) | **1** | "Central" → shared remote in a distributed model |
| Standardized commits; branching | **2** | Branching + messages before review gates |
| Integrated (CI/CD) | **4** | **Protected main + PR moved to 3** — CI alone without review is level 4 prep, not full integration |
| Hooks; repo surgery | **4–5** | Hooks at 4; surgery and repo governance at 5 |

The level shift at 3–4 reflects 2026 norm: **merge review before automation**, not CI as substitute for collaboration discipline.

---

## Evidence in this workspace

| Level | What it looks like | Repo paths |
|---|---|---|
| **1–2** | Mental model, basic workflow | [git-learning-guide.md](../../../devops/git/git-learning-guide.md) · [Git For Ages 4 And Up](../../../library/git-for-ages-4-and-up.md) |
| **2** | Branch naming, when to branch | [rules/branching.md](../../../rules/branching.md) |
| **2–3** | Trunk-based GitOps fleet | [ADOPTING-TRUNK-BASED.md](../../../devops/argo/examples/framework/docs/ADOPTING-TRUNK-BASED.md) |
| **3** | Protected main, PR workflow, no force-push to main | [branching.md](../../../rules/branching.md) · [PR-WORKFLOW-GUIDE.md](../../../devops/argo/examples/docs/workflows/PR-WORKFLOW-GUIDE.md) · [GUIDELINES — Git is source of truth](../../../devops/argo/examples/framework/GUIDELINES.md) |
| **3–4** | Platform/policy in Git, not just apps | [git-driven-configuration.md](../../../devops/rhacm/git-driven-configuration.md) |
| **4** | CI/hooks on change | Pre-commit in repo root · [GitHub workflows — Argo diff](../../../devops/argo/examples/github-workflows/) |
| **5** | Submodule governance, merge discipline, history safety | [branching.md — merge/force-push](../../../rules/branching.md) · [submodule-workflow.md](../../../rules/submodule-workflow.md) |

---

## Fleet, platform, and systems engineering

Source control maturity is not only **application repos**:

| Scope | Example in this corpus |
|---|---|
| Workload manifests | Argo CD app-of-apps; child apps may pin tags/branches per env — [APP-OF-APPS-PATTERN.md](../../../devops/argo/examples/docs/patterns/APP-OF-APPS-PATTERN.md) |
| Hub and policy | RHACM placements, policies, integrations in Git — [git-driven-configuration.md](../../../devops/rhacm/git-driven-configuration.md) |
| Fleet truth | Imperative cluster edits overwritten by reconcile = **source control + deployment** failure — [GUIDELINES](../../../devops/argo/examples/framework/GUIDELINES.md) |

**Systems vs software:** software teams often mature app repos first while platform config stays tribal knowledge. Fleet GitOps forces both into the same discipline — or exposes the gap.

---

## AI era

AI coding agents increase **commit volume and branch churn** without automatically improving **review, merge policy, or history hygiene**.

| Risk | Mitigation (source-control axis) |
|---|---|
| Large unreviewed diffs merged to main | Protected main; PR/MR required (L3) |
| Agents work on wrong branch / lost context | Documented branch naming; truth anchor in [AGENTS.md](../../../AGENTS.md) |
| Force-push or rewritten main breaks sessions | [branching.md — never force-push main](../../../rules/branching.md) |
| Generated secrets in commits | Rotation + history repair — ties to [Security & secrets](security-and-secrets.md) |

DORA metrics may **improve or degrade** in the AI era depending on whether automation speeds up the whole delivery system or only the typing step. Source control and review gates are where "faster generation" meets "same merge bar." See [research note — DORA and AI](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md).

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| Long-lived branches diverging for months | Merge pain; lost review signal — conflicts with trunk-based delivery research |
| "Fix" commits without context | Audit and bisect break |
| Secrets committed once "because emergency" | History forever — use rotation + `git filter-repo` |
| Fork without upstream sync discipline | Drift from fleet truth |
| CI green but no human/agent review on intent | Level 4 automation without level 3 collaboration |

---

## Cross-axis dependencies

```text
Source control ──prerequisite──▶ Deployment (GitOps, reconcile)
              ──feeds────────▶ Builds (CI on every change)
              ──risk─────────▶ Security (secrets in history)
              ──enables──────▶ Documentation (ADRs, handoffs in git)
              ──enables──────▶ AI agents (commits as truth anchor)
```

---

## Teaching note — from 2016 deck

*"We've got all of this code, all over the place. How do we keep it from going horribly wrong?"*

Tools evolved (CVS → SVN → Git). The question did not. Maturity is agreement on **how change enters shared history**, not which GUI client you use.

---

## Research and external validation

| Source | What it supports | Limit |
|---|---|---|
| [Fowler — branching patterns](https://martinfowler.com/articles/branching-patterns.html) | Trunk-based, feature branches, release branches — level 2–3 choices | Patterns, not scores |
| [Trunk Based Development](https://trunkbaseddevelopment.com/) | Short-lived branches, main as integration | Fleet GitOps companion to argo trunk doc |
| *Accelerate* (Forsgren, Humble, Kim) | Version control + trunk-based dev among capabilities tied to performance | Organizational study; not AI-specific |
| [DORA research program](https://dora.dev/) | Four keys metrics; continuous improvement of delivery | Measures outcomes; doesn't replace per-axis assessment |
| [Git For Ages 4 And Up](../../../library/git-for-ages-4-and-up.md) | L1–2 mental model pedagogy | 2013 talk; mechanics unchanged |

**Not in library yet:** enriched *Accelerate* entry — catalog stub only ([library/catalog.md](../../../library/catalog.md)).

---

## Repo examples (index)

| Topic | Path |
|---|---|
| Git mental model | [git-learning-guide.md](../../../devops/git/git-learning-guide.md) |
| Trunk-based adoption | [ADOPTING-TRUNK-BASED.md](../../../devops/argo/examples/framework/docs/ADOPTING-TRUNK-BASED.md) |
| PR workflow | [PR-WORKFLOW-GUIDE.md](../../../devops/argo/examples/docs/workflows/PR-WORKFLOW-GUIDE.md) |
| Workspace branch policy | [rules/branching.md](../../../rules/branching.md) |
| RHACM config in Git | [git-driven-configuration.md](../../../devops/rhacm/git-driven-configuration.md) |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

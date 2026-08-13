---
review:
  status: unreviewed
  notes: "Source control deep dive — distributed VCS levels, trunk/branch practices."
---

# Source Control — maturity deep dive

> **Audience:** Teams assessing collaboration, auditability, and change history — Git or equivalent.
>
> **Purpose:** Refresh the 2016 "central server" wording for distributed version control. Link to [devops/git/](../../../devops/git/git-learning-guide.md).

**Related:** [Deployment & release](deployment-and-release.md) · [Trailhead](../software-systems-maturity.md#source-control)

---

## What this axis answers

*Can we collaborate on code, know what changed, when, and why — and recover from mistakes?*

Source control is the foundation for [deployment maturity](deployment-and-release.md): without it, GitOps is impossible; with it alone, you are not yet at deployment level 3.

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

**2016 deck said "central versioning server"** — still true for **shared remote**, but Git is **distributed**: every clone is a full history. Level 2+ assumes team agreement on **trunk-based vs release branches**, not tool choice.

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| Long-lived branches diverging for months | Merge pain; lost review signal |
| "Fix" commits without context | Audit and bisect break |
| Secrets committed once "because emergency" | History forever — use rotation + `git filter-repo` |
| Fork without upstream sync discipline | Drift from fleet truth |

**Fleet lens:** [Argo framework GUIDELINES — Git is the only source of truth](../../../devops/argo/examples/framework/GUIDELINES.md#12-git-is-the-only-source-of-truth) — imperative hotfixes overwritten by reconcile are a **deployment + source control** failure mode.

---

## Repo examples

| Topic | Path |
|---|---|
| Git mental model | [git-learning-guide.md](../../../devops/git/git-learning-guide.md) |
| Trunk-based adoption | [ADOPTING-TRUNK-BASED.md](../../../devops/argo/examples/framework/docs/ADOPTING-TRUNK-BASED.md) |
| PR workflow | [PR-WORKFLOW-GUIDE.md](../../../devops/argo/examples/docs/workflows/PR-WORKFLOW-GUIDE.md) |

---

## External references

- [Martin Fowler — Patterns for Managing Source Code Branches](https://martinfowler.com/articles/branching-patterns.html)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

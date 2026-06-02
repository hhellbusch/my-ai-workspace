# Git and GitHub Learning Path

**Audience:** Infrastructure and platform engineers who have not used source control day to day — or who use it occasionally but have not internalized *why* the model works the way it does.

**Outcomes:** Understand how Git stores history (the inside-out mental model); use the daily workflow (clone → branch → commit → push → PR → merge) without looking up commands; reason about `git log`, `git diff`, and `git revert`; operate comfortably in a GitHub-centric organization with branch protection, CODEOWNERS, and SSO/SAML; explain how Git and pull requests replace (and improve on) a traditional CAB/change-ticket process.

**Prerequisite:** None. A basic comfort with the command line helps for Stage 2 onward.

---

## Why Git first — not just "how to Git"

Most Git tutorials start with commands. This path starts with the *model*, because the commands make no sense without it. Git's design is unusual — it stores snapshots, not diffs; commits are immutable content-addressed objects; branches are labels, not containers. Every confusing moment in Git (detached HEAD, merge vs rebase, "why did my push get rejected?") is a model mismatch, not a command lookup problem.

The Schwern talk in Stage 0 teaches the model first. Do it before anything else.

---

## Why Git matters for infrastructure engineers

Git and GitOps are not just a new tool for doing what you already do. They are a different accountability and change management model.

**Infrastructure as Code** means infrastructure is defined in text files, stored in Git, reviewed before applying, and applied automatically when approved.

| Principle | What it replaces or improves |
|-----------|------------------------------|
| **Version control** | "Who changed this and when?" is answered by `git log`, not by asking around or trawling change tickets. |
| **Auditability** | Every change has an author, a timestamp, a diff, a PR discussion, and an approver. This is your audit trail. |
| **Accountability** | A merge commit to the production branch is a named, timestamped, peer-reviewed action. Drift from that state is detectable. |
| **Consistency** | The same manifest applied to dev, staging, and prod produces the same result. Snowflake configs are a Git diff, not a mystery. |
| **Speed and efficiency** | Approved changes apply automatically. No maintenance window required for config changes the team has already reviewed. |
| **Security and compliance** | Branch protection, required reviewers, CODEOWNERS, and signed commits are enforceable controls — comparable to CAB gates but with a full diff attached. |
| **Scalability** | One repo can drive hundreds of clusters. ClickOps does not scale. |
| **Declarative by nature** | You describe the desired state; the system reconciles. Stop writing runbooks for "how to apply this," start writing manifests for "what this should be." |

### Git replaces (and improves on) your change management process

| Your current process | Git / GitHub equivalent |
|----------------------|-------------------------|
| Change ticket describing the change | **Pull request** — the change *is* the diff; the description is the PR body |
| CAB review / approval | **PR review** — named approvers, required reviewers enforced by branch protection |
| Approval record | **Merge commit** — named, timestamped, traceable to the PR and the approvers |
| Maintenance window | Not required for config-only changes managed by GitOps (still applies to changes that cause rolling restarts, storage migrations, or network disruptions) |
| "Who changed this?" investigation | `git log`, `git blame`, PR history |
| Emergency change / break-glass | Emergency PR with post-hoc review; audit trail preserved |
| Rollback | `git revert` creates a new commit undoing the change — history of both the change and the rollback is preserved |

Git does not eliminate governance. It makes governance faster, more traceable, and automatable at the enforcement layer rather than the process layer.

---

## Stage 0 — Mental model first (free, ~2 hours)

**Do this before anything else.**

**[Git For Ages 4 And Up — Michael Schwern (linux.conf.au 2013)](https://www.youtube.com/watch?v=1ffBJ4sVUb4)** (~1h 40m)

A standout introduction to *how Git actually works*. Schwern teaches the inside-out mental model — objects → commits → labels → staging area → remotes — using physical props on a table. He does not say "Git is like Subversion but better." He says throw out what you know and build the model from scratch.

After this talk, "detached HEAD," merge vs rebase, and `git reset` all become logical consequences of the model rather than mysterious commands. Library entry: [`library/git-for-ages-4-and-up.md`](../../../library/git-for-ages-4-and-up.md).

**Verification:** After watching, draw (on paper or a whiteboard) the relationship between: a blob, a tree, a commit object, a branch label, HEAD, and a remote ref. You should be able to explain what `git commit` physically does to those objects.

---

## Stage 1 — Hands-on basics (free, 2–4 hours)

Work through these in order. They are short, interactive, and build on each other.

### GitHub Skills (free, in-browser, ~1–2 hours)

Run entirely inside GitHub repos using GitHub Actions to automate feedback. No setup required beyond a GitHub account.

| Course | What it covers | Link |
|--------|---------------|-------|
| **Introduction to Git** | Commits, branches, history, basic collaboration | [skills.github.com](https://skills.github.com/) → "Introduction to Git" |
| **Introduction to GitHub** | Repositories, pull requests, issues, GitHub flow | [skills.github.com](https://skills.github.com/) → "Introduction to GitHub" |

### Microsoft Learn (free, structured modules, ~1–2 hours)

| Module / Path | Level | Length | Link |
|---------------|-------|--------|-------|
| Introduction to Git | Beginner | ~1h 26m | [Microsoft Learn](https://learn.microsoft.com/en-us/training/modules/intro-to-git/) |
| Collaborate with Git | Beginner | 44 min | [Microsoft Learn](https://learn.microsoft.com/en-us/training/modules/collaborate-with-git/) |
| Introduction to GitHub | Beginner | Short | [Microsoft Learn](https://learn.microsoft.com/en-us/training/modules/introduction-to-github/) |

All include exercises and knowledge checks. Free with a Microsoft account.

**Verification:** Clone a public repo or a disposable template, create a branch, edit one line, commit, push, and open a PR. Write the PR description as if it were a change ticket: what changed, why, what the risk is, how to verify.

---

## Stage 2 — Internals and interactive practice (free)

| Resource | What it covers | Notes |
|----------|---------------|-------|
| **[learngitbranching.js.org](https://learngitbranching.js.org/)** | Branching, merging, rebasing, cherry-pick — visually | Best interactive branching visualizer available. Run it in-browser, no install. Start with "Introduction Sequence." |
| **[Pro Git book](https://git-scm.com/book/en/v2)** (online, free) | Everything from basics to internals | Chapters 1–3 for fundamentals; Chapter 10 ("Git Internals") for the object model after the Schwern talk. Deeper chapters for merge strategies, rerere, submodules when you hit those problems. |

**Verification:** Complete at least the "Introduction Sequence" and "Ramping Up" sections of learngitbranching. Explain, without looking it up, what `git rebase main` does to your feature branch compared to `git merge main`.

---

## Mechanics checklist

Work through this checklist as you progress through Stages 1–2. Everything here will come up in day-to-day GitOps work.

| Topic | Why it matters |
|-------|---------------|
| Install Git locally; set `user.name` / `user.email` | Every commit is attributed; matches org policy and audit requirements. |
| **Clone**, **remote**, **fetch** vs **pull** | Argo CD and GitOps tooling read from remotes; you need a reproducible local copy. |
| **Branch**, **commit**, **push** | Typical flow: feature branch → PR → merge to `main` or an environment branch. |
| **Pull request** lifecycle | Where review and approval happen before any automation syncs config to the cluster. |
| **Diff** (`git diff`, IDE diff view) | You will compare YAML changes to cluster behavior constantly. |
| `git log` / `git log --oneline --graph` | How you answer "what changed and when?" |
| `git stash` | Shelve work-in-progress when you need to switch branches. |
| `git revert` vs `git reset` | `revert` is safe in shared branches (adds a new commit). `reset` rewrites history — use only on local or unshared branches. |
| Org basics: **permissions**, **CODEOWNERS**, **branch protection** | You may not be able to push directly to `main` — that is correct and intentional. |
| Optional: **GitHub CLI** (`gh`) | Open PRs and check CI status from the terminal — useful when you live in `oc` or `kubectl` shells. |

---

## Enterprise GitHub notes

If your organization uses SSO or SAML with GitHub Enterprise:

- Complete IT's device and token onboarding *before* trying to push — personal access tokens often require SSO authorization once before they work with org repos.
- Fine-grained personal access tokens are the recommended auth method for scripting and automation (avoid classic tokens scoped to "repo" where possible).
- If you are cloning internal repos from a CI/CD context (Argo CD, GitHub Actions, Tekton), use a deploy key or a service account token, not a personal token.

---

## Verification (scenario-based)

These are the checks that confirm you are ready to move into GitOps workflows:

1. **Clone → branch → edit → push → PR:** Clone a team repo (or a disposable public template), create a branch, edit one file, commit with a descriptive message, push, and open a PR. Write the PR description as if it were a change ticket: what changed, why, what the risk is, how to verify.

2. **Explain the model:** Without notes — what is the difference between `git commit` (local history) and `git push` (publish to remote)? What is the difference between `git pull` on your laptop and merging a PR on GitHub (review gates, approval record, audit trail)?

3. **Read history:** Given a repo's `git log`, answer: who changed `deployment.yaml` two weeks ago, what did they change, and was it reviewed?

4. **Recover from a mistake:** Make a bad commit on a feature branch. Use `git revert` to undo it. Explain why you did not use `git reset` on a branch that others might have pulled.

---

## Where to go next

- If you arrived here from the **VMware admins → Kubernetes / OpenShift path**: return to [that path](../vmware-admins/README.md) and pick up from Phase 1. Git will come up constantly in the lab exercises.
- **GitOps concepts** (Argo CD, desired state, sync loops, ApplicationSets): Phase 4 of the VMware admins path covers these in depth once you are comfortable with Git mechanics.

---

*AI-assisted content. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for review status details.*

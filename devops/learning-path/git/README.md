# Git, GitHub, and GitLab Learning Path

**Audience:** Anyone learning Git for the first time — whether you're a developer, a writer, a researcher, or an infrastructure engineer. If you've used Git but not internalized *why* the model works the way it does, this path is for you.

**Outcomes:** Understand how Git stores history (the inside-out mental model); use the daily workflow (clone → branch → commit → push → merge request/PR → merge) without looking up commands; reason about `git log`, `git diff`, and `git revert`; operate comfortably in both GitHub and GitLab with branch protection, CODEOWNERS, and SSO/SAML; explain how Git and merge requests create accountability and review that goes beyond ad-hoc file sharing.

**Prerequisite:** None. A basic comfort with the command line helps for Stage 2 onward.

---

## Why Git first — not just "how to Git"

Most Git tutorials start with commands. This path starts with the *model*, because the commands make no sense without it. Git's design is unusual — it stores snapshots, not diffs; commits are immutable content-addressed objects; branches are labels, not containers. Every confusing moment in Git (detached HEAD, merge vs rebase, "why did my push get rejected?") is a model mismatch, not a command lookup problem.

The Schwern talk in Stage 0 teaches the model first. Do it before anything else.

---

## Git vs Git hosting platforms

Before you start, it's important to understand what Git is — and what it isn't. Git and GitHub (or GitLab) are not the same thing.

**Git** is a decentralized version control system. It was created by Linus Torvalds in 2005 to manage the Linux kernel source code. Git stores snapshots of files as content-addressed objects (blobs, trees, commits), and every developer has a complete copy of the repository history on their machine. The mental model from the Schwern talk — objects, commits, labels, staging area, remotes — applies to *every* Git installation on earth, whether it lives on your laptop, a shared server, or across a network.

**GitHub** and **GitLab** are hosting services that sit on top of Git. They add collaborative features: web interfaces for browsing code, pull requests and merge requests, issue tracking, code review tools, CI/CD pipelines, wikis, and project management. GitHub also provides GitHub Actions for continuous integration and deployment. GitLab has GitLab CI built in. These features are *on top of* Git, not part of Git itself.

The key insight: **you can use Git without GitHub or GitLab.** You can host a bare Git repository on your own server and use SSH to push and fetch. You can share a repository over a USB drive. Git works everywhere it's installed. GitHub and GitLab are simply the most common places organizations host their Git repos because they provide the collaborative tooling that teams need.

**Git is the same everywhere.** The commands are identical, the mental model is identical, and the history you create is identical — whether you push to GitHub, GitLab, Bitbucket, or a server in your closet. The collaborative workflow layer (PRs, merge requests, CI, issue tracking) is what changes from platform to platform.

### GitHub vs GitLab — the main differences

Both platforms provide similar core features, but they use different terminology and have different strengths. Learning one platform transfers to the other — the concepts are the same, only the names and UI differ.

| GitHub | GitLab | What it means |
|--------|--------|---------------|
| Pull Request (PR) | Merge Request (MR) | Same concept: a proposed change that is reviewed before merging |
| GitHub Actions | GitLab CI | Both provide CI/CD; GitLab's is built-in, GitHub's is opt-in |
| Repository | Project | Same concept; "project" in GitLab also refers to a meta-organization feature |
| Organizations | Groups | Both provide team/organization management |
| GitHub CLI (`gh`) | GitLab CLI (`glab`) | Terminal tools for both platforms — `gh` is more widely used |
| Marketplace | GitLab Marketplace | Third-party integrations and extensions |
| `git push origin main` | `git push origin main` | Git itself doesn't care which hosting platform you use |

**The core workflow is identical on both platforms:**

```
git clone <repo-url>        → Clone the repository
git checkout -b feature     → Create and switch to a new branch
git add <files>             → Stage changes
git commit -m "message"     → Commit staged changes
git push -u origin feature  → Push your branch to the remote
git push --set-upstream origin feature  → Set the upstream once, then just `git push`
```

On GitHub, after pushing, you create a **pull request**. On GitLab, you create a **merge request**. Both create a review page where collaborators can comment, request changes, and approve before the changes are merged into the target branch.

**Which platform to use?** If your organization uses GitHub, start there. If it uses GitLab, start there. The mental model from this path is identical on both platforms. When you learn Git, you learn it once — the platform-specific features (PR vs MR, Actions vs CI, Marketplace vs Marketplace) you'll pick up as you use them day to day.

---

### Git as the tool for change management

Git itself doesn't create governance — the workflows built on top of it do. The table below maps traditional change management to the Git/GitHub or GitLab workflow. Git is the system that records, enforces, and makes that workflow traceable.

| Your current process | Git / Git hosting platform workflow equivalent |
|----------------------|---------------------------------------------|
| Change ticket describing the change | **Pull request / merge request** — the change *is* the diff; the description is the PR/MR body |
| Peer review / approval | **PR/MR review** — named approvers, required reviewers enforced by branch protection |
| Approval record | **Merge commit** — named, timestamped, traceable to the PR/MR and the approvers |
| Manual update process | Not required when changes flow through a pipeline (still applies to changes that affect other systems) |
| "Who changed this?" investigation | `git log`, `git blame`, PR history |
| Emergency change / break-glass | Emergency PR with post-hoc review; audit trail preserved |
| Rollback | `git revert` creates a new commit undoing the change — history of both the change and the rollback is preserved |

*For infrastructure and platform teams:* when Git stores configuration files, this model extends into **GitOps** — infrastructure as code, where the same PR/review/merge pattern controls cluster state, deployment pipelines, and automation rules. See the **VMware admins → Kubernetes / OpenShift path** for how Git drives platform operations.

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

### GitLab for Beginners (free, in-browser, ~1–2 hours)

GitLab's official interactive course walks through the same Git fundamentals in the GitLab interface. Run in any GitLab project — no paid plan required. Use this if your organization uses GitLab, or run both to see the platform differences.

| Course | What it covers | Link |
|--------|---------------|-------|
| **GitLab for Beginners** | Cloning repos, creating branches, committing changes, merging, pull requests | [about.gitlab.com/learn/gitlab-for-beginners](https://about.gitlab.com/learn/gitlab-for-beginners/) |

### Microsoft Learn (free, structured modules, ~1–2 hours)

| Module / Path | Level | Length | Link |
|---------------|-------|--------|-------|
| Introduction to Git | Beginner | ~1h 26m | [Microsoft Learn](https://learn.microsoft.com/en-us/training/modules/intro-to-git/) |
| Collaborate with Git | Beginner | 44 min | [Microsoft Learn](https://learn.microsoft.com/en-us/training/modules/collaborate-with-git/) |
| Introduction to GitHub | Beginner | Short | [Microsoft Learn](https://learn.microsoft.com/en-us/training/modules/introduction-to-github/) |

All include exercises and knowledge checks. Free with a Microsoft account.

**Verification:** Clone a public repo or a disposable template, create a branch, edit one line, commit, push, and open a PR or merge request. Write the description as if it were a change ticket: what changed, why, what the risk is, how to verify.

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
| **Pull request / merge request** lifecycle | Where review and approval happen before any automation syncs config to the cluster. |
| **Diff** (`git diff`, IDE diff view) | You will compare YAML changes to cluster behavior constantly. |
| `git log` / `git log --oneline --graph` | How you answer "what changed and when?" |
| `git stash` | Shelve work-in-progress when you need to switch branches. |
| `git revert` vs `git reset` | `revert` is safe in shared branches (adds a new commit). `reset` rewrites history — use only on local or unshared branches. |
| Org basics: **permissions**, **CODEOWNERS**, **branch protection** | You may not be able to push directly to `main` — that is correct and intentional. |
| Optional: **GitHub CLI** (`gh`) or **GitLab CLI** (`glab`) | Open PRs/merge requests and check CI status from the terminal — useful when you live in `oc` or `kubectl` shells. |

---

## Enterprise hosting notes

Both GitHub Enterprise and GitLab Enterprise support SSO/SAML, fine-grained access control, and audit logs. The principles below apply to either platform.

- Complete IT's device and token onboarding *before* trying to push — personal access tokens often require SSO authorization once before they work with org repos.
- Fine-grained personal access tokens are the recommended auth method for scripting and automation (avoid classic tokens scoped to "repo" where possible).
- If you are cloning internal repos from a CI/CD context (Argo CD, GitHub Actions, GitLab CI, Tekton), use a deploy key or a service account token, not a personal token.

---

## Verification (scenario-based)

These are the checks that confirm you are ready to move into GitOps workflows:

1. **Clone → branch → edit → push → PR:** Clone a team repo (or a disposable public template), create a branch, edit one file, commit with a descriptive message, push, and open a PR. Write the PR description as if it were a change ticket: what changed, why, what the risk is, how to verify.

2. **Explain the model:** Without notes — what is the difference between `git commit` (local history) and `git push` (publish to remote)? What is the difference between `git pull` on your laptop and merging a PR or MR on the host platform (review gates, approval record, audit trail)?

3. **Read history:** Given a repo's `git log`, answer: who changed `deployment.yaml` two weeks ago, what did they change, and was it reviewed?

4. **Recover from a mistake:** Make a bad commit on a feature branch. Use `git revert` to undo it. Explain why you did not use `git reset` on a branch that others might have pulled.

---

## Where to go next

- If you arrived here from the **VMware admins → Kubernetes / OpenShift path**: return to [that path](../vmware-admins/README.md) and pick up from Phase 1. Git will come up constantly in the lab exercises.
- **GitOps concepts** (Argo CD, desired state, sync loops, ApplicationSets): Phase 4 of the VMware admins path covers these in depth once you are comfortable with Git mechanics.

---

*AI-assisted content. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for review status details.*

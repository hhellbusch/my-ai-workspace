---
description: Use git worktrees to isolate parallel agent tasks — each agent or long-running task gets its own working directory and branch
globs:
alwaysApply: true
---

# Git worktrees for parallel agent work

When multiple agents (or an agent and a human session) are working on the same repo simultaneously, each must have its own git worktree. A shared working tree means competing staging areas, dirty-state collisions, and work landing on the wrong branch.

## When to create a worktree

- Starting a new paude/agent task while another is already running
- Any long-running background task that will make commits
- Parallel research or implementation work that should stay branch-isolated until merged

## Convention

Worktrees live **inside** the main workspace under `worktrees/`:

```
~/gemini-workspace/                        ← main worktree (main branch)
~/gemini-workspace/worktrees/{slug}/       ← agent task worktree
```

`worktrees/` is gitignored — git tracks the branch, not the working directory on disk.

**Slug** = short kebab-case description of the task (e.g. `paude-async-delegation`, `obs-guide`, `ocp-storage-fix`). The branch name matches the slug.

## Creating a worktree

```bash
# New branch (most common — new task)
git -C ~/gemini-workspace worktree add worktrees/{slug} -b {slug}

# Existing branch (resuming or handing off)
git -C ~/gemini-workspace worktree add worktrees/{slug} {branch-name}
```

The agent or task then runs inside `~/gemini-workspace/worktrees/{slug}/`. It has its own index and staging area. Both share the same `.git` object store — no repo duplication.

## Listing and removing

```bash
# See all active worktrees (run from anywhere inside the repo)
git worktree list

# Remove after branch is merged
git worktree remove ~/gemini-workspace/worktrees/{slug}
git branch -d {slug}
```

## Handing a worktree to an agent (paude pattern)

`cd` into the worktree before running `paude create` — it infers the workspace from `cwd`. The agent commits to its isolated branch; harvest the diff and open a PR to main when done.

```bash
git -C ~/gemini-workspace worktree add worktrees/{slug} -b {slug}
cd ~/gemini-workspace/worktrees/{slug}
paude create {slug} --git --yolo --prompt-file ~/gemini-workspace/.planning/.../spec.md
```

> `--git` is a boolean flag, not a path. The workspace is always the current directory.
> Use absolute paths for `--prompt-file` — the cwd changes per worktree.

## Rules

- Never run two agents against the same worktree simultaneously
- Keep worktree slug and branch name identical — reduces confusion
- Remove worktrees promptly after merge — stale worktrees lock the branch
- The main workspace (`~/gemini-workspace`) stays on `main` or a stable base; task branches live in sibling worktrees

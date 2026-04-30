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

Worktrees live as siblings of the main workspace:

```
~/gemini-workspace/           ← main worktree (main branch or current base)
~/gemini-workspace-{slug}/    ← agent task worktree
```

**Slug** = short kebab-case description of the task (e.g. `paude-async-delegation`, `library-additions`, `ocp-troubleshooting-update`).

## Creating a worktree

```bash
# New branch (most common — new task)
git worktree add ~/gemini-workspace-{slug} -b {slug}

# Existing branch (resuming or handing off)
git worktree add ~/gemini-workspace-{slug} {branch-name}
```

The agent or task then runs inside `~/gemini-workspace-{slug}/`. It has its own index and staging area. Both share the same `.git` object store — no repo duplication.

## Listing and removing

```bash
# See all active worktrees
git worktree list

# Remove after branch is merged
git worktree remove ~/gemini-workspace-{slug}
git branch -d {slug}
```

## Handing a worktree to an agent (paude pattern)

For paude tasks, point `--git` at the worktree directory rather than the main workspace. The agent commits to its branch; you harvest the diff and open a PR to main.

```bash
git worktree add ~/gemini-workspace-{task-slug} -b {task-slug}
paude create --git ~/gemini-workspace-{task-slug} --yolo --prompt-file task.md
```

## Rules

- Never run two agents against the same worktree simultaneously
- Keep worktree slug and branch name identical — reduces confusion
- Remove worktrees promptly after merge — stale worktrees lock the branch
- The main workspace (`~/gemini-workspace`) stays on `main` or a stable base; task branches live in sibling worktrees

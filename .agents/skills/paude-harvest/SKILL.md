---
name: paude-harvest
description: Harvest and locally merge changes from a paude container session. Use when
  pulling agent work from paude, running paude harvest, merging session commits,
  importing submodule changes from a container, or fixing failed harvest/submodule fetch.
argument-hint: "<session-name> [--slug <task-slug>] [--merge | --no-merge]"
allowed-tools: Read Write Shell Glob Grep StrReplace
---

# Paude Harvest

<objective>
Pull committed work from a running paude session into the host repo and merge locally — including submodule SHAs that exist only in the container.
</objective>

<essential_principles>

- Uncommitted container work is invisible to harvest — triage first if diff is empty.
- `paude harvest` often fails on submodule fetch; the fallback path is normal, not exceptional.
- Never `git submodule update --remote` — it discards harvested work.
- Verify every commit with `git show` / `git diff` — container handoffs can be wrong.
- Host `main` must be fetched/pulled before harvest to avoid stale-base merges.

</essential_principles>

<context>
- Narrative guide: `docs/ai-engineering/paude-getting-started.md`
- Spec: `.planning/paude-skills/SKILLS-SPEC.md`
- Worktrees: `rules/git-worktrees.md`
- Submodule init: `rules/submodule-workflow.md`
</context>

<intake>
What do you want to do?

1. **Harvest** — pull session into a branch (default)
2. **Merge locally** — merge an existing harvest branch into main + submodules
3. **Diagnose** — harvest failed or empty diff

Parse `$ARGUMENTS` for intent. If `--merge` or user said "merge locally", run harvest then merge. If `--no-merge`, harvest only.

**Session name is required** — from `$ARGUMENTS` or ask after `paude list`.
</intake>

<routing>
| Intent | Workflow |
|--------|----------|
| Harvest (default) | `workflows/harvest.md` |
| Merge locally / `--merge` | `workflows/harvest.md` then `workflows/merge-locally.md` |
| Merge only (branch already exists) | `workflows/merge-locally.md` |
| Failed harvest / empty diff | Read `references/failure-modes.md`, then `workflows/harvest.md` |

Read referenced workflow files and follow exactly.
</routing>

<success_criteria>
- Harvest branch exists with verified commits
- Submodule changes merged on correct default branches
- Host main pointers updated without reverting unrelated work
- User told what was merged and what remains unpushed
</success_criteria>

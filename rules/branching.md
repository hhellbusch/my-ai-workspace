# Branching Strategy — Stable Main, Branched Work

`main` is the checkpointed, stable line of work in this repository.

Default posture: new work starts on a branch, lands in `main` only after review.

## Branch naming

- `feature/<topic>` — new capabilities, skills, rules, structural changes
- `experiment/<topic>` — uncertain tries, Paude output evaluation, research spikes
- `docs/<topic>` — essay/doc drafting (default for content drafts)
- `fix/<topic>` — targeted corrections

Use short kebab-case slugs.

## What should branch

- Any multi-commit change
- New or modified rules/skills/automation
- Work in `submodules/`
- Planning or structure changes (new directories, moves, renames)
- Essay/doc drafts until author review is complete
- Agent work (Paude harvest branches already follow this naturally)

## What may go direct to `main`

- Routine backlog bookkeeping (`backlog:` commits)
- Lightweight checkpoint/handoff updates
- Tiny typo/link corrections in otherwise complete work

If uncertain, branch.

## Merge discipline

- Prefer `git merge --no-ff` to preserve branch boundaries in history
- Run the appropriate `/review` depth before merging
- Avoid merging half-finished experimental branches just to checkpoint; keep them open or park with a clear branch name

## Worktrees and branches

This rule complements `git-worktrees.md`:
- Worktrees isolate concurrent tasks
- Branches isolate units of change

Parallel agent sessions should use both: one worktree per task and one task branch per worktree.

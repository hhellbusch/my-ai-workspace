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

## Force-push discipline

**Never force-push to `main`.** Ever.

Force-push rewrites history that other sessions (and paude harvest cycles) depend on. It breaks the repo as truth anchor — a fresh session fetching from origin will silently discard commits it hasn't seen.

Force-push is allowed only on feature/experiment branches you own, and only before those branches are merged to main.

If you need a clean history on a branch, rebase or squash locally before merging. If you've already force-pushed to main (you shouldn't have), the fix is to recover: check the reflog, identify the lost commits, and reconstruct.

## Merge discipline

- Prefer `git merge --no-ff` to preserve branch boundaries in history
- Run the appropriate `/review` depth before merging
- Avoid merging half-finished experimental branches just to checkpoint; keep them open or park with a clear branch name

## Worktrees and branches

This rule complements `git-worktrees.md`:
- Worktrees isolate concurrent tasks
- Branches isolate units of change

Parallel agent sessions should use both: one worktree per task and one task branch per worktree.

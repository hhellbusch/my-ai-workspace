# Workflow: Merge Harvest Locally

<required_reading>
- `references/submodule-targets.md`
- `references/failure-modes.md`
- `rules/git-worktrees.md`
</required_reading>

<process>

### 1. Confirm intent

Local merge only — do not push unless user explicitly asks.

Confirm harvest branch from prior step or `$ARGUMENTS`.

### 2. Per-submodule merge

For each submodule with new work:

```bash
git -C submodules/<name> fetch origin
git -C submodules/<name> checkout <default-branch>
git -C submodules/<name> pull origin <default-branch>
git -C submodules/<name> merge harvest/import-<slug>   # or cherry-pick / patch apply
```

Default branches: see `references/submodule-targets.md`.

Commit in submodule with the message from the container if accurate; fix message if misleading.

### 3. Update parent repo pointers

On host `main`:

```bash
git checkout main
git pull origin main   # if not already current
```

Update only submodules that changed:

```bash
cd submodules/<name> && git checkout <merged-sha> && cd ../..
git add submodules/<name>
```

Include other harvest changes (`.gitignore`, patch archives) only if intentional.

**Do not** run `git submodule update --remote`.

### 4. Commit on main

One commit or logical splits — match repo convention:

```bash
git commit -m "submodules: <summary of harvested work>"
```

### 5. Verify

```bash
git submodule status
git log --oneline -3
git status -sb
```

### 6. Cleanup (offer, don't auto-delete)

```bash
git worktree remove worktrees/<slug>   # if created
git branch -d <harvest-branch>         # after merge
```

Remove submodule import branches (`harvest/import-*`) when done.

</process>

<success_criteria>
- Submodule SHAs on main match merged commits on target branches
- No accidental revert of unrelated submodule pointers
- Host main has a single clear commit (or justified split) for the harvest
</success_criteria>

# Workflow: Harvest from Session

<required_reading>
- `references/commands.md`
- `references/failure-modes.md`
- `docs/ai-engineering/paude-getting-started.md` (Harvest section)
</required_reading>

<process>

### 1. Parse arguments

From `$ARGUMENTS` extract:

- `<session-name>` — required (e.g. `workspace`, `ocp-sno`)
- `--slug <task-slug>` — optional; used for branch naming
- `--no-merge` — stop after harvest branch exists

If session name missing, run `paude list` and ask.

### 2. Host pre-flight

```bash
git fetch origin && git pull origin main
```

If pull blocked by dirty state, stash unrelated changes or ask user.

Ensure host main worktree is on `main` — not on a harvest branch.

### 3. Session check

```bash
paude status <session-name>
```

Prefer Idle state. If Active, note it — user may still want progress harvest.

### 4. Inspect container

```bash
podman exec paude-<session-name> bash -lc 'cd /pvc/workspace && git branch && git log --oneline -5 && git status -sb'
```

Record:

- Container branch (e.g. `harvest/paude-agents`)
- Commits ahead of `origin/main`
- Dirty/untracked files
- `AGENT-NOTES.md` if present

Check for patch exports:

```bash
podman exec paude-<session-name> bash -lc 'ls devops/paude-proxy/harvest/*/ 2>/dev/null'
```

### 5. Choose harvest branch name

Default: mirror container branch, but if `harvest/<slug>` collides with existing `harvest` branch, use `harvest-<slug>`.

See `references/failure-modes.md` — branch collision.

### 6. Run harvest

```bash
paude harvest <session-name> -b <harvest-branch>
```

**On failure** (submodule fetch): follow fallback in `references/commands.md`:

```bash
git fetch paude-<session-name> <container-branch> --no-recurse-submodules
git checkout -B <harvest-branch> paude-<session-name>/<container-branch>
```

### 7. Import submodule-only commits

If parent pointer references SHAs not on any remote:

1. Read `references/submodule-targets.md`
2. Bundle or patch-import per submodule
3. Do not skip — harvest parent commit alone is incomplete

### 8. Verify

```bash
git log --oneline main..<harvest-branch>
git diff --stat main..<harvest-branch>
```

**Flag for user** if diff would revert unrelated submodule pointers (stale container base).

Report:

- Harvest branch name and tip SHA
- Files changed vs main
- Submodule SHAs referenced
- Patch paths if any

### 9. Next step

Unless `--no-merge`, proceed to `workflows/merge-locally.md` with same session context.

If `--no-merge`, suggest worktree:

```bash
git worktree add worktrees/<slug> <harvest-branch>
```

</process>

<success_criteria>
- Harvest branch exists with expected commits
- Submodule-only work identified and import path stated
- User warned about pointer reverts or empty diffs
</success_criteria>

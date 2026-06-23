# Paude Harvest — Failure Modes

Real incidents from this workspace. Check these before assuming harvest succeeded.

## `paude harvest` fails on submodule fetch

**Symptom:**

```
fatal: remote error: upload-pack: not our ref <sha>
Errors during submodule fetch: submodules/<name>
```

**Cause:** Parent repo commit points at a submodule SHA that exists only inside the container — never pushed to GitHub.

**Fix:**

```bash
git fetch paude-<session> <container-branch> --no-recurse-submodules
git checkout -B <harvest-branch> paude-<session>/<container-branch>
```

Then import submodule commits separately (bundle or patch).

## Branch name collision: `harvest/foo`

**Symptom:**

```
fatal: 'refs/heads/harvest' exists; cannot create 'refs/heads/harvest/foo'
```

**Cause:** An older branch named `harvest` blocks creating `harvest/<slug>`.

**Fix:** Use `harvest-<slug>` on the host (e.g. `harvest-paude-agents`).

## Stale container base vs host-ahead main

**Symptom:** `git diff main..harvest-branch` shows submodule pointer **reverts** (e.g. paude back to old SHA).

**Cause:** Container branched from older `origin/main`; host has since merged other work.

**Fix:** When merging, take only intended files (pelorus pointer, patches) — not accidental pointer rollbacks. Compare `git show <harvest-commit> --stat` to the full diff vs main.

## Misleading commit messages

**Symptom:** Commit message says "proxy: host:port" but diff is only `.gitignore`.

**Cause:** Agent committed parent repo without applying submodule changes.

**Fix:** Inspect `git show` per commit. Use patch exports or submodule log inside container. Do not trust handoff prose alone.

## Patch leaves `.orig` files

**Symptom:** `patch -p1` creates `*.orig` files that get committed.

**Fix:** Remove `.orig` before commit; prefer `git apply` or format-patch import.

## `git submodule update --remote` in handoff

**Symptom:** Agent instructions say to run this on the host.

**Cause:** Wrong advice — pulls upstream, discards container work.

**Fix:** Ignore. Merge submodule branches locally; update pointers manually.

## Empty harvest diff

**Symptom:** Harvest succeeds but `git diff main..branch` is empty.

**Cause:** Agent never committed, or container still on `main` with no commits.

**Fix:** `paude-triage` — inspect `git status` in container; send harvest-prep prompt or commit manually.

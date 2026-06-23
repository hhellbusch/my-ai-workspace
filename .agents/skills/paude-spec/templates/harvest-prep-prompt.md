# Harvest Prep (container agent)

Paste this into the paude session when work is done. Replace `<session-name>` and `<short-task-slug>`.

---

You are finishing work in this paude session. Prepare the workspace for harvest by the operator on the host — do NOT push unless explicitly instructed.

## Goal

Leave the workspace ready for `paude harvest <session-name> -b harvest/<short-task-slug>`. Uncommitted changes are invisible to harvest.

## Branch discipline (main repo)

1. All main-repo work on `harvest/<short-task-slug>` — NOT `main`:

   ```bash
   git fetch origin main
   git checkout -B harvest/<short-task-slug> origin/main
   ```

2. Accurate commit messages — message must match the diff.

3. Clean tree: `git status` shows nothing unstaged/untracked (except noted artifacts).

## Submodule discipline

If you changed anything under `submodules/`:

1. Branch from upstream default (not pinned commit):

   ```bash
   git -C submodules/<name> fetch origin
   git -C submodules/<name> checkout -B harvest/<short-task-slug> origin/<default-branch>
   ```

   Defaults: `paude-proxy` → `develop`, `paude` → `main`, `pelorus` → `maci0-main`

2. Commit inside submodule first.

3. Update pointer in parent:

   ```bash
   git add submodules/<name>
   git commit -m "submodules: <name> — <summary>"
   ```

4. Do NOT run `git submodule update --remote`.

## Session artifacts

- Add secrets/artifacts to `.gitignore` — do not commit them.

## Backup patches (if submodule push unavailable)

```bash
mkdir -p devops/paude-proxy/harvest/<short-task-slug>
git -C submodules/<name> format-patch origin/<branch>..HEAD \
  -o devops/paude-proxy/harvest/<short-task-slug>/ 2>/dev/null || true
git add devops/paude-proxy/harvest/<short-task-slug>/
git commit -m "harvest: export patches for <short-task-slug>"
```

## AGENT-NOTES.md

Write at repo root:

1. Summary (2–3 sentences)
2. Repos touched
3. Submodule SHAs and branch logs
4. Verification output (`git status -sb`, `git diff --stat origin/main..HEAD`, `git submodule status`)
5. Operator instructions: session name, harvest branch, merge targets, patch paths

## Do NOT

- Commit on container `main`
- Tell operator to use `git submodule update --remote`
- Hand off unverified instructions

## Final output

```text
HARVEST READY
session: <session-name>
branch: harvest/<short-task-slug>
commits: <N>
submodules: <list or none>
patches: <path or none>
notes: AGENT-NOTES.md
```

Stop — do not push, merge to main, or reset the session.

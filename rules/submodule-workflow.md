# Submodule Workflow — Init, Troubleshooting, Branching

> Git submodules require careful handling in this workspace. This rule covers the operational details that don't belong in the always-loaded AGENTS.md.

## Initialization

Submodule directories may be empty (git placeholders without cloned content). Before working with a submodule, always check:

```bash
# Fast check — shows state with prefix indicators:
# - empty (not initialized) | + modified | U merge conflict
ls submodules/
git -C . submodule status | head -10

# Initialize a specific one:
git submodule update --init submodules/<name>

# Initialize all at once:
git submodule update --init --recursive
```

The paude container is supposed to auto-init submodules on session start via `entrypoint-session.sh`, but this can fail silently if the container image wasn't rebuilt after changes to the init hook. If a submodule is empty, **assume it needs manual init** — don't assume the code exists just because the directory is listed.

An empty submodule directory means you cannot inspect its code, understand its behavior, or debug issues inside it. When debugging a workspace problem, submodule state is often the first thing to check.

## Troubleshooting

| Symptom | Diagnosis | Fix |
|---|---|---|
| Empty directory + `git submodule status` shows `-<hash>` | Not initialized | `git submodule update --init` |
| `git submodule status` shows `+<hash>` | Initialized but pointing to wrong commit | `git submodule update --init --recursive` |
| Clone fails | Network or permissions issue | `git ls-remote <url> HEAD` |
| Submodule should be init but isn't | Container image needs rebuild | The init hook exists in code but isn't baked into the running image |

**Requirements:** Submodule clone requires SSH keys or HTTPS access. If `git submodule update --init` fails, check that SSH keys are available on the host or that the workspace was cloned with `--recurse-submodules`.

## Branching in Submodules

Always branch from the upstream default branch, **not** the pinned commit the submodule currently points to.

```bash
# Find the upstream default branch
git -C submodules/<name> remote show origin | grep 'HEAD branch'

# Fetch and branch from it
git -C submodules/<name> fetch origin
git -C submodules/<name> checkout -b <branch> origin/<default-branch>
```

For forks like `paude`, the default branch is `develop`. Branching off the pinned commit instead creates a PR with a bad base and a merge conflict.

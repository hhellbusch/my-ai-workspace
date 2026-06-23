# Paude Harvest — Commands

## Session discovery

```bash
paude list
paude status
paude status <session-name>
```

Remote name for harvest: `paude-<session-name>` (e.g. `paude-workspace`, `paude-ocp-sno`).

## Inspect container

```bash
podman exec paude-<session> bash -lc 'cd /pvc/workspace && git branch -a && git log --oneline -5 && git status -sb'
podman exec paude-<session> bash -lc 'cat /pvc/workspace/AGENT-NOTES.md' 2>/dev/null
```

## Harvest (try first)

```bash
paude harvest <session-name> -b <harvest-branch>
```

Protected branch names cannot be harvest targets (`main`, `master`, `release`, `release-*`).

## Harvest fallback (submodule fetch failure)

```bash
cd <host-workspace>
git fetch paude-<session> <container-branch> --no-recurse-submodules
git checkout -B <harvest-branch> paude-<session>/<container-branch>
```

Container branch is often `harvest/<slug>` — discover with inspect commands above.

## Host pre-flight

```bash
git fetch origin && git pull origin main
git worktree list
```

Stash unrelated dirty state if pull is blocked.

## Submodule bundle import

```bash
podman exec paude-<session> bash -lc \
  'cd /pvc/workspace/submodules/<name> && git bundle create /tmp/bundle <ref>'
podman cp paude-<session>:/tmp/bundle /tmp/bundle
git -C submodules/<name> fetch /tmp/bundle <ref>:harvest/import-<slug>
```

## Apply exported patches

```bash
cd submodules/<name>
git checkout <default-branch> && git pull origin <default-branch>
patch -p1 < /path/to/devops/paude-proxy/harvest/<slug>/0001-*.patch
# Remove any *.orig files before committing
```

## Worktree (optional, for review before merging to main)

```bash
git worktree add worktrees/<slug> <harvest-branch>
```

See `rules/git-worktrees.md`.

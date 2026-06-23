# Submodule Merge Targets (this workspace)

When merging harvested submodule work on the host, branch from and merge into these targets.

| Submodule | Default branch | Notes |
|-----------|----------------|-------|
| `submodules/paude-proxy` | `develop` | Fork; host:port and proxy features land here |
| `submodules/paude` | `main` | Fork; CLI/backend changes land here |
| `submodules/pelorus` | `maci0-main` | Fork branch; not `main` |
| `submodules/paude-pi-extension` | `main` | |
| `submodules/zanshin-pi-extension` | `main` | |
| `submodules/lid-pi-extension` | `main` | |
| `submodules/pi-openai-compat` | `main` | |
| `submodules/pi-anthropic-vertex` | `main` | |
| `submodules/helm-charts` | check `origin/HEAD` | |

**Branching rule:** Always branch from `origin/<default>`, not the pinned commit in the parent repo.
See `rules/submodule-workflow.md`.

**Import container-only SHAs:**

```bash
# Bundle one commit range from container
podman exec paude-<session> bash -lc \
  'cd /pvc/workspace/submodules/<name> && git bundle create /tmp/sub.bundle <range>'
podman cp paude-<session>:/tmp/sub.bundle /tmp/sub.bundle
git -C submodules/<name> fetch /tmp/sub.bundle HEAD:harvest/import-<slug>
```

**Patches:** Container may export to `devops/paude-proxy/harvest/<slug>/`. Apply on the correct default branch, then update parent pointer.

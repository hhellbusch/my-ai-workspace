# Paude Create Flags

## Minimal launch (this workspace)

```bash
git -C <workspace> worktree add worktrees/<slug> -b <slug>
cd <workspace>/worktrees/<slug>
paude create <session-name> --git --yolo --agent pi \
  --prompt-file <absolute-path-to-spec.md>
```

## Flags

| Flag | Purpose |
|------|---------|
| `--git` | Push workspace to session remote; required for harvest |
| `--yolo` | Autonomous mode — agent does not wait for approvals |
| `--agent pi\|claude\|gemini\|cursor\|copilot` | Agent CLI inside container |
| `--prompt-file <path>` | Task spec — **must be absolute path** |
| `--allowed-domains <group\|host>` | Merged with `paude.json` and user defaults |
| `--pi-extension` | Opt-in `paude-pi-extension` (not in base image) |

## Session naming

- `<session-name>` — stable name for `paude connect`, `paude harvest` (e.g. `workspace`, `ocp-sno`)
- `<slug>` — git branch / worktree name (e.g. `paude-agents`, `ocp-sno-proxy`)
- Keep them related but they need not be identical

## Domains

Read workspace `paude.json` `create.allowed-domains`.

Add session-specific hosts:

```bash
paude allowed-domains <session-name> --add api.cluster.example:6443
```

Blocked? `paude blocked-domains <session-name>`

## Fork / local image

```bash
cd submodules/paude && make build
PAUDE_IMAGE=local paude create ...
```

## After create

```bash
paude status <session-name>
paude wait <session-name> --notify   # optional
```

Detach from session: `Ctrl+b d` in tmux.

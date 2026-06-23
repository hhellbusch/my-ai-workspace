# Paude Container Tooling

Operational reference for adding developer tooling to paude containers. The central question: **where does a tool belong?** The answer determines whether you need to rebuild an image, whether a tool travels with the workspace, and who else benefits from having it.

---

## The three layers

```
┌─────────────────────────────────────────────────────────┐
│  Base image  (Dockerfile)                               │
│  Built once. Shared across all workspaces.              │
│  Tooling here: always available, slow to change.        │
├─────────────────────────────────────────────────────────┤
│  Workspace layer  (paude.json / devcontainer.json)      │
│  Per-project. Rebuilt from base on first use.           │
│  Tooling here: travels with the repo, fast to change.   │
├─────────────────────────────────────────────────────────┤
│  Runtime layer  (entrypoint / agent install scripts)    │
│  Every session start. Installed into PVC, not image.    │
│  Tooling here: licensing constraints, user-specific.    │
└─────────────────────────────────────────────────────────┘
```

---

## Layer 1 — Base image

**File:** `submodules/paude/containers/paude/Dockerfile`

**Use when:** A tool is needed in virtually every paude session, regardless of the project. `git`, `curl`, `jq`, `python3`, `pre-commit`, and `tmux` are examples — they're infrastructure, not project dependencies.

**Cost:** Requires rebuilding and republishing the base image. Changes take effect only after the new image is deployed.

**What's already there:** git, curl, jq, python3.12, pip3.12, pre-commit, uv, gh (GitHub CLI), tmux (built from source), tini.

**What does NOT belong here:** Workspace-specific package installs (pip packages for a single project's scripts, language runtimes for one repo's language). These inflate the shared image for everyone and obscure what each project actually needs.

---

## Layer 2 — Workspace layer

**Files:** `paude.json` (simple) or `.devcontainer/devcontainer.json` (full Dev Container spec)

This is the right layer for the majority of developer tooling. It doesn't require touching the base image, the configuration lives in the repo, and any agent or person cloning the repo gets the right environment automatically.

### `paude.json` — simple format

```json
{
  "setup": "pip install requests beautifulsoup4 markdownify",
  "packages": ["make", "gcc"],
  "create": {
    "allowed-domains": ["default", "golang"],
    "agent": "pi"
  }
}
```

| Key | What it does |
|---|---|
| `setup` | Shell command run once after first container start. Arbitrary: pip install, npm install, download binaries. |
| `packages` | OS packages. Installed via auto-detected package manager (apt / dnf / apk / yum). |
| `base` | Override the base image entirely. |
| `build.dockerfile` | Use a custom Dockerfile instead. |
| `create.allowed-domains` | Network domains to allow. Merged with user defaults (not replaced). |
| `create.agent` | Default agent for this workspace (`pi`, `claude`, `gemini`, etc.). |
| `create.provider` | Default model provider. |

### `devcontainer.json` — full spec

Use when you need Dev Container Features — OCI artifacts that install complete language runtimes (Go, Node, Rust, etc.) without a custom Dockerfile:

```json
{
  "image": "python:3.11-slim",
  "features": {
    "ghcr.io/devcontainers/features/go:1": { "version": "latest" },
    "ghcr.io/devcontainers/features/node:1": { "version": "20" }
  },
  "postCreateCommand": "pip install -r requirements.txt",
  "containerEnv": {
    "MY_VAR": "value"
  }
}
```

Paude downloads features via oras → skopeo → curl (in priority order), generates Dockerfile `RUN` layers from their `install.sh`, and builds a custom image layer on demand. No base image changes needed.

See `submodules/paude/examples/` for working Python, Node, and Go examples.

---

## Layer 3 — Runtime / entrypoint

**File:** `submodules/paude/containers/paude/entrypoint-lib-install.sh`

**Use when:** A tool cannot be redistributed in a container image (licensing restriction) or must be installed to the PVC for persistence across container restarts. The primary example is the agent CLI itself (Claude Code, Pi) — installed to `/pvc/.local/bin` at session start so it survives image updates.

This layer is not for developer tooling in the normal sense. If you're reaching for it for a tool without a licensing constraint, use layer 2 instead.

---

## Decision guide

| The tool is needed... | Right layer |
|---|---|
| In every session, every project | Base image (`Dockerfile`) |
| Only in this workspace | `paude.json` `setup` or `packages` |
| For a full language runtime (Go, Node, Rust) | `devcontainer.json` features |
| For a specific project's build/test pipeline | `paude.json` `setup` |
| Due to a licensing restriction on redistribution | Runtime / entrypoint |
| For the agent itself | Runtime / entrypoint (already handled) |

---

## This workspace — `paude.json`

The `paude.json` at the repo root installs the Python packages used by the research and transcript scripts:

```json
{
  "setup": "pip install requests beautifulsoup4 markdownify pdfplumber youtube-transcript-api",
  "create": {
    "allowed-domains": ["default", "research", "youtube"],
    "agent": "pi"
  }
}
```

| Package | Used by |
|---|---|
| `requests` | `fetch-sources.py` — HTTP fetching |
| `beautifulsoup4` | `fetch-sources.py` — HTML parsing |
| `markdownify` | `fetch-sources.py` — HTML→markdown conversion |
| `pdfplumber` | `fetch-sources.py` — PDF text extraction |
| `youtube-transcript-api` | `fetch-transcript.py` — YouTube captions |

`setup` runs once on first container start. On subsequent sessions the packages are already present in the container filesystem (or PVC, depending on backend).

---

## Network domains

`paude.json` `create.allowed-domains` declares which domains this workspace needs at session create time. Paude merges these with user defaults (union, not replacement). Individual sessions can expand further with `--allowed-domains` or at runtime with `paude allowed-domains <session> --add <domain>`.

Domain group aliases defined in paude:

| Alias | Covers |
|---|---|
| `default` | Vertex AI, Python packages, GitHub, agent-specific |
| `golang` | go.dev, proxy.golang.org, sum.golang.org |
| `nodejs` | npmjs.org, yarnpkg.com |
| `rust` | crates.io, static.rust-lang.org |
| `research` | General web research domains |
| `youtube` | youtube.com and transcript API endpoints |
| `all` | Unrestricted (use with care) |

---

## Diagnosing blocked domains mid-session

```bash
# See what got blocked
paude blocked-domains <session-name>

# Allow a domain without restarting
paude allowed-domains <session-name> --add registry.npmjs.org
```

## Verifying workspace config before building

```bash
paude create --dry-run
```

---

## Related

- **Host skills:** `.agents/skills/paude-launch`, `paude-spec`, `paude-harvest`, `paude-triage` — session lifecycle (see `rules/paude-workflow.md`)
- [`devops/paude/harvest-prep-prompt.md`](harvest-prep-prompt.md) — paste into container agent when task is done
- [`docs/ai-engineering/paude-getting-started.md`](../../docs/ai-engineering/paude-getting-started.md) — narrative guide
- [`.planning/paude-skills/SKILLS-SPEC.md`](../../.planning/paude-skills/SKILLS-SPEC.md) — skill requirements
- [`devops/paude-proxy/README.md`](../paude-proxy/README.md) — proxy architecture, CA certs, PAT scopes
- [`devops/pi/README.md`](../pi/README.md) — Pi agent configuration, extensions, skills discovery
- [`submodules/paude/docs/CONFIGURATION.md`](../../submodules/paude/docs/CONFIGURATION.md) — full config reference
- [`submodules/paude/examples/`](../../submodules/paude/examples/) — Python, Node, Go devcontainer examples

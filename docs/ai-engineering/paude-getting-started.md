# Getting Started with Paude — Autonomous Agent Sessions

> **Status:** In progress — being written from first-hand exploration. Sections marked `[pending]` are not yet written.
> **Source:** Paude v0.20.0a2+ · [github.com/hhellbusch/paude](https://github.com/hhellbusch/paude/tree/feature/wait-and-prompt-file) · Fedora Linux / Podman
> **Fork of:** [github.com/bbrowning/paude](https://github.com/bbrowning/paude) — adds `paude wait`, `--prompt-file`, Pi agent, and GitHub Copilot agent

Paude runs AI coding agents (Claude Code, Gemini CLI, Cursor CLI, OpenClaw, Pi, GitHub Copilot) in isolated, network-filtered containers with git-based sync. You push your code in, assign a task, disconnect, and pull the output back as a branch when the agent is done. The value is parallelism and isolation — the agent runs without you watching, and you review a diff rather than a live session.

This guide is written from hands-on exploration. It covers what actually works, not just what the README describes.

---

## Supported Agents

| Agent | Flag | Primary use |
|---|---|---|
| Claude Code | `--agent claude` (default) | Claude via Vertex AI or direct Anthropic API |
| Gemini CLI | `--agent gemini` | Gemini via Google AI or Vertex AI |
| Cursor CLI | `--agent cursor` | Cursor subscription |
| OpenClaw | `--agent openclaw` | Multi-model gateway (browser UI) |
| Pi | `--agent pi` | Minimal terminal agent; no permission system — container is the boundary |
| GitHub Copilot CLI | `--agent copilot` | GitHub Copilot enterprise/personal subscription |

Agents are installed automatically inside the container — no local agent install needed. You just need auth credentials for your chosen provider.

Pi is the day-to-day agent in this workspace. It runs against Vertex AI (Claude Sonnet by default, switchable to Gemini) using the same ADC auth flow as Claude Code.

**Project context in Pi:** After `--git`, your tree is under `/pvc/workspace/`. Pi loads **`.pi/SYSTEM.md`** as project-local system prompt material for that repo. It does **not** automatically ingest large files such as the full `BACKLOG.md` or `submodules/zanshin-pi-extension/kit/WORKING-STYLE.md` unless you or `.pi/SYSTEM.md` direct a read. Keep `.pi/SYSTEM.md` small. For the split between always-on vs on-demand context (and a future portable Pi extension), see `.planning/ai-context-architecture/`.

## Pi prompt injection model (what is injected)

Three layers can affect Pi's prompt/context in a paude session:

1. **Pi core system prompt** (from Pi itself)
2. **Project-local `.pi/SYSTEM.md`** (from your workspace)
3. **Optional Pi extensions** (via `before_agent_start` hooks)

**Current paude behavior in this workspace:**
- `pi-anthropic-vertex` is baked into the image for Vertex Claude models.
- `paude-pi-extension` is **not auto-installed** by paude; opt in with `--pi-extension` if desired.
- Zanshin/LID are intentionally not baked into the base image; peers can choose their own extension stack.

**Best practices for useful injections:**
- Keep always-on injections short and behavioral (constraints, priorities, failure modes).
- Keep domain/project depth in files the agent reads on demand (`.pi/SYSTEM.md`, `WORKING-STYLE.md`, etc.).
- Treat extension prompt blocks as "policy and posture", not as a place to preload large context.
- If two extensions inject overlapping guidance, consolidate them or make one conditional to reduce prompt drag.

**Credential boundary reality check:**
- API keys for OpenAI/Anthropic providers should stay proxy-only.
- Vertex AI follows paude's standard model: ADC credentials are available in the container for Vertex auth, while network egress remains proxy-filtered.
- For stricter boundaries, treat this as an optional fork direction rather than default behavior.

---

## Prerequisites

- **Podman** (or Docker) installed and running
- **API key** for your chosen agent — e.g. `ANTHROPIC_API_KEY` for Claude Code, or `GOOGLE_CLOUD_PROJECT` + `gcloud auth application-default login` for Vertex AI
- **git** — your workspace must be a git repo
- **uv** — for installing Paude itself

---

## Install

```bash
uv tool install paude
paude --version
```

By default, Paude pulls container images from `quay.io/bbrowning` on first use. Pull happens at session creation — cache it once and subsequent sessions start fast.

## Fork development mode (local image builds)

If you're developing a fork that is not publishing images yet, use local builds:

```bash
cd submodules/paude
make build

# from your workspace root
PAUDE_DEV=1 paude create --agent pi --provider vertex --yolo --git my-session
```

Notes:
- `PAUDE_DEV=1` makes paude use locally built images (`paude-base-centos10:latest[-arch]`) instead of pulling from registry.
- Re-run `make build` after Dockerfile/container-layer changes.
- You can export `PAUDE_DEV=1` in your shell while actively developing, then unset it for normal registry-backed runs.

---

## New Environment Bootstrap (Fast Path)

When you move to a new machine, run the workspace bootstrap check first:

```bash
./scripts/env-check.sh
```

This prints missing dependencies and exact next steps (for this workspace): `uv`, `paude`, `gcloud`, submodule state, and ADC readiness.

Recommended order:

1. Initialize extension/tool submodules:
   ```bash
   git submodule update --init
   ```
2. Install `uv` (if missing), then install paude from your fork source:
   ```bash
   uv tool install --editable submodules/paude
   ```
3. Install/auth Google Cloud CLI for Vertex:
   ```bash
   gcloud auth application-default login
   ```
4. Re-run bootstrap check and proceed only when the required items are green:
   ```bash
   ./scripts/env-check.sh
   ```

If you also run Pi directly on the host (outside paude), install Pi separately. For paude sessions, the agent tooling is installed in-container automatically.

---

## Phase 1: Smoke Test — Learning the Lifecycle

Before running real tasks, exercise the full session lifecycle against a throwaway directory.

```bash
mkdir /tmp/paude-smoke && cd /tmp/paude-smoke
git init && git commit --allow-empty -m "init"

paude create smoke-test --git
paude list                        # list all sessions
paude status                      # enriched status with activity + summary
paude connect smoke-test          # look around, then detach with Ctrl+b d
paude stop smoke-test             # preserves state, saves resources
paude start smoke-test            # instant resume
paude delete smoke-test --confirm # permanent removal
```

**What to notice:**
- First `create` pulls the container image — slow. Subsequent creates reuse the cache and are fast.
- `status` shows `Active` when the agent is working, `Idle` when waiting.
- `stop` / `start` lets you pause and resume without losing conversation state.
- `delete` removes the volume too — permanent.

---

## Phase 2: First Real Task

```bash
cd your-project
paude create my-project --git --yolo -a '-p "your task here"'
```

Key flags on `paude create`:

| Flag | Purpose |
|---|---|
| `--git` | Push your workspace into the container, set as origin |
| `--yolo` | Skip all permission prompts — needed for agents with built-in permission systems (Claude Code, Gemini CLI, Cursor CLI). **Not needed for Pi**, which has no permission system (Zanshin practices provide guardrails instead). |
| `--prompt-file <path>` | Read initial prompt from a file on the host — no shell quoting issues |
| `-a '-p "..."'` | Inline prompt (fragile for multi-line — prefer `--prompt-file`) |
| `--agent` | Choose agent: `claude` (default), `gemini`, `cursor`, `openclaw`, `pi`, `copilot` |
| `--dry-run` | Preview the full resolved config without running |

### Writing a task spec that works

Four failure modes surfaced in hands-on runs — all from spec problems, not tool problems:

| Failure | Cause | Fix |
|---|---|---|
| Agent ran `/review` instead of the task | Prompt started with "Review..." — matched a workspace slash command | Never start a prompt with a word that matches a workspace command |
| Agent asked for clarification in headless mode | "Two lab folders" was ambiguous — agent didn't know which two | Name things explicitly: full paths, not counts |
| Harvest produced empty diff | Agent wrote files but didn't commit | Always end the spec with an explicit commit instruction |
| Agent received broken or truncated prompt | Long spec passed via shell expansion — backticks, embedded quotes, and newlines mangled before Paude received them | Use `--prompt-file` (see below) |
| Spec file not found in container — agent did nothing | `--git` clones from origin; spec committed locally but not pushed, OR session created from a branch that doesn't have the spec commit | Use `--prompt-file` — reads from host filesystem, branch-independent. Or push spec commit to origin first. |

### `--prompt-file` — the canonical approach for non-trivial tasks

`--prompt-file <path>` reads the spec from the host filesystem and passes it to the agent directly — no shell expansion, no quoting issues, no need to commit the file first. Paude reads it in Python before any shell touches it.

```bash
paude create my-session --git --yolo \
  --prompt-file .planning/paude-integration/task-specs/my-task-spec.txt
```

The spec file lives wherever is convenient. It does not need to be in the repo or committed. The agent receives the full content verbatim.

**Prompt checklist before handing off:**

1. Does the spec start with a word that matches a workspace slash command? Rename it.
2. Are all paths, names, and quantities explicit? No "the two files" — use full paths.
3. Does the spec end with a commit instruction?
4. Would a junior engineer reading the spec cold know exactly what to do — and what not to do?

**Always end specs with:**

```
After completing all work, run: git add -A && git commit -m "feat: describe what was done"
```

**Verify a commit exists before harvesting:**

```bash
paude connect my-session
# Inside the container:
git log --oneline -3
# If the expected commit is present, detach (Ctrl+b d) and harvest.
# If git log shows nothing new, the agent didn't commit — do it manually before exiting.
```

**Headless vs. interactive:**

- **Headless (`--prompt-file`)**: fire-and-forget. Use when the spec is airtight. Agent cannot ask clarifying questions without stalling.
- **Interactive (no prompt, `paude connect` first)**: agent can clarify, you can course-correct. Use for exploratory or underspecified tasks.

**The spec gate:** before handing off any headless task, read the spec file cold — as if you're briefing someone who has never seen the codebase. If you'd need to add a sentence of context to make it clear, add it to the spec before launching.

### The AGENT-NOTES pattern

Append this to every task prompt:

> After completing the task, write a brief `AGENT-NOTES.md` in the workspace root: what decisions did you make that the task spec did not explicitly cover? What was ambiguous? What assumptions did you make?

This surfaces where the spec was underspecified — the most useful output for improving your next brief. Read `AGENT-NOTES.md` before reviewing the actual code diff.

---

## The Workflow Pattern: Craft → Gate → Hand Off → Monitor → Harvest → Analyze

Every successful Paude run follows this sequence. Skipping steps produces empty diffs and confused agents.

**Craft** — write the task spec to a file in `.planning/paude-integration/task-specs/`. Apply the prompt checklist. End with an explicit commit instruction. Write the AGENT-NOTES request at the bottom.

**Gate** — read the spec file cold. Use `/grill-me` or a peer read. Would someone with no prior context know exactly what to do? If not, fix the spec — not the tool.

**Hand off** — choose mode:
- Airtight spec → headless with `--prompt-file`:
  ```bash
  paude create my-session --git --yolo \
    --prompt-file .planning/paude-integration/task-specs/my-task-spec.txt
  ```
- Exploratory or uncertain → interactive (`paude create --yolo --git`, then `paude connect`)

**Monitor** — two tools, two levels of detail:

`paude wait` tracks session state (Active / Idle) and fires actions when done:
```bash
paude wait my-session
paude wait my-session --on-idle "paude harvest my-session -b review/branch-name" --notify
```
Options: `--timeout <minutes>` (default: 60), `--interval <seconds>` (default: 30), `--notify` (desktop notification via `notify-send`).

`paude tail` reads the agent's actual tmux output without attaching — useful when you want to see what the agent is writing:
```bash
paude tail my-session            # last 50 lines, then exit
paude tail my-session -n 100    # last 100 lines
paude tail my-session -f        # follow: stream new lines as they appear (Ctrl+C to stop)
```

`Active` means working. `Idle` means done or stalled. If Active longer than expected, `paude tail -f` will show whether the agent is stuck asking for clarification or still producing output.

**Harvest** — before running `paude harvest`, connect and verify a commit exists:
```bash
paude connect my-session
git log --oneline -3   # confirm the expected commit is there
# Ctrl+b d to detach
paude harvest my-session -b review/branch-name
```
Empty diff after harvest = agent didn't commit. Connect and check `git status` inside the container; commit manually if files are there.

**Analyze** — read in this order:
1. `AGENT-NOTES.md` — what did the agent find ambiguous or underspecified?
2. `git diff main..review/branch-name` — what actually changed?
3. Assess: does the output match the intent? Where did the spec fail?

The analysis feeds the next spec. The pattern compounds — each run produces a better brief for the next one.

---

## Phase 3: Fire-and-Forget Orchestration

```bash
# Launch with spec from file
paude create my-project --git --yolo \
  --prompt-file .planning/paude-integration/task-specs/my-task-spec.txt

# Option A — block and watch; auto-harvest when Idle
paude wait my-project \
  --on-idle "paude harvest my-project -b feature/my-task" \
  --notify

# Option B — fire-and-forget; check back manually
paude wait my-project &
# ... go do other things ...
paude status my-project                    # check back periodically
paude harvest my-project -b feature/my-task  # pull changes into a local branch

git diff main..feature/my-task             # review the diff
```

**Harvest** creates a local branch with all of the agent's commits. Protected branch names (`main`, `master`, `release`, `release-*`) cannot be used as harvest targets.

Open a PR from the harvest branch:

```bash
paude harvest my-project -b feature/my-task --pr
# or with a custom title
paude harvest my-project -b feature/my-task --pr --pr-title "Add rate limiting"
```

This pushes the branch to origin and runs `gh pr create`. Requires GitHub CLI to be authenticated (see GitHub CLI below).

**Reset for the next task:**

```bash
paude reset my-project
```

Reset checks out the base branch, runs `git reset --hard origin/main`, and clears conversation history. Use `--keep-conversation` to preserve history across tasks. The session must be running.

---

## Phase 4: Multi-Agent Comparison

[pending — being written from Phase 4 exploration]

Running the same task with two agents:

```bash
paude create task-claude --git --yolo --agent claude -a '-p "..."'
paude create task-gemini --git --yolo --agent gemini -a '-p "..."'
paude status
paude harvest task-claude -b review/claude-attempt
paude harvest task-gemini -b review/gemini-attempt
git diff review/claude-attempt review/gemini-attempt
```

What to compare: not just output quality — behavioral differences. How did each agent interpret the spec? Where did each deviate? Which required more precision to produce something useful?

---

## GitHub CLI Authentication

Paude installs `gh` CLI inside the container and includes GitHub domains in the default network allowlist. Without a token, `gh` operations (listing PRs, creating PRs from `harvest --pr`, reading issues) will fail.

Set a fine-grained personal access token before connecting:

```bash
export PAUDE_GITHUB_TOKEN=ghp_yourtoken
paude start my-project
# gh is authenticated automatically inside the container
```

Or pass it per-session:

```bash
paude start --github-token ghp_yourtoken my-project
```

Create a fine-grained read-only PAT at: https://github.com/settings/tokens?type=beta — scope to specific repos, grant **Contents: Read-only** and **Metadata: Read-only** only.

> The host's `GH_TOKEN` is **never** auto-propagated to the container. Set `PAUDE_GITHUB_TOKEN` explicitly.

---

## Network and Allowed Domains

Paude runs a proxy sidecar that filters all container egress. The default allowlist (`["default"]`) includes:

- **vertexai**: Vertex AI and Google OAuth
- **python**: PyPI, PyTorch, Pythonhosted
- **github**: github.com, api.github.com, raw.githubusercontent.com
- **agent-specific**: for Claude Code, adds `.claude.ai` and `.anthropic.com` automatically

```bash
--allowed-domains default            # standard allowlist (default)
--allowed-domains default golang     # add Go module proxy
--allowed-domains default nodejs     # add npm/Yarn
--allowed-domains default rust       # add Cargo/crates.io
--allowed-domains all                # unrestricted (use with caution)
```

Multiple `--allowed-domains` flags are additive. Passing any `--allowed-domains` on the CLI overrides user defaults entirely (no merging).

**Debugging blocked domains:**

```bash
paude blocked-domains my-project         # see what the proxy blocked
paude allowed-domains my-project --add registry.npmjs.org  # add on the fly
```

---

## Persisting Defaults

Avoid typing long flags on every create:

```bash
paude config init          # creates ~/.config/paude/defaults.json
paude config show          # shows resolved defaults with provenance
```

Example `~/.config/paude/defaults.json`:

```json
{
  "defaults": {
    "backend": "podman",
    "agent": "pi",
    "provider": "vertex",
    "git": true,
    "allowed-domains": ["default"]
  }
}
```

`"git": true` wires `paude remote add` + `git push` on every `paude create`, so `/pvc/workspace/` is populated without a separate manual step (matches the resolver default of `git: false` if omitted).

With this, `paude create my-session` runs Pi on Vertex (Claude Sonnet) with workspace sync — no `--git` or `--yolo` flag needed each time. (Pi has no permission system, so `--yolo` is unnecessary. You only need it for agents with built-in permission prompts — Claude Code, Gemini CLI, Cursor CLI, etc.) Override at create time as needed:

```bash
paude create --agent claude --yolo my-session    # Claude Code instead of Pi (needs --yolo)
paude create --agent claude --allowed-domains "default youtube" my-session  # add domains for this session
```

---

## Measurement

Paude supports OpenTelemetry export via `--otel-endpoint`:

```bash
paude create my-project --git --yolo --otel-endpoint http://collector:4318 -a '-p "..."'
```

Captures token counts, timing, and traces. The endpoint hostname is automatically added to the proxy allowlist. Supported for Claude Code, Gemini CLI, and OpenClaw.

[pending — covering collector setup and useful metrics]

---

## Session Command Reference

| Command | What it does |
|---|---|
| `paude create` | Create session (starts automatically) |
| `paude start` | Start a stopped session |
| `paude stop` | Stop session, preserve volume |
| `paude connect` | Attach to running session |
| `paude status` | Enriched status: activity, state, summary |
| `paude tail [-n N] [-f]` | Print last N lines of agent's tmux output without attaching |
| `paude run --task-file <path>` | Atomic create+wait+harvest+claim evaluation from a task YAML |
| `paude wait [--on-idle cmd] [--notify]` | Poll until Idle; optionally run a command and send a notification |
| `paude list` | All sessions with version info |
| `paude harvest -b <branch>` | Pull agent commits into a local branch |
| `paude harvest -b <branch> --pr` | Harvest + open a PR |
| `paude reset` | Reset workspace, clear conversation history |
| `paude upgrade` | Upgrade session to current paude version |
| `paude delete --confirm` | Remove session and volume permanently |
| `paude blocked-domains` | Show what the proxy blocked |
| `paude allowed-domains --add` | Add a domain to a running session |
| `paude config show` | Show resolved defaults with provenance |

---

*This document was created with AI assistance and is being updated as first-hand exploration progresses. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

# Getting Started with Paude — Autonomous Agent Sessions

> **Status:** In progress — being written from first-hand exploration. Sections marked `[pending]` are not yet written.
> **Source:** Paude v0.15.0 · [github.com/bbrowning/paude](https://github.com/bbrowning/paude) · Fedora Linux / Podman

Paude runs AI coding agents (Claude Code, Gemini CLI, Cursor CLI, OpenClaw) in isolated, network-filtered containers with git-based sync. You push your code in, assign a task, disconnect, and pull the output back as a branch when the agent is done. The value is parallelism and isolation — the agent runs without you watching, and you review a diff rather than a live session.

This guide is written from hands-on exploration. It covers what actually works, not just what the README describes.

---

## Supported Agents

| Agent | Flag |
|---|---|
| Claude Code | `--agent claude` (default) |
| Gemini CLI | `--agent gemini` |
| Cursor CLI | `--agent cursor` |
| OpenClaw | `--agent openclaw` |

Agents are installed automatically inside the container — no local agent install needed. You just need auth credentials for your chosen provider.

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

Paude pulls container images from `quay.io/bbrowning` on first use. Image pull happens at session creation — cache it once and subsequent sessions start fast.

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
| `--yolo` | Skip all permission prompts — agent runs without asking |
| `-a '-p "..."'` | Assign a prompt to the agent as the initial task |
| `--agent` | Choose agent: `claude` (default), `gemini`, `cursor`, `openclaw` |
| `--dry-run` | Preview the full resolved config without running |

### Writing a task spec that works

Three failure modes surfaced in early hands-on runs — all from spec problems, not tool problems:

| Failure | Cause | Fix |
|---|---|---|
| Agent ran `/review` instead of the task | Prompt started with "Review..." — matched a workspace slash command | Never start a prompt with a word that matches a workspace command |
| Agent asked for clarification in headless mode | "Two lab folders" was ambiguous — agent didn't know which two | Name things explicitly: full paths, not counts |
| Harvest produced empty diff | Agent wrote files but didn't commit | Always end the prompt with an explicit commit instruction |

**Prompt checklist before handing off:**

1. Does the prompt start with a word that matches a workspace slash command? Rename it.
2. Are all paths, names, and quantities explicit? No "the two files" — use full paths.
3. Does the prompt end with a commit instruction?
4. Would a junior engineer reading this cold know exactly what to do — and what not to do?

**Always end headless prompts with:**

```
After completing all work, run: git add -A && git commit -m "feat: describe what was done"
```

**Headless vs. interactive:**

- **Headless (`-a '-p "..."'`)**: fire-and-forget. Use only when the spec is airtight. Agent cannot ask clarifying questions without stalling.
- **Interactive (no `-a`, `paude connect` first)**: agent can clarify, you can course-correct. Use for exploratory or underspecified tasks.

**The spec gate:** before handing off any headless task, read the prompt aloud as if you're briefing someone who has never seen the codebase. If you'd need to add a sentence of context to make it clear — add it to the prompt.

### The AGENT-NOTES pattern

Append this to every task prompt:

> After completing the task, write a brief `AGENT-NOTES.md` in the workspace root: what decisions did you make that the task spec did not explicitly cover? What was ambiguous? What assumptions did you make?

This surfaces where the spec was underspecified — the most useful output for improving your next brief. Read `AGENT-NOTES.md` before reviewing the actual code diff.

---

## The Workflow Pattern: Craft → Gate → Hand Off → Monitor → Harvest → Analyze

Every successful Paude run follows this sequence. Skipping steps produces empty diffs and confused agents.

**Craft** — write the task spec. Apply the prompt checklist above. End with an explicit commit instruction.

**Gate** — read it cold. Use `/grill-me` or a peer read. Would someone with no prior context know exactly what to do? If not, fix the spec — not the tool.

**Hand off** — choose mode:
- Airtight spec → headless (`paude create --yolo --git -a '-p "..."'`)
- Exploratory or uncertain → interactive (`paude create --yolo --git`, then `paude connect`)

**Monitor** — `paude status` every 30-60 seconds. `Active` means working. `Idle` means done or stalled. If Active longer than expected, connect and check — the agent may be waiting for clarification it can't get in headless mode.

**Harvest** — `paude harvest -b review/branch-name`. Empty diff = agent didn't commit. Connect and check `git status` inside the container; commit manually if files are there.

**Analyze** — read in this order:
1. `AGENT-NOTES.md` — what did the agent find ambiguous or underspecified?
2. `git diff main..review/branch-name` — what actually changed?
3. Assess: does the output match the intent? Where did the spec fail?

The analysis feeds the next spec. The pattern compounds — each run produces a better brief for the next one.

---

## Phase 3: Fire-and-Forget Orchestration

```bash
paude create my-project --git --yolo -a '-p "..."'
# disconnect — go do something else
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
    "agent": "claude",
    "yolo": true,
    "git": true,
    "allowed-domains": ["default"]
  }
}
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

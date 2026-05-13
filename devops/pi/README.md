# Pi Resource Wiring

Reference for how pi discovers and displays resources in this workspace.

---

## Directory layout

```
/pvc/workspace/
├── .agents/
│   └── skills/                ← AgentSkills standard; discovered by Cursor, Claude Code, Pi
│       └── <name>/SKILL.md
├── .pi/
│   └── SYSTEM.md              ← project system prompt (pi-native)
├── .cursor/
│   ├── skills/                ← rich skills with scripts/assets (Cursor-specific)
│   │   └── <name>/SKILL.md
│   └── rules/                 ← Cursor rules (auto-loaded)
└── CLAUDE.md  (AGENTS.md symlinks to it)
```

All commands are skills in `.agents/skills/`. Pi discovers them natively — no symlinks or sync needed.

---

## How pi discovers resources

Pi looks in `<cwd>/.pi/` for project-level resources and `~/.pi/agent/` for user-level resources.

| Resource | Location scanned | Discovery rule |
|----------|-----------------|----------------|
| Skills | `.agents/skills/`, `.pi/skills/` | Recursive scan for `SKILL.md` in each subdir |
| Extensions | `.pi/extensions/` | `*.ts` / `*.js` files |
| Themes | `.pi/themes/` | `*.json` files |
| Context | `CLAUDE.md` / `AGENTS.md` | First match walking up from cwd |
| System prompt | `.pi/SYSTEM.md` | Read as project system prompt |

Ignore rules: pi reads `.gitignore`, `.ignore`, `.fdignore` from each directory it scans (not from the workspace root).

---

## Installed packages (`~/.pi/agent/settings.json`)

Two packages are installed at user scope by default. Each provides **extensions only** — no skills or prompts from packages.

| Package | What it provides |
|---------|-----------------|
| `zanshin-pi-extension` | Extension: injects Zanshin L0 into system prompt; registers `/spar`, `/shoshin`, `/checkpoint`, `/push`, `/pop`, `/stack` commands |
| `pi-openai-compat` | Extension: registers an OpenAI-compatible model provider (reads `OPENAI_COMPAT_BASE_URL`) |

Package extensions live at: `~/.pi/agent/git/github.com/hhellbusch/<name>/extensions/`

Optional package (not auto-loaded by paude):

| Package | What it provides |
|---------|-----------------|
| `paude-pi-extension` | Extension: injects Paude container-awareness context when `PAUDE_SUPPRESS_PROMPTS=1` |

One additional extension is installed directly:
- `~/.pi/agent/extensions/pi-anthropic-vertex/` — Anthropic Vertex AI provider

---

## Startup display (`showLoadedResources`)

At startup pi renders these sections into the chat area — **section only appears if non-empty**:

```
[Context]     CLAUDE.md (walked up from cwd)
[Skills]      from .agents/skills/<name>/SKILL.md
[Extensions]  from installed packages (zanshin, openai-compat, vertex, and any opt-in extras)
[Themes]      none configured
```

Each section is an `ExpandableText` — collapsed by default, expandable with the configured key.

Controlled by `getQuietStartup()`. If quiet mode is on, sections are suppressed entirely.

---

---

## Extension Patterns

The zanshin-pi-extension bundles four `.ts` extensions under `extensions/`, all auto-discovered via the package.json `"extensions"` field. They follow two architectural patterns.

### Pattern 1: Session lifecycle hooks

Subscribes to pi event hooks for state management, behavioral posture, and context injection. This is the pattern for anything that lives in the agent's operational loop rather than just intercepting output.

**Key hooks and when they fire:**

| Hook | When | Mutable? | Common use |
|------|------|----------|------------|
| `session_start` | Session created, loaded, or resumed | State only | Restore in-memory state, notify on project detection |
| `session_shutdown` | Session ending (quit, reload, switch) | Cleanup only | Warn about uncommitted changes, persist state |
| `before_agent_start` | User submits prompt, before agent loop | System prompt + message | Inject context, modify instructions for this turn |
| `tool_result` | After tool execution, before result message | Can modify result | Enrich output, track file changes, send external hooks |
| `turn_start` / `turn_end` | Each LLM response + tool call cycle | State only | Per-turn bookkeeping, git stashes, counters |
| `session_before_compact` | Before context compaction | Can cancel or provide custom summary | Custom compaction logic, checkpoint triggers |
| `agent_end` | After the LLM has no more tool calls | State only | Clear per-turn state, trigger follow-up actions |

**Key API for persistence:**

```typescript
// Store state that survives restarts (does NOT enter LLM context)
pi.appendEntry("my-state", { count: 42 });

// Restore on session start
pi.on("session_start", async (_event, ctx) => {
  for (const entry of ctx.sessionManager.getEntries()) {
    if (entry.type === "custom" && entry.customType === "my-state") {
      state = entry.data;
    }
  }
});
```

**Practical use cases from pi's examples:**

1. **Git checkpoint (git-checkpoint.ts)** — Creates a `git stash create` before each turn, then when the user forks, offers to restore code state to that checkpoint. Uses `tool_result` to track the current entry ID, `turn_start` to stash, `session_before_fork` to offer restore.

2. **Dirty repo guard (dirty-repo-guard.ts)** — Blocks session switches and forks when uncommitted changes exist. Uses `session_before_switch` and `session_before_fork` with `git status --porcelain`. Shows the pattern for guarding state transitions.

3. **Auto-compact on token threshold (trigger-compact.ts)** — Monitors `ctx.getContextUsage()` in `turn_end` and triggers compaction when the token count crosses a threshold. Shows the pattern for cross-session threshold tracking (stores `previousTokens` in module state). Also exposes a manual `/trigger-compact` command.

4. **Session name management (session-name.ts)** — Sets the session display name based on prompt content. Uses `before_agent_start` to analyze the prompt and `pi.setSessionName()` to tag the session for easier navigation.

**The zanshin hooks (in this workspace):**

| Hook | What it does | Why |
|------|-------------|-----|
| `before_agent_start` | Injects L0 discipline text into system prompt | Ensures working discipline is present each turn without bloating the initial prompt |
| `session_start` | Restores stack state from `zanshin-stack` entries; auto-notifies `/shoshin` when project brief exists | Survives context compaction; surfaces assumptions on project re-entry |
| `tool_result` | Counts `write`/`edit` calls, persists to `zanshin-changes` | Drives the 5-write checkpoint reminder |
| `session_shutdown` | Warns if uncommitted changes exist without checkpoint | Prevents lost work from context loss |

**When to use this pattern vs. command interception:**

- **Lifecycle hooks** — when you need to observe or modify the agent's state, context, or flow. The agent is still doing the work; you're adjusting conditions around it.
- **Bash interception** — when you need to block or confirm specific commands before they execute. The agent never runs if you block it.
- These are not mutually exclusive. A robust guard like `risky-ops-guard` might also track stats in `turn_end` for reporting.

**Footguns (from pi docs):**

- Captured `ctx.sessionManager` is stale after session replacement. Use only the `ctx` passed to replacement callbacks.
- After `ctx.reload()`, code in the old call frame still runs — don't assume in-memory state survived.
- `ctx.signal` is `undefined` outside active turn events. Check before using with `fetch()` or other abort-aware calls.

### Pattern 2: Bash command interception (risky-ops-guard, process-guard, git-force-push-guard)

Intercepts `tool_call` events on bash commands, detects specific patterns via regex, and requires user confirmation before proceeding.

```typescript
export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("bash", event)) return;
    const command = event.input.command ?? "";
    const match = detectRiskyOp(command);
    if (!match) return;

    const ok = await ctx.ui.confirm("Risky operation detected", `
This command may cause irreversible data loss (${match}):

  ${command}

Proceed?
`);

    if (!ok) {
      return { block: true, reason: `Blocked: user declined (${match}).` };
    }
  });
}
```

This pattern is the reuse mechanism — the same scaffolding (detect → confirm → block-or-allow) is applied to three different domains:

| Extension | What it blocks | Scope |
|-----------|---------------|-------|
| `risky-ops-guard.ts` | `rm -rf`, `chmod -R`, `shred`, `dd of=/dev/`, `mkfs`, `truncate -s 0` | Irreversible file operations |
| `process-guard.ts` | `pkill`, `killall`, `kill -9`, `kill -SIGKILL`, `fuser -k`, `lsof | xargs kill` | Process termination |
| `git-force-push-guard.ts` | `git push --force`, `git push -f` to main/master/develop | History rewriting |

The guard pattern is designed to be copy-pasted and customized: change the regex patterns, change the confirmation message, and it works. No new scaffolding needed.

### Extension loading

Extensions are auto-discovered from any package that declares `"extensions": ["./extensions"]` in its `package.json`. They live at `~/.pi/agent/git/github.com/hhellbusch/<name>/extensions/` for installed packages, or at `~/.pi/agent/extensions/` for direct installs. No manual wiring or config updates needed — pi scans the directory on load.

---

## Troubleshooting checklist

1. **`! ls .agents/skills/`** — confirm skill directories are present with `SKILL.md` inside
2. **No `.pi/settings.json`** should exist — if it does, check for `skills: [...]` override entries that might be disabling resources
3. **Quiet startup** — if pi was started with quiet mode, no sections show; check `~/.pi/agent/settings.json` for `"quietStartup": true`
4. **Extension not loading?** — Pi discovers from installed packages (git clone → `PackageManager.resolve()`), **not** from workspace submodules. The installed clone lives at `~/.pi/agent/git/github.com/hhellbusch/<name>/`. If you're developing in a workspace submodule, check whether the installed clone is stale:
   ```bash
   git -C ~/.pi/agent/git/github.com/hhellbusch/<name> log --oneline -3
   # vs
   git -C submodules/<name> log --oneline -3
   ```
   If the installed clone is behind, update it: `pi update <name>` (or `pi update source` for the global source).
5. **`ls` shows directory but `stat`/`read`/`cat` fail** — likely a git submodule that's not checked out (empty commit). Run `git submodule update --init <name>` in the workspace or `git submodule status` to check. The paude container's auto-init can fail silently if the container image predates the init hook.

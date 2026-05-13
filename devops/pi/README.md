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

### Pattern 1: Session lifecycle hooks (zanshin.ts)

Subscribes to pi event hooks for state management and behavioral posture:

- **`before_agent_start`** — Injects L0 discipline text into the system prompt
- **`session_start`** — Restores stack state from prior sessions; auto-notifies shoshin when a project brief is detected
- **`tool_result`** — Tracks `write`/`edit` calls for progressive bookkeeping (checkpoint counter)
- **`session_shutdown`** — Warns if uncommitted changes exist without a checkpoint
- **Command registration** — `/spar`, `/shoshin`, `/checkpoint`, `/push`, `/pop`, `/stack` are registered as slash commands with handlers that delegate to the LLM

Key API: `pi.appendEntry("zanshin-changes", { count })` for cross-session state persistence.

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

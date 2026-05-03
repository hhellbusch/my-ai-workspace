# Pi Resource Wiring

Reference for how pi discovers and displays resources in this workspace.

---

## Directory layout

```
/pvc/workspace/
├── .pi/
│   ├── SYSTEM.md               ← project system prompt (pi-native)
│   ├── skills -> ../.cursor/skills      ← symlink; pi scans this for SKILL.md
│   └── prompts -> ../.cursor/commands  ← symlink; pi scans this for *.md
├── .cursor/
│   ├── skills/                 ← source of truth for skills
│   │   └── <name>/SKILL.md
│   └── commands/               ← source of truth for prompt templates
│       └── <name>.md
└── CLAUDE.md  (AGENTS.md symlinks to it)
```

`.pi/skills` and `.pi/prompts` are symlinks created in commit `eba0e3b`.
Node.js follows them correctly — pi sees the same files as if they were real directories.

---

## How pi discovers resources

Pi looks in `<cwd>/.pi/` for project-level resources and `~/.pi/agent/` for user-level resources.

| Resource | Location scanned | Discovery rule |
|----------|-----------------|----------------|
| Skills | `.pi/skills/` | Recursive scan for `SKILL.md` in each subdir |
| Prompts | `.pi/prompts/` | Top-level `*.md` files only (no recursion) |
| Extensions | `.pi/extensions/` | `*.ts` / `*.js` files |
| Themes | `.pi/themes/` | `*.json` files |
| Context | `CLAUDE.md` / `AGENTS.md` | First match walking up from cwd |
| System prompt | `.pi/SYSTEM.md` | Read as project system prompt |

Ignore rules: pi reads `.gitignore`, `.ignore`, `.fdignore` from each directory it scans (not from the workspace root).

---

## Installed packages (`~/.pi/agent/settings.json`)

Three packages are installed at user scope. Each provides **extensions only** — no skills or prompts from packages.

| Package | What it provides |
|---------|-----------------|
| `paude-pi-extension` | Extension: injects Paude container awareness into system prompt (activates only when `PAUDE_SUPPRESS_PROMPTS=1`) |
| `zanshin-pi-extension` | Extension: injects Zanshin L0 into system prompt; registers `/spar`, `/shoshin`, `/checkpoint`, `/push`, `/pop`, `/stack` commands |
| `pi-openai-compat` | Extension: registers an OpenAI-compatible model provider (reads `OPENAI_COMPAT_BASE_URL`) |

Package extensions live at: `~/.pi/agent/git/github.com/hhellbusch/<name>/extensions/`

One additional extension is installed directly:
- `~/.pi/agent/extensions/pi-anthropic-vertex/` — Anthropic Vertex AI provider

---

## Startup display (`showLoadedResources`)

At startup pi renders these sections into the chat area — **section only appears if non-empty**:

```
[Context]     CLAUDE.md (walked up from cwd)
[Skills]      from .pi/skills/ → .cursor/skills/<name>/SKILL.md
[Prompts]     from .pi/prompts/ → .cursor/commands/<name>.md
[Extensions]  from installed packages (paude, zanshin, openai-compat, vertex)
[Themes]      none configured
```

Each section is an `ExpandableText` — collapsed by default, expandable with the configured key.

Controlled by `getQuietStartup()`. If quiet mode is on, sections are suppressed entirely.

---

## `/config` selector

Opens a TUI list of **all resolved resources** (enabled and disabled) grouped by:
1. Origin: `package` (from installed packages) vs `top-level` (from `.pi/` or `~/.pi/agent/`)
2. Scope: `user` vs `project`

Within each group, subgroups appear for: Extensions · Skills · Prompts · Themes.

A subgroup only renders if it has at least one item.

---

## Known quirk: prompt subdirectory recursion

`collectAutoPromptEntries` reads only **top-level** `.md` files from the prompts directory.
Subdirectories like `.cursor/commands/consider/` and `.cursor/commands/research/` are **not** scanned.
Those prompts are on disk but not loaded by pi.

Skills do recurse — `collectAutoSkillEntries` walks subdirectories looking for `SKILL.md`.

---

## Troubleshooting checklist

1. **`! ls -la /pvc/workspace/.pi`** — confirm symlinks exist and point to `../.cursor/commands` and `../.cursor/skills`
2. **`! ls /pvc/workspace/.cursor/skills`** — confirm skill directories are present with `SKILL.md` inside
3. **`! ls /pvc/workspace/.cursor/commands/*.md`** — confirm prompt `.md` files exist at top level
4. **No `.pi/settings.json`** should exist — if it does, check for `skills: [...]` or `prompts: [...]` override entries that might be disabling resources
5. **Quiet startup** — if pi was started with quiet mode, no sections show; check `~/.pi/agent/settings.json` for `"quietStartup": true`

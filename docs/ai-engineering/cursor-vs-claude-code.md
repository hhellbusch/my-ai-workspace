---
review:
  status: unreviewed
---

# Tool Implementations — Cursor, Claude Code, Copilot CLI

> This document captures the structural and behavioral differences between tool implementations of the Zanshin framework in this workspace. Use it when porting changes between environments or diagnosing behavioral divergence.

## Summary

All tools run the same behavioral framework. The differences are architectural — where rules live, how skills are loaded, which tool primitives are available, and what each tool adds beyond the shared layer.

**Shared layer:** `.agents/skills/` — portable [AgentSkills](https://agentskills.io/specification)-compliant skills, discovered natively by Cursor, Claude Code, Copilot CLI, and Pi. Edit once, available everywhere.

**Tool-specific layers:**
- `.cursor/rules/` + `.cursor/agents/` + `.cursorrules` — Cursor behavioral rules and subagents
- `.claude/skills/` — Claude Code-specific skills (hooks, MCP servers, subagents)
- `submodules/zanshin-pi-extension/skills/` — Pi / Copilot CLI skills (portable Zanshin discipline)

---

## Skills / Commands

The shared layer. All tools discover `.agents/skills/` natively — no manual copy or sync step.

| Aspect | Cursor | Claude Code | Copilot CLI / Pi |
|---|---|---|---|
| Skill location | `.agents/skills/<name>/SKILL.md` | `.agents/skills/<name>/SKILL.md` | `.agents/skills/<name>/SKILL.md` |
| Discovery | Native AgentSkills | Native AgentSkills | Native AgentSkills (`/skills add`) |
| Update workflow | Edit `.agents/skills/` | Edit `.agents/skills/` | Edit `.agents/skills/` |
| Tool-specific skills | `.cursor/agents/` (subagents) | `.claude/skills/` (hooks, MCP, subagents) | `zanshin-pi-extension/skills/` (Zanshin discipline) |

**Note:** Skills in `.agents/skills/` are also indexed by Red Hat SkillsHub, which scans this repository. The `description:` field in each skill's frontmatter is what gets surfaced there — keep descriptions accurate and self-explanatory.

---

## Rules / Behavioral Context

Cursor and Claude Code implement the same behavioral rules via different mechanisms. Copilot CLI loads behavioral context through a `copilot-instructions.md` file.

| Aspect | Cursor | Claude Code | Copilot CLI |
|---|---|---|---|
| Primary config | `.cursorrules` (repo root) | `CLAUDE.md` (repo root) | `~/.copilot/copilot-instructions.md` (global) |
| Behavioral rules | `.cursor/rules/*.mdc` — separate files, loaded per-rule | Inline in `CLAUDE.md` — one file carries all rules | Inline in `copilot-instructions.md` |
| Rule scoping | YAML frontmatter: `alwaysApply: true/false`, `globs:` | Not supported — `CLAUDE.md` is always-on | Not supported |
| Global config | `~/.cursor/` | `~/.claude/CLAUDE.md` | `~/.copilot/copilot-instructions.md` |
| Project config | `.cursor/rules/` + `.cursorrules` | `CLAUDE.md` at repo root | No per-project override |

### Cursor rule file extension — `.mdc` vs `.md`

This distinction matters: Cursor only parses `alwaysApply` and `globs` frontmatter in `.mdc` files. Plain `.md` files in `.cursor/rules/` are treated as reference documents — their frontmatter is ignored.

**`.mdc` — behavioral rules** (auto-loaded per their frontmatter):
`shoshin`, `backlog-capture`, `pre-commit-review`, `review-tracking`, `session-awareness`, `shell-strict-mode`, `cross-linking`, `git-worktrees`, `structured-edit-discipline`, `zanshin-kit`, `command-editing`, `lid`

**`.md` — reference documents** (on-demand, frontmatter not parsed):
`workspace-ethos`, `repo-structure`, `feedback-checkpoints`, `case-study-reflection`

**Implication:** In Cursor, `.mdc` rules can be glob-scoped (e.g., `cross-linking.mdc` loads only when a `.md` file is open). In Claude Code, everything in `CLAUDE.md` loads on every session, making token efficiency more important.

---

## Tool-Specific Skill Layers

Beyond `.agents/skills/`, each tool has a layer for capabilities that are native to that tool only.

### `.cursor/agents/` — Cursor subagents

Custom subagent configurations that appear in Cursor's agent picker:
- `skill-auditor.md` — audits `SKILL.md` files against best practices
- `slash-command-auditor.md` — audits slash command skill files
- `subagent-auditor.md` — audits subagent configurations

These are Cursor-specific (`.md` with Cursor subagent frontmatter). No Claude Code or Copilot CLI equivalent.

### `.claude/skills/` — Claude Code-specific skills

Skills using Claude Code-only primitives:
- `create-hooks/` — create and configure Claude Code hooks
- `create-mcp-servers/` — build MCP server integrations
- `create-subagents/` — create Task-tool subagent configurations

These use Claude Code tool names (`Bash`, `Write`) and primitives not available in Cursor or Copilot CLI.

---

## Tool Names (in skill `allowed-tools`)

| Cursor tool | Claude Code equivalent | Notes |
|---|---|---|
| `Shell` | `Bash` | Renamed; same function |
| `StrReplace` | `Write` | Claude Code rewrites full files; no partial-string replace tool |
| `SemanticSearch` | *(not available)* | Cursor-specific; use `Grep` + keyword search |
| `Read` | `Read` | Same |
| `Write` | `Write` | Same |
| `Glob` | `Glob` | Same |
| `Grep` | `Grep` | Same |
| `WebSearch` | `WebSearch` | Same |
| `WebFetch` | `WebFetch` | Same |

---

## Context Loading in Skills

| Aspect | Cursor | Claude Code |
|---|---|---|
| Auto-load files | `@file` in YAML context block | Explicit `Read` instructions in process body |
| Auto-run commands | `` !`cmd` `` in YAML context block | Explicit `Bash` tool calls or "Run:" instructions |
| Semantic search | `SemanticSearch` tool | `Grep` with keyword search (lower recall for fuzzy topics) |

**Implication:** In Cursor, context declared in a skill's YAML frontmatter is loaded before the skill runs. In Claude Code, the model loads context by running reads as part of the process — it's guaranteed only if the skill instructions are explicit.

---

## Behavioral Alignment

The following behaviors are present in Cursor and Claude Code. Copilot CLI picks up the behavioral discipline from `zanshin-pi-extension/skills/` rather than workspace-level rules.

| Behavior | Cursor | Claude Code |
|---|---|---|
| Session orientation | `.agents/skills/start/SKILL.md` + `session-awareness.mdc` | `.agents/skills/start/SKILL.md` + `CLAUDE.md` section |
| Shoshin | `.cursor/rules/shoshin.mdc` (always-on) | `CLAUDE.md` shoshin section |
| Sparring | `.agents/skills/spar/SKILL.md` | `.agents/skills/spar/SKILL.md` |
| Feedback checkpoints | `.cursor/rules/feedback-checkpoints.mdc` (reference doc) | `CLAUDE.md` feedback checkpoints section |
| Review tracking | `.cursor/rules/review-tracking.mdc` (always-on) | `CLAUDE.md` review tracking section |
| Backlog capture | `.cursor/rules/backlog-capture.mdc` (always-on) | `CLAUDE.md` backlog capture section |
| Case study reflection | `.cursor/rules/case-study-reflection.mdc` (reference doc) | `CLAUDE.md` case study section |
| Pre-commit review | `.agents/skills/review/SKILL.md` | `.agents/skills/review/SKILL.md` |
| Cross-linking | `.cursor/rules/cross-linking.mdc` (glob-scoped to `.md` files) | `CLAUDE.md` cross-linking section (always-on) |
| Collaboration style | `.cursorrules` | `CLAUDE.md` |
| Workspace identity | `.cursorrules` + `ABOUT.md` | `CLAUDE.md` + `ABOUT.md` |

---

## Known Gaps

| Gap | Status | Notes |
|---|---|---|
| SemanticSearch in `/cross-link` | Workaround | Claude Code version uses Grep; lower recall for fuzzy topic matching. |
| StrReplace precision | Degraded | Claude Code's `Write` rewrites the full file — more token-intensive for large files. |
| Glob-scoped rule loading | Not available in Claude Code | `CLAUDE.md` loads every session regardless of open files. Cross-linking checks run even when not working on content. |
| Copilot CLI rule scoping | Not available | No per-project override; behavioral context loads from `~/.copilot/copilot-instructions.md` only. |

---

## Maintenance Protocol

When updating the framework:

1. **Edit skills** — `.agents/skills/<name>/SKILL.md` is the shared source for slash-command behavior (Cursor, Claude Code, Pi, Copilot CLI). Changes here reach all tools.
2. **Update `CLAUDE.md`** if the change is a behavioral rule for Claude Code.
3. **Update Cursor rules** (`.cursor/rules/*.mdc`, `.cursorrules`) when the change is Cursor-specific.
4. **Update `zanshin-pi-extension/skills/`** when the change should also reach Copilot CLI / Pi (bump submodule pointer after committing in the submodule).
5. **Update this document** if the change introduces a new structural difference.

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

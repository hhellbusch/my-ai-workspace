---
review:
  status: unreviewed
---

# Cursor vs. Claude Code — Implementation Differences

> This document captures the structural and behavioral differences between the Cursor and Claude Code implementations of the Zanshin framework in this workspace. Use it when porting changes between environments or diagnosing behavioral divergence.

## Summary

Both environments run the same behavioral framework. The differences are architectural — where rules live, how commands are loaded, and which tool primitives are available. The framework content is aligned as of 2026-04-21.

---

## Rules / Behavioral Context

| Aspect | Cursor | Claude Code |
|---|---|---|
| Primary config | `.cursorrules` (repo root) | `CLAUDE.md` (repo root) |
| Always-on rules | `.cursor/rules/*.md` — separate files, loaded by Cursor | Inline in `CLAUDE.md` — one file carries all behavioral rules |
| Rule scoping | YAML frontmatter: `alwaysApply: true/false`, `globs:` | Not supported — `CLAUDE.md` is always-on; no selective loading |
| Global config | `~/.cursor/` | `~/.claude/CLAUDE.md` (global, loads in every project) |
| Project config | `.cursor/rules/` + `.cursorrules` | `CLAUDE.md` at repo root |

**Implication:** In Cursor, rules can be glob-scoped (e.g., `cross-linking.md` loads only when a `.md` file is open). In Claude Code, everything in `CLAUDE.md` loads on every session. This makes token efficiency more important — `CLAUDE.md` is written more concisely than the full Cursor rule set.

**Cross-linking rule specifically:** In Cursor, `cross-linking.md` uses `globs: ["**/*.md", ...]` to activate only when relevant files are open. In Claude Code, the cross-linking behavior is always-on as a section in `CLAUDE.md`.

---

## Commands

| Aspect | Cursor | Claude Code |
|---|---|---|
| Command location | `.agents/skills/<name>/SKILL.md` (AgentSkills; ships with repo) | `.agents/skills/<name>/SKILL.md` (same files) |
| Project-level commands | Supported natively | Supported natively |
| Installation | Automatic — native Agent Skills discovery | Automatic — native Agent Skills discovery |
| Source of truth | `.agents/skills/` | `.agents/skills/` |
| Update workflow | Edit `.agents/skills/<name>/SKILL.md` | Edit `.agents/skills/<name>/SKILL.md` |

**Implication:** Slash commands are Agent Skills in `.agents/skills/`. Cursor, Claude Code, and Pi discover them natively — no manual copy step. See `.claude/README.md`.

---

## Tool Names (in command `allowed-tools`)

| Cursor tool | Claude Code equivalent | Notes |
|---|---|---|
| `Shell` | `Bash` | Renamed; same function |
| `StrReplace` | `Write` | Claude Code rewrites full files; no partial-string replace tool |
| `SemanticSearch` | *(removed)* | Cursor-specific; replaced with `Grep` + keyword search in process instructions |
| `Read` | `Read` | Same |
| `Write` | `Write` | Same |
| `Glob` | `Glob` | Same |
| `Grep` | `Grep` | Same |
| `WebSearch` | `WebSearch` | Same |
| `WebFetch` | `WebFetch` | Same |

---

## Context Loading in Commands

| Aspect | Cursor | Claude Code |
|---|---|---|
| Auto-load files | `@file` in YAML context block | Explicit `Read file` instructions in process body |
| Auto-run commands | `!`cmd`` in YAML context block | Explicit `Bash` tool calls or "Run:" instructions in process body |
| Semantic search | `SemanticSearch` tool | `Grep` with keyword search (lower recall for fuzzy topics) |

**Implication:** Cursor commands can declaratively load context in their YAML frontmatter and it happens before the command runs. Claude Code commands must instruct the model to load context explicitly as part of the process. This is a behavior difference: in Cursor, context is guaranteed available at command start; in Claude Code, the model runs the reads as part of the process.

---

## Behavioral Alignment

The following behaviors are present in both environments:

| Behavior | Cursor implementation | Claude Code implementation |
|---|---|---|
| Session orientation | `.agents/skills/start/SKILL.md` + `session-awareness.md` rule | `.agents/skills/start/SKILL.md` + `CLAUDE.md` session orientation section |
| Shoshin | `.cursor/rules/shoshin.mdc` (always-on) | `CLAUDE.md` shoshin section |
| Sparring | `.agents/skills/spar/SKILL.md` | `.agents/skills/spar/SKILL.md` |
| Feedback checkpoints | `.cursor/rules/feedback-checkpoints.md` (always-on) | `CLAUDE.md` feedback checkpoints section |
| Review tracking | `.cursor/rules/review-tracking.mdc` (always-on) | `CLAUDE.md` review tracking section |
| Backlog capture | `.cursor/rules/backlog-capture.mdc` (always-on) | `CLAUDE.md` backlog capture section |
| Case study reflection | `.cursor/rules/case-study-reflection.md` (always-on) | `CLAUDE.md` case study section |
| Pre-commit review | `.agents/skills/review/SKILL.md` | `.agents/skills/review/SKILL.md` |
| Cross-linking | `.cursor/rules/cross-linking.mdc` (glob-scoped) | `CLAUDE.md` cross-linking section (always-on) |
| Collaboration style | `.cursorrules` | `CLAUDE.md` |
| Workspace identity | `.cursorrules` + `ABOUT.md` | `CLAUDE.md` + `ABOUT.md` |

---

## Known Gaps

| Gap | Status | Notes |
|---|---|---|
| SemanticSearch in `/cross-link` | Workaround | Claude Code version uses Grep; lower recall for fuzzy topic matching. The command falls back to "check anchor relationships" for always-relevant docs. |
| StrReplace precision | Degraded | Claude Code's `Write` rewrites the full file. For large files, this is more token-intensive than Cursor's `StrReplace` (partial edit). |
| Glob-scoped rule loading | Not available | Claude Code loads `CLAUDE.md` on every session regardless of what files are open. Cross-linking checks run even when not working on content. |
| `framework-bootstrap.md` parity | Aligned | AgentSkills migration removed the manual Claude command-copy path; bootstrap reflects native `.agents/skills/` discovery. |

---

## Maintenance Protocol

When updating the framework:

1. **Edit skills** — `.agents/skills/<name>/SKILL.md` is the shared source for slash-command behavior (Cursor, Claude Code, Pi).
2. **Update `CLAUDE.md`** if the change is a behavioral rule.
3. **Update Cursor rules** (`.cursor/rules/`, `.cursorrules`) when the change is Cursor-specific.
4. **Update this document** if the change introduces a new structural difference.

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

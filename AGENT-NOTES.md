# AGENT-NOTES

Session: 2026-05-03 — workspace meta cleanup + lid-pi-extension scaffold

## What this session did

1. **Workspace cleanup** (`f0df97c`)
   - `AGENTS.md → CLAUDE.md` symlink: pi, Copilot, Zed, Cline now auto-load
     workspace context without a second file
   - `CLAUDE.md`: removed collaboration style re-declaration (kit owns it),
     fixed dead `.cursor/rules/` citations → on-demand read table, fixed YouTube
     skill path, added Intent First section, added Workspace Extensions table
   - `.cursorrules`: trimmed collaboration style to a kit pointer; updated Tool
     Resources section to reflect symlink architecture

2. **lid-pi-extension scaffold** (this commit)
   - Full extension ready to extract to its own GitHub repo
   - Non-code arrow adaptation: Intent → Design Note → Acceptance Criteria → Change
   - Three-tier trigger: Touch / Change / Restructure
   - `.cursor/rules/lid.mdc` for Cursor auto-load
   - CLAUDE.md already has the Intent First section (Claude Code / pi)
   - `.planning/lid-pi-extension/BRIEF.md` documents all design decisions

## Decisions made (not in task spec)

**Submodule question — keep zanshin submodule.**
The submodule serves Cursor and Claude Code; pi uses the installed extension.
Two delivery mechanisms for two tool contexts — both correct. Removing the
submodule would break Cursor rules and CLAUDE.md references to kit files.

**lid-pi-extension as directory, not submodule yet.**
Currently lives in `lid-pi-extension/` at workspace root. Cursor rule and
CLAUDE.md reference it by directory path. Once extracted to its own repo,
paths stay the same — it becomes a submodule and nothing else changes.
Backlog item added for extraction.

**Commands parity — cannot symlink `.claude/commands/` → `.cursor/commands/`.**
The files have meaningful content differences beyond tool names: Cursor uses
`@file` reference syntax and different read patterns; Claude Code uses explicit
`Read` steps. Symlinking would break Claude Code commands. Parity requires
porting missing commands individually. Not done this session — left for later.

**Paude workspace architecture — separate workspace per code project.**
Code projects should NOT be git submodules of this workspace. Each gets its own
paude workspace (`/pvc/`). This workspace is the knowledge/practice workspace.
Extensions (zanshin, lid) are installed per workspace — they're the portability
layer. Tool extensions remain submodules here because this workspace consumes them.

**`.gitmodules` not staged.**
The container required HTTPS to clone the zanshin submodule (SSH blocked).
The `.gitmodules` file shows `url = https://...` as a result. Not committed —
the host environment uses SSH and should keep it. Revert after harvest if needed:
```
git submodule set-url zanshin-pi-extension git@github.com:hhellbusch/zanshin-pi-extension.git
```

## Ambiguities resolved

**Non-code EARS adaptation**: dropped EARS terminology and `@spec` annotations
entirely for the non-code workflow. They're code-specific and add noise without
value in a docs/tooling workspace. Plain acceptance criteria language is enough.
Semantic IDs retained as optional for long-running structural work.

**Integration between Zanshin and LID**: achieved by loading both extensions,
not by baking integration into either. Each is independently useful. Natural
touchpoints (shoshin at phase gates, checkpoints after phases, spar for edge
audit) are documented in LID-WORKFLOW.md and the README but not enforced.

## What's ready for next steps

- Extract `lid-pi-extension/` to its own GitHub repo (backlog item added)
- Port missing `.cursor/commands/` commands to `.claude/commands/` format
  (commands parity gap — not tackled this session)
- Consider opening upstream discussion with LID repo about non-code adaptation

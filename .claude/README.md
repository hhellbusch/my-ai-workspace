# Claude Code Configuration

This directory contains Claude Code commands adapted from the Cursor equivalents in `.cursor/commands/`.

## Setup

Claude Code loads commands from `~/.claude/commands/`. To install or update:

```bash
# Install all workspace commands
cp /path/to/this/repo/.claude/commands/*.md ~/.claude/commands/

# Or from within the workspace
cp .claude/commands/*.md ~/.claude/commands/
```

The workspace `CLAUDE.md` (repo root) loads automatically when Claude Code runs in this directory — no copy needed.

## Files

`commands/` — Workspace-specific slash commands. These are adapted from `.cursor/commands/` for Claude Code's environment:
- `Shell` → `Bash` in `allowed-tools`
- `StrReplace` → `Write`
- `SemanticSearch` removed (use `Grep` with keyword search instead)
- `@file` context references converted to explicit read instructions
- `!`cmd`` auto-run syntax converted to plain instructions
- `.cursorrules` references updated to `CLAUDE.md` where appropriate

## Updating

When `.cursor/commands/` is updated, re-run the copy with adaptations or update the files here manually and re-copy to `~/.claude/commands/`.

Source of truth for changes: `.cursor/commands/` (Cursor version). This directory tracks the Claude Code adaptation.

## Differences from Cursor

See `docs/ai-engineering/cursor-vs-claude-code.md` for the full implementation comparison.

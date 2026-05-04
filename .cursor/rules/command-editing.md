---
description: Guardrail for editing shared commands — edit .commands/ first, then sync
globs:
  - .commands/**
  - .cursor/commands/**
  - .claude/commands/**
alwaysApply: false
---

# Command Editing — Source of Truth

Shared command bodies live in `.commands/` (repo root). Platform wrappers in `.cursor/commands/` and `.claude/commands/` add YAML frontmatter (tool names differ between platforms) and embed the shared body after a `<!-- body: ../.commands/foo.md -->` marker.

## When editing a shared command

1. **Edit `.commands/foo.md`** — this is the source of truth for the body.
2. **Run `scripts/sync-commands.sh`** — propagates the body into both platform wrappers, preserving each wrapper's frontmatter.
3. **Review the diff** in `.cursor/commands/` and `.claude/commands/` before committing.

## When editing a platform wrapper directly

If the file contains a `<!-- body: -->` marker, **stop** — you are about to edit a generated file. Edit `.commands/` instead, then sync. Changes made directly to the wrapper body will be overwritten on the next sync.

Editing **frontmatter only** (description, allowed-tools, argument-hint) in the wrapper is fine — the sync script preserves frontmatter. Frontmatter is platform-specific and lives in the wrapper, not in `.commands/`.

## Cursor-only commands

Commands in `.cursor/commands/` that have **no** `<!-- body: -->` marker are Cursor-only — they have no shared body and no `.claude/commands/` counterpart. Edit them directly.

---
description: Maintain cross-references when creating or modifying content
globs:
alwaysApply: true
---

# Cross-Linking Convention

When creating or modifying content, check whether cross-references need updating:

## New Content Triggers

- **New file in `docs/`** — Place in the correct track subdirectory (`ai-engineering/`, `philosophy/`, or `case-studies/`). Add to that track's `README.md` reading list and to the master `docs/README.md` cross-track reading order. Add to the Related Reading section of related essays. For essays in the zen-karate series: include a **Sources and References** section linking to specific research sources, threads, and library entries that informed the essay, and an **Open Review** section linking to any sparring notes with a summary of unresolved counterarguments.
- **New directory in `research/`** — Add to `research/README.md` contents table. If it relates to a docs/ essay, mention it there.
- **New command in `.cursor/commands/`** — Consider whether `.cursorrules` TACHES section needs updating.
- **New skill in `.cursor/skills/`** — Consider whether `.cursorrules` TACHES section needs updating.
- **New rule in `.cursor/rules/`** — No registry to update, but verify the rule doesn't conflict with existing rules.
- **New planning project in `.planning/`** — Ensure a corresponding backlog item exists in `BACKLOG.md`.
- **New library entry in `library/`** — Update `library/README.md` index. Check if the reference is relevant to any active project's curated reading list.

## Modified Content Triggers

- **Renamed or moved file** — Search for markdown links pointing to the old path and update them.
- **Deleted file** — Search for markdown links pointing to it and remove or redirect them.
- **Scope change to a directory** — Check if its parent README description is still accurate.

## Inline Implementation Links

When writing prose that mentions a specific file, command, script, rule, or skill by name, link it to the actual implementation on first mention. The reader should be able to follow the reference without searching.

**Link these on first mention in a section or document:**
- Commands: `` [`/spar`](path/to/spar.md) `` — link to `.cursor/commands/`
- Rules: `` [`shoshin.md`](path/to/shoshin.md) `` — link to `.cursor/rules/`
- Scripts: `` [`fetch-transcript.py`](path/to/script) `` — link to the script file
- Skills: `` [`create-meta-prompts`](path/to/SKILL.md) `` — link to the skill's `SKILL.md`
- Planning artifacts: `` [`BRIEF.md`](path/to/BRIEF.md) ``, `` [`CHANGELOG.md`](path/to/CHANGELOG.md) `` — link to the specific project's file
- Config files: `` [`BACKLOG.md`](path/to/BACKLOG.md) ``, `` [`.cursorrules`](path/to/.cursorrules) `` — link to the file

**When not to link:**
- Subsequent mentions of the same file in the same section — link once, then use backtick-only
- Generic references ("run the command", "check the rule") that don't name a specific file
- Artifact tables that already provide links — the table is the link, prose nearby doesn't need to duplicate it

Use relative paths from the document's location, not absolute paths.

## Don't Over-Link

Not every file needs to be linked from everywhere. The key registries are:
- `docs/README.md` — Every published essay
- `research/README.md` — Every research directory
- `library/README.md` — Every personal reference entry
- `BACKLOG.md` — Every tracked work item
- `.cursorrules` — High-level project description (not every file, but every major content area)

When in doubt, run `/audit` to check.

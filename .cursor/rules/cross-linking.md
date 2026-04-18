---
description: Maintain cross-references when creating or modifying content
globs:
alwaysApply: true
---

# Cross-Linking Convention

When creating or modifying content, check whether cross-references need updating:

## New Content Triggers

- **New file in `docs/`** — Add to `docs/README.md` reading list. Add to the Related Reading section of related essays.
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

## Don't Over-Link

Not every file needs to be linked from everywhere. The key registries are:
- `docs/README.md` — Every published essay
- `research/README.md` — Every research directory
- `library/README.md` — Every personal reference entry
- `BACKLOG.md` — Every tracked work item
- `.cursorrules` — High-level project description (not every file, but every major content area)

When in doubt, run `/audit` to check.

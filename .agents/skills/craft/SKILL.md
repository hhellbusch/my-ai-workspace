---
name: craft
description: Apply engineering principles to code or design — DRY, KISS, SRP, YAGNI, phased delivery
argument-hint: "[file path | diff | design | inline content from conversation]"
allowed-tools: Read Grep Glob Shell SemanticSearch
---

# Craft — Invoked (Workspace)

<objective>
Apply engineering judgment lenses to code, diffs, or designs in this workspace. Follow the portable core process, then workspace conventions.
</objective>

## Core process

Read and follow **`submodules/zanshin-pi-extension/skills/craft/SKILL.md`** in full.

Full principle reference: **`submodules/zanshin-pi-extension/kit/ENGINEERING-PRINCIPLES.md`**.

Artifact discipline (JBGE, TAGRI): **`submodules/zanshin-pi-extension/kit/AGILE-ARTIFACT-DISCIPLINE.md`**.

## Workspace conventions

When reviewing code in this repo, also check:

| Area | Convention |
|---|---|
| Shell scripts | `set -euo pipefail` — see `rules/shell-strict-mode.md` |
| Submodule edits | Commit inside submodule, update parent SHA — see `rules/submodule-workflow.md` |
| Structured edits | Prefer targeted edits over full-file rewrites — see `rules/structured-edit.md` |
| Extension source | ASCII-safe comments — see `submodules/zanshin-pi-extension/docs/CODING-CONVENTIONS.md` |

`/review` is the pre-commit **repo conventions** gate (placement, links, voice). `/craft` is **engineering judgment** on the code itself. Run both before significant commits when appropriate.

## Ordering

- **Shoshin** first when the problem or scope may be wrong
- **Craft** when the approach is settled but implementation quality matters
- **Spar** when committing to a design direction needs adversarial challenge
- **Review** before commit for repo-wide convention compliance

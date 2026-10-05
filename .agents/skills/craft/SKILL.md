---
name: craft
description: >
  Apply engineering principles to code or design — DRY, KISS, SRP, YAGNI,
  convention over configuration, orchestration vs program, phased delivery.
  Use when the user says /craft or asks to review for craft / CoC / glue-vs-program.
argument-hint: "[file path | diff | design | inline content from conversation]"
allowed-tools: Read Grep Glob Shell SemanticSearch
---

# Craft — Invoked (Workspace)

<objective>
Apply engineering judgment lenses to code, diffs, or designs in this workspace. Follow the portable core process, then Field Notes–only conventions.
</objective>

## Core process

Read and follow **`submodules/zanshin-pi-extension/skills/craft/SKILL.md`** in full.

Full principle reference: **`submodules/zanshin-pi-extension/kit/ENGINEERING-PRINCIPLES.md`**.

Artifact discipline (JBGE, TAGRI): **`submodules/zanshin-pi-extension/kit/AGILE-ARTIFACT-DISCIPLINE.md`**.

Basics (kihon): kit loads **`kit/kihon/`** when relevant — or run `/kihon <domain>`. Stance map: **`kit/DESIGN-PHILOSOPHY.md`**.

When reviewing pipelines or Ansible/Helm that have grown control flow or a flag forest, craft lenses **orchestration vs program** and **convention over configuration** (omakase) apply.

## Workspace-only conventions

| Area | Convention |
|---|---|
| Submodule edits | Commit inside submodule, update parent SHA — see `rules/submodule-workflow.md` |
| Extension source | ASCII-safe comments — see `submodules/zanshin-pi-extension/docs/CODING-CONVENTIONS.md` |

Portable kihon forms live in the kit (`kit/kihon/`), not in `rules/` forks.

`/review` is the pre-commit **repo conventions** gate (placement, links, voice). `/craft` is **engineering judgment**. `/kihon` is **fixed forms**. Run as needed before significant commits.

## Ordering

- **Shoshin** first when the problem or scope may be wrong
- **Kihon** when writing/reviewing shell, secrets, CI basics, or insert edits
- **Craft** when the approach is settled but implementation quality matters
- **Spar** when committing to a design direction needs adversarial challenge
- **Review** before commit for repo-wide convention compliance

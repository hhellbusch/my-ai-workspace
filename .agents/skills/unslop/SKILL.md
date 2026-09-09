---
name: unslop
description: >-
  Cut AI tells from writing. Use when the user says /unslop, "unslop this",
  or asks to strip AI patterns from a draft in this workspace.
argument-hint: "[file path | inline content from conversation]"
allowed-tools: Read Grep Glob
---

# Unslop — Invoked (Workspace)

<objective>
Cut AI tells from a named draft. Follow the portable core, then this workspace's style exceptions.
</objective>

## Core process

Read and follow **`submodules/zanshin-pi-extension/skills/unslop/SKILL.md`** in full.

Upstream pattern list: [cursor/plugins pstack unslop](https://github.com/cursor/plugins/blob/main/pstack/skills/unslop/SKILL.md).

## Workspace exceptions

| Upstream rule | Here |
|---|---|
| 13 em dashes | Keep `# Title — subtitle` in `docs/` / `devops/` when that is the house style. Strip body em dashes used as clause glue. |
| 17 title case | `STYLE.md` uses a title-case `#` heading plus optional em-dash subtitle. Keep that. Use sentence case for `##` / `###`. |
| 26 metaphor nouns | Keep **harness**, **sandbox** (Ambler), **JBGE**, **TAGRI**, **clanker** when those are the project's words. |
| Always-on | Do not. Ambient line is already "cut before adding." This skill is a pass. |

Also keep semantic line breaks (`STYLE.md`): one sentence per line.

## Ordering

- **Shoshin** if the doc may be answering the wrong question
- **Craft** (JBGE / TAGRI) if the doc may not need to exist
- **Unslop** when the frame is right and the prose is the problem
- **Review** before commit

---
description: Guardrail for editing skills — edit .agents/skills/ directly
globs:
  - .agents/skills/**
alwaysApply: false
---

# Skill Editing

All skills live in `.agents/skills/<name>/SKILL.md` ([AgentSkills standard](https://agentskills.io/specification)). Cursor, Claude Code, and Pi all discover this directory natively.

## Frontmatter fields

- `name`, `description` — required (AgentSkills spec)
- `argument-hint` — shown in `/` menu autocomplete
- `allowed-tools` — space-separated string of pre-approved tools (experimental)
- `metadata` — arbitrary key-value for additional properties

## Editing

Edit `.agents/skills/<name>/SKILL.md` directly. No sync or build step needed.

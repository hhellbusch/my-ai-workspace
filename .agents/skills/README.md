# Agent Skills

Portable slash-command skills following the [AgentSkills standard](https://agentskills.io/specification). Discovered natively by Cursor, Claude Code, Copilot CLI, and Pi — no manual copy or sync step.

## Discovery

| Tool | How skills load |
|---|---|
| Cursor | Native — scans `.agents/skills/` automatically |
| Claude Code | Native — scans `.agents/skills/` automatically |
| Copilot CLI | `/skills add <path>/.agents/skills/` (one-time per machine) |
| Pi | Native — configured via Pi extension |

## External indexing

Red Hat SkillsHub scans this repository and indexes skills from this directory. The `description:` field in each skill's YAML frontmatter is what gets surfaced to SkillsHub users. Keep descriptions accurate and self-contained — external users may invoke a skill without any workspace context.

## Structure

Each skill lives in its own directory:

```
.agents/skills/
  <skill-name>/
    SKILL.md          # Required — frontmatter + process instructions
    README.md         # Optional — extended documentation
    references/       # Optional — supporting reference material
    templates/        # Optional — output templates
    workflows/        # Optional — multi-step workflow definitions
    scripts/          # Optional — supporting scripts (e.g. fetch-transcript.py)
```

`SKILL.md` frontmatter:

```yaml
---
name: skill-name          # matches directory name
description: One sentence — shown in tool pickers and SkillsHub
allowed-tools: [Read, Grep, Shell, ...]
---
```

## Skills in this directory

### Working discipline (from `zanshin-pi-extension`)

| Skill | Purpose |
|---|---|
| `/spar` | Adversarial review — challenge a plan, design, or argument |
| `/grill-me` | Relentless interrogation before building |
| `/checkpoint` | Fast mid-session crash recovery snapshot |
| `/whats-next` | Full session handoff |
| `/ask-me-questions` | Surface unknowns before starting |
| `/debug` | Systematic deep-analysis debugging |

### Reasoning frameworks (`/consider-*`)

Ten structured thinking lenses: `5-whys`, `10-10-10`, `eisenhower-matrix`, `first-principles`, `inversion`, `occams-razor`, `one-thing`, `opportunity-cost`, `pareto`, `second-order`, `swot`, `via-negativa`.

### Research (`/research-*`)

Structured research workflows: `competitive`, `deep-dive`, `feasibility`, `history`, `landscape`, `open-source`, `options`, `technical`.

### Workspace management

| Skill | Purpose |
|---|---|
| `/start` | Session orientation |
| `/review` | Pre-commit quality gate |
| `/audit` | Content health check |
| `/backlog` | Backlog management |
| `/validate` | Mark content as human-reviewed |
| `/cross-link` | Maintain cross-references |
| `/organize` | Repository structure audit |
| `/reference` | Personal reference library management |

### Skill authoring

| Skill | Purpose |
|---|---|
| `/create-agent-skill` | Create new AgentSkills-compliant SKILL.md files |
| `/improve-skill` | Improve an existing skill |
| `/audit-skill` | Audit a skill against best practices |
| `/create-plan` | Create hierarchical project plans |
| `/create-meta-prompt` | Build prompts for Claude-to-Claude pipelines |
| `/run-plan` | Execute a plan file |
| `/run-prompt` | Execute a prompt file |
| `/create-prompt` | Author a structured prompt |

### Research utilities

| Skill | Purpose |
|---|---|
| `/research-and-analyze` | YouTube transcript ingestion + systematic source analysis |
| `/youtube-transcript-library` | Narrow entry: fetch YouTube transcript and create library stub |

## Tool-specific skills

Skills using tool-specific primitives live outside this directory:

- `.claude/skills/` — Claude Code only: hooks, MCP servers, subagents
- `.cursor/agents/` — Cursor only: skill auditor, slash command auditor, subagent auditor
- `submodules/zanshin-pi-extension/skills/` — Pi / Copilot CLI: portable Zanshin discipline skills

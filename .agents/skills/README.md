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

These are workspace-specific skills — unique to this project.

### Session management

| Skill | Purpose |
|---|---|
| `/start` | Session orientation — load context, check handoffs, suggest focus |
| `/shoshin` | Invoked assumption-checking — collaborative questions, beginner's mind (extends zanshin kit) |
| `/craft` | Invoked engineering-principles review on code, diff, or design (extends zanshin kit) |
| `/whats-next` | Full session handoff — create comprehensive continuation doc |
| `/checkpoint` | Mid-session state save — lightweight crash recovery snapshot |
| `/review` | Pre-commit quality gate — verify against repo conventions |
### Quality & content governance

| Skill | Purpose |
|---|---|
| `/audit` | Content health check — links, registry alignment, cross-refs, freshness |
| `/audit-skill` | Audit a skill against AgentSkills best practices (scored report) |
| `/release-tags` | Tag and analyze day-based releases — backfill, diff, summarize sessions |
| `/validate` | Mark content as human-reviewed with specific validation types |
| `/cross-link` | Find and fix missing cross-links for a file or all new files |
| `/organize` | Repository structure audit — flag misplaced files, convention violations |

### Backlog & planning

| Skill | Purpose |
|---|---|
| `/backlog` | View, add, pick, complete, or review items in the project backlog |
| `/run-plan` | Execute a PLAN.md file directly (autonomous, segmented, or decision-dependent) |
| `/run-prompt` | Delegate prompts to fresh sub-task contexts (parallel or sequential) |

### Research

| Skill | Purpose |
|---|---|
| `/research-and-analyze` | YouTube transcript ingestion + systematic source analysis (gather/analyze/synthesize pipeline) |
| `/youtube-transcript-library` | Narrow entry: fetch YouTube transcript and create library stub |

### Library management

| Skill | Purpose |
|---|---|
| `/reference` | Add, search, or enrich entries in the personal reference library |

### Skill authoring

| Skill | Purpose |
|---|---|
| `/create-agent-skill` | Create new AgentSkills-compliant SKILL.md files |
| `/improve-skill` | Improve an existing skill's SKILL.md |

## Portable core reference — Zanshin kit

The [Zanshin working discipline kit](https://github.com/hhellbusch/zanshin-pi-extension) is the portable core of reasoning frameworks, adversarial review, and session discipline. It ships as a separate package:

- **Repo:** `submodules/zanshin-pi-extension/`
- **Kit docs:** `kit/WORKING-STYLE.md`, `kit/STYLE.md`
- **Skills:** `submodules/zanshin-pi-extension/skills/` (not copied into this workspace)

### Available in the kit (not duplicated here)

| Category | Skills |
|---|---|
| Working discipline | `/spar` · `/shoshin` · `/craft` · `/grill-me` · `/push` · `/pop` · `/stack` |
| Reasoning frameworks | `/consider-5-whys` · `/consider-10-10-10` · `/consider-first-principles` · `/consider-inversion` · `/consider-occams-razor` · `/consider-one-thing` · `/consider-opportunity-cost` · `/consider-pareto` · `/consider-second-order` · `/consider-swot` · `/consider-via-negativa` · `/consider-eisenhower-matrix` |
| Research | `/research-competitive` · `/research-deep-dive` · `/research-technical` · `/research-open-source` · `/research-options` · `/research-feasibility` · `/research-history` · `/research-landscape` |
| Debug & intake | `/debug` · `/ask-me-questions` |

To use zanshin-kit skills in this workspace:

```bash
# Add to Cursor / Claude Code / Copilot CLI
/skills add /path/to/zanshin-pi-extension/skills/
```

Or install as a Pi extension:

```bash
pi install git:git@github.com:hhellbusch/zanshin-pi-extension.git
```

## Tool-specific skills

Skills using tool-specific primitives live outside this directory:

- `.claude/skills/` — Claude Code only: hooks, MCP servers, subagents
- `.cursor/agents/` — Cursor only: skill auditor, slash command auditor, subagent auditor

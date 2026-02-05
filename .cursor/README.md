# TÂCHES Resources for Cursor

**Source:** [TÂCHES Claude Code Resources](https://github.com/glittercowboy/taches-cc-resources)  
**Platform:** Cursor IDE (Native Slash Commands + Skills)  
**Date:** February 3, 2026

## ✅ Cursor Native Support

This directory contains TÂCHES resources properly integrated with Cursor's native features:

- **Slash Commands** - `.cursor/commands/` → Auto-discovered by Cursor
- **Skills** - `.cursor/skills/` → Reference with `@.cursor/skills/`
- **Agents** - `.cursor/agents/` → Reference with `@.cursor/agents/`

## How to Use

### 1. Slash Commands (Native - Works Automatically!)

Cursor automatically discovers commands in `.cursor/commands/`. Use them like any built-in command:

```
/create-plan Build a REST API with authentication
/debug
/whats-next
/create-agent-skill Document our deployment process
```

**Thinking Frameworks:**
```
/consider:first-principles
/consider:5-whys
/consider:pareto
/consider:inversion
```

**Research Templates:**
```
/research:technical
/research:feasibility
/research:options
```

**Context Management:**
```
/whats-next
/add-to-todos
/check-todos
```

### 2. Skills (Reference with @)

Skills provide deep domain knowledge. Reference them to load methodologies:

```
@.cursor/skills/debug-like-expert/SKILL.md
@.cursor/skills/create-plans/SKILL.md
@.cursor/skills/create-agent-skills/SKILL.md
```

Then describe your task - I'll follow the skill's methodology.

### 3. Agents (Reference with @)

Agent guides provide evaluation checklists:

```
@.cursor/agents/skill-auditor.md
@.cursor/agents/slash-command-auditor.md
@.cursor/agents/subagent-auditor.md
```

## Directory Structure

```
.cursor/
├── README.md              # This file
├── commands/              # ✅ Auto-discovered as slash commands!
│   ├── create-plan.md
│   ├── debug.md
│   ├── whats-next.md
│   ├── create-agent-skill.md
│   ├── add-to-todos.md
│   ├── check-todos.md
│   ├── consider/          # Thinking frameworks
│   │   ├── first-principles.md
│   │   ├── 5-whys.md
│   │   ├── pareto.md
│   │   └── ... (12 frameworks)
│   └── research/          # Research templates
│       ├── technical.md
│       ├── feasibility.md
│       └── options.md
├── skills/                # Reference with @.cursor/skills/
│   ├── create-agent-skills/
│   ├── create-plans/
│   ├── create-meta-prompts/
│   ├── create-slash-commands/
│   ├── create-subagents/
│   ├── create-hooks/
│   ├── create-mcp-servers/
│   ├── debug-like-expert/
│   ├── setup-ralph/
│   └── expertise/
│       ├── iphone-apps/
│       ├── macos-apps/
│       └── n8n-automations/
└── agents/                # Reference with @.cursor/agents/
    ├── skill-auditor.md
    ├── slash-command-auditor.md
    └── subagent-auditor.md
```

## Quick Examples

### Example 1: Plan a Project (Slash Command)

```
/create-plan Ansible playbook for OpenShift cluster provisioning with HA control plane
```

**What happens:** Command automatically invokes the create-plans skill and guides you through planning.

### Example 2: Debug Systematically (Slash Command)

```
/debug

My pod keeps crashing with CrashLoopBackOff but logs don't show obvious errors.
```

**What happens:** Activates systematic debugging methodology.

### Example 3: Load a Skill Directly

```
@.cursor/skills/debug-like-expert/SKILL.md

[Describe your issue]
```

**What happens:** I load the full debugging methodology and apply it to your issue.

### Example 4: Think Through a Decision

```
/consider:first-principles

Should we migrate from manual certificate management to cert-manager?
```

**What happens:** I apply first-principles thinking framework.

## Available Slash Commands

### Project & Planning
- `/create-plan` - Create hierarchical project plans
- `/create-prompt` - Generate optimized prompts
- `/run-prompt` - Execute saved prompts

### Meta-Development
- `/create-agent-skill` - Create new skills
- `/create-slash-command` - Create new commands
- `/create-subagent` - Create specialized agents
- `/create-meta-prompt` - Create workflow prompts
- `/create-hook` - Create event hooks

### Debugging & Analysis
- `/debug` - Systematic debugging methodology

### Context Management
- `/whats-next` - Create handoff documents
- `/add-to-todos` - Capture tasks
- `/check-todos` - Review tasks

### Auditing
- `/audit-skill` - Audit skill files
- `/audit-slash-command` - Audit commands
- `/audit-subagent` - Audit agents
- `/heal-skill` - Fix skill issues

### Thinking Frameworks (12 total)
All accessible via `/consider:` prefix:
- `first-principles` - Break down to fundamentals
- `5-whys` - Drill to root cause
- `pareto` - Apply 80/20 rule
- `inversion` - Think backwards
- `second-order` - Consider consequences
- `occams-razor` - Find simplest explanation
- `one-thing` - Identify highest leverage
- `swot` - Strategic analysis
- `eisenhower-matrix` - Prioritize tasks
- `10-10-10` - Evaluate across time
- `opportunity-cost` - Analyze tradeoffs
- `via-negativa` - Improve by removing

## Key Skills Overview

### create-plans
**Purpose:** Hierarchical project planning  
**Command:** `/create-plan [description]`  
**Direct:** `@.cursor/skills/create-plans/SKILL.md`  
**Outputs:** BRIEF.md, ROADMAP.md, phase plans

### debug-like-expert
**Purpose:** Systematic debugging methodology  
**Command:** `/debug`  
**Direct:** `@.cursor/skills/debug-like-expert/SKILL.md`  
**Approach:** Evidence gathering, hypothesis testing, verification

### create-agent-skills
**Purpose:** Creating structured documentation  
**Command:** `/create-agent-skill [description]`  
**Direct:** `@.cursor/skills/create-agent-skills/SKILL.md`  
**Outputs:** SKILL.md files with workflows

### create-meta-prompts
**Purpose:** Building staged workflows  
**Command:** `/create-meta-prompt [description]`  
**Direct:** `@.cursor/skills/create-meta-prompts/SKILL.md`  
**Outputs:** Structured prompts

### create-mcp-servers
**Purpose:** Building MCP servers  
**Direct:** `@.cursor/skills/create-mcp-servers/SKILL.md`  
**Supports:** Python and TypeScript

## Integration with Your Work

### For Ansible Projects
```
/create-plan Ansible playbook for automated certificate renewal
```

### For OpenShift Troubleshooting
```
/debug

My OpenShift cluster has [describe issue]
```

### For Documentation
```
/create-agent-skill Document our cluster upgrade procedure
```

### For ArgoCD Configuration
```
/create-plan Multi-hub ArgoCD GitOps pipeline
```

## Comparison: Cursor vs Claude Code

| Feature | Claude Code | Cursor |
|---------|-------------|--------|
| **Commands** | ✅ `~/.claude/commands/` | ✅ `.cursor/commands/` |
| **Slash Syntax** | ✅ `/command` | ✅ `/command` |
| **Skills** | ✅ `Skill()` invocation | ⚠️ `@.cursor/skills/` |
| **Agents** | ✅ Spawn subagents | ⚠️ `@.cursor/agents/` |
| **Auto-discovery** | ✅ Yes | ✅ Yes (commands only) |

**Bottom line:** Commands work identically. Skills require `@` reference in Cursor.

## Tips for Effective Use

### 1. Use Slash Commands for Quick Actions

```
✅ Quick:
/create-plan Build a REST API

vs

❌ Slower:
@.cursor/skills/create-plans/SKILL.md
I need to plan a REST API
```

### 2. Load Skills for Deep Guidance

When you need the full methodology and context:

```
@.cursor/skills/debug-like-expert/SKILL.md
@.cursor/skills/debug-like-expert/references/hypothesis-testing.md

[Complex debugging scenario]
```

### 3. Combine Commands and Skills

```
/debug

[After initial debugging, load more context]
@.cursor/skills/debug-like-expert/references/verification-patterns.md
```

## Maintenance

Update from TÂCHES repository:

```bash
cd ~/gemini-workspace
git clone https://github.com/glittercowboy/taches-cc-resources.git .taches-update
cp -r .taches-update/commands/* .cursor/commands/
cp -r .taches-update/skills/* .cursor/skills/
cp -r .taches-update/agents/* .cursor/agents/
rm -rf .taches-update
```

## Resources

- **TÂCHES Repository:** https://github.com/glittercowboy/taches-cc-resources
- **TÂCHES YouTube:** youtube.com/tachesteaches
- **Cursor Docs:** https://cursor.com/docs/context/commands
- **Integration Plan:** `@TACHES-INTEGRATION-PLAN.md`

---

**Installation Date:** February 3, 2026  
**TÂCHES Version:** Latest from main branch  
**Platform:** Cursor IDE (Native Commands + Skill References)  
**Status:** ✅ Fully integrated with native slash command support

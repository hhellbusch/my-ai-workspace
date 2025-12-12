# Meta-Development System Integration Guide

This guide explains how to use and integrate the meta-development system consisting of **Skills**, **Commands**, and **Agents**.

## Table of Contents

- [System Overview](#system-overview)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Usage Patterns](#usage-patterns)
- [Creating New Components](#creating-new-components)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## System Overview

The meta-development system provides a structured approach to AI-assisted development through three interconnected layers:

```
┌─────────────────────────────────────────────┐
│  USER INTERFACE (Slash Commands)            │
│  /create-agent-skill, /audit-skill, etc.   │
└──────────────────┬──────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────┐
│  SKILL LAYER (Domain Expertise)             │
│  create-agent-skills, create-plans, etc.   │
└──────────────────┬──────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────┐
│  AGENT LAYER (Specialized Evaluation)       │
│  skill-auditor, slash-command-auditor, etc.│
└─────────────────────────────────────────────┘
```

### What Each Layer Does

**Commands** (`/commands`)
- User-facing entry points
- Simple, focused actions
- Pass arguments to skills or agents
- Example: `/create-agent-skill [description]`

**Skills** (`@skills`)
- Domain expertise modules
- Router pattern with workflows
- Progressive disclosure of knowledge
- Example: `create-agent-skills` skill with 10+ workflows

**Agents** (`@agents`)
- Specialized subagents
- Complex evaluation and auditing
- Independent execution context
- Example: `skill-auditor` for comprehensive skill evaluation

## Quick Start

### Using Existing Commands

Start using the system immediately with these commands:

```bash
# Create a new skill
/create-agent-skill [description of what the skill should do]

# Audit an existing skill
/audit-skill path/to/SKILL.md

# Create a project plan
/create-plan [what you want to build]

# Execute a plan
/run-plan path/to/PLAN.md

# Debug something
/debug

# Get next steps
/whats-next
```

### Example Workflow: Creating and Auditing a Skill

```bash
# Step 1: Create a new skill
/create-agent-skill Create a skill for managing Docker containers

# Step 2: Claude will invoke the create-agent-skills skill
# Follow the prompts to build your skill

# Step 3: Audit the created skill
/audit-skill skills/manage-docker/SKILL.md

# Step 4: Review audit findings and fix issues
# Claude will provide specific file:line locations and fixes

# Step 5: Re-audit to verify
/audit-skill skills/manage-docker/SKILL.md
```

## Architecture

### Skills Directory Structure

```
.cursor/skills/
├── create-agent-skills/       # Skill creation expertise
│   ├── SKILL.md              # Router + essential principles
│   ├── workflows/            # Step-by-step procedures
│   │   ├── create-new-skill.md
│   │   ├── audit-skill.md
│   │   └── upgrade-to-router.md
│   ├── references/           # Domain knowledge
│   │   ├── core-principles.md
│   │   ├── use-xml-tags.md
│   │   └── skill-structure.md
│   └── templates/            # Output structures
│       ├── simple-skill.md
│       └── router-skill.md
├── create-plans/             # Planning expertise
├── create-slash-.cursor/commands/    # Command creation
├── create-sub.cursor/agents/         # Agent creation
└── expertise/                # Domain-specific skills
    ├── iphone-apps/
    └── macos-apps/
```

### Commands Directory Structure

```
.cursor/commands/
├── create-agent-skill.md     # Invokes Skill(create-agent-skills)
├── audit-skill.md            # Invokes Agent(skill-auditor)
├── run-plan.md               # Executes PLAN.md files
├── whats-next.md             # Creates handoff documents
└── consider/                 # Thinking prompts
    └── *.md
```

### Agents Directory Structure

```
.cursor/agents/
├── skill-auditor.md          # Audits SKILL.md files
├── slash-command-auditor.md  # Audits command files
└── subagent-auditor.md       # Audits agent files
```

## Usage Patterns

### Pattern 1: Direct Skill Invocation

When you want to use a skill directly without a command wrapper:

```
User: I need to create a new skill for managing Kubernetes deployments

Claude: [Reads @skills/create-agent-skills/SKILL.md]
        What would you like to do?
        1. Create new skill
        2. Audit/modify existing skill
        ...

User: 1

Claude: [Follows workflows/create-new-skill.md]
        [Loads references/ as needed]
        [Creates the skill following the workflow]
```

### Pattern 2: Command-Based Invocation

When you want a quick, focused action:

```
User: /create-agent-skill Manage K8s deployments

Claude: [Reads .cursor/commands/create-agent-skill.md]
        [Invokes Skill(create-agent-skills) with arguments]
        [Executes workflow automatically]
```

### Pattern 3: Agent Evaluation

When you need comprehensive evaluation:

```
User: /audit-skill skills/manage-k8s/SKILL.md

Claude: [Reads .cursor/commands/audit-skill.md]
        [Spawns skill-auditor agent]
        [Agent reads best practices]
        [Agent evaluates skill]
        [Returns detailed audit report]
```

### Pattern 4: Planning and Execution

Multi-step planning workflow:

```
# Create a plan
User: /create-plan Build a REST API with authentication

Claude: [Creates .planning/ directory]
        [Creates BRIEF.md with requirements]
        [Creates ROADMAP.md with phases]
        [Creates phase-specific PLAN.md files]

# Execute a specific phase
User: /run-plan .planning/phases/01-setup/PLAN.md

Claude: [Reads execution context]
        [Executes tasks]
        [Creates SUMMARY.md]
        [Commits changes]
```

## Creating New Components

### Creating a New Skill

**Option 1: Use the meta-system (recommended)**

```bash
/create-agent-skill [skill description]
```

**Option 2: Manual creation**

1. Create directory: `skills/my-skill/`
2. Create `SKILL.md` with YAML frontmatter:

```yaml
---
name: my-skill
description: What it does and when to use it (third person)
---

<objective>What this skill accomplishes</objective>
<quick_start>Immediate actionable guidance</quick_start>
<process>Step-by-step procedure</process>
<success_criteria>How to know it worked</success_criteria>
```

3. Add workflows, references, templates as needed
4. Audit with: `/audit-skill skills/my-skill/SKILL.md`

### Creating a New Command

**Option 1: Use the meta-system (recommended)**

```bash
/create-slash-command [command description]
```

**Option 2: Manual creation**

1. Create file: `.cursor/commands/my-command.md`
2. Add YAML frontmatter and prompt:

```yaml
---
description: Clear, specific description of what the command does
argument-hint: [expected arguments format]
allowed-tools: Skill(skill-name) or Task or specific tools
---

Execute the following task with $ARGUMENTS:

[Clear, direct instructions]
```

3. Audit with: `/audit-slash-command .cursor/commands/my-command.md`

### Creating a New Agent

**Option 1: Use the meta-system (recommended)**

```bash
/create-subagent [agent description]
```

**Option 2: Manual creation**

1. Create file: `.cursor/agents/my-agent.md`
2. Add YAML frontmatter and structure:

```yaml
---
name: my-agent
description: What the agent does and when to use it
tools: Read, Grep, Glob
model: sonnet
---

<role>
Define the agent's expertise and purpose
</role>

<constraints>
- NEVER do X
- MUST always do Y
- ALWAYS verify Z
</constraints>

<critical_workflow>
1. Mandatory step 1
2. Mandatory step 2
3. Mandatory step 3
</critical_workflow>

<success_criteria>
Task is complete when:
- Criterion 1
- Criterion 2
- Criterion 3
</success_criteria>
```

3. Audit with: `/audit-subagent .cursor/agents/my-agent.md`

## Best Practices

### Skill Best Practices

**Structure:**
- Keep SKILL.md under 500 lines (router + principles only)
- Use pure XML structure (no markdown headings in body)
- Progressive disclosure: detailed content in references/
- Include required tags: `<objective>`, `<quick_start>`, `<success_criteria>`

**Content:**
- Only context Claude doesn't have
- Direct, specific instructions
- Concrete, minimal examples
- Clear routing logic

**Organization:**
- `workflows/` - Step-by-step procedures (FOLLOW)
- `references/` - Domain knowledge (READ)
- `templates/` - Output structures (COPY + FILL)
- `scripts/` - Reusable code (EXECUTE)

### Command Best Practices

**YAML Configuration:**
- Clear description (not "helps with" or vague terms)
- `argument-hint` when command uses arguments
- `allowed-tools` for security-sensitive operations

**Arguments:**
- Use `$ARGUMENTS` for simple pass-through
- Use `$1`, `$2`, `$3` for structured input
- Handle empty arguments gracefully

**Security:**
- Restrict tools for git operations: `allowed-tools: Bash(git *)`
- Restrict for read-only: `allowed-tools: Read`
- Restrict for analysis: `allowed-tools: [Read, Grep, Glob]`

**Dynamic Context:**
- Use `` !`git status` `` for git-aware commands
- Load state-dependent context with `!`command``

### Agent Best Practices

**Role Definition:**
- Specific expertise area
- Clear capabilities and limitations
- When to use this agent vs. others

**Constraints:**
- Strong modals: MUST, NEVER, ALWAYS
- Security constraints first
- Operational constraints second

**Workflows:**
- Mandatory steps clearly marked
- Validation at each stage
- Error handling and recovery

**Output:**
- Structured format for consistency
- Validation checklist before output
- Clear next-step options

## Troubleshooting

### Command Not Working

**Symptom:** Command doesn't execute or produces errors

**Solutions:**
1. Check YAML frontmatter syntax:
   ```yaml
   ---
   description: Must be valid YAML
   argument-hint: [format]
   ---
   ```

2. Verify skill/agent exists:
   ```bash
   # Check if skill exists
   ls skills/skill-name/SKILL.md
   
   # Check if agent exists
   ls .cursor/agents/agent-name.md
   ```

3. Audit the command:
   ```bash
   /audit-slash-command .cursor/commands/my-command.md
   ```

### Skill Not Loading References

**Symptom:** Skill doesn't have expected knowledge

**Solutions:**
1. Check routing logic in SKILL.md
2. Verify workflow specifies which references to load
3. Ensure reference files exist:
   ```bash
   ls skills/my-skill/references/
   ```

### Agent Not Reading Best Practices

**Symptom:** Agent audit doesn't follow expected standards

**Solutions:**
1. Check `<critical_workflow>` section specifies reading references
2. Verify reference paths are correct
3. Ensure agent has Read tool permission:
   ```yaml
   tools: Read, Grep, Glob
   ```

### Context Window Issues

**Symptom:** Running out of context when using skills

**Solutions:**
1. Use progressive disclosure - don't load all references at once
2. Let skill's router pattern control what gets loaded
3. Use workflows to specify minimal required context
4. Check SKILL.md is under 500 lines (move content to references/)

### Audit Returning Wrong Findings

**Symptom:** Audit flags issues that don't apply

**Solutions:**
1. Check contextual judgment in agent
2. Verify agent reads current best practices (not outdated patterns)
3. Ensure agent applies judgment based on complexity
4. Update agent's reference paths if best practices moved

## Integration with Cursor

### Referencing Skills in Prompts

```
# Direct reference
@skills/create-agent-skills/SKILL.md

# Invoke skill
Skill(create-agent-skills) [arguments]

# Reference specific workflow
@skills/create-agent-skills/workflows/create-new-skill.md

# Reference specific reference
@skills/create-agent-skills/references/core-principles.md
```

### Using Commands

```
# Basic command
/create-agent-skill [description]

# Command with arguments
/audit-skill skills/my-skill/SKILL.md

# Command without arguments
/debug
/whats-next
```

### Context Efficiency

The system is designed for optimal context usage:

```
Target Context Allocation:
├── System overhead: ~5-10%    (.cursorrules, command loading)
├── Skill context: ~10-20%     (SKILL.md + active workflow)
├── Domain context: ~10-20%    (references loaded by workflow)
└── Work context: ~60-70%      (actual codebase and implementation)
```

**Tips for maintaining efficiency:**
- Let routers control what loads (don't manually load everything)
- Use workflows to specify minimal required context
- Reference files rather than loading entire directories
- Use agents for complex tasks (they have independent context)

## Advanced Usage

### Chaining Commands

Create workflow sequences:

```bash
# 1. Create and immediately audit
/create-agent-skill [description]
# (wait for completion)
/audit-skill skills/new-skill/SKILL.md

# 2. Plan and execute
/create-plan [project description]
# (review plan)
/run-plan .planning/phases/01/PLAN.md

# 3. Debug and document
/debug
# (fix issue)
/whats-next
```

### Custom Skill Combinations

Combine skills for complex tasks:

```
User: Create a new iOS app skill with comprehensive testing

Claude: [Invokes create-agent-skills]
        [Creates skill structure]
        [References expertise/iphone-apps for patterns]
        [Adds testing workflows from references]
```

### Agent Orchestration

Use multiple agents for quality assurance:

```bash
# Audit all components of a new feature
/audit-skill skills/new-feature/SKILL.md
/audit-slash-command .cursor/commands/new-feature.md
# Fix issues
/audit-skill skills/new-feature/SKILL.md  # Verify fixes
```

## Contributing

### Adding to the System

When adding new components:

1. Use the meta-system to create them (dogfooding)
2. Audit before committing
3. Test with real usage
4. Update registries:
   - `.cursor/skills/REGISTRY.md`
   - `.cursor/commands/README.md`
   - `.cursor/.cursor/agents/REGISTRY.md`

### Quality Standards

All components must:
- Follow best practices (audit score shows compliance)
- Have clear, specific descriptions
- Include success criteria
- Be tested with real usage
- Have no critical audit findings

### Documentation

When creating new skills/.cursor/commands/agents:
- Add entry to appropriate registry
- Update `.cursorrules` if adding new patterns
- Add examples to this guide if introducing new usage patterns
- Include inline documentation in the component itself

## Resources

### Key Files

- `.cursorrules` - System configuration and integration
- `INTEGRATION.md` - This guide
- `.cursor/skills/REGISTRY.md` - Complete skill index
- `.cursor/commands/README.md` - Command reference
- `.cursor/.cursor/agents/REGISTRY.md` - Agent capabilities

### Best Practice References

- `skills/create-agent-skills/references/core-principles.md`
- `skills/create-agent-skills/references/skill-structure.md`
- `skills/create-slash-.cursor/commands/references/patterns.md`
- `skills/create-sub.cursor/agents/references/subagents.md`

### Example Components

- **Simple skill:** `skills/create-slash-.cursor/commands/SKILL.md`
- **Router skill:** `skills/create-agent-skills/SKILL.md`
- **Command:** `.cursor/commands/audit-skill.md`
- **Agent:** `.cursor/agents/skill-auditor.md`

## Support

If you encounter issues:

1. Use `/debug` for investigation guidance
2. Audit your components: `/audit-skill`, `/audit-slash-command`, `/audit-subagent`
3. Check this guide's Troubleshooting section
4. Review best practice references in skills/
5. Use `/whats-next` to create a detailed handoff if switching contexts




# Agents Registry

Specialized subagents for complex evaluation and auditing tasks.

## Overview

Agents are autonomous subagents with specific roles, constraints, and workflows. They operate independently with their own context and provide comprehensive evaluation and analysis.

### Agent Characteristics

- **Specialized expertise** - Focused on specific evaluation domain
- **Independent context** - Separate from main conversation context
- **Strong constraints** - Use MUST/NEVER/ALWAYS directives
- **Structured workflows** - Mandatory steps that can't be skipped
- **Validation before output** - Built-in quality checks
- **Actionable findings** - Specific, implementable recommendations

## Available Agents

### skill-auditor

**Path:** `agents/skill-auditor.md`

**Description:** Expert skill auditor for Claude Code Skills. Use when auditing, reviewing, or evaluating SKILL.md files for best practices compliance.

**Expertise Areas:**
- YAML frontmatter compliance (name, description)
- Pure XML structure (no markdown headings in body)
- Progressive disclosure patterns
- Required XML tags (objective, quick_start, success_criteria)
- Conditional XML tags (appropriate for complexity)
- Anti-patterns (markdown headings, hybrid XML/markdown)
- Contextual judgment based on skill type

**Tools:** Read, Grep, Glob

**Model:** Sonnet

**Workflow:**
1. Read best practices from `skills/create-agent-skills/references/`
2. Read the target skill file(s)
3. Evaluate against best practices (YAML, Structure, Content, Anti-patterns)
4. Apply contextual judgment (simple vs complex skills)
5. Generate severity-based findings (Critical, Recommendations, Quick Fixes)
6. Validate completeness before output

**Output Format:**
```markdown
## Audit Results: [skill-name]

### Assessment
[1-2 sentence overall assessment]

### Critical Issues
[Issues that hurt effectiveness or violate required patterns]

### Recommendations
[Improvements that would make skill better]

### Strengths
[What's working well]

### Quick Fixes
[Minor issues easily resolved]

### Context
- Skill type: [simple/complex/delegation]
- Line count: [number]
- Estimated effort: [low/medium/high]
```

**Invocation:**
```bash
/audit-skill path/to/SKILL.md
```

**Reference Documentation:**
- `skills/create-agent-skills/SKILL.md` - Overview
- `skills/create-agent-skills/references/use-xml-tags.md` - XML requirements
- `skills/create-agent-skills/references/skill-structure.md` - Structure patterns
- `skills/create-agent-skills/references/common-patterns.md` - Anti-patterns
- `skills/create-agent-skills/references/core-principles.md` - Core principles

**Use Cases:**
- Audit newly created skills
- Evaluate existing skills for migration to pure XML
- Check compliance before committing
- Identify anti-patterns in legacy skills
- Verify progressive disclosure structure

---

### slash-command-auditor

**Path:** `agents/slash-command-auditor.md`

**Description:** Expert slash command auditor for Claude Code slash commands. Use when auditing, reviewing, or evaluating slash command .md files for best practices compliance.

**Expertise Areas:**
- YAML configuration (description, allowed-tools, argument-hint)
- Argument usage ($ARGUMENTS, positional $1/$2/$3)
- Dynamic context loading (exclamation mark + backtick syntax)
- Tool restrictions (security patterns)
- File references (@ prefix usage)
- Multi-step workflow structure
- Security patterns

**Tools:** Read, Grep, Glob

**Model:** Sonnet

**Workflow:**
1. Read best practices from `skills/create-slash-commands/references/`
2. Read the target command file
3. Evaluate against best practices (YAML, Arguments, Dynamic Context, Tool Restrictions, Content)
4. Apply contextual judgment (simple vs state-dependent vs security-sensitive)
5. Generate severity-based findings
6. Validate completeness before output

**Output Format:**
```markdown
## Audit Results: [command-name]

### Assessment
[1-2 sentence overall assessment]

### Critical Issues
[Issues that hurt effectiveness or security]

### Recommendations
[Improvements that would make command better]

### Strengths
[What's working well]

### Quick Fixes
[Minor issues easily resolved]

### Context
- Command type: [simple/state-dependent/security-sensitive]
- Line count: [number]
- Security profile: [none/low/medium/high]
- Estimated effort: [low/medium/high]
```

**Invocation:**
```bash
/audit-slash-command commands/my-command.md
```

**Reference Documentation:**
- `skills/create-slash-commands/SKILL.md` - Overview
- `skills/create-slash-commands/references/arguments.md` - Argument patterns
- `skills/create-slash-commands/references/patterns.md` - Command patterns
- `skills/create-slash-commands/references/tool-restrictions.md` - Security patterns

**Use Cases:**
- Audit newly created commands
- Validate security-sensitive commands
- Check tool restriction appropriateness
- Verify argument handling correctness
- Ensure dynamic context for state-dependent commands

---

### subagent-auditor

**Path:** `agents/subagent-auditor.md`

**Description:** Expert subagent auditor for Claude Code subagents. Use when auditing, reviewing, or evaluating subagent .md files for best practices compliance.

**Expertise Areas:**
- YAML configuration (name, description, tools, model)
- Role definition (specific expertise, clear capabilities)
- Constraints (strength, coverage, security)
- Workflows (mandatory steps, validation, error handling)
- Success criteria (completeness, measurability)
- Output formats (structure, consistency)
- Error handling patterns

**Tools:** Read, Grep, Glob

**Model:** Sonnet

**Workflow:**
1. Read best practices from `skills/create-subagents/references/`
2. Read the target agent file
3. Evaluate against best practices (YAML, Role, Constraints, Workflow, Success Criteria)
4. Apply contextual judgment (evaluation vs task vs orchestration agents)
5. Generate severity-based findings
6. Validate completeness before output

**Output Format:**
```markdown
## Audit Results: [agent-name]

### Assessment
[1-2 sentence overall assessment]

### Critical Issues
[Issues that hurt effectiveness or reliability]

### Recommendations
[Improvements that would make agent better]

### Strengths
[What's working well]

### Quick Fixes
[Minor issues easily resolved]

### Context
- Agent type: [evaluation/task/orchestration]
- Line count: [number]
- Complexity: [simple/moderate/complex]
- Estimated effort: [low/medium/high]
```

**Invocation:**
```bash
/audit-subagent agents/my-agent.md
```

**Reference Documentation:**
- `skills/create-subagents/SKILL.md` - Overview
- `skills/create-subagents/references/subagents.md` - Subagent fundamentals
- `skills/create-subagents/references/writing-subagent-prompts.md` - Prompt structure
- `skills/create-subagents/references/orchestration-patterns.md` - Multi-agent patterns
- `skills/create-subagents/references/error-handling-and-recovery.md` - Error patterns

**Use Cases:**
- Audit newly created agents
- Validate agent constraints and workflows
- Check success criteria completeness
- Verify error handling coverage
- Ensure role definition clarity

---

## Agent Architecture

All agents follow this structure:

```yaml
---
name: agent-name
description: What the agent does and when to use it
tools: Read, Grep, Glob  # Specific tools needed
model: sonnet  # Model to use
---

<role>
Clear definition of agent's expertise and purpose
</role>

<constraints>
- NEVER do X (security constraints)
- MUST always do Y (mandatory operations)
- ALWAYS verify Z (quality gates)
</constraints>

<focus_areas>
Key areas the agent evaluates or focuses on
</focus_areas>

<critical_workflow>
**MANDATORY** steps that cannot be skipped:
1. Required step 1
2. Required step 2
3. Required step 3
</critical_workflow>

<evaluation_areas>
<area name="area1">
Check for:
- Thing 1
- Thing 2
</area>

<area name="area2">
Check for:
- Thing 3
- Thing 4
</area>
</evaluation_areas>

<contextual_judgment>
How to apply judgment based on context:
- Simple cases: [what to check]
- Complex cases: [what to check]
- Special cases: [what to check]
</contextual_judgment>

<output_format>
Template for agent output (markdown for readability)
</output_format>

<success_criteria>
Task is complete when:
- Criterion 1 met
- Criterion 2 met
- Criterion 3 met
</success_criteria>

<validation>
Before presenting output, verify:
- [ ] Completeness check 1
- [ ] Completeness check 2
- [ ] Accuracy check 1
- [ ] Quality check 1
</validation>

<final_step>
After presenting findings, offer:
1. Option 1 (e.g., implement all fixes)
2. Option 2 (e.g., show detailed examples)
3. Option 3 (e.g., focus on critical issues)
4. Other
</final_step>
```

## Agent Types

### Evaluation Agents

**Purpose:** Assess artifacts against standards

**Characteristics:**
- Read-only operations
- Compare against best practices
- Generate findings with severity
- Provide actionable recommendations

**Examples:**
- `skill-auditor` - Evaluates SKILL.md files
- `slash-command-auditor` - Evaluates command files
- `subagent-auditor` - Evaluates agent files

### Task Agents

**Purpose:** Execute specific tasks autonomously

**Characteristics:**
- Write operations allowed
- Specific objective
- Success criteria
- Error handling

**Examples:**
- (None currently in this workspace, but pattern supported)

### Orchestration Agents

**Purpose:** Coordinate multiple sub-tasks or agents

**Characteristics:**
- Spawn other agents
- Aggregate results
- Manage workflow
- Track progress

**Examples:**
- (None currently in this workspace, but pattern supported)

## Usage Patterns

### Direct Invocation

Via commands:
```bash
/audit-skill path/to/SKILL.md
/audit-slash-command commands/my-command.md
/audit-subagent agents/my-agent.md
```

### Programmatic Invocation

From skills or other agents:
```
Spawn subagent: skill-auditor
Arguments: path/to/SKILL.md
Wait for results
Process findings
```

## Best Practices

### Role Definition

**Clear expertise area:**
```yaml
<role>
You are an expert Claude Code Skills auditor. You evaluate SKILL.md 
files against best practices for structure, conciseness, progressive 
disclosure, and effectiveness.
</role>
```

### Strong Constraints

**Use strong modals:**
```yaml
<constraints>
- NEVER modify files during audit - ONLY analyze and report
- MUST read all reference documentation before evaluating
- ALWAYS provide file:line locations for every finding
</constraints>
```

### Mandatory Workflows

**Critical steps that can't be skipped:**
```yaml
<critical_workflow>
**MANDATORY**: Read best practices FIRST, before auditing:

1. Read @skills/create-agent-skills/SKILL.md for overview
2. Read @skills/create-agent-skills/references/use-xml-tags.md
3. Read the target skill file
4. Evaluate against best practices
</critical_workflow>
```

### Contextual Judgment

**Apply appropriate evaluation:**
```yaml
<contextual_judgment>
Apply judgment based on skill complexity:

**Simple skills** (single task, <100 lines):
- Required tags only is appropriate
- Minimal examples acceptable

**Complex skills** (multi-step, security concerns):
- Missing conditional tags is a real issue
- Comprehensive examples expected
</contextual_judgment>
```

### Validation Before Output

**Quality gates:**
```yaml
<validation>
Before presenting findings, verify:

**Completeness checks**:
- [ ] All evaluation areas assessed
- [ ] Findings have file:line locations

**Accuracy checks**:
- [ ] Line numbers verified
- [ ] Recommendations match complexity

**Quality checks**:
- [ ] Findings are actionable
- [ ] "Why it matters" explains impact
</validation>
```

## Quality Assurance

Agents can audit themselves:

```bash
# Audit the skill-auditor agent
/audit-subagent agents/skill-auditor.md

# Audit the slash-command-auditor agent
/audit-subagent agents/slash-command-auditor.md

# Audit the subagent-auditor agent (meta!)
/audit-subagent agents/subagent-auditor.md
```

## Contributing

To add a new agent:

1. Use `/create-subagent [description]`
2. Define clear role and constraints
3. Specify mandatory workflow
4. Add validation checklist
5. Audit with `/audit-subagent`
6. Test with real usage
7. Add entry to this registry
8. Update `.cursorrules` if needed

## Context Efficiency

Agents operate in independent context:

- **Main context** - Stays light, only orchestration
- **Agent context** - Loads full evaluation requirements
- **Result merging** - Only findings returned to main context

This allows comprehensive evaluation without bloating main context.

## References

- See `INTEGRATION.md` for integration guide
- See `.cursorrules` for system configuration
- See `skills/REGISTRY.md` for available skills
- See `commands/README.md` for available commands
- See `skills/create-subagents/references/subagents.md` for agent fundamentals



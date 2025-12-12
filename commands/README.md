# Commands Reference

User-facing slash commands that provide quick access to skills and agents.

## Command Categories

### Skill Creation & Management

#### /create-agent-skill
Create or edit Claude Code skills with expert guidance.

```bash
/create-agent-skill [skill description or requirements]
```

**What it does:**
- Invokes `Skill(create-agent-skills)`
- Provides router with options (create, audit, add component, guidance)
- Guides through skill creation workflow
- Follows best practices automatically

**Examples:**
```bash
/create-agent-skill Create a skill for managing Docker containers
/create-agent-skill Add testing capabilities to existing apps
```

---

#### /audit-skill
Audit skill for YAML compliance, pure XML structure, progressive disclosure, and best practices.

```bash
/audit-skill <skill-path>
```

**What it does:**
- Invokes `skill-auditor` agent
- Reads best practices from `skills/create-agent-skills/references/`
- Evaluates XML structure, required tags, anti-patterns
- Returns detailed findings with file:line locations

**Examples:**
```bash
/audit-skill skills/manage-docker/SKILL.md
/audit-skill skills/create-plans/SKILL.md
```

---

#### /heal-skill
Fix and improve problematic skills with intelligent repair strategies.

```bash
/heal-skill <skill-path>
```

**What it does:**
- Analyzes skill issues
- Suggests fixes for common problems
- Applies repairs with validation
- Re-audits after fixes

---

### Planning & Execution

#### /create-plan
Create hierarchical project plans for solo agentic development.

```bash
/create-plan [what to plan]
```

**What it does:**
- Invokes `Skill(create-plans)`
- Creates BRIEF.md, ROADMAP.md, phase plans
- Defines milestones and checkpoints
- Structures for intelligent execution

**Examples:**
```bash
/create-plan Build a REST API with authentication
/create-plan Refactor codebase to use dependency injection
```

---

#### /run-plan
Execute a PLAN.md file directly without loading planning skill context.

```bash
/run-plan <plan_path>
```

**What it does:**
- Verifies plan exists and is unexecuted
- Parses plan structure and checkpoints
- Determines execution strategy (autonomous, segmented, decision-dependent)
- Executes with optimal context usage
- Creates SUMMARY.md and commits

**Examples:**
```bash
/run-plan .planning/phases/01-setup/PLAN.md
/run-plan .planning/phases/02-api-implementation/02-01-PLAN.md
```

---

### Command & Agent Creation

#### /create-slash-command
Create a new slash command following best practices.

```bash
/create-slash-command [command description or requirements]
```

**What it does:**
- Invokes `Skill(create-slash-commands)`
- Guides through command creation
- Configures YAML frontmatter
- Sets up arguments and tool restrictions

**Examples:**
```bash
/create-slash-command Create a command to run all tests
/create-slash-command Git commit with conventional format
```

---

#### /audit-slash-command
Audit slash command for best practices compliance.

```bash
/audit-slash-command <command-path>
```

**What it does:**
- Invokes `slash-command-auditor` agent
- Evaluates YAML configuration
- Checks argument handling
- Validates tool restrictions
- Returns detailed findings

**Examples:**
```bash
/audit-slash-command commands/run-tests.md
/audit-slash-command commands/git-commit.md
```

---

#### /create-subagent
Create specialized Claude Code subagents.

```bash
/create-subagent [agent idea or description]
```

**What it does:**
- Invokes `Skill(create-subagents)`
- Defines agent role and constraints
- Sets up workflows and success criteria
- Configures tools and model

**Examples:**
```bash
/create-subagent Create an agent to analyze code complexity
/create-subagent Build an agent for security auditing
```

---

#### /audit-subagent
Audit subagent for best practices compliance.

```bash
/audit-subagent <agent-path>
```

**What it does:**
- Invokes `subagent-auditor` agent
- Evaluates role definition
- Checks constraints and workflows
- Validates success criteria
- Returns detailed findings

**Examples:**
```bash
/audit-subagent agents/code-complexity-analyzer.md
/audit-subagent agents/security-auditor.md
```

---

### Meta-Prompts & Hooks

#### /create-meta-prompt
Create meta-prompts for complex reasoning tasks.

```bash
/create-meta-prompt [description]
```

**What it does:**
- Invokes `Skill(create-meta-prompts)`
- Designs prompts for research, planning, refinement
- Implements question-driven approaches
- Structures for iterative improvement

---

#### /create-hook
Create Claude Code hooks with input/output schemas.

```bash
/create-hook [description]
```

**What it does:**
- Invokes `Skill(create-hooks)`
- Configures hook type (command/prompt)
- Defines matchers and schemas
- Sets up input/output handling

---

### Prompt Execution

#### /run-prompt
Execute a prompt file with specified context.

```bash
/run-prompt <prompt-path>
```

**What it does:**
- Loads and executes prompt file
- Handles context efficiently
- Tracks execution state
- Creates output artifacts

---

### Debugging & Analysis

#### /debug
Expert debugging guidance with hypothesis testing.

```bash
/debug
```

**What it does:**
- Invokes `Skill(debug-like-expert)`
- Provides debugging methodology
- Guides hypothesis formation
- Suggests investigation techniques
- Helps verify fixes

---

### Workflow Management

#### /check-todos
Review and manage TODO items.

```bash
/check-todos
```

**What it does:**
- Lists current TODO items
- Shows status (pending/in_progress/completed)
- Suggests next actions
- Helps prioritize work

---

#### /add-to-todos
Add items to TODO list.

```bash
/add-to-todos [task description]
```

**What it does:**
- Creates new TODO items
- Sets initial status
- Integrates with existing TODOs
- Preserves task context

---

#### /whats-next
Create handoff document for continuing work in fresh context.

```bash
/whats-next
```

**What it does:**
- Analyzes current conversation
- Documents completed work
- Lists remaining tasks
- Captures critical context
- Creates comprehensive handoff document

---

## Command Format

All commands follow this structure:

```yaml
---
description: Clear, specific description of what the command does
argument-hint: [expected arguments format]
allowed-tools: Skill(skill-name) or Task or specific tools
---

Command prompt body with $ARGUMENTS placeholders
```

### YAML Fields

**description** (required)
- Clear, specific action description
- No vague terms ("helps with", "processes")
- Third person POV

**argument-hint** (optional)
- Shows expected argument format
- Displayed in command autocomplete
- Examples: `[file-path]`, `[skill-name]`, `[what to plan]`

**allowed-tools** (optional)
- Restricts tools for security
- Examples:
  - `Skill(skill-name)` - Only invoke specific skill
  - `Task` - Can spawn subagents
  - `Read` - Read-only operations
  - `[Read, Grep, Glob]` - Multiple specific tools
  - `Bash(git *)` - Only git commands

### Argument Handling

**$ARGUMENTS** - Pass all arguments to skill/agent:
```yaml
Invoke the skill-name skill for: $ARGUMENTS
```

**Positional** - Use $1, $2, $3 for structured input:
```yaml
Execute task $1 on file $2 with options $3
```

**Mixed** - Combine with static text:
```yaml
Audit the skill at @$ARGUMENTS for compliance
```

### Dynamic Context

Load state-dependent information:

```yaml
Current git status:
!`git status`

Current directory:
!`pwd`

Environment info:
!`env | grep NODE`
```

## Usage Patterns

### Pattern 1: Direct Skill Invocation

Command delegates to skill, letting skill's router handle workflow:

```yaml
---
description: Create or edit Claude Code skills
argument-hint: [skill description]
allowed-tools: Skill(create-agent-skills)
---

Invoke the create-agent-skills skill for: $ARGUMENTS
```

### Pattern 2: Agent Spawning

Command spawns specialized agent for evaluation:

```yaml
---
description: Audit skill for best practices compliance
argument-hint: <skill-path>
---

<objective>
Invoke the skill-auditor subagent to audit the skill at $ARGUMENTS.
</objective>

<process>
1. Invoke skill-auditor subagent
2. Pass skill path: $ARGUMENTS
3. Review detailed findings
</process>
```

### Pattern 3: Direct Execution

Command executes task directly:

```yaml
---
description: Run all project tests
allowed-tools: Bash
---

Run the test suite:

1. Detect test framework (npm test, pytest, cargo test, etc.)
2. Execute tests with appropriate command
3. Report results with summary
```

### Pattern 4: Multi-Step Workflow

Command orchestrates complex workflow:

```yaml
---
description: Execute PLAN.md with intelligent segmentation
argument-hint: <plan-path>
---

Execute the plan at $ARGUMENTS using intelligent segmentation:

**Process:**
1. Verify plan exists
2. Parse structure and checkpoints
3. Determine execution strategy
4. Execute with optimal context
5. Create SUMMARY.md and commit
```

## Security Best Practices

### Tool Restrictions

**Git operations** - Restrict to git only:
```yaml
allowed-tools: Bash(git *)
```

**Read-only analysis** - No file modifications:
```yaml
allowed-tools: [Read, Grep, Glob]
```

**Thinking-only** - No tool access:
```yaml
allowed-tools: Think
```

**Specific skill** - Delegate to trusted skill:
```yaml
allowed-tools: Skill(skill-name)
```

### Argument Validation

Always validate arguments before use:
```yaml
1. Verify file exists: $ARGUMENTS
2. Check file is in expected location
3. Validate file format
4. Proceed with operation
```

## Quality Assurance

Audit commands before using:

```bash
/audit-slash-command commands/my-command.md
```

Audit checks:
- YAML configuration validity
- Argument handling correctness
- Tool restriction appropriateness
- Security patterns
- Clear instructions
- Dynamic context usage

## Contributing

To add a new command:

1. Use `/create-slash-command [description]`
2. Follow creation workflow
3. Audit with `/audit-slash-command`
4. Test with real usage
5. Add entry to this README
6. Update `.cursorrules` if needed

## References

- See `INTEGRATION.md` for integration guide
- See `.cursorrules` for system configuration
- See `skills/REGISTRY.md` for available skills
- See `agents/REGISTRY.md` for available agents
- See `skills/create-slash-commands/references/patterns.md` for command patterns




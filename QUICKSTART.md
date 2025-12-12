# Quick Start Guide

Get up and running with the meta-development system in minutes.

## First Steps

### 1. Verify System is Active

The system should be active in Cursor. Look for these indicators:

- `.cursorrules` file exists in workspace root
- Slash commands autocomplete when you type `/create-` or `/audit-`
- Skills are accessible via `@skills/` references

### 2. Test Basic Commands

Try these simple commands to verify everything works:

```bash
# Show available todos (empty initially)
/check-todos

# Get debugging guidance
/debug

# Create a handoff document
/whats-next
```

## Essential Workflows

### Workflow 1: Create and Audit a Simple Skill

**Goal:** Build a skill, audit it, and fix any issues.

**Steps:**

1. **Create the skill:**
   ```bash
   /create-agent-skill Create a skill that checks if Docker is running
   ```

2. **Follow the prompts:**
   - Select "1. Create new skill"
   - Choose "Task-execution skill"
   - Answer any clarifying questions

3. **Audit the created skill:**
   ```bash
   /audit-skill skills/check-docker-running/SKILL.md
   ```

4. **Review findings:**
   - Critical issues (must fix)
   - Recommendations (should fix)
   - Quick fixes (easy wins)

5. **Apply fixes** based on audit report

6. **Re-audit to verify:**
   ```bash
   /audit-skill skills/check-docker-running/SKILL.md
   ```

**Expected outcome:** A working skill with no critical audit findings.

---

### Workflow 2: Create a Project Plan

**Goal:** Plan a small project with hierarchical structure.

**Steps:**

1. **Describe what you want to build:**
   ```bash
   /create-plan Build a CLI tool that validates YAML files
   ```

2. **Review generated structure:**
   ```
   .planning/
   ├── BRIEF.md          # Project overview
   ├── ROADMAP.md        # Phases breakdown
   └── phases/
       ├── 01-setup/
       │   └── PLAN.md   # Detailed phase plan
       ├── 02-core/
       │   └── PLAN.md
       └── 03-polish/
           └── PLAN.md
   ```

3. **Review the BRIEF.md** - Ensure it captures your requirements

4. **Review ROADMAP.md** - Check phase breakdown makes sense

5. **Execute first phase:**
   ```bash
   /run-plan .planning/phases/01-setup/PLAN.md
   ```

6. **Check the SUMMARY.md** created after execution

**Expected outcome:** Structured project plan with executable phase plans.

---

### Workflow 3: Debug Systematically

**Goal:** Investigate an issue using expert debugging methodology.

**Steps:**

1. **Invoke debug mode:**
   ```bash
   /debug
   ```

2. **Describe the issue when prompted**

3. **Follow the debugging protocol:**
   - Gather evidence (error messages, logs, behavior)
   - Form hypotheses (what could cause this?)
   - Design experiments (how to test each hypothesis?)
   - Execute tests (run experiments)
   - Analyze results (what did we learn?)
   - Verify fix (ensure problem is resolved)

4. **Document findings** in issue tracker or notes

**Expected outcome:** Root cause identified and verified fix.

---

### Workflow 4: Create a Slash Command

**Goal:** Build a custom command for a specific task.

**Steps:**

1. **Create the command:**
   ```bash
   /create-slash-command Create a command that runs project tests with coverage
   ```

2. **Follow the prompts** to configure:
   - Description
   - Arguments (if needed)
   - Tool restrictions (security)
   - Command behavior

3. **Audit the command:**
   ```bash
   /audit-slash-command .cursor/commands/run-tests-coverage.md
   ```

4. **Test the command:**
   ```bash
   /run-tests-coverage
   ```

5. **Fix any issues** based on audit or testing

**Expected outcome:** Working slash command you can use repeatedly.

---

### Workflow 5: Manage Tasks with Todos

**Goal:** Capture tasks during work and resume them later.

**Steps:**

1. **While working, capture a task:**
   ```bash
   /add-to-todos Refactor authentication to use middleware pattern
   ```

2. **Continue current work** without losing context

3. **Later, check your todos:**
   ```bash
   /check-todos
   ```

4. **Select a todo to work on** and Claude will:
   - Load the captured context
   - Present the task details
   - Help you complete it

5. **Mark as complete** when done

**Expected outcome:** No lost ideas, seamless task switching.

---

### Workflow 6: Apply Thinking Frameworks

**Goal:** Use mental models to analyze decisions or problems.

**Steps:**

1. **Choose a framework** based on your situation:

   **For prioritization:**
   ```bash
   /consider:pareto         # 80/20 rule
   /consider:eisenhower-matrix  # Urgent vs Important
   ```

   **For decision making:**
   ```bash
   /consider:10-10-10       # Impact across time horizons
   /consider:opportunity-cost   # What you give up
   ```

   **For problem solving:**
   ```bash
   /consider:first-principles  # Break down to fundamentals
   /consider:5-whys         # Drill to root cause
   /consider:inversion      # What guarantees failure?
   ```

2. **Describe your situation** when prompted

3. **Review the analysis** Claude provides

4. **Make informed decision** based on framework insights

**Expected outcome:** Structured thinking applied to your challenge.

---

## Integration with DevOps Examples

The meta-development system enhances your DevOps work:

### Create Ansible Skills

```bash
# Create a skill for Ansible best practices
/create-agent-skill Expert guidance for Ansible playbook development

# Use it to review a playbook
Skill(ansible-best-practices) Review ansible-examples/9_global_defaults_across_roles/main_playbook.yml
```

### Plan ArgoCD Improvements

```bash
# Plan enhancements to ArgoCD setup
/create-plan Add monitoring and alerting to ArgoCD deployments

# Execute the plan
/run-plan .planning/phases/01-setup/PLAN.md
```

### Debug OpenShift Issues

```bash
# Systematic debugging
/debug

# Then describe your OCP issue:
"Control plane pods are crashlooping after upgrade"
```

### Document Troubleshooting Workflows

```bash
# Create a skill for common troubleshooting
/create-agent-skill OpenShift networking troubleshooting workflow

# Audit it
/audit-skill skills/ocp-networking-troubleshooting/SKILL.md
```

## Common Patterns

### Pattern 1: Build-Audit-Fix Loop

```bash
# Create something
/create-agent-skill [description]

# Audit it
/audit-skill skills/my-skill/SKILL.md

# Fix issues based on audit

# Re-audit
/audit-skill skills/my-skill/SKILL.md
```

### Pattern 2: Plan-Execute-Document

```bash
# Plan the work
/create-plan [project description]

# Execute phases
/run-plan .planning/phases/01/PLAN.md
/run-plan .planning/phases/02/PLAN.md

# Review summaries
cat .planning/phases/01/SUMMARY.md
cat .planning/phases/02/SUMMARY.md
```

### Pattern 3: Capture-Process-Complete

```bash
# During work, capture tasks
/add-to-todos Task 1
/add-to-todos Task 2

# Later, process them
/check-todos

# Work through each, marking complete
```

### Pattern 4: Debug-Document-Prevent

```bash
# Debug the issue
/debug

# Document in troubleshooting guide
# Add to ocp-troubleshooting/ or create new guide

# Create skill to prevent recurrence
/create-agent-skill Detect and prevent [specific issue pattern]
```

## Tips for Success

### 1. Start Small

Begin with simple skills and commands before building complex ones:
- ✅ Simple skill: Check if service is running
- ❌ Complex skill: Full CI/CD orchestration

### 2. Use Progressive Disclosure

Skills load content progressively. Let the router guide you:
- Don't manually load all references
- Answer the router's questions
- Let workflows specify what to load

### 3. Audit Early and Often

Catch issues early:
```bash
# After creating anything
/audit-skill skills/my-skill/SKILL.md
/audit-slash-command .cursor/commands/my-command.md
/audit-subagent .cursor/agents/my-agent.md
```

### 4. Test with Real Usage

After creating a skill/command:
- Use it on a real task
- Note what works and what doesn't
- Refine based on actual usage

### 5. Keep Context Efficient

The system is designed for minimal context usage:
- SKILL.md should be < 500 lines
- Use references for detailed content
- Let routers control what loads

### 6. Leverage Existing Skills

Before creating new skills, check if existing ones help:
```bash
# For iOS/macOS development
Skill(expertise/iphone-apps)
Skill(expertise/macos-apps)

# For planning
Skill(create-plans)

# For debugging
Skill(debug-like-expert)
```

## Troubleshooting

### Commands Not Working

**Issue:** Slash commands don't autocomplete or execute

**Solutions:**
1. Verify `.cursorrules` exists in workspace root
2. Restart Cursor
3. Check command file syntax (YAML frontmatter)
4. Audit the command: `/audit-slash-command .cursor/commands/my-command.md`

### Skills Not Loading

**Issue:** Skill references don't work

**Solutions:**
1. Verify path: `@skills/skill-name/SKILL.md`
2. Check SKILL.md exists and has valid YAML
3. Audit the skill: `/audit-skill skills/skill-name/SKILL.md`

### Context Window Issues

**Issue:** Running out of context during complex operations

**Solutions:**
1. Use `/whats-next` to create handoff
2. Start fresh context with handoff document
3. Break work into smaller chunks
4. Use `/run-plan` for autonomous execution (uses separate context)

### Audit Reports Unclear

**Issue:** Not sure how to fix audit findings

**Solutions:**
1. Ask Claude to show examples for specific findings
2. Reference best practices:
   - `@skills/create-agent-skills/references/core-principles.md`
   - `@skills/create-slash-.cursor/commands/references/patterns.md`
3. Use `/heal-skill` to auto-fix common issues

## Next Steps

Now that you're familiar with the basics:

1. **Explore the registries:**
   - [skills/REGISTRY.md](skills/REGISTRY.md) - All available skills
   - [.cursor/commands/README.md](.cursor/commands/README.md) - All available commands
   - [.cursor/agents/REGISTRY.md](.cursor/agents/REGISTRY.md) - All available agents

2. **Read the full integration guide:**
   - [INTEGRATION.md](INTEGRATION.md) - Comprehensive documentation

3. **Review best practices:**
   - `@skills/create-agent-skills/references/core-principles.md`
   - `@skills/create-agent-skills/references/use-xml-tags.md`
   - `@skills/create-slash-.cursor/commands/references/patterns.md`

4. **Build your first skill:**
   - Start with something simple from your domain
   - Use `/create-agent-skill` to build it
   - Audit and refine it
   - Use it in real work

5. **Plan your next project:**
   - Use `/create-plan` to structure it
   - Execute phases with `/run-plan`
   - Document outcomes in SUMMARY.md files

## Getting Help

If you get stuck:

1. **Use the debug skill:**
   ```bash
   /debug
   ```

2. **Create a handoff document:**
   ```bash
   /whats-next
   ```
   Then share it or use it to continue in fresh context

3. **Reference documentation:**
   - [INTEGRATION.md](INTEGRATION.md) - Full guide
   - [TÂCHES Repository](https://github.com/glittercowboy/taches-cc-resources) - Original source

4. **Audit your components:**
   - Auditors provide specific, actionable feedback
   - Follow their recommendations

Happy building! 🚀




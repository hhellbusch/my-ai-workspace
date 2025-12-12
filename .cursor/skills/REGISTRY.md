# Skills Registry

Complete index of all available skills in the meta-development system.

## Meta-Development Skills

Skills for creating and managing the meta-development system itself.

### create-agent-skills

**Path:** `skills/create-agent-skills/`

**Description:** Expert guidance for creating, writing, building, and refining Claude Code Skills. Use when working with SKILL.md files, authoring new skills, improving existing skills, or understanding skill structure and best practices.

**Use Cases:**
- Create a new skill from scratch
- Audit existing skill for best practices
- Add workflows, references, templates, or scripts to a skill
- Upgrade simple skill to router pattern
- Get guidance on skill structure

**Key Workflows:**
- `workflows/create-new-skill.md` - Build a skill from scratch
- `workflows/audit-skill.md` - Analyze skill against best practices
- `workflows/upgrade-to-router.md` - Convert to router pattern
- `workflows/add-workflow.md` - Add workflow to existing skill
- `workflows/add-reference.md` - Add reference to existing skill

**Key References:**
- `references/core-principles.md` - Fundamental principles
- `references/skill-structure.md` - Structure and organization
- `references/use-xml-tags.md` - XML tag requirements
- `references/common-patterns.md` - Patterns and anti-patterns

**Invocation:** 
- `/create-agent-skill [description]`
- `Skill(create-agent-skills)`
- `@skills/create-agent-skills/SKILL.md`

---

### create-plans

**Path:** `skills/create-plans/`

**Description:** Create hierarchical project plans for solo agentic development including briefs, roadmaps, and phase plans with intelligent execution strategies.

**Use Cases:**
- Create comprehensive project plans
- Break down large projects into phases
- Define milestones and checkpoints
- Execute plans with segmentation
- Track progress and create summaries

**Key Workflows:**
- `workflows/create-brief.md` - Create project BRIEF.md
- `workflows/create-roadmap.md` - Create phase ROADMAP.md
- `workflows/plan-phase.md` - Plan a specific phase
- `workflows/execute-phase.md` - Execute a phase plan
- `workflows/complete-milestone.md` - Complete and document milestone

**Key References:**
- `references/plan-format.md` - Plan file structure
- `references/checkpoints.md` - Checkpoint types and usage
- `references/hierarchy-rules.md` - Brief→Roadmap→Phase hierarchy
- `references/context-management.md` - Efficient context usage

**Templates:**
- `templates/brief.md` - Project brief template
- `templates/roadmap.md` - Roadmap template
- `templates/milestone.md` - Milestone template
- `templates/summary.md` - Execution summary template

**Invocation:**
- `/create-plan [project description]`
- `Skill(create-plans)`
- `@skills/create-plans/SKILL.md`

---

### create-meta-prompts

**Path:** `skills/create-meta-prompts/`

**Description:** Create meta-prompts for complex reasoning, research, planning, and refinement tasks with intelligent question-driven approaches.

**Use Cases:**
- Create research prompts for investigation
- Build planning prompts for complex projects
- Design refinement prompts for iterative improvement
- Develop question-driven exploration prompts

**Key References:**
- `references/research-patterns.md` - Research prompt patterns
- `references/plan-patterns.md` - Planning prompt patterns
- `references/refine-patterns.md` - Refinement patterns
- `references/question-bank.md` - Question templates
- `references/intelligence-rules.md` - Intelligence routing

**Invocation:**
- `/create-meta-prompt [description]`
- `Skill(create-meta-prompts)`
- `@skills/create-meta-prompts/SKILL.md`

---

### create-slash-commands

**Path:** `skills/create-slash-commands/`

**Description:** Create new slash commands following best practices including YAML configuration, argument handling, tool restrictions, and security patterns.

**Use Cases:**
- Create user-facing slash commands
- Configure tool restrictions
- Handle arguments properly
- Add dynamic context loading
- Implement security patterns

**Key References:**
- `references/arguments.md` - Argument patterns and handling
- `references/patterns.md` - Common command patterns
- `references/tool-restrictions.md` - Security and tool restriction patterns

**Invocation:**
- `/create-slash-command [description]`
- `Skill(create-slash-commands)`
- `@skills/create-slash-commands/SKILL.md`

---

### create-subagents

**Path:** `skills/create-subagents/`

**Description:** Create specialized Claude Code subagents with expert guidance on roles, constraints, workflows, and orchestration patterns.

**Use Cases:**
- Create evaluation agents
- Build specialized task agents
- Define agent roles and constraints
- Implement error handling
- Set up orchestration patterns

**Key References:**
- `references/subagents.md` - Subagent fundamentals
- `references/writing-subagent-prompts.md` - Prompt structure
- `references/orchestration-patterns.md` - Multi-agent patterns
- `references/error-handling-and-recovery.md` - Error patterns
- `references/evaluation-and-testing.md` - Testing strategies

**Invocation:**
- `/create-subagent [description]`
- `Skill(create-subagents)`
- `@skills/create-subagents/SKILL.md`

---

### create-hooks

**Path:** `skills/create-hooks/`

**Description:** Create Claude Code hooks with input/output schemas, matchers, and proper hook type configuration.

**Use Cases:**
- Create command hooks
- Build prompt hooks
- Define input/output schemas
- Configure matchers
- Troubleshoot hook issues

**Key References:**
- `references/hook-types.md` - Command vs prompt hooks
- `references/matchers.md` - Matcher configuration
- `references/input-output-schemas.md` - Schema definition
- `references/examples.md` - Hook examples
- `references/troubleshooting.md` - Common issues

**Invocation:**
- `/create-hook [description]`
- `Skill(create-hooks)`
- `@skills/create-hooks/SKILL.md`

---

## Domain Expertise Skills

Skills providing deep domain knowledge for specific technical areas.

### debug-like-expert

**Path:** `skills/debug-like-expert/`

**Description:** Expert-level debugging methodology including hypothesis testing, investigation techniques, and verification patterns.

**Use Cases:**
- Debug complex issues
- Form and test hypotheses
- Investigate root causes
- Verify fixes
- Decide when to research

**Key References:**
- `references/debugging-mindset.md` - Debugging approach
- `references/hypothesis-testing.md` - Scientific debugging
- `references/investigation-techniques.md` - Investigation methods
- `references/verification-patterns.md` - Fix verification
- `references/when-to-research.md` - When to seek external info

**Invocation:**
- `/debug`
- `Skill(debug-like-expert)`
- `@skills/debug-like-expert/SKILL.md`

---

### expertise/iphone-apps

**Path:** `skills/expertise/iphone-apps/`

**Description:** Comprehensive iOS/iPhone app development expertise with SwiftUI, UIKit, App Store, testing, performance, and deployment.

**Use Cases:**
- Build new iPhone apps
- Add features to existing apps
- Debug iOS issues
- Optimize performance
- Ship to App Store
- Write tests

**Key Workflows:**
- `workflows/build-new-app.md` - Create new iOS app
- `workflows/add-feature.md` - Add feature to existing app
- `workflows/debug-app.md` - Debug iOS issues
- `workflows/optimize-performance.md` - Performance optimization
- `workflows/ship-app.md` - App Store submission
- `workflows/write-tests.md` - Testing strategies

**Key References:**
- `references/swiftui-patterns.md` - SwiftUI best practices
- `references/app-architecture.md` - Architecture patterns
- `references/networking.md` - API and networking
- `references/data-persistence.md` - CoreData, UserDefaults
- `references/app-store.md` - App Store submission
- `references/testing.md` - Unit, UI, integration tests
- `references/performance.md` - Performance optimization

**Invocation:**
- `Skill(expertise/iphone-apps)`
- `@skills/expertise/iphone-apps/SKILL.md`

---

### expertise/macos-apps

**Path:** `skills/expertise/macos-apps/`

**Description:** Comprehensive macOS app development expertise with AppKit, SwiftUI, Mac App Store, sandboxing, and macOS-specific patterns.

**Use Cases:**
- Build new macOS apps
- Add features to existing apps
- Debug macOS issues
- Handle sandboxing
- Ship to Mac App Store
- Implement menu bar apps

**Key Workflows:**
- `workflows/build-new-app.md` - Create new macOS app
- `workflows/add-feature.md` - Add feature to existing app
- `workflows/debug-app.md` - Debug macOS issues
- `workflows/optimize-performance.md` - Performance optimization
- `workflows/ship-app.md` - Mac App Store submission
- `workflows/write-tests.md` - Testing strategies

**Invocation:**
- `Skill(expertise/macos-apps)`
- `@skills/expertise/macos-apps/SKILL.md`

---

## Skill Organization Principles

### Simple Skills

Single-file skills for focused tasks:
- `SKILL.md` only
- Under 200 lines
- Direct execution
- Examples: Most commands delegate to these

### Router Skills

Complex skills with workflows and references:
- `SKILL.md` = router + essential principles
- `workflows/` = step-by-step procedures
- `references/` = domain knowledge
- `templates/` = output structures
- `scripts/` = executable code
- Examples: `create-agent-skills`, `create-plans`

### Expertise Skills

Domain-specific knowledge bases:
- Comprehensive coverage of a domain
- Multiple workflows for different scenarios
- Extensive reference library
- Examples: `expertise/iphone-apps`, `expertise/macos-apps`

## Usage Patterns

### Direct Invocation

```
Skill(skill-name) [optional arguments]
```

Use when you want to interact with the skill's router and choose workflows.

### File Reference

```
@skills/skill-name/SKILL.md
@skills/skill-name/workflows/workflow-name.md
@skills/skill-name/references/reference-name.md
```

Use when you want to load specific content without invoking the skill.

### Command Invocation

```
/command-name [arguments]
```

Use when you want a quick, focused action that delegates to a skill.

## Progressive Disclosure

Skills are designed for progressive disclosure:

1. **SKILL.md** loads first (router + essential principles)
2. **Workflow** loads based on user selection
3. **References** load as specified by workflow
4. **Templates/Scripts** load only when needed

This keeps context usage minimal while providing comprehensive expertise.

## Quality Assurance

All skills can be audited:

```bash
/audit-skill skills/skill-name/SKILL.md
```

Audit checks:
- YAML compliance
- XML structure (pure, no markdown headings)
- Progressive disclosure
- Required tags present
- Anti-patterns flagged
- Contextual appropriateness

## Contributing

To add a new skill:

1. Use `/create-agent-skill [description]`
2. Follow the creation workflow
3. Audit with `/audit-skill`
4. Add entry to this registry
5. Update `.cursorrules` if needed
6. Test with real usage

## References

- See `INTEGRATION.md` for integration guide
- See `.cursorrules` for system configuration
- See `commands/README.md` for available commands
- See `agents/REGISTRY.md` for available agents



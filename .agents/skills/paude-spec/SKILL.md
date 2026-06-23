---
name: paude-spec
description: Write a task spec file for a paude container agent. Use when delegating
  work to paude, preparing a paude prompt-file, writing fire-and-forget agent tasks,
  or scoping submodule work for harvest.
argument-hint: "[--project <name>] [--slug <slug>] [--output <absolute-path>]"
allowed-tools: Read Write Shell Glob Grep
---

# Paude Spec

<objective>
Produce a task spec that a container agent can execute autonomously and hand off for harvest without ambiguous commits or wrong submodule discipline.
</objective>

<essential_principles>

- Spec states **outcomes**, not step-by-step implementation (unless safety-critical).
- Every spec names `session-name`, `harvest/<slug>`, and repos likely touched.
- Spec ends with harvest-prep instructions — uncommitted work is lost.
- Use absolute output paths when the spec will be passed to `--prompt-file`.

</essential_principles>

<context>
- Template: `templates/task-spec.md`
- Harvest prep (for container): `templates/harvest-prep-prompt.md`
- Also copied to: `devops/paude/harvest-prep-prompt.md` for human visibility
- Launch: `.agents/skills/paude-launch/SKILL.md`
- Planning specs: `.planning/paude-integration/task-specs/`
</context>

<process>

### 1. Gather intent

From conversation and `$ARGUMENTS`:

- Task goal and boundaries
- `--project <name>` — planning directory (default: infer or `paude-integration`)
- `--slug <slug>` — kebab-case task id
- `--output <path>` — override default path

If scope is unclear, ask one sharp question before writing.

### 2. Choose output path

Default:

```text
.planning/<project>/task-specs/<slug>.md
```

### 3. Write spec

Copy structure from `templates/task-spec.md`. Fill all sections.

Required fields:

- Session name (match planned `paude create` name)
- Harvest branch `harvest/<slug>`
- Repos table
- Commit discipline block
- "When finished" → harvest prep template reference

### 4. Copy harvest-prep for visibility

Ensure `devops/paude/harvest-prep-prompt.md` exists and matches `templates/harvest-prep-prompt.md` (update if drift).

### 5. Present to user

Show path and suggest:

```bash
paude-launch <session-name> --slug <slug> --spec <absolute-path>
```

</process>

<success_criteria>
- Spec file exists at agreed path
- Session name and harvest branch are explicit
- Submodule defaults and no-push rule included
- User has launch command with absolute spec path
</success_criteria>

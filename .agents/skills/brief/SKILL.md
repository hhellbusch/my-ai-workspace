---
name: brief
description: Create or update a project BRIEF.md — scaffolds planning structure for work that crosses the 5-file / multi-session threshold
argument-hint: "[project-name]"
allowed-tools: Read Write Shell Glob
---

# Brief — Project Scaffold

<objective>
Create a BRIEF.md and initial whats-next.md for work that has crossed the
project threshold (5+ files, multi-session, new directory, or scope expansion).
The brief is the authoritative scope anchor. Handoff files reference it; they
don't replace it.
</objective>

## When to invoke

- Agent detects 5+ files modified in a session with no BRIEF
- Work has been compacted across sessions and no BRIEF exists
- User explicitly asks to create a project brief
- `/start` flags a brief gap for active work

## Process

### 1. Determine project name

If `$ARGUMENTS` is provided, use it as the project name (slug format: `kebab-case`).

If not provided:
- Look at recent git commits and modified files to infer the work area
- Propose a name: "This looks like `gpu-vgpu-gitops` work — use that name, or suggest one?"
- Wait for confirmation before creating directories

### 2. Check for existing brief

```bash
ls .planning/<project-name>/ 2>/dev/null
```

If a BRIEF already exists, read it and ask: "A brief already exists — update it or start fresh?"

### 3. Gather context

Before writing, collect:
- Recent commits touching this work: `git log --oneline -10 -- <relevant paths>`
- Files modified this session (from conversation context or git status)
- Any decisions or constraints already surfaced in conversation

Do not ask the user for information you can derive from the repo.

### 4. Scaffold the brief

Create `.planning/<project-name>/BRIEF.md`:

```markdown
# <Project Name>

> **Status:** In Progress
> **Started:** <date>
> **Owner:** <from ABOUT.md if available>

## Audience and Purpose

**Reader:** [Who reads this brief — role or person]
**Enables:** [What decision or scope boundary this anchors]

## Problem Statement

[One paragraph — what problem is this work solving and why now?]

## Scope

[What's in. Be specific about boundaries.]

**Out of scope:** [What's explicitly excluded — prevents scope creep]

## Success Criteria

- [ ] [Concrete, checkable outcome]
- [ ] [Concrete, checkable outcome]

## Constraints

- [Hard constraints: hardware, versions, patterns already established]

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| [topic]  | [what was decided] | [why] |

## Related

- [Links to key files, runbooks, research]
```

### 5. Create initial whats-next.md

Create `.planning/<project-name>/whats-next.md` with a stub:

```markdown
# Checkpoint — <date>

**In progress:** [current task]
**Just completed:** [what landed before this brief was created — from git log]
**Next step:** [immediate next action]
**Git:** `<HEAD commit hash and message>`
```

### 6. Commit

```bash
git add .planning/<project-name>/
git commit -m "chore(planning): create <project-name> project brief"
```

### 7. Surface the brief gap if invoked automatically

If this skill was invoked because a brief gap was detected (not by explicit user request), after creating the brief say:

> "Brief created at `.planning/<project-name>/BRIEF.md`. I'll use this as the scope anchor going forward — handoffs will reference it rather than carrying all context themselves."

## What makes a good brief

- **Audience and purpose** answer TAGRI — who reads it, what it enables
- **Problem statement** answers *why*, not *what*
- **Success criteria** are checkable — avoid "improve" or "better"
- **Key decisions** capture the things most likely to be re-litigated
- **Out of scope** prevents the brief from expanding to cover everything

## What to skip

- Don't reproduce file contents in the brief — link to them
- Don't list every task — that's the backlog's job
- Don't write the brief in the user's voice — factual and terse

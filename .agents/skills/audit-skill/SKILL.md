---
name: audit-skill
description: Audit a skill's SKILL.md for AgentSkills compliance — YAML frontmatter,
  XML structure, progressive disclosure, routing, and content quality. Provides a
  scored report with specific fixes.
argument-hint: "<skill-path>"
allowed-tools: Read Shell Glob Grep Write StrReplace
---

<objective>
Read and evaluate the skill at $ARGUMENTS against AgentSkills best practices. Produce a scored audit report with specific, actionable fixes. Offer to apply fixes after the report.
</objective>

<process>

### Step 1: Locate the skill

If $ARGUMENTS is a path, use it directly. If empty, list available skills and ask:

```bash
ls .agents/skills/ 2>/dev/null || ls ~/.claude/skills/ 2>/dev/null
```

### Step 2: Read the full skill structure

```bash
cat <skill-path>/SKILL.md
ls <skill-path>/
ls <skill-path>/workflows/ 2>/dev/null
ls <skill-path>/references/ 2>/dev/null
ls <skill-path>/templates/ 2>/dev/null
ls <skill-path>/scripts/ 2>/dev/null
```

Read referenced workflow and reference files if they exist.

### Step 3: Evaluate against the checklist

**YAML Frontmatter**
- [ ] Has `name:` field (lowercase-with-hyphens only, no underscores or uppercase)
- [ ] `name` matches the directory name exactly
- [ ] Has `description:` field
- [ ] Description says what it does AND when to use it
- [ ] Description is written in third person ("Use when...")

**Structure**
- [ ] SKILL.md under 500 lines
- [ ] Body uses pure XML tags — no markdown headings (`#`, `##`, `###`) in the body
- [ ] All XML tags properly closed
- [ ] Has `<objective>` or `<essential_principles>` (at least one)
- [ ] Has `<success_criteria>`

**Router pattern (for complex skills with workflows/)**
- [ ] Essential principles are inline in SKILL.md (not hidden in a reference file)
- [ ] Has `<intake>` question
- [ ] Has `<routing>` table mapping responses to workflows
- [ ] All referenced workflow files actually exist on disk
- [ ] All referenced reference files actually exist on disk

**Workflows (if `workflows/` dir exists)**
- [ ] Each workflow has `<required_reading>` section
- [ ] Each workflow has `<process>` section
- [ ] Each workflow has `<success_criteria>` section
- [ ] Files listed in `<required_reading>` actually exist

**Content quality**
- [ ] Steps are specific — not "handle the error appropriately" or "do the thing"
- [ ] Success criteria are verifiable — not "user is satisfied"
- [ ] No redundant content duplicated across files
- [ ] Principles are actionable, not vague platitudes

### Step 4: Generate the report

```
## Audit Report: {skill-name}

### ✅ Passing
- [list each passing item]

### ⚠️ Issues Found
1. **[Issue name]** — [Description]
   → Fix: [Specific action, file and line if applicable]

### Score: X/Y criteria passing
```

**Common anti-patterns to flag:**
- Essential principles in a separate file instead of inline in SKILL.md (skippable by the agent)
- Single SKILL.md over 500 lines (monolithic — split into router + references)
- Procedures and knowledge mixed in one file (mixed concerns)
- `#` headings in the body instead of XML tags
- Complex skill with no intake/routing
- Files mentioned in SKILL.md that don't exist on disk (broken references)
- Same content in multiple files (redundancy)

### Step 5: Offer fixes

If issues found:

```
Would you like me to fix these issues?

1. Fix all — apply all recommended fixes
2. Fix one by one — review each fix before applying
3. Just the report — no changes needed
```

Apply fixes if requested. Read back changed sections to verify.

</process>

<success_criteria>
- Skill fully read including all referenced files
- All checklist items evaluated with pass/fail
- Report presented with score and specific fix instructions
- Fixes applied if requested and verified by reading back
</success_criteria>

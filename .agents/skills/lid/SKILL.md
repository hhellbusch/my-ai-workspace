---
name: lid
description: Linked-Intent Development — scale change discipline to scope (touch/change/restructure)
argument-hint: "[touch | change | restructure | cascade | spar]"
allowed-tools: Read Write StrReplace Shell
---

# LID — Linked-Intent Development

<objective>
Scale change discipline to scope. When intent and implementation disagree, intent wins — fix the change or deliberately update the intent and cascade.
</objective>

<context>
- LID workflow (full): `submodules/lid-pi-extension/kit/LID-WORKFLOW.md`
- Intent template: `submodules/lid-pi-extension/kit/templates/INTENT.md`
- Design note template: `submodules/lid-pi-extension/kit/templates/DESIGN-NOTE.md`
- Acceptance criteria template: `submodules/lid-pi-extension/kit/templates/ACCEPTANCE.md`
- Planning directory: `.planning/`
- Current date: `date "+%Y-%m-%d"`
</context>

<process>

Parse `$ARGUMENTS` to determine the subcommand. If empty, default to **touch** (the minimal level).

---

### Level: `touch` — 1-2 files, obvious scope

Intent lives in the commit message. One sentence: what problem does this solve?

```bash
git commit -m "fix: correct path in SKILL.md — .cursor/skills → .pi/skills"
```

If you can't write the one-sentence why, that's a signal the scope is larger than it appears — escalate to **change**.

No separate document needed.

---

### Level: `change` — 3-5 files, OR any new command/skill/rule/configuration

Write a one-paragraph Intent Note before touching any files.

**Format:** problem statement, not solution statement.

1. Create (or read existing) `submodules/lid-pi-extension/kit/templates/INTENT.md`
2. Write intent: problem statement only, no solution statement
3. Stop and get acknowledgment before proceeding to the change
4. Store at: `.planning/{topic}/INTENT.md`

```
## Intent

The workspace has three tools (Cursor, Claude Code, pi) that each need
the same command content, but currently .claude/commands/ is a manual
subset of .cursor/commands/ — missing 18 commands and requiring manual sync.
```

Use the template file when available. If it's not present, write a one-paragraph problem statement at the top of a new file.

---

### Level: `restructure` — 5+ files, new directories, architectural shifts

Walk the full arrow. Stop for review after each step. No changes until Acceptance Criteria are approved.

1. **Intent Note** (see **change** level above)
2. **Design Note** — where does this fit the existing structure? what alternatives were considered? what are the downstream effects?
   - Use template: `submodules/lid-pi-extension/kit/templates/DESIGN-NOTE.md`
3. **Acceptance Criteria** — a checklist of verifiable outcomes. For non-code work these are manual checks, not automated tests. Each criterion should be something a fresh session could verify by reading the repo.
   - Use template: `submodules/lid-pi-extension/kit/templates/ACCEPTANCE.md`
4. **Change** — execute, reference the Intent Note in commit messages, check off Acceptance Criteria

Spar the intent, not the implementation. Run `/spar` against the Intent Note before proceeding.

---

### `cascade` — propagate intent changes downward

When intent at one level changes, cascade downward:

- Intent changes → review Design Note, Acceptance Criteria, then Change
- Design Note changes → review Acceptance Criteria, then Change
- Acceptance Criteria change → re-verify the Change satisfies them

**Within one logical change, cascade freely.** Across separate changes, pause — confirm the adjacent change is still coherent with the new intent before touching it.

When requirements and implementation disagree: **requirements win.** Fix the change to match the intent, or explicitly update the intent and record why it changed.

---

### `spar` — adversarial review of intent

Before proceeding past the Intent Note for a Restructure-level change, run `/spar` against the intent. Adversarial review at the Intent level — before design is locked in — is more valuable than review after execution.

## Workflow

```
Intent → Design Note → Acceptance Criteria → Change
```

| Level | Answers | Lives in |
|---|---|---|
| Intent | Why? What problem? | Commit message or `.planning/` |
| Design Note | How does it fit? Alternatives? | `.planning/{topic}/` |
| Acceptance Criteria | How will you know it worked? | `.planning/{topic}/` or inline |
| Change | The actual files modified | The repo |

## Cascade discipline

**Within one logical change, cascade freely.** Across separate changes, pause and confirm.

When requirements and implementation disagree: **requirements win.** Fix the change to match the intent, or explicitly update the intent and record why it changed.

</process>

<success_criteria>
- Touch-level changes have a one-sentence intent in the commit message
- Change-level changes have a stored Intent Note before any files are modified
- Restructure-level changes walk the full arrow with stops for review at each phase
- Cascade direction is respected: intent → design → acceptance → change
- Requirements always win over implementation when they disagree
- `/spar` is used to adversarially review Intent Notes for Restructure-level changes

</success_criteria>

# LID Workflow — Non-Code Adaptation

> Version: 2026-05-03
>
> Adapts Linked-Intent Development for pi sessions and non-code workspaces.
> For the original LID methodology (code projects, Claude Code plugins):
> https://github.com/jszmajda/lid

---

## Why this exists

The standard LID arrow (`HLD → LLD → EARS → Tests → Code`) assumes software.
Many valuable workspaces are documents, configurations, commands, and knowledge
structures — not code. The discipline is the same; the artifacts differ.

The core insight transfers exactly: **intent gaps are the real problem**, not
implementation bugs. When an agent restructures a workspace without documented
intent, the next agent can't tell why things are arranged the way they are —
and refactors it away. The arrow of intent makes decisions durable across
sessions, models, and context resets.

---

## The non-code arrow

```
Intent → Design Note → Acceptance Criteria → Change
```

| Level | Answers | Lives in |
|---|---|---|
| **Intent** | Why? What problem? | Commit message or `.planning/` |
| **Design Note** | How does it fit? What alternatives? | `.planning/{topic}/` |
| **Acceptance Criteria** | How will you know it worked? | `.planning/{topic}/` or inline |
| **Change** | The actual files modified | The repo |

---

## When to use each level

### Touch — 1–2 files, obvious scope

Intent lives in the commit message. One sentence: what problem does this solve?

```
fix: correct YouTube skill path in CLAUDE.md — .cursor/skills → .pi/skills
```

No separate document needed. If you can't write the one-sentence why,
that's a signal the scope is larger than it appears.

### Change — 3–5 files, OR any new command / skill / rule / configuration

Write a one-paragraph Intent Note before touching any files.

**Format:** problem statement, not solution statement.

```
## Intent

The workspace has three tools (Cursor, Claude Code, pi) that each need
the same command content, but currently .claude/commands/ is a manual
subset of .cursor/commands/ — missing 18 commands and requiring manual
sync. This makes parity invisible and creates drift on every update.
```

Stop and get acknowledgment before proceeding to the change.
Use the template at `templates/INTENT.md`.

### Restructure — 5+ files, new directories, or architectural shifts

Walk the full arrow. Stop for review after each step.

**Step 1 — Intent Note** (see above)

**Step 2 — Design Note**

Covers: where does this fit the existing structure? what alternatives
were considered and why rejected? what are the downstream effects?

Use the template at `templates/DESIGN-NOTE.md`.

**Step 3 — Acceptance Criteria**

A checklist of verifiable outcomes. For non-code work these are manual
checks, not automated tests. Each criterion should be something a fresh
session could verify by reading the repo.

```
- [ ] `pi install` succeeds in a clean container
- [ ] L0 block appears in system prompt on session start
- [ ] Agent reads LID-WORKFLOW.md before a 3-file change without prompting
- [ ] No conflict when loaded alongside zanshin-pi-extension
```

Use the template at `templates/ACCEPTANCE.md`.

**Step 4 — Change**

Execute. Reference the Intent Note in commit messages.
After completing, check off the Acceptance Criteria.

---

## Cascade discipline

When intent at one level changes, cascade downward:

- Intent changes → review Design Note, Acceptance Criteria, then Change
- Design Note changes → review Acceptance Criteria, then Change
- Acceptance Criteria change → re-verify the Change satisfies them

**Within one logical change, cascade freely.**
**Across separate changes, pause** — confirm the adjacent change is still
coherent with the new intent before touching it.

When requirements and implementation disagree: **requirements win.**
Fix the change to match the intent, or explicitly update the intent and
record why it changed.

---

## Storing artifacts

**Commit message** — sufficient for Touch-level intent.

**`.planning/{topic}/INTENT.md`** — for Change and Restructure level.
Create the directory when the work warrants it.

**`.planning/{topic}/BRIEF.md`** — combines Intent + Design Note for
structured efforts. The planning directory doubles as the project's
memory across sessions.

**In the change itself** — large structural changes can carry their
intent inline: a `## Why` section in a new README, a comment block
at the top of a new configuration file.

---

## Spec IDs (optional)

For long-running structural work, semantic IDs help trace intent to change:

```
{DOMAIN}-{TYPE}-{NNN}

Examples:
  CMDS-INTENT-001   — intent spec for a commands change
  ARCH-DESIGN-003   — design note for an architecture shift
  EXT-ACCEPT-002    — acceptance criterion for an extension
```

Use IDs when: the work spans multiple sessions, multiple people, or
multiple interacting changes. Skip them for contained single-session work.

IDs are stable once assigned — revise text, not IDs. Delete specs that
are no longer relevant; don't mark them. Git preserves history.

---

## Integration with Zanshin

When both extensions are loaded (zanshin-pi-extension + lid-pi-extension),
they operate at different layers without conflict:

| Extension | Layer | Fires when |
|---|---|---|
| Zanshin | Session discipline | Always — spar, shoshin, bookkeeping, stack |
| LID | Change discipline | Before executing a change |

Natural integration points:

- **Shoshin at phase gates**: before starting a Design Note, verify the
  Intent is still accurate — don't inherit a stale framing.
- **Checkpoints at phase completion**: commit the Intent Note, then the
  Design Note, then the Acceptance Criteria — progressive bookkeeping
  applied to the arrow.
- **Spar the intent**: adversarial review belongs at the Intent level,
  before design is locked in. LID's edge audit phase = Zanshin spar.

---

## Relationship to LID upstream

This workflow adapts LID's discipline. For code projects, the upstream
Claude Code plugins provide richer integration (auto-invoking skills,
slash commands, bidirectional spec-code traceability):

  https://github.com/jszmajda/lid

This extension is for pi sessions and non-code contexts. A project using
both Claude Code and pi can install both — the discipline is compatible,
the tooling is additive.

# lid-pi-extension

**Linked-Intent Development (LID)** for [Pi](https://github.com/badlogic/pi-mono):
an always-on L0 discipline block injected into the system prompt via
`before_agent_start`, plus a non-code workflow adaptation in `kit/`.

Adapts [LID](https://github.com/jszmajda/lid) — a design-before-change methodology
that keeps intent and implementation coherent across sessions — for pi sessions and
non-code workspaces where the standard `HLD → LLD → EARS → Tests → Code` arrow
doesn't map cleanly.

## What it does

At every session start, the extension injects a compact L0 block into the system
prompt. The L0 tells the agent: before executing a change, scale the intent work
to the size of the change.

**Touch** (1–2 files): intent in the commit message.
**Change** (3–5 files, or any new command/skill/rule): Intent Note before touching files.
**Restructure** (5+ files, directories, architecture): full arrow — Intent → Design Note → Acceptance Criteria → Change.

Full workflow, phase triggers, and examples: `kit/LID-WORKFLOW.md` (on-demand depth).
Templates: `kit/templates/`.

## Install

```bash
pi install git:https://github.com/hhellbusch/lid-pi-extension.git
```

Pin a commit (recommended):

```bash
pi install git:https://github.com/hhellbusch/lid-pi-extension.git#<40-char-sha>
```

## What ships

| Path | Role |
|---|---|
| `extensions/lid-l0.ts` | `before_agent_start` → inject L0 + absolute paths to kit files |
| `kit/LID-WORKFLOW.md` | Full non-code workflow: phases, triggers, cascade rules |
| `kit/templates/INTENT.md` | Intent Note template |
| `kit/templates/DESIGN-NOTE.md` | Design Note template |
| `kit/templates/ACCEPTANCE.md` | Acceptance Criteria template |

## Using with Cursor or Claude Code

The pi extension handles auto-injection for pi sessions. For Cursor and Claude Code,
wire the same discipline via their native mechanisms:

**Cursor:** add `.cursor/rules/lid.mdc` to your project (see below).

**Claude Code:** add an "Intent First" section to your `CLAUDE.md` referencing
`kit/LID-WORKFLOW.md`. The workspace that ships this extension uses it as a
git submodule and references it from `CLAUDE.md` and a Cursor rule.

### `.cursor/rules/lid.mdc`

```markdown
---
description: LID — linked-intent discipline for all workspace changes
globs:
alwaysApply: true
---

# LID L0 — linked-intent discipline

Intent is the artifact. Changes are output.

Before executing any change:
- **Touch** (1–2 files): intent in the commit message
- **Change** (3–5 files, or new command/skill/rule): Intent Note first
- **Restructure** (5+ files, architecture): full arrow —
  Intent → Design Note → Acceptance Criteria → Change

Full workflow: `lid-pi-extension/kit/LID-WORKFLOW.md`
Templates: `lid-pi-extension/kit/templates/`
```

## Integration with Zanshin

When loaded alongside
[zanshin-pi-extension](https://github.com/hhellbusch/zanshin-pi-extension),
the two extensions operate at different layers without conflict:

| Extension | Layer | Fires |
|---|---|---|
| Zanshin | Session discipline | Always — spar, shoshin, bookkeeping, stack |
| LID | Change discipline | Before executing a change |

Natural integration: use Zanshin's shoshin at LID phase gates (verify the
intent is still accurate before inheriting a design note's framing), and
Zanshin's checkpoints after each completed phase.

## Relationship to LID upstream

This extension adapts [LID](https://github.com/jszmajda/lid)'s discipline for pi
and non-code contexts. For code projects, the upstream Claude Code plugins provide
richer integration (auto-invoking skills, slash commands, spec-code traceability).
Both can coexist: install this extension for pi sessions, the upstream plugins for
Claude Code sessions.

## License

MIT

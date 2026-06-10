# Handoff Skill — Evaluation

Source: [mattpocock/skills — handoff](https://github.com/mattpocock/skills/blob/main/skills/productivity/handoff/SKILL.md)

## What It Does

Compresses the current conversation into a handoff document for another agent to pick up later. Saves to OS temp directory (workspace-agnostic), includes a "suggested skills" section, references existing artifacts by path, and redacts sensitive info.

## Our Ecosystem

Our workspace handles session handoff through three mechanisms:

- **`/checkpoint`** (zanshin) → writes `whats-next.md` to `.planning/<project>/`
- **`/start`** → reads handoffs, generates session orientation, surfaces focus suggestions
- **`/run-prompt`** → delegates to fresh contexts for sub-task execution

The handoff cycle is:

```
/whats-next (session end) → whats-next.md → /start (session start)
```

## Mapping

| Matt Pocock | Our Equivalent | Notes |
|---|---|---|
| Compress conversation → handoff doc | `/checkpoint` → `whats-next.md` | Ours is project-anchored; his is conversation-first |
| "Suggested skills" section | `/start` suggestion generation | Ours is more opinionated (In Progress / Up Next / Quick Win) |
| Reference artifacts by path | `/brief` links, not duplicates | Ours is more disciplined |
| Redact sensitive info | Not explicit | **Gap** |
| Workspace-agnostic output (temp dir) | Lives in `.planning/` | His is more portable |

## The Real Divergence

Our `/checkpoint` is **project-anchored**. It lives under `.planning/<project>/` and is consumed by `/start` at session beginning. It's the hub of a planning cycle tied to the repo's structure.

Matt's handoff is **conversation-anchored**. It's a one-shot document you generate when leaving context — not tied to project structure, not consumed by a start ritual. It's a handoff between *agents*, not a session checkpoint for *yourself*.

## Where It Fits (or Doesn't)

**It doesn't fit as a new skill.** Three reasons:

1. **Overlap with `/checkpoint`.** Ours is project-anchored and repo-persistent. His is a throwaway temp-file approach. Ours is the more useful pattern for this workspace because the planning cycle is project-first.

2. **Overlap with `/run-prompt`.** Matt's skill suggests skills for the next agent. We already have `/run-prompt` for spawning sub-task contexts with fresh state — parallel/sequential execution, archiving, committing. More capable.

3. **The portable handoff is a real need.** Matt's temp-file approach means a handoff document travels outside the workspace. Ours is locked to `.planning/`. If you want to hand off work to someone without repo access, there's no path.

## One Genuine Gap

**Redaction.** Matt's skill explicitly calls out redacting API keys and PII. Our checkpoint doesn't. This is a one-line addition to the existing `/checkpoint` skill rather than a new skill.

## Recommendation

Don't add the skill as-is. Instead:

1. **Add redaction to `/checkpoint`** — explicit instruction to scrub sensitive data from handoff docs. One-line edit.

2. **Consider a `--portable` flag to `/checkpoint`** — instead of writing to `.planning/*/whats-next.md`, write a standalone markdown doc to a user-specified location (downloads, temp, desktop). Captures the portable handoff without duplicating the project-anchored default.

3. **Add "suggested next skills" to checkpoint output** — Matt's "suggested skills" section is a nice pattern. Would make `/start` smarter by surfacing which skills are relevant to the handoff content.

## Bottom Line

The Matt Pocock skill captures a real pattern — portable, conversation-anchored handoffs — but the substance is better served by extending our existing mechanisms than by adding a new one. The divergence is philosophical (project-first vs. conversation-first) and our workspace is already optimized for the former. Worth borrowing the portable concept and the redaction discipline; not worth importing the whole skill.

# When the Safety Net Is Too Heavy to Use

> **Audience:** Engineers designing review processes, quality gates, or any system intended to catch errors before they ship.
> **Purpose:** Documents how a pre-commit review process designed to catch everything ended up being skipped entirely — and how the fix was scaling the review depth rather than adding more checks.

---

## The Setup

This repository uses a pre-commit review rule (`.cursor/rules/pre-commit-review.md`) that requires running a structured review process before every commit. The review checks file placement, README coverage, cross-references, content quality, secrets, biographical content, and backlog alignment. It was designed to be comprehensive — the full `/review` command runs 11+ steps and produces a structured report.

The system also tracks review status via YAML frontmatter. When the author reads and approves a file, `/validate` stamps it with `status: reviewed` and validation dates. The intent: if a reviewed file gets modified later, the system should flag the staleness.

---

## What Happened

During a previous session, [The Shift](../ai-engineering/the-shift.md) was validated — the author read the full essay and the system recorded `read: 2026-04-17` and `voice-approved: 2026-04-17`. Then, in the same session, three subsequent edits were made:

1. Inline token definition with billing dimension
2. Expanded fluency-accuracy section with case study links
3. Token usage named as the new "lines of code" fallacy

Each edit was committed. None of the commits ran the full `/review` process. The review frontmatter was never updated. The file's `status: reviewed` became stale immediately after the first edit, but nothing in the system flagged it.

When the author asked "did our review mechanisms kick in appropriately?", the answer was no — on three counts:

1. The **pre-commit review rule** was violated (no `/review` before commits)
2. The **review status** became silently stale (modified after validation, no alert)
3. The **feedback checkpoints rule** wasn't consistently applied after substantive content changes

---

## Why This Matters

The pre-commit review rule failed not because it was wrong, but because it was too heavy for the situation. A one-paragraph inline definition doesn't need an 11-step review with cross-reference checks, README coverage analysis, and backlog alignment verification. But the rule said "always run `/review`" — no exceptions, no scaling.

When a safety mechanism is disproportionate to the change, people (and AI agents) skip it. This is the same dynamic that makes 200-file pull requests get rubber-stamped while 5-file PRs get meaningful review. The problem isn't that reviewers are lazy — it's that the process doesn't scale with the risk.

The deeper issue was the *silent* staleness. The system had no mechanism to say "you just edited a file that was marked as reviewed — the author needs to know." The review frontmatter carried dates, but nothing compared those dates against subsequent modifications in real time.

---

## The Fix — Scaled Review and Three-Layer Detection

### Scaled pre-commit review

The rigid "always run full `/review`" rule was replaced with a proportional system:

- **Full `/review`** — required for new files, 5+ file changes, structural changes, or when explicitly requested
- **Quick review** — sufficient for small edits (1-3 files), backlog updates, frontmatter changes, typo fixes. Read the diff, verify links, check for secrets, flag stale reviews.
- **Three mandatory checks regardless of scale**: stale review detection, external URL verification, secrets scan

This makes the rule followable. A quick review for a one-line change takes seconds. A full review for a new essay takes minutes. Neither gets skipped because neither is disproportionate to what it's checking.

### Three-layer staleness detection

Instead of relying on a single checkpoint, the fix distributes detection across three moments:

1. **At edit time** — The `review-tracking.md` rule now instructs the agent to warn before editing any file with `review: status: reviewed`: "This file was reviewed on DATE. This edit makes the review stale." Not a blocker, but visible.

2. **At commit time** — Step 7 of `/review` now reads frontmatter of every modified file and flags stale reviews prominently, above other findings.

3. **Retroactively** — `/audit` layer 5d catches stale reviews during periodic health checks.

### SHA-based "diff since last review"

To make re-review practical, `/validate` now records the git SHA at validation time (`at: abc1234` in frontmatter). When staleness is detected, the system provides the exact diff command:

```
git diff abc1234..HEAD -- docs/ai-engineering/the-shift.md
```

This means the author doesn't have to re-read a 400-line essay to catch up on three paragraphs of changes. The SHA turns "this file changed" from a vague warning into a precise, actionable diff.

---

## The Meta-Development Pattern

This follows the [meta-development loop](../ai-engineering/the-meta-development-loop.md):

1. **Gap** — Review process too heavy → skipped entirely → reviewed file silently invalidated
2. **Tool** — Scaled review rule, three-layer staleness detection, SHA tracking
3. **Application** — Immediately tested: `git diff 3e34f12..HEAD -- the-shift.md` showed exactly the two content changes since last review
4. **Feedback** — The incident becomes this case study

But this instance adds a nuance to the loop: the gap wasn't a missing capability — it was a capability that was *too comprehensive* to use. Sometimes the fix is subtraction (removing rigidity) rather than addition (adding more checks).

---

## What This Connects To

The core principle — **safety mechanisms must be proportionate to the risk, or they'll be bypassed** — shows up across engineering:

- Code review: 200-file PRs get rubber-stamped; 5-file PRs get scrutiny. The process signals "this is all equally important" when it isn't.
- CI/CD gates: A 45-minute test suite that runs on every typo fix teaches developers to batch changes (hiding risk) rather than commit atomically.
- Compliance: Security checklists that require the same 30-field form for a log message change and a production deployment get filled out reflexively, catching nothing.

In AI-assisted workflows specifically, this connects to [The Shift](../ai-engineering/the-shift.md) section 4 (verification as the primary skill): the volume of AI output means more review moments, which means the review process itself must be lightweight enough to sustain at that frequency. A comprehensive review that only happens sometimes is less valuable than a quick check that happens every time.

---

## Artifacts

| Artifact | What it is |
|---|---|
| [pre-commit-review.md](../../.cursor/rules/pre-commit-review.md) | Scaled from rigid "always full review" to proportional depth |
| [review-tracking.md](../../.cursor/rules/review-tracking.md) | Added `at` SHA field and "flag when editing reviewed files" behavior |
| [/review](../../.cursor/commands/review.md) | Added step 7: review staleness check with SHA-based diff commands |
| [/validate](../../.cursor/commands/validate.md) | Now auto-records git SHA for precise "diff since last review" |
| [/audit](../../.cursor/commands/audit.md) | Layer 5d updated with SHA-based diff hints |
| [The Shift](../ai-engineering/the-shift.md) | The file whose silent staleness exposed the gap |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

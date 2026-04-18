---
description: View, add, pick, complete, or review items in the project backlog
argument-hint: "[add <description> | pick | done <title> | review | prioritize]"
allowed-tools:
  - Read
  - Write
  - StrReplace
  - Shell
  - Glob
  - Grep
---

# Backlog — Project Tracking

Manage the persistent project backlog in `BACKLOG.md`. This file tracks ideas, in-flight work, and completed items across sessions. It is shareable — peers browse it to understand what's happening in this workspace.

## Context

- Backlog file: `BACKLOG.md` (repo root)
- Current date: !`date "+%Y-%m-%d"`

## Instructions

Parse `$ARGUMENTS` to determine the subcommand. If empty or unrecognized, default to **status**.

---

### Subcommand: `status` (default, no arguments)

1. Read `BACKLOG.md`
2. Count items in each section (In Progress, Up Next, Ideas, Done)
3. Display a compact summary:

```
Backlog Summary:
  In Progress (N):  <titles, comma-separated>
  Up Next (N):      <titles, comma-separated>
  Ideas (N):        <count only>
  Done (N):         <count only>
```

4. If any In Progress items have been there for a while, note it: "Heads up: <title> has been in progress since <date>."

---

### Subcommand: `add <description>`

1. Read `BACKLOG.md`
2. From the description and the current conversation context, infer:
   - **Title**: concise 3-8 word heading
   - **Product**: match to an existing product tag in the backlog (`ansible`, `argo`, `coreos`, `meta`, `ocp`, `rhacm`, `vault`) or use a new short tag if needed
   - **Context**: 1-3 sentences explaining what this is and why it matters, with enough detail for a fresh AI session to understand
   - **Links**: relevant file paths or URLs (if identifiable from conversation)
3. Add the item to the **Ideas** section (append before the `## Done` heading)
4. Update the `Last updated` date at the top
5. Confirm:

```
Added to Ideas: <title>
Product: <tag> | Links: <paths>
```

6. If the user said something suggesting urgency or priority, ask: "This sounds like it might belong in Up Next instead of Ideas. Want me to move it?"

---

### Subcommand: `pick`

1. Read `BACKLOG.md`
2. Display numbered list of **Up Next** items:

```
Up Next:
  1. <title> — <first line of context>
  2. <title> — <first line of context>
```

3. Prompt: "Which item do you want to start? Reply with the number."
4. Wait for user response
5. Move the selected item from **Up Next** to **In Progress**:
   - Change the `Added:` field to `Started:` with today's date
   - Place it at the bottom of the In Progress section
6. Update the `Last updated` date
7. Confirm: "Moved to In Progress: <title>"

---

### Subcommand: `done <title>`

1. Read `BACKLOG.md`
2. Find the item in **In Progress** matching the title (fuzzy match on the heading text)
3. If not found, search **Up Next** and **Ideas** as fallback
4. If still not found, list In Progress items and ask user to clarify
5. Move the item to the **Done** section:
   - Change `Started:` (or `Added:`) to `Completed:` with today's date
   - Place it at the top of the Done section (most recent first)
6. Update the `Last updated` date
7. Confirm: "Completed: <title>"

---

### Subcommand: `review`

1. Read `BACKLOG.md` in full
2. Analyze and report:

**Staleness check:**
- Flag In Progress items older than 2 weeks as potentially stale
- Flag Up Next items that have been waiting more than a month

**Promotion candidates:**
- Suggest Ideas that relate to recent conversation topics or recent commits as candidates for Up Next

**Done section hygiene:**
- If Done has more than 10 items, suggest trimming the oldest ones (they've served their changelog purpose)

**Consistency check:**
- Verify all items have the required fields (Product, Context, Links or date)
- Flag any items missing fields

3. Present findings as a checklist and ask: "Want me to fix any of these? Reply with the numbers or 'all'."

---

### Subcommand: `prioritize`

A deliberate analysis and reordering of the backlog. Unlike `review` (which checks hygiene), `prioritize` evaluates what matters most and recommends a ranked order.

1. Read `BACKLOG.md` in full
2. Read recent git history: `git log --oneline -15`
3. Scan the conversation context for topics the user has been discussing

4. **Zero-base evaluation** — Before analyzing items by their current section placement, evaluate every non-Done item *as if it had no current priority*. Strip the section labels (In Progress, Up Next, Ideas) and score each item purely on its merits:

| Dimension | Question | Weight |
|---|---|---|
| **Peer value** | Would this help someone browsing the repo? | High |
| **Momentum** | Is there recent work that makes this easier to do now? | High |
| **Dependency** | Does anything else depend on this being done first? | Medium |
| **Effort** | How much work is this (small/medium/large)? | Medium |
| **Staleness risk** | Will this get harder or less relevant if delayed? | Low |
| **Anchoring risk** | Am I ranking this here because it was already here? | Check |

The **Anchoring risk** dimension is not weighted — it is a bias check. For each item, ask: "If this were in Ideas instead of Up Next, would I still rank it this high?" If the answer is "only because it was already prioritized," the item needs fresh justification.

This produces a **zero-base ranking** — what the priority order would be if starting from scratch.

5. **Compare zero-base vs. current** — Present both rankings side by side:

```
Backlog Priority Analysis:

## Zero-Base vs. Current Ranking

| # | Zero-Base Ranking | Current Section | Delta | Note |
|---|-------------------|-----------------|-------|------|
| 1 | <title> | Up Next (#1) | — | Confirmed |
| 2 | <title> | Ideas | +3 | Zero-base promotes this; was buried in Ideas |
| 3 | <title> | Up Next (#2) | -1 | Slight drop; current ranking may be momentum-driven |
| 4 | <title> | In Progress | ↓ | Active but zero-base ranks it lower — sunk cost? |

## Anchoring Flags
- <title>: Ranked high in current ordering but zero-base analysis suggests [momentum bias / sunk cost / genuine priority]. [Fresh justification or recommendation to deprioritize.]

## In Progress Check
- <title>: <assessment — still active? blocked? should it be deprioritized?>

## Quick Wins
- <any items that are small effort + high value>

## Items to Consider Dropping
- <any items that no longer seem relevant>
```

6. **Ask the user** what to act on:

"Zero-base analysis suggests a different ordering than the current backlog in these areas:
- <title> ranks higher than its current section suggests (currently in Ideas, zero-base puts it at #N)
- <title> may be anchored by momentum rather than current value

Recommended changes:
- Promote <title> from Ideas to Up Next
- Reorder Up Next to: 1. <x>, 2. <y>
- <other suggestions>

Want me to make these changes? Reply with 'yes', specific numbers, or tell me what you'd adjust."

7. If the user confirms, update `BACKLOG.md`:
   - Reorder items within sections based on the agreed priority
   - Promote items from Ideas to Up Next as agreed
   - Update the `Last updated` date

---

## Backlog Item Format

Every item follows this structure:

```markdown
### <Title>
- **Product:** <tag>
- **Context:** <1-3 sentences>
- **Links:** <file paths, URLs> (optional for Ideas)
- **Added:** <YYYY-MM-DD or YYYY-MM> (Ideas and Up Next)
- **Started:** <YYYY-MM-DD or YYYY-MM> (In Progress)
- **Completed:** <YYYY-MM-DD or YYYY-MM> (Done)
```

### Title Conventions

- **`Case study:`** prefix — Seeds for potential case study essays. These are observations that current work demonstrates a pattern worth documenting, connects to an existing essay, or could become its own piece. Always set **Product** to `docs`. Example: `### Case study: sparring integration as meta-development pattern`. Added by the `case-study-reflection` rule during work or by `/whats-next` during session handoff.

## File Structure

`BACKLOG.md` has four sections in this order:

```markdown
# Backlog
> Last updated: YYYY-MM-DD

## In Progress
## Up Next
## Ideas
## Done
```

Items move downward through the lifecycle: Ideas → Up Next → In Progress → Done.

---
description: View, add, pick, complete, or review items in the project backlog
argument-hint: "[add <description> | pick | done <title> | review | prioritize | archive-done]"
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
- Archive file: `BACKLOG-ARCHIVE.md` (older **`## Done`** items; see **Done retention** below)
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
  Done (N):         <count only>  (max 15 in file; older in BACKLOG-ARCHIVE.md)
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
8. If **`## Done`** now has **more than 15** items (count `###` headings only), run **`archive-done`** automatically as part of the same edit (no extra confirmation unless the user previously asked to skip archival).

---

### Subcommand: `archive-done`

Trim **`## Done`** in `BACKLOG.md` to the rolling cap by moving excess items to `BACKLOG-ARCHIVE.md`.

1. Read `BACKLOG.md` and `BACKLOG-ARCHIVE.md` (if the archive is missing, create it using the header template in **Done retention**).
2. Count Done items: `###` headings under **`## Done`** only (ignore the rolling-cap note paragraph).
3. If count ≤ **15**, report: `Done has N items (cap 15). Nothing to archive.` and stop.
4. **`## Done` order:** newest completions **first** (most recent at the top, oldest at the bottom). If order has drifted, re-sort to that convention before cutting.
5. Remove whole item blocks from the **bottom** of **`## Done`** until exactly **15** remain. Each block starts at `###` and runs until the next `###` or end of section.
6. In `BACKLOG-ARCHIVE.md`, **prepend** a new batch **after the intro** and **immediately before** the first existing `## Archived` heading (so newer batches stay at the top of the archive). Use heading `## Archived YYYY-MM-DD (N items)` where the date is **today** and **N** is the number of items moved. Paste the **full** markdown for each archived item (preserve original **`Completed:`** lines).
7. Update `Last updated` in `BACKLOG.md`.
8. Confirm: `Archived N Done item(s) to BACKLOG-ARCHIVE.md. Done now has 15 items.`

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
- If **`## Done`** has **more than 15** items, offer to run **`archive-done`** (or run it if the user asked to fix hygiene in bulk)
- If count is ≤15 but the section is not **newest-first**, suggest reordering to match **Done retention**

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

---

## Done retention (rolling cap)

- **`## Done`** holds at most **15** completed items so `BACKLOG.md` stays a current board, not a full history.
- **Order:** **newest first** — when moving an item to Done, insert it **immediately after** the rolling-cap note paragraph (at the top of the list).
- **Overflow:** When a completion pushes Done past 15, move items from the **bottom** (oldest in that section) to `BACKLOG-ARCHIVE.md` in the same change set as the completion, or run **`/backlog archive-done`** explicitly.
- **Archive file:** `BACKLOG-ARCHIVE.md` — each batch uses `## Archived YYYY-MM-DD (N items)`; keep full item bodies (title, Product, Context, Links, Completed). **Newer batches go above older ones** in the file for quick scanning.
- **Git** remains authoritative for diffs; the archive is for **cheap lookup** without `git log -p` on large backlog edits.

---
description: Orient a new session — load project context, check handoffs, and suggest what to work on
allowed-tools:
  - Read
  - Shell
  - Glob
  - Grep
---

# Start — Session Orientation

<objective>
Load persistent project state and present a clear picture of where things stand so the user can decide what to work on. This is the complement to `/whats-next` (which creates the handoff at session end).

Run this at the beginning of a new session, or whenever you need to re-orient.
</objective>

<context>
- Backlog: @BACKLOG.md
- Older completed items: `BACKLOG-ARCHIVE.md` (when **`## Done`** in the backlog is trimmed to the rolling cap)
- Recent commits: !`git log --oneline -10`
- Handoff file: !`ls whats-next.md 2>/dev/null || echo "No handoff file"`
- Planning projects: !`ls -d .planning/*/ 2>/dev/null || echo "No planning projects"`
- Continue-here files: !`find .planning -name ".continue-here*.md" 2>/dev/null || echo "No continue-here files"`
</context>

<process>

### Step 1: Backlog snapshot

Read `BACKLOG.md` and present the project-level context first — this is the ground truth that any handoff or continuity suggestion should be evaluated against.

```
## Where Things Stand

**In Progress:**
- [title] — [first line of context] (started [date])

**Up Next:**
- [title] — [first line of context]
- [title] — [first line of context]

**Ideas:** [N] items queued

**Recently Completed:** [last 2-3 items from **`## Done`** in `BACKLOG.md` — newest are listed first; older completions live in `BACKLOG-ARCHIVE.md`]

**Review coverage:** N/M files reviewed (X%)
```

For the review coverage line, do a quick count: `rg -l "^  status: reviewed" --glob "*.md"` for reviewed files vs. total markdown files (excluding `.git/`). One line is enough — `/audit` has the detailed breakdown.

### Step 2: Check for handoff

If `whats-next.md` exists in the repo root:
1. Check staleness: run `stat -c %Y whats-next.md` and compare against the timestamp of the most recent commit (`git log -1 --format=%ct`). If the handoff is older than the most recent commit, flag it:
   - "There's a handoff from a previous session, but commits have been made since it was written. The handoff may be stale — read it with that in mind."
2. Read it in full
3. Present a summary: what was being worked on, what remains, any blockers or decisions pending
4. Cross-reference against the backlog snapshot from Step 1. If the handoff references work that's now in Done, or if the backlog has changed significantly, note the discrepancy.
5. Ask: "There's a handoff from a previous session. Want to pick up where you left off, or start fresh from the backlog?"

If a `.continue-here*.md` file exists in any `.planning/` subdirectory:
1. Read it
2. Present: which project, which phase, what was in progress
3. Ask: "There's a planning handoff for [project]. Want to resume?"

### Step 2.5: Fresh-eyes check (shoshin)

For each directory in `.planning/` that has a `BRIEF.md`:

1. Read the brief's **one-liner**, **problem** statement, and **success criteria**
2. Compare against the current In Progress and Up Next backlog items
3. If there's a gap — work that doesn't connect to any stated goal, or stated goals with no active work — note it briefly:

```
## Brief Alignment
- **[project]**: Current work aligns with stated goals.
  OR
- **[project]**: In Progress item "[title]" doesn't connect to any success criterion in the brief. Has the scope evolved, or has the work drifted?
  OR
- **[project]**: Brief lists "[criterion]" as a goal but nothing in the backlog is working toward it.
```

If a `CHANGELOG.md` exists in the planning directory, check the most recent entry — it captures why the scope last changed and may explain apparent drift.

This step is lightweight. If everything aligns, one line is enough. Only surface conflicts.

### Step 3: Recent activity

From the git log, identify:
- What was committed in the last session (cluster of recent commits)
- Any uncommitted changes (`git status`)
- Present as: "Last session you worked on: [summary of recent commits]"

### Step 4: Planning project status

For each directory in `.planning/`:
1. Read `ROADMAP.md` if it exists
2. Find the current phase (first phase with status "Not started" or "In progress")
3. Present: "[project]: Phase N — [name] ([status])"

### Step 5: Suggest focus

Based on all the above, suggest 2-3 options for what to work on, prioritized by:
1. Handoff continuations (if any exist)
2. In-progress backlog items
3. Up Next items that have been waiting longest
4. Quick wins (small effort, high value)

Present as a numbered list:

```
## Suggested Focus

1. **[Continue: title]** — Pick up from handoff / in-progress item
2. **[Next: title]** — Highest priority Up Next item
3. **[Quick win: title]** — Small item that could be knocked out quickly

What would you like to work on? Pick a number or tell me something else.
```

</process>

<success_criteria>
- Backlog state presented first — project-level context before session-level handoffs
- Handoff files detected, staleness-checked, and cross-referenced against backlog
- Brief alignment checked — drift surfaced if present
- Recent activity summarized from git log
- Planning project status checked
- 2-3 actionable suggestions presented
- User chooses direction, not the agent
</success_criteria>

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
- Backlog summary: !`head -4 BACKLOG.md`
- Recent commits: !`git log --oneline -10`
- Handoff file: !`ls .planning/whats-next.md 2>/dev/null || echo "No handoff file"`
- Planning projects: !`ls -d .planning/*/ 2>/dev/null || echo "No planning projects"`
- Continue-here files: !`find .planning -name ".continue-here*.md" 2>/dev/null || echo "No continue-here files"`
</context>

<process>

### Step 0: Read ABOUT.md

If `ABOUT.md` exists at the repo root, read it before anything else. It is the workspace owner's self-description and takes precedence over any identity inferences from the corpus or `.cursorrules`. Note the professional domains, background, and framing — then carry that understanding into all subsequent steps. Do not infer the owner's primary domain from the technical content you are about to load.

If `ABOUT.md` does not exist, note it and proceed — but be especially cautious about identity inferences from the corpus alone.

### Step 1: Backlog snapshot

Present the summary header from `BACKLOG.md` (already loaded in context — the `> State:` line). This is the ground truth for session orientation. Do not read the full `BACKLOG.md` unless the user asks for detail on a specific section or item.

```
## Where Things Stand

[State line from BACKLOG.md header — counts and last done]
[Last updated line]
```

If the user asks "what's in progress?" or "show me up next" or similar, then read the relevant section of `BACKLOG.md`. Otherwise, the summary is sufficient to orient the session and suggest focus.

**Review coverage** is opt-in — skip unless the user asks. `/audit` has the detailed breakdown.

### Step 2: Check for handoff

If `.planning/whats-next.md` exists:
1. Check staleness: run `stat -c %Y .planning/whats-next.md` and compare against the timestamp of the most recent commit (`git log -1 --format=%ct`). If the handoff is older than the most recent commit, flag it:
   - "There's a handoff from a previous session, but commits have been made since it was written. The handoff may be stale — read it with that in mind."
2. Read it in full
3. Present a summary: what was being worked on, what remains, any blockers or decisions pending
4. Cross-reference against the backlog snapshot from Step 1. If the handoff references work that's now in Done, or if the backlog has changed significantly, note the discrepancy.
5. Ask: "There's a handoff from a previous session. Want to pick up where you left off, or start fresh from the backlog?"

If `.planning/whats-next.md` does **not** exist (crash, abrupt end, or `/whats-next` was skipped):
1. Use the git log as a synthetic handoff — it is the next best thing
2. From `git log --oneline -10`, identify the cluster of commits from the last session (grouped by time proximity and subject)
3. Synthesize and present:

```
## Reconstructed Session Context (no handoff file found)

**Last session worked on:** [summary of recent commit cluster — what changed, what was built]
**Likely in-flight:** [any backlog items that connect to recent commits but aren't yet Done]
**Possible next step:** [what the commit sequence suggests was coming next]

---
⚠️ **What this reconstruction cannot recover:**
- Decisions made in conversation that weren't committed to any file (e.g., "we discussed doing X but held off")
- Pending intent — what the agent was about to do next
- Scope calls, trade-offs, or approach choices discussed but not yet written down
- Anything agreed to verbally that didn't produce a file change

Git log shows *what landed*, not what was in flight or decided-but-deferred. If anything feels ambiguous or you're unsure whether a decision was made, ask rather than assume. Re-litigating a decision is lower cost than undoing a wrong assumption.

*(Reconstructed from git log — treat as approximate. The backlog above is ground truth.)*
```

4. Proceed with Step 3 as normal — the reconstruction replaces the handoff summary.

If a `.continue-here*.md` file exists in any `.planning/` subdirectory:
1. Read it
2. Present: which project, which phase, what was in progress
3. Ask: "There's a planning handoff for [project]. Want to resume?"

### Step 2.5: Planning projects — one-liners always, full reads on request

For each directory in `.planning/` that has a `BRIEF.md`:

1. Read the brief's **one-liner only** — the first non-blank line after the title or the purpose statement in the opening section. Do not read the full brief.
2. Compare the one-liner against the current In Progress and Up Next backlog items
3. Surface gaps only — if everything aligns, one line suffices:

```
## Planning Projects
- **zen-karate**: [one-liner from BRIEF.md] — aligns with Up Next essays
- **paude-integration**: [one-liner from BRIEF.md] — nothing active in backlog ⚠
```

This preserves the shoshin function — catching drift you don't know about — at low cost. One-liners are fast to read; the check runs unconditionally so it catches what you're not looking for. Full BRIEF content and full ROADMAP status remain opt-in.

**To run a full brief alignment check** (when resuming a project or when the one-liner suggests drift):
1. Read the brief's **problem** statement and **success criteria** in full
2. Compare against In Progress and Up Next backlog items
3. Surface gaps:

```
## Brief Alignment — [project]
- **[project]**: Current work aligns with stated goals.
  OR
- **[project]**: In Progress item "[title]" doesn't connect to any success criterion. Has scope evolved?
  OR
- **[project]**: Brief lists "[criterion]" but nothing in the backlog is working toward it.
```

If a `CHANGELOG.md` exists in the planning directory, check its most recent entry first — it captures why scope last changed.

### Step 3: Recent activity

From the git log, identify:
- What was committed in the last session (cluster of recent commits)
- Any uncommitted changes (`git status`)
- Present as: "Last session you worked on: [summary of recent commits]"

### Step 4: Planning project status — on request only

Do **not** read ROADMAPs automatically. The planning projects were listed in Step 2.5. Reading every ROADMAP on every session start scales poorly.

If the user is resuming a specific project, or asks for roadmap status:
1. Read `ROADMAP.md` for that project
2. Find the current phase (first phase with status "Not started" or "In progress")
3. Present: "[project]: Phase N — [name] ([status])"

If no project is specified and the session has a clear non-planning focus, skip this step entirely.

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

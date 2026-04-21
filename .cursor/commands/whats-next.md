---
name: whats-next
description: Analyze the current conversation and create a handoff document for continuing this work in a fresh context
allowed-tools:
  - Read
  - Write
  - Bash
  - WebSearch
  - WebFetch
---

Create a comprehensive, detailed handoff document that captures all context from the current conversation. This allows continuing the work in a fresh context with complete precision.

## Instructions

**PRIORITY: Comprehensive detail and precision over brevity.** The goal is to enable someone (or a fresh Claude instance) to pick up exactly where you left off with zero information loss.

### Step 0: Evaluate whether a handoff is needed

Before creating anything, check whether the session's work is already fully persisted:

1. Read `BACKLOG.md` — are all completed items logged in Done? Are new ideas captured?
2. Check `git status` and `git log --oneline -5` — is the working tree clean? Are all changes committed?
3. Review any `.planning/` files touched this session — are they up to date?

**If all work is committed, the backlog is current, and there's no in-flight state** (no half-finished task, no pending decision, no context the next session needs that isn't in a committed file), then:
- Tell the user: "This session's work is fully persisted in committed artifacts. No handoff needed — `/start` will pick up everything from the backlog and git log."
- If a stale `.planning/whats-next.md` exists from a previous session, ask: "There's an old handoff file. Want me to delete it since it's outdated?"
- **Stop here.** Don't create a handoff for handoff's sake.

**If there is genuine in-flight state** — an unfinished task, a decision that needs to be made, context that only exists in the conversation — proceed to Step 0.5.

### Step 0.5: Read the project backlog

Read `BACKLOG.md` from the repo root. Include a **Project Backlog Snapshot** section in the handoff that captures:
- All **In Progress** items (title + context)
- All **Up Next** items (title only)
- Count of Ideas

This bridges session-level context with project-level priorities so the next session knows what's active beyond the immediate task.

### Step 1: Capture session context

Adapt the level of detail to the task type (coding, research, analysis, writing, configuration, etc.) but maintain comprehensive coverage:

1. **Original Task**: Identify what was initially requested (not new scope or side tasks)

2. **Work Completed**: Document everything accomplished in detail
   - All artifacts created, modified, or analyzed (files, documents, research findings, etc.)
   - Specific changes made (code with line numbers, content written, data analyzed, etc.)
   - Actions taken (commands run, APIs called, searches performed, tools used, etc.)
   - Findings discovered (insights, patterns, answers, data points, etc.)
   - Decisions made and the reasoning behind them

3. **Work Remaining**: Specify exactly what still needs to be done
   - Break down remaining work into specific, actionable steps
   - Include precise locations, references, or targets (file paths, URLs, data sources, etc.)
   - Note dependencies, prerequisites, or ordering requirements
   - Specify validation or verification steps needed

4. **Attempted Approaches**: Capture everything tried, including failures
   - Approaches that didn't work and why they failed
   - Errors encountered, blockers hit, or limitations discovered
   - Dead ends to avoid repeating
   - Alternative approaches considered but not pursued

5. **Critical Context**: Preserve all essential knowledge
   - Key decisions and trade-offs considered
   - Constraints, requirements, or boundaries
   - Important discoveries, gotchas, edge cases, or non-obvious behaviors
   - Relevant environment, configuration, or setup details
   - Assumptions made that need validation
   - References to documentation, sources, or resources consulted

6. **Current State**: Document the exact current state
   - Status of deliverables (complete, in-progress, not started)
   - What's committed, saved, or finalized vs. what's temporary or draft
   - Any temporary changes, workarounds, or open questions
   - Current position in the workflow or process

Write to `.planning/whats-next.md` using the format below.

### Step 1.5: Framework intervention log

Before writing the handoff, briefly scan: did any framework intervention produce a notable outcome this session?

- Did `/spar` catch something non-obvious — a structural contradiction, a load-bearing claim exposed, an assumption dressed as evidence?
- Did the SHA guardrail detect genuine staleness in a briefing?
- Did shoshin surface an inherited framing assumption that needed correction before work started?
- Did compaction surface and trigger a re-read that changed a decision?
- Did a thread get explicitly recovered after a tangent?
- Did a checkpoint enable recovery after a crash or context loss?

**If yes to any:** Append an entry to `research/framework-efficacy/intervention-log.md` using the format defined there. Be specific about what was caught and what the counterfactual would have been. Don't summarize — name the specific finding.

**If a counterfactual comparison was run** (naive pass + structured pass): also add a row to the comparison table in `research/framework-efficacy/counterfactual-protocol.md`.

**If nothing notable fired:** skip entirely. Don't log null events — the absence of entries should mean nothing notable, not that logging was skipped.

---

### Step 1.6: Case study reflection

Before writing the handoff, briefly review the session's work and ask:

- Did this session produce a process or pattern that connects to an existing essay in `docs/`?
- Could anything from this session become its own case study?
- Did the work validate or challenge a claim in an existing doc?

If yes to any, include a **Case Study Opportunities** section in the handoff document (see output format below). These are brief observations, not full proposals — just enough for the next session to decide whether to pursue them.

If nothing stands out, skip this section entirely. Not every session produces essay-worthy material.

### Step 1.75: Shoshin — Assumptions check

Before writing the handoff, identify assumptions this session is carrying that a fresh session should question rather than inherit:

- What framing decisions were made in this session? (e.g., "we decided the essay should lead with X" or "we treated the backlog ordering as settled")
- What was taken as given that might not be true? (e.g., "we assumed the brief's scope is still accurate" or "we relied on a source without re-verifying it")
- Did the project's scope or framing shift during this session? If so, were all related planning documents updated as a set?

If any assumptions are worth surfacing, include an `<assumptions_carried>` section in the handoff (see output format below). If the session was straightforward with no framing decisions, skip it.

### Step 2: Update the backlog if needed

If work completed in this session resolved a backlog item, move it to Done in `BACKLOG.md`. If new ideas or follow-up work emerged, add them to Ideas. Update the `Last updated` date.

## Output Format

```xml
<project_backlog>
[Snapshot from BACKLOG.md:
- In Progress items with titles and context
- Up Next item titles
- Ideas count
- Note any items that should be updated based on this session's work]
</project_backlog>

<original_task>
[The specific task that was initially requested - be precise about scope]
</original_task>

<work_completed>
[Comprehensive detail of everything accomplished:
- Artifacts created/modified/analyzed (with specific references)
- Specific changes, additions, or findings (with details and locations)
- Actions taken (commands, searches, API calls, tool usage, etc.)
- Key discoveries or insights
- Decisions made and reasoning
- Side tasks completed]
</work_completed>

<work_remaining>
[Detailed breakdown of what needs to be done:
- Specific tasks with precise locations or references
- Exact targets to create, modify, or analyze
- Dependencies and ordering
- Validation or verification steps needed]
</work_remaining>

<attempted_approaches>
[Everything tried, including failures:
- Approaches that didn't work and why
- Errors, blockers, or limitations encountered
- Dead ends to avoid
- Alternative approaches considered but not pursued]
</attempted_approaches>

<critical_context>
[All essential knowledge for continuing:
- Key decisions and trade-offs
- Constraints, requirements, or boundaries
- Important discoveries, gotcas, or edge cases
- Environment, configuration, or setup details
- Assumptions requiring validation
- References to documentation, sources, or resources]
</critical_context>

<current_state>
[Exact state of the work:
- Status of deliverables (complete/in-progress/not started)
- What's finalized vs. what's temporary or draft
- Temporary changes or workarounds in place
- Current position in workflow or process
- Any open questions or pending decisions]
</current_state>

<case_study_opportunities>
[Optional — only include if something from this session could connect to existing docs or become its own case study.
- What happened and what pattern it demonstrates
- Which existing essay(s) it connects to
- Whether it was already added to the backlog as a seed]
</case_study_opportunities>

<assumptions_carried>
[Optional — only include if this session made framing decisions or carried assumptions that the next session should question rather than inherit.
- Framing decisions: "We decided X" — is that still the right call?
- Unverified assumptions: "We assumed Y" — should the next session check?
- Scope shifts: "The user broadened/narrowed Z" — were all planning docs updated?
- Context reliance: "We relied on [handoff/summary] without re-reading the brief"]
</assumptions_carried>

<open_threads>
[Optional — only include if the session left multiple threads open in a depth-first stack. Omit if there's only one active thread or the work is fully resolved.

Format:
- `[bottom]` Parent topic — status
  - `[open]` Subtopic — what's waiting
    - `[open]` Sub-subtopic — if needed

The next session should return to each thread in reverse order (innermost first, then surface up) unless the user redirects.]
</open_threads>
```

# Session Brief — Framework: Stack Tracking, /start Audit, Meta-Prompts Concept Doc

> Written: 2026-04-20 (private session → public session privacy-filtered handoff)
> Start here: read this file, then begin with Deliverable 1.

## What this session is for

Three deliverables, in suggested order:

### 1. Implement stack-based conversation tracking

The workspace needs to support depth-first conversation navigation — users
push subtopics, explore until satisfied, pop back to the parent. This is
currently invisible and doesn't survive session boundaries.

**Read first:** `BACKLOG.md` — "Framework: stack-based conversation tracking"
(Ideas section) for the full spec. Also read `.cursor/commands/checkpoint.md`
and `.cursor/commands/whats-next.md`.

**What to implement:**
- Add a note to `.cursor/rules/session-awareness.md` encoding the push/pop
  convention: when a branch concludes, surface "that feels resolved — we were
  on X, want to return?" Don't make this mechanical — it's a conversational
  posture, not a state machine.
- Add an optional `**Open threads:**` field to the checkpoint format
  (`.cursor/commands/checkpoint.md`) — one line per open branch with its
  parent context. Example format:
  ```
  **Open threads (stack):**
  - `[bottom]` Parent topic — status
    - `[open]` Subtopic — what's waiting
  ```
- Add the same optional field to `/whats-next` (`.cursor/commands/whats-next.md`).
- Move the BACKLOG item from Ideas to Done when complete.

**Constraint:** Keep it lightweight. Convention + checkpoint field is the
right scope. Don't wire a `/stack` command yet.

---

### 2. Run the /start simplification audit

Read `.cursor/commands/start.md` in full, then audit every piece of context
it loads against this question: "Does the user need this on every session,
or only when working on that specific context?"

**Flag specifically:**
- Steps 4 (planning project status) and 2.5 (shoshin brief alignment check):
  these load and cross-reference every BRIEF and ROADMAP on every session
  start. As the workspace grows, this cost grows proportionally. Does the
  user need this every time, or only when resuming a planning project?
- Any other steps that could be opt-in without breaking core orientation.

**Produce:** A clear recommendation — what stays always-on, what becomes
opt-in, what changes to `/start` are warranted. Then implement the changes.
Move the BACKLOG item from Ideas to Done when complete.

---

### 3. Write a concept doc: interaction patterns for AI sessions

**Background:**

The `create-meta-prompts` skill (`.cursor/skills/create-meta-prompts/SKILL.md`)
was the original inspiration for much of this framework — lifted from earlier
work and used exploratorily. Its core idea: structure Claude-to-Claude
pipelines explicitly — research → spar → plan → implement — with persistent
XML artifacts in `.prompts/` that each stage can consume. That architecture
is well-suited for complex, multi-stage analytical tasks.

Building out this framework revealed that most sessions don't need a pipeline.
They need one of two lighter things:

1. **Planning mode** — interactive, collaborative design in the current
   session. Good for "what should we build." Synchronous, no persistent
   artifact produced.

2. **A session-start briefing** — a curated context document written for a
   fresh agent. Not a pipeline, not an interactive design. This file is an
   example of one.

The meta-prompts skill fills a real gap, but a different one: orchestration
of work that genuinely has stages, with structured outputs feeding each other.
For most sessions, it's the wrong tool — too heavy, produces `.prompts/`
infrastructure that doesn't pay off for single-stage work.

**Additional use case to cover — the privacy-filtered handoff:**
The session-start briefing is also a **curated handoff** for private-to-public
session transitions. When a private session produces insights that should
inform public work, you write a briefing containing only what's safe to share
and start a fresh public session from it. The new session works only from what
was written — it can't reconstruct what was omitted. Note: this is not a true
"clean room" in the IP engineering sense. The brief is still written by someone
holding the private context, so its shape reflects knowledge the public session
won't have. The privacy guarantee is about what crosses the boundary, not about
eliminating the author's judgment. This current file is an example: written in
a private session, curated to pattern-level content, with the curation
decisions made by the author — not enforced by the format.

**Write:** `docs/ai-engineering/interaction-patterns.md` — a concept doc that
names and explores these patterns. Note: this pattern (session-start briefing)
has one documented instance — this file. Write the doc as an exploration and
naming, not as documentation of a proven, stable pattern. Where behavior is
observed across multiple sessions it can be stated confidently; where it is
novel, say so. The doc should be honest about what is established vs. what is
emerging. This is also a case study opportunity: the session-brief was sparred
before being committed, and the spar improved it — that meta-development loop
is itself worth documenting alongside the pattern.

Cover:
- The three patterns: meta-prompt pipeline, planning mode, session-start
  briefing — what each is for, cost/benefit, when to use it
- The gap the meta-prompts skill fills (and where it's overkill)
- Session-brief vs. whats-next: when they overlap and when they don't — be
  explicit, don't assume the distinction is obvious
- The privacy-filtered handoff as a distinct use case — with the accurate
  framing (curated handoff, not clean room)
- The /start bypass: when using a session-brief, `/start` is intentionally
  skipped. Name this tradeoff — you lose orientation infrastructure in exchange
  for a focused, pre-scoped entry point. That's appropriate when you know
  exactly what you're walking into.
- Practical guidance: for a given task, which pattern fits?

**Audience:** Peers and users new to this framework. Write for an external
reader arriving via a direct GitHub link — explain concepts without assuming
knowledge of Cursor's planning mode or Claude-to-Claude pipelines.

Register the doc in `docs/ai-engineering/README.md` when done.

---

## Constraints for this session

- **Public session** — all commits go to the main repo. No private content.
  Standard commit flow.
- Follow the opt-in principle: don't wire new things into always-running
  commands unless needed on every session.
- The concept doc goes in `docs/` and should read well for an external reader
  (per `workspace-ethos.md` publishing guidance).

---

## Lifecycle

This file is active until consumed. Once you've read and internalized it,
archive it so it doesn't appear stale on future `/start` runs:

```bash
mkdir -p .planning/archive
git mv .planning/session-brief.md .planning/archive/session-brief-2026-04-20.md
git commit -m "planning: archive session brief (consumed)"
```

When all three deliverables are verified complete and `/whats-next` is written,
delete the archived copy:

```bash
git rm .planning/archive/session-brief-2026-04-20.md
git commit -m "planning: delete consumed session brief"
```

Archive when done reading. Delete when done working. Don't make it your first
action — read the brief and start working; handle the archive when it feels
natural, not as a prescribed step 0.

---

## Suggested starting point

Read `ABOUT.md`, confirm the two BACKLOG items exist in the Ideas section,
then start with Deliverable 1 (stack tracking). It's the smallest and gives
you a feel for the framework before the audit and the essay.

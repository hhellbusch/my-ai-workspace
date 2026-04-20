---
review:
  status: unreviewed
  notes: "AI-generated case study draft. Pattern and framing need author read. The session being described is the one that generated this case study, so the author has direct experience to draw on."
---

# What Survives a Crash

> **Audience:** Anyone using AI coding assistants for long, context-heavy sessions — particularly sessions where the AI has accumulated significant working state across many exchanges.
> **Purpose:** Documents what is and isn't recoverable when a session crashes mid-work, and how the conventions this project already uses for human handoff also serve as crash recovery infrastructure.

---

## The Setup

A 511-message session spent several hours on local LLM experiments, case study drafting, adversarial review, and cross-linking work. The session ended mid-operation — in the middle of renumbering a list in `docs/README.md` after inserting a new case study entry. The final committed message from the AI was completing a `StrReplace` for item #23; items #23–28 still needed incrementing to #24–29.

The next session opened with: "can you resume a crashed session?"

---

## What Happened

The recovery process went like this:

1. Located the JSONL transcript for the crashed session (`agent-transcripts/<uuid>/`)
2. Parsed the last ~15 messages to identify where work stopped
3. Checked git status to confirm what had been committed vs. what was staged but uncommitted
4. Found the incomplete renumber — duplicate `23.` entry, items after it still at old numbers
5. Fixed the numbering and committed everything

Total recovery time: a few minutes. Working state before the crash: gone.

The artifact trail — commits, the case study file, the partial `docs/README.md` edit — was complete enough to reconstruct *what* had been done. What couldn't be recovered was *what was being thought*: what topics were prepped, what was being weighed for next, what the session's working model of the project state was. The previous session's last unprompted message was "Ready to draft the survivorship bias case study, or something else while the pull finishes?" — context that would have taken time to re-establish from scratch.

---

## The Pattern

Long AI sessions accumulate two kinds of state:

**Artifact state** — files written, commits made, notes logged, backlog items added. This survives. It's on disk.

**Context state** — the working mental model: what's prepped and ready, what trade-offs are in flight, what the session was about to do next, what the human said three exchanges ago that's shaping the current direction. This doesn't survive. It lives only in the context window, and when the session ends, it ends with it.

The gap between these two matters most in long sessions. A 10-message session that crashes is easy to re-run. A 500-message session that crashes has potentially hours of accumulated context state that no artifact fully captures.

The JSONL transcript records every tool call and result — it's a complete action log. But reading it cold is reconstruction work, not continuation. The difference between resuming a session and reconstructing one is the difference between picking up a conversation mid-sentence and reading a transcript of a conversation you weren't in.

---

## What the Human Brought

The opening question — "can you resume a crashed session?" — is the right question. It named the gap directly rather than just re-explaining the task and hoping the new session would reconstruct context from scratch.

It also produced a useful answer: the tooling can resume subagents launched within a conversation, but not crashed Cursor chat sessions. That distinction — "sort of, but not really" — is worth knowing. The instinct to ask rather than assume is what surfaced it.

---

## The Fix

There is no fix for artifact-vs-context gap — it's a property of how sessions work. But the gap can be narrowed by how sessions end.

**Handoff documents** (`/whats-next`) are the primary mitigation. A session that ends with a handoff note — what was done, what's in flight, what's ready to go next — compresses context state into an artifact. The handoff doesn't fully replace the context, but it's the difference between a new session starting oriented and a new session starting cold.

**Diligent artifact logging** — experiment journals, BACKLOG entries, frequent commits — compounds over time. Each artifact is a checkpoint. A crash that happens after a commit loses less than one that happens before it.

**Small commits over large ones.** The crashed session had committed the Ollama SELinux fix, the backlog item, and several case study registrations before hitting the renumber. The only thing left uncommitted was the tail end of one operation. A crash mid-large-operation is worse than a crash mid-small-one.

The conventions this project already uses for *human* context switching between sessions — journals, backlog, handoff docs — turn out to also be *crash recovery infrastructure*. They weren't designed for that purpose, but they serve it.

---

## When This Applies — and When It Doesn't

**Applies when:** sessions are long, context-heavy, and multi-threaded — the kind where an AI assistant has accumulated significant working state across many exchanges. Infrastructure work, long writing sessions, multi-phase research. Any work where "where were we?" is a non-trivial question.

**Doesn't apply when:** sessions are short and single-threaded. A 10-message session with one clear task can be re-run from scratch with minimal cost. The artifact-vs-context gap only becomes significant when the context state is large relative to the artifact trail.

**The asymmetry to watch:** crash risk doesn't scale with session length — a long session isn't necessarily more likely to crash than a short one. But crash *cost* scales directly with length. Logging conventions that feel like overhead in short sessions are crash insurance in long ones.

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

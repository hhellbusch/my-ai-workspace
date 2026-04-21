# The Session Framework — Patterns, Behaviors, and Why

> **Audience:** Engineers and practitioners who want to understand the behavioral patterns encoded in this workspace's AI collaboration framework — what each behavior is defending against, how they fit together, and how to adapt them.
> **Purpose:** A human-facing map of the framework. The individual commands and rules contain the operational detail; this document explains the reasoning behind them so the structure makes sense as a whole rather than as a collection of arbitrary conventions.

---

## The Problems Being Solved

AI assistants have three structural characteristics that create predictable failure modes in multi-session work.

**Cross-session statelessness.** Every session starts fresh. Context from prior sessions — decisions made, approaches tried, scope defined — doesn't carry over unless it was committed to a file. For single-session tasks this doesn't matter. For work that spans days or weeks, it compounds into drift: the session produces good output that doesn't connect to prior work, or re-litigates decisions that were already settled.

**In-session context compaction.** Within a long session, earlier context gets summarized as the context window fills. The session continues, but the model's internal representation of prior work is a compression — not the original. This is harder to notice than cross-session loss: the session feels continuous, but specific file contents, decisions, and details may have been compressed into approximations. The model proceeds as if it remembers, but what it's working from is a summary. Decisions made on summarized memory of file contents are a common source of subtle errors in long sessions.

**Frictionlessness.** AI assistants are trained to be agreeable. They validate your framing, inherit your assumptions, and produce fluent output that looks correct. This isn't a bug — it's what makes them fast to work with. It becomes a bug when the framing is wrong, the assumption is stale, or the output needs genuine challenge. A tool optimized to agree doesn't naturally provide adversarial pressure.

The framework is a set of behaviors that aim to address all three. Some manage state so context survives across sessions. Some create structural friction to counter the AI's tendency toward agreement.

A note on which behaviors are optional: some are always-on rules that fire regardless of task complexity (the shoshin framing check, pre-commit review, session-awareness defaults). Others are commands you invoke deliberately (`/start`, `/checkpoint`, `/whats-next`, `/spar`). The distinction matters — "the framework won't intrude on simple work" is true for the command layer, not for the always-on rules.

---

## Session Orientation — Starting With an Accurate Picture

Every session risks inheriting a stale model of the world. The previous session left a handoff; the handoff was accurate then; commits have happened since. Or there's no handoff, and the session reconstructs context from whatever is most salient. Either way, the starting framing may be wrong, and the session will build on it as if it's right.

The `/start` command automates a structured orientation sequence: read `ABOUT.md` (the workspace owner's self-description, which takes precedence over inferences from the corpus), load the backlog as ground truth, check any handoff for staleness, scan planning project briefs for drift, and reconstruct recent activity from the git log. The goal is a clean picture *before* scope is set for the session.

**The shoshin principle behind this:** "Shoshin" (初心) — beginner's mind — means approaching context as if encountering it for the first time rather than inheriting a prior session's framing. In practice: read the source documents rather than trusting the summary; check the handoff against the backlog rather than inheriting its model; surface discrepancies before building on top of them. The [`shoshin.md` rule](../../.cursor/rules/shoshin.md) encodes this as a default posture.

**The opt-in principle:** Not everything should load every session. `/start` loads what's genuinely needed every time — identity context, backlog state, recent activity — and defers everything else. Brief alignment checks run from one-liners, not full reads. ROADMAP status loads only when a specific project is being resumed. As a workspace grows, orientation commands that load everything become taxes paid on every session for context that's rarely relevant.

---

## Handoffs and Crash Recovery — Surviving Session Boundaries

Multi-session work fails in two ways: the session ends cleanly but the next session doesn't know what to pick up, or the session ends abruptly (crash, context loss, abandoned window) and nothing was captured.

Two tools address this, designed for different scenarios:

**`/checkpoint`** is fast, designed for mid-session use, and built for crash recovery. It writes a minimal snapshot to `.planning/whats-next.md`: what's in progress, what just finished, what the next step is, what decision was made that would otherwise be re-litigated. Five minutes to write, thirty seconds to read. Run it before risky operations (directory moves, large refactors), after completing a significant unit of work, or when more than a few commits have accumulated since the last save. The git log shows what landed; the checkpoint captures what was in flight and what was decided.

**`/whats-next`** is a full session handoff — comprehensive context capture for handing off to a new session or ending a long work block. It includes a backlog snapshot, work completed in detail, what remains, decisions made, and a case study reflection (did anything from this session demonstrate a pattern worth documenting?). Heavier than a checkpoint; worth running when the session produced substantial work that needs accurate context for continuation.

**Why commit frequently:** A clean working tree is the cheapest form of crash recovery. Uncommitted work is unrecoverable after a crash; committed state is always there in the git log. The framework pushes toward small, logical commits after each unit of work rather than batching.

---

## In-Session Context Compaction — When Memory Isn't What It Was

The handoffs section covers session boundaries. This failure mode is different: it happens inside a session that feels continuous.

As a long session fills its context window, earlier material gets summarized. The model continues — it doesn't announce the compression — but its working representation of prior content is now an approximation. File contents read an hour ago may be remembered in paraphrase. Decisions made mid-session may have lost their specifics. The session proceeds as if it remembers, and nothing in its behavior signals when it doesn't.

**The mitigations:**

**Committed files are the truth anchor.** In-context memory of a file may be compressed; the committed file is always accurate and re-readable. When a decision depends on what a rule says, what a BACKLOG item claims, or what a prior doc contains — read it. Don't rely on what the session remembers reading.

**Re-read before deciding.** The cost of a file read is much lower than the cost of a decision made on a compressed approximation. This applies to any high-stakes decision in a long session: read the source, not the memory of the source.

**Surface uncertainty rather than guessing.** When something feels uncertain — "I believe we decided X" or "I think the file said Y" — name the uncertainty and re-read rather than proceeding. A session that flags its own uncertainty is more trustworthy than one that proceeds with false confidence.

**Frequent commits serve double duty.** Each commit externalizes state into the repo before it can be compressed. A checkpoint mid-session creates a re-readable anchor in `.planning/whats-next.md` that reflects what was true when it was written — independent of what the session currently remembers.

---

## Conversation Stack Tracking — Navigating Depth

Sessions naturally explore topics in a depth-first pattern: a main thread gets set aside while a subtopic is pursued, which may spawn its own tangent. This is invisible without deliberate tracking — by the time the subtopic resolves, the parent thread has lost momentum, and the session often closes without returning to it.

The framework encodes a conversational posture rather than a mechanism: when a branch feels resolved — a question answered, a task finished, a tangent satisfied — surface it: *"That feels resolved. We were working on X before — want to return to that?"* This is a light touch, not an interruption. Stack depth (four to five levels deep) is a signal to park something before pushing further.

**Branch closure as a capture opportunity:** Before leaving a resolved branch, there's a brief moment to check whether it produced anything worth keeping. Decisions that only lived in conversation won't survive without a commit. Patterns observed during the work may be worth logging as BACKLOG seeds or case study candidates. Bookkeeping — BACKLOG item to Done, README updated, cross-link added — often gets deferred and forgotten.

**The user-initiated artifact review:** At any point — especially at natural session pauses — asking "what artifacts, bookkeeping, case studies, or documentation do we need now?" triggers a structured enumeration across four buckets: BACKLOG updates, documentation to create or update, case study candidates, and uncommitted work. The response should be concrete inventory, not a list of suggestions. If a bucket is empty, one word is enough.

---

## Adversarial Pressure — Sparring and Shoshin

Shoshin operates at the start of work: don't inherit a prior framing without verifying it. Sparring operates at the end of a drafting phase: generate the strongest counterarguments before treating something as settled.

These are covered in depth in the [Sparring and Shoshin](sparring-and-shoshin.md) companion guide. In the context of the broader framework, the connection is: shoshin catches drift at session start (the handoff may be stale, the brief may have evolved), and sparring catches weakness in any specific artifact (an essay, a design decision, a framework rule) before it's committed and inherited by future sessions.

Framework artifacts — rules, commands, planning documents — benefit from the same adversarial pressure as essays. An imprecise rule propagates as if it were precise. A guardrail designed with a logical flaw will be followed as designed. Sparring a rule before committing it is hygiene, not exception.

---

## Structured Session Entries — The Session-Start Briefing

For sessions where the scope is already decided, the `/start` orientation infrastructure can be replaced by a curated briefing document. Rather than loading the full project picture, the briefing tells the new session exactly what it needs: the scope, the deliverables, the constraints, the background. The session reads it and goes.

The distinction between what the briefing provides and what it doesn't is critical: **a briefing provides scope, not state**. It was written at a point in time; the repo may have changed since. The guardrail exists to catch that drift.

**Guardrail sequence (order matters):** Before the briefing's framing is absorbed, run a lightweight state check — git staleness (commits newer than the briefing's date), BACKLOG spot-check for items the brief references, deliverable conflicts (file already exists, work already done). If the check is clean, read the briefing for scope. If conflicts exist, surface them before executing anything. The check runs *before* the brief is read because once you've absorbed a briefing's framing, a conflict surfaces as a correction to a model already in place rather than a prevention.

The session-start briefing is also the mechanism for privacy-filtered handoffs: moving insights from a private session into a public context without crossing private content. The briefing is written at a level of generality the author is comfortable making public; the new session works only from what was written.

---

## The Meta-Development Loop — The Framework Improves Itself

The framework was built using the same tools it encodes. A gap was noticed — sessions drifted, handoffs decayed, adversarial review was absent — a tool was built to address it, the tool was applied immediately to real work, and the output reshaped what came next. The resulting case studies became source material for the next round of improvement.

This is documented at length in [The Meta-Development Loop](the-meta-development-loop.md). The relevant observation here: **the same loop applies to the framework itself**. When a rule produces unexpected behavior, spar it. When a command creates friction instead of reducing it, that friction is the signal. The framework is not a fixed specification — it's the current best version of a set of practices that keeps evolving as the work reveals gaps.

---

## How They Work Together

The behaviors are designed to bracket the places where AI-assisted multi-session work most commonly goes wrong:

```
[session start] → shoshin/orientation → [clean framing]
                                              ↓
[session work]  → stack tracking → [no thread loss]
                                              ↓
[branch closes] → capture check  → [nothing lost in conversation]
                                              ↓
[output produced] → sparring    → [challenged before committed]
                                              ↓
[session ends]  → checkpoint/handoff → [context survives]
```

None of these require the others. A session can use sparring without checkpoints, or checkpoints without a structured start. The framework is modular. The value of running them together is that each behavior covers a failure mode the others don't: orientation catches stale framing, stack tracking catches lost threads, capture checks catch ephemeral decisions, sparring catches weak outputs, and handoffs catch context that otherwise dies with the session.

The ethos behind the whole: **use AI tools heavily on real problems, with human-owned verification at every merge point.** Speed without mistaking fluency for truth.

---

## Related Reading

- [Sparring and Shoshin](sparring-and-shoshin.md) — the two structural practices for adversarial pressure and framing verification, in depth
- [Interaction Patterns for AI Sessions](interaction-patterns.md) — the meta-prompt pipeline and session-start briefing as structured patterns; when each fits
- [The Meta-Development Loop](the-meta-development-loop.md) — the engineering pattern behind building tools that improve AI workflows; the framework as a case study
- [Building Knowledge Management with AI](../case-studies/building-knowledge-management-with-ai.md) — the case study that prompted the original session orientation and handoff infrastructure
- [Heavy Safety Nets](../case-studies/heavy-safety-nets.md) — what happens when review processes are too rigid to follow; why the opt-in principle exists

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

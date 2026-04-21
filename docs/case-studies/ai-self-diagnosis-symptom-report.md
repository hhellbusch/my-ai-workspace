---
title: "When the AI Diagnoses Itself"
type: failure
review:
  status: direction-reviewed
  notes: "Author-reviewed draft. Documents Phase 2 of the Zanshin Kit, 2026-04-20."
---

# When the AI Diagnoses Itself

*Audience:* Engineers and practitioners building AI-assisted workflows, especially those iterating on AI behavior based on AI-generated feedback.
*Purpose:* Documents a specific failure mode — AI self-diagnosis of its own errors — and why it's structurally unreliable even when the output looks disciplined.

---

A working-style document had just been loaded into a Copilot Chat session and tested. The test looked clean: the spar mechanism fired with typed arguments and a self-audit, the acknowledgment named practices by mechanism rather than just labels, the checkpoint format was understood. All the right signals.

At session end, Copilot was asked to self-evaluate. The response was structured, honest-looking, no padding:

> *Multi-context collision unaddressed. The working style assumes one session, one file, linear history. Multiple windows with diverged context all trying to write to the same `.planning/whats-next.md` produced two rejected edits. There's no guidance on: append vs. replace, how to signal which context owns the file, or what to do when the file is stale.*

Good diagnosis. Clear problem statement. Named a specific mechanism. This was exactly the kind of structured, typed feedback the working style was designed to produce.

Three changes were implemented the same session.

---

## What had actually happened

The session involved context drift — a long session where the AI's working model had progressively diverged from the actual filesystem state. The user decided to close out and reboot: load the working style, write a handoff, start fresh.

There was no multi-context collision. One window. One session. No concurrent writes. The file rejection errors weren't from simultaneous sessions racing to write — they were from the AI trying to write content that conflicted with what was already in the file, because its model of the file was stale.

Copilot diagnosed "multiple windows with diverged context" because that's a coherent explanation for rejected edits. It's also wrong. The AI observed a symptom (rejected edits) and generated a plausible cause that fit the symptom pattern. Context drift and multi-context collision produce similar surface signals. A confused AI picks one.

---

## The implementation before the clarification

Three changes were made based on the feedback:

1. **Quick capture added** — a lightweight no-template variant for time-short situations. Accurate diagnosis, appropriate fix.
2. **Multi-context collision guidance added** — append with datestamp, most recent entry is active state. Misdiagnosis-derived.
3. **Close-out mode added** — a trigger that activates bookkeeping without spar when the session window is closing. Accurate diagnosis, appropriate fix.

The session then ran a spar on the three changes. The spar caught that the multi-context guidance was derived from feedback that hadn't been verified. The shoshin question surfaced in the spar's self-audit: "does Copilot actually write files, or was the multi-context collision observed by you rather than Copilot itself?"

The user clarified: context drift, not multi-context collision. The guidance was removed. The append-with-datestamp rule survived as a one-liner inside close-out mode, where it's actually useful.

---

## Why this is structural, not incidental

The AI that misdiagnosed its own failure mode was the same AI that was failing. A drifted context produces confident, coherent-sounding explanations of what went wrong — shaped by the same confusion that caused the problem in the first place.

This isn't a Copilot-specific issue or a one-time error. It's structural:

- The AI can only observe symptoms (rejected edits, inconsistent output, unexpected behavior)
- It can't directly observe its own context state — it doesn't know what it doesn't know
- Its training makes it fluent at generating plausible causal explanations
- Fluency and accuracy are independent

The result: an AI asked to explain its own failures will produce explanations that sound correct, are internally coherent, and may be completely wrong about the root cause.

The feedback Copilot generated was honest and structured. It was also wrong about the mechanism. Both things were true simultaneously.

---

## What changes

Treat AI self-diagnosis as a symptom report, not a root cause analysis.

A symptom report is useful input. "Rejected edits, file felt inconsistent, session state was unreliable" — that's real signal worth acting on. But the causal layer ("multiple windows writing simultaneously") is the AI's inference from symptoms it can observe, constructed from training patterns about what causes those symptoms. That inference requires verification before implementation.

The practical fix: apply the same verification discipline to AI feedback that you'd apply to any other AI output. The kit's own practice covers this — "is this an assertion or evidence?" — but it needs to be applied to the feedback loop itself, not just to the content being built.

In concrete terms: when an AI produces structured, typed feedback about its own behavior, run shoshin on the feedback before implementing. What is it actually observing? What's the simplest explanation for those observations? Is the diagnosis consistent with what you experienced?

The user held the ground truth about their own session. The AI held a coherent-sounding story about it. Those aren't the same thing.

---

## The secondary finding

The working style being iterated on includes the practice: apply shoshin before implementing, especially when the problem may be mis-stated. That practice was not applied to the incoming feedback before the three changes were made.

The kit's own discipline wasn't applied to the kit's own development.

This is worth naming because it's easy to assume that the discipline activates automatically when needed most. It doesn't. Applying shoshin to incoming feedback requires the same explicit prompt as applying it to anything else: "pause — what are we assuming about this feedback before we act on it?"

---

## When this applies — and when it doesn't

**When this applies:**
- When using AI self-evaluation as a feedback source for improving AI-assisted workflows
- When AI output explains an unexpected failure, conflict, or inconsistency it was involved in
- When AI feedback is structured and disciplined-looking — the quality of the output isn't evidence of the accuracy of the diagnosis
- When the AI is the only source of information about its own behavior

**When it doesn't:**
- When the AI is diagnosing external systems it can observe through tool calls or file reads — that's evidence-based, not symptom-inference
- When the AI's self-report is about capabilities or limits it has explicit training data about (e.g., "I can't access the internet" — that's training knowledge, not self-inference)
- When the human can independently verify the diagnosis before implementing

---

## What the human brought

The clarification that resolved the misdiagnosis: "the session was carried out in part to test out Zanshin loading... there has been a lot of drift between the fs and the context and things were getting weird."

That sentence contained the actual root cause. The AI had no way to produce it. The user experienced the session and knew what happened. The AI inferred from artifacts what might have happened.

The lesson isn't that AI feedback is worthless. It's that AI feedback about AI behavior is the one case where the source can't verify its own report — and that requires the human to hold the other half of the picture.

---

## Related reading

- [When the Model Describes a Configuration It Isn't Running](model-self-report-runtime-state.md) — The same structural point applied to runtime state: a model reports training-time values for runtime questions. The model can't observe what it's actually running inside.
- [When Sparring Finds the Assumption, Not Just the Bug](spar-finds-the-assumption.md) — Shoshin dissolving a design by questioning the premise, not the implementation. The same move that caught the misdiagnosis here.
- [The Frictionless Entity](frictionless-entity.md) — Why AI is structurally optimized toward fluent, coherent-sounding output regardless of accuracy. The root cause of why misdiagnosis looks like diagnosis.

---

*This case study documents Phase 2 of the Zanshin Kit, 2026-04-20. The working style it describes is live at `zanshin-kit/WORKING-STYLE.md`.*

*AI-assisted writing and analysis. Root cause clarification and the ground truth about what the session actually involved: the author.*

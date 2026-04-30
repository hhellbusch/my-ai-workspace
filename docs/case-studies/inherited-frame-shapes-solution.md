# The Frame You Inherited Shapes the Solution You Can See

> **Audience:** Anyone running multi-session AI-assisted work where early decisions accumulate into a shared context — especially builders of reference patterns, frameworks, or designs that evolve over many sessions.
> **Purpose:** Names the structural reason why AI review cannot challenge the organizing assumptions in your own documents — and what it takes to break free from them.
> *Context:* This workspace includes a GitOps reference pattern (`helm-component-pattern`) built over multiple sessions. A structural choice made early (presenting two implementation approaches, A and B) survived every review until the user explicitly rejected it. This documents why.

---

## The Pattern

When a design choice is embedded in a document that has become authoritative — a brief, a README, a planning document — all subsequent review of that document operates inside the same frame. The frame shapes what questions get asked. It cannot surface questions about itself.

The fix isn't more review. It's a mechanism that can interrupt the frame from outside it.

---

## The Case

The `helm-component-pattern` began with two implementation approaches: an `ApplicationSet`-based option (Approach A) and a `hub-clusters` Helm chart (Approach B). The A/B framing was an early structuring decision that made sense at the time — it communicated optionality, acknowledged trade-offs, and was technically accurate.

Over multiple sessions, the pattern evolved. Approach B became the clear recommendation. Approach A remained as a documented alternative. The comparison structure stayed intact.

`/spar` was run against the design. It challenged specific decisions within the pattern but didn't question whether the A/B framing still served anyone. `shoshin` was applied to check for session drift. It verified that the session matched the documents — which it did, because the documents themselves contained the framing.

The A/B structure was removed when the user said: "We don't need legacy things." Not after a review. After a judgment that the comparison structure had become overhead rather than value.

---

## Why AI Review Doesn't Catch This

`/spar` challenges content within a frame. If the argument *for* Approach B is weak, spar will find it. If the comparison is internally inconsistent, spar will find it. But "should this comparison exist at all?" is not a question spar asks — it inherits the document's structure as the thing to evaluate.

`shoshin` checks that sessions match documents. That's the right check for the common case: drift from an agreed-upon frame. But when the documents *are* the problem, shoshin confirms their authority rather than questioning it.

The mechanism that catches this is different in kind: a perspective that isn't inside the frame. A user decision to throw out a section. External feedback that says "I don't understand what this is trying to do." A deliberate "what would we remove if we started fresh?" prompt. These are human-originated interruptions, not AI review passes.

---

## The Fix

`shoshin.md` now includes a section — "When the Document Itself May Be Wrong" — with four explicit triggers for questioning whether the *organizing structure* of a document is still right, not just whether its contents are accurate:

1. External feedback reveals fundamental confusion about what the document is trying to do
2. A section survives multiple reviews unchanged but still feels off
3. The author's intent has evolved beyond what the brief can express
4. A major transition (first external review, publishing, handing off to a new contributor)

At each trigger, one question: *"Is the brief asking the right question — or is it a well-written answer to the wrong one?"*

This doesn't make AI review capable of catching frame problems. It creates named moments where the human is prompted to ask the question that AI review structurally cannot.

---

## What the Human Brought

The judgment that the comparison had become overhead. The instruction to remove it. No AI check or review surfaced the question — the user's shift in perspective did.

---

## When This Applies — and When It Doesn't

**Good fit:**
- Multi-session work where early structural decisions accumulate
- Reference patterns, frameworks, or designs that grow by accretion over time
- Any project where the organizing documents (brief, README, plan) have become authoritative — treated as the definition of what's being built rather than as a current draft
- Agentic workflows in YOLO mode where the agent inherits context from prior sessions without a human interruption between them

**Not needed for:**
- Single-session work where no prior frame exists
- Work where the organizing structure is externally mandated and not up for challenge
- Implementation tasks where the frame is fixed (the question is "does this work?", not "should this exist?")

---

## The Broader Principle

AI review optimizes within frames. It makes the content of a document better by the document's own standards. It cannot make the document question whether its standards are right.

Long-running projects accumulate frames. Each session starts from what the last session left behind. The longer a structure persists, the more authoritative it becomes — and the less visible the question "should this still exist?" becomes.

The shoshin extension names this ceiling explicitly: *"Shoshin catches drift between sessions and documents. It cannot catch a wrong frame embedded in the documents themselves — that requires a perspective that isn't inside the frame."* That's not a failure of the tool. It's an honest description of the limit, so the human knows where to look.

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

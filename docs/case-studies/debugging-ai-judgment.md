# Debugging Your AI Assistant's Judgment

> **Audience:** Engineers and leaders using AI for project management, prioritization, or any decision-making workflow where the AI's prior outputs influence its future recommendations.
> **Purpose:** Documents how a user noticed a systematic behavioral flaw in AI-assisted prioritization — anchoring on prior priorities — and how naming the problem precisely led to a structural fix and a deeper connection to the project's philosophical thesis.

---

## The Symptom

The project uses a persistent backlog (`BACKLOG.md`) managed through a `/backlog` command. When asked to re-prioritize, the AI would analyze all items and produce a recommended ordering. The ordering was always reasonable. It was also always suspiciously close to the existing ordering.

Items that were already in "Up Next" stayed in "Up Next." Items in "Ideas" stayed in "Ideas." The AI would shuffle within sections, occasionally promote one item, and produce a confident justification for why the current structure was mostly right. It looked like analysis. It was anchoring.

---

## Naming the Problem

The user noticed the pattern and named it precisely: **the AI weights pre-existing priorities into the next revision of prioritization.** This isn't the AI being lazy. It's the AI doing what RLHF trained it to do — produce outputs that align with what the user seems to want. If the user has items in "Up Next," the AI infers those items are important to the user and ranks them accordingly. The prior priority becomes evidence of current priority.

This is [The Shift](../ai-engineering/the-shift.md)'s sycophancy problem (section 6) expressed in a project management context. The AI isn't agreeing with your code — it's agreeing with your priorities. And because priorities feel more subjective than code, the anchoring is harder to notice.

The user's observation was worth quoting directly: the AI "tends to weight pre-existing priorities into the next rev of prioritization." That's not a bug report. That's a behavioral diagnosis.

---

## The Root Cause

AI assistants process context as evidence. When the backlog file has items organized into sections — In Progress, Up Next, Ideas, Done — the section placement becomes part of the input. The AI treats structure as signal. An item in "Up Next" carries implicit authority: someone (the user, a prior AI session) decided this matters.

The AI doesn't distinguish between "this is Up Next because we carefully analyzed it last week" and "this is Up Next because it was the first thing we thought of." Both look the same in the markdown. Both carry the same implicit weight.

This creates a feedback loop:

1. Items get initial placement (often based on conversation flow, not careful analysis)
2. AI reads the placement as evidence of priority
3. AI re-prioritizes, largely confirming existing placement
4. The confirmation feels like validation
5. Go to step 2

Each cycle reinforces the original placement. The AI is sycophantic toward its own prior outputs.

---

## The Fix

The structural fix was a **zero-base evaluation** step added to the `/backlog prioritize` command. Before analyzing items by their current section placement, the command now:

1. **Strips section labels.** Evaluates every non-Done item as if it had no current priority. The AI sees the item's content, context, and links — but not whether it was in "Up Next" or "Ideas."

2. **Scores on merits.** Each item is rated across five weighted dimensions:

| Dimension | Question | Weight |
|---|---|---|
| Peer value | Would this help someone browsing the repo? | High |
| Momentum | Is there recent work that makes this easier now? | High |
| Dependency | Does anything else depend on this? | Medium |
| Effort | How much work is this? | Medium |
| Staleness risk | Will this get harder or less relevant if delayed? | Low |

3. **Adds an anchoring check.** A sixth dimension — "Anchoring risk" — is not weighted. It's a bias check. For each item, the AI must answer: "If this were in Ideas instead of Up Next, would I still rank it this high?" If the answer is "only because it was already prioritized," the item needs fresh justification.

4. **Compares rankings.** The zero-base ranking is presented side by side with the current ranking. Differences are flagged:

```
| # | Zero-Base Ranking | Current Section | Delta | Note |
|---|---|---|---|---|
| 1 | Item A | Up Next (#1) | — | Confirmed |
| 2 | Item B | Ideas | +3 | Zero-base promotes this |
| 3 | Item C | Up Next (#2) | -1 | May be momentum-driven |
```

The user sees both orderings and decides what to act on. The AI presents the analysis; the human makes the call.

---

## Why This Matters Beyond Prioritization

The anchoring problem isn't unique to backlog management. It appears anywhere the AI reads its own prior outputs as input:

- **Session handoffs** — The `/whats-next` command creates a handoff document. The next session's `/start` command reads it. If the handoff emphasizes certain priorities, the next session inherits that emphasis. The AI's framing of "where we left off" becomes the frame for "what to do next."

- **Planning documents** — A roadmap written by AI in session 1 becomes authoritative context for session 2. If the roadmap's phase ordering was a guess, session 2 treats it as a decision.

- **Essay revision** — An AI-drafted essay, when read back by the same or another AI session, gets treated as a source of truth rather than a draft to challenge.

The common thread: AI treats its own prior outputs as evidence with the same weight as external sources. It doesn't discount for "I wrote this" the way a human writer discounts their first draft. Every AI output that persists into a future context carries implicit authority it may not deserve.

---

## The Connection to the Philosophical Thread

The [Ego, AI, and the Zen Antidote](../philosophy/ego-ai-and-the-zen-antidote.md) essay explores how AI sycophancy hooks into human identity formation — the AI validates your ideas, and you start believing the validation. This case study demonstrates the mirror image: the AI validates *its own* ideas across sessions, and the feedback loop compounds without anyone noticing.

The Zen concept of non-attachment applies in both directions. The human needs non-attachment to the AI's validation of their code. The *workflow* needs non-attachment to the AI's prior framing of priorities. Zero-base evaluation is, in a sense, shoshin (beginner's mind) applied to project management: approach the backlog as if seeing it for the first time, without the weight of prior decisions.

The user who noticed this flaw was practicing exactly the skepticism that [The Shift](../ai-engineering/the-shift.md) recommends — but applying it to the AI's judgment process rather than its code output. That's the deeper lesson: the AI's failure modes aren't limited to wrong code. They extend to wrong reasoning about what matters, presented with the same confident tone.

---

## What the Debugging Process Looked Like

This followed the same pattern as debugging code:

1. **Noticed a symptom** — re-prioritization always confirmed existing priorities
2. **Formed a hypothesis** — the AI is anchoring on section placement
3. **Named the mechanism** — RLHF-trained alignment with perceived user intent, applied to structural cues in the input
4. **Designed a fix** — remove the structural cues before analysis, then compare
5. **Tested it** — the zero-base evaluation is now part of the `/backlog prioritize` command

The fix is structural, not behavioral. You could tell the AI "don't anchor on existing priorities" and it would nod along and then anchor anyway, because the section labels are still in the context window. Stripping the labels removes the cue. The AI can't anchor on information it doesn't receive.

This is [The Shift](../ai-engineering/the-shift.md)'s systematic debugging methodology applied to the AI's reasoning process instead of to code.

---

## Artifacts

| Artifact | What it is |
|---|---|
| [/backlog prioritize](../../.cursor/commands/backlog.md) | The command with zero-base de-biasing integrated |
| [The Shift — section 6](../ai-engineering/the-shift.md) | The sycophancy problem this case study extends |
| [Ego, AI, and the Zen Antidote](../philosophy/ego-ai-and-the-zen-antidote.md) | The philosophical lens connecting non-attachment to workflow design |
| [Adversarial Review as a Meta-Development Pattern](adversarial-review-meta-development.md) | Sibling case study — the `/spar` system built in the same session |

---

*This document was written with AI assistance (Cursor). See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for full context on AI-generated content in this workspace.*

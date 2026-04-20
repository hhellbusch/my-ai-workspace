---
title: "When Sparring Finds the Assumption, Not Just the Bug"
type: workflow
review:
  status: direction-reviewed
  notes: "Author-reviewed draft. Case study documents a session from 2026-04-20."
---

# When Sparring Finds the Assumption, Not Just the Bug

*Audience:* Engineers and practitioners who use adversarial review (/spar or equivalent) as a quality gate.
*Purpose:* Documents two different things a spar can catch — implementation errors and unexamined assumptions — and why the second is harder to find and more valuable.

---

A feature was being designed: a private workspace layer, a local git repo ignored by the parent, for work that shouldn't be published. The use case was concrete — preparing for a promotion panel across multiple sessions without any of that work appearing in the public repo.

The design was straightforward. A `private/` folder. Its own git history. The framework (session orientation, checkpoints, handoffs) would integrate with it.

Then `/spar` ran against the plan. And then again.

---

## First spar: finding the bugs

The first adversarial review found real implementation errors.

The `/whats-next` command evaluated whether a session was fully persisted by checking: is the public working tree clean? Is the public BACKLOG current? If yes — "no handoff needed." After a session spent entirely in `private/`, both checks would pass. The public tree *is* clean. The public BACKLOG *is* current. The safety mechanism gives a green light when private work may be uncommitted and lost.

The `/checkpoint` command had the same problem. It read git state from the public repo and wrote the checkpoint to the public handoff location. Running it mid-private-session produced a checkpoint that accurately described the public repo and said nothing about the private work in progress.

These were real bugs. The plan was updated to fix them: detection logic to identify which session was active, new steps in `/checkpoint` to check private git status, updated branching in `/start` to handle dual handoff files.

The fixes worked. But they added complexity. `/start` acquired dual-handoff detection and a routing question. `/checkpoint` gained a new Step 0 with four-point branching logic. `/whats-next` needed an additional check sequence. Three commands, each now more complex than before.

---

## Second spar: finding the complexity

The second adversarial review targeted the plan after the fixes.

The argument: `session-awareness.md` is an `alwaysApply: true` rule. It's in context on every session, before any command runs. The private session rules — which git repo, which handoff location, which backlog to update — belong there, not replicated across three commands. The commands were now doing behavioral routing that the rule layer already handled. The detection logic (compare file mtimes, check two git repos, branch on the result) was complexity equivalent to an explicit mode command, just hidden inside inference machinery that was harder to debug.

This was also right. But the more important observation came from the user, not the spar.

---

## The assumption beneath the bugs

> "I only want to evaluate or load private stuff into context if I explicitly ask for it."

That's the line that changed the design.

The entire previous architecture assumed the framework should automatically detect session context — which handoff is active, whether private work is uncommitted, whether to route to public or private. That assumption was never stated. It was never examined. It followed naturally from "fix the false green light problem" and "make it seamless," and it accumulated across two rounds of design iteration.

The assumption was wrong. The public/private boundary should be enforced by intent, not inference. The framework doesn't need to detect which context is active. The user knows. They'll say so.

With that reframe, most of the complexity dissolved. Not by fixing the detection logic but by removing it. The session-awareness rule got one bullet: private content is opt-in, don't auto-check. The commands stayed unchanged. `private/README.md` carries the usage conventions and is only read when you ask to work privately — which is exactly the right time.

The plan went from eight todos touching four commands to six todos touching one bullet in one rule.

---

## What the two spars caught differently

The first spar caught **implementation errors** — specific, mechanical failures where the commands would behave incorrectly given the new feature. It found real bugs and the fixes were real fixes.

The second spar caught **complexity drift** — the accumulation of fixes had made the commands heavier than the problem warranted. This led toward the assumption.

The assumption itself wasn't surfaced by either spar. It was surfaced by the user applying shoshin: beginner's mind on the design principle underlying the feature. "Why is the framework detecting this? Do I want it to?" The answer was no. That single question dissolved most of the design.

The pattern:
- **First spar:** finds what's broken
- **Second spar:** finds what's heavy
- **Shoshin:** finds what was assumed

Each step operates at a different level. The bugs are visible once you look for them. The complexity is visible once you've fixed the bugs. The assumption is only visible when you stop and ask whether the frame is right.

---

## The side effect: a framework principle

The case study doesn't end with the feature. It ends with something that was extracted from it.

The opt-in principle is now encoded in `workspace-ethos.md`:

> New capabilities added to the framework default to opt-in. Before wiring anything into always-running commands, ask: does the user need this on every session, or only when they ask? If the answer is "only when they ask," keep it opt-in.

This wasn't the goal of the design session. It emerged as a side effect — a generalization that the specific design forced into the open.

The framework was already drifting in the direction the principle corrects. `/start` loads planning project BRIEFs and ROADMAPs for every project on every session start, whether or not you're working on those projects. That's a cost paid on every session for context that's only useful some sessions. The private layer, by making the opt-in choice explicit, made the existing drift visible.

A backlog item now exists for a `/start` simplification audit. The principle is the seed; that audit is the harvest.

---

## When this applies — and when it doesn't

**When this applies:**
- Any design process that goes through multiple revision rounds: run the first spar for bugs, the second spar for complexity, and then ask whether the underlying assumption is right before implementing.
- When fixes to a design produce more structure than the original problem: that's the signal that an assumption may be driving the complexity rather than the requirements.
- When a feature defaults to "automatic" behavior: test whether opt-in would serve the use case as well with less framework weight.

**When it doesn't:**
- When a feature genuinely needs to run on every session. Some things are worth the cost: BACKLOG.md is large and `/start` loads it every time, but knowing what's in progress is actually necessary for session orientation. Not everything that runs automatically is worth challenging.
- When the first spar found the real problem and the fix is right. Not every design needs a second pass. Two spars were warranted here because the first round added meaningful complexity; if the fixes had been small, one round would have been enough.

---

## What the human brought

The design process had two turns that the AI couldn't have originated:

1. **"I only want to evaluate or load private stuff if I explicitly ask."** — The decision that collapsed the design. The AI was solving "how to detect session context automatically." The user rejected the premise.

2. **"This feedback was not just about this current plan — but the overall system / framework in general."** — Applying the principle beyond the immediate feature. The AI would have fixed the feature; the user connected it to the framework's broader trajectory.

Both were shoshin moves: questioning the frame rather than optimizing within it.

---

## Related reading

- [When the Safety Net Is Too Heavy to Use](heavy-safety-nets.md) — A similar pattern: a process that was technically correct but too rigid to follow in practice. The fix required reducing structure, not adding more.
- [When a Spar Argument Outgrows Its Essay](spar-to-essay-pipeline.md) — The opposite direction: spar as a generative tool that produces more work. Here, spar as a simplification tool that reduces it.
- [Building a Personal Knowledge Management System with AI](building-knowledge-management-with-ai.md) — Relevant to the "infrastructure trap" observation: building the meta-system can become its own project.

---

*This case study documents a session from 2026-04-20. The private workspace layer it describes is live in this workspace; the promotion panel content that will use it has not yet begun.*

*AI-assisted writing and analysis. Final framing and both shoshin interventions by the author.*

---
review:
  status: unreviewed
  notes: "First draft. Framing and argument structure need author read before citing."
---

# Prompting Is Necessary but Not Sufficient

> **Audience:** Engineers using AI assistants for work that spans multiple sessions.
> **Purpose:** The standard advice for AI-assisted work centers on prompting skill: better prompts produce better outputs. This is correct and important. It's also incomplete. For work that spans days or weeks, the harder challenge isn't producing good outputs within a session — it's keeping work coherent *across* sessions. These are different problems with different tools.

---

## The Standard Advice Is Right

The prompting literature addresses a real problem. Vague prompts produce vague outputs. Specificity, framing, constraints, examples — these genuinely move output quality. An engineer who has developed a feel for how to decompose a problem into a clear prompt, how to give the AI the right context at the start, how to iterate when the first output misses, produces better work with AI than one who hasn't.

Sparring and shoshin build on this: structured adversarial review catches what fluent prompting still misses; beginner's mind at session start prevents inheriting a prior session's stale framing. These are prompting-adjacent skills — how to interact with AI effectively, how to counter its characteristic failure modes within a session.

None of this is wrong. The quality ceiling for any given session does depend substantially on how well you work with AI in that session.

---

## The Boundary Where Prompting's Leverage Ends

For single-session tasks — a script, a document, a one-off analysis — prompting skill is the primary lever. The session starts, you work, the session ends with a deliverable. The problem fits inside the window.

For work that spans multiple sessions — a multi-week project, a growing documentation corpus, a sustained engineering track — a different problem appears that prompting skill doesn't address: **what does the next session start from?**

Not "what prompt will make this session's output better." The prior question: what context does this session even have? What was decided three sessions ago? What does the current file state actually say, as opposed to what the model thinks it said two hours into the last session when context compaction was shrinking everything to summaries? What framing was established in a conversation that no longer exists, and is the current session inheriting it without noticing?

A skilled prompter who starts a session from stale or missing context produces skilled outputs that don't connect to prior work. The quality problem moves upstream.

---

## What Happens Without It

The failure modes compound slowly and don't announce themselves:

**Framing drift.** A project is defined as X early in session one. By session five, the model treats it as Y — a natural extension of how session four framed it. Nobody made a decision to change course. The framing migrated, session by session, in small increments that each seemed locally reasonable.

**Re-litigated decisions.** Session six re-examines whether to use approach A or approach B. The reasons for choosing A were documented in session three. The new session doesn't know that. The discussion produces the same conclusion, or a different one, with no record of either exchange.

**Output that's locally correct, globally incoherent.** Each session produces fluent, responsive output. The work within each session is of genuine quality. The sessions don't add up. Connections between documents are missing. Assumptions that were settled in one session show up as open questions in another.

These failures don't look like AI failures. The model performed well in each session. The problem lives in the gaps between sessions, where no model output covers anything and no practitioner naturally lingers.

---

## What State Management Actually Means

State management isn't just "write better handoffs." It's a practice of treating session boundaries as the highest-risk moment in multi-session work — the moment where context loss is guaranteed and the quality of what gets preserved determines whether future sessions build on accurate ground or on approximations.

The specific practices:

**Commits as truth anchors.** In-context memory of file contents may be compressed; the committed file is always accurate and re-readable. Frequent small commits mean the authoritative state of the work is always current and always accessible.

**Structured session close.** Not a summary for the next session's convenience — an examination of what the session *actually* produced versus what it felt like it produced. Decisions that existed only in conversation, scope changes that weren't reflected in planning documents, context that accumulated and then compressed.

**Session-start orientation.** Reading what was committed before generating output. Not trusting the summary or the handoff in isolation — checking it against the current file state. This is where the inherited framing from a prior session gets either confirmed or questioned.

**Captured decisions.** A backlog that includes *why* a decision was made, not just what was decided. This is what makes re-litigation visible — "we already decided this, here's why" requires having written down the reasoning when the decision was made.

None of these is a substitute for prompting skill. They're additive — they determine whether the inputs to each session are accurate, which determines whether good prompting has accurate material to work with.

---

## Why Both Compound Together

Prompting skill and state management address adjacent failure modes. Prompting addresses quality within the session. State management addresses coherence across sessions. The failure modes are independent enough that each can be present without the other.

A practitioner with strong prompting skill and weak state management produces high-quality individual sessions that don't add up to coherent long-horizon work. The sessions are good; the project is fragmented.

A practitioner with strong state management and weak prompting skill produces well-connected sessions whose individual output quality is limited by how poorly they're extracting value from the AI within each session. The project is coherent; the sessions are mediocre.

Both skills together compound: each well-executed session builds accurately on the prior one, and the quality of each session's output is genuinely high. This is the only configuration that scales to multi-week and multi-month AI-assisted work without progressive quality loss.

The standard advice to invest in prompting skill is correct. For anyone whose work extends across session boundaries — which includes most substantive engineering and writing work — the investment that compounds on top of prompting is state management. These are different problems, and noticing the difference is the first step to addressing both.

---

## Related Reading

| Resource | What it covers |
|---|---|
| [The Session Framework — Patterns, Behaviors, and Why](session-framework.md) | The operational map: what each behavior defends against and how they connect |
| [Sparring and Shoshin](sparring-and-shoshin.md) | The two practices that address in-session quality — adversarial review and beginner's mind |
| [Zanshin — What Remains When the Session Ends](../philosophy/zanshin.md) | The philosophical framing: why session boundaries are the hardest moment, and why the framework is named for the awareness that persists after completion |
| [When AI Ignores Changes Made by Other Sessions](../case-studies/stale-context-in-long-sessions.md) | A concrete failure mode: one agent's state overwrites another's changes because cross-session context wasn't maintained |
| [The Shift — Engineering Skills in the Age of AI](the-shift.md) | The foundational essay: what changes when AI handles implementation, and what skills matter more now |

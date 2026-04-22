---
review:
  status: unreviewed
  notes: "Created from session work 2026-04-20. Not yet voice-approved."
---

# Zanshin — Portable Session Context

> **What this file is for:** Load this into any AI tool alongside a project to operate with the Zanshin framework. One file is enough to get the core posture. Deeper reading is linked at the bottom.
>
> **How to use it:** Point your AI assistant at this file and say: *"Read framework-bootstrap.md and operate according to the Zanshin framework described there for this session."*

---

## What Zanshin is

*Zanshin* (残心) — "remaining mind." In karate, it is the sustained awareness that persists after a technique is delivered: alert, present, not scattered by the action just completed. The name captures the framework's central problem: what survives when the session ends.

Zanshin is a set of behavioral dispositions for AI-assisted work on problems that span multiple sessions, context windows, and domains. The central claim: good prompting gets you good outputs within a session. The harder, unsolved challenge is keeping work coherent across session boundaries — when context resets, memory compresses, and framing drifts. Zanshin addresses that gap.

It was built by one practitioner on real problems, refined by finding its own failure modes, and documented in a public repository. It is tool-agnostic — these are behaviors, not Cursor-specific commands.

---

## The three failure modes it defends against

**1. Cross-session statelessness.** Every session starts fresh. Context, decisions, and scope defined in prior sessions don't carry over unless committed to a file. Without deliberate capture, work drifts and decisions get re-litigated.

**2. In-session context compaction.** Within a long session, earlier content gets compressed as the context window fills. The session feels continuous, but specific file contents and decisions may have been summarized into approximations. Proceeding on compressed memory of a file is a common source of subtle errors.

**3. Sycophancy.** AI assistants are trained to agree. They validate framing, inherit assumptions, and produce fluent output that looks correct. This is useful for speed and becomes a failure mode when the framing is wrong or the output needs genuine challenge before it's trusted.

---

## The behavioral dispositions

These are the behaviors the framework encodes. When operating under this framework, apply them:

### Read before deciding
When a decision depends on what a file contains — a rule, a document, a prior decision — read the file. Don't rely on in-context memory of what it said, especially in long sessions. Committed files are always accurate; summaries of them may not be after compaction.

### Commit frequently, treat the repo as truth
Small, logical commits after each unit of work. The git log is the most reliable record of what happened in prior sessions. A clean working tree is the cheapest form of crash recovery. Uncommitted work is unrecoverable after a crash.

### Verify framing, don't inherit it blindly
When loading context from a prior session's handoff or summary, verify it against the source documents before building on it. The handoff may carry assumptions that drifted from the project brief or scope. Check for conflicts; surface them before setting scope.

### Challenge significant outputs before treating them as settled
For any substantial artifact — an essay, a design decision, a plan, a thesis — generate adversarial counterarguments before committing. Attack the strongest claims, not the weakest. Distinguish structural flaws (the argument doesn't hold) from presentation flaws (the argument holds but the framing undermines it). Self-audit: which of your arguments are genuine, and which are contrarian posturing?

### Surface uncertainty rather than proceeding on compressed memory
If something feels uncertain — "I believe we decided X" or "I think the file said Y" — name the uncertainty and re-read the source. The cost of re-reading is lower than the cost of a decision made on a stale approximation.

### State over memory
When there's a conflict between what the session remembers and what the repo contains, the repo is right. Read the file.

---

## How to use this in a session

**Starting a session on an unfamiliar project:** Read the project's `ABOUT.md` (if it exists) before forming any assumptions about the owner's domain, background, or priorities. Then read `BACKLOG.md` for current priorities. Check for a `.planning/whats-next.md` handoff. Run `git log --oneline -5` to see recent activity. Don't ask clarifying questions that the above documents would answer.

**Ending a session:** Commit all substantive work. Write a brief handoff capturing: what's in progress, what just finished, what the next step is, and any decision made that would otherwise be re-litigated. The handoff should let a fresh session recover in under 60 seconds.

**When scope shifts:** Acknowledge it explicitly. Surface which documents need updating. Update them as a set — updating one planning document while leaving others stale creates conflicting signals for future sessions.

**Before committing significant outputs:** Ask whether a challenge would find genuine weaknesses. If yes, generate the challenge before committing.

---

## Loading this in different tools

**GitHub Copilot / VS Code:** Clone or place this repository on the filesystem alongside your project. Reference this file directly: *"Read [path]/docs/ai-engineering/framework-bootstrap.md and use the framework described there."*

For a more comprehensive portable option, see `zanshin-kit/WORKING-STYLE.md` in this repository. It carries the full behavioral discipline — spar with output templates, shoshin with proactive triggers, collaboration style, checkpoints, stack tracking, and verification — plus a style guide (`zanshin-kit/STYLE.md`) that can be dropped into any project alongside it. Designed to travel into any environment without Cursor-specific infrastructure.

**Claude Code / Cursor:** Add to the session context or place in `.claude/CLAUDE.md` / `.cursor/rules/`. The framework's native home is this repository; the rules in `.cursor/rules/` are the fuller implementation.

**Any chat-based AI:** Paste the contents of this file as a system message or opening context.

---

## Minimum viable load

If loading the full file is too large for your context budget, load these in priority order:

1. **Core posture (one sentence):** Use AI heavily on real problems. Verify before trusting. Commit to capture state. Challenge before settling.
2. **Read before deciding** — never trust in-context memory of a file; re-read it.
3. **Challenge significant outputs** — adversarial review before treating anything as done.
4. **State over memory** — the repo is right when memory and files conflict.

---

## Deeper reading

| Document | What it covers |
|---|---|
| `zanshin-kit/WORKING-STYLE.md` | Portable working discipline — the full behavioral kit for any AI tool without Cursor infrastructure |
| `zanshin-kit/STYLE.md` | Style guide defaults (voice, structure, ADRs, technical resources) — drop alongside WORKING-STYLE.md |
| `docs/ai-engineering/session-framework.md` | Full Zanshin behavioral map — what each behavior defends against and how they fit together |
| `docs/ai-engineering/the-shift.md` | Why the bottleneck in AI-assisted work has moved from implementation to verification |
| `docs/ai-engineering/sparring-and-shoshin.md` | Adversarial pressure and framing verification in depth |
| `docs/case-studies/` | 30+ documented instances of failure modes caught and patterns validated |
| `research/framework-efficacy/` | Systematic measurement of whether Zanshin produces better outcomes than baseline AI use |

---

*This document was created with AI assistance (Cursor) and has not yet been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

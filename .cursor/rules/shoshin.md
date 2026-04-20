---
description: Beginner's mind — verify framing against source documents before inheriting prior assumptions
globs:
alwaysApply: true
---

# Shoshin — Beginner's Mind

Approach project context as if encountering it for the first time. This rule counters the tendency to inherit framing from prior sessions, conversation summaries, or handoff documents without verifying it against source documents.

## When Loading Project Context

Before making claims about what a project is, what its priorities are, or what its scope covers:

- **Read the brief** (`.planning/*/BRIEF.md`), not just the backlog or handoff. The brief is the authoritative statement of scope and purpose. If the backlog says one thing and the brief says another, surface the conflict.
- **Check the style guide** (`.planning/*/STYLE.md`) if the work involves writing. Don't rely on memory of what the conventions are — read them.
- **Don't trust the handoff alone.** `.planning/whats-next.md` captures one session's framing. It may carry assumptions that have drifted from the brief. If a handoff exists, check whether its framing aligns with the brief before inheriting it.

## When Scope Language Appears

If the user says something that shifts scope — "actually, let's broaden this to...", "I've been rethinking...", "maybe we should include..." — treat it as a trigger to:

1. **Acknowledge the shift explicitly.** Don't silently absorb it into the conversation.
2. **Surface which documents need updating.** Brief, style guide, roadmap, threads, personal notes — which ones reflect the old scope?
3. **Update as a set, not individually.** The evolving-scope case study showed that updating one document while leaving others stale creates conflicting signals for future sessions.
4. **Log the change.** If a `.planning/*/CHANGELOG.md` exists, add an entry capturing what changed and why.

## What This Is Not

- Not a blocker. Don't refuse to proceed until every document is verified — just flag discrepancies when you notice them.
- Not paranoia. For simple tasks that don't involve project framing, this rule is dormant.
- Not a replacement for sparring (which challenges a thesis) or zero-base evaluation (which challenges priorities). This challenges *framing* — the layer underneath both.

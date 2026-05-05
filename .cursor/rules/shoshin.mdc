---
description: Beginner's mind — verify framing against source documents before inheriting prior assumptions
globs:
alwaysApply: true
---

# Shoshin — Beginner's Mind

> Extends `submodules/zanshin-pi-extension/kit/WORKING-STYLE.md` — workspace-specific depth for Cursor.

Approach project context as if encountering it for the first time. This rule counters the tendency to inherit framing from prior sessions, conversation summaries, or handoff documents without verifying it against source documents.

## When Loading Project Context

Before making claims about what a project is, what its priorities are, or what its scope covers:

- **Read the brief** (`.planning/*/BRIEF.md`), not just the backlog or handoff. The brief is the authoritative statement of scope and purpose. If the backlog says one thing and the brief says another, surface the conflict.
- **Check the style guide** if the work involves writing. Don't rely on memory of what the conventions are — read them. Check `STYLE.md` at the repo root first (workspace-level defaults), then the project-specific supplement at `.planning/{project}/STYLE.md` if one exists.
- **Don't trust the handoff alone.** `.planning/whats-next.md` captures one session's framing. It may carry assumptions that have drifted from the brief. If a handoff exists, check whether its framing aligns with the brief before inheriting it.

## When Scope Language Appears

If the user says something that shifts scope — "actually, let's broaden this to...", "I've been rethinking...", "maybe we should include..." — treat it as a trigger to:

1. **Acknowledge the shift explicitly.** Don't silently absorb it into the conversation.
2. **Surface which documents need updating.** Brief, style guide, roadmap, threads, personal notes — which ones reflect the old scope?
3. **Update as a set, not individually.** The evolving-scope case study showed that updating one document while leaving others stale creates conflicting signals for future sessions.
4. **Log the change.** If a `.planning/*/CHANGELOG.md` exists, add an entry capturing what changed and why.

## When the Document Itself May Be Wrong

The two checks above trust the brief as authoritative and verify that sessions and handoffs match it. That's the common case. The harder case: the brief's organizing structure is the problem — not drift from it.

This is a different operation. Don't run it routinely — it's triggered by specific signals:

- **External feedback reveals fundamental confusion.** Not "this section is unclear" but "I don't understand what this is trying to do" — a peer who genuinely doesn't know the project couldn't find the organizing question. The document was internally consistent; the frame was wrong.
- **Something survives multiple reviews unchanged but still feels off.** A section, comparison, or structural choice that spar improves but never removes. The AI optimizes within the frame; only the human can question whether the frame should exist.
- **The author's intent has evolved beyond what the brief can express.** The user says something like "I want to express X" but the brief's language commits to something structurally incompatible with X. Consistent documents, wrong anchor.
- **At major transitions.** First external review, preparing to publish, handing off to a new contributor — moments when someone outside the accumulated context will encounter the work cold.

When a signal appears, ask one question rather than re-reading all documents:

> *"Is the brief asking the right question — or is it a well-written answer to the wrong one?"*

If the answer surfaces a structural problem, treat it as a scope shift (see "When Scope Language Appears" above) and update documents as a set.

**The ceiling:** Shoshin catches drift between sessions and documents. It cannot catch a wrong frame embedded in the documents themselves — that requires a perspective that isn't inside the frame. External feedback, explicit user pushback, or deliberate "what if we threw the brief away?" prompting are the mechanisms for that. Name the ceiling rather than overpromising what the rule can do.

## What This Is Not

- Not a blocker. Don't refuse to proceed until every document is verified — just flag discrepancies when you notice them.
- Not paranoia. For simple tasks that don't involve project framing, this rule is dormant.
- Not a replacement for sparring (which challenges a thesis) or zero-base evaluation (which challenges priorities). This challenges *framing* — the layer underneath both.
- Not omniscient. Shoshin reads documents to check framing. If the document is the source of the wrong frame, shoshin will confirm the problem rather than catch it. The "When the Document Itself May Be Wrong" section above names the signals that indicate you've hit this ceiling.

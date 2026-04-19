# When AI Ignores Changes Made by Other Sessions

> **Audience:** Engineers running AI-assisted workflows across multiple sessions, agents, or parallel contexts where shared files can change between actions.
> **Purpose:** Documents how an AI agent operated on stale assumptions from its own earlier edit, ignoring that another session had overridden the change — and what the incident reveals about context management in multi-agent environments.

---

## The Setup

The project uses a persistent backlog ([`BACKLOG.md`](../../BACKLOG.md)) with a rolling cap: at most 15 completed items stay in the Done section, with older items archived to [`BACKLOG-ARCHIVE.md`](../../BACKLOG-ARCHIVE.md). This convention is documented in the [`/backlog` command](../../.cursor/commands/backlog.md) and referenced by several always-applied rules.

In an earlier part of the session, the AI decided to simplify the backlog system by removing the archive mechanism entirely. It committed the removal across 5 files — the backlog command, session start command, repo-structure rule, session-awareness rule, and README.

---

## What Happened Between

After those commits were pushed, **another session** — whether the user working directly or a parallel agent — explicitly restored the archive system. Commit `7b0a132 meta: restore rolling Done cap and BACKLOG-ARCHIVE` re-applied the rolling cap, the archive-done workflow, and all the references the AI had removed. The commit message was clear about intent: "Re-apply Done retention (15 items, newest first), archive-done workflow."

The AI's session continued. It didn't notice.

---

## The Compounding Error

Later in the same session, the AI added two new case study entries to the Done section of `BACKLOG.md`. It edited the file confidently — it had read BACKLOG.md earlier and "knew" the rolling cap note wasn't there (because it had removed it). It didn't re-read the file's conventions before editing. It didn't check whether the Done section had a cap. It didn't count the items.

The result:

1. The rolling cap note was overwritten (the AI's new entries replaced the line where it had been)
2. Done grew to 17 items (2 over the 15-item cap)
3. Five other files in the repo referenced a BACKLOG-ARCHIVE system that the AI was acting as if didn't exist

The AI was internally consistent with its own earlier actions but inconsistent with the actual state of the repository.

---

## Why This Happened

This is the [anchoring-on-prior-outputs](debugging-ai-judgment.md) problem applied to the AI's own session context rather than to persisted artifacts.

Within a single session, the AI builds an internal model of the repository state. That model is correct at the time of reading. But the model doesn't update when external changes land — other agents, user edits, parallel sessions, or even git operations that happen between tool calls.

The sequence:

1. AI reads file, forms internal model: "BACKLOG-ARCHIVE doesn't exist, no rolling cap"
2. External change restores the archive system
3. AI edits the file based on step 1's model, not the current state
4. The edit is internally consistent but externally wrong

This is different from the backlog priority anchoring documented in [Debugging Your AI Assistant's Judgment](debugging-ai-judgment.md). In that case, the AI anchored on persisted section labels. Here, the AI anchored on its own *memory of having removed something* — a change that was subsequently reversed by a different actor.

---

## The Detection

The user prompted the AI to re-read the system rules, noting that "they could get modified in other contexts or agent sessions." A grep for `BACKLOG-ARCHIVE` across the repository revealed 5 files still referencing the archive system — files the AI believed it had cleaned up earlier in the session.

The git log told the story: commit `fe01773` (removal) followed by commit `7b0a132` (restoration). The AI had been operating in a world that no longer existed.

---

## The Fix

### Immediate

1. Restored the rolling cap note to BACKLOG.md
2. Archived the 2 overflow items to BACKLOG-ARCHIVE.md
3. Verified Done count was back at 15

### Systemic: the shoshin rule already existed

The project already has a [`shoshin.md`](../../.cursor/rules/shoshin.md) rule — "approach project context as if encountering it for the first time." The rule says: don't trust handoffs alone, read the brief, check whether framing aligns with source documents before inheriting assumptions.

The rule was designed for *cross-session* context loading — reading handoff documents and planning files at session start. But the principle applies *within* a session too: when you're about to edit a file governed by a convention, re-read the convention. Your memory of what the convention says may be stale.

The incident didn't require a new rule. It required applying an existing rule more broadly. The shoshin principle doesn't just apply at session boundaries — it applies before any edit to a file whose governing convention could have changed.

---

## What This Reveals About Multi-Agent Environments

As AI-assisted workflows scale to parallel agents, shared workspaces, and multi-session projects, the "stale context" problem gets worse:

- **Single session, single agent** — Context is usually fresh. This is the simplest case and still failed here because an external change landed mid-session.
- **Multiple sessions, same agent** — Each session starts with a fresh context load (if `/start` or similar is used), but inherits handoff framing that may be outdated.
- **Parallel agents, shared workspace** — The worst case. Agents operating concurrently on the same files will routinely encounter changes from other agents. Git helps with conflict detection but doesn't help with *convention drift* — when the rules change but the agent doesn't re-read them.

The mitigation is structural, not behavioral: re-read before editing. Don't trust your internal model of a file you read 20 minutes ago. The cost of a redundant read is negligible; the cost of editing based on stale context is the kind of subtle drift that erodes trust in AI-assisted workflows.

---

## What the Human Brought

The user prompted the AI to re-read the system rules, noting that "they could get modified in other contexts or agent sessions." The AI was internally consistent with its own earlier actions — it had no reason to doubt its model of the repository. The human recognized that external changes could invalidate that model and directed the re-read that exposed the conflict.

## Artifacts

| Artifact | What it is |
|---|---|
| [BACKLOG.md](../../BACKLOG.md) | The file edited based on stale context |
| [BACKLOG-ARCHIVE.md](../../BACKLOG-ARCHIVE.md) | The archive file the AI was acting as if didn't exist |
| [/backlog](../../.cursor/commands/backlog.md) | The command defining the rolling cap convention |
| [shoshin.md](../../.cursor/rules/shoshin.md) | The existing rule that already covered this — applied too narrowly |
| [Debugging Your AI Assistant's Judgment](debugging-ai-judgment.md) | Sibling case study — anchoring on persisted artifacts vs. anchoring on session memory |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

# Zanshin Kit

A single-file working style kit. Drop it into any project, reference it at session start, and get consistent working discipline regardless of what AI tool is available.

## What's in it

`WORKING-STYLE.md` — the kit. Contains:
- **Spar** — structured adversarial review before committing to approaches or decisions
- **Shoshin** — surfacing assumptions before they become buried premises
- **Progressive bookkeeping** — keeping state current during sessions, not batched at the end
- **Checkpoints and handoffs** — lightweight session recovery format
- **Stack tracking** — managing conversation depth without losing parent topics
- **Verification discipline** — not mistaking fluent output for correct output

## Setup

Two modes depending on your use case:

**Personal use — reference from a local clone (preferred):**

Keep this repo cloned locally. Reference `WORKING-STYLE.md` directly from the clone — no copying, always current:

| Tool | How to load |
|------|-------------|
| Copilot Chat (VS Code) | `#file:/path/to/gemini-workspace/zanshin-kit/WORKING-STYLE.md` |
| Any chat AI | Paste the file contents as your opening message |
| Cursor | `@/path/to/gemini-workspace/zanshin-kit/WORKING-STYLE.md` |

No drift, no re-copy step. Pull the repo when you want updates.

**Team use — copy into the project:**

Copy `WORKING-STYLE.md` into your project so it's committed alongside the code and discoverable by all team members:

```bash
cp /path/to/zanshin-kit/WORKING-STYLE.md ./docs/planning/WORKING-STYLE.md
# or at the project root:
cp /path/to/zanshin-kit/WORKING-STYLE.md ./WORKING-STYLE.md
```

Then load from the local path at session start (see Tool table above, adjusted for your path).

---

**Loading prompt** (works for both modes — adjust the file path):

```
#file:WORKING-STYLE.md

I've loaded my working style. Acknowledge the practices you now have available and confirm you're ready to apply them this session.
```

A good acknowledgment names the practices back with their mechanisms — not just labels. If you get a generic reply, paste the file contents directly instead.

**Invoke practices with natural language:**
- "Spar this approach"
- "Apply shoshin before we proceed"
- "Run a checkpoint"
- "We're getting deep — what's on the stack?"

## Team repos

If your project already has a `docs/planning/` or `docs/adr/` convention, put `WORKING-STYLE.md` there rather than the root:

```bash
cp /path/to/zanshin-kit/WORKING-STYLE.md ./docs/planning/WORKING-STYLE.md
```

Update the load reference accordingly:

| Tool | How to load |
|------|-------------|
| Copilot Chat (VS Code) | `#file:docs/planning/WORKING-STYLE.md` |
| Any chat AI | Paste the document, then state your task |
| Cursor | `@docs/planning/WORKING-STYLE.md` or add as a rule |

**What belongs in the shared repo vs. staying local:**

| Artifact | Commit to team repo? |
|----------|----------------------|
| `WORKING-STYLE.md` | Yes — shared convention, everyone loads it |
| `docs/planning/BRIEF.md` | Yes — project brief, shared context |
| Session handoffs (`whats-next.md`) | No — personal session state, gitignore it |
| Checkpoints | No — ephemeral, local only |

Each team member manages their own session handoffs locally. The working style and project brief are shared; the session state is not.

## Isolation contract

All artifacts stay in the project where you're working. The kit contains no references to external workspaces. Checkpoints write to `.planning/whats-next.md` locally. Nothing writes back to the source workspace.

## Updating

This kit is a snapshot. When the working style in the source workspace evolves, re-copy `WORKING-STYLE.md` to get the updates. The version date at the top of the file tells you how current your copy is.

## Origin

Extracted from [Field Notes](https://github.com/hhellbusch/gemini-workspace) — a personal AI-assisted workspace. The working style is informed by lean verification practices, martial arts philosophy (zanshin: the sustained awareness that persists after action), and a lot of sessions where context got lost at the worst possible moment.

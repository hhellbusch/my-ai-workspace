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

**Copy the file into your project:**
```bash
cp /path/to/zanshin-kit/WORKING-STYLE.md ./WORKING-STYLE.md
```

**Load it at session start:**

| Tool | How to load |
|------|-------------|
| Copilot Chat (VS Code) | Include `#file:WORKING-STYLE.md` in your first message |
| Any chat AI | Paste the document as your opening message, then state your task |
| Cursor | Reference as `@WORKING-STYLE.md` or add as a rule |

**That's it.** The practices are active for the session. Use natural language to invoke them:
- "Spar this approach"
- "Apply shoshin before we proceed"
- "Run a checkpoint"
- "We're getting deep — what's on the stack?"

## Isolation contract

All artifacts stay in the project where you're working. The kit contains no references to external workspaces. Checkpoints write to `.planning/whats-next.md` locally. Nothing writes back to the source workspace.

## Updating

This kit is a snapshot. When the working style in the source workspace evolves, re-copy `WORKING-STYLE.md` to get the updates. The version date at the top of the file tells you how current your copy is.

## Origin

Extracted from [Field Notes](https://github.com/hhellbusch/gemini-workspace) — a personal AI-assisted workspace. The working style is informed by lean verification practices, martial arts philosophy (zanshin: the sustained awareness that persists after action), and a lot of sessions where context got lost at the worst possible moment.

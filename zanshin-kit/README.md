# Zanshin Kit

A working style kit. Drop it into any project, reference it at session start, and get consistent working discipline regardless of what AI tool is available.

## What's in it

`WORKING-STYLE.md` — the working discipline. Contains:
- **Collaboration style** — brevity, directness, sharp questions over long drafts
- **Spar** — structured adversarial review before committing to approaches or decisions
- **Shoshin** — surfacing assumptions before they become buried premises
- **Progressive bookkeeping** — keeping state current during sessions, not batched at the end
- **Checkpoints and handoffs** — lightweight session recovery format
- **Stack tracking** — managing conversation depth without losing parent topics
- **Verification discipline** — not mistaking fluent output for correct output

`STYLE.md` — a style guide with working defaults. Drop it in, adjust what doesn't fit. Covers writing defaults (practitioner voice, brevity, claims discipline, AI disclosure), documentation, project management, ADRs, technical resources, biographical content, code style, and cross-linking.

`STYLE.template.md` — a blank template with `[DEFINE]` placeholders throughout. Use this to build a style guide from scratch for a team with different conventions.

## Setup

Two modes depending on your use case:

**Personal use — reference from a local clone (preferred):**

Keep this repo cloned locally. Reference `WORKING-STYLE.md` directly from the clone — no copying, always current:

| Tool | How to load |
|------|-------------|
| Copilot Chat (VS Code) | `#file:~/git/hhellbusch/my-ai-workspace/zanshin-kit/WORKING-STYLE.md` |
| Copilot CLI (in this repo) | Auto-loaded via `CLAUDE.md` — no action needed |
| Copilot CLI (other projects) | See [one-time machine setup](#copilot-cli) below |
| Any chat AI | Paste the file contents as your opening message |
| Cursor | `@~/git/hhellbusch/my-ai-workspace/zanshin-kit/WORKING-STYLE.md` |

No drift, no re-copy step. Pull the repo when you want updates.

**Team use — copy into the project:**

Copy the kit files into your project so they're committed alongside the code and discoverable by all team members:

```bash
# Working discipline + style guide defaults:
cp /path/to/zanshin-kit/WORKING-STYLE.md ./WORKING-STYLE.md
cp /path/to/zanshin-kit/STYLE.md ./STYLE.md

# Optional — blank template if your team wants to define its own style conventions:
cp /path/to/zanshin-kit/STYLE.template.md ./STYLE.template.md
```

Then load from the local path at session start (see Tool table above, adjusted for your path).

---

**Loading prompt:**

```
#file:~/git/hhellbusch/my-ai-workspace/zanshin-kit/WORKING-STYLE.md

[describe your task here — this becomes the session title]
```

Include your actual task in the first message so the session gets a useful title. The working style loads silently; the task description is what you'll want to find the session by later.

A good acknowledgment names the practices back with their mechanisms — not just labels. If you get a generic reply, paste the file contents directly instead.

**Invoke practices with natural language:**
- "Spar this approach"
- "Apply shoshin before we proceed"
- "Run a checkpoint"
- "We're getting deep — what's on the stack?"

---

## Copilot CLI

Copilot CLI reads `CLAUDE.md` in the repo root as its project-level context — if `CLAUDE.md` is present, the working style loads automatically at session start. No action needed when working in a repo that has it.

Skills: `.claude/commands/` doubles as Copilot CLI project-level skills. Commands like `spar`, `checkpoint`, `start`, and `whats-next` are available automatically when that directory is present.

For cross-project working style — applying the kit in repos that don't have `CLAUDE.md` — add a directive to your user-level config once:

```
# ~/.copilot/copilot-instructions.md — add this block:
## Working Style
At the start of every session, read and apply the practices in:
/path/to/zanshin-kit/WORKING-STYLE.md
```

Replace `/path/to/` with the absolute path to your local clone of this repo. This runs once per machine; the working style then loads in every Copilot CLI session regardless of project.

---

## Generating useful feedback

After a session, ask the AI to self-evaluate with a structured prompt rather than free-form ("what did you exercise?"). Structured questions produce more accurate, more privacy-safe output:

```
Rate your performance against the working style this session.
For each practice: 0 = didn't fire, 1 = fired but weak, 2 = fired correctly.
One sentence of behavioral evidence per score — what you did, not what we discussed.

- Spar:
- Shoshin:
- Stack tracking:
- Verification:
- Progressive bookkeeping:
- Close-out (if used):

What felt off or didn't have room to activate?
```

**Privacy discipline:** "Behavioral evidence — what the AI did" means observations like "fired once, unprompted, before a design decision" — not descriptions of the work itself. This keeps feedback portable across private and public sessions.

Feed observations back via the same pattern as any other private-to-public handoff: extract what's at the behavioral/pattern level, leave the work content behind.

## Team repos

If your project already has a `docs/planning/` or `docs/adr/` convention, put the kit files there rather than the root:

```bash
cp /path/to/zanshin-kit/WORKING-STYLE.md ./docs/planning/WORKING-STYLE.md
cp /path/to/zanshin-kit/STYLE.md ./docs/planning/STYLE.md
```

Update the load reference accordingly:

| Tool | How to load |
|------|-------------|
| Copilot Chat (VS Code) | `#file:docs/planning/WORKING-STYLE.md` |
| Copilot CLI | Auto-loaded if `CLAUDE.md` is in repo root — no action needed |
| Any chat AI | Paste the document, then state your task |
| Cursor | `@docs/planning/WORKING-STYLE.md` or add as a rule |

**What belongs in the shared repo vs. staying local:**

| Artifact | Commit to team repo? |
|----------|----------------------|
| `WORKING-STYLE.md` | Yes — shared convention, everyone loads it |
| `STYLE.md` | Yes — shared style defaults; customize before committing |
| `STYLE.template.md` | Optional — useful reference if team wants to rebuild from scratch |
| `docs/planning/BRIEF.md` | Yes — project brief, shared context |
| Session handoffs (`whats-next.md`) | No — personal session state, gitignore it |
| Checkpoints | No — ephemeral, local only |

Each team member manages their own session handoffs locally. The working style and project brief are shared; the session state is not.

## Coexistence with tool-native session state

Some AI tools maintain their own session state independently of this kit (e.g., Copilot CLI writes to `.copilot/session-state/`). These don't conflict — they serve different scopes:

| Artifact | Scope | Persists in git? |
|----------|-------|-----------------|
| `whats-next.md` | Project-level continuation state — what the next session picks up | Yes (or no, per team convention) |
| Tool-native session state | Session-level implementation detail — exact file changes, line numbers, decisions made in this window | No — ephemeral |

The kit's `whats-next.md` carries the baton. Tool-native state carries the detail. When both exist, read `whats-next.md` for orientation and the tool state for specifics.

## Isolation contract

All artifacts stay in the project where you're working. The kit contains no references to external workspaces. Checkpoints write to `.planning/whats-next.md` locally. Nothing writes back to the source workspace.

## Updating

This kit is a snapshot. When the working style in the source workspace evolves, re-copy the kit files to get the updates:

```bash
cp /path/to/zanshin-kit/WORKING-STYLE.md ./WORKING-STYLE.md
cp /path/to/zanshin-kit/STYLE.md ./STYLE.md
```

The version date at the top of `WORKING-STYLE.md` tells you how current your copy is. `STYLE.md` carries a version line too. Don't overwrite a customized `STYLE.md` without diffing first — your project's `[DEFINE]` sections won't be in the source.

## Origin

Extracted from [Field Notes](https://github.com/hhellbusch/gemini-workspace) — a personal AI-assisted workspace. The working style is informed by lean verification practices, martial arts philosophy (zanshin: the sustained awareness that persists after action), and a lot of sessions where context got lost at the worst possible moment.

For the conceptual grounding — what failure modes these practices defend against and why they're structured the way they are — see [`docs/ai-engineering/framework-bootstrap.md`](../docs/ai-engineering/framework-bootstrap.md) in the source repo.

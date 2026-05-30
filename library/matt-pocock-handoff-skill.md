---
title: "/handoff is my new favourite skill"
speaker: Matt Pocock
channel: Matt Pocock
date: 2026
url: https://www.youtube.com/watch?v=dtAJ2dOd3ko
wing: ai-engineering
tags: [ai-engineering, context-engineering, handoff, dumb-zone, session-continuity, skills, multi-agent]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# Matt Pocock — /handoff is my new favourite skill

## Source

- **Speaker:** Matt Pocock (skills.new, ~100k stars)
- **URL:** https://www.youtube.com/watch?v=dtAJ2dOd3ko
- **Duration:** 12:25
- **Transcript:** [cached](../research/ingest-queue/sources/handoff-is-my-new-favourite-skill.md)

---

## About

Matt Pocock explains his `/handoff` skill — a context window compressor that creates a focused markdown document for a fresh agent session. Covers how it differs from built-in `compact`, the dumb zone, and three specific patterns (scope isolation, grilling + prototype, DIY sub-agent). Also introduces the "design concept" artifact independently of Dex Horthy.

---

## The dumb zone (independent corroboration)

> "Around the 120k token mark, I start to feel like I'm in the dumb zone. So this means yes that even though Anthropic advertises a ton of context window, really for proper smart tasks you've only got about 120k to work with."

Smart zone = early context, fewer attention relationships, better focus. Dumb zone = accumulated context, diffuse attention, degraded performance. Matt's practical threshold is 120k, not 40% — both are the same structural phenomenon at different scales.

---

## Handoff vs. compact

| | Compact | Handoff |
|---|---|---|
| Purpose | Continue the same long-running session | Start a fresh focused session |
| What it does | Summarizes + continues in-place | Creates a portable markdown doc |
| Use case | Debugging marathon | Scope fork, sub-agent, cross-tool |
| Risk | "Sediment" from multiple compactions | Disposable — save to `/tmp`, not codebase |

Compact is good for barging through one thing. Handoff is for when you want to keep your current session clean and fork off a parallel context.

---

## Three key patterns

**1. Scope isolation**
> "I want to complete this other thing in a separate session and keep my current session pure."
Notice a refactoring opportunity mid-session → handoff the out-of-scope work → two independent sessions, both in their smart zones.

**2. Grilling → prototype → back**
Grilling session surfaces unknown-unknowns that need prototyping. Handoff to prototype session → 169k token prototype session runs → handoff the learnings back to the grilling session. "Almost like you've done a kind of DIY sub agent."

**3. Cross-agent portability**
> "The thing that's cool about just using a markdown document here and not relying on native agent stuff is that you can have this first session be Claude Code, but you can just pass this to another agent."
Plain markdown → works with Claude Code, Codex, Copilot CLI, Cursor. Simple adversarial review between coding agents.

---

## Handoff skill design rules

- **Save to `/tmp`** — not the codebase. Handoff docs are disposable.
- **Use pointers, not duplication** — reference existing markdown files and issues; don't re-copy their content
- **Include suggested skills** — tell the next session what skills to invoke so it picks up with the right flavor
- **Redact sensitive info** — API keys, passwords, PII before handing off
- **Require the purpose as an argument** — "I can't see how you'd write a good handoff document without knowing what the next session will focus on"

---

## Connections to this workspace

- `/handoff` is the external equivalent of the workspace's `/checkpoint` + `/whats-next` skills — the same problem solved independently with nearly identical structure
- The dumb zone observation independently corroborates [Dex Horthy — Everything wrong about RPI](dex-horthy-everything-wrong-rpi.md)
- The DIY sub-agent pattern (parent → fork → child → return) maps to the parallel agent worktree approach in `rules/git-worktrees.md`
- "Suggested skills in the handoff doc" = the workspace's handoff `whats-next.md` linking to relevant BRIEF.md and skills — same encoding instinct
- Connects to: [Simon Scrapes — Memory Systems](simon-scrapes-claude-code-memory-systems.md) (handoff doc = L2 external conversation memory)

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

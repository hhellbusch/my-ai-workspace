---
title: "Building pi in a World of Slop"
speaker: Mario Zechner (creator of Pi, MCI, MCApps)
channel: AI Engineer
date: 2026
url: https://www.youtube.com/watch?v=RjfbvDXpFls
wing: ai-engineering
tags: [harness, context, minimal-agent, pi, verification, slop, oss]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# Mario Zechner — Building pi in a World of Slop

## Source

- **Speaker:** Mario Zechner (creator of Pi / the Pi agent used in this workspace)
- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=RjfbvDXpFls
- **Duration:** 18:11
- **Transcript:** [cached](../research/ingest-queue/sources/building-pi-in-a-world-of-slop-mario-zechner.md)

---

## About

A "tragedy in three acts" from AI Engineer London 2026. Act 1: Why Zechner built Pi (context ownership, minimal harness thesis). Act 2: Clankers destroying OSS. Act 3: Why agent slop is compounding and how to slow down. Opinionated, funny, and technically grounded. Notable: Zechner is the creator of Pi — the agent used in this workspace via the Zanshin and Paude extensions.

---

## Key themes

### Context ownership — "my context wasn't my context"

Claude Code modifies context behind your back: system prompt changes with every release, tool definitions added/removed, irrelevant "this may or may not be relevant" injections mid-context. The harness that controls context controls the model's behavior. If you don't own your context, you don't own your agent.

### Minimal harness thesis

Terminal Bench (minimal benchmark: model gets only a tool to send keystrokes to tmux and read output) scores at or above native model harnesses regardless of model family. Less harness = less context pollution = better outcomes. Pi has 4 tools: read, write, edit, bash. That's the core.

### Self-modifying agents

Pi ships documentation and code examples of its own extensions. Tell Pi what you need; it writes the extension and hot-reloads it. The agent adapts to the workflow, not the other way around. Extensions are TypeScript modules, distributable on NPM.

### Agents compound errors with no natural bottleneck

Humans feel pain — when the codebase becomes unmaintainable, humans eventually refactor or quit. Agents don't. They have:
- Zero learning (no update to weights from session experience)
- No bottleneck (no natural limit on booboos per day)
- Delayed pain (broken code surfaces later, to you, not the agent)

A review agent is an ouroboros — it catches some issues but was trained on the same garbage.

### Models learned from garbage code

90% of code on the internet is mediocre. Models reproduce complexity, abstractions, duplication, and backward-compatibility scaffolding from that training set. "Enterprise-grade complexity within 2 weeks with two humans and 10 agents."

### "A sufficiently detailed spec is a program"

Blanks in a spec get filled with garbage the model learned from the internet. If the spec is sufficiently detailed to constrain the model, you've written the program.

### Practical guidance — scope, review, slow down

- Scope agent tasks so the agent is guaranteed to find everything it needs: modularize the codebase
- Give it an evaluation function when possible (hill climbing)
- Non-critical code: slop ahead. Critical code: read every line
- Write important things by hand — friction builds understanding of the system
- Cap the amount of generated code you need to review
- Learn to say no — "your most valuable capability right now"

### Clankers destroying OSS

Autonomous agents flood GitHub with garbage PRs/issues. OSS maintainers filtering strategies: human-voice PR requirement, vouch system, deprioritize clanker-labeled issues, 3D issue cluster embeddings to spot duplicates.

---

## Connections to this workspace

- **Pi in this workspace** — the Pi agent is this workspace's Zanshin and Paude extension host. Zechner is directly relevant as the upstream author.
- **Harness problems — interface layer** — "my context wasn't my context" is the strongest articulation of interface bleed: the harness modifies context without your knowledge.
- **Harness ≥ model** — Terminal Bench minimal harness outperforming native harnesses is the empirical benchmark version of the thesis.
- **Trust, but verify / read every line** — "critical code: read every line" is the concrete implementation of the verification posture.
- **What stays human** — humans feel pain; agents don't. Pain is the feedback loop that drives quality. Human judgment and bottlenecking are features, not bugs.
- **The dojo after the automation** — friction (writing by hand) builds understanding; removing friction removes learning.

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

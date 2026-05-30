---
title: "AgentCraft: Putting the Orc in Orchestration"
speaker: Ido Salomon (creator of AgentCraft, MCI, MCApps)
channel: AI Engineer
date: 2026
url: https://www.youtube.com/watch?v=kR64LOqBBCU
wing: ai-engineering
tags: [multi-agent, orchestration, visibility, harness, gaming-metaphor]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# Ido Salomon — AgentCraft: Putting the Orc in Orchestration

## Source

- **Speaker:** Ido Salomon (creator of AgentCraft, MCI, MCApps)
- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=kR64LOqBBCU
- **Duration:** 11:10
- **Transcript:** [cached](../research/ingest-queue/sources/agentcraft-putting-the-orc-in-orchestration-ido-salomon.md)

---

## About

Short product demo / talk from AI Engineer London 2026. Salomon argues the multi-agent scaling problem is not agent capability — it's human orchestration capacity. Introduces AgentCraft as a gaming-inspired orchestration UI that raises the ceiling on how many agents a human can effectively manage.

---

## Key themes

### The human bottleneck

Spinning up 10 or 100 agents is easy. Orchestrating them isn't. The bottleneck shifts to the human managing them — a role engineers haven't had to perform before, but that maps naturally to skills from gaming.

### Gaming as the mental model

RTS (real-time strategy) game skills — managing dozens of units, muscle-memory cycling between active agents, rapid decision-making under parallel work — transfer directly to multi-agent orchestration. These aren't new skills; they've been sitting in games.

### AgentCraft visibility layer

- File system projected as a map; files as rooms; agents visually positioned where they're working
- Heatmap overlay to detect and prevent agent collisions (two agents editing the same file)
- Full lineage: which agent did what, when
- Muscle-memory cycling through agents needing approval or answers

### Campaign feature: shift from planning to review

Broad task description → container spun up → agents decompose, plan, execute autonomously. Human effort moves to planning input and review output, not babysitting mid-execution. Review bundles: visual evidence (screenshots, video) for efficient PR review without deep re-reading.

### Human-agent-agent collaboration

Cross-team workspaces where multiple engineers can see each other's agents, hand off work between human-started and agent-continued workstreams, and communicate via a shared chat that agents also read.

---

## Connections to this workspace

- **Krentsel + Parsons** — confirms the parallel agent coordination failure pattern (Parsons: parallel agents with dependency graphs failed; Salomon builds tooling to manage this problem). Campaign feature is the structured answer to that failure.
- **Harness ≥ model** — the orchestration layer (human attention, visibility, collision prevention) is the differentiator, not the underlying models.
- **What stays human** — planning and review remain human; execution and decomposition delegate. The campaign feature makes this explicit.

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

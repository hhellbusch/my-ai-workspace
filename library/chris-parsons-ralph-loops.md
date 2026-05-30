---
title: "Ralph Loops: Build Dumb AI Loops That Ship"
speaker: Chris Parsons (Cherrypick)
channel: AI Engineer
date: 2026
url: https://www.youtube.com/watch?v=2TLXsxkz0zI
wing: ai-engineering
tags: [agentic-loops, harness, skills, context, workflow]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# Chris Parsons — Ralph Loops: Build Dumb AI Loops That Ship

## Source

- **Speaker:** Chris Parsons (CTO / consultant, Cherrypick)
- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=2TLXsxkz0zI
- **Duration:** ~1h 48m (workshop format)
- **Transcript:** [cached](../research/ingest-queue/sources/ralph-loops-build-dumb-ai-loops-that-ship-chris-parsons-cherrypick.md)

---

## About

A hands-on workshop on "Ralph loops" — a simple agentic pattern where the AI is instructed to re-attempt the same task after claiming completion. Named after Ralph Wiggum (The Simpsons): just try it again until it works. The talk contrasts brittle n8n-style workflow orchestration with simple loops + skills, and progresses through increasingly powerful loop patterns: single-shot retry → ticket-driven loops → parallel attempts with selective acceptance.

---

## Key themes

### The Ralph loop

Re-run the same prompt after the AI says it's done. The AI reviews its own work and catches what it missed. Named after Ralph Wiggum (Simpsons): "try the same thing again until it works."

Original insight credited to Geoffrey Hinton Lee: always retry after AI completion. The dumbest implementation: `while true; do claude implement ticket; done`.

With modern models (GPT-4.1+, Sonnet 3.7+), the single-task retry matters less — models complete more cleanly — but the loop pattern scales to ticket batches.

### Simple loops > complex orchestration

Parsons moved from an n8n workflow for his weekly newsletter (weeks to build, brittle, broke every Monday) to a Claude Code skill that loops through the same task. The skill works better and is self-improving: he ends each run with "update the skill with what you should have done differently."

### Ticket-driven loops

Point the loop at a folder of tickets rather than a single task. The loop picks up each ticket, implements it, and moves to the next. Sequential and simple — no dependency graph required.

Parallel agent orchestration with pre-specified dependency graphs failed: agents contended on shared tickets, created duplicate implementations, recreated waterfall pathologies. Sequential ticket loops avoid this.

### Context management in loops

Each loop iteration ideally starts fresh — don't carry context from prior iterations unless intentional. Stale context in loops degrades quality and introduces accumulated assumptions.

### Self-improving skills

After a loop run: "Update the skill with anything you should have done differently." The skill improves over time without manual editing. This is Software 3.0 in practice: the skill is the program, and it updates itself.

---

## Connections to this workspace

- **Krentsel matryoshka** — Ralph loops are Krentsel's Loop 3/4 (scoped agent / autonomous shell) made concrete. The ticket folder is the task backlog; the loop is the outer shell.
- **Skills** — Parsons' newsletter skill is exactly the Agent Skills pattern: a workflow recipe, not an MCP server.
- **Harness ≥ model** — same model, different loop discipline → very different outcomes. The harness (loop structure, ticket format, context management) is the differentiator.
- **Software 3.0** — "update the skill with what you should have done differently" is Software 3.0 maintenance: the context (skill) is the program.

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

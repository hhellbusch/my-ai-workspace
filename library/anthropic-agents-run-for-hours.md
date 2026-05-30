---
title: "Anthropic Workshop: Build Agents That Run for Hours"
speaker: Ash Prabaker & Andrew Wilson (Anthropic Applied AI)
channel: AI Engineer
date: 2026
url: https://www.youtube.com/watch?v=mR-WAvEPRwE
wing: ai-engineering
tags: [ai-engineering, long-running-agents, harness, gan-evaluator, context-anxiety, ralph-loop, verification, multi-agent, anthropic]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# Anthropic — Build Agents That Run for Hours

## Source

- **Speakers:** Ash Prabaker & Andrew Wilson, Anthropic Applied AI
- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=mR-WAvEPRwE
- **Duration:** 1:15:26
- **Transcript:** [cached](../research/ingest-queue/sources/anthropic-workshop-build-agents-that-run-for-hours-ash-prabaker-andrew-wilson.md)

---

## About

Anthropic's own workshop on building agents that run for hours (5–12 hour sustained tasks). Andrew Wilson gives a historical tour of Claude Code evolution; Ash Prabaker presents experimental harness patterns including GAN-style generator/evaluator loops. Primary source for context anxiety, skills progressive disclosure, and the generator-evaluator contract pattern.

---

## The three problems for long-running agents

1. **Context:** Finite window + context rot (less coherence deep in session) + **context sense anxiety** (model rushes to finish when near the end of its context window)
2. **Planning:** Models attempt one-shot completion, build half a feature and stop, or run out of context mid-task
3. **Verification:** Models are bad at judging their own output — they'll call a half-implemented feature "done" because it looks finished

---

## Progression from 1 hour to 12 hours (Sonnet 3.7 → Opus 4.6)

| Model | Harness-minimal 50%-task-completion run time |
|---|---|
| Opus 3.7 | ~1 hour |
| Opus 4 | ~4 hours |
| Opus 4.5 | ~30 hours (with sub-agent economy) |
| Opus 4.6 | ~12 hours (minimal scaffold) |

Key insight: **harness and model co-evolve.** Each release ships harness changes alongside model improvements. The harness fills in current model gaps; those gaps get baked into the next model's training; the harness evolves to fill new gaps.

---

## The GAN-style harness (experimental)

Borrowed from generative adversarial networks: separate **generator** and **evaluator** with their own context windows and adversarial pressure.

Why a standalone evaluator works better than self-review:
> "Tuning a standalone critic to be harsh is very tractable. Tuning a builder to be self-critical is not."

The evaluator doesn't just read diffs — it runs Playwright, opens live pages, clicks around, and grades against a rubric (design, originality, craft, functionality). If the generator keeps failing one criterion, the harness discards and restarts from scratch — which a single-session Ralph Loop can't do.

---

## The generator-evaluator contract pattern

Before writing a single line of code, generator and evaluator negotiate what "done" means:
- Generator proposes: "I'll build X, you should test Y"
- Evaluator pushes back: "Scope too big, tests too weak, you missed Z"
- Both iterate via files on disk until agreement
- Evaluator grades against the *contract*, not the original spec

> "This bridges user stories (the spec) and converts them into testable assertions without the planner over-specifying upfront."

This is the key innovation missing from the Ralph Loop: adversarial pressure on the plan itself, not just the implementation.

---

## Three-role architecture (PM / IC / QA)

> "If you squint at this, it's just a very simple PM, IC, and QA org structure. We didn't invent this. We just gave each role its own context window."

- **Planner:** takes the one-line prompt, breaks down into high-level sprints (not granular technical details — errors in granular planning cascade)
- **Generator (IC):** implements features, proposes done criteria
- **Evaluator (QA):** grades against contract, provides critique, can restart

---

## Other patterns from the historical tour

- **Fresh context windows per feature** — each feature starts a new session; persistent state lives in JSON files (models less likely to overwrite JSON than markdown)
- **Verification loops** — use Puppeteer/Playwright to actually test the feature, not just read code
- **Skills progressive disclosure** — only the front matter of a skill loads initially; full body loads only when instantiated. This reduces context overhead significantly.
- **Programmatic tool calling** — instead of running many tools individually and pulling all results into context, write code to batch tool calls and return only the final result

---

## Connections to this workspace

- Context sense anxiety explains why the "dumb zone" slides matter: the model isn't just less capable — it's rushing
- The generator-evaluator contract pattern is a concrete implementation of the spar + shoshin bracket: adversarial pressure on the plan before execution
- Fresh context + persistent JSON artifacts maps to the workspace's git-as-truth-anchor pattern (whats-next.md + committed state)
- Skills progressive disclosure validates the workspace's skill design: front matter routing is the right pattern
- Relates to: [Dex Horthy — RPI](dex-horthy-everything-wrong-rpi.md) (harness design, fresh context), [Matt Pocock — handoff](matt-pocock-handoff-skill.md) (session continuity), [Chris Parsons — Ralph Loops](chris-parsons-ralph-loops.md) (the original technique referenced here)
- The "harness co-evolves with the model" claim directly supports the workspace philosophy: harness investment compounds over time

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
title: "Fixing the PR Bottleneck"
speaker: Matt Pocock (AIHero)
channel: AI Engineer
date: 2026
url: https://www.youtube.com/watch?v=LlgiOCmFG_w
wing: ai-engineering
tags: [ai-engineering, pr-review, harness, skills, automated-checks, deep-modules, slop, one-way-door, retro]
review:
  status: unreviewed
  notes: "AI-generated summary and evaluation. Needs read and sources-checked before citing."
---

# Matt Pocock — Fixing the PR Bottleneck

## Source

- **Speaker:** Matt Pocock (AIHero / aihero.dev/skills)
- **Channel:** AI Engineer (Paris)
- **URL:** https://www.youtube.com/watch?v=LlgiOCmFG_w
- **Duration:** 22:35
- **Transcript:** [cached](../research/matt-pocock-fixing-pr-bottleneck/sources/fixing-the-pr-bottleneck-matt-pocock-aihero.md)
- **Assessment:** [research assessment](../research/matt-pocock-fixing-pr-bottleneck/assessment.md)

---

## About

22-minute AI Engineer talk on the PR review bottleneck under agentic throughput. Thesis: software factories accelerate initiation and volume; without designed **brakes**, you get a "slop cannon." Three layered brakes — automated checks, automated review, human review — make human attention scarce and high-leverage. Announces / iterates skills in the AIHero skills repo (v1.3), including codebase design, code review, PR, and retro.

---

## Key principles

### Acceleration needs brakes

Agent- and signal-driven initiation (classifiers, slow-query alerts, etc.) push more code through the factory. Brakes slow things down *in order to go faster*: quality mechanisms that keep the codebase from becoming entropy the next agent inherits.

> "If you just have permanent acceleration pushing stuff through your factory, you're going to end up with a slop cannon."

### Three-layer cake

1. **Automated checks** — lint, tests, types, metrics (cheap CPU; deterministic)
2. **Automated review** — agent lie-detector for what checks miss / structure quality
3. **Human review** — scarce attention; made faster by stacking the first two

First principle of the stack: **stop the slop** — raise ship quality so humans intervene less.

### Checks are cheap and can lie

Green CI ≠ merge-ready. Agent failure modes called out:

- **Tautological tests** — reassert the implementation (`expect(limit).toBe(280)` testing a constant)
- **Structure-sensitive tests** — assert source-file order instead of rendered behavior
- **Unfailable tests** — over-mocking (e.g. stubbing AudioContext so error modes never run)

Fix path: **codebase design** — deep modules (Ousterhout): hide complexity behind a small interface so agents test at the seam, not internals. Shared vocabulary: locality, leverage, seams.

### Implementation is overloaded; review is underloaded

Don't put coding standards in the implement agent / `AGENTS.md` global scope — explore + edit + debug already fill the window. Put standards in `coding-standards.md` consumed by a **review sub-agent** with its own context. Mental model: implement = make it work; review = make it good (red-green-refactor across two windows).

> "Stop trying to oneshot good code."

### Don't outsource automated review; reviewer should commit

Generic third-party bots trend toward irrelevant false positives or language-specific overfit. Prefer team-owned standards that compound. Default behavior for the review agent: **commit fixes**, comment only when uncertain — comments alone dump work onto the human.

### Human-friendly PRs

- **One-way vs two-way doors** (AWS framing) + blast radius → "merge danger" summary
- Visual / pseudo-code PR bodies (credits Dex Horthy `/show-me`) so *why* is graspable fast
- You don't need equal scrutiny on every two-way door; one-way doors get full attention

### Review the system that produces the code

Human review should update checks, standards, navigation pointers, tool economy, and steering bloat via a **retro** skill — so the same comment never needs writing twice. Compounding loop: each review raises the floor for the next.

---

## Quotes worth keeping

> "Code is the environment your agent operates in. And if you have bad code in your codebase, that is going to be more bad code."

> "While implementation is overloaded, review is actually underloaded."

> "When you do a human review, you're not just reviewing the code, you're reviewing the system that creates it."

---

## Related

- [Matt Pocock — /handoff skill](matt-pocock-handoff-skill.md)
- [Armin Ronacher — Friction is Your Judgment](armin-ronacher-friction-is-your-judgment.md) — brakes as designed friction
- [Dex Horthy — No Vibes Allowed](dex-horthy-no-vibes-allowed.md) — `/show-me`; mental alignment as review purpose
- [Mario Zechner — Building pi in a World of Slop](mario-zechner-pi-world-of-slop.md)
- Skills: [aihero.dev/skills](https://aihero.dev/skills)

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

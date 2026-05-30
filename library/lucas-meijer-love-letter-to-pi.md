---
title: "A love letter to Pi"
speaker: Lucas Meijer (Unity co-creator, Build Monumental)
channel: Build Monumental
date: 2026
url: https://www.youtube.com/watch?v=fdbXNWkpPMY
wing: ai-engineering
tags: [pi, harness, evaluation, context-management, agent-workflow]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# Lucas Meijer — A love letter to Pi

## Source

- **Speaker:** Lucas Meijer (Unity co-creator, exploring AI-native game engines)
- **Channel:** Build Monumental
- **URL:** https://www.youtube.com/watch?v=fdbXNWkpPMY
- **Duration:** 27:10
- **Transcript:** [cached](../research/ingest-queue/sources/a-love-letter-to-pi-lucas-meijer.md)

---

## About

A practical user-perspective talk from a veteran game engine engineer (Unity). Covers a personal toolkit for working with coding agents, centering on Pi for its hackability and context control. Three strong frameworks: the Marble Madness mental model for agent-friendly repos, evaluation packs for review efficiency, and Barbapapa software for self-morphing tools.

---

## Key themes

### The Marble Madness mental model — your repo is the level

The marble is the agent; the repo is the level. Your job is to design the level so the marble rolls through smoothly. Hazards: incomplete AGENTS.md instructions, stale build warnings that have been "ignored for years," documentation that's out of sync with the code. Remedy: read the full session transcript after each run, find where the agent went off track, and ask: "What would have helped it reach its goal faster?" — then fix the repo.

### Evaluation packs — decide how you'll evaluate before you start

The biggest mental shift in agent work: decide how you will evaluate the result *before* sending the agent on the task. Put the evaluation criteria in the prompt. Agents (and humans) perform better when they know what "done" looks like.

Then ask the agent to produce an **evaluation pack** — a self-contained package that makes your review efficient:
- Single-page HTML slide deck with findings
- A screen recording demonstrating all features
- Screenshots with visual verification

Forcing the agent to make a recording prevents "I wrote some code, we should be good" — it has to actually open Chrome, run the JavaScript, and catch runtime errors. The agent benefits too: forced execution validates its own work in a self-correction loop.

### Context as a cost — pay for it intentionally

Every side quest stays in context and costs both tokens and intelligence. Once the context crosses the 50–60% range, the dumb zone begins — quality degrades. Stay below 50%.

Don't argue with the agent. When it produces something you don't like, use Pi's `/tree` (branch navigation) to return to a prior point and re-ask differently. Arguing accrues context debt with no benefit. The agent is "a token-producing machine, not a human you're supposed to talk to."

### Pi's /tree — non-linear context branching

Pi tracks context as a tree, not a linear chat log. `/tree` lets you navigate to any prior branch point and resume from there, either discarding the side quest entirely or capturing it as a summary. Precise control over what stays in context.

### "Barbapapa software" — self-morphing tools

Software that extends and configures itself while running on the user's machine. Pi's self-extension capability (agent writes its own TypeScript extension, hot-reloads) is the prototype: the tool shapes itself to the task at hand rather than the user shaping their workflow to the tool. Named for the 1970s cartoon character who shape-shifts to meet whatever challenge the adventure requires.

### We're so early — experiment, don't wait

Nobody knows what an ergonomic AI assistant looks like. Neither Claude Code, nor Codex, nor Pi. The correct response is to experiment obsessively and notice what actually works for you specifically — not wait for the SaaS solution designed for the median user.

Only solve the problem you actually have. Most practitioners are not at "stage nine" (full autonomous agent swarms); most friction is closer to home.

### The bottleneck is you

Running 10–12 parallel agent workstreams is possible; the bottleneck is the human evaluating the output. Agent does one hour of work → takes 15 minutes to review. Optimizing evaluation speed (evaluation packs, HTML output) is the leverage point, not spinning up more agents.

---

## Connections to this workspace

- **Pi** — direct upstream product; Meijer is a power user demonstrating Pi's `/tree`, self-extension, and evaluation pack workflow.
- **Marble Madness = AGENTS.md discipline** — the "make the repo agent-friendly" practice is what this workspace does with `AGENTS.md`, skills, and rules. The Marble Madness metaphor makes the mechanism legible for a non-workspace-aware audience.
- **Dumb zone** — confirmed independently: Meijer also uses 50% as his threshold for "get very nervous." Convergent evidence for the deck's dumb-zone slide.
- **Trust, but verify** — evaluation packs are the harness-level verification mechanism: force the agent to prove it works, don't trust the summary.
- **Artifacts as async multiplier** — evaluation packs are artifacts that offload review cognitive load onto the agent's output rather than the human's attention.
- **What stays human** — evaluation, judgment, and decision to accept/reject. The bottleneck (human as evaluator) is positioned as a feature, not a bug.

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
title: "Everything We Got Wrong About Research-Plan-Implement"
speaker: Dexter Horthy (Hatchet)
channel: MLOps.community
date: 2026
url: https://www.youtube.com/watch?v=YwZR6tc7qYg
wing: ai-engineering
tags: [ai-engineering, context-engineering, dumb-zone, instruction-budget, rpi, coding-agents, planning, harness]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# Dexter Horthy — Everything We Got Wrong About Research-Plan-Implement

## Source

- **Speaker:** Dexter Horthy (Hatchet; also author of "12 Factor Agents")
- **Channel:** MLOps.community
- **URL:** https://www.youtube.com/watch?v=YwZR6tc7qYg
- **Duration:** 26:42
- **Transcript:** [cached](../research/ingest-queue/sources/everything-we-got-wrong-about-research-plan-implement---dexter-horthy.md)

---

## About

Honest post-mortem on the Research-Plan-Implement (RPI) methodology that Hatchet popularized (10k+ users, prompts widely adopted). Covers what failed in practice (magic words, single giant prompts, too many instructions, unread plans) and what they rebuilt. Introduces the "dumb zone," the instruction budget, and the design concept artifact. Also notable for Dex explicitly saying "I was wrong" about not reading the code.

---

## The dumb zone (primary source)

> "You have about 168,000 tokens in 200,000, but some are reserved for output. Around 40% on average — depending on what you're doing — you hit this point where you have degrading results. Obviously sometimes you can get good enough results at 60%, but the less of the context window you use, the better results you will get."

Concrete operationalization: if your MCPs have tons of tool descriptions, that instruction overhead fills the window before you've written any code — and by the time the model is writing, it's already in the dumb zone.

**Design implication:** prefer smaller, focused prompts over large context windows. More instructions ≠ better adherence.

---

## The instruction budget

> "Frontier LLMs could only follow about 150–200 instructions with good consistency. Anything more than that and it's kind of half-attending to all of them — you're rolling the dice."

Single mega-prompts (85+ instructions) guarantee partial adherence. Any step in the workflow that relied on one of those instructions getting followed is now probabilistic. The magic words that "made it work" were patching instruction-budget failures, not product design.

---

## What they got wrong

| Wrong assumption | What they learned |
|---|---|
| Plans are enough — don't read the code | **Read the code.** Tried skipping for 6 months. "It did not end well." |
| 1,000-line plans are useful reviews | Plans diverge from code. Reviewing both is double work, not leverage. |
| Magic words make it work | If users need magic words to get good output, **fix the tool** |
| Single 85-instruction planning prompt | Split into smaller prompts with fewer instructions each |

The OpenClaw / Beads exception: OSS projects with no paying customers have different stakes. "If you have people who depend on your code, please read it."

---

## The redesigned workflow

Old: **Research → Plan → Implement** (3 steps, 1 big prompt)

New: **Questions → Research → Design → Structure → Plan → Work → Implement → PR** (8 steps, <40 instructions each)

Key structural change for research: **hide the ticket from the research context window**. Research that knows what you're building produces opinions; research that doesn't know produces facts. Facts compound; opinions constrain.

---

## The design concept artifact

Instead of a 1,000-line plan, build a 200-line "design concept" markdown document — the shared understanding between engineer and agent:

- Current state → desired end state
- Patterns to follow (explicitly; point away from the old patterns)
- Resolved design decisions
- Open questions for the engineer to answer

> "You want to give the agent every single opportunity to show you what it's wrong about before you go write 2,000 lines of code."

Brain surgery on the agent's understanding before proceeding. 200 lines → real review leverage. 1,000-line plan → theater.

---

## Control flow vs. prompt flow

> "Don't use prompts for control flow if you can use control flow for control flow. The if statement is really really powerful."

LLMs are good at classification. Use classification → branch to smaller, focused prompts with fewer instructions and fewer tool choices. This is the architectural lesson that RPI's monolithic prompt violated.

---

## Key phrases

- **"Do not outsource the thinking."** The engineer is an important part of the process. The agent shows you what it knows; you decide.
- **"No more slop."** 2026 is the year of craft vs. slop. 10x faster doesn't matter if you throw it all away in 6 months. Target 2–3x with near-human quality.
- **"Seek leverage."** Find ways to ensure correctness without reading all the code and resteering after the fact.

---

## Connections to this workspace

- **Primary source for the "dumb zone" slide** in `presentations/field-notes-for-peers.md` — the 40% threshold and context budget framing come from this talk
- "Do not outsource the thinking" directly parallels the **shoshin** and **sparring** discipline in the workspace — the engineer's judgment is the non-delegatable core
- The instruction budget finding validates the workspace design choice to split concerns across separate AGENTS.md, rules, and skills rather than one giant system prompt
- Connects to: [Patrick Debois — Context is the New Code](patrick-debois-context-is-the-new-code.md) (context engineering as the craft)
- Connects to: [Hak — Is this the only skill left?](hak-systems-thinking-only-skill-left.md) (systems thinking / don't outsource judgment)
- "12 Factor Agents" mentioned — worth looking up separately

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

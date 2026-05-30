---
title: "Everything I Learned Training Frontier Small Models"
speaker: Maxime Labonne (Liquid AI)
channel: AI Engineer
date: 2026
url: https://www.youtube.com/watch?v=fLUtUkqYHnQ
wing: ai-engineering
tags: [ai-engineering, small-models, edge-inference, training, rl, tool-use, local-llm, specialization]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# Maxime Labonne — Everything I Learned Training Frontier Small Models

## Source

- **Speaker:** Maxime Labonne, Head of Pre-training, Liquid AI
- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=fLUtUkqYHnQ
- **Duration:** 19:56
- **Transcript:** [cached](../research/ingest-queue/sources/everything-i-learned-training-frontier-small-models-maxime-labonne-liquid-ai.md)

---

## About

Lessons from pre-training 350M–24B parameter edge models at Liquid AI. Covers small-model characteristics, architecture choices for on-device inference, training recipe, and the reinforcement learning findings. Most relevant to this workspace: why small models demand narrow task focus, and what RL unlocks even at small scale.

---

## Small model characteristics

| Characteristic | Implication |
|---|---|
| Memory bound | Target hardware constrains everything — on-device profile first |
| Low knowledge capacity | Can't be general-purpose; design for narrow task excellence |
| Task-specialized | Data extraction and tool use are better targets than coding |
| Latency sensitive | Architecture matters more than at larger scale; prefer fast operators |

> "Small models are not just scaled-down versions of bigger models. They have their own unique challenges."

---

## The embedding layer problem

Distilled small models (Gemma 3 270M) have 63% of parameters in the embedding layer — not used for reasoning. Effective reasoning parameters are much smaller. Liquid's LFM 2 achieves ~10% embedding overhead, giving more "effective parameters" for the same memory footprint.

**Takeaway:** when evaluating small models, benchmark on-device, not on paper parameter counts.

---

## Over-training works

350M model trained on 28 trillion tokens — well beyond Chinchilla compute-optimal. Chinchilla optimizes for compute efficiency, not test performance. Test-time scaling laws show performance still grows with more tokens at small scale. "We should pre-train even more."

---

## Reinforcement learning at small scale

> "Reinforcement learning is extremely efficient even at very small scale. It's a really really important technique that we use everywhere."

Key requirement: narrow tasks with verifiable outcomes. If RL isn't converging, the likely cause is missing cold-start SFT data — add supervised samples for the target task first, then run RL on top.

---

## The right use case for small models

> "We wanted the model to be very good at data extraction and at tool use. If it's not the best model at code, it doesn't matter — people don't use it that way anyway."

Don't ask a small model to be a general-purpose assistant. Ask it to do one or two things well. Tool calling, structured data extraction, and function invocation are high-leverage targets.

---

## Connections to this workspace

- Directly relevant to the local LLM / hybrid workflow backlog item — small on-device models are good for bounded tool-use tasks, not for multi-file reasoning or synthesis
- Reinforces [Mo Bitar — Done with AGI](mo-bitar-done-agi-rant.md): specialization wins for concrete tasks; generality isn't what makes a model useful in a codebase
- The "narrow focus for small models" principle extends to the instruction budget finding from [Dex Horthy — RPI](dex-horthy-everything-wrong-rpi.md): fewer instructions, focused task, better adherence
- On-device profiling as ground truth mirrors the workspace's "measure, don't extrapolate" epistemics

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

# What's next

> Written: 2026-05-30 | SHA: `eb58822`

## Current state

Mid-session YouTube ingest. Batch 2 queue file: `.planning/youtube-ingest/QUEUE-2.md`.

**15 of 31 videos done** (videos 1–15). All committed and pushed. Two skipped: #10 (transcripts disabled — "Coding is no longer the constraint" from Spotify/Claude channel) and #16, #31 (duplicates from batch 1 — Tejas Kumar and Armin Ronacher).

## Remaining videos (16–31 from QUEUE-2.md, skipping #16 and #31)

| # | Video ID | Title (from fetch) |
|---|---|---|
| 17 | `eW_vxrjvERk` | pending |
| 18 | `6e9B7q3gvYY` | pending |
| 19 | `JT3OzDKrucU` | pending |
| 20 | `7UIQ1aTvXgk` | pending |
| 21 | `sqtX2OmgOF0` | pending |
| 22 | `FlTp9Ij7Mbo` | pending |
| 23 | `vAIDdLKB6-w` | pending |
| 24 | `esY99nYXxR4` | pending |
| 25 | `W76woOYHlvY` | pending |
| 26 | `zgNvts_2TUE` | pending |
| 27 | `UG9IAdmi2Dg` | pending |
| 28 | `h403btjldDQ` | pending |
| 29 | `ow1we5PzK-o` | pending |
| 30 | `wijoYNiZq3M` | pending |

## To resume

1. Read `.planning/youtube-ingest/QUEUE-2.md` for current status
2. Next video to fetch: `https://www.youtube.com/watch?v=eW_vxrjvERk` (video 17)
3. Continue the pattern: fetch → read transcript → write library entry → 4-step ingest → commit → next
4. Use `python3 .agents/skills/research-and-analyze/scripts/fetch-transcript.py "<url>" research/ingest-queue/sources/` with `required_permissions: ["all"]`

## What was ingested this session (batch 2, videos 1–15)

| # | Slug | Key concept |
|---|---|---|
| 1 | `hak-systems-thinking-only-skill-left` | Peter Naur "code is the shadow" / conductor frame / LLM ≠ compiler |
| 2 | `ibm-ai-agents-break-zero-trust-last-mile` | Last mile identity / zero trust breaks at legacy backend / vault + ABAC |
| 3 | `dex-horthy-everything-wrong-rpi` | **Dumb zone primary source** / instruction budget / design concept / don't outsource thinking |
| 4 | `mo-bitar-ex-google-ceo-ai-shtshow` | Two pricing charts / token costs rising / AI psychosis (Hashimoto) |
| 5 | `matt-pocock-handoff-skill` | /handoff vs compact / dumb zone ~120k / DIY sub-agent / cross-agent portability |
| 6 | `serious-cto-senior-devs-shipping-slow` | Architect's ego / 7 patterns / scale = result of simplicity |
| 7 | `mo-bitar-done-agi-rant` | AGI skepticism / specialization > generality / mechanism matters / anti-extrapolation |
| 8 | `ibm-five-ai-risks-get-fired` | Shadow AI / hallucination laundering / prompt injection / zombie agents |
| 9 | `primeagen-industry-ai-psychosis` | MTTR/MTBF analogy / architecture decay / typing cheap wisdom expensive |
| 10 | — | skipped (transcripts disabled) |
| 11 | `maxime-labonne-frontier-small-models` | Small model characteristics / over-training works / RL at small scale |
| 12 | `anthropic-agents-run-for-hours` | **Context anxiety** / GAN harness / generator-evaluator contract / harness co-evolves with model |
| 13 | `primeagen-10x-engineer-useless` | Comprehension debt spiral / two easy buttons / code review impossibility |
| 14 | `mo-bitar-openai-founder-admits` | Karpathy contradiction / heart-attack code / RL limits / spec-writing |
| 15 | `mo-bitar-ai-coding-minimum-wage` | Prompt ceiling / doctor vs MRI tech / FOMO critique |

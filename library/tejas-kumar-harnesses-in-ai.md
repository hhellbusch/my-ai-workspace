---
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# Tejas Kumar — Harnesses in AI: A Deep Dive

## Source

- **Speaker:** Tejas Kumar (AI Developer Advocate, IBM)
- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=C_GG5g38vLU
- **Duration:** 20:18
- **Published:** 2026
- **Transcript:** [cached](../research/harness-engineering/sources/harnesses-in-ai-a-deep-dive-tejas-kumar-ibm.md)

## About the Talk

First-principles introduction to **agent harnesses** for an audience that mostly couldn't define the term at the start. Kumar distinguishes ML "harness" (eval test suite) from **AI agent harness** (everything around the model that grounds it in a stable environment you control). Live demo: browser agent on Hacker News upvote task using **GPT-3.5 Turbo** intentionally — outcome improves by adding harness pieces **without changing the prompt once**.

Recommended after [Ryan Lopopolo — Harness Engineering](ryan-lopopolo-harness-engineering.md) (organizational scale) or before it (first principles) — Kumar is the clearest **anatomy + demo** talk in the AI Engineer harness cluster.

## Key Themes

### Why harness — reliability on rented models

Most practitioners rent inference (limited context, black-box model swaps). Harness goal: agents **do what they should** irrespective of model quirks — reliability over raw model IQ.

### Agent harness components

| Part | Role |
|---|---|
| **Tool registry** | Read/write/exec — Claude Code, Cursor, Codex |
| **Model** | Often swappable inside the harness |
| **Context primitives** | Compaction, trimming — harness job, not model |
| **Guardrails** | Max steps, max messages, kill run |
| **Agent loop** | Inside harness — harness can wrap *outer* loop (N attempts) |
| **Verify step** | Lint, tests, domain checks — "remove the lie" when agent claims success |

> Harness is **not** just the agent loop — it's the stuff **around** the loop (and can be a loop around your loop).

### Demo arc — prompt unchanged, harness grows

1. Bare loop → agent "succeeds" but **doesn't verify** (false success on login wall)
2. Add guardrails (context trim, max messages)
3. Extract `runHarness()` — ~19-line entry point
4. Add **verify step** + max attempts (outer retry loop)
5. Add **login handler** (deterministic harness injection before agent continues)

**Closing line:** "I did not touch the prompt once. We just built a harness and the outcome radically changed."

### Cheap model + great harness

Use smaller/cheaper models (GPT-3.5, open-weight) when harness provides grounding, verify, and guardrails — aligns with [Alberta Tech Terminal Bench observation](alberta-tech-why-devs-obsessed-claude-code.md) (same model, harness drives rank).

### 2026 framing

"2025 was the year of agents. 2026 is the year of harnesses." Speculative next step: dynamic on-the-fly harness generation before task execution (plan mode on steroids).

## Notable Quotes (from transcript)

> "The agent harness is everything around the model that gives it grounding in reality."

> "Claude Code … is a harnessed coding agent."

> "It doesn't verify. This is the job of a harness."

> "The harness is literally harnessing the agent to something stable, something deterministic."

## Connections to This Workspace

| Kumar concept | Field Notes analogue |
|---|---|
| Verify step | Trust but verify; `/review`, tests before merge |
| Guardrails / max steps | Session scope; rules that fire on friction |
| Context compaction in harness | Act II compaction slides; re-read source files |
| Tool registry + stable environment | Loop 3 agent slide; `AGENTS.md` + rules + skills |
| Prompt unchanged, harness changed outcome | Invest in harness (docs, rules, skills) not prompt hacks |

Related: [Lopopolo](ryan-lopopolo-harness-engineering.md) · [Horthy](dex-horthy-no-vibes-allowed.md) · [Krentsel / OpenClaw](alex-krentsel-openclaw-deep-dive.md)

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

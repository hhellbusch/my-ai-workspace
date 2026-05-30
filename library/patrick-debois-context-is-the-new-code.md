---
title: "Context Is the New Code"
speaker: Patrick Debois (inventor of DevOps) / Tessl
channel: AI Engineer
date: 2026
url: https://www.youtube.com/watch?v=bSG9wUYaHWU
wing: ai-engineering
tags: [context-engineering, devops, software-3.0, skills, testing, harness]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# Patrick Debois — Context Is the New Code

## Source

- **Speaker:** Patrick Debois (inventor of DevOps; Tessl)
- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=bSG9wUYaHWU
- **Duration:** 27:05
- **Transcript:** [cached](../research/ingest-queue/sources/context-is-the-new-code-patrick-debois-tessl.md)

---

## About

Patrick Debois (who coined "DevOps" in 2009) applies the same DevOps lifecycle thinking to context. If code got a development lifecycle (SDLC), context — AGENTS.md, skills, rules, prompts — deserves one too. The talk introduces the Context Development Life Cycle: Generate → Test → Distribute → Observe → Adapt. Unpolished but conceptually grounded.

---

## Key themes

### Context is the new code — and code is transforming back into context

> "LLMs are just the engine. If you give the engine the wrong fuel, which is context, they're not going to perform."

Your AGENTS.md, skills, and rules are the programming surface. The optimization lever is context, not the model. Code that used to be parameterized conditional logic ("if Python, do this; if Node, do that") can be replaced by a skill that gives the agent instructions for figuring it out — solving more problems than any code branch ever could.

### The Context Development Life Cycle (CDLC)

By analogy with SDLC, a lifecycle for context:

1. **Generate** — write prompts, create skills, pull documentation, use spec-driven development to decompose requirements
2. **Test** — evals (linting for structure, LLM-as-judge for behavior, integration tests with tools running in sandboxes)
3. **Distribute** — commit to repo (zero friction for team), package as skills, publish to registries
4. **Observe** — read agent logs for missing context, treat PR feedback as context failures, instrument production failures as new test cases
5. **Adapt** — optimize context based on eval feedback; the flywheel: fix it once, distribute to the team, everyone improves

### Testing context is not like testing code

Context eval results are non-deterministic. You can't run an eval once and declare pass/fail. Run it 5× and ask: how many times did it succeed? Use **error budgets** (borrowed from SRE): some tests are allowed to fail occasionally; critical ones must hit near-100% to proceed.

LLM-as-judge: ask the model to evaluate whether the generated output follows the criteria in your context. The judge can also use tools (run a curl, check the endpoint actually responds correctly) — making evals into integration tests.

### Skills as the package format for context

Skills contain not just prompts but scripts, documents, and MCP configurations. They're effectively packages for distributing context across projects and teams. Public registries exist but 99.9% of public skills are crap — quality standards are not yet enforced. Internal registries for team-curated context are the practical path.

Dependency hell is coming: context packages will conflict.

### Context filter — WAF for prompts

AGENTS.md and skill.md are loaded automatically when a coding agent starts — no sandbox blocks this. A context filter (web application firewall for prompts) is needed to detect and block prompt injections and malicious patterns in loaded context.

### The organizational flywheel

Individual: you craft your own markdown, notice what's missing, add it.
Team: shared context in the repo, distributed to all engineers.
Organization: agent logs surface gaps across teams; fixing a context hole benefits everyone at once. Scale of impact: one context fix → all engineers improve simultaneously.

---

## Connections to this workspace

- **Software 3.0 / context window as programming surface** — Debois's "context is the new code" is the DevOps practitioner's version of Karpathy's Software 3.0 thesis. Both say the same thing from different angles.
- **AGENTS.md discipline** — the entire workspace's AGENTS.md/rules/skills setup is exactly the "generate context" phase of the CDLC. The workspace is already doing this; Debois names and formalizes the practice.
- **Skills as packages** — direct alignment with the AgentSkills standard and the `.agents/skills/` structure in this workspace.
- **Harness ≥ model** — "LLMs are just the engine; context is the fuel" is the clearest one-sentence statement of the harness-over-model principle.
- **Verification in the harness** — Debois's eval/testing layer is the systematic version of "trust, but verify" — not just manual review, but structured tests for context behavior.

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

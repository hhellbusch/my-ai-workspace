---
review:
  status: unreviewed
  notes: "Documentation v2 — deck critique of coverage %, dual audience exemplar."
---

# Documentation & Knowledge — maturity deep dive

> **Audience:** Humans, future teammates, **and** AI coding agents — multi-session work.
>
> **Purpose:** Context quality over coverage %; this repo as dual-audience exemplar.

**Related:** [Artifact Discipline and AI](../artifact-discipline-and-ai.md) · [Prompting Is Necessary but Not Sufficient](../prompting-and-state.md) · [Architecture & change](architecture-and-change.md) · [DORA / AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md)

---

## What this axis answers

*Is knowledge load-bearing — for onboarding, operations, change, and the next agent session?*

| Architecture & change | Documentation & knowledge |
|---|---|
| Boundaries sound? | Others **find and trust** what we know? |
| ADRs, deprecation | READMEs, runbooks, handoffs, skills |

---

## Levels

| Level | Posture | Evidence |
|---|---|---|
| **1** | Scattered wikis, stale README | New hire lost; agent invents structure |
| **2** | Humans find docs eventually | No stable agent entry point |
| **3** | Index, conventions, metadata | [STYLE.md](../../../STYLE.md), README TOCs, `review:` |
| **4** | Handoffs, skills, briefs; TAGRI/JBGE | [Session framework](../session-framework.md), [AGENTS.md](../../../AGENTS.md), skills |
| **5** | Orientation time improves; fewer repeated errors | Retros update docs; evals on critical paths |

**Deck lineage (with 2026 critique):**

| Deck tier | Level | Modern note |
|---|---|---|
| None | **1** | — |
| Ad-hoc scattered | **1–2** | — |
| Standardized; >50% coverage | **2–3** | **Reject coverage %** as goal — TAGRI/JBGE instead |
| Publishing; ~100% coverage | **3** | Prefer **index + discipline** over completeness |
| Auto publish; periodic reviews | **4–5** | Staleness review = [`/validate`](../../../.agents/skills/validate/SKILL.md), handoffs |

Deck cited Agile Manifesto — working software over comprehensive documentation **≠** no documentation ([Ambler](http://www.ambysoft.com/essays/agileManifesto.html)).

---

## Dual audience (2026)

- Agents read committed, linked state — no hallway context  
- Over-documentation hurts ([TAGRI](../artifact-discipline-and-ai.md))  
- **JBGE:** sufficient for the decision  

| Layer | Role | Example |
|---|---|---|
| Workshop | Raw sources | [research/](../../../research/README.md) |
| Wiki | Enriched entries | [library/](../../../library/README.md) |
| Essays / guides | Synthesis | [docs/](../../../docs/README.md) |

[rules/research.md](../../../rules/research.md) — sources are drawers, not edit logs.

---

## DORA

**Generative culture** (learning, sharing) correlates with delivery performance — documentation that enables onboarding and blameless learning supports team practices and MTTR, not a direct DORA metric. See [research note](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md).

---

## Evidence in this workspace (rich)

| Practice | Path |
|---|---|
| Artifact economics | [artifact-discipline-and-ai.md](../artifact-discipline-and-ai.md) |
| Session continuity | [prompting-and-state.md](../prompting-and-state.md) · `.planning/*/whats-next.md` |
| Maturity handoffs | [.planning/software-systems-maturity/](../../../.planning/software-systems-maturity/whats-next.md) |
| Cross-link / review | [cross-link skill](../../../.agents/skills/cross-link/SKILL.md) · [review skill](../../../.agents/skills/review/SKILL.md) |
| Research → library ingest | 4-step checklist in [AGENTS.md](../../../AGENTS.md) |

---

## AI era

Level 4 here **enables** [AI agents L3+](ai-agents-and-harnesses.md) — bounded tools need externalized state ([prompting and state](../prompting-and-state.md)).

Anti-pattern: handoffs that restate git log — TAGRI failure.

---

## Anti-patterns

- Coverage % targets (gameable)  
- Orphan `research/` without library/docs output  
- Prep notes in `sources/` (see research rules)  
- Docs nobody maintains after AI bulk generation  

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

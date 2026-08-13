---
review:
  status: unreviewed
  notes: "Documentation & knowledge deep dive — dual audience humans and AI agents."
---

# Documentation & Knowledge — maturity deep dive

> **Audience:** Teams whose "documentation" is read by humans, future teammates, **and** AI coding agents — especially multi-session work.
>
> **Purpose:** Replace coverage-percent thinking with **context quality** — can someone orient and make a correct decision quickly?

**Related:** [Trailhead](../software-systems-maturity.md#documentation--knowledge) · [Artifact Discipline and AI](../artifact-discipline-and-ai.md) · [Prompting Is Necessary but Not Sufficient](../prompting-and-state.md) · [Architecture & change](../software-systems-maturity.md#architecture--change) (related axis)

---

## What this axis answers

*Is knowledge load-bearing — for onboarding, operations, change, and the next agent session?*

This overlaps **Architecture & change** (system coherence) but is distinct:

| Architecture & change | Documentation & knowledge |
|---|---|
| Are boundaries and contracts sound? | Can others **find and trust** what we know about the system? |
| ADRs, deprecation policy | READMEs, runbooks, handoffs, skills |

You can have clean architecture with unusable docs — or excellent agent-oriented docs on a tangled system. Mature organizations need both.

---

## Dual audience (2026)

Documentation maturity now includes **machines as readers**:

- Agents do not inherit hallway context; they read what is committed and linked.
- Over-documentation hurts agents too ([TAGRI](../artifact-discipline-and-ai.md) — they ain't gonna read it).
- **JBGE** applies: sufficient for the decision, no more.

Three layers in this workspace (exemplar, not universal standard):

| Layer | Role | Example |
|---|---|---|
| **Workshop** | Raw sources while writing | [research/](../../../research/README.md) |
| **Wiki / reference** | Enriched entries | [library/](../../../library/README.md) |
| **Essays / guides** | Synthesis and practice | [docs/](../../../docs/README.md) |

Convention: [rules/research.md](../../../rules/research.md) — sources are working copies, not edit logs.

---

## Levels

| Level | Posture | Evidence |
|---|---|---|
| **1** | Scattered wikis, stale README | New hire lost; agent invents structure |
| **2** | Humans find docs eventually | No stable entry point for agents |
| **3** | Index, conventions, metadata | [STYLE.md](../../../STYLE.md), README TOCs, `review:` blocks |
| **4** | Handoffs, skills, briefs; artifact discipline | [Session framework](../session-framework.md), [AGENTS.md](../../../AGENTS.md), `.agents/skills/` |
| **5** | Measured orientation time; fewer repeated errors | Retros improve docs; evals on critical paths |

**Anti-patterns:**

- Coverage % targets (gameable in microservice estates)
- Docs that restate git log (TAGRI failure)
- Orphan sources in `research/` with no essay or library output
- Preparation notes inside `sources/` files (see research conventions)

---

## Connection to AI agents axis

Level 4 here enables level 3+ on [AI agents & harnesses](../software-systems-maturity.md#ai-agents--harnesses): bounded tools only help if **state and intent** are externalized ([prompting and state](../prompting-and-state.md)).

---

## Repo examples

| Practice | Path |
|---|---|
| Artifact economics | [artifact-discipline-and-ai.md](../artifact-discipline-and-ai.md) |
| Session continuity | [prompting-and-state.md](../prompting-and-state.md), `.planning/*/whats-next.md` |
| Review metadata | [rules/review-tracking.md](../../../rules/review-tracking.md) |
| Cross-link discipline | [.agents/skills/cross-link/](../../../.agents/skills/cross-link/SKILL.md) |

---

## External references

- [Agile Modeling — document late, travel light](https://agilemodeling.com/)
- [Ambler on the Agile Manifesto](http://www.ambysoft.com/essays/agileManifesto.html)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

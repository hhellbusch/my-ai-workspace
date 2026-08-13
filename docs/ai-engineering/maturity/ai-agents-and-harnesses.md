---
review:
  status: unreviewed
  notes: "AI agents v2 — harness layers, DORA open questions, repo exemplar."
---

# AI Agents & Harnesses — maturity deep dive

> **Audience:** Coding agents, chat assistants, autonomous jobs — beyond one-off prompts.
>
> **Purpose:** Bounded, reviewed, session-continuous AI work. Connect [The Shift](../the-shift.md).

**Related:** [Documentation & knowledge](documentation-and-knowledge.md) · [Team practices](team-practices.md) · [Code quality L4](code-quality.md) · [DORA / AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md)

---

## What this axis answers

*Is AI-assisted work **bounded**, **reviewed**, and **continuous across sessions** — or fast chaos?*

Agents amplify existing maturity. High deployment + low review = accelerated drift.

---

## Levels

| Level | Posture |
|---|---|
| **0** | Unreviewed agent changes to prod |
| **1** | Ad hoc prompts; context only in chat |
| **2** | Repeatable prompts/skills; human reviews merges |
| **3** | Bounded tools; handoff/checkpoint discipline |
| **4** | Spar/shoshin/eval on risky changes; TAGRI/JBGE |
| **5** | Failure modes catalogued; orientation/errors improve |

**L3 requires** [documentation L3+](documentation-and-knowledge.md). **L4 overlaps** [team practices L4](team-practices.md).

---

## Harness layers (this workspace)

| Layer | Examples |
|---|---|
| Runtime boundary | Paude containers, tool permissions |
| Discipline | [AGENTS.md](../../../AGENTS.md), skills, rules |
| Session state | BRIEF, whats-next, git truth anchor |
| Review | Spar, pre-commit, human merge authority |
| Maturity lens | [Software Systems Maturity](../../../AGENTS.md) § |

Maturity ≠ model choice — **constrain and record** work.

---

## DORA / open research

Hypothesis: AI improves typing speed before org delivery metrics. **Open question:** do DORA capability correlations hold under heavy agent use, or shift toward eval harnesses and skills governance? See [research note](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md).

---

## Evidence in this workspace (rich)

| Topic | Path |
|---|---|
| Bottleneck shift | [the-shift.md](../the-shift.md) |
| State vs prompting | [prompting-and-state.md](../prompting-and-state.md) |
| Artifact economics | [artifact-discipline-and-ai.md](../artifact-discipline-and-ai.md) |
| Spar / shoshin | [sparring-and-shoshin.md](../sparring-and-shoshin.md) |
| Paude | [paude-getting-started.md](../paude-getting-started.md) |
| Session framework | [session-framework.md](../session-framework.md) |
| Harnesses (library) | [tejas-kumar-harnesses-in-ai.md](../../../library/tejas-kumar-harnesses-in-ai.md) |

---

## Cross-axis

| Axis | Link |
|---|---|
| Code quality L4 | Human owns merge |
| Documentation L4 | Handoffs, skills |
| Security L0 | Secrets in prompts/commits |
| Deployment L4 | Same GitOps gates as humans |
| Testing L4 | CI on agent PRs |

---

## Anti-patterns

| Anti-pattern | Trap |
|---|---|
| Paste entire repo into chat | L1 |
| Write access, no review | L1–2 |
| Handoffs = git log | Doc L2 |
| Eval-free prod autonomy | Below L4 |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

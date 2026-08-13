---
review:
  status: unreviewed
  notes: "AI agents & harnesses deep dive — bounded automation, review gates, session state."
---

# AI Agents & Harnesses — maturity deep dive

> **Audience:** Teams using coding agents, chat assistants, or autonomous jobs — beyond one-off prompts.
>
> **Purpose:** Expand the [trailhead](../software-systems-maturity.md#ai-agents--harnesses) axis. Connect to [The Shift](../the-shift.md): when implementation is cheap, verification and framing dominate.

**Related:** [Documentation & knowledge](documentation-and-knowledge.md) · [Team practices](team-practices.md) · [Artifact Discipline and AI](../artifact-discipline-and-ai.md) · [Prompting Is Necessary but Not Sufficient](../prompting-and-state.md)

---

## What this axis answers

*Is AI-assisted work **bounded**, **reviewed**, and **continuous across sessions** — or fast chaos?*

"Clankers" (agents) amplify whatever maturity you already have. High deployment maturity + low review maturity = accelerated drift.

---

## Levels

| Level | Posture |
|---|---|
| **1** | Ad hoc prompts; no review; context only in chat |
| **2** | Repeatable prompts or skills; human reviews all merges |
| **3** | Bounded tools (permissions, sandbox); handoff/checkpoint discipline |
| **4** | Spar, shoshin, or eval gates on risky changes; TAGRI/JBGE on artifacts |
| **5** | Known failure modes catalogued; orientation time and error rates improve |

**Level 3** requires [documentation & knowledge](documentation-and-knowledge.md) level 3+ — externalized state (briefs, handoffs, skills, committed truth).

**Level 4** overlaps [team practices](team-practices.md) level 4 — intentionally. Agents make agreeable output cheap; structural friction is the counterweight.

---

## Harness — what it means here

A **harness** is everything that wraps the model:

| Layer | Examples in this workspace |
|---|---|
| Runtime boundary | Paude containers, tool permissions |
| Discipline | [AGENTS.md](../../../AGENTS.md), skills, rules |
| Session state | BRIEF, whats-next, git as truth anchor |
| Review | Spar, pre-commit, human merge authority |

Maturity is not "which model" — it is whether the harness **constrains and records** work.

---

## Anti-patterns

| Anti-pattern | Level trap |
|---|---|
| Paste entire repo into chat | L1 — no durable context |
| Agent with write access, no review | L1–2 |
| Skills/rules without human merge gate | L2 theater |
| Handoffs that restate git log | Documentation L2 |
| Eval-free autonomy on prod paths | Below L4 for regulated/high-risk |

---

## Connection to other axes

| Axis | Link |
|---|---|
| Code quality L4 | Human owns merge; agent assists |
| Documentation L4 | Handoffs, skills, artifact discipline |
| Security L0 | Secrets in prompts or committed `.env` |
| Deployment L4 | Agent applies prod — needs same GitOps gates as humans |

---

## Repo examples

| Topic | Path |
|---|---|
| Bottleneck moved | [the-shift.md](../the-shift.md) |
| State vs prompting | [prompting-and-state.md](../prompting-and-state.md) |
| Artifact economics | [artifact-discipline-and-ai.md](../artifact-discipline-and-ai.md) |
| Spar / shoshin | [sparring-and-shoshin.md](../sparring-and-shoshin.md) |
| Paude harness | [paude-getting-started.md](../paude-getting-started.md) |

---

## External references

- [Tejas Kumar — harnesses in AI (library)](../../../library/tejas-kumar-harnesses-in-ai.md)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

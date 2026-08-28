---
review:
  status: unreviewed
  notes: "Team practices v2 — DORA generative culture, session framework evidence."
---

# Team Practices — maturity deep dive

> **Audience:** Leads assessing **how people work together** — not only pipelines.
>
> **Purpose:** Deck's individual/team performance promise; session framework as repo exemplar.

**Related:** [Session Framework](../session-framework.md) · [Sparring and Shoshin](../sparring-and-shoshin.md) · [Code quality L4](../software-systems-maturity.md#code-quality) · [DORA / AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md)

---

## What this axis answers

*Does the team get better over time — or replay heroics and silent agreement?*

Technical axes can be high while team practices lag: GitOps without review culture, tests without onboarding, fast AI without frame challenge.

---

## Levels

| Level | Posture | Signals |
|---|---|---|
| **0** | Toxic heroics; blame culture | Repeat incidents; attrition |
| **1** | Hero knowledge; inconsistent onboarding | Bus factor |
| **2** | Ad hoc pairing/review | Quality varies by who is on call |
| **3** | Review expected; onboarding checklist; retros | New members ship with guidance |
| **4** | Practices change behavior | Spar/shoshin; blameless postmortems that alter process |
| **5** | Learning loops measured; safe to challenge frames | Fewer repeats; psych safety in retro |

---

## DORA — generative culture

*Accelerate* identifies **generative organizational culture** (learning, cooperation, shared responsibility) as correlating with delivery performance — alongside technical capabilities. This axis names what DORA doesn't operationalize as a pipeline step. See [research note](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md).

**Not certification theater** — deck CMM criticism: observe behavior, not training hours.

---

## Level 4 in this workspace

| Practice | Defends against |
|---|---|
| [Shoshin](../sparring-and-shoshin.md) | Wrong problem |
| [Spar](../sparring-and-shoshin.md) | Agreeable wrong output |
| [Handoffs](../session-framework.md) | Session boundary loss |
| [Artifact discipline](../artifact-discipline-and-ai.md) | Unread docs |

Shared team practices — not solo habits.

---

## Example evidence for this workspace

> Illustrates practices on this axis using paths in Field Notes. **Not a maturity score** for this workspace or your team. See [navigation vs benchmark](../maturity-as-navigation-not-benchmark.md) and [artifact map](../../../research/software-systems-maturity/findings/artifact-map.md).


| Practice | Path |
|---|---|
| Framework map | [session-framework.md](../session-framework.md) |
| Peer intro | [sparring-and-shoshin.md](../sparring-and-shoshin.md) |
| Portable bootstrap | [framework-bootstrap.md](../framework-bootstrap.md) |
| Craft principles | [craft skill](../../../.agents/skills/craft/SKILL.md) |
| Feedback checkpoints | [AGENTS.md](../../../AGENTS.md) |

---

## AI era

Polished agent output merged without challenge = **spar gap + code quality gap**. Team norm: human owns merge; disagreeing with frames is allowed ([shoshin](../../../AGENTS.md)).

Joel #11 (hire the best) — **out of scope** for this model ([appendix](joel-test-appendix.md)).

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| "No time for review" | Debt → prod/on-call |
| Retros without actions | Ritual only |
| AI merged because fluent | Spar gap |
| Certification badges | CMM lesson |

---

## Cross-axis

```text
Team L4 ──enables──▶ Code quality L4 (review culture)
        ──enables──▶ AI agents L4 (spar/eval)
        ──pairs with──▶ Monitoring L4 (blameless postmortems)
        ──pairs with──▶ Documentation L4 (handoffs)
```

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

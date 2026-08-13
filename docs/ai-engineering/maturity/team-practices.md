---
review:
  status: unreviewed
  notes: "Team practices deep dive — learning loops, review culture, spar/shoshin mapped to levels."
---

# Team Practices — maturity deep dive

> **Audience:** Leads and teams who want maturity on **how people work together** — not only how pipelines run.
>
> **Purpose:** Make the deck's "individual and team performance" promise explicit. Map levels to practices encoded in this workspace's session framework.

**Related:** [Trailhead](../software-systems-maturity.md#team-practices) · [Session Framework](../session-framework.md) · [Sparring and Shoshin](../sparring-and-shoshin.md) · [Code quality L4](../software-systems-maturity.md#code-quality) (human owns merge)

---

## What this axis answers

*Does the team get better over time — or replay heroics, stale assumptions, and silent agreement?*

Technical axes can be high while team practices lag: excellent GitOps with no review culture, strong tests with no onboarding path, fast AI output with no one challenging frames.

---

## Levels

| Level | Posture | Signals |
|---|---|---|
| **1** | Hero knowledge; inconsistent onboarding | Bus factor; repeated mistakes |
| **2** | Ad hoc pairing; review when someone remembers | Quality varies by who is on call |
| **3** | Review expected; onboarding checklist; retros happen | New members ship with guidance |
| **4** | Deliberate practices change behavior | Spar/shoshin, blameless postmortems that alter process |
| **5** | Learning loops measured; safe to challenge frames | Fewer repeated incidents; psych safety cited in retro |

**Level 4 in this workspace** maps to:

| Practice | Defends against |
|---|---|
| [Shoshin](../sparring-and-shoshin.md#shoshin--beginners-mind) | Stale framing, wrong problem |
| [Spar](../sparring-and-shoshin.md#sparring--adversarial-review) | Agreeable but wrong output |
| [Handoffs / checkpoint](../session-framework.md#handoffs-and-crash-recovery--surviving-session-boundaries) | Lost context across sessions |
| [Artifact discipline](../artifact-discipline-and-ai.md) | Docs nobody reads |

These are **team** practices when shared — not solo habits.

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| "We don't have time for review" | Debt migrates to production and on-call |
| Retros without actions | Ritual without maturity gain |
| Senior-only challenge allowed | Juniors inherit bad frames silently |
| AI output merged because it looks polished | Spar gap + code quality gap |
| Certification theater | CMM lesson — badge ≠ competence |

---

## Connection to CMM criticism

The deck criticized certification industries. **Team practices** maturity is where that lesson lands: assess **observed behavior**, not training hours completed.

---

## Repo examples

| Practice | Path |
|---|---|
| Framework map | [session-framework.md](../session-framework.md) |
| Intro for peers | [sparring-and-shoshin.md](../sparring-and-shoshin.md) |
| Portable bootstrap | [framework-bootstrap.md](../framework-bootstrap.md) |
| Engineering principles | [.agents/skills/craft/](../../../.agents/skills/craft/SKILL.md) |

---

## External references

- [Martin Fowler — Maturity Model](https://martinfowler.com/bliki/MaturityModel.html) (mixologist — capability under variation)
- Blameless postmortem culture (SRE practice — any canonical SRE reader)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

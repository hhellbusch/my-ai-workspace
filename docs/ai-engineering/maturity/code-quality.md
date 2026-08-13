---
review:
  status: unreviewed
  notes: "Code quality deep dive — tradable quality, Boy Scout Rule, review with human merge gate."
---

# Code Quality — maturity deep dive

> **Audience:** Teams assessing maintainability, standards, and review discipline — including AI-assisted coding.
>
> **Purpose:** Restore deck teaching points (tradable quality, Boy Scout Rule) without XKCD figures — links only.

**Related:** [Team practices](team-practices.md) · [AI agents](ai-agents-and-harnesses.md) · [Trailhead](../software-systems-maturity.md#code-quality)

---

## What this axis answers

*Will the codebase stay changeable — or erode until every feature is expensive?*

[Tradable quality hypothesis](https://martinfowler.com/bliki/TradableQualityHypothesis.html): in software, **lack** of quality costs more over time (people-time), unlike skipping a luxury car option.

Defect cost rises the longer they live — context is lost, more people get involved (help desk, management, customers).

---

## Levels

| Level | Posture |
|---|---|
| **1** | No standards; style varies by author |
| **2** | Style guide; DRY, YAGNI taught |
| **3** | Linters in CI; config externalized from code |
| **4** | Review before merge — **human owns decision**; agents assist |
| **5** | Periodic architecture/health review; debt scheduled |

**Boy Scout Rule** ([Fowler — opportunistic refactoring](https://martinfowler.com/bliki/OpportunisticRefactoring.html)): leave code a little better than you found it — not rewrite everything you touch.

**SOLID** vocabulary fits level 2–3 teaching — not before basics stick ([Wikipedia — SOLID](https://en.wikipedia.org/wiki/SOLID)).

---

## Teaching references (deck)

Quality erosion comic thread — use as conversation starters, not shaming:

- [xkcd #1513](https://xkcd.com/1513/) · [#1695](https://xkcd.com/1695/) · [#1833](https://xkcd.com/1833/) · [Bad Code](https://xkcd.com/292/)

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| Lint disabled "just this once" | Becomes permanent |
| Review rubber-stamp | Level 4 theater |
| Agent output merged unread | Quality + AI agents gap |
| Big-bang rewrite instead of Boy Scout steps | Risk without incremental gain |

---

## Repo examples

| Topic | Path |
|---|---|
| Craft principles | [.agents/skills/craft/](../../../.agents/skills/craft/SKILL.md) |
| Adversarial review | [sparring-and-shoshin.md](../sparring-and-shoshin.md) |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
review:
  status: unreviewed
  notes: "Code quality v2 — deck lineage, tradable quality, AI review gates."
---

# Code Quality — maturity deep dive

> **Audience:** Teams assessing maintainability, standards, and review discipline — including AI-assisted coding.
>
> **Purpose:** Restore deck teaching points (tradable quality, Boy Scout Rule, quality continuum) with 2026 review and agent gates.

**Related:** [Team practices](team-practices.md) · [AI agents](ai-agents-and-harnesses.md) · [Testing](testing-and-verification.md) · [DORA / AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md) · [Trailhead](../software-systems-maturity.md#code-quality)

---

## What this axis answers

*Will the codebase stay changeable — or erode until every feature is expensive?*

[Tradable quality hypothesis](https://martinfowler.com/bliki/TradableQualityHypothesis.html): in software, **lack** of quality costs more over time (people-time), unlike skipping a luxury car option.

Defect cost rises the longer they live — context is lost, more people get involved (help desk, management, customers). Deck: degraded quality makes **new features harder** — periodic health assessment required.

---

## Levels

| Level | Posture |
|---|---|
| **0** | Known unsafe patterns tolerated in prod paths |
| **1** | No standards; style varies by author |
| **2** | Style guide; DRY, YAGNI taught |
| **3** | Linters in CI; config externalized from code |
| **4** | Review before merge — **human owns decision**; agents assist |
| **5** | Periodic architecture/health review; debt scheduled |

**Deck lineage (2016 → 2026):**

| Deck tier | Level |
|---|---|
| Poor; no standards | **1** |
| Style guide; DRY; YAGNI; SOLID teaching | **2** |
| Linting; no hard coding | **3** |
| Code reviews (manual and "clanker driven") | **4** |
| Periodic system evaluation / debt reduction | **5** |

**Boy Scout Rule** ([Fowler — opportunistic refactoring](https://martinfowler.com/bliki/OpportunisticRefactoring.html)): leave code a little better than you found it — not rewrite everything you touch.

**Sweet spot (deck):** quality + simplicity + **user needs** — not purity for its own sake.

---

## DORA / team culture

DORA emphasizes **generative culture** and technical practices together — code review discipline supports **change failure rate** when paired with [testing](testing-and-verification.md). This axis has no standalone DORA metric; assess via review behavior and defect escape rate. See [research note](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md).

---

## AI era

| Risk | Mitigation |
|---|---|
| Agent output merged unread | L4 theater — human owns merge ([source control L3+](source-control.md)) |
| Polished but wrong code | [Spar](../sparring-and-shoshin.md) + review |
| Lint disabled for generated files | L3 regression |
| Volume without Boy Scout discipline | Erosion accelerates |

Deck foreshadowed **"clanker driven"** reviews — maturity is **human decision, agent assist**, not agent merge authority.

---

## Teaching references (deck)

Quality erosion — conversation starters, not shaming:

- [xkcd #1513](https://xkcd.com/1513/) · [#1695](https://xkcd.com/1695/) · [#1833](https://xkcd.com/1833/) · [Bad Code](https://xkcd.com/292/)
- [Quality continuum](https://thesmithfam.org/images/code-quality-continuum.png) (deck image — external)

---

## Evidence in this workspace

| Level | Path |
|---|---|
| **2–3** | [craft skill](../../../.agents/skills/craft/SKILL.md) · [ENGINEERING-PRINCIPLES](../../../submodules/zanshin-pi-extension/kit/ENGINEERING-PRINCIPLES.md) |
| **3–4** | Root pre-commit · [/review skill](../../../.agents/skills/review/SKILL.md) |
| **4** | [sparring-and-shoshin.md](../sparring-and-shoshin.md) · [branching rules](../../../rules/branching.md) merge discipline |
| **5** | Periodic health — informal via craft/JBGE; no formal audit program in-repo |

**Corpus:** thin by design — principles in skills/essays, not a style guide per language.

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| Lint disabled "just this once" | Becomes permanent |
| Review rubber-stamp | Level 4 theater |
| Agent output merged unread | Quality + AI agents gap |
| Big-bang rewrite instead of Boy Scout steps | Risk without incremental gain |
| SOLID before basics stick | Deck: acronyms after DRY/YAGNI |

---

## Cross-axis

```text
Code quality L4 ──requires──▶ Source control L3 (PR review)
                ──pairs with──▶ Testing L4 (CI gates)
                ──overlaps────▶ Team practices L4 (spar)
                ──AI era──────▶ AI agents L4 (eval/review gates)
```

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

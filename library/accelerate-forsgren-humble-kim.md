# Accelerate — Nicole Forsgren, Jez Humble, Gene Kim

**Type:** Book
**Authors:** Nicole Forsgren, Jez Humble, Gene Kim
**Published:** 2018
**ISBN:** 978-1942788331
**Publisher:** IT Revolution Press

**Related:** [DORA research note](../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md) · [Software systems maturity trailhead](../../docs/ai-engineering/software-systems-maturity.md) · [Maturity as navigation — not a benchmark](../../docs/ai-engineering/maturity-as-navigation-not-benchmark.md)

---

## What it is

*Accelerate* presents research linking **software delivery performance** (the DORA four keys) with **technical and cultural capabilities** in organizations studied by the authors and collaborators.

It is evidence-backed advocacy for continuous delivery, trunk-based development, test automation, monitoring, loosely coupled architecture, and generative culture — not a prescriptive maturity certification.

---

## DORA four keys (outcomes)

1. **Deployment frequency**
2. **Lead time for changes**
3. **Time to restore service** (MTTR)
4. **Change failure rate**

These are **outcome metrics** on a defined delivery scope — typically a product or service pipeline — not a single org-wide maturity number.

---

## Capabilities (examples — partial)

The book groups capabilities that **correlated** with higher performance in studied populations.
Treat as hypotheses to test locally, not guarantees:

| Capability (examples) | Often maps to maturity axis here |
|---|---|
| Version control | Source control |
| Trunk-based development | Source control + deployment |
| Continuous integration | Builds & artifacts |
| Continuous delivery / deployment | Deployment & release |
| Test automation | Testing & verification |
| Monitoring / observability | Monitoring & reliability |
| Loosely coupled architecture | Architecture & change |
| Generative culture | Team practices |

**Gaps for 2026 work:** AI agent harnesses, dual-audience documentation, fleet platform policy — named in this workspace's maturity model but not as first-class DORA capabilities.

---

## How to use with this workspace's maturity model

| Lens | Question |
|---|---|
| **DORA / Accelerate** | How fast and safely does *this service or pipeline* deliver? |
| **Software systems maturity** | Which practice gaps block trust, fleet scale, agents, or knowledge — per axis? |

Do not collapse axis levels into a fake DORA score.
Do not ignore DORA when you have delivery metrics and a bounded scope.

Working crosswalk: [dora-accelerate-and-ai-systems.md](../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md).

---

## Limits (read before citing)

- **Correlation ≠ causation** — capabilities associated with performance in research may not transfer unchanged to your org.
- **Population and context** — studies center software delivery organizations; platform/fleet measurement may need per-service or per-pipeline slices.
- **AI era** — whether capability sets shift under heavy agent assistance is an **open question** in this workspace, not a claim in *Accelerate*.

---

## Sources

- [DORA — dora.dev](https://dora.dev/)
- [Accelerate (publisher page)](https://itrevolution.com/product/accelerate/)
- [State of DevOps reports](https://dora.dev/) — ongoing research program

---

*Enriched entry for maturity/DORA crosswalk — JBGE summary, not a substitute for reading the book.*

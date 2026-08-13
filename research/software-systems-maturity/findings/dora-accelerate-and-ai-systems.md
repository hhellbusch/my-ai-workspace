# DORA, Accelerate, and AI systems — research note

**Purpose:** Connect the [software systems maturity](../../../docs/ai-engineering/software-systems-maturity.md) model to DORA/Accelerate evidence — and surface what changes (or doesn't) when AI agents join the delivery path.

**Status:** Working note — axis iteration seed (2026-08-12). Not a standalone essay yet.

**Related:** [Source control deep dive](../../../docs/ai-engineering/maturity/source-control.md) · [Deployment & release](../../../docs/ai-engineering/maturity/deployment-and-release.md) · [AI agents & harnesses](../../../docs/ai-engineering/maturity/ai-agents-and-harnesses.md)

---

## Three lenses (don't collapse them)

| Lens | Question | Typical home |
|---|---|---|
| **Systems / software engineering** | Can we build and operate reliable systems? | This maturity model (multi-axis) |
| **Product / software delivery (DORA)** | How fast and safely do we deliver change? | Four metrics + capabilities in *Accelerate* |
| **Team / craft practice** | How do we work together well? | Team practices axis; session framework |

These overlap but are not interchangeable. A team can score well on DORA metrics while weak on documentation-for-agents — or mature on source control while deployment stays manual.

---

## DORA four keys (reminder)

From the [DORA research program](https://dora.dev/) and *Accelerate* (Forsgren, Humble, Kim):

1. **Deployment frequency**
2. **Lead time for changes**
3. **Time to restore service** (MTTR)
4. **Change failure rate**

DORA studies **outcomes** and correlates them with **capabilities** (technical and cultural). It does not assign a single maturity level per organization.

---

## Mapping DORA capabilities → maturity axes (partial)

| Accelerate / DORA capability (examples) | Primary axis here | Notes |
|---|---|---|
| Version control | [Source control](../../../docs/ai-engineering/maturity/source-control.md) | Foundational |
| Trunk-based development | Source control + [Deployment](../../../docs/ai-engineering/maturity/deployment-and-release.md) | Practice spans both |
| Continuous integration | [Builds & artifacts](../../../docs/ai-engineering/maturity/builds-and-artifacts.md) | |
| Continuous delivery / deployment | Deployment & release | GitOps = pattern under deployment |
| Test automation | [Testing & verification](../../../docs/ai-engineering/maturity/testing-and-verification.md) | |
| Monitoring / observability | [Monitoring & reliability](../../../docs/ai-engineering/maturity/monitoring-and-reliability.md) | |
| Loosely coupled architecture | [Architecture & change](../../../docs/ai-engineering/maturity/architecture-and-change.md) | |
| Generative organizational culture | [Team practices](../../../docs/ai-engineering/maturity/team-practices.md) | Not fully captured by technical axes |

**Gap:** DORA does not cover AI agent harnesses, dual-audience documentation, or fleet platform policy as first-class capabilities — this model's 2026 axes exist partly to name those gaps.

---

## Systems engineering vs "software development"

The 2016 deck was **software development** maturity. The 2026 trailhead expanded to **software systems** — infrastructure, platform, fleet, AI agents.

DORA research historically centered on **software delivery organizations** (often product teams). Platform and fleet engineers still benefit from the same capabilities (VCS, CI, observability) but **measurement** may be per service, per cluster, or per fleet slice — not one org-wide DORA dashboard.

Use DORA metrics **where a defined service or pipeline exists**; use per-axis maturity **where work is inherently multi-axis** (e.g. RHACM hub + Argo + Vault together).

---

## AI era — what might shift

Hypotheses to validate in practice (not claims):

| Observation | Implication |
|---|---|
| Agents increase code and doc **throughput** | Source control L3+ (review before merge) and documentation axis matter *more*, not less |
| Faster typing ≠ faster **delivery** if CI, test, and deploy are unchanged | DORA lead time may stay flat while commit volume rises |
| Agents depend on **committed, linked state** | Source control + documentation/knowledge enable AI agents axis |
| "Vibe coding" without VCS | Level 0 anti-pattern amplified — no audit trail for generated change |
| Maintainer burnout (see library entries on AI + OSS) | Team practices + review gates — DORA culture capabilities |

**Open question for future research:** Do high-performing teams with heavy AI assistance show the same DORA capability correlations, or does the capability set shift (e.g. eval harnesses, agent review, prompt/skills governance)? Track as [AI agents & harnesses](../../../docs/ai-engineering/maturity/ai-agents-and-harnesses.md) matures.

---

## How to use both models together

1. **Pick a service or pipeline** — measure DORA four keys if you have data.
2. **Assess per axis** — use [worksheet](../../../docs/ai-engineering/maturity/worksheet.md) where DORA is flat or unknown.
3. **Prioritize** — improve the axis that blocks the metric that hurts (often deployment, testing, or monitoring before "more AI").

Avoid: converting axis levels into a fake DORA score. Avoid: ignoring DORA because maturity slides feel comfortable.

---

## Sources

- *Accelerate* — Forsgren, Humble, Kim (2018) — [library catalog stub](../../../library/catalog.md)
- [DORA](https://dora.dev/) — ongoing research program
- [Fowler — Continuous Delivery](https://martinfowler.com/bliki/ContinuousDelivery.html) — linked from trailhead
- Workspace: [artifact map](artifact-map.md)

---

## Possible follow-ups

- Enriched library entry for *Accelerate* / DORA (4-step ingest)
- Essay: "DORA in the agent era" under `docs/ai-engineering/`
- Per-axis iteration notes linking DORA capabilities (deployment, builds, testing next)

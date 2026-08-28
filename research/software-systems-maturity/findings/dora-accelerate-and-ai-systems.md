# DORA, Accelerate, and AI systems — research note

**Purpose:** Connect the [software systems maturity](../../../docs/ai-engineering/software-systems-maturity.md) model to DORA/Accelerate evidence — and surface what changes (or doesn't) when AI agents join the delivery path.

**Status:** Working note — optional parallel lens to per-axis maturity. **All 14 axes v2** linked (2026-08-12). Correlation ≠ causation; AI-era rows are hypotheses. See [Accelerate library entry](../../../library/accelerate-forsgren-humble-kim.md) and [navigation vs benchmark essay](../../../docs/ai-engineering/maturity-as-navigation-not-benchmark.md).

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

## Deployment axis — DORA links

**Primary DORA metrics for this axis:**

| DORA metric | Deployment axis connection |
|---|---|
| **Deployment frequency** | L4–5 automated reconcile enables safe frequent promote; L0–2 caps frequency regardless of desire |
| **Lead time for changes** | L3+ declarative Git + PR + pipeline shortens commit→prod; manual deploy steps dominate at L1–2 |
| **Change failure rate** | Under-investment in testing/monitoring at same deploy level — AI throughput can worsen this |
| **MTTR** | L5 drift visibility + rollback paths; GitOps self-heal vs manual reconcile choice ([fleet spectrum](../../../devops/fleet-control-spectrum.md)) |

**Accelerate capabilities mapped here:** continuous delivery, continuous deployment, deployment automation, trunk-based development (with [source control](source-control.md)).

**Fleet nuance:** measure DORA on a **defined service or pipeline** (one app, one promotion path). Fleet-wide "we GitOps everything" is not one metric — hub policy, spokes, and apps may sit at different levels.

**AI era:** agents accelerate manifest **production**; deployment maturity determines whether that increases **deployment frequency** or **change failure rate**. PR diff tools ([argocd-diff-preview](../../../library/argocd-diff-preview.md)) are L3–4 enablers when generation volume rises.

**Corpus (example evidence — rich):** [devops/argo/](../../../devops/argo/README.md) · [artifact map](artifact-map.md) · [deployment deep dive](../../../docs/ai-engineering/maturity/deployment-and-release.md)

---

## Builds axis — DORA links

**Primary DORA connection:** **Continuous integration** (*Accelerate* technical capability) — automated build and test on every change.

| Maturity level | CI / artifact posture |
|---|---|
| **L1–2** | No DORA-aligned CI — integration is manual or scripted ad hoc |
| **L3** | CI runs on change; artifact may still be ephemeral |
| **L4** | Immutable stored artifact (registry tag, rendered manifest commit, pinned CSV) |
| **L5** | Main always deployable; broken build blocks progression — supports **deployment frequency** without raising **change failure rate** |

**Skew pattern:** build **L3** + deploy **L2** (CI produces output, human promotes) — name both axes in assessment.

**GitOps nuance:** fleet repos often treat **CI render + lint** as the build stage and **Argo sync** as deploy ([builds deep dive](../../../docs/ai-engineering/maturity/builds-and-artifacts.md)).

**AI era:** agent throughput increases PR volume — CI capacity and "broken main" discipline (deck: every build deployable) matter more. SBOM/provenance at L5 overlaps [Security](../../../docs/ai-engineering/maturity/security-and-secrets.md) when dependencies are agent-suggested.

**Corpus:** [framework pipelines](../../../devops/argo/examples/framework/pipelines/) · [operators-installer](../../../devops/argo/examples/examples/operators-installer/) · [github-workflows](../../../devops/argo/examples/github-workflows/)

---

## Testing axis — DORA links

**Primary DORA connection:** **Test automation** capability ↔ lower **change failure rate** and safer **deployment frequency** (with [deployment](deployment-and-release.md) and [builds](builds-and-artifacts.md)).

| Maturity signal | DORA / delivery effect |
|---|---|
| Bugs found in production (L1) | High change failure rate; customer as QA |
| Documented plans only (L2) | Manual gating — slow lead time, inconsistent quality |
| Automated suites in non-prod (L3) | Foundation for reliable CI |
| CI gates merge (L4) | Failures caught before prod — primary lever on change failure rate |
| Perf/security + fix-when-found (L5) | Reduces severity and MTTR when failures occur |

**Sandbox discipline:** deck rule — customer discovers bug = too late — aligns with DORA outcomes regardless of test count.

**Skew pattern:** deploy **L4** GitOps + testing **L2** (manual only) → frequent **change failure rate** pain despite fast reconcile.

**Systems engineering:** operational verification (preflight harness, network probes, dry-run) counts toward L3–4 when automated — see [cross-dc-network-test](../../../devops/ocp/examples/networking/cross-dc-network-test/README.md) · [bare-metal sandbox](../../../devops/bare-metal-dev-sandbox/HARNESS.md).

**AI era:** agent-local "testing" without CI does not move DORA metrics; eval harnesses overlap [AI agents](../../../docs/ai-engineering/maturity/ai-agents-and-harnesses.md) axis.

---

## Other axes — DORA touchpoints (v2)

Per-axis detail in deep dives; summary DORA relevance:

| Axis | DORA / Accelerate touchpoint |
|---|---|
| [Code quality](code-quality.md) | Indirect — review culture + **change failure rate** with testing |
| [Architecture & change](architecture-and-change.md) | **Loosely coupled architecture** capability |
| [Data management](data-management.md) | Weak direct link — pipeline integration at L5 |
| [Monitoring & reliability](monitoring-and-reliability.md) | **MTTR** four-key metric |
| [Security & secrets](security-and-secrets.md) | Supply chain overlaps builds L5; not a classic DORA capability name |
| [Documentation & knowledge](documentation-and-knowledge.md) | **Generative culture** enabler; no coverage metric |
| [Platform & fleet](platform-as-accelerator.md) | Measure DORA per service, not cluster count |
| [AI agents & harnesses](ai-agents-and-harnesses.md) | **Open research** — eval/skills not in original DORA set |
| [Team practices](team-practices.md) | **Generative culture** capability |
| [Product discovery](product-discovery.md) | Outcomes vs DORA output metrics — wrong-thing-built risk |

---

## Sources

- *Accelerate* — Forsgren, Humble, Kim (2018) — [library catalog stub](../../../library/catalog.md)
- [DORA](https://dora.dev/) — ongoing research program
- [Fowler — Continuous Delivery](https://martinfowler.com/bliki/ContinuousDelivery.html) — linked from trailhead
- Workspace: [artifact map](artifact-map.md)

---

## Possible follow-ups

- Per-axis iteration — **all 14 axes v2 complete** (2026-08-12)
- Enriched library entry for *Accelerate* / DORA (4-step ingest)
- Essay: "DORA in the agent era" under `docs/ai-engineering/`

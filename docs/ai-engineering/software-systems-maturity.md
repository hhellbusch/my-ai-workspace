---
review:
  status: unreviewed
  notes: "Draft rubric v2 — spar framing pass 2026-08-12. Levels subject to revision; see maturity-as-navigation-not-benchmark.md."
---

# Software Systems Maturity — a trailhead

> **Audience:** Engineers, leads, and peers who want a structured way to assess where a **team or service** is today and what to improve next — including teams new to Kubernetes, teams not on Kubernetes at all, and teams using a platform (Kubernetes, OpenShift, or similar) as a maturity accelerator.
>
> **Purpose:** Introduce a multi-axis maturity model (originally a slide deck from 2016–2017) as a **draft trailhead**. Assess current level **per axis** on *your* scope; prioritize the **next level up**. Deep dives live under [maturity/](maturity/README.md). Example paths in this repo illustrate practices — they do **not** score Field Notes; see [Maturity as navigation — not a benchmark](maturity-as-navigation-not-benchmark.md).

**Origin:** Started in 2016 or 2017; revisited on and off since. The original plan was this intro plus **one deep dive per axis** — those deep dives were never published. This revision expands toward **software systems** (not only application delivery) and **2026 context** (platform fleets, declarative ops, AI agents, knowledge for humans and machines).

**Source material:** [research/software-systems-maturity/](../../research/software-systems-maturity/README.md)

**Related:** [The Shift](the-shift.md) · [Artifact Discipline and AI](artifact-discipline-and-ai.md) · [Sparring and Shoshin](sparring-and-shoshin.md) · [Deployment & release deep dive](maturity/deployment-and-release.md) · [Platform as maturity accelerator](maturity/platform-as-accelerator.md) · [Maturity as navigation — not a benchmark](maturity-as-navigation-not-benchmark.md)

---

## On this page

- [What a maturity model is for](#what-a-maturity-model-is-for)
- [How to use this model](#how-to-use-this-model)
- [Example evidence in this workspace](#example-evidence-in-this-workspace)
- [Models worth knowing (and their limits)](#models-worth-knowing-and-their-limits)
- [Axis ecosystem](#axis-ecosystem)
- [DevOps, GitOps, and API reconcile](#devops-gitops-and-api-reconcile)
- [Platform as maturity accelerator](#platform-as-maturity-accelerator)
- [Axis summaries](#axis-summaries)
- [Deep dives](#deep-dives)
- [What is not here yet](#what-is-not-here-yet)
- [References](#references)

---

## What a maturity model is for

A maturity model assesses how effective, capable, and reliable a person, team, or system is **today**, and suggests what to build or learn **next**.

Questions it helps answer:

- Can we trust this software to run production workloads?
- Can we trust it to support good decisions (metrics, audits, reproducibility)?
- Can we trust **new versions** without heroic effort?

Levels are **prioritization**, not certification. [Martin Fowler's mixologist metaphor](https://martinfowler.com/bliki/MaturityModel.html): novices follow recipes; experts substitute; masters invent from constraints.

The original deck named **software, individual, and team** performance. The axes below are mostly **system and practice** dimensions; [Team practices](#team-practices-optional) and [Product discovery](#product-discovery-optional) make the people/product side explicit.

---

## How to use this model

1. **Assess per team or service** — not one score for the whole organization.
2. **Pick the next level** on the axis that hurts most.
3. **Expect skew** — level 4 builds with level 2 monitoring is common and dangerous.
4. **Use level 0 optionally** for known anti-patterns (manual prod changes, secrets in Git, no docs entry point).
5. **Treat some level 5 rows as aspirational** — especially monitoring/reliability (FMEA, chaos culture).

Disagreement about level is often the valuable output.

**Draft rubric:** Level language here and in deep dives is for **prioritization and conversation**, not certification. Peer review welcome if the framework spreads — see [navigation vs benchmark](maturity-as-navigation-not-benchmark.md).

---

## Example evidence in this workspace

Deep dives and the [artifact map](../../research/software-systems-maturity/findings/artifact-map.md) link to paths in Field Notes as **example evidence** — illustrations of practices on each axis.

They do **not**:

- Rank or certify maturity **of this workspace**
- Imply that copying a path makes **your** team level N
- Treat corpus richness as a score (deployment examples are abundant because practice lives there, not because that axis is "done")

**Corpus bias:** `devops/` is GitOps, OpenShift, and fleet-heavy. Rubrics are generic; examples are not. Thin axes (data, product discovery, much of code quality) rely on external canon — see artifact map **partial** / **thin** labels.

Use example evidence to **find patterns to study**; use the [worksheet](maturity/worksheet.md) with **your** pipeline and runbook links for assessment.

---

## Models worth knowing (and their limits)

### Capability Maturity Model (CMM)

Five levels — Initial through Optimizing — aligned in spirit with continual improvement. Useful vocabulary; dangerous as a **comparison score** (document-heavy history, certification ≠ competence).

### Joel Test and successors

[Joel Spolsky's test](https://www.joelonsoftware.com/2000/08/09/the-joel-test-12-steps-to-better-code/) — blunt project hygiene checklist. Mapped to these axes in the [Joel Test appendix](maturity/joel-test-appendix.md).

### DORA and Accelerate *(optional parallel lens)*

The [DORA research program](https://dora.dev/) and *Accelerate* (Forsgren, Humble, Kim) study **delivery outcomes** — deployment frequency, lead time, MTTR, change failure rate — and **correlate** them with capabilities (VCS, CI, test automation, monitoring, architecture, culture) in researched populations.

**Use DORA when** you have metrics on a **defined service or pipeline**.
**Use this model when** work spans platform, fleet, documentation-for-agents, or AI harnesses that DORA does not name — or when DORA data is missing and you still need a gap conversation.

**Limits:** Correlation in published studies is not causation in your org. Do not convert axis levels into a fake DORA score. AI-era hypotheses (throughput vs delivery, review gates) are **open questions**, not claims — see the [working research note](../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md) and [Accelerate library entry](../../library/accelerate-forsgren-humble-kim.md).

### This model

**One size does not fit all** — define axes that match your context. Kubernetes or OpenShift may accelerate several axes at once; they are not required ([Platform as maturity accelerator](maturity/platform-as-accelerator.md)).

---

## Axis ecosystem

Axes grouped by concern. Per-axis maturity **differs** — that is normal.

| Layer | Axis | Deep dive |
|---|---|---|
| **Build** | Source control | [source-control.md](maturity/source-control.md) |
| | Code quality | [code-quality.md](maturity/code-quality.md) |
| | Testing & verification | [testing-and-verification.md](maturity/testing-and-verification.md) |
| | Architecture & change | [architecture-and-change.md](maturity/architecture-and-change.md) |
| **Ship** | Builds & artifacts | [builds-and-artifacts.md](maturity/builds-and-artifacts.md) |
| | Deployment & release | [deployment-and-release.md](maturity/deployment-and-release.md) |
| | Data management | [data-management.md](maturity/data-management.md) |
| **Run** | Monitoring & reliability | [monitoring-and-reliability.md](maturity/monitoring-and-reliability.md) |
| **Protect** | Security & secrets | [security-and-secrets.md](maturity/security-and-secrets.md) |
| **Know** | Documentation & knowledge | [documentation-and-knowledge.md](maturity/documentation-and-knowledge.md) |
| **Scale** | Platform & fleet | [platform-as-accelerator.md](maturity/platform-as-accelerator.md) |
| **Automate** | AI agents & harnesses | [ai-agents-and-harnesses.md](maturity/ai-agents-and-harnesses.md) |
| **People** | Team practices | [team-practices.md](maturity/team-practices.md) |
| **Product** *(optional)* | Product discovery | [product-discovery.md](maturity/product-discovery.md) |

**Merged elsewhere (not standalone axes):** supply chain provenance → Builds + Security; observability→action → Monitoring & reliability; GitOps → pattern under Deployment (+ Platform for fleet policy).

**Workspace artifact map:** [research/software-systems-maturity/findings/artifact-map.md](../../research/software-systems-maturity/findings/artifact-map.md) — example evidence index, not a workspace scorecard.

---

## DevOps, GitOps, and API reconcile

These are **not** "we use Git." They are a stack of maturity patterns — detailed in [Deployment & release](maturity/deployment-and-release.md) with examples from [devops/argo/](../../devops/argo/README.md).

```text
DevOps       → own delivery end-to-end; shorten feedback loops
CI/CD        → automate build, test, promote through environments
GitOps       → declarative desired state in Git; diff/review; reconcile; drift
API reconcile → same principles when apply target is REST/CLI/Job, not a CR
```

| Level | Posture |
|---|---|
| 0 | Prod changes manual, unique, untracked ("snowflakes") |
| 1 | Scripts exist; human runs per environment |
| 2 | Pipeline automates build/test; deploy still manual or partial |
| 3 | Declarative desired state in Git; human or gated apply |
| 4 | Automated reconcile (operator, Argo CD, Terraform, or idempotent API Job) |
| 5 | Drift visible; unsafe drift corrected or alerted |

**Common confusion:** a repo and pull requests are **source control** maturity. **GitOps** starts when merged main (or a release branch) is what production **converges toward**, with automation doing the converge.

**API-driven systems** (legacy platforms, admin REST, CLIs) can reach levels 3–5 with **desired spec in Git + reconcile script** — GitOps principles without a Kubernetes CR. See deployment deep dive.

---

## Platform as maturity accelerator

Teams adopt Kubernetes, OpenShift, and similar platforms because a **shared control plane** advances multiple axes together — not because containers are fashionable.

| Capability | Axes helped |
|---|---|
| Declarative workloads, rollouts, health checks | Deployment, Monitoring |
| Namespaces, quotas, network policy | Security, Architecture |
| Operators, OLM, GitOps hooks | Deployment, Platform |
| Central logging/metrics stacks | Monitoring |
| Secrets integration (ESO, Vault agents, platform vaults) | Security & secrets |
| Multi-cluster fleet tools (ACM-class) | Platform & fleet |

**New to Kubernetes:** you may be level 1–2 on several axes while the **platform gives you level 3 primitives for free** (e.g. rolling updates, liveness probes). Assess **your team's practices**, not only what the platform makes possible.

**Not on Kubernetes:** the same axes apply. Maturity is measured against **your** delivery and runtime model (VMs, serverless, mainframe ops, SaaS config). The patterns (declarative state, reconcile, drift) transfer; the machinery differs.

Full write-up: [Platform as maturity accelerator](maturity/platform-as-accelerator.md).

---

## Axis summaries

Five levels per axis unless noted. Deep dives add teaching stories, anti-patterns, and repo examples.

### Source control

| Level | Posture |
|---|---|
| 0 | No VCS, or critical work outside VCS |
| 1 | Shared remote; regular commits; basic collaboration |
| 2 | Branching model agreed; meaningful commit messages |
| 3 | Protected main; PR/MR review before merge |
| 4 | CI on every change; hooks (lint, test, sign) |
| 5 | Safe history repair; monorepo or multi-repo governance documented |

Deep dive: [deck lineage, DORA alignment, fleet/AI notes](maturity/source-control.md).

### Code quality

Levels 0–5 — deck lineage, tradable quality, AI review gates: [code-quality deep dive](maturity/code-quality.md).

### Testing & verification

Levels 0–5 — sandbox discipline, DORA change failure rate, verification corpus: [testing deep dive](maturity/testing-and-verification.md).

### Architecture & change

Levels 0–5 — fleet Git truth, loosely coupled architecture: [architecture deep dive](maturity/architecture-and-change.md).

### Builds & artifacts

Levels 0–5 — deck lineage, DORA CI mapping, GitOps render pipeline: [builds deep dive](maturity/builds-and-artifacts.md).

### Deployment & release

See [DevOps/GitOps table](#devops-gitops-and-api-reconcile) and [deep dive](maturity/deployment-and-release.md) — deck lineage, DORA links (deployment frequency, CD), fleet corpus, AI-era review gates.

### Data management

Levels 0–5 — evolutionary design, deck lineage (thin repo corpus): [data-management deep dive](maturity/data-management.md).

### Monitoring & reliability

Levels 0–5 — deck lineage, DORA MTTR, SLO primer; L5 aspirational: [monitoring deep dive](maturity/monitoring-and-reliability.md).

### Security & secrets

Two tracks, one axis — **application security** and **secrets/IAM ops**.

| Level | Application security | Secrets & identity |
|---|---|---|
| 0 | Known antipatterns tolerated (hardcoded creds, unsafe defaults) | Secrets in Git, images, or plain config |
| 1 | Antipatterns removed ad hoc | Central store; manual copy; long-lived tokens |
| 2 | Basic threat awareness; reactive patches | Scoped paths/policies; rotation runbooks |
| 3 | Designed against common attacks | Dynamic secrets; least privilege |
| 4 | Secure-by-default; fine-grained authz | Integrated with CI/CD and runtime |
| 5 | Regular audits; patch discipline | Automated rotation; blast-radius drills |

Vault-class platforms exemplify the secrets track — see [security deep dive](maturity/security-and-secrets.md) (deck lineage, fleet secrets) and [devops/vault/](../../devops/vault/README.md).

### Documentation & knowledge

Outcome-based — not coverage percentages. **Dual audience:** humans and agent sessions.

| Level | Posture |
|---|---|
| 1 | Scattered; no entry point |
| 2 | Findable for humans; unstable for agents |
| 3 | Conventions (structure, index, metadata) |
| 4 | Handoffs, skills, artifact discipline (JBGE/TAGRI) |
| 5 | Orientation time improves; fewer repeated mistakes *(directional — not audited)* |

See [documentation deep dive](maturity/documentation-and-knowledge.md) (deck critique of coverage %, dual audience) and [Artifact Discipline and AI](artifact-discipline-and-ai.md).

### Platform & fleet

| Level | Posture |
|---|---|
| 0 | Manual platform changes untracked |
| 1 | Single cluster/account; manual drift |
| 2 | Multiple envs; documented differences |
| 3 | Git-managed platform config; promotion model |
| 4 | Multi-cluster/fleet; policy as code |
| 5 | Upgrade safety, blast-radius governance measured |

Deep dive: [platform accelerator](maturity/platform-as-accelerator.md) · [fleet corpus](../../devops/fleet-control-spectrum.md).

### AI agents & harnesses

| Level | Posture |
|---|---|
| 0 | Unreviewed agent changes to prod |
| 1 | Ad hoc prompts; no review |
| 2 | Repeatable prompts/skills; human reviews all output |
| 3 | Bounded tools; session/handoff discipline |
| 4 | Spar/eval gates on risky changes |
| 5 | Failure modes catalogued; improvement measured |

See [The Shift](the-shift.md) and [AI agents deep dive](maturity/ai-agents-and-harnesses.md) (harness layers, DORA open questions).

### Team practices

| Level | Posture |
|---|---|
| 0 | Blame culture; hero-only recovery |
| 1 | Hero knowledge; inconsistent onboarding |
| 2 | Ad hoc pairing/review |
| 3 | Onboarding checklist; review expected |
| 4 | Deliberate practices (spar, shoshin, retros that change behavior) |
| 5 | Learning loops; safe to challenge frames |

See [Session Framework](session-framework.md) and [team practices deep dive](maturity/team-practices.md) (DORA generative culture).

### Product discovery *(optional)*

Skip or mark N/A for pure platform/infra teams.

| Level | Posture |
|---|---|
| 0 | Build without problem statement |
| 1 | Build what's asked; no validation |
| 2 | Informal stakeholder conversation |
| 3 | Problem statement and success criteria before build |
| 4 | Thin experiments; data-informed priority |
| 5 | Continuous discovery tied to outcomes |

Deep dive: [optional axis, AI TAGRI](maturity/product-discovery.md). Not big upfront spec — **validated learning** before expensive build.

---

## Deep dives

Full index: [maturity/README.md](maturity/README.md) — **14 axis v2 deep dives** + [Joel Test appendix](maturity/joel-test-appendix.md) + [assessment worksheet](maturity/worksheet.md).

| Layer | Topics |
|---|---|
| Build | Source control, code quality, testing, architecture & change |
| Ship | Builds, deployment, data |
| Run / protect / know | Monitoring, security, documentation |
| Scale / automate / people | Platform, AI agents, team practices |
| Optional | Product discovery |

---

## What is not here yet

- **Draft rubric** — levels subject to revision; [navigation vs benchmark essay](maturity-as-navigation-not-benchmark.md)
- **Deep author review** — optional `/validate read` per doc after merge
- Deck **PDF** for diagram-only slides not captured in text export
- Worked **SLO YAML / error-budget alert** examples in devops (primer exists: [slo-and-runbooks.md](../../devops/slo-and-runbooks.md))
- Expanded **product discovery** corpus (optional axis — thin by choice)
- **`maturity:` frontmatter** on corpus paths — optional; see [artifact map](../../research/software-systems-maturity/findings/artifact-map.md)

Track progress: [resurrection notes](../../research/software-systems-maturity/findings/2026-resurrection-notes.md) · [artifact map](../../research/software-systems-maturity/findings/artifact-map.md) · [session handoff](../../.planning/software-systems-maturity/whats-next.md)

If this framework becomes an organizational standard, level rubrics need peer review — this document remains the **draft trailhead**.

---

## References

- [Martin Fowler — Maturity Model](https://martinfowler.com/bliki/MaturityModel.html)
- [Joel Spolsky — The Joel Test](https://www.joelonsoftware.com/2000/08/09/the-joel-test-12-steps-to-better-code/)
- [Continuous Delivery (Fowler)](https://martinfowler.com/bliki/ContinuousDelivery.html)
- [Evolutionary Database Design (Fowler)](https://martinfowler.com/articles/evodb.html)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

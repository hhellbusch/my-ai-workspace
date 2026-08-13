---
review:
  status: unreviewed
  notes: "2026 revision — v1 first pass complete (author skim OK 2026-08-12). Deep dives in maturity/."
---

# Software Systems Maturity — a trailhead

> **Audience:** Engineers, leads, and peers who want a structured way to assess where a team or system is today and what to improve next — including teams new to Kubernetes, teams not on Kubernetes at all, and teams using a platform (Kubernetes, OpenShift, or similar) as a maturity accelerator.
>
> **Purpose:** Introduce a multi-axis maturity model (originally a slide deck from 2016–2017) as a **trailhead**. Assess current level **per axis**; prioritize the **next level up**. Deep dives live under [maturity/](maturity/README.md).

**Origin:** Started in 2016 or 2017; revisited on and off since. The original plan was this intro plus **one deep dive per axis** — those deep dives were never published. This revision expands toward **software systems** (not only application delivery) and **2026 context** (platform fleets, declarative ops, AI agents, knowledge for humans and machines).

**Source material:** [research/software-systems-maturity/](../../research/software-systems-maturity/README.md)

**Related:** [The Shift](the-shift.md) · [Artifact Discipline and AI](artifact-discipline-and-ai.md) · [Sparring and Shoshin](sparring-and-shoshin.md) · [Deployment & release deep dive](maturity/deployment-and-release.md) · [Platform as maturity accelerator](maturity/platform-as-accelerator.md)

---

## On this page

- [What a maturity model is for](#what-a-maturity-model-is-for)
- [How to use this model](#how-to-use-this-model)
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

---

## Models worth knowing (and their limits)

### Capability Maturity Model (CMM)

Five levels — Initial through Optimizing — aligned in spirit with continual improvement. Useful vocabulary; dangerous as a **comparison score** (document-heavy history, certification ≠ competence).

### Joel Test and successors

[Joel Spolsky's test](https://www.joelonsoftware.com/2000/08/09/the-joel-test-12-steps-to-better-code/) — blunt project hygiene checklist. Mapped to these axes in the [Joel Test appendix](maturity/joel-test-appendix.md).

### DORA and Accelerate

The [DORA research program](https://dora.dev/) and *Accelerate* (Forsgren, Humble, Kim) correlate **technical capabilities** (version control, trunk-based development, CI, test automation, monitoring, architecture) with **delivery performance** — deployment frequency, lead time, MTTR, change failure rate.

Use DORA for **outcome metrics** on a defined service or pipeline; use this model's **per-axis levels** where work spans platform, fleet, documentation-for-agents, and AI harnesses that DORA does not name explicitly. In the AI era, faster code generation raises the cost of weak review gates and thin observability — it does not replace them.

Working map: [DORA, Accelerate, and AI systems](../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md).

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

**Workspace artifact map:** [research/software-systems-maturity/findings/artifact-map.md](../../research/software-systems-maturity/findings/artifact-map.md)

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

| Level | Posture |
|---|---|
| 1 | No standards |
| 2 | Style guide; DRY, YAGNI |
| 3 | Linting; environment config not hard-coded |
| 4 | Review before merge — human decision; agents assist |
| 5 | Periodic architecture/health review; debt reduced |

### Testing & verification

| Level | Posture |
|---|---|
| 0 | No test intent; production is the test environment |
| 1 | Ad hoc; bugs found in production |
| 2 | Documented test cases |
| 3 | Automated unit/integration (or operational equivalent); non-prod runs |
| 4 | CI gates; coverage or risk analysis informs runs |
| 5 | Performance/security characterization; defects fixed when found |

Deep dive: [sandbox discipline, DORA change failure rate, verification corpus](maturity/testing-and-verification.md).

### Architecture & change

| Level | Posture |
|---|---|
| 1 | Ad hoc structure; breaking changes surprise consumers |
| 2 | Informal boundaries; occasional ADRs |
| 3 | Documented interfaces; deprecation notices |
| 4 | Change governance (who approves prod); compatibility policy |
| 5 | Evolution measured; technical debt visible in roadmap |

### Builds & artifacts

| Level | Posture |
|---|---|
| 0 | No build step; compile on target hosts |
| 1 | Manual ad hoc builds |
| 2 | Script automation |
| 3 | CI-built artifacts (or rendered output) on every change |
| 4 | Artifact registry or committed render; immutable tags |
| 5 | Every build deployable; broken build stops the line; provenance/SBOM on critical paths |

Deep dive: [deck lineage, DORA CI mapping, GitOps render pipeline](maturity/builds-and-artifacts.md).

### Deployment & release

See [DevOps/GitOps table](#devops-gitops-and-api-reconcile) and [deep dive](maturity/deployment-and-release.md) — deck lineage, DORA links (deployment frequency, CD), fleet corpus, AI-era review gates.

### Data management

| Level | Posture |
|---|---|
| 1 | Ad hoc schemas |
| 2 | Designed; reviewed; normalized where appropriate |
| 3 | Migrations; DR plan exists |
| 4 | Automated migrations |
| 5 | Data change integrated with delivery pipeline |

### Monitoring & reliability

| Level | Posture |
|---|---|
| 1 | Reactive firefighting |
| 2 | Logging; manual checks |
| 3 | Automated alerts; runbooks |
| 4 | SLOs; traceability to root cause |
| 5 | *(Aspirational)* FMEA, chaos, error-budget culture |

### Security & secrets

Two tracks, one axis — **application security** and **secrets/IAM ops**.

| Level | Application security | Secrets & identity |
|---|---|---|
| 1 | Known antipatterns in code | Secrets in repo or plain config |
| 2 | Antipatterns removed | Central store; manual rotation |
| 3 | Designed against common attacks | Dynamic secrets; least privilege |
| 4 | Secure-by-default; fine-grained authz | Integrated with CI/CD and runtime |
| 5 | Audits; patch discipline | Automated rotation; blast-radius drills |

Vault-class platforms exemplify the secrets track — see [security deep dive](maturity/security-and-secrets.md) and [devops/vault/](../../devops/vault/README.md).

### Documentation & knowledge

Outcome-based — not coverage percentages. **Dual audience:** humans and agent sessions.

| Level | Posture |
|---|---|
| 1 | Scattered; no entry point |
| 2 | Findable for humans; unstable for agents |
| 3 | Conventions (structure, index, metadata) |
| 4 | Handoffs, skills, artifact discipline (JBGE/TAGRI) |
| 5 | Time-to-orient improves; fewer repeated mistakes |

See [documentation deep dive](maturity/documentation-and-knowledge.md) and [Artifact Discipline and AI](artifact-discipline-and-ai.md).

### Platform & fleet

| Level | Posture |
|---|---|
| 1 | Single cluster/account; manual drift |
| 2 | Multiple envs; documented differences |
| 3 | Git-managed platform config; promotion model |
| 4 | Multi-cluster/fleet; policy as code |
| 5 | Upgrade safety, blast-radius governance measured |

### AI agents & harnesses

| Level | Posture |
|---|---|
| 1 | Ad hoc prompts; no review |
| 2 | Repeatable prompts/skills; human reviews all output |
| 3 | Bounded tools; session/handoff discipline |
| 4 | Spar/eval gates on risky changes |
| 5 | Failure modes catalogued; improvement measured |

See [The Shift](the-shift.md) and [AI agents deep dive](maturity/ai-agents-and-harnesses.md).

### Team practices

| Level | Posture |
|---|---|
| 1 | Hero knowledge; inconsistent onboarding |
| 2 | Ad hoc pairing/review |
| 3 | Onboarding checklist; review expected |
| 4 | Deliberate practices (spar, shoshin, retros that change behavior) |
| 5 | Learning loops; safe to challenge frames |

See [Session Framework](session-framework.md) and [team practices deep dive](maturity/team-practices.md).

### Product discovery *(optional)*

Skip or mark N/A for pure platform/infra teams.

| Level | Posture |
|---|---|
| 1 | Build what's asked; no validation |
| 2 | Informal stakeholder conversation |
| 3 | Problem statement and success criteria before build |
| 4 | Thin experiments; data-informed priority |
| 5 | Continuous discovery tied to outcomes |

Not a return to big upfront spec — **validated learning** before expensive build.

---

## Deep dives

Full index: [maturity/README.md](maturity/README.md) — **14 axis drafts** + [Joel Test appendix](maturity/joel-test-appendix.md) + [assessment worksheet](maturity/worksheet.md).

| Layer | Topics |
|---|---|
| Build | Source control, code quality, testing, architecture & change |
| Ship | Builds, deployment, data |
| Run / protect / know | Monitoring, security, documentation |
| Scale / automate / people | Platform, AI agents, team practices |
| Optional | Product discovery |

---

## What is not here yet

- **Deep author review** — first pass skim OK; optional `/validate read` per doc after merge
- Deck **PDF** for diagram-only slides not captured in text export
- Worked **SLO YAML / error-budget alert** examples in devops (primer exists: [slo-and-runbooks.md](../../devops/slo-and-runbooks.md))
- Expanded **product discovery** corpus (optional axis — thin by choice)
- **`maturity:` frontmatter** on corpus paths — optional; see [artifact map](../../research/software-systems-maturity/findings/artifact-map.md)

Track progress: [resurrection notes](../../research/software-systems-maturity/findings/2026-resurrection-notes.md) · [artifact map](../../research/software-systems-maturity/findings/artifact-map.md) · [session handoff](../../.planning/software-systems-maturity/whats-next.md)

If this framework becomes an organizational standard, level rubrics need peer review — this document remains the **trailhead**.

---

## References

- [Martin Fowler — Maturity Model](https://martinfowler.com/bliki/MaturityModel.html)
- [Joel Spolsky — The Joel Test](https://www.joelonsoftware.com/2000/08/09/the-joel-test-12-steps-to-better-code/)
- [Continuous Delivery (Fowler)](https://martinfowler.com/bliki/ContinuousDelivery.html)
- [Evolutionary Database Design (Fowler)](https://martinfowler.com/articles/evodb.html)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

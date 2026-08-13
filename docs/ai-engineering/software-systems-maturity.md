---
review:
  status: unreviewed
  notes: "Resurrected from 2016–2017 slide deck text export; 2026 expansion draft — author review needed for new axes."
---

# Software Systems Maturity — a trailhead

> **Audience:** Engineers, leads, and peers who want a structured way to assess where a team or system is today and what to improve next — without pretending one score captures everything.
>
> **Purpose:** Introduce a multi-axis maturity model (originally a slide deck from 2016–2017) as a **trailhead**, not a complete guide. Assess current level per axis; prioritize the **next level up**.

**Origin:** Started in 2016 or 2017; revisited on and off since. The original plan was this intro plus **one deep dive per axis** — those deep dives were never published. This essay resurrects the framework and sketches **2026 expansions** (platform, GitOps, AI agents — affectionately *clankers*).

**Source material:** [research/software-systems-maturity/](../../research/software-systems-maturity/README.md)

**Related:** [The Shift](the-shift.md) · [Artifact Discipline and AI](artifact-discipline-and-ai.md) · [Sparring and Shoshin](sparring-and-shoshin.md) · [GitOps maturity ladder (cluster links)](../../devops/ocp/examples/messaging/kafka/cluster-link-gitops/README.md#gitops-maturity-ladder-cluster-links)

---

## On this page

- [What a maturity model is for](#what-a-maturity-model-is-for)
- [Models worth knowing (and their limits)](#models-worth-knowing-and-their-limits)
- [How to use this model](#how-to-use-this-model)
- [The nine axes (2016 core)](#the-nine-axes-2016-core)
- [2026 — toward software systems](#2026--toward-software-systems)
- [Domain-specific ladders](#domain-specific-ladders)
- [What is not here yet](#what-is-not-here-yet)
- [References](#references)

---

## What a maturity model is for

A maturity model is a tool to assess how effective, capable, and reliable a person, team, or system is **today**, and to suggest what to learn or build **next**.

Questions it helps answer:

- Can we trust this software to run production workloads?
- Can we trust it to support good decisions (metrics, audits, reproducibility)?
- Can we trust **new versions** without heroic effort?

It is structured as **levels** — usually four or five per axis. The point is not certification or ranking companies. The point is **prioritization**: if you are at level 2 on testing, work on level 3 before chasing level 5 on documentation.

[Martin Fowler's mixologist metaphor](https://martinfowler.com/bliki/MaturityModel.html) captures the idea: novices follow recipes; experts substitute missing ingredients; masters invent drinks from constraints. Maturity is capability under variation — and exceptions keep increasing.

---

## Models worth knowing (and their limits)

### Capability Maturity Model (CMM)

Five levels — Initial, Managed, Defined, Quantitatively Managed, Optimizing — aligned in spirit with [ISO 9001](https://www.iso.org/iso-9001-quality-management.html) continual improvement. Many organizations aim for **Defined (3) through Optimizing (5)**.

**Caveats** (still valid):

- Document-heavy, plan-driven culture — tension with agile (*working software*, *responding to change*).
- Certification industry ≠ competence.
- Comparing organizations by level alone invites gaming.

Use CMM for vocabulary and improvement mindset; do not treat the level as destiny.

### Joel Test and successors

[Joel Spolsky's 12-step test](https://www.joelonsoftware.com/2000/08/09/the-joel-test-12-steps-to-better-code/) — a blunt checklist for project hygiene. Updated variants (e.g. SavvyClutch) exist. Useful as a **conversation starter**, not a full systems view.

### This model

**One size does not fit all** — define axes that match your organization. The nine axes below were chosen for software delivery teams; 2026 adds room for **platform**, **fleet**, and **AI-driven systems**.

---

## How to use this model

1. **Assess** each axis honestly (team self-assessment beats external audit for learning).
2. **Pick the next level** on the axis that hurts most — not the highest glamour axis.
3. **Generate conversation** — disagreements about level often reveal real risks.
4. **Re-assess** after meaningful change; levels are not permanent badges.

Per-axis maturity can differ: level 4 builds with level 2 monitoring is a common and dangerous pattern.

---

## The nine axes (2016 core)

Each axis uses five levels (1 = weakest, 5 = strongest). Wording follows the original deck; minor 2026 edits noted inline.

### Source control

Version control is document control for code — the backbone of collaboration and audit.

| Level | Posture |
|---|---|
| 1 — Not used | No VCS, or rarely used |
| 2 — Used | Central server (or equivalent), regular commits |
| 3 — Standardized | Commit message standards; branching model agreed |
| 4 — Integrated | Tied to CI/CD automation |
| 5 — Hooks & surgery | Hooks boost productivity; team can fix history safely ("repo surgery") |

Tools named in the deck (CVS → SVN → **Git**) date the examples; the levels are tool-agnostic.

### Code quality

Quality is not tradable like a luxury car — [lack of quality costs people-time](https://martinfowler.com/bliki/TradableQualityHypothesis.html). Defects get more expensive the longer they live; erosion makes new features harder ([Boy Scout Rule](https://martinfowler.com/bliki/OpportunisticRefactoring.html): leave it a little better).

| Level | Posture |
|---|---|
| 1 — Poor | No standards |
| 2 — Style guide | DRY, YAGNI; style guide for major languages |
| 3 — Linting | Linters; hard-coded environment params largely gone |
| 4 — Code review | Regular reviews — manual **and clanker-assisted** (2026) |
| 5 — System evaluation | Periodic design review; legacy and debt actively reduced |

SOLID and friends remain the advanced vocabulary ([SRP, O/C, LSP, ISP, DIP](https://en.wikipedia.org/wiki/SOLID)) — teach when level 2–3 is stable, not before.

### Testing

Push discovery left: production is **too late** for first discovery ([sandbox discipline](http://www.agiledata.org/essays/sandboxes.html)).

| Level | Posture |
|---|---|
| 1 — Ad hoc | Little or no testing; bugs in production |
| 2 — Test plans | Documented cases and expected behaviors |
| 3 — Automated unit/integration | Suite automated; runs in non-prod |
| 4 — CI/CD integrated | Tests gate automation; coverage informs risk |
| 5 — Performance & security | Broader characterization; defects fixed immediately when found |

### Builds

Turn code into **observable artifacts** ([12-factor release](https://12factor.net/)).

| Level | Posture |
|---|---|
| 1 — Manual | Ad hoc builds |
| 2 — Scripts | Partial script automation |
| 3 — CI/CD integrated | Builds in developer pipeline |
| 4 — Artifact management | Built artifacts stored and shared reliably |
| 5 — Every build deployable | Broken builds block new work |

### Deployment

Minimize risk and **environment variation** ([Continuous Delivery](https://martinfowler.com/bliki/ContinuousDelivery.html), [deployment pipeline](https://martinfowler.com/bliki/DeploymentPipeline.html)).

| Level | Posture |
|---|---|
| 1 — Manual | Snowflake servers; unique each time |
| 2 — Automated, manual run | Scripts exist but human triggers per server |
| 3 — Standardized & integrated | Orchestrated via IT/dev tools |
| 4 — Multi-env safe | Dev/test/prod; blue/green or canary |
| 5 — Zero-touch CD | Frequent, efficient, safe production updates |

### Data management

Design, evolution, migration, and **recovery** ([evolutionary database design](https://martinfowler.com/articles/evodb.html)).

| Level | Posture |
|---|---|
| 1 — Ad hoc | Structures undocumented |
| 2 — Designed | Reviewed design; normalized where OLTP applies |
| 3 — Migrations & DR plan | Migrations for change; DR documented |
| 4 — Automated migrations | Schema/data change automated |
| 5 — CI/CD integrated | Data management in same automation as code |

### Security

Assume benign misuse before malice. Antipatterns (passwords in repo) eliminated early.

| Level | Posture |
|---|---|
| 1 — Antipatterns | Known bad patterns still present |
| 2 — No antipatterns | Bad habits gone; not designed for security |
| 3 — Designed | Resists common attacks; basic access control |
| 4 — Secure by default | Fine-grained authorization (ACLs, etc.) |
| 5 — Audited | Regular audits; patches applied deliberately |

### Documentation

Agile manifesto says working software — not **no** documentation ([Ambler on the manifesto](http://www.ambysoft.com/essays/agileManifesto.html)). Document as you build; keep it findable.

| Level | Posture |
|---|---|
| 1 — None | — |
| 2 — Ad hoc | Scattered docs |
| 3 — Standardized | Standard + >50% coverage; easy to find |
| 4 — Publishing | ~90%+ coverage; WIP publish workflow |
| 5 — Living docs | Auto-publish on change; periodic stale review |

See also [Artifact Discipline and AI](artifact-discipline-and-ai.md) for when **not** to write docs in the AI era.

### Monitoring

Move from firefighting to **proactive** failure management.

| Level | Posture |
|---|---|
| 1 — None / ad hoc | Reactive only |
| 2 — Basic logging | Manual monitoring |
| 3 — Automated | Alerts; may trigger support |
| 4 — Traceability | Standardized logs; root-cause friendly |
| 5 — FMEA | Proactive failure-mode analysis |

---

## 2026 — toward software systems

The deck already pointed past "software development" to **software systems** — infrastructure, platform, AI-driven components. Proposed additional axes (draft; levels TBD in deep dives):

| Axis | Scope |
|---|---|
| **Platform & fleet** | Multi-cluster lifecycle, policy, identity, upgrade safety |
| **GitOps & declarative ops** | Desired state in Git, reconcile, drift detection |
| **AI agents & harnesses** | Tool boundaries, review gates, non-determinism, session state |
| **Supply chain & provenance** | SBOM, signed artifacts, dependency hygiene (extends Security/Builds) |

**Clankers** belong explicitly in **code review** (level 4) today and likely earn their own axis as agent autonomy increases — see [The Shift](the-shift.md) for where human judgment moves when implementation is cheap.

---

## Domain-specific ladders

Not every problem needs a new top-level axis. Narrow **domain ladders** nest under Deployment, Platform, or GitOps:

**Example:** [GitOps maturity ladder for Cluster Links](../../devops/ocp/examples/messaging/kafka/cluster-link-gitops/README.md#gitops-maturity-ladder-cluster-links) — levels 0 (Control Center only) through 5 (drift-aware reconcile). Same pattern could apply to topic provisioning, ACL management, or fleet import.

Use a domain ladder when:

- The general axis (e.g. Deployment level 3) is true but a **specific capability** is still ad hoc.
- You need Argo/CI conversation with concrete next steps.

---

## What is not here yet

Per the original 2016 intent, each axis deserves its **own deep dive** — not written yet:

- Source control, quality, testing, builds, deployment, data, security, documentation, monitoring
- New: platform/fleet, GitOps, AI agents

The [2026 resurrection notes](../../research/software-systems-maturity/findings/2026-resurrection-notes.md) track proposed structure. A separate data-management deep dive was drafted historically but is not published here.

If this framework evolves toward a published organizational standard, axis definitions and level rubrics need peer review — this essay is the **trailhead**, not the final standard.

---

## References

- [Martin Fowler — Maturity Model](https://martinfowler.com/bliki/MaturityModel.html)
- [Joel Spolsky — The Joel Test](https://www.joelonsoftware.com/2000/08/09/the-joel-test-12-steps-to-better-code/)
- [Capability Maturity Model (Wikipedia)](https://en.wikipedia.org/wiki/Capability_Maturity_Model)
- [Continuous Delivery (Fowler)](https://martinfowler.com/bliki/ContinuousDelivery.html) · [Blue-green deployment](https://martinfowler.com/bliki/BlueGreenDeployment.html)
- [Evolutionary Database Design (Fowler)](https://martinfowler.com/articles/evodb.html)
- [Unit testing (Fowler)](https://martinfowler.com/bliki/UnitTest.html)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

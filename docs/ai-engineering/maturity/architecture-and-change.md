---
review:
  status: unreviewed
  notes: "Architecture & change v2 — fleet Git truth, DORA loosely coupled, change governance."
---

# Architecture & Change — maturity deep dive

> **Audience:** Teams assessing system boundaries, evolution, and **who may change production how**.
>
> **Purpose:** Structural coherence separate from [documentation](documentation-and-knowledge.md); fleet Git-truth and change governance patterns.

**Related:** [Source control](source-control.md) · [Deployment](deployment-and-release.md) · [Platform accelerator](platform-as-accelerator.md) · [DORA / AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md)

---

## What this axis answers

*Is the system evolvable — and are changes governed without surprise?*

DORA **loosely coupled architecture** supports delivery performance — small, independent changes fail less often. This axis names **boundaries and governance**, not microservice count.

---

## Levels

| Level | Posture |
|---|---|
| **0** | No shared model; prod changes bypass design |
| **1** | Ad hoc structure; breaking changes surprise consumers |
| **2** | Informal boundaries; occasional design notes |
| **3** | ADRs or equivalent; interfaces documented; deprecation notices |
| **4** | Change governance (approvers, windows); compatibility policy |
| **5** | Technical debt visible in roadmap; coupling/change failure tracked |

**Documentation overlap:** ADRs live in [documentation & knowledge](documentation-and-knowledge.md) — this axis asks whether **decisions constrain future change**.

---

## Fleet / GitOps architecture (repo evidence)

| Pattern | Level signal | Path |
|---|---|---|
| Git is only source of truth | L3–4 | [GUIDELINES](../../../devops/argo/examples/framework/GUIDELINES.md) |
| Hub-and-spoke; central reconcile | L4 | GUIDELINES §1.1 |
| Cascading values + cluster sovereignty | L4 | [architecture-opinions.md](../../../devops/argo/examples/helm-component-pattern/docs/architecture-opinions.md) |
| RHACM vs Argo authority spectra | L4–5 design | [fleet-control-spectrum.md](../../../devops/fleet-control-spectrum.md) |
| Greenfield fleet stack choices | L3–4 | [greenfield-fleet-architecture.md](../../../devops/rhacm/notes/greenfield-fleet-architecture.md) |
| Promotion / change windows | L4 | [framework promotion](../../../devops/argo/examples/framework/README.md) |

These enable [deployment](deployment-and-release.md) L4+ — architecture choices **precede** GitOps mechanics.

---

## AI era

Agents refactor across boundaries without map → silent coupling. **L3 ADRs** and [spar](../sparring-and-shoshin.md) before large agent-driven restructures. Fleet repos: agent edits to `groups/all/values.yaml` need cascade understanding ([architecture-opinions](../../../devops/argo/examples/helm-component-pattern/docs/architecture-opinions.md)).

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| `oc edit` hotfix without Git follow-up | Reconciler reverts or drift hides |
| Shared library without versioning | Silent breaks |
| "Strangler" without boundary map | Two systems, one confusion |
| ADRs written after merge | Theater |
| App-of-apps without ownership matrix | [bigfix-gitops-on-ocp.md](../../../devops/bigfix-gitops-on-ocp.md) — discussion pattern |

---

## Cross-axis

```text
Architecture ──enables──▶ Deployment (GitOps invariants)
             ──documented in──▶ Documentation (ADRs)
             ──constrained by──▶ Security (policy boundaries)
             ──fleet scale──▶ Platform (multi-cluster)
```

---

## Research

- [Fowler — maturity model](https://martinfowler.com/bliki/MaturityModel.html) (variation under change)
- DORA: loosely coupled architecture — [research note](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
review:
  status: unreviewed
  notes: "Architecture & change deep dive — boundaries, ADRs, change governance, Git truth."
---

# Architecture & Change — maturity deep dive

> **Audience:** Teams assessing system boundaries, evolution, and **who may change production how**.
>
> **Purpose:** Separate structural coherence from [documentation](documentation-and-knowledge.md) — and link fleet Git-truth patterns.

**Related:** [Source control](source-control.md) · [Deployment](deployment-and-release.md) · [Documentation](documentation-and-knowledge.md)

---

## What this axis answers

*Is the system evolvable — and are changes governed without surprise?*

---

## Levels

| Level | Posture |
|---|---|
| **1** | Ad hoc structure; breaking changes surprise consumers |
| **2** | Informal boundaries; occasional design notes |
| **3** | ADRs or equivalent; interfaces documented; deprecation notices |
| **4** | Change governance (approvers, windows); compatibility policy |
| **5** | Technical debt visible in roadmap; measured coupling/change failure rate |

**Documentation overlap:** ADRs live in [documentation & knowledge](documentation-and-knowledge.md) — this axis asks whether **decisions constrain future change**, not whether PDFs exist.

---

## Fleet / GitOps architecture signals

From [Framework GUIDELINES](../../../devops/argo/examples/framework/GUIDELINES.md):

- **Git is the only source of truth** — no imperative side channels  
- **Hub-and-spoke** — central decisions, spoke receives rendered intent  
- **Cascading values with cluster sovereignty** — fleet defaults + per-cluster override  

These are **architecture & change** choices that enable [deployment](deployment-and-release.md) level 4+.

Additional: [architecture-opinions.md](../../../devops/argo/examples/helm-component-pattern/docs/architecture-opinions.md), [greenfield-fleet-architecture.md](../../../devops/rhacm/notes/greenfield-fleet-architecture.md)

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| `oc edit` hotfix without Git follow-up | Reconciler reverts or drift hides |
| Shared library without versioning | Silent breaks |
| "Strangler" without boundary map | Two systems, one confusion |
| ADRs written after merge | Theater |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

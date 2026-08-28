---
review:
  status: unreviewed
  notes: "Monitoring v2 — deck lineage, DORA MTTR, SLO primer linked."
---

# Monitoring & Reliability — maturity deep dive

> **Audience:** Teams moving from "we find out when users complain" toward SLOs, runbooks, and proactive reliability work.
>
> **Purpose:** Merged observability + incident response. Level 5 **aspirational**. DORA **MTTR** alignment.

**Related:** [Platform accelerator](platform-as-accelerator.md) · [Team practices](team-practices.md) · [Deployment](deployment-and-release.md) · [slo-and-runbooks.md](../../../devops/slo-and-runbooks.md) · [DORA / AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md)

---

## What this axis answers

*Do we know when the system is unhealthy before customers — and do we learn from failure without repeating it?*

Dashboards without runbooks are level 2–3; runbooks without learning loops stall at level 3.

---

## Levels

| Level | Posture |
|---|---|
| **0** | No logging; prod fires only |
| **1** | Reactive firefighting; no proactive checks |
| **2** | Logging; manual dashboard checks |
| **3** | Automated alerts; runbooks; on-call rotation |
| **4** | SLOs/error budgets; traceability to root cause; standardized logs |
| **5** | *(Aspirational)* FMEA, chaos experiments, error-budget-driven prioritization |

**Deck lineage:**

| Deck tier | Level |
|---|---|
| None; ad-hoc — fight fires | **1** |
| Basic logging; manual monitoring | **2** |
| Automated monitoring; triggered support | **3** |
| Advanced logging; traceability to root cause | **4** |
| FMEA techniques | **5** |

**Honest assessment:** many teams live at **3–4**. Level 5 is direction, not gatekeeping.

---

## DORA / MTTR

**Time to restore service** (DORA four keys) maps to **L3–5** here — runbooks, SLOs, postmortems, rollback. Faster [deployment](deployment-and-release.md) without monitoring raises **change failure rate** visibility lag. See [research note — monitoring](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md).

---

## Platform accelerator

| Platform gives | You still need |
|---|---|
| Prometheus/Grafana operators | SLOs, alert routing, runbooks |
| Liveness/readiness probes | Correct probe design |
| Centralized logging | Structured logs, correlation IDs |

See [platform accelerator](platform-as-accelerator.md).

---

## Incident response (levels 3–5)

| Signal | Level |
|---|---|
| Incidents ad hoc | 1–2 |
| Runbook for top failures | 3 |
| Blameless postmortem used | 3–4 |
| Postmortem actions tracked | 4 |
| FMEA / chaos with safety gates | 5 |

Connects to [team practices](team-practices.md).

---

## Example evidence for this workspace

> Illustrates practices on this axis using paths in Field Notes. **Not a maturity score** for this workspace or your team. See [navigation vs benchmark](../maturity-as-navigation-not-benchmark.md) and [artifact map](../../../research/software-systems-maturity/findings/artifact-map.md).


| Type | Path |
|---|---|
| SLI/SLO/runbook primer | [slo-and-runbooks.md](../../../devops/slo-and-runbooks.md) |
| Symptom → fix narratives | [ocp/troubleshooting/](../../../devops/ocp/troubleshooting/) · [SYMPTOM-INDEX.md](../../../devops/SYMPTOM-INDEX.md) |
| RHACM observability issues | [rhacm/troubleshooting/](../../../devops/rhacm/troubleshooting/) |
| Fleet ops context | [greenfield-fleet-architecture.md](../../../devops/rhacm/notes/greenfield-fleet-architecture.md) |
| **Optional gap** | SLO YAML / error-budget alert examples |

---

## AI era

Agents don't replace on-call. **Alert fatigue** worsens if agent-driven deploys increase change rate without SLOs. Structured logs help humans **and** agents debug — unstructured prod logs stay L2.

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| Alerts always firing | Alert fatigue |
| Dashboards nobody owns | No operational contract |
| Logs without structure | Expensive root cause |
| No deploy ↔ release correlation | Can't tie regression to change |
| Chaos without safety gates | Activity without maturity |

---

## Teaching note

**Production is too late** for basic failure modes — aligns with [testing sandbox](testing-and-verification.md) and [deployment](deployment-and-release.md).

---

## External references

- [Google SRE — SLOs](https://sre.google/sre-book/service-level-objectives/)
- [Google SRE — postmortem culture](https://sre.google/sre-book/postmortem-culture/)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

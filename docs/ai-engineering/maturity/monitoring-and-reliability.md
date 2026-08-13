---
review:
  status: unreviewed
  notes: "Monitoring & reliability deep dive — observability, SLOs, incident learning; L5 aspirational."
---

# Monitoring & Reliability — maturity deep dive

> **Audience:** Teams moving from "we find out when users complain" toward SLOs, runbooks, and proactive reliability work.
>
> **Purpose:** Expand [Monitoring & reliability](../software-systems-maturity.md#monitoring--reliability) — merged observability and incident response. Level 5 labeled **aspirational**.

**Related:** [Platform accelerator](platform-as-accelerator.md) · [Team practices](team-practices.md) · [Deployment](deployment-and-release.md)

---

## What this axis answers

*Do we know when the system is unhealthy before customers — and do we learn from failure without repeating it?*

This axis merges what some models split as "monitoring" and "reliability engineering." Dashboards without runbooks are level 2–3; runbooks without learning loops stall at level 3.

---

## Levels

| Level | Posture |
|---|---|
| **1** | Reactive firefighting; no proactive checks |
| **2** | Logging; manual dashboard checks |
| **3** | Automated alerts; runbooks; on-call rotation |
| **4** | SLOs/error budgets; traceability to root cause; standardized logs |
| **5** | *(Aspirational)* FMEA, chaos experiments, error-budget-driven prioritization |

**Honest assessment:** many production teams live at **3–4**. Level 5 is a direction, not a gate for "real engineers."

---

## Platform accelerator

Kubernetes/OpenShift often ships **with** metrics/logging stacks available — similar to deployment maturity trap:

| Platform gives | You still need |
|---|---|
| Prometheus/Grafana operators | SLOs, alert routing, runbooks |
| Liveness/readiness probes | Correct probe design |
| Centralized logging | Structured logs, correlation IDs |

See [platform accelerator](platform-as-accelerator.md).

---

## Incident response (embedded in levels 3–5)

| Maturity signal | Level |
|---|---|
| Incidents handled ad hoc | 1–2 |
| Runbook exists for top failures | 3 |
| Blameless postmortem template used | 3–4 |
| Postmortem actions tracked to completion | 4 |
| Failure modes proactively hunted (FMEA/chaos) | 5 |

Connects to [team practices](team-practices.md) — retros that change behavior.

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| Alerts that always fire | Alert fatigue → level 2 theater |
| Dashboards nobody owns | No operational contract |
| Logs without structure | Root cause stays expensive |
| Monitoring without deployment traceability | Can't correlate release to regression |
| Chaos day without safety gates | Activity without maturity |

---

## Repo corpus (partial)

This workspace is **strong on troubleshooting narratives**, lighter on unified SLO guidance:

| Type | Path |
|---|---|
| Reactive investigation patterns | [devops/ocp/troubleshooting/](../../../devops/ocp/troubleshooting/) |
| RHACM observability issues | [rhacm/troubleshooting/](../../../devops/rhacm/troubleshooting/) |
| Fleet ops maturity notes | [greenfield-fleet-architecture.md](../../../devops/rhacm/notes/greenfield-fleet-architecture.md) |

**Gap:** central SLO/runbook maturity doc — candidate for future devops or deep-dive expansion.

---

## Teaching note — from 2016 deck

Monitoring maturity supports the deployment/testing story: **production is too late** to discover basic failure modes. Alerts and SLOs exist to **pull signal left** after you ship.

---

## External references

- [Google SRE Book — SLOs](https://sre.google/sre-book/service-level-objectives/)
- [Google SRE Book — postmortem culture](https://sre.google/sre-book/postmortem-culture/)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

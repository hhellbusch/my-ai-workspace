---
review:
  status: unreviewed
  notes: "Cross-cutting SLI/SLO and runbook primer — closes partial monitoring corpus gap."
---

# SLOs and runbooks — a practitioner primer

> **Audience:** Platform and application teams moving from reactive troubleshooting toward measurable reliability — especially after GitOps or operator adoption gives you metrics without giving you SLOs.
>
> **Purpose:** Minimum vocabulary and artifact bar for **level 3→4** on [Monitoring & reliability](../docs/ai-engineering/maturity/monitoring-and-reliability.md). Not a replacement for the [Google SRE book](https://sre.google/sre-book/service-level-objectives/).

**Related:** [Monitoring deep dive](../docs/ai-engineering/maturity/monitoring-and-reliability.md) · [Platform accelerator](../docs/ai-engineering/maturity/platform-as-accelerator.md) · [Symptom index](SYMPTOM-INDEX.md) · [OCP troubleshooting](ocp/troubleshooting/README.md)

---

## Vocabulary (short)

| Term | Meaning |
|---|---|
| **SLI** (indicator) | A measurable signal of user-visible quality — availability, latency, error rate, throughput |
| **SLO** (objective) | Target range for an SLI over a window — e.g. 99.9% successful requests / 30 days |
| **Error budget** | Allowed unreliability before the SLO is breached — `(1 − SLO) × window` |
| **Runbook** | Repeatable steps when an alert fires or a symptom appears — owner, verification, rollback |

Prometheus/Grafana (or an observability platform) provide **data**. SLOs provide **policy** — what "good enough" means and when to stop shipping features to fix reliability.

---

## Maturity bar (honest)

| Level | What you have |
|---|---|
| **2** | Logs and dashboards; humans notice problems |
| **3** | Alerts + runbooks for top failures; on-call rotation |
| **4** | SLOs with error budgets; alerts tied to SLO burn; postmortems with tracked actions |
| **5** | Proactive failure-mode work (FMEA, chaos with safety gates) — aspirational for most teams |

Dashboards without runbooks stall at **2–3**. Runbooks without SLOs can still be valuable — but you won't know when to prioritize reliability over features.

---

## Minimum viable runbook

One page per alert or top symptom. Include:

1. **Trigger** — alert name, threshold, or symptom string (link to [SYMPTOM-INDEX.md](SYMPTOM-INDEX.md) if applicable)
2. **Impact** — who cares, what's degraded
3. **Verify** — commands or dashboard panels that confirm the problem (not just the alert)
4. **Mitigate** — safe steps in order; note blast radius
5. **Escalate** — when to stop and page another team
6. **Owner** — team or rotation that keeps this current

This repo's troubleshooting guides are often **level 2–3 runbook seeds** — symptom → investigation → fix. Promoting one to level 3+ means: named owner, alert mapping, and a "last verified" date.

---

## Minimum viable SLO (one service)

Start with **one user-visible SLI**, not every metric:

1. Pick the SLI users feel (availability or latency are common starting points)
2. Set an SLO slightly below current measured performance — ambitious but achievable
3. Define the **measurement window** (30 days is common)
4. Wire **one alert** on error-budget burn rate, not on every threshold twitch
5. Document in the same place as the runbook — link bidirectionally

Avoid SLO theater: an SLO nobody reviews in planning meetings is level 2 with extra YAML.

---

## Platform note (Kubernetes / OpenShift)

Operators and monitoring stacks lower the **cost** of metrics and alerts. They do not choose your SLIs, write runbooks, or run postmortems. See [platform as maturity accelerator](../docs/ai-engineering/maturity/platform-as-accelerator.md).

| Platform often provides | You still own |
|---|---|
| Metrics scrape targets, dashboards | SLI selection, SLO targets, error budgets |
| Alertmanager routing | Alert ↔ runbook mapping, on-call policy |
| Liveness/readiness probes | Probe design that reflects real dependencies |

---

## Corpus in this workspace

| Evidence type | Where |
|---|---|
| Symptom → fix narratives (runbook seeds) | [ocp/troubleshooting/](ocp/troubleshooting/) · [rhacm/troubleshooting/](rhacm/troubleshooting/) |
| Fleet ops context | [rhacm/notes/greenfield-fleet-architecture.md](rhacm/notes/greenfield-fleet-architecture.md) |
| Maturity levels and anti-patterns | [Monitoring deep dive](../docs/ai-engineering/maturity/monitoring-and-reliability.md) |
| Self-assessment | [Maturity worksheet](../docs/ai-engineering/maturity/worksheet.md) |

**Still thin here:** worked examples of SLO YAML, error-budget alert rules, or postmortem templates in-repo — add when a real fleet service documents one.

---

## External references

- [Google SRE Book — Service Level Objectives](https://sre.google/sre-book/service-level-objectives/)
- [Google SRE Book — Postmortem culture](https://sre.google/sre-book/postmortem-culture/)
- [Monitoring deep dive — levels](../docs/ai-engineering/maturity/monitoring-and-reliability.md#levels)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

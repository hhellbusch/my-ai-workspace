# 2026 resurrection notes — Software Systems Maturity

**Source:** [deck-text-export.txt](../sources/deck-text-export.txt) (text export, Aug 2026)

---

## What survived well from 2016

- **Trailhead framing** — assess current level, prioritize the *next* level up ([Fowler mixologist](https://martinfowler.com/bliki/MaturityModel.html)).
- **Multi-axis model** — maturity is not one number; teams can be level 4 on builds and level 1 on monitoring.
- **Practitioner tone** — XKCD, Boy Scout Rule, tradable quality hypothesis — keeps the model grounded.
- **CMM skepticism** — document-heavy, certification ≠ competence; aligns with agile values.

---

## 2026 additions already in the deck export

- Slide 17: expand from "software development" → **software systems** (infra, platform, AI agents).
- Slide 32 level 4: **"manual and clanker driven"** code reviews — first explicit AI axis hook.

---

## Proposed new axes (draft — not in original deck)

| Axis | Why now |
|---|---|
| **Platform / fleet** | ACM, GitOps, multi-cluster — org capability separate from app CI/CD |
| **GitOps & declarative ops** | Desired state in Git, reconcile loops, drift detection |
| **AI agents & harnesses** | Non-deterministic automation, review gates, artifact discipline |
| **Observability → action** | Metrics/logs/traces tied to runbooks and SLOs (extends Monitoring) |

Each should get the same **5-level ladder** treatment as the original nine axes.

---

## Domain-specific ladders (pattern)

The cross-DC Kafka work produced a **GitOps maturity ladder** (levels 0–5) for cluster links only — an example of nesting a narrow ladder under a broader axis (Deployment / Platform). See [CLUSTER-LINK-GITOPS.md](../../../devops/ocp/examples/messaging/kafka/CLUSTER-LINK-GITOPS.md).

---

## Deep dives still owed (per original intent)

One document per axis, suitable for organizational publication where appropriate:

1. Source control
2. Code quality
3. Testing
4. Builds
5. Deployment
6. Data management
7. Security
8. Documentation
9. Monitoring
10. (new) Platform / fleet
11. (new) AI agents

---

## Ingestion format note

This export worked well: slide numbers + body text + URLs preserved.
PDF would help recover diagram-only slides (CMM level charts, deployment pipeline figures).
Optional: export speaker notes into a second `.txt` if they differ from on-slide text.

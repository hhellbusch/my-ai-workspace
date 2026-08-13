---
review:
  status: unreviewed
  notes: "Self-assessment worksheet — not certification; links to trailhead and deep dives."
---

# Maturity assessment worksheet

> **Audience:** Team leads, architects, and peers doing an honest capability review — per service or team, not one org score.
>
> **Purpose:** Capture current level, next target, and **your** evidence — links to **your** runbooks, pipelines, and repos. Paths in Field Notes are [example evidence](../maturity-as-navigation-not-benchmark.md) only; they do not score this workspace.

**Related:** [Trailhead](../software-systems-maturity.md) · [Deep dives](README.md) · [Artifact map](../../../research/software-systems-maturity/findings/artifact-map.md) · [Navigation vs benchmark](../maturity-as-navigation-not-benchmark.md) · [Platform accelerator](platform-as-accelerator.md) (mechanism vs team maturity)

---

## Before you start

1. **Scope one unit** — a team, a service, or a fleet slice — not the whole company.
2. **Per axis, not one number** — skew is normal (e.g. L4 deployment with L2 monitoring).
3. **Platform ≠ team** — Kubernetes/OpenShift may provide L4 *mechanisms* while the team is still L2 on practices.
4. **Your evidence, not claims** — link **your** runbooks, pipelines, and repos; avoid rounding up. Field Notes paths illustrate rubric language; they are not your assessment.
5. **Security — two tracks** — score **application security** and **secrets & IAM** separately (same deep dive, two numbers).
6. **Product discovery** — mark **N/A** for pure platform/infra teams if appropriate.

Copy the table below into `.planning/<project>/` or a team wiki. Disagreement about level is often the valuable output.

---

## Assessment table

| Axis | Deep dive | Current (0–5) | Next target | Evidence (your links) | Notes |
|---|---|:---:|:---:|---|---|
| Source control | [source-control.md](source-control.md) | | | | |
| Code quality | [code-quality.md](code-quality.md) | | | | |
| Testing & verification | [testing-and-verification.md](testing-and-verification.md) | | | | |
| Architecture & change | [architecture-and-change.md](architecture-and-change.md) | | | | |
| Builds & artifacts | [builds-and-artifacts.md](builds-and-artifacts.md) | | | | |
| Deployment & release | [deployment-and-release.md](deployment-and-release.md) | | | | |
| Data management | [data-management.md](data-management.md) | | | | |
| Monitoring & reliability | [monitoring-and-reliability.md](monitoring-and-reliability.md) | | | | |
| Security — application | [security-and-secrets.md](security-and-secrets.md) | | | | |
| Security — secrets & IAM | [security-and-secrets.md](security-and-secrets.md) | | | | |
| Documentation & knowledge | [documentation-and-knowledge.md](documentation-and-knowledge.md) | | | | |
| Platform & fleet | [platform-as-accelerator.md](platform-as-accelerator.md) | | | | |
| AI agents & harnesses | [ai-agents-and-harnesses.md](ai-agents-and-harnesses.md) | | | | |
| Team practices | [team-practices.md](team-practices.md) | | | | |
| Product discovery *(opt)* | [product-discovery.md](product-discovery.md) | N/A | | | |

---

## Prioritization (after filling)

1. Which axis **hurts most** if it fails this quarter?
2. Which gap is **cheapest to close one level**?
3. Which [example evidence](../maturity-as-navigation-not-benchmark.md) in the artifact map can you reuse as a **pattern** (not as proof you are level N)?

For fleet/GitOps work, also read [fleet-management ideas](../../../devops/fleet-management-ideas.md) — executive labels vs architect labels on the same barometers.

---

## Field Notes example evidence (reference only)

| Corpus richness | Axes | Where to look |
|---|---|---|
| **Rich** | Deployment, platform, documentation, AI agents, team | `devops/argo/`, `devops/rhacm/`, `docs/ai-engineering/`, skills |
| **Partial** | Security, monitoring, architecture, builds, source control | `devops/vault/`, `devops/ocp/troubleshooting/`, fleet notes |
| **Thin** | Code quality, data, product discovery | Deep dives + external canon |

These paths **illustrate** rubric language for this workspace — they do **not** certify Field Notes or your team. When this assessment drives backlog work, tag items in `BACKLOG.md` with axis and gap (e.g. `deployment 3→4`).

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

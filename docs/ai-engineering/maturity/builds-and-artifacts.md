---
review:
  status: unreviewed
  notes: "Builds & artifacts deep dive — reproducible artifacts, registry, provenance at L4–5."
---

# Builds & Artifacts — maturity deep dive

> **Audience:** Teams assessing whether code becomes **reproducible, shareable artifacts** — not just compiled on a laptop.
>
> **Purpose:** Connect builds to [deployment](deployment-and-release.md) and supply-chain maturity at upper levels.

**Related:** [Joel Test appendix](joel-test-appendix.md) · [Security — supply chain](security-and-secrets.md) · [Trailhead](../software-systems-maturity.md#builds--artifacts)

---

## What this axis answers

*Can anyone produce the same artifact from the same commit — and promote *that* artifact through environments?*

[12-factor — one codebase, many deploys](https://12factor.net/codebase): build once, deploy many times.

---

## Levels

| Level | Posture |
|---|---|
| **1** | Manual builds on developer machines |
| **2** | Scripts; partially reproducible |
| **3** | CI produces artifacts on every change |
| **4** | Immutable registry; tagged promotions |
| **5** | Every main commit deployable; broken build stops the line; SBOM/provenance on critical paths |

**Joel Test** items 2–3 map here: one-step build, daily (continuous) builds — see [appendix](joel-test-appendix.md).

**Supply chain (L4–5):** signed images, SBOM, dependency pinning — extends into [Security](security-and-secrets.md), not a separate axis.

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| "Works on my machine" artifact | Not reproducible |
| Rebuild per environment | Config drift in artifact |
| Floating `:latest` in prod | Rollback impossible |
| CI green but artifact not stored | Can't promote what you can't find |

---

## Repo examples

| Topic | Path |
|---|---|
| GitHub Actions workflows | [argo/examples/github-workflows/](../../../devops/argo/examples/github-workflows/README.md) |
| Operator chart CI / upgrade chains | [operators-installer/](../../../devops/argo/examples/examples/operators-installer/README.md) |
| Helm component pattern | [helm-component-pattern/](../../../devops/argo/examples/helm-component-pattern/README.md) |

---

## External references

- [12-factor — build, release, run](https://12factor.net/build-release-run)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

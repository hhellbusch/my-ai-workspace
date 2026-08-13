---
review:
  status: unreviewed
  notes: "Builds & artifacts v2 — axis iteration; DORA CI mapping, deck lineage, GitOps render pipeline."
---

# Builds & Artifacts — maturity deep dive

> **Audience:** Teams assessing whether code and config become **reproducible, shareable artifacts** — container images, charts, rendered manifests, pinned operator versions — not just output on a laptop.
>
> **Purpose:** Connect builds to [deployment](deployment-and-release.md), Joel Test items 2–3, DORA continuous integration, and supply-chain maturity at upper levels (with [Security](security-and-secrets.md)).

**Related:** [Joel Test appendix](joel-test-appendix.md) · [Deployment & release](deployment-and-release.md) · [DORA / AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md) · [Trailhead](../software-systems-maturity.md#builds--artifacts)

---

## What this axis answers

*Can anyone produce the same artifact from the same commit — and promote **that** artifact through environments?*

[12-factor — build, release, run](https://12factor.net/build-release-run): **strict separation** — build stage produces immutable release; run stage executes it. Config that varies per environment belongs in the release/config layer, not a rebuild per env.

In **GitOps/platform** work, "artifact" is not only a container image:

| Artifact type | Example in this corpus |
|---|---|
| Container image | App workloads (standard CI → registry) |
| Helm chart version | Pinned chart + values in Git |
| Rendered manifests | `hub/rendered/` from CI ([framework hub-bootstrap](../../../devops/argo/examples/framework/README.md)) |
| Pinned operator CSV | [operators-installer](../../../devops/argo/examples/examples/operators-installer/README.md) `csv:` in Git |

---

## Levels

| Level | Posture |
|---|---|
| **0** | No build step; compile or bundle on target hosts |
| **1** | Manual builds on developer machines |
| **2** | Scripts; partially reproducible |
| **3** | CI produces artifacts (or rendered output) on every change |
| **4** | Immutable registry or committed render output; tagged promotions |
| **5** | Every main commit deployable; broken build stops the line; SBOM/provenance on critical paths |

**DORA/Accelerate alignment:** **Continuous integration** is a core capability in *Accelerate* — maps to **L3+** (automated build/test on every change). CI alone without stored immutable artifacts is L3 prep, not L4. See [DORA research note — builds axis](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md#builds-axis-dora-links).

**Joel Test** items 2–3: [one-step build, daily builds](joel-test-appendix.md) — binary checklist items; here they imply **L2–3 minimum**, L5 culture for "fix broken build before new work."

**Supply chain (L4–5):** signed images, SBOM, dependency pinning — extends into [Security](security-and-secrets.md), not a separate axis (per trailhead merge decision).

---

## Deck lineage (2016 → 2026)

| 2016 deck tier | 2026 level | Notes |
|---|---|---|
| Builds manual and ad-hoc | **1** | "Works on my machine" |
| Automation scripts | **2** | Partial reproducibility |
| Integrated automation (CI/CD) | **3** | Deck merged build + CD; we split **build** (this axis) from **deploy** ([deployment](deployment-and-release.md)) |
| Artifact management | **4** | Registry, immutable tags, shared render output |
| Every build deployable | **5** | Broken build stops the line — team discipline + pipeline gate |

Deck cited [12-factor release](https://12factor.net/build-release-run) imagery — still the conceptual backbone.

---

## Evidence in this workspace

| Level | What it looks like | Repo paths |
|---|---|---|
| **3** | CI on PR — lint, template, validate | [github-workflows/](../../../devops/argo/examples/github-workflows/README.md) · [validate-pr.yaml](../../../devops/argo/examples/framework/pipelines/github-actions/) (framework) |
| **3–4** | Rendered hub Applications committed by CI | [framework README — hub-bootstrap](../../../devops/argo/examples/framework/README.md) · [architecture-opinions](../../../devops/argo/examples/helm-component-pattern/docs/architecture-opinions.md) |
| **4** | Promotion gates per branch — CI + diff + approvals | [framework promotion table](../../../devops/argo/examples/framework/README.md) · [promotion/](../../../devops/argo/examples/framework/pipelines/promotion/) |
| **4** | Pinned operator CSV as immutable intent | [operators-installer/](../../../devops/argo/examples/examples/operators-installer/README.md) |
| **4** | Helm component lint in CI | [lint-array-safety.sh](../../../devops/argo/examples/framework/scripts/lint-array-safety.sh) |
| **4** | Repo-wide pre-commit on docs/devops | Root `pre-commit` · [source control L4 hooks](source-control.md) |
| **5** | Upgrade chains, broken-build narrative | operators-installer `upgradeChain`; deck "every build deployable" |
| **Thin** | Container image SBOM/signing in-repo | See [Security](security-and-secrets.md); OCP image signature troubleshooting exists |

**GitOps split:** in fleet repos, **build** often means `helm template` + validation + commit render output — **deploy** is Argo reconcile of that output ([deployment deep dive](deployment-and-release.md)).

---

## Build vs deploy (avoid conflating axes)

| Question | Axis |
|---|---|
| Does CI produce a storable, reproducible output from a commit? | **Builds** (this doc) |
| Does that output reach prod through a governed path? | [Deployment](deployment-and-release.md) |
| Does CI run tests? | [Testing](testing-and-verification.md) — build pipeline *hosts* tests |

Pipeline at deployment L2 ("CI builds, human deploys") is **build L3 + deploy L2** skew — common and worth naming in assessment.

---

## AI era

| Observation | Builds implication |
|---|---|
| Agents generate source faster | **L3 CI** must run on agent-authored PRs — same bar as human commits |
| Skipping CI "because the agent tested locally" | L1 behavior — no shared artifact |
| Dependency churn from generated code | L5 SBOM/provenance on critical paths ([Security](security-and-secrets.md)) |
| Rendered manifest repos | CI must stay green when agents edit values — broken template blocks fleet |

**DORA:** faster commits without CI automation do not improve **lead time** end-to-end — they increase WIP and broken-main risk (Joel item 3 culture at L5).

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| "Works on my machine" artifact | Not reproducible |
| Rebuild per environment | Violates 12-factor release separation |
| Floating `:latest` in prod | Rollback impossible |
| CI green but artifact not stored | Can't promote what you can't find |
| GitOps without CI render/lint | Broken YAML reaches reconcile — [deployment](deployment-and-release.md) L4 with **build L2** skew |
| Agent merge without one-step build | Joel #2 failure — team may not notice until prod |

---

## Cross-axis dependencies

```text
Source control ──triggers────▶ Builds (CI on change — L4 hooks)
Builds ──produces─────────────▶ Deployment (artifacts to promote)
Testing ──runs inside────────▶ Builds (pipeline stages)
Security ──extends L4–5─────▶ Builds (sign, SBOM, pin)
Deployment ──consumes────────▶ Builds (GitOps pulls render/image ref)
AI agents ──increases────────▶ Builds (CI volume and dependency risk)
```

---

## Teaching note — from 2016 deck

*"Construction of something observable and tangible"* — converting source into an artifact others can consume. For platform teams, the artifact is often **committed rendered state** or **pinned version pins**, not only a binary in a registry.

**Every build deployable** (deck L5) is a **team norm**: broken main is everyone's problem — connects to [team practices](team-practices.md), not only tooling.

---

## Research and external validation

| Source | What it supports | Limit |
|---|---|---|
| [12-factor — build, release, run](https://12factor.net/build-release-run) | Separation of stages — L3–4 | Apps-first; adapt for GitOps render |
| [DORA / Accelerate — CI](https://dora.dev/) | CI capability ↔ performance | Not artifact-format-specific |
| [Fowler — Continuous Integration](https://martinfowler.com/articles/continuousIntegration.html) | Integrate often, fix breaks fast | Culture + mechanics |
| Workspace | [Deployment v2](deployment-and-release.md) · [DORA note](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md) | |

---

## Repo examples (index)

| Topic | Path |
|---|---|
| GitHub Actions workflows | [github-workflows/](../../../devops/argo/examples/github-workflows/README.md) |
| Framework CI + promotion | [framework/pipelines/](../../../devops/argo/examples/framework/pipelines/) |
| Operator chart / CSV pins | [operators-installer/](../../../devops/argo/examples/examples/operators-installer/README.md) |
| Helm component pattern | [helm-component-pattern/](../../../devops/argo/examples/helm-component-pattern/README.md) |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

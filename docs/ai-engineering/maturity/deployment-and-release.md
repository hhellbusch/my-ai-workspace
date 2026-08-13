---
review:
  status: unreviewed
  notes: "Deployment & release v2 — axis iteration; DORA mapping, deck lineage, fleet/AI corpus."
---

# Deployment & Release — maturity deep dive

> **Audience:** Platform and application teams assessing how code and config reach production — Kubernetes/OpenShift, VMs, API-managed platforms, and **multi-cluster fleets**.
>
> **Purpose:** Expand the [trailhead](../software-systems-maturity.md) deployment axis with levels, deck lineage, DORA alignment, anti-patterns, and **workspace examples** from GitOps practice.

**Related:** [Trailhead — DevOps/GitOps](../software-systems-maturity.md#devops-gitops-and-api-reconcile) · [Source control](source-control.md) · [Platform accelerator](platform-as-accelerator.md) · [DORA / AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md) · [Argo CD reference](../../../devops/argo/README.md)

---

## What this axis answers

*How predictably, safely, and audibly do we move intended state into production — and know when production drifted?*

Deployment maturity is **not** the same as having a CI job. It includes **release governance** (who can change prod), **environment parity**, and **convergence** (desired state actually applied).

The 2016 deck asked: *how does code travel from a developer's machine to production — minimizing risk and variation?* That question applies equally to **cluster config, fleet policy, and platform operators** — not only application binaries.

---

## DevOps → GitOps → API reconcile

```text
DevOps       Cultural: break silos, own production, automate feedback
CI/CD        Mechanical: build → test → promote through environments
GitOps       Declarative: Git is desired state; reconcile + drift detection
API reconcile Same principles when apply path is REST/CLI/Job, not a CR
```

**Misread to avoid:** "We use Git" = GitOps. Git without automated **converge** is [source control](source-control.md) maturity, not deployment maturity.

**Prerequisite:** [Source control L3+](source-control.md) (protected main, PR review) before GitOps at L4 is meaningful — otherwise Git is a remote exec channel.

---

## Levels

| Level | Posture | Typical evidence |
|---|---|---|
| **0** | Snowflake servers; manual prod edits | No reproducible deploy record |
| **1** | Scripts checked in; human runs each env | Runbooks; SSH/Ansible ad hoc |
| **2** | CI builds/tests; deploy manual or partial | Pipeline to artifact only; human promote |
| **3** | Declarative desired state in Git; gated apply | Manifests/Helm in repo; manual `apply` or approved pipeline |
| **4** | Automated reconcile | Argo CD, Flux, operator, Terraform Cloud, idempotent API Job |
| **5** | Drift visible and managed | Diff alerts, self-heal policy, scheduled `--check-only` reconcile |

**DORA/Accelerate alignment:** **Continuous delivery/deployment** and **deployment frequency** (a DORA four-key metric) correlate with capabilities at **L3–5** here — declarative promotion, automated reconcile, safe rollback paths. **Change failure rate** and **MTTR** depend on this axis *plus* [testing](testing-and-verification.md) and [monitoring](monitoring-and-reliability.md). See [DORA research note](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md#deployment-axis-dora-links).

---

## Deck lineage (2016 → 2026)

| 2016 deck tier | 2026 level | What changed |
|---|---|---|
| Manual; ad-hoc ("snowflake servers") | **0** | Unchanged framing |
| Automated scripts, **manually executed** per server | **1** | Scripts in Git optional at L1 |
| Standardized & integrated (CI/CD); blue/green; Dev/Test/Prod | **2–3** | Split: CI-only = L2; declarative Git + gated promote = L3 |
| Zero-touch CD — prod updated frequently, safely | **4–5** | Maps to **reconcile + drift** — GitOps is one implementation |

The deck did not name **GitOps** or **fleet reconcile**; zero-touch CD in 2016 often meant pipeline-to-prod. In 2026, **continuous reconcile** (Argo CD, operators) is the fleet-native expression of L4–5.

---

## Evidence in this workspace

| Level | What it looks like | Repo paths |
|---|---|---|
| **0–1** | Ad hoc apply; runbook-driven | Contrasted in anti-patterns below |
| **2** | CI to build/test; GitHub Actions on PR | [github-workflows/](../../../devops/argo/examples/github-workflows/) |
| **3** | Declarative manifests; PR before merge; manual or gated sync | [PR-WORKFLOW-GUIDE.md](../../../devops/argo/examples/docs/workflows/PR-WORKFLOW-GUIDE.md) · [helm-component-pattern](../../../devops/argo/examples/helm-component-pattern/) |
| **4** | App-of-apps, multi-cluster, promotion pipelines | [APP-OF-APPS-PATTERN.md](../../../devops/argo/examples/docs/patterns/APP-OF-APPS-PATTERN.md) · [multi-cluster-deployment.md](../../../devops/argo/examples/docs/deployment/multi-cluster-deployment.md) · [promotion/](../../../devops/argo/examples/framework/pipelines/promotion/) |
| **4** | Trunk-based fleet — `main` → RollingSync | [ADOPTING-TRUNK-BASED.md](../../../devops/argo/examples/framework/docs/ADOPTING-TRUNK-BASED.md) |
| **4–5** | RHACM policy + Argo-generated resources | [ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md](../../../devops/argo/examples/docs/patterns/ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md) |
| **4–5** | Hub policy in Git (same PR flow as apps) | [git-driven-configuration.md](../../../devops/rhacm/git-driven-configuration.md) |
| **5** | Diff visibility, PR preview, drift semantics | [diffing-and-visibility.md](../../../devops/argo/examples/helm-component-pattern/docs/diffing-and-visibility.md) · [argocd-diff-preview](../../../library/argocd-diff-preview.md) |
| **Design** | RHACM vs Argo authority (not L4 alone) | [fleet-control-spectrum.md](../../../devops/fleet-control-spectrum.md) |
| **Pedagogy** | Hands-on sync and GitOps labs | [argo/labs/](../../../devops/argo/labs/README.md) |

**Framework invariants:** [GUIDELINES — Git is the only source of truth](../../../devops/argo/examples/framework/GUIDELINES.md) — imperative hotfixes overwritten by reconcile are a **source control + deployment** failure.

---

## Fleet and platform deployment

Multi-cluster work adds **promotion** and **authority** on top of single-cluster GitOps:

| Concern | Where this corpus goes deeper |
|---|---|
| Who reconciles what (Argo vs RHACM) | [fleet-control-spectrum.md](../../../devops/fleet-control-spectrum.md) |
| Greenfield hub + GitOps default stack | [greenfield-fleet-architecture.md](../../../devops/rhacm/notes/greenfield-fleet-architecture.md) |
| Operator upgrade chains (OLM GitOps) | [operators-installer](../../../devops/argo/examples/examples/operators-installer/) |
| Namespace guardrails via Git | [namespace-guardrails](../../../devops/ocp/guides/namespace-guardrails/) |

**Platform accelerator trap:** OpenShift + GitOps operators provide L4 **mechanisms** while the team is still L2 on promotion discipline — see [platform accelerator](platform-as-accelerator.md).

---

## API reconcile (without a Kubernetes CR)

Levels **3–5** still apply when the apply target is admin REST, CLI, or a batch Job:

```text
desired spec in Git → PR review → idempotent reconcile script/Job → fail on drift
```

Same governance as manifests; different executor. Useful for legacy platforms, SaaS admin APIs, and fleet scripts that are not CR-shaped. Pattern appears in RHACM/AAP integration notes and OCM subscription automation — declarative intent in Git even when apply is not `kubectl`.

---

## Non-Kubernetes

Levels still apply: desired config in Git, Ansible/Terraform/Puppet converge, drift via scheduled plan/diff. The **shape** is identical; reconciler differs. [Ansible](../../../devops/ansible/) examples in this repo skew toward automation patterns rather than full CD — deployment axis may stay L2–3 until converge is automated.

---

## AI era

| Observation | Deployment implication |
|---|---|
| Agents generate manifests and config faster | **L3 review gates** (PR, diff preview) become the bottleneck — invest there before more generation |
| Desired-state diffs on PR | [argocd-diff-preview](../../../library/argocd-diff-preview.md) — desired vs desired, not live cluster noise |
| Agent applies directly to cluster | Bypasses GitOps — L0–1 behavior even if code was "AI-written" |
| Higher deployment frequency without test/monitor maturity | DORA **change failure rate** rises — AI amplifies existing gaps |

**Hypothesis (validate in practice):** AI improves *local* lead time (typing, scaffolding) more easily than *organizational* lead time (review, promote, reconcile, observe). Measure DORA four keys on a real pipeline before attributing gains to agents.

---

## Anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| "Deploy Friday" manual kubectl | No audit trail; hero-dependent |
| Config only in UI (SaaS admin, control plane) | Failover reproduction impossible |
| GitOps without review | Git as remote exec, not governance |
| Mixing manual prod hotfix with GitOps self-heal | Fighting the reconciler — [GUIDELINES](../../../devops/argo/examples/framework/GUIDELINES.md) |
| Same branch, divergent cluster hand-edits | Git lies about prod |
| GitOps on apps, tribal knowledge for hub policy | Split maturity — hub belongs in Git too ([RHACM git-driven](../../../devops/rhacm/git-driven-configuration.md)) |
| Optimizing deploy frequency without rollback/test | DORA change failure rate — see [testing](testing-and-verification.md) |

---

## Cross-axis dependencies

```text
Source control ──prerequisite──▶ Deployment (L3+ before L4 GitOps)
Builds ──feeds──────────────────▶ Deployment (artifacts to promote)
Testing ──gates─────────────────▶ Deployment (safe promotion)
Monitoring ──closes loop────────▶ Deployment (change failure → detect)
Security ──constrains───────────▶ Deployment (signing, policy, secrets)
Platform ──accelerates──────────▶ Deployment (operators, GitOps hooks)
Documentation ──enables─────────▶ Deployment (runbooks, promotion docs)
AI agents ──throughput──────────▶ Deployment (review/diff become critical path)
```

---

## Teaching note — sandbox shift (from 2016 deck)

Push discovery left: bugs found in **production** are **too late**. Deployment maturity connects to [testing](../software-systems-maturity.md#testing--verification) — environments should exist **before** prod, with promotion increasing fidelity.

Deck also cited **12-factor** release discipline (one codebase, explicit releases) — still compatible with L2+ pipeline thinking.

---

## Research and external validation

| Source | What it supports | Limit |
|---|---|---|
| [Fowler — Continuous Delivery](https://martinfowler.com/bliki/ContinuousDelivery.html) | Pipeline, release discipline — L2–4 | Pre-GitOps vocabulary |
| [Fowler — Deployment pipeline](https://martinfowler.com/bliki/DeploymentPipeline.html) | Stage promotion | |
| [Fowler — Blue-green](https://martinfowler.com/bliki/BlueGreenDeployment.html) | Safe cutover — deck L3 tier | One tactic, not full model |
| [DORA / Accelerate](https://dora.dev/) | Deployment frequency, CD capability ↔ performance | Outcome metrics; fleet measurement nuance |
| [OpenGitOps principles](https://opengitops.dev/) | Declarative, reconciled, auditable | Kubernetes-centric framing |
| Workspace | [DORA + AI research note](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md) | Working note |

---

## Level 4 pattern index (quick reference)

| Pattern | Where |
|---|---|
| App-of-apps, multi-env | [APP-OF-APPS-PATTERN.md](../../../devops/argo/examples/docs/patterns/APP-OF-APPS-PATTERN.md) |
| Multi-cluster delivery | [multi-cluster-deployment.md](../../../devops/argo/examples/docs/deployment/multi-cluster-deployment.md) |
| Promotion pipelines | [framework/pipelines/promotion/](../../../devops/argo/examples/framework/pipelines/promotion/) |
| PR / diff workflow | [PR-WORKFLOW-GUIDE.md](../../../devops/argo/examples/docs/workflows/PR-WORKFLOW-GUIDE.md) |
| Policy + generated resources | [ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md](../../../devops/argo/examples/docs/patterns/ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md) |
| Hands-on labs | [argo/labs/](../../../devops/argo/labs/README.md) |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

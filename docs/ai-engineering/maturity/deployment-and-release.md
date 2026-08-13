---
review:
  status: unreviewed
  notes: "Deployment & release deep dive — DevOps/GitOps/API reconcile with argo corpus links."
---

# Deployment & Release — maturity deep dive

> **Audience:** Platform and application teams assessing how code and config reach production — including teams on Kubernetes/OpenShift, VMs, or API-managed platforms.
>
> **Purpose:** Expand the [trailhead](../software-systems-maturity.md) deployment axis with levels, anti-patterns, and **workspace examples** from GitOps practice.

**Related:** [Trailhead — DevOps/GitOps](../software-systems-maturity.md#devops-gitops-and-api-reconcile) · [Platform accelerator](platform-as-accelerator.md) · [Argo CD reference](../../../devops/argo/README.md)

---

## What this axis answers

*How predictably, safely, and audibly do we move intended state into production — and know when production drifted?*

Deployment maturity is **not** the same as having a CI job. It includes **release governance** (who can change prod), **environment parity**, and **convergence** (desired state actually applied).

---

## DevOps → GitOps → API reconcile

```text
DevOps       Cultural: break silos, own production, automate feedback
CI/CD        Mechanical: build → test → promote through environments
GitOps       Declarative: Git (or equivalent) is desired state; reconcile + drift
API reconcile Same principles when apply path is REST/CLI/Job, not a CR
```

**Misread to avoid:** "We use Git" = GitOps. Git without automated **converge** is [source control](../software-systems-maturity.md#source-control) maturity, not deployment maturity.

---

## Levels

| Level | Posture | Typical evidence |
|---|---|---|
| **0** | Snowflake servers; manual prod edits | No reproducible deploy record |
| **1** | Scripts checked in; human runs each env | Runbooks; SSH/Ansible ad hoc |
| **2** | CI builds/tests; deploy manual or partial | Jenkins/GitHub Actions to artifact only |
| **3** | Declarative desired state in Git; gated apply | Manifests/Helm in repo; manual `kubectl apply` or approved pipeline |
| **4** | Automated reconcile | Argo CD, Flux, operator, Terraform Cloud, or idempotent API Job |
| **5** | Drift visible and managed | Diff alerts, self-heal policy, or scheduled `--check-only` reconcile |

**Level 4 examples in this repo:**

| Pattern | Where |
|---|---|
| App-of-apps, multi-env | [APP-OF-APPS-PATTERN.md](../../../devops/argo/examples/docs/patterns/APP-OF-APPS-PATTERN.md) |
| Multi-cluster delivery | [multi-cluster-deployment.md](../../../devops/argo/examples/docs/deployment/multi-cluster-deployment.md) |
| Promotion pipelines | [framework/pipelines/promotion/](../../../devops/argo/examples/framework/pipelines/promotion/) |
| PR / diff workflow | [PR-WORKFLOW-GUIDE.md](../../../devops/argo/examples/docs/workflows/PR-WORKFLOW-GUIDE.md), [diffing-and-visibility.md](../../../devops/argo/examples/helm-component-pattern/docs/diffing-and-visibility.md) |
| Policy + generated resources | [ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md](../../../devops/argo/examples/docs/patterns/ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md) |
| Hands-on labs | [argo/labs/](../../../devops/argo/labs/README.md) |

**API reconcile (level 3–4 without CR):** desired YAML in Git + idempotent script or Job in the same delivery pipeline — same review gate as manifests, different apply target. Useful for platforms that expose admin REST or CLIs but no Kubernetes CR. Pattern: declarative spec → reconcile → fail sync on non-zero exit.

**Non-Kubernetes:** levels still apply — desired config in Git, Ansible/Terraform/Puppet converge, drift detection via scheduled plan/diff. The **shape** is identical; reconciler differs.

---

## Anti-patterns

| Anti-pattern | Why it hurts |
|---|---|
| "Deploy Friday" manual kubectl | No audit trail; hero-dependent |
| Config only in UI (SaaS admin, control plane) | Failover reproduction impossible |
| GitOps without review | Git as remote exec, not governance |
| Mixing manual prod hotfix with GitOps self-heal | Fighting the reconciler |
| Same branch, divergent cluster hand-edits | Git lies about prod |

---

## Teaching note — sandbox shift (from 2016 deck)

Push discovery left: bugs found in **production** are **too late**. Deployment maturity connects to [testing](../software-systems-maturity.md#testing--verification) — environments should exist **before** prod, with promotion increasing fidelity.

---

## External references

- [Continuous Delivery (Fowler)](https://martinfowler.com/bliki/ContinuousDelivery.html)
- [Deployment pipeline (Fowler)](https://martinfowler.com/bliki/DeploymentPipeline.html)
- [Blue-green deployment (Fowler)](https://martinfowler.com/bliki/BlueGreenDeployment.html)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

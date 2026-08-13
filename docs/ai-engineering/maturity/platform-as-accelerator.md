---
review:
  status: unreviewed
  notes: "Platform as maturity accelerator — K8s/OCP and non-K8s framing."
---

# Platform as Maturity Accelerator

> **Audience:** Teams evaluating or operating on Kubernetes/OpenShift (or similar), **and** teams not on those platforms who want a fair comparison of what a control plane buys you.
>
> **Purpose:** Explain why many organizations adopt a shared platform — not for hype, but because it advances **multiple maturity axes at once** — without implying you cannot mature elsewhere.

**Related:** [Trailhead](../software-systems-maturity.md#platform-as-maturity-accelerator) · [Deployment deep dive](deployment-and-release.md) · [Platform & fleet levels](../software-systems-maturity.md#platform--fleet)

---

## The question

*"Do we need Kubernetes to be mature?"*

**No.** Maturity is measured on **practices**, not labels. A disciplined VM or serverless shop can score higher than a cluster full of manual `kubectl` and secrets in ConfigMaps.

*"Then why did so many teams adopt Kubernetes or OpenShift?"*

Because a **shared declarative control plane** bundles primitives that otherwise require bespoke integration — each primitive maps to one or more [maturity axes](../software-systems-maturity.md#axis-ecosystem).

---

## What the platform bundles

| Platform capability | Maturity axes advanced |
|---|---|
| Declarative workload spec + rollout | Deployment, Architecture |
| Liveness/readiness, rolling updates | Deployment, Monitoring |
| Namespace isolation, ResourceQuota, NetworkPolicy | Security, Architecture |
| Ingress/service abstraction | Deployment |
| Operators / OLM lifecycle | Deployment, Platform |
| Integrated logging/metrics stacks (when deployed) | Monitoring |
| Secrets operators, external secret sync | Security & secrets |
| Multi-cluster fleet (ACM-class, GitOps hub) | Platform & fleet |
| Policy-as-code (Gatekeeper, RHACM policies) | Security, Platform |

**OpenShift** adds opinionated integration (Routes, SCCs, built-in operators, supported upgrade paths) — trading flexibility for **faster baseline** on several axes. That is an organizational trade, not a universal win.

---

## New to Kubernetes — read maturity honestly

Common trap: the **platform offers level 3–4 mechanisms** while the **team is still level 1–2 on practices**.

Examples:

| Platform gives you | You still need |
|---|---|
| Rolling update API | Git-managed manifests, review, promotion model |
| NetworkPolicy CRD | Someone to write and test policy |
| Prometheus operator | SLOs, alert routing, runbooks |
| External Secrets Operator | Vault (or equivalent) design, rotation |

Assess **team behavior**, not cluster features. A maturity conversation should ask: *"If we lost the platform defaults, what would we still do correctly?"*

**On-ramp in this repo:** [argo/labs/](../../../devops/argo/labs/README.md), [ocp/examples/](../../../devops/ocp/examples/README.md), [cross-dc rollout](../../../devops/ocp/examples/networking/cross-dc-rollout/README.md) (advanced networking illustration).

---

## Not on Kubernetes

The same **patterns** apply without etcd:

| Pattern | K8s expression | Non-K8s expression |
|---|---|---|
| Declarative desired state | Manifests in Git | Terraform, Ansible, cloud formation |
| Reconcile loop | Argo CD, operator | Scheduled apply, desired-state config mgmt |
| Drift detection | Argo diff, audit | Plan/diff in CI, config audit tools |
| Environment promotion | Overlays, ApplicationSet | Stage/prod parameter sets |
| Fleet | Multi-cluster Argo, ACM | Multi-account, multi-region automation |

**Do not discount non-K8s maturity.** Mainframe ops with change windows and evidence retention may exceed a startup cluster on **change governance** while lagging on **deployment frequency**.

---

## Platform & fleet — levels (expanded)

| Level | Posture |
|---|---|
| **1** | Single cluster/account; tribal knowledge |
| **2** | Dev/test/prod; documented differences |
| **3** | Platform config in Git; promotion documented |
| **4** | Multi-cluster fleet; policy as code; hub-spoke or peer GitOps |
| **5** | Upgrade safety, blast radius, and drift measured org-wide |

**Repo anchors:**

| Topic | Path |
|---|---|
| Fleet control spectrum | [fleet-control-spectrum.md](../../../devops/fleet-control-spectrum.md) |
| RHACM Git-driven config | [rhacm/](../../../devops/rhacm/README.md) |
| Greenfield fleet architecture | [greenfield-fleet-architecture.md](../../../devops/rhacm/notes/greenfield-fleet-architecture.md) |
| Multi-cluster Argo | [multi-cluster-deployment.md](../../../devops/argo/examples/docs/deployment/multi-cluster-deployment.md) |
| Executive vs architect framing | [fleet-management-ideas.md](../../../devops/fleet-management-ideas.md) (D-4) |

---

## When a platform **slows** maturity

Platforms can obscure pain:

- `kubectl apply` without Git → **false** deployment maturity
- Helm chart copy-paste without values discipline → config drift
- "The operator handles it" → no runbook when it doesn't
- GitOps for apps, manual cluster changes → split brain

The [Deployment deep dive](deployment-and-release.md) anti-patterns apply at platform scale.

---

## Summary

Choose a platform when its **integrated primitives** match axes you would otherwise build slowly yourself — and invest the saved time in **team practices**, **documentation for humans and agents**, and **security/secrets** maturity that platforms do not fully automate.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

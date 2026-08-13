---
review:
  status: unreviewed
  notes: "Platform accelerator v2 — mechanism vs team, fleet corpus, DORA measurement nuance."
---

# Platform as Maturity Accelerator

> **Audience:** K8s/OCP teams **and** non-K8s teams comparing what a control plane buys.
>
> **Purpose:** Multi-axis acceleration without implying Kubernetes is required for maturity.

**Related:** [Trailhead](../software-systems-maturity.md#platform-as-maturity-accelerator) · [Deployment](deployment-and-release.md) · [Security](security-and-secrets.md) · [DORA / AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md)

---

## The question

*"Do we need Kubernetes to be mature?"* **No.** Practices, not labels.

*"Why adopt K8s/OpenShift?"* Shared declarative control plane bundles primitives mapping to [multiple axes](../software-systems-maturity.md#axis-ecosystem).

---

## What the platform bundles

| Capability | Axes advanced |
|---|---|
| Declarative workload + rollout | Deployment, Architecture |
| Probes, rolling updates | Deployment, Monitoring |
| Namespace, quota, NetworkPolicy | Security, Architecture |
| Operators / OLM | Deployment, Platform |
| Logging/metrics stacks | Monitoring |
| ESO, vault integration | Security |
| ACM-class fleet, GitOps hub | Platform, Deployment |
| Policy-as-code | Security, Platform |

**OpenShift:** opinionated integration — faster **mechanism** baseline; organizational trade.

---

## Mechanism vs team (honest assessment)

| Platform gives | You still need |
|---|---|
| Rolling update API | Git manifests, review, promotion |
| NetworkPolicy CRD | Written, tested policy |
| Prometheus operator | SLOs, runbooks |
| ESO | Vault design, rotation |

Assess **team behavior**: *"If we lost platform defaults, what would we still do correctly?"*

**On-ramp:** [argo/labs/](../../../devops/argo/labs/README.md) · [ocp/examples/](../../../devops/ocp/examples/README.md)

---

## Platform & fleet — levels

| Level | Posture |
|---|---|
| **0** | Manual cluster/account changes untracked |
| **1** | Single cluster; tribal knowledge |
| **2** | Dev/test/prod; documented differences |
| **3** | Platform config in Git; promotion documented |
| **4** | Multi-cluster fleet; policy as code; hub-spoke GitOps |
| **5** | Upgrade safety, blast radius, drift measured org-wide |

---

## Evidence in this workspace (rich)

| Topic | Path |
|---|---|
| Fleet control spectrum | [fleet-control-spectrum.md](../../../devops/fleet-control-spectrum.md) |
| RHACM Git-driven | [rhacm/git-driven-configuration.md](../../../devops/rhacm/git-driven-configuration.md) |
| Greenfield fleet | [greenfield-fleet-architecture.md](../../../devops/rhacm/notes/greenfield-fleet-architecture.md) |
| Multi-cluster Argo | [multi-cluster-deployment.md](../../../devops/argo/examples/docs/deployment/multi-cluster-deployment.md) |
| Executive vs architect labels | [fleet-management-ideas.md](../../../devops/fleet-management-ideas.md) |
| Advanced networking illustration | [cross-dc-rollout/](../../../devops/ocp/examples/networking/cross-dc-rollout/README.md) |

---

## Not on Kubernetes

| Pattern | K8s | Non-K8s |
|---|---|---|
| Declarative state | Git manifests | Terraform, Ansible |
| Reconcile | Argo, operator | Scheduled apply |
| Drift | Argo diff | Plan/diff in CI |
| Fleet | ACM + Argo | Multi-account automation |

Mainframe change windows may exceed startup clusters on **governance** while lagging **deployment frequency**.

---

## DORA measurement nuance

Measure DORA on a **service/pipeline**, not "we have 50 clusters." Fleet platform work spans axes — use [worksheet](worksheet.md) per fleet slice or hub/spoke role.

---

## When platform slows maturity

- `kubectl apply` without Git  
- GitOps apps + manual hub changes  
- "Operator handles it" without runbook  

See [deployment anti-patterns](deployment-and-release.md).

---

## AI era

Agents editing fleet `values.yaml` without cascade understanding → architecture + documentation gap. Platform mechanisms don't validate semantic correctness of agent output.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

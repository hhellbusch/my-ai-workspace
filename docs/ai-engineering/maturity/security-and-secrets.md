---
review:
  status: unreviewed
  notes: "Security & secrets deep dive — application security + secrets/IAM tracks with vault/RHACM corpus."
---

# Security & Secrets — maturity deep dive

> **Audience:** Teams assessing application security and **secrets/identity operations** — especially those standardizing on Vault-class stores, External Secrets Operator, or fleet secret distribution.
>
> **Purpose:** Expand the [trailhead](../software-systems-maturity.md#security--secrets) axis with two parallel tracks, levels, anti-patterns, and workspace examples.

**Related:** [Deployment & release](deployment-and-release.md) · [Platform accelerator](platform-as-accelerator.md) · [Vault integration](../../../devops/vault/integration/README.md) · [RHACM secret management](../../../devops/rhacm/examples/secret-management/README.md)

---

## What this axis answers

*Can we protect the system and its data — and operate credentials without heroes, leaks, or surprise blast radius?*

One axis, **two tracks** that mature at different speeds:

| Track | Question |
|---|---|
| **Application security** | Is the software designed and maintained to resist abuse? |
| **Secrets & identity ops** | Are credentials short-lived, scoped, auditable, and out of Git? |

Level 3 on one track with level 1 on the other is a common and dangerous skew.

---

## Application security — levels

| Level | Posture |
|---|---|
| **0** | Known antipatterns (hardcoded creds, unsafe defaults) |
| **1** | Antipatterns removed ad hoc |
| **2** | Basic threat awareness; patches applied reactively |
| **3** | Designed against common attacks; basic access control |
| **4** | Secure-by-default; fine-grained authorization |
| **5** | Regular audits; patch and vulnerability discipline measured |

**Platform note:** Kubernetes/OpenShift provides **mechanisms** (NetworkPolicy, SCCs, RBAC) at level 3+ *potential* — your team still earns the level by using them correctly.

---

## Secrets & identity ops — levels

| Level | Posture |
|---|---|
| **0** | Secrets in Git, images, or plain ConfigMaps |
| **1** | Central store; manual copy; long-lived tokens |
| **2** | Scoped paths/policies; rotation runbooks |
| **3** | Dynamic or short-lived credentials; least privilege |
| **4** | Integrated with CI/CD and runtime (ESO, Vault Agent, platform vault) |
| **5** | Automated rotation; blast-radius drills; audit evidence |

**Vault-class pattern (2020s standard):** hierarchical paths (`shared/`, `regional/`, cluster-specific), KV v2 for versioning, Kubernetes auth to avoid bootstrap token sprawl — see [Vault integration overview](../../../devops/vault/integration/README.md).

---

## Fleet secret distribution (platform lens)

Multi-cluster shops add a **distribution** problem on top of storage:

| Approach | When | Repo |
|---|---|---|
| Policy-based push (Hub → spoke) | CA certs, registry creds, simple configs | [RHACM secret-management/1_basic_secret_distribution/](../../../devops/rhacm/examples/secret-management/1_basic_secret_distribution/) |
| ManagedServiceAccount | Automation/CI access to clusters | [2_managed_service_accounts/](../../../devops/rhacm/examples/secret-management/2_managed_service_accounts/) |
| External Secrets Operator | App secrets from Vault/AWS SM/etc. | [3_external_secrets_operator/](../../../devops/rhacm/examples/secret-management/3_external_secrets_operator/) |

Compare approaches: [secret-management README — when to use each](../../../devops/rhacm/examples/secret-management/README.md#when-to-use-each-approach).

**Maturity signal:** production app secrets at level 4+ usually mean **ESO + central store**, not Policy copying sensitive payloads to every cluster indefinitely.

---

## Anti-patterns

| Anti-pattern | Track |
|---|---|
| Passwords in repository | Secrets L0 |
| Shared admin kubeconfig in wiki | Secrets L0–1 |
| Vault installed but apps still use static K8s Secrets | Secrets L2 theater |
| NetworkPolicy CRDs exist; default allow everywhere | AppSec L3 gap |
| Rotating secrets without updating consumers | Secrets L3 failure |
| GitOps for apps, manual cluster admin creds | Split maturity |

---

## Connection to other axes

- **Deployment:** secret sync as part of reconcile ([deployment deep dive](deployment-and-release.md))
- **Documentation:** runbooks for break-glass and rotation ([documentation deep dive](documentation-and-knowledge.md))
- **AI agents:** never commit credentials; skills/rules flag secret files — overlaps [AI agents](ai-agents-and-harnesses.md)

---

## External references

- [HashiCorp Vault documentation](https://developer.hashicorp.com/vault/docs)
- [External Secrets Operator](https://external-secrets.io/)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

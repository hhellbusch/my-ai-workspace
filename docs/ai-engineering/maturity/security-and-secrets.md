---
review:
  status: unreviewed
  notes: "Security v2 — deck lineage, supply chain with builds L5, fleet secrets corpus."
---

# Security & Secrets — maturity deep dive

> **Audience:** Application security and **secrets/identity operations** — Vault, ESO, fleet distribution.
>
> **Purpose:** Two parallel tracks, deck lineage, workspace examples, supply chain overlap with [builds](builds-and-artifacts.md) L5.

**Related:** [Deployment](deployment-and-release.md) · [Platform accelerator](platform-as-accelerator.md) · [Vault integration](../../../devops/vault/integration/README.md) · [RHACM secret management](../../../devops/rhacm/examples/secret-management/README.md) · [DORA / AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md)

---

## What this axis answers

*Can we protect the system and operate credentials without heroes, leaks, or surprise blast radius?*

**Two tracks** — mature at different speeds:

| Track | Question |
|---|---|
| **Application security** | Designed against abuse? |
| **Secrets & identity ops** | Credentials short-lived, scoped, out of Git? |

---

## Application security — levels

| Level | Posture |
|---|---|
| **0** | Known antipatterns (hardcoded creds, unsafe defaults) |
| **1** | Antipatterns removed ad hoc |
| **2** | Basic threat awareness; reactive patches |
| **3** | Designed against common attacks; basic access control |
| **4** | Secure-by-default; fine-grained authorization |
| **5** | Regular audits; patch discipline measured |

**Deck lineage (appSec):** antipatterns present → no antipatterns → designed for security → secure by default → regular audits/patches.

---

## Secrets & identity ops — levels

| Level | Posture |
|---|---|
| **0** | Secrets in Git, images, plain ConfigMaps |
| **1** | Central store; manual copy; long-lived tokens |
| **2** | Scoped paths/policies; rotation runbooks |
| **3** | Dynamic/short-lived creds; least privilege |
| **4** | Integrated with CI/CD and runtime (ESO, Vault Agent) |
| **5** | Automated rotation; blast-radius drills; audit evidence |

**Vault-class pattern:** hierarchical paths, KV v2, K8s auth — [Vault integration overview](../../../devops/vault/integration/README.md).

---

## Supply chain (builds L4–5 overlap)

Signed images, SBOM, dependency pinning — [builds & artifacts](builds-and-artifacts.md) L5 + this axis. Not a separate maturity axis (trailhead merge decision).

---

## Fleet secret distribution

| Approach | Path |
|---|---|
| Policy-based push | [1_basic_secret_distribution/](../../../devops/rhacm/examples/secret-management/1_basic_secret_distribution/) |
| ManagedServiceAccount | [2_managed_service_accounts/](../../../devops/rhacm/examples/secret-management/2_managed_service_accounts/) |
| External Secrets Operator | [3_external_secrets_operator/](../../../devops/rhacm/examples/secret-management/3_external_secrets_operator/) |

Compare: [secret-management README](../../../devops/rhacm/examples/secret-management/README.md).

---

## AI era

Secrets in prompts, committed `.env`, or agent-generated config with credentials → **L0**. Review skill and rules flag secret patterns. Never trust agent to "redact" after commit — rotate + history repair ([source control](source-control.md)).

---

## Anti-patterns

| Anti-pattern | Track |
|---|---|
| Passwords in repository | Secrets L0 |
| Vault installed; apps use static Secrets | L2 theater |
| NetworkPolicy exists; default allow | AppSec L3 gap |
| GitOps apps; manual admin creds | Split maturity |

---

## Cross-axis

```text
Security ──gates──▶ Deployment (policy in reconcile)
         ──docs────▶ Documentation (break-glass runbooks)
         ──AI──────▶ AI agents (tool boundaries, no secrets in corpus)
```

---

## External references

- [HashiCorp Vault docs](https://developer.hashicorp.com/vault/docs)
- [External Secrets Operator](https://external-secrets.io/)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

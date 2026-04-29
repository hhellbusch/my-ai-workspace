# Automate OpenShift Cluster Deployment with RHACM and AAP

**Type:** Conference talk (video)
**Event:** DevConf.US 2024
**Presenters:** Michael Navarro, Michael Dado, Michael Zamot (Red Hat)
**URL:** https://www.youtube.com/watch?v=mi1z5H4VL3Q
**Duration:** ~31 minutes
**Research transcript:** [`research/devops/sources/ref-02-transcript.md`](../research/devops/sources/ref-02-transcript.md)

---

## Why This Matters

A rare practitioner-level talk that shows a real customer engagement — hundreds of OpenShift clusters, existing Ansible investment, two-week deadline — and how ACM + AAP were wired together without discarding the legacy automation. Directly relevant to any VMware admin team that already has Ansible and is evaluating how far to adopt GitOps.

---

## Key Themes

### 1. The Ansible + ACM bridge pattern

The central thesis: you do not need to discard existing battle-tested Ansible playbooks to adopt ACM and GitOps. The pipeline uses both simultaneously:

- **AAP generates Kubernetes CRs** using Jinja templates from Ansible inventory (host_vars / group_vars) — Jinja handles external lookups (Redfish, HashiCorp Vault, DNS) far more naturally than Go templates
- **ACM deploys the cluster** from those CRs (ManagedCluster, AgentClusterInstall, InfraEnv)
- **ACM policies trigger AAP** for Day 2 tasks via the `PolicyAutomation` object — when a policy goes non-compliant, ACM calls AAP to run a specific job

This bridges the gap between "existing Ansible shop" and "GitOps shop" without a big-bang rewrite.

### 2. `PolicyAutomation` — the ACM→AAP link mechanism

The key object that makes ACM and AAP interoperable:

```yaml
# PolicyAutomation — links an ACM policy to an AAP job
# When the policy is non-compliant, ACM calls AAP
kind: PolicyAutomation
spec:
  policyRef: post-provisioning-policy
  automationDef:
    name: post-provision-job   # AAP job template name
    secret: aap-credentials    # Kubernetes Secret containing AAP URL + token
  mode: once                   # or: everyEvent
```

The secret contains only the AAP instance URL and a bearer token. The PolicyAutomation object declares which policy event should trigger which AAP workflow. No custom code required.

### 3. The full pipeline flow

```
git commit (host_vars / group_vars)
     │
     ▼ webhook
AAP pre-deployment playbook
  → Jinja renders Kubernetes CRs
  → creates ManagedCluster, AgentClusterInstall, InfraEnv in ACM
     │
     ▼
ACM provisions cluster (Assisted Installer)
  + applies Day 1 ACM policies (operators, LDAP, etc.)
     │
     ▼ AAP labels ManagedCluster: post-provision=true
ACM policy detects label → non-compliant
  → PolicyAutomation calls AAP
     │
     ▼
AAP post-provisioning playbook
  → external DNS, monitoring config, application deployment
```

### 4. Why they chose ACM over Argo CD

Direct practitioner answer: "ACM does almost all the functionality that Argo CD will do under the hood — they work under the same models and can perform the same task. There was no need to add another piece of software when ACM already does those tasks." Secondary reason: Jinja (via AAP) handles external data lookups (Redfish, Vault) far better than Go templating.

### 5. Blue-green cluster upgrades instead of in-place

With a 40-minute cluster provisioning time, the team moved the customer toward blue-green cluster lifecycle: deploy a new cluster on the target OCP version, migrate workloads, retire the old one. In-place major version upgrades were 8+ hours with limited maintenance windows; blue-green makes the cluster disposable. This is the "cattle not pets" model applied to clusters themselves, not just to the workloads running inside them.

### 6. Disconnected / air-gapped environments

The entire pipeline was demonstrated on a fully disconnected environment. ACM, AAP, and the Assisted Installer all operated without internet access. Noted as a requirement for the customer.

### 7. Idempotency via Ansible

Running the pipeline repeatedly is safe: Ansible renders the same templates from the same source-of-truth (git) and only applies changes. If the cluster is already deployed, the playbook changes nothing. This is native Ansible idempotency applied to cluster lifecycle.

---

## Notable Ideas

| Idea | Implication |
|------|-------------|
| AAP + Jinja generate the K8s CRs | External data sources (Redfish, Vault, DNS) can feed cluster definitions; Go templates alone cannot do this easily |
| `PolicyAutomation` links ACM → AAP | ACM policy non-compliance can trigger any AAP job — not just cluster ops; ServiceNow tickets, PagerDuty alerts, anything AAP can reach |
| Blue-green over in-place upgrades | 40-minute provisioning makes cluster replacement faster than upgrade maintenance windows |
| Reuse Ansible investment | Teams with 2+ years of Ansible playbooks don't have to rewrite; ACM is the orchestrator, Ansible is the executor |
| Disconnected environments | Full pipeline confirmed working air-gapped |

---

## Sources

- [Talk recording (YouTube)](https://www.youtube.com/watch?v=mi1z5H4VL3Q)
- [Raw transcript](../research/devops/sources/ref-02-transcript.md)
- Presenters' GitHub repo referenced in the talk: search for `rhacm-aap-cluster-deployment` on GitHub

---

*AI-assisted content. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for review status details.*

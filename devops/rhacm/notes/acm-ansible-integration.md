---
review:
  status: unreviewed
  notes: "AI-generated 2026-08-03. Verified against RHACM 2.15 governance docs, ACM 2.10 applications docs, cluster-curator-controller, and ACM 2.16 support matrix."
---

# RHACM and Ansible / AAP Integration

> **Audience:** Platform architects and engineers evaluating how Red Hat Advanced Cluster Management and Ansible Automation Platform work together.
> **Purpose:** Map native ACM→Ansible integration paths, prerequisites, and what requires a controller versus external orchestration.

---

## Mental model

ACM is the **fleet control plane** (inventory, provisioning, policies, placements).
Ansible (via **AAP**, **AWX**, or historically Tower) is the **automation executor** for playbooks and external integrations.

ACM does **not** run playbooks itself.
It **orchestrates when** a controller runs them, via `AnsibleJob` resources reconciled by the **Ansible Automation Platform Resource Operator**.

```
AAP generates CRs (optional)  →  ACM provisions / governs  →  ACM triggers AAP on events
```

Bidirectional pattern from practice: [library: Automate OCP cluster deployment with RHACM and AAP](../../../library/automate-ocp-cluster-deployment-rhacm-aap.md).

---

## Is AAP required?

| Component | Required for native ACM Ansible hooks? |
|-----------|----------------------------------------|
| **AAP** (commercial) | No — but Red Hat **support** and docs target AAP |
| **AWX** (upstream) | **Yes, works** — same API + Job Template model |
| **AAP Resource Operator** | **Yes** — creates `AnsibleJob` CRs (`tower.ansible.com/v1alpha1`) |
| **ansible-core alone** | **No** — not invokable by ClusterCurator / PolicyAutomation |

Minimum controller version cited in docs: Tower/AAP **3.7.3+**.
[ACM support matrix](https://access.redhat.com/articles/7136928) tests/fixes integrations for AAP versions **N** and **N-1**.

Install the Resource Operator from OperatorHub; channel `stable-2.x-cluster-scoped`.
It can run on the hub or a separate cluster (version must match AAP if co-located on hub).

---

## Four native integration paths

### 1. Cluster lifecycle — `ClusterCurator`

Pre/post hooks around **install** and **upgrade** (primary supported lifecycle stages per [ACM 2.16 support matrix — Integrate Ansible (create, upgrade)](https://access.redhat.com/articles/7136928)).

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: ClusterCurator
metadata:
  name: prod-bm-01
  namespace: prod-bm-01
spec:
  desiredCuration: install
  install:
    prehook:
      - name: validate-network          # AAP Job Template name
    posthook:
      - name: set-ocm-subscription
  towerAuthSecret: aap-credentials
```

Flow: curator controller → `AnsibleJob` → controller API → playbook.

**Auto-injected `extra_vars`** (ClusterCurator):

- `cluster_deployment` — cluster metadata (`clusterName`, platform, …)
- `machine_pool` — worker pool details

Job templates must allow **Prompt on launch** for **Extra Variables** — ACM always passes `extra_vars`.

For install/upgrade **hooks** (ClusterCurator), see [bare-metal-lifecycle-hook-patterns.md](./bare-metal-lifecycle-hook-patterns.md).

Workspace examples:

- [cluster-curator/README.md](../examples/ocm-subscription-automation/cluster-curator/README.md)
- [CLUSTERCURATOR-ARCHITECTURE-DECISION.md](../examples/ocm-subscription-automation/cluster-curator/CLUSTERCURATOR-ARCHITECTURE-DECISION.md)
- [agent-install-preflight.md](agent-install-preflight.md)

**Caveat:** Curator hooks assume **Hive / Assisted Installer** provisioning.
If Ansible still fully provisions clusters, Curator only helps at the edges.
Destroy/scale hooks appear in CRDs and workspace notes — validate against your ACM/MCE version; matrix lists Ansible for **create and upgrade** only.

---

### 2. Governance — `PolicyAutomation`

Links a **policy** to an **AAP Job Template** when the policy is non-compliant.

```yaml
apiVersion: policy.open-cluster-management.io/v1beta1
kind: PolicyAutomation
metadata:
  name: my-policy-automation
spec:
  policyRef: my-policy
  mode: once                    # once | everyEvent | disabled
  automationDef:
    name: remediate-or-ticket
    type: AnsibleJob
    secret: ansible-tower
    extra_vars:
      ticket_queue: storage
```

**Modes** ([ACM 2.15 policy deployment](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/governance/policy-deployment)):

| Mode | Behavior |
|------|----------|
| `once` | Runs on violation, then sets itself to `disabled` |
| `everyEvent` | Runs per violation; optional `DelayAfterRunSeconds` |
| `disabled` | Off until re-enabled |

**Auto-injected `extra_vars`:**

- `target_clusters` — non-compliant cluster names
- `policy_name`, `policy_namespace`, `hub_cluster`, `policy_sets`
- `policy_violations` — per-cluster policy status

Use for **external** remediation (ServiceNow, DNS, CMDB) — not for K8s config that policies can `enforce` directly.

Reference: [Red Hat blog — Ansible on policy violations](https://www.redhat.com/en/blog/initiating-ansible-automation-on-policy-violations).

---

### 3. Application subscriptions — Git `prehook` / `posthook`

Legacy **ACM Applications** (channel/subscription) can run Ansible before/after app deploy:

```text
git-repo/
├── prehook/      # AnsibleJob CRs — block deploy until success
├── posthook/
└── … app manifests …
```

Subscription `spec.hookSecretRef` → `AnsibleJob.spec.tower_auth_secret`.

Most greenfield fleets use **Argo CD** instead of ACM subscriptions.
See [ACM 2.10 Applications — Ansible configuration](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.10/html-single/applications/index).

---

### 4. Standalone `AnsibleJob` + Placement

`AnsibleJob` bound to cluster labels; when clusters join/leave, `extra_vars.target_clusters` updates.

Useful for ongoing automation tied to fleet membership, not only lifecycle events.
See [ACM 2.3 — Ansible on managed clusters](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.3/html/clusters/ansible-config-cluster).

---

## Executing on spoke clusters (Day 2)

Native hooks often run playbooks on **localhost** (hub).
To run against **managed cluster APIs** from Ansible:

| Addon / tool | Role |
|--------------|------|
| **ClusterProxy** | Hub→spoke network tunnel |
| **ManagedServiceAccount** | Hub-projected tokens for spoke API |
| **stolostron.core** collection | `ocm_managedcluster` inventory, `managed_serviceaccount` module |

Demo: [acm-ansible-collection-demo](https://github.com/stolostron/acm-ansible-collection-demo).

This is distinct from [fleet ad-hoc data gathering](fleet-ad-hoc-data-gathering.md) — same connectivity building blocks, different trigger (manual playbook vs ACM event).

---

## External Ansible (not native ACM hooks)

Common patterns that **do not** use ClusterCurator or PolicyAutomation:

| Pattern | Location in workspace |
|---------|----------------------|
| Cluster import playbooks | [cluster-import-ansible](../examples/cluster-import-ansible/README.md) |
| AAP renders ACM CRs from Jinja/inventory | [library: RHACM + AAP talk](../../../library/automate-ocp-cluster-deployment-rhacm-aap.md) |
| Import strategy comparison | [CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md](../examples/CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md) |
| Fleet host diagnostics (`oc debug`) | [NVMe ansible](../../ocp/troubleshooting/nvme-tcp-storage-network/ansible/README.md) |

---

## Operational prerequisites

1. **Resource Operator** installed and healthy
2. **Credential Secret** on hub (`host` + `token`) — `towerAuthSecret` or policy credential
3. **Job templates** idempotent; **Prompt on launch** enabled for extra vars
4. **AAP/AWX** reachable from hub (watch proxy environments — curator + AAP through cluster-wide proxy can fail)

Sample templates: [stolostron/ansible-tower-samples](https://github.com/stolostron/ansible-tower-samples).

---

## What ACM Ansible integration is not

| Expectation | Reality |
|-------------|---------|
| Fleet-wide ad-hoc shell | Not supported — see [fleet-ad-hoc-data-gathering.md](fleet-ad-hoc-data-gathering.md) |
| Replace GitOps delivery | Argo CD owns most Day 2 config in modern fleets |
| Run without any controller | Need AAP, AWX, or external CI/ansible-core outside hook system |
| Ansible as primary provisioner | Conflicts with Hive/CIM curator model |

---

## Related reading

| Topic | Location |
|-------|----------|
| Greenfield fleet (when to add AAP) | [greenfield-fleet-architecture.md](greenfield-fleet-architecture.md) |
| Hook implementation (preflight, BMH, Go) | [bare-metal-lifecycle-hook-patterns.md](bare-metal-lifecycle-hook-patterns.md) |
| Fleet control spectrum | [fleet-control-spectrum.md](../../fleet-control-spectrum.md) |
| ClusterCurator deep dive | [cluster-curator/README.md](../examples/ocm-subscription-automation/cluster-curator/README.md) |
| Git-driven RHACM | [git-driven-configuration.md](../git-driven-configuration.md) |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

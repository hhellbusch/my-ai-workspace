# Fleet Control Spectrum

> **Audience:** Platform architects and engineers choosing how RHACM and Argo CD divide fleet work on OpenShift
> **Purpose:** Multiple axes for tradeoffs — not a "pick one product" decision — plus a reconsideration checklist when the solution leans GitOps-heavy

---

## What this is

RHACM and Argo CD overlap in capability.
Both can push YAML to managed clusters.
Both can reconcile drift.

The useful question is not *which tool wins* but *where authority lives* for each class of change — and whether deviation is a **sync problem** or a **compliance event**.

This document names several **spectra** (barometers) on those axes.
Read them together.
A posture that is correct on one axis may be wrong on another.

Pure 100% on either end is rare in production.
The extremes are **design postures** — useful anchors, not procurement choices.

---

## On this page

- [Axis 1: Reconciliation authority](#axis-1-reconciliation-authority)
- [Axis 2: Compliance posture](#axis-2-compliance-posture)
- [Axis 3: Lifecycle scope](#axis-3-lifecycle-scope)
- [Axis 4: Targeting and identity](#axis-4-targeting-and-identity)
- [Axis 5: Organizational ownership](#axis-5-organizational-ownership)
- [Axis 6: Drift semantics](#axis-6-drift-semantics)
- [Axis 7: Secrets and sensitive material](#axis-7-secrets-and-sensitive-material)
- [Reference posture: GitOps-heavy hub-and-spoke](#reference-posture-gitops-heavy-hub-and-spoke)
- [Reconsideration triggers](#reconsideration-triggers)
- [Per-concern placement worksheet](#per-concern-placement-worksheet)
- [Governance phase: what to add without redesign](#governance-phase-what-to-add-without-redesign)
- [Related reading](#related-reading)

---

## Axis 1: Reconciliation authority

*Who is the controller of record for desired state on spokes?*

```
GitOps-first ◄────────────────────────────────────────► Governance-first
(Argo CD)                                              (RHACM Policy)
```

| Position | Posture | Typical signals |
|----------|---------|-----------------|
| Far left | All Day 1/Day 2 config delivered via ApplicationSets and Helm charts; hub-only Argo CD | Strong PR culture, platform owns one Git monorepo, teams accept central promotion |
| Center | Split by concern: ACM for mandates and lifecycle, Argo for app/platform delivery | Most enterprise fleets; OpenShift Platform Plus default mental model |
| Far right | Policies and subscriptions own reconciliation; Argo optional or absent | Ansible-heavy shops, regulatory baselines, ZTP-at-scale, minimal app-team GitOps maturity |

**Line between tools (per resource):** *Who owns this, and is deviation a team preference or a compliance violation?*
See the decision table in [VMware admins learning path — Phase 5](learning-path/vmware-admins/README.md#phase-5--fleet-scale-gitops-with-acm).

---

## Axis 2: Compliance posture

*When live state diverges from intent, what happens — and who sees it?*

```
Self-heal quietly ◄────────────────────────────────────► Report and enforce
(Argo sync)                                            (ACM inform / enforce)
```

| Position | Behavior | Good fit |
|----------|----------|----------|
| Left | Argo CD reverts drift; audit trail is Git history + Argo UI | Team-owned config, fast iteration, "Git is the contract" |
| Center | Argo for delivery; ACM `inform` on selected platform objects | Want fleet visibility without dual controllers fighting |
| Right | ACM `enforce` + compliance dashboard + policy reports | Platform mandates, auditors, SOC workflows, "non-compliant" as a first-class signal |

**Argo-heavy gap:** Fleet-wide compliance status, severity, and remediation history live in ACM Governance — not in the Argo CD UI.
If stakeholders ask *"which clusters are out of policy?"* and the answer requires parsing Application sync errors cluster by cluster, this axis is underspecified.

---

## Axis 3: Lifecycle scope

*How much of cluster birth-to-death runs through the hub control plane?*

```
Import + configure ◄──────────────────────────────────► Provision + upgrade + retire
                                                     (CIM, ZTP, ClusterCurator)
```

| Position | RHACM role | Argo CD role |
|----------|------------|--------------|
| Left | Import existing clusters; inventory; optional label sync | All post-import configuration |
| Center | Import or provision; baseline policies; GitOpsCluster registration | Day 2 delivery and values cascade |
| Right | Assisted install, ZTP, upgrade orchestration, PolicyAutomation → AAP | Delivers app content ACM subscribes to, or absent |

**Argo-heavy gap:** Day 0 cluster creation stays outside the GitOps loop unless CIM/ZTP is added on the hub.
That is fine when clusters are born elsewhere — but the lifecycle axis and the reconciliation axis should be documented together so customers do not assume "GitOps fleet" implies "GitOps provisioning."

---

## Axis 4: Targeting and identity

*How do you decide which clusters get which configuration?*

```
Argo cluster generator ◄──────────────────────────────► ACM Placement + Policy
(labels on cluster secrets)                            (ManagedCluster selectors)
```

| Mechanism | Source of truth | Propagation |
|-----------|-----------------|-------------|
| Argo ApplicationSet `clusters` generator | Labels on Argo CD cluster secrets | RHACM GitOps addon copies `ManagedCluster` labels → secrets |
| ACM Placement | Labels or claims on `ManagedCluster` | PolicyBinding wires policies to placements |

**Hybrid touchpoint (already in-repo):** Git defines labels in `cluster.yaml`; RHACM Policy enforces them on `ManagedCluster`; Argo reads them for ApplicationSet targeting.
See [cluster label sync](argo/examples/framework/hub/rhacm/cluster-labels/README.md).

**Argo-heavy risk:** If labels are edited only in Git and enforced only at sync time — without ACM policy — manual `oc label` on `ManagedCluster` can desync targeting until the next pipeline run.
The label-sync policy pattern exists precisely to close that gap without moving delivery to ACM.

---

## Axis 5: Organizational ownership

*Who merges to production — and for what scope?*

```
Team autonomy ◄────────────────────────────────────────► Platform mandate
(app repos, env branches)                              (single fleet baseline)
```

| Position | Pattern |
|----------|---------|
| Left | App teams own repos and Argo Applications; platform provides cluster inventory |
| Center | Platform owns fleet repo (Helm + values cascade); teams opt in per app label |
| Right | Platform owns policy bundles; variation only via policy templates (OCP version, region) |

Day 2 cluster customizations defined as Helm charts in a platform repo sit **left-center** on this axis: centralized delivery, per-cluster overrides via `values.yaml`, opt-in/out via labels.

That is coherent when the platform team is the merge gate.
It strains when many teams need independent promotion cadences for the same cluster-scoped operators.

---

## Axis 6: Drift semantics

*What does "drift" mean in your operating model?*

| Semantic | Tool | Operator question |
|----------|------|-------------------|
| "Cluster differs from Git" | Argo CD | Is the Application Synced? |
| "Cluster violates organizational policy" | ACM | Is the policy Compliant? |
| "Someone changed the cluster outside Git" | Both — if both own the same object | **Conflict** — pick one owner |

**Rule:** One controller per resource kind (or per object instance).
Dual ownership of the same `Subscription`, `OAuth`, or `ConfigMap` produces fight-or-flap behavior.

**Argo-heavy implication:** Everything in the fleet app catalog is Argo-owned drift.
Objects nobody deployed via Argo — console edits, day-1 install payloads, addon defaults — are invisible unless you add ACM `inform` policies or periodic audits.

---

## Axis 7: Secrets and sensitive material

```
Git + ESO on spoke ◄──────────────────────────────────► Hub-held secrets via ACM
(Vault → ExternalSecret)                                 (CopySecret / fromSecret policies)
```

| Approach | Fits when |
|----------|-----------|
| External Secrets Operator deployed by Argo; Vault upstream | Secrets tied to app delivery; same GitOps pipeline |
| ACM secret distribution patterns | Pull secrets, TLS bundles, or credentials that must exist before GitOps apps sync; fleet-wide bootstrap |

Neither is wrong.
The axis matters when onboarding order is fragile (e.g. pull secret must exist before operators sync).

See [RHACM secret management examples](rhacm/examples/secret-management/) and the framework's [external-secrets app](argo/examples/framework/apps/external-secrets/).

---

## Reference posture: GitOps-heavy hub-and-spoke

The [Argo CD fleet framework](argo/examples/framework/) expresses a deliberate **GitOps-first** posture.
Approximate positions on each axis:

| Axis | Position | Notes |
|------|----------|-------|
| Reconciliation authority | ~75–85% GitOps-first | Day 2 configs are Helm charts via hub ApplicationSets |
| Compliance posture | ~80% self-heal | No fleet policy catalog; drift = Argo OutOfSync |
| Lifecycle scope | ~70% import + configure | Provisioning optional via [CIM hub setup](rhacm/notes/cim-hub-setup.md) |
| Targeting | Hybrid | ACM enforces labels; Argo targets on those labels |
| Ownership | Left-center | Platform monorepo, cluster sovereignty in `values.yaml` |
| Drift semantics | Argo-primary | ACM only for label enforcement on hub |
| Secrets | ESO via Argo | Vault upstream; not ACM CopySecret |

### What RHACM still does in this posture

| Concern | RHACM role |
|---------|------------|
| Cluster import and health | `ManagedCluster` lifecycle |
| Fleet inventory | Hub console, search (if enabled) |
| Argo CD registration | `GitOpsCluster` + `ManagedClusterSetBinding` — [integration example](rhacm/examples/gitops-cluster-integration/) |
| Label integrity | Policy-generated from `cluster.yaml` — [label sync chart](argo/examples/framework/hub/rhacm/cluster-labels/) |
| Addon enablement | ManagedServiceAccount, observability, etc. |

### What Argo CD owns

| Concern | Examples in framework |
|---------|----------------------|
| Platform operators and config | cert-manager, cluster-monitoring, cluster-logging, nvidia-gpu-operator |
| Infrastructure glue | external-secrets, baremetal-hosts |
| Fleet app catalog | Opt-in/out via `app.enabled/*` labels; values cascade |
| Promotion and review | Git workflows, CI validation, RollingSync |

This is a valid architecture when the organization accepts **Git + Argo as the compliance story** for everything in the catalog — and ACM is treated as **control plane + inventory**, not governance.

---

## Reconsideration triggers

Use these when reviewing an Argo-heavy design.
Each trigger maps to an axis and a possible ACM addition **without** moving delivery off Argo.

### 1. Platform mandates with audit requirements

**Signal:** Security or compliance asks for fleet-wide "compliant / non-compliant" on OAuth, kubelet, kubeadmin removal, NMState, file-integrity-operator, or pull secrets.

**Axis:** Compliance posture.

**Reconsider:** ACM Policy with `inform` first, `enforce` when ready — even if Argo also deploys the same object today.
Pick one owner; do not dual-deploy.

**Repo pointer:** [distribute-yaml-to-all-clusters.md](rhacm/examples/distribute-yaml-to-all-clusters.md) Option 2.

### 2. Objects outside the Argo app catalog drift silently

**Signal:** Console edits or emergency `oc` changes persist; nobody notices until an incident.

**Axis:** Drift semantics.

**Reconsider:** ACM `inform` policies on critical types Argo does not manage — or expand the catalog.
Argo self-heal only applies to resources under an Application.

### 3. Heterogeneous fleet + platform mandate

**Signal:** "Every Virt cluster must have NMState" but channel varies by OCP minor version.

**Axis:** Reconciliation authority (grey zone).

**Reconsider:** ACM policy templating — not a wholesale move to Argo.
See [grey zone resolution](learning-path/vmware-admins/README.md#key-decision-argo-cd-application-vs-acm-policy).

### 4. Day-2 work outside Kubernetes

**Signal:** Post-provision DNS, CMDB, ServiceNow, bare-metal firmware — triggered by cluster state.

**Axis:** Lifecycle scope.

**Reconsider:** `PolicyAutomation` → AAP.
Argo CD does not call external systems on compliance events.
See [library: RHACM + AAP talk](library/automate-ocp-cluster-deployment-rhacm-aap.md).

### 5. Regulatory evidence beyond Git log

**Signal:** Auditors want policy reports, not screenshots of Argo UI.

**Axis:** Compliance posture.

**Reconsider:** PolicyGenerator from Git (policies still reviewed in PRs) + ACM compliance export.
Git remains truth; ACM becomes the **reporter**.

### 6. Blast radius on fleet-wide sync

**Signal:** One bad chart promote affects every matching cluster in one sync wave.

**Axis:** Organizational ownership / operations.

**Reconsider:** Operational controls (RollingSync, sync windows, `preserveResourcesOnDeletion`) — Argo-side — **and** optionally ACM to gate *whether* an ApplicationSet may exist on a class of clusters.
See [framework evaluation — sync risk](argo/examples/framework/docs/FRAMEWORK-EVALUATION-v1.md).

### 7. Onboarding MVP defers governance

**Signal:** Phase plan has "governance slice" after first Git deploy — labels and drift scope still TBD.

**Axis:** All.

**Reconsider:** Use [Governance phase](#governance-phase-what-to-add-without-redesign) below as a minimal ACM increment that preserves the Argo-heavy spine.

---

## Per-concern placement worksheet

For each configuration class, plot **one** owner.
If unsure, answer the two questions first.

| Question | Lean Argo | Lean ACM |
|----------|-----------|----------|
| Who decides this exists? | Team or platform via PR to fleet repo | Platform mandate on cluster type |
| Is deviation a violation or a preference? | Preference (fix in next PR) | Violation (must report or enforce) |

| Concern | Typical owner in GitOps-heavy posture | Revisit with ACM when… |
|---------|---------------------------------------|-------------------------|
| Workloads (Deployments, Routes, team apps) | Argo | Rarely |
| Team-owned operators (Strimzi, custom monitoring) | Argo | Mandate + audit required |
| Cluster monitoring/logging baseline | Argo (framework apps) | Compliance dashboard required |
| cert-manager / TLS platform | Argo | Regulatory evidence on cert policy |
| NMState, OAuth, kubelet, kubeadmin | **Often ACM** — currently may be absent in Argo-only catalog | Always for mandates |
| OpenShift Virt operator (platform) | Grey zone | Mandate → ACM; team variance → Argo |
| Cluster labels / group membership | ACM policy enforcing Git (`cluster.yaml`) | Already hybrid in framework |
| Pull secrets / bootstrap secrets | ESO or ACM | Bootstrap order fragile |
| Cluster provision / upgrade | ACM (CIM, ZTP, Curator) | Any automated Day 0 |
| External automation on cluster ready | ACM PolicyAutomation | DNS, tickets, AAP workflows |

---

## Governance phase: what to add without redesign

When an onboarding program reaches a "governance slice" after Git deploy works, these increments fit an Argo-heavy spine:

1. **Label policy only (likely already present)** — `ManagedCluster` labels match `cluster.yaml`; no manual `oc label`.
2. **Inform policies on unmanged critical types** — detect drift Argo does not touch (e.g. `ClusterVersion`, `OAuth`, selected `OperatorGroup`).
3. **One enforce policy for a single mandate** — prove Placement + Policy + compliance UI E2E before a catalog.
4. **Document the split** — table of Argo-owned vs ACM-owned kinds; escalation path when sync and compliance disagree.

Non-goals for this slice: duplicating Argo app content in policies; fleet-wide policy catalog; legacy drift remediation.

---

## Related reading

| Topic | Location |
|-------|----------|
| Argo vs ACM decision table + grey zone | [learning-path/vmware-admins — Phase 5](learning-path/vmware-admins/README.md) |
| Three ways to push YAML fleet-wide | [distribute-yaml-to-all-clusters.md](rhacm/examples/distribute-yaml-to-all-clusters.md) |
| Hub-and-spoke framework | [argo/examples/framework/](argo/examples/framework/) |
| Framework design invariants | [GUIDELINES.md](argo/examples/framework/GUIDELINES.md) |
| RHACM → Argo registration | [gitops-cluster-integration/](rhacm/examples/gitops-cluster-integration/) |
| ACM + Ansible bridge | [library/automate-ocp-cluster-deployment-rhacm-aap.md](../library/automate-ocp-cluster-deployment-rhacm-aap.md) |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author.
See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

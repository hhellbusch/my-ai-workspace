# Learning path: VMware admin → Kubernetes, OpenShift, and OpenShift Virtualization

**Audience:** Infrastructure and platform engineers who already know vSphere — across storage, networking, and compute/VM management — and want to operate **OpenShift (OCP)** and **OpenShift Virtualization** confidently. Application development is not the primary goal; understanding Kubernetes deeply enough to administer the platform — and to automate its full lifecycle — is.

**Outcomes:** Understand Kubernetes internals well enough to reason about cluster state; use `oc` and `kubectl`; operate networking and storage at a platform level; run and migrate VMs with OpenShift Virtualization; use Git and GitHub as an accountability and change management system. At fleet scale: manage configuration and compliance across many clusters with ACM and, for very large environments, automate the full cluster lifecycle with the ZTP GitOps pipeline.

**Scale and topology — which phases apply to you**

Most teams do not run a single cluster in production. Whether you are managing ten clusters across two data centres or two hundred edge sites, the operational model changes when you add more clusters. Use this as a guide to which phases are relevant:

| Environment | Typical cluster count | Recommended phases | Lab requirement |
|-------------|----------------------|-------------------|----------------|
| Getting started / single cluster | 1–2 | 0–4 + Git prerequisite | Single cluster (SNO lab in this repo) |
| Small fleet | 3–10 | 0–5 | Hub cluster + ≥1 managed cluster |
| Medium fleet | 10–50 | 0–5, ACM required | Hub cluster + managed clusters |
| Large / edge fleet | 50–200+ | 0–6 | Hub + bare metal / simulated nodes |

ACM is not required to get value from this path. Phases 0–4 stand alone with the existing lab. Phase 5 (fleet management) and Phase 6 (ZTP) require additional infrastructure.

**Disclaimer:** This is a curated study guide, not Red Hat training, certification prep, or support. Official product behavior, course numbers, and doc URLs change — verify against [Red Hat Documentation](https://docs.redhat.com/) and your subscription entitlements before production decisions. *Red Hat*, *OpenShift*, and related marks are trademarks of Red Hat, Inc. *Portworx* and *Pure Storage* content is third-party; see the supplementary section for scope.

---

## How to use this path

1. **Start fresh.** See Phase 0. The biggest obstacle is not a missing skill — it is a mental model that needs to be rebuilt, not extended.
2. If you are **new to Git**, complete the **[Prerequisite: Git and GitHub](#prerequisite-git-and-github)** section before Phase 4; doing it before Phase 1 makes lab and "edit YAML in repo" workflows much easier.
3. **Phases 1 and 2 can run in parallel** — Phase 1 covers application-layer Kubernetes (Pods, Deployments, Services); Phase 2 covers cluster-level operations (cluster operators, MachineConfig, node management). They are distinct enough that an experienced infrastructure engineer can move through both simultaneously. **Both must be substantially complete before Phase 3.** OpenShift Virtualization runs on top of Kubernetes; understanding the substrate first is not optional.
4. Each phase has **verification** — scenario-based, not definition-recall. If you cannot do the check without notes, that phase is not done.
5. Pair **reading** with a **single lab cluster** (workshop, cloud trial, or home lab) so every concept maps to something you can inspect in the console **or** from the CLI. Note the lab requirements per phase in the scale table above — Phases 5 and 6 need infrastructure beyond a single SNO.

**Lab options in this repo**

- [SNO on KVM lab setup](../../ocp/examples/sno-kvm-lab/README.md) — single-node OpenShift for local practice.
- [Argo CD labs](../../argo/labs/README.md) — GitOps exercises (after you are comfortable with namespaces and manifests).
- [OCP command notes](../../ocp/notes/openshift-useful-commands.md) — day-to-day `oc` / `kubectl` patterns.

---

## Phase 0 — Start fresh: OCP is a Kubernetes platform (½–1 day)

**The single most important thing to internalize before anything else:**

> **OpenShift is a Kubernetes platform. OpenShift Virtualization is a Kubernetes add-on that runs VMs inside Kubernetes. The substrate is Kubernetes — not a hypervisor.**

The most common failure mode for VMware teams is treating OCP as "vSphere with containers bolted on." It is the inverse: a container orchestration platform with virtual machine support bolted on. If you build your mental model starting from vCenter and map Kubernetes onto it, that model breaks at the first upgrade, the first failing pod, the first time a node drains. If you build your mental model starting from Kubernetes and then add VMs to that picture, you can reason about the whole system.

**Approach this with beginner's mind.** Some of what you know about infrastructure operations transfers. A significant amount does not — and anchoring too hard on the VMware analogy makes those gaps harder to find and correct. The mapping table below is a temporary scaffold, not a map to trust permanently. You will know you are past this phase when you stop reaching for the analogy and start reading the cluster state directly.

**Goals**

- Understand the **control plane / worker / workload** three-layer split that replaces the vCenter / ESXi / VM picture.
- Understand that **Pods — not VMs — are the unit Kubernetes reasons about**, even when VMs are running inside it via OpenShift Virtualization.
- Accept that Phase 1 (Kubernetes internals) comes before Phase 3 (VMs) for a reason: a KubeVirt VirtualMachineInstance *is a Pod*. You cannot operate it without understanding what a Pod is.

**Reading**

- [Architecture overview](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/architecture/) (OCP docs) — read for the shape of the system; do not try to memorize yet.
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/) (Kubernetes docs) — the atom. A KubeVirt VMI is a Pod with a hypervisor process inside it; the scheduler does not know or care.

**Verification (scenario-based)**

- Without notes: sketch the three layers and place API server, etcd, kubelet, and scheduler correctly. If you cannot, the rest of the path will feel arbitrary.
- Answer out loud: "When OpenShift Virtualization creates a VM, what does Kubernetes see?" If you cannot answer "a Pod" without hesitation, stay in Phase 0.

---

## VMware concepts: what maps, what partially maps, what to discard

Use this as a **temporary scaffold only**. The right column is the destination; the left column is where you are starting. Some mappings break under pressure — the "Discard or reframe" column names where.

| VMware concept | OpenShift / Kubernetes analogue | Discard or reframe when… |
|----------------|----------------------------------|--------------------------|
| vCenter UI / web client | **OpenShift Console** — a read/observe tool, not the source of truth. Git is the source of truth. | You click something in the console and expect it to survive a GitOps sync. It will not. |
| ESXi host | **Worker node** | You think of nodes as long-lived, managed hosts. Nodes are cattle — they can be drained, replaced, or re-provisioned. |
| vCenter cluster | **OpenShift cluster** (Kubernetes + platform operators) | — |
| Resource pool / reservation | **Requests and limits**, **PriorityClasses**, **scheduling** | Resource pools are administrative hierarchy. Requests/limits are per-workload contracts with the scheduler. Entirely different model. |
| VM / template | **VirtualMachine** / **DataVolume** (Virt); **Deployment** + Pods (containers) | VM templates are static. Kubernetes manifests are declarative desired-state — the controller reconciles continuously, not at deploy-time only. |
| Port group / dvSwitch | **Cluster Network Operator (OVN-Kubernetes)**, **NAD** / **Multus** for additional interfaces ([NAD example](../../ocp/examples/network-attachment-definitions/README.md)) | NSX policy model does not map to Kubernetes NetworkPolicy model; relearn networking from the CNI up. |
| vSAN / VMFS / NFS datastore | **StorageClass**, **PV/PVC**, CSI drivers; Virt adds **DataVolumes** and **VolumeSnapshots** | Datastores are shared mounts. StorageClasses are dynamic provisioners — storage is requested per-workload, provisioned on demand. |
| DRS / HA rules | **Scheduling**, **PodAffinity/AntiAffinity**, **Pod disruption budgets** | DRS optimises existing placement. Kubernetes scheduler makes placement decisions at creation time. Anti-affinity rules are constraints, not post-hoc rebalancing. |
| vMotion / storage vMotion | **Live migration** (Virt), **drain/cordon** for nodes | — |
| Bulk VM migration from vSphere | **Migration Toolkit for Virtualization (MTV)** | — |
| Change ticket / CAB record | **Pull request** + **merge** — see the Git prerequisite section | This is the most important cultural reframe. See below. |

---

## Prerequisite: Git and GitHub

**Who needs this:** Anyone who has not used source control day to day. If you already commit and open PRs regularly, skim the "why" section and the CAB/change-ticket framing — even experienced Git users often miss why GitOps replaces their existing change-management process.

### Why Git — Infrastructure as Code

Before the mechanics, the reason. Git and GitOps are not just a new tool for doing what you already do. They are a different accountability and change management model. The principles matter as much as the commands.

**Infrastructure as Code** means infrastructure is defined in text files, stored in Git, reviewed before applying, and applied automatically when approved. The benefits are not abstract:

| Principle | What it replaces / improves |
|-----------|----------------------------|
| **Version control** | "Who changed this and when?" is answered by `git log`, not by asking around or trawling change tickets. |
| **Auditability** | Every change has an author, a timestamp, a diff, a PR discussion, and an approver. This is your audit trail. |
| **Accountability** | A merge commit to the production branch is a named, timestamped, peer-reviewed action. Drift from that state is detectable. |
| **Consistency** | The same manifest applied to dev, staging, and prod produces the same result. Snowflake configs are a Git diff, not a mystery. |
| **Speed and efficiency** | Approved changes apply automatically. No maintenance window required for config changes the team has already reviewed. |
| **Security and compliance** | Branch protection, required reviewers, CODEOWNERS, and signed commits are enforceable controls — comparable to CAB gates but with a full diff attached. |
| **Scalability** | One repo can drive hundreds of clusters. ClickOps does not scale. |
| **Declarative by nature** | You describe the desired state; the system reconciles. You stop writing runbooks for "how to apply this" and start writing manifests for "what this should be." |

### Git replaces (and improves on) your change management process

This is the reframe that matters most for VMware teams with mature change-management practices.

| Your current process | Git / GitOps equivalent |
|----------------------|-------------------------|
| Change ticket describing the change | **Pull request** — the change is the diff; the description is the PR body |
| CAB review / approval | **PR review** — named approvers, required reviewers enforced by branch protection |
| Approval record | **Merge commit** — named, timestamped, traceable to the PR and the approvers |
| Maintenance window | Not required for GitOps-managed config; rollback is `git revert` + merge |
| "Who changed this?" investigation | `git log`, `git blame`, PR history |
| Emergency change / break-glass | Emergency PR with post-hoc review; audit trail preserved |
| Rollback | `git revert` creates a new commit undoing the change — the history of both the change and the rollback is preserved |

Git does not eliminate governance. It makes governance faster, more traceable, and automated at the enforcement layer rather than the process layer.

### Mechanics (checklist)

| Topic | Why it matters for OpenShift / GitOps |
|-------|----------------------------------------|
| Install Git locally; `user.name` / `user.email` | Every commit is attributed; matches org policy and audit requirements. |
| **Clone**, **remote**, **fetch** vs **pull** | Argo CD reads from the remote; you need a reproducible local copy. |
| **Branch**, **commit**, **push** | Typical flow: feature branch → PR → merge to `main` / environment branch. |
| **Pull request** lifecycle | Where review and approval happen before Argo CD syncs config to the cluster. |
| **Diff** (`git diff`, IDE view) | You will compare YAML changes to cluster behavior constantly. |
| Org basics: **permissions**, **CODEOWNERS**, **branch protection** | You may not be able to push to `main`; that is correct and intentional. |
| Optional: **GitHub CLI** (`gh`) | Open PRs and check status from the terminal — useful when you live in `oc` shells. |

**Official starting points (free)**

- **[Git For Ages 4 And Up — Michael Schwern (linux.conf.au 2013)](https://www.youtube.com/watch?v=1ffBJ4sVUb4)** (~1h 40m) — the best single introduction to *how Git actually works*. Schwern teaches the inside-out mental model (objects → commits → labels → staging area → remotes) using physical props. He does not say "Git is like Subversion but better." He says throw out what you know and build the model from scratch — the same approach this path recommends for Kubernetes. Library entry: [`library/git-for-ages-4-and-up.md`](../../../library/git-for-ages-4-and-up.md).
- [GitHub Docs — Get started](https://docs.github.com/en/get-started) — account, repos, forks, clones, PRs. Follow after the Schwern talk.
- [Introduction to GitHub](https://skills.github.com/) (GitHub Skills) — short guided modules.
- [Pro Git book](https://git-scm.com/book/en/v2) (online) — Chapters 1–3 for internals; deeper chapters when you troubleshoot merges.

**Enterprise GitHub**

If your org uses SSO or SAML with GitHub Enterprise, complete IT's device / token onboarding *before* the verification below — tokens often require SSO authorization once before they work.

**Verification (scenario-based)**

- Clone a team repo (or disposable public template), create a branch, edit one line, commit, push, open a PR. Write a PR description as if it were a change ticket: what changed, why, what the risk is, how to verify.
- Explain out loud, without notes: what is the difference between a `git commit` (local history) and a `git push` (publish to remote)? What is the difference between `git pull` on your laptop and merging a PR on GitHub (review gates, approval record, audit trail)?
- Given a repo's `git log`, answer: who changed `deployment.yaml` two weeks ago, what did they change, and was it reviewed?

---

## Supplementary reading: Portworx "Demystifying Kubernetes for the VMware Admin"

Pure Storage / Portworx publishes a 10-part series (also bundled as an [ebook](https://portworx.com/resources/demystify-kubernetes-ebook-2026/)) aimed at VMware admins. **Use it as optional narrative reading, not as the canonical OpenShift syllabus** — Red Hat product documentation governs anything version-specific on OCP. Storage chapters reflect a vendor portfolio; compare against your org's chosen CSI driver and [OpenShift Storage docs](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/storage/index).

| Series theme | Read alongside |
|--------------|----------------|
| ClickOps → GitOps, forcing functions | Phase 0–1 (mindset); revisit in Phase 4 |
| ESXi / nodes, scheduling, control plane | Phase 0–1 |
| SDDC stack mapping (compute / storage / network) | Phase 1 (after you have run one app) |
| NSX → Kubernetes networking | Phase 1–2 |
| KubeVirt, VMware-to-Kubernetes migration | Phase 3 (before or parallel to MTV docs) |
| Day 2, security, migration planning | Phase 2–5 |

**Posts:** [ClickOps to GitOps](https://portworx.com/blog/paradigm-shift-from-clickops-to-gitops/) · [Mapping the stack](https://portworx.com/blog/mapping-the-stack-sddc-to-cloud-native/) · [ESXi vs nodes](https://portworx.com/blog/compute-esxi-hosts-vs-kubernetes-nodes/) · [NSX to K8s networking](https://portworx.com/blog/nsx-to-kubernetes-networking/) · [KubeVirt migration](https://portworx.com/blog/migrate-vmware-to-kubernetes-kubevirt/)

---

## Phase 1 — Kubernetes internals and OpenShift (1–2 weeks)

**Why this comes before VMs:** OpenShift Virtualization runs VMs as Pods. You cannot diagnose a stuck VM, a failed migration, a network connectivity problem, or a storage provisioning error without understanding Pods, namespaces, scheduling, and operators. This phase is not a detour — it is the foundation the VM layer sits on.

**Goal:** Read and reason about YAML; navigate the console and CLI; deploy a stateless app and diagnose it when it breaks. Build enough Kubernetes vocabulary that Phase 3's VM primitives are additive, not foreign.

**Topics**

- **Images, registries, Deployments, Services, Routes / Ingress, ConfigMaps, Secrets** — the objects that make up a running application
- **Namespaces / Projects**, **RBAC** — who can `oc get` what, and why that maps (imperfectly) to vCenter permissions
- **Operators** — how the platform extends itself; installed CRDs add new resource types the same way the VirtualMachine CRD adds VM support

**Official starting points**

- [OpenShift learning (Red Hat Developer)](https://developers.redhat.com/learn/openshift) — no-cost tutorials; use as the hub entry (URLs change).
- [An introduction to GitOps](https://www.redhat.com/en/blog/an-introduction-to-gitops) — read once here so Phase 4 does not feel disconnected.

**Formal course option (paid):** [DO180 — Containers, Kubernetes, and Red Hat OpenShift](https://www.redhat.com/en/services/training/do180-introduction-containers-kubernetes-red-hat-openshift)

**Verification (scenario-based)**

- Given a Deployment YAML you have not seen before: identify the image, replica count, exposed port, environment variables, and volume mounts — without help.
- Run a pod that fails due to a misconfiguration (wrong image tag, missing env var). Use `oc get pods`, `oc describe pod`, `oc logs`, and `oc get events` to diagnose the root cause and fix it. Do not use the console.
- Expose a running HTTP app with a Route; confirm it is reachable from outside the cluster with `curl`. Explain what the Route resource did and which operator manages it.

**This repo**

- [OpenShift useful commands](../../ocp/notes/openshift-useful-commands.md)

---

## Phase 2 — OpenShift cluster operations (admin lens) (2–4 weeks, parallel with Phase 1)

**Goal:** Understand how the platform assembles and governs itself — not to install production clusters alone on day one, but to recognize which component owns which configuration and what to look at when something is wrong.

**Topics**

- **Cluster operators** — the controllers that own the platform's own components; `oc get co` is the dashboard for platform health
- **MachineConfig / MachineConfigPool** — how node-level configuration is managed declaratively (and why you do not SSH into nodes to make changes)
- **Nodes**: cordon, drain, `oc get nodes`, node conditions — the equivalents of putting a host in maintenance mode
- **Authentication** (OAuth, identity providers) — enough to diagnose "I cannot log in" and understand who can do what
- **Monitoring and alerting** at a high level — where to look when the API or console is slow

**Official**

- [OpenShift Container Platform documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/) — bookmark **Operators**, **Nodes**, **Networking**, **Security and compliance**.

**Formal course option (paid):** [DO280 — OpenShift Administration II](https://www.redhat.com/en/services/training/Red-Hat-OpenShift-Administration-II-Operating-a-Production-Kubernetes-Cluster-DO280) (confirm current title on this page — Red Hat renames offerings).

**Verification (scenario-based)**

- Run `oc get co` in a lab cluster. Find one cluster operator that is not fully available or has a condition set. Using `oc describe`, `oc get events`, and the operator's own logs, write a one-paragraph explanation of what is wrong — even if you cannot fix it.
- Cordon a worker node, confirm existing pods are not evicted (just unschedulable), then drain it and confirm pods have moved. Uncordon. Explain what you would do differently in a production cluster with PodDisruptionBudgets set.

**This repo (when things break)**

- [OpenShift troubleshooting index](../../ocp/troubleshooting/README.md) — API slowness, CSR management, kube-controller-manager crashloops, namespace termination, and more.

---

## Phase 3 — OpenShift Virtualization (2–3 weeks)

**Goal:** Create, start, stop, and migrate VMs on Kubernetes; connect storage and networking; understand the KubeVirt primitives (`VirtualMachine`, `VirtualMachineInstance`, `DataVolume`) as Kubernetes resources — because that is what they are.

**Official**

- [About OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/virtualization/about-virt) — stay in the product docs until navigation feels natural.
- [Migrating virtual machines from VMware vSphere](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/migration_toolkit_for_virtualization/) — Migration Toolkit for Virtualization (MTV) for bulk import from vSphere.

**Blog / solution context**

- [Virtual machines as code with OpenShift GitOps and OpenShift Virtualization](https://cloud.redhat.com/blog/virtual-machines-as-code-with-openshift-gitops-and-openshift-virtualization)
- [Using RHACM and OpenShift GitOps to manage OpenShift Virtualization](https://www.redhat.com/en/blog/using-red-hat-advanced-cluster-management-and-openshift-gitops-to-manage-openshift-virtualization)

**Formal course options (paid)**

- [DO316 — Managing virtual machines with OpenShift Virtualization](https://www.redhat.com/en/services/training/do316-managing-virtual-machines-red-hat-openshift-virtualization) — broad VM-on-OCP operations.
- [DO156 — OpenShift Virtualization Administration I](https://www.redhat.com/en/services/training/do156-red-hat-openshift-virtualization-administration-i-operating-virtual-machines) and [DO256 — OpenShift Virtualization Administration II](https://www.redhat.com/en/services/training/do256-red-hat-openshift-virtualization-administration-ii-configuring-production-virtual-machines) — confirm prerequisites in the current catalog.

**Verification (scenario-based)**

- Create a VM from a template or YAML manifest. Console or SSH into the guest. Then: find the Pod that backs the VMI using `oc get pods`; describe it; confirm it is the same object Kubernetes is scheduling.
- **Live migration** *(requires multi-node cluster — not possible on SNO)*: Perform a live migration between two worker nodes. After migration, explain which Kubernetes mechanisms (pod scheduling, node affinity, resource availability) determined where the VM landed. If you only have SNO available: read the live migration documentation, trace the API objects involved (`VirtualMachineInstanceMigration`, source/target pods, shared storage requirement), and explain why SNO cannot support it — understanding the constraint is the learning outcome.
- Walk through one MTV planning chapter: source vSphere inventory requirements, network maps, storage maps, cutover concepts — even if you only migrate one small VM in lab.

**This repo**

- [KubeVirt VM stuck provisioning](../../ocp/troubleshooting/kubevirt-vm-stuck-provisioning/README.md) — a realistic failure involving webhooks, CSI, and snapshots.

---

## Phase 4 — GitOps with Argo CD (1–2 weeks)

**Goal:** Apply Git-as-change-management to cluster configuration. A PR merge replaces a change ticket. A `git revert` replaces an emergency rollback procedure. Argo CD (OpenShift GitOps) is the reconciliation engine that closes the loop between what is in Git and what is running in the cluster.

**Lab:** The [SNO KVM lab](../../ocp/examples/sno-kvm-lab/README.md) in this repo is sufficient for this entire phase — you need one cluster and a Git repo.

**Depends on:** [Prerequisite: Git and GitHub](#prerequisite-git-and-github).

**Topics**

- **OpenShift GitOps (Argo CD)**: Application, AppProject, sync policies, health checks, self-healing
- **ApplicationSet** — generate many Applications from a single template (by cluster label, by directory, by Git branch)
- **App-of-apps pattern** — a root Application that manages child Applications; the complete cluster inventory lives in Git
- **Configuration drift** — what Argo CD detects when cluster state diverges from Git; `selfHeal` vs manual sync
- **Sync options** — `Validate`, `CreateNamespace`, `RespectIgnoreDifferences`, retry strategies

**Official**

- [Understanding OpenShift GitOps](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/latest/html/understanding_openshift_gitops/index)
- [`redhat-cop/helm-charts` — operators-installer](https://github.com/redhat-cop/helm-charts/tree/main/charts/operators-installer) — community Helm chart for GitOps-driven operator installation; a useful pattern for team-owned operators

**This repo**

- [Argo CD examples](../../argo/examples/) and [Argo CD labs](../../argo/labs/README.md)

**Verification (scenario-based)**

- Create an Argo CD Application syncing from a Git repo. Make a change in Git (wrong replica count, incorrect image tag). Watch the cluster converge. Roll back by reverting the commit and watching the cluster follow.
- Introduce a deliberate drift — change a resource directly via `oc`, bypassing Git. Confirm Argo CD detects it and either alerts or remediates depending on your sync policy. Explain to a colleague what just happened and why the console change did not survive.
- Create an ApplicationSet that generates one Application per directory in a repo. Add a new directory. Confirm Argo CD creates the Application automatically.
- **Failure modes** (the questions that arrive in production): Introduce a broken manifest into Git — a YAML syntax error or a missing required field — and push it. What state does the Application enter? How do you identify the sync error without console access? How do you unblock it? Then: intentionally cause a health check failure (deploy a pod with a container that crashes on start). Distinguish `OutOfSync` (cluster state differs from Git) from `Degraded` (cluster state matches Git but the resource is unhealthy). Explain why Argo CD can report both simultaneously and what each requires from the operator.

---

## Fleet thinking — the second mental model shift

Phase 0 required you to throw out the VMware mental model and rebuild from Kubernetes up. Phase 5 requires a second rebuild: from *single-cluster operator* to *fleet operator*. The instincts that served you well in Phases 1–4 become liabilities at fleet scale if you don't name them.

In single-cluster thinking, your job is: configure this cluster, fix this problem, deploy this workload. In fleet thinking, your job is: define what *every* cluster should look like, detect when any cluster drifts from that definition, and push corrections declaratively — without logging into each one.

| Single-cluster instinct | Fleet-operator reframe |
|-------------------------|----------------------|
| "I'll fix this cluster" | "I'll fix the policy and let ACM apply it everywhere" |
| "Who changed that?" | "Which commit changed the policy? Which clusters are now non-compliant?" |
| "I'll deploy this operator" | "All clusters labelled `virt=enabled` should have the Virt operator — I'll write a policy for that" |
| Console change, then document it | Console is a read/observe tool; Git is the change record for the fleet |

Returning to single-cluster habits at fleet scale is how teams end up with configuration drift they cannot explain and compliance posture they cannot prove.

---

## Phase 5 — Fleet management with ACM (2–3 weeks)

**Goal:** Operate a fleet of clusters declaratively. ACM (Red Hat Advanced Cluster Management) is the governance and policy layer that makes consistency across many clusters tractable. Argo CD handles reconciliation; ACM handles targeting, compliance reporting, and enforcement. This phase requires a hub cluster and at least one managed cluster — the single-node lab is not sufficient.

**Lab setup:** You need a hub cluster with ACM and OpenShift GitOps installed, and at least one additional managed cluster enrolled. A second SNO on KVM, a cloud trial cluster, or a workshop environment all work.

**When ACM earns its keep:** At 3+ clusters you will feel configuration drift within weeks without it. Policy consistency — everyone running the same OAuth config, the same kubelet settings, the same Virt operator version — becomes a manual problem that scales with cluster count. ACM solves this declaratively.

**Architecture — hub-and-spoke:**

```
Git repository
     │
     ▼
Hub cluster (ACM + Argo CD)
     ├── Managed cluster A  ← policies + ApplicationSets
     ├── Managed cluster B
     └── Managed cluster C (OCP Virt workloads)
```

**Topics**

- **Cluster lifecycle with ACM** — importing clusters, labeling for policy targeting, viewing fleet compliance status
- **ACM PolicyGenerator** — converts YAML manifests into RHACM policies via a kustomize plugin; the primary tool for fleet-wide config
- **ACM Placements and PlacementBindings** — label-based targeting: which policy applies to which clusters
- **`inform` vs `enforce`** — inform detects and reports non-compliance without changing anything; enforce remediates automatically
- **`PolicyAutomation`** — the ACM object that links a policy compliance event to an AAP job; when a policy goes non-compliant ACM calls a specific AAP workflow; used for Day 2 tasks, ServiceNow tickets, PagerDuty alerts, or anything AAP can reach outside Kubernetes
- **Ansible + ACM bridge pattern** — teams with existing Ansible investment do not need to discard it; AAP generates Kubernetes CRs using Jinja templates (which can query Redfish, Vault, DNS); ACM deploys; ACM policies trigger AAP post-provisioning jobs via `PolicyAutomation`; the pipeline is fully idempotent
- **Secret management** — keeping sensitive data out of Git; External Secrets Operator (ESO) with a Vault back end; prerequisite for Phase 6 ZTP

**Key decision: Argo CD Application vs ACM Policy**

You now know both tools. This is the question practitioners get wrong most often — both can install an operator or deploy a config, but the choice is about *ownership, enforcement, and compliance posture*.

| Signal | Use Argo CD (e.g. operators-installer Helm chart) | Use ACM Policy |
|--------|--------------------------------------------------|----------------|
| Who decides this exists? | A team — they own the operator for their workloads | Platform mandate — all clusters of type X must have this |
| What if it goes missing? | The workload breaks; team notices and fixes it | Compliance violation — platform team must know immediately |
| Enforcement required? | No — Argo CD reconciliation is sufficient | Yes — drift must be detected, optionally auto-corrected |
| Environment variation? | Yes — dev uses `alpha` channel, prod uses `stable` | No — the same baseline everywhere |
| Audit trail needed? | Git log + PR history | ACM compliance dashboard + policy report + Git log |
| Cluster lifecycle stage | Day 2 workload deployment | Day 1 bootstrap or organizational baseline |

*Use ACM Policy for:* NMState, cert-manager, OpenShift Virtualization operator, file-integrity-operator, OAuth, kubelet config, kubeadmin removal, pull secret distribution — platform mandates that must not drift.

*Use Argo CD / operators-installer for:* Team-owned operators (Strimzi, app-specific monitoring stacks) that vary by environment or team ownership.

**When the table gives conflicting signals — the grey zone**

The table breaks when a requirement triggers multiple columns simultaneously. The most common case: a platform mandate (→ ACM Policy) on a heterogeneous fleet where different clusters need different operator versions (→ Argo CD). Example: NMState must be on every Virt cluster, but OCP 4.16 clusters need NMState channel `stable-4.16` and OCP 4.18 clusters need `stable-4.18`.

The resolution is **ACM policy templating**, not a switch to Argo CD. ACM policies support Go-template-style variable substitution against cluster labels and hub cluster facts. You write one policy that evaluates the target cluster's OCP version label and selects the correct channel at enforcement time — the mandate stays in ACM, the variation is handled within the policy rather than by routing to a different tool.

```yaml
# Policy template using cluster label for channel selection
spec:
  object-templates:
    - complianceType: musthave
      objectDefinition:
        apiVersion: operators.coreos.com/v1alpha1
        kind: Subscription
        spec:
          channel: '{{ fromClusterClaim "openshiftVersion" | splitList "." | first | printf "stable-4.%s" }}'
```

When a mandate genuinely cannot be expressed as a policy template — for example, the configuration is too complex, varies by team rather than by cluster type, or is owned by a team that should not have ACM access — that is the signal to reach for Argo CD, even for something that looks like a platform concern. The deciding factor is always: *who owns this, and does deviation represent a compliance violation or a team preference?*

**The hybrid pattern:** ACM and Argo CD are complementary layers. A common production pattern uses ACM to *deliver* an Argo CD ApplicationSet to every managed cluster — ACM ensures the ApplicationSet object exists, Argo CD reconciles the workload content. Fleet-wide targeting plus application-level reconciliation in one pipeline.

**Official**

- [GitOps with ACM](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/gitops/gitops-overview) — ACM + Argo CD integration; hub-managed ApplicationSets; subscription-based GitOps
- [ACM governance](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/governance/governance) — policy concepts, PlacementRules, compliance status
- [PolicyGenerator integration](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.11/html/governance/integrate-policy-generator) — the kustomize generator plugin

**Blog and reference**

- [GitOps approach to configure OpenShift clusters managed by RHACM](https://www.redhat.com/en/blog/gitops-approach-to-configure-openshift-clusters-managed-by-red-hat-advanced-cluster-management-for-kubernetes) — policy templating, PolicyGenerator, and drift detection end-to-end
- [How to manage a fleet of heterogeneous OpenShift clusters](https://developers.redhat.com/articles/2024/03/18/how-manage-fleet-heterogeneous-openshift-clusters) — real-world fleet management across different OCP versions and regions
- [Leveraging ApplicationSets and Helm with cluster labels in RHACM](https://developers.redhat.com/articles/2025/08/27/leveraging-applicationsets-helm-cluster-labels) — label-driven targeting for differentiated deployments
- [Automate OpenShift Cluster Deployment with RHACM and AAP (DevConf.US 2024)](https://www.youtube.com/watch?v=mi1z5H4VL3Q) — 31-minute practitioner talk; real customer engagement (hundreds of clusters, two-week deadline); shows `PolicyAutomation`, the Ansible+ACM bridge pattern, blue-green cluster upgrades, and disconnected environment operation. Library entry: [`library/automate-ocp-cluster-deployment-rhacm-aap.md`](../../../library/automate-ocp-cluster-deployment-rhacm-aap.md)
- [Implement zero-touch provisioning for OpenShift with GitOps](https://developers.redhat.com/articles/2025/07/29/implement-zero-touch-provisioning-openshift-gitops) — read **Policy management** and **Best practices** now; return for ZTP Day 1 content in Phase 6

**Formal course option (paid)**

- [DO480 — Multicluster Management with Red Hat OpenShift Platform Plus](https://www.redhat.com/en/services/training/do480-multicluster-management-red-hat-openshift-platform-plus) — ACM, policy management, RHACS, Quay; requires DO280 and DO380. Preparation for EX480.

**This repo**

- [RHACM examples](../../rhacm/examples/) — secret management, cluster import, GitOps integration

**Verification (scenario-based)**

- Import a second cluster into ACM. Label it. Write a PolicyGenerator manifest that enforces a configuration (an RBAC policy or alertmanager rule) on clusters matching that label. Confirm compliance status in the ACM console. Switch `remediationAction` from `inform` to `enforce` and observe the difference.
- Explain the fleet compliance model without notes: what does "non-compliant" mean in ACM? Who is notified? How does a remediation policy differ from a monitoring policy?
- Given this scenario: install the OpenShift Virtualization operator on all production clusters (platform mandate), and install the Strimzi operator only on clusters owned by a specific team. Argue which tool you use for each and why. What changes if the Virt operator install becomes a regulatory compliance requirement?

---

## Phase 6 — Zero Touch Provisioning: Day 0 / Day 1 / Day 2 automation *(Advanced — large-scale environments)*

> **Who this phase is for:** Teams managing **50 or more clusters**, particularly at remote or edge sites where manual cluster installation is not operationally viable. This is the pattern used in large retail, utility, and telecommunications deployments. If you are managing a fleet of 3–20 clusters in a data centre, Phase 5 (ACM) is likely sufficient — come back here when cluster count or geographic distribution makes individual cluster provisioning a bottleneck. A dedicated learning path for ZTP at scale is planned in [`devops/learning-path/`](../README.md).

**Goal:** Automate the complete cluster lifecycle — from bare metal preparation through installation and into ongoing Day 2 operations — using the GitOps ZTP pipeline. This is where the Git-as-change-management model, ACM policies, and Argo CD converge into a fully automated provisioning and upgrade system.

**Depends on:** Phases 0–5 fully completed, including ACM fleet management. ZTP makes no sense without understanding Pods, operators, ACM policy, and Argo CD Applications — all of which it uses internally.

**Day 0 / Day 1 / Day 2 — the operations framework**

ZTP is organized around this three-day model, which you will encounter throughout Red Hat documentation for edge and large-scale deployments:

| Day | What it covers | ZTP component |
|-----|---------------|--------------|
| **Day 0** | Pre-installation: network config, bare metal preparation, health checks | ClusterCurator + Ansible Automation Platform hooks |
| **Day 1** | Cluster installation and initial provisioning | SiteConfig, AgentClusterInstall, infraenv, Assisted Installer |
| **Day 2** | Post-installation: config management, upgrades, compliance, scaling | PolicyGenTemplate, TALM, ClusterGroupUpgrade |

Most VMware admins joining an existing OCP team land in **Day 2** operations first — clusters already exist. ZTP adds Day 0 and Day 1 automation on top of the Day 2 skills built in Phases 1–4.

**The ZTP pipeline — what it is**

ZTP (Zero Touch Provisioning) is a GitOps-driven pipeline that provisions and configures OpenShift clusters on bare metal without human intervention after the initial Git commit. The pipeline is:

```
Git commit (SiteConfig / PolicyGenTemplate)
     │
     ▼
Argo CD (on hub) detects change → applies CRs to ACM
     │
     ▼
ACM + Assisted Installer provisions the cluster (Day 1)
     │
     ▼
TALM operator applies Day 2 policies via ClusterGroupUpgrade
     │
     ▼
Managed cluster: running, compliant, GitOps-managed
```

**Day 0 — pre-installation automation**

Before a cluster is installed, ZTP allows automation of infrastructure preparation via **ClusterCurator** and **Ansible Automation Platform (AAP)**:

- Network configuration automation
- Bare metal host preparation and health checks
- Prerequisite verification (storage, firmware, connectivity)

```yaml
# ClusterCurator pre/post hooks — runs AAP jobs at install/upgrade events
spec:
  install:
    towerAuthSecret: aap-integrations
    prehook:
      - name: Pre-Installation Check
        extra_vars:
          check_network: true
          check_storage: true
    posthook:
      - name: Post-Installation Validation
        extra_vars:
          validate_operators: true
```

**Day 1 — cluster provisioning (SiteConfig)**

The `SiteConfig` (or equivalent `AgentClusterInstall` / `ClusterDeployment` manifests) defines the cluster topology and is committed to Git. Argo CD picks it up; ACM and the Assisted Installer provision the cluster. Key Day 1 files:

```
cluster-name/
├── day1-agentclusterinstall.yaml   # Cluster topology (nodes, networking)
├── day1-bmh.yaml                   # BareMetalHost definitions
├── day1-clusterdeployment.yaml     # Cluster deployment
├── day1-infraenv.yaml              # Discovery ISO / agent environment
├── day1-managedcluster.yaml        # ACM managed cluster enrollment
├── day1-nmstateconfig.yaml         # Node network configuration
└── kustomization.yaml
```

An `ApplicationSet` on the hub automatically creates an Argo CD Application for each cluster directory found in Git — new cluster = new directory = automated provisioning triggered.

**Day 2 — policy-driven configuration and upgrades (PolicyGenTemplate / TALM)**

After installation, Day 2 configuration is applied via **PolicyGenTemplate** (PGT) — a ZTP-specific generator that produces RHACM policies from concise YAML, then applies them through the **Topology Aware Lifecycle Manager (TALM)** operator.

Cluster upgrades follow the same GitOps pattern: update the desired version in Git, commit, and Argo CD + ACM + TALM handle the rest:

```yaml
# PolicyGenTemplate — cluster upgrade via Git commit
spec:
  bindingRules:
    name: "cluster-name"
  sourceFiles:
    - fileName: ClusterVersion.yaml
      policyName: "platform-upgrade"
      spec:
        channel: "stable-4.16"
        desiredUpdate:
          version: 4.16.8
```

TALM creates a **ClusterGroupUpgrade (CGU)** object that orchestrates the rollout — controlling concurrency, canary clusters, and timeout. Reference: [Leveraging the GitOps ZTP pipeline to upgrade OpenShift clusters](https://www.redhat.com/en/blog/leveraging-gitops-ztp-pipeline-upgrade-red-hat-openshift-clusters).

**Upgrade strategy — choosing the right model for your hardware**

In-place upgrades via TALM and blue-green replacement are not mutually exclusive across a fleet — the right choice depends on available hardware and workload mobility. Use this to reason through your situation:

| Scenario | Recommended approach |
|----------|----------------------|
| **Bare metal, no spare capacity** — SNO fleet where every node is a production site | TALM in-place with canary waves. `maxConcurrency` limits blast radius; `timeout` auto-aborts per CGU. Designate one SNO per region/type as the canary for each wave. |
| **Bare metal, small spare pool (5–10%)** | Serial blue-green with hardware rotation: provision new cluster on spares, migrate workloads from site N, return site N's hardware to the spare pool. Repeat. Cost: one cluster's worth of spare hardware, not the full fleet. |
| **Virtualized control planes** | Partial blue-green: provision new control plane VMs at the target version, drain and re-join existing physical worker nodes. Workers never leave the hardware — only the control plane layer is replaced. Hardware overhead is three control plane VMs, not a full parallel cluster. |
| **Any environment with a fast provisioning pipeline** | Full blue-green: provision parallel cluster, migrate workloads, decommission old cluster. The DevConf.US 2024 talk describes moving from 4-hour serial deployments to 5 clusters in 40 minutes, making this viable. Requires spare capacity during the transition and a mature workload migration process. |

**TALM canary wave pattern — the primary bare metal approach:**

```yaml
# ClusterGroupUpgrade — canary first, then production in batches of 5
apiVersion: ran.openshift.io/v1alpha1
kind: ClusterGroupUpgrade
spec:
  remediationStrategy:
    maxConcurrency: 5
    timeout: 240             # minutes; abort and mark failed after 4h
  managedPolicies:
    - platform-upgrade-prep
    - platform-upgrade
  clusters:                  # canary sites — upgraded first
    - canary-site-region-1
    - canary-site-region-2
  clusterSelector:
    - env=production         # remaining production sites follow
```

Validate canaries before expanding the CGU to the full fleet. For SNO specifically: because there is no in-cluster redundancy, canary designation is the primary risk control — pick representative sites that can tolerate a failed upgrade window without customer impact.

**Secret management in ZTP — External Secrets Operator**

Never store sensitive data in Git. ZTP environments use the **External Secrets Operator (ESO)** to pull secrets from a vault (HashiCorp Vault, AWS Secrets Manager, or similar) at runtime:

- `SecretStore`: defines the connection to the vault back end
- `ExternalSecret`: maps vault paths to Kubernetes Secrets in the cluster

Secrets managed this way include: pull secrets, BMH credentials, ingress certificates, Htpasswd auth, and ACM communication tokens.

**Recommended policy folder structure**

```
policies/
├── Global/
│   ├── base-config/          # chrony, custom CA, kubelet, SSH keys
│   ├── day2-config/          # alertmanager, ingress certs, storage class
│   ├── security-auth/        # OAuth, remove kubeadmin, RBAC
│   ├── secrets-config/       # External Secrets, SecretStore
│   └── testing/
│       └── virtualizations/
│           ├── policy-install-mtv.yaml           # Migration Toolkit
│           ├── policy-install-nmstate.yaml        # NMState operator
│           └── policy-install-virtualization.yaml # OpenShift Virt
└── Hub/
    ├── policy-clusterlogging.yaml
    └── policy-storagecluster.yaml
```

**Official and reference reading**

- [Challenges of the network far edge and ZTP overview (OCP 4.19)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/edge_computing/ztp-deploying-far-edge-clusters-at-scale) — start here; covers the overall ZTP architecture, hub setup, and the SiteConfig / PolicyGenTemplate pipeline
- [Updating GitOps ZTP (OCP 4.19)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/edge_computing/ztp-updating-gitops) — Day 1 and Day 2 pipeline update procedures including TALM integration
- [TALM (Topology Aware Lifecycle Manager) for cluster updates](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/edge_computing/cnf-talm-for-cluster-updates) — ClusterGroupUpgrade, canary clusters, batch rollout, timeout strategies
- [Implement zero-touch provisioning for OpenShift with GitOps](https://developers.redhat.com/articles/2025/07/29/implement-zero-touch-provisioning-openshift-gitops) — full ZTP walkthrough including OpenShift Virtualization integration, ESO, AAP hooks, ApplicationSet patterns
- [Leveraging the GitOps ZTP pipeline to upgrade OpenShift clusters](https://www.redhat.com/en/blog/leveraging-gitops-ztp-pipeline-upgrade-red-hat-openshift-clusters) — practical upgrade workflow: PolicyGenTemplate → Argo CD → ACM → TALM → CGU → cluster

**Verification (scenario-based)**

- Commit a new `SiteConfig` directory to the ZTP Git repo and watch the hub's Argo CD detect it. Trace the chain: ApplicationSet → Application → ACM ManagedCluster CR → Assisted Installer. Even if you cannot run a full installation to completion in lab, map the objects and understand which component is responsible for each step.
- Write a `PolicyGenTemplate` that installs the OpenShift Virtualization operator on all clusters labeled `virt=enabled`. Apply it through TALM via a `ClusterGroupUpgrade` object. Confirm the operator appears on the managed cluster.
- Given a ZTP upgrade workflow: a new version is committed to Git. Trace every step from `git push` to `oc adm upgrade` completing on the managed cluster. Name the component responsible at each step: Argo CD → ACM → PolicyGenTemplate → TALM → CGU → ClusterVersion operator.
- Walk through the ESO secret flow: where does the secret live? How does ESO authenticate to the vault? When does the Kubernetes Secret appear on the managed cluster?

---

## Phase 7 — Certification (optional)

| Exam | After which phase | Notes |
|------|------------------|-------|
| [EX280 — Red Hat Certified OpenShift Administrator](https://www.redhat.com/en/services/training/ex280-red-hat-certified-openshift-administrator-exam) | Phase 2 depth | Core cluster admin skills |
| [EX480 — Red Hat Certified Specialist in MultiCluster Management](https://www.redhat.com/en/services/training/ex480-red-hat-certified-specialist-multicluster-management-exam) | Phase 5 depth | ACM, policy management, fleet governance; prepare with DO480 |

Virt-focused exams follow product announcements — check [Red Hat Certification](https://www.redhat.com/en/services/certifications) for current names and prerequisites.

---

## Maintaining this path

- Add internal runbook links or org-specific standards under each phase as they develop.
- When Red Hat renumbers courses, update **Formal course option** lines only — keep phases and verification stable.
- OpenShift GitOps docs live under `red_hat_openshift_gitops` on docs.redhat.com, not the older `openshift_gitops` path.
- Third-party URLs (Portworx blog, ebook) change when campaigns refresh — spot-check periodically.
- **GitHub** UI and GitHub Skills URLs move — refresh the prerequisite section when onboarding feedback reports broken links.
- **ZTP tooling evolves rapidly** — `PolicyGenTemplate` (PGT) is the current generator; `SiteConfig` v1/v2 naming has changed across OCP releases. Verify against the installed `ztp-site-generate` image version, not doc screenshots.
- ACM policy API (`policy.open-cluster-management.io`) version and `PolicyGenerator` kustomize plugin version can drift from OCP releases — check the ACM release notes when upgrading the hub.

---

**Document:** Learning path v1.9 · Last updated 2026-04-29 (Phase 3 live migration lab caveat; Phase 1/2 parallel clarified; fleet thinking at Phase 4/5 bridge; Phase 4 failure-mode verification; ACM policy templating grey zone; Portworx reference corrected; PolicyAutomation + Ansible bridge pattern added to Phase 5; blue-green cluster upgrade model added to Phase 6; DevConf.US 2024 RHACM+AAP talk added to library and Phase 5).

*AI-assisted content. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for review status details.*

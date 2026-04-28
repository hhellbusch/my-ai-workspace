# Learning path: VMware admin → Kubernetes, OpenShift, and OpenShift Virtualization

**Audience:** Infrastructure and platform engineers who already know vSphere — across storage, networking, and compute/VM management — and want to operate **OpenShift (OCP)** and **OpenShift Virtualization** confidently. Application development is not the primary goal; understanding Kubernetes deeply enough to administer the platform is.

**Outcomes:** Understand Kubernetes internals well enough to reason about cluster state; use `oc` and `kubectl`; operate networking and storage at a platform level; run and migrate VMs with OpenShift Virtualization; use Git and GitHub as an accountability and change management system; understand why GitOps replaces ClickOps and how it maps to your existing change-management practices.

**Disclaimer:** This is a curated study guide, not Red Hat training, certification prep, or support. Official product behavior, course numbers, and doc URLs change — verify against [Red Hat Documentation](https://docs.redhat.com/) and your subscription entitlements before production decisions. *Red Hat*, *OpenShift*, and related marks are trademarks of Red Hat, Inc. *Portworx* and *Pure Storage* content is third-party; see the supplementary section for scope.

---

## How to use this path

1. **Start fresh.** See Phase 0. The biggest obstacle is not a missing skill — it is a mental model that needs to be rebuilt, not extended.
2. If you are **new to Git**, complete the **[Prerequisite: Git and GitHub](#prerequisite-git-and-github)** section before Phase 4 (GitOps); doing it before Phase 1 makes lab and "edit YAML in repo" workflows much easier.
3. Work **in order** through Phases 0–3 before deep-diving on Virt. OpenShift Virtualization runs on top of Kubernetes; understanding the substrate first is not optional — it is the difference between operating the platform and cargo-culting commands.
4. Each phase has **verification** — scenario-based, not definition-recall. If you cannot do the check without notes, that phase is not done.
5. Pair **reading** with a **single lab cluster** (workshop, cloud trial, or home lab) so every concept maps to something you can inspect in the console **or** from the CLI.

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
| Day 2, security, migration planning | Phase 2–4 |

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
- Perform a live migration between two worker nodes. After migration, explain which Kubernetes mechanisms (pod scheduling, node affinity, resource availability) determined where the VM landed.
- Walk through one MTV planning chapter: source vSphere inventory requirements, network maps, storage maps, cutover concepts — even if you only migrate one small VM in lab.

**This repo**

- [KubeVirt VM stuck provisioning](../../ocp/troubleshooting/kubevirt-vm-stuck-provisioning/README.md) — a realistic failure involving webhooks, CSI, and snapshots.

---

## Phase 4 — GitOps and multicluster (1–2 weeks to first value; ongoing)

**Goal:** Apply what you learned about Git-as-change-management to cluster configuration. A PR merge replaces a change ticket. A Git revert replaces an emergency rollback procedure. Argo CD is the reconciliation engine that closes the loop between what is in Git and what is running in the cluster.

**Depends on:** [Prerequisite: Git and GitHub](#prerequisite-git-and-github) (or equivalent experience).

**Topics**

- **OpenShift GitOps** (Argo CD): Application, AppProject, sync policies, health checks
- **App-of-apps pattern** — managing many applications declaratively from a single root Application
- Optional: **RHACM** for fleet-wide policy and GitOps at scale across many clusters

**Official**

- [Understanding OpenShift GitOps](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/latest/html/understanding_openshift_gitops/index)
- [GitOps overview (RHACM)](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html/gitops/gitops-overview) if multicluster is in scope.

**This repo**

- [Argo CD examples](../../argo/examples/) and [Argo CD labs](../../argo/labs/README.md)

**Verification (scenario-based)**

- Create an Argo CD Application syncing from a Git repo. Make a change to a manifest in Git (wrong replica count, incorrect image tag). Watch the cluster converge — or detect the error in Argo CD's health status. Roll back by reverting the commit in Git and watching the cluster follow.
- Explain to a colleague: "If someone makes a change directly in the OpenShift console instead of through Git, what happens?" (Answer: Argo CD detects drift and either alerts or auto-remediates, depending on sync policy. The console change is not the source of truth.)

---

## Phase 5 — Certification (optional)

**Red Hat Certified OpenShift Administrator (EX280)** after Phase 2 depth. Virt-focused exams follow product announcements — check [Red Hat Certification](https://www.redhat.com/en/services/certifications) for current names and prerequisites.

---

## Maintaining this path

- Add internal runbook links or org-specific standards under each phase as they develop.
- When Red Hat renumbers courses, update **Formal course option** lines only — keep phases and verification stable.
- OpenShift GitOps docs live under `red_hat_openshift_gitops` on docs.redhat.com, not the older `openshift_gitops` path.
- Third-party URLs (Portworx blog, ebook) change when campaigns refresh — spot-check periodically.
- **GitHub** UI and GitHub Skills URLs move — refresh the prerequisite section when onboarding feedback reports broken links.

---

**Document:** Learning path v1.2 · Last updated 2026-04-28 (Phase 0 reframe; analogy table with discard column; IaC / CAB–PR framing; scenario-based verification throughout).

*AI-assisted content. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for review status details.*

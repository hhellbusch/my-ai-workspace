# Learning path: VMware admin → Kubernetes, OpenShift, and OpenShift Virtualization

**Audience:** Infrastructure and platform engineers who already know vSphere — across storage, networking, and compute/VM management — and want to operate **OpenShift (OCP)** and **OpenShift Virtualization** confidently. Application development is not the primary goal; understanding Kubernetes deeply enough to administer the platform — and to automate its full lifecycle — is.

**Outcomes:** Understand Kubernetes internals well enough to reason about cluster state; use `oc` and `kubectl`; operate networking (OVN-Kubernetes, Multus, NAD, MetalLB, NMState, SR-IOV) and storage (StorageClass, PVC, ODF, DataVolume, VolumeSnapshot) at a platform level; run and migrate VMs with OpenShift Virtualization; back up and recover clusters with etcd backup and OADP; use Git as an accountability and change management system, including structured GitOps repo layout and secrets handling; diagnose SCCs, OLM failures, and Argo CD sync errors. At fleet scale: manage configuration and compliance across many clusters with ACM and, for very large environments, automate the full cluster lifecycle with the ZTP GitOps pipeline. In disconnected environments: mirror images and operator catalogs, configure IDMS, and operate OperatorHub without internet access.

**Scale and topology — which phases apply to you**

Most teams do not run a single cluster in production. Whether you are managing ten clusters across two data centres or two hundred edge sites, the operational model changes when you add more clusters. Use this as a guide to which phases are relevant:

| Environment | Typical cluster count | Recommended phases | Lab requirement |
|-------------|----------------------|-------------------|----------------|
| Getting started / single cluster | 1–2 | 0–4 + Git prerequisite | Single cluster (SNO lab in this repo) |
| Small fleet | 3–10 | 0–5 | Hub cluster + ≥1 managed cluster |
| Medium fleet | 10–50 | 0–5, ACM required | Hub cluster + managed clusters |
| Large / edge fleet | 50–200+ | 0–5 + ZTP specialist track | Hub + bare metal / simulated nodes |

ACM is not required to get value from this path. Phases 0–4 stand alone with the existing lab. Phase 5 (fleet management) and Phase 6 (ZTP) require additional infrastructure.

**Disclaimer:** This is a curated study guide, not Red Hat training, certification prep, or support. Official product behavior, course numbers, and doc URLs change — verify against [Red Hat Documentation](https://docs.redhat.com/) and your subscription entitlements before production decisions. *Red Hat*, *OpenShift*, and related marks are trademarks of Red Hat, Inc. *Portworx* and *Pure Storage* content is third-party; see the supplementary section for scope.

---

## How to use this path

1. **Start fresh.** See Phase 0. The biggest obstacle is not a missing skill — it is a mental model that needs to be rebuilt, not extended.
2. If you are **new to Git**, complete the **[Prerequisite: Git](#prerequisite-git)** section before Phase 4; doing it before Phase 1 makes lab and "edit YAML in repo" workflows much easier.
3. **Phases 1 and 2 can run in parallel** — Phase 1 covers application-layer Kubernetes (Pods, Deployments, Services); Phase 2 covers cluster-level operations (cluster operators, MachineConfig, node management). They are distinct enough that an experienced infrastructure engineer can move through both simultaneously. **Both must be substantially complete before Phase 3.** OpenShift Virtualization runs on top of Kubernetes; understanding the substrate first is not optional.
4. Each phase has **verification** — scenario-based, not definition-recall. If you cannot do the check without notes, that phase is not done.
5. Pair **reading** with a **single lab cluster** (workshop, cloud trial, or home lab) so every concept maps to something you can inspect in the console **or** from the CLI. Note the lab requirements per phase in the scale table above — Phases 5 and 6 need infrastructure beyond a single SNO.

**Lab options in this repo**

- [SNO on KVM lab setup](../../ocp/examples/sno-kvm-lab/README.md) — single-node OpenShift for local practice.
- [Argo CD labs](../../argo/labs/README.md) — GitOps exercises (after you are comfortable with namespaces and manifests).
- [OCP command notes](../../ocp/notes/openshift-useful-commands.md) — day-to-day `oc` / `kubectl` patterns.

---

## Phase 0 — Start fresh: OCP is a Kubernetes platform (½–1 day)

**The core mental shift before anything else:**

> **OpenShift is a Kubernetes platform. OpenShift Virtualization is a Kubernetes add-on that runs VMs inside Kubernetes. The substrate is Kubernetes — not a hypervisor.**

VMware teams most often struggle with treating OCP as "vSphere with containers bolted on." It is the inverse: a container orchestration platform with virtual machine support bolted on. If you build your mental model starting from vCenter and map Kubernetes onto it, that model breaks at the first upgrade, the first failing pod, the first time a node drains. If you build your mental model starting from Kubernetes and then add VMs to that picture, you can reason about the whole system.

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

Use this as a **temporary scaffold only**. The right column is the destination; the left column is where you are starting.

**Expiry notice:** If you are still consulting this table after completing Phase 2, that is the signal. The analogy has done its job — stop reaching for it and read the cluster state directly. Several rows below break *before* Phase 2 is complete; those are marked explicitly.

| VMware concept | OpenShift / Kubernetes analogue | Discard or reframe when… |
|----------------|----------------------------------|--------------------------|
| vCenter UI / web client | **OpenShift Console** — a read/observe tool, not the source of truth. Git is the source of truth. | **Breaks immediately in Phase 4.** You click something in the console and expect it to survive a GitOps sync. It will not. |
| ESXi host | **Worker node** | **Breaks in Phase 1.** You think of nodes as long-lived, managed hosts. Nodes are cattle — they can be drained, replaced, or re-provisioned without data loss because state lives in PVCs, not on the node. |
| vCenter cluster | **OpenShift cluster** (Kubernetes + platform operators) | Reasonable scaffold; revisit when you manage multiple clusters (Phase 5) — a "cluster" is now a unit in a fleet, not the top of the hierarchy. |
| Resource pool / reservation | **Requests and limits**, **PriorityClasses**, **scheduling** | **Breaks in Phase 1.** Resource pools are administrative hierarchy. Requests/limits are per-workload contracts with the scheduler — an entirely different model with no concept of pool membership. |
| VM / template | **VirtualMachine** / **DataVolume** (Virt); **Deployment** + Pods (containers) | **Breaks in Phase 1–2.** VM templates are static artifacts applied once. Kubernetes manifests are desired-state — the controller reconciles continuously, and divergence from the manifest is automatically corrected. |
| Port group / dvSwitch | **Cluster Network Operator (OVN-Kubernetes)**, **NAD** / **Multus** for additional interfaces ([NAD example](../../ocp/examples/network-attachment-definitions/README.md)) | **Breaks in the networking deep dive.** NSX policy model does not map to Kubernetes NetworkPolicy; relearn from the CNI up. The analogy will mislead you in any non-trivial networking scenario. |
| vSAN / VMFS / NFS datastore | **StorageClass**, **PV/PVC**, CSI drivers; Virt adds **DataVolumes** and **VolumeSnapshots** | **Breaks in the storage deep dive.** Datastores are shared mounts you manage. StorageClasses are dynamic provisioners — storage is requested per-workload, provisioned on demand, and the workload does not know where it lives. |
| DRS / HA rules | **Scheduling**, **PodAffinity/AntiAffinity**, **Pod disruption budgets** | **Breaks in Phase 1.** DRS optimises existing placement post-hoc. The Kubernetes scheduler makes placement decisions at creation time; anti-affinity rules are constraints, not rebalancing triggers. |
| vMotion / storage vMotion | **Live migration** (Virt), **drain/cordon** for nodes | Reasonable analogy for the outcome; the mechanism is entirely different (see Phase 3 and the storage deep dive). |
| Bulk VM migration from vSphere | **Migration Toolkit for Virtualization (MTV)** | — |
| Change ticket / CAB record | **Pull request** + **merge** — see the Git prerequisite section | **Most important cultural reframe — and the slowest to complete.** The mechanics transfer; the cultural habits do not. See the Git section below. |

---

## Prerequisite: Git

**Who needs this:** Anyone who has not used source control day to day. If you already commit and open PRs regularly, skim the change-management reframe below — even experienced Git users often miss why GitOps replaces their existing CAB process.

**Full path:** See the dedicated **[Git, GitHub, and GitLab Learning Path](../git/README.md)** for the complete staged curriculum (mental model → hands-on basics → internals).

### The one reframe that matters before you start

Git and GitOps are not just a new tool for doing what you already do. They are a different accountability and change management model.

| Your current process | Git / GitHub equivalent |
|----------------------|-------------------------|
| Change ticket describing the change | **Pull request** — the change *is* the diff; the description is the PR body |
| CAB review / approval | **PR review** — named approvers, required reviewers enforced by branch protection |
| Approval record | **Merge commit** — named, timestamped, traceable to the PR and the approvers |
| Maintenance window | Not required for config-only GitOps changes (still applies to rolling restarts, storage migrations, network disruptions) |
| "Who changed this?" investigation | `git log`, `git blame`, PR history |
| Emergency change / break-glass | Emergency PR with post-hoc review; audit trail preserved |
| Rollback | `git revert` — history of both the change and the rollback is preserved |

Git does not eliminate governance. It makes governance faster, more traceable, and automatable at the enforcement layer rather than the process layer.

### Minimum mechanics for this path

Before Phase 1 you need: clone, branch, commit, push, open a PR, read `git log` and `git diff`. Before Phase 4 you need: merge, `git revert`, branch protection, CODEOWNERS.

**Start here (free, ~2 hours each):**

- **[Git For Ages 4 And Up — Michael Schwern](https://www.youtube.com/watch?v=1ffBJ4sVUb4)** (~1h 40m) — the inside-out mental model. Do this first. Library entry: [`library/git-for-ages-4-and-up.md`](../../../library/git-for-ages-4-and-up.md).
- [GitHub Skills](https://skills.github.com/) — interactive in-repo exercises (Introduction to Git, Introduction to GitHub).
- [Microsoft Learn — Introduction to Git](https://learn.microsoft.com/en-us/training/modules/intro-to-git/) — structured free module with knowledge checks (~1h 26m).

See the **[Git, GitHub, and GitLab Learning Path](../git/README.md)** for the full staged curriculum including [learngitbranching.js.org](https://learngitbranching.js.org/), the Pro Git book, and enterprise hosting notes.

**Verification:** Clone a team repo, create a branch, edit one file, commit, push, open a PR. Write the PR description as a change ticket: what changed, why, what the risk is, how to verify. Explain without notes: what is the difference between `git commit` and `git push`? Between `git pull` and merging a PR?

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

**Formal course option:** [DO180 — Containers, Kubernetes, and Red Hat OpenShift](https://www.redhat.com/en/services/training/do180-introduction-containers-kubernetes-red-hat-openshift)

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
- **Security Context Constraints (SCCs)** — OpenShift's pod-level security model; no VMware equivalent. Every pod runs under an SCC; `restricted-v2` is the default and is more restrictive than vanilla Kubernetes. A workload that runs on upstream Kubernetes or a development cluster often fails on OCP because of SCC violations. Use `oc adm policy who-can use scc` to audit what service accounts have elevated access.
- **Operator Lifecycle Manager (OLM)** — how operators are installed, updated, and removed. Objects to know: `CatalogSource` (the catalog index image), `Subscription` (which operator and channel you want), `InstallPlan` (the list of resources to create — can require manual approval), `ClusterServiceVersion` (CSV — the installed operator version and its state). A CSV stuck in `Installing` is the operator install failure I see most often; the resolution is almost always in the CSV's own status conditions or the operator pod logs.
- **Multi-tenancy** — when to isolate teams by namespace vs by cluster. Namespaces with `ResourceQuota` and `LimitRange` are the lightweight isolation model; separate clusters provide stronger isolation at higher operational cost. The decision depends on trust boundary, regulatory compliance requirements, and blast-radius tolerance. RBAC patterns for self-service namespace provisioning: teams should be able to operate within their namespace without requiring platform-admin intervention on every request.
- **Observability** — the platform monitoring stack (Prometheus + Alertmanager) is installed by default; user workload monitoring is opt-in. Key objects: `PrometheusRule` (custom alerting rules), `AlertmanagerConfig` (routing and receivers). Log aggregation: LokiStack is the current log backend for the Logging Operator (replaced EFK/Elasticsearch). First-line diagnostic tools: `oc adm must-gather` (collects a full cluster snapshot for support or post-incident review), `oc adm inspect` (targeted resource-level inspection). At fleet scale: ACM Observability provides hub-level metrics aggregation across all managed clusters.
- **Backup and disaster recovery** — `etcd` backup is the control-plane recovery mechanism; without a recent backup, a failed control plane cannot be recovered — the cluster must be rebuilt from scratch or from the GitOps repo (which recovers workloads but not cluster state such as certificates, cluster ID, and custom CRs). OADP (OpenShift API for Data Protection — Velero-based) backs up workload namespaces, PVs, and their metadata to object storage. OCP Virt VMs require the KubeVirt Velero plugin for consistent VM-level backup. Understand the two recovery models: *restore* (from etcd backup + node rebuild) vs *rebuild* (from GitOps repo re-apply) — each recovers different things and neither fully replaces the other.

**Official**

- [OpenShift Container Platform documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/) — bookmark **Operators**, **Nodes**, **Networking**, **Security and compliance**.
- [Managing security context constraints](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/authentication_and_authorization/managing-security-context-constraints)
- [Backing up etcd](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/backup_and_restore/control-plane-backup-and-restore)
- [OADP (OpenShift API for Data Protection)](https://docs.redhat.com/en/documentation/openshift_api_data_protection/)
- [Monitoring overview](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/monitoring/)

**Formal course option:** [DO280 — OpenShift Administration II](https://www.redhat.com/en/services/training/Red-Hat-OpenShift-Administration-II-Operating-a-Production-Kubernetes-Cluster-DO280) (confirm current title on this page — Red Hat renames offerings).

**Verification (scenario-based)**

*Lab for this phase: single cluster (SNO on KVM is sufficient for most checks below). Multi-node checks are marked.*

- Run `oc get co` in a lab cluster. Find one cluster operator that is not fully available or has a condition set. Using `oc describe`, `oc get events`, and the operator's own logs, write a one-paragraph explanation of what is wrong — even if you cannot fix it.
- *(Multi-node cluster required)* Cordon a worker node, confirm existing pods are not evicted (just unschedulable), then drain it and confirm pods have moved. Uncordon. Explain what you would do differently in a production cluster with PodDisruptionBudgets set. *On SNO: read the drain/cordon documentation and trace what would happen — name the components involved and the constraint SNO imposes.*
- **SCCs**: Deploy a pod spec that requests `hostNetwork: true`. Find the SCC-related failure in pod events. Use `oc adm policy who-can use scc hostnetwork` to identify which service accounts have that access. Explain the difference between `restricted-v2` (the default) and `privileged`, and why this matters for workload portability from vanilla Kubernetes.
- **OLM**: Install an operator via a `Subscription`. Watch for the `InstallPlan` to appear and the CSV to reach `Succeeded`. Then modify the subscription to reference a non-existent channel. Diagnose what is stuck — use `oc get sub`, `oc get ip`, and `oc get csv -A` to trace the failure. Explain how you would recover without deleting the operator.
- **Observability**: Write a `PrometheusRule` that fires an alert when any namespace has more than 10 pods in `Pending` state for more than 5 minutes. Confirm the alert appears in Alertmanager. *Prerequisite: user workload monitoring must be enabled on your lab cluster (`enableUserWorkload: true` in the cluster-monitoring ConfigMap) — this is not on by default.* Separately: explain what `oc adm must-gather` collects and when you would run it vs `oc adm inspect`.
- **Backup and DR**: Run a manual etcd backup on a lab cluster (or trace the documented procedure step-by-step if running on a single-node lab where the etcd pod layout differs from a multi-master cluster). Describe what the backup contains, where it is stored, and what a restore procedure looks like. Compare to a vSphere VM snapshot: what does etcd backup preserve that a GitOps rebuild cannot, and what does a GitOps rebuild recover that etcd backup alone does not?

**This repo (when things break)**

- [OpenShift troubleshooting index](../../ocp/troubleshooting/README.md) — API slowness, CSR management, kube-controller-manager crashloops, namespace termination, and more.

---

## Networking and storage deep dive

**Read before Phase 3.** OpenShift Virtualization is critically dependent on correct networking (for secondary VM interfaces and live migration traffic) and correct storage (for DataVolumes, live migration, and VM snapshots). The analogy table in Phase 0 mapped these in one row each. This section fills in the depth those single rows omitted — skip it and you will hit unexplained failures in Phase 3.

### Networking

VMware admins from NSX-T face the steepest networking relearn in this path. The Kubernetes networking model and the NSX policy model are architecturally different at every layer.

**Core concepts**

- **OVN-Kubernetes** — the default CNI (Container Network Interface) for OCP. Provides overlay networking for pods, services, and egress. Logical routers and switches underpin the fabric; the Cluster Network Operator manages them — you interact through Kubernetes APIs, not a graphical topology editor.
- **NetworkPolicy** — the Kubernetes API for restricting pod-to-pod and pod-to-external traffic. Important reframe: NetworkPolicy is a set of *allow* rules, not a firewall. Without any NetworkPolicy, all pod-to-pod traffic is allowed. An NSX distributed firewall rule (deny-by-default with explicit permits) maps conceptually to a default-deny NetworkPolicy + explicit allow policies — but the implementation is entirely different. Relearn this from the Kubernetes model, not by translating NSX constructs.
- **Multus CNI** — enables multiple network interfaces on a single pod or VM. The primary interface is always managed by OVN-Kubernetes; secondary interfaces (additional VLANs for VM workloads, storage networks, management networks) are attached via Multus with bridge, MACVLAN, or IPVLAN plugins.
- **NetworkAttachmentDefinition (NAD)** — the CR that defines a secondary network and its plugin configuration. A VM spec references a NAD to attach to that network. Required for any OCP Virt VM that needs to appear on a physical VLAN or a network that is separate from the pod overlay. See [NAD example](../../ocp/examples/network-attachment-definitions/README.md) in this repo.
- **MetalLB** — provides LoadBalancer-type services on bare metal clusters (a role performed by cloud load balancers on cloud clusters, or by NSX on vSphere). Required if services need external IPs on bare metal without a cloud provider.
- **NMState** — declarative node-level network configuration (bond interfaces, VLANs, bridge creation, MTU settings). Applied via `NodeNetworkConfigurationPolicy` CRs; the OCP equivalent of maintaining `/etc/sysconfig/network-scripts` files on each node — but declarative, version-controlled, and applied by the NMState Operator.
- **SR-IOV Network Operator** — hardware-based network virtualization for high-throughput, low-latency workloads. Creates VFs (Virtual Functions) from SR-IOV-capable NICs (PFs). Required for telco RAN workloads and performance-sensitive VM network interfaces. Uses `SriovNetworkNodePolicy` and `SriovNetwork` CRs.

**Official**

- [Networking overview (OCP docs)](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/networking/)
- [OVN-Kubernetes network provider](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/networking/ovn-kubernetes-network-provider)
- [Multiple networks with Multus](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/networking/multiple-networks)
- [Hardware networks (SR-IOV, DPDK)](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/networking/hardware-networks)
- [NMState for node networking](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/networking/nmstate-operator)

**Verification**

- Create a NAD for a bridge network. Attach a test pod to it. Confirm the secondary interface appears inside the pod. Explain which components provisioned each interface: OVN-Kubernetes for `eth0`, Multus + bridge plugin for the secondary.
- Write a NetworkPolicy that allows ingress to a pod only from pods in the same namespace with a specific label. Confirm it blocks traffic from a pod without that label. Explain why this is not equivalent to an NSX distributed firewall rule — what is the model difference, and what happens to traffic when no NetworkPolicy exists?

### Storage

The shift from vSAN/VMFS datastores to the Kubernetes storage model is as significant as the networking shift. The key conceptual difference: storage is *requested per workload* (PVC), *provisioned dynamically* (StorageClass + CSI driver), and the workload does not know or care where the storage lives.

**Core concepts**

- **StorageClass** — defines a provisioner (CSI driver) and its configuration parameters. The equivalent of choosing a datastore type in vCenter. Multiple StorageClasses can coexist (ODF Ceph, NFS, iSCSI, local-storage) with different performance and redundancy profiles. A default StorageClass is used when a PVC does not specify one.
- **PersistentVolumeClaim (PVC) and PersistentVolume (PV)** — the user-facing request (PVC) and the actual provisioned storage object (PV). Kubernetes binds them. Critical lifecycle distinction: a PVC persists independently of the pod that uses it — deleting a pod does not delete its PVC unless explicitly configured to do so.
- **CSI (Container Storage Interface)** — the plugin API that connects Kubernetes to storage back ends. Every storage vendor (NetApp, Pure, Portworx, Ceph, NFS) ships a CSI driver. The driver handles provisioning, attach/detach, mount, and snapshot operations. Swapping storage back ends is a StorageClass change, not a Kubernetes change.
- **OpenShift Data Foundation (ODF)** — Red Hat's software-defined storage layer; Ceph under the hood. The functional equivalent of vSAN. Provides block (RBD), file (CephFS), and object (RGW) storage from the same storage cluster running on OCP nodes. CephFS is the primary provider of ReadWriteMany (RWX) volumes — which are required for live migration.
- **DataVolume and CDI (Containerized Data Importer)** — OCP Virt uses `DataVolume` CRs to import VM disk images from HTTP URLs, container registries, or existing PVCs. CDI manages the import pipeline. A `DataVolume` creates and populates a PVC; the VM boots from that PVC. Understand this before Phase 3 — it is how every VM gets its disk.
- **VolumeSnapshot and VolumeSnapshotClass** — the Kubernetes API for point-in-time storage snapshots. A `VolumeSnapshot` object triggers the CSI driver to create a snapshot; this is not automatic and not equivalent to a vSphere VM-level snapshot (which also captures memory state, VM configuration, and network state). Only PVC data is snapshotted. The CSI driver and storage backend must support the `VolumeSnapshot` API.
- **ReadWriteMany (RWX)** — the PVC access mode that allows simultaneous mounting by multiple nodes. Required for live migration (both source and target nodes mount the same volume during migration). Block storage (RBD, iSCSI) is typically ReadWriteOnce (RWO); file storage (CephFS, NFS) provides RWX. If your storage only provides RWO, live migration is not possible without additional configuration.

**Official**

- [Storage overview (OCP docs)](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/storage/)
- [OpenShift Data Foundation documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/)
- [Persistent storage using PVCs](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/storage/understanding-persistent-storage)
- [Volume snapshots (CSI)](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/storage/using-container-storage-interface-csi#persistent-storage-csi-snapshots)

**Verification**

- Create a PVC using your lab's default StorageClass. Mount it in a pod, write a file, delete the pod, confirm the file persists when a new pod mounts the same PVC. Change the reclaim policy to `Retain` on a second PVC — delete it, find the retained PV, and explain what happens next.
- Explain why live migration requires RWX storage. Trace what happens at the `VirtualMachineInstanceMigration` object and its source/target pods when the VM's PVC is RWO. What error surfaces, and where?

---

## Phase 3 — OpenShift Virtualization (2–3 weeks)

**Goal:** Create, start, stop, and migrate VMs on Kubernetes; connect storage and networking; understand the KubeVirt primitives (`VirtualMachine`, `VirtualMachineInstance`, `DataVolume`) as Kubernetes resources — because that is what they are.

**Topics**

- **VirtualMachine, VirtualMachineInstance, DataVolume** — the KubeVirt primitives; a VM is a declarative desired-state object, a VMI is the running instance (a Pod with a hypervisor process), a DataVolume is a managed PVC with an import pipeline
- **VM networking** — attaching VMs to secondary networks via NAD; the difference between the pod overlay network (OVN-Kubernetes) and bridge-attached networks for workload VLANs (covered in depth in the networking deep dive above)
- **VM storage** — DataVolume import workflows (HTTP, registry, PVC clone), RWX requirement for live migration, VolumeSnapshot for VM disk point-in-time backups
- **Live migration** — the mechanism, the Kubernetes objects involved (`VirtualMachineInstanceMigration`), the shared storage requirement, and the node scheduling decisions
- **Migration Toolkit for Virtualization (MTV)** — bulk import from vSphere: source inventory, network maps, storage maps, cutover planning
- **Performance tuning for latency-sensitive VM workloads** *(read-ahead, not required for every environment)*:
  - **CPU pinning and NUMA** — `dedicatedCpuPlacement: true` in the VM spec dedicates physical CPUs to the VM, eliminating scheduling jitter; NUMA topology alignment prevents cross-NUMA memory access penalties. Requires reserved CPU capacity on the node.
  - **HugePages** — large memory pages (2Mi or 1Gi) reduce TLB pressure for memory-intensive VMs; configured via the Node Tuning Operator or `PerformanceProfile` CR and requested in the VM spec.
  - **SR-IOV for VM networking** — attaching SR-IOV VFs directly to VM network interfaces for near-native throughput; requires the SR-IOV operator (see networking deep dive) and a `SriovNetworkNodePolicy`. Bypasses the software CNI path entirely.
  - **Real-time kernel** — for workloads with strict sub-millisecond latency requirements (telco RAN, financial trading); configured via a `PerformanceProfile` CR; requires specific hardware and the `openshift-rt-kernel` image.
  - **Node Tuning Operator** — applies kernel and OS-level tuning profiles (`TuningProfile` CRs) across nodes without SSH; manages HugePages reservation, CPU isolation (`isolcpus`), IRQ affinity, and kernel parameters

**Official**

- [About OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/virtualization/about-virt) — stay in the product docs until navigation feels natural.
- [Migrating virtual machines from VMware vSphere](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/migration_toolkit_for_virtualization/) — Migration Toolkit for Virtualization (MTV) for bulk import from vSphere.

**Blog / solution context**

- [Virtual machines as code with OpenShift GitOps and OpenShift Virtualization](https://cloud.redhat.com/blog/virtual-machines-as-code-with-openshift-gitops-and-openshift-virtualization)
- [Using RHACM and OpenShift GitOps to manage OpenShift Virtualization](https://www.redhat.com/en/blog/using-red-hat-advanced-cluster-management-and-openshift-gitops-to-manage-openshift-virtualization)

**Formal course options**

- [DO316 — Managing virtual machines with OpenShift Virtualization](https://www.redhat.com/en/services/training/do316-managing-virtual-machines-red-hat-openshift-virtualization) — broad VM-on-OCP operations.
- [DO156 — OpenShift Virtualization Administration I](https://www.redhat.com/en/services/training/do156-red-hat-openshift-virtualization-administration-i-operating-virtual-machines) and [DO256 — OpenShift Virtualization Administration II](https://www.redhat.com/en/services/training/do256-red-hat-openshift-virtualization-administration-ii-configuring-production-virtual-machines) — confirm prerequisites in the current catalog.

**Verification (scenario-based)**

- Create a VM from a template or YAML manifest. Console or SSH into the guest. Then: find the Pod that backs the VMI using `oc get pods`; describe it; confirm it is the same object Kubernetes is scheduling.
- **Live migration** *(multi-node cluster with RWX storage required — not possible on SNO)*: Perform a live migration between two worker nodes. After migration, explain which Kubernetes mechanisms (pod scheduling, node affinity, resource availability) determined where the VM landed.

  *SNO fallback (documentation trace — acceptable substitute):* Read the live migration documentation and trace every API object involved: the `VirtualMachineInstanceMigration` CR, the source VMI pod, the target VMI pod, the shared PVC with RWX access mode, and the QEMU migration channel. Explain specifically why SNO cannot support live migration (single schedulable node — no valid target for the migration pod), and what the minimum cluster topology is. The constraint is the learning outcome; demonstrating you can explain it without running it counts for this check.
- Walk through one MTV planning chapter: source vSphere inventory requirements, network maps, storage maps, cutover concepts — even if you only migrate one small VM in lab.

**This repo**

- [KubeVirt VM stuck provisioning](../../ocp/troubleshooting/kubevirt-vm-stuck-provisioning/README.md) — a realistic failure involving webhooks, CSI, and snapshots.

---

## Phase 4 — GitOps with Argo CD (1–2 weeks)

**Goal:** Apply Git-as-change-management to cluster configuration. A PR merge replaces a change ticket. A `git revert` replaces an emergency rollback procedure. Argo CD (OpenShift GitOps) is the reconciliation engine that closes the loop between what is in Git and what is running in the cluster.

**Lab:** The [SNO KVM lab](../../ocp/examples/sno-kvm-lab/README.md) in this repo is sufficient for this entire phase — you need one cluster and a Git repo.

**Depends on:** [Prerequisite: Git](#prerequisite-git).

**Topics**

- **OpenShift GitOps (Argo CD)**: Application, AppProject, sync policies, health checks, self-healing
- **ApplicationSet** — generate many Applications from a single template (by cluster label, by directory, by Git branch)
- **App-of-apps pattern** — a root Application that manages child Applications; the complete cluster inventory lives in Git
- **Configuration drift** — what Argo CD detects when cluster state diverges from Git; `selfHeal` vs manual sync
- **Sync options** — `Validate`, `CreateNamespace`, `RespectIgnoreDifferences`, retry strategies
- **GitOps repository structure** — this is where new teams consistently make long-lived decisions they later regret; get it right early. The Red Hat COP `components/groups/clusters` pattern is the standard starting point:

  **The `components / groups / clusters` pattern** ([`redhat-cop/gitops-standards-repo-template`](https://github.com/redhat-cop/gitops-standards-repo-template))

  Red Hat's community of practice publishes a reference repo template for multi-cluster day-2 configuration. It defines three folders whose separation is the key design insight:

  ```
  components/          # atomic, reusable building blocks — one config concern per subfolder
  │  ├── oauth/        # no cluster-specific values; just the raw manifest
  │  ├── nmstate/
  │  └── cert-manager/
  groups/              # composable cluster profiles — each group is a Kustomize Component
  │  ├── all/          # applied to every cluster
  │  ├── non-prod/     # overrides for non-production clusters
  │  ├── geo-east/     # geography-based group
  │  └── virt-enabled/ # clusters running OpenShift Virtualization
  clusters/            # cluster-specific config — selects which groups to compose
     ├── hub/
     └── site-dc1/
  ```

  Groups are Kustomize `kind: Component` (not `kind: Kustomization`), which makes them *composable* rather than *inherited*. A cluster can belong to `all + non-prod + geo-east` simultaneously. This avoids the combinatorial explosion of full overlays.

  **`redhat-cop/gitops-catalog`** — the component library ([`redhat-cop/gitops-catalog`](https://github.com/redhat-cop/gitops-catalog))

  A library of 80+ pre-built Kustomize base components for common OCP operators and configurations. Rather than writing your own `Subscription` and `OperatorGroup` YAML for every operator, reference a catalog entry as a Kustomize remote base:

  ```yaml
  # components/nmstate/kustomization.yaml
  resources:
    - github.com/redhat-cop/gitops-catalog/nmstate/operator/overlays/stable?ref=main
  ```

  Directly relevant entries for this learning path: `advanced-cluster-management`, `nmstate`, `metallb-operator`, `openshift-data-foundation-operator`, `virtualization-operator`, `topology-aware-lifecycle-manager-operator`, `external-secrets-operator`, `sealed-secrets-operator`, `loki-operator`, `openshift-api-for-data-protection-operator`, `openshift-sriov-network-operator`. Start here instead of writing operator YAML from scratch.

  **Helm variant — `mustMergeOverwrite` with named component keys**

  The same `components/groups/clusters` concept can be implemented with Helm instead of Kustomize. Each values file — whether a group or a cluster — defines its configuration under a key named `component-<groupName>` or `component-<clusterName>`. This namespacing is the resolution mechanism: when all values files are merged with `mustMergeOverwrite`, each component's key is distinct and Helm's deep map merge accumulates them without collision. The Argo CD Application Helm template then explicitly reads each component key and sets the resolved values directly on the Application YAML.

  ```yaml
  # groups/all/values.yaml
  component-all:
    operators:
      nmstate: {enabled: true, channel: stable}
      cert-manager: {enabled: true}

  # groups/virt-enabled/values.yaml
  component-virt-enabled:
    operators:
      kubevirt: {enabled: true, channel: stable}
      nmstate: {channel: stable-4.16}   # virt group overrides the channel

  # clusters/site-dc1/values.yaml
  component-site-dc1:
    clusterName: site-dc1
    operators:
      nmstate: {channel: stable-4.16}   # cluster-level pin, same result
  ```

  The Helm template that generates Argo CD Application objects merges these component keys in order using `mustMergeOverwrite` and then explicitly sets the resolved values on each Application's `spec.source.helm.values` (or `parameters`). The Application YAML that Argo CD receives already has the fully-resolved configuration baked in — there is no further value resolution at sync time. This is the "app of app of apps" pattern: the parent chart generates Application objects whose own Helm values have been resolved by the parent chart's template logic before Argo CD ever sees them.

  The naming convention (`component-<name>`) is not cosmetic — it is what prevents key collisions when Helm merges a cluster's values file with multiple group values files simultaneously, and it is what the template uses to iterate over resolved components to build each Application's final values.

  **Mono-repo vs multi-repo**: a single repo for all cluster config (simple, one PR spans all changes) vs separate repos per team or per environment (cleaner access control, more operational overhead). Most platform teams start with mono-repo and split when team count or access control requirements force it.

  **Secrets in GitOps** — never commit plaintext or base64-encoded secrets to Git. Three approved patterns: (1) *Sealed Secrets* (asymmetrically encrypted in Git, decrypted by controller in-cluster — simple, no external dependency; `gitops-catalog` has a component for it); (2) *External Secrets Operator* (secret lives in a vault, never in Git — preferred for production; also in `gitops-catalog`); (3) *Helm Secrets* (SOPS-encrypted values file — works with the Helm variant above). Choose based on vault investment and secret rotation cadence.

**Official**

- [Understanding OpenShift GitOps](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/latest/html/understanding_openshift_gitops/index)
- [`redhat-cop/gitops-standards-repo-template`](https://github.com/redhat-cop/gitops-standards-repo-template) — the `components/groups/clusters` reference layout for multi-cluster day-2 configuration; use as the starting template for any new GitOps repo
- [`redhat-cop/gitops-catalog`](https://github.com/redhat-cop/gitops-catalog) — 80+ pre-built Kustomize base components for OCP operators; reference as remote bases rather than writing operator YAML from scratch
- [`redhat-cop/helm-charts` — operators-installer](https://github.com/redhat-cop/helm-charts/tree/main/charts/operators-installer) — community Helm chart for GitOps-driven operator installation; the foundation for the Helm app-of-apps variant

**This repo**

- [Argo CD examples](../../argo/examples/) and [Argo CD labs](../../argo/labs/README.md)
- [Helm component pattern](../../argo/examples/helm-component-pattern/README.md) — working reference implementation of the `mustMergeOverwrite` + `component-<name>` key pattern; includes the `cluster-apps` chart, group/cluster values files, render script, and pre-rendered Application output for two example clusters

**Verification (scenario-based)**

- Create an Argo CD Application syncing from a Git repo. Make a change in Git (wrong replica count, incorrect image tag). Watch the cluster converge. Roll back by reverting the commit and watching the cluster follow.
- Introduce a deliberate drift — change a resource directly via `oc`, bypassing Git. Confirm Argo CD detects it and either alerts or remediates depending on your sync policy. Explain to a colleague what just happened and why the console change did not survive.
- Create an ApplicationSet that generates one Application per directory in a repo. Add a new directory. Confirm Argo CD creates the Application automatically.
- **Failure modes** (the questions that arrive in production): Introduce a broken manifest into Git — a YAML syntax error or a missing required field — and push it. What state does the Application enter? How do you identify the sync error without console access? How do you unblock it? Then: intentionally cause a health check failure (deploy a pod with a container that crashes on start). Distinguish `OutOfSync` (cluster state differs from Git) from `Degraded` (cluster state matches Git but the resource is unhealthy). Explain why Argo CD can report both simultaneously and what each requires from the operator.
- **Repo structure**: Clone `redhat-cop/gitops-standards-repo-template`. Without reading the full README, map what each top-level folder is for by reading only the `kustomization.yaml` files. Then: design a `groups/` structure for a fleet that has three cluster types — `all` (shared baseline), `virt-enabled` (OCP Virt), and `edge-sno` (single-node, resource-constrained). Explain how a cluster that is both `virt-enabled` and `edge-sno` references both groups, and what Kustomize `kind: Component` makes possible that `kind: Kustomization` overlays do not.
- **Catalog usage**: Browse `redhat-cop/gitops-catalog` and find the Kustomize base for NMState, MetalLB, and the External Secrets Operator. Create a `components/nmstate/kustomization.yaml` in a test repo that references the catalog as a remote base. Point an Argo CD Application at it. Confirm the operator installs.
- **Secrets**: A teammate has committed a Kubernetes Secret manifest (base64-encoded data, not encrypted) to the GitOps repo. Explain the security exposure, which tool you would use to remediate it (Sealed Secrets vs ESO — and why), and how you would prevent recurrence via a pre-commit hook or CODEOWNERS rule.

**Planting a question for Phase 5:** You now have one tool — Argo CD — and it can install operators, apply configs, and manage workloads across clusters. Before you move to Phase 5, ask yourself: *when should a platform configuration NOT be in Argo CD?* What is the difference between "Argo CD manages this" and "the platform mandates this on every cluster"? Phase 5 answers this question with a structured decision framework. Go into it with the question already alive.

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

**Formal course option**

- [DO480 — Multicluster Management with Red Hat OpenShift Platform Plus](https://www.redhat.com/en/services/training/do480-multicluster-management-red-hat-openshift-platform-plus) — ACM, policy management, RHACS, Quay; requires DO280 and DO380. Preparation for EX480.

**This repo**

- [Fleet control spectrum](../../fleet-control-spectrum.md) — multiple barometers (reconciliation, compliance, lifecycle, drift) beyond the decision table above
- [RHACM examples](../../rhacm/examples/) — secret management, cluster import, GitOps integration

**Verification (scenario-based)**

*Lab for this phase: hub cluster with ACM + OpenShift GitOps installed, plus at least one managed cluster. A second SNO on KVM, a cloud trial, or a workshop environment works. This phase cannot be verified on a single cluster — the multi-cluster topology is the thing being learned.*

- Import a second cluster into ACM. Label it. Write a PolicyGenerator manifest that enforces a configuration (an RBAC policy or alertmanager rule) on clusters matching that label. Confirm compliance status in the ACM console. Switch `remediationAction` from `inform` to `enforce` and observe the difference.
- Explain the fleet compliance model without notes: what does "non-compliant" mean in ACM? Who is notified? How does a remediation policy differ from a monitoring policy?
- Given this scenario: install the OpenShift Virtualization operator on all production clusters (platform mandate), and install the Strimzi operator only on clusters owned by a specific team. Argue which tool you use for each and why. What changes if the Virt operator install becomes a regulatory compliance requirement?

---

---

> **The core path ends at Phase 5.** A VMware admin who completes Phases 0–5 can operate and govern an OpenShift fleet. Phase 6 below is a **specialist track** — a different role and a different infrastructure scope. Read the framing box before deciding whether it applies to you.

---

## Specialist track: Zero Touch Provisioning — Day 0 / Day 1 / Day 2 automation

> **Who this is for:** Teams managing **50 or more clusters**, particularly at remote or edge sites where manual cluster installation is not operationally viable. This is the pattern used in large retail, utility, and telecommunications deployments. The required skills go beyond fleet operations (Phase 5) into bare metal infrastructure, hardware provisioning pipelines, and large-scale upgrade orchestration — this is a distinct engineering specialty, not the next step after Phase 5 for every operator.
>
> If you are managing a fleet of 3–20 clusters in a data centre, **Phase 5 is sufficient for your scope**. Come back here when cluster count or geographic distribution makes individual cluster provisioning a bottleneck. A dedicated learning path for ZTP at scale is planned in [`devops/learning-path/`](../README.md).

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

## Appendix: Disconnected and air-gapped environments

Many enterprise, government, and telco OCP deployments run without direct internet access — nodes cannot reach `registry.redhat.io`, `quay.io`, or the default OperatorHub catalogs. All phases above assume internet-connected infrastructure. This appendix covers the additional layers required when your environment is partially or fully disconnected.

**When you need this:** Nodes in any phase cannot pull images or operator catalogs from the internet. Common scenarios: regulated industries (financial services, defence, healthcare), edge clusters with no guaranteed WAN, or lab environments behind strict egress firewalls. ZTP Phase 6 environments are often fully disconnected — the DevConf.US 2024 talk in Phase 5 demonstrates this end-to-end.

### Mirror registry

All images your clusters need must be copied to a local registry before they can be used. Red Hat provides `mirror-registry` (a single-node Quay instance) as the recommended local registry for this purpose.

- **`oc-mirror` plugin** — the current Red Hat tool for mirroring OCP release images, operator catalogs, and additional images into a local registry. Replaces the older `oc adm release mirror` workflow. Takes an *image set configuration* file and syncs only what is declared — incremental updates on subsequent runs.
- **Image set configuration** — a YAML file that declares which OCP release versions, operator catalogs (and which operators within them), and additional images to mirror. Controlling this file in Git is the GitOps-native approach to managing your mirror content.

```yaml
# ImageSetConfiguration — minimal example
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
mirror:
  platform:
    channels:
      - name: stable-4.16
        minVersion: 4.16.0
        maxVersion: 4.16.8
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.16
      packages:
        - name: advanced-cluster-management
        - name: openshift-gitops-operator
        - name: kubevirt-hyperconverged
```

### Image content source policy

After mirroring, clusters must redirect image pulls from the public registry to your local mirror:

- **`ImageDigestMirrorSet` (IDMS)** — the current API (OCP 4.13+) for redirecting pulls by image digest to a mirror. Applied as a cluster-level CR; the Machine Config Operator propagates it to all nodes via `MachineConfig`. Use this for new clusters.
- **`ImageContentSourcePolicy` (ICSP)** — the older equivalent (OCP 4.12 and earlier); functionally identical, deprecated in favor of IDMS. Still appears in older ZTP SiteConfig templates — know both.

Both objects are generated automatically by `oc-mirror` at the end of a mirror run; apply the output directory to the cluster or commit it to the ZTP Git repo.

### Disconnected OperatorHub

By default, OperatorHub shows all operators from Red Hat's hosted index images. In a disconnected environment:

1. Mirror the operator catalog index image and all required bundle images with `oc-mirror`.
2. Disable the default internet-hosted `CatalogSources`:
   ```bash
   oc patch operatorhub cluster --type merge \
     -p '{"spec":{"disableAllDefaultSources":true}}'
   ```
3. Create a `CatalogSource` pointing to your mirrored index image.

After this, `oc get packagemanifests` shows only the operators you have mirrored. `Subscription` and `InstallPlan` objects work identically to a connected environment — the only difference is where images are pulled from.

### Cross-phase integration

| Phase | Disconnected addition |
|-------|-----------------------|
| Phase 2 (cluster operations) | Cluster nodes pull `oc adm must-gather` image from local mirror |
| Phase 4 (GitOps) | Argo CD and OpenShift GitOps images must be mirrored; IDMS applied before install |
| Phase 5 (ACM) | ACM hub and all managed cluster images mirrored; `MultiClusterHub` uses local registry |
| Phase 6 (ZTP) | Full pipeline runs disconnected; SiteConfig references mirror registry; ESO pulls vault creds without internet |

**Official**

- [Disconnected installation mirroring (OCP docs)](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/disconnected_environments/)
- [About the oc-mirror plugin](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/disconnected_environments/mirroring-images-for-a-disconnected-installation)
- [Mirroring operator catalogs](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/disconnected_environments/mirroring-operator-catalogs-for-use-with-disconnected-clusters)

**Verification**

- Mirror one OCP minor version and two operators into a local registry using `oc-mirror`. Apply the generated `ImageDigestMirrorSet` to a lab cluster. Verify the cluster can pull those images without internet access by temporarily blocking egress (or by checking that image pulls resolve to the local registry address).
- Disable the default OperatorHub `CatalogSources` on a lab cluster. Create a `CatalogSource` pointing to a mirrored index. Install one operator via `Subscription`. Explain why the install works without internet access and what would break if the IDMS was not applied.

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

**Document:** Learning path v2.2 · Last updated 2026-04-29 (v2.2: adversarial review fixes — Phase 0 mapping table expiry cues with per-row break conditions; verification lab requirements and SNO fallbacks made explicit; Phase 6 reframed as specialist track separate from core path; Git/GitOps governance claims qualified for regulated-env reality; Phase 4 closes with forward-reference question for Phase 5 Argo CD vs ACM decision; scale table updated to reflect ZTP as specialist track; v2.1: Phase 4 GitOps repo structure section replaced with concrete, named references; v2.0: Phase 2 SCCs/OLM/multi-tenancy/observability/backup-DR; networking+storage deep dive bridge; Phase 3 VM topics + performance tuning; Phase 4 GitOps repo structure + secrets; disconnected environments appendix).

*AI-assisted content. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for review status details.*

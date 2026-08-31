---
review:
  status: unreviewed
  notes: "Complete 4.20 pass plus 4.22. Escalation URLs for intra-minor doc clashes; 4.18 vs 4.20 freeze/thaw unchanged. 2026-08-31."
---

# What cannot change after OpenShift install

A catalog of `install-config.yaml` (and cousin) settings that are **frozen**, **one-way**, or **expand-only** after the cluster exists — versus settings that look install-only in the installer book but have a Day-2 API.

> **Audience:** Operators reviewing an `install-config` before ABI / IPI / UPI, and anyone compiling Red Hat immutability notes.
>
> **Purpose:** Decide what must be right before install, without treating the installer chapter’s blanket “cannot change after installation” as the whole story.

**Pinned:** OpenShift Container Platform **4.20** (tables below).
**Latest GA compared:** **4.22** (GA ~Jun 2026; 4.22.9 errata Aug 2026).
**4.23** is CI/nightly, not GA.

---

## How to read this

The installer books all say some version of:

> These settings are used for installation only, and cannot be changed after installation.

That means you cannot re-apply `install-config.yaml`.
It does **not** always mean there is no other supported API.

| Status | Meaning |
|--------|---------|
| **Frozen** | No supported Day-2 change. Rebuild (or live with it). |
| **One-way** | You can turn it *on* (or add) after install; you cannot turn it *off*. |
| **Expand-only** | You can enlarge a range; you cannot shrink, rename the base, or change the other dimension. |
| **Day-2** | A documented post-install procedure exists (often disruptive). |
| **Installer-consumed** | Used at provision time; not a live CR. Related live knobs may exist elsewhere. |

When two Red Hat books disagree, this page **prefers the post-install / operator chapter** and notes the clash.

CIDR math (`hostPrefix` vs node count): [cluster-network-hostprefix.md](cluster-network-hostprefix.md).

Primary field list: [Installation configuration parameters for the Agent-based Installer](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installation-config-parameters-agent) — chapter 9 (OCP 4.20).
Cloud books use the same required/optional tables plus platform stanzas.

---

## Frozen, one-way, expand-only (4.20)

### Identity and platform

| Field | Status | Notes |
|-------|--------|--------|
| `baseDomain` | **Frozen** | DNS is `<metadata.name>.<baseDomain>`. No supported rename. |
| `metadata.name` | **Frozen** | Same. |
| `platform` (type: `baremetal`, `none`, `vsphere`, …) | **Frozen** | You do not convert IPI/UPI platform after the fact. |
| `fips` | **Frozen** | Must be on before the OS first boots. Cannot enable after deploy. |
| `cpuPartitioningMode` | **Frozen** | Enable **only** at install; **cannot disable** later. Does not pin workload CPUs. |
| `featureSet: TechPreviewNoUpgrade` | **Frozen** (once on) | Cannot undo; blocks minor upgrades. Not for production. |
| `compute` / `controlPlane` `architecture` | **Treat as frozen** | Installer: mixed arch in one install is not supported. Adding heterogeneous workers is a separate feature — not catalogued here. |
| `controlPlane.hyperthreading` / `compute.hyperthreading` | **Treat as frozen** | No documented SMT toggle. Changing kernel args by hand is not a supported “undo install-config” path. |
| `controlPlane.replicas` | **Treat as frozen** | 3 (or 1 for SNO). Expanding/shrinking the control plane is not “edit install-config”; it is a specialized procedure. |
| `publish` | **Installer intent** | `Internal` vs `External` at install. `Internal` is not supported on non-cloud platforms. After install, **cloud** clusters can restrict Ingress/API via the private-cluster chapter — that is not rewriting `publish`. |

`fips`: [Support for FIPS cryptography](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installation_overview/installing-fips) — chapter 4, *Installation overview*.

Private endpoints after install: [Configuring a private cluster](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/postinstallation_configuration/configuring-private-cluster) — *Postinstallation configuration* (OCP 4.20).

### Cluster and service network

| Field | Status | Notes |
|-------|--------|--------|
| `networking.networkType` | **Frozen** | OVN-Kubernetes only at install in 4.20. |
| `networking.clusterNetwork[].cidr` **base** | **Frozen** | Cannot change `100.100.0.0` to another network. Not the join subnet. |
| `networking.clusterNetwork[].cidr` **mask** | **Expand-only** | OVN-K: `/15` → `/14` (same base). More **nodes**, not more IPs per node. |
| `networking.clusterNetwork[].hostPrefix` | **Frozen** | CNO rejects. Per-node pod IP slice. |
| `networking.serviceNetwork` | **Frozen** | Cannot expand via CNO or ServiceCIDR API. |
| `ovnKubernetesConfig.genevePort` | **Frozen** | Default 6081. CNO: `cannot change ovn-kubernetes genevePort`. |
| `serviceNodePortRange` | **Expand-only** | Set at install or expand after; **cannot shrink**. Must keep `30000-32768` inside an expanded default range. |

Detail: [cluster-network-hostprefix.md](cluster-network-hostprefix.md).

[Configuring the cluster network range](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/configuring_network_settings/configuring-cluster-network-range) — chapter 3; [Cluster Network Operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/networking_operators/cluster-network-operator) — chapter 6; [Configuring the node port service range](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/configuring_network_settings/configuring-node-port-service-range) — chapter 2, *Configuring network settings*.

`genevePort`: CNO [`isOVNKubernetesChangeSafe`](https://github.com/openshift/cluster-network-operator/blob/release-4.20/pkg/network/ovn_kubernetes.go) (`cannot change ovn-kubernetes genevePort`); also [Installing on IBM Cloud with customizations](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_on_ibm_cloud/installing-ibm-cloud-customizations) — chapter 5, *Installing on IBM Cloud* (OCP 4.20).

### Capabilities

| Field | Status | Notes |
|-------|--------|--------|
| `capabilities` | **One-way** | Enable after install. **Cannot disable** once on. Upgrades can implicitly enable a capability. |

[Cluster capabilities](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installation_overview/cluster-capabilities) — chapter 3, *Installation overview*.

### Per-host / Agent ISO (those machines)

| Field | Status | Notes |
|-------|--------|--------|
| `hosts[].rootDeviceHints` | **Frozen for that install** | Chooses the RHCOS install disk. Wrong disk ⇒ reinstall that node. |
| `hosts[].networkConfig` (nmstate) | **Installer-consumed** | Day-2 equivalent is NNCP / MachineConfig, not re-running Agent ISO. |
| `rendezvousIP` | **Install-only** | Bootstrap/assisted-service; gone after install. |

ABI chapter 9.2: Agent parameters “cannot be modified after installation” in the file sense; live nodes use NMState/MCO instead.

---

## Day-2 (4.20) — do not treat the installer blanket as frozen

| Field | Status | Notes |
|-------|--------|--------|
| Cluster CIDR **mask** | Expand-only | CNO ~30 min; proxy clusters may reboot all nodes |
| `maxPods` / kubelet | Day-2 `KubeletConfig` | Rolling drain + reboot |
| Dual-stack (add the other family) | Day-2 | Patch Network (+ Infrastructure on IPI); recreate pods |
| `internalJoinSubnet` | **Day-2** | CNO ~30 min. **Clash:** installer text says cannot change. Prefer OVN ch. 6. |
| `internalTransitSwitchSubnet` | Day-2 | Same class of patch |
| `gatewayConfig.ipv4.internalMasqueradeSubnet` | Day-2 | Documented post-install |
| `gatewayConfig` (`ipForwarding`, Shared/Local, …) | Day-2 | CNO names this the runtime exception |
| IPsec (`ipsecConfig.mode`) | Day-2 | Enable/disable after install; drop overlay MTU by 46 for ESP first |
| Overlay **MTU** | Day-2 | MTU **migration**; node reboots. **Clash:** older CNO tables said MTU cannot change. |
| `compute.replicas` / extra workers | Day-2 | MachineSet / BMH / Agent |
| `pullSecret` | Day-2 | Global pull secret |
| `sshKey` | Day-2 | MCO SSH authorized keys (often rebootless) |
| `proxy` | Day-2 | `Proxy` CR `cluster`; nodes reboot |
| `additionalTrustBundle` | Day-2 | ConfigMap + `Proxy.spec.trustedCA` |
| `imageContentSources` | Day-2 | ImageDigestMirrorSet / ImageTagMirrorSet (ICSP deprecated) |
| etcd encryption | Day-2 | `APIServer.spec.encryption.type`; also disableable |
| Ingress / API “private” (cloud) | Day-2 | Private-cluster chapter — not a `baseDomain` change |
| `platform.baremetal.hosts` / BMC | Day-2 | ABI table 9.4: available after install so you need not set them at ISO time |
| `machineNetwork` | Installer-consumed | VIP/discovery. Workload VLANs: Multus. [vlan-segmentation.md](../examples/networking/vlan-segmentation.md) |

Join / transit / masquerade: [Configuring OVN-Kubernetes internal IP address subnets](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/ovn-kubernetes_network_plugin/configure-ovn-kubernetes-subnets) — chapter 6.

IPsec: [Configuring IPsec encryption](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/network_security/configuring-ipsec-ovn) — chapter 6, *Network security*.

MTU: [Changing the MTU for the cluster network](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/advanced_networking/index) — chapter 2, *Advanced networking*.

Dual-stack: [Converting to IPv4/IPv6 dual-stack networking](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/ovn-kubernetes_network_plugin/converting-to-dual-stack) — chapter 5.

`maxPods`: [Working with nodes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/nodes/working-with-nodes) — section 6.5.

Proxy: [Configuring the cluster-wide proxy](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/configuring_network_settings/enable-cluster-wide-proxy) — chapter 5.

Trust bundle: [Configuring a custom PKI](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/configuring_network_settings/configuring-a-custom-pki) — chapter 6.

etcd: [Enabling etcd encryption](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/etcd/etcd-encrypt) — chapter 5, *etcd*.

---

## Document contradictions (same minor, different books)

Yes. Red Hat docs **disagree with each other inside 4.20** (and the same pairs already existed in **4.18**).
This is the packet to escalate: two URLs, two quotes, same product minor.

**Prefer** the post-install / OVN / CNO **procedure** chapter over the installer field table, except where CNO **code** is stricter (Geneve port: frozen).
Oracle for Geneve: [`isOVNKubernetesChangeSafe`](https://github.com/openshift/cluster-network-operator/blob/release-4.20/pkg/network/ovn_kubernetes.go) — `cannot change ovn-kubernetes genevePort`; MTU only via `Migration.MTU`.

### Clash 1 — Whole `networking:` object vs CIDR expand / dual-stack / NodePort

| Side | Quote (paraphrase of the table note) | Pin |
|------|--------------------------------------|-----|
| **A — frozen** | “You cannot change parameters specified by the `networking` object after installation.” Also the chapter lead-in: settings “cannot be changed after installation.” | [Installation configuration parameters for the Agent-based Installer](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installation-config-parameters-agent) — chapter 9, table 9.2, *Installing an on-premise cluster with the Agent-based Installer* (OCP **4.20**). Same note: [4.18 ch. 8](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installation-config-parameters-agent), [4.22 ch. 9](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installation-config-parameters-agent). |
| **B — expand mask** | After install you **can** enlarge the cluster CIDR **mask**; “The host prefix cannot be modified”; you **cannot** change the network **base**. | [Configuring the cluster network range](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/configuring_network_settings/configuring-cluster-network-range) — chapter 3, *Configuring network settings* (OCP **4.20**). Same chapter in [4.18](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/configuring_network_settings/configuring-cluster-network-range). |
| **B — dual-stack** | Convert single-stack to dual-stack **after** install (recreate pods). | [Converting to IPv4/IPv6 dual-stack networking](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/ovn-kubernetes_network_plugin/converting-to-dual-stack) — chapter 5 (OCP **4.20**). Same in [4.18](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/ovn-kubernetes_network_plugin/converting-to-dual-stack). |
| **B — NodePort** | Expand `serviceNodePortRange` after install; cannot shrink. | [Configuring the node port service range](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/configuring_network_settings/configuring-node-port-service-range) — chapter 2 (OCP **4.20**). |

Ask docs: narrow table 9.2 so it does not freeze the whole `networking:` object.

### Clash 2 — Join (and transit) subnet: installer + CRD vs OVN procedure

| Side | Quote | Pin |
|------|-------|-----|
| **A — frozen** | `internalJoinSubnet`: “You cannot change the value after installation.” | ABI table 9.2 — same [4.20](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installation-config-parameters-agent) / [4.18](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installation-config-parameters-agent) / [4.22](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installation-config-parameters-agent) URLs as clash 1. |
| **A — CRD godoc (4.18)** | `internalJoinSubnet` / `internalTransitSwitchSubnet`: “The value cannot be changed after installation.” | [Network [operator.openshift.io/v1]](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/operator_apis/network-operator-openshift-io-v1) — *Operator APIs* (OCP **4.18**). Same freeze text in [4.15](https://docs.redhat.com/en/documentation/openshift_container_platform/4.15/html/operator_apis/network-operator-openshift-io-v1). |
| **B — Day-2 patch** | “You can change the join subnet”; `oc patch network.operator.openshift.io cluster` … `internalJoinSubnet`. Up to 30 minutes. | [Configuring OVN-Kubernetes internal IP address subnets](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/ovn-kubernetes_network_plugin/configure-ovn-kubernetes-subnets) — chapter 6 (OCP **4.20**). Same procedure in [4.18](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/ovn-kubernetes_network_plugin/configure-ovn-kubernetes-subnets) and [4.17](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/ovn-kubernetes_network_plugin/configure-ovn-kubernetes-subnets). |

**4.18 → 4.20 drift (API book only):** the [4.20 Operator API](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/operator_apis/network-operator-openshift-io-v1) `internalJoinSubnet` description **no longer** includes “cannot be changed after installation.”
Installer tables **still do** through 4.22.
Ask docs: delete the installer freeze sentence; keep the OVN ch. 6 procedure. Align CRD comments with CNO (join is changeable).

### Clash 3 — CNO “only `gatewayConfig` at runtime” vs later chapters

| Side | Quote | Pin |
|------|-------|-----|
| **A — understatement** | “You can only change the configuration for your cluster network plugin during cluster installation, except for the `gatewayConfig` field that can be changed at runtime as a postinstallation activity.” | [Cluster Network Operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/networking_operators/cluster-network-operator) — chapter 6, after table 6.10 (OCP **4.20**). Same sentence: [4.18 CNO](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/networking_operators/cluster-network-operator). Present since at least [4.14 CNO](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html/networking/cluster-network-operator). |
| **B — IPsec after install** | “You can enable IPsec either during or after installing the cluster.” | [Configuring IPsec encryption](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/network_security/configuring-ipsec-ovn) — chapter 6, *Network security*. Same in [4.18](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/network_security/configuring-ipsec-ovn). |
| **B — overlay MTU** | Dedicated **migration** (not a raw `mtu` patch). | [Changing the MTU for the cluster network](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/advanced_networking/index) — chapter 2, *Advanced networking*. Same chapter in [4.18](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/advanced_networking/index). |
| **B — join/transit** | Clash 2, OVN ch. 6. | URLs above. |

Ask docs: replace the CNO one-liner with a split (frozen vs Day-2 vs migration), or point to those chapters.

### Clash 4 — Geneve port (CNO table omits freeze; IBM states it; old OVN books showed a patch)

| Side | Quote | Pin |
|------|-------|-----|
| **A — frozen (correct)** | `genevePort`: “This value cannot be changed after cluster installation.” | [Installing a cluster on IBM Cloud with customizations](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_on_ibm_cloud/installing-ibm-cloud-customizations) — chapter 5, network customization field table (OCP **4.20**). |
| **A — CNO omission** | `genevePort` is listed with no per-field freeze; the **blanket** “only `gatewayConfig` at runtime” is the only hint. | [CNO ch. 6](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/networking_operators/cluster-network-operator) table 6.3 + the gatewayConfig exception sentence. |
| **B — stale patch (do not follow on 4.20)** | `oc patch` … `genevePort`. | Historical OVN-Kubernetes provider chapters, e.g. [4.11](https://docs.redhat.com/en/documentation/openshift_container_platform/4.11/html/networking/ovn-kubernetes-default-cni-network-provider), [4.8](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/networking/ovn-kubernetes-default-cni-network-provider). CNO has rejected Geneve changes since the option was added ([commit](https://github.com/openshift/cluster-network-operator/commit/f1b60468c936d942cb16769d8088345a7a18eca3)). |

Ask docs: add “cannot change after install” on CNO table 6.3 `genevePort`, same as IBM. Do not restore the old patch.

---

## 4.18 vs 4.20+ (product freeze/thaw)

The **immutability contract did not flip** between 4.18 and 4.20 for the rows this catalog cares about.
CIDR **mask** expand, frozen `hostPrefix`, join **Day-2** patch, dual-stack conversion, IPsec after install, MTU migration, and the installer vs OVN **wording clash** are all already in **4.18** (join patch also in **4.17**).

What **did** move in the docs (not a new CNO behavior):

| Item | 4.18 | 4.20+ |
|------|------|--------|
| ABI `networking:` / `internalJoinSubnet` freeze sentences | Present (ch. **8**) | Present (ch. **9**); still in **4.22** |
| Operator API “cannot be changed after installation” on join/transit | Present | **Dropped** from the [4.20 API book](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/operator_apis/network-operator-openshift-io-v1) field text — installer tables were not updated |
| Service CIDR cannot expand (incl. ServiceCIDR API) | CIDR-expand chapter silent on services in the 4.18 fetch | Called out in [4.20 cluster network range](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/configuring_network_settings/configuring-cluster-network-range) |

Workspace [ovn-kubernetes-install-config](../examples/networking/ovn-kubernetes-install-config/README.md) (Feb 2026) mixed **schema presence** (OKD 4.18 install-config table) with freeze/thaw.
That is a different bug from these RH book clashes.

---

## 4.20 vs 4.22 (latest GA)

Checked the same freeze/thaw chapters on **4.22**: cluster network range, CNO, ABI install-config, FIPS, OVN internal subnets, capabilities.

**No change to the freeze/thaw rules** that this catalog cares about:

- `hostPrefix` still cannot be modified.
- Service CIDR still cannot be expanded (including ServiceCIDR API).
- Cluster CIDR **mask** still expand-only (same base, same `hostPrefix`).
- `networkType` still frozen.
- FIPS still cannot be enabled after first boot.
- `cpuPartitioningMode` still install-only / cannot disable.
- Join / transit / masquerade still have the same Day-2 patches.
- Installer still claims the whole `networking` object and `internalJoinSubnet` cannot change (same clash).
- CNO still says only `gatewayConfig` is the runtime exception (same understatement).

4.22 docs to re-pin if you are on that minor:

- [Configuring the cluster network range](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/configuring_network_settings/configuring-cluster-network-range) — chapter 3
- [Cluster Network Operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/networking_operators/cluster-network-operator) — chapter 6
- [ABI installation configuration parameters](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installation-config-parameters-agent) — chapter 9
- [FIPS](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/installation_overview/installing-fips) — chapter 4
- [OVN internal subnets](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/ovn-kubernetes_network_plugin/configure-ovn-kubernetes-subnets) — chapter 6

4.22 also has a generic [Installation configuration parameters](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/installation_configuration/installation-config-parameters-generic) book (chapter 3) with the same `networking` / join-subnet freeze wording.

**Not claimed:** every new 4.21/4.22 *feature* (operators, UI). Only whether the **immutability contract** moved.

---

## Still not catalogued

- API / Ingress **VIP address moves** on bare metal (keepalived) — specialized; not classified Frozen vs Day-2 in this pass
- Root-disk LUKS / extra partitions as Ignition vs Day-2 MachineConfig (etcd-on-second-disk is a separate note)
- Cloud-only networks (AWS VPC, Azure VNet, GCP subnet) as live vs rebuild
- `credentialsMode` transitions (CCO mint → manual has its own book)
- Hosted control planes / HyperShift
- 4.23 (not GA)

---

Customer handoff dump (frozen + one-way + expand-only): [pre-release-freeze-audit.md](pre-release-freeze-audit.md).

## Read it on a live cluster

```bash
oc get network.config.openshift.io cluster -o yaml
oc get network.operator.openshift.io cluster -o yaml
oc get proxy cluster -o yaml
oc get apiserver cluster -o jsonpath='{.spec.encryption}{"\n"}'
oc get clusterversion version -o jsonpath='{.spec.capabilities}{"\n"}{.status.capabilities}{"\n"}'
oc get featuregate cluster -o jsonpath='{.spec.featureSet}{"\n"}'
oc describe node <node> | grep -A20 Allocatable
oc get kubeletconfig
```

---

## Related

- [pre-release-freeze-audit.md](pre-release-freeze-audit.md) — Handoff dump of live frozen values
- [cluster-network-hostprefix.md](cluster-network-hostprefix.md) — IP slice math
- [OVN-Kubernetes install-config](../examples/networking/ovn-kubernetes-install-config/README.md)
- [vlan-segmentation.md](../examples/networking/vlan-segmentation.md)
- [container-density-overcommit.md](container-density-overcommit.md)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
review:
  status: unreviewed
  notes: "First pass 2026-08-31 against OCP 4.20 product docs + CNO. Not an exhaustive install-config field list; cloud-specific and VIP/disk items left as gaps."
---

# What cannot change after OpenShift install

A working catalog of `install-config.yaml` (and cousin) settings that are **frozen**, **one-way**, or **expand-only** after the cluster exists — versus settings that look install-only in the installer book but have a Day-2 API.

**Audience:** Operators and anyone reviewing an `install-config` before ABI / IPI / UPI, including an agent compiling Red Hat immutability notes.

**Purpose:** Decide what must be right before `openshift-install` / Agent ISO, without treating the installer chapter’s blanket “cannot change after installation” as the whole story.

**Pinned minor:** OpenShift Container Platform **4.20**, OVN-Kubernetes. Re-check the linked chapters on other minors.

---

## How to read this

The installer books all say some version of:

> These settings are used for installation only, and cannot be changed after installation.

That means you cannot re-apply `install-config.yaml`.
It does **not** always mean there is no other supported API.

This catalog uses four statuses:

| Status | Meaning |
|--------|---------|
| **Frozen** | No supported Day-2 change. Rebuild (or live with it). |
| **One-way** | You can turn it *on* (or add) after install, but you cannot turn it *off*. |
| **Expand-only** | You can enlarge a range; you cannot shrink, rename the base, or change the other dimension. |
| **Day-2** | A documented post-install procedure exists (often disruptive). |

When two Red Hat books disagree, this page **prefers the post-install / operator chapter** and notes the clash.

CIDR math (`hostPrefix` vs node count) lives in [cluster-network-hostprefix.md](cluster-network-hostprefix.md) — not repeated here.

---

## Frozen or expand-only (get these right at install)

### Identity and platform

| Field | Status | Notes |
|-------|--------|--------|
| `baseDomain` | **Frozen** | Cluster DNS is `<metadata.name>.<baseDomain>`. Installer chapter; no supported rename. |
| `metadata.name` | **Frozen** | Same. |
| `platform` (type: `baremetal`, `none`, `vsphere`, …) | **Frozen** | You do not convert IPI/UPI platform after the fact. |
| `fips` | **Frozen** | Must be on before the OS first boots. You cannot enable FIPS after deploy. |
| `cpuPartitioningMode` | **Frozen** | Enable only at install; **cannot disable** later. Does not pin which CPUs workloads use. |
| `featureSet: TechPreviewNoUpgrade` | **Frozen** (once on) | Cannot be undone; blocks minor upgrades. Do not use on production. |
| `compute` / `controlPlane` `architecture` | **Treat as frozen** | Installer: mixed arch in one install is not supported. Heterogeneous-arch *additions* are a separate feature — not catalogued here. |

`fips`: [Support for FIPS cryptography](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installation_overview/installing-fips) — chapter 4, *Installation overview* (OCP 4.20).

Identity / platform / `cpuPartitioningMode`: [Installation configuration parameters for the Agent-based Installer](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installation-config-parameters-agent) — chapter 9, *Installing an on-premise cluster with the Agent-based Installer* (OCP 4.20). Other platform books use the same wording.

### Cluster network (pods and services)

| Field | Status | Notes |
|-------|--------|--------|
| `networking.networkType` | **Frozen** | OVN-Kubernetes only at install in 4.20. CNO: cannot change after install. |
| `networking.clusterNetwork[].cidr` **base** | **Frozen** | You cannot change `100.100.0.0` to another network. |
| `networking.clusterNetwork[].cidr` **mask** | **Expand-only** | OVN-K: `/15` → `/14` (same base, smaller prefix number). More **nodes**, not more IPs per node. |
| `networking.clusterNetwork[].hostPrefix` | **Frozen** | CNO rejects changes. Per-node pod IP slice is install-time. |
| `networking.serviceNetwork` | **Frozen** | Cannot expand via CNO or ServiceCIDR API. Size ClusterIPs at install. |
| `ovnKubernetesConfig.genevePort` | **Frozen** | Default 6081. Product text: cannot change after install. |

Detail and tables: [cluster-network-hostprefix.md](cluster-network-hostprefix.md).

Product: [Configuring the cluster network range](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/configuring_network_settings/configuring-cluster-network-range) — chapter 3, *Configuring network settings* (OCP 4.20); [Cluster Network Operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/networking_operators/cluster-network-operator) — chapter 6, *Networking Operators* (OCP 4.20).

`genevePort`: same CNO field table (also in [Installing a cluster on IBM Cloud with customizations](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_on_ibm_cloud/installing-ibm-cloud-customizations) — chapter 5, *Installing on IBM Cloud*).

### Capabilities (one-way)

| Field | Status | Notes |
|-------|--------|--------|
| `capabilities` (optional operators/components) | **One-way** | You **may enable** after install. You **cannot disable** a capability once it is on. |

[Cluster capabilities](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installation_overview/cluster-capabilities) — chapter 3, *Installation overview* (OCP 4.20).

---

## Day-2 (do not treat the installer blanket as frozen)

These appear under `networking` / OVN in `install-config` (or CNO) but **4.20 has a post-install procedure**.

| Field | Status | Disruption |
|-------|--------|------------|
| Cluster network CIDR **mask** | Expand-only | CNO rollout (~30 min); proxy clusters may reboot nodes |
| `maxPods` / kubelet | Day-2 `KubeletConfig` | Rolling drain + reboot |
| Dual-stack (add IPv6 or IPv4 block) | Day-2 | Patch Network (+ Infrastructure on IPI); recreate pods |
| `internalJoinSubnet` | **Day-2** | CNO; up to ~30 min. **Clash:** installer parameter text says you cannot change it after install. Prefer the OVN chapter. |
| `internalTransitSwitchSubnet` | Day-2 | Same class of patch |
| `gatewayConfig.ipv4.internalMasqueradeSubnet` | Day-2 | Documented as post-install |
| `gatewayConfig` (e.g. `ipForwarding`, routing) | Day-2 | CNO: `gatewayConfig` is the runtime exception |
| IPsec (`ipsecConfig.mode`) | Day-2 | Enable/disable after install; drop overlay MTU by 46 first for ESP |
| Cluster / overlay **MTU** | Day-2 | Dedicated migration; node reboots. **Clash:** older CNO/IBM tables said MTU cannot change. Prefer *Advanced networking* ch. 2. |
| `serviceNodePortRange` | Day-2 | Network config API: can be updated after install |
| Worker `replicas` / adding nodes | Day-2 | Scale MachineSets / BMH / Agent — not an overlay CIDR change |
| Pull secret, SSH keys, proxy, IDMS/ICSP | Day-2 | Global pull secret, MachineConfig, Proxy CR, ImageDigestMirrorSet |
| `machineNetwork` | Installer-consumed | Used for VIP/discovery at install; not a live CR. Workload VLANs are Multus. See [vlan-segmentation.md](../examples/networking/vlan-segmentation.md). |

Join / transit / masquerade: [Configuring OVN-Kubernetes internal IP address subnets](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/ovn-kubernetes_network_plugin/configure-ovn-kubernetes-subnets) — chapter 6, *OVN-Kubernetes network plugin* (OCP 4.20).

IPsec: [Configuring IPsec encryption](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/network_security/configuring-ipsec-ovn) — chapter 6, *Network security* (OCP 4.20).

MTU: [Changing the MTU for the cluster network](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/advanced_networking/index) — chapter 2, *Advanced networking* (OCP 4.20).

Dual-stack: [Converting to IPv4/IPv6 dual-stack networking](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/ovn-kubernetes_network_plugin/converting-to-dual-stack) — chapter 5, *OVN-Kubernetes network plugin* (OCP 4.20).

`maxPods`: [Working with nodes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/nodes/working-with-nodes) — section 6.5 (OCP 4.20).

---

## Document clashes (do not copy blindly)

| Topic | Installer / old CNO text | Prefer |
|-------|--------------------------|--------|
| Whole `networking:` object | “You cannot change parameters specified by the `networking` object after installation.” | Split: `hostPrefix` / service CIDR / `networkType` frozen; CIDR **mask** expand-only; OVN internals often Day-2. |
| `internalJoinSubnet` | Install-config: “You cannot change the value after installation.” | OVN plugin ch. 6 patch procedure. |
| Overlay MTU | Historic CNO: cannot change | *Advanced networking* MTU migration (OVN-K, reboots). |
| Dual-stack | Some local notes marked enablement ❌ | 4.20 conversion chapter exists. |
| IPsec | Some CNO snippets: set at create only | 4.20: enable during **or after** install. |

Workspace pages that still mix “not in install-config schema” with “immutable”: [INSTALL-TIME-VS-POST-INSTALL.md](../examples/networking/ovn-kubernetes-install-config/INSTALL-TIME-VS-POST-INSTALL.md) and [QUICK-REFERENCE.md](../examples/networking/ovn-kubernetes-install-config/QUICK-REFERENCE.md) (MTU/Geneve). Prefer **this** note + [cluster-network-hostprefix.md](cluster-network-hostprefix.md) for freeze/thaw.

---

## What this catalog does not cover yet

Not claimed frozen or Day-2 until a 4.20 chapter is checked:

- API / Ingress VIP moves, `publish: Internal|External` after install
- Root disk / extra partition / etcd on a second disk (install-time Ignition vs Day-2 MachineConfig)
- Cloud-only fields (AWS VPC, Azure VNet, vSphere failure domains as *live* vs rebuild)
- Proxy, additional trust bundle, and disconnected mirror *as a full procedure list* (they are Day-2; details elsewhere)
- Hosted control planes / HyperShift (different objects)

---

## Read it on a live cluster

```bash
# Overlay + hostPrefix + services
oc get network.config.openshift.io cluster -o yaml

# CNO (join/transit/masquerade, geneve, MTU, IPsec)
oc get network.operator.openshift.io cluster -o yaml

# FIPS (nodes)
oc get machineconfig 99-worker-fips 99-master-fips --ignore-not-found
# RHCOS: fips=1 on kernel args / /proc/sys/crypto/fips_enabled via oc debug

# Capabilities
oc get clusterversion version -o jsonpath='{.spec.capabilities}{"\n"}{.status.capabilities}{"\n"}'

# Feature set
oc get featuregate cluster -o jsonpath='{.spec.featureSet}{"\n"}'

# maxPods
oc describe node <node> | grep -A20 Allocatable
oc get kubeletconfig
```

---

## Related

- [cluster-network-hostprefix.md](cluster-network-hostprefix.md) — IP slice math, `/15` × `hostPrefix` node counts
- [OVN-Kubernetes install-config](../examples/networking/ovn-kubernetes-install-config/README.md) — overlap checklist, `install-config` shape
- [vlan-segmentation.md](../examples/networking/vlan-segmentation.md) — `machineNetwork` vs day-2 Multus
- [container-density-overcommit.md](container-density-overcommit.md) — requests/CRO/VPA, not CIDRs

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

# OpenShift VLAN Network Segmentation

> **Audience:** Platform operators managing OpenShift clusters with bare-metal or user-provisioned infrastructure
> **Purpose:** What VLANs configured at install time become on the cluster, and how to manage VLAN segmentation day-2

---

## The Short Answer

**Install-time VLANs** — The `machineNetwork` field in install-config.yaml specifies the CIDR of the physical network the cluster nodes live on. If those nodes are on a VLAN, the VLAN is handled by the physical network and BMC/Redfish provisioning network. OpenShift does **not** create any Kubernetes custom resources from `machineNetwork`. It simply uses the CIDR for VIP placement and cluster discovery.

**Day-2 VLAN segmentation for workloads** — Once the cluster is running, pod-level VLAN attachment is managed through **Multus CNI** + **NetworkAttachmentDefinition** CRDs. These are fully mutable: create, edit, or delete them after installation. No cluster restart required.

---

## Install-Time: What Gets Created

The install-config networking block looks like this:

```yaml
networking:
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16
  machineNetwork:
  - cidr: 192.168.100.0/24    # <-- physical VLAN where nodes live
```

**What happens at install time:**

| Field | What it does | CR on the cluster? |
|-------|-------------|---------------------|
| `clusterNetwork` | Pod IP pool | Written to `network.config.openshift.io` (NetworkConfig CR) |
| `serviceNetwork` | Service IP pool | Written to `network.config.openshift.io` |
| `machineNetwork` | Physical node network CIDR | **Not a CR** — used by installer only for VIP validation and node discovery |
| `networkType` | CNI plugin selection | Written to `network.config.openshift.io` |
| `ovnKubernetesConfig` | OVN-K internals (MTU, subnets, IPsec) | Written to `network.operator.openshift.io` (NetworkOperator CR) |

**Bottom line:** There are no Kubernetes resources called "VLANs" created from the install config. The `machineNetwork` is consumed by the installer to validate VIP placement. After install, it has no operational effect.

---

## Day-2: Adding VLANs for Workloads

When you want pods to connect to additional VLANs on a running cluster, you use **Multus CNI** (enabled by default on OpenShift) with **NetworkAttachmentDefinition (NAD)** CRDs.

### 1. Verify Multus is available

```bash
# Should show available
oc get network-attachment-definitions -n openshift-multus

# Or check the operator
oc get co multus
```

### 2. Create a NetworkAttachmentDefinition

Each NAD defines one VLAN + IPAM strategy:

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: vlan-100
  namespace: default
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens3",
      "mode": "bridge",
      "vlan": 100,
      "ipam": {
        "type": "whereabouts",
        "range": "10.100.0.0/24",
        "range_start": "10.100.0.10",
        "range_end": "10.100.0.50"
      }
    }
```

**Key decisions:**

| Field | Options | When to choose |
|-------|---------|----------------|
| `type` | `macvlan` or `ipvlan` | `macvlan` — pods appear as separate L2 identities; `ipvlan` — lighter, shared MAC, L2/L3 mode |
| `mode` | `bridge`, `private`, `vepa`, `passthru` | `bridge` for most cases (pods on same host can talk); `private` when host isolation is needed |
| `ipam.type` | `whereabouts`, `dhcp`, `static` | `whereabouts` for automatic IP pools across the cluster; `dhcp` if a DHCP server sits on the VLAN; `static` when IPs are pre-assigned |
| `master` | Node interface name | Typically `ens3`, `ens4f0`, or whatever physical NIC carries the VLAN on that node |

### 3. Attach a pod to the VLAN

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: db-app
  namespace: default
  annotations:
    k8s.v1.cni.cncf.io/networks: vlan-100
spec:
  containers:
  - name: db
    image: postgres:15
```

The pod gets a second interface (e.g., `net1`) tagged with VLAN 100, receiving an IP from the defined pool.

### 4. Verify

```bash
# NAD is registered
oc get network-attachment-definitions

# Pod has additional interface
oc exec db-app -- ip addr show net1

# Traffic is on the VLAN (from a node)
oc debug node/worker-0
chroot /host
tcpdump -i ens3 -e -n vlan 100
```

---

## Adding and Removing VLANs After Install

All of this is standard Kubernetes CRD operations. No cluster maintenance windows needed.

**Add a VLAN** — `oc apply -f nad-vlan-200.yaml`

**Remove a VLAN** — `oc delete network-attachment-definition vlan-100`
Existing pods on that VLAN keep their interfaces; new pods simply can't attach.

**Change a VLAN's IP pool** — Edit the NAD, then restart existing pods that need new IPs.

**Change the physical interface** — Update the `master` field in the NAD, then restart attached pods. Note: not all nodes may have the same interface name.

---

## NetworkSegments (Multus NW Platform Plugin)

There is a second Multus ecosystem resource called `NetworkSegment` (from the [Network Plumbing Working Group](https://github.com/k8snetworkplumbingwg)). It provides a higher-level abstraction that maps a logical network name to a VLAN ID on the physical switch, potentially managed by SDN controllers or automation tools.

This is **not** installed by default with OpenShift. If you're not explicitly using a Network Plumbing Controller (e.g., NMN Controller, SR-IOV Network Operator), you likely aren't using NetworkSegments. The NAD approach above is the default OpenShift pattern.

---

## Cross-References

- [NetworkAttachmentDefinition (NAD) guide](./examples/network-attachment-definitions/) — NAD configurations, IPAM strategies, troubleshooting
- [OVN-Kubernetes install config](./examples/ovn-kubernetes-install-config/) — Cluster-level network configuration at install time
- [AAP SSH MTU issues](./troubleshooting/aap-ssh-mtu-issues/) — MTU considerations for VLAN-tagged pod traffic
- [CoreOS networking issues](./troubleshooting/coreos-networking-issues/) — Node-level network verification

---

*This document was created with AI assistance (pi / qwen3.6-35b-a3b) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

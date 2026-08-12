---
review:
  status: unreviewed
  notes: "Design doc drafted from an architecture discussion; not yet implemented or reviewed by network/platform teams."
---

# Dedicated Cross-Datacenter Replication Network — Bare-Metal OpenShift

**Audience:** Platform engineers and peers reviewing a proposed network architecture before implementation — not yet a build guide.

**Purpose:** Describe the shape of a dedicated, bonded-NIC network between two bare-metal OpenShift clusters in different datacenters, used to carry replication traffic (e.g., storage mirroring, cross-cluster application replication) without bleeding onto general cluster/management traffic. Workload-agnostic — see [Kafka Cluster Linking](../messaging/kafka/cross-dc-cluster-linking.md) for a concrete application of this pattern.

**Need the whole picture in one doc?** See [Cross-DC architecture overview](../messaging/kafka/cross-dc-architecture-overview.md) — combines this doc and the Kafka Cluster Linking doc for sharing outside the repo.

**Related:**

- [VLAN segmentation](vlan-segmentation.md) — install-time vs day-2 Multus VLANs
- [NetworkAttachmentDefinition (NAD) guide](network-attachment-definitions/README.md) — macvlan/SR-IOV, IPAM
- [NVMe/TCP storage network](../../troubleshooting/nvme-tcp-storage-network/README.md) — contrasting pattern: dual NIC, **no bond**, for storage multipath
- [MachineConfig pools](../../notes/machine-config-pools.md) — custom pool targeting for host-level config

---

## On this page

- [Problem shape](#problem-shape)
- [Layer map](#layer-map)
- [Layer 1–2: host network](#layer-12-host-network)
- [Layer 3: routing](#layer-3-routing)
- [Layer 2/3: pod attachment via Multus](#layer-23-pod-attachment-via-multus)
- [Securing the secondary network: MultiNetworkPolicy](#securing-the-secondary-network-multinetworkpolicy)
- [Anti-patterns](#anti-patterns)
- [Verification checklist](#verification-checklist)
- [Open questions to confirm before implementing](#open-questions-to-confirm-before-implementing)

---

## Problem shape

Two bare-metal OpenShift clusters, one per datacenter, need a **dedicated, isolated** network path for bulk replication traffic — separate from management/API/OVN pod traffic. Each node has two NICs on **two different physical cards** (slot A, slot B), intended for HA via bonding.

This is a **third network**, distinct from both the cluster's machine network and any storage network:

| Network | Typical pattern |
|---|---|
| Management / API / OVN | Existing machine network |
| Storage (NVMe/TCP, etc.) | Two independent NICs, **no bond** — see [NVMe/TCP guide](../../troubleshooting/nvme-tcp-storage-network/README.md) |
| **Cross-DC replication** | Bonded NIC pair + VLAN + routed subnet — this doc |

**Before building this:** confirm whether the two NICs per node are genuinely new/unconfigured, or whether they're existing NICs already bonded for something else and this is really "add a VLAN to an existing bond." The two scenarios have very different bandwidth-isolation and fault-isolation properties — check `nmcli connection show` / `ip -d link show` / `oc get nns` on a target node rather than assuming.

---

## Layer map

```text
L7  Application         Kafka, storage replication protocol, etc. — workload-specific
L4  Transport            TCP session, dedicated listener/port
L3  Network              Routed subnets per DC, static route (not default gateway)
L2  Data link            Bond (two cards) + VLAN tag
L1  Physical             Two NICs, two cards, dedicated fiber/circuit
```

Pod attachment (Multus) sits at L2/L3 and is the layer most often skipped by mistake — see below.

---

## Layer 1–2: host network

Prefer **NMState / `NodeNetworkConfigurationPolicy`** over raw MachineConfig/Butane if the `kubernetes-nmstate` operator is available — it's day-2 mutable (no MCO drain/reboot for most changes) and gives you `NodeNetworkState` to verify what actually landed. Fall back to Butane/Ignition MachineConfig only if nmstate isn't installed.

```yaml
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: repl-network
spec:
  nodeSelector:
    node-role.kubernetes.io/repl-gateway: ""   # only nodes actually cabled for this
  desiredState:
    interfaces:
      - name: bond-repl
        type: bond
        state: up
        link-aggregation:
          mode: active-backup      # LACP (802.3ad) only if the local ToR pair supports it end-to-end
          port:
            - ens4f0                # slot A, port 1
            - ens5f0                # slot B, port 1
      - name: bond-repl.200
        type: vlan
        state: up
        vlan:
          base-iface: bond-repl
          id: 200
        ipv4:
          enabled: true
          address:
            - ip: 10.200.1.11
              prefix-length: 26
          dhcp: false
```

**Decisions to nail down here, in order of how often they're gotten wrong:**

1. **Node targeting.** If only a subset of nodes have this NIC layout (e.g., dedicated gateway/broker nodes), target them with a label + `nodeSelector`, not the default `worker` pool. Applying this cluster-wide to nodes without the matching hardware will fail or misconfigure.
2. **Interface naming stability.** Kernel interface names (`ens4f0`, etc.) depend on PCI enumeration order and can differ across otherwise-identical hardware. For a small number of specific nodes this is manageable with a sanity check; at fleet scale, match by MAC/PCI path via `systemd.link` rather than assuming names are consistent.
3. **Bonding mode.** `active-backup` works with any switch. `802.3ad`/LACP requires every hop in the bond to participate — fine if the bond terminates at your own local ToR pair, **not** viable if anyone assumes the bond itself spans the WAN (it doesn't; the WAN segment is routed, not bonded).

---

## Layer 3: routing

**The most common mistake in this whole design:** setting the node's **default route** on the replication interface instead of a route scoped to the remote subnet. A default route on this interface sends *all* egress traffic (image pulls, DNS, API calls) out over a link sized, firewalled, and provisioned for one purpose only — and it usually breaks connectivity outright, since the replication link typically can't reach the internet or the cluster's normal DNS/API path.

```yaml
routes:
  config:
    - destination: 10.200.2.0/26      # remote DC's replication subnet — NOT 0.0.0.0/0
      next-hop-address: 10.200.1.1
      next-hop-interface: bond-repl.200
# deliberately no default-route entry on this interface
```

**L3 routed, not L2 stretched.** Each DC gets its own subnet on this VLAN; a router/gateway pair exchanges the routes. Don't stretch one VLAN/subnet across both DCs "for simplicity" — L2 stretch at distance introduces STP, MAC-learning, and failure-domain problems that routed L3 avoids entirely, and nothing about this use case requires it.

**MTU:** confirm what the WAN circuit actually supports end-to-end (`ping -M do -s <size> <remote-ip>`) before assuming jumbo frames survive the full path.

---

## Layer 2/3: pod attachment via Multus

A MachineConfig/NNCP configures the **host**. It does nothing for pods on the default OVN network — pods don't automatically see this interface, and OVN-Kubernetes **SNATs pod egress to the node's primary (machine-network) IP** before the routing table is consulted. So even though the host has a correct route to the remote /26 via `bond-repl.200`, a pod on the default network reaching that destination gets routed over the right interface but with the **wrong source IP** — breaking return routing symmetry and complicating firewall rules that expect traffic sourced from the replication subnet specifically.

The fix: attach the workload's pod directly to the VLAN via a Multus `NetworkAttachmentDefinition`, giving it a real IP in the replication subnet.

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: repl-net
  namespace: <workload-namespace>
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "bond-repl.200",
      "mode": "bridge",
      "ipam": {
        "type": "whereabouts",
        "range": "10.200.1.0/26",
        "range_start": "10.200.1.20",
        "range_end": "10.200.1.60"
      }
    }
```

**macvlan vs ipvlan:** `macvlan` (each pod gets its own MAC) is the common default. If many pods per node share this VLAN and the ToR does MAC-count/port-security limiting, switch to `ipvlan` mode `l2` instead — shares the host's MAC, avoids MAC-table growth.

**hostNetwork as an alternative:** if the workload is a host-level daemon (not a typical pod) or already runs with `hostNetwork: true`, it shares the host's network namespace directly and the host route alone is sufficient — no Multus needed for that specific workload.

---

## Securing the secondary network: MultiNetworkPolicy

Standard Kubernetes `NetworkPolicy` **only governs the default pod network** — it has no effect on the Multus-attached secondary interface. Without `MultiNetworkPolicy`, anything attached to this NAD can reach anything else attached to it, with zero in-cluster enforcement; you'd be relying entirely on physical VLAN isolation and upstream switch/router ACLs.

**Enable the capability:**

```yaml
apiVersion: operator.openshift.io/v1
kind: Network
metadata:
  name: cluster
spec:
  useMultiNetworkPolicy: true
```

**Opt the NAD in:**

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: repl-net
  namespace: <workload-namespace>
  annotations:
    k8s.v1.cni.cncf.io/policy-for: <workload-namespace>/repl-net
spec:
  # ...same config as above
```

**Restrict traffic on it:**

```yaml
apiVersion: k8s.cni.cncf.io/v1beta1
kind: MultiNetworkPolicy
metadata:
  name: repl-net-restrict
  namespace: <workload-namespace>
  annotations:
    k8s.v1.cni.cncf.io/policy-for: <workload-namespace>/repl-net
spec:
  podSelector:
    matchLabels:
      <label-selecting-the-workload>
  policyTypes: [Ingress, Egress]
  ingress:
    - from: [{ipBlock: {cidr: 10.200.2.0/26}}]
      ports: [{protocol: TCP, port: <replication-port>}]
  egress:
    - to: [{ipBlock: {cidr: 10.200.2.0/26}}]
      ports: [{protocol: TCP, port: <replication-port>}]
```

Verify enforcement explicitly — spin up a debug pod on the same NAD without the matching label and confirm it *can't* reach the workload's replication port. `MultiNetworkPolicy` misconfiguration (missing `policy-for` annotation on either the NAD or the policy) tends to fail open silently.

---

## Anti-patterns

| Anti-pattern | Why it breaks things |
|---|---|
| Default gateway on the replication NIC | Bleeds all egress traffic onto a link sized for one purpose; usually breaks connectivity |
| Assuming pods on the default network use the new NIC automatically | OVN SNAT + default routing table means they don't, without Multus |
| L2-stretching a subnet across DCs "for simplicity" | STP, MAC-learning, and failure-domain problems at distance |
| LACP bond assumed to span the WAN | The WAN carrier doesn't participate in your LACP; bond terminates locally, WAN segment is routed |
| MachineConfig/NNCP applied to the default `worker` pool when only some nodes have the hardware | Fails to render, or misconfigures nodes without the matching NICs |
| No `MultiNetworkPolicy` on the secondary interface | Standard `NetworkPolicy` doesn't see it; no in-cluster enforcement at all |

---

## Verification checklist

1. Confirm current NIC/bond state on target nodes before assuming new vs. existing (`nmcli connection show`, `oc get nns`).
2. `curl`/`nc` the remote replication IP:port from a debug pod on the NAD — confirms L2–L4 before the workload is involved.
3. Check the workload pod's `k8s.v1.cni.cncf.io/network-status` annotation — confirms it actually got the second interface and correct IP.
4. Fail one leg of the bond; confirm the replication path stays reachable.
5. Confirm `MultiNetworkPolicy` actually blocks an unauthorized pod on the same NAD.
6. `ping -M do -s <size>` across the full path to confirm real MTU.

---

## Open questions to confirm before implementing

- Are the two NICs per node genuinely new/unconfigured, or is this a VLAN added to an already-existing bond used for other traffic? (Changes bandwidth and fault isolation — see [Problem shape](#problem-shape).)
- Do all nodes have this NIC layout, or only a subset (dedicated gateway/broker nodes)? Determines custom `MachineConfigPool`/NNCP `nodeSelector` scope.
- Does the local ToR pair support LACP, or should the bond use `active-backup`?
- What MTU does the WAN circuit actually support end-to-end?
- Is `kubernetes-nmstate` already installed, or does this need to go through raw MachineConfig/Butane instead?

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

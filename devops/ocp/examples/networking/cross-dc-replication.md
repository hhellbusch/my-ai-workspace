---
review:
  status: unreviewed
  notes: "Design doc drafted from an architecture discussion; not yet implemented or reviewed by network/platform teams."
---

# Dedicated Cross-Datacenter Replication Network — Bare-Metal OpenShift

**Audience:** Platform engineers and peers reviewing a proposed network architecture before implementation — not yet a build guide.

**Purpose:** Describe the shape of a dedicated, bonded-NIC network between two bare-metal OpenShift clusters in different datacenters, used to carry replication traffic without bleeding onto general cluster/management traffic. Workload-agnostic network depth — **start at the [architecture overview](../messaging/kafka/cross-dc-architecture-overview.md)** for path comparison and Kafka context.

**Related:**

- [Cross-DC network test framework](cross-dc-network-test/README.md) — automates the verification checklist below against two live clusters, isolated from Kafka
- [Cross-DC rollout inventory](cross-dc-rollout/README.md) — inventory YAML renders NNCP values, test env, and Kafka net Helm values
- [VLAN segmentation](vlan-segmentation.md) — install-time vs day-2 Multus VLANs
- [NetworkAttachmentDefinition (NAD) guide](network-attachment-definitions/README.md) — macvlan/SR-IOV, IPAM
- [Cross-DC ingress / Route alternative](../messaging/kafka/cross-dc-ingress-alternative.md) — skip Multus pod attachment; use dedicated `IngressController` + CFK Routes (Kafka Cluster Linking)
- [NVMe/TCP storage network](../../troubleshooting/nvme-tcp-storage-network/README.md) — contrasting pattern: dual NIC, **no bond**, for storage multipath
- [MachineConfig pools](../../notes/machine-config-pools.md) — custom pool targeting for host-level config
- [OpenShift: Secondary networks — attaching a pod](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/multiple_networks/secondary-networks#nw-multus-advanced-annotations_attaching-pod) — `default-route` override, static IP/MAC annotations
- [OpenShift: Secondary networks — configuring multi-network policy](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/multiple_networks/secondary-networks#configuring-multi-network-policy)
- [OpenShift: MultiNetworkPolicy API reference](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/network_apis/multinetworkpolicy-k8s-cni-cncf-io-v1beta1)

---

## On this page

- [Problem shape](#problem-shape)
- [How workloads attach (path fork)](#how-workloads-attach-path-fork)
- [Layer map](#layer-map)
- [Layer 1–2: host network](#layer-12-host-network)
- [MTU — parent-first and path constraints](#mtu--parent-first-and-path-constraints)
- [Layer 3: routing](#layer-3-routing)
- [Layer 2/3: pod attachment via Multus](#layer-23-pod-attachment-via-multus)
- [Securing the secondary network: MultiNetworkPolicy](#securing-the-secondary-network-multinetworkpolicy)
- [Anti-patterns](#anti-patterns)
- [Verification checklist](#verification-checklist)
- [Pre-flight before network verification](../messaging/kafka/cross-dc-architecture-overview.md#pre-flight-before-network-verification)
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

## How workloads attach (path fork)

**Host bond/VLAN/route (below) is required for any design that uses the dedicated replication VLAN.**

How pods (or ingress routers) use that VLAN depends on the replication mechanism — compared in full in the [architecture overview](../messaging/kafka/cross-dc-architecture-overview.md#choose-your-replication-path):

| Mechanism | Pod/workload attachment | This doc covers |
|---|---|---|
| **Multus direct** | Broker pod gets macvlan NAD on `bond-repl.200` | Host layers + [Multus](#layer-23-pod-attachment-via-multus) + [MNP](#securing-the-secondary-network-multinetworkpolicy) |
| **Dedicated ingress shard** | HAProxy on repl-gateway nodes; brokers stay on OVN | Host layers only — ingress depth in [cross-dc-ingress-alternative.md](../messaging/kafka/cross-dc-ingress-alternative.md) |

Kafka-specific listener and Cluster Link semantics: [cross-dc-cluster-linking.md](../messaging/kafka/cross-dc-cluster-linking.md).

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

**NNCP scope:** examples in this doc and the [NNCP Helm chart](../messaging/kafka/cross-dc-nncp-helm/README.md) define **only** the replication bond/VLAN/route. The **management / machine network** (default route, API, OVN) is usually configured at **cluster install** and often **does not appear in any NNCP** — it is still on the node. To see the true layout, use `oc get nns <node>` (`NodeNetworkState`) or inspect the host (`nmcli`, `ip link`) — not the replication NNCP YAML alone.

**Decisions to nail down here, in order of how often they're gotten wrong:**

1. **Node targeting.** If only a subset of nodes have this NIC layout (e.g., dedicated gateway/broker nodes), target them with a label + `nodeSelector`, not the default `worker` pool. Applying this cluster-wide to nodes without the matching hardware will fail or misconfigure.
   **If every node needs a unique static IP** on this interface (e.g., the workload runs fleet-wide, not on a small gateway subset), a single role-based NNCP won't do it — NMState applies identical `desiredState`, including the IP, to every node it matches. The only NNCP-native fix is one policy per node via `kubernetes.io/hostname`. See [Cross-DC replication NNCP (Helm)](../messaging/kafka/cross-dc-nncp-helm/README.md) for a template that renders this from a node list instead of hand-authoring each CR.
2. **Interface naming stability.** Kernel interface names (`ens4f0`, etc.) depend on PCI enumeration order and can differ across otherwise-identical hardware. For a small number of specific nodes this is manageable with a sanity check; at fleet scale, match by MAC/PCI path via `systemd.link` rather than assuming names are consistent.
3. **Bonding mode.** `active-backup` works with any switch. `802.3ad`/LACP requires every hop in the bond to participate — fine if the bond terminates at your own local ToR pair, **not** viable if anyone assumes the bond itself spans the WAN (it doesn't; the WAN segment is routed, not bonded).

---

## MTU — parent-first and path constraints

Two separate rules govern MTU on the replication VLAN.
Both need answers before you pick `expectedMtu` in [rollout inventory](cross-dc-rollout/inventory-dc-a.example.yaml) or assume jumbo frames on the replication path.

### Parent-first constraint (on the host)

A VLAN subinterface cannot send larger IP packets than its **parent bond** can carry on the wire.

```text
bond-repl          ← parent — sets the frame ceiling
  └── bond-repl.200   ← VLAN — IP MTU must fit inside parent (+ 802.1Q tag on egress)
        └── macvlan pods (Multus master) ← inherit this path's MTU
```

On egress, the host typically emits an **802.1Q-tagged** frame on `bond-repl` for traffic from `bond-repl.200`.
Practical rule: set **`bond-repl` MTU first**, then **`bond-repl.200` MTU** to the IP MTU you want (often the same numeric value, e.g. `9000`, when NICs and switches support jumbo).
You **cannot** configure `bond-repl.200` at `9000` while `bond-repl` remains at `1500` — raise the parent before the VLAN.

The [NNCP Helm chart](../messaging/kafka/cross-dc-nncp-helm/README.md) sets bond + VLAN MTU from inventory `replicationNetwork.expectedMtu` when rendered via [render-config.py](cross-dc-rollout/render-config.py).
After apply, confirm with `oc debug node/<n> -- chroot /host ip link show bond-repl bond-repl.200`.

### Path MTU constraint (end-to-end)

Effective MTU for replication traffic is the **minimum** across **every hop** on the **replication path only**:

```text
NIC → bond-repl → ToR (VLAN 200) → … → inter-DC link → … → remote bond-repl.200 → remote pod net1
```

If any hop on that path is capped at 1500, the replication path is 1500 — even when local NICs and switches support 9000.

This is **independent of the management / OVN network.**
Management (`eth0`, machine network, cluster overlay) can stay at 1500 end-to-end while the **dedicated replication bond + VLAN 200** is engineered separately for jumbo — because they are different interfaces and usually different physical paths.
Raising replication MTU does not change OVN overlay MTU; see [OVN install-config MTU](ovn-kubernetes-install-config/README.md) only for the default pod network.

| Scenario | What to configure |
|---|---|
| WAN on VLAN 200 supports **1500** only | `expectedMtu: 1500` on bond, VLAN, and in tests — jumbo locally buys nothing across the WAN |
| WAN + switches on VLAN 200 support **9000** both ways | `expectedMtu: 9000` on **bond-repl and bond-repl.200 on every node**, jumbo on switches/routers for VLAN 200, then verify |
| Unsure | Measure — do not assume |

### Verification

Inventory field `replicationNetwork.expectedMtu` drives:

1. **NNCP** — host bond + VLAN MTU (when rendered)
2. **Network test** — test 5 `ping -M do` sweep against `DCx_EXPECTED_MTU` ([cross-dc-network-test](cross-dc-network-test/README.md))

Run the sweep **from a Multus test pod** on the replication NAD toward the remote DC — that exercises the same path brokers use on `net1`, not just host `ping` from `oc debug node`.

```bash
# Example: probe max unfragmented payload toward remote test pod IP
# (exact command is in run-network-test.sh test 5)
ping -M do -s $(( EXPECTED_MTU - 28 )) <remote-repl-ip>
```

If PMTUD breaks (firewall drops ICMP), TCP replication can stall with black-hole symptoms — align WAN/firewall policy with path MTU or fix MSS; see [MULTINETWORKPOLICY.md](../messaging/kafka/cross-dc-kafka-net-helm/MULTINETWORKPOLICY.md) (ICMP not allowed on broker `net1` by default).

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

**MTU:** see [MTU — parent-first and path constraints](#mtu--parent-first-and-path-constraints) — confirm end-to-end path MTU before assuming jumbo frames; inventory `expectedMtu` and network test 5 encode the chosen value.

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

**Ingress / Route as an alternative (Kafka):** for Confluent Cluster Linking on CFK, a **dedicated `IngressController` shard** on the replication VLAN plus CFK `externalAccess.type: route` avoids Multus pod attachment entirely — brokers stay on OVN; replication traffic enters via HAProxy on the repl subnet.
Trade-offs, DNS/VIP requirements, and security: [cross-dc-ingress-alternative.md](../messaging/kafka/cross-dc-ingress-alternative.md).
Host NNCP on repl-gateway nodes is still required for router frontend addressing.

**The pod-level version of the "no default route" rule:** the same mistake from [Layer 3](#layer-3-routing) has a pod-scoped equivalent. The extended JSON form of the `k8s.v1.cni.cncf.io/networks` annotation accepts a `default-route` key per attachment — leave it unset for `repl-net`. Left unset, the pod's default route stays on the primary (OVN) interface as normal, and `repl-net` only carries a route to its own subnet, mirroring the host-level NNCP config. Confirm via `k8s.v1.cni.cncf.io/network-status` on the pod: the `repl-net` entry should have no `"default-route"` key. ([Ref](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/multiple_networks/secondary-networks#nw-multus-advanced-annotations_attaching-pod))

**Static IP/MAC as an alternative to whereabouts:** macvlan supports per-pod pinning via chained `static` IPAM and the extended Multus pod annotation. **Cluster Linking does not require static IPs** — it requires correct advertised Multus addresses. Compare modes in [BROKER-IPAM.md](../messaging/kafka/cross-dc-kafka-net-helm/BROKER-IPAM.md).

```json
{
  "cniVersion": "0.3.1",
  "name": "repl-net-static",
  "plugins": [
    {
      "type": "macvlan",
      "capabilities": { "ips": true },
      "master": "bond-repl.200",
      "mode": "bridge",
      "ipam": { "type": "static" }
    },
    {
      "capabilities": { "mac": true },
      "type": "tuning"
    }
  ]
}
```

The pod requests its address via `ips` / `routes` in `k8s.v1.cni.cncf.io/networks`. **Whereabouts** keeps one NAD and a pool; **static** trades pool simplicity for predictable per-replica IPs — useful when firewalls or link config reference specific addresses, not just the subnet.

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

For mis-attachment defense (catch-all default deny + broker allow-list), see [MULTINETWORKPOLICY.md](../messaging/kafka/cross-dc-kafka-net-helm/MULTINETWORKPOLICY.md) in the Kafka net Helm chart.

**If a peer sends you the "subnets field" caveat, it doesn't apply here.** Red Hat's docs note that `podSelector`/`namespaceSelector` peer matching in a multi-network policy is only valid if the secondary network's CNI config defines a `subnets` field — otherwise only `ipBlock` works. That restriction is scoped to **OVN-Kubernetes secondary networks** (CNI type `ovn-k8s-cni-overlay`, `topology: layer2`/`localnet`), a different mechanism from the **macvlan** NAD this design uses. For macvlan/IPVLAN/SR-IOV NADs, `podSelector` is valid regardless — there's no `subnets` field in a macvlan CNI config to begin with. ([Ref](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/multiple_networks/secondary-networks#configuring-multi-network-policy))

**CLI verification:** the resource name is `multi-networkpolicy` (singular, hyphenated), not `multinetworkpolicy` or the plural you'd guess from the CRD `kind` — `oc get multi-networkpolicy -n <namespace>`.

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
| `default-route` set on the pod's `repl-net` Multus annotation | Same failure mode as the host-level default-route mistake, at pod scope — bleeds pod egress onto the replication link |
| Assuming the OVN-K8s "`subnets` field required for `podSelector`" caveat applies to this macvlan NAD | It's specific to OVN-Kubernetes secondary networks, not macvlan/IPVLAN/SR-IOV |
| Jumbo MTU on `bond-repl.200` without raising `bond-repl` (parent-first constraint) | VLAN IP MTU cannot exceed what the parent bond can carry; config may fail silently or truncate |
| Local jumbo on replication NICs when the inter-DC path on VLAN 200 is 1500 (path MTU constraint) | Effective MTU is the minimum hop on the replication path — measure with test 5, don't assume |

---

## Verification checklist

**Pre-flight:** see [Pre-flight before network verification](#pre-flight-before-network-verification) and [`preflight.sh`](cross-dc-network-test/preflight.sh) before running the automated suite.

**Automated:** the [cross-DC network test framework](cross-dc-network-test/README.md) runs items 2–7 below against two live clusters via a script + [repl-net-probe](cross-dc-network-test/repl-net-probe/README.md) test pods, isolated from Kafka.

1. Confirm current NIC/bond state on target nodes before assuming new vs. existing (`nmcli connection show`, `oc get nns`).
2. `curl`/`nc` the remote replication IP:port from a debug pod on the NAD — confirms L2–L4 before the workload is involved.
3. Check the workload pod's `k8s.v1.cni.cncf.io/network-status` annotation — confirms it actually got the second interface and correct IP.
4. Fail one leg of the bond; confirm the replication path stays reachable.
5. Confirm `MultiNetworkPolicy` actually blocks an unauthorized pod on the same NAD (`oc get multi-networkpolicy -n <namespace>` to confirm it's present first).
6. `ping -M do -s <size>` across the full path to confirm real MTU — [path MTU constraint](#mtu--parent-first-and-path-constraints); inventory `expectedMtu` / network test 5.
7. Check the pod's `k8s.v1.cni.cncf.io/network-status` for the `repl-net` entry — confirm no `"default-route"` key is present unless deliberately set.

---

## Open questions to confirm before implementing

- Are the two NICs per node genuinely new/unconfigured, or is this a VLAN added to an already-existing bond used for other traffic? (Changes bandwidth and fault isolation — see [Problem shape](#problem-shape).)
- Do all nodes have this NIC layout, or only a subset (dedicated gateway/broker nodes)? Determines custom `MachineConfigPool`/NNCP `nodeSelector` scope.
- Does the local ToR pair support LACP, or should the bond use `active-backup`?
- What MTU does the replication path on VLAN 200 support end-to-end? ([path MTU constraint](#mtu--parent-first-and-path-constraints) — not the same as management/OVN MTU)
- Is `kubernetes-nmstate` already installed, or does this need to go through raw MachineConfig/Butane instead?

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

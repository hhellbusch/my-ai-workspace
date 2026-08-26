---
review:
  status: unreviewed
  notes: "Design note from architecture discussion — Path A on the existing br-ex trunk (no extra NICs). Example YAML not applied to a cluster. OVN-K localnet + route-override chaining is unverified."
---

# Cross-DC Replication on a Shared Uplink — `br-ex` Trunk VLAN

**Audience:** Platform and network engineers evaluating Cluster Linking (or any broker-to-broker replication) when the replication VLAN is a **tag on the existing machine-network trunk**, not a dedicated NIC pair.

**Purpose:** Show how replication traffic is steered onto that VLAN, what Kubernetes objects actually hold the scoped route, and the trade-off between macvlan-on-`br-ex` (documented routes) and OVN-K `localnet` (documented attachment). Decision this enables: whether Path A is still viable without extra NICs — and which NAD shape to lab first.

This is still **Path A** (Multus / secondary interface on the broker pod).
It is not a fourth replication path.
The dedicated-NIC host model lives in [cross-dc-replication.md](cross-dc-replication.md).
Start at the [architecture overview](../messaging/kafka/cross-dc-architecture-overview.md) for path comparison.

**Related:**

- [Cross-DC architecture overview](../messaging/kafka/cross-dc-architecture-overview.md) — canonical hub
- [Dedicated NIC replication network](cross-dc-replication.md) — bond + kernel VLAN + host route (extra NICs)
- [NAD guide](network-attachment-definitions/README.md) — macvlan / IPAM
- [Kafka NAD Helm chart](../messaging/kafka/cross-dc-kafka-net-helm/README.md) — current chart assumes `master: bond-repl.<vlan>`; not this host model
- [OpenShift 4.20: Secondary networks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/multiple_networks/secondary-networks) — *Multiple networks*, chapter 4 (`localnet`, `route-override`, attaching a pod)
- [OpenShift 4.20: About OVN-Kubernetes](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/ovn-kubernetes_network_plugin/about-ovn-kubernetes) — supported vs unsupported post-install NIC/VLAN changes

---

## Constraint

No extra NICs.
Switch ports are **trunks**.
The node already has `br-ex` on the machine-network uplink (typically the install-time bond).

Do **not** apply the [cross-dc-nncp-helm](../messaging/kafka/cross-dc-nncp-helm/README.md) `bond-repl` policies here.
Do **not** add a kernel VLAN on the uplink OVN already owns.
Red Hat does not support creating additional VLANs or sub-interfaces on the primary NIC / `br-ex` as a day-2 NMState change.

What *is* supported for this layout:

- Map an OVN-K `localnet` secondary network onto the **existing** `br-ex` (no port changes).
- Tag with `vlanID` in the NAD; OVN tags/untags; the physical port stays a trunk.
- Or attach macvlan with `master: br-ex` and `"vlan": <id>` — this is the shape Red Hat uses when demonstrating scoped routes (chapter 4, plugin chaining).

Isolation is **VLAN + subnet on shared NICs**, not a dedicated circuit.
Replication and machine-network / OVN egress compete for the same bond.

Example numbers below are DC-A.
DC-B swaps local/remote: local `10.200.2.0/26`, gateway `10.200.2.1`, remote `10.200.1.0/26`.
VLAN **200** is a placeholder — it must not be the machine-network VLAN.

---

## What actually steers egress

Attaching the pod to VLAN 200 is necessary and not sufficient.

Cluster Linking dest brokers dial `REPLICATION://<remote-repl-ip>:9095`.
Inside the source broker, the kernel picks the interface from the routing table:

| Destination | Required route | Egress |
|---|---|---|
| Local VLAN (`10.200.1.0/26`) | connected on `net1` | VLAN, source = repl IP |
| Remote DC (`10.200.2.0/26`) | `via 10.200.1.1 dev net1` | VLAN, source = repl IP |
| Everything else | default via `eth0` | OVN overlay → SNAT to **machine-network** IP |

Without the middle row, `ip route get 10.200.2.21` returns `eth0`.
Firewalls on VLAN 200 never see the session.

The Red Hat **`default-route` annotation** on the secondary attachment installs a **default** gateway on that interface.
That is the wrong control: API, DNS, and image pulls would follow the replication VLAN.
Leave it unset.
Confirm in `k8s.v1.cni.cncf.io/network-status`.

`AdminPolicyBasedExternalRoute` and `EgressIP` steer **default-network** namespace egress.
Wrong granularity, wrong network.

---

## There is no ScopedRoute object

The scoped route is a **field inside the NAD**:

- macvlan / whereabouts: `ipam.routes`
- chained CNI: `route-override` `addroutes`

Host `NodeNetworkConfigurationPolicy` `routes.config` only affects the host namespace.
It does not steer these pods unless they are `hostNetwork: true`.

On a shared uplink there is typically **no host IP on VLAN 200**, so there is nothing useful to put in host `routes.config` anyway.

---

## Two NAD shapes

| | **macvlan on `br-ex`** | **OVN-K `localnet` on `br-ex`** |
|---|---|---|
| Host | none (do not change `br-ex`) | NNCP **mapping only**: `ovn.bridge-mappings` → `br-ex` |
| Tagging | macvlan `"vlan": 200` | NAD `vlanID: 200` |
| Pod IPAM | whereabouts / static | OVN `subnets` / `excludeSubnets` |
| Scoped route | `ipam.routes` or `route-override` — **documented** | not in the NAD schema; chaining `route-override` is **unverified** with this CNI |
| `MultiNetworkPolicy` `podSelector` | valid on macvlan | valid when `subnets` is set |

Pick one.
Do not run both against VLAN 200 on the same nodes.

### 1. macvlan on `br-ex` (documented scoped route)

This is the Red Hat plugin-chaining example with whereabouts instead of a single static IP, so brokers do not share one address.

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: kafka-repl-net
  namespace: confluent
  annotations:
    k8s.v1.cni.cncf.io/policy-for: confluent/kafka-repl-net
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "name": "kafka-repl-net",
      "plugins": [
        {
          "type": "macvlan",
          "master": "br-ex",
          "mode": "bridge",
          "vlan": 200,
          "ipam": {
            "type": "whereabouts",
            "range": "10.200.1.0/26",
            "range_start": "10.200.1.20",
            "range_end": "10.200.1.60",
            "routes": [
              { "dst": "10.200.2.0/26", "gw": "10.200.1.1" }
            ]
          }
        }
      ]
    }
```

Equivalent using the chained plugin from the book (same routing outcome):

```yaml
# metadata as above
spec:
  config: |
    {
      "cniVersion": "1.0.0",
      "name": "kafka-repl-net",
      "plugins": [
        {
          "type": "macvlan",
          "master": "br-ex",
          "vlan": 200,
          "mode": "bridge",
          "ipam": {
            "type": "whereabouts",
            "range": "10.200.1.0/26",
            "range_start": "10.200.1.20",
            "range_end": "10.200.1.60"
          }
        },
        {
          "type": "route-override",
          "addroutes": [
            { "dst": "10.200.2.0/26", "gw": "10.200.1.1" }
          ]
        }
      ]
    }
```

Omit IPAM `"gateway"`.
Omit pod `"default-route"`.
Broker annotation is a name only:

```yaml
annotations:
  k8s.v1.cni.cncf.io/networks: kafka-repl-net
```

Chapter 1 of the OVN-Kubernetes book lists “using the primary network interface for additional secondary networks” as unsupported, while chapter 4 of *Multiple networks* shows `master: br-ex` with a VLAN for this exact routing pattern.
Lab it; treat GSS confirmation as a gate if this is the production choice.

### 2. OVN-K `localnet` on `br-ex` (supported attachment)

Mapping only — do not list `br-ex` ports or the uplink in `desiredState.interfaces`:

```yaml
apiVersion: nmstate.io/v1
kind: NodeNetworkConfigurationPolicy
metadata:
  name: kafka-repl-localnet-mapping
spec:
  nodeSelector:
    node-role.kubernetes.io/worker: ""
  desiredState:
    ovn:
      bridge-mappings:
        - localnet: kafka-repl
          bridge: br-ex
          state: present
```

`ovn.bridge-mappings.localnet` must equal the NAD `spec.config.name` (here `kafka-repl`).

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: kafka-repl-net
  namespace: confluent
  annotations:
    k8s.v1.cni.cncf.io/policy-for: confluent/kafka-repl-net
spec:
  config: |
    {
      "cniVersion": "0.4.0",
      "name": "kafka-repl",
      "type": "ovn-k8s-cni-overlay",
      "topology": "localnet",
      "physicalNetworkName": "kafka-repl",
      "vlanID": 200,
      "subnets": "10.200.1.0/26",
      "excludeSubnets": "10.200.1.0/32,10.200.1.1/32,10.200.1.63/32",
      "mtu": 1500,
      "netAttachDefName": "confluent/kafka-repl-net"
    }
```

That attaches the pod to VLAN 200 and installs a **connected** route for `10.200.1.0/26` only.
Traffic to `10.200.2.0/26` still leaves `eth0`.

`ClusterUserDefinedNetwork` with `topology: Localnet` has no routes field either.
Localnet role is **Secondary**.

The scoped route would have to be a chain on the same NAD:

```json
{
  "cniVersion": "0.4.0",
  "name": "kafka-repl",
  "plugins": [
    {
      "type": "ovn-k8s-cni-overlay",
      "topology": "localnet",
      "physicalNetworkName": "kafka-repl",
      "vlanID": 200,
      "subnets": "10.200.1.0/26",
      "excludeSubnets": "10.200.1.0/32,10.200.1.1/32,10.200.1.63/32",
      "mtu": 1500,
      "netAttachDefName": "confluent/kafka-repl-net"
    },
    {
      "type": "route-override",
      "addroutes": [
        { "dst": "10.200.2.0/26", "gw": "10.200.1.1" }
      ]
    }
  ]
}
```

Red Hat only shows `route-override` chained to **macvlan**.
OVN-K also discovers secondary networks from a top-level `"type": "ovn-k8s-cni-overlay"`.
A `plugins` array can mean the logical switch is never created.
Treat this as a lab proof, not a settled design.

---

## `MultiNetworkPolicy`

Same intent as the dedicated-NIC Path A policy.
Enable `spec.useMultiNetworkPolicy: true` on the cluster `Network` operator first.

```yaml
apiVersion: k8s.cni.cncf.io/v1beta1
kind: MultiNetworkPolicy
metadata:
  name: kafka-repl-restrict
  namespace: confluent
  annotations:
    k8s.v1.cni.cncf.io/policy-for: confluent/kafka-repl-net
spec:
  podSelector:
    matchLabels:
      app: kafka
  policyTypes: [Ingress, Egress]
  ingress:
    - from: [{ ipBlock: { cidr: 10.200.2.0/26 } }]
      ports: [{ protocol: TCP, port: 9095 }]
  egress:
    - to: [{ ipBlock: { cidr: 10.200.2.0/26 } }]
      ports: [{ protocol: TCP, port: 9095 }]
```

For macvlan, keep `ipBlock` (as in [MULTINETWORKPOLICY.md](../messaging/kafka/cross-dc-kafka-net-helm/MULTINETWORKPOLICY.md)).
For localnet with `subnets` set, `podSelector` peers are also valid.

Add the default-deny catch-all on the same NAD if unselected pods might attach.

---

## Verification

From a probe or broker pod, before Kafka:

```bash
ip route get 10.200.2.21
# want: via 10.200.1.1 dev net1 src 10.200.1.x

ip route get 8.8.8.8
# want: default via <ovn> dev eth0 — not net1
```

`network-status` on the pod: second interface present, **no** `"default-route"` key.

Then `tcpdump` on `br-ex` / the uplink vs confirming the packet is **VLAN 200 tagged** with source in the local `/26`, not a node management address.

The existing [cross-DC network test](cross-dc-network-test/README.md) assumes a macvlan master of `bond-repl.<vlan>`.
It does not cover this host model until the test NAD `master` (or CNI type) is changed.

---

## What this is not

| Anti-pattern | Why |
|---|---|
| `bond-repl` NNCP / kernel VLAN on the `br-ex` uplink | Unsupported day-2 change to the primary NIC / OVS bridge |
| `default-route` on the replication attachment | Steals **all** pod egress onto VLAN 200 |
| Host `routes.config` as the pod fix | Wrong network namespace |
| `AdminPolicyBasedExternalRoute` / EgressIP | Default-network SNAT, not the replication VLAN |
| L2-stretching `10.200.0.0/25` across DCs | Same failure domain problem as the dedicated-NIC design |
| Mapping `localnet` **and** macvlan onto VLAN 200 together | Two attachments, one tag |

Kafka / CFK listener wiring (`$(REPL_IP)`, Cluster Link `bootstrap.servers`) is unchanged from Path A once the pod actually has a repl IP and the scoped route — see [BROKER-IPAM.md](../messaging/kafka/cross-dc-kafka-net-helm/BROKER-IPAM.md).

---

## Open questions before implementing

- Is the machine network **untagged** native VLAN on this trunk, or is `br-ex` already on a tagged sub-interface (e.g. `bond0.100`)? VLAN 200 must not collide with that tag.
- Is sharing the machine-network bond acceptable for replication volume, or is “no extra NICs” a temporary constraint?
- Lab first: macvlan + `ipam.routes`, or localnet mapping only (knowing the remote `/26` will miss until the route gap is closed)?
- Path MTU on VLAN 200 vs `br-ex` MTU — parent-first still applies; jumbo on 200 cannot exceed `br-ex`.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

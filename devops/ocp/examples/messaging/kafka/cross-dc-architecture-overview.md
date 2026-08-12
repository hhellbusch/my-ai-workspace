---
review:
  status: unreviewed
  notes: "Combined design doc assembled from cross-dc-replication.md + cross-dc-cluster-linking.md for peer sharing. Not yet implemented or reviewed by network/platform teams. This is a snapshot for review — if it drifts from the two source docs, treat those as authoritative."
---

# Cross-DC Kafka Replication Architecture — Complete Picture

**Audience:** Platform engineers and peers reviewing a proposed cross-DC network + Kafka replication design before implementation — not yet a build guide.

**Purpose:** Single-document combination of two split design docs, for sharing with peers who need the whole picture in one place. Covers the generic dedicated cross-DC network (bonded NIC → VLAN → routed subnet → Multus pod attachment → `MultiNetworkPolicy`) and how Confluent's **Cluster Linking** layers Kafka replication on top of it.

**Source of truth:** This doc is a point-in-time combination. The maintained, individually-linked versions are:

- [Dedicated cross-DC replication network](../../networking/cross-dc-replication.md) — the generic network layers (workload-agnostic)
- [Confluent Cluster Linking across datacenters](cross-dc-cluster-linking.md) — the Kafka/CFK-specific layer

If this combined doc and those two disagree later, the split docs win — update them first, then re-sync this one (or regenerate it).

**Deployment context:** Confluent for Kubernetes (**CFK**), installed via Helm (not OLM/OperatorHub). Helm vs. OLM only affects how the operator itself is deployed, not the `platform.confluent.io` CRDs it watches.

---

## On this page

- [Problem shape](#problem-shape)
- [Layer map](#layer-map)
- [Part 1 — The dedicated network (workload-agnostic)](#part-1--the-dedicated-network-workload-agnostic)
  - [Layer 1–2: host network](#layer-12-host-network)
  - [Layer 3: routing](#layer-3-routing)
  - [Layer 2/3: pod attachment via Multus](#layer-23-pod-attachment-via-multus)
  - [Securing the secondary network: MultiNetworkPolicy](#securing-the-secondary-network-multinetworkpolicy)
- [Part 2 — Confluent Cluster Linking on top of it](#part-2--confluent-cluster-linking-on-top-of-it)
  - [What Cluster Linking simplifies](#what-cluster-linking-simplifies)
  - [Connection direction](#connection-direction)
  - [The routes trap](#the-routes-trap)
  - [CFK listener configuration](#cfk-listener-configuration)
  - [The link itself: API-driven, not a CRD](#the-link-itself-api-driven-not-a-crd)
  - [Bidirectional, pre-staged links for failover](#bidirectional-pre-staged-links-for-failover)
  - [Security requirements](#security-requirements)
  - [MultiNetworkPolicy for Kafka](#multinetworkpolicy-for-kafka)
- [Anti-patterns](#anti-patterns)
- [Verification checklist](#verification-checklist)
- [Open questions to confirm before implementing](#open-questions-to-confirm-before-implementing)

---

## Problem shape

Two bare-metal OpenShift clusters, one per datacenter, need a **dedicated, isolated** network path for bulk replication traffic — separate from management/API/OVN pod traffic. Each node has two NICs on **two different physical cards** (slot A, slot B), intended for HA via bonding. This is a **third network**, distinct from both the cluster's machine network and any storage network:

| Network | Typical pattern |
|---|---|
| Management / API / OVN | Existing machine network |
| Storage (NVMe/TCP, etc.) | Two independent NICs, **no bond** |
| **Cross-DC replication** | Bonded NIC pair + VLAN + routed subnet — this doc |

The concrete workload driving this design is **Apache Kafka (Confluent Platform, via CFK)**, using **Cluster Linking** for broker-to-broker replication between the two clusters.

**Before building this:** confirm whether the two NICs per node are genuinely new/unconfigured, or whether they're existing NICs already bonded for something else and this is really "add a VLAN to an existing bond." The two scenarios have very different bandwidth-isolation and fault-isolation properties — check `nmcli connection show` / `ip -d link show` / `oc get nns` on a target node rather than assuming.

---

## Layer map

```text
L7  Application         Kafka broker protocol, Cluster Linking (fetch-based replication)
L4  Transport            TCP session, dedicated REPLICATION listener/port
L3  Network              Routed subnets per DC, static route (not default gateway)
L2  Data link            Bond (two cards) + VLAN tag
L1  Physical             Two NICs, two cards, dedicated fiber/circuit
```

Pod attachment (Multus) sits at L2/L3 and is the layer most often skipped by mistake.

---

## Part 1 — The dedicated network (workload-agnostic)

Everything in this part is Kafka-agnostic — it would look the same for any workload needing a dedicated cross-DC path (storage mirroring, other replication traffic, etc.).

### Layer 1–2: host network

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
2. **Interface naming stability.** Kernel interface names (`ens4f0`, etc.) depend on PCI enumeration order and can differ across otherwise-identical hardware. At fleet scale, match by MAC/PCI path via `systemd.link` rather than assuming names are consistent.
3. **Bonding mode.** `active-backup` works with any switch. `802.3ad`/LACP requires every hop in the bond to participate — fine if the bond terminates at your own local ToR pair, **not** viable if anyone assumes the bond itself spans the WAN (it doesn't; the WAN segment is routed, not bonded).

### Layer 3: routing

**The most common mistake in this whole design:** setting the node's **default route** on the replication interface instead of a route scoped to the remote subnet. A default route on this interface sends *all* egress traffic (image pulls, DNS, API calls) out over a link sized, firewalled, and provisioned for one purpose only — and it usually breaks connectivity outright.

```yaml
routes:
  config:
    - destination: 10.200.2.0/26      # remote DC's replication subnet — NOT 0.0.0.0/0
      next-hop-address: 10.200.1.1
      next-hop-interface: bond-repl.200
# deliberately no default-route entry on this interface
```

**L3 routed, not L2 stretched.** Each DC gets its own subnet on this VLAN; a router/gateway pair exchanges the routes. Don't stretch one VLAN/subnet across both DCs "for simplicity" — L2 stretch at distance introduces STP, MAC-learning, and failure-domain problems that routed L3 avoids entirely.

**MTU:** confirm what the WAN circuit actually supports end-to-end (`ping -M do -s <size> <remote-ip>`) before assuming jumbo frames survive the full path.

### Layer 2/3: pod attachment via Multus

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

### Securing the secondary network: MultiNetworkPolicy

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

**Restrict traffic on it** (generic version — see [Part 2](#multinetworkpolicy-for-kafka) for the Kafka-scoped version actually used):

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

## Part 2 — Confluent Cluster Linking on top of it

Everything in this part is Kafka/CFK-specific — how the broker pods use the network built in Part 1.

### What Cluster Linking simplifies

Unlike MirrorMaker2 or Confluent Replicator, Cluster Linking is broker-to-broker — *"does not require running Connect to move messages between clusters"* ([Confluent docs](https://docs.confluent.io/platform/current/multi-dc-deployments/cluster-linking/index.html)). No separate `Connect` CR or Connect worker pods to also attach to the replication network — only the **Kafka broker pods** need the Multus attachment from Part 1.

```text
Brokers (Multus-attached, dedicated listener) ──→ Cluster Link config ──→ remote brokers
```

### Connection direction

By default, the **destination cluster's brokers initiate the connection and fetch from the source** — it behaves like a consumer pulling data, not the source pushing. This determines which side needs an egress rule and which needs an ingress rule in `MultiNetworkPolicy` and any upstream firewall.

- **One-directional link** (e.g., pure DR, no failback link pre-staged): only the destination DC's brokers dial out; the source DC only needs inbound from the destination's /26.
- **Bidirectional** (this design — see [below](#bidirectional-pre-staged-links-for-failover)): each DC is simultaneously a source (accepting inbound) and a destination (dialing out) for its respective link, so rules end up symmetric on both sides regardless.

A newer **source-initiated link** option (CP 7.8+) flips this — confirm which mode is actually configured before assuming direction.

### The routes trap

CFK supports [`externalAccess.type: route`](https://docs.confluent.io/operator/current/co-routes.html) for exposing Kafka to clients outside the OpenShift cluster — TLS passthrough/SNI through the HAProxy ingress router, with a DNS entry and the router's load-balancer IP on port 443.

**Do not use this for the cluster-link listener.** Every byte of replication traffic would flow through the shared ingress router pods — exactly the ungoverned, shared path the dedicated bonded VLAN exists to avoid. This would quietly defeat the entire network architecture without producing an obvious error.

### CFK listener configuration

What's needed: a listener with **no `externalAccess` block**, bound to the pod's Multus secondary interface, advertising that interface's IP.

```yaml
apiVersion: platform.confluent.io/v1beta1
kind: Kafka
metadata:
  name: kafka
  namespace: confluent
spec:
  podTemplate:
    annotations:
      k8s.v1.cni.cncf.io/networks: kafka-repl-net
  listeners:
    internal:
      tls:
        enabled: true
    # no "external" block, no externalAccess.type: route for the replication path
  configOverrides:
    server:
      - "listeners=INTERNAL://0.0.0.0:9071,REPLICATION://0.0.0.0:9095"
      - "listener.security.protocol.map=INTERNAL:PLAINTEXT,REPLICATION:SSL"
      - "advertised.listeners=INTERNAL://$(POD_NAME).kafka.confluent.svc.cluster.local:9071,REPLICATION://$(REPL_IP):9095"
```

**Verify against the installed CFK version's CRD reference:**

1. Whether the structured `listeners` block supports a fully custom named listener without an `externalAccess` type attached, or whether the `configOverrides.server` raw passthrough above is the correct escape hatch.
2. How `$(REPL_IP)` actually gets populated — the Multus-assigned IP isn't known at manifest-authoring time. Typically an init container reads the pod's own `k8s.v1.cni.cncf.io/network-status` annotation and exports it as an env var consumed by the broker's startup config.

### The link itself: API-driven, not a CRD

Per the current plan, the Cluster Link is being created via **API calls, likely through Control Center** — not a CFK CRD. This means the link configuration lives **outside** anything Kubernetes/GitOps tracks, and it's worth separating two distinct traffic flows that are easy to conflate:

1. **The API call that creates the link** — management/control-plane traffic against Control Center's backend (or the native Kafka Admin API via the `kafka-cluster-links` CLI). This just needs to reach whichever cluster's Control Center/Admin endpoint hosts the link — normal management-network traffic, doesn't need to ride the dedicated VLAN.
2. **The replication traffic the link generates once active** — continuous broker fetch requests over the `REPLICATION` listener, on the dedicated VLAN.

What matters: the `bootstrap.servers` value **inside** the API payload must be the `REPLICATION` listener's advertised address (the Multus IP:port) — not the cluster's internal or external-facing address. Getting this value wrong means the link either fails or silently uses the wrong path.

**Topology question that changes reachability requirements:** one Control Center instance per DC (each only needs to reach its own local cluster's Admin API), or one shared instance managing both clusters (needs direct WAN reachability to both clusters' Admin APIs — a separate requirement from the replication path, and shouldn't ride the same dedicated VLAN).

**Reproducibility gap:** since this bypasses CRD-based management, the link configuration should still be scripted and version-controlled (curl/Ansible/CLI invocation checked into a repo) — not a one-off manual action through the Control Center UI. This matters most exactly when it's least convenient: mid-failover, needing to reproduce or verify what "working" looked like.

### Bidirectional, pre-staged links for failover

The design: **active/standby**, but with links configured in **both directions** upfront, so replication can resume when a failed DC comes back online without building a link under pressure.

Confluent has a built-in alternative worth confirming was deliberately not chosen: `reverse-and-start` / `reverse-and-pause` reverses an existing link's direction rather than requiring two independently-managed link objects. It has a specific limitation — doesn't support prefixed cluster links — which is the most likely reason to use two separate links instead, if topic prefixing is in use to avoid naming collisions between clusters.

Either approach needs the same symmetric network reachability; it doesn't change anything in Part 1. It does change how failover/failback is *operated*, so worth confirming which was intended.

### Security requirements

Confluent's own guidance treats these as requirements, not optional hardening, specifically because Cluster Linking accesses the listener like a client:

- **TLS/SASL required** — *"Do not use unauthenticated listeners with Confluent Platform. Cluster Linking can access the listeners, increasing the security risk."*
- **Certificate/keystore files at the same path on every broker** — a real operational trap if using file-based TLS material rather than inline PEM config; inconsistency causes link failures.
- **ACL syncing** — Cluster Linking syncs ACLs between clusters by default. If the two clusters have independently-managed ACLs today, this needs a deliberate decision, not a default left alone.
- **Long-lived TCP connections** — *"Firewalls that allow the cluster link connection ... must allow the TCP connection to persist."* Check idle-connection timeouts on any firewall/router on the WAN path; aggressive timeouts silently break Cluster Linking.

### MultiNetworkPolicy for Kafka

Same pattern as [Part 1](#securing-the-secondary-network-multinetworkpolicy), scoped to the broker pods and the replication port:

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
    - from: [{ipBlock: {cidr: 10.200.2.0/26}}]
      ports: [{protocol: TCP, port: 9095}]
  egress:
    - to: [{ipBlock: {cidr: 10.200.2.0/26}}]
      ports: [{protocol: TCP, port: 9095}]
```

Because Cluster Linking is broker-only (no Connect layer), this is the only workload-specific policy needed — no separate rule set for Connect workers.

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
| `externalAccess.type: route` used for the Kafka replication listener | Routes all replication traffic through the shared ingress router — defeats the dedicated VLAN silently |
| Unauthenticated Kafka listener exposed to Cluster Linking | Confluent explicitly calls this a security risk, not a style choice |

## Verification checklist

1. Confirm current NIC/bond state on target nodes before assuming new vs. existing (`nmcli connection show`, `oc get nns`).
2. `curl`/`nc` the remote replication IP:port from a debug pod on the NAD — confirms L2–L4 before the workload is involved.
3. Check the workload pod's `k8s.v1.cni.cncf.io/network-status` annotation — confirms it actually got the second interface and correct IP.
4. Fail one leg of the bond; confirm the replication path stays reachable.
5. Confirm `MultiNetworkPolicy` actually blocks an unauthorized pod on the same NAD.
6. `ping -M do -s <size>` across the full path to confirm real MTU.
7. Confirm the Cluster Link's `bootstrap.servers` payload value resolves to the `REPLICATION` listener's advertised (Multus) address, not the internal/external one.
8. Fail over and back: confirm the pre-staged reverse link actually resumes replication without manual re-creation.

## Open questions to confirm before implementing

**Network:**

- Are the two NICs per node genuinely new/unconfigured, or is this a VLAN added to an already-existing bond used for other traffic?
- Do all nodes have this NIC layout, or only a subset (dedicated gateway/broker nodes)?
- Does the local ToR pair support LACP, or should the bond use `active-backup`?
- What MTU does the WAN circuit actually support end-to-end?
- Is `kubernetes-nmstate` already installed, or does this need to go through raw MachineConfig/Butane instead?

**Kafka / CFK:**

- Two independently-managed links, or a deliberate choice over `reverse-and-start`/`reverse-and-pause`? (Likely reason: topic prefixing.)
- One Control Center instance per DC, or one shared instance? (Determines if Control Center needs any cross-DC network path beyond what brokers already have.)
- Will the link-creation API calls be scripted/version-controlled, or done manually through the Control Center UI?
- Does the installed CFK version's `listeners` schema support a custom listener without an `externalAccess` type, or is `configOverrides.server` passthrough required?
- How is `$(REPL_IP)` populated at broker startup — init container reading `network-status`, or another mechanism?

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

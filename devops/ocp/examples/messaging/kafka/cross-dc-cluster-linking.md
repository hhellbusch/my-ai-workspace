---
review:
  status: unreviewed
  notes: "Design doc drafted from an architecture discussion; not yet implemented or reviewed by network/platform teams. CFK field names should be checked against the installed CFK version's CRD reference before use."
---

# Confluent Cluster Linking Across Datacenters — CFK on Bare-Metal OpenShift

**Audience:** Platform engineers and peers reviewing a proposed cross-DC Kafka replication design before implementation.

**Purpose:** Describe how Confluent's **Cluster Linking** feature layers onto a dedicated cross-DC replication network — which parts are Kafka-specific, and which parts are inherited unchanged from the general network pattern.

**Deployment context:** Confluent for Kubernetes (**CFK**), installed via Helm (not OLM/OperatorHub). This doesn't change the CRD-level answer — Helm vs. OLM only affects how the operator itself is deployed, not the `platform.confluent.io` CRDs it watches.

**Need the whole picture in one doc?** See [Cross-DC architecture overview](cross-dc-architecture-overview.md) — combines this doc and the generic network doc for sharing outside the repo.

**Related:**

- [Dedicated cross-DC replication network](../../networking/cross-dc-replication.md) — the generic host network (bond/VLAN/route), Multus NAD, and `MultiNetworkPolicy` layers this doc builds on. **Read that first** — this doc only covers what's different for Kafka/Confluent.
- [Kafka bare-metal + Portworx](bare-metal-portworx/README.md) — rack-aware CFK/Strimzi example (single-cluster, not cross-DC)
- [Network policy and observability](../../../notes/network-policy-observability.md) — Strimzi vs CFK policy differences
- [Confluent: Configure OpenShift Routes](https://docs.confluent.io/operator/current/co-routes.html) — the external-access mechanism to **avoid** for this use case (see below)
- [Confluent: Cluster Linking overview](https://docs.confluent.io/platform/current/multi-dc-deployments/cluster-linking/index.html)
- [OpenShift: Secondary networks — attaching a pod](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/multiple_networks/secondary-networks#nw-multus-advanced-annotations_attaching-pod) — static IP/MAC annotations, relevant to how `$(REPL_IP)` could be avoided (see below)
- [OpenShift: MultiNetworkPolicy API reference](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/network_apis/multinetworkpolicy-k8s-cni-cncf-io-v1beta1)

---

## On this page

- [What Cluster Linking simplifies](#what-cluster-linking-simplifies)
- [Connection direction](#connection-direction)
- [The routes trap](#the-routes-trap)
- [CFK listener configuration](#cfk-listener-configuration)
- [The link itself: API-driven, not a CRD](#the-link-itself-api-driven-not-a-crd)
- [Bidirectional, pre-staged links for failover](#bidirectional-pre-staged-links-for-failover)
- [Security requirements](#security-requirements)
- [MultiNetworkPolicy for Kafka](#multinetworkpolicy-for-kafka)
- [Open questions to confirm before implementing](#open-questions-to-confirm-before-implementing)

---

## What Cluster Linking simplifies

Unlike MirrorMaker2 or Confluent Replicator, Cluster Linking is broker-to-broker — *"does not require running Connect to move messages between clusters"* ([Confluent docs](https://docs.confluent.io/platform/current/multi-dc-deployments/cluster-linking/index.html)). No separate `Connect` CR or Connect worker pods to also attach to the replication network — only the **Kafka broker pods** need the Multus attachment from the [general network doc](../../networking/cross-dc-replication.md).

```text
Brokers (Multus-attached, dedicated listener) ──→ Cluster Link config ──→ remote brokers
```

## Connection direction

By default, the **destination cluster's brokers initiate the connection and fetch from the source** — it behaves like a consumer pulling data, not the source pushing. This determines which side needs an egress rule and which needs an ingress rule in `MultiNetworkPolicy` and any upstream firewall.

- **One-directional link** (e.g., pure DR, no failback link pre-staged): only the destination DC's brokers dial out; the source DC only needs inbound from the destination's /26.
- **Bidirectional** (this design — see [below](#bidirectional-pre-staged-links-for-failover)): each DC is simultaneously a source (accepting inbound) and a destination (dialing out) for its respective link, so rules end up symmetric on both sides regardless.

A newer **source-initiated link** option (CP 7.8+) flips this — confirm which mode is actually configured before assuming direction.

## The routes trap

CFK supports [`externalAccess.type: route`](https://docs.confluent.io/operator/current/co-routes.html) for exposing Kafka to clients outside the OpenShift cluster — TLS passthrough/SNI through the HAProxy ingress router, with a DNS entry and the router's load-balancer IP on port 443.

**Do not use this for the cluster-link listener.** Every byte of replication traffic would flow through the shared ingress router pods — exactly the ungoverned, shared path the dedicated bonded VLAN exists to avoid. This would quietly defeat the entire network architecture without producing an obvious error.

## CFK listener configuration

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
2. How `$(REPL_IP)` gets populated — see [BROKER-IPAM.md](cross-dc-kafka-net-helm/BROKER-IPAM.md): **whereabouts** (init container + `network-status`) vs **static** (pinned IP per ordinal).

**Whereabouts (default):** an init container reads `k8s.v1.cni.cncf.io/network-status` and exports `REPL_IP` — see [cfk-kafka-whereabouts.snippet.yaml](cross-dc-kafka-net-helm/examples/cfk-kafka-whereabouts.snippet.yaml).

**Static alternative:** pin each broker's IP in the Multus annotation; `REPL_IP` can be literal — see [cfk-kafka-static.snippet.yaml](cross-dc-kafka-net-helm/examples/cfk-kafka-static.snippet.yaml) and the rendered `kafka-repl-net-broker-ip-map` ConfigMap.

## The link itself: API-driven, not a CRD

Per the current plan, the Cluster Link is being created via **API calls, likely through Control Center** — not a CFK CRD. This means the link configuration lives **outside** anything Kubernetes/GitOps tracks, and it's worth separating two distinct traffic flows that are easy to conflate:

1. **The API call that creates the link** — management/control-plane traffic against Control Center's backend (or the native Kafka Admin API via the `kafka-cluster-links` CLI). This just needs to reach whichever cluster's Control Center/Admin endpoint hosts the link — normal management-network traffic, doesn't need to ride the dedicated VLAN.
2. **The replication traffic the link generates once active** — continuous broker fetch requests over the `REPLICATION` listener, on the dedicated VLAN.

What matters: the `bootstrap.servers` value **inside** the API payload must be the `REPLICATION` listener's advertised address (the Multus IP:port) — not the cluster's internal or external-facing address. Getting this value wrong means the link either fails or silently uses the wrong path.

**Topology question that changes reachability requirements:** one Control Center instance per DC (each only needs to reach its own local cluster's Admin API), or one shared instance managing both clusters (needs direct WAN reachability to both clusters' Admin APIs — a separate requirement from the replication path, and shouldn't ride the same dedicated VLAN).

**Reproducibility gap:** since this bypasses CRD-based management, the link configuration should still be scripted and version-controlled (curl/Ansible/CLI invocation checked into a repo) — not a one-off manual action through the Control Center UI. This matters most exactly when it's least convenient: mid-failover, needing to reproduce or verify what "working" looked like.

## Bidirectional, pre-staged links for failover

The design: **active/standby**, but with links configured in **both directions** upfront, so replication can resume when a failed DC comes back online without building a link under pressure.

Confluent has a built-in alternative worth confirming was deliberately not chosen: `reverse-and-start` / `reverse-and-pause` reverses an existing link's direction rather than requiring two independently-managed link objects. It has a specific limitation — doesn't support prefixed cluster links — which is the most likely reason to use two separate links instead, if topic prefixing is in use to avoid naming collisions between clusters.

Either approach needs the same symmetric network reachability; it doesn't change anything in the [general network doc](../../networking/cross-dc-replication.md). It does change how failover/failback is *operated*, so worth confirming which was intended.

## Security requirements

Confluent's own guidance treats these as requirements, not optional hardening, specifically because Cluster Linking accesses the listener like a client:

- **TLS/SASL required** — *"Do not use unauthenticated listeners with Confluent Platform. Cluster Linking can access the listeners, increasing the security risk."*
- **Certificate/keystore files at the same path on every broker** — a real operational trap if using file-based TLS material rather than inline PEM config; inconsistency causes link failures.
- **ACL syncing** — Cluster Linking syncs ACLs between clusters by default. If the two clusters have independently-managed ACLs today, this needs a deliberate decision, not a default left alone.
- **Long-lived TCP connections** — *"Firewalls that allow the cluster link connection ... must allow the TCP connection to persist."* Check idle-connection timeouts on any firewall/router on the WAN path; aggressive timeouts silently break Cluster Linking.

## MultiNetworkPolicy for Kafka

Same pattern as the [general doc](../../networking/cross-dc-replication.md#securing-the-secondary-network-multinetworkpolicy), scoped to the broker pods and the replication port:

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

## Open questions to confirm before implementing

- Two independently-managed links, or a deliberate choice over `reverse-and-start`/`reverse-and-pause`? (Likely reason: topic prefixing.)
- One Control Center instance per DC, or one shared instance? (Determines if Control Center needs any cross-DC network path beyond what brokers already have.)
- Will the link-creation API calls be scripted/version-controlled, or done manually through the Control Center UI?
- Does the installed CFK version's `listeners` schema support a custom listener without an `externalAccess` type, or is `configOverrides.server` passthrough required?
- How is `$(REPL_IP)` populated — [BROKER-IPAM.md](cross-dc-kafka-net-helm/BROKER-IPAM.md) (`whereabouts` vs `static`)?

Also carries forward the [open questions from the general network doc](../../networking/cross-dc-replication.md#open-questions-to-confirm-before-implementing) — none of those are Kafka-specific, but all need answers before this is buildable.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

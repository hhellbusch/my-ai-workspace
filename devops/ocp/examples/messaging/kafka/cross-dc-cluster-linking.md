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
- [Cluster Link GitOps — CRD vs API patterns](CLUSTER-LINK-GITOPS.md) — Argo CD, reconcile Jobs, decision matrix
- [OpenShift: Secondary networks — attaching a pod](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/multiple_networks/secondary-networks#nw-multus-advanced-annotations_attaching-pod) — static IP/MAC annotations, relevant to how `$(REPL_IP)` could be avoided (see below)
- [OpenShift: MultiNetworkPolicy API reference](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/network_apis/multinetworkpolicy-k8s-cni-cncf-io-v1beta1)

---

## On this page

- [What Cluster Linking simplifies](#what-cluster-linking-simplifies)
- [Connection direction](#connection-direction)
- [The routes trap](#the-routes-trap)
- [CFK listener configuration](#cfk-listener-configuration)
- [Managing the cluster link (GitOps)](#managing-the-cluster-link-gitops)
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
2. How `$(REPL_IP)` gets populated — see [BROKER-IPAM.md](cross-dc-kafka-net-helm/BROKER-IPAM.md): **whereabouts** (init container + `network-status`) vs **static** (pinned IP per ordinal). Step-by-step from Multus attachment through `advertised.listeners` to link `bootstrap.servers`: [End-to-end pipeline](cross-dc-kafka-net-helm/BROKER-IPAM.md#end-to-end-pipeline).

**Whereabouts (default):** an init container reads `k8s.v1.cni.cncf.io/network-status` and exports `REPL_IP` — see [End-to-end lifecycle (whereabouts)](cross-dc-kafka-net-helm/BROKER-IPAM.md#end-to-end-lifecycle-whereabouts) and [cfk-kafka-whereabouts.snippet.yaml](cross-dc-kafka-net-helm/examples/cfk-kafka-whereabouts.snippet.yaml).

**Static alternative:** pin each broker's IP in the Multus annotation; `REPL_IP` can be literal — see [End-to-end lifecycle (static)](cross-dc-kafka-net-helm/BROKER-IPAM.md#end-to-end-lifecycle-static), [cfk-kafka-static.snippet.yaml](cross-dc-kafka-net-helm/examples/cfk-kafka-static.snippet.yaml), and the rendered `kafka-repl-net-broker-ip-map` ConfigMap.

## Managing the cluster link (GitOps)

The link object (name, source/dest, **`bootstrap.servers` / `bootstrapEndpoint`**, mirror topics, ACL filters) must be **version-controlled** — not only created in Control Center during cutover.

Two valid approaches:

| Approach | When |
|---|---|
| **`ClusterLink` CRD** + Argo CD | CFK exposes every setting you need; CFK operator reconciles the CR |
| **Declarative spec in Git** + **reconcile script** (often as an Argo **Job** or CronJob) | CRD schema gaps, legacy API-only settings, or team preference for `confluent kafka link` / REST |

Peers sometimes report the CRD **does not expose all link settings** — that must be verified on **your** CFK version (`oc explain clusterlink.spec`), not assumed. CFK **does** document a broad `ClusterLink` CR ([co-link-clusters](https://docs.confluent.io/operator/current/co-link-clusters.html)); gaps are version- and requirement-specific.

**Full comparison** (Patterns A–G: CRD, Job reconcile, PostSync hooks, CronJob drift, external CI, hybrid, long-running reconciler): **[CLUSTER-LINK-GITOPS.md](CLUSTER-LINK-GITOPS.md)**.

Regardless of pattern, separate two traffic types:

1. **Management** — API/CLI/Control Center call or CR apply against Admin REST (management network / in-cluster REST — **not** the replication VLAN).
2. **Replication** — broker fetch traffic on the `REPLICATION` listener once the link is active (`net1` / Multus path).

The **`bootstrap.servers` / `bootstrapEndpoint` value must be the `REPLICATION` listener advertised address** (Multus IP:port) — not internal Service DNS or OpenShift Routes. Wrong bootstrap means link failure or silent use of the wrong path.

**Topology:** one Control Center per DC vs one shared instance changes Admin API reachability — see open questions in [CLUSTER-LINK-GITOPS.md](CLUSTER-LINK-GITOPS.md) and below.

**Do not mix:** mirror topics managed via API/CLI **and** a `ClusterLink` CR on the same link — CFK may delete externally created mirrors on reconcile ([Confluent docs](https://docs.confluent.io/operator/current/co-link-clusters.html)).

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
- Will the link be managed via **`ClusterLink` CRD**, **API reconcile Job**, or hybrid? See [CLUSTER-LINK-GITOPS.md](CLUSTER-LINK-GITOPS.md) and gap checklist there.
- Does the installed CFK version's `listeners` schema support a custom listener without an `externalAccess` type, or is `configOverrides.server` passthrough required?
- How is `$(REPL_IP)` populated — [BROKER-IPAM.md](cross-dc-kafka-net-helm/BROKER-IPAM.md) (`whereabouts` vs `static`)?

Also carries forward the [open questions from the general network doc](../../networking/cross-dc-replication.md#open-questions-to-confirm-before-implementing) — none of those are Kafka-specific, but all need answers before this is buildable.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

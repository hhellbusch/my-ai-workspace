---
review:
  status: unreviewed
  notes: "Design doc drafted from an architecture discussion; not yet implemented or reviewed by network/platform teams. CFK field names should be checked against the installed CFK version's CRD reference before use."
---

# Confluent Cluster Linking Across Datacenters — CFK on Bare-Metal OpenShift

**Audience:** Platform engineers and peers reviewing a proposed cross-DC Kafka replication design before implementation.

**Purpose:** Kafka/CFK-specific depth for Cluster Linking on a dedicated replication VLAN — listeners, links, security, and policy. **Start at the [architecture overview](cross-dc-architecture-overview.md)** for path comparison and shared foundations; this doc assumes you have chosen a replication mechanism.

**Deployment context:** Confluent for Kubernetes (**CFK**), installed via Helm (not OLM/OperatorHub). Helm vs. OLM only affects how the operator itself is deployed, not the `platform.confluent.io` CRDs it watches.

**Related:**

- [Cross-DC architecture overview](cross-dc-architecture-overview.md) — **canonical hub** — path comparison, build order, verification
- [Dedicated cross-DC replication network](../../networking/cross-dc-replication.md) — generic host + Multus network depth
- [Cross-DC ingress / Route alternative](cross-dc-ingress-alternative.md) — dedicated `IngressController` + CFK Routes
- [Kafka bare-metal + Portworx](bare-metal-portworx/README.md) — rack-aware CFK/Strimzi example (single-cluster, not cross-DC)
- [Network policy and observability](../../../notes/network-policy-observability.md) — Strimzi vs CFK policy differences
- [Confluent: Configure OpenShift Routes](https://docs.confluent.io/operator/current/co-routes.html)
- [Confluent: Cluster Linking overview](https://docs.confluent.io/platform/current/multi-dc-deployments/cluster-linking/index.html)
- [Cluster Link GitOps — CRD vs API patterns](CLUSTER-LINK-GITOPS.md) — Argo CD, reconcile Jobs, decision matrix
- [OpenShift: Secondary networks — attaching a pod](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/multiple_networks/secondary-networks#nw-multus-advanced-annotations_attaching-pod) — static IP/MAC annotations, relevant to how `$(REPL_IP)` could be avoided (see below)
- [OpenShift: MultiNetworkPolicy API reference](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/network_apis/multinetworkpolicy-k8s-cni-cncf-io-v1beta1)

---

## On this page

- [Replication mechanisms (Kafka layer)](#replication-mechanisms-kafka-layer)
- [What Cluster Linking simplifies](#what-cluster-linking-simplifies)
- [Connection direction](#connection-direction)
- [CFK listener configuration](#cfk-listener-configuration)
- [Managing the cluster link (GitOps)](#managing-the-cluster-link-gitops)
- [Bidirectional, pre-staged links for failover](#bidirectional-pre-staged-links-for-failover)
- [Security requirements](#security-requirements)
- [MultiNetworkPolicy for Kafka (Multus path)](#multinetworkpolicy-for-kafka-multus-path)
- [Open questions to confirm before implementing](#open-questions-to-confirm-before-implementing)

---

## Replication mechanisms (Kafka layer)

Cluster Linking is broker-to-broker regardless of network path.
What changes is how **advertised listeners** and **firewall rules** are shaped:

| Mechanism | Broker attachment | Advertised endpoints | Deep dive |
|---|---|---|---|
| **Multus direct** | macvlan NAD on `bond-repl.200` | `REPLICATION://$(REPL_IP):9095` | [BROKER-IPAM.md](cross-dc-kafka-net-helm/BROKER-IPAM.md) |
| **Dedicated ingress shard** | Brokers on OVN; HAProxy on repl VLAN | Route hostnames on `:443` (TLS passthrough) | [cross-dc-ingress-alternative.md](cross-dc-ingress-alternative.md) |

**Do not use the default `apps.*` ingress for production replication on a dedicated VLAN** — traffic stays on the machine network. See [overview — choose your path](cross-dc-architecture-overview.md#choose-your-replication-path).

---

## What Cluster Linking simplifies

Unlike MirrorMaker2 or Confluent Replicator, Cluster Linking is broker-to-broker — *"does not require running Connect to move messages between clusters"* ([Confluent docs](https://docs.confluent.io/platform/current/multi-dc-deployments/cluster-linking/index.html)). No separate `Connect` CR or Connect worker pods on the replication path.

```text
Multus:  Brokers (Multus REPLICATION listener) ──→ Cluster Link config ──→ remote brokers
Ingress: Brokers (Route hostnames :443)        ──→ Cluster Link config ──→ remote brokers
```

---

## Connection direction

By default, the **destination cluster's brokers initiate the connection and fetch from the source** — it behaves like a consumer pulling data, not the source pushing. This determines firewall egress/ingress direction and, on the Multus path, `MultiNetworkPolicy` shape.

- **One-directional link:** only the destination DC's brokers dial out; the source DC only needs inbound from the destination's replication subnet.
- **Bidirectional** (see [below](#bidirectional-pre-staged-links-for-failover)): symmetric rules on both sides.

A newer **source-initiated link** option (CP 7.8+) flips this — confirm which mode is configured before assuming direction.

---

## CFK listener configuration

See [overview — CFK listener configuration](cross-dc-architecture-overview.md#cfk-listener-configuration) for the full split. Snippets:

### Multus path

Listener on the Multus interface; `advertised.listeners` uses `$(REPL_IP)`:

- [cfk-kafka-whereabouts.snippet.yaml](cross-dc-kafka-net-helm/examples/cfk-kafka-whereabouts.snippet.yaml)
- [cfk-kafka-static.snippet.yaml](cross-dc-kafka-net-helm/examples/cfk-kafka-static.snippet.yaml)
- IPAM lifecycle: [BROKER-IPAM.md](cross-dc-kafka-net-helm/BROKER-IPAM.md)

### Ingress path

`listeners.custom` with `externalAccess.type: route` — CFK manages Routes and advertised hostnames:

- [cfk-kafka-route-replication.snippet.yaml](examples/cfk-kafka-route-replication.snippet.yaml)
- IngressController example: [ingress-replication/](examples/ingress-replication/README.md)

**Verify against installed CFK CRD reference** for `listeners.custom`, `route.labels`, and status field paths for `bootstrap.servers`.

---

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
2. **Replication** — broker fetch traffic on the replication listener once the link is active (Multus `:9095` or Route `:443` passthrough).

The **`bootstrap.servers` / `bootstrapEndpoint` value must be the replication listener's advertised address** — Multus IP:9095 (Path A) or route hostname:443 (Path B/C) — not internal Service DNS or the wrong ingress VIP. Wrong bootstrap means link failure or silent use of the wrong path.

**Topology:** one Control Center per DC vs one shared instance changes Admin API reachability — see open questions in [CLUSTER-LINK-GITOPS.md](CLUSTER-LINK-GITOPS.md) and below.

**Do not mix:** mirror topics managed via API/CLI **and** a `ClusterLink` CR on the same link — CFK may delete externally created mirrors on reconcile ([Confluent docs](https://docs.confluent.io/operator/current/co-link-clusters.html)).

## Bidirectional, pre-staged links for failover

**Active/standby** with links configured in **both directions** upfront so replication can resume when a failed DC returns without building a link under pressure.

Alternative: `reverse-and-start` / `reverse-and-pause` (does not support prefixed cluster links). Either approach needs symmetric network reachability; it changes failover *operations*, not host VLAN design.

---

## Security requirements

Confluent treats these as requirements for Cluster Linking:

- **TLS/SASL required** on the replication listener
- **Consistent cert/keystore paths** on every broker when using file-based TLS
- **ACL syncing** — deliberate decision if clusters have independent ACLs today
- **Long-lived TCP** — avoid aggressive firewall idle timeouts on the WAN path

---

## MultiNetworkPolicy for Kafka (Multus path)

**Ingress path:** use standard `NetworkPolicy` for router→broker on OVN — see [ingress alternative — security](cross-dc-ingress-alternative.md#security-and-access-control).

On the Multus path, standard `NetworkPolicy` does not govern the secondary interface. The [cross-dc-kafka-net-helm](cross-dc-kafka-net-helm/README.md) chart renders default-deny + broker allow-list — see [MULTINETWORKPOLICY.md](cross-dc-kafka-net-helm/MULTINETWORKPOLICY.md).

---

## Open questions to confirm before implementing

- Multus vs dedicated ingress shard? ([overview](cross-dc-architecture-overview.md#choose-your-replication-path))
- Two independently-managed links, or a deliberate choice over `reverse-and-start`/`reverse-and-pause`? (Likely reason: topic prefixing.)
- One Control Center instance per DC, or one shared instance? (Determines if Control Center needs any cross-DC network path beyond what brokers already have.)
- Will the link be managed via **`ClusterLink` CRD**, **API reconcile Job**, or hybrid? See [CLUSTER-LINK-GITOPS.md](CLUSTER-LINK-GITOPS.md) and gap checklist there.
- Does the installed CFK version's `listeners` schema support a custom listener without an `externalAccess` type, or is `configOverrides.server` passthrough required?
- Multus only: how is `$(REPL_IP)` populated — [BROKER-IPAM.md](cross-dc-kafka-net-helm/BROKER-IPAM.md) (`whereabouts` vs `static`)?
- Ingress only: VIP vs DNS LB on repl VLAN? ([ingress alternative](cross-dc-ingress-alternative.md#frontend-options-without-an-external-hardware-lb))

Also: [open questions from the generic network doc](../../networking/cross-dc-replication.md#open-questions-to-confirm-before-implementing).

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

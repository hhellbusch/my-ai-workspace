---
review:
  status: unreviewed
  notes: "Topic index — messaging workloads on OpenShift."
---

# Messaging — OpenShift Examples

Event streaming workloads on OpenShift: Kafka first; room for Schema Registry, Connect, and MirrorMaker examples later.

**Cross-cutting reference:**

- [Network policy and observability](../../notes/network-policy-observability.md) — Strimzi vs Confluent CFK, Flink egress, OVN audit logging, NetObserv
- [Kafka on OpenShift tenancy](../../notes/kafka-on-openshift-tenancy.md) — shared vs dedicated workers, MCP/CVO upgrades

## Cross-DC Kafka replication (track)

**Entry point:** [Cross-DC architecture overview](kafka/cross-dc-architecture-overview.md) — canonical hub; path comparison, shared foundation, build order.

| Layer | Artifact | Multus path | Ingress path |
|---|---|---|---|
| Hub / decide | [cross-dc-architecture-overview.md](kafka/cross-dc-architecture-overview.md) | ✓ | ✓ |
| Generic network | [cross-dc-replication.md](../networking/cross-dc-replication.md) | ✓ | host only |
| Kafka / CFK | [cross-dc-cluster-linking.md](kafka/cross-dc-cluster-linking.md) | ✓ | ✓ |
| Cluster Link GitOps | [CLUSTER-LINK-GITOPS.md](kafka/CLUSTER-LINK-GITOPS.md), [scaffold](kafka/cluster-link-gitops/README.md) | ✓ | ✓ |
| Ingress depth | [cross-dc-ingress-alternative.md](kafka/cross-dc-ingress-alternative.md) | — | ✓ |
| Inventory → render | [cross-dc-rollout](../networking/cross-dc-rollout/README.md) | ✓ | ✓ |
| Host NNCP | [cross-dc-nncp-helm](kafka/cross-dc-nncp-helm/README.md) | ✓ | ✓ |
| Network test | [cross-dc-network-test](../networking/cross-dc-network-test/README.md) | ✓ | — |
| Ingress test | [cross-dc-ingress-test](../networking/cross-dc-ingress-test/README.md) | — | ✓ |
| Kafka NAD + MNP | [cross-dc-kafka-net-helm](kafka/cross-dc-kafka-net-helm/README.md) | ✓ | skip |
| Ingress examples | [ingress-replication/](kafka/examples/ingress-replication/README.md) | — | ✓ |

## Kafka (single-cluster)

| Example | Summary |
|---------|---------|
| [kafka/bare-metal-portworx/](kafka/bare-metal-portworx/README.md) | Rack-aware Kafka (CFK primary, Strimzi comparison), Portworx CSI, OCP 4.20+ |
| [kafka/README.md](kafka/README.md) | Full Kafka example index including cross-DC track |

Platform-agnostic Kafka content (when added) will live under `devops/workloads/messaging/` — not here.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

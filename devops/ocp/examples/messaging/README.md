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

## Kafka

| Example | Summary |
|---------|---------|
| [kafka/bare-metal-portworx/](kafka/bare-metal-portworx/README.md) | Rack-aware Kafka (CFK primary, Strimzi comparison), Portworx CSI, OCP 4.20+ |

Platform-agnostic Kafka content (when added) will live under `devops/workloads/messaging/` — not here.

## Planned / ideas

- Flink operator or standalone deployment (likely `devops/ocp/examples/streaming/` when it arrives)
- Schema Registry alongside CFK or Strimzi cluster

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

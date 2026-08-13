---
review:
  status: unreviewed
  notes: "Topic index — OpenShift networking examples."
---

# Networking — OpenShift Examples

Cluster networking configuration: OVN-Kubernetes install-time settings, Multus secondary networks, and VLAN segmentation.

## Cross-DC replication (track)

**Entry point:** [Cross-DC architecture overview](../messaging/kafka/cross-dc-architecture-overview.md)

| Guide | Summary |
|-------|---------|
| [cross-dc-replication.md](cross-dc-replication.md) | Generic host bond/VLAN/route + Multus depth |
| [cross-dc-rollout/](cross-dc-rollout/README.md) | Inventory → NNCP / test env / Kafka net (or ingress tickets) |
| [cross-dc-network-test/](cross-dc-network-test/README.md) | Pre-Kafka Multus verification (Path A) |
| [cross-dc-ingress-test/](cross-dc-ingress-test/README.md) | Pre-Kafka layered ingress verification (Path B) |
| [Cross-DC ingress alternative](../messaging/kafka/cross-dc-ingress-alternative.md) | Dedicated ingress shard + external handoff |

## Other networking

| Guide | Summary |
|-------|---------|
| [vlan-segmentation.md](vlan-segmentation.md) | Install-time `machineNetwork` vs day-2 Multus VLANs |
| [network-attachment-definitions/](network-attachment-definitions/README.md) | NAD, macvlan, SR-IOV, IPAM |
| [ovn-kubernetes-install-config/](ovn-kubernetes-install-config/README.md) | `install-config.yaml` OVN parameters, MTU, verification |

**Troubleshooting:** [CoreOS networking](../../troubleshooting/coreos-networking-issues/README.md) · [AAP SSH MTU](../../troubleshooting/aap-ssh-mtu-issues/README.md) · [Debug toolbox + NAD](../../troubleshooting/debug-toolbox-container/README.md)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
review:
  status: unreviewed
  notes: "Topic index — OpenShift networking examples."
---

# Networking — OpenShift Examples

Cluster networking configuration: OVN-Kubernetes install-time settings, Multus secondary networks, and VLAN segmentation.

| Guide | Summary |
|-------|---------|
| [vlan-segmentation.md](vlan-segmentation.md) | Install-time `machineNetwork` vs day-2 Multus VLANs |
| [network-attachment-definitions/](network-attachment-definitions/README.md) | NAD, macvlan, SR-IOV, IPAM |
| [ovn-kubernetes-install-config/](ovn-kubernetes-install-config/README.md) | `install-config.yaml` OVN parameters, MTU, verification |
| [cross-dc-replication.md](cross-dc-replication.md) | Bonded-NIC dedicated network between two datacenters — bond/VLAN/route, Multus NAD, MultiNetworkPolicy (design doc, not yet implemented) |
| [Cross-DC architecture overview](../messaging/kafka/cross-dc-architecture-overview.md) | Combined single-doc version of this + [Kafka Cluster Linking](../messaging/kafka/cross-dc-cluster-linking.md), for sharing outside the repo |
| [Cross-DC replication NNCP (Helm)](../messaging/kafka/cross-dc-nncp-helm/README.md) | Per-node `NodeNetworkConfigurationPolicy` generator for the pattern above — one CR per node, unique static IP, rendered from Helm values |
| [Cross-DC rollout inventory](cross-dc-rollout/README.md) | Single inventory YAML per DC → renders NNCP values, test env files, Kafka NAD/MultiNetworkPolicy values |
| [Cross-DC network test framework](cross-dc-network-test/README.md) | Script-driven verification of the network layer above across two live clusters (UBI9 probe pods), isolated from Kafka |
| [Cross-DC Kafka replication network (Helm)](../messaging/kafka/cross-dc-kafka-net-helm/README.md) | Kafka `NetworkAttachmentDefinition` + `MultiNetworkPolicy` on the replication VLAN — deploy after network test passes |

**Troubleshooting:** [CoreOS networking](../../troubleshooting/coreos-networking-issues/README.md) · [AAP SSH MTU](../../troubleshooting/aap-ssh-mtu-issues/README.md) · [Debug toolbox + NAD](../../troubleshooting/debug-toolbox-container/README.md)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
review:
  status: unreviewed
  notes: "Kafka scenario index on OpenShift."
---

# Kafka on OpenShift — Examples

Scenario-specific guides for running Apache Kafka on OpenShift (Confluent Platform Operator or Strimzi / Streams for Apache Kafka).

## Examples

| Scenario | Path | Operators | Focus |
|----------|------|-----------|-------|
| Bare metal + Portworx, rack-aware | [bare-metal-portworx/](bare-metal-portworx/README.md) | CFK (primary), Strimzi/AMQ Streams | Rack labels, Portworx CSI, ACM inventory, KRaft |
| Cross-DC Cluster Linking | [cross-dc-cluster-linking.md](cross-dc-cluster-linking.md) | CFK (Helm install) | Dedicated replication network, listener config, bidirectional DR links (design doc, not yet implemented) |
| Cross-DC architecture overview (combined) | [cross-dc-architecture-overview.md](cross-dc-architecture-overview.md) | CFK (Helm install) | Single-doc combination of the network + Cluster Linking designs above, for sharing outside the repo (design doc, not yet implemented) |
| Cross-DC replication NNCP (Helm) | [cross-dc-nncp-helm/](cross-dc-nncp-helm/README.md) | kubernetes-nmstate | Per-node `NodeNetworkConfigurationPolicy` generator — one CR per node with a unique static IP, rendered from Helm values |
| Cross-DC Kafka replication network (Helm) | [cross-dc-kafka-net-helm/](cross-dc-kafka-net-helm/README.md) | Multus / whereabouts | Kafka `NetworkAttachmentDefinition` + `MultiNetworkPolicy` on the replication VLAN — after network test passes |
| Cross-DC rollout inventory | [../../networking/cross-dc-rollout/](../../networking/cross-dc-rollout/README.md) | — | Inventory YAML per DC renders NNCP values, test env, and Kafka net values |

### bare-metal-portworx document map

| Doc | Purpose |
|-----|---------|
| [README](bare-metal-portworx/README.md) | Architecture, prerequisites, apply order, verification |
| [VALIDATION.md](bare-metal-portworx/VALIDATION.md) | Static review status, prerequisites matrix, cluster-side checks |
| [LABELING-COMPARISON.md](bare-metal-portworx/LABELING-COMPARISON.md) | `topology.kubernetes.io/zone` vs custom rack labels; CFK vs Strimzi field mapping |
| [manifests/](bare-metal-portworx/manifests/README.md) | zone-region and custom-rack manifest trees |

## OCP notes (cross-cutting)

| Topic | Note |
|-------|------|
| Network policy, OVN audit, NetObserv, Flink ports | [network-policy-observability](../../../notes/network-policy-observability.md) |
| Tenancy models, MCP/CVO upgrades, PDB pitfalls | [kafka-on-openshift-tenancy](../../../notes/kafka-on-openshift-tenancy.md) |
| Custom worker pools / MCP targeting | [machine-config-pools](../../../notes/machine-config-pools.md) |

## Related troubleshooting

| Symptom area | Guide |
|--------------|-------|
| Broker stuck in init — cannot reach `kubernetes.default` | [kafka-broker-init-kubernetes-svc](../../../troubleshooting/kafka-broker-init-kubernetes-svc/README.md) |
| Portworx CSI crashloop | [portworx-csi-crashloop](../../../troubleshooting/portworx-csi-crashloop/README.md) |
| NVMe host NQN duplicates (FlashArray prerequisite) | [nvme-host-nqn-duplicate](../../../troubleshooting/nvme-host-nqn-duplicate/README.md) |
| NVMe/TCP storage network | [nvme-tcp-storage-network](../../../troubleshooting/nvme-tcp-storage-network/README.md) |
| NFS Portworx proxy PVC slow bind | [nfs-portworx-proxy-pvc-slow-ready](../../../troubleshooting/nfs-portworx-proxy-pvc-slow-ready/README.md) |

Platform-agnostic Kafka content (when added) will live under `devops/workloads/messaging/` — not here.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

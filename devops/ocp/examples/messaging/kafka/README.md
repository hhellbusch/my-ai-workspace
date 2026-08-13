---
review:
  status: unreviewed
  notes: "Kafka scenario index on OpenShift."
---

# Kafka on OpenShift — Examples

Scenario-specific guides for running Apache Kafka on OpenShift (Confluent Platform Operator or Strimzi / Streams for Apache Kafka).

**Cross-DC replication:** start at [architecture overview](cross-dc-architecture-overview.md). Full track table: [messaging/README.md](../README.md#cross-dc-kafka-replication-track).

## Examples

| Scenario | Path | Operators | Focus |
|----------|------|-----------|-------|
| Bare metal + Portworx, rack-aware | [bare-metal-portworx/](bare-metal-portworx/README.md) | CFK (primary), Strimzi/AMQ Streams | Rack labels, Portworx CSI, ACM inventory, KRaft |
| Cross-DC Cluster Linking | [cross-dc-cluster-linking.md](cross-dc-cluster-linking.md) | CFK (Helm install) | Kafka/CFK layer — see [overview](cross-dc-architecture-overview.md) first |
| Cluster Link GitOps (CRD vs API) | [CLUSTER-LINK-GITOPS.md](CLUSTER-LINK-GITOPS.md) | Argo CD / CFK | Link management patterns — CRD, reconcile Job, decision matrix |
| Cluster Link GitOps scaffold | [cluster-link-gitops/README.md](cluster-link-gitops/README.md) | Argo CD / CFK | Example desired specs, reconcile script, CR/Job manifests |
| Cross-DC architecture overview | [cross-dc-architecture-overview.md](cross-dc-architecture-overview.md) | CFK (Helm install) | **Canonical hub** for cross-DC replication |
| Cross-DC ingress / Route alternative | [cross-dc-ingress-alternative.md](cross-dc-ingress-alternative.md) | CFK Routes + IngressController | Dedicated ingress shard on repl VLAN |
| Cross-DC replication NNCP (Helm) | [cross-dc-nncp-helm/](cross-dc-nncp-helm/README.md) | kubernetes-nmstate | Per-node `NodeNetworkConfigurationPolicy` generator — one CR per node with a unique static IP, rendered from Helm values |
| Cross-DC Kafka replication network (Helm) | [cross-dc-kafka-net-helm/](cross-dc-kafka-net-helm/README.md) | Multus / whereabouts | Kafka NAD + `MultiNetworkPolicy` on the replication VLAN — after network test passes |
| MultiNetworkPolicy on replication NAD | [cross-dc-kafka-net-helm/MULTINETWORKPOLICY.md](cross-dc-kafka-net-helm/MULTINETWORKPOLICY.md) | Multus | Default deny, mis-attachment defense, verification |
| Broker replication IP (whereabouts vs static) | [cross-dc-kafka-net-helm/BROKER-IPAM.md](cross-dc-kafka-net-helm/BROKER-IPAM.md) | Multus / CFK | Mode comparison, end-to-end lifecycle, subnet layout, failure modes |
| Cross-DC rollout inventory | [../../networking/cross-dc-rollout/](../../networking/cross-dc-rollout/README.md) | — | Inventory YAML per DC → rendered NNCP, test env, Kafka net (Multus) or ingress tickets |
| Ingress replication examples | [examples/ingress-replication/](examples/ingress-replication/README.md) | IngressController | Generic manifests for dedicated ingress shard |

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

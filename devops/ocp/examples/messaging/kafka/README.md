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

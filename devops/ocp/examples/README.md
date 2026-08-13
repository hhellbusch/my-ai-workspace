---
review:
  status: unreviewed
  notes: "Reorganized by topic 2026-07-23 — bare-metal, messaging, networking, labs."
---

# OpenShift Configuration Examples

Runnable scenarios and templates for OpenShift clusters, grouped by **topic** under `examples/`.

> **Where does new content go?** See [devops/ORGANIZATION.md](../../ORGANIZATION.md) for placement rules (platform vs workload, examples vs troubleshooting vs notes).

## Topic index

| Topic | When to look here |
|-------|-------------------|
| [bare-metal/](bare-metal/README.md) | Secondary disks, `/var/log` offload, fleet `by-path` identity |
| [messaging/](messaging/README.md) | Kafka (Strimzi/CFK), future Connect/Schema Registry |
| [networking/](networking/README.md) | OVN install config, Multus/NAD, VLAN segmentation |
| [labs/](labs/README.md) | Home-lab and SNO reproduction environments |

**Symptom under fire?** Use [troubleshooting](../troubleshooting/README.md) or [SYMPTOM-INDEX.md](../../SYMPTOM-INDEX.md) — not this directory.

---

## bare-metal

- **[Secondary disk offload](bare-metal/secondary-disk/README.md)** — Patterns A–D, `by-path`, 14 TiB layout, use-case index
- **[`/var/log` on secondary disk](bare-metal/var-log-disk/README.md)** — Ignition vs script + systemd `MachineConfig`

## messaging

- **[Kafka on bare-metal with Portworx](messaging/kafka/bare-metal-portworx/README.md)** — Rack-aware CFK/Strimzi, OCP 4.20+
- **[Cross-DC Cluster Linking](messaging/kafka/cross-dc-cluster-linking.md)** — Confluent Cluster Linking over a dedicated cross-DC network (design doc)
- **[Cross-DC architecture overview](messaging/kafka/cross-dc-architecture-overview.md)** — combined network + Cluster Linking doc, for sharing outside the repo (design doc)
- **[Cross-DC replication NNCP (Helm)](messaging/kafka/cross-dc-nncp-helm/README.md)** — per-node `NodeNetworkConfigurationPolicy` generator, one CR per node with a unique static IP
- **[Cross-DC Kafka replication network (Helm)](messaging/kafka/cross-dc-kafka-net-helm/README.md)** — Kafka NAD + `MultiNetworkPolicy` on the replication VLAN (whereabouts or static broker IPs); [policy primer](messaging/kafka/cross-dc-kafka-net-helm/MULTINETWORKPOLICY.md)
- **[Cross-DC rollout inventory](networking/cross-dc-rollout/README.md)** — single inventory YAML per DC → renders NNCP values, test env, Kafka net values
- **[Cross-DC network test](networking/cross-dc-network-test/README.md)** — script-driven pre-cutover verification across two live clusters

Companion notes: [network policy and observability](../notes/network-policy-observability.md) · [Kafka on OpenShift tenancy](../notes/kafka-on-openshift-tenancy.md)

## networking

- **[VLAN segmentation](networking/vlan-segmentation.md)** — Install-time vs day-2 Multus VLANs
- **[NetworkAttachmentDefinition (NAD)](networking/network-attachment-definitions/README.md)** — Multus, VLAN, SR-IOV
- **[OVN-Kubernetes install config](networking/ovn-kubernetes-install-config/README.md)** — `install-config.yaml` networking
- **[Cross-DC replication network](networking/cross-dc-replication.md)** — Bonded NIC, dedicated VLAN, MultiNetworkPolicy (design doc)
- **[Cross-DC network test](networking/cross-dc-network-test/README.md)** — Pre-cutover verification script + UBI9 probe image
- **[Cross-DC rollout inventory](networking/cross-dc-rollout/README.md)** — Inventory → rendered Helm values and test env files

## labs

- **[SNO on KVM](labs/sno-kvm-lab/README.md)** — Agent install, HPP storage, image registry, ArgoCD bootstrap

---

## Using these examples

Each example should include:

1. **Overview** — what it is and when to use it
2. **Quick start** — copy-paste commands
3. **Manifests or config** — runnable artifacts
4. **Verification** — how to confirm it worked
5. **Cross-links** — related troubleshooting and RHACM hub notes

When adding a new example, pick the topic directory (or create one), add a row to that topic's `README.md`, and link from this file.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
review:
  status: unreviewed
  notes: "Helm chart drafted from cross-DC replication design; supports whereabouts and static broker IP modes — see BROKER-IPAM.md."
---

# Cross-DC Kafka Replication Network — Helm Template

**Audience:** Whoever deploys Kafka on the replication VLAN after the [network test](../../../networking/cross-dc-network-test/README.md) passes.

**Purpose:** Render the workload `NetworkAttachmentDefinition` and matching `MultiNetworkPolicy` for Kafka brokers — in either **whereabouts pool** or **static per-broker** IP mode (`ipam.mode`).

**Related:** [BROKER-IPAM.md](BROKER-IPAM.md) (trade-offs) · [Cross-DC architecture overview](../cross-dc-architecture-overview.md#broker-replication-ip-assignment) · [Cross-DC rollout inventory](../../../networking/cross-dc-rollout/README.md)

---

## Broker IP modes

| `ipam.mode` | Helm output | CFK integration |
|---|---|---|
| `whereabouts` (default) | NAD with whereabouts pool + route in IPAM | Simple pod annotation + init container → [snippet](examples/cfk-kafka-whereabouts.snippet.yaml) |
| `static` | Static IPAM NAD + `broker-ip-map` ConfigMap | Per-broker extended annotation → [snippet](examples/cfk-kafka-static.snippet.yaml) |

**Read [BROKER-IPAM.md](BROKER-IPAM.md) before choosing** — neither mode is required for Cluster Linking; they differ in predictability, firewall shape, and operational overhead. Runtime chain and failure modes: [End-to-end pipeline](BROKER-IPAM.md#end-to-end-pipeline).

---

## Prerequisites

- Host NNCP applied and [network test](../../../networking/cross-dc-network-test/README.md) passed
- `useMultiNetworkPolicy: true` — [cluster-network-operator-patch.example.yaml](../../../networking/cross-dc-rollout/examples/cluster-network-operator-patch.example.yaml)
- Workload namespace exists — this chart does not install CFK

## Quick start

```bash
cd ../../../networking/cross-dc-rollout
cp inventory-dc-a.example.yaml inventory-dc-a.yaml   # or inventory-dc-a.static.example.yaml
python3 render-config.py --inventory inventory-dc-a.yaml
```

```bash
helm template kafka-repl-net . -f values-dc-a.yaml | oc apply -f -
```

Manual values: `values-dc-a.example.yaml` (whereabouts) or `values-dc-a.static.example.yaml` (static).

## Values

| Field | Meaning |
|---|---|
| `ipam.mode` | `whereabouts` or `static` — see [BROKER-IPAM.md](BROKER-IPAM.md) |
| `ipam.range` / `.rangeStart` / `.rangeEnd` | Whereabouts pool (mode=whereabouts only) |
| `brokers[]` | `name` + `replIp` per replica (mode=static only) |
| `replicationNetwork.*` | Bond VLAN master, gateway, remote subnet |
| `workload.*` | Namespace, NAD name, replication port, policy podSelector |

Static mode also renders ConfigMap `{{ nadName }}-broker-ip-map` with copy-paste Multus JSON per broker.

## Verification

1. `oc get network-attachment-definition -n confluent`
2. `oc get multi-networkpolicy -n confluent`
3. Static: `oc get cm kafka-repl-net-broker-ip-map -n confluent`
4. Broker `network-status` — no `default-route` on replication attachment
5. [Architecture verification checklist](../cross-dc-architecture-overview.md#verification-checklist)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

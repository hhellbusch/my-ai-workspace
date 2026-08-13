---
review:
  status: unreviewed
  notes: "Helm chart drafted from cross-DC replication design; supports whereabouts and static broker IP modes — see BROKER-IPAM.md."
---

# Cross-DC Kafka Replication Network — Helm Template

**Audience:** Whoever deploys Kafka on the replication VLAN after the [network test](../../../networking/cross-dc-network-test/README.md) passes.

**Purpose:** Render the workload `NetworkAttachmentDefinition` and matching `MultiNetworkPolicy` objects for Kafka brokers — **Multus path only**. For the dedicated ingress shard path, skip this chart; see [cross-dc-ingress-alternative.md](../cross-dc-ingress-alternative.md) and [ingress-replication examples](../examples/ingress-replication/README.md).

**Related:** [MULTINETWORKPOLICY.md](MULTINETWORKPOLICY.md) (how policy works + mis-attachment defense) · [BROKER-IPAM.md](BROKER-IPAM.md) (broker IP modes) · [Cross-DC architecture overview](../cross-dc-architecture-overview.md#broker-replication-ip-assignment) · [Cross-DC rollout inventory](../../../networking/cross-dc-rollout/README.md)

---

## MultiNetworkPolicy posture

By default the chart renders **two** policies on `kafka-repl-net`:

| Policy | Purpose |
|---|---|
| `kafka-repl-net-default-deny` | Catch-all deny on `net1` for every pod attached to the NAD (mis-attachment defense) |
| `kafka-repl-net-restrict` | Allow labeled brokers TCP `9095` ↔ remote DC `/26` only |

Read **[MULTINETWORKPOLICY.md](MULTINETWORKPOLICY.md)** before changing policy shape — especially [default allow vs default deny](MULTINETWORKPOLICY.md#default-allow-vs-default-deny) and [verification](MULTINETWORKPOLICY.md#verify-enforcement).

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
| `multiNetworkPolicy.defaultDenyOnNad` | Render catch-all deny on the NAD (default `true`) — see [MULTINETWORKPOLICY.md](MULTINETWORKPOLICY.md) |
| `replicationNetwork.*` | Bond VLAN master, gateway, remote subnet |
| `workload.*` | Namespace, NAD name, replication port, policy `podSelector` |

Static mode also renders ConfigMap `{{ nadName }}-broker-ip-map` with copy-paste Multus JSON per broker.

## Verification

1. `oc get network-attachment-definition -n confluent`
2. `oc get multi-networkpolicy -n confluent` — expect `kafka-repl-net-default-deny` and `kafka-repl-net-restrict` when `defaultDenyOnNad: true`
3. Static: `oc get cm kafka-repl-net-broker-ip-map -n confluent`
4. Broker `network-status` — no `default-route` on replication attachment
5. [Mis-attachment probe](MULTINETWORKPOLICY.md#verify-enforcement) — unlabeled pod on `kafka-repl-net` cannot reach `:9095`
6. [Architecture verification checklist](../cross-dc-architecture-overview.md#verification-checklist)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

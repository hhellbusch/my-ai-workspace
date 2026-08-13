---
review:
  status: unreviewed
  notes: "Rollout tooling drafted from cross-DC replication design; inventory renderer not yet run against real clusters."
---

# Cross-DC Rollout — Inventory and Config Rendering

**Audience:** Whoever fills in real cluster inventory once and renders the downstream Helm values / test env files from it.

**Purpose:** One inventory file per DC drives the per-node NNCP chart, the network-test `dc-*.env` files, and the Kafka NAD/`MultiNetworkPolicy` chart — without maintaining three parallel copies of the same subnets, gateways, and node hostnames.

**Related:** [Cross-DC architecture overview](../../messaging/kafka/cross-dc-architecture-overview.md#pre-flight-before-network-verification) · [NNCP Helm chart](../../messaging/kafka/cross-dc-nncp-helm/README.md) · [Kafka net Helm chart](../../messaging/kafka/cross-dc-kafka-net-helm/README.md) · [Network test framework](../cross-dc-network-test/README.md)

---

## On this page

- [Inventory vs Helm values — same or overlay?](#inventory-vs-helm-values--same-or-overlay)
- [What needs Helm vs what doesn't](#what-needs-helm-vs-what-doesnt)
- [Quick start](#quick-start)
- [Inventory schema](#inventory-schema)
- [Layout](#layout)

---

## Inventory vs Helm values — same or overlay?

**Neither identical nor a Helm `--values` overlay.** The inventory is a **superset**; `render-config.py` **projects** it into three downstream shapes:

| Downstream file | Chart / consumer | Relationship to inventory |
|---|---|---|
| `cross-dc-nncp-helm/values-dc-a.yaml` | NNCP Helm | Subset: `replicationNetwork.*` + `nodes[].hostname/ip` only |
| `cross-dc-network-test/dc-a.env` | `preflight.sh` / `run-network-test.sh` | Derived: kubeconfig, space-separated `NODE_NAMES`, bond VLAN iface name (`bondName.vlanId`), test pool, probe image |
| `cross-dc-kafka-net-helm/values-dc-a.yaml` | Kafka NAD + `MultiNetworkPolicy` Helm | Subset: bond/VLAN master, kafka whereabouts pool, remote subnet route, workload labels |

You **edit inventory once**, re-render, then deploy each layer in order. The `.example.yaml` files in each chart remain as documentation; real clusters should use rendered `values-dc-*.yaml` from inventory.

---

## What needs Helm vs what doesn't

| OpenShift layer | Tooling | Why |
|---|---|---|
| Host bond/VLAN/routes (NNCP) | **Helm** — [cross-dc-nncp-helm](../../messaging/kafka/cross-dc-nncp-helm/) | Per-node unique static IPs — *N* similar CRs |
| Kafka NAD + `MultiNetworkPolicy` | **Helm** — [cross-dc-kafka-net-helm](../../messaging/kafka/cross-dc-kafka-net-helm/) | Per-DC values (namespace, pools, remote subnet) — repeatable after network test |
| Network verification pods | **`envsubst` + shell** — [cross-dc-network-test](../cross-dc-network-test/) | Fixed two-cluster runbook; env rendered from inventory |
| `useMultiNetworkPolicy: true` | **One-time patch** — [examples/cluster-network-operator-patch.example.yaml](examples/cluster-network-operator-patch.example.yaml) | Singleton `Network` CR — not chart material |
| CFK / Cluster Linking API | **Out of scope here** | Confluent Helm + API calls — see [cross-dc-cluster-linking.md](../../messaging/kafka/cross-dc-cluster-linking.md) |
| MachineConfig / MCP node pools | **Manual / site-specific** | Only if you target NNCP by pool instead of hostname — not templated in this example set |

---

## Quick start

```bash
cd devops/ocp/examples/networking/cross-dc-rollout

# 1. Copy and fill inventory (gitignored real copies)
cp inventory-dc-a.example.yaml inventory-dc-a.yaml
cp inventory-dc-b.example.yaml inventory-dc-b.yaml

# 2. Validate and render all downstream configs
python3 render-config.py --both --validate-only   # dry validation
python3 render-config.py --both

# 3. Optional: firewall change ticket for network team
python3 render-config.py --both \
  --firewall-request firewall-change-request.md

# 4. Deploy in order (each cluster, DC-A then DC-B or parallel per your process)
#    a. Enable MultiNetworkPolicy (once per cluster)
oc apply -f examples/cluster-network-operator-patch.example.yaml

#    b. Host network
helm template repl-net ../../messaging/kafka/cross-dc-nncp-helm \
  -f ../../messaging/kafka/cross-dc-nncp-helm/values-dc-a.yaml | oc apply -f -

#    c. Verify network layer
cd ../cross-dc-network-test
./preflight.sh dc-a.env dc-b.env
./run-network-test.sh dc-a.env dc-b.env

#    d. Kafka NAD + policy (after network test passes)
helm template kafka-repl-net ../../messaging/kafka/cross-dc-kafka-net-helm \
  -f ../../messaging/kafka/cross-dc-kafka-net-helm/values-dc-a.yaml | oc apply -f -
```

Requires **Python 3 + PyYAML** (`dnf install python3-pyyaml`).

---

## Inventory schema

See [INVENTORY-WORKSHEET.md](INVENTORY-WORKSHEET.md) for a human worksheet, then transcribe into YAML.

| Section | Used by |
|---|---|
| `cluster.kubeconfig` | Test env only (workstation path) |
| `replicationNetwork.*` | All three downstream outputs |
| `nodes[]` | NNCP (`hostIp`); test env (`hostname`, `networkTest`) |
| `workload.brokerIpam.mode` | `whereabouts` or `static` — see [BROKER-IPAM.md](../../messaging/kafka/cross-dc-kafka-net-helm/BROKER-IPAM.md) |
| `workload.multiNetworkPolicy.defaultDenyOnNad` | Catch-all deny on replication NAD (default `true`) — [MULTINETWORKPOLICY.md](../../messaging/kafka/cross-dc-kafka-net-helm/MULTINETWORKPOLICY.md) |
| `workload.brokers[]` | Static mode only — `name` + `replIp` per Kafka replica |
| `ipPools.test` | Test env / test NAD |
| `ipPools.kafka` | Whereabouts mode pool (optional spacing reference for static) — [subnet layout on the `/26`](../../messaging/kafka/cross-dc-kafka-net-helm/BROKER-IPAM.md#subnet-layout-on-the-26) |
| `workload.*` | Kafka NAD + `MultiNetworkPolicy` Helm |
| `probe.image` | Test env (`TEST_PROBE_IMAGE`) |

`render-config.py` validates that host IPs do not fall inside test/kafka pools and that test/kafka pools do not overlap.

---

## Layout

```text
cross-dc-rollout/
├── README.md                              — this file
├── INVENTORY-WORKSHEET.md                   — planning table before YAML
├── inventory-dc-a.example.yaml            — whereabouts mode (default)
├── inventory-dc-a.static.example.yaml       — static per-broker IPs
├── inventory-dc-b.example.yaml
├── render-config.py                       — inventory → nncp values + dc env + kafka values
├── validate-local.sh                      — local lint/template/frontmatter gate (no cluster)
├── templates/
│   └── firewall-change-request.md.example
└── examples/
    └── cluster-network-operator-patch.example.yaml
```

Generated (gitignored): `inventory-dc-*.yaml`, chart `values-dc-*.yaml`, `cross-dc-network-test/dc-*.env`, optional `firewall-change-request.md`.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

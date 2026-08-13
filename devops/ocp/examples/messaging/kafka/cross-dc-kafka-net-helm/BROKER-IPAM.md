---
review:
  status: unreviewed
  notes: "Broker replication IP assignment modes for cross-DC Kafka — trade-offs and CFK integration."
---

# Broker replication IP assignment — whereabouts vs static

**Audience:** Whoever chooses how Kafka brokers get Multus IPs on the replication VLAN and how `REPL_IP` is wired into CFK.

**Purpose:** Compare the two supported `ipam.mode` values for [cross-dc-kafka-net-helm](README.md) and explain what each implies for Cluster Linking, firewalls, and pod lifecycle — so the choice is deliberate, not accidental.

**Related:** [Cross-DC architecture overview](../cross-dc-architecture-overview.md#broker-replication-ip-assignment) · [Cross-DC rollout inventory](../../../networking/cross-dc-rollout/README.md) · [Cluster Linking listener config](../cross-dc-cluster-linking.md#cfk-listener-configuration)

---

## What brokers actually need

Cluster Linking does **not** require statically pinned IPs. It requires:

1. Each broker has a **real Multus IP** on the replication NAD (not the default OVN network).
2. `advertised.listeners` exposes `REPLICATION://<that-ip>:9095` (via `$(REPL_IP)` or equivalent).
3. The link's `bootstrap.servers` uses those **advertised** addresses — not internal/external listeners.
4. Addresses are **stable enough** for your operational model (pod restart, failback, firewall change process).

Both modes below satisfy (1)–(3). They differ on (4), manifest complexity, and firewall shape.

---

## Mode comparison

| | **whereabouts** (pool) | **static** (per-broker pin) |
|---|---|---|
| **NAD shape** | Single macvlan + whereabouts range + route in IPAM | Chained macvlan + `static` IPAM + tuning plugin |
| **IP chosen by** | Whereabouts at pod schedule time | You, per StatefulSet ordinal, in pod annotation |
| **`REPL_IP` source** | Init container reading `network-status` (typical) | Literal env or annotation-derived — known before pod starts |
| **Pod annotation** | `k8s.v1.cni.cncf.io/networks: kafka-repl-net` | Extended JSON with `ips` + `routes` per broker — see [static snippet](examples/cfk-kafka-static.snippet.yaml) |
| **After pod delete/recreate** | IP may change unless whereabouts reassigns consistently | Same ordinal → same IP (if annotation unchanged) |
| **Cluster Link bootstrap list** | Must be updated if IPs drift, or automate discovery | Fixed list from [broker-ip-map](templates/broker-ip-map.yaml) ConfigMap |
| **Firewall ACLs** | Allow whole pool range (e.g. `.20–.60`) | Can allow per-`/32` broker IPs |
| **Operational complexity** | Lower — one pool, one annotation shape | Higher — N broker rows in inventory, per-pod CFK patches |
| **Best first choice when** | Subnet-wide firewall rules, GitOps link scripts that query live brokers | Per-broker `/32` ACLs, hand-maintained link config, avoiding init container |

**Host NNCP static IPs are a separate question.** Per-node host addresses on the bond VLAN are **not** required for macvlan broker traffic — see [NNCP Helm README](../cross-dc-nncp-helm/README.md). Brokers care about **pod** IPs, not host IPs.

---

## Whereabouts mode (default)

### How it works

1. Helm renders a whereabouts NAD with a carved pool and route to the remote `/26`.
2. CFK Kafka `podTemplate` attaches the NAD by name.
3. An **init container** (or equivalent) reads `k8s.v1.cni.cncf.io/network-status`, extracts the `kafka-repl-net` IP, exports `REPL_IP` for broker startup.
4. Firewalls allow **TCP/9095 (and ICMP for MTU)** between the **kafka pools** on each DC.

### Trade-offs

**Pros:** One NAD for all brokers; simplest pod annotation; pool scales if broker count changes; matches the [network test](../../../networking/cross-dc-network-test/README.md) pattern (whereabouts + routes in IPAM).

**Cons:** `REPL_IP` not known at manifest-authoring time; init container adds a moving part; broker recreate **may** get a new IP — Cluster Link config that hard-codes bootstrap addresses can drift unless you refresh links or automate discovery.

See [examples/cfk-kafka-whereabouts.snippet.yaml](examples/cfk-kafka-whereabouts.snippet.yaml).

---

## Static mode

### How it works

1. Helm renders a **static IPAM** NAD (chained plugins — no whereabouts pool on the NAD).
2. Inventory lists `brokers[]` with `name` + `replIp` per StatefulSet replica.
3. Helm also renders a **ConfigMap** (`kafka-repl-net-broker-ip-map`) with per-broker `networks-annotation.json` fragments.
4. Each broker's CFK `podTemplate` uses the **extended** Multus annotation (IP + route to remote subnet — routes are on the **pod**, not the NAD).
5. `REPL_IP` can be a **literal env var** per ordinal (or templated from the same inventory).

### Trade-offs

**Pros:** Predictable IPs for firewalls and link bootstrap; no init container; survives pod recreate with same ordinal; maps cleanly to StatefulSet identity.

**Cons:** More inventory and CFK YAML to maintain; adding/removing brokers requires IP plan + link updates; mis-typed annotation fails at schedule time; no dynamic pool — you own IPAM.

See [examples/cfk-kafka-static.snippet.yaml](examples/cfk-kafka-static.snippet.yaml).

---

## Choosing in inventory

Set `workload.brokerIpam.mode` in [inventory YAML](../../../networking/cross-dc-rollout/inventory-dc-a.example.yaml):

```yaml
workload:
  brokerIpam:
    mode: whereabouts   # or static
  brokers: []           # required when mode=static
  # brokers:
  #   - name: kafka-0
  #     replIp: 10.200.1.21
```

Run `render-config.py` — it validates pools, renders Helm values, and (for static) passes through `brokers[]`.

Examples:

- [inventory-dc-a.example.yaml](../../../networking/cross-dc-rollout/inventory-dc-a.example.yaml) — whereabouts (default)
- [inventory-dc-a.static.example.yaml](../../../networking/cross-dc-rollout/inventory-dc-a.static.example.yaml) — static per-broker

---

## Switching modes later

Not a hot-swap — plan a maintenance window:

1. Update inventory `brokerIpam.mode` and broker list / pool as needed.
2. Re-render and apply NAD (mode change replaces CNI config).
3. Rolling restart brokers with updated pod annotations / init container / `REPL_IP` wiring.
4. Update Cluster Link `bootstrap.servers` on both sides.
5. Confirm firewalls match new shape (pool range vs `/32` list).

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

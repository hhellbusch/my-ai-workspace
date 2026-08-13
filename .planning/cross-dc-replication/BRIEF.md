# Cross-DC Replication Network + Kafka Rollout

> **Status:** In Progress — artifacts drafted; not yet run against live clusters
> **Started:** 2026-08-11 (design); 2026-08-12 (implementation tooling)
> **Owner:** Platform engineering (OpenShift + CFK)

## Audience and Purpose

**Reader:** Platform engineers and network peers implementing or reviewing dedicated cross-DC replication networking on bare-metal OpenShift before Confluent Cluster Linking cutover.

**Enables:** Generic design guide and runnable tooling for dedicated cross-DC replication — compare Multus vs ingress paths; implement either without the corpus assuming a single chosen path.

## Problem Statement

Two bare-metal OpenShift clusters in different datacenters need a **dedicated, routed replication VLAN** (bond + VLAN + scoped L3 route) so Confluent Cluster Linking traffic can stay off management/OVN paths. The corpus documents **two production mechanisms** (Multus direct attachment vs dedicated ingress shard) plus shared host-network foundations. Runnable tooling covers both paths: Multus network test and ingress layered test; ingress also has frontend examples and change-request templates.

## Scope

**In scope (this project):**

- Design documentation: hub at `cross-dc-architecture-overview.md`; depth in `cross-dc-replication.md`, `cross-dc-cluster-linking.md`, `cross-dc-ingress-alternative.md`
- Host network: per-node NNCP Helm chart (`cross-dc-nncp-helm`)
- Pre-Kafka verification: `cross-dc-network-test/` (Multus); `cross-dc-ingress-test/` (ingress layered checks) + UBI9 `repl-net-probe` image
- Rollout inventory: single YAML per DC → rendered NNCP values, test env, Kafka NAD/MNP values
- Kafka replication VLAN: NAD + MultiNetworkPolicy Helm chart with **whereabouts or static** broker IP modes (`BROKER-IPAM.md`)
- Pre-flight docs, `preflight.sh`, `validate-local.sh`, firewall change template

**Out of scope:**

- CFK install, listener CR wiring, Cluster Link API calls / Control Center UI steps (documented as open questions only)
- Submariner / L2 stretch / shared subnet across DCs
- Production firewall implementation (template only)
- CI workflow for `validate-local.sh` (future)

## Success Criteria

**Shared (both paths):**

- [ ] Real inventory filled; `render-config.py --both` produces consistent configs for both DCs
- [ ] NNCP applied; `oc get nnce` Available on replication nodes (both clusters)

**Multus path (`replicationPath: multus`):**

- [ ] `./preflight.sh` then `./run-network-test.sh` pass on both clusters
- [ ] Kafka NAD + MultiNetworkPolicy applied; brokers advertise `REPL_IP` on port 9095
- [ ] Cluster Link `bootstrap.servers` uses replication listener addresses

**Ingress path (`replicationPath: ingress`):**

- [ ] `./preflight-ingress.sh` then `./run-ingress-test.sh` pass on both clusters (layered host → frontend → router → route)
- [ ] DNS + firewall tickets rendered; replication hostnames resolve to repl-subnet frontend
- [ ] Dedicated `IngressController` shard admits only labelled Routes
- [ ] CFK Route listener active; Cluster Link `bootstrap.servers` uses route hostnames

**Either path:**

- [ ] Bidirectional pre-staged links resume replication after failback

## Constraints

- CFK via Helm (not OLM); `platform.confluent.io` CRDs
- Bare-metal nodes; bond on two physical cards; L3 routed /26 per DC
- Multus macvlan (or ipvlan if ToR MAC limits); whereabouts IPAM for pools
- `useMultiNetworkPolicy: true` on both clusters before policy enforcement
- Secure clusters: no third-party debug images — UBI9 `repl-net-probe` on Quay (`0.1.1`)
- Design docs remain source of truth; overview is a combined shareable snapshot

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Host config mechanism | NNCP (nmstate) over raw MachineConfig | Day-2 mutable; `NodeNetworkState` verification |
| Per-node host IPs | Optional — chart supports them; macvlan pods don't require host IP | Simpler if firewalls allow pod subnets only |
| Per-node NNCP templating | Helm from node list | NMState can't vary IP inside one CR |
| Pre-Kafka verification | Shell script + probe pods, not Chainsaw/CI | One-time pre-cutover runbook; YAGNI |
| Probe image | UBI9 `repl-net-probe` (ncat, ping, iproute) | Quay-publishable; no netshoot CVE surface |
| Test vs Kafka IP pools | Disjoint whereabouts ranges on same VLAN | Test independently of CFK state |
| Downstream config shape | Inventory YAML → `render-config.py` projections | Avoid duplicating subnets/node names across env + Helm values |
| Kafka broker attachment | **Multus** (primary) or **dedicated ingress shard** (alternative) | Multus: per-broker repl IPs, no router hop. Ingress: CFK Route ergonomics — `cross-dc-ingress-alternative.md` |
| Kafka broker IPAM (Multus path) | **whereabouts** (default) or **static** per ordinal | Flexibility; documented trade-offs in `BROKER-IPAM.md` |
| Kafka net templating | Helm for NAD/MNP; test framework stays envsubst | Helm where N/DC values matter; fixed two-cluster test stays shell |
| Cluster Linking ops | API-driven (Control Center), not CRD | Current plan; link config must still be scripted/versioned |

## Open Questions (require real environment)

- New bond vs VLAN on existing bond — bandwidth/fault isolation differs
- LACP vs active-backup on local ToR
- End-to-end WAN MTU
- Whether static per-node host IPs are required by network ops
- **Replication path:** Multus direct vs dedicated ingress shard vs default-ingress PoC (`cross-dc-ingress-alternative.md`)
- **Ingress frontend:** VIP (keepalived/MetalLB) vs DNS LB to router node repl IPs — no external hardware LB today
- CFK `listeners` schema vs `configOverrides.server` passthrough for REPLICATION listener
- `reverse-and-start` vs two independent bidirectional links (topic prefixing?)

## Related

| Artifact | Path |
|----------|------|
| **Canonical hub** | `devops/ocp/examples/messaging/kafka/cross-dc-architecture-overview.md` |
| Generic network design | `devops/ocp/examples/networking/cross-dc-replication.md` |
| Cluster Linking layer | `devops/ocp/examples/messaging/kafka/cross-dc-cluster-linking.md` |
| Ingress / Route alternative | `devops/ocp/examples/messaging/kafka/cross-dc-ingress-alternative.md` |
| Ingress examples | `devops/ocp/examples/messaging/kafka/examples/ingress-replication/` |
| Rollout inventory | `devops/ocp/examples/networking/cross-dc-rollout/` |
| Network test | `devops/ocp/examples/networking/cross-dc-network-test/` |
| NNCP Helm | `devops/ocp/examples/messaging/kafka/cross-dc-nncp-helm/` |
| Kafka net Helm | `devops/ocp/examples/messaging/kafka/cross-dc-kafka-net-helm/` |
| Broker IPAM guide | `devops/ocp/examples/messaging/kafka/cross-dc-kafka-net-helm/BROKER-IPAM.md` |
| Session transcript | `.cursor/projects/.../66ce9761-c76d-403c-90dd-27ad7a4bb4cb.jsonl` |

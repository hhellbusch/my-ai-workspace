---
review:
  status: unreviewed
  notes: "Planning worksheet for cross-DC inventory — transcribe into inventory YAML."
---

# Cross-DC inventory worksheet

Fill this in during discovery, then transcribe into `inventory-dc-a.yaml` / `inventory-dc-b.yaml` and run `render-config.py --both`.

**Hub:** [architecture overview](../../messaging/kafka/cross-dc-architecture-overview.md)

## Replication path

| Field | Value | Notes |
|---|---|---|
| `replicationPath` | `multus` or `ingress` | Default `multus` — see [inventory-dc-a.ingress.example.yaml](inventory-dc-a.ingress.example.yaml) |

## Cluster

| Field | DC-A value | Notes |
|---|---|---|
| `cluster.id` | `dc-a` | Must end in `-a` or `-b` for env prefix |
| `cluster.kubeconfig` | | Workstation path only |

## Replication network (shared per DC)

| Field | DC-A value | Confirm with |
|---|---|---|
| `bondName` | `bond-repl` | NNCP / `oc get nns` |
| `bondMode` | `active-backup` | ToR LACP capability |
| `ports[]` | `ens4f0`, `ens5f0` | `ip link` / hardware inventory |
| `vlanId` | `200` | Network team |
| `prefixLength` | `26` | IP plan |
| `localSubnet` | `10.200.1.0/26` | This DC |
| `localGateway` | `10.200.1.1` | On-wire gateway for remote route |
| `remoteSubnet` | `10.200.2.0/26` | **Other** DC |
| `expectedMtu` | `1500` | End-to-end path MTU on VLAN 200 — drives NNCP bond/VLAN MTU + network test 5. See [MTU constraints](../cross-dc-replication.md#mtu--parent-first-and-path-constraints). |

Derived (do not duplicate in inventory): VLAN iface = `{bondName}.{vlanId}` → `bond-repl.200`

## IP pools (test always; kafka pool for whereabouts mode)

| Pool | range | start | end | Must not overlap |
|---|---|---|---|---|
| `test` | | `.6` | `.10` | host IPs, kafka/broker IPs |
| `kafka` | | `.20` | `.60` | host IPs, test pool (whereabouts only) |

Full address map (gateway, test, host, kafka/static pins): [BROKER-IPAM.md — subnet layout](../../messaging/kafka/cross-dc-kafka-net-helm/BROKER-IPAM.md#subnet-layout-on-the-26).

## Nodes

| hostname | hostIp | networkTest | Notes |
|---|---|---|---|
| | | `true` | Must match `kubernetes.io/hostname` |
| | | `true` | |
| | | `false` | Broker-only node, skip test 1–2 node list |

## Workload (Kafka) — `replicationPath: multus` only

Skip this section when `replicationPath: ingress` — use **Ingress** section below instead.

| Field | Value |
|---|---|
| `workload.brokerIpam.mode` | `whereabouts` (default) or `static` — [BROKER-IPAM.md](../../messaging/kafka/cross-dc-kafka-net-helm/BROKER-IPAM.md) |
| `namespace` | `confluent` |
| `nadName` | `kafka-repl-net` |
| `replicationPort` | `9095` |
| `podSelector` | `app: kafka` |
| `multiNetworkPolicy.defaultDenyOnNad` | `true` (default) — [MULTINETWORKPOLICY.md](../../messaging/kafka/cross-dc-kafka-net-helm/MULTINETWORKPOLICY.md) |

**Whereabouts:** leave `workload.brokers: []`, use `ipPools.kafka` above.

**Static:** set `mode: static` and list brokers — see [inventory-dc-a.static.example.yaml](inventory-dc-a.static.example.yaml).

| broker name | replIp |
|---|---|
| `kafka-0` | |
| `kafka-1` | |

## Ingress — `replicationPath: ingress` only

| Field | Value |
|---|---|
| `ingress.domain` | `kafka-repl.dc-a.example.com` |
| `ingress.routeLabel` | `ingress: replication` |
| `ingress.frontendMode` | `vip` or `dns_lb` |
| `ingress.vip` | e.g. `10.200.1.5` (vip mode) |
| `ingress.dnsTargets[]` | router node repl IPs (dns_lb mode) |
| `ingress.externalPort` | `443` |
| `ingress.dnsTtl` | e.g. `60` |

Tickets: `render-config.py --both --firewall-request-ingress … --dns-request …`

## Probe image

| Field | Value |
|---|---|
| `probe.image` | `quay.io/.../repl-net-probe:0.1.1` |

---

## Cross-check before render

- [ ] `replicationPath` set consistently on both DC inventories
- [ ] Multus: every `hostIp` outside both pools; test/kafka pools disjoint
- [ ] Ingress: `ingress.domain` and VIP or `dnsTargets` filled per DC
- [ ] `remoteSubnet` on DC-A equals DC-B's `localSubnet` (and vice versa)
- [ ] Firewalls briefed using rendered `firewall-change-request.md`
- [ ] `useMultiNetworkPolicy: true` on both clusters

See [README.md](README.md) for render and deploy order.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

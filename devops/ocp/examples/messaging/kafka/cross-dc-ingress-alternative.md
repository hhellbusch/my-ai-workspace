---
review:
  status: unreviewed
  notes: "Design alternative drafted from architecture review — ingress/Route path vs Multus direct attachment. CFK field names and IngressController API should be checked against installed versions before use. Not yet run against live clusters."
---

# Cross-DC Kafka Replication — Ingress / Route Alternative

**Audience:** Platform engineers and network/DNS peers evaluating whether to use a **dedicated OpenShift IngressController** + CFK Routes instead of **Multus pod attachment** for Confluent Cluster Linking on a dedicated replication VLAN.

**Purpose:** Document the ingress-based replication path end-to-end — how it compares to the Multus design, what external network dependencies it creates (VIP, DNS, firewall, TLS), and how to operate it on bare metal **without** an external hardware load balancer (F5).

**Related:**

- [Cross-DC architecture overview](cross-dc-architecture-overview.md) — entry point; [choose your replication path](cross-dc-architecture-overview.md#choose-your-replication-path) compares all three paths
- [Confluent Cluster Linking across datacenters](cross-dc-cluster-linking.md) — Kafka/CFK listener and link semantics
- [Dedicated cross-DC replication network](../../networking/cross-dc-replication.md) — host bond/VLAN/route (required for both paths)
- [Cross-DC replication NNCP (Helm)](cross-dc-nncp-helm/README.md) — per-node host network on `bond-repl.200`
- [Cross-DC rollout inventory](../../networking/cross-dc-rollout/README.md) — inventory-driven NNCP rendering
- [Ingress replication examples](examples/ingress-replication/README.md) — generic `IngressController` manifests
- [Confluent: Configure OpenShift Routes](https://docs.confluent.io/operator/current/co-routes.html)
- [OpenShift: Ingress sharding (4.18)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/ingress_and_load_balancing/configuring-ingress-cluster-traffic#nw-ingress-sharding)
- [OpenShift: Ingress Operator (4.20)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/networking_operators/configuring-ingress)

---

## On this page

- [Replication path options](#replication-path-options)
- [Why teams consider ingress](#why-teams-consider-ingress)
- [Second IngressController on the replication VLAN](#second-ingresscontroller-on-the-replication-vlan)
- [CFK listener configuration (Route mode)](#cfk-listener-configuration-route-mode)
- [External network requirements](#external-network-requirements)
- [Frontend options without an external hardware LB](#frontend-options-without-an-external-hardware-lb)
- [Security and access control](#security-and-access-control)
- [Trade-off summary](#trade-off-summary)
- [Decision tree](#decision-tree)
- [External dependencies handoff](#external-dependencies-handoff)
- [Verification checklist (ingress path)](#verification-checklist-ingress-path)
- [Open questions](#open-questions)

---

## Replication path options

Three realistic shapes for cross-DC Cluster Linking on bare-metal OpenShift:

| Path | Pod attachment | Advertised endpoints | WAN egress from pod |
|---|---|---|---|
| **A — Multus (primary design)** | macvlan NAD on `bond-repl.200` | `REPLICATION://$(REPL_IP):9095` | Direct on replication `/26` |
| **B — Dedicated ingress shard** | None — broker stays on OVN | CFK Route hostnames on `:443` (TLS passthrough) | Router VIP or node repl IPs on replication `/26` → OVN → broker |
| **C — Default ingress (PoC)** | None | CFK Route hostnames on `apps.*` domain | Machine-network ingress VIP — **not** replication VLAN |

```text
Path A (Multus):
  Remote broker ──TCP 9095──► 10.200.1.21 (broker pod on repl VLAN)

Path B (dedicated ingress):
  Remote broker ──TCP 443──► repl VIP or DNS-LB pool on repl VLAN
           ──HAProxy (SNI)──► OVN ──► broker pod :9095

Path C (PoC / anti-pattern for prod):
  Remote broker ──TCP 443──► machine-network ingress VIP
           ──default HAProxy──► OVN ──► broker pod :9095
```

Path **C** is valid for functional PoC but defeats the dedicated VLAN goal.
Path **B** is the ingress-based production compromise when `$(REPL_IP)` / Multus operational complexity is the blocker.
Path **A** remains the design in [cross-dc-architecture-overview.md](cross-dc-architecture-overview.md) when per-broker IPs, no shared proxy hop, and `MultiNetworkPolicy` on the NAD are priorities.

---

## Why teams consider ingress

The Multus path requires wiring `advertised.listeners` to a secondary interface IP — typically `$(REPL_IP)` from an init container reading `network-status`, or static per-ordinal IPs ([BROKER-IPAM.md](cross-dc-kafka-net-helm/BROKER-IPAM.md)).

**CFK Route mode automates that chain:** CFK creates per-broker Routes, sets `advertised.listeners` to route hostnames, and Cluster Link `bootstrap.servers` becomes DNS names on port **443** (with TLS passthrough to broker **9095**).

A PoC on the **default** ingress proves Cluster Linking works with Routes — the open question is whether replication traffic can be moved onto the **replication VLAN** via a **second IngressController**, not whether Routes work at all.

---

## Second IngressController on the replication VLAN

OpenShift supports multiple `IngressController` shards.
Each shard is a separate HAProxy router deployment.
Sharding uses `routeSelector` / `namespaceSelector` — not a special Route annotation for shard membership (labels on the Route object itself).

### What you get vs what you build

| Component | Default ingress (today) | Replication ingress shard |
|---|---|---|
| Router pods (HAProxy) | `openshift-ingress` | Separate deployment (e.g. `openshift-ingress-replication`) |
| Platform-managed VIP | Machine network (`ingressVIP` at install) | **Not automatic** — you provide frontend on repl `/26` |
| `spec.domain` | `apps.<cluster>.<base>` | Separate zone, e.g. `kafka-repl.dc-a.example.com` |
| Route admission | All routes (unless excluded) | Only routes matching `routeSelector` |

The gap is not "need F5 instead of HAProxy."
It is: **what IP on `10.200.x.x/26` do remote brokers connect to?**

### Example IngressController

```yaml
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  name: replication
  namespace: openshift-ingress-operator
spec:
  domain: kafka-repl.dc-a.example.com
  routeSelector:
    matchLabels:
      ingress: replication
  nodePlacement:
    nodeSelector:
      matchLabels:
        node-role.kubernetes.io/repl-gateway: ""
  endpointPublishingStrategy:
    type: HostNetwork          # or LoadBalancer if MetalLB on repl VLAN
    hostNetwork:
      httpPort: 8080             # non-default ports if co-located with other HostNetwork routers
      httpsPort: 8443
  # tuningOptions:
  #   threadCount: 4             # size for bulk replication throughput
```

**Red Hat caveat:** if the cluster uses the platform keepalived ingress VIP (typical bare metal), validate guidance for non-default `IngressController` with `HostNetwork` against your OCP version — some docs recommend `NodePort` instead when keepalived ingress VIP is deployed.

**DNS:** broker route hostnames must resolve to addresses on the **replication path**, not the default `apps.*` ingress VIP.
Use a **separate** `spec.domain` per shard.

---

## CFK listener configuration (Route mode)

Use a **custom listener** with `externalAccess.type: route` — CFK manages Routes and advertised endpoints; no `$(REPL_IP)` init container.

```yaml
apiVersion: platform.confluent.io/v1beta1
kind: Kafka
metadata:
  name: kafka
  namespace: confluent
spec:
  listeners:
    internal:
      tls:
        enabled: true
    custom:
    - name: replication
      port: 9095
      tls:
        enabled: true
      externalAccess:
        type: route
        route:
          domain: kafka-repl.dc-a.example.com
          bootstrapPrefix: repl-kafka
          brokerPrefix: repl-b
          labels:
            ingress: replication
          annotations:
            haproxy.router.openshift.io/timeout: 3600s
            route.openshift.io/termination: passthrough
```

**Verify against installed CFK CRD reference:**

- Exact shape of `listeners.custom` vs `configOverrides.server` passthrough
- Whether `route.labels` maps to Route `metadata.labels` for `routeSelector` matching
- `oc get kafka kafka -o jsonpath='{.status.listeners.replication.advertisedExternalEndpoints}'` (field path may differ by CFK version)

**Cluster Link `bootstrap.servers`:** must use the **replication listener** route endpoints from CFK status — not internal Service DNS, not `apps.*` routes.

---

## External network requirements

Requirements split into **WAN/firewall**, **DNS**, and **frontend addressing**.

### Between datacenters (firewall / routing)

| Requirement | Ingress path (Path B) | Multus path (Path A) |
|---|---|---|
| Routed replication VLAN per DC | Yes | Yes |
| Scoped L3 routes (not default gateway on repl NIC) | Yes (host NNCP) | Yes (host + pod) |
| Firewall — ingress path | TCP **443** between repl subnets, **both directions** (bidirectional Cluster Linking) | TCP **9095** between broker pod IPs |
| MTU | End-to-end on VLAN 200 path | Same |
| ICMP | Optional; useful for troubleshooting | Same |

Host NNCP ([cross-dc-nncp-helm](cross-dc-nncp-helm/README.md)) is still required for router nodes — they need `bond-repl.200` addresses even when brokers skip Multus.

### DNS

| Requirement | Detail |
|---|---|
| **Zone per DC** | e.g. `kafka-repl.dc-a.example.com`, `kafka-repl.dc-b.example.com` |
| **Resolvable from remote DC** | DC-B brokers must resolve DC-A broker route hostnames to repl-path IPs |
| **Not `apps.*`** | Names must not resolve to machine-network ingress VIP |
| **Wildcard recommended** | `*.kafka-repl.dc-a.example.com` covers all CFK-created broker + bootstrap hostnames |
| **Split horizon OK** | Internal DNS only |

CFK creates concrete hostnames such as `repl-b1.kafka-repl.dc-a.example.com`.
A wildcard `*.kafka-repl.dc-a.example.com` avoids per-broker DNS tickets.

### TLS / certificates (passthrough)

| Layer | Certificate needed? |
|---|---|
| **Router (HAProxy)** | **No** — TLS passthrough; router routes by SNI hostname |
| **Kafka broker** | **Yes** — TLS terminates on broker; SANs must match route hostnames |
| **Wildcard at broker** | Optional — `*.kafka-repl.dc-a.example.com` is fine |
| **Cross-DC trust** | Both clusters must trust the remote broker CA (or shared CA) |

### Per-router-node FQDN?

**No.**
Remote brokers dial **broker route hostnames** (`repl-b1.kafka-repl.dc-a.example.com`), not router node names.
Router nodes are infrastructure; their repl VLAN IPs may appear in DNS **as A-record targets** behind a wildcard, but do not need individual FQDNs.

---

## Frontend options without an external hardware LB

Bare-metal OpenShift typically uses internal HAProxy (openshift-router) plus a platform **ingress VIP** on the **machine network**.
That VIP does **not** extend automatically to the replication VLAN.

### Option 1 — Single VIP per DC on replication subnet (recommended for production)

```text
10.200.1.5  ← VIP (keepalived/VRRP on repl-gateway nodes, or MetalLB pool on VLAN 200)
*.kafka-repl.dc-a.example.com → 10.200.1.5

Remote broker → repl-b1.kafka-repl.dc-a.example.com:443 → VIP → HAProxy → broker pod
```

| Pros | Cons |
|---|---|
| One firewall rule target per DC | VIP mechanism on repl VLAN is new work (keepalived or MetalLB) |
| Stable Cluster Link config | Platform `ingressVIP` does not cover this automatically |
| Simple DNS (one wildcard A) | |

**Hardware LB:** not required.
**MetalLB:** optional in-cluster VIP allocator.

### Option 2 — DNS load balancer to router node repl IPs (no VIP)

```text
*.kafka-repl.dc-a.example.com → A 10.200.1.11, A 10.200.1.12, A 10.200.1.13
                                 (repl NIC IPs of nodes running replication-router pods)
```

| Pros | Cons |
|---|---|
| No keepalived/MetalLB on repl VLAN | No single stable IP — firewall ACLs are a node list |
| Reuses HostNetwork HAProxy pattern | Stale A records if a node dies (unless DNS has health checks) |
| No F5 | Uneven load with dumb round-robin |
| | More moving parts as router replica count grows |

**Per node you need:** repl VLAN IP via NNCP, `repl-gateway` label, firewall allow from remote `/26` to that IP:443.
**Per node you do not need:** a dedicated FQDN for the router host.

**DNS sophistication matters:**

| DNS type | Failover |
|---|---|
| Static round-robin (basic internal DNS) | Dead node IP stays in rotation until manual change |
| Health-checked DNS (GSLB, Infoblox probes, etc.) | Removes unhealthy IPs — better for production |
| Low TTL (30–60s) | Faster recovery; more DNS load |

### Option 3 — MetalLB pool on replication VLAN

Same frontend shape as Option 1; VIP allocated by in-cluster MetalLB from `10.200.1.0/26` pool.
`IngressController` uses `endpointPublishingStrategy.type: LoadBalancer`.

Requires MetalLB speakers with L2 reachability on VLAN 200.

### Option 4 — Default ingress (PoC only)

```text
*.kafka-repl.dc-a.example.com → existing machine-network ingress VIP
```

Simplest; replication traffic stays on management network.
See [anti-pattern note in architecture overview](cross-dc-architecture-overview.md#anti-patterns).

---

## Security and access control

### Route creation — RBAC, not NetworkPolicy

`NetworkPolicy` governs **pod traffic**.
It does **not** control who can create `Route` objects.
That is **RBAC** on `routes/route.openshift.io`.

| Control | What it does |
|---|---|
| **`routeSelector` on IngressController** | Only labelled Routes are served by the replication shard |
| **Separate `spec.domain`** | Replication hostnames live outside `apps.*` — default ingress should not admit them |
| **Namespace RBAC** | Restrict `create routes` in `confluent` to CFK operator ServiceAccount |
| **Admission policy** (optional) | Gatekeeper / VAP: label `ingress: replication` only on CFK-owned Routes |
| **Exclude routes from default ingress** | See Red Hat "Sharding the default Ingress Controller" — verify default shard does not also admit replication routes |

### NetworkPolicy — what it still helps with

Restrict **direct** pod-to-broker access on port 9095 — only replication router pods should reach brokers, not arbitrary cluster workloads:

```yaml
# Illustrative — adjust selectors to match your router deployment labels
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kafka-replication-from-router-only
  namespace: confluent
spec:
  podSelector:
    matchLabels:
      app: kafka
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: openshift-ingress-replication
      ports:
        - protocol: TCP
          port: 9095
```

This does not stop Route creation; it limits who can bypass the router and hit brokers directly on OVN.

### Security comparison

| Risk | Default ingress (PoC) | Dedicated repl ingress | Multus direct |
|---|---|---|---|
| Replication on mgmt network | Yes | No (if DNS/VIP correct) | No |
| Shared proxy bottleneck | Default router pool | Dedicated router pool | None |
| Router compromise blast radius | All cluster ingress | Replication shard only | N/A |
| Firewall granularity | One VIP:443 | One VIP:443 (SNI) or node IP list | Per-broker IP:9095 |
| In-cluster policy on repl path | OVN NetworkPolicy only | OVN NetworkPolicy only | `MultiNetworkPolicy` on NAD |

---

## Trade-off summary

| Dimension | Multus (A) | Dedicated ingress (B) | Default ingress PoC (C) |
|---|---|---|---|
| **advertised.listeners complexity** | High (`REPL_IP` / static IP) | Low (CFK Routes) | Low |
| **Dedicated repl VLAN** | Full | Partial (to router frontend) | No |
| **Router hop** | None | Yes (every replication byte) | Yes |
| **External hardware LB** | No | No (VIP via keepalived/MetalLB/DNS LB) | No |
| **Firewall port** | 9095 | 443 | 443 |
| **Per-broker firewall ACLs** | Pod IPs | Shared VIP (SNI) or node IP pool | Shared mgmt VIP |
| **Platform moving parts** | Multus + MNP + whereabouts | 2nd IngressController + DNS + VIP/DNS LB | Existing ingress only |

---

## Decision tree

```text
Is dedicated replication VLAN required for production?
├─ No  → Path C (default ingress + CFK Routes) — PoC / low volume only
└─ Yes
    ├─ Is CFK Route ergonomics the priority over direct pod attachment?
    │   ├─ Yes → Path B (dedicated ingress shard)
    │   │         ├─ Can you run keepalived or MetalLB on repl VLAN? → Option 1 or 3 (VIP)
    │   │         └─ DNS LB only? → Option 2 (accept health-check / stale-DNS risk)
    │   └─ No  → Path A (Multus) — see architecture overview
    └─ Already invested in Multus tooling / per-broker ACLs? → Path A
```

---

## External dependencies handoff

Use this checklist when opening tickets with network and DNS teams for **Path B**.

### Network team (per DC)

- [ ] Replication `/26` routed between DCs (existing design)
- [ ] Firewall: TCP **443** between remote and local replication subnets, **both directions**
- [ ] Static repl IP per `repl-gateway` node on `bond-repl.200` (NNCP)
- [ ] **Option 1/3:** one VIP on repl `/26` for ingress frontend, or **Option 2:** document node IP pool for DNS LB
- [ ] MTU confirmed end-to-end on VLAN 200 path
- [ ] ICMP allowed for troubleshooting (optional)

### DNS team (per DC)

- [ ] Internal zone: `kafka-repl.dc-a.example.com` (adjust naming convention)
- [ ] Wildcard record:
  - **VIP model:** `*.kafka-repl.dc-a.example.com` → `10.200.1.5`
  - **DNS LB model:** `*.kafka-repl.dc-a.example.com` → `10.200.1.11`, `.12`, `.13` (repl IPs of router nodes)
- [ ] Conditional forwarder / cross-DC resolution so remote DC resolvers can query the zone
- [ ] TTL policy documented (especially for DNS LB without health checks)

### Platform team (per DC)

- [ ] NNCP on repl-gateway nodes ([cross-dc-nncp-helm](cross-dc-nncp-helm/README.md))
- [ ] `IngressController` `replication` shard (`domain`, `routeSelector`, `nodePlacement`)
- [ ] Frontend: VIP (keepalived/MetalLB) or DNS LB to node repl IPs
- [ ] CFK `listeners.custom` replication listener with `externalAccess.type: route`
- [ ] Verify `oc get route -o yaml` → `status.ingress` shows **replication** shard only (not default)
- [ ] Cluster Link `bootstrap.servers` uses replication route hostnames from CFK status
- [ ] Broker TLS / cross-DC trust configured

### Not required

- External hardware LB (F5)
- Per-router-node FQDN
- Wildcard certificate on the router (passthrough)
- Multus NAD / `MultiNetworkPolicy` on brokers (unless retaining Multus for other reasons)

---

## Verification checklist (ingress path)

**Automated (pre-Kafka):** [cross-dc-ingress-test](../../networking/cross-dc-ingress-test/README.md) — layers 1–6 (host → frontend → IngressController → route → local/cross-DC HTTP). Frontend examples: [ingress-replication/](examples/ingress-replication/README.md) (keepalived, MetalLB).

**Manual (post-CFK or in addition):**

1. `repl-gateway` nodes: `oc get nnce` Available; repl IP on `bond-repl.200` matches DNS targets.
2. From remote DC: `dig repl-b1.kafka-repl.dc-a.example.com` returns repl-path IP(s), not machine-network ingress VIP.
3. From remote DC: `openssl s_client -connect repl-b1.kafka-repl.dc-a.example.com:443 -servername repl-b1.kafka-repl.dc-a.example.com` reaches broker TLS cert with matching SAN.
4. `oc get route -n confluent -l ingress=replication` — routes admitted by replication shard (`status.ingress[].routerName` or canonical hostname).
5. Default ingress does **not** list replication-domain routes in `status.ingress` (or they are unreachable from WAN by design).
6. Cluster Link active; replication throughput acceptable under load (router not bottleneck).
7. Fail one replication-router node (DNS LB path): confirm failover behavior matches DNS TTL / health-check design.
8. Bidirectional links: symmetric firewall and DNS on both DCs.

---

## Open questions

- **IngressController API vs platform keepalived:** confirm `HostNetwork` for non-default shard on your OCP version when platform ingress VIP is deployed.
- **CFK `route.labels`:** verify label propagation to Route objects for `routeSelector` matching on your CFK version.
- **Router sizing:** `threadCount` and replica count for expected replication throughput — load test required.
- **DNS LB health checks:** does the org DNS platform support automatic removal of dead A records?
- **Default ingress exclusion:** explicit config needed so replication routes are not also served on `apps.*` if domains overlap.
- **Path choice:** document the decision in inventory / BRIEF — Multus vs ingress affects firewall tickets, DNS, and CFK listener shape.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

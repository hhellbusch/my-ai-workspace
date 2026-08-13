---
review:
  status: unreviewed
  notes: "Layered ingress verification framework — not yet run against live clusters."
---

# Cross-DC Ingress Test Framework (Path B)

**Audience:** Platform engineers validating the **dedicated IngressController** path before trusting CFK Routes and Cluster Linking on it.

**Purpose:** Layered, pre-cutover verification that isolates failures by stack depth — host network → frontend VIP/DNS-LB → OpenShift ingress → route admission → end-to-end HTTP through the replication shard. Uses a disposable echo Route/backend instead of Kafka so failures here are unambiguously **ingress/network** problems, not CFK config.

**Related:** [Cross-DC ingress alternative](../../messaging/kafka/cross-dc-ingress-alternative.md) · [Architecture overview — verification](../../messaging/kafka/cross-dc-architecture-overview.md#verification-checklist) · [Ingress examples](../../messaging/kafka/examples/ingress-replication/) · [Multus network test](../cross-dc-network-test/README.md) (Path A) · [Rollout inventory](../cross-dc-rollout/README.md)

---

## On this page

- [When to use this vs Multus network test](#when-to-use-this-vs-multus-network-test)
- [Layer model](#layer-model)
- [Prerequisites](#prerequisites)
- [Build order](#build-order)
- [Usage](#usage)
- [Layer isolation — how to read failures](#layer-isolation--how-to-read-failures)
- [What this does not prove](#what-this-does-not-prove)
- [Layout](#layout)

---

## When to use this vs Multus network test

| Path | Test framework |
|---|---|
| **A — Multus** (`replicationPath: multus`) | [cross-dc-network-test](../cross-dc-network-test/README.md) |
| **B — Dedicated ingress** (`replicationPath: ingress`) | **This framework** |

Run **both** shared Layer 1 (host NNCP) checks are duplicated here for isolation — you do not need to pass the Multus pod-attachment suite first, but host NNCP must be applied on `repl-gateway` nodes before ingress tests.

---

## Layer model

| Layer | What it proves | Typical failure owner |
|---|---|---|
| **0** | Workstation tools, env, kubeconfig, image pull | You |
| **1** | Host bond/VLAN/route on `repl-gateway` nodes (NNCP) | Platform / network |
| **2** | TCP to frontend target (`VIP` or `dns_lb` node IPs) on `:443` from **remote** DC repl-gateway | Network / firewall / VIP (keepalived/MetalLB) |
| **3** | `IngressController` Available, router deployment ready, domain matches | Platform / OpenShift |
| **4** | Test Route admitted by **replication** shard (`status.ingress.routerName`) | Platform (routeSelector labels) |
| **5** | Local curl via frontend IP → test hostname → echo backend | Frontend port map (443→8443), router, route TLS |
| **6** | Cross-DC curl (remote DC node → local frontend → local route) | WAN firewall, DNS (if used), symmetric config |

Layers are ordered: fix the **lowest** failing layer before debugging higher ones.

```text
Remote DC repl-gateway node
        │
        │  L2: TCP :443 ─────────────────────────────► Frontend VIP / dns_lb IP
        │                                              │
        │  L6: curl --resolve host:443:vip ─────────►│──► replication router (HostNetwork)
        │                                              │         │
        │                                              │         └──► OVN ──► echo pod
        │
Local DC: L1 host route ──► L3 IngressController ──► L4 route admission ──► L5 local curl
```

---

## Prerequisites

- Replication NNCP on `repl-gateway` nodes — [`cross-dc-nncp-helm`](../../messaging/kafka/cross-dc-nncp-helm/README.md)
- Dedicated `IngressController` applied — [`ingresscontroller.example.yaml`](../../messaging/kafka/examples/ingress-replication/ingresscontroller.example.yaml)
- Frontend on replication VLAN — **one of:**
  - [keepalived VIP example](../../messaging/kafka/examples/ingress-replication/keepalived-vip.example.conf)
  - [MetalLB examples](../../messaging/kafka/examples/ingress-replication/metallb-ipaddresspool.example.yaml)
  - DNS round-robin to router node repl IPs (`frontendMode: dns_lb` in inventory)
- VIP must forward **external port 443** to router **HostNetwork httpsPort** (default **8443** in the example IngressController) unless you bind router directly on 443
- `repl-net-probe` image built — reuse from [cross-dc-network-test](../cross-dc-network-test/repl-net-probe/README.md); set `TEST_PROBE_IMAGE` in env files
- `oc`, `jq`, `envsubst`; cluster-admin-ish access on both clusters

---

## Build order

1. Resolve design questions in [architecture overview](../../messaging/kafka/cross-dc-architecture-overview.md#open-questions-to-confirm-before-implementing).
2. Apply NNCP on both clusters; label `repl-gateway` nodes.
3. Apply `IngressController` replication shard on both clusters.
4. Deploy frontend (keepalived, MetalLB, or DNS LB) — see [ingress-replication examples](../../messaging/kafka/examples/ingress-replication/README.md).
5. Coordinate firewall — TCP **443** between DC subnets to frontend targets ([ingress firewall template](../cross-dc-rollout/templates/firewall-change-request-ingress.md.example)).
6. Render env files from ingress inventory:

```bash
cd ../cross-dc-rollout
cp inventory-dc-a.ingress.example.yaml inventory-dc-a.yaml
cp inventory-dc-b.ingress.example.yaml inventory-dc-b.yaml
# edit both
python3 render-config.py --both
```

7. Pre-flight:

```bash
cd ../cross-dc-ingress-test
./preflight-ingress.sh dc-a.env dc-b.env
```

8. Run layered tests:

```bash
./run-ingress-test.sh dc-a.env dc-b.env
```

---

## Usage

```bash
./preflight-ingress.sh dc-a.env dc-b.env
./run-ingress-test.sh dc-a.env dc-b.env
./run-ingress-test.sh dc-a.env dc-b.env --cleanup
```

Gate example:

```bash
./preflight-ingress.sh dc-a.env dc-b.env && ./run-ingress-test.sh dc-a.env dc-b.env
```

`dc-*.env` are gitignored — copy from `dc-*.env.example` or render from inventory.

---

## Layer isolation — how to read failures

| If this fails… | And this passes… | Likely cause |
|---|---|---|
| L1 | — | NNCP wrong node list, missing scoped route, or default route on repl VLAN |
| L2 | L1 | VIP not on VLAN, keepalived/MetalLB down, firewall blocks :443, wrong `FRONTEND_TARGETS` |
| L3 | L1–L2 | IngressController not applied, router pods not on `repl-gateway`, domain typo |
| L4 | L3 | Route missing `ingress: replication` label; shard `routeSelector` mismatch |
| L5 | L4 | VIP forwards to wrong host port (443 vs 8443), echo backend not ready, TLS/route misconfig |
| L6 | L5 (local) | Remote→local firewall, asymmetric VIP/DNS, or WAN path MTU (rare for HTTPS) |

Manual checks the scripts do **not** automate (add before CFK cutover):

- `dig repl-b1.<ingress-domain>` from remote DC returns repl-path IP, not machine-network VIP
- `openssl s_client` to a **passthrough** CFK broker route hostname (after CFK deploy)
- Default ingress does not admit replication-domain routes on WAN

---

## What this does not prove

- CFK `advertised.listeners` / Cluster Link bootstrap correctness
- TLS passthrough to broker `:9095` (test Route uses **edge** TLS for simplicity)
- Router throughput under replication load
- DNS TTL failover behavior (`dns_lb` mode)

After this framework passes, proceed to CFK Route listener verification in [cross-dc-ingress-alternative.md](../../messaging/kafka/cross-dc-ingress-alternative.md#verification-checklist-ingress-path).

---

## Layout

```text
cross-dc-ingress-test/
├── README.md
├── preflight-ingress.sh       — Layer 0–1 + IngressController read-only checks
├── run-ingress-test.sh        — Layers 1–6 with echo Route
├── dc-a.env.example
├── dc-b.env.example
└── manifests/
    ├── namespace.example.yaml
    ├── echo-backend.example.yaml
    ├── echo-service.example.yaml
    └── echo-route.example.yaml
```

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

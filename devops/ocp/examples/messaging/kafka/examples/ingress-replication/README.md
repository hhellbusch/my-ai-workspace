---
review:
  status: unreviewed
  notes: "Generic examples for dedicated IngressController on replication VLAN — not a Helm chart. Verify against installed OCP version."
---

# Ingress Replication — Example Manifests

**Audience:** Platform engineers implementing the **dedicated ingress shard** path for cross-DC Kafka replication.

**Purpose:** Generic, copy-and-adapt examples for `IngressController` sharding on the replication VLAN — complement to [cross-dc-ingress-alternative.md](../../cross-dc-ingress-alternative.md).

**Prerequisites:** Host NNCP on `repl-gateway` nodes ([cross-dc-nncp-helm](../../cross-dc-nncp-helm/README.md)); DNS and firewall tickets from [cross-dc-rollout templates](../../../../networking/cross-dc-rollout/templates/).

---

## Files

| File | Purpose |
|---|---|
| [ingresscontroller.example.yaml](ingresscontroller.example.yaml) | Dedicated shard: domain, `routeSelector`, node placement |
| [networkpolicy-router-to-broker.example.yaml](networkpolicy-router-to-broker.example.yaml) | Optional OVN policy: only router pods → broker :9095 |
| [keepalived-vip.example.conf](keepalived-vip.example.conf) | Host-level VRRP VIP on `bond-repl.<vlan>` (DIY — not platform ingress VIP) |
| [metallb-ipaddresspool.example.yaml](metallb-ipaddresspool.example.yaml) | MetalLB pool on replication `/26` |
| [metallb-l2advertisement.example.yaml](metallb-l2advertisement.example.yaml) | L2 adv on `repl-gateway` nodes + VLAN iface |
| [metallb-router-service.example.yaml](metallb-router-service.example.yaml) | Optional `LoadBalancer` Service → router pods (`443`→`8443`) |

## Frontend patterns

**Mutually exclusive — choose one pattern per cluster (per DC).** keepalived and MetalLB both implement **Option 1** (single VIP on the replication VLAN); do not deploy both. The platform install-time **ingress VIP** on the machine network is separate — it does not replace a repl-VLAN frontend.

| Pattern | Option | When | Verify with |
|---|---|---|---|
| **keepalived (1a)** | Single VIP | Small static VIP, full control on repl-gateway nodes | [cross-dc-ingress-test](../../../../networking/cross-dc-ingress-test/README.md) Layer 2 |
| **MetalLB L2 (1b)** | Single VIP | Pool on repl VLAN, operator already in cluster | Same + `oc get svc -n openshift-ingress-replication` external IP |
| **DNS LB (2)** | No VIP | A records to each router node repl IP | Layer 2 with `frontendMode: dns_lb` in inventory |

External clients (and cross-DC tests) usually hit **:443** on the frontend. The example IngressController uses HostNetwork **httpsPort 8443** — map VIP/LB `443` → node `8443` unless you change router ports.

## CFK integration

- Listener snippet: [cfk-kafka-route-replication.snippet.yaml](../cfk-kafka-route-replication.snippet.yaml)
- Route labels must match `spec.routeSelector` on the IngressController

## Verification

Layered pre-Kafka checks: [cross-dc-ingress-test](../../../../networking/cross-dc-ingress-test/README.md). After CFK deploy, manual passthrough checks in [cross-dc-ingress-alternative.md](../../cross-dc-ingress-alternative.md#verification-checklist-ingress-path).

## Not included here

- Default ingress exclusion / shard uniqueness — validate `oc get route -o yaml` → `status.ingress` after apply
- Site-specific DNAT/firewall rules between VIP and router host ports

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

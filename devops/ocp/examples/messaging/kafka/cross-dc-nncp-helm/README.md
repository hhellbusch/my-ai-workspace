---
review:
  status: unreviewed
  notes: "Helm chart drafted from the cross-DC replication design discussion; not yet applied to a real cluster. Rendered and linted with `helm template`/`helm lint` only — not deployed against nmstate."
---

# Cross-DC Replication NNCP — Helm Template

**Audience:** Whoever implements the host-network layer of [Cross-DC Kafka Replication Architecture — Complete Picture](../cross-dc-architecture-overview.md).

**Purpose:** Render one [`NodeNetworkConfigurationPolicy`](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/kubernetes_nmstate/k8s-nmstate-updating-node-network-config) (NNCP) per node, each with a unique static IP on the replication VLAN, from a single node list in Helm values — instead of hand-authoring N nearly-identical YAML files.

**Related:** [Cross-DC architecture overview](../cross-dc-architecture-overview.md#layer-12-host-network) · [Cross-DC replication network](../../../networking/cross-dc-replication.md#layer-12-host-network) · [Cross-DC rollout inventory](../../../networking/cross-dc-rollout/README.md) · [Kubernetes NMState upstream docs](https://nmstate.github.io/kubernetes-nmstate/user-guide/102-configuration.html)

---

## Why this exists

NMState applies identical `desiredState` to every node an NNCP's `nodeSelector` matches — there's no native per-node templating for values like IP addresses. Multiple sources confirm the only NNCP-native way to get unique static IPs is one policy per node, selected by `kubernetes.io/hostname`:

- [K8s Recipes: NNCP static IP assignment](https://kubernetes.recipes/recipes/networking/nncp-static-ip-workers/) — *"A single NNCP applies identical config to all matching nodes. For per-node IPs, use separate NNCPs with specific `nodeSelector` labels."*
- [Community example: per-node NNCP by hostname](https://myopenshiftblog.com/additional-ocp-networks/)

This chart automates that pattern from a values file rather than copy-pasting N CRs by hand.

## NNCP scope — replication bond only (not the full node picture)

The rendered NNCPs define **only** the cross-DC replication stack: `bond-repl` → `bond-repl.<vlan>` → scoped route to the remote `/26`. They do **not** describe the cluster's **management / machine network** (API, OVN, ingress VIP, default route).

On bare-metal OpenShift that management network is usually created at **install time** — `install-config.yaml`, Ignition/MachineConfig, or site networking applied before nmstate is in play. Those interfaces and bonds **may not appear in any NNCP** in this repo. That is expected: Kubernetes NMState manages what you declare in each policy; it does not replace or re-document the entire node network layout in one CR.

**Implication for reviewers:** reading `oc get nncp` or the Helm template is **not** enough to understand a node. You can have:

- A management bond (e.g. `bond0` / `br-ex`) from install — **not** in these examples
- A separate `bond-repl` from this chart — **only** what the NNCP owns

Before filling `nodes[].hostname` and `replicationNetwork.ports`, confirm on the **node** (or from cluster state) which NICs are free vs already consumed by management/storage:

```bash
oc get nns <node> -o yaml          # NodeNetworkState — full effective host config nmstate sees
oc debug node/<node> -- chroot /host nmcli -g GENERAL.CONNECTION,IP4.ADDRESS device show
oc debug node/<node> -- chroot /host ip -d link show
```

`oc get nnce` / `NodeNetworkConfigurationEnactment` shows whether **this** policy applied; `NodeNetworkState` shows the **merged** result alongside install-time config. If `bond-repl` ports overlap NICs already in the management bond, nmstate may fail the enactment or produce an unintended layout — catch that in preflight, not from the YAML alone.

**Related:** [cross-dc-replication.md — Layer 1–2](../../../networking/cross-dc-replication.md#layer-12-host-network) · [architecture overview — shared foundation](../cross-dc-architecture-overview.md#layer-12-bond-and-vlan)

**Before reaching for this:** confirm you actually need a static, per-node host IP at all. The [architecture overview's Layer 1–2 discussion](../cross-dc-architecture-overview.md#layer-12-host-network) found that the host interface doesn't need an IP for the Kafka/macvlan pod traffic path — macvlan children get their own IP independent of the host's — confirmed against a [multus-cni issue thread](https://github.com/k8snetworkplumbingwg/multus-cni/issues/1104) showing a macvlan master interface working with no `ipam` at all. DHCP or no address is simpler and scales with node churn automatically; this chart is for when you've deliberately decided you want static, predictable per-node host addresses anyway (e.g., firewall allow-listing by host IP, inventory/monitoring conventions).

## Quick start

```bash
# Render only, to review before applying
helm template repl-net . -f values-dc-a.example.yaml

# Apply directly (NNCP is cluster-scoped — no namespace needed)
helm template repl-net . -f values-dc-a.example.yaml | oc apply -f -
```

Deploy **one release per cluster/DC** — `values-dc-a.example.yaml` for DC-A's cluster, `values-dc-b.example.yaml` for DC-B's. Each cluster only renders NNCPs for its own nodes, routing toward the *other* DC's subnet.

## Values

Prefer filling [inventory YAML](../../../networking/cross-dc-rollout/README.md) and running `render-config.py --both` to generate `values-dc-a.yaml` / `values-dc-b.yaml` — avoids duplicating subnets and node hostnames across charts.

| Field | Meaning |
|---|---|
| `replicationNetwork.bondName`, `.bondMode`, `.ports` | Shared bond config — identical across every node in this DC |
| `replicationNetwork.vlanId`, `.prefixLength` | VLAN tag and subnet mask, shared |
| `replicationNetwork.localGateway` | This DC's replication subnet gateway (the route's next-hop) |
| `replicationNetwork.remoteSubnet` | The *other* DC's `/26` — what the route on this interface targets, not `0.0.0.0/0` |
| `replicationNetwork.mtu` | Optional — sets bond + VLAN MTU on every node (from inventory `expectedMtu` when rendered). [Parent-first constraint](../../../networking/cross-dc-replication.md#mtu--parent-first-and-path-constraints). |
| `nodes[].hostname` | Must exactly match `kubernetes.io/hostname` — confirm with `oc get nodes -o wide` |
| `nodes[].ip` | The one thing that actually varies per node |

See `values.yaml` for the full schema with comments; `values-dc-a.example.yaml` / `values-dc-b.example.yaml` for filled-in examples matching the subnets used throughout the architecture overview (`10.200.1.0/26` / `10.200.2.0/26`).

## Verification

1. `helm template ... | oc apply -f -` then `oc get nnce` (`NodeNetworkConfigurationEnactment`) — one enactment per node, confirms each **replication** policy applied.
2. `oc get nns <node>` (`NodeNetworkState`) — **full** host networking nmstate reports (replication NNCP **plus** install-time management bonds, routes, and addresses). Use this when the NNCP YAML alone does not show the management/default network you expect.
3. Full verification checklist: [architecture overview](../cross-dc-architecture-overview.md#verification-checklist).

## Rollout safety — an open question, not solved here

The single-NNCP-with-`maxUnavailable`-per-CR pattern normally staggers rollout across a fleet within *one* CR. That doesn't apply here — each rendered NNCP already matches exactly one node, so `maxUnavailable` on it is a no-op (left in the values schema as a placeholder in case you consolidate back to shared NNCPs later).

The actual risk: `helm template | oc apply` submits every node's NNCP at once. Since nmstate has no cross-policy concurrency control, all matched nodes could start applying network changes simultaneously — the exact fleet-wide-outage scenario `maxUnavailable` exists to prevent in the shared-NNCP pattern. If that risk matters for your rollout (first time applying this, or changing an existing bond), consider splitting `nodes` into a few batches across separate `values-*.yaml` files and applying them sequentially, confirming `oc get nnce` is healthy between batches, rather than one release covering the whole node list at once.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
review:
  status: unreviewed
  notes: "MultiNetworkPolicy primer for cross-DC Kafka replication — default deny, mis-attachment defense, verification."
---

# MultiNetworkPolicy on the replication NAD

**Audience:** Platform engineers new to Kubernetes network policy (or familiar with standard `NetworkPolicy` on the default pod network) who need to understand how traffic is restricted on the Kafka replication VLAN in this design.

**Purpose:** Explain how `MultiNetworkPolicy` works on a Multus secondary interface, why this chart renders **two** policies, what mis-attachment defense buys you, and how to verify enforcement before trusting Cluster Linking on the dedicated path.

**Related:** [Helm chart README](README.md) · [Cross-DC architecture overview](../cross-dc-architecture-overview.md#securing-the-secondary-network-multinetworkpolicy) · [Network test framework](../../../networking/cross-dc-network-test/README.md) (test 6) · [OpenShift: MultiNetworkPolicy API reference](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/network_apis/multinetworkpolicy-k8s-cni-cncf-io-v1beta1)

---

## On this page

- [Two interfaces, two policy systems](#two-interfaces-two-policy-systems)
- [Standard NetworkPolicy recap](#standard-networkpolicy-recap)
- [What MultiNetworkPolicy adds](#what-multinetworkpolicy-adds)
- [Enable enforcement on the cluster](#enable-enforcement-on-the-cluster)
- [Opt the NAD in with policy-for](#opt-the-nad-in-with-policy-for)
- [Default allow vs default deny](#default-allow-vs-default-deny)
- [This chart: two policies on one NAD](#this-chart-two-policies-on-one-nad)
- [Mis-attachment and fail-open behavior](#mis-attachment-and-fail-open-behavior)
- [What brokers are allowed to do](#what-brokers-are-allowed-to-do)
- [What MultiNetworkPolicy does not cover](#what-multinetworkpolicy-does-not-cover)
- [Verify enforcement](#verify-enforcement)
- [Optional hardening beyond policy](#optional-hardening-beyond-policy)
- [Troubleshooting](#troubleshooting)

---

## Two interfaces, two policy systems

A Kafka broker in this design is **dual-homed**:

```text
┌─ broker pod ──────────────────────────────────────────────┐
│  eth0 (OVN)     default cluster overlay — clients, DNS, API │
│  net1 (Multus)  replication VLAN — Cluster Link replication │
└─────────────────────────────────────────────────────────────┘
```

| Interface | Policy mechanism | Governs |
|---|---|---|
| `eth0` | Kubernetes **`NetworkPolicy`** (OVN-Kubernetes) | In-cluster overlay traffic |
| `net1` | **`MultiNetworkPolicy`** | Traffic on the Multus-attached replication NAD only |

Standard `NetworkPolicy` **does not see** `net1`.
Without `MultiNetworkPolicy`, any pod attached to the replication NAD can talk freely on that interface — you rely on VLAN isolation and WAN firewalls alone.

For Multus, SNAT, and scoped routes on these interfaces, see [Networking basics](../cross-dc-architecture-overview.md#networking-basics-terms-used-in-this-doc) in the architecture overview.

---

## Standard NetworkPolicy recap

Kubernetes network policy is **allow-list** semantics for pods it selects:

1. If **no** `NetworkPolicy` selects a pod → **all traffic allowed** (for that policy type / network).
2. If **any** policy selects a pod → **default deny** for the listed `policyTypes` (e.g. `Ingress`, `Egress`).
3. Only traffic matching an explicit `ingress` / `egress` rule is permitted.

Policies are **additive**: if multiple policies select the same pod, the **union** of all allow rules applies.

`MultiNetworkPolicy` follows the same mental model, but applies to a **named secondary network** (your NAD), not to `eth0`.

---

## What MultiNetworkPolicy adds

`MultiNetworkPolicy` is a separate CRD (`k8s.cni.cncf.io/v1beta1`, resource name `multi-networkpolicy`).

Each policy object:

- Lives in the **workload namespace** (e.g. `confluent`)
- Names the target NAD via annotation **`k8s.v1.cni.cncf.io/policy-for: <namespace>/<nad-name>`**
- Selects pods with **`podSelector`**
- Allows or denies **only traffic on that secondary interface**

This design uses a **macvlan** NAD (`kafka-repl-net`).
For macvlan/IPVLAN/SR-IOV, `podSelector` and `ipBlock` peers work as you'd expect.

The OpenShift caveat about needing a `subnets` field for `podSelector` applies to **OVN-Kubernetes secondary networks**, not this macvlan NAD — see the architecture overview for detail.

---

## Enable enforcement on the cluster

`MultiNetworkPolicy` is **off by default** until the cluster Network CR opts in:

```yaml
apiVersion: operator.openshift.io/v1
kind: Network
metadata:
  name: cluster
spec:
  useMultiNetworkPolicy: true
```

Apply once per cluster — [cluster-network-operator-patch.example.yaml](../../../networking/cross-dc-rollout/examples/cluster-network-operator-patch.example.yaml).

Verify:

```bash
oc get network cluster -o jsonpath='{.spec.useMultiNetworkPolicy}{"\n"}'
# must print: true
```

Without this, policy objects exist in etcd but **do not enforce** — a silent fail-open.

The [network test preflight](../../../networking/cross-dc-network-test/preflight.sh) checks this before test 6 runs.

---

## Opt the NAD in with policy-for

Both the **NAD** and every **MultiNetworkPolicy** on that network must carry the same annotation:

```yaml
k8s.v1.cni.cncf.io/policy-for: confluent/kafka-repl-net
```

The Helm chart sets this on:

- `NetworkAttachmentDefinition` `kafka-repl-net` ([templates/nad.yaml](templates/nad.yaml))
- Each `MultiNetworkPolicy` rendered for that NAD

If `policy-for` is missing or mismatched on **either** side, enforcement tends to **fail open silently** — the policy appears applied but traffic is unrestricted on `net1`.

---

## Default allow vs default deny

This distinction drives mis-attachment defense.

| Situation | On `net1` |
|---|---|
| Pod attached to NAD, **no** policy selects it | **Allow all** (default allow) |
| Pod selected by policy with `policyTypes: [Ingress, Egress]` and **no** allow rules | **Deny all** (for those directions) |
| Pod selected by policy with explicit allow rules | Only listed traffic permitted (+ union of other selecting policies) |

**Important:** the existing broker-only policy (`kafka-repl-net-restrict`) selects pods with `app: kafka`.
It makes those brokers **default deny except** cross-DC replication TCP.

It does **nothing** for a pod on the same NAD **without** matching labels — that pod stays **default allow** unless another policy selects it.

---

## This chart: two policies on one NAD

When `multiNetworkPolicy.defaultDenyOnNad: true` (default in this chart), Helm renders **two** policies on `kafka-repl-net`:

| Resource | `podSelector` | Rules | Role |
|---|---|---|---|
| `kafka-repl-net-default-deny` | `{}` (all pods in namespace) | `Ingress` + `Egress`, **no allows** | Deny everything on `net1` for any attached pod |
| `kafka-repl-net-restrict` | `app: kafka` (configurable) | Allow TCP `9095` ↔ remote DC `/26` | Exception for broker replication |

How they combine for a **labeled broker**:

1. Broker matches **both** policies.
2. Default-deny policy allows nothing.
3. Restrict policy adds the replication allow rules.
4. **Union** → broker may use replication traffic only.

How they combine for a **mis-attached** pod (has `kafka-repl-net`, wrong labels):

1. Matches **only** default-deny (`{}`).
2. No allow rules apply.
3. **All** `net1` traffic blocked.

Disable the catch-all for break-glass debugging only:

```yaml
multiNetworkPolicy:
  defaultDenyOnNad: false
```

Set in [inventory](../../../networking/cross-dc-rollout/inventory-dc-a.example.yaml) under `workload.multiNetworkPolicy` or directly in Helm values.

---

## Mis-attachment and fail-open behavior

**Mis-attachment** here means a pod gets the Multus annotation for `kafka-repl-net` without being an authorized broker — copy-paste error, debug pod, wrong Helm chart, etc.

Without catch-all deny:

```text
Pod → kafka-repl-net annotation → replication-subnet IP on net1
  → not selected by kafka-repl-net-restrict
  → default ALLOW on net1
  → can reach :9095 on peers, scan the VLAN, bypass intent of "brokers only"
```

With catch-all deny (default in this chart):

```text
Same mis-attached pod → selected by kafka-repl-net-default-deny only
  → no allow rules → denied on net1
  → replication path contained even though the pod still consumed an IP
```

Catch-all deny **does not** prevent attachment or IP allocation — it limits what the pod can **do** on `net1`.
Combine with namespace discipline (Kafka-only in `confluent`), RBAC, and optional admission control for defense in depth — see [Optional hardening](#optional-hardening-beyond-policy).

**Label collision:** if a mis-attached pod also carries `app: kafka`, it inherits the **allow** policy.
Use a specific selector matching real CFK broker labels; confirm with `oc get pod -n confluent --show-labels` before cutover.

---

## What brokers are allowed to do

On `net1`, brokers matching `workload.podSelector` may:

| Direction | Peer | Protocol | Port |
|---|---|---|---|
| Ingress | Remote DC replication `/26` (`replicationNetwork.remoteSubnet`) | TCP | `workload.replicationPort` (9095) |
| Egress | Remote DC replication `/26` | TCP | 9095 |

Everything else on `net1` is denied — including:

- Same-local-subnet peers on the replication VLAN (other local IPs in your `/26`)
- Remote ports other than 9095
- ICMP on `net1` (not in policy — blocked when default deny applies)

**Bidirectional Cluster Linking** (this design's default) needs symmetric ingress and egress — both are present.

For **one-directional** links only, you might tighten one direction per DC; confirm link direction before narrowing rules — see [Connection direction](../cross-dc-architecture-overview.md#connection-direction).

**ICMP / PMTUD:** WAN firewalls often allow ICMP for MTU discovery; this policy does not.
If path MTU issues appear on the replication interface, evaluate ICMP rules separately or fix MTU on the WAN path.

---

## What MultiNetworkPolicy does not cover

| Concern | Where it belongs |
|---|---|
| WAN / datacenter firewall ACLs | Network team — [firewall change template](../../../networking/cross-dc-rollout/templates/firewall-change-request.md.example) |
| Traffic on `eth0` (internal Kafka clients, API) | Standard `NetworkPolicy` in `confluent` (separate design) |
| Pods without `kafka-repl-net` attachment | Not on replication NAD — out of scope for these policies |
| TLS/SASL on replication listener | CFK listener config — still TCP 9095 from policy view |
| Cluster Link `bootstrap.servers` correctness | API / GitOps — see [BROKER-IPAM.md](BROKER-IPAM.md) |
| Preventing wrong Multus annotation at admission | Optional ValidatingAdmissionPolicy / OPA — not in this chart |

---

## Verify enforcement

### 1. Objects present

```bash
oc get network-attachment-definition kafka-repl-net -n confluent \
  -o jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/policy-for}{"\n"}'

oc get multi-networkpolicy -n confluent
# expect: kafka-repl-net-default-deny, kafka-repl-net-restrict (when defaultDenyOnNad true)
```

### 2. Network test (before Kafka)

Run [cross-dc-network-test](../../../networking/cross-dc-network-test/README.md) — **test 6** proves `ipBlock` enforcement on the **test** NAD using local vs remote peers.
Same semantics; different namespace and pool.

### 3. Mis-attachment probe (after Kafka NAD applied)

Deploy a short-lived pod **with** `kafka-repl-net` and **without** broker labels — it should **not** reach a broker replication IP on `:9095` on `net1`.

Example shape (adjust image and IPs):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: repl-net-misattach-probe
  namespace: confluent
  labels:
    app: misattach-probe   # intentionally NOT app: kafka
  annotations:
    k8s.v1.cni.cncf.io/networks: kafka-repl-net
spec:
  containers:
    - name: probe
      image: registry.access.redhat.com/ubi9/ubi-minimal
      command: ["sleep", "3600"]
  restartPolicy: Never
```

From the probe (once it has a replication-subnet IP on `net1`):

```bash
# Should FAIL / time out when default-deny is enforcing
nc -zv -w 5 <broker-repl-ip> 9095
```

From a labeled broker pod or from the remote DC (Cluster Link path), `:9095` should still succeed when the link and listeners are wired.

Delete the probe when done.

### 4. Broker labels

```bash
oc get pods -n confluent -l app=kafka --show-labels
```

If CFK uses different labels, update `workload.podSelector` in inventory and re-render — otherwise brokers match only default-deny and **lose** replication connectivity.

---

## Optional hardening beyond policy

| Control | Benefit |
|---|---|
| **Dedicated namespace** — Kafka only in `confluent` | Reduces who can attach to `kafka-repl-net` |
| **RBAC** — limit pod create/patch and NAD use | Fewer accidental annotations |
| **ValidatingAdmissionPolicy** — reject `networks: kafka-repl-net` unless allowed SA/labels | Blocks mis-attachment before schedule |
| **GitOps-only CFK** — no ad-hoc debug pods in prod namespace | Operational discipline |
| **Periodic audit** — list pods with `kafka-repl-net` in annotations | Detect drift |

Catch-all `MultiNetworkPolicy` is the in-cluster safety net; admission is the preventative layer.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| All `net1` traffic works despite policies | `useMultiNetworkPolicy` not `true`, or missing/wrong `policy-for` |
| Brokers can't replicate | `podSelector` doesn't match broker labels; or default-deny on but restrict policy missing |
| Mis-attached pod still reaches `:9095` | `defaultDenyOnNad: false`; or pod not actually on `kafka-repl-net` |
| Policy objects exist, no effect | Cluster policy controller not running; check OpenShift network operator logs |
| Test 6 skipped / inconclusive | Preflight failed `useMultiNetworkPolicy` — fix cluster config first |

**CLI note:** resource name is `multi-networkpolicy` (singular, hyphenated):

```bash
oc get multi-networkpolicy -n confluent
oc describe multi-networkpolicy kafka-repl-net-restrict -n confluent
```

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

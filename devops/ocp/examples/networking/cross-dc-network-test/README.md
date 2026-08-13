---
review:
  status: unreviewed
  notes: "Test framework drafted from the cross-DC replication design discussion; not yet run against real clusters."
---

# Cross-DC Network Test Framework (Isolated from Kafka)

**Audience:** Whoever validates the host network (NNCP) + Multus pod attachment (NAD/whereabouts) + `MultiNetworkPolicy` layers before trusting Kafka (or any other workload) to run on them.

**Purpose:** A one-time/occasional pre-cutover runbook that proves the [cross-DC replication network](../cross-dc-replication.md) works end-to-end across the real DC-A/DC-B clusters, using purpose-built [repl-net-probe](repl-net-probe/README.md) test pods instead of Kafka — so any failure found here is unambiguously a network-layer problem, not a Kafka/CFK config problem.

**Related:** [Cross-DC replication network](../cross-dc-replication.md) · [Cross-DC architecture overview](../../messaging/kafka/cross-dc-architecture-overview.md#verification-checklist) · [Cross-DC rollout inventory](../cross-dc-rollout/README.md) · [Cross-DC replication NNCP (Helm)](../../messaging/kafka/cross-dc-nncp-helm/README.md) · [repl-net-probe image](repl-net-probe/README.md)

---

## On this page

- [Scope](#scope)
- [Why a script + probe pods, not a declarative multi-cluster framework](#why-a-script--probe-pods-not-a-declarative-multi-cluster-framework)
- [Prerequisites](#prerequisites)
- [Pre-flight](#pre-flight)
- [Usage](#usage)
- [Templating: Helm vs envsubst](#templating-helm-vs-envsubst)
- [What each test checks](#what-each-test-checks)
- [Why test 6 uses a local peer](#why-test-6-uses-a-local-peer)
- [Cleanup](#cleanup)
- [Layout](#layout)

---

## Scope

Tests, using disposable resources only (no CFK/Kafka anywhere):

1. Host layer — NNCP/NNCE health, correct bond/VLAN/route on target nodes
2. Pod attachment — a test pod's `k8s.v1.cni.cncf.io/network-status` shows the second interface with the expected IP, and no unintended `default-route`
3. Cross-DC reachability — an actual TCP handshake between a pod in DC-A and a pod in DC-B, over the replication VLAN specifically
4. MTU — real path MTU across the full route, compared against the configured value
5. `MultiNetworkPolicy` enforcement — the policy blocks a local-subnet peer, allows the legitimate remote-DC one
6. Bond failover (optional, manual/opt-in only — induces a real fault on a live node)

This is the same checklist already in the [architecture overview](../../messaging/kafka/cross-dc-architecture-overview.md#verification-checklist) and [`cross-dc-replication.md`](../cross-dc-replication.md#verification-checklist) — this framework automates that checklist rather than inventing a new one, so the design docs and the test suite can't drift apart.

**Explicitly out of scope:** anything CFK/Kafka-specific (listener config, Cluster Linking, broker `StatefulSet` identity). The test `NetworkAttachmentDefinition` uses a separate `whereabouts` range from Kafka's own pool — same VLAN/subnet/master interface, different IPs — so this can be run and re-run independently of whatever state Kafka is in, including before Kafka is deployed at all. What a passing test proves vs broker `REPL_IP` / Cluster Link wiring: [BROKER-IPAM.md — what the network test proves](../../messaging/kafka/cross-dc-kafka-net-helm/BROKER-IPAM.md#what-the-network-test-proves).

---

## Why a script + probe pods, not a declarative multi-cluster framework

Considered [Kyverno Chainsaw](https://kyverno.github.io/chainsaw/main/), which has genuine native multi-cluster support — the architecturally "correct" tool for a two-cluster test in a vacuum. Not used here because the stated need is a one-time/occasional pre-cutover runbook, not an ongoing CI suite — introducing a new binary and declarative test DSL for something run rarely is disproportionate (YAGNI). A shell script driving plain manifests fits how the rest of this workspace's verification checklists already work.

Test pods use [repl-net-probe](repl-net-probe/README.md), a minimal UBI9 image built for this runbook — not upstream `netshoot`, which is Alpine-based, not published on Quay, and carries a large third-party CVE surface unrelated to what these checks actually exercise.

---

## Prerequisites

- **`repl-net-probe` image built and pushed** — see [repl-net-probe/README.md](repl-net-probe/README.md). Set `TEST_PROBE_IMAGE` in both `dc-a.env` and `dc-b.env` to the digest/tag your clusters can pull.
- `oc` CLI logged in with cluster-admin-ish access on **both** clusters (needed for `oc debug node`), and a kubeconfig file per cluster
- `envsubst` (part of `gettext` — `dnf install gettext` / `apt install gettext-base`)
- `jq`
- The replication NNCP/bond/VLAN already applied on both clusters — see [`cross-dc-nncp-helm`](../../messaging/kafka/cross-dc-nncp-helm/README.md) or the manual example in [`cross-dc-replication.md`](../cross-dc-replication.md#layer-12-host-network). This framework tests that layer; it doesn't create it.
- **SCC/Pod Security:** the test pods request the `NET_RAW` capability (needed for `ping -M do` in test 5). `manifests/namespace.example.yaml` sets `pod-security.kubernetes.io/enforce: privileged` on the test namespace to allow this without touching cluster-wide SCC policy. If your cluster enforces Pod Security admission more strictly at the cluster level, you may instead need `oc adm policy add-scc-to-user` for the namespace's default service account — confirm with `oc get pods -n cross-dc-net-test` after running the script; a pod stuck in `Blocked`/`CreateContainerConfigError` state usually means this.

---

## Pre-flight

Run this **after** the replication NNCP/bond/VLAN is applied on both clusters and **before** `./run-network-test.sh` applies test pods. The [architecture overview](../../messaging/kafka/cross-dc-architecture-overview.md#pre-flight-before-network-verification) carries a condensed version of this checklist for peer review; this section is the operational detail.

### Build order

1. Resolve the [open design questions](../../messaging/kafka/cross-dc-architecture-overview.md#open-questions-to-confirm-before-implementing) — real subnets, VLAN interface names, node hostnames, MTU, which nodes carry the bond.
2. Apply host network on both clusters — [`cross-dc-nncp-helm`](../../messaging/kafka/cross-dc-nncp-helm/README.md) or manual NNCP; confirm `oc get nnce` is `Available`.
3. Build/push [`repl-net-probe`](repl-net-probe/README.md); set `TEST_PROBE_IMAGE` in both `dc-*.env` files.
4. Copy env templates and fill in real values — **or** render from [cross-dc-rollout inventory](../cross-dc-rollout/README.md):

```bash
cd ../cross-dc-rollout
cp inventory-dc-a.example.yaml inventory-dc-a.yaml
cp inventory-dc-b.example.yaml inventory-dc-b.yaml
# edit both inventories
python3 render-config.py --both
```

5. Run automated pre-flight (read-only except optional image-pull pods):

```bash
./preflight.sh dc-a.env dc-b.env
```

6. Coordinate with network/firewall teams — TCP **9095** and ICMP must be allowed **between test pod IPs** on the replication VLAN (both directions). Host-only ACLs are a common false negative.
7. Run the test suite (skip bond failover on the first attempt):

```bash
./run-network-test.sh dc-a.env dc-b.env
```

### What preflight.sh checks

| Check | What failure usually means |
|---|---|
| Workstation tools (`oc`, `jq`, `envsubst`) | Install missing packages before proceeding |
| Env vars non-empty | Incomplete `dc-*.env` copy |
| `oc whoami` on both kubeconfigs | Wrong path, expired login, or no API reachability |
| CRDs (nmstate, whereabouts) | Operator not installed on that cluster |
| `useMultiNetworkPolicy: true` | Cluster Network operator config — test 6 won't enforce without it |
| Nodes in `NODE_NAMES` exist | Typo in hostname vs `kubernetes.io/hostname` |
| NNCE `Available` per node | NNCP not applied, failed, or wrong node list |
| VLAN interface on first node | `BOND_VLAN_IFACE` doesn't match what NNCP created |
| Probe image pull (unless `--skip-image-pull`) | Missing pull secret, mirror, or registry access |

Preflight does **not** prove cross-DC reachability — that's test 4. It catches the mistakes that waste a test run: wrong env values, platform gaps, and image pull failures.

### Manual checks preflight doesn't automate

- Test whereabouts pool (`.6–.10` in the examples) doesn't overlap host IPs, Kafka's planned pool, or other static assignments on the `/26`.
- Port **9095** isn't already consumed on the replication VLAN for another service.
- You have cluster-admin-ish access for `oc debug node` (host route checks in the full suite).

A passing pre-flight means the **network stack is ready to test**, not that Kafka or Cluster Linking works.

---

## Usage

```bash
# After pre-flight passes:
./run-network-test.sh dc-a.env dc-b.env

# Include the manual/opt-in bond failover test (interactive, prompts before acting)
./run-network-test.sh dc-a.env dc-b.env --with-bond-failover-test

# Tear down test resources on both clusters
./run-network-test.sh dc-a.env dc-b.env --cleanup
```

`dc-a.env` / `dc-b.env` are gitignored (see root `.gitignore`) — they'll contain real kubeconfig paths and node hostnames, so keep the `.example` files as the tracked templates and never commit the filled-in copies.

The script exits non-zero if any check fails, so it's safe to use as a gate in a larger cutover checklist (`./preflight.sh dc-a.env dc-b.env && ./run-network-test.sh dc-a.env dc-b.env && echo "network layer verified"`).

---

## Templating: Helm vs envsubst

| Artifact | Templating | Why |
|---|---|---|
| Per-DC inventory | YAML in [cross-dc-rollout](../cross-dc-rollout/README.md) | Single source of truth for overlapping fields |
| Per-node NNCP (host bond/VLAN/routes) | [Helm](../../messaging/kafka/cross-dc-nncp-helm/README.md) | One policy per node with unique static IPs — an *N nodes* problem |
| Kafka NAD + `MultiNetworkPolicy` | [Helm](../../messaging/kafka/cross-dc-kafka-net-helm/README.md) | Per-DC workload layer after network test |
| Test framework manifests (NAD, pods, policy) | `envsubst` in `run-network-test.sh` | Fixed two-cluster runbook — env rendered from inventory |
| Env files (`dc-a.env`, `dc-b.env`) | Rendered or manual `export` | Kubeconfig paths are workstation-local |

Helm makes sense where you render many similar CRs from a node list and may roll them out in batches. The test framework applies a known-small manifest set twice (DC-A, DC-B) with different subnet values — `envsubst` keeps the dependency surface to `oc` + `gettext`. Converting the test manifests to Helm would mostly duplicate the env files as `values-dc-a.yaml` without simplifying the workflow.

If you later want a single packaging story, a thin wrapper chart that embeds the same YAML and takes two value files is possible — but it's optional polish, not a prerequisite for the first live run.

---

## What each test checks

| # | Check | How | Maps to checklist item |
|---|---|---|---|
| 1 | Host NNCP/NNCE healthy | `oc get nnce` on both clusters — enactment for each target node is `Available` | 1 |
| 2 | Host route correct, not default | `oc debug node/<n> -- chroot /host ip route show table main` — confirms the `/26` route exists on the VLAN interface, and that interface has no `default` route | — |
| 3 | Pod got second interface, correct IP, no default-route | Parses the test pod's `k8s.v1.cni.cncf.io/network-status` annotation | 3, 7 |
| 4 | Cross-DC reachability | `ncat -zv` from the DC-A test pod to the DC-B test pod's port, and the reverse (links are bidirectional) | 2 |
| 5 | Real path MTU | `ping -M do -s <size>` sweep from the DC-A pod to the DC-B pod, compared against `DCx_EXPECTED_MTU` | 6 |
| 6 | `MultiNetworkPolicy` enforcement | A local-subnet peer pod on the same NAD is blocked; the legitimate remote-DC pod (test 4) is allowed | 5 |
| 7 | Bond failover (manual/opt-in) | Interactive: `nmcli device disconnect <member>` via `oc debug node`, re-runs test 4, then reconnects | 4 |

Each check prints `PASS`/`FAIL` with enough context to diagnose; the run ends with a summary count and a non-zero exit code if anything failed.

---

## Why test 6 uses a local peer

The naive version of this test — "an unlabeled pod can't reach the labeled one" — doesn't actually prove enforcement. `MultiNetworkPolicy` (like standard `NetworkPolicy`) is **default-allow for pods no policy selects**: a pod not matched by any `podSelector` has no restrictions applied to it at all, so a truly "unlabeled" pod would be unrestricted by default regardless of whether the policy works correctly.

What the real Kafka policy in [`cross-dc-replication.md`](../cross-dc-replication.md#securing-the-secondary-network-multinetworkpolicy) actually restricts is the **source IP range** via `ipBlock`, scoped to the remote DC's subnet. So the meaningful negative case is a peer whose IP is *not* in that allowed range — and the easiest such peer to stand up is another pod on the same NAD, same local DC, whose IP falls in the local (not remote) subnet.

`probe-unauthorized` exists for exactly this: same NAD, same namespace, IP in the local test pool. Test 6 confirms it's blocked from reaching `probe-authorized`'s port, while test 4 already confirmed the legitimate remote-DC `probe-authorized` pod *can* reach it — together, that's proof the `ipBlock` restriction is doing real work, not just present in the API.

---

## Cleanup

`./run-network-test.sh dc-a.env dc-b.env --cleanup` deletes the `cross-dc-net-test` namespace (and everything in it — pods, the NAD, the policy) on both clusters. Safe to leave test resources in place between runs if you're iterating on a failure; re-running `apply_side` (i.e., a normal run) is idempotent (`oc apply`).

If a run fails partway through, the partially-applied resources are left in place deliberately — useful for `oc describe`/`oc debug` follow-up. Clean up explicitly once you're done rather than relying on an automatic teardown.

---

## Layout

```text
cross-dc-network-test/
├── README.md                          — this file
├── preflight.sh                       — read-only prerequisite checks
├── run-network-test.sh                — driver script
├── dc-a.env.example                   — DC-A config template (copy to dc-a.env)
├── dc-b.env.example                   — DC-B config template (copy to dc-b.env)
├── repl-net-probe/
│   ├── Containerfile                  — UBI9 minimal probe image
│   └── README.md                      — build, publish, manual debug
└── manifests/
    ├── namespace.example.yaml
    ├── nad-test.example.yaml           — separate whereabouts pool from Kafka's own
    ├── probe-pod.example.yaml          — applied twice: probe-authorized, probe-unauthorized
    └── multinetworkpolicy-test.example.yaml
```

Plain YAML + `envsubst` for the DC-specific values (subnet/gateway/kubeconfig/node names) — not Helm. This is a fixed two-sided test, not the "N nodes" templating problem the [NNCP Helm chart](../../messaging/kafka/cross-dc-nncp-helm/README.md) solves, so Helm's value-add doesn't apply here.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

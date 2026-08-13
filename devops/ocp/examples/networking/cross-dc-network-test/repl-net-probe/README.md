---
review:
  status: unreviewed
  notes: "UBI9 probe image for cross-DC network test framework; Containerfile linted via podman build only."
---

# repl-net-probe — UBI9 Network Probe Image

**Audience:** Whoever builds and publishes the container image used by the [cross-DC network test framework](../README.md).

**Purpose:** A minimal, UBI9-based probe image scoped to VLAN/Multus connectivity verification — not a `netshoot` replacement. Packages come from Red Hat UBI BaseOS/AppStream only (no EPEL, no vendored Go binaries, no Alpine `edge` repos).

**Related:** [Cross-DC network test framework](../README.md) · [Cross-DC replication network](../../cross-dc-replication.md)

---

## On this page

- [What's in the image](#whats-in-the-image)
- [Build and publish](#build-and-publish)
- [Wire into the test framework](#wire-into-the-test-framework)
- [Manual debugging](#manual-debugging)

---

## What's in the image

| Tool | Package | Used by |
|---|---|---|
| `ncat` | `nmap-ncat` | Test 4/6 — TCP listener (`-l -k`) and `-zv` probes |
| `ping` | `iputils` | Test 5 — path MTU sweep (`ping -M do -s …`) |
| `ip`, `ss` | `iproute` | Manual — routes, interfaces, sockets on the NAD |
| `tcpdump` | `tcpdump` | Manual — capture on the secondary interface |
| `ethtool` | `ethtool` | Manual — NIC/MTU settings |
| `tracepath` | `iputils` | Manual — path discovery |
| `jq` | `jq` | Manual — parse JSON in ad-hoc checks |

The test framework's driver script only execs `ncat` and `ping` inside these pods; everything else is there for interactive follow-up when a check fails.

**Why no `bind-utils`?** `dig`/`host` are useful for DNS troubleshooting, but this VLAN test is IP-based (Multus whereabouts, static routes, `ncat` to pod IPs) — DNS is not on the critical path. `bind-utils` also pulled in 21 unfixable HIGH CVEs on the latest UBI bind RPM at `0.1.0` scan time. For occasional name checks, `getent hosts <name>` is enough without adding bind.

**`0.1.1` changes:** `microdnf upgrade -y` before install (current UBI errata); dropped `bind-utils`.

---

## Build and publish

```bash
cd devops/ocp/examples/networking/cross-dc-network-test/repl-net-probe

# Build locally
podman build -t repl-net-probe:0.1.1 -f Containerfile .

# Tag for your internal registry (both clusters must be able to pull this)
podman tag repl-net-probe:0.1.1 quay.io/rh_hhellbusch/repl-net-probe:0.1.1
podman push quay.io/rh_hhellbusch/repl-net-probe:0.1.1
```

On OpenShift, ensure the `cross-dc-net-test` namespace (or cluster-wide pull secret) can reach your registry. If clusters use a disconnected mirror, mirror this image the same way you mirror other UBI-based workload images.

**Scan before import:** run your registry's Clair/Trivy policy against the pushed digest. This image is intentionally small — a typical scan surface is ~10 RPMs on UBI minimal, not the 200+ CRITICAL/HIGH findings common on upstream `nicolaka/netshoot:latest`.

---

## Wire into the test framework

Add to both `dc-a.env` and `dc-b.env` (same value on both sides):

```bash
export TEST_PROBE_IMAGE="quay.io/rh_hhellbusch/repl-net-probe:0.1.1"
```

Then run the test suite as documented in [../README.md](../README.md#usage).

---

## Manual debugging

After a failed run, exec into a probe pod on the NAD:

```bash
# Secondary interface is usually net1 when repl-net-test is the only Multus attachment
oc -n cross-dc-net-test exec -it probe-authorized -- sh

# Confirm the Multus IP and routes inside the pod
ip -4 addr show
ip -4 route show

# Probe the remote DC pod IP (from the other cluster's probe-authorized)
ncat -zv <remote-pod-ip> 9095

# Path MTU check (same as test 5)
ping -M do -s 1472 -c 2 <remote-pod-ip>

# Capture on the replication interface (adjust -i if your CNI names it differently)
tcpdump -i net1 -n host <remote-pod-ip>
```

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

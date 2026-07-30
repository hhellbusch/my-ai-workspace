---
review:
  status: unreviewed
  notes: "NVMe/TCP storage network troubleshooting guide — review metadata backfill."
---

# NVMe/TCP Storage Network on Bare-Metal OpenShift

## Overview

Bare-metal OpenShift nodes that use **NVMe over TCP** (NVMe/TCP) for block storage typically have **two dedicated storage NICs** cabled to **two switches** and a **dual-controller array**.
Redundancy comes from **independent network paths** plus **native NVMe multipath** in the kernel — not from bonding storage interfaces.

This guide covers topology decisions, what **not** to bond, multipath vs `dm-multipath`, sysctl/NMState patterns on RHCOS, and how this fits with host NQN prep and CSI install.

**Prerequisite:** unique host NQN per node — see [NVMe Host NQN Duplicates](../nvme-host-nqn-duplicate/README.md) first.

## When to Use This Guide

| Scenario | Use this guide |
|----------|----------------|
| Dell CSM / Pure FlashArray / HPE CSI over NVMe/TCP on bare metal | Yes — before CSI install |
| Two storage interfaces on each worker, unsure about bonding | Yes |
| iSCSI or FC only (no NVMe/TCP) | No — different multipath stack (`dm-multipath`) |
| Cloud / single-NIC workers | Partial — vendor may not require dual-path TCP |
| Front-end / management network design | No — see [CoreOS Networking Issues](../coreos-networking-issues/README.md) |

---

## Target topology

```text
                    ┌── Switch A ── Array controller A
Host storage NIC-0 ─┤
                    │
Host storage NIC-1 ─┤── Switch B ── Array controller B

Host front-end (optional bond) ── app / OVN / API traffic  (separate from storage)
```

| Layer | Recommendation |
|-------|----------------|
| NICs | Minimum **2 dedicated storage NICs** per node |
| Switches | **Dual fabric** — one NIC per switch |
| Bonding storage NICs | **Do not** (LACP/802.3ad) — breaks independent-path model |
| Bonding front-end NICs | OK — unrelated to NVMe/TCP data path |
| L3 | Static IP **per storage NIC**; **no default gateway** on storage interfaces |
| MTU | **9000** end-to-end if fabric supports jumbo frames |
| VLAN | Dedicated storage VLAN(s) — one or two VLANs depending on design |
| Multipath | **Native NVMe** (`nvme_core.multipath=Y`) — not `dm-multipath` |

Pure documents this model in [NVMe-TCP architecture overview](https://support.purestorage.com/bundle/m_linux/page/Solutions/Linux/topics/c_rhel_nvme-tcp_best-practices_architecture_overview.html) (bonding row: *Do NOT bond storage NICs*).

---

## Bond or not?

### Do not bond storage NICs for NVMe/TCP

NVMe/TCP HA expects **multiple independent paths** (host NIC × array portal × controller).
The kernel **native NVMe multipath** layer balances and fails over across those paths.

Bonding storage NICs (especially **802.3ad/LACP**) tends to:

- Collapse independent paths into one logical interface
- Interfere with per-path discovery and reconnect behavior
- Work against array-side multipath zoning

### Front-end vs storage

| Network | Typical pattern |
|---------|-----------------|
| Management / OVN / ingress | Bond or single NIC — cluster design choice |
| **NVMe/TCP storage** | **Two separate interfaces**, each with its own IP |

Community OCP + FlashArray guides (e.g. [DinoCloud](https://dinocloud.net/2026/02/16/beginners-guide-to-openshift-virtualization-with-nvme-tcp-pure-flasharray/)) commonly use 2 front-end NICs (sometimes bonded) **plus** 2 storage NICs on dedicated VLANs **without** bonding.

### Active-backup bond (exception)

Some Linux storage docs mention `active-backup` bonding as an alternative HA pattern.
That is **not** the primary recommendation for NVMe/TCP multipath.
If storage architecture mandates it, validate with the array vendor — **avoid LACP** for NVMe/TCP.

---

## L3 layout options

### Option A — Two subnets (common)

| NIC | Example | Switch |
|-----|---------|--------|
| `ens1f0` | `10.100.1.101/24` | Switch A |
| `ens1f1` | `10.100.2.101/24` | Switch B |

Cleanest for path isolation; no special ARP sysctl required.

### Option B — Same subnet, two NICs

Both NICs on one storage VLAN/subnet works if **ARP tuning** is applied (Pure documents this for same-subnet multipath):

```bash
sysctl -w net.ipv4.conf.all.arp_ignore=2
sysctl -w net.ipv4.conf.all.arp_announce=2
```

Persist via MachineConfig `storage.files` or sysctl drop-in on workers.

### All options

- **No default route** on storage interfaces — storage traffic stays on local subnets
- **DNS not required** on storage interfaces
- Confirm **MTU matches** host, switches, and array ports (`ping -M do -s 8972 <array-ip>` for MTU 9000)

---

## Native NVMe multipath (not dm-multipath)

NVMe/TCP uses **kernel native multipath**, not `multipathd` / `multipath.conf` (those are for iSCSI/FC).

### Verify

```bash
cat /sys/module/nvme_core/parameters/multipath    # expect Y
lsmod | grep nvme_tcp
nvme list-subsys
```

### Enable (if needed)

Via MachineConfig — module drop-in:

```yaml
# Fragment — merge into a worker MachineConfig storage.files entry
path: /etc/modprobe.d/nvme-tcp.conf
contents:
  source: data:,options%20nvme_core%20multipath%3DY%0A
```

Reboot or reload module per vendor docs after applying.

Dell CSM OpenShift install guides add **udev rules** for IO policy (`round-robin` / `queue-depth`) and `ctrl_loss_tmo` — see [Dell CSM PowerMax install](https://dell.github.io/csm-docs/docs/getting-started/installation/openshift/powermax/csmoperator/) for array-specific MachineConfig fragments.

---

## OpenShift: NMState for storage interfaces

Day-2 storage network configuration on RHCOS uses the **kubernetes-nmstate operator** and `NodeNetworkConfigurationPolicy` (NNCP).

1. Install NMState Operator (Software Catalog or GitOps).
2. Apply an NNCP that defines **two independent ethernet connections** on storage NICs — not a bond.
3. Scope with `nodeSelector` to workers that participate in storage I/O.

Example skeleton (adjust interface names, IPs, MTU): [example-nncp-storage-interfaces.yaml](example-nncp-storage-interfaces.yaml)

```bash
oc apply -f example-nncp-storage-interfaces.yaml
oc get nncp,nns   # policy enacted; per-node state
```

**Assisted / ABI install:** storage static IPs can be defined at install time via NMState in the discovery ISO workflow — coordinate with rack/IP planning before nodes join.

NMState is separate from OVN primary networking (`br-ex` / node IP). Storage NICs are additional interfaces; CSI and `nvme connect` use the storage IPs.

---

## Prep checklist (order matters)

| Step | Guide / action |
|------|----------------|
| 1 | Unique host NQN per node — [nvme-host-nqn-duplicate](../nvme-host-nqn-duplicate/README.md) |
| 2 | Storage network (this guide) — dual NIC, no bond, MTU, no default route |
| 3 | Native NVMe multipath + vendor udev MCs if required |
| 4 | CSI install (Dell CSM, Portworx, HPE, etc.) |
| 5 | Array host registration / volume attach |
| 6 | If CSI fails — [Portworx CSI CrashLoop](../portworx-csi-crashloop/README.md) |

---

## Verification

On each storage worker after NNCP/MC apply:

```bash
# Interfaces up with expected IPs and MTU
ip -br addr show
ip link show <storage-nic-0> | grep mtu

# No default route via storage NIC
ip route | grep default

# Multipath enabled
cat /sys/module/nvme_core/parameters/multipath

# After CSI/array config — subsystems and paths
nvme list-subsys

# Pre-CSI fabric check (per path; adjust IPs / ifaces)
nvme discover -t tcp -a <ctrl-a-ip> -s 4420 -w ens1f0
nvme discover -t tcp -a <ctrl-b-ip> -s 4420 -w ens1f1
```

Via `oc debug` (no SSH):

```bash
oc debug node/<node> --quiet -- chroot /host \
  nvme discover -t tcp -a <ctrl-a-ip> -s 4420 -w ens1f0
```

Across a node list: [ansible/README.md](ansible/README.md).

From a bastion with SSH (optional):

```bash
for h in worker-0 worker-1 worker-2; do
  echo "=== $h ==="
  ssh core@"$h" 'ip -br addr; cat /sys/module/nvme_core/parameters/multipath 2>/dev/null'
done
```

---

## See Also

- [Quick Reference](QUICK-REFERENCE.md) — decision tree and copy-paste checks
- [Index](INDEX.md) — navigate by task
- [ansible/ — nvme discover via oc debug](ansible/README.md) — fleet fabric check
- [NVMe Host NQN Duplicates](../nvme-host-nqn-duplicate/README.md) — step 1 in the prep chain
- [Portworx CSI CrashLoop](../portworx-csi-crashloop/README.md)
- [Kafka + Portworx bare metal](../../examples/messaging/kafka/bare-metal-portworx/README.md)

## External References

- [Pure — NVMe/TCP architecture overview](https://support.purestorage.com/bundle/m_linux/page/Solutions/Linux/topics/c_rhel_nvme-tcp_best-practices_architecture_overview.html)
- [Pure — NVMe/TCP network configuration](https://support.purestorage.com/bundle/m_linux/page/Solutions/Linux/topics/c_rhel_nvme-tcp_best-practices_network_configuration.html)
- [Pure — NVMe/TCP high availability / multipath](https://support.purestorage.com/bundle/m_red_hat/page/Linux/topics/c_rhel_nvme-tcp_best-practices_high_availability.html)
- [Dell CSM — PowerMax on OpenShift](https://dell.github.io/csm-docs/docs/getting-started/installation/openshift/powermax/csmoperator/) — udev + NVMe MC fragments
- [DinoCloud — OCP + NVMe-TCP + FlashArray](https://dinocloud.net/2026/02/16/beginners-guide-to-openshift-virtualization-with-nvme-tcp-pure-flasharray/) — dual storage VLAN pattern
- [OCP — kubernetes-nmstate](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/kubernetes_nmstate/k8s-nmstate-about-the-kubernetes-nmstate-operator)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

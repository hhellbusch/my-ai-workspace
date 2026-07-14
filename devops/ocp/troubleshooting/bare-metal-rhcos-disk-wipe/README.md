# Bare Metal RHCOS Disk Wipe

## Overview

Powering off an OpenShift bare-metal node is **not** enough to retire it. RHCOS on disk retains ignition, ostree, and — on control-plane nodes — etcd and static-pod state. On next boot the host can rejoin the old cluster identity, answer on its old IP, or be reprovisioned by Metal3 if a `BareMetalHost` still exists.

This guide covers **safe identification**, **cluster object removal**, **disk wipe**, and **BMC policy** when decommissioning or repurposing bare-metal OpenShift hardware.

## When to Use This Guide

| Scenario | Use this guide |
|----------|----------------|
| Retired control-plane or worker hardware being removed from service | Yes |
| Old nodes powered on after IP reuse on new hardware | Yes — after [isolating stale hosts](../bare-metal-stale-node-ip-conflict/README.md) |
| Full cluster destroy and hardware reuse | Start with [Destroy Cluster Without Metadata — Bare Metal](../destroy-cluster-without-metadata/BAREMETAL-GUIDE.md); use this for per-node disk wipe detail |
| Node stuck in provisioning | No — see [Bare Metal Node Inspection Timeout](../bare-metal-node-inspection-timeout/README.md) |

---

## Prerequisites

- **BMC access** (iDRAC, ILO, Redfish) — system serial is the source of truth, not IP or hostname
- Inventory record: which serial is approved for wipe
- SSH install key (optional — for wipe via SSH when the target host is confirmed)
- Optional: `oc` access to delete `Node`, `BareMetalHost`, and `Machine` objects before wipe

---

## Step 1: Confirm the Target Host

**Never wipe by IP alone.** Two machines may have shared an address during a hardware swap.

### Via BMC (preferred)

| BMC address | Serial | Role | Wipe? |
|-------------|--------|------|-------|
| `<bmc-ip>` | `…` | retired | **yes** |
| `<bmc-ip>` | `…` | in-service | **no** |

### Via SSH (when reachable)

```bash
hostname
sudo dmidecode -s system-serial-number 2>/dev/null
sudo cat /etc/machine-id
ip addr show
```

Match serial to inventory before any destructive command.

---

## Step 2: Isolate Before Wipe

1. **Power off** other hosts that might conflict on the same IP (see [Stale Node IP Conflict](../bare-metal-stale-node-ip-conflict/README.md) if applicable).
2. Power on **only** the retired host if you need SSH or virtual media — keep in-service hardware off contested IPs.
3. Disable switch port or move to quarantine VLAN if the host must boot for wipe.

```bash
# IPMI power off (before or after wipe)
ipmitool -I lanplus -H <bmc-ip> -U <user> -P '<pass>' power off
```

---

## Step 3: Remove Cluster Objects

Prevent Metal3 from reprovisioning the host on next PXE boot.

```bash
oc get nodes -o wide
oc get baremetalhost -n openshift-machine-api -o wide
oc get machines -n openshift-machine-api

oc delete node <node-name>
oc delete baremetalhost <bmh-name> -n openshift-machine-api
oc delete machine <machine-name> -n openshift-machine-api  # if it remains
```

During API TLS incidents, add `--insecure-skip-tls-verify` if needed.

If the API is unavailable, complete physical isolation and disk wipe first; delete API objects when the control plane is reachable.

---

## Step 4: Wipe All Disks

Shutdown without wipe leaves bootable RHCOS. Wipe **every** block device on the retired host.

```bash
lsblk

for d in $(lsblk -dpno NAME | grep -E '^/dev/sd|^/dev/nvme'); do
  echo "Wiping $d"
  sudo wipefs -a "$d"
  sudo sgdisk --zap-all "$d" 2>/dev/null || true
  sudo dd if=/dev/zero of="$d" bs=1M count=100 status=progress
done
```

### Option A: SSH to the retired host

Run the loop above after serial confirmation. Power off from BMC when finished — do not leave the host booting into a wiped-but-reachable state on production networks.

### Option B: BMC virtual media + live ISO

When SSH is unavailable or IP trust is uncertain:

1. Mount Fedora/RHEL live ISO (or RHCOS live ISO) via BMC virtual media.
2. Boot **only** the retired server.
3. Run the same `wipefs` / `sgdisk` / `dd` loop on every disk.
4. Power off from BMC.

### Option C: RAID controller / iDRAC storage erase (Dell and similar)

On PERC-backed systems: iDRAC → Storage → delete virtual disks or run cryptographic/secure erase. Clear foreign configs. Disable internal disk boot in BIOS until hardware is repurposed.

---

## Step 5: Prevent Return on Power-On

| Layer | Action |
|-------|--------|
| **Power** | BMC: AC power recovery → **Stay Off** |
| **Boot** | `ipmitool ... chassis bootdev none` (vendor support varies); disable PXE-first in BIOS |
| **Network** | Switch port disabled or quarantine VLAN |
| **DHCP/DNS** | Remove reservations for retired MAC addresses |
| **Inventory** | Tag asset `RETIRED — disks wiped` |

```bash
ipmitool -I lanplus -H <bmc-ip> -U <user> -P '<pass>' chassis bootdev none
```

---

## Step 6: Verify

```bash
# From BMC: PowerState Off; boot should not find RHCOS
# Optional: one-time power on with virtual media — installer should not see old ostree

# If reprovisioning later: new ignition/ISO only; no old partitions
lsblk  # from live ISO or first boot — no openshift/RHCOS labels
```

---

## Quick Reference: Order of Operations

| Step | Action |
|------|--------|
| 1 | Confirm serial via BMC — not IP |
| 2 | Isolate / power policy |
| 3 | `oc delete node` + `baremetalhost` |
| 4 | `wipefs` + `sgdisk --zap-all` + `dd` on all disks |
| 5 | BMC Stay Off; disable port |
| 6 | Power on replacement hardware only |

---

## Prevention

- Decommission checklist: power off → delete BMH → wipe disks → disable switch port → AC Stay Off.
- Bind BMC serial to inventory role; never reuse IPs without retiring old chassis in writing.
- Keep `BareMetalHost` count aligned with physical machines in service.

---

## See Also

- [Quick Reference](QUICK-REFERENCE.md) – Copy-paste wipe commands
- [Index](INDEX.md) – Navigate by task
- [Bare Metal Stale Node IP Conflict](../bare-metal-stale-node-ip-conflict/README.md) – When duplicate IPs cause MAC flapping
- [Destroy Cluster Without Metadata — Bare Metal](../destroy-cluster-without-metadata/BAREMETAL-GUIDE.md) – Full cluster teardown
- [Bare Metal Node Inspection Timeout](../bare-metal-node-inspection-timeout/README.md) – Active provisioning issues

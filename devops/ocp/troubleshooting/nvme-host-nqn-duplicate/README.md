# NVMe Host NQN Duplicates on OpenShift Nodes

## Overview

Each OpenShift node that connects to external block storage over **NVMe-oF** (NVMe over Fabrics — TCP, RDMA, or FC) must present a **unique host NQN** (NVMe Qualified Name).
The host NQN is the initiator identity the storage array uses for zoning, host registration, and access control — analogous to an iSCSI IQN.

On RHCOS, that identity normally lives in:

| File | Purpose |
|------|---------|
| `/etc/nvme/hostnqn` | Host NQN string presented to NVMe-oF targets |
| `/etc/nvme/hostid` | 16-byte host ID paired with the NQN for reconnect stability |

**The common failure:** nodes installed from the same RHCOS image inherit identical values in these files.
Every worker then looks like the same initiator.
Storage CSI drivers, multipath, and array-side host objects break — sometimes with an explicit duplicate-NQN error.

This guide covers verification, the correct MachineConfig fix, how vendor proposals compare, an anti-pattern to avoid, and array registration notes for Dell and Portworx environments.

## When to Use This Guide

| Scenario | Use this guide |
|----------|----------------|
| Dell CSM (PowerMax, PowerStore, PowerFlex) prep on bare-metal OCP | Yes — prerequisite |
| Portworx + Pure FlashArray over NVMe-TCP | Yes |
| HPE CSI reports duplicate NQN on node registration | Yes |
| PVCs stuck; NVMe connect or multipath errors on workers | Check NQNs first |
| iSCSI-only storage (no NVMe-oF) | Partial — see [iSCSI initiator note](#iscsi-initiator-same-class-of-bug) |
| Local NVMe disks (`/dev/nvme0n1` as root device) only | No — host NQN is for fabric attach, not local PCIe NVMe |

---

## Background: What the NQN Should Look Like

On bare-metal Dell (and most physical servers), the expected host NQN format is:

```text
nqn.2014-08.org.nvmexpress:uuid:<system-uuid>
```

Where `<system-uuid>` comes from SMBIOS — the same value as:

```bash
dmidecode -s system-uuid
cat /sys/class/dmi/id/product_uuid
```

Generation is defined in NVMe TP-4126 (Host NQN and Host ID should derive from the platform system UUID).
The `nvme gen-hostnqn` command implements this with validation and fallback when DMI UUID is invalid (all zeros — common in VMs).

---

## Symptoms

- Two or more nodes report the **same** `/etc/nvme/hostnqn`
- CSI node driver fails to start; logs mention **duplicate NQN** or initiator validation failure
- NVMe-oF volumes attach on one node but not others
- Array-side host registration shows one host where many are expected
- Multipath shows unexpected path grouping across nodes

Example error (HPE CSI on OpenShift):

```text
CRITICAL: Duplicate NQN 'nqn.2014-08.org.nvmexpress:uuid:...' detected on node 'worker-0'
(attempting to register on node 'worker-1'). Each node must have unique NVMe Qualified Names
```

---

## Root Cause

RHCOS/CoreOS images can ship with **static** `/etc/nvme/hostnqn` and `/etc/nvme/hostid` baked into the rootfs.
Every node installed from that image copies the same files.
The installer does not always regenerate per-node values before first boot.

This is the same class of bug documented for Harvester ([harvester#6911](https://github.com/harvester/harvester/issues/6911)) and acknowledged for OCP ([Red Hat KCS 7073579](https://access.redhat.com/solutions/7073579), [RHEL Bug 2049991](https://bugzilla.redhat.com/show_bug.cgi?id=2049991)).

On bare metal, hardware UUIDs *are* unique — the problem is the **file content**, not the servers.

---

## Step 1: Verify

Run on **each** node that will use NVMe-oF storage (workers at minimum; masters too if they participate in storage I/O):

```bash
echo "hostnqn: $(cat /etc/nvme/hostnqn)"
echo "hostid:   $(cat /etc/nvme/hostid)"
echo "dmi uuid: $(dmidecode -s system-uuid 2>/dev/null || cat /sys/class/dmi/id/product_uuid)"
```

From a bastion with SSH access to all nodes:

```bash
for host in worker-0 worker-1 worker-2; do
  echo "=== $host ==="
  ssh -o StrictHostKeyChecking=no core@"$host" \
    'cat /etc/nvme/hostnqn; dmidecode -s system-uuid 2>/dev/null'
done
```

**Pass:** every node has a different `hostnqn`, and the UUID suffix matches that node's DMI system UUID.

**Fail:** two or more nodes share the same `hostnqn`, or the file contains a literal `$(cat ...)` string (see anti-pattern below).

### Red Hat KBA diagnostic (KCS 7073579)

Red Hat's recommended triage compares **what the host should have** vs **what is on disk**:

```bash
nvme gen-hostnqn          # correct value from host UUID
cat /etc/nvme/hostnqn     # value currently in use
```

If these differ, the baked-in file is wrong — apply the fix in Step 2.
This check is the fastest way to confirm the duplicate-NQN problem without comparing nodes to each other.

---

## Step 2: Apply the Fix (MachineConfig + systemd)

Per-node identity must be generated **on each node at boot**.
A cluster-wide `MachineConfig` cannot embed node-specific static file content via Ignition — see [Anti-pattern: Ignition static file](#anti-pattern-ignition-static-file-with-shell).

### Recommended MachineConfig

Apply separate configs for `worker` and `master` pools if both connect to NVMe-oF storage.
Match `ignition.version` to your cluster (check an existing MachineConfig: `oc get mc 00-worker -o yaml | grep version`).
OCP 4.20+ clusters often use `3.5.0`; older clusters may use `3.2.0` or `3.4.0`.

Example manifest: [99-worker-nvme-host-identity.yaml](99-worker-nvme-host-identity.yaml)

```bash
oc apply -f 99-worker-nvme-host-identity.yaml
```

MCO rolls the pool — expect a **rolling reboot** of affected nodes.

### What the fix does

A systemd oneshot runs early in boot on **each** node:

1. `nvme gen-hostnqn > /etc/nvme/hostnqn` — format DMI UUID as standard host NQN (with validation/fallback)
2. `dmidecode -s system-uuid > /etc/nvme/hostid` — set paired host ID

Both files must stay in sync for stable NVMe-oF reconnect behavior.

The systemd unit runs on **every boot** and overwrites both files.
On bare metal with a stable DMI system UUID, `nvme gen-hostnqn` produces the same value each time — the unit is idempotent in practice.
If the motherboard is replaced or DMI UUID changes, the NQN changes too; update array-side host registration to match.

**If hosts were already registered on the array under duplicate or wrong NQNs:** after this fix, re-collect per-node NQNs and update or recreate host objects on the array (Dell CSM and Portworx can often re-register automatically; manual arrays need a storage-admin pass).
Disconnect or migrate volumes first if the array rejects NQN changes on in-use hosts.

### After reboot — re-verify

```bash
for host in worker-0 worker-1 worker-2; do
  echo "=== $host ==="
  ssh core@"$host" 'cat /etc/nvme/hostnqn; cat /etc/nvme/hostid'
done
```

Confirm uniqueness across nodes before installing or restarting storage CSI drivers.

---

## Provider fixes compared

Storage vendors and the OpenShift ecosystem have converged on the same underlying fix: **run `nvme gen-hostnqn` on each node at boot via a MachineConfig systemd unit**.
Differences are in whether they also set `hostid`, how many systemd units they use, and whether regeneration is unconditional or gated on a known-bad value.

The manifest in this directory — [99-worker-nvme-host-identity.yaml](99-worker-nvme-host-identity.yaml) — synthesizes vendor guidance with two additions most vendors omit: **paired `hostid` generation** and **explicit boot ordering** (`Before=network-online.target`).

### Summary

| Source | Reference | Mechanism | Sets `hostnqn` | Sets `hostid` | Systemd units | Regeneration |
|--------|-----------|-----------|----------------|---------------|---------------|--------------|
| **This repo** | [99-worker-nvme-host-identity.yaml](99-worker-nvme-host-identity.yaml) | MC + systemd oneshot | `nvme gen-hostnqn` | `dmidecode -s system-uuid` | 1 combined | Every boot (idempotent on stable DMI) |
| **Dell CSM** | [PowerMax / PowerStore / PowerFlex OpenShift install](https://dell.github.io/csm-docs/docs/getting-started/installation/openshift/powermax/csmoperator/) | MC + systemd oneshot | `nvme gen-hostnqn` | No | 1 (`custom-coreos-generate-nvme-hostnqn`) | Every boot |
| **HPE CSI** | [Duplicate NQNs on OpenShift](https://scod.hpedev.io/csi_driver/partners/redhat_openshift/index.html) | MC + systemd oneshot | `nvme gen-hostnqn` | `dmidecode -s system-uuid` | 2 separate | Every boot |
| **Pure / Portworx** | [DinoCloud OCP + NVMe-TCP + FlashArray](https://dinocloud.net/2026/02/16/beginners-guide-to-openshift-virtualization-with-nvme-tcp-pure-flasharray/) | MC + systemd oneshot | `nvme gen-hostnqn` | Optional (`random/uuid` if empty) | 1 conditional | Only if value matches known duplicate |
| **Red Hat** | [KCS 7073579](https://access.redhat.com/solutions/7073579), [RHEL Bug 2049991](https://bugzilla.redhat.com/show_bug.cgi?id=2049991), OCPBUGS-34629, RHEL-8041 | Manual per node (KBA) or installer/dracut (desired) | `nvme gen-hostnqn` | DMI UUID / sysimage copy | N/A (KBA); MC gap-fill in practice | KBA: manual; vendors: every boot |
| **Harvester** | [#6911](https://github.com/harvester/harvester/issues/6911) | Image build + first-boot scriptlets | RPM postinstall / boot script | Same | N/A (fix the image) | Once at first boot |
| **Peer anti-pattern** | Field suggestion (do not use) | Ignition `storage.files` | Literal `$(cat ...)` string | No | N/A | Never executes |

### Dell CSM

Dell documents the duplicate-NQN problem across PowerMax, PowerStore, and PowerFlex OpenShift install guides.
Their MachineConfig uses a single systemd unit that runs:

```bash
/usr/sbin/nvme gen-hostnqn > /etc/nvme/hostnqn
```

**Compared to this repo:** same `hostnqn` command and MC pattern.
Dell does **not** set `/etc/nvme/hostid` in the same unit.
For Dell CSM that is often sufficient because CSM registers hosts by NQN, but setting `hostid` as well is safer for general NVMe-oF reconnect behavior.
Dell bundles additional MC fragments in the same guides (udev multipath policy, `ctrl_loss_tmo` rules) — see their docs for the full NVMe/TCP prep stack, not just NQN.

### HPE CSI

HPE documents the failure mode explicitly — CSI init container errors with `Duplicate NQN ... will cause data corruption` — and ships hosted manifests:

- Worker: `https://scod.hpedev.io/csi_driver/partners/redhat_openshift/examples/nqns/machine-config.yaml`
- Converged (master pool): `.../machine-config-converged.yaml`

Their worker manifest uses **two** systemd units:

```bash
nvme gen-hostnqn > /etc/nvme/hostnqn
dmidecode -s system-uuid > /etc/nvme/hostid
```

**Compared to this repo:** same commands for both files.
HPE splits them into separate units (easier to see which step failed); we combine them in one `ExecStart` (atomic update, fewer moving parts).
HPE uses `ignition.version: 3.2.0` and does not set `Before=network-online.target`.
HPE ships a ready-made **master** variant for converged clusters; we document duplicating the MC with `role: master` instead.

**When to prefer HPE's YAML:** HPE CSI on OpenShift, especially if you want the upstream-hosted manifest and separate unit names matching HPE support docs.

### Pure Storage / Portworx (community)

The [DinoCloud FlashArray + OCP guide](https://dinocloud.net/2026/02/16/beginners-guide-to-openshift-virtualization-with-nvme-tcp-pure-flasharray/) embeds NQN fix inside a larger `99-px-nvme-optimization` MachineConfig (multipath, udev, nmstate).
Their NQN unit is **conditional** — it regenerates only when `hostnqn` equals a specific known duplicate:

```bash
if [ "$(cat /etc/nvme/hostnqn)" = "nqn.2014-08.org.nvmexpress:uuid:4957c8e0-..." ]; then
  nvme gen-hostnqn > /etc/nvme/hostnqn
fi
```

The author later recommends also handling `hostid`, optionally with `cat /proc/sys/kernel/random/uuid` when empty.

**Compared to this repo:** conditional regen is safer if you already registered hosts on the array under the *old* NQN and want to avoid changing identity on every boot until you're sure — but it **fails silently** if the baked-in duplicate is a different UUID than the one hardcoded in the `if` test.
Our manifest regenerates unconditionally, which is simpler and correct when the duplicate value is unknown or varies by image version.
Prefer conditional logic only when you know the exact bad NQN and have a migration plan for array-side host objects.

### Red Hat / Harvester (root cause, not workaround)

These references explain **why** the duplicate exists rather than shipping a customer MachineConfig:

- **[KCS 7073579](https://access.redhat.com/solutions/7073579)** (updated Jan 2026) — acknowledges duplicate host NQNs on OCP nodes; resolution is `nvme gen-hostnqn > /etc/nvme/hostnqn`; **recommends manual fix per node** until RHCOS automates generation (tracked under **OCPBUGS-34629**, **RHEL-8041**).
- **RHEL Bug 2049991** — installer should run `nvme gen-hostnqn` and copy `{hostnqn,hostid}` into the installed rootfs before dracut rebuild; relevant for NVMe boot-from-SAN.
- **Harvester #6911** — static files baked into the ISO rootfs; fix by removing them at image build and regenerating at first boot.

**KBA install-only steps (not day-2 CSI):** FC `echo add > /sys/class/fc/fc_udev_device/nvme_discovery` and copying `{hostnqn,hostid}` to `/mnt/sysimage/etc/nvme/` apply during **live install / boot-from-SAN**, not to a running cluster.

**Manual vs MachineConfig:** Red Hat's KBA prefers manual per-node correction; HPE, Dell, and this repo use **MachineConfig + systemd** because cluster-scale manual SSH does not scale.
Both implement the same command — the tension is operational automation vs waiting for a platform fix.
Revisit or remove the MC when OCPBUGS-34629 / RHEL-8041 land in your OCP version.

**Compared to this repo:** our MachineConfig is a **day-2 gap-fill** when the platform image still ships duplicates.
Harvester/RHEL fixes address the image pipeline; until RHCOS does the same, the MC workaround remains necessary.

### Why this repo's manifest

| Choice | Rationale |
|--------|-----------|
| Combined systemd unit | Same outcome as HPE's two units; one place to read the full identity setup |
| Both `hostnqn` and `hostid` | HPE and NVMe-oF best practice; Dell omits `hostid` but it costs little to set |
| Unconditional regen | Handles any baked-in duplicate, not just one known UUID (DinoCloud approach) |
| `Before=network-online.target` | Identity ready before storage network and CSI connect attempts |
| `/usr/sbin/nvme` path | Explicit path; works even if `$PATH` differs in the systemd service context |

Use vendor-hosted YAML (HPE) or Dell's exact unit name if your support contract expects matching config.
Functionally, all systemd-based approaches listed above produce the same per-node NQN on bare metal when DMI UUID is valid.

---

## Anti-pattern: Ignition Static File with Shell

A common peer suggestion looks like this:

```yaml
storage:
  files:
  - contents:
      source: data:,nqn.2014-08.org.nvmexpress:uuid:$(cat /sys/class/dmi/id/product_uuid)
    path: /etc/nvme/hostnqn
    overwrite: true
```

**This does not work.**

| Issue | Why |
|-------|-----|
| Ignition does not execute shell | `$(cat ...)` is written **literally** to the file on every node |
| Single MachineConfig is cluster-wide | Even with templating, one MC spec cannot produce different static content per node |
| No `hostid` | NVMe-oF expects both files; setting only `hostnqn` is incomplete |
| No DMI validation | `nvme gen-hostnqn` rejects all-zero UUIDs; raw `echo` does not |

All nodes would end up with the identical invalid string:

```text
nqn.2014-08.org.nvmexpress:uuid:$(cat /sys/class/dmi/id/product_uuid)
```

The **intent** (derive NQN from product UUID) is correct.
The **layer** (Ignition `storage.files`) is wrong.
Use systemd oneshot (or install-time per-node Ignition — impractical at scale) instead.

---

## Step 3: Register Hosts on the Storage Array

After NQNs are unique, array-side registration depends on the backend:

| Backend | Registration |
|---------|--------------|
| **Dell CSM** (PowerMax, PowerStore, PowerFlex) | CSM registers hosts automatically using node NQN — see [Dell CSM OpenShift install docs](https://dell.github.io/csm-docs/docs/getting-started/installation/openshift/powermax/csmoperator/) |
| **Portworx + Pure FlashArray** | Portworx REST API creates host objects; collect NQNs first — see [Portworx FlashArray prep](https://docs.portworx.com/portworx-csi/install/prepare/flash-array) |
| **Manual array config** | Create one host per node; add each node's NQN in the array UI or CLI |

Collect NQNs for manual registration:

```bash
for host in worker-0 worker-1 worker-2; do
  printf "%s " "$host"
  ssh core@"$host" 'cat /etc/nvme/hostnqn'
done
```

---

## Timing: Pre-install vs Post-install

| When | Approach |
|------|----------|
| **Post-install** (most common) | Apply MachineConfig after cluster is up; MCO rolling reboot |
| **Pre-install / ABI** | Include the same systemd units in install-time manifests (`AgentClusterInstall` extra manifests or `install-config` `additionalTrustBundle` + `machineConfig` pool) if storage is needed before day-2 |
| **NVMe boot-from-SAN** | Host NQN must be correct in initramfs before root mount — coordinate with installer/Ignition; see RHEL Bug 2049991 for dracut `rd.nvmf.hostnqn` context |

For ACM agent-based install on bare metal, post-install MachineConfig is usually sufficient unless the CSI driver is part of day-0 storage.

---

## iSCSI Initiator: Same Class of Bug

`/etc/iscsi/initiatorname.iscsi` can also be duplicated across nodes from the same image.
If the cluster uses iSCSI (with or without NVMe-oF), check and fix initiator names in the same pass:

```bash
cat /etc/iscsi/initiatorname.iscsi
```

Harvester fixed all three (`machine-id`, iSCSI initiator, NVMe host files) together — see [harvester#6911](https://github.com/harvester/harvester/issues/6911).

---

## Prevention

- Verify NQN uniqueness **before** deploying storage CSI (Dell CSM, Portworx, HPE, etc.)
- Add the MachineConfig to cluster build automation (GitOps / ACM policies) for any NVMe-oF workload
- After node replacement or reprovision, re-check NQNs on new hardware
- Document per-node NQNs in runbooks if the storage team registers hosts manually

---

## See Also

- [Quick Reference](QUICK-REFERENCE.md) — verify, apply, and confirm commands
- [Index](INDEX.md) — navigate by task
- [NVMe/TCP Storage Network](../nvme-tcp-storage-network/README.md) — step 2: dual NIC topology, no bond, NMState (after NQN fix)
- [Portworx CSI CrashLoop](../portworx-csi-crashloop/README.md) — if CSI fails after NQN fix
- [Kafka on Bare Metal + Portworx](../../examples/kafka-bare-metal-portworx/README.md) — rack-aware storage example
- [Bare Metal Node Inspection Timeout](../bare-metal-node-inspection-timeout/README.md) — provisioning issues before storage attach

## External References

Vendor and platform docs cited in [Provider fixes compared](#provider-fixes-compared):

- [Dell CSM — PowerMax on OpenShift](https://dell.github.io/csm-docs/docs/getting-started/installation/openshift/powermax/csmoperator/) — duplicate NQN problem; `hostnqn`-only MachineConfig
- [Dell CSM — PowerStore NVMe requirements](https://dell.github.io/csm-docs/v3/deployment/csmoperator/drivers/powerstore/)
- [HPE CSI — Duplicate NQNs on OpenShift](https://scod.hpedev.io/csi_driver/partners/redhat_openshift/index.html) — hosted worker and converged MachineConfig YAML
- [DinoCloud — OCP + NVMe-TCP + Pure FlashArray](https://dinocloud.net/2026/02/16/beginners-guide-to-openshift-virtualization-with-nvme-tcp-pure-flasharray/) — conditional NQN regen inside broader storage MC
- [Portworx FlashArray prep](https://docs.portworx.com/portworx-csi/install/prepare/flash-array) — Portworx host registration (assumes unique NQNs)
- [Red Hat KCS 7073579](https://access.redhat.com/solutions/7073579) — duplicate NQN on OCP; manual fix; OCPBUGS-34629 / RHEL-8041 tracking
- [RHEL Bug 2049991](https://bugzilla.redhat.com/show_bug.cgi?id=2049991) — installer / dracut hostnqn generation
- [Harvester #6911](https://github.com/harvester/harvester/issues/6911) — root-cause explanation for RHCOS-derived images
- [nvme gen-hostnqn man page](https://github.com/linux-nvme/nvme-cli/blob/master/Documentation/nvme-gen-hostnqn.txt)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

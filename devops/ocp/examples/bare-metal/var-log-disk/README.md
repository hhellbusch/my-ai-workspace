---
review:
  status: unreviewed
  notes: "Bare-metal /var/log disk offload example — review metadata backfill."
---

# Bare-Metal Secondary Disk for `/var/log` — Two Approaches

**Parent guide:** [Secondary disk offload overview](../secondary-disk/README.md) · [Use-case index](../secondary-disk/use-cases/README.md)

**Audience:** Platform engineers offloading node logs and journal from the OS disk on homogeneous bare-metal OpenShift (RHCOS) workers.

**Purpose:** Compare two `MachineConfig` patterns side by side — declarative Ignition partitioning vs script + systemd — and choose a path for GitOps rollout.

**Scope:** OpenShift 4.20+ (Ignition 3.5.0). Example assumes a **14 TiB NVMe** in a fixed bay with a **256 GiB** log slice; remaining capacity left unallocated for a future data partition or Local Storage.

**Manifests (view side by side):**

| Approach | File |
|----------|------|
| **A — Ignition** | [approach-a-ignition.yaml](approach-a-ignition.yaml) |
| **B — Script + systemd** | [approach-b-script-systemd.yaml](approach-b-script-systemd.yaml) |

**Related:** [MachineConfig pools](../../../notes/machine-config-pools.md) · [SNO lab disk mount](../../labs/sno-kvm-lab/hpp-vdb-mount.yaml) · [Ignition operator notes](https://coreos.github.io/ignition/operator-notes/)

---

## On this page

- [Problem](#problem)
- [Side-by-side comparison](#side-by-side-comparison)
- [Shared prerequisites](#shared-prerequisites)
- [Approach A — Ignition](#approach-a--ignition)
- [Approach B — Script + systemd](#approach-b--script--systemd)
- [14 TiB NVMe sizing](#14-tib-nvme-sizing)
- [Multiple NVMe drives](#multiple-nvme-drives)
- [Pitfalls](#pitfalls)
- [GitOps delivery](#gitops-delivery)
- [Rollout and verification](#rollout-and-verification)
- [Choosing between A and B](#choosing-between-a-and-b)
- [Related reading](#related-reading)

---

## Problem

On bare-metal workers the OS virtual disk carries `/var` (container images, kubelet, logs).
Journal and `/var/log` growth can pressure the OS disk even when large secondary NVMe drives are installed.

Goal: mount **`/var/log`** on a **dedicated partition or disk** on secondary NVMe, using a **stable `by-path`** identifier on homogeneous hardware.

That single mount covers **journal**, **kubelet container log files**, and other paths under `/var/log` (see below).

This does **not** replace cluster logging (Loki / Cluster Logging).
It relocates **node-local** log storage and caps journal growth via `journald` limits.

---

## What mounting `/var/log` includes

Mounting at **`/var/log`** moves the **entire tree** — no separate `MachineConfig` for pod logs.

| Path | Role |
|------|------|
| `/var/log/journal/` | Persistent systemd journal (kubelet, crio, units) |
| `/var/log/pods/` | Per-pod log files (`kubectl logs` reads via kubelet) |
| `/var/log/containers/` | Symlinks into `pods/` |
| `/var/log/audit/` | auditd (if enabled) |

**Does not move:** `/var/lib/containers` (images), `/var/lib/kubelet` (sandboxes, emptyDir).
Kubelet **log rotation** (`containerLogMaxSize`, `containerLogMaxFiles`) still applies regardless of disk.

Verify pod logs share the mount:

```bash
oc debug node/worker-0 -- chroot /host bash -c '
  findmnt /var/log /var/log/pods 2>/dev/null || findmnt /var/log
  df -h /var/log/pods
'
```

---

## Side-by-side comparison

| Dimension | **A — Ignition** | **B — Script + systemd** |
|-----------|------------------|---------------------------|
| **Contract** | Declarative partition + filesystem in MC spec | Imperative bash; MC delivers script + units |
| **Idempotency** | Ignition: match partition `number` or fail | Script guards + `ConditionPathExists` on units |
| **“Only if not partitioned”** | No `if` — blank disk or matching p1 required | Script skips create when `by-partlabel/var_log` exists |
| **Wrong disk risk** | `wipe*: false` → fail, not wipe | Script refuses if device hosts `/sysroot` |
| **Boot order** | Ignition `with_mount_unit` | `Before=systemd-journald` on mount unit |
| **14 TiB partial slice** | `sizeMiB: 262144` on partition 1 | `sgdisk … +256GiB` in script |
| **Messy factory partitions** | MCP may **fail** until disk cleaned | Can adapt (if script extended) — default refuses unknown p1 |
| **GitOps review** | Behavior visible in YAML | Behavior split into bash — easy to miss in PR |
| **Support posture** | Red Hat documented MCO/Ignition path | Custom script — your ownership |

---

## Shared prerequisites

### 1. Discover stable `by-path` (not WWN, not `nvme0n1`)

WWN is unique per physical disk.
On identical servers, **bay position** via `by-path` usually repeats:

```bash
oc debug node/worker-0 -- chroot /host bash -c '
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL
  echo "---"
  ls -la /dev/disk/by-path/ | grep -v part | grep -v "\-fc\-"
'
```

Validate the **same** `by-path` basename on three or more workers before fleet rollout.

NVMe example (replace with your path):

```text
/dev/disk/by-path/pci-0000:3d:00.0-nvme-1  →  ../../nvme1n1
```

### 2. Disk hygiene

Both approaches expect the secondary NVMe to be:

- **Unpartitioned** (preferred), or
- Already having **partition 1** with GPT label `var_log` matching the spec

They **refuse or fail** if partition 1 exists with unexpected content.

### 3. MCP rollout

Both trigger **drain + reboot** per node in the pool.

```bash
oc get mcp worker
oc describe mcp worker
```

Plan a maintenance window.
See [machine-config-pools.md](../../../notes/machine-config-pools.md) for custom pools if only some workers have the NVMe.

### 4. Do not apply both approaches

Use **one** of `99-worker-var-log-disk-ignition` or `99-worker-var-log-disk-script`.
Remove or rename the other to avoid conflicting mounts.

---

## Approach A — Ignition

**File:** [approach-a-ignition.yaml](approach-a-ignition.yaml)

### How it works

```text
MCO applies MachineConfig
  → node reboot
  → Ignition storage:
       disk: by-path device, wipeTable: false
       partition 1: label var_log, 256 GiB, number: 1
       filesystem: xfs on by-partlabel/var_log, wipeFilesystem: false
       mount: /var/log (systemd mount unit generated)
       journald drop-in: SystemMaxUse=50G, etc.
```

### Safety flags (the “only partition if appropriate” behavior)

| Flag | Value | Effect |
|------|-------|--------|
| `wipeTable` | `false` | Never destroy partition table |
| `wipePartitionEntry` | `false` | Never delete existing partitions |
| `number` | `1` | Match/reuse partition **by number** (not label alone) |
| `wipeFilesystem` | `false` | Format only when empty; reuse existing XFS |

Ignition creates partition 1 when absent; verifies and no-ops when present; **fails** when p1 exists but does not match.

### Key excerpt

```yaml
partitions:
  - number: 1
    label: var_log
    startMiB: 1
    sizeMiB: 262144
    shouldExist: true
    wipePartitionEntry: false
filesystems:
  - device: /dev/disk/by-partlabel/var_log
    format: xfs
    wipeFilesystem: false
    path: /var/log
    with_mount_unit: true
```

Full manifest: [approach-a-ignition.yaml](approach-a-ignition.yaml)

---

## Approach B — Script + systemd

**File:** [approach-b-script-systemd.yaml](approach-b-script-systemd.yaml)

### How it works

```text
MCO applies MachineConfig
  → writes /usr/local/sbin/prepare-var-log-disk.sh
  → writes prepare-var-log-disk.service + var-log.mount
  → node reboot
  → if by-partlabel/var_log missing:
       script: sgdisk partition 1 (256 GiB), mkfs.xfs
  → var-log.mount mounts /dev/disk/by-partlabel/var_log at /var/log
  → journald limits drop-in (same as A)
```

### Safety guards in the script

- Device must exist at configured `BY_PATH`
- Refuses if `by-path` resolves to the OS disk (`/sysroot` check)
- Refuses if partition 1 exists without `var_log` partlabel
- Creates GPT only when no partition table present
- Formats XFS only when filesystem type is not already `xfs`

### systemd ordering

| Unit | Role |
|------|------|
| `prepare-var-log-disk.service` | Oneshot; runs only when `!…/by-partlabel/var_log` |
| `var-log.mount` | Mounts partition; `Before=systemd-journald.service` |

The mount unit does **not** `Require=` the prepare service (skipped on subsequent boots when partition exists).

### Key excerpt

```ini
# prepare-var-log-disk.service
ConditionPathExists=!/dev/disk/by-partlabel/var_log

# var-log.mount
Before=systemd-journald.service
ConditionPathExists=/dev/disk/by-partlabel/var_log
```

Full manifest: [approach-b-script-systemd.yaml](approach-b-script-systemd.yaml)

---

## 14 TiB NVMe sizing

Do **not** assign the full 14 TiB to logs.

| Item | Example value | Notes |
|------|---------------|-------|
| Log partition (p1) | **256 GiB** (`262144` MiB) | Adjust 128–512 GiB by audit/chatiness |
| Journal cap | `SystemMaxUse=50G` | Independent of partition size |
| Remainder of NVMe | Unallocated in both drafts | Reserve for PVC / Local Storage / p2 later |

A 256 GiB partition formats in seconds; a 14 TiB `mkfs` on first boot does not.

---

## Multiple NVMe drives

Extra NVMe bays change **layout**, not the MC mechanism.
You still mount **`/var/log` once**; `/var/log/pods` comes along automatically.

| Layout | When |
|--------|------|
| **p1 log slice on one large NVMe** | Single data NVMe (e.g. 14 TiB) — p2+ for [application PV](../bare-metal-secondary-disk/use-cases/application-pv.md) |
| **Whole smaller NVMe → `/var/log`** | Two or more NVMe — dedicate a 1–2 TiB drive to logs; use [whole-disk mount](../sno-kvm-lab/hpp-vdb-mount.yaml) instead of partitioning a 14 TiB data drive |
| **NVMe #2 = logs, #3+ = data** | Cleanest with 3+ drives — one `by-path` per role in Git |

```text
BOSS/PERC (OS)     nvme1 (logs)           nvme2–n (data)
──────────────     ────────────           ──────────────
/var, images       whole disk or p1       Local Storage / LVMS / CSI
                   → /var/log
                   (includes pods/)
```

Each bay needs its own validated `by-path` in inventory.
See [secondary disk overview](../bare-metal-secondary-disk/README.md#large-nvme-layout-example).

---

## Pitfalls

| Pitfall | Why it hurts | Mitigation |
|---------|--------------|------------|
| **Separate mount at `/var/log/pods` only** | Journal/audit stay on OS disk; nested mounts are harder to reason about | Mount parent **`/var/log`** |
| **Wrong `by-path` per bay** | MC formats or mounts the wrong NVMe | Validate on ≥3 nodes; document bay → path in Git |
| **Same block device to CSI and log MC** | Portworx/ODF vs Ignition fight over the disk | One consumer per device or explicit p1/p2 split |
| **Full 14 TiB to logs** | Wastes data-tier capacity; huge FS if uncapped | Fixed slice or dedicated smaller NVMe + `journald` limits |
| **Both approach A and B applied** | Conflicting units / double mount | One MC per pool |
| **Expecting `/var/log` to free image space** | CRI-O/kubelet still on OS `/var` | Size OS VD or see [container storage](../bare-metal-secondary-disk/use-cases/container-storage.md) |

---

## GitOps delivery

Neither approach requires a custom CRD.
Use plain values in group or cluster config:

```yaml
# groups/infra-baremetal/values.yaml (illustrative)
nodeConfig:
  varLogDisk:
    enabled: true
    byPath: pci-0000:3d:00.0-nvme-1
    partitionSizeGiB: 256
    approach: ignition   # or script
```

Helm (or Kustomize) renders [approach-a-ignition.yaml](approach-a-ignition.yaml) or [approach-b-script-systemd.yaml](approach-b-script-systemd.yaml) into a spoke repo path; Argo CD syncs to the cluster.

**Hub (ACM install)** owns inventory and labels; **spoke** owns post-install `MachineConfig`.

Validate `by-path` in CI on sample nodes before merge — see [kafka bare-metal inventory pattern](../../messaging/kafka/bare-metal-portworx/README.md#acm-provisioning-and-inventory).

---

## Rollout and verification

### Apply (lab)

```bash
# Pick one:
oc apply -f approach-a-ignition.yaml
# oc apply -f approach-b-script-systemd.yaml

oc get mcp worker -w
```

### Post-reboot checks

```bash
NODE=worker-0

oc debug node/$NODE -- chroot /host bash -c '
  echo "=== mounts ==="
  findmnt /var/log /var
  echo "=== disk ==="
  lsblk -o NAME,SIZE,PARTLABEL,FSTYPE,MOUNTPOINT
  echo "=== journal ==="
  journalctl --disk-usage
  df -h /var/log /var
'
```

Expected:

- `/var/log` on `by-partlabel/var_log` (or child device), **not** the OS `/var` filesystem
- `df /var/log/pods` shows the **same** filesystem as `/var/log`
- Partition 1 ≈ 256 GiB (or whole log NVMe); data NVMe(s) separate when multi-bay
- `journalctl --disk-usage` well below partition size

### Failure signals

| Symptom | Likely cause |
|---------|----------------|
| MCP `Degraded` | Ignition storage mismatch (A) or script exit 1 (B) |
| Logs still on OS disk | Mount ordering — journald started before `/var/log` mount |
| Script refused OS disk | Wrong `by-path` — fix before retry |

On-node logs:

```bash
oc debug node/$NODE -- chroot /host journalctl -t prepare-var-log-disk
oc debug node/$NODE -- chroot /host journalctl -u ignition-mount-var-log.service
```

---

## Choosing between A and B

| Choose **A (Ignition)** when | Choose **B (script)** when |
|------------------------------|----------------------------|
| Secondary NVMe is **blank by policy** (inventory + preflight) | Disk state **varies** (factory partitions, redeployed drives) |
| You want **fail-closed** GitOps | You need explicit **conditional** create logic |
| Reviewers should see full behavior in YAML | Team already operates and tests the script path |

**Hybrid often wins:** preflight blank disk in CI/AAP → **Approach A** in production (script stays out of the boot path).

---

## Related reading

- [MachineConfig pools](../../../notes/machine-config-pools.md)
- [Bare metal RHCOS disk wipe](../../../troubleshooting/bare-metal-rhcos-disk-wipe/README.md)
- [Ignition partition reuse semantics](https://coreos.github.io/ignition/operator-notes/#partition-reuse-semantics)
- [OCP 4.20 — Machine configuration](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/machine_configuration/machine-configs-configure)

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author.
See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

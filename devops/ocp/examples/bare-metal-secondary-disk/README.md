# Bare-Metal Secondary Disk Offload — Overview

**Audience:** Platform engineers planning how to use secondary drives on homogeneous bare-metal OpenShift (RHCOS) — OS on a virtual disk, one or more physical NVMe/HDD tiers available.

**Purpose:** Decide **what** to move off the OS disk, **how** each use case is implemented, and **which guide** to follow. Logs are the first detailed use case; other candidates have draft guides or cross-links.

**Scope:** Worker and master nodes on OpenShift 4.20+ unless a use case notes install-time-only constraints.

---

## On this page

- [Layering model](#layering-model)
- [What burdens the OS disk](#what-burdens-the-os-disk)
- [Offload candidates](#offload-candidates)
- [Implementation patterns](#implementation-patterns)
- [Large NVMe layout (example)](#large-nvme-layout-example)
- [Fleet identity (`by-path`)](#fleet-identity-by-path)
- [GitOps shape](#gitops-shape)
- [Use-case guides](#use-case-guides)
- [What not to do](#what-not-to-do)
- [Related reading](#related-reading)

---

## Layering model

Typical Dell-class bare metal:

```text
PERC / BOSS (virtual disk)          Secondary bay(s) — NVMe or HDD
─────────────────────────          ─────────────────────────────────
RHCOS install target               Raw or partitioned data tier
/sysroot + /var (ephemeral)        PVCs, logs, optional etcd
CRI-O images, kubelet, logs        Local Storage / LVMS / CSI pools
```

**Design principle:** keep the OS disk predictable.
Push **growth**, **I/O-heavy**, and **large durable data** to secondary devices.

Cluster logging (Loki / Cluster Logging) is a **separate** layer — it moves logs off the *cluster*, not just off the OS partition.

---

## What burdens the OS disk

| Consumer | Path / mechanism | Growth |
|----------|------------------|--------|
| Container images | `/var/lib/containers` | Steady — every pull |
| Kubelet / sandboxes | `/var/lib/kubelet` | Bursty |
| Journal + node logs | `/var/log`, journal | Steady; spiky under debug |
| etcd | `/var/lib/etcd` | **Masters only** |
| Platform PVCs (default) | under `/var` if no SC | Large if unconfigured |
| Mirror registry (misconfig) | `/var/lib/containers/...` | Huge on disconnected installs |

Secondary disks are wasted if only the OS VD is sized while **terabytes sit unused**.

---

## Offload candidates

Priority ordered for typical bare-metal workers:

| Priority | Use case | Typical size | Mechanism | Guide |
|----------|----------|--------------|-----------|-------|
| 1 | **Application / platform PVCs** | Largest share | Local Storage, LVMS, ODF, Portworx | [Application PV](use-cases/application-pv.md) |
| 2 | **Node logs + journal** | 64–512 GiB | `MachineConfig` mount `/var/log` | [**`/var/log` (full)**](../bare-metal-var-log-disk/README.md) |
| 3 | **CSI storage pools** | Whole devices | Portworx / ODF consume raw disks | [CSI raw disks](use-cases/csi-raw-disks.md) |
| 4 | **etcd (masters)** | Small but latency-critical | Install / Ignition split | [etcd master](use-cases/etcd-master.md) |
| 5 | **Mirror registry blobs** | Hundreds of GiB–TB | `--quayStorage` on data mount | [Registry](use-cases/disconnected-registry.md) |
| 6 | **Container image store** | Large | Kubelet/CRI-O root move | [Container storage](use-cases/container-storage.md) *(advanced)* |

**Opportunity cost:** on a 14 TiB NVMe, logs should be a **slice**, not the full device.
See [large NVMe layout](#large-nvme-layout-example).

---

## Implementation patterns

Four patterns appear across use cases:

| Pattern | When | GitOps home | Rollout |
|---------|------|-------------|---------|
| **A — Ignition in `MachineConfig`** | Fixed partition/mount on homogeneous hardware | Spoke repo MC YAML | MCO drain + reboot |
| **B — Script + systemd in MC** | Variable initial disk state; conditional prep | Spoke repo MC + script | MCO drain + reboot |
| **C — Storage operator claims device** | PVCs or distributed storage | `LocalVolume`, `LVMCluster`, PX/ODF CRs | Operator-managed |
| **D — Install-time only** | etcd, root device, day-0 layout | ACM inventory / install config | Before or during install |

Patterns A and B are compared in depth for logs:

- [approach-a-ignition.yaml](../bare-metal-var-log-disk/approach-a-ignition.yaml)
- [approach-b-script-systemd.yaml](../bare-metal-var-log-disk/approach-b-script-systemd.yaml)

**Default:** preflight disk hygiene in CI → **Pattern A** for node mounts → **Pattern C** for the rest of the device.

---

## Large NVMe layout (example)

14 TiB secondary NVMe on a worker — illustrative split:

```text
nvme1n1  (14 TiB)
├── p1  256 GiB   var_log     → /var/log          Pattern A or B
└── p2  ~13.7 TiB (unallocated or data)          Pattern C
         └── Local Storage / LVMS / Portworx
```

| Slice | Rationale |
|-------|-----------|
| **p1 fixed size** | Logs capped by partition + `journald` limits |
| **Remainder for data** | Kafka, DBs, monitoring TSDB — better use of NVMe |
| **Avoid `sizeMiB: 0` on p1** | Consumes entire disk for logs |

---

## Fleet identity (`by-path`)

| Identifier | Use for fleet-wide MC? |
|------------|-------------------------|
| `wwn-…` / serial | **No** — unique per drive |
| `by-path` (bay/HBA) | **Yes** on identical chassis + cabling |
| `sdb`, `nvme1n1` | **No** — probe order varies |

Discovery (run on ≥3 workers):

```bash
oc debug node/worker-0 -- chroot /host bash -c '
  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
  ls -la /dev/disk/by-path/ | grep -v "\-fc\-"
'
```

NVMe whole-disk and partition symlinks (example):

```text
pci-0000:3d:00.0-nvme-1       →  whole disk
pci-0000:3d:00.0-nvme-1-part2 →  partition 2 (udev `-partN` suffix)
```

When you assign GPT partition names in Git, **`/dev/disk/by-partlabel/<name>`** is often clearer than `-partN` in downstream CRs (Local Storage, LVMS).

Store the chosen path in group/cluster Git values — not per-host WWN.
See [use-cases index](use-cases/README.md).

---

## GitOps shape

No standard `HardwareProfile` CRD exists.
Use **values + templates**:

```text
groups/infra-baremetal/values.yaml     # by-path, partition sizes, feature flags
clusters/<cluster>/values.yaml         # overrides
spokes/<cluster>/platform/           # rendered MachineConfigs, LocalVolume, etc.
```

Hub (ACM): inventory, `BareMetalHost`, install labels.
Spoke (Argo CD): day-2 `MachineConfig` and storage CRs.

---

## Use-case guides

| Guide | Status | Pattern |
|-------|--------|---------|
| [Use-case index](use-cases/README.md) | Index | — |
| [`/var/log` + journal](../bare-metal-var-log-disk/README.md) | **Complete** (A vs B MC) | A / B |
| [Application PV](use-cases/application-pv.md) | Draft | C |
| [CSI raw disks](use-cases/csi-raw-disks.md) | Draft | C |
| [etcd on masters](use-cases/etcd-master.md) | Draft | D |
| [Disconnected registry](use-cases/disconnected-registry.md) | Draft (links existing) | Host mount |
| [Container image store](use-cases/container-storage.md) | Draft (advanced) | A / custom |

---

## What not to do

- Put heavy PVC workloads on the OS virtual disk “temporarily”
- Use WWN in a shared `MachineConfig` across the fleet
- Give logs an entire 14 TiB partition without `journald` caps
- Run Pattern A and B mount logic for the same path on one node
- `wipeTable: true` on a data disk with existing PVCs

---

## Related reading

- [MachineConfig pools](../../notes/machine-config-pools.md)
- [SNO local storage](../sno-kvm-lab/local-storage.md) — Pattern C on a lab VM
- [Kafka + Portworx bare metal](../kafka-bare-metal-portworx/README.md)
- [Disconnected install — mirror storage](../../disconnected-install/working-guide.md)
- [Bare metal RHCOS disk wipe](../../troubleshooting/bare-metal-rhcos-disk-wipe/README.md)

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author.
See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

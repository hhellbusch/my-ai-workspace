# Use Case — CSI Storage Pools (Portworx, ODF) on Raw Disks

**Audience:** Platform engineers dedicating secondary drives to distributed storage on bare metal.

**Purpose:** Document **Pattern C** when the storage product consumes **whole block devices** — not individual mount points under `/var`.

**Status:** Draft — cross-links to existing examples; not a duplicate of vendor install guides.

**Parent:** [Secondary disk overview](../README.md)

---

## When to use

| Signal | Action |
|--------|--------|
| Fleet uses **Portworx** or **ODF** for PVCs | Give operators **raw disks** or dedicated partitions |
| 14 TiB NVMe per worker | Often **entire device** to PX pool, or p2 after log p1 |
| Rack-aware replication | Align [node labels](../../kafka-bare-metal-portworx/README.md) with storage failure domains |

---

## What operators expect

| Product | Typical input | OpenShift integration |
|---------|---------------|------------------------|
| **Portworx** | Block devices / PVG | `StorageCluster`, device specs per node |
| **ODF** | Raw OSD devices | `StorageCluster`, `DeviceSet` |

These are **not** `MachineConfig` mount problems — operators format and manage devices themselves.

**Do not** simultaneously mount the same device with Ignition **and** hand it to Portworx/ODF.

---

## Disk layout options

### Option 1 — Whole secondary NVMe to CSI

```text
OS VD (PERC)     Secondary NVMe (entire) → Portworx / ODF
```

Logs stay on OS disk or get journald limits only.

### Option 2 — Log p1 + CSI p2 (same NVMe)

```text
nvme1n1
├── p1  var_log     → MachineConfig
└── p2  data        → PX / ODF (device path …-part2)
```

Requires coordinated GitOps: log MC creates p1; storage CR references p2 `by-path`.

### Option 3 — Separate physical drives

```text
NVMe bay 1 → logs (MC)
NVMe bay 2 → CSI pool (whole disk)
```

Clearest ops model on dual-NVMe servers.

---

## Prerequisites (workspace)

- [NVMe host NQN duplicates](../../../troubleshooting/nvme-host-nqn-duplicate/README.md) — before NVMe-oF
- [NVMe/TCP storage network](../../../troubleshooting/nvme-tcp-storage-network/README.md)
- [Portworx CSI crashloop](../../../troubleshooting/portworx-csi-crashloop/README.md)
- [Kafka + Portworx example](../../kafka-bare-metal-portworx/README.md)

---

## GitOps

| Layer | Owns |
|-------|------|
| Inventory | Which bay is **log** vs **storage** per SKU |
| Spoke `platform/` | Log `MachineConfig` if applicable |
| Spoke `storage/` | Portworx/ODF CRs, device paths |

Validate `by-path` per node class before merge — same rules as [overview](../README.md#fleet-identity-by-path).

---

## Verification

```bash
oc get storagecluster -A
oc get nodes -l px/enabled=true   # example; label varies
oc debug node/worker-0 -- chroot /host lsblk
```

---

## Related

- [Application PV (Local Storage / LVMS)](application-pv.md) — node-local PVCs without PX/ODF
- [var-log](../../bare-metal-var-log-disk/README.md)

---

*Draft — refer to vendor docs for device spec details on your OCP z-stream.*

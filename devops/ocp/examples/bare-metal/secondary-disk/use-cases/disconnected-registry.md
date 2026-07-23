# Use Case — Mirror Registry on Secondary Disk (Disconnected)

**Audience:** Engineers running `mirror-registry` or Quay for disconnected OpenShift — often on a **bare-metal or RHEL host**, not always an OCP worker.

**Purpose:** Point registry **image blobs** at secondary/data mounts so `/` and Podman volumes on the OS disk do not fill.

**Status:** Draft — defers to existing phased guide.

**Parent:** [Secondary disk overview](../README.md)

---

## Problem

Default trap documented in the workspace:

> Without `--quayStorage`, blobs go to Podman volumes under `/var/lib/containers/storage/volumes/` on **`/`**.

A dedicated mount at `/quay` that is empty while `/` fills is misconfiguration — not a sizing problem on the right disk.

---

## Pattern — host-level data mount (not MachineConfig)

This use case is typically a **RHEL mirror host**, not RHCOS `MachineConfig`:

| Flag | Holds |
|------|-------|
| `--quayRoot` | Config, nginx, certs — few GiB |
| `--quayStorage` | **Image blobs** — hundreds of GiB to TB |
| `--sqliteStorage` | DB metadata |

Install example from [disconnected install guide](../../../../disconnected-install/working-guide.md):

```bash
./mirror-registry install -v \
  --quayHostname "${MIRROR_HOST}" \
  --quayRoot /data/quay/install \
  --quayStorage /data/quay/storage \
  --sqliteStorage /data/quay/sqlite
```

**fstab** the data mount — reboot breaks registry if the data LV is not mounted.

---

## Sizing (OCP 4.18-class reference)

| Content | Approx. size |
|---------|--------------|
| Platform / one z-stream | ~12 GB |
| Platform + full operator catalog | ~358 GB |
| Platform + Virt + Portworx + headroom | **400–500 GB** |
| Growth | plan **1 TB+** |

Full table: [disconnected-install/working-guide.md](../../../../disconnected-install/working-guide.md#storage-planning-mirror-registry).

---

## Relation to OCP worker secondary disks

| Host type | Mechanism |
|-----------|-----------|
| Mirror **bastion** / registry VM | LVM/fstab + `mirror-registry` flags |
| **Worker** running local registry (unusual) | Pattern A/B MC for mount + registry config |

Most fleets keep mirror registry **off** worker nodes.

---

## Verification

```bash
df -h / /data/quay
podman volume inspect quay-storage 2>/dev/null || true   # should not grow on /
```

---

## Related

- [Disconnected install working guide](../../../../disconnected-install/working-guide.md)
- [Overview](../README.md)

---

*Draft pointer — operational detail lives in disconnected-install guide.*

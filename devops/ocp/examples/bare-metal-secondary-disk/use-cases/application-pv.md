# Use Case — Application and Platform PVCs on Secondary Disk

**Audience:** Platform engineers who need local persistent volumes on bare-metal workers without consuming the OS virtual disk.

**Purpose:** Dedicate secondary disk capacity (whole device or partition p2+) to **Local Storage Operator** or **LVMS** — the highest-ROI offload for large secondary drives.

**Status:** Draft — patterns validated in SNO lab; extend to multi-node bare metal with `by-path`.

**Parent:** [Secondary disk overview](../README.md)

---

## Why this is priority #1

| Workload | Stays on OS disk if unconfigured | Belongs on secondary |
|----------|-----------------------------------|----------------------|
| Kafka, DB PVCs | Yes — risk | Secondary / CSI |
| Prometheus TSDB (local) | Yes | Secondary |
| DevSpaces / workspace PVCs | Yes | Secondary |
| EmptyDir / ephemeral | `/var/lib/kubelet` | Limits + monitoring |

Logs are tens to hundreds of GiB.
Application data is **terabytes** — the natural consumer of a 14 TiB NVMe after a log slice.

---

## Pattern C — storage operator claims device

```text
Secondary NVMe (p2 or whole disk if logs elsewhere)
    → LocalVolume / LVMCluster devicePaths: by-path
    → StorageClass (local-storage, lvms-…)
    → PVCs
```

### Local Storage (whole disk or partition)

One PV per device path — simple, static.
Lab reference: [SNO local storage](../../sno-kvm-lab/local-storage.md).

Illustrative `LocalVolume` (replace `by-path`):

```yaml
apiVersion: local.storage.openshift.io/v1
kind: LocalVolume
metadata:
  name: worker-data
  namespace: openshift-local-storage
spec:
  nodeSelector:
    nodeSelectorTerms:
      - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
              - worker-0   # or nodeSelector for all workers with this disk
  storageClassDevices:
    - devicePaths:
        - /dev/disk/by-path/pci-0000:3d:00.0-nvme-1-part2
      fsType: xfs
      storageClassName: local-storage-data
      volumeMode: Filesystem
```

**Note:** use `-part2` suffix on the NVMe `by-path` (e.g. `…-nvme-1-part2`) when p1 is the log partition from [var-log](../../bare-metal-var-log-disk/README.md), or prefer `/dev/disk/by-partlabel/<label>` if p2 has a GPT name in Git.
Verify on-node: `ls -la /dev/disk/by-path/*part2` after p1 exists.

### LVMS (preferred when catalog available)

Thin-provisioned local volumes from a device set — multiple PVCs per disk.
SNO target: [lvms.yaml](../../sno-kvm-lab/lvms.yaml), [dynamic-storage.md](../../sno-kvm-lab/dynamic-storage.md).

On bare metal, same `by-path` rules apply to `DeviceClass` / `LVMCluster` device selectors (OCP version-specific API — confirm against your z-stream docs).

---

## Layout with logs on p1

```text
nvme1n1
├── p1  256 GiB   var_log      → MachineConfig (var-log guide)
└── p2  remainder              → LocalVolume / LVMS
```

Order of rollout:

1. Apply log `MachineConfig` (p1) — or pre-create p1+p2 in one Ignition MC
2. Apply `LocalVolume` / LVMS targeting **p2 only**
3. Set default `StorageClass` or reference explicitly in platform operators (e.g. [Prometheus storage](../../../troubleshooting/prometheus-monitoring-storage/README.md))

---

## GitOps

| Artifact | Repo layer |
|----------|------------|
| `by-path` for p2 | `groups/infra-baremetal/values.yaml` |
| `LocalVolume` / LVMS CRs | Spoke `storage/` app |
| Log partition MC | Spoke `platform/` (see var-log guide) |

Do not let the OS disk remain the default SC for production bare metal.

---

## Verification

```bash
oc get localvolume -n openshift-local-storage
oc get pv
oc get storageclass
oc debug node/worker-0 -- chroot /host lsblk -o NAME,SIZE,PARTLABEL,MOUNTPOINT
```

PVC smoke test: [storage-smoke-test.yaml](../../sno-kvm-lab/storage-smoke-test.yaml).

---

## Related

- [CSI raw disks](csi-raw-disks.md) — when Portworx/ODF own whole nodes
- [var-log](../../bare-metal-var-log-disk/README.md) — p1 log slice
- [Kafka bare metal + Portworx](../../kafka-bare-metal-portworx/README.md)

---

*Draft — AI-assisted. Not end-to-end tested on multi-node bare metal in this workspace.*

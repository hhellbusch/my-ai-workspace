# Secondary Disk — Use-Case Index

Parent overview: [bare-metal/secondary-disk/README.md](../README.md)

| # | Use case | OS disk pressure | Guide | Status |
|---|----------|------------------|-------|--------|
| 1 | Node logs + journal | `/var/log`, journal growth | [**`/var/log` (full)**](../../var-log-disk/README.md) | Complete |
| 2 | Application / platform PVCs | Avoid default local PV on `/` | [application-pv.md](application-pv.md) | Draft |
| 3 | Portworx / ODF pools | N/A — dedicated tier | [csi-raw-disks.md](csi-raw-disks.md) | Draft |
| 4 | etcd (masters) | `/var/lib/etcd` I/O + size | [etcd-master.md](etcd-master.md) | Draft |
| 5 | Mirror registry blobs | `/` fill on misconfig | [disconnected-registry.md](disconnected-registry.md) | Draft |
| 6 | Container images (CRI-O) | `/var/lib/containers` | [container-storage.md](container-storage.md) | Draft |

## Shared patterns

| Topic | Where documented |
|-------|------------------|
| Ignition vs script `MachineConfig` | [var-log guide](../../var-log-disk/README.md) |
| `by-path` fleet identity | [Overview](../README.md#fleet-identity-by-path) |
| Multi-partition 14 TiB layout | [Overview](../README.md#large-nvme-layout-example) |

*AI-assisted index. See [AI-DISCLOSURE.md](../../../../../../AI-DISCLOSURE.md).*

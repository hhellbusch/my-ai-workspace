# Use Case — Container Image Store (`/var/lib/containers`)

**Audience:** Platform engineers evaluating whether to move CRI-O / Podman image layers off the OS disk.

**Purpose:** Document **Pattern A (advanced)** — highest OS disk churn on workers, hardest to relocate cleanly on RHCOS.

**Status:** Draft — exploratory; prefer sizing OS VD + image pruning before custom roots.

**Parent:** [Secondary disk overview](../README.md)

---

## Why this is listed last

| Factor | Logs on secondary | Image store on secondary |
|--------|-------------------|---------------------------|
| Size growth | Bounded with journald caps | **Unbounded** with image pulls |
| Move mechanism | Mount `/var/log` | Change **kubelet** + **CRI-O** roots |
| RHCOS support | Straightforward MC | **Sensitive** — MCO merge, upgrades |
| ROI on 14 TiB NVMe | Low — small slice | **High** — can be TiB |

---

## What consumes space

```text
/var/lib/containers/storage    # CRI-O / overlay layers
/var/lib/kubelet/...           # sandboxes, emptyDir (related, separate path)
```

Pull-heavy namespaces and `:latest` tags dominate growth.

---

## Approaches (high level)

### 1 — Operational (no disk move)

- Image pruning / `ImagePruner` / policy on `imagestream` usage
- `imagePullPolicy: IfNotPresent`
- Larger OS virtual disk in hardware profile

Lowest risk; often sufficient.

### 2 — Secondary mount for containers storage

Requires supported alignment of:

- `storage.root` / `runroot` in `/etc/containers/storage.conf` (or drop-in)
- Kubelet root if co-located
- `MachineConfig` files + possibly reboot ordering

**Validate against your exact OCP z-stream** — undocumented combinations break upgrades.

### 3 — Secondary disk for PVCs instead (recommended)

Offload **durable** data via [application PV](application-pv.md).
Keep image cache on OS disk with **size + prune**.

Often better economics than fighting CRI-O roots.

---

## If pursuing Pattern A for images

Same building blocks as [var-log](../../var-log-disk/README.md):

1. Partition secondary NVMe (dedicated slice or share with data tier)
2. Mount at e.g. `/var/lib/containers` **only** if MCO/Ignition ordering supports replacing default path
3. Prefer **Ignition** over script for long-term merge behavior
4. Test **OCP upgrade** in lab — z-stream updates re-merge Ignition

**Not documented as a copy-paste manifest here** until validated on target OCP version.

---

## 14 TiB NVMe allocation hint

If images must move:

```text
nvme1n1
├── p1  256 GiB    var_log
├── p2  1–2 TiB    containers   (if validated)
└── p3  remainder  PVC / CSI
```

Images rarely need 14 TiB unless prune is broken.

---

## Related

- [Application PV](application-pv.md)
- [var-log](../../var-log-disk/README.md)
- [Overview](../README.md)

---

*Draft — treat as research track; confirm with Red Hat support before production MC.*

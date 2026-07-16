# Use Case — `/var/log` and Journal

**Status:** Complete guide with side-by-side manifests.

This use case is documented in a dedicated example directory:

→ **[bare-metal-var-log-disk/README.md](../../bare-metal-var-log-disk/README.md)**

## Summary

| Item | Value |
|------|-------|
| **Mount** | `/var/log` (includes persistent journal) |
| **Typical slice** | 128–512 GiB on secondary NVMe (not full device) |
| **Patterns** | A — Ignition MC · B — script + systemd MC |
| **Manifests** | [approach-a-ignition.yaml](../../bare-metal-var-log-disk/approach-a-ignition.yaml) · [approach-b-script-systemd.yaml](../../bare-metal-var-log-disk/approach-b-script-systemd.yaml) |

## When this use case fits

- Workers (or masters) with chatty journal, audit, or platform logs pressuring OS `/var`
- Homogeneous hardware with stable `by-path` to secondary NVMe
- Cluster logging exists or is planned — local disk is for **node survival**, not long retention

## Pair with

After allocating a small log partition (p1), use remaining NVMe capacity for [application PV](application-pv.md) or [CSI pools](csi-raw-disks.md).

---

*Pointer doc. Full content in [bare-metal-var-log-disk](../../bare-metal-var-log-disk/README.md).*

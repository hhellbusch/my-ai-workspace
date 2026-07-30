---
review:
  status: unreviewed
  notes: "Secondary disk /var/log use case — review metadata backfill."
---

# Use Case — `/var/log` and Journal

**Status:** Complete guide with side-by-side manifests.

This use case is documented in a dedicated example directory:

→ **[bare-metal/var-log-disk/README.md](../../var-log-disk/README.md)**

## Summary

| Item | Value |
|------|-------|
| **Mount** | `/var/log` — includes `journal/`, **`pods/`**, `containers/`, audit |
| **Typical slice** | 128–512 GiB on secondary NVMe, or **whole smaller NVMe** when multiple bays |
| **Patterns** | A — Ignition MC · B — script + systemd MC |
| **Manifests** | [approach-a-ignition.yaml](../../var-log-disk/approach-a-ignition.yaml) · [approach-b-script-systemd.yaml](../../var-log-disk/approach-b-script-systemd.yaml) |

## When this use case fits

- Workers (or masters) with chatty journal, audit, or **container logs** pressuring OS `/var`
- Homogeneous hardware with stable `by-path` to secondary NVMe (one path per bay)
- Cluster logging exists or is planned — local disk is for **node survival**, not long retention

## Pair with

- **One large NVMe:** log p1, then [application PV](application-pv.md) on p2+
- **Multiple NVMe:** whole log drive at `/var/log`, data bay(s) for [application PV](application-pv.md) or [CSI pools](csi-raw-disks.md)

Pitfalls (nested `pods/` mount, wrong bay, CSI conflict): [var-log guide § Pitfalls](../../var-log-disk/README.md#pitfalls).

---

*Pointer doc. Full content in [bare-metal/var-log-disk](../../var-log-disk/README.md).*

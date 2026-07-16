# Use Case — etcd on a Dedicated Master Disk

**Audience:** Platform engineers sizing control-plane storage on bare-metal masters.

**Purpose:** Outline **Pattern D** (install-time) for isolating `/var/lib/etcd` from the OS virtual disk — latency and I/O isolation, not capacity at 14 TiB scale.

**Status:** Draft — etcd layout is tightly coupled to install method; validate against your OCP version and ACM agent install docs.

**Parent:** [Secondary disk overview](../README.md)

---

## Why masters differ from workers

| Concern | Workers | Masters |
|---------|---------|---------|
| Primary disk pressure | Images, kubelet, logs | **etcd** + images + logs |
| Secondary disk size | Terabytes common | Often smaller fast NVMe |
| Offload priority | PVCs + logs | **etcd I/O** > log slice |

etcd is **latency-sensitive**.
A small fast NVMe for etcd can matter more than capacity.

---

## Pattern D — install-time layout

etcd data path is established at **install**, not casually moved day-2.

Typical paths:

| Install method | Where disk layout is declared |
|----------------|------------------------------|
| **ACM agent / assisted** | Host inventory, `Agent` / install overrides, extra manifests |
| **IPI bare metal (Metal3)** | `BareMetalHost` `rootDeviceHints`, RAID, userData |
| **Day-2 only** | **Not recommended** for etcd migration |

OpenShift 4.x runs etcd as static pods with data under `/var/lib/etcd` on masters.
Splitting that to another mount generally requires **initial Ignition** that matches Red Hat supported partitioning for control plane nodes.

---

## Design questions (answer before implementing)

1. Is the etcd disk **separate physical device** or a **PERC VD**?
2. Does Red Hat support matrix allow custom master partitioning for your platform?
3. Is etcd on **NVMe** while OS stays on BOSS/VD?
4. What happens on **single-disk master** failure vs etcd disk failure?

---

## Sizing (not 14 TiB)

| Resource | Typical need |
|----------|--------------|
| etcd data | Grows with cluster churn — monitor `du -sh /var/lib/etcd` |
| Disk size | Often **100–500 GiB** fast media is plenty |
| IOPS / latency | More important than TB |

See [API slowness — etcd size](../../../troubleshooting/api-slowness-web-console/README.md).

---

## Logs on masters

Same [var-log](../../bare-metal-var-log-disk/README.md) patterns apply with `machineconfiguration.openshift.io/role: master`.

etcd and logs are **different devices** in the ideal layout:

```text
BOSS / OS VD          Fast NVMe #1        Optional NVMe #2
────────────          ───────────        ────────────────
/sysroot              etcd (install)     /var/log (MC day-2)
```

---

## GitOps

- etcd disk: **hub install inventory** + install manifests
- `/var/log` on masters: spoke `MachineConfig` (same as workers, `role: master`)

---

## Related

- [Overview](../README.md)
- [Bare metal install examples](../../ovn-kubernetes-install-config/EXAMPLES.md) — `rootDeviceHints`
- [RHACM BMO integration](../../../../rhacm/examples/BARE-METAL-OPERATOR-INTEGRATION.md)

---

*Draft — confirm against current Red Hat bare-metal day-0 partitioning guidance before production.*

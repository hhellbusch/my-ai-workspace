---
review:
  status: unreviewed
  notes: "Topic index — bare-metal OpenShift examples."
---

# Bare Metal — OpenShift Examples

Runnable guides for **bare-metal worker and control-plane nodes**: moving data off the OS disk, fleet disk identity, and layouts that pair with Portworx or local PV patterns.

**Cluster-side troubleshooting** (symptoms): [stale node IP](../../troubleshooting/bare-metal-stale-node-ip-conflict/README.md), [RHCOS disk wipe](../../troubleshooting/bare-metal-rhcos-disk-wipe/README.md), [inspection timeout](../../troubleshooting/bare-metal-node-inspection-timeout/README.md), [worker TLS](../../troubleshooting/worker-node-tls-cert-failure/README.md).

**Hub / ACM provisioning** (firewall, CIM, destroy): [RHACM bare-metal network requirements](../../../rhacm/notes/acm-bare-metal-network-requirements.md), [bare-metal cluster destroy](../../../rhacm/notes/bare-metal-cluster-destroy.md).

## Examples

| Guide | Summary |
|-------|---------|
| [secondary-disk/](secondary-disk/README.md) | What to move off the OS disk; patterns A–D; use-case index |
| [var-log-disk/](var-log-disk/README.md) | Complete `/var/log` + journal on secondary NVMe (Ignition vs script MC) |

## Related workloads

- [Kafka + Portworx](../messaging/kafka/bare-metal-portworx/README.md) — rack-aware brokers on labeled workers
- [NVMe host NQN](../../troubleshooting/nvme-host-nqn-duplicate/README.md) — prerequisite for NVMe-oF to FlashArray
- [NVMe/TCP storage network](../../troubleshooting/nvme-tcp-storage-network/README.md) — dual-NIC storage VLAN

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

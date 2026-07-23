# Quick Reference: NVMe/TCP Storage Network

Dual-NIC storage fabric prep on bare-metal OCP before CSI install.

## Decision Tree

```
NVMe/TCP to external array on bare-metal workers?
│
├─ Step 1: Unique host NQN per node?
│  └─ no → ../nvme-host-nqn-duplicate/ first
│
├─ Two dedicated storage NICs cabled to two switches?
│  └─ no → fix cabling/fabric before CSI
│
├─ Bonding storage NICs (LACP)?
│  └─ yes → undo; use independent interfaces + native NVMe multipath
│
├─ Each storage NIC: static IP, no default gateway, MTU matches fabric?
│  └─ no → NMState NNCP or install-time static config
│
├─ nvme_core.multipath = Y ?
│  └─ no → modprobe drop-in + reboot (see README)
│
└─ Install CSI → verify nvme list-subsys shows multiple paths
```

---

## Topology cheat sheet

| Do | Don't |
|----|-------|
| 2 storage NICs → 2 switches → dual array controllers | Single switch for all storage paths |
| Static IP per storage NIC | Default route on storage interfaces |
| MTU 9000 end-to-end (if supported) | Mixed MTU host vs switch vs array |
| Native NVMe multipath | `dm-multipath` for NVMe/TCP |
| Bond front-end/mgmt if needed | Bond storage NICs (802.3ad) for NVMe/TCP |

---

## Verify on node

```bash
# Storage interfaces
ip -br addr show

# No storage iface as default route
ip route show default

# Jumbo MTU (if used)
ip link show ens1f0 | grep mtu

# Native multipath
cat /sys/module/nvme_core/parameters/multipath

# NQN (prerequisite)
cat /etc/nvme/hostnqn
nvme gen-hostnqn   # should match file after NQN fix
```

Same-subnet dual-NIC — may need:

```bash
sysctl net.ipv4.conf.all.arp_ignore net.ipv4.conf.all.arp_announce
# expect 2 and 2
```

---

## NMState

```bash
oc get nncp,nns
oc describe nncp <policy-name>
```

Example policy skeleton: [example-nncp-storage-interfaces.yaml](example-nncp-storage-interfaces.yaml)

---

## Prep order

1. [NVMe host NQN](../nvme-host-nqn-duplicate/QUICK-REFERENCE.md)
2. **This guide** — storage network + multipath
3. Vendor CSI install
4. [Portworx CSI crashloop](../portworx-csi-crashloop/README.md) if needed

---

## Related

- [Full guide](README.md)
- [Index](INDEX.md)

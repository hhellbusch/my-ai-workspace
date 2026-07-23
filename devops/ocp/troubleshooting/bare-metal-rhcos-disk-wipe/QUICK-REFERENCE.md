# Quick Reference: Bare Metal RHCOS Disk Wipe

Wipe OpenShift/RHCOS state from retired bare-metal hardware before reuse or storage.

## Decision Tree

```
Retiring bare-metal OpenShift hardware?
│
├─ Confirm target (BMC serial — NOT IP)
│
├─ API reachable?
│  ├─ yes → oc delete node + baremetalhost
│  └─ no → isolate; wipe; delete objects later
│
├─ Wipe all disks
│  ├─ SSH → wipefs + sgdisk + dd loop
│  ├─ no SSH → BMC virtual media live ISO
│  └─ Dell PERC → iDRAC storage erase
│
└─ BMC: power off, AC Stay Off, bootdev none, disable switch port
```

---

## 1. Confirm serial (before wipe)

```bash
# BMC inventory — preferred
# Or SSH:
hostname
sudo dmidecode -s system-serial-number
sudo cat /etc/machine-id
```

---

## 2. Remove cluster objects

```bash
oc delete node <node-name>
oc delete baremetalhost <bmh-name> -n openshift-machine-api
```

Add `--insecure-skip-tls-verify` if API TLS is broken.

---

## 3. Wipe all disks

```bash
lsblk

for d in $(lsblk -dpno NAME | grep -E '^/dev/sd|^/dev/nvme'); do
  echo "Wiping $d"
  sudo wipefs -a "$d"
  sudo sgdisk --zap-all "$d" 2>/dev/null || true
  sudo dd if=/dev/zero of="$d" bs=1M count=100 status=progress
done
```

No SSH? Boot BMC virtual media live ISO and run the same loop.

Dell PERC: iDRAC → Storage → secure erase / delete virtual disks.

---

## 4. Lock down BMC

```bash
ipmitool -I lanplus -H <bmc-ip> -U <user> -P '<pass>' power off
ipmitool -I lanplus -H <bmc-ip> -U <user> -P '<pass>' chassis bootdev none
```

AC power recovery → **Stay Off**. Disable switch port.

---

## Why shutdown is not enough

| On disk | Risk if not wiped |
|---------|-------------------|
| Ignition / ostree | Boots back into old cluster identity |
| etcd (masters) | Stale control-plane member on power-on |
| BareMetalHost exists | Metal3 may reprovision on PXE |

---

Full guide: [README.md](README.md) · Navigation: [INDEX.md](INDEX.md)

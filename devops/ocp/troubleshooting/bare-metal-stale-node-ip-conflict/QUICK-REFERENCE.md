# Quick Reference: Bare Metal Stale Node IP Conflict

Fast triage and decommission commands when retired hardware fights new nodes for the same IP.

## Decision Tree

```
API / SSH / console flaky after hardware swap?
│
├─ ARP/MAC check (10 pings)
│  ├─ MAC changes for same IP → THIS GUIDE (IP conflict)
│  └─ MAC stable → not IP conflict
│        ├─ consistent TLS unknown authority → API cert deadlock guide
│        └─ connection refused / timeout → network or apiserver down
│
├─ Identify hardware (BMC serial — not IP)
│  ├─ stale serial → isolate + wipe
│  └─ current serial → keep; find other chassis on same IP
│
├─ Isolate stale nodes
│  ├─ BMC power off
│  ├─ switch port disable / quarantine VLAN
│  └─ AC recovery = Stay Off
│
├─ API reachable?
│  ├─ yes → oc delete node + baremetalhost (stale)
│  └─ no → physical isolation first
│
├─ Wipe all disks on stale hardware only
│  └─ wipefs + sgdisk --zap-all + dd (or iDRAC storage erase)
│
└─ Power on CURRENT hardware only → re-check ARP + openssl issuer
   └─ TLS still wrong? → apiserver-cert-deadlock guide
```

---

## 0. Confirm IP conflict

```bash
TARGET_IP=<master-ip-or-api-vip>

for i in {1..10}; do
  ping -c1 -W1 "$TARGET_IP" >/dev/null 2>&1
  ip neigh show "$TARGET_IP"
  sleep 2
done
```

| Result | Meaning |
|--------|---------|
| Different MAC across iterations | Duplicate host — stale hardware likely powered on |
| Same MAC every time | Not MAC flapping; investigate cert or service health |
| `openssl s_client` issuer changes between runs | Strong signal of hitting two different apiservers |

```bash
for i in 1 2 3; do
  echo "=== run $i ==="
  echo | openssl s_client -connect api.<cluster-domain>:6443 \
    -servername api.<cluster-domain> 2>/dev/null | openssl x509 -noout -issuer -subject
done
```

---

## 1. Identify host (SSH or BMC)

```bash
hostname
sudo dmidecode -s system-serial-number
sudo cat /etc/machine-id
ip addr show
```

Match serial to inventory **before** any destructive action.

---

## 2. Isolate stale hardware

```bash
# IPMI power off
ipmitool -I lanplus -H <bmc-ip> -U <user> -P '<pass>' power off

# Optional: block PXE boot
ipmitool -I lanplus -H <bmc-ip> -U <user> -P '<pass>' chassis bootdev none
```

Also: disable switch port; iDRAC AC power recovery → **Stay Off**.

---

## 3. Remove from cluster (if API works)

```bash
oc get nodes -o wide
oc get baremetalhost -n openshift-machine-api

oc delete node <stale-node-name>
oc delete baremetalhost <stale-bmh-name> -n openshift-machine-api
```

Emergency API access during cert incidents: add `--insecure-skip-tls-verify`.

---

## 4. Wipe disks (stale hardware only)

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

## 5. Verify recovery

```bash
# One MAC per IP
for i in {1..5}; do ping -c1 -W1 <master-ip>; ip neigh show <master-ip>; done

# Consistent API cert
curl -k https://api.<cluster-domain>:6443/healthz

# On current master
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get nodes -o wide
```

---

## Error → Likely cause

| What you see | Likely cause | First action |
|--------------|--------------|--------------|
| API works sometimes, MAC flips | Stale node same IP | Power off stale BMC |
| `unknown authority` + issuer changes | Two apiservers / two clusters | Isolate stale hardware before cert work |
| SSH to "master" wrong serial | IP conflict | Use BMC serial; disable stale port |
| Node returns after "shutdown" | Disk not wiped | wipefs all disks on stale host |
| Old host reprovisions on PXE | BMH still exists | `oc delete baremetalhost` |

---

Full guide: [README.md](README.md) · Navigation: [INDEX.md](INDEX.md)

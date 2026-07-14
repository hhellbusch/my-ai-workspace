# Bare Metal Stale Node IP Conflict

## Overview

During bare-metal OpenShift lifecycle changes — hardware replacement, control-plane swap, lab reuse, or rack moves — **old servers can remain powered on with the same IP addresses** later assigned to new nodes. Two physical hosts answering for one IP causes ARP/MAC flapping, intermittent API and SSH failures, and TLS errors that look like certificate problems.

This guide helps you **confirm an IP conflict**, **isolate stale hardware**, and **remove stale cluster membership**. Wipe disks on retired hardware per [Bare Metal RHCOS Disk Wipe](../bare-metal-rhcos-disk-wipe/README.md).

## Symptoms

- API or web console intermittently unreachable from the bastion; works from some nodes but not others
- `oc` errors vary between attempts: `timeout`, `connection refused`, `x509: certificate signed by unknown authority`
- `curl -k https://api.<cluster-domain>:6443/healthz` sometimes `ok`, sometimes fails
- `openssl s_client` against the API shows **different issuers or subjects** on repeated tries
- SSH to a control-plane IP succeeds sometimes and fails other times; hostname or serial does not match inventory
- Switch logs report **MAC flapping** on ports tied to cluster IPs or the API VIP
- Console, OAuth, and ingress operators degraded — often downstream of unstable API reachability

**Do not assume a cert rollout failure until IP stability is confirmed.** A client hitting two different apiservers can produce `unknown authority` even when the live cluster's certificates are fine.

---

## Triage: IP Conflict vs Certificate vs Network Down

| Check | IP conflict | Cert deadlock | True outage |
|-------|-------------|---------------|-------------|
| `ip neigh` / ARP for master IP or API VIP | MAC address **changes** between pings | Stable MAC | No ARP entry or host down |
| `curl -k .../healthz` repeated | Intermittent ok / fail | Usually consistent | Consistent fail |
| `openssl s_client` issuer repeated | **Changes** between attempts | Same wrong issuer every time | No TLS handshake |
| BMC power off suspect old host | Symptoms **stop** | Unchanged | Unchanged |

Confirm MAC flapping from bastion or a worker:

```bash
TARGET_IP=<master-ip-or-api-vip>

for i in {1..10}; do
  ping -c1 -W1 "$TARGET_IP" >/dev/null 2>&1
  ip neigh show "$TARGET_IP"
  sleep 2
done
```

Different link-layer (MAC) addresses for the same IP across iterations strongly indicates duplicate hosts.

> **Not this guide:** MCS/ignition TLS on port 22623 during worker provisioning — see [Worker Node TLS Certificate Failure](../worker-node-tls-cert-failure/README.md). Persistent TLS to a **stable** API endpoint — see [API Server Certificate Deadlock](../apiserver-cert-deadlock/README.md).

---

## Prerequisites

- BMC (iDRAC, ILO, Redfish) access to **old and new** hardware — serial numbers are the source of truth, not IP or hostname
- Inventory mapping: which physical server is **current** vs **retired**
- SSH install key (optional — to confirm serial via SSH on a reachable host)
- Optional: `oc` access to remove stale `Node` / `BareMetalHost` objects

---

## Step 1: Identify Old vs New Hardware

**Never decommission by IP alone.** Two machines may have fought for the same address.

### Via BMC

Record system serial for every server that ever held a control-plane or API VIP address:

| BMC address | Serial | Intended role | Status |
|-------------|--------|---------------|--------|
| `<bmc-ip>` | `…` | current master | keep |
| `<bmc-ip>` | `…` | retired master | isolate + wipe |

### Via SSH (when reachable)

```bash
hostname
sudo dmidecode -s system-serial-number 2>/dev/null
sudo cat /etc/machine-id
ip addr show
sudo grep server /etc/kubernetes/kubeconfig 2>/dev/null
```

Compare serial to inventory. If serial matches a **retired** asset, treat the host as stale regardless of hostname.

---

## Step 2: Isolate Stale Nodes Immediately

Stop L2/L3 contention before disk wipe or cert work.

### Power off via BMC

```bash
# IPMI example
ipmitool -I lanplus -H <bmc-ip> -U <user> -P '<pass>' power off

# Redfish example
curl -k -u "<user>:<pass>" -X POST \
  "https://<bmc-ip>/redfish/v1/Systems/System.Embedded.1/Actions/ComputerSystem.Reset" \
  -H "Content-Type: application/json" \
  -d '{"ResetType": "ForceOff"}'
```

### Network isolation

- Disable switch ports for retired chassis, **or**
- Move retired NICs to a quarantine VLAN with no route to cluster networks

### BMC policy (prevent accidental return)

- **AC power recovery:** Stay Off (not "last state" or "on")
- **Boot order:** disable PXE-first / network boot for retired assets
- Document asset tag: `RETIRED — do not power on`

```bash
# Discourage network boot via IPMI (vendor support varies)
ipmitool -I lanplus -H <bmc-ip> -U <user> -P '<pass>' chassis bootdev none
```

Re-run the ARP loop from [Triage](#triage-ip-conflict-vs-certificate-vs-network-down). One stable MAC per IP before continuing.

---

## Step 3: Remove Stale Objects from the Cluster

If the API is reachable (including `oc --insecure-skip-tls-verify` during cert incidents):

```bash
oc get nodes -o wide
oc get baremetalhost -n openshift-machine-api -o wide
oc get machines -n openshift-machine-api

# Replace with stale host identifiers (name or serial in BMH status)
oc delete node <stale-node-name>
oc delete baremetalhost <stale-bmh-name> -n openshift-machine-api
oc delete machine <stale-machine-name> -n openshift-machine-api  # if it remains
```

Deleting the **BareMetalHost** prevents Metal3/Ironic from reprovisioning the old server on next PXE boot.

If the API is unavailable, complete physical isolation first; reconcile API objects after the live control plane is stable.

---

## Step 4: Wipe Disks on Retired Hardware

Shutdown alone is **not** sufficient — stale RHCOS can return on power-on. After isolation and cluster object removal, wipe all disks on **retired** serials only.

See **[Bare Metal RHCOS Disk Wipe](../bare-metal-rhcos-disk-wipe/README.md)** for serial confirmation, wipe methods (SSH, BMC live ISO, iDRAC/PERC), and BMC lock-down.

---

## Step 5: Bring Up Current Hardware Only

1. Confirm retired chassis: powered off, disks wiped, ports disabled.
2. Power on **new** control-plane nodes one at a time; verify serial via BMC matches inventory.
3. Re-run stability checks:

```bash
# Stable MAC
for i in {1..5}; do ping -c1 -W1 <master-ip>; ip neigh show <master-ip>; done

# Consistent API cert (issuer should not change)
for i in {1..3}; do
  echo | openssl s_client -connect api.<cluster-domain>:6443 \
    -servername api.<cluster-domain> 2>/dev/null \
    | openssl x509 -noout -issuer
done

curl -k https://api.<cluster-domain>:6443/healthz
```

4. If TLS errors persist with **stable** ARP and **consistent** `openssl` output, proceed to [API Server Certificate Deadlock](../apiserver-cert-deadlock/README.md).

On a current control-plane node:

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get nodes -o wide
oc get co etcd kube-apiserver
```

Unexpected extra nodes in `oc get nodes` may indicate stale members still registered — delete them in Step 3.

---

## Quick Reference: Order of Operations

| Situation | Action |
|-----------|--------|
| Intermittent API + changing MAC | Power off stale hardware → isolate network → verify ARP |
| Stale host identified | BMC off → delete Node/BMH → [wipe disks](../bare-metal-rhcos-disk-wipe/README.md) |
| API TLS errors after ARP stable | [API Server Certificate Deadlock](../apiserver-cert-deadlock/README.md) |
| Full cluster teardown + reuse | [Destroy Cluster Without Metadata](../destroy-cluster-without-metadata/BAREMETAL-GUIDE.md) |
| Cannot reach API at all | Physical isolation first; localhost kubeconfig on **current** master — [Control Plane Kubeconfigs](../control-plane-kubeconfigs/README.md) |

---

## Prevention

- **Inventory:** bind BMC serial to role; never reuse IPs without retiring old chassis in writing.
- **Decommission checklist:** power off → delete BMH → [wipe disks](../bare-metal-rhcos-disk-wipe/README.md) → disable switch port → AC Stay Off.
- **DHCP/DNS:** remove or quarantine reservations for retired MAC addresses.
- **Metal3:** keep `BareMetalHost` count aligned with physical machines in service.
- **Monitoring:** alert on MAC flapping and duplicate ARP for API VIP and master IPs.

---

## See Also

- [Quick Reference](QUICK-REFERENCE.md) – Decision tree and copy-paste commands
- [Index](INDEX.md) – Navigate by symptom or task
- [Bare Metal RHCOS Disk Wipe](../bare-metal-rhcos-disk-wipe/README.md) – Wipe retired hardware after isolation
- [API Server Certificate Deadlock](../apiserver-cert-deadlock/README.md) – After IP stability is confirmed
- [Control Plane Kubeconfigs](../control-plane-kubeconfigs/README.md) – localhost kubeconfig on current masters
- [Destroy Cluster Without Metadata — Bare Metal](../destroy-cluster-without-metadata/BAREMETAL-GUIDE.md) – Full cluster teardown
- [Bare Metal Node Inspection Timeout](../bare-metal-node-inspection-timeout/README.md) – Provisioning-phase issues on active hosts
- [Worker Node TLS Certificate Failure](../worker-node-tls-cert-failure/README.md) – MCS :22623 TLS (different scope)

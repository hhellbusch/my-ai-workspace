# Real-World Examples - CoreOS Network Issues

This document shows real output from various network failure scenarios to help you identify your specific problem.

## Table of Contents

1. [Healthy System (For Reference)](#healthy-system)
2. [Scenario 1: DHCP Not Working](#scenario-1-dhcp-not-working)
3. [Scenario 2: No Physical Link](#scenario-2-no-physical-link)
4. [Scenario 3: Wrong Static Configuration](#scenario-3-wrong-static-configuration)
5. [Scenario 4: DNS Not Working](#scenario-4-dns-not-working)
6. [Scenario 5: NetworkManager Not Running](#scenario-5-networkmanager-not-running)
7. [Scenario 6: Missing Default Gateway](#scenario-6-missing-default-gateway)

---

## Healthy System

### What a working system looks like:

```bash
$ systemctl is-active NetworkManager
active

$ ip link show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff

$ ip addr show ens3
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.100/24 brd 192.168.122.255 scope global dynamic noprefixroute ens3
       valid_lft 3421sec preferred_lft 3421sec
    inet6 fe80::5054:ff:fe12:3456/64 scope link 
       valid_lft forever preferred_lft forever

$ ip route show
default via 192.168.122.1 dev ens3 proto dhcp metric 100 
192.168.122.0/24 dev ens3 proto kernel scope link src 192.168.122.100 metric 100

$ nmcli device status
DEVICE  TYPE      STATE      CONNECTION         
ens3    ethernet  connected  Wired connection 1 
lo      loopback  unmanaged  --                 

$ ping -c 2 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=8.24 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=117 time=7.89 ms

--- 8.8.8.8 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 7.890/8.065/8.240/0.175 ms

$ nslookup google.com
Server:		192.168.122.1
Address:	192.168.122.1#53

Non-authoritative answer:
Name:	google.com
Address: 172.217.164.46
```

**Key indicators of healthy system:**
- NetworkManager is `active`
- Interface shows `state UP` and `LOWER_UP`
- Has valid IP address (not 169.254.x.x)
- Has default route
- Device is `connected` in nmcli
- Can ping external IPs
- DNS resolution works

---

## Scenario 1: DHCP Not Working

### Symptoms
- Interface is UP but has no IP or link-local only
- No default gateway
- Can't reach anything

### Example Output

```bash
$ systemctl is-active NetworkManager
active

$ ip addr show ens3
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
    inet 169.254.123.45/16 brd 169.254.255.255 scope link noprefixroute ens3
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe12:3456/64 scope link 
       valid_lft forever preferred_lft forever

$ ip route show
169.254.0.0/16 dev ens3 proto kernel scope link src 169.254.123.45 metric 100

$ nmcli device status
DEVICE  TYPE      STATE         CONNECTION         
ens3    ethernet  connected     Wired connection 1 
lo      loopback  unmanaged     --                 

$ journalctl -u NetworkManager | grep -i dhcp | tail -5
Dec 09 10:15:23 coreos NetworkManager[1234]: <info>  [1234567890.1234] dhcp4 (ens3): activation: beginning transaction (timeout in 45 seconds)
Dec 09 10:16:08 coreos NetworkManager[1234]: <warn>  [1234567935.5678] dhcp4 (ens3): request timed out
Dec 09 10:16:08 coreos NetworkManager[1234]: <info>  [1234567935.5679] dhcp4 (ens3): state changed unknown -> timeout
Dec 09 10:16:08 coreos NetworkManager[1234]: <info>  [1234567935.5680] dhcp4 (ens3): canceled DHCP transaction
Dec 09 10:16:08 coreos NetworkManager[1234]: <info>  [1234567935.5681] dhcp4 (ens3): state changed timeout -> done
```

**Key indicators:**
- IP address is `169.254.x.x` (link-local fallback)
- No default route
- Logs show "request timed out" or "canceled DHCP transaction"
- No DHCP server responding

### Root Causes
1. No DHCP server on network
2. DHCP server not responding to this MAC address
3. Network switch blocking DHCP traffic
4. VLAN misconfiguration
5. Firewall blocking DHCP (ports 67/68)

### Fix
```bash
# Verify DHCP is configured
nmcli connection show "Wired connection 1" | grep ipv4.method
# Should show: ipv4.method: auto

# Force DHCP retry
nmcli connection down "Wired connection 1"
nmcli connection up "Wired connection 1"

# If still failing, check logs in real-time
journalctl -u NetworkManager -f

# If DHCP is unavailable, use static IP
nmcli connection modify "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 192.168.1.100/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "8.8.8.8"
nmcli connection up "Wired connection 1"
```

---

## Scenario 2: No Physical Link

### Symptoms
- Interface exists but shows NO-CARRIER
- Can't do anything network-related

### Example Output

```bash
$ ip link show ens3
2: ens3: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN mode DEFAULT group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff

$ cat /sys/class/net/ens3/carrier
0

$ cat /sys/class/net/ens3/operstate
down

$ nmcli device status
DEVICE  TYPE      STATE         CONNECTION         
ens3    ethernet  unavailable   --                 
lo      loopback  unmanaged     --                 

$ ip addr show ens3
2: ens3: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc fq_codel state DOWN group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
```

**Key indicators:**
- `NO-CARRIER` flag in interface status
- `state DOWN`
- carrier file shows `0`
- operstate shows `down`
- nmcli shows device as `unavailable`
- No IP address assigned

### Root Causes
1. **VM Environment:** Network adapter not connected in hypervisor
2. **Bare Metal:** Cable unplugged or bad cable
3. **Switch Issue:** Port disabled or wrong VLAN
4. **Driver Issue:** Network card not properly initialized

### Fix by Environment

**VMware ESXi/vSphere:**
```bash
# From ESXi host or vCenter:
# 1. Select VM → Edit Settings
# 2. Find Network Adapter
# 3. Ensure "Connected" checkbox is checked
# 4. Ensure "Connect At Power On" is checked
# 5. OK and check again from console
```

**KVM/libvirt:**
```bash
# From hypervisor host:
virsh list --all
virsh dominfo <vm-name>

# Check network definition
virsh domiflist <vm-name>

# If needed, attach network
virsh attach-interface <vm-name> network default --model virtio --config --live

# Or edit domain XML
virsh edit <vm-name>
# Ensure <interface> section is present and correct
```

**VirtualBox:**
```bash
# From VirtualBox host:
VBoxManage showvminfo <vm-name> | grep NIC

# Enable network adapter
VBoxManage modifyvm <vm-name> --cableconnected1 on

# Or via GUI: Settings → Network → Adapter 1 → Enable Network Adapter
```

**Bare Metal:**
```bash
# Check if link comes up when you replug cable
# Watch this while plugging/unplugging:
watch -n 0.5 'cat /sys/class/net/ens3/carrier 2>/dev/null || echo "no carrier"'

# Check dmesg for driver issues
dmesg | grep -i ens3
dmesg | grep -i eth
dmesg | grep -i network

# List PCI network devices
lspci | grep -i ethernet
lspci | grep -i network

# Check driver info
ethtool -i ens3
```

---

## Scenario 3: Wrong Static Configuration

### Symptoms
- Has IP but can't reach network
- Wrong subnet or gateway

### Example Output

```bash
$ ip addr show ens3
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.100/24 brd 10.0.0.255 scope global noprefixroute ens3
       valid_lft forever preferred_lft forever

$ ip route show
10.0.0.0/24 dev ens3 proto kernel scope link src 10.0.0.100 metric 100 
default via 10.0.0.1 dev ens3 proto static metric 100

$ ping -c 2 10.0.0.1
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
From 10.0.0.100 icmp_seq=1 Destination Host Unreachable
From 10.0.0.100 icmp_seq=2 Destination Host Unreachable

--- 10.0.0.1 ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1023ms

$ ip neigh show
# Empty or no entry for 10.0.0.1

$ nmcli connection show "Wired connection 1" | grep ipv4
ipv4.method:                            manual
ipv4.dns:                               8.8.8.8
ipv4.addresses:                         10.0.0.100/24
ipv4.gateway:                           10.0.0.1
```

**Key indicators:**
- Has IP address
- Has default route
- But can't reach gateway (Destination Host Unreachable)
- No ARP entry for gateway
- Indicates wrong subnet or gateway IP

### Root Causes
1. Wrong IP address for network
2. Wrong subnet mask
3. Wrong gateway IP
4. On different VLAN than configured
5. Network actually uses different subnet

### Fix
```bash
# First, determine correct network settings
# Option 1: Ask network admin
# Option 2: Try DHCP to see what it gives
nmcli connection modify "Wired connection 1" ipv4.method auto
nmcli connection up "Wired connection 1"
# Wait a moment, then check what DHCP provided:
ip addr show ens3
ip route show

# Once you know correct settings, apply them
nmcli connection modify "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 192.168.122.100/24 \
  ipv4.gateway 192.168.122.1 \
  ipv4.dns "192.168.122.1 8.8.8.8"
nmcli connection up "Wired connection 1"

# Verify
ping -c 3 192.168.122.1
ping -c 3 8.8.8.8
```

---

## Scenario 4: DNS Not Working

### Symptoms
- Can ping IPs but can't resolve hostnames
- Network works except DNS

### Example Output

```bash
$ ping -c 2 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=8.45 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=117 time=8.12 ms

--- 8.8.8.8 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms

$ ping google.com
ping: google.com: Temporary failure in name resolution

$ cat /etc/resolv.conf
# This file is managed by man:systemd-resolved(8). Do not edit.
#
# (empty or wrong nameserver)

$ nslookup google.com
;; connection timed out; no servers could be reached

$ nslookup google.com 8.8.8.8
Server:		8.8.8.8
Address:	8.8.8.8#53

Non-authoritative answer:
Name:	google.com
Address: 172.217.164.46

$ nmcli connection show "Wired connection 1" | grep dns
ipv4.dns:                               --
ipv4.dns-search:                        --
ipv4.dns-options:                       --
```

**Key indicators:**
- Can ping external IPs (like 8.8.8.8)
- Cannot ping hostnames
- "Temporary failure in name resolution"
- Empty or wrong DNS servers in resolv.conf
- DNS query to 8.8.8.8 directly works
- No DNS configured in NetworkManager connection

### Root Causes
1. No DNS servers configured
2. DNS servers unreachable
3. DNS servers wrong or not responding
4. Firewall blocking DNS (port 53)

### Fix
```bash
# Add DNS servers
nmcli connection modify "Wired connection 1" \
  ipv4.dns "8.8.8.8 1.1.1.1"
nmcli connection up "Wired connection 1"

# Verify resolv.conf updated
cat /etc/resolv.conf
# Should now show:
# nameserver 8.8.8.8
# nameserver 1.1.1.1

# Test
nslookup google.com
ping google.com
```

---

## Scenario 5: NetworkManager Not Running

### Symptoms
- Interface exists but nothing is configured
- No connections in nmcli

### Example Output

```bash
$ systemctl status NetworkManager
○ NetworkManager.service - Network Manager
     Loaded: loaded (/usr/lib/systemd/system/NetworkManager.service; enabled; preset: enabled)
     Active: inactive (dead)

$ systemctl is-active NetworkManager
inactive

$ nmcli device status
Error: NetworkManager is not running.

$ ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff

$ ip link show ens3
2: ens3: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
```

**Key indicators:**
- NetworkManager is `inactive (dead)`
- nmcli commands fail with "NetworkManager is not running"
- Interfaces are DOWN and have no IP
- state shows `DOWN` not `UP`

### Root Causes
1. NetworkManager service stopped/crashed
2. Service disabled
3. System boot issue

### Fix
```bash
# Start NetworkManager
systemctl start NetworkManager

# Ensure it's enabled
systemctl enable NetworkManager

# Check status
systemctl status NetworkManager

# Check logs for why it stopped
journalctl -u NetworkManager -n 50

# After starting, interfaces should come up automatically
# Wait 10 seconds then check:
sleep 10
ip addr show
nmcli device status

# If needed, manually bring up connection
nmcli connection up "Wired connection 1"
```

---

## Scenario 6: Missing Default Gateway

### Symptoms
- Has IP address
- Can ping devices on local network
- Cannot reach internet

### Example Output

```bash
$ ip addr show ens3
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:12:34:56 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.100/24 brd 192.168.1.255 scope global noprefixroute ens3
       valid_lft forever preferred_lft forever

$ ip route show
192.168.1.0/24 dev ens3 proto kernel scope link src 192.168.1.100 metric 100

$ ping -c 2 192.168.1.1
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=64 time=0.234 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=64 time=0.198 ms

--- 192.168.1.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms

$ ping -c 2 8.8.8.8
connect: Network is unreachable

$ nmcli connection show "Wired connection 1" | grep gateway
ipv4.gateway:                           --
```

**Key indicators:**
- Has IP address
- Can ping local devices
- No `default via` line in route table
- "Network is unreachable" when pinging external IPs
- No gateway configured in NetworkManager

### Root Causes
1. Static IP configured without gateway
2. DHCP not providing gateway
3. Gateway configuration removed/lost

### Fix
```bash
# Add gateway (use your network's gateway IP)
nmcli connection modify "Wired connection 1" ipv4.gateway 192.168.1.1
nmcli connection up "Wired connection 1"

# Verify route added
ip route show
# Should now show:
# default via 192.168.1.1 dev ens3 proto static metric 100
# 192.168.1.0/24 dev ens3 proto kernel scope link src 192.168.1.100 metric 100

# Test external connectivity
ping -c 3 8.8.8.8
```

---

## Quick Comparison Table

| Scenario | Interface UP? | Has IP? | Has Route? | Ping Gateway? | Ping 8.8.8.8? | DNS Works? |
|----------|---------------|---------|------------|---------------|---------------|------------|
| **Healthy** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **No DHCP** | ✅ | ⚠️ (169.254.x.x) | ❌ | ❌ | ❌ | ❌ |
| **No Link** | ⚠️ (NO-CARRIER) | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Wrong Config** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **DNS Issue** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **NM Not Running** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **No Gateway** | ✅ | ✅ | ⚠️ (local only) | ✅ | ❌ | ❌ |

Use this table to quickly identify which scenario matches your situation.


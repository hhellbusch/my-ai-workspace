# Quick Reference - CoreOS Network Troubleshooting

## Essential Commands (Copy & Paste)

### Quick Status Check
```bash
# Run all these commands to get a quick overview
systemctl status NetworkManager
ip link show
ip addr show
ip route show
ping -c 3 8.8.8.8
nmcli device status
```

### Check What's Wrong

```bash
# Is NetworkManager running?
systemctl is-active NetworkManager

# Do I have a network interface?
ip link show | grep -v "lo:"

# Does my interface have an IP?
ip addr show | grep "inet "

# Do I have a default route?
ip route | grep default

# Can I reach my gateway?
ping -c 3 $(ip route | grep default | awk '{print $3}')

# Can I reach the internet?
ping -c 3 8.8.8.8

# Can I resolve DNS?
nslookup google.com
```

### Quick Fixes

#### Restart NetworkManager
```bash
systemctl restart NetworkManager
```

#### Restart a Connection
```bash
# List connections
nmcli connection show

# Restart a connection
nmcli connection down "Wired connection 1"
nmcli connection up "Wired connection 1"
```

#### Bring Interface Up
```bash
# Replace ens3 with your interface name
ip link set ens3 up
nmcli device connect ens3
```

#### Create New Connection (DHCP)
```bash
# Replace ens3 with your interface name
nmcli connection add type ethernet ifname ens3 con-name "Wired connection 1" autoconnect yes
nmcli connection up "Wired connection 1"
```

#### Configure Static IP
```bash
# Replace values with your network settings
nmcli connection modify "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 192.168.1.100/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "8.8.8.8 1.1.1.1"
  
nmcli connection up "Wired connection 1"
```

#### Force DHCP Renewal
```bash
# Using NetworkManager
nmcli connection down "Wired connection 1"
nmcli connection up "Wired connection 1"

# Using dhclient (replace ens3)
dhclient -r ens3
dhclient ens3
```

#### Fix DNS
```bash
# Add DNS servers
nmcli connection modify "Wired connection 1" ipv4.dns "8.8.8.8 1.1.1.1"
nmcli connection up "Wired connection 1"

# Or edit directly (temporary)
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

#### Add Default Route
```bash
# Temporary (replace values)
ip route add default via 192.168.1.1 dev ens3

# Permanent via NetworkManager
nmcli connection modify "Wired connection 1" ipv4.gateway 192.168.1.1
nmcli connection up "Wired connection 1"
```

### Check Logs

```bash
# Recent NetworkManager logs
journalctl -u NetworkManager -n 50

# Follow NetworkManager logs live
journalctl -u NetworkManager -f

# DHCP-related logs
journalctl -u NetworkManager | grep -i dhcp

# Ignition logs (CoreOS provisioning)
journalctl -u ignition-files.service
```

### Check Physical Link

```bash
# Check if cable/link is detected
cat /sys/class/net/ens3/carrier
# 1 = link detected, 0 = no link

# Check operational state
cat /sys/class/net/ens3/operstate
# up = interface is up, down = interface is down
```

### NetworkManager Connection Details

```bash
# Show all connection settings
nmcli connection show "Wired connection 1"

# Show just IPv4 settings
nmcli connection show "Wired connection 1" | grep ipv4

# Show device details
nmcli device show ens3
```

### Firewall Check

```bash
# Check firewalld status
systemctl status firewalld

# List firewall rules
firewall-cmd --list-all

# Temporarily disable firewall (for testing only!)
systemctl stop firewalld
```

## Troubleshooting Decision Tree

```
No Network?
├─ Is NetworkManager running?
│  ├─ No → systemctl start NetworkManager
│  └─ Yes → Continue
│
├─ Do I see network interfaces?
│  ├─ No → Hardware/driver issue
│  └─ Yes → Continue
│
├─ Is interface UP?
│  ├─ No → ip link set <iface> up
│  └─ Yes → Continue
│
├─ Is physical link detected?
│  ├─ No → Check cable/VM settings
│  └─ Yes → Continue
│
├─ Do I have an IP address?
│  ├─ No → Check DHCP or static config
│  │      nmcli connection up <name>
│  └─ Yes → Continue
│
├─ Do I have a default route?
│  ├─ No → Add route or fix DHCP
│  └─ Yes → Continue
│
├─ Can I ping gateway?
│  ├─ No → Layer 2 issue, VLAN, or firewall
│  └─ Yes → Continue
│
├─ Can I ping external IP (8.8.8.8)?
│  ├─ No → Gateway not routing or firewall
│  └─ Yes → Continue
│
└─ Can I resolve DNS?
   ├─ No → Fix DNS configuration
   └─ Yes → Network is working!
```

## One-Liner Diagnostic

```bash
echo "NetworkManager: $(systemctl is-active NetworkManager) | Interfaces: $(ip -br link | grep -v lo | wc -l) | IPs: $(ip -br addr | grep -v "127.0.0.1" | grep -c UP) | Gateway: $(ip route | grep -q default && echo "YES" || echo "NO") | Internet: $(ping -c 1 -W 1 8.8.8.8 &>/dev/null && echo "YES" || echo "NO") | DNS: $(nslookup google.com &>/dev/null && echo "YES" || echo "NO")"
```

## Common Interface Names

- `ens3`, `ens192`, `ens1` - Physical/virtual NIC (predictable naming)
- `eth0`, `eth1` - Traditional naming
- `enp0s3`, `enp0s8` - PCI bus location-based naming
- `lo` - Loopback (always present)

## Common Error Messages

| Error | Meaning | Fix |
|-------|---------|-----|
| `NO-CARRIER` | No physical link | Check cable/VM network settings |
| `state DOWN` | Interface disabled | `ip link set <iface> up` |
| `No such device` | Interface doesn't exist | Check interface name |
| `RTNETLINK answers: Network is unreachable` | No route to destination | Add default route |
| `temporary failure in name resolution` | DNS not working | Fix /etc/resolv.conf |

## Getting Help

If you're still stuck, gather information:

```bash
# Run diagnostic script
bash diagnose-network.sh > network-diag.txt

# Or manually collect
{
  echo "=== System Info ==="
  hostnamectl
  echo ""
  echo "=== NetworkManager Status ==="
  systemctl status NetworkManager
  echo ""
  echo "=== Interfaces ==="
  ip addr show
  echo ""
  echo "=== Routes ==="
  ip route show
  echo ""
  echo "=== DNS ==="
  cat /etc/resolv.conf
  echo ""
  echo "=== Connections ==="
  nmcli connection show
  echo ""
  echo "=== Recent Logs ==="
  journalctl -u NetworkManager -n 50
} > network-info.txt
```

Then share `network-diag.txt` or `network-info.txt` for further assistance.


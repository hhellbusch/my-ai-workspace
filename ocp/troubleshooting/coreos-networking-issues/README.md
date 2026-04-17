# CoreOS Networking Troubleshooting Guide

## Overview

This guide helps diagnose network connectivity issues on a freshly installed CoreOS system. Use this when you have root access via virtual console but network connectivity is missing.

## Quick Diagnosis Script

Run this first to gather all relevant information:

```bash
# Save this as diagnose-network.sh and run with: bash diagnose-network.sh
```

See [diagnose-network.sh](./diagnose-network.sh) for the complete diagnostic script.

## Manual Step-by-Step Troubleshooting

### Phase 1: Basic Interface and Service Status

#### 1.1 Check NetworkManager Status
```bash
# Check if NetworkManager is running
systemctl status NetworkManager

# If not running, try to start it
systemctl start NetworkManager

# Check for failures
journalctl -u NetworkManager -n 50
```

**Expected:** NetworkManager should be `active (running)`

**Common Issues:**
- Service failed to start → Check journalctl output for errors
- Service doesn't exist → CoreOS should always have NetworkManager

#### 1.2 List Network Interfaces
```bash
# Show all interfaces
ip link show

# Show interfaces with addresses
ip addr show
```

**Expected:** At least `lo` (loopback) and one or more physical interfaces (e.g., `ens3`, `eth0`, `enp0s3`)

**Check for:**
- Interface state should be `UP` (e.g., `state UP`)
- Interface should not be `DOWN` or `UNKNOWN`
- Look for physical interfaces beyond just `lo`

#### 1.3 Check NetworkManager Connection Status
```bash
# List all connections
nmcli connection show

# Show device status
nmcli device status

# Show detailed device info
nmcli device show
```

**Expected:** 
- Devices should be `connected` not `disconnected` or `unavailable`
- At least one connection should be active

**Red Flags:**
- Device shows as `disconnected` → Configuration issue
- Device shows as `unavailable` → Driver or hardware issue
- No connections listed → No network configuration

### Phase 2: Physical and Link Layer

#### 2.1 Check Physical Link Status
```bash
# Check link detection (requires ethtool)
ip link show | grep -i "state"

# For specific interface (replace ens3 with your interface)
cat /sys/class/net/ens3/carrier
# Should return: 1 (link detected) or 0 (no link)

cat /sys/class/net/ens3/operstate
# Should return: up or down
```

**Expected:** 
- `carrier` = 1 (link is up)
- `operstate` = up

**If carrier = 0:**
- Physical cable unplugged (bare metal)
- Virtual network adapter not connected (VM)
- Switch port disabled
- Bad cable

#### 2.2 Check for Link-Local Connectivity
```bash
# Look for link-local address (169.254.x.x or fe80::)
ip addr show

# Try to bring interface up manually if needed
ip link set ens3 up
```

### Phase 3: IP Configuration

#### 3.1 Check IP Address Assignment
```bash
# Check current IP addresses
ip addr show

# Check DHCP client status
nmcli connection show <connection-name>
# Look for ipv4.method and ipv6.method

# Check for DHCP leases
journalctl -u NetworkManager | grep -i dhcp

# Check dhcp client processes
ps aux | grep dhcp
```

**Expected (DHCP):**
- Interface has an IP address (not 169.254.x.x)
- `ipv4.method: auto` in nmcli output
- DHCP lease obtained in logs

**Expected (Static):**
- Interface has configured static IP
- `ipv4.method: manual` in nmcli output

**Red Flags:**
- No IP address → DHCP failure or missing static config
- 169.254.x.x address → DHCP failed, fell back to link-local
- Correct config method but wrong IP → Configuration error

#### 3.2 Check Default Gateway
```bash
# Show routing table
ip route show

# Should see a line like:
# default via 192.168.1.1 dev ens3 proto dhcp metric 100
```

**Expected:** 
- A `default via` route exists
- Points to correct gateway IP
- Uses correct interface

**If missing:**
- DHCP didn't provide gateway
- Static configuration missing route
- NetworkManager connection misconfigured

### Phase 4: Layer 3 Connectivity

#### 4.1 Test Local Network Connectivity
```bash
# Ping default gateway (use your gateway IP)
ping -c 4 192.168.1.1

# Ping another host on same subnet
ping -c 4 192.168.1.2

# If ping fails, try ARP
ip neigh show
arping -I ens3 192.168.1.1
```

**Expected:** 
- Gateway responds to ping
- ARP entries appear for reachable hosts

**If fails:**
- No response from gateway → Gateway down, wrong IP, or firewall
- VLAN mismatch
- Wrong subnet configuration

#### 4.2 Test External Connectivity
```bash
# Ping external IP (Google DNS)
ping -c 4 8.8.8.8

# Try different external IP
ping -c 4 1.1.1.1
```

**Expected:** Packets reach external IPs

**If fails but local works:**
- Gateway not routing to internet
- Firewall blocking outbound
- NAT not configured on gateway

### Phase 5: DNS Resolution

#### 5.1 Check DNS Configuration
```bash
# Check resolv.conf
cat /etc/resolv.conf

# Check NetworkManager DNS settings
nmcli connection show <connection-name> | grep dns

# Check systemd-resolved status (if used)
systemctl status systemd-resolved
resolvectl status
```

**Expected:**
- At least one nameserver listed
- Nameservers are reachable

#### 5.2 Test DNS Resolution
```bash
# Test with dig
dig google.com

# Test with nslookup
nslookup google.com

# Test with host
host google.com

# Manual DNS query to specific server
dig @8.8.8.8 google.com
```

**Expected:** Domain resolves to IP addresses

**If fails:**
- DNS server unreachable → Check connectivity to DNS IP
- DNS server not responding → DNS server issue
- Works with 8.8.8.8 but not local DNS → Local DNS server issue

### Phase 6: Firewall

#### 6.1 Check Firewall Status
```bash
# Check firewalld
systemctl status firewalld

# List firewall rules
firewall-cmd --list-all

# Check iptables
iptables -L -n -v
iptables -t nat -L -n -v

# Check nftables
nft list ruleset
```

**Common Issue:** Overly restrictive firewall blocking outbound traffic

### Phase 7: CoreOS-Specific Checks

#### 7.1 Check Ignition Configuration
```bash
# Check what Ignition configured
journalctl -u ignition-files.service
journalctl -u ignition-disks.service

# Look for network configuration in Ignition
ls -la /etc/NetworkManager/system-connections/

# Check for Ignition network configs
cat /etc/NetworkManager/system-connections/*
```

#### 7.2 Check for Overriding Configs
```bash
# Check for manual network configs that might conflict
ls -la /etc/sysconfig/network-scripts/

# Check NetworkManager configuration
cat /etc/NetworkManager/NetworkManager.conf
ls -la /etc/NetworkManager/conf.d/
```

#### 7.3 Check Kernel Network Parameters
```bash
# Check if IP forwarding or other params are misconfigured
sysctl -a | grep net.ipv4

# Key parameters to check:
sysctl net.ipv4.ip_forward
sysctl net.ipv4.conf.all.rp_filter
```

## Common Scenarios and Solutions

### Scenario 1: DHCP Not Working

**Symptoms:** No IP address or 169.254.x.x address

**Diagnosis:**
```bash
nmcli connection show
journalctl -u NetworkManager | grep -i dhcp
```

**Solutions:**
```bash
# Restart NetworkManager
systemctl restart NetworkManager

# Manually trigger DHCP
nmcli connection down <connection-name>
nmcli connection up <connection-name>

# Force DHCP renewal
dhclient -r ens3
dhclient ens3
```

### Scenario 2: Interface Not Coming Up

**Symptoms:** Interface shows as DOWN

**Diagnosis:**
```bash
ip link show ens3
nmcli device status
journalctl -u NetworkManager | grep ens3
```

**Solutions:**
```bash
# Manually bring up interface
ip link set ens3 up

# Create/activate NetworkManager connection
nmcli connection add type ethernet ifname ens3 con-name "Wired connection 1"
nmcli connection up "Wired connection 1"
```

### Scenario 3: Wrong Gateway or No Route

**Symptoms:** Can't reach external hosts, but have IP address

**Diagnosis:**
```bash
ip route show
ping <gateway-ip>
```

**Solutions:**
```bash
# Add default route manually (temporary)
ip route add default via 192.168.1.1 dev ens3

# Fix NetworkManager connection
nmcli connection modify "Wired connection 1" ipv4.gateway 192.168.1.1
nmcli connection up "Wired connection 1"
```

### Scenario 4: DNS Not Working

**Symptoms:** Can ping IPs but can't resolve hostnames

**Diagnosis:**
```bash
cat /etc/resolv.conf
dig google.com
ping 8.8.8.8
```

**Solutions:**
```bash
# Add DNS servers to NetworkManager
nmcli connection modify "Wired connection 1" ipv4.dns "8.8.8.8 1.1.1.1"
nmcli connection up "Wired connection 1"

# Temporary fix - edit resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### Scenario 5: Virtual Machine Network Not Connected

**Symptoms:** No carrier detected, interface shows NO-CARRIER

**Diagnosis:**
```bash
cat /sys/class/net/ens3/carrier  # Returns 0
ip link show | grep "NO-CARRIER"
```

**Solutions:**
- **VMware:** Check VM settings, ensure network adapter is "Connected"
- **KVM/QEMU:** Check virsh network, restart VM
- **VirtualBox:** Check adapter settings, ensure cable connected
- **Hyper-V:** Check virtual switch assignment

## Quick Fix Attempts

Try these in order:

```bash
# 1. Restart NetworkManager
systemctl restart NetworkManager

# 2. Bring interface down and up
nmcli device disconnect ens3
nmcli device connect ens3

# 3. Delete and recreate connection
nmcli connection delete "Wired connection 1"
nmcli connection add type ethernet ifname ens3 con-name "Wired connection 1" autoconnect yes

# 4. Manual IP configuration (if DHCP fails)
nmcli connection modify "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses 192.168.1.100/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "8.8.8.8 1.1.1.1"
nmcli connection up "Wired connection 1"
```

## Next Steps

1. Run the diagnostic script first: `./diagnose-network.sh`
2. Follow the manual troubleshooting phases in order
3. Match your symptoms to common scenarios
4. Try quick fixes if appropriate

## Related Files

- [diagnose-network.sh](./diagnose-network.sh) - Automated diagnostic script
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Quick command reference
- [EXAMPLES.md](./EXAMPLES.md) - Real-world examples with output

## Additional Resources

- [CoreOS Documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/)
- [NetworkManager Documentation](https://networkmanager.dev/)
- [Red Hat CoreOS Troubleshooting](https://docs.openshift.com/container-platform/latest/installing/installing_bare_metal/installing-bare-metal.html)


#!/bin/bash

# CoreOS Network Diagnostic Script
# Run this to gather comprehensive network diagnostic information

set +e  # Don't exit on errors - we want to capture everything

echo "======================================================================"
echo "CoreOS Network Diagnostics"
echo "Generated: $(date)"
echo "Hostname: $(hostname)"
echo "======================================================================"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo "======================================================================"
    echo "$1"
    echo "======================================================================"
    echo ""
}

# Function to run command and show output
run_cmd() {
    echo "### Command: $1"
    echo ""
    eval "$1" 2>&1
    local exit_code=$?
    echo ""
    echo "Exit code: $exit_code"
    echo "---"
    return $exit_code
}

# ===================================================================
# PHASE 1: SYSTEM AND SERVICE STATUS
# ===================================================================
print_section "PHASE 1: System and Service Status"

run_cmd "hostnamectl"

run_cmd "systemctl status NetworkManager --no-pager -l"

run_cmd "systemctl is-active NetworkManager"

run_cmd "systemctl status systemd-resolved --no-pager -l"

# ===================================================================
# PHASE 2: NETWORK INTERFACES
# ===================================================================
print_section "PHASE 2: Network Interfaces"

run_cmd "ip link show"

run_cmd "ip addr show"

run_cmd "nmcli device status"

run_cmd "nmcli connection show"

run_cmd "nmcli device show"

# Check carrier status for each interface
echo "### Checking carrier status for all interfaces"
echo ""
for iface in /sys/class/net/*; do
    if [ -e "$iface/carrier" ]; then
        ifname=$(basename "$iface")
        carrier=$(cat "$iface/carrier" 2>/dev/null || echo "unknown")
        operstate=$(cat "$iface/operstate" 2>/dev/null || echo "unknown")
        echo "Interface: $ifname"
        echo "  Carrier: $carrier (1=link detected, 0=no link)"
        echo "  Operstate: $operstate"
        echo ""
    fi
done
echo "---"

# ===================================================================
# PHASE 3: IP CONFIGURATION AND ROUTING
# ===================================================================
print_section "PHASE 3: IP Configuration and Routing"

run_cmd "ip route show"

run_cmd "ip -4 route show"

run_cmd "ip -6 route show"

# Check for default gateway
echo "### Default Gateway Check"
echo ""
default_gw=$(ip route | grep default | awk '{print $3}' | head -1)
if [ -n "$default_gw" ]; then
    echo "Default gateway found: $default_gw"
else
    echo "WARNING: No default gateway found!"
fi
echo ""
echo "---"

# ===================================================================
# PHASE 4: CONNECTIVITY TESTS
# ===================================================================
print_section "PHASE 4: Connectivity Tests"

# Test gateway connectivity
if [ -n "$default_gw" ]; then
    echo "### Testing gateway connectivity"
    echo ""
    run_cmd "ping -c 3 -W 2 $default_gw"
fi

# Test external connectivity
echo "### Testing external connectivity (Google DNS)"
echo ""
run_cmd "ping -c 3 -W 2 8.8.8.8"

echo "### Testing external connectivity (Cloudflare DNS)"
echo ""
run_cmd "ping -c 3 -W 2 1.1.1.1"

# ===================================================================
# PHASE 5: DNS CONFIGURATION AND RESOLUTION
# ===================================================================
print_section "PHASE 5: DNS Configuration and Resolution"

run_cmd "cat /etc/resolv.conf"

if systemctl is-active systemd-resolved >/dev/null 2>&1; then
    run_cmd "resolvectl status"
fi

echo "### DNS Resolution Test (google.com)"
echo ""
run_cmd "nslookup google.com"

echo "### DNS Resolution Test using Google DNS directly"
echo ""
run_cmd "nslookup google.com 8.8.8.8"

# ===================================================================
# PHASE 6: ARP TABLE
# ===================================================================
print_section "PHASE 6: ARP Table"

run_cmd "ip neigh show"

run_cmd "arp -a"

# ===================================================================
# PHASE 7: FIREWALL STATUS
# ===================================================================
print_section "PHASE 7: Firewall Status"

run_cmd "systemctl status firewalld --no-pager -l"

if systemctl is-active firewalld >/dev/null 2>&1; then
    run_cmd "firewall-cmd --list-all"
fi

run_cmd "iptables -L -n -v"

run_cmd "iptables -t nat -L -n -v"

# ===================================================================
# PHASE 8: NETWORK CONFIGURATION FILES
# ===================================================================
print_section "PHASE 8: Network Configuration Files"

echo "### NetworkManager Configuration"
echo ""
run_cmd "cat /etc/NetworkManager/NetworkManager.conf"

echo "### NetworkManager Connections"
echo ""
if [ -d /etc/NetworkManager/system-connections/ ]; then
    run_cmd "ls -la /etc/NetworkManager/system-connections/"
    for conn in /etc/NetworkManager/system-connections/*; do
        if [ -f "$conn" ]; then
            echo ""
            echo "### Connection file: $(basename $conn)"
            echo ""
            cat "$conn" 2>&1 || echo "Unable to read file"
            echo ""
        fi
    done
else
    echo "Directory /etc/NetworkManager/system-connections/ not found"
fi
echo "---"

echo "### Network Scripts (if any)"
echo ""
if [ -d /etc/sysconfig/network-scripts/ ]; then
    run_cmd "ls -la /etc/sysconfig/network-scripts/"
else
    echo "Directory /etc/sysconfig/network-scripts/ not found (normal for newer CoreOS)"
fi

# ===================================================================
# PHASE 9: DHCP AND NETWORKMANAGER LOGS
# ===================================================================
print_section "PHASE 9: Recent NetworkManager Logs"

run_cmd "journalctl -u NetworkManager -n 100 --no-pager"

echo "### DHCP-related log entries"
echo ""
run_cmd "journalctl -u NetworkManager | grep -i dhcp | tail -50"

# ===================================================================
# PHASE 10: IGNITION AND COREOS-SPECIFIC
# ===================================================================
print_section "PHASE 10: Ignition and CoreOS-Specific"

run_cmd "journalctl -u ignition-files.service --no-pager"

run_cmd "rpm-ostree status"

# ===================================================================
# PHASE 11: KERNEL NETWORK PARAMETERS
# ===================================================================
print_section "PHASE 11: Key Kernel Network Parameters"

run_cmd "sysctl net.ipv4.ip_forward"
run_cmd "sysctl net.ipv4.conf.all.forwarding"
run_cmd "sysctl net.ipv4.conf.all.rp_filter"
run_cmd "sysctl net.ipv4.conf.default.rp_filter"
run_cmd "sysctl net.ipv6.conf.all.disable_ipv6"

# ===================================================================
# SUMMARY
# ===================================================================
print_section "DIAGNOSTIC SUMMARY"

echo "Key Findings:"
echo ""

# Check NetworkManager status
if systemctl is-active NetworkManager >/dev/null 2>&1; then
    echo "[OK] NetworkManager is running"
else
    echo "[FAIL] NetworkManager is NOT running"
fi

# Check for interfaces
iface_count=$(ip link show | grep -c "^[0-9]")
if [ "$iface_count" -gt 1 ]; then
    echo "[OK] Found $iface_count network interfaces"
else
    echo "[WARN] Only found loopback interface"
fi

# Check for IP addresses
ip_count=$(ip addr show | grep -c "inet ")
if [ "$ip_count" -gt 1 ]; then
    echo "[OK] Found $ip_count IP addresses assigned"
else
    echo "[WARN] Only loopback has IP address"
fi

# Check for default gateway
if [ -n "$default_gw" ]; then
    echo "[OK] Default gateway configured: $default_gw"
else
    echo "[FAIL] No default gateway found"
fi

# Check gateway connectivity
if [ -n "$default_gw" ]; then
    if ping -c 1 -W 2 "$default_gw" >/dev/null 2>&1; then
        echo "[OK] Gateway is reachable"
    else
        echo "[FAIL] Cannot reach gateway"
    fi
fi

# Check external connectivity
if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo "[OK] External connectivity works"
else
    echo "[FAIL] No external connectivity"
fi

# Check DNS
if nslookup google.com >/dev/null 2>&1; then
    echo "[OK] DNS resolution works"
else
    echo "[FAIL] DNS resolution not working"
fi

# Check for carrier on physical interfaces
echo ""
echo "Link Status:"
for iface in /sys/class/net/*; do
    if [ -e "$iface/carrier" ]; then
        ifname=$(basename "$iface")
        if [ "$ifname" != "lo" ]; then
            carrier=$(cat "$iface/carrier" 2>/dev/null || echo "?")
            if [ "$carrier" = "1" ]; then
                echo "[OK] $ifname: Link detected"
            else
                echo "[FAIL] $ifname: No link detected"
            fi
        fi
    fi
done

echo ""
echo "======================================================================"
echo "Diagnostic complete. Review the output above for issues."
echo "======================================================================"


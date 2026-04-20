# Debug Toolbox Container - Quick Reference

Fast command reference for OpenShift debug containers.

## Quick Start

### Create Toolbox Container
```bash
# Standard toolbox
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1

# Privileged toolbox (required for most diagnostic tools)
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true

# In specific namespace
oc run -it toolbox -n <namespace> --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true

# On specific node
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true \
  --overrides='{"spec":{"nodeName":"<node-name>"}}'

# With NAD/VLAN attachment
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true \
  --annotations='k8s.v1.cni.cncf.io/networks=vlan100'

# VLAN toolbox with static IP (using YAML)
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: vlan-toolbox
  annotations:
    k8s.v1.cni.cncf.io/networks: |
      [
        {
          "name": "vlan100",
          "interface": "net1",
          "ips": ["192.168.100.200/24"],
          "gateway": ["192.168.100.1"]
        }
      ]
spec:
  containers:
  - name: toolbox
    image: registry.redhat.io/ubi10/toolbox:10.1
    command: ["/bin/bash", "-c", "sleep infinity"]
    securityContext:
      privileged: true
EOF
```

### Manage Toolbox
```bash
# Reconnect to existing toolbox
oc attach toolbox -it

# Execute single command
oc exec toolbox -- <command>

# Delete toolbox
oc delete pod toolbox
```

## Install Diagnostic Tools

### Network Diagnostics
```bash
dnf install -y mtr              # MTU and path testing
dnf install -y traceroute       # Path tracing
dnf install -y tcpdump          # Packet capture
dnf install -y nmap-ncat        # Port scanning
dnf install -y bind-utils       # dig, nslookup, host
dnf install -y iperf3           # Bandwidth testing
```

### All-in-One Installation
```bash
dnf install -y mtr traceroute tcpdump nmap-ncat bind-utils iperf3 vim
```

## Common Diagnostics

### MTU Testing
```bash
# Test standard MTU (1500)
ping -M do -s 1472 <target-ip> -c 4
mtr -s 1472 <target-ip>

# Test overlay MTU (1400)
ping -M do -s 1372 <target-ip> -c 4
mtr -s 1372 <target-ip>

# Find maximum working size
for s in 1472 1450 1428 1400 1350; do 
  echo -n "MTU $((s+28)) (size $s): "
  ping -M do -s $s -c 2 <target-ip> &>/dev/null && echo "OK" || echo "FAIL"
done

# Report mode
mtr -r -c 10 -s 1472 <target-ip>
```

### DNS Testing
```bash
# Basic resolution
nslookup <hostname>
dig <hostname>
host <hostname>

# Specific DNS server
dig @8.8.8.8 <hostname>
dig @10.0.0.10 <hostname>

# Check configuration
cat /etc/resolv.conf

# Test internal cluster DNS
nslookup kubernetes.default
```

### Network Path Tracing
```bash
# Basic traceroute
traceroute <target-ip>

# ICMP traceroute
traceroute -I <target-ip>

# Continuous monitoring with mtr
mtr <target-ip>

# MTR report mode
mtr -r -c 100 <target-ip>
```

### Port Connectivity
```bash
# Test TCP connection
nc -zv <target-ip> <port>

# With timeout
timeout 5 nc -zv <target-ip> <port>

# Test multiple ports
for port in 80 443 8080; do 
  echo -n "Port $port: "
  nc -zv <target-ip> $port 2>&1 | grep -q succeeded && echo "OPEN" || echo "CLOSED"
done

# HTTP/HTTPS testing
curl -v http://<target-ip>:<port>
curl -k -v https://<target-ip>:<port>
```

### VLAN/Additional Network Testing
```bash
# Check additional interfaces (when using NAD)
ip addr show
# Look for: eth0 (default), net1 (first NAD), net2 (second NAD)

# Test via specific VLAN interface
ping -I net1 <target-ip>
mtr -I net1 <target-ip>

# Check VLAN interface details
ip addr show net1
ip route show dev net1

# MTU test on VLAN
ping -M do -s 1472 -I net1 <target-ip> -c 4
mtr -s 1472 -I net1 <target-ip>

# Trace route via VLAN
traceroute -i net1 <target-ip>

# Complete VLAN test workflow
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: vlan-test
  annotations:
    k8s.v1.cni.cncf.io/networks: |
      [{"name":"vlan100","interface":"net1","ips":["192.168.100.200/24"]}]
spec:
  containers:
  - name: toolbox
    image: registry.redhat.io/ubi10/toolbox:10.1
    command: ["/bin/bash", "-c", "sleep infinity"]
    securityContext:
      privileged: true
EOF
oc wait --for=condition=ready pod/vlan-test --timeout=60s
oc exec -it vlan-test -- bash -c "ip addr show net1 && ping -I net1 -c 4 192.168.100.1"
```

### Packet Capture
```bash
# Capture all traffic
tcpdump -i any

# Specific host
tcpdump -i any host <target-ip>

# Specific port
tcpdump -i any port 443

# Save to file
tcpdump -i any -w /tmp/capture.pcap

# With filters
tcpdump -i any 'host <target-ip> and port 443'
```

## File Operations

### Copy Files
```bash
# Copy TO container
oc cp local-file.txt toolbox:/tmp/file.txt

# Copy FROM container
oc cp toolbox:/tmp/capture.pcap ./capture.pcap

# Copy directory
oc cp ./local-dir toolbox:/tmp/remote-dir
```

## One-Liners

### Quick MTU Test from Cluster
```bash
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true --rm -- \
  bash -c "dnf install -y mtr >/dev/null 2>&1 && mtr -r -c 10 -s 1472 <target-ip>"
```

### Quick DNS Test
```bash
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --rm -- \
  bash -c "nslookup <hostname>"
```

### Quick Port Test
```bash
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --rm -- \
  bash -c "timeout 5 bash -c '</dev/tcp/<target-ip>/<port>' && echo 'Port open' || echo 'Port closed'"
```

### Packet Capture and Retrieve
```bash
# Start capture (in background terminal)
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true
dnf install -y tcpdump
tcpdump -i any -w /tmp/capture.pcap 'host <target-ip>'

# In another terminal, copy file when done
oc cp toolbox:/tmp/capture.pcap ./capture.pcap
oc delete pod toolbox
```

## Troubleshooting

### Package Install Fails with "Error unpacking rpm"
```bash
# Delete and recreate with privileged flag
oc delete pod toolbox
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true
```

### Container Exits Immediately
```bash
# Ensure -it flags are present
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true

# If already exists, attach
oc attach toolbox -it
```

### Cannot Create Privileged Container
```bash
# Check permissions
oc auth can-i create pods/privileged

# Alternative: Use debug node
oc debug node/<node-name>
chroot /host
```

## Available Images

```bash
# UBI 10 (Latest, RHEL 10-based)
registry.redhat.io/ubi10/toolbox:10.1

# UBI 9 (RHEL 9-based)
registry.redhat.io/ubi9/toolbox:9.4

# UBI 8 (Legacy, RHEL 8-based)
registry.redhat.io/ubi8/toolbox:8.10
```

## Security Reminder

⚠️ **Delete privileged containers immediately after use:**
```bash
oc delete pod toolbox
```

Privileged containers have elevated permissions and should not be left running in production.

---

**See:** [README.md](./README.md) for detailed explanations and examples.

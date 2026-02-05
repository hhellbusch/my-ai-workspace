# Debug Toolbox Container for OpenShift Troubleshooting

## Overview

This guide covers using ephemeral debug containers with the Red Hat Universal Base Image (UBI) toolbox for troubleshooting OpenShift clusters. The toolbox provides a full-featured Linux environment with package management, allowing you to install diagnostic tools on-demand without modifying cluster nodes or application containers.

## When to Use This Technique

Use a debug toolbox container when you need to:
- Test network connectivity from within the cluster's pod network
- Install diagnostic tools not available in application containers
- Perform MTU testing, packet captures, or network tracing
- Test DNS resolution from a pod's perspective
- Access cluster resources without SSH access to nodes
- Troubleshoot without modifying production containers
- Run network diagnostic tools like `mtr`, `tcpdump`, `traceroute`, `nmap`

## Quick Start

### Basic Toolbox Container
```bash
# Start interactive toolbox container
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1

# If you exit and need to reconnect
oc attach toolbox -it

# Clean up when done
oc delete pod toolbox
```

### Privileged Toolbox Container

**⚠️ Important:** The `--privileged` flag is required for:
- Installing certain packages (like `mtr`, `tcpdump`)
- Running packet captures
- Network diagnostic tools that need raw socket access
- Tools requiring special capabilities

```bash
# Start privileged toolbox container
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true

# Inside the container, you can now install packages
dnf install mtr tcpdump traceroute bind-utils nmap-ncat
```

## Detailed Usage

### 1. Creating Debug Containers

#### Standard Container (Limited Capabilities)
```bash
oc run -it toolbox \
  --image=registry.redhat.io/ubi10/toolbox:10.1 \
  --restart=Never

# Good for:
# - Basic DNS testing (nslookup, dig - if available)
# - HTTP/HTTPS connectivity testing (curl, wget)
# - Basic network connectivity (ping, telnet)
# - File operations and scripting
```

#### Privileged Container (Full Capabilities)
```bash
oc run -it toolbox \
  --image=registry.redhat.io/ubi10/toolbox:10.1 \
  --privileged=true \
  --restart=Never

# Good for:
# - Installing packages that fail in standard mode
# - Network packet captures (tcpdump)
# - Advanced network diagnostics (mtr, traceroute)
# - Raw socket operations
# - Tools requiring special capabilities
```

#### Container in Specific Namespace
```bash
# Run in application namespace to test from that network context
oc run -it toolbox \
  -n <namespace> \
  --image=registry.redhat.io/ubi10/toolbox:10.1 \
  --privileged=true
```

#### Container on Specific Node
```bash
# Run on specific node (useful for node-specific network issues)
oc run -it toolbox \
  --image=registry.redhat.io/ubi10/toolbox:10.1 \
  --privileged=true \
  --overrides='{"spec":{"nodeName":"<node-name>"}}'
```

#### Container with Additional Network (NAD/VLAN)
```bash
# Attach to VLAN using NetworkAttachmentDefinition
oc run -it toolbox \
  --image=registry.redhat.io/ubi10/toolbox:10.1 \
  --privileged=true \
  --annotations='k8s.v1.cni.cncf.io/networks=vlan100'

# Multiple VLANs
oc run -it toolbox \
  --image=registry.redhat.io/ubi10/toolbox:10.1 \
  --privileged=true \
  --annotations='k8s.v1.cni.cncf.io/networks=vlan100,vlan200'

# With static IP assignment (using pod YAML)
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

# Connect to VLAN toolbox
oc wait --for=condition=ready pod/vlan-toolbox --timeout=60s
oc exec -it vlan-toolbox -- bash
```

**Note:** See [NetworkAttachmentDefinition Guide](../../ocp-examples/network-attachment-definitions/README.md) for complete NAD/VLAN documentation.

### 2. Installing Diagnostic Tools

Once inside a privileged toolbox container:

```bash
# Network diagnostics
dnf install -y mtr              # MTU and path testing
dnf install -y traceroute       # Path tracing
dnf install -y tcpdump          # Packet capture
dnf install -y nmap-ncat        # Port scanning and netcat

# DNS tools
dnf install -y bind-utils       # dig, nslookup, host

# Performance tools
dnf install -y iperf3           # Bandwidth testing
dnf install -y sysstat          # System performance

# HTTP/API tools
dnf install -y httpd-tools      # ab (Apache Bench)

# General utilities
dnf install -y vim              # Text editing
dnf install -y less             # Paging
dnf install -y procps-ng        # ps, top, etc.
```

### 3. Common Troubleshooting Tasks

#### MTU Testing
```bash
# Install mtr
dnf install -y mtr

# Test standard Ethernet MTU (1500)
mtr -s 1472 <target-ip>

# Test overlay MTU (1400)
mtr -s 1372 <target-ip>

# Report mode (non-interactive)
mtr -r -c 10 -s 1472 <target-ip>

# Or use ping (already available)
ping -M do -s 1472 <target-ip> -c 4
```

#### Network Path Tracing
```bash
# Install traceroute
dnf install -y traceroute

# Trace path to target
traceroute <target-ip>

# ICMP traceroute
traceroute -I <target-ip>

# With specific MTU size
traceroute -F -N 1 <target-ip>
```

#### Packet Capture
```bash
# Install tcpdump
dnf install -y tcpdump

# Capture on all interfaces
tcpdump -i any

# Capture specific host
tcpdump -i any host <target-ip>

# Capture specific port
tcpdump -i any port 443

# Save to file for analysis
tcpdump -i any -w /tmp/capture.pcap
```

#### DNS Resolution Testing
```bash
# Install DNS tools
dnf install -y bind-utils

# Test DNS resolution
nslookup <hostname>
dig <hostname>
host <hostname>

# Test specific DNS server
dig @8.8.8.8 <hostname>

# Check DNS search domains
cat /etc/resolv.conf
```

#### Port Connectivity Testing
```bash
# Install ncat
dnf install -y nmap-ncat

# Test TCP connection
nc -zv <target-ip> <port>

# Test with timeout
timeout 5 nc -zv <target-ip> <port>

# Listen on port (for reverse testing)
nc -l 8080
```

#### VLAN/Additional Network Testing
```bash
# Check additional network interfaces (when using NAD)
ip addr show

# Should see:
# - eth0 (default pod network)
# - net1 (first additional network/VLAN)
# - net2 (second additional network/VLAN, if configured)

# Test connectivity via specific interface
ping -I net1 <target-ip>

# Check VLAN interface details
ip addr show net1
ip route show dev net1

# MTU testing on VLAN interface
dnf install -y mtr
mtr -s 1472 -I net1 <target-ip>
ping -M do -s 1472 -I net1 <target-ip> -c 4

# Trace route via VLAN
traceroute -i net1 <target-ip>

# Check if traffic is using VLAN
# From node (in separate session):
oc debug node/<node-name>
chroot /host
tcpdump -i ens3 -e -n vlan <vlan-id>
```

**Example: Complete VLAN troubleshooting workflow**
```bash
# 1. Create toolbox on VLAN 100
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

# 2. Wait and connect
oc wait --for=condition=ready pod/vlan-toolbox --timeout=60s
oc exec -it vlan-toolbox -- bash

# 3. Inside pod - verify VLAN interface
ip addr show net1
# Should show: 192.168.100.200/24

# 4. Test connectivity
ping -I net1 192.168.100.1  # Gateway
ping -I net1 192.168.100.10 # Target server

# 5. Install and run diagnostics
dnf install -y mtr traceroute
mtr -I net1 192.168.100.10

# 6. Clean up
exit
oc delete pod vlan-toolbox
```

### 4. Managing the Container

#### Reconnecting to Existing Container
```bash
# List running pods
oc get pods

# Reconnect to toolbox
oc attach toolbox -it

# Or use exec
oc exec -it toolbox -- bash
```

#### Running Commands Without Interactive Shell
```bash
# Execute single command
oc exec toolbox -- ping -c 4 <target-ip>

# Run multiple commands
oc exec toolbox -- bash -c "mtr -r -c 10 <target-ip>"
```

#### Copying Files To/From Container
```bash
# Copy file TO container
oc cp local-file.txt toolbox:/tmp/file.txt

# Copy file FROM container
oc cp toolbox:/tmp/capture.pcap ./capture.pcap
```

#### Cleaning Up
```bash
# Delete the toolbox pod
oc delete pod toolbox

# Force delete if stuck
oc delete pod toolbox --force --grace-period=0
```

## Privileged Flag Considerations

### When Privileged Mode is Required

The `--privileged=true` flag is necessary when:

1. **Package Installation Failures**
   - Error: "Error unpacking rpm package"
   - Packages like `mtr`, `tcpdump`, `traceroute` need special capabilities
   - Solution: Recreate container with `--privileged=true`

2. **Raw Socket Operations**
   - Tools requiring ICMP (ping variants, traceroute, mtr)
   - Tools requiring packet capture (tcpdump)
   - Low-level network diagnostics

3. **Special Capabilities**
   - Operations requiring CAP_NET_RAW
   - Operations requiring CAP_NET_ADMIN
   - System-level diagnostics

### Security Implications

**⚠️ Important Security Considerations:**

- Privileged containers have elevated permissions similar to root on the host
- They can access host resources and bypass security constraints
- Should only be used for troubleshooting, not for running applications
- Delete immediately after troubleshooting is complete
- Do not leave privileged containers running in production

**Best Practices:**
```bash
# 1. Create only when needed
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true

# 2. Do your troubleshooting work
# ...

# 3. Delete immediately when done
oc delete pod toolbox

# 4. If you need to step away, at least note when it was created
oc get pod toolbox -o jsonpath='{.metadata.creationTimestamp}'
```

### Alternative: Debug Node for Node-Level Access

If you need node-level access instead of pod network perspective:

```bash
# Debug a specific node
oc debug node/<node-name>

# Change to host filesystem
chroot /host

# Now you're on the actual node
# Install packages (changes persist only in debug container)
dnf install mtr

# Exit the chroot
exit

# Exit the debug session
exit
```

## Real-World Examples

### Example 1: MTU Issue Troubleshooting

**Symptom:** SSH connections from Ansible Automation Platform pods fail to remote hosts

**Solution:**
```bash
# 1. Create privileged toolbox
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true

# 2. Install mtr
dnf install -y mtr

# 3. Test MTU to target
mtr -s 1472 192.168.100.50  # Test 1500 MTU
mtr -s 1372 192.168.100.50  # Test 1400 MTU

# 4. If 1400 works but 1500 doesn't, you have MTU mismatch
# See: ../aap-ssh-mtu-issues/README.md

# 5. Clean up
exit
oc delete pod toolbox
```

### Example 2: DNS Resolution Issues

**Symptom:** Application can't resolve external hostnames

**Solution:**
```bash
# 1. Create toolbox in same namespace
oc run -it toolbox -n myapp --image=registry.redhat.io/ubi10/toolbox:10.1

# 2. Install DNS tools
dnf install -y bind-utils

# 3. Test DNS resolution
nslookup external.example.com

# 4. Check DNS configuration
cat /etc/resolv.conf

# 5. Test specific DNS server
dig @10.0.0.10 external.example.com

# 6. Clean up
exit
oc delete pod toolbox -n myapp
```

### Example 3: Network Path Investigation

**Symptom:** Intermittent connectivity to external service

**Solution:**
```bash
# 1. Create privileged toolbox
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true

# 2. Install diagnostic tools
dnf install -y mtr traceroute

# 3. Run continuous monitoring
mtr external-service.example.com

# Watch for:
# - Packet loss percentage
# - High latency hops
# - Route changes

# 4. Capture specific details
mtr -r -c 100 external-service.example.com > /tmp/mtr-report.txt

# 5. Copy report out
exit
oc cp toolbox:/tmp/mtr-report.txt ./mtr-report.txt
oc delete pod toolbox
```

### Example 4: Packet Capture for API Debugging

**Symptom:** Need to see actual traffic to/from API

**Solution:**
```bash
# 1. Create privileged toolbox
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true

# 2. Install tcpdump
dnf install -y tcpdump

# 3. Start capture
tcpdump -i any -w /tmp/api-capture.pcap 'host api.example.com'

# 4. Let it run while reproducing issue
# Press Ctrl+C to stop

# 5. Copy capture file for analysis
exit
oc cp toolbox:/tmp/api-capture.pcap ./api-capture.pcap
oc delete pod toolbox

# 6. Analyze with Wireshark locally
wireshark api-capture.pcap
```

## Troubleshooting the Toolbox

### Problem: "Error unpacking rpm package"

**Cause:** Package requires capabilities not available in standard container

**Solution:**
```bash
# Delete existing container
oc delete pod toolbox

# Recreate with privileged flag
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true

# Try installation again
dnf install mtr
```

### Problem: Cannot Create Privileged Container

**Cause:** Security policy or RBAC restrictions

**Check:**
```bash
# Check if you have required permissions
oc auth can-i create pods/privileged

# Check PodSecurityPolicy/SecurityContextConstraints
oc get scc
oc describe scc privileged
```

**Solution:**
- Request appropriate RBAC permissions
- Use `oc debug node/<node-name>` as alternative for node-level access
- Use standard toolbox with pre-installed tools (limited)

### Problem: Container Exits Immediately

**Cause:** Missing `-it` flags or no TTY

**Solution:**
```bash
# Ensure both -i and -t flags are present
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true

# If container already exists
oc attach toolbox -it
```

### Problem: Network Not Accessible

**Check:**
1. Is pod Running? `oc get pod toolbox`
2. Does pod have IP? `oc get pod toolbox -o wide`
3. Can ping within cluster? `oc exec toolbox -- ping 10.0.0.1`
4. DNS working? `oc exec toolbox -- nslookup kubernetes.default`

## Available UBI Toolbox Images

```bash
# UBI 10 (RHEL 10-based) - Latest
registry.redhat.io/ubi10/toolbox:10.1

# UBI 9 (RHEL 9-based) - Previous stable
registry.redhat.io/ubi9/toolbox:9.4

# UBI 8 (RHEL 8-based) - Legacy
registry.redhat.io/ubi8/toolbox:8.10
```

**Recommendation:** Use UBI 10 unless you need compatibility with older tools or systems.

## Related Documentation

- [NetworkAttachmentDefinition Guide](../../ocp-examples/network-attachment-definitions/README.md) - Complete NAD/VLAN configuration and usage
- [AAP SSH MTU Issues](../aap-ssh-mtu-issues/README.md) - Using toolbox for MTU testing
- [CoreOS Networking Issues](../coreos-networking-issues/README.md) - Node-level network troubleshooting
- [API Slowness](../api-slowness-web-console/README.md) - Using toolbox to test API connectivity

## Reference Commands

See [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) for copy-paste ready commands.

---

**AI Disclosure:** This documentation was created with AI assistance to provide comprehensive troubleshooting guidance for OpenShift debug containers.

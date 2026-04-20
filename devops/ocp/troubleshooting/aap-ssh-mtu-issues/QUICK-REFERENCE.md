# Quick Reference: AAP SSH MTU Issues

> **AI Disclosure:** This documentation was created with AI assistance (Claude 3.5 Sonnet via Cursor) on 2026-02-04.

One-line commands for quick diagnostics and fixes.

## Quick Diagnostics

### Find AAP Execution Pod
```bash
# List all pods to identify execution/job pods
oc get pods -n <aap-namespace>

# Flexible selector for job/executor/task pods
oc get pods -n <aap-namespace> --field-selector=status.phase=Running -o name | grep -iE "job|executor|task|ee" | head -1

# Note: Pod naming varies by AAP version and deployment method
```

### Test MTU from Pod
```bash
# Test standard Ethernet MTU (1500)
oc exec -n <aap-namespace> <pod> -- ping -M do -s 1472 <target-ip> -c 4

# Test overlay MTU (1400)
oc exec -n <aap-namespace> <pod> -- ping -M do -s 1372 <target-ip> -c 4

# Find maximum working size
for s in 1472 1450 1428 1400 1350; do echo -n "$s: "; oc exec -n <ns> <pod> -- ping -M do -s $s -c 2 <ip> &>/dev/null && echo "OK" || echo "FAIL"; done
```

### Check Cluster MTU
```bash
# Cluster network MTU
oc get network.config.openshift.io cluster -o jsonpath='{.status.clusterNetwork[0].mtu}'

# OVN overlay MTU
oc get network.operator.openshift.io cluster -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.mtu}'
```

### Check Pod MTU
```bash
oc exec -n <aap-namespace> <pod> -- ip link show eth0 | grep mtu
```

### Test Path MTU Discovery
```bash
oc exec -n <aap-namespace> <pod> -- tracepath <target-ip>
```

### Test SSH Verbosely
```bash
oc exec -it -n <aap-namespace> <pod> -- ssh -vvv -o ConnectTimeout=10 <target-host>
```

## Quick Fixes

> **Important:** SSH has limited direct control over MTU/packet sizes. Valid SSH options work by influencing QoS, compression, and connection management. For best results, combine with network-level fixes (MSS clamping).

### Fix 1: SSH Configuration in Inventory (Recommended)
```yaml
# Add to AAP inventory host variables
# IPQoS throughput = Prioritize bulk data over latency
ansible_ssh_common_args: '-o IPQoS=throughput'

# Or with compression
ansible_ssh_common_args: '-o IPQoS=throughput -o Compression=yes'
```

### Fix 2: Test SSH with MTU Workaround
```bash
# From AAP pod
ssh -o IPQoS=throughput -o Compression=yes <target-host>
```

### Fix 3: Ansible Configuration with Pipelining
```ini
# In ansible.cfg in AAP project
[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o IPQoS=throughput -o Compression=yes
```

### Fix 4: Environment Variable
```bash
# Set in AAP job template environment
ANSIBLE_SSH_ARGS='-o IPQoS=throughput -o Compression=yes'
```

**Valid SSH Options for MTU Issues:**
- `IPQoS=throughput` - QoS for bulk transfers (most effective)
- `Compression=yes` - Reduce payload size
- `ControlMaster=auto` - Connection reuse
- `ControlPersist=60s` - Keep connections alive
- `ServerAliveInterval=30` - Keepalive packets

**Invalid Options** (not recognized by SSH):
- ❌ `TCPRcvBuf` - System-level TCP parameter, not SSH option
- ❌ `TCPSndBuf` - System-level TCP parameter, not SSH option
- ❌ `MTU` - Network interface setting, not SSH option

## Common MTU Values

| Network Type | Cluster MTU | Node MTU | Notes |
|--------------|-------------|----------|-------|
| Standard Ethernet | 1400 | 1500 | OVN overlay (default) |
| Jumbo Frames | 8900 | 9000 | High-performance networks |
| VPN/Tunnel | 1350-1400 | 1500 | Varies by tunnel overhead |
| Cloud (AWS) | 1400 | 1500 | Standard for most regions |
| Cloud (Azure) | 1400 | 1500 | Standard configuration |

## Packet Size Math

```
Packet Size = Payload + IP Header (20) + Protocol Header (8 for ICMP)
Example: ping -s 1472 = 1472 + 20 + 8 = 1500 byte packet

For TCP (SSH): Payload + IP Header (20) + TCP Header (20) = Total
Example: 1460 bytes payload = 1500 byte packet
```

## Interpretation Guide

### Ping Test Results
- ✅ `1472` works = No MTU issues (path supports 1500)
- ⚠️ `1400` works, `1472` fails = Path MTU is ~1428 (minor issue)
- ❌ `1350` works, `1400` fails = Path MTU is ~1378 (significant issue)
- ❌ Only `<1300` works = Critical MTU constraint

### Tracepath Output
- `pmtu XXXX` = MTU discovered successfully
- `no reply` = ICMP blocked (PMTUD failure)
- `too big` = Fragmentation needed (PMTUD working)
- `asymm` = Asymmetric routing or MTU

### SSH Behavior
- Hangs after "Authentication succeeded" = **Classic MTU symptom**
- "Connection timeout" = Routing/firewall issue
- "Connection refused" = SSH service down/blocked
- "Permission denied" = Auth issue (not MTU)

## One-Liner Diagnostic Script

```bash
# Complete MTU test from pod
AAP_NS="<namespace>"; TARGET="<target-ip>"; POD=$(oc get pods -n $AAP_NS -l app=automation-job -o name | head -1); echo "Testing MTU from $POD to $TARGET"; for s in 1472 1450 1428 1400 1350; do echo -n "Size $s (MTU $((s+28))): "; oc exec -n $AAP_NS $POD -- ping -M do -s $s -c 2 -W 2 $TARGET &>/dev/null && echo "✓ OK" || echo "✗ FAIL"; done
```

## Automated Diagnostic

Run full diagnostic script:
```bash
./diagnose-mtu.sh <aap-namespace> <target-host-ip>
```

## Network Team Quick Reference

### Information to Provide Network Team

```
1. Cluster overlay MTU: <run: oc get network.config.openshift.io cluster -o jsonpath='{.status.clusterNetwork[0].mtu}'>
2. Effective path MTU: <result from ping tests>
3. Source network: <OCP cluster network>
4. Destination network: <target host network>
5. Symptom: SSH hangs after authentication
6. Request: Enable TCP MSS clamping or allow ICMP type 3 code 4
```

### MSS Clamping Values
```
If path MTU is 1428: Set MSS to 1388 (1428 - 40)
If path MTU is 1400: Set MSS to 1360 (1400 - 40)
If path MTU is 1350: Set MSS to 1310 (1350 - 40)

Formula: MSS = MTU - 40 (20 IP header + 20 TCP header)
```

## Verification Commands

### After Applying Fix
```bash
# Test SSH with large output
oc exec -n <aap-namespace> <pod> -- ssh <target-host> 'dmesg | tail -100'

# Test file transfer
oc exec -n <aap-namespace> <pod> -- ssh <target-host> 'dd if=/dev/zero bs=1M count=10' > /dev/null

# Run Ansible ad-hoc command with large output
# From AAP UI: Run command: yum list installed
```

## Related Commands

### Debug Node Network
```bash
# Get shell on node
oc debug node/<node-name>
chroot /host

# Check interface MTU
ip link show | grep mtu

# Check OVN interfaces
ip link show ovn-k8s-mp0
ip link show br-ex

# Capture packets
tcpdump -i any -n 'host <target-ip> and (tcp port 22 or icmp)' -w /tmp/capture.pcap
```

### Compare Node vs Pod
```bash
# From node - should work if MTU is pod-specific issue
ping -M do -s 1472 <target-ip> -c 4

# From pod - may fail
oc exec -n <ns> <pod> -- ping -M do -s 1472 <target-ip> -c 4
```

## Emergency Workaround

If nothing else works, apply SSH settings directly to running pod:
```bash
# Apply SSH optimizations to current pod
oc exec -n <aap-namespace> <pod> -- sh -c "echo 'IPQoS throughput' >> /etc/ssh/ssh_config"
oc exec -n <aap-namespace> <pod> -- sh -c "echo 'Compression yes' >> /etc/ssh/ssh_config"

# Note: This persists only for the current pod - better to fix in execution environment image
```

**Better approach:** Build a custom execution environment with these settings baked in (see README.md Strategy 1, Option C).

## Technical Notes

### SSH and MTU: What You Need to Know

**SSH cannot directly control MTU, packet sizes, or TCP buffers.** These are kernel-level settings. 

**What SSH options actually do:**
- `IPQoS=throughput` - Sets DSCP bits for QoS (may help routers handle traffic better)
- `Compression=yes` - Reduces payload size (indirectly helps with MTU)
- `ControlMaster/Persist` - Reuses connections (fewer handshakes = fewer issues)

**Real solutions for MTU issues:**
1. Network-level MSS clamping (best)
2. ICMP unblocking for PMTUD (best)
3. Interface MTU adjustment (disruptive)
4. SSH workarounds (symptom relief only)

See README.md "Understanding SSH's Limited MTU Control" for detailed explanation.

---

## Documentation Links

- Full guide: `README.md`
- Real scenarios: `EXAMPLES.md`
- Technical explanation: `README.md` → "Understanding SSH's Limited MTU Control"
- OpenShift MTU docs: https://docs.openshift.com/container-platform/latest/networking/changing-cluster-network-mtu.html

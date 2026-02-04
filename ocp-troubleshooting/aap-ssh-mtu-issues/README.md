# Troubleshooting: SSH Connection Issues from AAP on OpenShift

> **AI Disclosure:** This documentation was created with AI assistance (Claude 3.5 Sonnet via Cursor) on 2026-02-04.

## Overview

When running Ansible Automation Platform (AAP) on OpenShift, SSH connections to target hosts may fail or hang due to Maximum Transmission Unit (MTU) mismatches between the cluster network and external networks. This guide provides systematic diagnostics and resolution steps.

## Scope

This guide covers:
- SSH connection failures from AAP execution pods to external hosts
- Connection hangs after authentication
- Intermittent connectivity issues
- SCP/SFTP transfer failures
- MTU-related packet fragmentation problems

## Severity

**MEDIUM-HIGH** - Prevents automation workflows from executing successfully. Can impact production deployments and remediation tasks.

## Symptoms

### Connection-Level Issues
- SSH connects but hangs after password/key authentication
- Connection established but no command output appears
- `ssh` command times out after initial handshake
- Works for some hosts but not others on the same network

### Data Transfer Issues
- Small commands (`hostname`, `date`) work but large outputs freeze
- File transfers (SCP/SFTP) start but stall partway through
- Ansible playbooks fail inconsistently on tasks that produce output
- `yum`/`dnf` operations hang during package downloads

### Network-Specific Patterns
- Connections work to hosts on same subnet/VLAN
- Failures correlate with hosts across routers/firewalls
- Issues appear after network equipment changes
- Problem exists from pods but not from cluster nodes directly

## Root Cause

**Path MTU Discovery (PMTUD) Failure**: OVN-Kubernetes overlay networks typically use MTU 1400 (100 bytes less than standard 1500 to accommodate Geneve encapsulation overhead). When packets traverse networks with different MTU values and ICMP "fragmentation needed" messages are blocked by firewalls, TCP connections fail or hang.

### Why SSH is Particularly Affected

1. **Initial handshake** uses small packets (works fine)
2. **After authentication**, SSH switches to encrypted bulk data transfer
3. **Larger packets** hit MTU limits and need fragmentation
4. **ICMP responses blocked** = PMTUD fails = connection hangs

> **Technical Note:** SSH itself has limited direct control over packet sizes and MTU. The operating system's TCP/IP stack handles fragmentation and PMTUD. SSH configuration options can influence behavior indirectly (e.g., via Quality of Service settings, compression, or connection multiplexing), but cannot directly set TCP buffer sizes or MTU values.

---

## 🚀 Quick Links

- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - One-line diagnostics and quick fixes
- **[diagnose-mtu.sh](diagnose-mtu.sh)** - Automated diagnostic script
- **[EXAMPLES.md](EXAMPLES.md)** - Real-world scenarios and solutions
- **[MTU-NODE-CONFIGURATION.md](MTU-NODE-CONFIGURATION.md)** - Can I configure nodes differently? (No, here's why)

---

## 🚨 Emergency Quick Checks - Run This First

### 1. Quick MTU Test from AAP Pod

```bash
# First, identify your AAP execution/job pods
oc get pods -n <aap-namespace>

# Look for pods with names containing: job, executor, task, or ee (execution environment)
# Then use the actual pod name, or use this flexible selector:
AAP_POD=$(oc get pods -n <aap-namespace> --field-selector=status.phase=Running -o name | grep -iE "job|executor|task|ee" | head -1)

# Test with ping (adjust target IP)
oc exec -n <aap-namespace> $AAP_POD -- ping -M do -s 1472 <target-host-ip> -c 4

# If ping with 1472 fails, try smaller sizes
oc exec -n <aap-namespace> $AAP_POD -- ping -M do -s 1400 <target-host-ip> -c 4
oc exec -n <aap-namespace> $AAP_POD -- ping -M do -s 1350 <target-host-ip> -c 4
```

> **Note:** Pod labels vary by AAP version and deployment method. AAP 2.x operator deployments may use different naming conventions. Always verify pod names in your specific environment.

**Interpretation:**
- ✅ `1472 bytes` succeeds = No MTU issues (effective MTU is 1500)
- ⚠️ `1400 bytes` succeeds but `1472` fails = MTU path limit is ~1428
- ❌ Only smaller sizes work = Significant MTU constraint in path

### 2. Check Cluster MTU Configuration

```bash
# Check cluster network MTU
oc get network.config.openshift.io cluster -o jsonpath='{.status.clusterNetwork[0].mtu}'

# Check OVN overlay MTU
oc get network.operator.openshift.io cluster -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.mtu}'
```

**Expected Values:**
- Standard Ethernet: `1400` (cluster) / `1500` (node)
- Jumbo Frames: `8900` (cluster) / `9000` (node)

---

## Investigation Workflow

### Phase 1: Confirm MTU as Root Cause

#### Step 1: Test Path MTU Discovery

```bash
# Get shell in AAP execution pod
AAP_POD=$(oc get pods -n <aap-namespace> -l app=automation-job -o name | head -1)
oc exec -it -n <aap-namespace> $AAP_POD -- bash

# Inside pod - test PMTUD to target
tracepath <target-host-ip>
```

**Look for:**
- `pmtu XXXX` showing MTU discovered at each hop
- `no reply` indicating ICMP filtering
- `too big` messages (indicates PMTUD working)
- Asymmetric MTU values

**Example Output:**
```
 1:  10.128.0.1          0.123ms pmtu 1400
 2:  192.168.1.1         1.234ms 
 3:  192.168.100.50      2.345ms pmtu 1428
     Resume: pmtu 1428 hops 3 back 3
```

This shows the path MTU dropped to 1428 at hop 3.

#### Step 2: Test with Progressive Packet Sizes

```bash
# Still inside AAP pod
# Test incrementally to find exact MTU limit
for size in 1472 1450 1428 1400 1350 1300; do
  echo "Testing MTU with $size byte payload..."
  if ping -M do -s $size -c 2 -W 2 <target-host-ip> > /dev/null 2>&1; then
    echo "✓ Success with $size bytes (MTU=$(($size + 28)))"
    break
  else
    echo "✗ Failed with $size bytes"
  fi
done
```

**Packet Size Math:**
- Payload size + 20 (IP header) + 8 (ICMP header) = Total packet size
- Example: `-s 1472` + 28 bytes overhead = 1500 byte packet

#### Step 3: Test SSH with Verbose Output

```bash
# From AAP pod - verbose SSH to see where it hangs
ssh -vvv -o ConnectTimeout=10 <target-host>

# Watch for:
# - "debug1: Authentication succeeded" (auth worked)
# - Hang after "Requesting [exec]" (MTU issue symptom)
```

### Phase 2: Verify Cluster Configuration

#### Step 1: Check OVN-Kubernetes MTU Settings

```bash
# Get full cluster network configuration
oc get network.config.openshift.io cluster -o yaml

# Check for MTU-related settings
oc get network.operator.openshift.io cluster -o yaml | grep -A 5 mtu
```

**Key Fields:**
```yaml
spec:
  defaultNetwork:
    ovnKubernetesConfig:
      mtu: 1400              # Overlay network MTU
      gatewayConfig:
        routingViaHost: false
```

#### Step 2: Check Node-Level MTU

```bash
# Pick a node running AAP pods
NODE=$(oc get pods -n <aap-namespace> -o wide | grep automation | head -1 | awk '{print $7}')

# Debug into node
oc debug node/$NODE

# Inside debug pod
chroot /host

# Check MTU on interfaces
ip link show | grep mtu

# Check OVN interfaces specifically
ip link show ovn-k8s-mp0 | grep mtu
ip link show br-ex | grep mtu
```

**Expected:**
- Physical interfaces (ens*, eth*): `mtu 1500` (or `9000` for jumbo)
- OVN overlay (ovn-k8s-mp0): `mtu 1400` (or `8900` for jumbo)
- Bridge (br-ex): Should match physical

#### Step 3: Verify Pod Network MTU

```bash
# From AAP pod
ip link show eth0 | grep mtu

# Should show mtu 1400 (for standard config)
# If mtu 1500, this is WRONG for OVN overlay
```

### Phase 3: Check External Network Path

#### Step 1: Test from Cluster Node (Bypass Pod Network)

```bash
# From your workstation
NODE=$(oc get nodes -l node-role.kubernetes.io/worker -o name | head -1)

# SSH to node (if possible)
oc debug $NODE

chroot /host

# Test ping with DF flag from node
ping -M do -s 1472 <target-host-ip> -c 4

# Test SSH from node
ssh -v <target-host>
```

**Interpretation:**
- ✅ Works from node but fails from pod = Pod MTU misconfiguration
- ❌ Fails from both = External network/firewall issue
- ✅ Works from both = Not MTU issue (investigate SSH config)

#### Step 2: Check for ICMP Filtering

```bash
# Capture packets on node while testing from pod
# On node (in debug pod, chrooted)
tcpdump -i any -n icmp and host <target-host-ip>

# In another terminal, test from pod
oc exec -n <aap-namespace> $AAP_POD -- ping -M do -s 1472 <target-host-ip> -c 4
```

**Look for:**
- `ICMP type 3 code 4` (Fragmentation Needed) messages
- If you see requests but no replies = ICMP blocked
- If you see neither = Routing issue

### Phase 4: AAP-Specific Checks

#### Step 1: Check AAP Execution Environment MTU

```bash
# List AAP execution pods
oc get pods -n <aap-namespace> -l app=automation-job

# Check MTU in multiple pods (should be consistent)
for pod in $(oc get pods -n <aap-namespace> -l app=automation-job -o name); do
  echo "=== $pod ==="
  oc exec -n <aap-namespace> $pod -- ip link show eth0 | grep mtu
done
```

#### Step 2: Test with Ansible Direct Command

```bash
# From AAP UI or CLI, run ad-hoc command
# Command: ip link show | grep mtu
# Should show MTU of target host interfaces

# Compare with pod MTU
```

---

## Resolution Strategies

### Strategy 1: Configure Ansible to Handle MTU (Recommended)

> **Important:** SSH configuration has limited direct control over MTU and packet sizes. These options work by influencing network behavior indirectly through Quality of Service (QoS) settings, compression, and connection management. For most cases, combining these with network-level fixes (Strategy 3) provides the best results.

#### Option A: Inventory-Level SSH Configuration

Add to your AAP inventory host variables:

```yaml
# In inventory host vars or group vars
# IPQoS throughput = Better handling of bulk data transfers
ansible_ssh_common_args: '-o IPQoS=throughput'
```

Or with compression (can help with larger payloads):

```yaml
ansible_ssh_common_args: '-o IPQoS=throughput -o Compression=yes'
```

**Valid SSH Options for MTU-Related Issues:**
- `IPQoS=throughput` - Sets QoS to prioritize throughput over latency
- `Compression=yes` - Enables compression (reduces effective payload size)
- `ControlMaster=auto` - Reuses connections (reduces handshakes)
- `ControlPersist=60s` - Keeps connections alive

**Note:** Options like `TCPRcvBuf`, `TCPSndBuf`, and direct MTU settings are **not valid SSH options**. These must be configured at the system/network level.

#### Option B: Ansible Configuration with Pipelining

In your AAP project, add `ansible.cfg`:

```ini
[defaults]
host_key_checking = False

[ssh_connection]
# Enable pipelining to reduce connection overhead
pipelining = True
# SSH arguments for MTU-constrained networks
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o IPQoS=throughput -o Compression=yes
```

**Why pipelining helps:** Reduces the number of SSH connections by sending multiple commands over a single connection, decreasing the likelihood of MTU-related handshake issues.

#### Option C: Execution Environment Custom Image

Create custom EE with optimized SSH settings:

```dockerfile
# Add to your EE definition
FROM quay.io/ansible/awx-ee:latest

# Configure SSH client for MTU-constrained networks
RUN echo 'Host *' >> /etc/ssh/ssh_config && \
    echo '  IPQoS throughput' >> /etc/ssh/ssh_config && \
    echo '  Compression yes' >> /etc/ssh/ssh_config && \
    echo '  ServerAliveInterval 30' >> /etc/ssh/ssh_config && \
    echo '  ServerAliveCountMax 3' >> /etc/ssh/ssh_config

# Configure Ansible for pipelining
RUN echo '[ssh_connection]' >> /etc/ansible/ansible.cfg && \
    echo 'pipelining = True' >> /etc/ansible/ansible.cfg && \
    echo 'ssh_args = -o ControlMaster=auto -o ControlPersist=60s' >> /etc/ansible/ansible.cfg
```

**Build and deploy:**
```bash
podman build -t quay.io/myorg/aap-ee-mtu-optimized:latest .
podman push quay.io/myorg/aap-ee-mtu-optimized:latest
```

### Strategy 2: Adjust Cluster MTU (Requires Cluster Restart)

⚠️ **Warning:** Changing cluster MTU requires cluster restart and affects all workloads.

> **Important:** MTU changes apply to the **entire cluster**. You cannot configure individual nodes with different MTU values. See [MTU-NODE-CONFIGURATION.md](MTU-NODE-CONFIGURATION.md) for detailed explanation.

```bash
# Check current MTU migration status
oc get network.operator.openshift.io cluster -o yaml | grep -A 10 migration

# Initiate MTU change (example: 1400 -> 1300)
# This affects ALL nodes in the cluster
oc patch network.operator.openshift.io cluster --type=merge --patch '
spec:
  migration:
    mtu:
      network:
        from: 1400
        to: 1300
      machine:
        to: 1300
'
```

**This is DISRUPTIVE.** Only do this if:
1. Other strategies don't work
2. You have maintenance window
3. MTU mismatch is confirmed and unavoidable
4. Business approves cluster restart
5. **All nodes** in cluster can support the new MTU

### Strategy 3: Configure MSS Clamping on Network Equipment

Work with network team to enable TCP MSS clamping on routers/firewalls between OpenShift and target networks:

```
# Example (Cisco)
interface GigabitEthernet0/1
  ip tcp adjust-mss 1360

# Example (Linux iptables)
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYS \
  -j TCPMSS --set-mss 1360
```

This forces TCP to use smaller segment sizes without requiring MTU changes.

### Strategy 4: Enable PMTUD on Network Path

Request network team to:
1. Allow ICMP Type 3 Code 4 (Fragmentation Needed) between networks
2. Verify firewalls don't block ICMP unreachable messages
3. Check that all routers properly decrement TTL

---

## Verification

### Test 1: Verify SSH Connectivity

```bash
# From AAP pod with fix applied
oc exec -it -n <aap-namespace> $AAP_POD -- bash

# Test SSH connection
ssh <target-host> 'echo "Connection successful"; ls -lah /tmp'

# Test with large output
ssh <target-host> 'cat /var/log/messages | head -1000'
```

### Test 2: Run Ansible Playbook

```yaml
---
# test-mtu-fix.yml
- name: Verify MTU Fix
  hosts: all
  gather_facts: yes
  tasks:
    - name: Check connectivity with large output
      shell: |
        dmesg | tail -100
      register: result
    
    - name: Display result
      debug:
        var: result.stdout_lines
    
    - name: Test file transfer
      copy:
        content: "{{ 'X' * 10000 }}"
        dest: /tmp/mtu-test.txt
```

Run from AAP:
```bash
ansible-playbook -i inventory test-mtu-fix.yml -v
```

### Test 3: Verify PMTUD

```bash
# Should now complete without errors
oc exec -n <aap-namespace> $AAP_POD -- tracepath <target-host-ip>

# Verify consistent MTU end-to-end
```

---

## Understanding SSH's Limited MTU Control

**Important Technical Context:**

SSH is an application-layer protocol that has **limited direct control** over packet sizes, MTU, and TCP behavior. The confusion often arises because SSH documentation and forums discuss "MTU issues," but the actual control mechanisms are at lower network layers:

### What SSH CAN Control:
- **QoS/DSCP markings** (via `IPQoS`) - Influences how routers prioritize packets
- **Compression** - Reduces payload size before encryption
- **Connection multiplexing** (via `ControlMaster`) - Reuses connections, reducing handshakes
- **Keepalive settings** - Maintains connections with small packets

### What SSH CANNOT Control:
- **MTU values** - Set at network interface level by the kernel
- **TCP buffer sizes** - System-level parameters (`net.ipv4.tcp_*` sysctl values)
- **Packet fragmentation** - Handled by the IP layer in the kernel
- **PMTUD behavior** - Controlled by kernel TCP/IP stack

### Why SSH Options Help Anyway:

1. **IPQoS=throughput**: Changes DSCP bits in IP headers, potentially avoiding QoS policies that throttle or drop packets
2. **Compression=yes**: Smaller encrypted payloads mean less likelihood of hitting MTU limits
3. **Pipelining**: Fewer connection handshakes = fewer opportunities for MTU-related failures
4. **ControlMaster**: Connection reuse reduces the number of times PMTUD must occur

### The Real Solutions:

For persistent MTU issues, you need **network-level fixes**:
- MSS clamping on routers/firewalls (forces smaller TCP segments)
- ICMP unblocking (allows PMTUD to work correctly)
- Interface MTU adjustment (kernel-level setting)

SSH configuration provides **workarounds** that reduce symptom frequency but don't address root causes.

---

## Prevention

### 1. Document Network MTU Requirements

Create network documentation including:
- Cluster MTU configuration (default 1400 for OVN)
- Required MTU for external networks
- Any jumbo frame usage
- ICMP filtering policies

### 2. Test MTU During Cluster Deployment

Include MTU tests in cluster validation:

```bash
# Add to cluster validation suite
oc apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: mtu-test
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot
    command: ["/bin/sleep", "3600"]
EOF

# Run tests from pod
oc exec mtu-test -- ping -M do -s 1472 <critical-host-ip>
```

### 3. Configure AAP Projects with MTU Handling

Include in all AAP projects' `ansible.cfg`:

```ini
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o IPQoS=throughput
```

### 4. Monitor for MTU Issues

Set up alerts for SSH connection timeouts:

```yaml
# Prometheus alert rule
- alert: HighSSHTimeouts
  expr: rate(ansible_playbook_ssh_errors[5m]) > 0.1
  annotations:
    summary: "High SSH timeout rate in AAP"
    description: "May indicate MTU issues"
```

### 5. Network Change Control

Require MTU impact analysis for:
- Firewall rule changes
- Router upgrades
- VLAN reconfigurations
- Network segmentation changes

---

## Common Scenarios

### Scenario 1: Works to Some Hosts But Not Others

**Diagnosis:**
- Hosts that work are on same subnet as cluster
- Hosts that fail are across routers

**Solution:** Configure MSS clamping on router or use Strategy 1 (Ansible SSH config)

### Scenario 2: SSH Hangs After Authentication

**Diagnosis:**
```bash
ssh -vvv target-host
# Shows:
# debug1: Authentication succeeded (publickey)
# debug1: channel 0: new [client-session]
# debug1: Requesting [exec]
# [HANGS HERE]
```

**Solution:** Classic MTU issue. Apply Strategy 1.

### Scenario 3: Small Playbooks Work, Large Ones Fail

**Diagnosis:**
- Playbooks with minimal output succeed
- Playbooks with package installs or large file transfers fail

**Solution:** MTU limiting bulk transfers. Apply Strategy 1 or 3.

### Scenario 4: Inconsistent Failures

**Diagnosis:**
- Same playbook sometimes works, sometimes fails
- Correlates with different execution pods

**Solution:** Pod-to-pod MTU inconsistency. Check pod network MTU.

---

## Reference Commands

### Get AAP Execution Pod
```bash
oc get pods -n <aap-namespace> -l app=automation-job
```

### Test MTU from Pod
```bash
oc exec -n <aap-namespace> <pod-name> -- ping -M do -s 1472 <target-ip> -c 4
```

### Check Cluster MTU
```bash
oc get network.config.openshift.io cluster -o yaml | grep mtu
```

### Test SSH from Pod
```bash
oc exec -it -n <aap-namespace> <pod-name> -- ssh -v <target-host>
```

### Capture Packets on Node
```bash
oc debug node/<node-name>
chroot /host
tcpdump -i any -n 'host <target-ip> and (tcp port 22 or icmp)'
```

---

## Additional Resources

### OpenShift Documentation
- [Changing Cluster Network MTU](https://docs.openshift.com/container-platform/latest/networking/changing-cluster-network-mtu.html)
- [OVN-Kubernetes Network Plugin](https://docs.openshift.com/container-platform/latest/networking/ovn_kubernetes_network_provider/about-ovn-kubernetes.html)

### Ansible Documentation
- [SSH Connection Options](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ssh_connection.html)
- [Ansible Configuration](https://docs.ansible.com/ansible/latest/reference_appendices/config.html)

### Network Fundamentals
- [Path MTU Discovery (RFC 1191)](https://tools.ietf.org/html/rfc1191)
- [TCP MSS Clamping](https://www.cisco.com/c/en/us/support/docs/ip/generic-routing-encapsulation-gre/25885-pmtud-ipfrag.html)

---

## Frequently Asked Questions

### Q: Can I configure individual nodes with different MTU?

**A: No.** All nodes in an OpenShift cluster must have the same cluster network MTU. Having mismatched MTU between nodes will break pod-to-pod communication and cause cluster instability.

**Why?** The OVN-Kubernetes overlay network spans all nodes and requires uniform MTU configuration.

**Alternative:** Use network-level solutions (MSS clamping, ICMP unblocking) instead. See [MTU-NODE-CONFIGURATION.md](MTU-NODE-CONFIGURATION.md) for detailed explanation.

### Q: Can I have dedicated AAP worker nodes with special network configuration?

**A: Yes, but with limitations.**

You can:
- ✅ Label specific nodes for AAP workloads
- ✅ Configure node-level routes to external networks
- ✅ Add additional network interfaces

You cannot:
- ❌ Use different cluster network MTU on those nodes
- ❌ Run different OVN overlay MTU per node

See [MTU-NODE-CONFIGURATION.md](MTU-NODE-CONFIGURATION.md) for examples.

### Q: Why don't SSH options like `TCPRcvBuf` work?

**A:** These are system-level TCP parameters, not SSH configuration options. SSH cannot directly control TCP buffer sizes or MTU values.

**What works:** Valid SSH options like `IPQoS=throughput` and `Compression=yes` influence network behavior indirectly.

See [TECHNICAL-ACCURACY-REVIEW.md](TECHNICAL-ACCURACY-REVIEW.md) for details.

### Q: What's the best way to fix AAP SSH MTU issues?

**A:** In priority order:

1. **Network-level fixes** (work with network team)
   - MSS clamping on routers/firewalls
   - ICMP unblocking for PMTUD

2. **SSH/Ansible configuration** (immediate workarounds)
   - `ansible_ssh_common_args: '-o IPQoS=throughput -o Compression=yes'`
   - Enable pipelining in ansible.cfg

3. **Cluster MTU change** (last resort, disruptive)
   - Only if external network requires different MTU
   - Affects entire cluster
   - Requires maintenance window

---

## Related Issues

- [coreos-networking-issues](../coreos-networking-issues/) - General CoreOS/RHCOS networking problems
- [api-slowness-web-console](../api-slowness-web-console/) - API performance issues (may include network problems)

---

**Last Updated:** 2026-02-04  
**Tested Versions:** OpenShift 4.12-4.16, AAP 2.4-2.5

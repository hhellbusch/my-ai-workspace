# Technical Accuracy Review - AAP SSH MTU Issues Documentation

**Review Date:** 2026-02-04  
**Reviewer:** AI-assisted technical accuracy check

## Summary

This documentation underwent a technical accuracy review after initial creation. Several corrections were made to ensure recommendations are technically sound and align with actual SSH capabilities and OpenShift/OVN-Kubernetes behavior.

---

## Issues Identified and Corrected

### 1. Invalid SSH Configuration Options ❌ → ✅

**Problem Found:**
The initial documentation recommended SSH options that don't actually exist in OpenSSH:
- `TCPRcvBuf` (not a valid SSH option)
- `TCPSndBuf` (not a valid SSH option)

**Why This Happened:**
These are valid **system-level TCP parameters** (Linux sysctl settings like `net.ipv4.tcp_rmem`), but they are **not SSH configuration options**. SSH cannot directly set TCP buffer sizes.

**Correction Applied:**
Replaced with valid SSH options:
```yaml
# INCORRECT (original)
ansible_ssh_common_args: '-o TCPRcvBuf=262144 -o TCPSndBuf=262144'

# CORRECT (revised)
ansible_ssh_common_args: '-o IPQoS=throughput -o Compression=yes'
```

**Valid SSH Options for MTU-Related Issues:**
- ✅ `IPQoS=throughput` - Sets QoS/DSCP bits in IP headers
- ✅ `Compression=yes` - Enables data compression
- ✅ `ControlMaster=auto` - Connection multiplexing
- ✅ `ControlPersist=60s` - Keep connections alive
- ✅ `ServerAliveInterval=30` - Keepalive packets
- ✅ `ServerAliveCountMax=3` - Keepalive retry count

**Invalid Options Removed:**
- ❌ `TCPRcvBuf` - System setting, not SSH option
- ❌ `TCPSndBuf` - System setting, not SSH option
- ❌ `MTU` - Interface setting, not SSH option

**Files Updated:**
- `README.md` - Strategy 1 section
- `QUICK-REFERENCE.md` - All Quick Fixes
- `EXAMPLES.md` - All 6 examples
- `diagnose-mtu.sh` - Recommendations section

---

### 2. AAP Pod Label Selector Accuracy ⚠️ → ✅

**Problem Found:**
Documentation used `app=automation-job` as the pod label selector without verification.

**Why This Is Problematic:**
AAP 2.x deployments use the Ansible Automation Platform Operator, which creates pods with varying labels depending on:
- AAP version (2.3, 2.4, 2.5)
- Deployment method (operator vs manual)
- Custom resource naming
- Installation configuration

**Correction Applied:**
Made pod selection more flexible and documented the variation:

```bash
# INCORRECT (original) - assumed specific label
AAP_POD=$(oc get pods -n <namespace> -l app=automation-job -o name | head -1)

# CORRECT (revised) - flexible search with user verification
# First list pods for user to identify
oc get pods -n <namespace>

# Then use flexible selector
AAP_POD=$(oc get pods -n <namespace> --field-selector=status.phase=Running -o name | grep -iE "job|executor|task|ee" | head -1)
```

**Added Notes:**
- Pod naming varies by AAP version and deployment method
- Users should verify pod names in their specific environment
- Examples include: job pods, executor pods, task pods, execution environment (ee) pods

**Files Updated:**
- `README.md` - Quick checks section
- `QUICK-REFERENCE.md` - Pod finder command
- `diagnose-mtu.sh` - Pod detection logic

---

### 3. OVN-Kubernetes MTU Documentation ✅

**Verified Correct:**
- OVN-Kubernetes uses **100 bytes of encapsulation overhead** for Geneve protocol
- Standard configuration: **MTU 1400** for overlay on **MTU 1500** physical network
- Jumbo frames: **MTU 8900** for overlay on **MTU 9000** physical network

**Source:** OpenShift official documentation
- https://docs.openshift.com/container-platform/latest/networking/changing-cluster-network-mtu.html

**No changes required** - this was already accurate.

---

## New Content Added

### Section: "Understanding SSH's Limited MTU Control"

Added comprehensive explanation to `README.md` clarifying:

**What SSH CAN Control:**
- Quality of Service (QoS) markings via IPQoS
- Data compression
- Connection multiplexing and reuse
- Keepalive behavior

**What SSH CANNOT Control:**
- MTU values (kernel/interface setting)
- TCP buffer sizes (sysctl parameters)
- Packet fragmentation (IP layer function)
- Path MTU Discovery behavior (kernel TCP/IP stack)

**Why SSH Options Help Anyway:**
- IPQoS changes packet priority handling by routers
- Compression reduces payload size before encryption
- Connection reuse reduces handshake opportunities for failure
- Keepalives maintain connections with small packets

**The Real Solutions:**
For persistent MTU issues, **network-level fixes** are required:
1. MSS clamping on routers/firewalls (best solution)
2. ICMP unblocking for proper PMTUD (best solution)
3. Interface MTU adjustment (disruptive, last resort)
4. SSH workarounds (symptom relief only)

---

## Technical Notes Added Throughout Documentation

### README.md
- Added technical context about SSH's limited MTU control
- Emphasized network-level solutions as primary fixes
- Clarified that SSH options are workarounds, not direct solutions
- Added notes about OVN-Kubernetes Geneve encapsulation

### QUICK-REFERENCE.md
- Added "Technical Notes" section
- Listed valid vs invalid SSH options with explanations
- Added cross-reference to detailed technical explanation
- Clarified what each SSH option actually does

### EXAMPLES.md
- Added technical accuracy note at top
- Added explanatory notes to each example
- Clarified why each approach works (or doesn't)
- Emphasized network-level solutions in all scenarios

### diagnose-mtu.sh
- Updated recommendations to use valid SSH options
- Added note about SSH's limited MTU control
- Improved pod detection with flexible search
- Added warnings about pod naming variations

### INDEX.md
- Added "Technical Accuracy Notes" section
- Documented what was verified/corrected
- Added cross-references to technical explanations

---

## Verification Sources

### OpenSSH Configuration
- Verified against `ssh_config(5)` man pages
- Sources: OpenBSD, Ubuntu, Linux, NetBSD official documentation
- Confirmed valid SSH options and rejected invalid ones

### OpenShift/OVN-Kubernetes
- Verified against Red Hat OpenShift documentation
- Confirmed 100-byte Geneve encapsulation overhead
- Verified MTU calculation: physical MTU - 100 = overlay MTU

### Ansible Automation Platform
- Reviewed AAP 2.x operator deployment documentation
- Confirmed pod labeling varies by version and deployment method
- Verified ansible_ssh_common_args variable usage

---

## Impact Assessment

### Documentation Accuracy: HIGH IMPACT
- **Before:** Recommended non-existent SSH options
- **After:** All SSH options verified as valid and functional

### User Experience: MEDIUM-HIGH IMPACT
- **Before:** Users would try invalid options and get errors
- **After:** Users get working configurations immediately

### Educational Value: HIGH IMPACT
- **Before:** Misled users about SSH's capabilities
- **After:** Clear explanation of what SSH can/cannot control

### Troubleshooting Effectiveness: MEDIUM IMPACT
- **Before:** Focus on SSH-only solutions (limited effectiveness)
- **After:** Emphasis on network-level solutions (most effective)

---

## Recommendations for Users

### If You Used the Original Documentation

**Check your configurations for these invalid options:**
```yaml
# Remove these - they don't work
ansible_ssh_common_args: '-o TCPRcvBuf=262144 -o TCPSndBuf=262144'
```

**Replace with valid options:**
```yaml
# Use these instead
ansible_ssh_common_args: '-o IPQoS=throughput -o Compression=yes'
```

**Add pipelining for better results:**
```ini
# In ansible.cfg
[ssh_connection]
pipelining = True
ssh_args = -o IPQoS=throughput -o Compression=yes
```

### For Persistent Issues

**Work with your network team to implement:**
1. **MSS Clamping** on routers/firewalls (most effective)
   ```
   # MSS = MTU - 40 (20 byte IP header + 20 byte TCP header)
   # For MTU 1400: MSS = 1360
   ```

2. **ICMP Unblocking** (allow Type 3 Code 4 "Fragmentation Needed")
   - Required for Path MTU Discovery to work properly

3. **MTU Adjustment** (if other options exhausted)
   - Most disruptive option
   - Requires cluster maintenance window

---

## Testing Recommendations

### Verify Your Configuration

**Test SSH with your current settings:**
```bash
# From AAP pod
oc exec -it -n <namespace> <pod> -- ssh -vvv <target-host>

# Look for successful authentication AND data transfer
```

**Test with corrected settings:**
```bash
# Test new valid options
oc exec -it -n <namespace> <pod> -- ssh -o IPQoS=throughput -o Compression=yes <target-host>
```

**Run Ansible playbook test:**
```yaml
# test-ssh-fix.yml
- hosts: all
  tasks:
    - name: Test with large output
      shell: dmesg | tail -100
      register: result
    
    - debug:
        var: result.stdout_lines
```

### Verify Network-Level Fixes

**If you implemented MSS clamping:**
```bash
# Verify MSS in TCP handshake
tcpdump -i any -n 'tcp[tcpflags] & tcp-syn != 0' and host <target-ip>

# Should see MSS values matching your clamping configuration
```

---

## Future Maintenance

### Keep This Documentation Accurate

**When updating:**
1. Verify all SSH options against current OpenSSH documentation
2. Test recommendations in a lab environment before documenting
3. Distinguish between direct solutions and workarounds
4. Keep network-level solutions as primary recommendations

**Monitor for changes:**
- OpenShift OVN-Kubernetes MTU defaults
- AAP operator pod labeling schemes
- OpenSSH new configuration options
- Ansible SSH connection plugin updates

---

## Credits

**Original Documentation:** AI-generated (Claude 3.5 Sonnet via Cursor)  
**Technical Review:** AI-assisted accuracy verification  
**Verification Sources:** OpenSSH documentation, OpenShift documentation, Ansible documentation  
**Review Date:** 2026-02-04

---

## Questions or Issues?

If you find additional technical inaccuracies or have questions about the corrections:

1. Verify against official documentation sources
2. Test in a lab environment
3. Update this documentation with findings
4. Add notes explaining what was corrected and why

**Remember:** Technical accuracy is critical for troubleshooting documentation. When in doubt, consult official sources and test before documenting.

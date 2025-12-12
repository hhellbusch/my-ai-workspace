# Troubleshooting Session Summary: master-2 Inspection Timeout

**Date:** December 3, 2025  
**Issue:** Third master node (master-2) stuck in "inspecting" state during OpenShift bare metal installation  
**Status:** ACTIVE TROUBLESHOOTING - Root cause identified  

---

## 📋 **Current Situation**

### Cluster State
- **Working Nodes:** master-0 and master-1 successfully provisioned
- **Failing Node:** master-2 stuck in `inspecting` state, consistently times out
- **Installation Method:** OpenShift bare metal installation using Bare Metal Operator (BMO)
- **Hardware:** Dell servers with iDRAC BMC and Mellanox NICs

### What We've Confirmed Working ✅
1. **BMC Credentials:** Correct username/password
2. **Network Connectivity:** Can reach iDRAC on the network
3. **Certificate Verification:** Disabled (self-signed certs)
4. **BMC Address Format:** Correct - `idrac-virtualmedia://IP/redfish/v1/Systems/System.Embedded.1`
5. **Power Management:** Fixed - was showing `poweredOn: false` when actually on, manual reboot resolved
6. **Inspection Started:** Node now in `inspecting` state after power cycle

### Current Status
- **BareMetalHost State:** `inspecting` 
- **Inspection Status:** In progress but may be hanging
- **Root Cause Identified:** Mellanox NIC driver error on master-2

---

## 🎯 **ROOT CAUSE IDENTIFIED**

### Critical Error Found on iDRAC Console

```
mlx5_query_module_id:315 query_mcia_reg failed: status 0x3
```

**CONFIRMED: Error is repeating continuously (stuck in retry loop)**

**What this means:**
- Inspection image (IPA - Ironic Python Agent) is querying the Mellanox ConnectX NIC
- The NIC module query is failing (status 0x3 = module not accessible/present)
- **ERROR IS REPEATING = Inspection is STUCK, not just slow**
- Line 315 in mlx5 kernel module is the query function
- System cannot progress past this hardware query

**Why this breaks inspection:**
- Hardware discovery tries to query all NICs in detail
- Mellanox driver query failures can cause retry loops
- May prevent inspection from completing within timeout period

---

## 🔧 **Configuration Details**

### BareMetalHost Configuration

```yaml
spec:
  bmc:
    address: idrac-virtualmedia://[IP_REDACTED]/redfish/v1/Systems/System.Embedded.1
    credentialsName: master-2-bmc-secret
    disableCertificateVerification: true
  online: true  # (after power cycle fix)
  bootMode: UEFI  # (assumed, matches master-0/1)
```

### Container Structure Discovered

OpenShift deployment uses consolidated containers in `openshift-machine-api` namespace:
- **Pod:** `metal3-<id>`
- **Containers:**
  - `metal3-ironic` - All Ironic services (inspector, conductor, API)
  - `metal3-httpd` - HTTP server for images
  - `metal3-ramdisk-logs` - Ramdisk logs

**Note:** NOT separate containers per service (different from some docs)

### Log Access Method

`oc logs` command not working in this environment, using `crictl` instead:

```bash
# From master node (via oc debug):
chroot /host
IRONIC=$(crictl ps | grep metal3-ironic | grep -v httpd | grep -v ramdisk | awk '{print $1}')
crictl logs -f $IRONIC
```

---

## 📝 **Timeline of Troubleshooting**

### Initial Assessment
1. Identified 2/3 masters provisioned, 3rd stuck in `inspecting`
2. Verified credentials and network connectivity
3. Confirmed certificate verification disabled
4. Validated BMC address format correct for Dell iDRAC

### Power State Issue Discovery
5. Found `status.poweredOn: false` but node was actually booted (seen in iDRAC)
6. This indicated Ironic couldn't properly manage power state
7. **Fix Applied:** Manual power cycle to resync state
   - Powered off node via iDRAC
   - Set `spec.online: false` in OpenShift
   - Waited for sync
   - Set `spec.online: true` to let Ironic control power

### Current Phase - NIC Driver Issue
8. Node successfully entered `inspecting` state
9. Discovered Mellanox NIC driver error on iDRAC console
10. Error is repeating, likely causing inspection to hang

---

## 🚀 **Recommended Next Steps (Priority Order)**

### ~~Step 1: Increase Inspection Timeout~~ (SKIP - Won't Help)

**UPDATE:** Error is repeating continuously = stuck in infinite retry loop.
Increasing timeout won't help because inspection will never complete.

**Hardware fix required first.**

### Step 1: Investigate Mellanox NIC Hardware Configuration (PRIORITY)

**Error repeating = hardware misconfiguration causing infinite retry loop**

#### A. Compare NIC Configuration via iDRAC

```
For each master (0, 1, 2):
iDRAC Web Console → System → Network Devices → Mellanox Card

Document:
1. Firmware version
2. How many ports shown
3. Which ports have "Status: Active/Enabled"
4. Which ports have cables/transceivers installed
5. Which ports are empty but enabled
```

#### B. Identify Differences

**Key questions:**
- Does master-2 have different firmware than master-0/1?
- Does master-2 have empty SFP/QSFP slots that are enabled?
- Does master-2 have different transceiver configuration?
- Are there unused transceivers causing detection issues?

#### C. Fix Hardware to Match Working Nodes

**Choose one approach:**

**Option 1: Add missing transceivers** (if master-0/1 have them)
- Install same transceivers in master-2 to match master-0/1

**Option 2: Remove problematic transceivers** (if master-2 has extras)
- Remove any unused transceivers from master-2

**Option 3: Update firmware** (if versions differ)
- Update master-2 Mellanox firmware to match master-0/1
- Reboot after update

**Option 4: Disable unused ports** (quickest workaround)
- Via BIOS or iDRAC: Disable Mellanox ports with no cables
- Or temporarily disable entire Mellanox NIC if not needed

**Option 5: Disable entire NIC temporarily** (if not needed for provisioning)
- BIOS → Network Settings → Disable Mellanox NIC
- Complete inspection/provisioning
- Re-enable NIC after node joins cluster

### Step 2: After Hardware Fix, Force Re-inspection

```bash
# Power off first
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 30

# Clear all state
oc annotate baremetalhost master-2 -n openshift-machine-api \
  baremetalhost.metal3.io/status- \
  baremetalhost.metal3.io/error- \
  --overwrite

# Power back on
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'

# Watch status
watch -n 5 'oc get baremetalhost master-2 -n openshift-machine-api'
```

### Step 3: Monitor Progress (Should be faster now)

**Terminal 1 - Watch BareMetalHost:**
```bash
watch -n 5 'oc get baremetalhost master-2 -n openshift-machine-api'
```

**Terminal 2 - Watch iDRAC Console:**
- Look for the mlx5 error
- Count how many times it appears
- Watch if inspection eventually moves past it
- Look for "hardware inspection complete" or similar

**Terminal 3 - Watch Ironic Logs (from master node):**
```bash
oc debug node/master-0
chroot /host
IRONIC=$(crictl ps | grep metal3-ironic | grep -v httpd | grep -v ramdisk | awk '{print $1}')
crictl logs -f $IRONIC | grep -i "master-2\|inspect\|introspect\|error"
```

### Step 4: Check for Inspection Completion

**Expected timeline after hardware fix:**
- 0-5 min: Node boots inspection image  
- 5-15 min: Hardware discovery (mlx5 errors should NOT repeat continuously)
- 15-25 min: Discovery completes, data sent to Ironic
- 25-30 min: Ironic processes data
- Result: State changes to `available` ✅

**If mlx5 errors still repeat continuously:**
- Hardware fix was not sufficient
- Try more aggressive approach (disable NIC entirely)
- Or proceed to Step 4 (Advanced Workarounds)

### Step 5: Hardware Investigation (If Step 1-4 Don't Work)

#### A. Compare NIC Configuration Across Masters

```bash
# From iDRAC web console for each master:
# 1. Check Mellanox NIC model and firmware version
# 2. Check which ports have cables/transceivers
# 3. Compare master-0, master-1, master-2 for differences
```

**Key questions:**
- Same Mellanox NIC model on all three?
- Same firmware version?
- Same ports populated with cables/SFPs?
- Any unused SFP/QSFP modules in master-2's NIC?

#### B. Physical Hardware Checks

```bash
# If accessible:
# 1. Check for loose or missing SFP/QSFP transceivers in Mellanox NIC
# 2. Try removing any unused transceivers
# 3. Ensure cables are properly seated
# 4. Check for any amber/error LEDs on the NIC
```

#### C. Firmware Update (If Needed)

```bash
# From iDRAC:
# 1. Check current Mellanox NIC firmware version
# 2. If significantly older than master-0/1, update firmware
# 3. Reboot and retry inspection
```

### Step 6: Alternative Workarounds (Advanced)

If hardware can't be changed and inspection still fails:

#### Option A: Skip Detailed NIC Inspection (Complex)
Would require modifying inspection image kernel parameters - not easily done in OpenShift.

#### Option B: Manually Provide Hardware Details
Bypass inspection by manually providing hardware info from a working node:

```bash
# Get hardware details from master-0
oc get baremetalhost master-0 -n openshift-machine-api -o jsonpath='{.status.hardwareDetails}' > master0-hw.json

# Edit master0-hw.json to change serial numbers, MACs, etc. to match master-2

# Patch master-2 with hardware details (this bypasses inspection)
# NOTE: This is a last resort and may cause issues
```

#### Option C: Use Different BMC Protocol
Try standard redfish instead of idrac-virtualmedia:

```bash
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "bmc": {
      "address": "redfish-virtualmedia+https://[IDRAC_IP]/redfish/v1/Systems/System.Embedded.1"
    }
  }
}'
```

---

## 📊 **Diagnostic Commands Reference**

### Check Current Status

```bash
# BareMetalHost status
oc get baremetalhost master-2 -n openshift-machine-api
oc get baremetalhost master-2 -n openshift-machine-api -o yaml

# Current state
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.provisioning.state}'

# Power status
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.poweredOn}'

# Error messages (if any)
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.errorMessage}'

# Recent events
oc get events -n openshift-machine-api \
  --field-selector involvedObject.name=master-2 \
  --sort-by='.lastTimestamp' | tail -20
```

### Access Logs

```bash
# From master node (since oc logs doesn't work):
oc debug node/master-0
chroot /host

# Find metal3-ironic container
crictl ps | grep metal3

# View logs
IRONIC=$(crictl ps | grep metal3-ironic | grep -v httpd | grep -v ramdisk | awk '{print $1}')
crictl logs --tail=200 $IRONIC

# Follow logs
crictl logs -f $IRONIC

# Search for master-2 activity
crictl logs $IRONIC | grep -i master-2

# Search for inspection messages
crictl logs $IRONIC | grep -i "inspect\|introspect"
```

### Force Re-inspection

```bash
# Method 1: Clear status annotation
oc annotate baremetalhost master-2 -n openshift-machine-api \
  baremetalhost.metal3.io/status- \
  --overwrite

# Method 2: Full power cycle with state clear
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 20
oc annotate baremetalhost master-2 -n openshift-machine-api \
  baremetalhost.metal3.io/status- \
  baremetalhost.metal3.io/error- \
  --overwrite
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

### Compare Working vs Failing Node

```bash
# Compare BMC configurations
for master in master-0 master-1 master-2; do
    echo "=== $master ==="
    echo "Address: $(oc get bmh $master -n openshift-machine-api -o jsonpath='{.spec.bmc.address}')"
    echo "Cert Verify Disabled: $(oc get bmh $master -n openshift-machine-api -o jsonpath='{.spec.bmc.disableCertificateVerification}')"
    echo "State: $(oc get bmh $master -n openshift-machine-api -o jsonpath='{.status.provisioning.state}')"
    echo "PoweredOn: $(oc get bmh $master -n openshift-machine-api -o jsonpath='{.status.poweredOn}')"
    echo ""
done

# Full spec diff
diff <(oc get bmh master-0 -n openshift-machine-api -o yaml | grep -A 40 "^spec:") \
     <(oc get bmh master-2 -n openshift-machine-api -o yaml | grep -A 40 "^spec:")
```

---

## 🔍 **What to Watch For**

### Good Signs (Inspection Progressing)

**In BareMetalHost status:**
- State remains `inspecting` (not error)
- `status.poweredOn: true`
- No error messages

**In iDRAC console:**
- Inspection image boots successfully
- Gets IP via DHCP
- mlx5 errors appear but system continues
- Eventually see "hardware inspection complete" or similar
- System may reboot after inspection

**In Ironic logs:**
- "Received introspection data from node"
- "Processing introspection data"
- Node UUID or MAC address appearing in logs
- "Introspection finished successfully"

### Bad Signs (Inspection Stuck/Failed)

**In BareMetalHost status:**
- State changes to `error`
- Error message appears in status
- `status.poweredOn: false` (power management failed again)

**In iDRAC console:**
- mlx5 error repeating endlessly (100+ times)
- System completely frozen
- Kernel panic
- Network timeout ("No DHCP response")
- Boot loop

**In Ironic logs:**
- "Timeout waiting for callback"
- "Introspection timeout"
- "Node not found"
- Repeated errors about master-2
- No callback/heartbeat messages

---

## 📁 **Supporting Documentation**

Full troubleshooting guides created:

1. **[README.md](README.md)** - Complete bare metal inspection troubleshooting guide
2. **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Fast command reference
3. **[YOUR-ISSUE-SUMMARY.md](YOUR-ISSUE-SUMMARY.md)** - Specific to "2 working, 1 failing" scenario
4. **[diagnose-bmh.sh](diagnose-bmh.sh)** - Automated diagnostic script

Related guides:
- **[kube-controller-manager troubleshooting](../kube-controller-manager-crashloop/README.md)** - For other cluster issues

---

## 🎯 **Success Criteria**

You'll know the issue is resolved when:

1. **BareMetalHost state changes from `inspecting` to `available`**
   ```bash
   oc get baremetalhost master-2 -n openshift-machine-api
   # STATE should show: available
   ```

2. **Hardware details are populated**
   ```bash
   oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.hardwareDetails}' | jq .
   # Should show CPU, RAM, disk details
   ```

3. **No error messages**
   ```bash
   oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.errorMessage}'
   # Should be empty
   ```

4. **Node eventually provisions and joins cluster**
   ```bash
   oc get nodes
   # Should eventually see master-2 in the list
   ```

---

## ⚠️ **Known Limitations / Workarounds in This Environment**

1. **`oc logs` not working** - Using `crictl` directly on nodes instead
2. **Consolidated containers** - metal3-ironic contains all Ironic services, not separate containers
3. **mlx5 NIC errors** - Known issue with Mellanox NICs during inspection, may need increased timeout

---

## 📝 **Notes for Tomorrow**

### Where We Left Off
- Root cause identified: Mellanox NIC driver error during inspection
- Node is currently in `inspecting` state
- **ACTION NEEDED:** Increase inspection timeout and retry (Step 1-3 above)

### First Thing to Check Tomorrow

```bash
# 1. Check if inspection completed overnight
oc get baremetalhost master-2 -n openshift-machine-api

# 2. If still inspecting, check how long
oc get baremetalhost master-2 -n openshift-machine-api -o yaml | grep lastUpdated

# 3. Check for any errors
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.errorMessage}'

# 4. If still stuck, proceed with Step 1 (increase timeout) above
```

### Quick Resume Commands

```bash
# Navigate to troubleshooting directory
cd ~/gemini-workspace/ocp-troubleshooting/bare-metal-node-inspection-timeout

# Read this summary
cat SESSION-SUMMARY-master2-inspection.md

# Check current status
oc get baremetalhost -n openshift-machine-api

# If need to increase timeout and retry:
oc patch provisioning provisioning-configuration --type merge -p '{"spec":{"inspectTimeout":"5400"}}'
oc annotate baremetalhost master-2 -n openshift-machine-api baremetalhost.metal3.io/status- --overwrite
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 20
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

---

## 🔗 **Useful Links**

- Red Hat OpenShift Bare Metal Documentation: https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html-single/deploying_installer-provisioned_clusters_on_bare_metal/
- Mellanox/NVIDIA NIC Documentation: Check Dell iDRAC for firmware updates
- Metal3 Project: https://metal3.io/

---

## 📞 **Escalation Criteria**

Consider escalating to Red Hat support if:

1. **Inspection still fails after increasing timeout to 90+ minutes**
2. **Hardware checks show no differences between master-0/1 and master-2**
3. **Mellanox firmware is up to date but errors persist**
4. **Manual hardware detail provisioning fails**

**Data to collect for support case:**
```bash
# Run diagnostic script
./diagnose-bmh.sh master-2

# Collect must-gather
oc adm must-gather

# Get specific logs
oc get baremetalhost master-2 -n openshift-machine-api -o yaml > master2-bmh.yaml
# (Capture iDRAC console output with mlx5 errors)
```

---

**END OF SESSION SUMMARY**

**Last Updated:** December 3, 2025  
**Status:** Awaiting timeout increase and re-inspection results  
**Next Action:** Follow Step 1-3 in "Recommended Next Steps" section


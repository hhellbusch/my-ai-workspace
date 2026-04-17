# Quick Start for Tomorrow

**Issue:** master-2 stuck in inspection  
**Root Cause:** Mellanox NIC driver error (`mlx5_query_module_id:315` repeating continuously)  
**Status:** ⚠️ STUCK IN RETRY LOOP - Hardware fix required, timeout increase won't help

---

## ⚡ **First: Check Current State**

```bash
# Quick status check
oc get baremetalhost master-2 -n openshift-machine-api

# Look for:
# - STATE: inspecting, available, error, or provisioned?
# - If "available" or "provisioned" = SUCCESS! 🎉
# - If still "inspecting" = continue below
# - If "error" = check error message below
```

## 🚨 **Error is Repeating = Hardware Issue (Not Timeout)**

Since `mlx5_query_module_id:315` is repeating continuously, increasing timeout won't help.
Inspection is **stuck in a retry loop** on the Mellanox NIC hardware query.

### Step 1: Check Mellanox NIC Configuration (CRITICAL)

**Via iDRAC for all three masters:**

```
iDRAC → System → Network Devices → Mellanox NIC

Compare:
- Master-0: Which ports have cables/transceivers? Firmware version?
- Master-1: Which ports have cables/transceivers? Firmware version?
- Master-2: Which ports have cables/transceivers? Firmware version?
```

**Look for differences:**
- Empty SFP/QSFP ports that are "enabled" but have no transceiver
- Different firmware versions
- Unused transceivers causing issues
- Different port configurations

### Step 2: Fix Hardware Configuration

**Option A: Match transceiver configuration**
- If master-0/1 have transceivers in ports 1-2, install them in master-2
- Remove any unused transceivers from master-2

**Option B: Update firmware**
- If master-2 has older firmware, update to match master-0/1

**Option C: Disable unused ports (Quick workaround)**
- In BIOS/iDRAC, disable any Mellanox ports that have no cables
- Or temporarily disable the entire Mellanox NIC if not needed for provisioning

### Step 3: After Hardware Fix, Retry Inspection

```bash
# After making hardware changes
oc annotate baremetalhost master-2 -n openshift-machine-api \
  baremetalhost.metal3.io/status- \
  --overwrite

oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 20
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

### Step 4: Monitor (Should complete in 20-30 minutes if fixed)

**Watch BareMetalHost status:**
```bash
watch -n 10 'oc get baremetalhost master-2 -n openshift-machine-api'
```

**Watch iDRAC console:**
- The `mlx5_query_module_id` error should NOT repeat continuously
- Inspection should progress past NIC discovery
- System should show "hardware inspection complete"

**Expected:** State changes from `inspecting` → `available` within 30 minutes

---

## 🔍 **Detailed Hardware Investigation

Compare Mellanox NIC configuration between masters:

**Via iDRAC for each master:**
1. System → Network Devices → Check Mellanox NIC
2. Note firmware version
3. Check which ports have cables/transceivers
4. Compare master-0, master-1, master-2

**Look for:**
- Different firmware versions
- Different cable/transceiver configuration
- Unused SFP/QSFP modules in master-2

### Try Hardware Fix

If you find differences:
- Update Mellanox firmware to match working nodes
- Remove unused SFP/QSFP transceivers
- Ensure cables are properly seated
- Retry inspection

---

## 📋 **Quick Reference Commands**

```bash
# Check state
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.provisioning.state}'

# Check for errors
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.errorMessage}'

# Check power state
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.poweredOn}'

# View Ironic logs (from master node)
oc debug node/master-0
chroot /host
IRONIC=$(crictl ps | grep metal3-ironic | grep -v httpd | grep -v ramdisk | awk '{print $1}')
crictl logs -f $IRONIC | grep -i master-2
```

---

## 📖 **Full Documentation**

For complete details, see:
- **[SESSION-SUMMARY-master2-inspection.md](SESSION-SUMMARY-master2-inspection.md)** - Complete session history
- **[README.md](README.md)** - Full troubleshooting guide
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Command reference

---

## ✅ **Success = State Changes to "available"**

```bash
oc get baremetalhost master-2 -n openshift-machine-api
# NAME       STATE       CONSUMER   ONLINE   ERROR   AGE
# master-2   available              true             1h
```

Then the node will proceed to provisioning and eventually join the cluster!


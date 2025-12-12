# Troubleshooting: Bare Metal Node Stuck in Inspection

## Overview

When installing OpenShift using the Bare Metal Operator (BMO), nodes must go through an inspection phase where Ironic discovers hardware details. A node "stuck in inspecting" and timing out indicates issues with the inspection process, typically related to BMC connectivity, network configuration, or hardware compatibility.

## Active Sessions

For ongoing troubleshooting sessions with detailed notes, see [active-sessions/](active-sessions/) directory.

## Severity

**HIGH** - Prevents cluster from reaching quorum or full capacity. A 3-node control plane requires all 3 masters for production use.

## Symptoms

- Node stuck in `inspecting` state
- Inspection times out after 15-30 minutes
- Two masters provisioned successfully, third fails
- BareMetalHost shows `State: inspecting` indefinitely
- Events show inspection timeout errors

## 🚨 Emergency Quick Checks - Run This First

**If your node is stuck in inspection, start here:**

```bash
# 1. Check the node status (30 seconds)
oc get baremetalhost -n openshift-machine-api
# Look for node stuck in "inspecting" state

# 2. Get error details
BMH_NAME="master-2"  # Replace with your failing node
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.errorMessage}'

# 3. Check BMC connectivity (most common issue)
BMC_IP=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.address}' | grep -oP '\d+\.\d+\.\d+\.\d+')
ping -c 2 $BMC_IP && curl -k https://$BMC_IP/redfish/v1/Systems

# 4. Check Ironic logs for errors
IRONIC_POD=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-inspector --tail=30
```

**Most common issues and quick fixes:**

- **Can't reach BMC**: Check BMC IP, verify credentials, disable cert verification
  ```bash
  oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"bmc":{"disableCertificateVerification":true}}}'
  ```

- **Stale state**: Clear status and retry
  ```bash
  oc annotate baremetalhost $BMH_NAME -n openshift-machine-api baremetalhost.metal3.io/status-
  ```

- **Authentication failed**: Update BMC credentials
  ```bash
  oc delete secret ${BMH_NAME}-bmc-secret -n openshift-machine-api
  oc create secret generic ${BMH_NAME}-bmc-secret -n openshift-machine-api --from-literal=username=root --from-literal=password=YOUR_PASSWORD
  ```

**After applying a fix, monitor recovery:**
```bash
watch oc get baremetalhost $BMH_NAME -n openshift-machine-api
# Wait for state to change from "inspecting" to "available" or "provisioned"
```

Use the diagnostic script below for detailed troubleshooting if quick checks don't resolve the issue.

---

## Quick Diagnosis

### 1. Check BareMetalHost Status

```bash
# List all BareMetalHosts
oc get baremetalhosts -n openshift-machine-api

# Expected output shows state
# NAME       STATE         CONSUMER   ONLINE   ERROR   AGE
# master-0   provisioned   master-0   true             2h
# master-1   provisioned   master-1   true             2h
# master-2   inspecting               true             30m  <-- STUCK

# Get detailed status of the failing host
oc get baremetalhost master-2 -n openshift-machine-api -o yaml

# Check events for the failing host
oc describe baremetalhost master-2 -n openshift-machine-api
```

### 2. Check Ironic Logs

```bash
# Get Ironic pod name
IRONIC_POD=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)

# Check Ironic conductor logs
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-conductor --tail=100

# Check Ironic inspector logs
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-inspector --tail=100

# Follow logs in real-time
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-inspector -f
```

### 3. Check Metal3 Operator Logs

```bash
# Check baremetal-operator logs
oc logs -n openshift-machine-api deployment/metal3 --tail=100

# Follow in real-time
oc logs -n openshift-machine-api deployment/metal3 -f
```

## Common Root Causes

### 1. BMC Connectivity Issues

**Symptoms:**
- Logs show "Unable to connect to BMC"
- "Connection timeout" or "Connection refused"
- SSL/TLS certificate errors
- Authentication failures

**Diagnosis:**

```bash
# Get BMC connection details
oc get baremetalhost master-2 -n openshift-machine-api -o yaml | grep -A 10 bmc:

# Example output:
#  bmc:
#    address: redfish-virtualmedia+https://10.0.0.13/redfish/v1/Systems/1
#    credentialsName: master-2-bmc-secret
#    disableCertificateVerification: false

# Check if BMC secret exists
oc get secret master-2-bmc-secret -n openshift-machine-api

# Get the BMC credentials (base64 decoded)
oc get secret master-2-bmc-secret -n openshift-machine-api -o jsonpath='{.data.username}' | base64 -d
echo
oc get secret master-2-bmc-secret -n openshift-machine-api -o jsonpath='{.data.password}' | base64 -d
echo

# Test BMC connectivity from your workstation
BMC_IP=$(oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.spec.bmc.address}' | grep -oP '\d+\.\d+\.\d+\.\d+')
curl -k https://${BMC_IP}/redfish/v1/Systems

# Test from within the cluster (if possible)
oc debug node/master-0 -- chroot /host curl -k https://${BMC_IP}/redfish/v1/Systems
```

**Common Issues and Fixes:**

#### Issue 1a: Wrong BMC Address

```bash
# Check if BMC address is correct
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.spec.bmc.address}'

# Common mistakes:
# - Wrong IP address (copy-paste error)
# - Wrong Redfish path (/redfish/v1/Systems/1 vs /redfish/v1/Systems/System.Embedded.1)
# - Wrong protocol (redfish vs redfish-virtualmedia)
# - HTTP instead of HTTPS or vice versa

# Fix by patching the BareMetalHost
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "bmc": {
      "address": "redfish-virtualmedia+https://CORRECT_IP/redfish/v1/Systems/1"
    }
  }
}'

# After fixing, re-trigger inspection
oc annotate baremetalhost master-2 -n openshift-machine-api \
  baremetalhost.metal3.io/status-
```

#### Issue 1b: Wrong Credentials

```bash
# Delete old secret
oc delete secret master-2-bmc-secret -n openshift-machine-api

# Create new secret with correct credentials
oc create secret generic master-2-bmc-secret \
  -n openshift-machine-api \
  --from-literal=username=CORRECT_USERNAME \
  --from-literal=password=CORRECT_PASSWORD

# Re-trigger inspection
oc annotate baremetalhost master-2 -n openshift-machine-api \
  baremetalhost.metal3.io/status-
```

#### Issue 1c: SSL Certificate Verification

```bash
# If BMC uses self-signed certificate, disable verification
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "bmc": {
      "disableCertificateVerification": true
    }
  }
}'
```

#### Issue 1d: Network Connectivity

```bash
# Check if provisioning network can reach BMC
# From a node that successfully provisioned:
oc debug node/master-0

# Inside the debug pod:
chroot /host
ping -c 3 BMC_IP_OF_MASTER_2
curl -k -m 10 https://BMC_IP_OF_MASTER_2/redfish/v1/Systems

# If it fails, check:
# 1. BMC is on correct VLAN
# 2. Firewall rules allow traffic
# 3. BMC network interface is configured
```

### 2. DHCP/Network Issues During Inspection

**Symptoms:**
- Node boots but doesn't get IP during inspection
- Inspection IPA (Ironic Python Agent) doesn't call back
- Timeout waiting for inspection data
- Logs show "Timeout waiting for node to boot"

**Diagnosis:**

```bash
# Check provisioning network configuration
oc get network.config.openshift.io cluster -o yaml | grep -A 20 provisioningNetwork

# Check DHCP range has available IPs
oc get provisioning provisioning-configuration -o yaml | grep -A 10 dhcpRange

# Check metal3 pod logs for DHCP-related errors
oc logs -n openshift-machine-api deployment/metal3 | grep -i dhcp

# Check if inspection image is being served
oc get pod -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-image-cache

# Check if node is getting PXE boot
# This requires access to the BMC console or SOL (Serial Over LAN)
ipmitool -I lanplus -H BMC_IP -U USERNAME -P PASSWORD sol activate
```

**Common Issues and Fixes:**

#### Issue 2a: DHCP Range Exhausted

```bash
# Check current DHCP leases (if using metal3 DHCP)
oc exec -n openshift-machine-api $IRONIC_POD -c ironic-dnsmasq -- cat /var/lib/dnsmasq/dnsmasq.leases

# If range is exhausted, you may need to:
# 1. Clean up old leases
# 2. Expand DHCP range (requires reinstall or manual reconfiguration)
# 3. Wait for leases to expire
```

#### Issue 2b: Inspection Image Not Accessible

```bash
# Check if metal3 image cache pod is running
oc get pod -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-image-cache

# Check if images are properly cached
oc exec -n openshift-machine-api $IRONIC_POD -c ironic-httpd -- ls -lh /shared/html/images/

# Verify httpd is serving images
HTTPD_IP=$(oc get pod -n openshift-machine-api $IRONIC_POD -o jsonpath='{.status.podIP}')
curl http://${HTTPD_IP}/images/
```

#### Issue 2c: Network Boot Issues

```bash
# Verify boot order in BareMetalHost
oc get baremetalhost master-2 -n openshift-machine-api -o yaml | grep -A 5 bootMode

# Should show:
#  bootMode: UEFI
#  or
#  bootMode: legacy

# If wrong, update it:
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "bootMode": "UEFI"
  }
}'
```

### 3. Hardware Compatibility Issues

**Symptoms:**
- Inspection starts but hangs partway through
- IPA (Ironic Python Agent) kernel panic or crashes
- Hardware not detected correctly
- Specific hardware component causes timeout

**Diagnosis:**

```bash
# Check Ironic inspector logs for hardware errors
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-inspector --tail=200 | grep -i error

# Common errors:
# - RAID controller issues
# - NIC driver problems
# - Disk detection failures
# - BIOS/UEFI compatibility issues

# Get hardware details from successful nodes for comparison
oc get baremetalhost master-0 -n openshift-machine-api -o yaml | grep -A 50 hardwareDetails

# Check for any hardware-specific errors in BMH status
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.errorMessage}'
```

**Common Issues and Fixes:**

#### Issue 3a: RAID Configuration

```bash
# If RAID controller is blocking inspection, may need to:
# 1. Configure RAID before inspection
# 2. Use specific RAID drivers
# 3. Pass through individual disks instead of RAID volumes

# Check current RAID configuration
oc get baremetalhost master-2 -n openshift-machine-api -o yaml | grep -A 10 raid

# Some RAID controllers require pre-configuration
# Access BMC and configure RAID before attempting inspection
```

#### Issue 3b: NIC Driver Issues

```bash
# Check if specific NIC models have issues
# Look for NIC-related errors in IPA logs
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-inspector | grep -i "nic\|network\|interface"

# May require custom IPA image with specific drivers
# Or BIOS settings adjustment for NIC boot
```

### 4. Inspection Timeout Configuration

**Symptoms:**
- Inspection times out too quickly
- Hardware is slow to respond
- Logs show legitimate timeout

**Diagnosis:**

```bash
# Check current timeout settings
oc get provisioning provisioning-configuration -o yaml | grep -i timeout

# Check BareMetalHost for any timeout annotations
oc get baremetalhost master-2 -n openshift-machine-api -o yaml | grep -i timeout

# Review Ironic configuration
oc get configmap -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state
```

**Fix:**

```bash
# Increase inspection timeout if hardware is legitimately slow
# Note: This requires editing the Provisioning CR

oc edit provisioning provisioning-configuration

# Add or modify:
spec:
  provisioningOSDownloadURL: <existing-value>
  watchAllNamespaces: false
  # Add timeout settings (values in seconds)
  inspectTimeout: 3600  # Increase from default 1800 (30 min) to 3600 (60 min)

# Alternatively, patch it:
oc patch provisioning provisioning-configuration --type merge -p '
{
  "spec": {
    "inspectTimeout": "3600"
  }
}'
```

### 5. Power Management Issues

**Symptoms:**
- Node won't power on
- Node powers on but doesn't boot
- Power state conflicts

**Diagnosis:**

```bash
# Check current power state
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.poweredOn}'

# Check for power-related errors
oc describe baremetalhost master-2 -n openshift-machine-api | grep -i power

# Check Ironic power management logs
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-conductor | grep -i "power\|boot"
```

**Fix:**

```bash
# Try manual power cycle
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "online": false
  }
}'

# Wait 30 seconds
sleep 30

# Power back on
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "online": true
  }
}'

# Or use BMC directly
ipmitool -I lanplus -H BMC_IP -U USER -P PASS power status
ipmitool -I lanplus -H BMC_IP -U USER -P PASS power cycle
```

### 6. Previous Failed State

**Symptoms:**
- Node was previously in error state
- Stale data from previous inspection attempt
- Status not properly cleared

**Diagnosis:**

```bash
# Check for error state
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.errorMessage}'
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.errorType}'

# Check for stale annotations
oc get baremetalhost master-2 -n openshift-machine-api -o yaml | grep -A 10 annotations:
```

**Fix:**

```bash
# Force re-inspection by removing status annotation
oc annotate baremetalhost master-2 -n openshift-machine-api \
  baremetalhost.metal3.io/status-

# Or remove the entire status to start fresh
oc patch baremetalhost master-2 -n openshift-machine-api --type json -p '[
  {"op": "remove", "path": "/status"}
]'

# If in error state, remove error condition
oc annotate baremetalhost master-2 -n openshift-machine-api \
  baremetalhost.metal3.io/error-

# Set online to false then true to trigger full cycle
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

## Step-by-Step Troubleshooting Process

### Step 1: Gather Basic Information

```bash
# Create output directory
mkdir -p bmh-diagnostics-$(date +%Y%m%d-%H%M%S)
cd bmh-diagnostics-*

# Get all BareMetalHosts
oc get baremetalhost -n openshift-machine-api -o yaml > baremetalhosts.yaml

# Get the failing host details
oc describe baremetalhost master-2 -n openshift-machine-api > master-2-describe.txt

# Get Metal3 pod status
oc get pods -n openshift-machine-api > pods.txt

# Get provisioning configuration
oc get provisioning provisioning-configuration -o yaml > provisioning-config.yaml
```

### Step 2: Check Logs

```bash
# Get Ironic pod logs
IRONIC_POD=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)

oc logs -n openshift-machine-api $IRONIC_POD -c ironic-conductor --tail=500 > ironic-conductor.log
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-inspector --tail=500 > ironic-inspector.log
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-api --tail=500 > ironic-api.log

# Get Metal3 operator logs
oc logs -n openshift-machine-api deployment/metal3 --tail=500 > metal3-operator.log

# Get baremetal-operator logs
oc logs -n openshift-machine-api deployment/cluster-baremetal-operator --tail=500 > baremetal-operator.log
```

### Step 3: Analyze Logs for Patterns

```bash
# Look for common error patterns
echo "=== Checking for BMC connectivity errors ==="
grep -i "unable to connect\|connection refused\|connection timeout\|tls\|certificate" *.log

echo "=== Checking for authentication errors ==="
grep -i "authentication\|unauthorized\|forbidden\|invalid credentials" *.log

echo "=== Checking for network/DHCP errors ==="
grep -i "dhcp\|timeout waiting\|no response from node" *.log

echo "=== Checking for hardware errors ==="
grep -i "hardware\|raid\|disk\|nic" *.log

echo "=== Checking for inspection errors ==="
grep -i "inspection.*failed\|inspection.*timeout\|inspection.*error" *.log
```

### Step 4: Test BMC Connectivity

```bash
# Extract BMC details
BMC_ADDRESS=$(oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.spec.bmc.address}')
BMC_IP=$(echo $BMC_ADDRESS | grep -oP '\d+\.\d+\.\d+\.\d+')
SECRET_NAME=$(oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.spec.bmc.credentialsName}')

# Get credentials
BMC_USER=$(oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.username}' | base64 -d)
BMC_PASS=$(oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.password}' | base64 -d)

echo "BMC Address: $BMC_ADDRESS"
echo "BMC IP: $BMC_IP"
echo "BMC User: $BMC_USER"

# Test connectivity
echo "Testing ping..."
ping -c 3 $BMC_IP

echo "Testing HTTPS..."
curl -k -m 10 https://$BMC_IP/redfish/v1/Systems

echo "Testing authentication..."
curl -k -u "${BMC_USER}:${BMC_PASS}" https://$BMC_IP/redfish/v1/Systems
```

### Step 5: Check Hardware Comparison

```bash
# Compare working vs failing node
echo "=== Master-0 Hardware ==="
oc get baremetalhost master-0 -n openshift-machine-api -o jsonpath='{.status.hardwareDetails}' | jq .

echo "=== Master-2 Hardware (if available) ==="
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.hardwareDetails}' | jq .

# Check if they're identical hardware
```

### Step 6: Apply Fix

Based on what you found in steps 1-5, apply the appropriate fix from the "Common Root Causes" section above.

### Step 7: Trigger Re-inspection

```bash
# After fixing the issue, trigger re-inspection
oc annotate baremetalhost master-2 -n openshift-machine-api \
  baremetalhost.metal3.io/status-

# Monitor progress
watch oc get baremetalhost master-2 -n openshift-machine-api

# Follow logs
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-inspector -f
```

## Quick Diagnostic Script

```bash
#!/bin/bash

BMH_NAME=${1:-master-2}
NAMESPACE="openshift-machine-api"

echo "==================================="
echo "BareMetalHost Diagnostic Script"
echo "==================================="
echo "Checking: $BMH_NAME"
echo ""

# Check if host exists
if ! oc get baremetalhost $BMH_NAME -n $NAMESPACE &>/dev/null; then
    echo "ERROR: BareMetalHost $BMH_NAME not found"
    exit 1
fi

echo "1. BareMetalHost Status:"
oc get baremetalhost $BMH_NAME -n $NAMESPACE

echo ""
echo "2. Current State:"
STATE=$(oc get baremetalhost $BMH_NAME -n $NAMESPACE -o jsonpath='{.status.provisioning.state}')
echo "   State: $STATE"

echo ""
echo "3. Error Message (if any):"
ERROR=$(oc get baremetalhost $BMH_NAME -n $NAMESPACE -o jsonpath='{.status.errorMessage}')
if [ -n "$ERROR" ]; then
    echo "   ERROR: $ERROR"
else
    echo "   No error message"
fi

echo ""
echo "4. BMC Configuration:"
oc get baremetalhost $BMH_NAME -n $NAMESPACE -o jsonpath='{.spec.bmc}' | jq .

echo ""
echo "5. BMC Connectivity Test:"
BMC_ADDRESS=$(oc get baremetalhost $BMH_NAME -n $NAMESPACE -o jsonpath='{.spec.bmc.address}')
BMC_IP=$(echo $BMC_ADDRESS | grep -oP '\d+\.\d+\.\d+\.\d+')
if [ -n "$BMC_IP" ]; then
    echo "   Testing ping to $BMC_IP..."
    if ping -c 2 -W 2 $BMC_IP &>/dev/null; then
        echo "   ✓ Ping successful"
    else
        echo "   ✗ Ping failed"
    fi
    
    echo "   Testing HTTPS to $BMC_IP..."
    if curl -k -s -m 5 https://$BMC_IP/redfish/v1/Systems &>/dev/null; then
        echo "   ✓ HTTPS successful"
    else
        echo "   ✗ HTTPS failed"
    fi
else
    echo "   Could not extract BMC IP"
fi

echo ""
echo "6. Recent Events:"
oc get events -n $NAMESPACE --field-selector involvedObject.name=$BMH_NAME --sort-by='.lastTimestamp' | tail -10

echo ""
echo "7. Ironic Inspector Logs (last 20 lines):"
IRONIC_POD=$(oc get pods -n $NAMESPACE -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)
oc logs -n $NAMESPACE $IRONIC_POD -c ironic-inspector --tail=20

echo ""
echo "==================================="
echo "Diagnostic complete"
echo "==================================="
```

Save as `diagnose-bmh.sh` and run:
```bash
chmod +x diagnose-bmh.sh
./diagnose-bmh.sh master-2
```

## Comparison: Working vs Failing Node

This helps identify configuration differences:

```bash
#!/bin/bash

WORKING_NODE="master-0"
FAILING_NODE="master-2"
NAMESPACE="openshift-machine-api"

echo "Comparing $WORKING_NODE (working) vs $FAILING_NODE (failing)"
echo ""

echo "=== BMC Address ===="
echo "Working: $(oc get bmh $WORKING_NODE -n $NAMESPACE -o jsonpath='{.spec.bmc.address}')"
echo "Failing: $(oc get bmh $FAILING_NODE -n $NAMESPACE -o jsonpath='{.spec.bmc.address}')"

echo ""
echo "=== Boot Mode ==="
echo "Working: $(oc get bmh $WORKING_NODE -n $NAMESPACE -o jsonpath='{.spec.bootMode}')"
echo "Failing: $(oc get bmh $FAILING_NODE -n $NAMESPACE -o jsonpath='{.spec.bootMode}')"

echo ""
echo "=== Online Status ==="
echo "Working: $(oc get bmh $WORKING_NODE -n $NAMESPACE -o jsonpath='{.spec.online}')"
echo "Failing: $(oc get bmh $FAILING_NODE -n $NAMESPACE -o jsonpath='{.spec.online}')"

echo ""
echo "=== Certificate Verification ==="
echo "Working: $(oc get bmh $WORKING_NODE -n $NAMESPACE -o jsonpath='{.spec.bmc.disableCertificateVerification}')"
echo "Failing: $(oc get bmh $FAILING_NODE -n $NAMESPACE -o jsonpath='{.spec.bmc.disableCertificateVerification}')"

echo ""
echo "=== Full Spec Diff ==="
diff <(oc get bmh $WORKING_NODE -n $NAMESPACE -o yaml | grep -A 50 "^spec:") \
     <(oc get bmh $FAILING_NODE -n $NAMESPACE -o yaml | grep -A 50 "^spec:")
```

## Emergency Recovery

If inspection continues to fail after all troubleshooting:

### Option 1: Manual Inspection Data

```bash
# If you know the hardware details, you can manually provide them
# This bypasses the inspection process

oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "hardwareProfile": "dell-r640"
  },
  "status": {
    "hardwareDetails": {
      "cpu": {
        "count": 2,
        "model": "Intel Xeon"
      },
      "ramMebibytes": 196608,
      "storage": [
        {
          "name": "/dev/sda",
          "sizeBytes": 480000000000
        }
      ]
    }
  }
}'

# Then remove inspection requirement
oc annotate baremetalhost master-2 -n openshift-machine-api \
  inspect.metal3.io=disabled
```

### Option 2: Use Different BMC Protocol

```bash
# If redfish-virtualmedia fails, try regular redfish
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "bmc": {
      "address": "redfish+https://BMC_IP/redfish/v1/Systems/1"
    }
  }
}'

# Or try IPMI (less preferred but works with older hardware)
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "bmc": {
      "address": "ipmi://BMC_IP"
    }
  }
}'
```

### Option 3: Re-create BareMetalHost

```bash
# Export current configuration
oc get baremetalhost master-2 -n openshift-machine-api -o yaml > master-2-bmh-backup.yaml

# Delete the BareMetalHost (this won't affect physical machine)
oc delete baremetalhost master-2 -n openshift-machine-api

# Edit the exported YAML:
# - Remove status section
# - Remove resourceVersion
# - Fix any known issues in spec

# Re-create it
oc create -f master-2-bmh-backup-edited.yaml
```

## Prevention and Best Practices

### Pre-Installation Checklist

```bash
# Before installing OpenShift on bare metal:

# 1. Verify BMC connectivity for ALL nodes
for ip in 10.0.0.11 10.0.0.12 10.0.0.13; do
    echo "Testing $ip..."
    curl -k https://$ip/redfish/v1/Systems
done

# 2. Verify BMC credentials for ALL nodes
# 3. Ensure consistent BIOS settings across all nodes
# 4. Configure RAID (if using) before installation
# 5. Verify network connectivity to provisioning network
# 6. Ensure DHCP range has enough IPs
# 7. Check that all nodes can PXE boot
# 8. Verify identical boot mode (UEFI vs Legacy) across nodes
```

### Post-Installation Monitoring

```bash
# Monitor BareMetalHost status
watch oc get baremetalhost -n openshift-machine-api

# Set up alerts for failed inspections
# (requires monitoring stack)
```

## Related Documentation

- [OpenShift Bare Metal IPI Documentation](https://docs.openshift.com/container-platform/latest/installing/installing_bare_metal_ipi/ipi-install-overview.html)
- [Metal3.io Documentation](https://metal3.io/)
- [Redfish API Specification](https://www.dmtf.org/standards/redfish)

## Summary

**Most Common Causes (in order of frequency):**
1. **BMC connectivity issues** (wrong IP, credentials, certificate)
2. **Network/DHCP problems** (no IP during inspection)
3. **Previous failed state** (stale data, needs reset)
4. **Hardware compatibility** (RAID, NIC drivers)
5. **Timeout too short** (slow hardware)

**Quick Fixes to Try First:**
1. Verify BMC connectivity and credentials
2. Disable certificate verification if using self-signed certs
3. Clear status and re-trigger inspection
4. Increase inspection timeout
5. Manual power cycle

**When to Escalate:**
- BMC is not accessible at all (hardware/network issue)
- Consistent kernel panics during inspection (hardware incompatibility)
- All troubleshooting steps exhausted (may need manual provisioning)


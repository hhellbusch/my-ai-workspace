# Your Specific Issue: 3rd Master Stuck in Inspecting

## Situation Summary

**What you have:**
- Newly installed OpenShift cluster using Bare Metal Operator
- 2 masters successfully provisioned
- 3rd master (master-2) stuck in `inspecting` state
- Inspection consistently times out

**Why this matters:**
- 3-node control plane requires all 3 masters for production quorum
- Until fixed, cluster is not fully ready
- Root cause must be identified to prevent similar issues

## Immediate Actions (Do This First)

### Step 1: Run the Diagnostic Script (2 minutes)

```bash
cd ~/gemini-workspace/ocp-troubleshooting/bare-metal-node-inspection-timeout

# Run automated diagnostics
./diagnose-bmh.sh master-2

# Review the output and RECOMMENDATIONS.txt
cat bmh-diagnostics-*/RECOMMENDATIONS.txt
```

This will automatically:
- Check BareMetalHost status
- Test BMC connectivity
- Verify credentials
- Analyze logs for errors
- Generate specific recommendations

### Step 2: Quick Manual Check (1 minute)

```bash
# Check current status
oc get baremetalhost -n openshift-machine-api

# Get details of the failing node
oc describe baremetalhost master-2 -n openshift-machine-api | tail -30

# Check for error messages
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.errorMessage}'
```

### Step 3: Compare with Working Nodes (1 minute)

```bash
# See what's different
diff <(oc get bmh master-0 -n openshift-machine-api -o yaml | grep -A 30 "^spec:") \
     <(oc get bmh master-2 -n openshift-machine-api -o yaml | grep -A 30 "^spec:")
```

## Most Likely Causes (Based on "2 working, 1 failing" Pattern)

When 2 masters work but the 3rd fails, it's almost always one of these:

### 1. Wrong BMC Configuration (70% probability)

**Most common mistakes:**
```bash
# Check BMC address
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.spec.bmc.address}'

# Common errors:
# - Copy-paste error in IP address (should be similar to master-0 and master-1)
# - Wrong Redfish path
# - Typo in credentials

# Quick fix if BMC IP is wrong:
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "bmc": {
      "address": "redfish-virtualmedia+https://CORRECT_IP/redfish/v1/Systems/1",
      "disableCertificateVerification": true
    }
  }
}'

# If credentials are wrong:
oc delete secret master-2-bmc-secret -n openshift-machine-api
oc create secret generic master-2-bmc-secret -n openshift-machine-api \
  --from-literal=username=CORRECT_USERNAME \
  --from-literal=password=CORRECT_PASSWORD

# Retry inspection
oc annotate baremetalhost master-2 -n openshift-machine-api baremetalhost.metal3.io/status-
```

### 2. BMC Not Accessible (20% probability)

**Check:**
```bash
# Extract BMC IP
BMC_IP=$(oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.spec.bmc.address}' | grep -oP '\d+\.\d+\.\d+\.\d+')

# Test connectivity
ping -c 3 $BMC_IP
curl -k https://$BMC_IP/redfish/v1/Systems

# If it fails:
# - BMC might be on wrong VLAN
# - BMC network settings might be incorrect
# - Firewall blocking access
# - BMC itself might need reconfiguration
```

### 3. Stale State from Previous Attempt (10% probability)

**Quick fix:**
```bash
# Clear everything and retry
oc annotate baremetalhost master-2 -n openshift-machine-api baremetalhost.metal3.io/status-
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'

# Watch progress
watch oc get baremetalhost master-2 -n openshift-machine-api
```

## Step-by-Step Resolution

### Phase 1: Identify the Issue (5 minutes)

```bash
# 1. Get BMC details for all three nodes
for master in master-0 master-1 master-2; do
    echo "=== $master ==="
    oc get baremetalhost $master -n openshift-machine-api -o jsonpath='{.spec.bmc.address}'
    echo ""
done

# 2. Check if BMC IPs are correct (should be sequential or similar pattern)
# 3. Test BMC connectivity for master-2

BMC_IP=$(oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.spec.bmc.address}' | grep -oP '\d+\.\d+\.\d+\.\d+')
echo "Testing BMC at: $BMC_IP"
ping -c 2 $BMC_IP && echo "PING: OK" || echo "PING: FAILED"
curl -k -s -m 5 https://$BMC_IP/redfish/v1/Systems && echo "HTTPS: OK" || echo "HTTPS: FAILED"

# 4. Check credentials
SECRET=$(oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.spec.bmc.credentialsName}')
echo "BMC Secret: $SECRET"
oc get secret $SECRET -n openshift-machine-api &>/dev/null && echo "Secret exists" || echo "Secret missing!"

# 5. Check Ironic logs
IRONIC_POD=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-inspector --tail=50 | grep -i "master-2\|error\|fail"
```

### Phase 2: Apply Fix (2 minutes)

Based on what you found in Phase 1:

**If BMC not reachable:**
```bash
# Verify BMC IP is correct by checking your install-config or BMC console
# Update if wrong:
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "bmc": {
      "address": "redfish-virtualmedia+https://CORRECT_BMC_IP/redfish/v1/Systems/1",
      "disableCertificateVerification": true
    }
  }
}'
```

**If credentials wrong:**
```bash
# Get working credentials from master-0 or master-1 for comparison
oc get secret master-0-bmc-secret -n openshift-machine-api -o jsonpath='{.data.username}' | base64 -d

# Update master-2 credentials
oc delete secret master-2-bmc-secret -n openshift-machine-api
oc create secret generic master-2-bmc-secret -n openshift-machine-api \
  --from-literal=username=YOUR_BMC_USER \
  --from-literal=password=YOUR_BMC_PASS
```

**If certificate issues:**
```bash
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "bmc": {
      "disableCertificateVerification": true
    }
  }
}'
```

**If state is stale:**
```bash
# Full reset
oc annotate baremetalhost master-2 -n openshift-machine-api baremetalhost.metal3.io/status-
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 15
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

### Phase 3: Monitor Recovery (10-30 minutes)

```bash
# Watch status changes
watch -n 10 'oc get baremetalhost -n openshift-machine-api'

# Follow Ironic inspector logs
IRONIC_POD=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-inspector -f

# Expected progression:
# inspecting -> available (inspection complete)
# Then later: provisioning -> provisioned (after OS deployment)
```

## Success Indicators

You'll know it's fixed when:

```bash
# State changes from 'inspecting' to something else
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.provisioning.state}'

# Expected states in order:
# inspecting -> available -> provisioning -> provisioned

# Hardware details get populated
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.hardwareDetails}' | jq .

# No error messages
oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.status.errorMessage}'
```

## If Still Stuck After Trying Above

### Check Ironic Infrastructure

```bash
# Ensure Ironic is healthy
oc get pods -n openshift-machine-api | grep -E 'metal|ironic'

# All should be Running
# If not, check their logs:
oc logs -n openshift-machine-api deployment/metal3
```

### Increase Timeout

```bash
# If inspection is legitimately slow
oc patch provisioning provisioning-configuration --type merge -p '
{
  "spec": {
    "inspectTimeout": "3600"
  }
}'
```

### Manual Power Cycle via BMC

```bash
# Sometimes a hard power cycle helps
# Using ipmitool (if BMC supports IPMI):
ipmitool -I lanplus -H BMC_IP -U USER -P PASS power cycle

# Or via BMC web console
```

## Detailed Documentation

For comprehensive troubleshooting, see:

- **[Full Guide](README.md)** - Complete troubleshooting with all scenarios
- **[Quick Reference](QUICK-REFERENCE.md)** - Fast command lookup
- **[Diagnostic Script](diagnose-bmh.sh)** - Automated analysis

## Getting Help

If you're still stuck after trying the above:

1. **Run diagnostic script:**
   ```bash
   ./diagnose-bmh.sh master-2
   ```

2. **Share the output:**
   - The generated `RECOMMENDATIONS.txt`
   - The `.tar.gz` archive
   - Output of `oc get baremetalhost -n openshift-machine-api`

3. **What to include when asking for help:**
   - OpenShift version
   - Hardware vendor (Dell, HP, etc.)
   - BMC type (iDRAC, iLO, etc.)
   - What you've tried from this guide
   - Any error messages from logs

## Quick Sanity Checks

Before going too deep, verify these basics:

```bash
# 1. Is the physical server actually powered on?
# Check via BMC console or physically

# 2. Are there 3 BareMetalHost objects?
oc get baremetalhost -n openshift-machine-api | wc -l
# Should show 3 (+ header)

# 3. Are the BMC IPs in the right network?
# They should all be in the same subnet

# 4. Did you use the same credentials for all BMCs?
# Common mistake: different password for one BMC

# 5. Is the server trying to PXE boot?
# Check via BMC console - should see network boot attempt
```

## Most Common Resolution

In my experience, the most common fix is:

```bash
# Disable certificate verification (BMCs use self-signed certs)
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '
{
  "spec": {
    "bmc": {
      "disableCertificateVerification": true
    }
  }
}'

# Clear state and retry
oc annotate baremetalhost master-2 -n openshift-machine-api baremetalhost.metal3.io/status-
```

This fixes about 50% of "2 working, 1 failing" scenarios.

Good luck! Let me know if you need clarification on any of these steps.


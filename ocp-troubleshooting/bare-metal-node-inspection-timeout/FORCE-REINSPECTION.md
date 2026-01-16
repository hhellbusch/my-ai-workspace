# Force BareMetalHost Re-Inspection - Quick Reference

## TL;DR - Force Re-Inspection Now

```bash
# Replace 'master-2' with your node name
BMH_NAME="master-2"

# Method 1: Remove status annotation (recommended, fast)
oc annotate baremetalhost $BMH_NAME -n openshift-machine-api \
  baremetalhost.metal3.io/status-

# Method 2: Power cycle + clear status (if Method 1 doesn't work)
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc annotate baremetalhost $BMH_NAME -n openshift-machine-api baremetalhost.metal3.io/status-
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

## Why This Works

The `baremetalhost.metal3.io/status-` annotation removal tells the Baremetal Operator to forget the current inspection state and start fresh. This is useful when:

- Inspection is stuck or timed out
- You've fixed BMC connectivity issues
- You've updated credentials or BMC address
- Node is in a stale error state

## Methods Explained

### Method 1: Clear Status Annotation (Fastest)

This simply tells the operator to re-run inspection:

```bash
oc annotate baremetalhost $BMH_NAME -n openshift-machine-api \
  baremetalhost.metal3.io/status-
```

**When to use:** Most situations, especially when you've just fixed a configuration issue.

### Method 2: Power Cycle + Clear Status (More Thorough)

This performs a full power cycle and clears state:

```bash
# Power off
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'

# Wait for power off
sleep 10

# Clear status
oc annotate baremetalhost $BMH_NAME -n openshift-machine-api \
  baremetalhost.metal3.io/status-

# Power on
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

**When to use:** When Method 1 doesn't work, or when the node is in an unknown power state.

### Method 3: Nuclear Option - Remove All Status

If the node is completely stuck, remove the entire status section:

```bash
# WARNING: This removes ALL status data
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type json -p '[
  {"op": "remove", "path": "/status"}
]'

# Then ensure it's online
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

**When to use:** Last resort when other methods fail.

### Method 4: Disable/Enable Inspection

Skip inspection entirely or re-enable it:

```bash
# Disable inspection (if you want to skip hardware discovery)
oc annotate baremetalhost $BMH_NAME -n openshift-machine-api \
  inspect.metal3.io=disabled

# Re-enable inspection (and trigger it)
oc annotate baremetalhost $BMH_NAME -n openshift-machine-api \
  inspect.metal3.io-
```

**When to use:** When you want to provision without inspection, or to force inspection after disabling it.

## Monitor Re-Inspection Progress

After triggering re-inspection, monitor progress:

```bash
# Watch status changes
watch oc get baremetalhost $BMH_NAME -n openshift-machine-api

# Follow Ironic inspector logs
IRONIC_POD=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)
oc logs -n openshift-machine-api $IRONIC_POD -c ironic-inspector -f

# Check for errors
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.errorMessage}'
```

## Expected State Transitions

During successful re-inspection, you should see:

1. **inspecting** - Node is being inspected (15-30 minutes typical)
2. **available** - Inspection complete, ready for provisioning
3. **provisioning** - OS is being installed (if provisioning triggered)
4. **provisioned** - Node is fully provisioned and running

## Common Pre-Reinspection Fixes

Before forcing re-inspection, fix the underlying issue:

### Fix BMC Connectivity

```bash
# Disable certificate verification (common issue with self-signed certs)
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '
{
  "spec": {
    "bmc": {
      "disableCertificateVerification": true
    }
  }
}'
```

### Fix BMC Credentials

```bash
# Update credentials
oc delete secret ${BMH_NAME}-bmc-secret -n openshift-machine-api
oc create secret generic ${BMH_NAME}-bmc-secret -n openshift-machine-api \
  --from-literal=username=root \
  --from-literal=password=YOUR_NEW_PASSWORD
```

### Fix BMC Address

```bash
# Update BMC address
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '
{
  "spec": {
    "bmc": {
      "address": "redfish-virtualmedia+https://CORRECT_IP/redfish/v1/Systems/1"
    }
  }
}'
```

## Verification After Re-Inspection

Check that inspection succeeded:

```bash
# Check state is 'available' or 'provisioned'
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.provisioning.state}'

# Verify hardware details were discovered
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.hardwareDetails}' | jq .

# Check for any errors
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.errorMessage}'
```

## Quick Test Before Re-Inspection

Test BMC connectivity before forcing re-inspection:

```bash
# One-liner to test everything
BMH_NAME="master-2"
BMC_IP=$(oc get bmh $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.address}' | grep -oP '\d+\.\d+\.\d+\.\d+')
SECRET=$(oc get bmh $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.credentialsName}')
USER=$(oc get secret $SECRET -n openshift-machine-api -o jsonpath='{.data.username}' | base64 -d)
PASS=$(oc get secret $SECRET -n openshift-machine-api -o jsonpath='{.data.password}' | base64 -d)
echo "Testing BMC at $BMC_IP with user $USER..."
ping -c 2 $BMC_IP && curl -k -u "$USER:$PASS" -s https://$BMC_IP/redfish/v1/Systems | jq . || echo "BMC TEST FAILED"
```

If the BMC test fails, fix the issue before forcing re-inspection.

## Troubleshooting Re-Inspection Failures

If re-inspection still fails:

1. **Check BMC logs** - `oc logs -n openshift-machine-api $IRONIC_POD -c ironic-inspector --tail=100`
2. **Verify network connectivity** - Ensure provisioning network can reach BMC
3. **Increase timeout** - `oc patch provisioning provisioning-configuration --type merge -p '{"spec":{"inspectTimeout":"3600"}}'`
4. **Compare with working node** - `diff <(oc get bmh master-0 -n openshift-machine-api -o yaml) <(oc get bmh $BMH_NAME -n openshift-machine-api -o yaml)`

## Related Documentation

- [README.md](README.md) - Full troubleshooting guide
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Quick diagnostic commands
- [diagnose-bmh.sh](diagnose-bmh.sh) - Diagnostic script

## Pro Tips

💡 **Always check BMC connectivity BEFORE forcing re-inspection** - Saves time and avoids repeated failures.

💡 **Use Method 1 first** - It's the fastest and least disruptive.

💡 **Monitor logs in real-time** - Catch issues as they happen rather than waiting for timeout.

💡 **Compare with working nodes** - Configuration drift is a common issue.

💡 **Document what you changed** - Makes troubleshooting easier if re-inspection still fails.


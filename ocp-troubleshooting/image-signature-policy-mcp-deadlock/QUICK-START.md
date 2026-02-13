# Quick Start: Fix Image Signature Policy Blocking MCP

## The Problem

Pods can't pull Red Hat images due to signature policy rejection, and MachineConfigPool can't complete because it needs those pods to run.

**Classic deadlock:** Can't fix policy without MCP completing, MCP can't complete without policy being fixed.

## The Solution (Quick Steps)

### 1. Run the Manual Fix Script

```bash
# Navigate to this directory
cd ocp-troubleshooting/image-signature-policy-mcp-deadlock/

# Run the script
./manual-fix-signature-policy.sh
```

**What it does:**
- Backs up existing policy.json on all nodes
- Deploys corrected policy.json with Red Hat registry support
- Restarts CRI-O on each node
- Verifies the fix

**Time required:** ~5-10 minutes depending on cluster size

### 2. Wait for Pods to Recover

```bash
# Check for image pull errors (should decrease)
oc get pods -A | grep -E "ImagePullBackOff|ErrImagePull"

# Wait 2-3 minutes for pods to restart
sleep 180

# Check again - should be much fewer or none
oc get pods -A | grep -E "ImagePullBackOff|ErrImagePull"
```

### 3. Monitor MCP Completion

```bash
# Watch MCP progress
watch oc get mcp

# Wait for:
# - UPDATED=True
# - UPDATING=False
# - DEGRADED=False
```

**Time required:** 30-60 minutes depending on cluster size

### 4. Apply Permanent Fix

Once MCP is complete and stable:

```bash
# Apply the MachineConfig to make the fix permanent
oc apply -f signature-policy-machineconfig.yaml

# This will trigger another MCP rollout (but this time it will succeed)
watch oc get mcp
```

## If You Want to Do It Manually

See the detailed step-by-step instructions in `README.md` under "Manual Fix - Step by Step"

## Verify Success

```bash
# All pods should be running (or their normal state)
oc get pods -A | grep -E "ImagePullBackOff|ErrImagePull"
# Should return no results

# MCP should be updated
oc get mcp
# All should show UPDATED=True

# Check that policy is correctly configured
oc debug node/$(oc get nodes -o name | head -1 | cut -d/ -f2) -- chroot /host cat /etc/containers/policy.json | jq '.transports.docker | keys'
# Should show: ["catalog.redhat.com", "registry.access.redhat.com", "registry.redhat.io"]
```

## Troubleshooting

### Script fails with "oc: command not found"
```bash
# Install OpenShift CLI
# Download from: https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/
```

### Script fails with "Not logged into OpenShift cluster"
```bash
# Log into your cluster
oc login --token=<token> --server=<api-server>
```

### MCP still stuck after manual fix
```bash
# Check what's blocking it
oc get mcp -o yaml | grep -A30 "conditions:"

# Check for other image pull errors
oc get events -A | grep -i "failed.*pull"

# Might need to scale down problematic pods temporarily
oc scale deployment <deployment-name> -n <namespace> --replicas=0
```

### CRI-O fails to restart
```bash
# Check CRI-O status on the node
oc debug node/<node-name>
chroot /host
systemctl status crio
journalctl -u crio -n 50

# Check for syntax errors in policy.json
cat /etc/containers/policy.json | jq .
```

## Need More Help?

See the full troubleshooting guide: `README.md`

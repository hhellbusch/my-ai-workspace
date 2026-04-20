# Verification Steps After Fix

After applying any fix for the VM provisioning issue, use this checklist to verify the system is working correctly.

## 1. Verify Webhook Status

### If You Removed the Webhook

```bash
# Confirm webhook is gone
oc get mutatingwebhookconfigurations | grep -i kubevirt | grep -i velero

# Should return no results
```

Expected: No output (webhook removed)

### If You Repaired the Webhook

```bash
# Check webhook exists
WEBHOOK_NAME=$(oc get mutatingwebhookconfigurations | grep kubevirt | grep velero | awk '{print $1}')
echo "Webhook: $WEBHOOK_NAME"

# Check webhook service exists
SERVICE_NAME=$(oc get mutatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].clientConfig.service.name}')
SERVICE_NAMESPACE=$(oc get mutatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].clientConfig.service.namespace}')

echo "Service: $SERVICE_NAME"
echo "Namespace: $SERVICE_NAMESPACE"

# Verify service exists
oc get svc $SERVICE_NAME -n $SERVICE_NAMESPACE
```

Expected: Service should exist and be running

```bash
# Check service endpoints
oc get endpoints $SERVICE_NAME -n $SERVICE_NAMESPACE

# Should show at least one endpoint IP
```

### If You Disabled the Webhook

```bash
# Check failure policy
oc get mutatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].failurePolicy}'
```

Expected: Should return "Ignore"

## 2. Verify Previously Stuck VMs

### Check VM Status

```bash
VM_NAME="<your-vm-name>"
VM_NAMESPACE="<your-namespace>"

# Check VM ready status
oc get vm $VM_NAME -n $VM_NAMESPACE

# Should show "True" in READY column
```

### Check VM Conditions

```bash
# Get detailed conditions
oc get vm $VM_NAME -n $VM_NAMESPACE -o jsonpath='{.status.conditions}' | jq .

# Look for:
# - type: Ready, status: "True"
# - type: Synchronized, status: "True"
```

Expected conditions:
```json
[
  {
    "type": "Ready",
    "status": "True",
    "reason": "VMReady"
  },
  {
    "type": "Synchronized",
    "status": "True",
    "reason": "VMCreated"
  }
]
```

### Check VMI (VirtualMachineInstance)

```bash
# VMI should exist and be running
oc get vmi $VM_NAME -n $VM_NAMESPACE

# Check VMI phase
oc get vmi $VM_NAME -n $VM_NAMESPACE -o jsonpath='{.status.phase}'
```

Expected phase: "Running"

### Check virt-launcher Pod

```bash
# Find virt-launcher pod
oc get pods -n $VM_NAMESPACE -l vm.kubevirt.io/name=$VM_NAME

# Should be in "Running" state with 2/2 or 3/3 containers ready
```

Expected output:
```
NAME                              READY   STATUS    RESTARTS   AGE
virt-launcher-<vm-name>-xxxxx     2/2     Running   0          5m
```

## 3. Test New VM Creation

Create a test VM to ensure the fix is working for new VMs:

```bash
# Create a simple test VM
cat <<EOF | oc apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: test-vm-verification
  namespace: default
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: test-vm-verification
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
          interfaces:
            - name: default
              masquerade: {}
        resources:
          requests:
            memory: 1Gi
            cpu: 1
      networks:
        - name: default
          pod: {}
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/kubevirt/cirros-container-disk-demo
EOF

# Wait a moment
sleep 2

# Start the VM
oc patch vm test-vm-verification -n default --type merge -p '{"spec":{"running":true}}'

# Watch it start (should complete in 1-2 minutes)
watch -n 2 'oc get vm,vmi,pod -n default | grep test-vm-verification'
```

Expected results:
- VM should reach "Ready: True" status
- VMI should be created and reach "Running" phase
- virt-launcher pod should be running

### Verify Test VM Started Successfully

```bash
# Check all components
oc get vm test-vm-verification -n default
oc get vmi test-vm-verification -n default
oc get pod -n default -l vm.kubevirt.io/name=test-vm-verification

# All should be in healthy state
```

### Clean Up Test VM

```bash
# Delete test VM
oc delete vm test-vm-verification -n default

# Verify cleanup
oc get vm,vmi,pod -n default | grep test-vm-verification

# Should return no results after a few seconds
```

## 4. Check System Events

```bash
# Check recent events for errors
oc get events -A --sort-by='.lastTimestamp' | tail -50

# Look for any webhook-related errors
oc get events -A --sort-by='.lastTimestamp' | grep -i webhook | tail -20

# Should see no new webhook errors after the fix
```

## 5. Verify KubeVirt Components

```bash
# Check all KubeVirt pods are healthy
oc get pods -n openshift-cnv

# All should be Running or Completed
```

Expected output (approximate):
```
NAME                                READY   STATUS    RESTARTS   AGE
virt-api-xxxxx                      1/1     Running   0          10d
virt-api-yyyyy                      1/1     Running   0          10d
virt-controller-xxxxx               1/1     Running   0          10d
virt-controller-yyyyy               1/1     Running   0          10d
virt-handler-xxxxx                  1/1     Running   0          10d
virt-handler-yyyyy                  1/1     Running   0          10d
virt-operator-xxxxx                 1/1     Running   0          10d
virt-operator-yyyyy                 1/1     Running   0          10d
```

## 6. Verify OADP/Velero (If Applicable)

### If You Repaired the Plugin

```bash
# Check OADP pods
oc get pods -n openshift-adp

# Check Velero pod is running
oc get pod -n openshift-adp -l component=velero

# Check plugin is loaded
VELERO_POD=$(oc get pod -n openshift-adp -l component=velero -o name | head -1)
oc exec -n openshift-adp $VELERO_POD -- velero plugin get | grep kubevirt
```

Expected: KubeVirt plugin should be listed

### Test Backup Functionality (Optional)

If OADP is repaired, test VM backup:

```bash
# Create a test VM if not already created
# (see section 3 above)

# Create a backup
velero backup create test-vm-backup \
  --include-namespaces default \
  --selector kubevirt.io/vm=test-vm-verification

# Check backup status
velero backup describe test-vm-backup

# Verify backup completed
velero backup get | grep test-vm-backup
```

Expected: Backup should complete successfully

### Clean Up Test Backup

```bash
# Delete test backup
velero backup delete test-vm-backup --confirm
```

## 7. Performance Check

Verify there's no performance degradation:

```bash
# Check API response time for VM operations
time oc get vm -A

# Should complete in < 2 seconds

# Check virt-controller CPU/memory
oc top pod -n openshift-cnv | grep virt-controller

# Should be within normal ranges for your cluster
```

## 8. Documentation Check

Ensure you've documented the fix:

- [ ] Root cause identified and documented
- [ ] Fix applied and verified
- [ ] Backup of any deleted resources saved
- [ ] Team notified if this was a production issue
- [ ] Runbook updated if needed

## Complete Verification Checklist

Use this checklist to confirm everything is working:

- [ ] Webhook status verified (removed, repaired, or disabled)
- [ ] Previously stuck VMs now running
- [ ] VMI created successfully for stuck VMs
- [ ] virt-launcher pods running for all VMs
- [ ] Test VM created and started successfully
- [ ] Test VM cleaned up without issues
- [ ] No webhook-related errors in events
- [ ] All KubeVirt components healthy
- [ ] OADP/Velero operational (if applicable)
- [ ] VM backup tested successfully (if applicable)
- [ ] Performance is normal
- [ ] Documentation updated

## Verification Script

For convenience, use this script to run all checks:

```bash
#!/bin/bash
# verification-script.sh

echo "=== Verification Script ==="
echo ""

echo "[1] Checking webhook status..."
WEBHOOK=$(oc get mutatingwebhookconfigurations | grep -i kubevirt | grep -i velero | awk '{print $1}' || echo "NONE")
echo "Webhook: $WEBHOOK"
echo ""

echo "[2] Checking KubeVirt pods..."
oc get pods -n openshift-cnv --no-headers | awk '{print $1, $2, $3}'
echo ""

echo "[3] Checking all VMs..."
oc get vm -A --no-headers | awk '{print $1, $2, $3, $4}'
echo ""

echo "[4] Checking for recent webhook errors..."
ERRORS=$(oc get events -A --sort-by='.lastTimestamp' | grep -i "webhook.*velero.*kubevirt" | tail -5)
if [ -z "$ERRORS" ]; then
  echo "No recent webhook errors found ✓"
else
  echo "Recent errors:"
  echo "$ERRORS"
fi
echo ""

echo "[5] Testing VM creation (dry-run)..."
cat <<EOF | oc apply --dry-run=server -f - &>/dev/null && echo "VM creation check: PASS ✓" || echo "VM creation check: FAIL ✗"
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: dryrun-test
  namespace: default
spec:
  running: false
  template:
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
              disk: {}
        resources:
          requests:
            memory: 64Mi
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/kubevirt/cirros-container-disk-demo
EOF

echo ""
echo "=== Verification Complete ==="
```

Save this as `verification-script.sh` and run:

```bash
chmod +x verification-script.sh
./verification-script.sh
```

## If Verification Fails

If any verification step fails:

1. Review the specific failure
2. Check relevant logs:
   ```bash
   # KubeVirt controller logs
   oc logs -n openshift-cnv -l kubevirt.io=virt-controller --tail=100
   
   # OADP logs (if applicable)
   oc logs -n openshift-adp -l component=velero --tail=100
   
   # API server logs
   oc logs -n openshift-kube-apiserver --tail=100 | grep -i webhook
   ```

3. Re-run diagnostic script:
   ```bash
   ./diagnostic-commands.sh
   ```

4. Review [INVESTIGATION-WORKFLOW.md](./INVESTIGATION-WORKFLOW.md)

5. If issue persists, consider escalation with:
   - Complete diagnostic output
   - Verification results
   - Timeline of changes made
   - Relevant logs


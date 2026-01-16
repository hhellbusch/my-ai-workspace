# Remove Velero KubeVirt Webhook (Quick Fix)

## When to Use This Solution

Use this approach if:
- You are **NOT** using OADP/Velero to backup KubeVirt VMs
- You need VMs working immediately
- You can deal with OADP/Velero configuration later

⚠️ **Warning**: After removing the webhook, OADP/Velero will not be able to properly backup/restore KubeVirt VMs until the plugin is properly installed.

## Step 1: Identify the Webhook

```bash
# List all mutating webhooks related to Velero and KubeVirt
oc get mutatingwebhookconfigurations | grep -i velero | grep -i kubevirt
```

Expected output example:
```
kubevirt-velero-annotations-remover   1          123d
```

## Step 2: Backup the Webhook Configuration (Optional but Recommended)

```bash
# Get the webhook name from step 1
WEBHOOK_NAME="kubevirt-velero-annotations-remover"

# Backup the configuration
oc get mutatingwebhookconfigurations $WEBHOOK_NAME -o yaml > webhook-backup-$(date +%Y%m%d-%H%M%S).yaml

echo "Backup saved to webhook-backup-*.yaml"
```

## Step 3: Remove the Webhook

```bash
# Delete the webhook configuration
WEBHOOK_NAME="kubevirt-velero-annotations-remover"
oc delete mutatingwebhookconfigurations $WEBHOOK_NAME
```

Expected output:
```
mutatingwebhookconfiguration.admissionregistration.k8s.io "kubevirt-velero-annotations-remover" deleted
```

## Step 4: Verify Removal

```bash
# Confirm the webhook is gone
oc get mutatingwebhookconfigurations | grep -i velero | grep -i kubevirt

# Should return no results
```

## Step 5: Test VM Creation

If you had a stuck VM, you may need to delete and recreate it:

```bash
# Check current VM status
oc get vm <vm-name> -n <namespace>

# Option A: Force delete and recreate (if VM is stuck)
oc delete vm <vm-name> -n <namespace> --force --grace-period=0
# Then recreate the VM from your original spec

# Option B: If VM exists but VMI doesn't, try creating the VMI
oc get vmi <vm-name> -n <namespace>
# If no VMI exists, start the VM
oc patch vm <vm-name> -n <namespace> --type merge -p '{"spec":{"running":true}}'
```

## Step 6: Verify VM is Running

```bash
# Check VM status
oc get vm <vm-name> -n <namespace>

# Check VMI status
oc get vmi <vm-name> -n <namespace>

# Check virt-launcher pod
oc get pods -n <namespace> | grep virt-launcher

# Check VM conditions
oc get vm <vm-name> -n <namespace> -o jsonpath='{.status.conditions}' | jq .
```

Expected healthy status:
```yaml
conditions:
  - type: Ready
    status: "True"
  - type: Synchronized
    status: "True"
```

## Step 7: Monitor for Issues

```bash
# Watch VM status
watch -n 2 'oc get vm -A'

# Watch events
oc get events -n <namespace> --watch

# Check virt-launcher logs if issues persist
oc logs -n <namespace> -l kubevirt.io=virt-launcher --tail=50
```

## Verification Checklist

- [ ] Webhook configuration removed
- [ ] Backup of webhook saved (if needed later)
- [ ] VM shows Ready status
- [ ] VMI is running
- [ ] virt-launcher pod is running
- [ ] Can connect to VM (console/SSH)

## If Issues Persist

If removing the webhook doesn't resolve the issue:

1. Check for other webhooks that might be blocking:
   ```bash
   oc get mutatingwebhookconfigurations
   oc get validatingwebhookconfigurations
   ```

2. Check CDI (Containerized Data Importer) if using PVCs:
   ```bash
   oc get pods -n openshift-cnv | grep cdi
   ```

3. Check for resource constraints:
   ```bash
   oc describe vm <vm-name> -n <namespace>
   oc get events -n <namespace> --sort-by='.lastTimestamp' | tail -20
   ```

## Restoring OADP/Velero Later

If you need to restore OADP/Velero functionality later:

1. See [REPAIR-VELERO-PLUGIN.md](./REPAIR-VELERO-PLUGIN.md)
2. Restore the webhook from backup if needed:
   ```bash
   oc apply -f webhook-backup-*.yaml
   ```

## Alternative: Disable Instead of Delete

If you want to keep the webhook but disable it temporarily:

```bash
# Patch the webhook to disable it
oc patch mutatingwebhookconfigurations kubevirt-velero-annotations-remover \
  --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value": "Ignore"}]'
```

This changes the failure policy from "Fail" to "Ignore", allowing VM creation to proceed even if the webhook service is missing.


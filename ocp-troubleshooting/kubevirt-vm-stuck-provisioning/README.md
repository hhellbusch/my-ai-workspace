# KubeVirt VM Stuck in Provisioning - Missing Velero Webhook

## Problem Summary

VirtualMachine stuck in provisioning state with error:
```
failed to create virtual machine pod: Internal error occurred: failed calling webhook 
"kubevirt-velero-annotations-remover.openshift-adp.svc": failed to call webhook: 
Post "https://kubevirt-velero-annotations-remover.velero-ppdm.svc:443/mutate?timeout=10s": 
service "kubevirt-velero-annotations-remover" not found
```

**Root Cause**: The OADP/Velero KubeVirt plugin's mutating webhook is configured but the webhook service doesn't exist. This prevents virt-launcher pods from being created.

## Quick Diagnosis

```bash
# Check VM status
oc get vm -A
oc describe vm <vm-name> -n <namespace>

# Check for webhook configuration
oc get mutatingwebhookconfigurations | grep velero

# Check if the webhook service exists
oc get svc -n openshift-adp | grep kubevirt
oc get svc -n velero-ppdm | grep kubevirt

# Check OADP installation
oc get pods -n openshift-adp
oc get dataprotectionapplication -n openshift-adp
```

## Resolution Options

### Option 1: Fix OADP/Velero KubeVirt Plugin (Recommended if you need backup/restore)

If you need OADP/Velero functionality for KubeVirt VMs, repair the plugin installation.

See: [REPAIR-VELERO-PLUGIN.md](./REPAIR-VELERO-PLUGIN.md)

### Option 2: Remove Webhook Configuration (Quick fix if not using Velero for VMs)

If you're not actively using OADP/Velero to backup KubeVirt VMs, remove the webhook.

See: [REMOVE-WEBHOOK.md](./REMOVE-WEBHOOK.md)

### Option 3: Disable Webhook Temporarily (Testing only)

For temporary testing, you can disable the webhook but this is NOT recommended for production.

See: [DISABLE-WEBHOOK-TEMP.md](./DISABLE-WEBHOOK-TEMP.md)

## Quick Fix Script

See: [fix-velero-webhook.sh](./fix-velero-webhook.sh)

## Related Files

- [diagnostic-commands.sh](./diagnostic-commands.sh) - Complete diagnostic script
- [VERIFICATION.md](./VERIFICATION.md) - Post-fix verification steps
- [PREVENTION.md](./PREVENTION.md) - How to prevent this issue

## Additional Context

This issue commonly occurs when:
1. OADP operator is installed but not fully configured
2. Velero KubeVirt plugin was partially installed/uninstalled
3. OADP was upgraded and the plugin didn't upgrade correctly
4. Custom namespace (velero-ppdm) was used instead of default (openshift-adp)


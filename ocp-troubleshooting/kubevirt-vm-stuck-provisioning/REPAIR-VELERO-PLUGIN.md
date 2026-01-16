# Repair OADP/Velero KubeVirt Plugin

## When to Use This Solution

Use this approach if:
- You **ARE** using OADP/Velero to backup KubeVirt VMs
- You want to properly fix the installation
- You need the webhook to function correctly for backup/restore operations

## Prerequisites

- OADP operator installed
- Cluster admin access
- S3-compatible storage configured (for OADP backups)

## Step 1: Verify Current OADP Installation

```bash
# Check OADP operator
oc get pods -n openshift-adp

# Check DataProtectionApplication
oc get dpa -n openshift-adp
```

## Step 2: Check Velero Deployment

```bash
# Check if Velero is running
oc get deployment -n openshift-adp | grep velero

# Check Velero pod
oc get pods -n openshift-adp -l component=velero

# Check Velero logs
VELERO_POD=$(oc get pod -n openshift-adp -l component=velero -o name | head -1)
oc logs -n openshift-adp $VELERO_POD --tail=100
```

## Step 3: Verify Plugin Configuration

The KubeVirt plugin should be configured in the DataProtectionApplication resource:

```bash
# Check current DPA configuration
oc get dpa -n openshift-adp -o yaml
```

Look for the plugins section. It should include the KubeVirt plugin:

```yaml
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: dpa-instance
  namespace: openshift-adp
spec:
  configuration:
    velero:
      defaultPlugins:
        - openshift
        - aws  # or azure, gcp, etc.
        - kubevirt  # <-- This plugin should be listed
      # ... other config
```

## Step 4: Add KubeVirt Plugin if Missing

If the plugin is not in the DPA configuration:

```bash
# Get the current DPA name
DPA_NAME=$(oc get dpa -n openshift-adp -o name | head -1 | cut -d'/' -f2)

# Edit the DPA to add kubevirt plugin
oc edit dpa $DPA_NAME -n openshift-adp
```

Add `kubevirt` to the `defaultPlugins` list:

```yaml
spec:
  configuration:
    velero:
      defaultPlugins:
        - openshift
        - aws  # your storage provider
        - kubevirt  # ADD THIS
```

Save and exit. The OADP operator will reconcile and deploy the plugin.

## Step 5: Wait for Reconciliation

```bash
# Watch the pods in openshift-adp namespace
watch -n 2 'oc get pods -n openshift-adp'

# Wait for all pods to be Running/Completed
# This may take 2-5 minutes
```

## Step 6: Verify Plugin Installation

```bash
# Check if Velero recognized the plugin
VELERO_POD=$(oc get pod -n openshift-adp -l component=velero -o name | head -1)
oc exec -n openshift-adp $VELERO_POD -- velero plugin get

# Should show something like:
# NAME                               KIND
# velero.io/kubevirt                 VolumeSnapshotter
```

## Step 7: Verify Webhook Service

```bash
# Check if the webhook service was created
oc get svc -n openshift-adp | grep kubevirt

# Expected output:
# kubevirt-velero-annotations-remover   ClusterIP   10.x.x.x   <none>   443/TCP   Xm
```

## Step 8: Verify Webhook Configuration

```bash
# Check the mutating webhook
oc get mutatingwebhookconfigurations | grep kubevirt

# Get details
WEBHOOK_NAME=$(oc get mutatingwebhookconfigurations | grep kubevirt | grep velero | awk '{print $1}')
oc get mutatingwebhookconfigurations $WEBHOOK_NAME -o yaml
```

Verify the service reference points to the correct namespace:

```yaml
webhooks:
  - name: kubevirt-velero-annotations-remover.openshift-adp.svc
    clientConfig:
      service:
        name: kubevirt-velero-annotations-remover
        namespace: openshift-adp  # Should match where service is running
        path: /mutate
```

## Step 9: Fix Webhook Service Reference (if needed)

If the webhook points to the wrong namespace (e.g., velero-ppdm instead of openshift-adp):

```bash
# Get the webhook name
WEBHOOK_NAME=$(oc get mutatingwebhookconfigurations | grep kubevirt | grep velero | awk '{print $1}')

# Patch the webhook to point to correct namespace
oc patch mutatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/clientConfig/service/namespace", "value": "openshift-adp"}]'
```

## Step 10: Test VM Creation

```bash
# Try creating a test VM
cat <<EOF | oc apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: test-vm
  namespace: default
spec:
  running: false
  template:
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
        resources:
          requests:
            memory: 1Gi
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/kubevirt/cirros-container-disk-demo
EOF

# Start the VM
oc patch vm test-vm -n default --type merge -p '{"spec":{"running":true}}'

# Check status
oc get vm test-vm -n default
oc get vmi test-vm -n default

# If successful, clean up
oc delete vm test-vm -n default
```

## Step 11: Fix Stuck VMs

If you had VMs stuck in provisioning before the fix:

```bash
# List stuck VMs
oc get vm -A | grep -v Running

# For each stuck VM, try restarting it:
VM_NAME="your-vm-name"
VM_NAMESPACE="your-namespace"

# Stop the VM
oc patch vm $VM_NAME -n $VM_NAMESPACE --type merge -p '{"spec":{"running":false}}'

# Wait a moment
sleep 5

# Start the VM
oc patch vm $VM_NAME -n $VM_NAMESPACE --type merge -p '{"spec":{"running":true}}'

# Monitor status
oc get vm $VM_NAME -n $VM_NAMESPACE -w
```

## Troubleshooting

### Plugin Not Loading

If the plugin doesn't load:

```bash
# Check OADP operator logs
oc logs -n openshift-adp deployment/oadp-operator --tail=100

# Check Velero pod logs
oc logs -n openshift-adp -l component=velero --tail=100

# Look for errors related to plugin initialization
```

### Webhook Service Not Created

If the service isn't created after adding the plugin:

```bash
# Delete and recreate the Velero pod to force reconciliation
oc delete pod -n openshift-adp -l component=velero

# Wait for pod to recreate
oc get pods -n openshift-adp -w
```

### Multiple OADP Namespaces

If you have OADP components in multiple namespaces (e.g., both openshift-adp and velero-ppdm):

1. Choose one as the primary namespace
2. Remove OADP from other namespaces
3. Update webhook to point to primary namespace

```bash
# Update webhook namespace
WEBHOOK_NAME=$(oc get mutatingwebhookconfigurations | grep kubevirt | awk '{print $1}')
oc patch mutatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/clientConfig/service/namespace", "value": "openshift-adp"}]'
```

## Verification Checklist

- [ ] OADP operator running
- [ ] DataProtectionApplication has kubevirt plugin
- [ ] Velero pod running and healthy
- [ ] `velero plugin get` shows kubevirt plugin
- [ ] Webhook service exists in correct namespace
- [ ] Webhook configuration points to correct service
- [ ] Test VM can be created and started
- [ ] Previously stuck VMs now working

## Testing Backup/Restore (Optional)

Once the plugin is working, test VM backup:

```bash
# Create a test backup
velero backup create test-vm-backup --include-namespaces default --selector kubevirt.io/vm=test-vm

# Check backup status
velero backup describe test-vm-backup

# Test restore (to different namespace)
velero restore create --from-backup test-vm-backup --namespace-mappings default:test-restore
```

## Reference

- [OADP Documentation](https://docs.openshift.com/container-platform/latest/backup_and_restore/application_backup_and_restore/installing/about-installing-oadp.html)
- [KubeVirt Plugin Documentation](https://github.com/kubevirt/kubevirt-velero-plugin)


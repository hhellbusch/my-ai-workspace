# Investigation Workflow for KubeVirt VM Stuck in Provisioning

This document provides a systematic workflow for investigating VMs stuck in provisioning state.

## Phase 1: Initial Assessment

### Step 1: Identify Stuck VMs

```bash
# List all VMs and their status
oc get vm -A -o wide

# Look for VMs not in "Running" state
oc get vm -A -o json | jq -r '.items[] | select(.status.ready != true) | "\(.metadata.namespace)/\(.metadata.name) - \(.status.conditions[].message)"'
```

### Step 2: Get Detailed VM Status

```bash
VM_NAME="<your-vm-name>"
VM_NAMESPACE="<your-namespace>"

# Get full VM status
oc get vm $VM_NAME -n $VM_NAMESPACE -o yaml

# Focus on conditions section
oc get vm $VM_NAME -n $VM_NAMESPACE -o jsonpath='{.status.conditions}' | jq .
```

### Step 3: Check for Common Error Patterns

Look for these in the VM status conditions:

**Pattern 1: Webhook errors**
```
message: 'failed to create virtual machine pod: Internal error occurred: 
failed calling webhook "...": ... service "..." not found'
```
→ **Resolution**: See [REMOVE-WEBHOOK.md](./REMOVE-WEBHOOK.md) or [REPAIR-VELERO-PLUGIN.md](./REPAIR-VELERO-PLUGIN.md)

**Pattern 2: PVC binding issues**
```
message: 'PersistentVolumeClaim is not bound'
reason: PVCNotReady
```
→ **Resolution**: See Phase 2, PVC Investigation

**Pattern 3: CDI import issues**
```
message: 'DataVolume not ready'
reason: DataVolumeError
```
→ **Resolution**: See Phase 2, CDI Investigation

**Pattern 4: Resource constraints**
```
message: 'Insufficient resources'
reason: FailedScheduling
```
→ **Resolution**: See Phase 2, Resource Investigation

**Pattern 5: Network issues**
```
message: 'Network attachment definition not found'
reason: NetworkError
```
→ **Resolution**: See Phase 2, Network Investigation

## Phase 2: Deep Dive Based on Error Pattern

### 2A: Webhook Investigation (Your Current Issue)

```bash
# List all mutating webhooks
oc get mutatingwebhookconfigurations

# Check for Velero-related webhooks
oc get mutatingwebhookconfigurations | grep -i velero

# If webhook found, check if service exists
WEBHOOK_NAME="<webhook-name-from-above>"
oc get mutatingwebhookconfigurations $WEBHOOK_NAME -o yaml | grep -A 10 "service:"

# Extract service name and namespace
SERVICE_NAME=$(oc get mutatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].clientConfig.service.name}')
SERVICE_NAMESPACE=$(oc get mutatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].clientConfig.service.namespace}')

# Check if service exists
oc get svc $SERVICE_NAME -n $SERVICE_NAMESPACE
```

**Resolution Options:**
- Quick fix: `oc delete mutatingwebhookconfigurations $WEBHOOK_NAME`
- Proper fix: Repair OADP plugin (see REPAIR-VELERO-PLUGIN.md)

### 2B: PVC Investigation

```bash
# Check VMI (VirtualMachineInstance) if it exists
oc get vmi $VM_NAME -n $VM_NAMESPACE

# Check PVCs for the VM
oc get pvc -n $VM_NAMESPACE | grep $VM_NAME

# Describe PVCs to see binding status
oc describe pvc -n $VM_NAMESPACE | grep -A 20 $VM_NAME

# Check for available PVs
oc get pv | grep Available

# Check storage class
oc get sc
```

**Common Issues:**
- No available PVs matching PVC requirements
- Storage class doesn't exist or is not default
- Insufficient storage capacity

**Resolution:**
```bash
# If PVC stuck pending, check events
oc get events -n $VM_NAMESPACE --sort-by='.lastTimestamp' | grep -i pvc

# If using dynamic provisioning, check provisioner pods
oc get pods -n openshift-storage  # or relevant storage namespace
```

### 2C: CDI (Containerized Data Importer) Investigation

```bash
# Check DataVolume if using CDI
oc get datavolume -n $VM_NAMESPACE | grep $VM_NAME
oc describe datavolume $VM_NAME -n $VM_NAMESPACE

# Check CDI pods
oc get pods -n openshift-cnv | grep cdi

# Check importer pod logs
IMPORTER_POD=$(oc get pods -n $VM_NAMESPACE | grep importer | grep $VM_NAME | awk '{print $1}')
oc logs $IMPORTER_POD -n $VM_NAMESPACE
```

**Common Issues:**
- CDI importer can't reach image URL
- Certificate issues with image registry
- Insufficient space in PVC

### 2D: Resource Investigation

```bash
# Check node resources
oc get nodes -o wide
oc describe nodes | grep -A 5 "Allocated resources"

# Check if VM can be scheduled
oc get events -n $VM_NAMESPACE --sort-by='.lastTimestamp' | grep -i $VM_NAME

# Check resource requests in VM spec
oc get vm $VM_NAME -n $VM_NAMESPACE -o jsonpath='{.spec.template.spec.domain.resources}'
```

**Resolution:**
- Scale down other workloads
- Add more nodes
- Reduce VM resource requests

### 2E: Network Investigation

```bash
# Check network attachment definitions
oc get network-attachment-definitions -A

# If VM uses specific network, check it exists
oc get network-attachment-definitions -n $VM_NAMESPACE

# Check multus pods (if using multus CNI)
oc get pods -n openshift-multus

# Check OVN/SDN pods
oc get pods -n openshift-sdn  # or openshift-ovn-kubernetes
```

## Phase 3: Check KubeVirt Components

### Step 1: Verify KubeVirt Installation

```bash
# Check KubeVirt operator
oc get pods -n openshift-cnv

# Check KubeVirt version
oc get kubevirt -A

# Check virt-operator logs
oc logs -n openshift-cnv deployment/virt-operator --tail=100
```

### Step 2: Check virt-controller

```bash
# Check virt-controller pods
oc get pods -n openshift-cnv | grep virt-controller

# Check logs for errors
oc logs -n openshift-cnv -l kubevirt.io=virt-controller --tail=100 | grep -i error
```

### Step 3: Check virt-api

```bash
# Check virt-api pods
oc get pods -n openshift-cnv | grep virt-api

# Check logs
oc logs -n openshift-cnv -l kubevirt.io=virt-api --tail=100
```

## Phase 4: Attempt Resolution

### Option 1: Restart VM (Soft Reset)

```bash
# Stop VM
oc patch vm $VM_NAME -n $VM_NAMESPACE --type merge -p '{"spec":{"running":false}}'

# Wait for VMI to terminate
oc get vmi $VM_NAME -n $VM_NAMESPACE -w

# Start VM
oc patch vm $VM_NAME -n $VM_NAMESPACE --type merge -p '{"spec":{"running":true}}'
```

### Option 2: Delete and Recreate VMI

```bash
# Backup VM spec
oc get vm $VM_NAME -n $VM_NAMESPACE -o yaml > vm-backup.yaml

# Delete VMI (not VM)
oc delete vmi $VM_NAME -n $VM_NAMESPACE

# VM controller should recreate VMI automatically
oc get vmi $VM_NAME -n $VM_NAMESPACE -w
```

### Option 3: Force Delete and Recreate VM

```bash
# Backup first!
oc get vm $VM_NAME -n $VM_NAMESPACE -o yaml > vm-backup.yaml

# Force delete
oc delete vm $VM_NAME -n $VM_NAMESPACE --force --grace-period=0

# Recreate from backup
oc apply -f vm-backup.yaml
```

### Option 4: Fix Underlying Issue

Based on Phase 1-3 investigation, fix the specific issue:
- Remove/fix webhook (current issue)
- Create missing PV/PVC
- Fix CDI importer
- Add node resources
- Configure network

## Phase 5: Verification

### Step 1: Monitor VM Startup

```bash
# Watch VM status
watch -n 2 'oc get vm $VM_NAME -n $VM_NAMESPACE'

# Watch VMI status
watch -n 2 'oc get vmi $VM_NAME -n $VM_NAMESPACE'

# Watch pods
watch -n 2 'oc get pods -n $VM_NAMESPACE | grep virt-launcher'
```

### Step 2: Check VM is Ready

```bash
# VM should show "Running: true" and "Ready: true"
oc get vm $VM_NAME -n $VM_NAMESPACE -o jsonpath='{.status}' | jq .

# VMI should be in "Running" phase
oc get vmi $VM_NAME -n $VM_NAMESPACE -o jsonpath='{.status.phase}'

# virt-launcher pod should be "Running"
oc get pods -n $VM_NAMESPACE -l kubevirt.io=virt-launcher,vm.kubevirt.io/name=$VM_NAME
```

### Step 3: Test VM Connectivity

```bash
# Access console (if available)
virtctl console $VM_NAME -n $VM_NAMESPACE

# Check VM IP (if guest agent running)
oc get vmi $VM_NAME -n $VM_NAMESPACE -o jsonpath='{.status.interfaces[0].ipAddress}'

# Test SSH (if configured)
ssh user@<vm-ip>
```

## Phase 6: Document and Prevent

### Document the Issue

1. Save diagnostic output
2. Note the root cause
3. Document the fix applied
4. Update runbooks if needed

### Prevent Recurrence

Based on root cause:

**Webhook issues:**
- Monitor OADP/Velero health
- Validate webhook configurations regularly
- See [PREVENTION.md](./PREVENTION.md)

**Resource issues:**
- Set up monitoring/alerting for node capacity
- Implement resource quotas appropriately

**Network issues:**
- Validate network policies
- Test network attachment definitions before VM creation

**Storage issues:**
- Monitor PV availability
- Set up dynamic provisioning with adequate storage

## Quick Reference Commands

```bash
# One-liner to check VM health
oc get vm $VM_NAME -n $VM_NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")]}' | jq .

# One-liner to get last error
oc get vm $VM_NAME -n $VM_NAMESPACE -o jsonpath='{.status.conditions[?(@.status=="False")].message}'

# One-liner to check all components
oc get vm,vmi,pod -n $VM_NAMESPACE -l vm.kubevirt.io/name=$VM_NAME

# Watch all VM events
oc get events -n $VM_NAMESPACE --watch | grep $VM_NAME
```

## Escalation Checklist

Escalate to senior support if:
- [ ] Issue persists after following this workflow
- [ ] KubeVirt components are unhealthy
- [ ] Issue affects multiple VMs across namespaces
- [ ] Underlying infrastructure issue suspected
- [ ] API server or etcd issues present

Include in escalation:
- Output from diagnostic-commands.sh
- VM YAML spec
- Relevant logs from KubeVirt components
- Timeline of issue and attempted fixes


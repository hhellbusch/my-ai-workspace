# Namespace Stuck in Terminating State

## Problem Statement

A namespace remains in `Terminating` state indefinitely, unable to complete deletion. This typically occurs when:
- Resources in the namespace have finalizers that cannot be processed
- The controller/operator responsible for the finalizer is no longer running
- Custom Resource Definitions (CRDs) or their operators were removed before cleaning up resources
- Webhook endpoints are unreachable or timing out

## Symptoms

```bash
$ oc get namespace <namespace-name>
NAME              STATUS        AGE
<namespace-name>  Terminating   45m

$ oc describe namespace <namespace-name>
...
Status:        Terminating
Conditions:
  Type                                    Status  LastTransitionTime               Reason                Message
  ----                                    ------  ------------------               ------                -------
  NamespaceContentRemaining               True    ...                              SomeFinalizersRemain  Some content in the namespace has finalizers remaining: <finalizer-name> in X resource instances
  NamespaceDeletionContentFailure         True    ...                              ContentDeletionFailed Failed to delete all resource types
```

## Root Cause

Finalizers are metadata fields that tell Kubernetes to perform specific cleanup actions before deleting a resource. When the controller that handles these finalizers is unavailable or encounters errors, the namespace cannot complete deletion.

Common problematic finalizers:
- `kubernetes` - Standard Kubernetes finalizer
- `opentelemetrycollector.opentelemetry.io/finalizer` - OpenTelemetry Operator
- `finalizers.managedcluster.cluster.open-cluster-management.io` - RHACM/ACM
- `kubernetes.io/pv-protection` - Persistent Volume protection
- Custom operator finalizers

## Investigation Steps

### 1. Check Namespace Status

```bash
# View namespace details
oc describe namespace <namespace-name>

# Check finalizers on the namespace itself
oc get namespace <namespace-name> -o yaml | grep -A 5 finalizers

# Get namespace in JSON for detailed inspection
oc get namespace <namespace-name> -o json | jq '.spec.finalizers, .metadata.finalizers'
```

### 2. Identify Resources with Finalizers

```bash
# List all resources in the namespace
oc api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 oc get --show-kind --ignore-not-found -n <namespace-name>

# Find resources with finalizers
oc api-resources --verbs=list --namespaced -o name | \
  while read resource; do
    oc get $resource -n <namespace-name> -o json 2>/dev/null | \
      jq -r ".items[] | select(.metadata.finalizers != null) | \"\(.kind)/\(.metadata.name): \(.metadata.finalizers)\""
  done
```

### 3. Check for Operator/Controller Issues

```bash
# Check if relevant operators are running
oc get pods -n openshift-operators
oc get pods -n openshift-operator-lifecycle-manager

# Check operator logs for errors
oc logs -n <operator-namespace> <operator-pod-name>
```

## Resolution Methods

### Method 1: Remove Finalizers from Individual Resources

This is the **recommended** approach as it's the cleanest and safest.

#### Step 1: Identify the problematic resource

```bash
# For OpenTelemetry Collector example:
oc get opentelemetrycollector -n <namespace-name>

# Generic approach for any resource type:
oc api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 oc get --show-kind --ignore-not-found -n <namespace-name> -o json | \
  jq -r 'select(.items != null) | .items[] | select(.metadata.finalizers != null) | "\(.kind)/\(.metadata.name)"'
```

#### Step 2: Remove the finalizer from the resource

```bash
# Patch method (preferred):
oc patch <resource-type> <resource-name> -n <namespace-name> \
  -p '{"metadata":{"finalizers":[]}}' --type=merge

# Example for OpenTelemetryCollector:
oc patch opentelemetrycollector my-collector -n <namespace-name> \
  -p '{"metadata":{"finalizers":[]}}' --type=merge

# Edit method:
oc edit <resource-type> <resource-name> -n <namespace-name>
# Remove or empty the finalizers array
```

#### Step 3: Verify namespace deletion

```bash
oc get namespace <namespace-name>
# Should show the namespace is gone or will complete deletion shortly
```

### Method 2: Remove Finalizers from Namespace Directly

Use this when resources are already gone but the namespace still has finalizers.

```bash
# Remove spec finalizers
oc patch namespace <namespace-name> \
  -p '{"spec":{"finalizers":null}}' --type=merge

# If that doesn't work, try metadata finalizers
oc patch namespace <namespace-name> \
  -p '{"metadata":{"finalizers":null}}' --type=merge

# Or edit directly
oc edit namespace <namespace-name>
# Remove finalizers arrays from both spec and metadata sections
```

### Method 3: Direct API Call (Nuclear Option)

Use this when patching fails due to API server issues or validation webhooks.

```bash
# Get the namespace
oc get namespace <namespace-name> -o json > namespace-backup.json

# Edit namespace-backup.json:
# - Remove or empty "finalizers" from spec
# - Remove or empty "finalizers" from metadata

# Apply using raw API
oc replace --raw "/api/v1/namespaces/<namespace-name>/finalize" -f namespace-backup.json
```

### Method 4: Automated Cleanup Script

See `cleanup-namespace-finalizers.sh` for an automated approach.

## Common Scenarios

### Scenario 1: OpenTelemetry Collector

**Error Message:**
```
Some content in the namespace has finalizers remaining: opentelemetrycollector.opentelemetry.io/finalizer in 1 resource instances
```

**Resolution:**
```bash
# Find the collector
oc get opentelemetrycollector -n <namespace-name>

# Remove finalizer
oc patch opentelemetrycollector <collector-name> -n <namespace-name> \
  -p '{"metadata":{"finalizers":[]}}' --type=merge

# Or use the automated approach:
oc get opentelemetrycollector -n <namespace-name> -o name | \
  xargs -I {} oc patch {} -n <namespace-name> \
    -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### Scenario 2: RHACM Managed Cluster

**Error Message:**
```
Some content in the namespace has finalizers remaining: finalizers.managedcluster.cluster.open-cluster-management.io
```

**Resolution:**
```bash
# Find managed cluster resources
oc get managedcluster -n <namespace-name>

# Remove finalizer
oc patch managedcluster <cluster-name> -n <namespace-name> \
  -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### Scenario 3: Persistent Volumes

**Error Message:**
```
Some content in the namespace has finalizers remaining: kubernetes.io/pv-protection
```

**Resolution:**
```bash
# Find PVCs with protection
oc get pvc -n <namespace-name> -o json | \
  jq -r '.items[] | select(.metadata.finalizers != null) | .metadata.name'

# Remove finalizer from each PVC
oc patch pvc <pvc-name> -n <namespace-name> \
  -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### Scenario 4: Custom Resource Definitions (CRD deleted)

When a CRD is deleted before its resources:

```bash
# The resource type may not be recognized anymore
# Use raw API to delete

# First, find the resource group/version/kind from the namespace status
oc describe namespace <namespace-name>

# Example: If you see "customresource.example.com/v1" 
# Try to get resources directly
oc get customresource.example.com -n <namespace-name> -o name

# If that fails, use raw API
RESOURCE_NAME="resource-name"
API_PATH="/apis/example.com/v1/namespaces/<namespace-name>/customresources/$RESOURCE_NAME"

# Get the resource
oc get --raw "$API_PATH" > resource.json

# Edit resource.json to remove finalizers

# Update via raw API
oc replace --raw "$API_PATH" -f resource.json
```

## Prevention

1. **Always delete resources before deleting operators:**
   ```bash
   # Delete operator resources first
   oc delete opentelemetrycollector --all -n <namespace-name>
   
   # Then uninstall the operator
   oc delete subscription <operator-subscription> -n openshift-operators
   ```

2. **Use proper cleanup procedures:**
   ```bash
   # Many operators provide cleanup commands
   # Check operator documentation before removal
   ```

3. **Set deletion timeouts for testing environments:**
   ```bash
   # Add annotations to allow forced deletion (use with caution)
   oc annotate namespace <namespace-name> \
     openshift.io/node-selector="" \
     --overwrite
   ```

## Verification

After removing finalizers, verify the namespace is deleted:

```bash
# Watch namespace deletion
watch oc get namespace <namespace-name>

# Check for any remaining resources
oc api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 oc get --show-kind --ignore-not-found -n <namespace-name>

# Verify no events indicate issues
oc get events -n <namespace-name>
```

## Additional Resources

- [Kubernetes Finalizers Documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/)
- [OpenShift Namespace Deletion](https://docs.openshift.com/container-platform/latest/applications/projects/working-with-projects.html)
- Script: `cleanup-namespace-finalizers.sh` - Automated cleanup
- Script: `investigate-namespace.sh` - Investigation helper
- Quick Reference: `QUICK-REFERENCE.md` - Common commands

## Safety Notes

⚠️ **Important:**
- Removing finalizers bypasses intended cleanup procedures
- This may leave orphaned resources in external systems
- Use the most targeted approach possible (remove from resources, not namespace)
- Always investigate WHY a finalizer is stuck before removing it
- In production, consider fixing the underlying operator/controller issue instead

## Troubleshooting Tips

1. **Namespace won't delete even after removing finalizers:**
   - Check if there are admission webhooks blocking deletion
   - Look for ValidatingWebhookConfiguration or MutatingWebhookConfiguration
   - Temporarily disable problematic webhooks if needed

2. **Can't patch resources:**
   - API server may be enforcing validation
   - Try using `--force` or `--grace-period=0`
   - Fall back to raw API calls

3. **Resources keep recreating:**
   - Check for controllers or operators still running
   - Look for DaemonSets, StatefulSets, or Deployments managing the resources
   - Scale down or delete the parent controller first

4. **Error: "the server doesn't have a resource type":**
   - CRD was likely deleted before resources
   - Use raw API paths to access resources
   - May need to temporarily recreate CRD to clean up resources

## Related Issues

- [control-plane-kubeconfigs](../control-plane-kubeconfigs/) - Stuck resources in kube-system
- [kubevirt-vm-stuck-provisioning](../kubevirt-vm-stuck-provisioning/) - VM finalizer issues
- [portworx-csi-crashloop](../portworx-csi-crashloop/) - CSI driver finalizers

---

*Last Updated: February 2026*
*OpenShift Versions: 4.12+*
*Tested on: OpenShift 4.14, 4.15*


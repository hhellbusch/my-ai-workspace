# Examples: Namespace Stuck in Terminating

This document provides real-world examples and scenarios for resolving namespace deletion issues.

## Table of Contents

1. [OpenTelemetry Collector](#example-1-opentelemetry-collector)
2. [RHACM Managed Cluster](#example-2-rhacm-managed-cluster)
3. [Multiple Resource Types](#example-3-multiple-resource-types)
4. [CRD Deleted Before Resources](#example-4-crd-deleted-before-resources)
5. [Webhook Blocking Deletion](#example-5-webhook-blocking-deletion)
6. [Persistent Volume Claims](#example-6-persistent-volume-claims)
7. [Service Mesh Resources](#example-7-service-mesh-resources)

---

## Example 1: OpenTelemetry Collector

### Scenario

Namespace `observability-test` is stuck after attempting to delete it. The OpenTelemetry Operator was uninstalled before cleaning up collector resources.

### Error Message

```bash
$ oc describe namespace observability-test
...
Status:        Terminating
Conditions:
  Type                                    Status  Reason                Message
  ----                                    ------  ------                -------
  NamespaceContentRemaining               True    SomeFinalizersRemain  Some content in the namespace has finalizers remaining: opentelemetrycollector.opentelemetry.io/finalizer in 1 resource instances
```

### Investigation

```bash
# Check namespace status
$ oc get namespace observability-test
NAME                 STATUS        AGE
observability-test   Terminating   45m

# Find the problematic resource
$ oc get opentelemetrycollector -n observability-test
NAME              AGE
metrics-collector 2d

# Check its finalizers
$ oc get opentelemetrycollector metrics-collector -n observability-test -o yaml | grep -A 5 finalizers
metadata:
  finalizers:
  - opentelemetrycollector.opentelemetry.io/finalizer
```

### Solution

```bash
# Remove the finalizer from the collector
$ oc patch opentelemetrycollector metrics-collector -n observability-test \
  -p '{"metadata":{"finalizers":[]}}' --type=merge

opentelemetrycollector.opentelemetry.io/metrics-collector patched

# Verify namespace deletion
$ oc get namespace observability-test
Error from server (NotFound): namespaces "observability-test" not found
```

### Prevention

Always delete resources before uninstalling operators:

```bash
# Correct order:
oc delete opentelemetrycollector --all -n observability-test
oc delete namespace observability-test
# Then uninstall operator via OLM
```

---

## Example 2: RHACM Managed Cluster

### Scenario

Namespace containing a managed cluster definition is stuck after the hub cluster was partially decommissioned.

### Error Message

```bash
$ oc describe namespace cluster-prod-west
...
Status:        Terminating
Conditions:
  NamespaceContentRemaining: True
  Message: Some content in the namespace has finalizers remaining:
    - managedcluster.finalizers.open-cluster-management.io
    - cluster.open-cluster-management.io/api-resource-cleanup
```

### Investigation

```bash
# Check for managed cluster resources
$ oc get managedcluster -n cluster-prod-west
NAME             HUB ACCEPTED   MANAGED CLUSTER URLS   JOINED   AVAILABLE   AGE
prod-west-01     true                                  Unknown  Unknown     5d

# Check finalizers
$ oc get managedcluster prod-west-01 -n cluster-prod-west -o jsonpath='{.metadata.finalizers}'
["managedcluster.finalizers.open-cluster-management.io","cluster.open-cluster-management.io/api-resource-cleanup"]

# Check if RHACM operator is running
$ oc get pods -n open-cluster-management
No resources found in open-cluster-management namespace.
```

### Solution

```bash
# Since the RHACM operator is gone, remove finalizers manually
$ oc patch managedcluster prod-west-01 -n cluster-prod-west \
  -p '{"metadata":{"finalizers":[]}}' --type=merge

# Also remove any klusterlet addon resources
$ oc get klusterletaddonconfig -n cluster-prod-west -o name | \
  xargs -I {} oc patch {} -n cluster-prod-west -p '{"metadata":{"finalizers":[]}}' --type=merge

# Verify
$ oc get namespace cluster-prod-west
Error from server (NotFound): namespaces "cluster-prod-west" not found
```

### Additional Cleanup

If you have multiple managed cluster namespaces:

```bash
# Find all managed cluster namespaces
$ oc get namespaces -l cluster.open-cluster-management.io/managedCluster=true

# Clean them all
for ns in $(oc get namespaces -l cluster.open-cluster-management.io/managedCluster=true -o name | cut -d'/' -f2); do
  echo "Cleaning namespace: $ns"
  oc get managedcluster -n $ns -o name | \
    xargs -I {} oc patch {} -n $ns -p '{"metadata":{"finalizers":[]}}' --type=merge
  oc patch namespace $ns -p '{"spec":{"finalizers":[]}}' --type=merge
done
```

---

## Example 3: Multiple Resource Types

### Scenario

Development namespace with multiple operators and custom resources, all stuck after namespace deletion.

### Investigation

```bash
$ ./investigate-namespace.sh dev-environment
...
Resources with Finalizers:
Type: OpenTelemetryCollector
Name: jaeger-collector
Finalizers: ["opentelemetrycollector.opentelemetry.io/finalizer"]
---
Type: ServiceMonitor
Name: app-metrics
Finalizers: ["monitoring.coreos.com/finalizer"]
---
Type: Certificate
Name: app-tls
Finalizers: ["cert-manager.io/finalizer"]
---
```

### Solution

```bash
# Use automated cleanup script
$ ./cleanup-namespace-finalizers.sh dev-environment --dry-run
[INFO] Checking prerequisites...
[SUCCESS] Prerequisites met
[INFO] Checking namespace: dev-environment
[SUCCESS] Namespace found and is in Terminating state
[INFO] Searching for resources with finalizers...
[WARNING] Found: OpenTelemetryCollector/jaeger-collector:["opentelemetrycollector.opentelemetry.io/finalizer"]
[WARNING] Found: ServiceMonitor/app-metrics:["monitoring.coreos.com/finalizer"]
[WARNING] Found: Certificate/app-tls:["cert-manager.io/finalizer"]
[INFO] [DRY-RUN] Would remove finalizers from 3 resource(s)

# Execute cleanup
$ ./cleanup-namespace-finalizers.sh dev-environment
...
[SUCCESS] Removed finalizers from 3 resource(s)
[SUCCESS] Namespace successfully deleted!
```

### Manual Alternative

```bash
# Remove finalizers one by one
oc patch opentelemetrycollector jaeger-collector -n dev-environment \
  -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch servicemonitor app-metrics -n dev-environment \
  -p '{"metadata":{"finalizers":[]}}' --type=merge

oc patch certificate app-tls -n dev-environment \
  -p '{"metadata":{"finalizers":[]}}' --type=merge
```

---

## Example 4: CRD Deleted Before Resources

### Scenario

A custom operator was completely removed including its CRD, but resources still exist in namespaces.

### Error Message

```bash
$ oc describe namespace app-prod
...
Status: Terminating
Message: Some content in the namespace has finalizers remaining: 
  customapp.example.com/v1alpha1 in 2 resource instances
```

### Investigation

```bash
# Try to get the custom resource (will fail)
$ oc get customapp -n app-prod
error: the server doesn't have a resource type "customapp"

# Check API resources
$ oc api-resources | grep customapp
# (no output - CRD is gone)

# Check namespace for stuck references
$ oc get namespace app-prod -o json | jq '.status.conditions'
```

### Solution Method 1: Using Raw API

```bash
# Get the full API path from namespace status or operator docs
# Example: customapps.example.com/v1alpha1

# List resources via raw API
$ oc get --raw "/apis/example.com/v1alpha1/namespaces/app-prod/customapps" | jq -r '.items[].metadata.name'
myapp-1
myapp-2

# Get each resource
$ oc get --raw "/apis/example.com/v1alpha1/namespaces/app-prod/customapps/myapp-1" > myapp-1.json

# Edit myapp-1.json to remove finalizers from metadata
$ vi myapp-1.json
# Remove: "metadata": { "finalizers": [...] }

# Update via raw API
$ oc replace --raw "/apis/example.com/v1alpha1/namespaces/app-prod/customapps/myapp-1" -f myapp-1.json

# Repeat for myapp-2
```

### Solution Method 2: Recreate CRD Temporarily

```bash
# If you have the CRD definition, recreate it temporarily
$ oc apply -f customapp-crd.yaml

# Now you can access and patch resources normally
$ oc get customapp -n app-prod
$ oc patch customapp myapp-1 -n app-prod -p '{"metadata":{"finalizers":[]}}' --type=merge
$ oc patch customapp myapp-2 -n app-prod -p '{"metadata":{"finalizers":[]}}' --type=merge

# Delete the CRD again (resources should be gone)
$ oc delete crd customapps.example.com
```

### Solution Method 3: Force Finalize Namespace

```bash
# Get namespace
$ oc get namespace app-prod -o json > namespace.json

# Edit namespace.json
$ vi namespace.json
# Remove "finalizers" from both spec and metadata
# Set "phase": "Active" in status (sometimes needed)

# Update using finalize endpoint
$ oc replace --raw "/api/v1/namespaces/app-prod/finalize" -f namespace.json
```

---

## Example 5: Webhook Blocking Deletion

### Scenario

Namespace deletion is blocked by a validating webhook that's no longer responding.

### Error Message

```bash
$ oc delete namespace test-webhooks
# Hangs indefinitely

$ oc describe namespace test-webhooks
...
Status: Terminating
Message: Unable to validate deletion due to webhook timeout
```

### Investigation

```bash
# Check validating webhooks
$ oc get validatingwebhookconfigurations
NAME                          WEBHOOKS   AGE
example-webhook-config        1          30d

# Check webhook details
$ oc get validatingwebhookconfigurations example-webhook-config -o yaml
...
webhooks:
- name: validate.example.com
  clientConfig:
    service:
      name: webhook-service
      namespace: webhook-system
      path: /validate
  failurePolicy: Fail  # <-- This is the problem
  namespaceSelector:
    matchExpressions:
    - key: environment
      operator: Exists
```

### Solution Method 1: Change Webhook Failure Policy

```bash
# Change failurePolicy to Ignore temporarily
$ oc patch validatingwebhookconfigurations example-webhook-config \
  --type='json' -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]'

# Try deletion again
$ oc delete namespace test-webhooks
namespace "test-webhooks" deleted
```

### Solution Method 2: Delete the Webhook

```bash
# If webhook is no longer needed
$ oc delete validatingwebhookconfigurations example-webhook-config

# Delete namespace
$ oc delete namespace test-webhooks
```

### Solution Method 3: Fix Webhook Service

```bash
# Check if webhook service exists and is responsive
$ oc get service webhook-service -n webhook-system

# Check webhook pod
$ oc get pods -n webhook-system -l app=webhook

# If service is down, scale it up or delete the webhook config
```

---

## Example 6: Persistent Volume Claims

### Scenario

Namespace with PVCs that have protection finalizers.

### Investigation

```bash
$ oc get pvc -n storage-test
NAME         STATUS        VOLUME    CAPACITY   ACCESS MODES   AGE
data-pvc-1   Terminating   pv-1234   10Gi       RWO            5d
data-pvc-2   Terminating   pv-5678   20Gi       RWO            5d

$ oc get pvc data-pvc-1 -n storage-test -o yaml | grep finalizers -A 2
metadata:
  finalizers:
  - kubernetes.io/pvc-protection
```

### Solution

```bash
# Method 1: Remove finalizers from PVCs
$ oc get pvc -n storage-test -o name | \
  xargs -I {} oc patch {} -n storage-test -p '{"metadata":{"finalizers":[]}}' --type=merge

# Method 2: Delete PVs first (if appropriate)
$ oc get pv | grep storage-test
pv-1234   10Gi   RWO   Retain   Bound   storage-test/data-pvc-1   ...
pv-5678   20Gi   RWO   Retain   Bound   storage-test/data-pvc-2   ...

# Remove PV protection
$ oc patch pv pv-1234 -p '{"metadata":{"finalizers":[]}}' --type=merge
$ oc patch pv pv-5678 -p '{"metadata":{"finalizers":[]}}' --type=merge

# Now PVCs should delete
$ oc delete pvc --all -n storage-test
```

### Important Notes

- **Data Loss Warning**: Removing PVC protection finalizers will delete data
- Check if PVs should be retained for other uses
- Consider backup before removal in production

---

## Example 7: Service Mesh Resources

### Scenario

Namespace with Istio/Service Mesh resources stuck due to sidecar injector finalizers.

### Investigation

```bash
$ oc describe namespace mesh-app
...
Status: Terminating
Message: Discovery failed for some groups: unable to retrieve the complete list of server APIs

$ oc get all -n mesh-app
NAME                        READY   STATUS        RESTARTS   AGE
pod/app-7d8f9c-abc12        2/2     Terminating   0          2d
```

### Solution

```bash
# Find mesh-related resources
$ oc get virtualservices -n mesh-app
$ oc get destinationrules -n mesh-app
$ oc get serviceentries -n mesh-app

# Remove finalizers from mesh resources
$ oc get virtualservices -n mesh-app -o name | \
  xargs -I {} oc patch {} -n mesh-app -p '{"metadata":{"finalizers":[]}}' --type=merge

$ oc get destinationrules -n mesh-app -o name | \
  xargs -I {} oc patch {} -n mesh-app -p '{"metadata":{"finalizers":[]}}' --type=merge

# If pods are stuck with sidecars
$ oc get pods -n mesh-app -o name | \
  xargs -I {} oc delete {} -n mesh-app --force --grace-period=0

# Remove namespace finalizers
$ oc patch namespace mesh-app -p '{"metadata":{"finalizers":[]}}' --type=merge
```

---

## Troubleshooting Patterns

### Pattern 1: Operator Lifecycle Issues

**Problem**: Operator deleted before cleaning resources

**Solution Template**:
```bash
# 1. Identify operator's resource types
oc api-resources --api-group=<operator-group>

# 2. Find all resources
for resource in $(oc api-resources --api-group=<operator-group> -o name); do
  oc get $resource -n <namespace>
done

# 3. Remove finalizers from each
for resource in $(oc api-resources --api-group=<operator-group> -o name); do
  oc get $resource -n <namespace> -o name | \
    xargs -I {} oc patch {} -n <namespace> -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
done
```

### Pattern 2: Bulk Namespace Cleanup

**Problem**: Multiple namespaces stuck with same issue

**Solution Template**:
```bash
# Create cleanup script for multiple namespaces
for ns in namespace1 namespace2 namespace3; do
  echo "Cleaning $ns..."
  ./cleanup-namespace-finalizers.sh $ns
done
```

### Pattern 3: Production Safety

**Problem**: Need to clean namespace in production carefully

**Solution Template**:
```bash
# 1. Investigation
./investigate-namespace.sh prod-namespace

# 2. Dry run
./cleanup-namespace-finalizers.sh prod-namespace --dry-run

# 3. Backup critical resources
oc get all -n prod-namespace -o yaml > prod-namespace-backup.yaml

# 4. Execute with confirmation
./cleanup-namespace-finalizers.sh prod-namespace

# 5. Verify
oc get namespace prod-namespace
```

---

## Common Finalizer Reference

| Finalizer | Operator/Source | Safe to Remove? | Notes |
|-----------|----------------|-----------------|-------|
| `kubernetes` | Core Kubernetes | Usually | Standard finalizer |
| `kubernetes.io/pv-protection` | Core Kubernetes | Check PV state | Protects against data loss |
| `opentelemetrycollector.opentelemetry.io/finalizer` | OpenTelemetry | Yes if operator gone | Cleans collector resources |
| `managedcluster.finalizers.open-cluster-management.io` | RHACM | Check cluster state | De-registers cluster |
| `cluster.open-cluster-management.io/api-resource-cleanup` | RHACM | Check cluster state | Cleans hub resources |
| `cert-manager.io/finalizer` | Cert-Manager | Yes if cert not needed | Revokes certificates |
| `monitoring.coreos.com/finalizer` | Prometheus Operator | Yes | Removes monitoring configs |
| `operator.tekton.dev` | Tekton | Yes if operator gone | Cleans pipeline resources |
| `finalizers.argocd.argoproj.io` | Argo CD | Check app state | Manages app resources |
| `resources-finalizer.argocd.argoproj.io` | Argo CD | Check app state | Cascades deletion |

---

*Last Updated: February 2026*
*OpenShift Versions: 4.12+*


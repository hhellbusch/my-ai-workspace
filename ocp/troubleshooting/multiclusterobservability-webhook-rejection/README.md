# MultiClusterObservability Admission Webhook Rejection

## Symptom

Unable to edit or delete a MultiClusterObservability resource due to an admission webhook rejecting the request with an error stating the name is nil, despite the name being present in the YAML manifest.

**Common error messages:**
```
Error from server: admission webhook "xxx" denied the request: name cannot be nil
Error from server: admission webhook "multiclusterobservabilities.observability.open-cluster-management.io" denied the request: metadata.name is required
admission webhook "vmulticlusterobservability.observability.open-cluster-management.io" denied the request: MultiClusterObservability.observability.open-cluster-management.io "" is invalid: <nil>: Internal error: resource name may not be empty
```

**Note:** The last error with `""` (empty string) and "resource name may not be empty" indicates the webhook is receiving a request where `metadata.name` is literally empty or not being passed at all.

## Root Causes

1. **Command Missing Resource Name**: Running delete/patch commands without specifying the resource name (e.g., `oc delete multiclusterobservability` instead of `oc delete multiclusterobservability observability`)
2. **Malformed YAML**: The YAML has `metadata:` section but missing or empty `name:` field
3. **Client/API Bug**: The oc client or API server is stripping the name from the request before it reaches the webhook
4. **Nested Resource Missing Name**: The webhook may be validating a nested resource (like alertmanager config, storage config, or advanced config) that's missing a name field
5. **Stale Webhook Configuration**: Webhook configurations pointing to non-existent or misconfigured services
6. **API Version Mismatch**: Using an older API version with newer webhook validation rules
7. **Operator in Degraded State**: The observability operator itself may be in a bad state
8. **CRD Definition Mismatch**: CRD and webhook validation schemas out of sync

## Investigation Workflow

### 1. Identify the Webhook Configuration

```bash
# List all validating webhooks related to observability
oc get validatingwebhookconfigurations | grep -i observability

# Get detailed webhook configuration
oc get validatingwebhookconfigurations <webhook-name> -o yaml

# List all mutating webhooks related to observability
oc get mutatingwebhookconfigurations | grep -i observability

# Get detailed mutating webhook configuration
oc get mutatingwebhookconfigurations <webhook-name> -o yaml
```

**What to look for:**
- Webhook service endpoints that may be unreachable
- `failurePolicy` settings (should be `Ignore` for operational flexibility)
- Namespace selector configurations
- API group/version configurations

### 2. Check the MultiClusterObservability Resource

```bash
# Get the current resource
oc get multiclusterobservability -o yaml > mco-current.yaml

# Check resource details
oc describe multiclusterobservability

# Check for finalizers that may be blocking deletion
oc get multiclusterobservability -o jsonpath='{.items[*].metadata.finalizers}'
```

**Validate your YAML:**
```yaml
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
  name: observability  # ← This should be present
spec:
  observabilityAddonSpec: {}
  storageConfig:
    metricObjectStorage:
      name: thanos-object-storage  # ← Nested resources need names too
      key: thanos.yaml
```

### 3. Check Observability Operator Status

```bash
# Check operator pods
oc get pods -n open-cluster-management-observability

# Check operator logs
oc logs -n open-cluster-management-addon-observability deployment/endpoint-observability-operator

# Check multicluster-observability-operator
oc logs -n open-cluster-management deployment/multicluster-observability-operator

# Check for any failing pods
oc get pods -n open-cluster-management-observability --field-selector=status.phase!=Running,status.phase!=Succeeded
```

### 4. Examine CRD Definition

```bash
# Get CRD details
oc get crd multiclusterobservabilities.observability.open-cluster-management.io -o yaml > mco-crd.yaml

# Check CRD validation schema
oc get crd multiclusterobservabilities.observability.open-cluster-management.io -o jsonpath='{.spec.versions[*].schema.openAPIV3Schema}' | jq .
```

### 5. Test Webhook Connectivity

```bash
# Get webhook service details
WEBHOOK_SVC=$(oc get validatingwebhookconfigurations <webhook-name> -o jsonpath='{.webhooks[0].clientConfig.service.name}')
WEBHOOK_NS=$(oc get validatingwebhookconfigurations <webhook-name> -o jsonpath='{.webhooks[0].clientConfig.service.namespace}')

# Check if service exists and has endpoints
oc get service $WEBHOOK_SVC -n $WEBHOOK_NS
oc get endpoints $WEBHOOK_SVC -n $WEBHOOK_NS

# Check pods backing the webhook
oc get pods -n $WEBHOOK_NS -l app=$WEBHOOK_SVC
```

## Resolution Strategies

### Strategy 0: Fix Command Syntax (For "resource name may not be empty")

**Use this if you see:** `MultiClusterObservability.observability.open-cluster-management.io "" is invalid: <nil>: Internal error: resource name may not be empty`

This error means the webhook is receiving a request where `metadata.name` is literally empty. This typically happens when:

#### Issue 1: Missing Resource Name in Command

```bash
# ❌ WRONG - Missing resource name
oc delete multiclusterobservability
oc patch multiclusterobservability -p '{"spec":{"enabled":false}}'
oc edit multiclusterobservability

# ✅ CORRECT - Include resource name
oc delete multiclusterobservability observability
oc patch multiclusterobservability observability -p '{"spec":{"enabled":false}}'
oc edit multiclusterobservability observability
```

**Check what resources exist:**
```bash
# List all MCO resources to get the name
oc get multiclusterobservability

# Common names are "observability" or "multicluster-observability"
NAME            AGE
observability   45d
```

**Then use the correct name:**
```bash
# Use the actual name from the list
oc delete multiclusterobservability observability
```

#### Issue 2: Malformed YAML Missing metadata.name

Check your YAML file:

```yaml
# ❌ WRONG - Missing name field
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
  namespace: open-cluster-management-observability  # ← name is missing!
spec:
  observabilityAddonSpec: {}

# ✅ CORRECT - Name is present
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
  name: observability  # ← Required!
spec:
  observabilityAddonSpec: {}
```

**Validate your YAML:**
```bash
# Check if name field exists
grep -A 3 "^metadata:" your-mco.yaml

# Should show:
# metadata:
#   name: observability
```

#### Issue 3: Using Wrong API Endpoint or Method

If you're using direct API calls (curl/scripts):

```bash
# ❌ WRONG - Generic endpoint without name
curl -X DELETE "https://$API/apis/observability.open-cluster-management.io/v1beta2/multiclusterobservabilities"

# ✅ CORRECT - Specific resource endpoint with name
curl -X DELETE "https://$API/apis/observability.open-cluster-management.io/v1beta2/multiclusterobservabilities/observability"
```

#### Issue 4: Name IS Present But Still Getting Error (Your Case!)

**If you're CERTAIN the name is in your YAML or command but still getting this error**, the name is being stripped somewhere. This is often a webhook bug or API issue.

**Debug the actual request:**

```bash
# Enable verbose logging to see what's actually being sent
oc delete multiclusterobservability observability -v=9 2>&1 | grep -A 5 -B 5 "Request Body"

# For YAML files, check what's actually being sent
oc apply -f your-mco.yaml -v=9 2>&1 | tee /tmp/oc-debug.log

# Look for the actual HTTP request
grep -A 20 "Request Body" /tmp/oc-debug.log
```

**Check for mutating webhooks that might strip the name:**

```bash
# List all mutating webhooks (these can modify resources before validation)
oc get mutatingwebhookconfigurations

# Check observability-related mutating webhooks
oc get mutatingwebhookconfigurations -o yaml | grep -A 30 observability
```

**Workaround: Bypass the webhook temporarily:**

Since the webhook is incorrectly validating a valid request, disable it:

```bash
# Get the webhook name
WEBHOOK_NAME=$(oc get validatingwebhookconfigurations | grep vmulticlusterobservability | awk '{print $1}')

echo "Found webhook: $WEBHOOK_NAME"

# Set failure policy to Ignore (allows operations even if webhook fails)
oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]'

# Now perform your operation
oc delete multiclusterobservability observability
# or
oc apply -f your-mco.yaml

# Verify the operation completed
oc get multiclusterobservability

# Re-enable strict validation (optional - only if you want to debug further)
# oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
#   -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Fail"}]'
```

**Alternative: Use kubectl instead of oc:**

Sometimes the oc client has issues that kubectl doesn't:

```bash
# Install kubectl if not present
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# chmod +x kubectl

# Try the operation with kubectl
kubectl delete multiclusterobservability observability
# or
kubectl apply -f your-mco.yaml
```

**Check webhook service health:**

The webhook service itself might be malfunctioning:

```bash
# Find webhook service details
WEBHOOK_SVC=$(oc get validatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].clientConfig.service.name}')
WEBHOOK_NS=$(oc get validatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].clientConfig.service.namespace}')

echo "Webhook service: $WEBHOOK_SVC in namespace: $WEBHOOK_NS"

# Check if service has endpoints
oc get endpoints $WEBHOOK_SVC -n $WEBHOOK_NS

# Check pods backing the webhook
oc get pods -n $WEBHOOK_NS -o wide

# Check webhook pod logs for errors
oc logs -n $WEBHOOK_NS -l app=multicluster-observability-operator --tail=100 | grep -i webhook
```

#### Issue 5: oc Client Bug or Version Mismatch

If commands with the name still fail:

```bash
# Check oc version
oc version

# Ensure you're using a compatible version
# Expected: Client Version: 4.12+ (matching cluster version)

# Try with explicit output to see what's being sent
oc delete multiclusterobservability observability -v=9

# Look for the actual API request URL in verbose output
# Should see: DELETE .../multiclusterobservabilities/observability
# Not: DELETE .../multiclusterobservabilities
```

#### Quick Fix: Use Full Resource Path

```bash
# Get the full resource path
oc get multiclusterobservability observability -o yaml | head -20

# Delete using the full API path
oc delete multiclusterobservability/observability

# Or even more explicit
oc delete multiclusterobservabilities.observability.open-cluster-management.io/observability
```

### Strategy 1: Patch the Resource Directly (Bypass Validation)

If the webhook is incorrectly validating, you can patch the resource directly:

```bash
# Remove finalizers if blocking deletion
oc patch multiclusterobservability <name> -p '{"metadata":{"finalizers":null}}' --type=merge

# Force delete if needed
oc delete multiclusterobservability <name> --grace-period=0 --force
```

**⚠️ Warning:** This bypasses normal cleanup. Ensure you manually clean up resources after.

### Strategy 2: Temporarily Disable Webhook Validation

```bash
# Get the webhook configuration name
WEBHOOK_NAME=$(oc get validatingwebhookconfigurations | grep observability | awk '{print $1}')

# Set failure policy to Ignore (allows operations to proceed even if webhook fails)
oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]'

# Perform your edit/delete operation
oc delete multiclusterobservability <name>
oc apply -f fixed-mco.yaml

# Restore strict validation (optional)
oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Fail"}]'
```

### Strategy 3: Fix Nested Resource Names

The webhook may be checking nested fields. Ensure all nested resources have proper names:

```yaml
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
  name: observability
spec:
  observabilityAddonSpec: {}
  storageConfig:
    metricObjectStorage:
      name: thanos-object-storage      # ← Required
      key: thanos.yaml
    writeStorage:
    - name: thanos                      # ← May be required
      key: write-storage.yaml
  advanced:
    retentionConfig:
      blockDuration: 2h
      deleteDelay: 48h
      retentionInLocal: 24h
      retentionResolutionRaw: 30d
      retentionResolution5m: 180d
      retentionResolution1h: 0d
```

### Strategy 4: Recreate Webhook Configuration

If the webhook configuration is corrupted:

```bash
# Delete the webhook (it should be recreated by the operator)
oc delete validatingwebhookconfigurations <webhook-name>

# Restart the observability operator to recreate webhooks
oc rollout restart deployment/multicluster-observability-operator -n open-cluster-management

# Wait for operator to stabilize
oc rollout status deployment/multicluster-observability-operator -n open-cluster-management

# Verify webhook was recreated
oc get validatingwebhookconfigurations | grep observability
```

### Strategy 5: Use Server-Side Apply

Server-side apply can sometimes bypass client-side validation issues:

```bash
# Apply with server-side apply
oc apply -f mco.yaml --server-side=true --force-conflicts
```

### Strategy 6: Edit via Direct API Call

Bypass the oc client validation:

```bash
# Get current resource
oc get multiclusterobservability <name> -o json > mco.json

# Edit mco.json as needed

# Apply via direct API call
curl -k -X PUT \
  -H "Authorization: Bearer $(oc whoami -t)" \
  -H "Content-Type: application/json" \
  --data @mco.json \
  "https://$(oc whoami --show-server)/apis/observability.open-cluster-management.io/v1beta2/multiclusterobservabilities/<name>"
```

## Verification

After applying any resolution:

```bash
# Verify resource state
oc get multiclusterobservability

# Check operator logs for errors
oc logs -n open-cluster-management deployment/multicluster-observability-operator --tail=50

# Verify observability components
oc get pods -n open-cluster-management-observability

# Check metrics are flowing
oc get pods -n open-cluster-management-addon-observability
```

## Prevention

1. **Always validate YAML before applying:**
   ```bash
   oc apply -f mco.yaml --dry-run=server
   ```

2. **Use the latest API version:**
   ```bash
   oc api-resources | grep multiclusterobservability
   ```

3. **Monitor webhook health:**
   ```bash
   # Add to monitoring
   oc get validatingwebhookconfigurations <webhook-name> -o jsonpath='{.webhooks[*].clientConfig.service}' | jq .
   ```

4. **Set appropriate failure policies:**
   - Development: `failurePolicy: Ignore`
   - Production: `failurePolicy: Fail` (but ensure webhook service is highly available)

## Common Mistakes

1. **Missing nested resource names**: Storage configs, alertmanager configs need names
2. **Assuming metadata.name is enough**: Webhook may validate spec-level names
3. **Not checking webhook service health**: Dead webhook services cause spurious errors
4. **Using old API versions**: Update to v1beta2 or latest
5. **Ignoring finalizers**: These can block deletion even when webhook allows it

## Related Issues

- RHACM observability operator issues
- Stale admission webhook configurations
- API version deprecations
- CRD validation schema mismatches

## Useful Commands

```bash
# Get all observability resources
oc get all -n open-cluster-management-observability

# Check ACM version
oc get csv -n open-cluster-management | grep advanced-cluster-management

# Check observability operator version
oc get csv -n open-cluster-management-observability

# Export current MCO for backup
oc get multiclusterobservability -o yaml > mco-backup-$(date +%Y%m%d-%H%M%S).yaml

# Check for stuck resources
oc api-resources --verbs=list --namespaced -o name | xargs -n 1 oc get --show-kind --ignore-not-found -n open-cluster-management-observability
```

## References

- [RHACM Observability Documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)
- [Kubernetes Admission Webhooks](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)
- [OpenShift Dynamic Admission Control](https://docs.openshift.com/container-platform/latest/architecture/admission-plug-ins.html)

---

**Investigation Framework**: Systematic webhook troubleshooting
**Resolution Time**: 15-45 minutes depending on root cause
**Impact**: Observability management operations blocked

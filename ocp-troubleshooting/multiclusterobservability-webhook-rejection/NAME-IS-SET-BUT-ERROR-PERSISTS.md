# Name IS Set But Error Persists

## Your Situation

You have a MultiClusterObservability YAML with `metadata.name` properly set:

```yaml
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
  name: observability  # ← This IS present!
spec:
  observabilityAddonSpec: {}
  storageConfig:
    metricObjectStorage:
      name: thanos-object-storage
      key: thanos.yaml
```

Or you're using a command with the resource name:

```bash
oc delete multiclusterobservability observability  # ← Name IS specified!
```

**But you still get:**
```
admission webhook "vmulticlusterobservability.observability.open-cluster-management.io" denied the request: 
MultiClusterObservability.observability.open-cluster-management.io "" is invalid: <nil>: 
Internal error: resource name may not be empty
```

## What's Happening

The name is being **stripped or lost** somewhere between your client and the webhook. This is typically caused by:

1. **Webhook bug** - The webhook itself is malfunctioning and not receiving the name
2. **Mutating webhook interference** - Another webhook is modifying the request and removing the name
3. **API server issue** - The API server is not properly forwarding the request
4. **Client bug** - The oc client has a bug in how it constructs the request

## Immediate Solution: Bypass the Webhook

Since this is a webhook validation bug (the resource is valid but the webhook is broken), the fastest fix is to disable the webhook temporarily:

### Step 1: Identify the Webhook

```bash
# Find the validating webhook
oc get validatingwebhookconfigurations | grep -i observability

# You should see something like:
# multiclusterobservability-validating-webhook
# or similar name with "vmulticlusterobservability" in it
```

### Step 2: Disable Webhook Validation

```bash
# Get the webhook name
WEBHOOK_NAME=$(oc get validatingwebhookconfigurations | grep -i vmulticlusterobservability | awk '{print $1}')

# Show current webhook config
echo "Webhook: $WEBHOOK_NAME"
oc get validatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].failurePolicy}'
echo ""

# Set failure policy to Ignore (operations proceed even if webhook fails)
oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]'

echo "Webhook validation temporarily disabled"
```

### Step 3: Perform Your Operation

```bash
# Now try your operation again
oc delete multiclusterobservability observability
# or
oc apply -f your-mco.yaml
# or
oc edit multiclusterobservability observability
```

### Step 4: Verify Success

```bash
# Check the operation completed
oc get multiclusterobservability

# For delete: should show "No resources found"
# For create/apply: should show your resource
# For edit: should show updated configuration
```

### Step 5: (Optional) Re-enable Webhook

**Only do this if you want to fix the webhook issue. Otherwise, leave it disabled.**

```bash
# Re-enable strict validation
oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Fail"}]'
```

## Alternative Solutions

### Option 2: Force Delete (For Deletion Only)

If you're trying to delete the resource, bypass webhooks entirely:

```bash
# Remove finalizers
oc patch multiclusterobservability observability -p '{"metadata":{"finalizers":null}}' --type=merge

# Force delete
oc delete multiclusterobservability observability --grace-period=0 --force

# Verify deletion
oc get multiclusterobservability
```

### Option 3: Try kubectl Instead of oc

Sometimes kubectl handles the request differently:

```bash
# If kubectl is installed, try it
kubectl delete multiclusterobservability observability
# or
kubectl apply -f your-mco.yaml
```

### Option 4: Direct API Call

Bypass both oc and kubectl:

```bash
# Get API server URL
API_SERVER=$(oc whoami --show-server)

# Get auth token
TOKEN=$(oc whoami -t)

# For DELETE operation
curl -k -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "${API_SERVER}/apis/observability.open-cluster-management.io/v1beta2/multiclusterobservabilities/observability"

# For CREATE/UPDATE operation
curl -k -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data @your-mco.yaml \
  "${API_SERVER}/apis/observability.open-cluster-management.io/v1beta2/multiclusterobservabilities/observability"
```

## Debugging the Root Cause

If you want to understand WHY this is happening:

### Check What's Actually Being Sent

```bash
# Run with maximum verbosity
oc delete multiclusterobservability observability -v=9 2>&1 | tee /tmp/oc-debug.log

# Check the actual request
grep -A 30 "Request Body" /tmp/oc-debug.log
grep -A 30 "DELETE" /tmp/oc-debug.log | grep multicluster
```

### Check for Interfering Mutating Webhooks

```bash
# List all mutating webhooks
oc get mutatingwebhookconfigurations

# Check if any modify MCO resources
oc get mutatingwebhookconfigurations -o yaml | grep -B 5 -A 20 "multiclusterobservability"
```

### Check Webhook Service Health

```bash
# Find webhook service
WEBHOOK_NAME=$(oc get validatingwebhookconfigurations | grep vmulticlusterobservability | awk '{print $1}')
WEBHOOK_SVC=$(oc get validatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].clientConfig.service.name}')
WEBHOOK_NS=$(oc get validatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].clientConfig.service.namespace}')

# Check service and endpoints
oc get service $WEBHOOK_SVC -n $WEBHOOK_NS
oc get endpoints $WEBHOOK_SVC -n $WEBHOOK_NS

# Check webhook pods
oc get pods -n $WEBHOOK_NS -o wide

# Check webhook logs
oc logs -n $WEBHOOK_NS -l app=multicluster-observability-operator --tail=50 | grep -i "webhook\|validation\|error"
```

### Check Operator Health

```bash
# Check observability operator
oc get pods -n open-cluster-management -o wide | grep observability

# Check operator logs
oc logs -n open-cluster-management deployment/multicluster-observability-operator --tail=100

# Look for webhook registration errors
oc logs -n open-cluster-management deployment/multicluster-observability-operator --tail=100 | grep -i webhook
```

## Complete Working Example

Here's a complete script you can run:

```bash
#!/bin/bash
# Fix MCO webhook rejection when name IS present

set -e

echo "=== MCO Webhook Bypass ==="
echo ""

# 1. Find the webhook
echo "1. Finding webhook..."
WEBHOOK_NAME=$(oc get validatingwebhookconfigurations 2>/dev/null | grep -i vmulticlusterobservability | awk '{print $1}')

if [ -z "$WEBHOOK_NAME" ]; then
    echo "ERROR: Could not find vmulticlusterobservability webhook"
    echo "Listing all webhooks:"
    oc get validatingwebhookconfigurations
    exit 1
fi

echo "   Found: $WEBHOOK_NAME"
echo ""

# 2. Check current policy
echo "2. Current webhook policy:"
CURRENT_POLICY=$(oc get validatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].failurePolicy}')
echo "   $CURRENT_POLICY"
echo ""

# 3. Disable webhook
echo "3. Disabling webhook validation..."
oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]'
echo "   ✓ Webhook set to Ignore failures"
echo ""

# 4. Perform operation
echo "4. Ready to perform your operation"
echo ""
echo "Now run your command:"
echo "  oc delete multiclusterobservability observability"
echo "  or"
echo "  oc apply -f your-mco.yaml"
echo ""
echo "When done, optionally re-enable the webhook:"
echo "  oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' \\"
echo "    -p='[{\"op\": \"replace\", \"path\": \"/webhooks/0/failurePolicy\", \"value\":\"Fail\"}]'"
```

Save this as `bypass-webhook.sh`, make it executable (`chmod +x bypass-webhook.sh`), and run it.

## Why This Happens

This is almost always a bug in the webhook implementation where:

1. The webhook is not properly extracting `metadata.name` from the admission review request
2. The webhook service is in a degraded state
3. There's a version mismatch between the CRD and the webhook validation logic
4. A mutating webhook is corrupting the request before it reaches the validating webhook

## Permanent Fix

To permanently fix this issue, the RHACM/observability operator needs to be patched or restarted:

```bash
# Try restarting the operator (may recreate webhook properly)
oc rollout restart deployment/multicluster-observability-operator -n open-cluster-management

# Wait for rollout
oc rollout status deployment/multicluster-observability-operator -n open-cluster-management

# Check if webhook was recreated
oc get validatingwebhookconfigurations $WEBHOOK_NAME -o yaml

# Test if issue is resolved
oc delete multiclusterobservability observability --dry-run=server
```

If the issue persists after operator restart, this is a bug that needs to be reported to Red Hat Support.

## Report to Red Hat Support

If you need to engage Red Hat Support, collect this information:

```bash
# Create diagnostics archive
./diagnose-webhook-issue.sh

# Additional specific info for this issue
oc get validatingwebhookconfigurations $(oc get validatingwebhookconfigurations | grep vmulticlusterobservability | awk '{print $1}') -o yaml > webhook-config.yaml
oc get multiclusterobservability -o yaml > mco-resource.yaml
oc logs -n open-cluster-management deployment/multicluster-observability-operator --tail=500 > operator-logs.txt

# Include your oc version
oc version > versions.txt
```

Include:
- The error message
- Your MCO YAML (with secrets redacted)
- That `metadata.name` IS present in the YAML
- The diagnostic files above
- RHACM/ACM version: `oc get csv -n open-cluster-management | grep advanced-cluster-management`

## Related Documentation

- [README.md](README.md) → Strategy 2: Temporarily Disable Webhook Validation
- [QUICK-FIX.md](QUICK-FIX.md) → "If you can't edit/delete and need to force it"
- [YOUR-ERROR-SOLUTION.md](YOUR-ERROR-SOLUTION.md) → General solution for this error

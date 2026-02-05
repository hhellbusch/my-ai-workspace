# Quick Fix Guide: MCO Webhook Rejection

## TL;DR - I Just Need This Fixed Now

### ⚠️ MOST COMMON: "resource name may not be empty"

**If you see this exact error:**
```
admission webhook "vmulticlusterobservability.observability.open-cluster-management.io" denied the request: 
MultiClusterObservability.observability.open-cluster-management.io "" is invalid: <nil>: 
Internal error: resource name may not be empty
```

#### First: Check if Name is Actually Missing

**Most common cause:** You're missing the resource name in your command!

```bash
# ❌ WRONG
oc delete multiclusterobservability
oc edit multiclusterobservability

# ✅ CORRECT - Get the name first
oc get multiclusterobservability
# Output: NAME            AGE
#         observability   45d

# Then use it
oc delete multiclusterobservability observability
oc edit multiclusterobservability observability
```

**Or your YAML is missing metadata.name:**
```yaml
# ❌ WRONG
metadata:
  namespace: open-cluster-management-observability

# ✅ CORRECT  
metadata:
  name: observability  # ← This is required!
  namespace: open-cluster-management-observability
```

#### If Name IS Set But Still Getting Error

**👉 If your name IS present but you still get this error, this is a webhook bug.**

**Quick fix:** Disable the webhook temporarily:

```bash
# Get webhook name
WEBHOOK_NAME=$(oc get validatingwebhookconfigurations | grep vmulticlusterobservability | awk '{print $1}')

# Disable validation
oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]'

# Now run your command
oc delete multiclusterobservability observability
# or
oc apply -f your-mco.yaml
```

**👉 For detailed explanation, see [NAME-IS-SET-BUT-ERROR-PERSISTS.md](NAME-IS-SET-BUT-ERROR-PERSISTS.md)**

---

### If you can't edit/delete and need to force it:

```bash
# Get the resource name
MCO_NAME=$(oc get multiclusterobservability -o jsonpath='{.items[0].metadata.name}')

# Option 1: Remove finalizers and force delete
oc patch multiclusterobservability $MCO_NAME -p '{"metadata":{"finalizers":null}}' --type=merge
oc delete multiclusterobservability $MCO_NAME --grace-period=0 --force

# Option 2: Temporarily disable webhook validation
WEBHOOK_NAME=$(oc get validatingwebhookconfigurations | grep observability | awk '{print $1}')
oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]'

# Now try your operation again
oc delete multiclusterobservability $MCO_NAME
```

### If you're trying to create/update:

**The webhook is probably complaining about a nested field missing a name.**

Check these sections in your YAML and ensure they have `name:` fields:

```yaml
spec:
  storageConfig:
    metricObjectStorage:
      name: thanos-object-storage  # ← ADD THIS if missing
      key: thanos.yaml
    writeStorage:
      - name: thanos-write         # ← ADD THIS if using writeStorage
        key: write-storage.yaml
  alertmanagerConfig:
    name: alertmanager-config      # ← ADD THIS if using alertmanagerConfig
```

See `example-mco.yaml` for complete working examples.

## Still Having Issues?

1. **Run the diagnostic script:**
   ```bash
   chmod +x diagnose-webhook-issue.sh
   ./diagnose-webhook-issue.sh
   ```

2. **Check the output:**
   ```bash
   # Review summary
   cat mco-webhook-diagnostics-*/SUMMARY.txt
   
   # Check webhook config
   cat mco-webhook-diagnostics-*/webhook-config-details.yaml
   
   # Check operator logs
   cat mco-webhook-diagnostics-*/observability-operator-logs.txt
   ```

3. **Read the full guide:** See `README.md` for detailed troubleshooting

## Common Error Messages and Fixes

### "resource name may not be empty"
**Full error:** `MultiClusterObservability.observability.open-cluster-management.io "" is invalid: <nil>: Internal error: resource name may not be empty`

**Most likely causes:**
1. You forgot to specify the resource name in your command
2. Your YAML is missing `metadata.name`

**Immediate fix:**
```bash
# Check what exists
oc get multiclusterobservability

# Use the name (usually "observability")
oc delete multiclusterobservability observability
oc edit multiclusterobservability observability
oc patch multiclusterobservability observability -p '{"spec":{"enabled":false}}'
```

**For YAML files:**
```bash
# Check if name exists
grep -A 2 "^metadata:" your-mco.yaml

# Should show metadata.name - if not, add it
```

See **README.md → Strategy 0** for complete details.

### "name cannot be nil"
**Fix:** Add `name:` field to the nested resource the webhook is validating
- Check `storageConfig.metricObjectStorage.name`
- Check `writeStorage[].name`
- Check `alertmanagerConfig.name`

### "admission webhook denied the request"
**Fix:** Check webhook service is running
```bash
# Find webhook service
WEBHOOK_NAME=$(oc get validatingwebhookconfigurations | grep observability | awk '{print $1}')
WEBHOOK_SVC=$(oc get validatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].clientConfig.service.name}')
WEBHOOK_NS=$(oc get validatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].clientConfig.service.namespace}')

# Check service and endpoints
oc get service $WEBHOOK_SVC -n $WEBHOOK_NS
oc get endpoints $WEBHOOK_SVC -n $WEBHOOK_NS

# If no endpoints, restart operator
oc rollout restart deployment/multicluster-observability-operator -n open-cluster-management
```

### "could not find the requested resource"
**Fix:** CRD may be missing or incorrect API version
```bash
# Check CRD exists
oc get crd multiclusterobservabilities.observability.open-cluster-management.io

# Check API version in your YAML matches:
oc api-resources | grep multiclusterobservability
```

## Nuclear Option: Complete Reset

**⚠️ WARNING: This will delete all observability data and configuration**

```bash
# 1. Force delete the MCO resource
oc patch multiclusterobservability observability -p '{"metadata":{"finalizers":null}}' --type=merge
oc delete multiclusterobservability observability --force --grace-period=0

# 2. Clean up the namespace (optional - only if recreating from scratch)
oc delete namespace open-cluster-management-observability --force --grace-period=0

# 3. Delete webhook configurations
oc delete validatingwebhookconfigurations $(oc get validatingwebhookconfigurations | grep observability | awk '{print $1}')
oc delete mutatingwebhookconfigurations $(oc get mutatingwebhookconfigurations | grep observability | awk '{print $1}')

# 4. Restart the observability operator
oc rollout restart deployment/multicluster-observability-operator -n open-cluster-management

# 5. Wait for operator to stabilize
sleep 30
oc get pods -n open-cluster-management

# 6. Recreate the MCO resource
oc apply -f example-mco.yaml
```

## Prevention Checklist

Before applying MultiClusterObservability:

- [ ] `metadata.name` is set
- [ ] `storageConfig.metricObjectStorage.name` is set
- [ ] `storageConfig.metricObjectStorage.key` is set
- [ ] Secret referenced by `metricObjectStorage.name` exists
- [ ] If using `writeStorage`, each entry has a `name`
- [ ] If using `alertmanagerConfig`, it has a `name`
- [ ] Validate with: `oc apply -f mco.yaml --dry-run=server`

## Get Help

If you're still stuck:
1. Run `diagnose-webhook-issue.sh` and share the archive
2. Include the error message you're seeing
3. Include your MCO YAML (sanitize secrets)
4. Check operator logs: `oc logs -n open-cluster-management deployment/multicluster-observability-operator --tail=100`

# ⚡ START HERE

## You're Getting This Error:

```
admission webhook "vmulticlusterobservability.observability.open-cluster-management.io" denied the request: 
MultiClusterObservability.observability.open-cluster-management.io "" is invalid: <nil>: 
Internal error: resource name may not be empty
```

## Quick Decision Tree

### Is `metadata.name` present in your YAML/command?

```bash
# Check your YAML
grep -A 3 "^metadata:" your-mco.yaml

# Or check your command has the resource name
# ✅ Good: oc delete multiclusterobservability observability
# ❌ Bad:  oc delete multiclusterobservability
```

---

### ✅ YES - Name IS Present

**This is a webhook bug. The name is being lost in the request.**

#### Immediate Fix (30 seconds):

```bash
cd ocp-troubleshooting/multiclusterobservability-webhook-rejection
./bypass-webhook.sh
```

Or manually:

```bash
# Disable webhook validation
WEBHOOK=$(oc get validatingwebhookconfigurations | grep vmulticlusterobservability | awk '{print $1}')
oc patch validatingwebhookconfigurations $WEBHOOK --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]'

# Now run your command
oc delete multiclusterobservability observability
# or
oc apply -f your-mco.yaml
```

**Read more:** [NAME-IS-SET-BUT-ERROR-PERSISTS.md](NAME-IS-SET-BUT-ERROR-PERSISTS.md)

---

### ❌ NO - Name IS Missing

**Add the name to your YAML or command.**

#### For Commands:

```bash
# ❌ Wrong
oc delete multiclusterobservability

# ✅ Correct - add resource name
oc get multiclusterobservability              # Get the name
oc delete multiclusterobservability observability
```

#### For YAML:

```yaml
# ❌ Wrong
metadata:
  namespace: open-cluster-management-observability

# ✅ Correct - add name field
metadata:
  name: observability  # ← Add this!
  namespace: open-cluster-management-observability
```

**Read more:** [YOUR-ERROR-SOLUTION.md](YOUR-ERROR-SOLUTION.md)

---

### 🤷 NOT SURE - Let Script Check

```bash
cd ocp-troubleshooting/multiclusterobservability-webhook-rejection
./check-mco-name.sh
```

This will tell you exactly what's wrong and how to fix it.

---

## All Resources in This Directory

| File | Purpose | When to Use |
|------|---------|-------------|
| **[README-FIRST.md](README-FIRST.md)** | This file - quick decision tree | Start here! |
| **[bypass-webhook.sh](bypass-webhook.sh)** | Interactive script to bypass webhook | Name IS set but error persists |
| **[check-mco-name.sh](check-mco-name.sh)** | Diagnostic for missing names | Not sure what's wrong |
| **[NAME-IS-SET-BUT-ERROR-PERSISTS.md](NAME-IS-SET-BUT-ERROR-PERSISTS.md)** | Detailed guide for webhook bug | Name IS set but error persists |
| **[YOUR-ERROR-SOLUTION.md](YOUR-ERROR-SOLUTION.md)** | Solution for this specific error | General troubleshooting |
| **[QUICK-FIX.md](QUICK-FIX.md)** | Fast fixes for all scenarios | Need quick commands |
| **[README.md](README.md)** | Complete troubleshooting guide | Want full understanding |
| **[INDEX.md](INDEX.md)** | Navigation guide | Need to find something |
| **[example-mco.yaml](example-mco.yaml)** | Working YAML examples | Creating new MCO |
| **[diagnose-webhook-issue.sh](diagnose-webhook-issue.sh)** | Full diagnostic collection | Debugging or support ticket |

---

## Quick Command Reference

```bash
# Check what MCO resources exist
oc get multiclusterobservability

# Delete with correct name
oc delete multiclusterobservability observability

# Edit with correct name
oc edit multiclusterobservability observability

# Apply YAML (ensure metadata.name is present)
oc apply -f mco.yaml

# Bypass webhook (if name IS present but still fails)
./bypass-webhook.sh

# Diagnose the issue
./check-mco-name.sh
```

---

## Still Stuck?

1. Run `./check-mco-name.sh` - automated diagnosis
2. Read [QUICK-FIX.md](QUICK-FIX.md) - all scenarios covered
3. Run `./diagnose-webhook-issue.sh` - collect full diagnostics
4. Check [README.md](README.md) - comprehensive guide

---

**Pro tip:** If you're 100% certain your name is set correctly, just run `./bypass-webhook.sh` and move on. This is almost always a webhook bug.

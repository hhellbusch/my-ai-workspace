# MultiClusterObservability Webhook Rejection Troubleshooting

This directory contains comprehensive resources for diagnosing and resolving RHACM MultiClusterObservability admission webhook rejection issues.

## Files in This Directory

### Quick Start
- **[YOUR-ERROR-SOLUTION.md](YOUR-ERROR-SOLUTION.md)** ⚡ - Solution for "resource name may not be empty" error
  - Specifically addresses the most common error
  - Step-by-step fix with examples
  - Immediate actions and verification

- **[NAME-IS-SET-BUT-ERROR-PERSISTS.md](NAME-IS-SET-BUT-ERROR-PERSISTS.md)** 🔧 - When name IS present but error still occurs
  - For when metadata.name IS set but webhook still rejects
  - Webhook bug workarounds
  - Bypass validation temporarily
  - Debug root cause
  
- **[QUICK-FIX.md](QUICK-FIX.md)** - Fast solutions for common scenarios
  - TL;DR fixes for immediate problems
  - Common error messages and their solutions
  - Nuclear option for complete reset
  - Prevention checklist

### Detailed Documentation
- **[README.md](README.md)** - Complete troubleshooting guide
  - Symptom identification
  - Root cause analysis
  - Investigation workflow
  - Six different resolution strategies
  - Verification steps
  - Prevention recommendations

### Tools & Examples
- **[bypass-webhook.sh](bypass-webhook.sh)** ⚡ - Interactive script to bypass broken webhook
  - **Use this if name IS set but error persists**
  - Automatically finds and disables the webhook
  - Optionally runs your command for you
  - Safe and reversible

- **[check-mco-name.sh](check-mco-name.sh)** - Quick diagnostic for "resource name may not be empty" error
  - Checks if MCO resources exist
  - Validates YAML files for missing names
  - Shows correct command syntax
  - Tests with dry-run validation
  
- **[diagnose-webhook-issue.sh](diagnose-webhook-issue.sh)** - Comprehensive diagnostic script
  - Collects all relevant information
  - Checks webhooks, CRDs, operators
  - Generates summary report
  - Creates archive for sharing
  
- **[example-mco.yaml](example-mco.yaml)** - Working configuration examples
  - Minimal valid configuration
  - Full configuration with all options
  - AlertManager integration
  - Proper naming conventions

## Usage Paths

### Path 1: My Name IS Set But I Still Get The Error ⚡
**This is your situation if `metadata.name` is present but webhook still rejects**

1. Run `./bypass-webhook.sh` - Interactive fix
2. Or read [NAME-IS-SET-BUT-ERROR-PERSISTS.md](NAME-IS-SET-BUT-ERROR-PERSISTS.md)
3. Done!

### Path 2: I'm Not Sure If Name Is Missing
1. Run `./check-mco-name.sh` for quick validation
2. Follow the recommendations it provides
3. If name IS set but error persists, go to Path 1

### Path 3: I Need This Fixed Right Now (Any Scenario)
1. Go to [QUICK-FIX.md](QUICK-FIX.md)
2. Find your error message
3. Copy-paste the fix
4. Done

### Path 4: I Want to Understand the Problem
1. Run `./check-mco-name.sh` for quick validation
2. If issue persists, run `./diagnose-webhook-issue.sh` for full diagnostics
3. Review the summary output
4. Read [README.md](README.md) for context
5. Apply appropriate resolution strategy

### Path 5: I'm Creating New MCO Resources
1. Check [example-mco.yaml](example-mco.yaml)
2. Copy the appropriate template
3. Follow the prevention checklist in [QUICK-FIX.md](QUICK-FIX.md)
4. Validate before applying

## Common Scenarios

### Scenario 0: "resource name may not be empty" Error ⚡ MOST COMMON
**Problem:** Error message: `MultiClusterObservability.observability.open-cluster-management.io "" is invalid: <nil>: Internal error: resource name may not be empty`

**Quick diagnosis:**
```bash
# Run the diagnostic script
./check-mco-name.sh
```

**Most likely cause:** You forgot to include the resource name in your command

**Quick Fix:**
```bash
# ❌ WRONG
oc delete multiclusterobservability

# ✅ CORRECT - Get name first, then use it
oc get multiclusterobservability
oc delete multiclusterobservability observability
```

**Reference:** README.md → Strategy 0: Fix Command Syntax

### Scenario 1: Can't Delete MCO Resource
**Problem:** Webhook rejects deletion with "name cannot be nil"

**Quick Fix:**
```bash
MCO_NAME=$(oc get multiclusterobservability -o jsonpath='{.items[0].metadata.name}')
oc patch multiclusterobservability $MCO_NAME -p '{"metadata":{"finalizers":null}}' --type=merge
oc delete multiclusterobservability $MCO_NAME --grace-period=0 --force
```

**Reference:** QUICK-FIX.md → "If you can't edit/delete"

### Scenario 2: Can't Edit MCO Resource
**Problem:** Webhook rejects updates even though YAML looks correct

**Quick Fix:**
```bash
# Temporarily disable webhook
WEBHOOK_NAME=$(oc get validatingwebhookconfigurations | grep observability | awk '{print $1}')
oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]'

# Apply your changes
oc apply -f your-mco.yaml

# Re-enable webhook
oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Fail"}]'
```

**Reference:** README.md → Strategy 2: Temporarily Disable Webhook Validation

### Scenario 3: Creating New MCO - Webhook Rejects
**Problem:** New MCO resource rejected with validation error

**Quick Fix:**
1. Check nested resources have `name` fields:
   - `storageConfig.metricObjectStorage.name`
   - `writeStorage[].name` (if used)
   - `alertmanagerConfig.name` (if used)

2. Use example from `example-mco.yaml`

3. Validate before applying:
   ```bash
   oc apply -f mco.yaml --dry-run=server
   ```

**Reference:** example-mco.yaml → Minimal valid configuration

### Scenario 4: Webhook Service Not Responding
**Problem:** Webhook times out or connection refused

**Quick Fix:**
```bash
# Find webhook service
WEBHOOK_NAME=$(oc get validatingwebhookconfigurations | grep observability | awk '{print $1}')
WEBHOOK_SVC=$(oc get validatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].clientConfig.service.name}')
WEBHOOK_NS=$(oc get validatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].clientConfig.service.namespace}')

# Check and restart if needed
oc get endpoints $WEBHOOK_SVC -n $WEBHOOK_NS
oc rollout restart deployment/multicluster-observability-operator -n open-cluster-management
```

**Reference:** README.md → Strategy 4: Recreate Webhook Configuration

## Diagnostic Script Output

When you run `diagnose-webhook-issue.sh`, it creates a directory with:

```
mco-webhook-diagnostics-<timestamp>/
├── SUMMARY.txt                           # Quick overview and recommendations
├── mco-resources.yaml                    # Current MCO resources
├── mco-describe.txt                      # Detailed MCO description
├── mco-finalizers.txt                    # Finalizers blocking deletion
├── validating-webhooks-list.txt          # All validating webhooks
├── webhook-config-details.yaml           # Specific webhook configuration
├── mco-crd.yaml                          # CRD definition
├── mco-crd-schema.json                   # Validation schema
├── observability-pods.txt                # Pod status
├── observability-operator-logs.txt       # Operator logs
├── webhook-service.yaml                  # Webhook service config
├── webhook-endpoints.yaml                # Service endpoints
└── ... (additional diagnostic files)
```

Start with `SUMMARY.txt` for quick analysis.

## Resolution Strategy Decision Tree

```
Can't perform operation on MCO?
│
├─ Error says "resource name may not be empty" with "" in message?
│  │
│  ├─ YES → You're missing resource name in command OR YAML
│  │        Run: ./check-mco-name.sh
│  │        See: README.md → Strategy 0
│  │        See: QUICK-FIX.md → Top section
│  │
│  └─ NO  → Continue below
│
├─ Error mentions "name" or "nil" (but not the above)?
│  │
│  ├─ YES → Check nested resource names
│  │        See: QUICK-FIX.md → "name cannot be nil"
│  │        Use: example-mco.yaml for proper structure
│  │
│  └─ NO  → Continue below
│
├─ Webhook connection/timeout error?
│  │
│  ├─ YES → Check webhook service
│  │        See: README.md → Strategy 4
│  │
│  └─ NO  → Continue below
│
├─ Need to force delete/bypass validation?
│  │
│  ├─ YES → Remove finalizers or disable webhook
│  │        See: QUICK-FIX.md → "If you can't edit/delete"
│  │        See: README.md → Strategy 1 or 2
│  │
│  └─ NO  → Continue below
│
├─ Creating new resource and getting validation error?
│  │
│  └─ YES → Use example YAML and validation
│           See: example-mco.yaml
│           Run: oc apply --dry-run=server
│
└─ Not sure?
   │
   └─ Run: ./diagnose-webhook-issue.sh
      Review: output/SUMMARY.txt
      Read: README.md for detailed analysis
```

## Additional Resources

### In This Workspace
- **RHACM Examples:** `/rhacm-examples/` - Other RHACM configuration examples
- **OCP Troubleshooting:** `/ocp-troubleshooting/` - Other OpenShift issues

### External Documentation
- [RHACM Observability Documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)
- [Kubernetes Admission Webhooks](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)

## Contributing

Found a new issue or solution? Add it to this troubleshooting guide following the existing pattern:
1. Document symptoms clearly
2. Provide investigation workflow
3. Include resolution steps
4. Add verification procedures

---

**Quick Links:**
- ⚡ **Name IS set but error persists:** `./bypass-webhook.sh` or [NAME-IS-SET-BUT-ERROR-PERSISTS.md](NAME-IS-SET-BUT-ERROR-PERSISTS.md)
- ⚡ **Not sure if name is set:** `./check-mco-name.sh`
- **Quick fixes:** [QUICK-FIX.md](QUICK-FIX.md)
- **Detailed guide:** [README.md](README.md)
- **Examples:** [example-mco.yaml](example-mco.yaml)
- **Full diagnostics:** `./diagnose-webhook-issue.sh`

# Quick Reference: Namespace Stuck in Terminating

## Quick Diagnosis

```bash
# Check namespace status
oc get namespace <namespace-name>

# View namespace details and conditions
oc describe namespace <namespace-name>

# Check namespace finalizers
oc get namespace <namespace-name> -o json | jq '.spec.finalizers, .metadata.finalizers'
```

## Quick Fix - Individual Resource

```bash
# Find resources with finalizers
oc api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 oc get --show-kind --ignore-not-found -n <namespace-name> -o json | \
  jq -r 'select(.items != null) | .items[] | select(.metadata.finalizers != null) | "\(.kind)/\(.metadata.name)"'

# Remove finalizer from specific resource (RECOMMENDED)
oc patch <resource-type> <resource-name> -n <namespace-name> \
  -p '{"metadata":{"finalizers":[]}}' --type=merge
```

## Quick Fix - Namespace Level

```bash
# Remove spec finalizers
oc patch namespace <namespace-name> -p '{"spec":{"finalizers":[]}}' --type=merge

# Remove metadata finalizers
oc patch namespace <namespace-name> -p '{"metadata":{"finalizers":[]}}' --type=merge
```

## Common Scenarios

### OpenTelemetry Collector

```bash
# Find and fix
oc get opentelemetrycollector -n <namespace-name> -o name | \
  xargs -I {} oc patch {} -n <namespace-name> -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### RHACM Managed Cluster

```bash
# Find and fix
oc get managedcluster -n <namespace-name> -o name | \
  xargs -I {} oc patch {} -n <namespace-name> -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### Persistent Volume Claims

```bash
# Find and fix
oc get pvc -n <namespace-name> -o name | \
  xargs -I {} oc patch {} -n <namespace-name> -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### All Resources (Nuclear Option)

```bash
# Remove finalizers from ALL resources in namespace
oc api-resources --verbs=list --namespaced -o name | \
  while read resource; do
    oc get $resource -n <namespace-name> -o name 2>/dev/null | \
      xargs -I {} oc patch {} -n <namespace-name> -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
  done
```

## Scripts

### Run Investigation

```bash
./investigate-namespace.sh <namespace-name>
```

### Run Automated Cleanup

```bash
# Dry run first
./cleanup-namespace-finalizers.sh <namespace-name> --dry-run

# Execute cleanup
./cleanup-namespace-finalizers.sh <namespace-name>
```

## One-Liner Complete Cleanup

```bash
NAMESPACE="<namespace-name>" && \
oc api-resources --verbs=list --namespaced -o name | \
while read r; do oc get $r -n $NAMESPACE -o name 2>/dev/null | \
xargs -I {} oc patch {} -n $NAMESPACE -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true; done && \
oc patch namespace $NAMESPACE -p '{"spec":{"finalizers":[]}}' --type=merge && \
oc patch namespace $NAMESPACE -p '{"metadata":{"finalizers":[]}}' --type=merge
```

## Verification

```bash
# Watch namespace deletion
watch oc get namespace <namespace-name>

# Check if any resources remain
oc api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 oc get --show-kind --ignore-not-found -n <namespace-name>
```

## Troubleshooting Tips

### Can't patch resources?

```bash
# Try with force flag
oc delete <resource-type> <resource-name> -n <namespace-name> --force --grace-period=0

# Use raw API
oc get <resource-type> <resource-name> -n <namespace-name> -o json > resource.json
# Edit resource.json to remove finalizers
oc replace --raw "/apis/<group>/<version>/namespaces/<namespace-name>/<resource-type>/<name>" -f resource.json
```

### Check for webhook issues

```bash
# List validating webhooks
oc get validatingwebhookconfigurations

# List mutating webhooks
oc get mutatingwebhookconfigurations

# Check webhook endpoints
oc get validatingwebhookconfigurations -o json | \
  jq -r '.items[] | .webhooks[] | "\(.name): \(.clientConfig.service // .clientConfig.url)"'
```

### Check operator status

```bash
# Check operator pods
oc get pods -n openshift-operators
oc get pods -n openshift-operator-lifecycle-manager

# Check specific operator logs
oc logs -n openshift-operators <operator-pod-name>
```

## Safety Checklist

Before removing finalizers:

- [ ] Understand what the finalizer is for
- [ ] Check if the operator/controller is running
- [ ] Review operator logs for errors
- [ ] Use the most targeted approach (resource > namespace)
- [ ] Consider if external cleanup is needed
- [ ] Have a backup/record of what you're removing

## When to Use Each Method

| Scenario | Method | Command |
|----------|--------|---------|
| One resource stuck | Patch resource | `oc patch <type> <name> -n <ns> -p '{"metadata":{"finalizers":[]}}'` |
| Multiple resources | Use script | `./cleanup-namespace-finalizers.sh <ns>` |
| Resources already gone | Patch namespace | `oc patch namespace <ns> -p '{"spec":{"finalizers":[]}}'` |
| Patching fails | Raw API | `oc replace --raw /api/v1/namespaces/<ns>/finalize` |
| Unknown state | Investigate first | `./investigate-namespace.sh <ns>` |

## Common Finalizers Reference

| Finalizer | Purpose | Safe to Remove? |
|-----------|---------|-----------------|
| `kubernetes` | Standard cleanup | Usually safe |
| `kubernetes.io/pv-protection` | PV deletion protection | Check PV state first |
| `opentelemetrycollector.opentelemetry.io/finalizer` | OTel cleanup | Safe if operator gone |
| `finalizers.managedcluster.cluster.open-cluster-management.io` | RHACM cleanup | Check cluster state |
| `operator.tekton.dev` | Tekton cleanup | Safe if operator gone |
| `foregroundDeletion` | Cascade deletion | Safe after children deleted |

## Getting Help

```bash
# View full documentation
cat README.md

# Run investigation
./investigate-namespace.sh <namespace-name>

# Check related issues
ls -la ../

# OpenShift documentation
# https://docs.openshift.com/container-platform/latest/applications/projects/working-with-projects.html
```

---

*Quick Reference - Namespace Stuck Terminating*
*Last Updated: February 2026*


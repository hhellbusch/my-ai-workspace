# Basic Secret Distribution with RHACM

Learn how to distribute secrets from the RHACM Hub cluster to managed clusters using Policies.

## Overview

This example demonstrates the fundamental pattern for distributing secrets across multiple clusters:

1. Create a Policy containing the secret definition
2. Create a Placement to select target clusters
3. Bind the Policy to the Placement
4. RHACM enforces the secret on matching clusters

## Use Cases

- Distribute CA certificates to all clusters
- Share configuration secrets across teams
- Deploy namespace-scoped secrets
- Ensure consistent secret presence across environments

## Files

- `simple-secret-policy.yaml` - Single policy with embedded secret
- `namespace-and-secret-policy.yaml` - Creates namespace + secret
- `placement-production.yaml` - Targets production clusters
- `placement-all-clusters.yaml` - Targets all managed clusters
- `placement-binding.yaml` - Binds policy to placement
- `validate.sh` - Validation script

## How It Works

### Architecture

```
┌──────────────────────────────────────┐
│         RHACM Hub Cluster            │
│                                      │
│  Policy (contains Secret definition) │
│         ↓                            │
│  PlacementRule (cluster selector)    │
│         ↓                            │
│  PlacementBinding (links them)       │
└────────────┬─────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
┌───▼──────┐    ┌────▼─────┐
│ Cluster1 │    │ Cluster2 │
│ Secret ✓ │    │ Secret ✓ │
└──────────┘    └──────────┘
```

### Policy Lifecycle

1. **Create**: Policy defined on Hub with `remediationAction: enforce`
2. **Evaluate**: RHACM checks managed clusters every ~10 seconds
3. **Enforce**: If secret missing/different, RHACM creates/updates it
4. **Report**: Policy shows compliance status

## Prerequisites

- RHACM Hub cluster with managed clusters connected
- Clusters labeled appropriately (e.g., `environment=production`)
- Access to create policies in a namespace

## Quick Start

### 1. Create a Policy Namespace

```bash
oc create namespace rhacm-policies
```

### 2. Apply Simple Secret Distribution

```bash
# Distribute secret to all clusters
oc apply -f simple-secret-policy.yaml
oc apply -f placement-all-clusters.yaml
oc apply -f placement-binding.yaml
```

### 3. Verify Distribution

```bash
# Check policy compliance (wait ~30 seconds)
oc get policy -n rhacm-policies

# Should show: Compliant

# Verify on a managed cluster
oc --context=<managed-cluster> get secret my-app-secret -n default
```

## Example Configurations

### Example 1: Simple Secret Distribution

Distributes a basic secret to all managed clusters:

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: simple-secret-distribution
  namespace: rhacm-policies
spec:
  remediationAction: enforce  # Auto-create/fix
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: simple-secret-config
      spec:
        remediationAction: enforce
        severity: medium
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: my-app-secret
              namespace: default
            type: Opaque
            stringData:
              username: admin
              api-endpoint: https://api.example.com
```

### Example 2: Namespace + Secret

Creates namespace if it doesn't exist, then creates secret:

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: namespace-and-secret
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-namespace
      spec:
        remediationAction: enforce
        severity: low
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Namespace
            metadata:
              name: my-app
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-secret
      spec:
        remediationAction: enforce
        severity: medium
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: app-config
              namespace: my-app
            type: Opaque
            stringData:
              database-url: postgresql://db.example.com:5432/myapp
              cache-endpoint: redis://cache.example.com:6379
```

### Example 3: Placement by Labels

Target only production clusters:

```yaml
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: production-clusters
  namespace: rhacm-policies
spec:
  clusterSelector:
    matchLabels:
      environment: production
      region: us-east
  clusterConditions:
  - type: ManagedClusterConditionAvailable
    status: "True"
```

Target by cluster names:

```yaml
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: specific-clusters
  namespace: rhacm-policies
spec:
  clusterSelector:
    matchExpressions:
    - key: name
      operator: In
      values:
      - cluster1
      - cluster2
      - cluster3
```

## Validation

### Manual Validation

```bash
# 1. Check policy status
oc get policy -n rhacm-policies
# Expected: NAME: simple-secret-distribution, STATUS: Compliant

# 2. View policy details
oc describe policy simple-secret-distribution -n rhacm-policies

# 3. Check which clusters policy applies to
oc get placementrule production-clusters -n rhacm-policies -o yaml

# 4. Verify secret on managed cluster
CLUSTER_NAME="cluster1"  # Change this
oc --context=$CLUSTER_NAME get secret my-app-secret -n default -o yaml

# 5. Decode secret values
oc --context=$CLUSTER_NAME get secret my-app-secret -n default \
  -o jsonpath='{.data.username}' | base64 -d
```

### Automated Validation Script

```bash
chmod +x validate.sh
./validate.sh
```

## Troubleshooting

### Policy Shows "NonCompliant"

```bash
# Check policy template details
oc get policy <policy-name> -n rhacm-policies -o yaml

# Look for status.details with violation messages
# Common issues:
# - Namespace doesn't exist
# - RBAC permissions issue
# - Cluster not available
```

### Secret Not Created

```bash
# Check ManifestWork (what RHACM actually applies)
CLUSTER_NAMESPACE="cluster1"  # Managed cluster namespace on Hub
oc get manifestwork -n $CLUSTER_NAMESPACE

# View ManifestWork content
oc get manifestwork -n $CLUSTER_NAMESPACE -o yaml | less

# Check cluster connection
oc get managedcluster $CLUSTER_NAMESPACE -o yaml
```

### Policy Not Applying to Expected Clusters

```bash
# Check PlacementRule decisions
oc get placementrule <placement-name> -n rhacm-policies -o yaml

# Look at status.decisions - lists matching clusters
# Verify cluster labels
oc get managedcluster --show-labels
```

### Changes Not Propagating

```bash
# Force policy reevaluation by adding annotation
oc annotate policy <policy-name> -n rhacm-policies \
  policy.open-cluster-management.io/trigger-update="$(date +%s)"

# Or delete and recreate the policy
oc delete policy <policy-name> -n rhacm-policies
oc apply -f <policy-file>.yaml
```

## Security Considerations

### ⚠️ Embedded Secrets Warning

**This example embeds secrets in Policy objects for learning purposes only.**

For production:
- **Don't store secrets in Git** - Use external secret stores
- **Use `stringData` carefully** - It's visible in policy YAML
- **Consider sealed secrets** - Encrypt before committing
- **Implement RBAC** - Limit who can view policies
- **Use External Secrets Operator** - See example 3

### Better Alternatives

1. **External Secrets Operator** - Sync from Vault/AWS SM
2. **Sealed Secrets** - Encrypt secrets in Git
3. **Policy Templates with fromSecret** - Reference existing Hub secrets

Example using Hub secret reference (RHACM 2.8+):

```yaml
object-templates:
- complianceType: musthave
  objectDefinition:
    apiVersion: v1
    kind: Secret
    metadata:
      name: app-secret
      namespace: default
    type: Opaque
    stringData:
      password: '{{hub fromSecret "vault-namespace" "master-secret" "password" hub}}'
```

## Advanced Usage

### Inform vs Enforce

```yaml
spec:
  remediationAction: inform  # Just report violations, don't fix
```

Use `inform` to:
- Test policies before enforcement
- Audit compliance without changes
- Monitor drift

### Pruning Behavior

```yaml
spec:
  pruneObjectBehavior: DeleteIfCreated  # Delete when policy removed
  # or: DeleteAll, None (default)
```

### Disable Temporarily

```yaml
spec:
  disabled: true  # Policy won't be evaluated
```

## Next Steps

- [Example 2: ManagedServiceAccounts](../2_managed_service_accounts/) - Access credentials
- [Example 3: External Secrets Operator](../3_external_secrets_operator/) - Production secret management
- [Example 4: Registry Credentials](../4_registry_credentials/) - Practical use case

## References

- [RHACM Policy Documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.11/html/governance/index)
- [Policy Collection Examples](https://github.com/stolostron/policy-collection)
- [ConfigurationPolicy Spec](https://github.com/stolostron/config-policy-controller)


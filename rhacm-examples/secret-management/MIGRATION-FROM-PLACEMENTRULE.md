# Migration Guide: PlacementRule to Placement

Quick reference for migrating from deprecated PlacementRule to modern Placement API in RHACM 2.15+.

## Side-by-Side Comparison

### OLD: PlacementRule (Deprecated)

```yaml
# PlacementRule (DO NOT USE)
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: production-clusters
  namespace: rhacm-policies
spec:
  clusterSelector:
    matchLabels:
      environment: production
  clusterConditions:
  - type: ManagedClusterConditionAvailable
    status: "True"
---
# PlacementBinding references PlacementRule
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-policy-prod
  namespace: rhacm-policies
placementRef:
  name: production-clusters
  kind: PlacementRule  # Old API
  apiGroup: apps.open-cluster-management.io  # Old API
subjects:
- name: my-policy
  kind: Policy
  apiGroup: policy.open-cluster-management.io
```

### NEW: Placement with ManagedClusterSet

```yaml
# Step 1: Create ManagedClusterSet
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSet
metadata:
  name: production
spec:
  clusterSelector:
    selectorType: LabelSelector
    labelSelector:
      matchLabels:
        environment: production
---
# Step 2: Bind ManagedClusterSet to namespace
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: production
  namespace: rhacm-policies
spec:
  clusterSet: production
---
# Step 3: Create Placement
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: production-clusters
  namespace: rhacm-policies
spec:
  clusterSets:
  - production
  tolerations:
  - key: cluster.open-cluster-management.io/unreachable
    operator: Exists
---
# Step 4: PlacementBinding references Placement
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-policy-prod
  namespace: rhacm-policies
placementRef:
  name: production-clusters
  kind: Placement  # New API
  apiGroup: cluster.open-cluster-management.io  # New API
subjects:
- name: my-policy
  kind: Policy
  apiGroup: policy.open-cluster-management.io
```

## Key Differences

| Aspect | PlacementRule | Placement |
|--------|--------------|-----------|
| **API Group** | `apps.open-cluster-management.io` | `cluster.open-cluster-management.io` |
| **API Version** | `v1` | `v1beta1` |
| **Status** | ⚠️ Deprecated in 2.6+ | ✅ Current |
| **ManagedClusterSet** | ❌ Not supported | ✅ Required |
| **Requires** | None | ManagedClusterSet + Binding |
| **Advanced Features** | ❌ Limited | ✅ Priority, spread, numberOfClusters |
| **Cluster Selection** | `clusterSelector` | `predicates` + `clusterSets` |

## Migration Steps

### Step 1: Identify PlacementRules

```bash
# Find all PlacementRules
oc get placementrule -A

# Get details for each
oc get placementrule <name> -n <namespace> -o yaml
```

### Step 2: Create ManagedClusterSets

For each logical grouping of clusters:

```bash
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSet
metadata:
  name: production
spec:
  clusterSelector:
    selectorType: LabelSelector
    labelSelector:
      matchLabels:
        environment: production
EOF
```

### Step 3: Create ManagedClusterSetBindings

Bind each ManagedClusterSet to the policy namespace:

```bash
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: production
  namespace: rhacm-policies
spec:
  clusterSet: production
EOF
```

### Step 4: Convert to Placement

Convert each PlacementRule to a Placement:

```bash
# Get old PlacementRule
OLD_NAME="production-clusters"
NAMESPACE="rhacm-policies"

# Create new Placement
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: ${OLD_NAME}
  namespace: ${NAMESPACE}
spec:
  clusterSets:
  - production
  tolerations:
  - key: cluster.open-cluster-management.io/unreachable
    operator: Exists
EOF
```

### Step 5: Update PlacementBindings

```bash
# List PlacementBindings that reference the old PlacementRule
oc get placementbinding -n rhacm-policies -o yaml | grep -A 5 "kind: PlacementRule"

# Update each PlacementBinding
# Change:
#   kind: PlacementRule → Placement
#   apiGroup: apps.open-cluster-management.io → cluster.open-cluster-management.io
```

**Example patch:**
```bash
oc patch placementbinding binding-name -n rhacm-policies --type=merge -p '
{
  "placementRef": {
    "kind": "Placement",
    "apiGroup": "cluster.open-cluster-management.io"
  }
}'
```

### Step 6: Verify

```bash
# Check PlacementDecisions
oc get placementdecision -n rhacm-policies

# Verify clusters are selected
oc get placementdecision -n rhacm-policies \
  -l cluster.open-cluster-management.io/placement=production-clusters \
  -o yaml

# Check policy compliance
oc get policy -n rhacm-policies
```

### Step 7: Clean Up

After verifying everything works:

```bash
# Delete old PlacementRules
oc delete placementrule production-clusters -n rhacm-policies
```

## Common Migration Patterns

### Pattern 1: Simple Label Selector

**Old:**
```yaml
spec:
  clusterSelector:
    matchLabels:
      environment: production
```

**New:**
```yaml
# In ManagedClusterSet
spec:
  clusterSelector:
    selectorType: LabelSelector
    labelSelector:
      matchLabels:
        environment: production
---
# In Placement
spec:
  clusterSets:
  - production
```

### Pattern 2: Multiple Labels

**Old:**
```yaml
spec:
  clusterSelector:
    matchLabels:
      environment: production
      region: us-east-1
```

**New:**
```yaml
# In ManagedClusterSet (environment only)
spec:
  clusterSelector:
    labelSelector:
      matchLabels:
        environment: production
---
# In Placement (add region filter)
spec:
  clusterSets:
  - production
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchLabels:
          region: us-east-1
```

### Pattern 3: MatchExpressions

**Old:**
```yaml
spec:
  clusterSelector:
    matchExpressions:
    - key: environment
      operator: In
      values:
      - production
      - staging
```

**New:**
```yaml
# Create two ManagedClusterSets
---
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSet
metadata:
  name: production
spec:
  clusterSelector:
    labelSelector:
      matchLabels:
        environment: production
---
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSet
metadata:
  name: staging
spec:
  clusterSelector:
    labelSelector:
      matchLabels:
        environment: staging
---
# In Placement (reference both)
spec:
  clusterSets:
  - production
  - staging
```

### Pattern 4: Exclude Clusters

**Old:**
```yaml
spec:
  clusterSelector:
    matchExpressions:
    - key: name
      operator: NotIn
      values:
      - local-cluster
```

**New:**
```yaml
# In ManagedClusterSet
spec:
  clusterSelector:
    labelSelector:
      matchExpressions:
      - key: name
        operator: NotIn
        values:
        - local-cluster
---
# In Placement
spec:
  clusterSets:
  - global  # Name of the ManagedClusterSet
```

## Automation Script

Complete migration script:

```bash
#!/bin/bash
# migrate-to-placement.sh

set -euo pipefail

NAMESPACE="rhacm-policies"

echo "Starting PlacementRule to Placement migration..."

# Get all PlacementRules
PLACEMENT_RULES=$(oc get placementrule -n $NAMESPACE -o name | sed 's|placementrule/||')

for pr in $PLACEMENT_RULES; do
    echo "Migrating PlacementRule: $pr"
    
    # Get cluster selector labels
    LABELS=$(oc get placementrule $pr -n $NAMESPACE -o jsonpath='{.spec.clusterSelector.matchLabels}')
    
    # Create ManagedClusterSet (if not exists)
    CLUSTERSET_NAME="${pr}-set"
    cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSet
metadata:
  name: ${CLUSTERSET_NAME}
spec:
  clusterSelector:
    selectorType: LabelSelector
    labelSelector:
      matchLabels: ${LABELS}
EOF
    
    # Create ManagedClusterSetBinding
    cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: ${CLUSTERSET_NAME}
  namespace: ${NAMESPACE}
spec:
  clusterSet: ${CLUSTERSET_NAME}
EOF
    
    # Create Placement
    cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: ${pr}
  namespace: ${NAMESPACE}
spec:
  clusterSets:
  - ${CLUSTERSET_NAME}
  tolerations:
  - key: cluster.open-cluster-management.io/unreachable
    operator: Exists
EOF
    
    # Update PlacementBindings
    BINDINGS=$(oc get placementbinding -n $NAMESPACE -o name | grep $pr || true)
    for binding in $BINDINGS; do
        echo "  Updating $binding"
        oc patch $binding -n $NAMESPACE --type=merge -p '
{
  "placementRef": {
    "kind": "Placement",
    "apiGroup": "cluster.open-cluster-management.io"
  }
}'
    done
    
    echo "  ✓ Migration complete for $pr"
done

echo ""
echo "Migration complete! Verify with:"
echo "  oc get placementdecision -n $NAMESPACE"
echo ""
echo "After verification, delete old PlacementRules:"
echo "  oc delete placementrule --all -n $NAMESPACE"
```

## Troubleshooting

### PlacementDecision Shows No Clusters

```bash
# Check ManagedClusterSet membership
oc get managedcluster -o custom-columns=\
NAME:.metadata.name,\
LABELS:.metadata.labels

# Verify ManagedClusterSetBinding
oc get managedclustersetbinding -n rhacm-policies

# Check Placement status
oc describe placement <name> -n rhacm-policies
```

### PlacementBinding Not Working

```bash
# Verify PlacementBinding references Placement (not PlacementRule)
oc get placementbinding <name> -n rhacm-policies -o yaml | grep -A 3 placementRef

# Should show:
#   kind: Placement
#   apiGroup: cluster.open-cluster-management.io
```

### Clusters Not Getting Policies

```bash
# Check ManifestWork
oc get manifestwork -n <cluster-namespace>

# View policy propagation
oc get policy.<policy-name> -n <cluster-namespace>
```

## References

- [RHACM Placement API](https://open-cluster-management.io/concepts/placement/)
- [ManagedClusterSet Guide](https://open-cluster-management.io/concepts/managedclusterset/)
- [RHACM 2.15+ Best Practices](../RHACM-2.15-BEST-PRACTICES.md)


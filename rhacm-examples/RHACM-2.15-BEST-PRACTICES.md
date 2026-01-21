# RHACM 2.15+ Best Practices

This document outlines best practices for Red Hat Advanced Cluster Management 2.15 and newer versions.

## 🚨 Breaking Changes from RHACM 2.5 and Earlier

### PlacementRule is DEPRECATED

**Old (Deprecated):**
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
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-policy
  namespace: rhacm-policies
placementRef:
  name: production-clusters
  kind: PlacementRule
  apiGroup: apps.open-cluster-management.io
subjects:
- name: my-policy
  kind: Policy
```

**New (RHACM 2.6+, Required in 2.15+):**
```yaml
# 1. Create ManagedClusterSet
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

# 2. Bind ManagedClusterSet to namespace
---
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: production
  namespace: rhacm-policies
spec:
  clusterSet: production

# 3. Create Placement (not PlacementRule!)
---
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

# 4. Bind Policy to Placement
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-policy
  namespace: rhacm-policies
placementRef:
  name: production-clusters
  kind: Placement  # Changed!
  apiGroup: cluster.open-cluster-management.io  # Changed!
subjects:
- name: my-policy
  kind: Policy
  apiGroup: policy.open-cluster-management.io
```

## ✅ RHACM 2.15+ Best Practices

### 1. Use ManagedClusterSets for Organization

Group clusters logically using ManagedClusterSets:

```yaml
# Environment-based
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
```

**Benefits:**
- Better RBAC granularity
- Logical cluster grouping
- Simplified policy targeting
- Multi-tenancy support

### 2. Always Bind ManagedClusterSets to Namespaces

Before using a ManagedClusterSet in a Placement, bind it to the namespace:

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: production
  namespace: rhacm-policies
spec:
  clusterSet: production
```

### 3. Use Placement Instead of PlacementRule

| Feature | PlacementRule (old) | Placement (new) |
|---------|-------------------|-----------------|
| API Group | `apps.open-cluster-management.io` | `cluster.open-cluster-management.io` |
| API Version | `v1` | `v1beta1` |
| ManagedClusterSet | ❌ Not supported | ✅ Required |
| Advanced scheduling | ❌ Basic | ✅ Priorities, spread, etc. |
| Status | ⚠️ Deprecated | ✅ Active |

### 4. Add Tolerations for Resilience

Always include tolerations in Placement objects:

```yaml
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
  - key: cluster.open-cluster-management.io/unavailable
    operator: Exists
```

This prevents policies from being removed during temporary cluster issues.

### 5. Use Hub Secret References (RHACM 2.8+)

Store secrets centrally on the Hub:

```yaml
# On Hub cluster
oc create secret generic db-credentials \
  -n rhacm-secrets \
  --from-literal=password=secret123

# In policy
stringData:
  password: '{{hub fromSecret "rhacm-secrets" "db-credentials" "password" hub}}'
```

**Benefits:**
- Single source of truth
- No secrets in Git
- Centralized rotation
- Better audit trail

### 6. Label Clusters Consistently

Use a consistent labeling strategy:

```yaml
# Environment
environment: production | staging | development

# Region
region: us-east-1 | us-west-2 | eu-central-1

# Cloud provider
cloud: aws | azure | gcp | on-prem

# Purpose
purpose: application | database | monitoring

# Compliance
compliance: pci-dss | hipaa | sox
```

### 7. Use External Secrets Operator for Production

For production workloads, use External Secrets Operator instead of direct secret distribution:

```yaml
# Install ESO via policy
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: install-eso
spec:
  # ... install ESO operator

# Configure SecretStore via policy
---
# ... configure Vault/AWS SM connection

# Create ExternalSecret via policy
---
# ... sync secrets from external store
```

**Benefits:**
- Secrets never stored in Kubernetes
- Automatic rotation
- Audit logging in external store
- Dynamic secret generation (Vault)

### 8. Use PlacementDecisions to Verify Targeting

Check which clusters are actually selected:

```bash
# View all placement decisions
oc get placementdecision -n rhacm-policies

# View specific placement
oc get placementdecision -n rhacm-policies \
  -l cluster.open-cluster-management.io/placement=production-clusters \
  -o yaml
```

### 9. Implement Progressive Rollouts

Use multiple Placements for staged deployments:

```yaml
# Stage 1: Canary (1 cluster)
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: canary
spec:
  clusterSets:
  - production
  numberOfClusters: 1
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchLabels:
          canary: "true"

# Stage 2: Production rollout (all remaining)
---
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: production-rollout
spec:
  clusterSets:
  - production
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchExpressions:
        - key: canary
          operator: DoesNotExist
```

### 10. Use Spread Policies for High Availability

Distribute workloads across regions/zones:

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: ha-placement
spec:
  clusterSets:
  - production
  numberOfClusters: 3
  spreadPolicy:
    spreadConstraints:
    - maxSkew: 1
      topologyKey: region
      whenUnsatisfiable: DoNotSchedule
```

## 📋 Migration Checklist

If migrating from older RHACM versions:

- [ ] Identify all PlacementRule resources
- [ ] Create corresponding ManagedClusterSets
- [ ] Create ManagedClusterSetBindings in policy namespaces
- [ ] Convert PlacementRules to Placements
- [ ] Update PlacementBindings to reference Placements
- [ ] Test policy distribution to clusters
- [ ] Verify PlacementDecisions show correct clusters
- [ ] Delete old PlacementRule resources
- [ ] Update documentation

## 🔄 Migration Script Example

```bash
#!/bin/bash
# Convert PlacementRule to Placement

OLD_PLACEMENT="production-clusters"
NAMESPACE="rhacm-policies"
CLUSTERSET="production"

# Create ManagedClusterSet
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSet
metadata:
  name: ${CLUSTERSET}
spec:
  clusterSelector:
    selectorType: LabelSelector
    labelSelector:
      matchLabels:
        environment: production
EOF

# Create ManagedClusterSetBinding
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: ${CLUSTERSET}
  namespace: ${NAMESPACE}
spec:
  clusterSet: ${CLUSTERSET}
EOF

# Create Placement (converting from PlacementRule)
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: ${OLD_PLACEMENT}
  namespace: ${NAMESPACE}
spec:
  clusterSets:
  - ${CLUSTERSET}
  tolerations:
  - key: cluster.open-cluster-management.io/unreachable
    operator: Exists
EOF

# Update PlacementBindings
# Note: You'll need to patch existing PlacementBindings to change:
# - kind: PlacementRule → Placement
# - apiGroup: apps.open-cluster-management.io → cluster.open-cluster-management.io

echo "Migration complete. Verify with:"
echo "  oc get placementdecision -n ${NAMESPACE}"
echo ""
echo "After verification, delete old PlacementRule:"
echo "  oc delete placementrule ${OLD_PLACEMENT} -n ${NAMESPACE}"
```

## 🔐 Security Best Practices

### 1. Enable etcd Encryption

```bash
oc patch apiserver cluster --type=merge \
  -p '{"spec":{"encryption":{"type":"aescbc"}}}'
```

### 2. Use Separate Namespace for Hub Secrets

```bash
oc create namespace rhacm-secrets
oc adm policy add-role-to-user view \
  system:serviceaccount:open-cluster-management:governance-policy-propagator \
  -n rhacm-secrets
```

### 3. Implement RBAC for ManagedClusterSets

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: managedclusterset-admin
rules:
- apiGroups:
  - cluster.open-cluster-management.io
  resources:
  - managedclustersets
  - managedclustersetbindings
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
```

### 4. Audit Policy Changes

```bash
# Enable audit logging for policy changes
oc get configmap -n openshift-kube-apiserver audit-policies
```

## 📊 Monitoring and Observability

### Key Metrics to Monitor

1. **Policy Compliance**
   ```bash
   oc get policies -A -o custom-columns=\
   NAME:.metadata.name,\
   NAMESPACE:.metadata.namespace,\
   COMPLIANT:.status.compliant
   ```

2. **Placement Decisions**
   ```bash
   oc get placementdecision -A -o yaml
   ```

3. **ManagedClusterSet Membership**
   ```bash
   oc get managedcluster -o custom-columns=\
   NAME:.metadata.name,\
   CLUSTERSET:.metadata.labels.cluster\.open-cluster-management\.io/clusterset,\
   STATUS:.status.conditions[?\(@.type==\"ManagedClusterConditionAvailable\"\)].status
   ```

## 🆘 Troubleshooting

### PlacementDecision Shows No Clusters

```bash
# Check ManagedClusterSet membership
oc get managedcluster -l environment=production

# Verify ManagedClusterSetBinding exists
oc get managedclustersetbinding -n rhacm-policies

# Check Placement status
oc get placement production-clusters -n rhacm-policies -o yaml
```

### Policy Not Applying to Clusters

```bash
# Check PlacementBinding
oc get placementbinding -n rhacm-policies

# Verify PlacementBinding references correct Placement
oc get placementbinding binding-name -n rhacm-policies -o yaml

# Check ManifestWork
oc get manifestwork -n <cluster-namespace>
```

### Hub Secret Reference Not Working

```bash
# Verify RHACM version (need 2.8+)
oc get multiclusterhub -n open-cluster-management \
  -o jsonpath='{.status.currentVersion}'

# Check secret exists on Hub
oc get secret -n rhacm-secrets

# Verify RBAC
oc auth can-i get secrets \
  --as=system:serviceaccount:open-cluster-management:governance-policy-propagator \
  -n rhacm-secrets
```

## 📚 Additional Resources

- [RHACM Documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.15)
- [Placement API Reference](https://open-cluster-management.io/concepts/placement/)
- [Policy Collection GitHub](https://github.com/stolostron/policy-collection)
- [ManagedClusterSet Guide](https://open-cluster-management.io/concepts/managedclusterset/)

## 🎯 Summary

**Key Takeaways for RHACM 2.15+:**

1. ✅ Use `Placement` (not `PlacementRule`)
2. ✅ Use `ManagedClusterSet` for cluster organization
3. ✅ Always create `ManagedClusterSetBinding` in policy namespaces
4. ✅ Use Hub secret references (`fromSecret`) instead of embedded secrets
5. ✅ Add tolerations to Placements for resilience
6. ✅ Use External Secrets Operator for production secrets
7. ✅ Implement progressive rollouts with multiple Placements
8. ✅ Monitor PlacementDecisions to verify targeting
9. ✅ Label clusters consistently
10. ✅ Enable etcd encryption and audit logging


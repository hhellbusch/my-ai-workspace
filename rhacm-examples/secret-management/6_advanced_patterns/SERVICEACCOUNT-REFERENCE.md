# RHACM ServiceAccount Reference for Hub Secrets

Quick reference guide for identifying and configuring the correct ServiceAccount for Hub secret access.

## ServiceAccount by RHACM Version

### Hub Cluster Namespace: `open-cluster-management`

**For Hub secret access** (`fromSecret` and `copySecretData`), only ServiceAccounts in this namespace on the **Hub cluster** need permissions:

| RHACM Version | Common ServiceAccount Name | Status | Notes |
|---------------|---------------------------|---------|-------|
| 2.6 - 2.8 | `governance-policy-propagator` | Legacy | Documented in RHACM 2.6-2.8 |
| 2.9 - 2.11 | `governance-policy-framework` | Current | Documented in RHACM 2.9+ |
| 2.12 - 2.15+ | `governance-policy-framework` | Current | May vary by deployment |

**Important:** The ServiceAccount name can vary between RHACM versions. Use the universal approach (grant to namespace group) to ensure compatibility.

### Managed Cluster Namespace: `open-cluster-management-agent-addon`

⚠️ **These run on MANAGED CLUSTERS and do NOT need Hub secret access:**

| Component | Location | Purpose |
|-----------|----------|---------|
| `config-policy-controller` | Managed clusters | Policy enforcement on managed clusters |
| `governance-policy-framework` | Managed clusters | Policy framework on managed clusters |

**Note:** ServiceAccount names for managed cluster components are **not documented** in Red Hat official documentation and should not be hardcoded.

## ⚠️ Important

The ServiceAccount name **varies between RHACM versions** and deployment configurations. Rather than hardcoding a specific ServiceAccount name, **use the universal approach**.

## ✅ Recommended: Universal Approach

Grant access to **all ServiceAccounts** in the `open-cluster-management` namespace on the **Hub cluster**:

```bash
# Works for ALL RHACM versions
# This is the ONLY namespace on the Hub that needs Hub secret access
oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management \
  -n rhacm-secrets
```

**Why only one namespace?**
- `fromSecret` and `copySecretData` template processing happens on the **Hub cluster**
- The policy framework ServiceAccount in `open-cluster-management` namespace does this processing
- `open-cluster-management-agent-addon` exists on **managed clusters**, not the Hub
- Managed cluster components don't need Hub secret access

### Why This Works

- ✅ Works across all RHACM versions (2.6 through 2.15+)
- ✅ No need to identify specific ServiceAccount name
- ✅ Survives RHACM upgrades without changes
- ✅ Handles configuration variations
- ✅ Only grants to Hub cluster namespace that needs it
- ✅ Still follows least privilege (scoped to namespace, read-only)

### Security Considerations

This approach:
- Grants **view** (read-only) access only
- Only to secrets in **one specific namespace** (e.g., `rhacm-secrets`)
- Only to ServiceAccounts in `open-cluster-management` namespace on **Hub cluster**
- Does NOT grant cluster-wide access
- Does NOT grant write permissions
- Does NOT grant access to managed cluster components
- Does NOT expose secrets outside RHACM Hub components

## Alternative: Specific ServiceAccount

If you need to grant to a specific ServiceAccount:

### Step 1: Identify Your ServiceAccount

```bash
# Use the verification script
./verify-serviceaccount.sh
```

Or manually:

```bash
# Check RHACM version
oc get multiclusterhub -n open-cluster-management \
  -o jsonpath='{.status.currentVersion}'

# List governance deployments in primary namespace
oc get deployment -n open-cluster-management | grep governance

# Check ServiceAccount used by deployment
oc get deployment governance-policy-propagator \
  -n open-cluster-management \
  -o jsonpath='{.spec.template.spec.serviceAccountName}'

# Check agent-addon namespace if it exists
oc get serviceaccount -n open-cluster-management-agent-addon 2>/dev/null | grep policy
```

### Step 2: Grant Access to Specific ServiceAccount

```bash
# Replace SERVICE_ACCOUNT_NAME with your actual ServiceAccount
oc adm policy add-role-to-user view \
  system:serviceaccount:open-cluster-management:SERVICE_ACCOUNT_NAME \
  -n rhacm-secrets
```

## YAML Configurations

### Universal Approach (Recommended)

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rhacm-secret-reader-primary
  namespace: rhacm-secrets
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
# Grants to all ServiceAccounts in open-cluster-management namespace
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:serviceaccounts:open-cluster-management
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rhacm-secret-reader-addon
  namespace: rhacm-secrets
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
# Grants to all ServiceAccounts in agent-addon namespace
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:serviceaccounts:open-cluster-management-agent-addon
```

### Specific ServiceAccount

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rhacm-secret-reader
  namespace: rhacm-secrets
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
# Specific ServiceAccount (verify name first!)
- kind: ServiceAccount
  name: governance-policy-framework  # Or your specific SA name
  namespace: open-cluster-management
```

## Multiple Source Namespaces

If you have Hub secrets in multiple namespaces:

```bash
# Apply to each namespace
for namespace in rhacm-secrets vault-secrets api-secrets; do
  oc adm policy add-role-to-group view \
    system:serviceaccounts:open-cluster-management \
    -n $namespace
done
```

## Verification

### Check RBAC is Configured

```bash
# List RoleBindings in the secrets namespace
oc get rolebinding -n rhacm-secrets

# Check for open-cluster-management group
oc get rolebinding -n rhacm-secrets \
  -o yaml | grep "system:serviceaccounts:open-cluster-management"
```

### Test Access

```bash
# Create test secret
oc create secret generic test-secret \
  -n rhacm-secrets \
  --from-literal=key=value

# Create test policy
cat <<EOF | oc apply -f -
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: test-hub-secret-access
  namespace: rhacm-policies
spec:
  remediationAction: inform
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: test-access
      spec:
        remediationAction: inform
        namespaceSelector:
          include:
          - default
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: test-secret
              namespace: default
            stringData:
              key: '{{hub fromSecret "rhacm-secrets" "test-secret" "key" hub}}'
EOF

# Check policy status (should be Compliant, not show RBAC errors)
oc get policy test-hub-secret-access -n rhacm-policies

# View details
oc describe policy test-hub-secret-access -n rhacm-policies
```

### Common Error Messages

**If RBAC is NOT configured correctly:**
```
Error: failed to get secret rhacm-secrets/test-secret: 
secrets "test-secret" is forbidden: 
User "system:serviceaccount:open-cluster-management:governance-policy-framework" 
cannot get resource "secrets" in API group "" in the namespace "rhacm-secrets"
```

**Solution:** Apply the universal RBAC configuration

## Automated Setup

Use the provided scripts:

### Setup RBAC Automatically

```bash
# Sets up RBAC with universal approach
./setup-hub-secret-rbac.sh rhacm-secrets
```

### Identify ServiceAccount

```bash
# Shows which ServiceAccount your RHACM uses
./verify-serviceaccount.sh
```

## Troubleshooting

### Problem: fromSecret not working

```bash
# 1. Verify RHACM version supports fromSecret (2.8+)
oc get multiclusterhub -n open-cluster-management \
  -o jsonpath='{.status.currentVersion}'

# 2. Check secret exists
oc get secret -n rhacm-secrets

# 3. Check RBAC
oc get rolebinding -n rhacm-secrets | grep open-cluster-management

# 4. If no RoleBinding, apply universal approach
oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management \
  -n rhacm-secrets
```

### Problem: copySecretData not working

Same RBAC requirements as `fromSecret`. Follow steps above.

### Problem: Access works but secret not propagating

```bash
# Check policy status
oc get policy <policy-name> -n rhacm-policies -o yaml

# Check ManifestWork
oc get manifestwork -n <cluster-namespace>

# Check on managed cluster
oc --context=<managed-cluster> get secret -n <target-namespace>
```

## Best Practices

### 1. Use Dedicated Namespace for Hub Secrets

```bash
# Create namespace
oc create namespace rhacm-secrets

# Apply RBAC
oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management \
  -n rhacm-secrets

# Organize secrets by purpose
oc create namespace vault-secrets
oc create namespace api-secrets
oc create namespace registry-secrets
```

### 2. Document ServiceAccount Dependencies

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: my-policy
  annotations:
    description: "Uses fromSecret to reference rhacm-secrets namespace"
    rbac-requirement: "Requires view access to rhacm-secrets namespace"
    setup-command: "oc adm policy add-role-to-group view system:serviceaccounts:open-cluster-management -n rhacm-secrets"
```

### 3. Verify After RHACM Upgrades

After upgrading RHACM:

```bash
# Re-verify ServiceAccount
./verify-serviceaccount.sh

# Check RBAC still works
oc get rolebinding -n rhacm-secrets

# Test a policy with fromSecret
```

### 4. Use Scripts for Consistency

```bash
# Include in your deployment automation
./setup-hub-secret-rbac.sh rhacm-secrets
./setup-hub-secret-rbac.sh vault-secrets
./setup-hub-secret-rbac.sh api-secrets
```

## Summary

**Key Takeaways:**

1. ✅ ServiceAccount name **varies by RHACM version**
2. ✅ **Only `open-cluster-management` namespace on Hub** needs Hub secret access
3. ✅ **`open-cluster-management-agent-addon` runs on managed clusters**, not Hub
4. ✅ **Use universal approach** (grant to namespace group)
5. ✅ Works across all versions and upgrades
6. ✅ Still follows principle of least privilege
7. ✅ Verified against official Red Hat documentation

## Quick Reference Commands

```bash
# Universal RBAC setup (recommended) - single namespace on Hub
oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management \
  -n rhacm-secrets

# Verify setup
oc get rolebinding -n rhacm-secrets

# Identify ServiceAccount (if needed)
./verify-serviceaccount.sh

# Automated setup
./setup-hub-secret-rbac.sh rhacm-secrets
```

## Related Documentation

- [RED-HAT-DOC-VERIFICATION.md](./RED-HAT-DOC-VERIFICATION.md) - Official documentation verification
- [RHACM 2.15+ Best Practices](../../RHACM-2.15-BEST-PRACTICES.md)
- [Hub Secret Reference Guide](./README.md)
- [copySecretData vs fromSecret](./COPYSECRETDATA-VS-FROMSECRET.md)
- [CORRECTIONS-SUMMARY.md](../../CORRECTIONS-SUMMARY.md) - What changed and why


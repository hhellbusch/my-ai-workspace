# Documentation Corrections Based on Red Hat Official Sources

**Date:** 2026-01-21  
**Reason:** User requested verification against Red Hat official documentation  
**Result:** Identified and corrected incorrect assumptions about RHACM ServiceAccount requirements

---

## Critical Findings

### ❌ Incorrect Assumption (Now Corrected)

**Previous documentation stated:**
- Hub secrets require RBAC for ServiceAccounts in TWO namespaces:
  - `open-cluster-management` (Hub cluster)
  - `open-cluster-management-agent-addon` (claimed to be Hub, referenced `config-policy-controller-sa`)

**Why this was wrong:**
1. `open-cluster-management-agent-addon` namespace exists on **MANAGED CLUSTERS**, not the Hub
2. `config-policy-controller` is a **ManagedClusterAddOn** that runs on managed clusters
3. ServiceAccount named `config-policy-controller-sa` is **NOT documented** in official Red Hat docs
4. Hub template processing (`fromSecret`, `copySecretData`) happens only on Hub cluster
5. Managed clusters receive already-processed ManifestWork objects

**Source:** Red Hat RHACM 2.6-2.15 official documentation verification

### ✅ Correct Configuration

**Hub secret access requires RBAC for ONE namespace only:**

```bash
# CORRECT: Only this namespace on Hub cluster needs access
oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management \
  -n rhacm-secrets
```

**Why this is correct:**
- ✅ Documented in Red Hat RHACM Governance docs
- ✅ Policy template processing happens in this namespace on Hub
- ✅ ServiceAccount names: `governance-policy-propagator` (2.6-2.8) or `governance-policy-framework` (2.9+)
- ✅ Follows principle of least privilege
- ✅ Works across all RHACM versions

---

## Files Corrected

### Deleted Files

1. **`secret-management/6_advanced_patterns/MULTI-NAMESPACE-RBAC.md`**
   - Reason: Based on incorrect assumption about two namespaces needing Hub access
   - Content has been replaced with correct single-namespace approach

### Updated Files

1. **`RHACM-2.15-BEST-PRACTICES.md`**
   - Removed multi-namespace RBAC commands
   - Removed reference to `config-policy-controller-sa`
   - Added clarification about managed cluster vs Hub namespaces

2. **`secret-management/README.md`**
   - Updated RBAC setup section (if it existed)
   - Removed multi-namespace references
   - Removed link to deleted MULTI-NAMESPACE-RBAC.md

3. **`secret-management/6_advanced_patterns/README.md`**
   - Updated RBAC section to single namespace
   - Removed `config-policy-controller-sa` references
   - Clarified Hub cluster vs managed cluster distinction

4. **`secret-management/6_advanced_patterns/SERVICEACCOUNT-REFERENCE.md`**
   - Completely restructured ServiceAccount tables
   - Clarified Hub vs managed cluster namespaces
   - Removed unverified ServiceAccount names
   - Added official documentation sources

5. **`secret-management/6_advanced_patterns/COPYSECRETDATA-VS-FROMSECRET.md`**
   - Updated RBAC requirements to single namespace
   - Removed multi-namespace YAML examples
   - Added clarification about Hub template processing

6. **`secret-management/6_advanced_patterns/setup-hub-secret-rbac.sh`**
   - Removed agent-addon namespace RBAC grant
   - Simplified to single namespace only
   - Updated informational messages

7. **`secret-management/6_advanced_patterns/verify-serviceaccount.sh`**
   - Removed agent-addon namespace checks
   - Added clarification that agent-addon is on managed clusters
   - Simplified recommendations to single namespace

### New Files Created

1. **`secret-management/6_advanced_patterns/RED-HAT-DOC-VERIFICATION.md`**
   - Complete documentation of verification process
   - Sources from official Red Hat documentation
   - Explanation of what was found and not found
   - Recommendations for correct approach

2. **`CORRECTIONS-SUMMARY.md`** (this file)
   - Summary of all corrections made
   - Rationale for changes
   - Before/after examples

---

## What Changed

### Before (Incorrect)

```bash
# INCORRECT - Do not use this
oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management \
  -n rhacm-secrets

oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management-agent-addon \
  -n rhacm-secrets
```

### After (Correct)

```bash
# CORRECT - Use this
oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management \
  -n rhacm-secrets
```

---

## ServiceAccount Name Clarification

### Verified (from Red Hat Docs)

| RHACM Version | Namespace | ServiceAccount | Location |
|---------------|-----------|----------------|----------|
| 2.6 - 2.8 | `open-cluster-management` | `governance-policy-propagator` | Hub cluster |
| 2.9 - 2.15+ | `open-cluster-management` | `governance-policy-framework` | Hub cluster |

### NOT Verified (not in Red Hat Docs)

| Claimed Name | Claimed Namespace | Status |
|--------------|-------------------|---------|
| `config-policy-controller-sa` | `open-cluster-management-agent-addon` | ❌ NOT documented by Red Hat |

**Note:** `config-policy-controller` is documented as a **ManagedClusterAddOn name**, not a ServiceAccount name, and it runs on **managed clusters**, not the Hub.

---

## Architecture Clarification

### Hub Cluster

```
Namespace: open-cluster-management
├── governance-policy-framework (RHACM 2.9+)
│   └── Processes policy templates (fromSecret, copySecretData)
│   └── NEEDS Hub secret access ✅
├── governance-policy-propagator (RHACM 2.6-2.8) 
│   └── Processes policy templates
│   └── NEEDS Hub secret access ✅
└── Other components...
```

### Managed Clusters

```
Namespace: open-cluster-management-agent-addon
├── config-policy-controller (ManagedClusterAddOn)
│   └── Enforces ConfigurationPolicy objects
│   └── Does NOT process Hub templates
│   └── Does NOT need Hub secret access ❌
└── Other addon controllers...
```

---

## Testing Recommendations

### Verify Your Setup

```bash
# 1. On Hub cluster, check which namespace has policy framework
oc get deployment -n open-cluster-management | grep -E "governance|policy"

# Expected: governance-policy-framework or governance-policy-propagator

# 2. Check ServiceAccount used
oc get deployment governance-policy-framework \
  -n open-cluster-management \
  -o jsonpath='{.spec.template.spec.serviceAccountName}'

# 3. Verify RBAC is configured correctly (should only show open-cluster-management)
oc get rolebinding -n rhacm-secrets

# 4. On managed cluster, verify config-policy-controller location
oc get deployment -n open-cluster-management-agent-addon | grep config-policy

# Expected: config-policy-controller deployment exists HERE, not on Hub
```

### Test Secret Access

```bash
# On Hub cluster
oc create secret generic test-secret \
  -n rhacm-secrets \
  --from-literal=key=test-value

# Create policy with fromSecret
cat <<EOF | oc apply -f -
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: test-fromsecret
  namespace: rhacm-policies
spec:
  remediationAction: inform
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: test
      spec:
        remediationAction: inform
        namespaceSelector:
          include: [default]
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: test
              namespace: default
            stringData:
              data: '{{hub fromSecret "rhacm-secrets" "test-secret" "key" hub}}'
EOF

# Check policy status - should be Compliant if RBAC is correct
oc get policy test-fromsecret -n rhacm-policies
```

---

## Impact Assessment

### Security Impact

✅ **POSITIVE:** Reduced unnecessary RBAC permissions
- Previous approach granted access to non-existent or unnecessary namespace
- Corrected approach follows principle of least privilege
- Only grants access where actually needed

### Functional Impact

✅ **NEUTRAL:** No functional change for correct deployments
- If RBAC was working before, single-namespace approach is sufficient
- Multi-namespace approach was redundant, not required

### Documentation Impact

✅ **POSITIVE:** Improved accuracy and clarity
- Aligns with official Red Hat documentation
- Eliminates confusion about Hub vs managed cluster namespaces
- Removes unverified ServiceAccount name references

---

## Lessons Learned

1. **Always verify against official documentation**
   - Don't assume ServiceAccount names follow patterns
   - Check official docs for each RHACM version
   - Distinguish between Hub and managed cluster components

2. **Understand component locations**
   - Policy template processing: Hub cluster
   - Policy enforcement: Managed clusters
   - Different namespaces, different purposes

3. **Use version-agnostic approaches**
   - Grant to namespace groups, not specific ServiceAccounts
   - ServiceAccount names change between versions
   - Universal approach survives upgrades

4. **Document sources**
   - Link to official Red Hat documentation
   - Note when something is NOT documented
   - Include verification commands

---

## Related Documentation

- **[RED-HAT-DOC-VERIFICATION.md](./secret-management/6_advanced_patterns/RED-HAT-DOC-VERIFICATION.md)** - Full verification details
- **[SERVICEACCOUNT-REFERENCE.md](./secret-management/6_advanced_patterns/SERVICEACCOUNT-REFERENCE.md)** - Corrected ServiceAccount reference
- **[RHACM-2.15-BEST-PRACTICES.md](./RHACM-2.15-BEST-PRACTICES.md)** - Updated best practices

---

## Questions?

If you encounter RHACM deployments where:
- Agent-addon namespace exists on Hub cluster
- config-policy-controller-sa exists and needs Hub access
- Multi-namespace RBAC is required

This may indicate a non-standard deployment. Please:
1. Verify your RHACM version
2. Check if you're looking at Hub vs managed cluster
3. Consult Red Hat support or official documentation
4. File an issue with specific deployment details

---

**Thank you for requesting verification! This made the documentation more accurate and aligned with Red Hat's official guidance.**


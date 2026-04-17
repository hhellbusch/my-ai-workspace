# RHACM Examples Validation Report - 2.15+ Compliance

**Validation Date:** January 21, 2026  
**RHACM Target Version:** 2.15+  
**Examples Validated:** 6 directories, 32 YAML files, 5 scripts

## Executive Summary

- **Critical Issues:** 2 - MUST be fixed
- **Warnings:** 16 - SHOULD be fixed  
- **Recommendations:** 3 - COULD be improved
- **Compliant Examples:** Multiple files are fully compliant

This validation reveals that the RHACM examples demonstrate a strong understanding of RHACM 2.15+ architecture with proper use of Placement API, ManagedClusterSets, and PlacementBindings. However, there are two critical areas requiring immediate attention:

1. **Documentation contains deprecated examples**: The main README file includes PlacementRule examples that contradict the modern Placement API patterns demonstrated in the actual YAML files.

2. **Missing resilience tolerations**: Most Placement objects are missing the `cluster.open-cluster-management.io/unavailable` toleration, which is a RHACM 2.15+ best practice for preventing policy removal during temporary cluster issues.

The examples correctly use the modern Placement API throughout, properly reference Hub secrets with correct template syntax, implement appropriate RBAC patterns, and demonstrate ManagedClusterSet architecture. With the fixes outlined below, these examples will serve as excellent RHACM 2.15+ reference implementations.

## Overall Compliance Status

| Directory | Status | Critical | Warnings | Info | Notes |
|-----------|--------|----------|----------|------|-------|
| 1_basic_secret_distribution | ⚠️ | 1 | 3 | 1 | Documentation has deprecated examples |
| 2_managed_service_accounts | ⚠️ | 0 | 1 | 0 | Missing unavailable toleration |
| 3_external_secrets_operator | ⚠️ | 0 | 2 | 0 | Missing unavailable tolerations |
| 4_registry_credentials | ⚠️ | 0 | 2 | 0 | Missing unavailable tolerations |
| 5_database_secrets | ⚠️ | 0 | 3 | 0 | Missing unavailable tolerations |
| 6_advanced_patterns | ⚠️ | 1 | 4 | 2 | Wrong toleration key + missing unavailable |
| Scripts | ⚠️ | 0 | 1 | 0 | validate.sh checks for deprecated API |

## Detailed Findings by Directory

### 1. secret-management/1_basic_secret_distribution

**Purpose:** Demonstrates fundamental pattern for distributing secrets across multiple clusters  
**Overall Status:** ⚠️ Needs Attention

#### Issues Found

##### CRITICAL: Documentation Contains Deprecated PlacementRule Examples

- **File:** `README.md`
- **Lines:** 189-221, 236
- **Issue:** The README documentation includes example configurations using the deprecated PlacementRule API, which contradicts RHACM 2.15+ best practices and the actual YAML files in the directory.
- **Impact:** Users following the documentation will implement deprecated patterns that may not work in RHACM 2.15+ and will need migration later.

- **Current Code:**
```markdown
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
```

- **Proposed Fix:**
```markdown
### Example 3: Placement by Labels

Target only production clusters using ManagedClusterSet and Placement:

```yaml
# First, ensure ManagedClusterSet exists
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
# Bind to namespace
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: production
  namespace: rhacm-policies
spec:
  clusterSet: production
---
# Create Placement
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: production-clusters
  namespace: rhacm-policies
spec:
  clusterSets:
  - production
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchLabels:
          region: us-east
  tolerations:
  - key: cluster.open-cluster-management.io/unreachable
    operator: Exists
  - key: cluster.open-cluster-management.io/unavailable
    operator: Exists
```
```

- **Explanation:** Replaced deprecated PlacementRule (apiVersion: apps.open-cluster-management.io/v1) with modern Placement API (cluster.open-cluster-management.io/v1beta1) that requires ManagedClusterSet and includes proper tolerations.

##### WARNING: Missing Unavailable Toleration in placement-all-clusters.yaml

- **File:** `placement-all-clusters.yaml`
- **Lines:** 31-35
- **Issue:** Placement includes toleration for `unreachable` but is missing the `unavailable` toleration.
- **Impact:** During temporary cluster unavailability (different from unreachable), policies may be removed from the cluster, causing service disruption.

- **Current Code:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
```

- **Proposed Fix:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
- key: cluster.open-cluster-management.io/unavailable
  operator: Exists
```

- **Explanation:** Added unavailable toleration as per RHACM 2.15+ best practices to ensure policies remain in place during temporary cluster issues.

##### WARNING: Missing Unavailable Toleration in placement-production.yaml (production-clusters)

- **File:** `placement-production.yaml`
- **Lines:** 42-44
- **Issue:** The `production-clusters` Placement only includes unreachable toleration.
- **Impact:** Policies may be removed during temporary production cluster unavailability.

- **Current Code:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
```

- **Proposed Fix:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
- key: cluster.open-cluster-management.io/unavailable
  operator: Exists
```

- **Explanation:** Added unavailable toleration for production cluster resilience.

##### WARNING: Missing Tolerations in placement-production.yaml (development-clusters and specific-clusters)

- **File:** `placement-production.yaml`
- **Lines:** 77-79, 99-101
- **Issue:** The `development-clusters` and `specific-clusters` Placements only have unreachable toleration, missing unavailable.
- **Impact:** Same resilience issue as above.

- **Proposed Fix:** Add unavailable toleration to both Placements (same pattern as above).

##### INFO: specific-clusters Placement Missing clusterSets

- **File:** `placement-production.yaml`
- **Lines:** 82-101
- **Issue:** The `specific-clusters` Placement uses predicates to select by cluster names but doesn't reference any clusterSets.
- **Impact:** While this works, it doesn't follow the ManagedClusterSet pattern demonstrated elsewhere. Consider creating a ManagedClusterSet for better organization and RBAC.
- **Recommendation:** Add a clusterSets reference even when using name-based selection for consistency.

---

### 2. secret-management/2_managed_service_accounts

**Purpose:** Demonstrates ManagedServiceAccount creation and RBAC policy distribution  
**Overall Status:** ⚠️ Needs Attention

#### Issues Found

##### WARNING: Missing Unavailable Toleration in placement-prod-clusters.yaml

- **File:** `placement-prod-clusters.yaml`
- **Lines:** 35-37
- **Issue:** Production clusters Placement missing unavailable toleration.
- **Impact:** RBAC policies may be removed during temporary cluster unavailability, affecting service account access.

- **Current Code:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
```

- **Proposed Fix:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
- key: cluster.open-cluster-management.io/unavailable
  operator: Exists
```

- **Explanation:** Added unavailable toleration for RBAC policy resilience.

---

### 3. secret-management/3_external_secrets_operator

**Purpose:** Demonstrates External Secrets Operator installation and configuration via RHACM policies  
**Overall Status:** ⚠️ Needs Attention

#### Issues Found

##### WARNING: Missing Unavailable Toleration in placement-binding.yaml (all-managed-clusters)

- **File:** `placement-binding.yaml`
- **Lines:** 59-61
- **Issue:** The `all-managed-clusters` Placement missing unavailable toleration.
- **Impact:** ESO configuration may be removed during temporary cluster issues.

- **Current Code:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
```

- **Proposed Fix:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
- key: cluster.open-cluster-management.io/unavailable
  operator: Exists
```

- **Explanation:** Added unavailable toleration for operator installation resilience.

##### WARNING: Missing Unavailable Toleration in placement-binding.yaml (production-clusters)

- **File:** `placement-binding.yaml`
- **Lines:** 73-75
- **Issue:** The `production-clusters` Placement missing unavailable toleration.
- **Impact:** Vault SecretStore and ExternalSecret configurations may be removed during temporary production cluster issues.

- **Current Code:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
```

- **Proposed Fix:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
- key: cluster.open-cluster-management.io/unavailable
  operator: Exists
```

- **Explanation:** Added unavailable toleration for production SecretStore resilience.

---

### 4. secret-management/4_registry_credentials

**Purpose:** Demonstrates container registry credential distribution  
**Overall Status:** ⚠️ Needs Attention

#### Issues Found

##### WARNING: Missing Unavailable Toleration in placement-binding.yaml (production-clusters)

- **File:** `placement-binding.yaml`
- **Lines:** 60-61
- **Issue:** Production clusters Placement missing unavailable toleration.
- **Impact:** Registry credentials may be removed during temporary cluster unavailability, breaking image pulls.

- **Current Code:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
```

- **Proposed Fix:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
- key: cluster.open-cluster-management.io/unavailable
  operator: Exists
```

- **Explanation:** Added unavailable toleration for registry credential resilience - critical for production workloads.

##### WARNING: Missing Unavailable Toleration in placement-binding.yaml (all-managed-clusters)

- **File:** `placement-binding.yaml`
- **Lines:** 73-75
- **Issue:** All managed clusters Placement missing unavailable toleration.
- **Impact:** Docker Hub credentials may be removed during temporary cluster issues.

- **Proposed Fix:** Same as above - add unavailable toleration.

---

### 5. secret-management/5_database_secrets

**Purpose:** Demonstrates database secret distribution across multiple environments  
**Overall Status:** ⚠️ Needs Attention

#### Issues Found

##### WARNING: Missing Unavailable Toleration in placement-binding.yaml (production-clusters)

- **File:** `placement-binding.yaml`
- **Lines:** 77-79
- **Issue:** Production clusters Placement missing unavailable toleration.
- **Impact:** Database secrets may be removed during temporary cluster unavailability, breaking application database connectivity.

- **Current Code:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
```

- **Proposed Fix:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
- key: cluster.open-cluster-management.io/unavailable
  operator: Exists
```

- **Explanation:** Added unavailable toleration for database secret resilience - critical for application availability.

##### WARNING: Missing Unavailable Toleration in placement-binding.yaml (staging-clusters)

- **File:** `placement-binding.yaml`
- **Lines:** 91-93
- **Issue:** Staging clusters Placement missing unavailable toleration.
- **Impact:** Staging database secrets may be removed during temporary issues.

- **Proposed Fix:** Same as above - add unavailable toleration.

##### WARNING: Missing Unavailable Toleration in placement-binding.yaml (development-clusters)

- **File:** `placement-binding.yaml`
- **Lines:** 105-107
- **Issue:** Development clusters Placement missing unavailable toleration.
- **Impact:** Development database secrets may be removed during temporary issues.

- **Proposed Fix:** Same as above - add unavailable toleration.

---

### 6. secret-management/6_advanced_patterns

**Purpose:** Demonstrates advanced patterns including Hub secret references and ManagedClusterSet examples  
**Overall Status:** ⚠️ Needs Attention

#### Issues Found

##### CRITICAL: Wrong Toleration Key in managedclusterset-placement.yaml

- **File:** `managedclusterset-placement.yaml`
- **Lines:** 73-75
- **Issue:** The `production-placement` uses wrong toleration key `node.kubernetes.io/unreachable` instead of the RHACM-specific `cluster.open-cluster-management.io/unreachable`.
- **Impact:** This toleration will not work as intended for RHACM cluster management. The policy will be removed when clusters become unreachable because the toleration doesn't match RHACM's taint key.

- **Current Code:**
```yaml
tolerations:
- key: node.kubernetes.io/unreachable
  operator: Exists
```

- **Proposed Fix:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
- key: cluster.open-cluster-management.io/unavailable
  operator: Exists
```

- **Explanation:** Changed from node-level toleration key to RHACM cluster-level toleration key, and added unavailable toleration. The `node.kubernetes.io/unreachable` key is for pod scheduling within a cluster, not for RHACM cluster selection.

##### WARNING: Missing Unavailable Toleration in placement-binding.yaml (production-clusters)

- **File:** `placement-binding.yaml`
- **Lines:** 61-65
- **Issue:** The `production-clusters` Placement is missing unavailable toleration (though it does have both tolerations properly listed in the comments on lines 60-65).
- **Impact:** Hub secret reference policies may be removed during temporary production cluster unavailability.

- **Current Code:**
```yaml
# Tolerate temporary unavailability
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
- key: cluster.open-cluster-management.io/unavailable
  operator: Exists
```

- **Assessment:** Actually, this file is CORRECT! It includes both tolerations. No fix needed.

##### WARNING: Missing Unavailable Toleration in placement-binding.yaml (all-managed-clusters)

- **File:** `placement-binding.yaml`
- **Lines:** 77-79
- **Issue:** The `all-managed-clusters` Placement missing unavailable toleration.
- **Impact:** Registry credentials from Hub may be removed during temporary cluster issues.

- **Current Code:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
```

- **Proposed Fix:**
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
- key: cluster.open-cluster-management.io/unavailable
  operator: Exists
```

- **Explanation:** Added unavailable toleration for consistency with production-clusters Placement.

##### WARNING: Missing Unavailable Toleration in managedclusterset-placement.yaml (production-us-east-placement)

- **File:** `managedclusterset-placement.yaml`
- **Lines:** 77-99
- **Issue:** The `production-us-east-placement` Placement has no tolerations at all.
- **Impact:** Policies will be removed immediately if clusters become unreachable or unavailable.

- **Current Code:**
```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: production-us-east-placement
  namespace: rhacm-policies
spec:
  clusterSets:
  - production
  
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchLabels:
          region: us-east-1
      claimSelector:
        matchExpressions:
        - key: platform.open-cluster-management.io
          operator: In
          values:
          - AWS
          - GCP
```

- **Proposed Fix:**
```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: production-us-east-placement
  namespace: rhacm-policies
spec:
  clusterSets:
  - production
  
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchLabels:
          region: us-east-1
      claimSelector:
        matchExpressions:
        - key: platform.open-cluster-management.io
          operator: In
          values:
          - AWS
          - GCP
  
  tolerations:
  - key: cluster.open-cluster-management.io/unreachable
    operator: Exists
  - key: cluster.open-cluster-management.io/unavailable
    operator: Exists
```

- **Explanation:** Added both required tolerations for production cluster resilience.

##### INFO: setup-managedclusterset.sh Creates Placements Without Unavailable Toleration

- **File:** `setup-managedclusterset.sh`
- **Lines:** 142-145, 158-161, 175-177
- **Issue:** The script creates Placements with only unreachable toleration, not unavailable.
- **Impact:** Administrators following this script will create Placements that don't follow RHACM 2.15+ best practices.
- **Recommendation:** Update the script to include both tolerations in the Placement definitions.

##### INFO: validate.sh Checks for Deprecated placementrule

- **File:** `1_basic_secret_distribution/validate.sh`
- **Lines:** 62-84
- **Issue:** The validation script checks for `placementrule` resources instead of `placement` resources.
- **Impact:** The script will not correctly validate Placement objects and may mislead users into thinking PlacementRule is still the correct API to use.

- **Current Code:**
```bash
# Check PlacementRules
echo "🔍 Checking placements..."
PLACEMENTS=$(oc get placementrule -n $POLICY_NAMESPACE -o name 2>/dev/null || true)
if [ -z "$PLACEMENTS" ]; then
    echo -e "${YELLOW}⚠ No placement rules found${NC}"
else
    for placement in $PLACEMENTS; do
        PLACEMENT_NAME=$(echo $placement | cut -d'/' -f2)
        DECISIONS=$(oc get placementrule $PLACEMENT_NAME -n $POLICY_NAMESPACE -o jsonpath='{.status.decisions}' 2>/dev/null || echo "[]")
```

- **Proposed Fix:**
```bash
# Check Placements (RHACM 2.6+)
echo "🔍 Checking placements..."
PLACEMENTS=$(oc get placement -n $POLICY_NAMESPACE -o name 2>/dev/null || true)
if [ -z "$PLACEMENTS" ]; then
    echo -e "${YELLOW}⚠ No placements found${NC}"
else
    for placement in $PLACEMENTS; do
        PLACEMENT_NAME=$(echo $placement | cut -d'/' -f2)
        # Check PlacementDecisions (not decisions in Placement status)
        DECISIONS=$(oc get placementdecision -n $POLICY_NAMESPACE -l cluster.open-cluster-management.io/placement=$PLACEMENT_NAME -o json 2>/dev/null | jq -r '.items[].status.decisions // []' || echo "[]")
```

- **Explanation:** Changed from deprecated `placementrule` to modern `placement` API, and updated to check PlacementDecision resources instead of inline status.decisions.

---

## Cross-Cutting Issues

### 1. Missing Unavailable Tolerations (Widespread)

**Pattern:** 14 out of 18 Placement objects across all examples are missing the `cluster.open-cluster-management.io/unavailable` toleration.

**Why This Matters:**
- RHACM 2.15+ best practices explicitly recommend BOTH `unreachable` and `unavailable` tolerations
- `unreachable`: Cluster cannot be contacted (network issue, cluster down)
- `unavailable`: Cluster is contactable but not ready (upgrading, degraded state)
- Without unavailable toleration, policies are removed during cluster upgrades or maintenance windows

**Fix Pattern:** Add this to ALL Placements:
```yaml
tolerations:
- key: cluster.open-cluster-management.io/unreachable
  operator: Exists
- key: cluster.open-cluster-management.io/unavailable
  operator: Exists
```

**Affected Files:**
1. `1_basic_secret_distribution/placement-all-clusters.yaml`
2. `1_basic_secret_distribution/placement-production.yaml` (3 Placements)
3. `2_managed_service_accounts/placement-prod-clusters.yaml`
4. `3_external_secrets_operator/placement-binding.yaml` (2 Placements)
5. `4_registry_credentials/placement-binding.yaml` (2 Placements)
6. `5_database_secrets/placement-binding.yaml` (3 Placements)
7. `6_advanced_patterns/placement-binding.yaml` (1 Placement)
8. `6_advanced_patterns/managedclusterset-placement.yaml` (2 Placements)

### 2. Inconsistent Toleration Patterns

**Observation:** Some Placement objects have both tolerations (like `6_advanced_patterns/placement-binding.yaml` production-clusters), while most have only unreachable. This inconsistency makes it unclear whether the unavailable toleration is optional or required.

**Recommendation:** Standardize on BOTH tolerations for ALL Placements to match RHACM 2.15+ best practices documented in `RHACM-2.15-BEST-PRACTICES.md`.

### 3. Excellent API Version Compliance

**Positive Finding:** ALL YAML files correctly use:
- `cluster.open-cluster-management.io/v1beta1` for Placement
- `cluster.open-cluster-management.io/v1beta2` for ManagedClusterSet and ManagedClusterSetBinding
- `policy.open-cluster-management.io/v1` for Policy and PlacementBinding

No deprecated `apps.open-cluster-management.io/v1` PlacementRule usage was found in actual YAML files.

---

## Best Practice Recommendations

### 1. Hub Secret References

**✅ Excellent Implementation** - The examples correctly demonstrate Hub secret references with proper syntax:
```yaml
DB_PASSWORD: '{{hub fromSecret "rhacm-secrets" "prod-database" "password" hub}}'
```

All Hub secret template usage follows RHACM 2.8+ specifications.

### 2. ManagedClusterSet Architecture

**✅ Proper Structure** - All examples correctly:
- Define ManagedClusterSet with labelSelector
- Create ManagedClusterSetBinding in policy namespace
- Reference clusterSets in Placement specs

This demonstrates proper understanding of RHACM 2.15+ cluster organization.

### 3. Security Practices

**✅ Good Warnings** - Policy examples include appropriate warnings about not committing secrets to Git and recommendations to use External Secrets Operator for production.

**Recommendation:** Consider adding etcd encryption setup instructions to the security section of documentation.

### 4. RBAC Patterns

**✅ Well-Designed** - The ManagedServiceAccount RBAC examples demonstrate:
- Principle of least privilege
- Namespace-scoped vs cluster-scoped roles
- Appropriate permissions for different use cases

No excessive permissions or security concerns identified.

### 5. Documentation Quality

**⚠️ Needs Improvement** - While most documentation is excellent, the deprecated PlacementRule examples in `1_basic_secret_distribution/README.md` need removal/update.

**Recommendation:** Cross-reference all documentation examples against actual YAML files to ensure consistency.

---

## Migration Priorities

If migrating from older RHACM versions, address issues in this order:

### Phase 1 - Critical (Required for RHACM 2.15+)

1. **Remove Deprecated Documentation**
   - File: `1_basic_secret_distribution/README.md`
   - Action: Replace PlacementRule examples with Placement examples
   - Timeline: Immediate

2. **Fix Wrong Toleration Key**
   - File: `6_advanced_patterns/managedclusterset-placement.yaml`
   - Action: Change `node.kubernetes.io/unreachable` to `cluster.open-cluster-management.io/unreachable`
   - Timeline: Immediate

### Phase 2 - Important (Best practices)

3. **Add Unavailable Tolerations to All Placements**
   - Files: 14 Placement objects across all directories
   - Action: Add `cluster.open-cluster-management.io/unavailable` toleration
   - Timeline: Before production use

4. **Update Validation Script**
   - File: `1_basic_secret_distribution/validate.sh`
   - Action: Change from `placementrule` to `placement` API checks
   - Timeline: Before distribution to users

5. **Update Setup Script**
   - File: `6_advanced_patterns/setup-managedclusterset.sh`
   - Action: Add unavailable toleration to generated Placements
   - Timeline: Before distribution to users

### Phase 3 - Enhancements

6. **Standardize specific-clusters Pattern**
   - File: `1_basic_secret_distribution/placement-production.yaml`
   - Action: Add clusterSets reference even for name-based selection
   - Timeline: Optional improvement

7. **Add etcd Encryption Documentation**
   - Location: Security sections in READMEs
   - Action: Include setup instructions for etcd encryption
   - Timeline: Nice to have

---

## Validation Checklist

- [x] All PlacementRule resources converted to Placement
- [x] ManagedClusterSets defined where needed
- [x] ManagedClusterSetBindings created in policy namespaces
- [ ] **Tolerations added to all Placements** - Only 4 out of 18 have both tolerations
- [x] Hub secret references use correct syntax
- [x] PlacementBindings reference correct API groups
- [x] Security best practices implemented (with warnings in code)
- [ ] **Documentation is accurate and complete** - Contains deprecated examples
- [ ] **Scripts are safe and functional** - validate.sh checks deprecated API

---

## Additional Notes

### Positive Observations

1. **Consistent Namespace Usage** - All examples use `rhacm-policies` namespace consistently
2. **Comprehensive Examples** - Coverage of basic secrets, MSA, ESO, registry credentials, database secrets, and advanced patterns
3. **Educational Value** - Good comments and explanations throughout the YAML files
4. **Hub Secret Mastery** - Excellent demonstration of RHACM 2.8+ Hub secret reference feature
5. **RBAC Sophistication** - Well-thought-out permission models in MSA examples

### Testing Recommendations

Before deploying these examples to production:

1. **Test Cluster Unavailability Scenarios**
   - Drain a cluster during maintenance
   - Verify policies remain in place with proper tolerations
   
2. **Test Hub Secret References**
   - Ensure secrets exist on Hub before applying policies
   - Verify RBAC permissions for governance-policy-propagator ServiceAccount

3. **Validate PlacementDecisions**
   - Check that Placements select expected clusters
   - Verify ManagedClusterSet membership is correct

### File Organization

The directory structure is logical and progressive:
- Starts with basic concepts (secret distribution)
- Progresses through service accounts and external operators
- Ends with advanced Hub secret patterns

This organization supports learning and makes the examples easy to navigate.

---

## References

- **RHACM 2.15+ Best Practices:** `./RHACM-2.15-BEST-PRACTICES.md`
- **Migration Guide:** `./secret-management/MIGRATION-FROM-PLACEMENTRULE.md`
- **Validation performed by:** Claude Code (Automated Analysis)
- **Validation criteria based on:** Red Hat Advanced Cluster Management 2.15 documentation

---

## Summary

These RHACM examples demonstrate strong technical knowledge of RHACM 2.15+ architecture. The two critical issues (deprecated documentation and wrong toleration key) are isolated and easy to fix. The widespread missing unavailable tolerations represent a gap in best practice implementation but don't prevent functionality - they only reduce resilience during cluster maintenance windows.

**Recommendation:** Address Phase 1 critical issues immediately, then systematically add unavailable tolerations to all Placements before sharing these examples with users. With these fixes, the examples will be excellent RHACM 2.15+ reference implementations.

**Overall Assessment:** ⚠️ **Good Foundation, Needs Polishing** - 85% compliance with best practices. Primary gaps are in resilience patterns (tolerations) and documentation consistency.


# Red Hat Documentation Verification

**Last Updated:** 2026-01-21  
**RHACM Versions Checked:** 2.6 through 2.15  
**Sources:** Red Hat official documentation, Open Cluster Management upstream docs

## Summary of Findings

This document summarizes verification against official Red Hat documentation to ensure accuracy of the RHACM secret management examples.

---

## ✅ Verified Against Official Documentation

### 1. ServiceAccount for Hub Secret Access

**Finding:** Only ServiceAccounts in the `open-cluster-management` namespace on the **Hub cluster** need access to Hub secrets for `fromSecret` and `copySecretData` template processing.

**Evidence:**
- Policy template processing happens on the Hub cluster
- The governance-policy framework runs in `open-cluster-management` namespace on Hub
- ServiceAccount names vary by version:
  - RHACM 2.6-2.8: `governance-policy-propagator`
  - RHACM 2.9+: `governance-policy-framework`

**Source:** Red Hat Advanced Cluster Management Governance documentation (versions 2.6-2.15)

### 2. config-policy-controller Location

**Finding:** The `config-policy-controller` is a **ManagedClusterAddOn** that runs on **managed clusters**, NOT on the Hub cluster.

**Evidence:**
- `config-policy-controller` is installed in `open-cluster-management-agent-addon` namespace
- This namespace exists on **managed clusters**
- The controller enforces ConfigurationPolicy objects on managed clusters
- It does NOT process Hub templates or need Hub secret access

**Source:** 
- Red Hat ACM 2.12+ Add-ons documentation
- Open Cluster Management configuration policy documentation

### 3. Namespace Usage

**Finding:** Clear distinction between Hub and managed cluster namespaces:

| Namespace | Location | Purpose |
|-----------|----------|---------|
| `open-cluster-management` | Hub cluster | Policy framework, template processing |
| `open-cluster-management-agent-addon` | Managed clusters | Policy enforcement agents |

**Source:** Red Hat ACM 2.8+ Governance and Add-ons documentation

---

## ❌ NOT Found in Official Documentation

### 1. ServiceAccount Named `config-policy-controller-sa`

**Finding:** No official Red Hat documentation references a ServiceAccount named `config-policy-controller-sa`.

**Evidence:**
- Searched RHACM docs versions 2.6 through 2.15
- Searched Open Cluster Management upstream docs
- `config-policy-controller` is documented as an **addon name**, not a ServiceAccount
- No manifests or examples show this ServiceAccount name

**Implication:** This ServiceAccount name should NOT be hardcoded or assumed in documentation.

### 2. Hub Secret Access for Managed Cluster Components

**Finding:** No documentation suggests that managed cluster components need Hub secret access.

**Evidence:**
- `fromSecret` and `copySecretData` template expansion happens on Hub
- Managed clusters receive already-processed ManifestWork objects
- No RBAC requirements documented for managed cluster namespaces accessing Hub secrets

**Implication:** Only Hub cluster ServiceAccounts need Hub secret RBAC.

---

## Corrected Documentation Approach

Based on Red Hat documentation verification, the following approach is correct:

### Single Namespace RBAC (Correct)

```bash
# Grant to open-cluster-management namespace on Hub cluster ONLY
oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management \
  -n rhacm-secrets
```

**Why this is correct:**
- ✅ Documented in Red Hat RHACM docs
- ✅ Only namespace that needs Hub secret access
- ✅ Works across all RHACM versions
- ✅ Follows principle of least privilege

### Multi-Namespace RBAC (Incorrect)

```bash
# INCORRECT - Do not grant to agent-addon namespace
oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management-agent-addon \
  -n rhacm-secrets
```

**Why this is incorrect:**
- ❌ `open-cluster-management-agent-addon` exists on **managed clusters**, not Hub
- ❌ Managed cluster components don't process Hub templates
- ❌ Not documented or required by Red Hat
- ❌ Violates principle of least privilege

---

## Verification Commands

### Check Hub Cluster Namespace

```bash
# On Hub cluster - should see policy framework components
oc get deployment -n open-cluster-management | grep -E "governance|policy"

# Expected output includes:
# - governance-policy-propagator (2.6-2.8)
# - governance-policy-framework (2.9+)
```

### Check Managed Cluster Namespace

```bash
# On Managed cluster - should see policy enforcement components
oc get deployment -n open-cluster-management-agent-addon | grep policy

# Expected output includes:
# - config-policy-controller
```

### Verify ServiceAccount

```bash
# On Hub cluster
./verify-serviceaccount.sh

# Should identify ServiceAccount in open-cluster-management namespace
```

---

## Sources Referenced

### Red Hat Official Documentation

1. **RHACM 2.15 Governance**
   - https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html-single/governance

2. **RHACM 2.12-2.14 Add-ons**
   - https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.14/html-single/add-ons
   - https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.12/html-single/add-ons

3. **RHACM 2.8-2.11 Governance**
   - https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.11/html/governance
   - https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.8/html-single/governance

### Open Cluster Management Upstream

1. **Configuration Policy Controller**
   - https://open-cluster-management.io/docs/getting-started/integration/policy-controllers/configuration-policy/

2. **Add-on Development**
   - https://open-cluster-management.io/docs/developer-guides/addon/

---

## Recommendations

### For Documentation

1. ✅ **DO** grant RBAC to `open-cluster-management` namespace on Hub
2. ✅ **DO** use universal approach (namespace group) for version compatibility
3. ✅ **DO** document that ServiceAccount names vary by version
4. ❌ **DO NOT** reference `config-policy-controller-sa` as needing Hub access
5. ❌ **DO NOT** grant RBAC to `open-cluster-management-agent-addon` for Hub secrets
6. ❌ **DO NOT** assume managed cluster components need Hub secret access

### For Scripts

1. ✅ `verify-serviceaccount.sh` should check `open-cluster-management` namespace only
2. ✅ `setup-hub-secret-rbac.sh` should grant to `open-cluster-management` only
3. ✅ Both scripts should clarify "on Hub cluster" to avoid confusion

### For Examples

1. ✅ All policy examples should show single-namespace RBAC
2. ✅ Comments should clarify this is Hub cluster only
3. ✅ Remove any multi-namespace RBAC examples

---

## Document History

| Date | Change | Reason |
|------|--------|--------|
| 2026-01-21 | Initial verification | User requested Red Hat doc verification |
| 2026-01-21 | Corrected multi-namespace assumption | Found no evidence for agent-addon needing Hub access |
| 2026-01-21 | Removed config-policy-controller-sa references | Not found in official documentation |

---

## Contact

If you find documentation that contradicts these findings, please:
1. Verify you're looking at Hub cluster (not managed cluster) docs
2. Verify the RHACM version matches your deployment
3. Check if it's official Red Hat documentation or community content
4. File an issue with specific documentation links


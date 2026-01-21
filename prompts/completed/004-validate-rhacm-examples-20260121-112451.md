<objective>
Perform a comprehensive validation of all RHACM (Red Hat Advanced Cluster Management) examples in the rhacm-examples/ directory against RHACM 2.15+ best practices and standards.

This validation will ensure the examples are production-ready, follow current API specifications, implement security best practices, and serve as reliable reference implementations for users.
</objective>

<context>
The rhacm-examples/ directory contains multiple subdirectories with YAML configurations, shell scripts, and documentation for RHACM patterns including secret management, managed service accounts, External Secrets Operator integration, registry credentials, database secrets, and advanced patterns.

The RHACM platform has undergone significant changes between versions 2.5 and 2.15+, including:
- Deprecation of PlacementRule in favor of Placement
- Introduction of ManagedClusterSet and ManagedClusterSetBinding (required in 2.15+)
- Hub secret references (RHACM 2.8+)
- Enhanced security patterns and RBAC

Read the best practices reference:
@rhacm-examples/RHACM-2.15-BEST-PRACTICES.md
</context>

<validation_requirements>
Thoroughly analyze and validate ALL aspects across ALL examples in rhacm-examples/:

## 1. API Version Compliance
- ✅ MUST use `Placement` (cluster.open-cluster-management.io/v1beta1)
- ❌ MUST NOT use deprecated `PlacementRule` (apps.open-cluster-management.io/v1)
- Verify correct API groups in PlacementBindings
- Check for proper apiGroup specifications on all resources

## 2. ManagedClusterSet Architecture
- Verify ManagedClusterSet definitions exist where needed
- Confirm ManagedClusterSetBinding is present in policy namespaces
- Validate clusterSets are referenced in Placement specs
- Check for proper labelSelector usage in ManagedClusterSets

## 3. Placement Configuration
- Verify all Placements include tolerations for resilience:
  - cluster.open-cluster-management.io/unreachable
  - cluster.open-cluster-management.io/unavailable
- Check for appropriate predicates and label selectors
- Validate numberOfClusters settings where used
- Assess spreadPolicy configurations for HA patterns

## 4. Security Best Practices
- Verify Hub secret references use proper syntax: `{{hub fromSecret "namespace" "secret-name" "key" hub}}`
- Check that secrets are not embedded directly in Git-tracked files
- Validate RBAC policies for appropriate permissions
- Ensure namespace isolation is properly configured
- Check for etcd encryption recommendations in documentation

## 5. PlacementBinding Correctness
- Verify placementRef uses correct kind: `Placement` (not `PlacementRule`)
- Verify placementRef uses correct apiGroup: `cluster.open-cluster-management.io`
- Check subjects reference correct policy names and apiGroups
- Validate namespace consistency between bindings and referenced resources

## 6. Secret Management Patterns
- For basic secret distribution: validate proper policy structure
- For External Secrets Operator: verify operator installation, SecretStore, and ExternalSecret configurations
- For registry credentials: check dockerconfigjson format and ServiceAccount linkage
- For Hub references: validate proper template syntax and namespace references

## 7. Documentation Quality
- Verify README files explain the purpose and prerequisites
- Check for migration guidance where PlacementRule might have been used
- Validate example commands are correct and safe
- Ensure version requirements are clearly stated

## 8. Shell Script Safety
- Review validation and setup scripts for correctness
- Check for proper error handling
- Verify oc/kubectl commands use correct API resources
- Ensure scripts include necessary prerequisites checks

## 9. Progressive Rollout Patterns
- Where applicable, validate canary and staged deployment configurations
- Check numberOfClusters settings for phased rollouts
- Verify proper label usage for stage separation

## 10. File Structure and Naming
- Validate YAML syntax correctness
- Check for consistent naming conventions
- Verify proper file organization within subdirectories
</validation_requirements>

<discovery_phase>
Before validation, thoroughly explore the codebase:

1. List all subdirectories in rhacm-examples/
2. Identify all YAML files across all subdirectories
3. Identify all shell scripts (.sh files)
4. Identify all documentation files (README.md, *.md)
5. Create a comprehensive inventory of what needs validation
</discovery_phase>

<validation_workflow>
For each example directory:

1. **Read all YAML files** in the directory
2. **Analyze against all validation requirements** listed above
3. **Document issues found** with:
   - Severity: CRITICAL (breaks functionality), WARNING (deprecated/risky), INFO (improvement suggestion)
   - File path and line numbers where applicable
   - Specific issue description
   - Why it matters (impact on functionality, security, or maintainability)
4. **Propose specific fixes** for each issue:
   - Show the problematic code section
   - Provide the corrected version
   - Explain what changed and why

5. **Review documentation and scripts** for accuracy and completeness

6. **Check cross-file consistency** (e.g., PlacementBinding references existing Placements)
</validation_workflow>

<output_format>
Create a comprehensive validation report saved to:
`./rhacm-examples/VALIDATION-REPORT-2.15.md`

Structure the report as follows:

```markdown
# RHACM Examples Validation Report - 2.15+ Compliance

**Validation Date:** [current date]
**RHACM Target Version:** 2.15+
**Examples Validated:** [count] directories, [count] YAML files, [count] scripts

## Executive Summary

- **Critical Issues:** [count] - MUST be fixed
- **Warnings:** [count] - SHOULD be fixed
- **Recommendations:** [count] - COULD be improved
- **Compliant Examples:** [count]

[2-3 paragraph summary of overall findings]

## Overall Compliance Status

| Directory | Status | Critical | Warnings | Info | Notes |
|-----------|--------|----------|----------|------|-------|
| 1_basic_secret_distribution | ✅ / ⚠️ / ❌ | 0 | 0 | 0 | ... |
| ... | ... | ... | ... | ... | ... |

## Detailed Findings by Directory

### 1. [directory-name]

**Purpose:** [brief description]
**Overall Status:** ✅ Compliant / ⚠️ Needs Attention / ❌ Critical Issues

#### Issues Found

##### CRITICAL: [Issue Title]
- **File:** `path/to/file.yaml`
- **Lines:** XX-YY
- **Issue:** [detailed description]
- **Impact:** [why this matters]
- **Current Code:**
```yaml
[problematic code]
```
- **Proposed Fix:**
```yaml
[corrected code]
```
- **Explanation:** [what changed and why]

##### WARNING: [Issue Title]
[same structure as above]

##### INFO: [Issue Title]
[same structure as above]

[Repeat for each directory]

## Cross-Cutting Issues

[Issues that appear across multiple examples]

## Best Practice Recommendations

[General improvements that would benefit all examples]

## Migration Priorities

If migrating from older RHACM versions, address issues in this order:

1. **Phase 1 - Critical (Required for RHACM 2.15+)**
   - [list critical fixes]

2. **Phase 2 - Important (Best practices)**
   - [list warning-level fixes]

3. **Phase 3 - Enhancements**
   - [list improvements]

## Validation Checklist

- [ ] All PlacementRule resources converted to Placement
- [ ] ManagedClusterSets defined where needed
- [ ] ManagedClusterSetBindings created in policy namespaces
- [ ] Tolerations added to all Placements
- [ ] Hub secret references use correct syntax
- [ ] PlacementBindings reference correct API groups
- [ ] Security best practices implemented
- [ ] Documentation is accurate and complete
- [ ] Scripts are safe and functional

## Additional Notes

[Any other observations, patterns noticed, or suggestions]

## References

- RHACM 2.15+ Best Practices: ./RHACM-2.15-BEST-PRACTICES.md
- Validation performed by: Claude Code
- Validation criteria based on: Red Hat Advanced Cluster Management 2.15 documentation
```
</output_format>

<success_criteria>
Before declaring the validation complete, verify:

1. ✅ All subdirectories in rhacm-examples/ have been examined
2. ✅ Every YAML file has been validated against all 10 validation requirement categories
3. ✅ Every issue has:
   - Clear severity classification (CRITICAL/WARNING/INFO)
   - Specific file path and location
   - Detailed explanation of the problem
   - Concrete proposed fix with before/after code
4. ✅ Cross-cutting issues are identified
5. ✅ Validation report is comprehensive and actionable
6. ✅ Report is saved to ./rhacm-examples/VALIDATION-REPORT-2.15.md
7. ✅ All findings are based on RHACM 2.15+ best practices
8. ✅ Documentation and scripts have been reviewed for accuracy

The validation is complete when you can confidently state: "These examples either comply with RHACM 2.15+ standards, or every non-compliant aspect has been identified with a specific fix proposed."
</success_criteria>

<important_notes>
- This is a REVIEW and PROPOSAL task - do NOT modify any existing files
- Document all findings; the user will review and decide which fixes to apply
- Be thorough but pragmatic - focus on issues that impact functionality, security, or maintainability
- If an example intentionally demonstrates an old pattern (like in migration docs), note this context
- When proposing fixes, provide complete, working YAML that can be copy-pasted
- Consider the examples are meant to teach others - documentation quality matters
</important_notes>


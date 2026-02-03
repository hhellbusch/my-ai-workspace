# Index: Namespace Stuck in Terminating

Navigation guide for the namespace terminating troubleshooting documentation.

## Quick Access by Role

### For Cluster Administrators (Need Fast Fix)

**I just need to fix it quickly:**
1. Start with [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
2. Use the relevant one-liner for your scenario
3. Verify with `oc get namespace <name>`

**Time: 2-5 minutes**

### For Support Engineers (Need to Investigate)

**I need to understand what's wrong:**
1. Run `./investigate-namespace.sh <namespace-name>`
2. Review the generated investigation report
3. Follow recommendations in the report
4. Use specific examples from [EXAMPLES.md](EXAMPLES.md)

**Time: 10-15 minutes**

### For Operations Teams (Need Safe Automation)

**I need to automate this safely:**
1. Read [README.md](README.md) to understand the issue
2. Test with `./cleanup-namespace-finalizers.sh <namespace> --dry-run`
3. Execute `./cleanup-namespace-finalizers.sh <namespace>`
4. Integrate into runbooks

**Time: 15-20 minutes**

## Quick Access by Symptom

### "Namespace stuck for hours"

**Status**: `kubectl get namespace` shows Terminating

**Quick Path**:
1. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) → Quick Diagnosis section
2. Run: `oc describe namespace <name>` to see the error
3. Jump to appropriate scenario in [EXAMPLES.md](EXAMPLES.md)

### "Error mentions specific finalizer"

**Message**: `Some content in the namespace has finalizers remaining: <finalizer-name>`

**Quick Path**:
1. Check [QUICK-REFERENCE.md](QUICK-REFERENCE.md) → Common Finalizers Reference
2. Find your finalizer in the table
3. Use the relevant command from Common Scenarios section

### "Multiple resources stuck"

**Symptom**: Many resources with different finalizers

**Quick Path**:
1. Run `./investigate-namespace.sh <namespace>` for full analysis
2. Use `./cleanup-namespace-finalizers.sh <namespace>` for automated cleanup
3. See [EXAMPLES.md](EXAMPLES.md) → Example 3: Multiple Resource Types

### "Operator deleted before resources"

**Symptom**: Operator gone but resources remain

**Quick Path**:
1. [EXAMPLES.md](EXAMPLES.md) → Example 1 (OpenTelemetry) or Example 2 (RHACM)
2. Follow the specific operator cleanup process
3. Use [README.md](README.md) → Method 1 for manual approach

### "CRD deleted before resources"

**Error**: `the server doesn't have a resource type`

**Quick Path**:
1. [EXAMPLES.md](EXAMPLES.md) → Example 4: CRD Deleted Before Resources
2. Choose between raw API or temporary CRD recreation
3. Follow detailed steps for your chosen method

### "Webhook blocking deletion"

**Symptom**: Namespace deletion hangs or times out

**Quick Path**:
1. [EXAMPLES.md](EXAMPLES.md) → Example 5: Webhook Blocking Deletion
2. Check webhook configurations
3. Modify webhook failurePolicy or delete webhook

## Quick Access by Technology

### OpenTelemetry

**Finalizer**: `opentelemetrycollector.opentelemetry.io/finalizer`

**Resources**:
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) → OpenTelemetry Collector section
- [EXAMPLES.md](EXAMPLES.md) → Example 1: OpenTelemetry Collector
- [README.md](README.md) → Scenario 1: OpenTelemetry Collector

### RHACM / ACM

**Finalizers**: 
- `managedcluster.finalizers.open-cluster-management.io`
- `cluster.open-cluster-management.io/api-resource-cleanup`

**Resources**:
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) → RHACM Managed Cluster section
- [EXAMPLES.md](EXAMPLES.md) → Example 2: RHACM Managed Cluster
- [README.md](README.md) → Scenario 2: RHACM Managed Cluster

### Persistent Volumes

**Finalizer**: `kubernetes.io/pv-protection`

**Resources**:
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) → Persistent Volume Claims section
- [EXAMPLES.md](EXAMPLES.md) → Example 6: Persistent Volume Claims
- [README.md](README.md) → Scenario 3: Persistent Volumes

### Service Mesh / Istio

**Finalizers**: Various mesh-related finalizers

**Resources**:
- [EXAMPLES.md](EXAMPLES.md) → Example 7: Service Mesh Resources
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) → Nuclear Option (for all resources)

### Cert-Manager

**Finalizer**: `cert-manager.io/finalizer`

**Resources**:
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) → Common Finalizers Reference
- [README.md](README.md) → Method 1: Remove Finalizers from Individual Resources

### Tekton Pipelines

**Finalizer**: `operator.tekton.dev`

**Resources**:
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) → Common Finalizers Reference
- [README.md](README.md) → Method 1: Remove Finalizers from Individual Resources

### Argo CD

**Finalizers**: 
- `finalizers.argocd.argoproj.io`
- `resources-finalizer.argocd.argoproj.io`

**Resources**:
- [EXAMPLES.md](EXAMPLES.md) → Common Finalizer Reference table
- [README.md](README.md) → Method 1: Remove Finalizers from Individual Resources

## Quick Access by Time Available

### 2 Minutes or Less

**Goal**: Quick fix, move on

1. [QUICK-REFERENCE.md](QUICK-REFERENCE.md) → Quick Fix sections
2. Copy and paste the relevant one-liner
3. Done

### 5-10 Minutes

**Goal**: Understand and fix properly

1. [README.md](README.md) → Investigation Steps (5 min)
2. [README.md](README.md) → Resolution Methods (5 min)
3. Verify and document

### 15+ Minutes

**Goal**: Thorough investigation and documentation

1. Run `./investigate-namespace.sh <namespace>` (5 min)
2. Review generated report (5 min)
3. Read relevant examples in [EXAMPLES.md](EXAMPLES.md) (5 min)
4. Execute fix and verify (5 min)
5. Document findings for team

## Document Structure

### [README.md](README.md) - Comprehensive Guide

**Contents**:
- Problem statement and symptoms
- Root cause analysis
- Investigation steps (systematic approach)
- Resolution methods (4 different approaches)
- Common scenarios (7 specific examples)
- Prevention strategies
- Verification steps

**Best For**: 
- First-time troubleshooting this issue
- Understanding the underlying problem
- Production environments requiring careful approach
- Training and documentation

**Length**: ~15-20 minute read

### [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Fast Command Reference

**Contents**:
- Quick diagnosis commands
- Quick fix commands (by scenario)
- Common finalizers reference table
- One-liner solutions
- Scripts usage
- When to use each method

**Best For**:
- Experienced administrators
- Emergency fixes
- Quick lookups during incidents
- Copy-paste operations

**Length**: ~2-5 minute scan

### [EXAMPLES.md](EXAMPLES.md) - Real-World Scenarios

**Contents**:
- 7 detailed real-world examples
- Step-by-step investigation and resolution
- Actual error messages and outputs
- Prevention tips for each scenario
- Common finalizer reference table

**Best For**:
- Learning from specific examples
- Matching your exact scenario
- Understanding operator-specific issues
- Patterns and templates

**Length**: ~10-15 minute read (or jump to specific example)

## Scripts and Tools

### `investigate-namespace.sh` - Investigation Tool

**Purpose**: Automated investigation and report generation

**Usage**:
```bash
./investigate-namespace.sh <namespace-name>
```

**Output**:
- Namespace information
- Resources with finalizers
- All resources in namespace
- Recent events
- Operator status
- Webhook configurations
- Investigation report with recommendations

**Time**: ~1-2 minutes to run

**Best For**: Understanding what's wrong before fixing

### `cleanup-namespace-finalizers.sh` - Cleanup Tool

**Purpose**: Automated finalizer removal

**Usage**:
```bash
# Dry run (recommended first)
./cleanup-namespace-finalizers.sh <namespace-name> --dry-run

# Execute cleanup
./cleanup-namespace-finalizers.sh <namespace-name>
```

**Features**:
- Dry-run mode for safety
- Confirmation prompts
- Removes finalizers from all resources
- Removes namespace-level finalizers
- Verification and status reporting

**Time**: ~1-2 minutes to run

**Best For**: Safe automated cleanup of stuck namespaces

## Common Workflows

### Workflow 1: Emergency Production Fix

```
1. QUICK-REFERENCE.md → Quick Diagnosis
2. Identify the specific finalizer
3. QUICK-REFERENCE.md → Common Scenarios → Copy relevant command
4. Execute and verify
5. Document what you did
```

**Time**: 2-5 minutes

### Workflow 2: Proper Investigation

```
1. Run ./investigate-namespace.sh <namespace>
2. Review investigation-<namespace>-<timestamp>/investigation-report.txt
3. Read relevant example in EXAMPLES.md
4. Execute recommended solution
5. Verify with oc get namespace <namespace>
```

**Time**: 10-15 minutes

### Workflow 3: Safe Automated Cleanup

```
1. README.md → Read safety notes
2. Run ./cleanup-namespace-finalizers.sh <namespace> --dry-run
3. Review what would be changed
4. Run ./cleanup-namespace-finalizers.sh <namespace>
5. Verify and document
```

**Time**: 5-10 minutes

### Workflow 4: Multiple Namespaces

```
1. Create list of stuck namespaces
2. Run investigation on each: ./investigate-namespace.sh <namespace>
3. Identify common patterns
4. Use EXAMPLES.md to find matching scenario
5. Apply fix to all namespaces using script or loop
```

**Time**: 15-30 minutes depending on count

## Related Documentation

### Within This Repository

- [../api-slowness-web-console/](../api-slowness-web-console/) - API server performance issues
- [../control-plane-kubeconfigs/](../control-plane-kubeconfigs/) - Control plane troubleshooting
- [../kubevirt-vm-stuck-provisioning/](../kubevirt-vm-stuck-provisioning/) - VM provisioning with finalizers
- [../portworx-csi-crashloop/](../portworx-csi-crashloop/) - Storage with finalizers

### External Resources

- [Kubernetes Finalizers Documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/)
- [OpenShift Projects and Namespaces](https://docs.openshift.com/container-platform/latest/applications/projects/working-with-projects.html)
- [Operator Lifecycle Manager](https://docs.openshift.com/container-platform/latest/operators/understanding/olm/olm-understanding-olm.html)

## Quick Decision Tree

```
Namespace stuck in Terminating?
│
├─ Is this emergency/production?
│  ├─ YES → QUICK-REFERENCE.md → Quick Fix
│  └─ NO → Continue
│
├─ Do you know the specific finalizer?
│  ├─ YES → QUICK-REFERENCE.md → Common Scenarios
│  └─ NO → Run ./investigate-namespace.sh
│
├─ Is it a known operator (OTel, RHACM, etc)?
│  ├─ YES → EXAMPLES.md → Find matching example
│  └─ NO → README.md → Investigation Steps
│
├─ Multiple resources or complex situation?
│  ├─ YES → Use ./cleanup-namespace-finalizers.sh
│  └─ NO → Manual patch commands
│
└─ Need to understand root cause?
   ├─ YES → README.md → Root Cause section
   └─ NO → Execute fix and verify
```

## Getting Help

**If you're stuck:**
1. Review the investigation report: `cat investigation-<namespace>-<timestamp>/investigation-report.txt`
2. Check [README.md](README.md) → Troubleshooting Tips
3. Look for similar scenarios in [EXAMPLES.md](EXAMPLES.md)
4. Check operator logs mentioned in investigation

**For clarification:**
- All commands are tested on OpenShift 4.12+
- Scripts require `oc`, `jq`, and `bash`
- Most commands work with `kubectl` instead of `oc`

**Safety questions:**
- Read [README.md](README.md) → Safety Notes before forcing deletion
- Always use `--dry-run` first when possible
- Consider impact of bypassing finalizers

---

*Last Updated: February 2026*
*OpenShift Versions: 4.12+*


# Troubleshooting RBAC for hubAcceptsClient

This guide helps diagnose and fix RBAC issues when creating ManagedCluster resources with `hubAcceptsClient: true`.

## The Error

```
admission webhook "managedclustervalidators.admission.cluster.open-cluster-management.io" 
denied the request: managedclusters/accept "cluster-name" is forbidden: 
user "system:serviceaccount:open-cluster-management:cluster-importer" 
cannot update the HubAcceptsClient field
```

## Root Cause

The `hubAcceptsClient` field is protected by RHACM's admission webhook and requires permission to update the `managedclusters/accept` subresource. The exact API group for this subresource can vary by RHACM version.

## Diagnosis Steps

### Step 1: Run the Debug Script

```bash
cd hub-rbac/

# Using service account kubeconfig
export KUBECONFIG=/tmp/cluster-importer-kubeconfig
./debug-rbac.sh
```

Look for the output section:

```
3. Testing permissions for service account...
  ✗ can-i update managedclusters/accept (denied)
```

### Step 2: Check API Resources

```bash
# See what API resources exist on your hub cluster
kubectl api-resources | grep managedcluster

# Expected output might include:
# managedclusters    cluster.open-cluster-management.io
# managedclusters    register.open-cluster-management.io
```

### Step 3: Verify ClusterRole is Applied

```bash
# Check ClusterRole exists
oc get clusterrole cluster-importer

# Check it has the accept permission
oc get clusterrole cluster-importer -o yaml | grep -A 5 "managedclusters/accept"

# Expected output:
#   - apiGroups: ["cluster.open-cluster-management.io"]
#     resources: ["managedclusters/accept"]
#     verbs: ["update"]
#   - apiGroups: ["register.open-cluster-management.io"]
#     resources: ["managedclusters/accept"]
#     verbs: ["update"]
```

### Step 4: Verify ClusterRoleBinding

```bash
# Check binding exists
oc get clusterrolebinding cluster-importer

# Verify it points to correct service account
oc get clusterrolebinding cluster-importer -o yaml

# Expected:
# subjects:
#   - kind: ServiceAccount
#     name: cluster-importer
#     namespace: open-cluster-management
```

### Step 5: Test Permission Directly

```bash
# Test as the service account
kubectl auth can-i update managedclusters/accept \
  --as=system:serviceaccount:open-cluster-management:cluster-importer \
  -n test-cluster

# Should return: yes
```

## Solutions

### Solution 1: Use Extended ClusterRole

If the basic ClusterRole doesn't work, try the extended version:

```bash
# Remove old binding (keeps ClusterRole)
oc delete clusterrolebinding cluster-importer

# Apply extended versions
oc apply -f clusterrole-extended.yaml
oc apply -f clusterrolebinding-extended.yaml

# Regenerate kubeconfig (to pick up new permissions)
./extract-token.sh
./create-kubeconfig.sh

# Test again
./debug-rbac.sh
```

The extended ClusterRole includes:
- Both API groups for accept subresource
- CSR approval permissions
- ManagedClusterSet permissions
- Work API permissions

### Solution 2: Check RHACM Version Specific Requirements

Different RHACM versions may have different requirements. Check your version:

```bash
# Check RHACM version
oc get csv -n open-cluster-management | grep advanced-cluster-management

# Check multicluster-engine version
oc get csv -n multicluster-engine | grep multicluster-engine
```

**Version-specific notes:**

**RHACM 2.5-2.7:**
- Uses `cluster.open-cluster-management.io` for most operations
- May require `register.open-cluster-management.io` for accept

**RHACM 2.8+:**
- Multicluster Engine (MCE) handles cluster lifecycle
- May require additional work API permissions

### Solution 3: Check for Admission Webhook Issues

```bash
# Check if admission webhooks are healthy
oc get validatingwebhookconfigurations | grep managedcluster

# Check specific webhook
oc get validatingwebhookconfigurations \
  managedclustervalidators.admission.cluster.open-cluster-management.io -o yaml

# Check webhook pod
oc get pods -n open-cluster-management | grep webhook
oc logs -n open-cluster-management <webhook-pod>
```

### Solution 4: Verify Service Account Token is Fresh

Stale tokens may not have latest permissions:

```bash
# Regenerate token
cd hub-rbac/
./extract-token.sh

# Recreate kubeconfig
./create-kubeconfig.sh

# Test permissions
export KUBECONFIG=/tmp/cluster-importer-kubeconfig
oc auth can-i update managedclusters/accept
```

### Solution 5: Try Manual Creation with Service Account

Test directly without Ansible:

```bash
export KUBECONFIG=/tmp/cluster-importer-kubeconfig

# Try creating a ManagedCluster
oc create -f - <<EOF
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: test-rbac-manual
  labels:
    environment: test
spec:
  hubAcceptsClient: true
  leaseDurationSeconds: 60
EOF
```

**If this succeeds:** Ansible playbook has an issue, not RBAC  
**If this fails:** RBAC needs more permissions

## Common Findings

### Finding 1: Wrong API Group

**Symptom**: Permission denied even after adding accept subresource

**Solution**: The API group varies by version. Run:
```bash
# Check API versions
oc api-versions | grep cluster-management
oc api-versions | grep register

# Output might show:
# cluster.open-cluster-management.io/v1
# register.open-cluster-management.io/v1
```

Use whichever group(s) appear in your output.

### Finding 2: CSR Approval Required

**Symptom**: Cluster joins but never becomes available

**Solution**: Add CSR permissions (included in extended ClusterRole)

### Finding 3: Webhook Certificate Issues

**Symptom**: Webhook errors in logs

**Solution**: Check webhook certificates:
```bash
oc get validatingwebhookconfigurations -o yaml | grep caBundle
```

## Quick Test Matrix

Run these tests in order to narrow down the issue:

| Test | Command | Expected | If Fails |
|------|---------|----------|----------|
| 1. Basic auth | `oc whoami` | service account name | Fix kubeconfig |
| 2. Namespace create | `oc auth can-i create namespace` | yes | Fix ClusterRole |
| 3. ManagedCluster create | `oc auth can-i create managedcluster` | yes | Fix ClusterRole |
| 4. Accept permission | `oc auth can-i update managedclusters/accept` | yes | Use extended role |
| 5. Dry-run create | `oc create -f test.yaml --dry-run=server` | success | Check webhook |

## If Nothing Works

### Fallback Option 1: Use Cluster-Admin Group

Add service account to cluster-admin (not recommended for production):

```bash
oc adm policy add-cluster-role-to-user cluster-admin \
  system:serviceaccount:open-cluster-management:cluster-importer
```

### Fallback Option 2: Copy Existing RHACM Role

RHACM has built-in roles that work. Copy their permissions:

```bash
# Find RHACM's own cluster import role
oc get clusterrole | grep -i cluster | grep -i import

# Examine it
oc get clusterrole <rhacm-role-name> -o yaml

# Use those permissions as reference
```

## Still Stuck?

Share the output of:

```bash
cd hub-rbac/
./debug-rbac.sh > rbac-debug-output.txt 2>&1

# Also get ClusterRole details
oc get clusterrole cluster-importer -o yaml >> rbac-debug-output.txt

# And webhook configuration
oc get validatingwebhookconfigurations \
  managedclustervalidators.admission.cluster.open-cluster-management.io \
  -o yaml >> rbac-debug-output.txt 2>&1 || echo "Webhook not found" >> rbac-debug-output.txt
```

Share `rbac-debug-output.txt` for further analysis.

---

**Last Updated**: February 19, 2026

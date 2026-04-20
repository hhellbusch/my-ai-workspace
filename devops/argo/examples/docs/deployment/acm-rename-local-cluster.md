# Renaming local-cluster in OpenShift ACM for ArgoCD Integration

## Overview

When using **OpenShift Advanced Cluster Management (ACM)** with GitOps/ArgoCD, the hub cluster is automatically registered with the name `local-cluster`. This can be confusing when managing multiple clusters, as you may want to use the actual cluster name instead.

This guide shows you how to rename `local-cluster` to use your cluster's actual infrastructure name using the supported ACM method.

## Problem Statement

By default, when ACM manages the hub cluster, it creates a `ManagedCluster` resource named `local-cluster`. This creates issues when:

- You want consistent naming across your cluster inventory
- You're integrating with ArgoCD and want meaningful cluster names
- You need to reference the hub cluster in GitOps configurations with its actual name
- You're working with multi-hub deployments and need to distinguish between hubs

## Supported Solution

Red Hat ACM provides a supported method to rename the local cluster using the `MultiClusterHub` custom resource. The process involves three steps:

1. Disable hub self-management
2. Set the desired cluster name
3. Re-enable hub self-management

**Reference:** [Red Hat ACM Documentation - Disable Hub Self-Management](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing#disable-hub-self-management)

## Prerequisites

- OpenShift cluster with ACM installed
- `cluster-admin` permissions
- OpenShift CLI (`oc`) configured and authenticated
- The `MultiClusterHub` resource is installed (typically in `open-cluster-management` namespace)

## Step-by-Step Instructions

### Step 1: Verify Current Configuration

First, check your current setup:

```bash
# Check current managed clusters
oc get managedcluster

# Verify MultiClusterHub exists
oc get MultiClusterHub -n open-cluster-management

# Check current configuration
oc get MultiClusterHub multiclusterhub -n open-cluster-management -o yaml | grep -A 5 "spec:"
```

Expected output should show `local-cluster` in the managed clusters list.

### Step 2: Disable Hub Self-Management

Disable hub self-management to allow the cluster name change:

```bash
oc patch MultiClusterHub multiclusterhub \
  -n open-cluster-management \
  --type merge \
  -p '{"spec":{"disableHubSelfManagement":true}}'
```

**Wait for completion:**

```bash
# Watch the local-cluster being removed
oc get managedcluster local-cluster -w

# The command will eventually show "Error from server (NotFound)"
# This is expected and means the cluster has been unmanaged
```

This typically takes 30-60 seconds.

### Step 3: Set the New Local Cluster Name

Determine your cluster's actual name and set it:

```bash
# Get the actual cluster infrastructure name
CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')

echo "Setting cluster name to: $CLUSTER_NAME"

# Patch the MultiClusterHub with the new name
oc patch MultiClusterHub multiclusterhub \
  -n open-cluster-management \
  --type merge \
  -p "{\"spec\":{\"localClusterName\":\"${CLUSTER_NAME}\"}}"
```

**Alternative:** Use a custom name:

```bash
# Use a custom cluster name instead
CLUSTER_NAME="production-hub"

oc patch MultiClusterHub multiclusterhub \
  -n open-cluster-management \
  --type merge \
  -p "{\"spec\":{\"localClusterName\":\"${CLUSTER_NAME}\"}}"
```

### Step 4: Re-enable Hub Self-Management

Re-enable hub self-management to register the cluster with the new name:

```bash
oc patch MultiClusterHub multiclusterhub \
  -n open-cluster-management \
  --type merge \
  -p '{"spec":{"disableHubSelfManagement":false}}'
```

**Wait for the cluster to be registered:**

```bash
# Watch for the new cluster to appear
oc get managedcluster -w

# Check cluster status
oc get managedcluster ${CLUSTER_NAME}
```

Wait until the cluster shows as `Available=True`:

```bash
oc get managedcluster ${CLUSTER_NAME} -o jsonpath='{.status.conditions[?(@.type=="ManagedClusterConditionAvailable")].status}'
```

## Automated Script

Use this complete script to automate the entire process:

```bash
#!/bin/bash
# rename-local-cluster.sh
# Renames ACM local-cluster to use the actual cluster infrastructure name

set -e

NAMESPACE="open-cluster-management"
MCH_NAME="multiclusterhub"

echo "================================================"
echo "ACM Local Cluster Rename Script"
echo "================================================"

# Get the actual cluster name
CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')

if [ -z "$CLUSTER_NAME" ]; then
  echo "ERROR: Could not determine cluster name"
  exit 1
fi

echo ""
echo "Current managed clusters:"
oc get managedcluster

echo ""
echo "Will rename local-cluster to: ${CLUSTER_NAME}"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Step 1: Disable hub self-management
echo ""
echo "================================================"
echo "Step 1: Disabling hub self-management..."
echo "================================================"
oc patch MultiClusterHub ${MCH_NAME} \
  -n ${NAMESPACE} \
  --type merge \
  -p '{"spec":{"disableHubSelfManagement":true}}'

echo "Waiting for local-cluster to be removed..."
TIMEOUT=120
ELAPSED=0
until ! oc get managedcluster local-cluster 2>/dev/null; do
  if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "ERROR: Timeout waiting for local-cluster removal"
    exit 1
  fi
  echo "  Waiting... (${ELAPSED}s/${TIMEOUT}s)"
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done
echo "✅ Hub self-management disabled"

# Step 2: Set the new local cluster name
echo ""
echo "================================================"
echo "Step 2: Setting local cluster name to ${CLUSTER_NAME}..."
echo "================================================"
oc patch MultiClusterHub ${MCH_NAME} \
  -n ${NAMESPACE} \
  --type merge \
  -p "{\"spec\":{\"localClusterName\":\"${CLUSTER_NAME}\"}}"
echo "✅ Local cluster name configured"

# Step 3: Re-enable hub self-management
echo ""
echo "================================================"
echo "Step 3: Re-enabling hub self-management..."
echo "================================================"
oc patch MultiClusterHub ${MCH_NAME} \
  -n ${NAMESPACE} \
  --type merge \
  -p '{"spec":{"disableHubSelfManagement":false}}'

echo "Waiting for ${CLUSTER_NAME} to be registered..."
TIMEOUT=120
ELAPSED=0
until oc get managedcluster ${CLUSTER_NAME} 2>/dev/null; do
  if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "ERROR: Timeout waiting for ${CLUSTER_NAME} registration"
    exit 1
  fi
  echo "  Waiting... (${ELAPSED}s/${TIMEOUT}s)"
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

echo "Waiting for ${CLUSTER_NAME} to be available..."
TIMEOUT=300
ELAPSED=0
until [[ $(oc get managedcluster ${CLUSTER_NAME} -o jsonpath='{.status.conditions[?(@.type=="ManagedClusterConditionAvailable")].status}' 2>/dev/null) == "True" ]]; do
  if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "WARNING: Cluster may still be initializing"
    break
  fi
  STATUS=$(oc get managedcluster ${CLUSTER_NAME} -o jsonpath='{.status.conditions[?(@.type=="ManagedClusterConditionAvailable")].status}' 2>/dev/null || echo "Unknown")
  echo "  Cluster status: ${STATUS} (${ELAPSED}s/${TIMEOUT}s)"
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

echo ""
echo "================================================"
echo "✅ Successfully renamed local-cluster to ${CLUSTER_NAME}"
echo "================================================"
echo ""
echo "Managed clusters:"
oc get managedcluster

echo ""
echo "Cluster details:"
oc get managedcluster ${CLUSTER_NAME} -o yaml | grep -A 20 "status:"

echo ""
echo "================================================"
echo "Next Steps:"
echo "================================================"
echo "1. Update your ArgoCD configuration to use: ${CLUSTER_NAME}"
echo "2. Update any ApplicationSets or Placements that reference local-cluster"
echo "3. Verify ArgoCD can see the cluster:"
echo "   argocd cluster list"
echo "   oc get secrets -n openshift-gitops -l argocd.argoproj.io/secret-type=cluster"
```

### Save and Run the Script

```bash
# Save the script
cat > rename-local-cluster.sh << 'EOF'
# ... paste the script above ...
EOF

# Make it executable
chmod +x rename-local-cluster.sh

# Run it
./rename-local-cluster.sh
```

## Verification

After completing the rename process, verify everything is working correctly:

### 1. Verify Managed Cluster

```bash
# Check that local-cluster is gone and new name exists
oc get managedcluster

# Expected output should show your new cluster name, not local-cluster
# NAME              HUB ACCEPTED   MANAGED CLUSTER URLS   JOINED   AVAILABLE   AGE
# my-cluster-name   true                                  True     True        5m
```

### 2. Check Cluster Status

```bash
CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')

# View detailed status
oc get managedcluster ${CLUSTER_NAME} -o yaml

# Check all conditions are healthy
oc get managedcluster ${CLUSTER_NAME} -o jsonpath='{range .status.conditions[*]}{.type}{"\t"}{.status}{"\n"}{end}'
```

Expected conditions:
```
ManagedClusterConditionAvailable    True
ManagedClusterJoined                True
HubAcceptedManagedCluster           True
```

### 3. Verify ArgoCD Integration

```bash
# Check ArgoCD cluster secrets
oc get secrets -n openshift-gitops -l argocd.argoproj.io/secret-type=cluster

# View the cluster name in the secret
oc get secret -n openshift-gitops \
  -l argocd.argoproj.io/secret-type=cluster \
  -o jsonpath='{.items[*].data.name}' | base64 -d
echo

# Using ArgoCD CLI (if available)
argocd login --core
argocd cluster list
```

### 4. Check MultiClusterHub Configuration

```bash
# View the current MCH configuration
oc get MultiClusterHub multiclusterhub -n open-cluster-management -o yaml

# Should show:
#   spec:
#     disableHubSelfManagement: false
#     localClusterName: your-cluster-name
```

## Update ArgoCD Configuration

After renaming the cluster, update your ArgoCD configurations to reference the new name:

### 1. Update hubs.yaml

If you're using the multi-cluster deployment workflow from this repository:

```yaml
# hubs.yaml
hubs:
  my-actual-cluster:  # Changed from local-cluster
    name: my-actual-cluster
    server: https://kubernetes.default.svc
    argocd_namespace: openshift-gitops
    token_secret: OPENSHIFT_TOKEN_HUB
    dry_run: false
```

### 2. Update ApplicationSets

If you have ApplicationSets using cluster selectors:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-apps
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          environment: production
      values:
        clusterName: my-actual-cluster  # Updated from local-cluster
```

### 3. Update Placement Rules

If using ACM Placement for app deployment:

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: hub-cluster
spec:
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchLabels:
          name: my-actual-cluster  # Updated from local-cluster
```

## Troubleshooting

### Cluster Stuck in Terminating

If `local-cluster` gets stuck during removal:

```bash
# Check for finalizers
oc get managedcluster local-cluster -o yaml | grep -A 5 finalizers

# Remove finalizers if stuck (use with caution)
oc patch managedcluster local-cluster -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### New Cluster Not Appearing

If the new cluster doesn't appear after re-enabling:

```bash
# Check MCH status
oc get MultiClusterHub multiclusterhub -n open-cluster-management -o yaml | grep -A 20 status

# Check operator logs
oc logs -n open-cluster-management deployment/multiclusterhub-operator -f

# Check klusterlet status
oc get klusterlet klusterlet -o yaml
```

### ArgoCD Not Seeing New Cluster

If ArgoCD still shows the old name:

```bash
# Restart ArgoCD components
oc rollout restart deployment/openshift-gitops-server -n openshift-gitops
oc rollout restart deployment/openshift-gitops-application-controller -n openshift-gitops

# Check cluster secrets
oc get secrets -n openshift-gitops -l argocd.argoproj.io/secret-type=cluster -o yaml
```

### Rollback to local-cluster

If you need to revert the change:

```bash
# Disable hub self-management
oc patch MultiClusterHub multiclusterhub \
  -n open-cluster-management \
  --type merge \
  -p '{"spec":{"disableHubSelfManagement":true}}'

# Wait for cluster removal
sleep 30

# Remove the localClusterName field (revert to default)
oc patch MultiClusterHub multiclusterhub \
  -n open-cluster-management \
  --type json \
  -p '[{"op": "remove", "path": "/spec/localClusterName"}]'

# Re-enable hub self-management
oc patch MultiClusterHub multiclusterhub \
  -n open-cluster-management \
  --type merge \
  -p '{"spec":{"disableHubSelfManagement":false}}'
```

## Important Notes

### Supported Method

This is the **officially supported** method for renaming the local cluster as documented by Red Hat. Do not attempt to:
- Manually edit the `ManagedCluster` resource name
- Delete and recreate cluster registration manually  
- Modify ArgoCD cluster secrets directly without updating ACM

### Timing Considerations

- **Downtime:** During the rename process (Steps 1-3), the hub cluster is not managed by ACM
- **Duration:** The entire process typically takes 2-5 minutes
- **Planning:** Perform this during a maintenance window if possible

### ACM Version Requirements

This feature is available in:
- Red Hat ACM 2.5+
- MultiCluster Engine 2.0+

Verify your version:
```bash
oc get MultiClusterHub multiclusterhub -n open-cluster-management -o jsonpath='{.status.currentVersion}'
```

### Impact on Running Applications

- **ArgoCD Applications:** May experience brief reconciliation delays
- **Policy Controllers:** Continue running but may not report status briefly
- **Observability:** Metrics collection may have gaps during transition
- **Managed Clusters:** Not affected (only hub cluster changes)

## Best Practices

1. **Choose a Meaningful Name:** Use your cluster's infrastructure name or a descriptive name like `production-hub`
2. **Document the Change:** Update your runbooks and documentation with the new name
3. **Update Automation:** Review and update any scripts or GitOps configs that reference `local-cluster`
4. **Test First:** If possible, test this process in a development environment first
5. **Backup Configuration:** Take a backup of your ACM configuration before making changes

## Related Documentation

- [Multi-Cluster ArgoCD Deployment](multi-cluster-deployment.md)
- [ArgoCD Setup Guide](../getting-started/SETUP-GUIDE.md)
- [Red Hat ACM Documentation](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/)
- [Red Hat ACM - Disable Hub Self-Management](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing#disable-hub-self-management)

## Example: Complete Workflow

Here's a complete example from start to finish:

```bash
# 1. Check current state
$ oc get managedcluster
NAME            HUB ACCEPTED   MANAGED CLUSTER URLS   JOINED   AVAILABLE   AGE
local-cluster   true                                  True     True        30d

# 2. Get desired cluster name
$ CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
$ echo $CLUSTER_NAME
ocp-prod-aws-01

# 3. Run the rename script
$ ./rename-local-cluster.sh
================================================
ACM Local Cluster Rename Script
================================================

Current managed clusters:
NAME            HUB ACCEPTED   MANAGED CLUSTER URLS   JOINED   AVAILABLE   AGE
local-cluster   true                                  True     True        30d

Will rename local-cluster to: ocp-prod-aws-01
Continue? (y/n) y

================================================
Step 1: Disabling hub self-management...
================================================
multiclusterhub.operator.open-cluster-management.io/multiclusterhub patched
Waiting for local-cluster to be removed...
  Waiting... (0s/120s)
  Waiting... (5s/120s)
✅ Hub self-management disabled

================================================
Step 2: Setting local cluster name to ocp-prod-aws-01...
================================================
multiclusterhub.operator.open-cluster-management.io/multiclusterhub patched
✅ Local cluster name configured

================================================
Step 3: Re-enabling hub self-management...
================================================
multiclusterhub.operator.open-cluster-management.io/multiclusterhub patched
Waiting for ocp-prod-aws-01 to be registered...
  Waiting... (0s/120s)
  Cluster status: Unknown (10s/300s)
  Cluster status: True (20s/300s)

================================================
✅ Successfully renamed local-cluster to ocp-prod-aws-01
================================================

Managed clusters:
NAME              HUB ACCEPTED   MANAGED CLUSTER URLS   JOINED   AVAILABLE   AGE
ocp-prod-aws-01   true                                  True     True        1m

# 4. Update hubs.yaml
$ vim hubs.yaml
# Changed local-cluster to ocp-prod-aws-01

# 5. Verify ArgoCD
$ argocd cluster list
SERVER                          NAME              VERSION  STATUS      MESSAGE
https://kubernetes.default.svc  ocp-prod-aws-01   1.28     Successful  

# 6. Done!
```

## Summary

Renaming `local-cluster` to use your actual cluster name:
- ✅ Uses the officially supported ACM method
- ✅ Maintains cluster health and functionality
- ✅ Provides better clarity in multi-cluster environments
- ✅ Integrates seamlessly with ArgoCD and GitOps workflows
- ✅ Takes only 2-5 minutes to complete

The three-step process (disable → rename → enable) ensures a clean transition with minimal disruption.


#!/bin/bash
# rename-local-cluster.sh
# Renames ACM local-cluster to use the actual cluster infrastructure name
#
# Usage: ./rename-local-cluster.sh [custom-name]
#
# If no custom name is provided, uses the cluster infrastructure name
# from: oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}'

set -e

NAMESPACE="open-cluster-management"
MCH_NAME="multiclusterhub"

echo "================================================"
echo "ACM Local Cluster Rename Script"
echo "================================================"

# Get the actual cluster name
if [ -n "$1" ]; then
  CLUSTER_NAME="$1"
  echo "Using custom cluster name: ${CLUSTER_NAME}"
else
  CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
  echo "Using infrastructure cluster name: ${CLUSTER_NAME}"
fi

if [ -z "$CLUSTER_NAME" ]; then
  echo "ERROR: Could not determine cluster name"
  echo "Usage: $0 [custom-cluster-name]"
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
echo ""
echo "Documentation: argo-examples/docs/deployment/acm-rename-local-cluster.md"


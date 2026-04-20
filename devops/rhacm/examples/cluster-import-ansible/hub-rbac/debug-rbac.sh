#!/bin/bash
# Debug RBAC permissions for managedclusters/accept
#
# This script helps identify the correct API group and permissions needed
# for the hubAcceptsClient field

set -e

SA_NAME="cluster-importer"
NAMESPACE="open-cluster-management"
KUBECONFIG_FILE="/tmp/cluster-importer-kubeconfig"

echo "=========================================="
echo "RHACM RBAC Debugging Tool"
echo "=========================================="
echo ""

# Check if we're using the service account
if [ -f "$KUBECONFIG_FILE" ]; then
    export KUBECONFIG="$KUBECONFIG_FILE"
    echo "Using service account kubeconfig: $KUBECONFIG_FILE"
else
    echo "Using current kubeconfig (admin)"
fi

CURRENT_USER=$(oc whoami)
echo "Current user: $CURRENT_USER"
echo ""

# Check API resources for managedclusters
echo "1. Checking ManagedCluster API resources..."
echo "----------------------------------------"
oc api-resources | grep -i managedcluster || echo "No managedcluster resources found"
echo ""

# Check API groups
echo "2. Checking API groups..."
echo "----------------------------------------"
oc api-versions | grep cluster-management || echo "No cluster-management API groups found"
echo ""

# Check specific permissions
echo "3. Testing permissions for service account..."
echo "----------------------------------------"

TESTS=(
    "create:managedclusters:cluster.open-cluster-management.io"
    "update:managedclusters:cluster.open-cluster-management.io"
    "update:managedclusters/accept:cluster.open-cluster-management.io"
    "update:managedclusters/accept:register.open-cluster-management.io"
    "create:managedclusters.cluster.open-cluster-management.io"
)

for test in "${TESTS[@]}"; do
    IFS=':' read -r verb resource group <<< "$test"
    
    if [ -n "$group" ]; then
        result=$(kubectl auth can-i "$verb" "$resource" --as="system:serviceaccount:${NAMESPACE}:${SA_NAME}" 2>&1)
    else
        result=$(kubectl auth can-i "$verb" "$resource" --as="system:serviceaccount:${NAMESPACE}:${SA_NAME}" 2>&1)
    fi
    
    if [[ "$result" == "yes" ]]; then
        echo "  ✓ can-i $verb $resource"
    else
        echo "  ✗ can-i $verb $resource (denied)"
    fi
done
echo ""

# Check ClusterRole
echo "4. Checking ClusterRole rules..."
echo "----------------------------------------"
if oc get clusterrole cluster-importer &>/dev/null; then
    echo "ClusterRole 'cluster-importer' exists"
    echo ""
    echo "Rules containing 'managedclusters':"
    oc get clusterrole cluster-importer -o yaml | grep -A 5 managedclusters || echo "No managedclusters rules found"
else
    echo "❌ ClusterRole 'cluster-importer' not found"
fi
echo ""

# Check ClusterRoleBinding
echo "5. Checking ClusterRoleBinding..."
echo "----------------------------------------"
if oc get clusterrolebinding cluster-importer &>/dev/null; then
    echo "ClusterRoleBinding 'cluster-importer' exists"
    oc get clusterrolebinding cluster-importer -o yaml | grep -A 3 subjects
else
    echo "❌ ClusterRoleBinding 'cluster-importer' not found"
fi
echo ""

# Try to describe what's blocking
echo "6. Testing actual ManagedCluster creation (dry-run)..."
echo "----------------------------------------"

if [[ "$CURRENT_USER" == *"serviceaccount"* ]]; then
    echo "Testing with service account..."
    
    oc create -f - --dry-run=server <<EOF
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: test-rbac-check
spec:
  hubAcceptsClient: true
EOF
    
    if [ $? -eq 0 ]; then
        echo "✓ Dry-run successful - RBAC should work"
    else
        echo "✗ Dry-run failed - RBAC issue detected"
    fi
else
    echo "Not using service account - skipping dry-run test"
    echo "Run with: export KUBECONFIG=$KUBECONFIG_FILE"
fi

echo ""
echo "=========================================="
echo "Debug Complete"
echo "=========================================="

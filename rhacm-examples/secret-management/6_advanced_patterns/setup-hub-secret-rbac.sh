#!/bin/bash

# Script to set up RBAC for Hub secret access
# Works with all RHACM versions by granting access to entire namespace

set -euo pipefail

echo "================================================"
echo "Setup RBAC for Hub Secret Access"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if we're on Hub cluster
if ! oc get multiclusterhub -n open-cluster-management &>/dev/null; then
    echo "❌ Not connected to RHACM Hub cluster"
    exit 1
fi

echo -e "${GREEN}✓ Connected to RHACM Hub${NC}"
echo ""

# Get target namespace
if [ $# -eq 0 ]; then
    TARGET_NAMESPACE="rhacm-secrets"
    echo "Using default namespace: $TARGET_NAMESPACE"
    echo "(Pass namespace as argument to use a different one)"
else
    TARGET_NAMESPACE=$1
    echo "Using provided namespace: $TARGET_NAMESPACE"
fi
echo ""

# Create namespace if it doesn't exist
if ! oc get namespace $TARGET_NAMESPACE &>/dev/null; then
    echo "📦 Creating namespace $TARGET_NAMESPACE..."
    oc create namespace $TARGET_NAMESPACE
    echo -e "${GREEN}✓ Namespace created${NC}"
else
    echo -e "${GREEN}✓ Namespace $TARGET_NAMESPACE already exists${NC}"
fi
echo ""

# Grant access - Universal approach
echo "🔐 Granting RBAC access..."
echo ""
echo "Method: Grant view to all ServiceAccounts in open-cluster-management namespace"
echo "(This works regardless of RHACM version)"
echo ""

echo "Granting access to open-cluster-management namespace on Hub cluster..."
oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management \
  -n $TARGET_NAMESPACE

echo ""
echo -e "${GREEN}✓ RBAC configured${NC}"
echo ""
echo "Note: ServiceAccount names vary by RHACM version:"
echo "  Namespace: open-cluster-management (Hub cluster)"
echo "    - RHACM 2.6-2.8: governance-policy-propagator"
echo "    - RHACM 2.9+: governance-policy-framework"
echo "  This configuration works for all versions"
echo ""

# Verify the RoleBinding was created
echo "📋 Verification:"
echo "================================================"
ROLEBINDING=$(oc get rolebinding -n $TARGET_NAMESPACE | grep "system:serviceaccounts:open-cluster-management" | head -1 | awk '{print $1}')
if [ -n "$ROLEBINDING" ]; then
    echo -e "${GREEN}✓ RoleBinding created: $ROLEBINDING${NC}"
    echo ""
    echo "Details:"
    oc describe rolebinding $ROLEBINDING -n $TARGET_NAMESPACE
else
    echo -e "${YELLOW}⚠ Could not find RoleBinding${NC}"
fi

echo ""
echo "================================================"
echo "Next Steps"
echo "================================================"
echo ""
echo "1. Create secrets in $TARGET_NAMESPACE namespace:"
echo "   oc create secret generic my-secret -n $TARGET_NAMESPACE \\"
echo "     --from-literal=username=admin \\"
echo "     --from-literal=password=secret123"
echo ""
echo "2. Reference in policies using fromSecret:"
echo "   stringData:"
echo "     password: '{{hub fromSecret \"$TARGET_NAMESPACE\" \"my-secret\" \"password\" hub}}'"
echo ""
echo "3. Or use copySecretData:"
echo "   copySecretData:"
echo "   - sourceNamespace: $TARGET_NAMESPACE"
echo "     sourceName: my-secret"
echo "     targetNamespace: production-apps"
echo "     targetName: my-secret"
echo ""
echo "✅ Setup complete!"


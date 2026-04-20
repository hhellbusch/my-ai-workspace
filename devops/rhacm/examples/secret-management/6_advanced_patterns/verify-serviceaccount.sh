#!/bin/bash

# Script to identify the correct ServiceAccount for Hub secret access
# Run this on the RHACM Hub cluster

set -euo pipefail

echo "================================================"
echo "RHACM ServiceAccount Verification"
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

# Get RHACM version
echo "📋 RHACM Version:"
RHACM_VERSION=$(oc get multiclusterhub -n open-cluster-management -o jsonpath='{.status.currentVersion}' 2>/dev/null || echo "Unknown")
echo "  Version: $RHACM_VERSION"
echo ""

# List governance-related deployments
echo "🔍 Governance Deployments:"
echo "================================================"
oc get deployment -n open-cluster-management | grep -E "NAME|governance|policy" || echo "No deployments found"
echo ""

# Check ServiceAccounts used by governance deployments
echo "👤 ServiceAccounts Used by Governance:"
echo "================================================"

DEPLOYMENTS=$(oc get deployment -n open-cluster-management -o name | grep -E "governance|policy" || true)

if [ -z "$DEPLOYMENTS" ]; then
    echo "No governance/policy deployments found"
else
    for deployment in $DEPLOYMENTS; do
        DEPLOY_NAME=$(echo $deployment | cut -d'/' -f2)
        SA_NAME=$(oc get deployment $DEPLOY_NAME -n open-cluster-management -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null || echo "default")
        echo -e "${BLUE}$DEPLOY_NAME${NC}"
        echo "  ServiceAccount: $SA_NAME"
        echo ""
    done
fi

# Show all ServiceAccounts in open-cluster-management
echo "📝 All ServiceAccounts in open-cluster-management (Hub cluster):"
echo "================================================"
oc get serviceaccount -n open-cluster-management | grep -E "NAME|governance|policy|propagator|framework" || echo "No relevant ServiceAccounts found"
echo ""
echo "Note: open-cluster-management-agent-addon namespace exists on MANAGED CLUSTERS,"
echo "      not on the Hub, and does not need Hub secret access."
echo ""

# Identify the most likely ServiceAccount for Hub secrets
echo "🎯 Likely ServiceAccount for Hub Secret Access:"
echo "================================================"

# Check for common names in open-cluster-management
LIKELY_SA=""
LIKELY_NAMESPACE="open-cluster-management"
for sa_name in "governance-policy-framework" "governance-policy-propagator" "policy-propagator" "governance-policy-addon-controller"; do
    if oc get serviceaccount $sa_name -n open-cluster-management &>/dev/null; then
        echo -e "${GREEN}✓ Found: $sa_name${NC}"
        LIKELY_SA=$sa_name
        break
    fi
done

if [ -z "$LIKELY_SA" ]; then
    echo -e "${YELLOW}⚠ Could not automatically determine ServiceAccount${NC}"
    echo "  Check the deployments listed above"
else
    echo ""
    echo "================================================"
    echo "Recommended RBAC Configuration"
    echo "================================================"
    echo ""
    echo "For a specific ServiceAccount:"
    echo ""
    cat <<EOF
# Grant access to specific ServiceAccount
oc adm policy add-role-to-user view \\
  system:serviceaccount:${LIKELY_NAMESPACE}:${LIKELY_SA} \\
  -n rhacm-secrets
EOF
    echo ""
    echo "Or using YAML:"
    echo ""
    cat <<EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rhacm-secret-reader-binding
  namespace: rhacm-secrets
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: ${LIKELY_SA}
  namespace: ${LIKELY_NAMESPACE}
EOF
fi

echo ""
echo "================================================"
echo "Universal Approach (Recommended)"
echo "================================================"
echo ""
echo "Grant access to all ServiceAccounts in open-cluster-management namespace:"
echo ""
cat <<'EOF'
# This works regardless of specific ServiceAccount names or RHACM version
# Only the Hub cluster's open-cluster-management namespace needs access
oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management \
  -n rhacm-secrets
EOF

echo ""
echo "================================================"
echo "Test Hub Secret Access"
echo "================================================"
echo ""
echo "1. Create a test secret:"
echo "   oc create secret generic test-secret -n rhacm-secrets --from-literal=key=value"
echo ""
echo "2. Create a test policy with fromSecret:"
echo "   (See test-hub-secret-policy.yaml)"
echo ""
echo "3. Check if policy can read the secret:"
echo "   oc get policy test-policy -n rhacm-policies -o yaml | grep -A 5 status"
echo ""
echo "✅ Verification complete!"


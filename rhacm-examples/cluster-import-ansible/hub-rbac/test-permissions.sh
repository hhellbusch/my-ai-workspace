#!/bin/bash
# Test service account permissions

set -e

KUBECONFIG_FILE="/tmp/cluster-importer-kubeconfig"

if [ ! -f ${KUBECONFIG_FILE} ]; then
    echo "❌ Error: Kubeconfig not found: ${KUBECONFIG_FILE}"
    echo "Run ./create-kubeconfig.sh first"
    exit 1
fi

export KUBECONFIG=${KUBECONFIG_FILE}

echo "=========================================="
echo "Testing Service Account Permissions"
echo "=========================================="
echo ""

# Test whoami
echo "1. Testing authentication..."
USER=$(oc whoami 2>&1)
if [[ $USER == *"serviceaccount"* ]]; then
    echo "   ✓ Authenticated as: ${USER}"
else
    echo "   ❌ Authentication failed: ${USER}"
    exit 1
fi
echo ""

# Test permissions
echo "2. Testing permissions..."
echo ""

# Should have permission
tests_pass=(
    "create managedcluster"
    "get managedcluster"
    "list managedcluster"
    "create namespace"
    "get secret"
    "list secret"
    "create klusterletaddonconfig"
)

# Should NOT have permission
tests_fail=(
    "delete managedcluster"
    "create deployment"
    "create pod"
    "delete namespace"
)

PASSED=0
FAILED=0

echo "   Expected to PASS:"
for test in "${tests_pass[@]}"; do
    if oc auth can-i ${test} &>/dev/null; then
        echo "   ✓ can-i ${test}"
        ((PASSED++))
    else
        echo "   ❌ can-i ${test} (SHOULD PASS)"
        ((FAILED++))
    fi
done

echo ""
echo "   Expected to FAIL (security):"
for test in "${tests_fail[@]}"; do
    if oc auth can-i ${test} &>/dev/null; then
        echo "   ❌ can-i ${test} (SHOULD FAIL)"
        ((FAILED++))
    else
        echo "   ✓ can-i ${test} (correctly denied)"
        ((PASSED++))
    fi
done

echo ""
echo "=========================================="
echo "Results: ${PASSED} passed, ${FAILED} failed"
echo "=========================================="

if [ ${FAILED} -eq 0 ]; then
    echo "✓ All permission tests passed"
    echo ""
    echo "Service account is ready to use for cluster imports"
    exit 0
else
    echo "❌ Some permission tests failed"
    echo ""
    echo "Check RBAC configuration:"
    echo "  oc get clusterrole cluster-importer"
    echo "  oc get clusterrolebinding cluster-importer"
    exit 1
fi

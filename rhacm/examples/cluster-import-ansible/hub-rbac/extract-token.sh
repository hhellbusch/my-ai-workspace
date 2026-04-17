#!/bin/bash
# Extract service account token for OpenShift 4.11+
# Uses TokenRequest API for time-limited tokens

set -e

SA_NAME="cluster-importer"
NAMESPACE="open-cluster-management"
TOKEN_DURATION="8760h"  # 1 year - adjust as needed

echo "=========================================="
echo "Extracting Service Account Token"
echo "=========================================="
echo "Service Account: ${SA_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Duration: ${TOKEN_DURATION}"
echo ""

# Check if service account exists
if ! oc get sa ${SA_NAME} -n ${NAMESPACE} &>/dev/null; then
    echo "❌ Error: ServiceAccount '${SA_NAME}' not found in namespace '${NAMESPACE}'"
    echo ""
    echo "Create it first:"
    echo "  oc apply -f serviceaccount.yaml"
    exit 1
fi

# Create token
echo "Generating token..."
TOKEN=$(oc create token ${SA_NAME} -n ${NAMESPACE} --duration=${TOKEN_DURATION})

if [ -z "$TOKEN" ]; then
    echo "❌ Error: Failed to generate token"
    exit 1
fi

# Save to file
OUTPUT_FILE="/tmp/cluster-importer-token.txt"
echo "$TOKEN" > ${OUTPUT_FILE}
chmod 600 ${OUTPUT_FILE}

echo ""
echo "✓ Token generated successfully"
echo ""
echo "Token (first 20 chars): ${TOKEN:0:20}..."
echo "Full token saved to: ${OUTPUT_FILE}"
echo ""
echo "Next steps:"
echo "1. Run ./create-kubeconfig.sh to generate kubeconfig"
echo "2. Update inventory/hosts.ini with kubeconfig path"
echo "3. Test permissions: export KUBECONFIG=/tmp/cluster-importer-kubeconfig && oc whoami"

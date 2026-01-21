#!/bin/bash

# Extract and use ManagedServiceAccount token
# Usage: ./extract-token.sh <msa-name> <cluster-name>

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <managed-service-account-name> <cluster-name>"
    echo ""
    echo "Example:"
    echo "  $0 cicd-pipeline prod-cluster-1"
    exit 1
fi

MSA_NAME=$1
CLUSTER_NAME=$2

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "ManagedServiceAccount Token Extractor"
echo "================================================"
echo ""

# Check if MSA exists
echo "🔍 Checking ManagedServiceAccount '$MSA_NAME' in cluster '$CLUSTER_NAME'..."
if ! oc get managedserviceaccount "$MSA_NAME" -n "$CLUSTER_NAME" &>/dev/null; then
    echo "❌ ManagedServiceAccount '$MSA_NAME' not found in namespace '$CLUSTER_NAME'"
    exit 1
fi

# Get token secret reference
echo -e "${GREEN}✓ ManagedServiceAccount found${NC}"
echo ""

echo "📦 Extracting token secret..."
SECRET_NAME=$(oc get managedserviceaccount "$MSA_NAME" \
  -n "$CLUSTER_NAME" \
  -o jsonpath='{.status.tokenSecretRef.name}' 2>/dev/null || echo "")

if [ -z "$SECRET_NAME" ]; then
    echo "❌ Token secret not ready yet. Wait a few seconds and try again."
    echo ""
    echo "Check status with:"
    echo "  oc get managedserviceaccount $MSA_NAME -n $CLUSTER_NAME -o yaml"
    exit 1
fi

echo -e "${GREEN}✓ Token secret: $SECRET_NAME${NC}"
echo ""

# Extract token
echo "🔑 Extracting token..."
TOKEN=$(oc get secret "$SECRET_NAME" \
  -n "$CLUSTER_NAME" \
  -o jsonpath='{.data.token}' | base64 -d)

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to extract token from secret"
    exit 1
fi

echo -e "${GREEN}✓ Token extracted successfully${NC}"
echo ""

# Get cluster API endpoint
echo "🌐 Getting cluster API endpoint..."
CLUSTER_API=$(oc get managedcluster "$CLUSTER_NAME" \
  -o jsonpath='{.spec.managedClusterClientConfigs[0].url}' 2>/dev/null || echo "")

if [ -z "$CLUSTER_API" ]; then
    echo -e "${YELLOW}⚠ Could not get cluster API endpoint${NC}"
    echo ""
    echo "Token (save to environment variable):"
    echo "================================================"
    echo "$TOKEN"
    echo "================================================"
    exit 0
fi

echo -e "${GREEN}✓ Cluster API: $CLUSTER_API${NC}"
echo ""

# Test token
echo "🧪 Testing token authentication..."
if oc --token="$TOKEN" \
      --server="$CLUSTER_API" \
      --insecure-skip-tls-verify=true \
      auth can-i get nodes &>/dev/null; then
    echo -e "${GREEN}✓ Token authentication successful${NC}"
else
    echo -e "${YELLOW}⚠ Token authentication succeeded but you may not have 'get nodes' permission${NC}"
fi

echo ""
echo "================================================"
echo "Usage Examples"
echo "================================================"
echo ""
echo "# Export token as environment variable:"
echo "export CLUSTER_TOKEN='$TOKEN'"
echo ""
echo "# Export cluster API:"
echo "export CLUSTER_API='$CLUSTER_API'"
echo ""
echo "# Use with oc command:"
echo "oc --token=\"\$CLUSTER_TOKEN\" --server=\"\$CLUSTER_API\" --insecure-skip-tls-verify=true get nodes"
echo ""
echo "# Create kubeconfig entry:"
echo "oc login --token=\"\$CLUSTER_TOKEN\" --server=\"\$CLUSTER_API\" --insecure-skip-tls-verify=true"
echo ""
echo "# Test permissions:"
echo "oc --token=\"\$CLUSTER_TOKEN\" --server=\"\$CLUSTER_API\" --insecure-skip-tls-verify=true auth can-i --list"
echo ""
echo "================================================"
echo ""

# Offer to test a command
echo "Would you like to test the token now? (y/n)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Testing: oc get nodes"
    echo "================================================"
    oc --token="$TOKEN" \
       --server="$CLUSTER_API" \
       --insecure-skip-tls-verify=true \
       get nodes
    echo ""
    
    echo "Testing: oc auth can-i --list"
    echo "================================================"
    oc --token="$TOKEN" \
       --server="$CLUSTER_API" \
       --insecure-skip-tls-verify=true \
       auth can-i --list | head -20
    echo "(output truncated...)"
fi

echo ""
echo "✅ Complete!"


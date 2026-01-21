#!/bin/bash
################################################################################
# Approve CSRs for Specific Node
################################################################################
# Approves only CSRs from a specified node
#
# Usage: ./approve-by-node.sh <node-name>
#
# Example: ./approve-by-node.sh master-1
#
# Requirements:
#   - oc CLI installed and configured
#   - jq installed
#   - Cluster admin or certificates approver role
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 <node-name>"
    echo "Example: $0 master-1"
    exit 1
fi

NODE_NAME="$1"

echo -e "${BLUE}=== CSR Approval for Node: $NODE_NAME ===${NC}"
echo ""

# Check if logged in
if ! oc whoami &>/dev/null; then
    echo -e "${RED}Error: Not logged into OpenShift cluster${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Logged in as: $(oc whoami)"

# Check if node exists
if ! oc get node "$NODE_NAME" &>/dev/null; then
    echo -e "${YELLOW}Warning: Node '$NODE_NAME' not found in cluster${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} Node '$NODE_NAME' found in cluster"
    oc get node "$NODE_NAME" -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type,ROLE:.metadata.labels.node-role\\.kubernetes\\.io/*
fi

echo ""

# Get pending CSRs for this node
echo "Checking for pending CSRs from $NODE_NAME..."

if ! command -v jq &>/dev/null; then
    echo -e "${YELLOW}Warning: jq not found, using basic filtering${NC}"
    PENDING_CSRS=$(oc get csr -o go-template='{{range .items}}{{if not .status}}{{if eq .spec.username (printf "system:node:%s" "'$NODE_NAME'")}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}{{end}}')
else
    PENDING_CSRS=$(oc get csr -o json | jq -r --arg node "system:node:$NODE_NAME" '.items[] | select(.status == {}) | select(.spec.username == $node) | .metadata.name')
fi

if [ -z "$PENDING_CSRS" ]; then
    echo -e "${GREEN}✓${NC} No pending CSRs found for $NODE_NAME"
    
    # Show if there are any approved CSRs for this node
    echo ""
    echo "Recent CSRs for $NODE_NAME:"
    oc get csr | grep "$NODE_NAME" | head -5 || echo "  No CSRs found"
    exit 0
fi

# Count and display
CSR_COUNT=$(echo "$PENDING_CSRS" | wc -l)
echo -e "${YELLOW}Found $CSR_COUNT pending CSR(s) for $NODE_NAME${NC}"
echo ""

# Display details
echo "CSR details:"
echo "$PENDING_CSRS" | while read csr; do
    SIGNER=$(oc get csr $csr -o jsonpath='{.spec.signerName}' 2>/dev/null || echo "unknown")
    AGE=$(oc get csr $csr -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null || echo "unknown")
    echo "  Name: $csr"
    echo "    Signer: $signer"
    echo "    Age: $AGE"
    echo ""
done

# Prompt for confirmation
read -p "Approve all $CSR_COUNT CSRs for $NODE_NAME? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Approve CSRs
echo ""
echo "Approving CSRs..."
echo "$PENDING_CSRS" | xargs --no-run-if-empty oc adm certificate approve

echo ""
echo -e "${GREEN}✓${NC} Approval complete"
echo ""
echo "Verification:"
oc get csr | grep "$NODE_NAME" | head -10













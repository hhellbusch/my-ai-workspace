#!/bin/bash
################################################################################
# Approve All Pending CSRs
################################################################################
# Approves all CSRs that are in Pending state (no status field)
#
# Usage: ./approve-all-pending.sh
#
# Requirements:
#   - oc CLI installed and configured
#   - Cluster admin or certificates approver role
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== CSR Approval Tool ===${NC}"
echo ""

# Check if logged in
if ! oc whoami &>/dev/null; then
    echo -e "${RED}Error: Not logged into OpenShift cluster${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Logged in as: $(oc whoami)"
echo ""

# Get pending CSRs
echo "Checking for pending CSRs..."
PENDING_CSRS=$(oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}')

if [ -z "$PENDING_CSRS" ]; then
    echo -e "${GREEN}✓${NC} No pending CSRs found"
    exit 0
fi

# Count pending CSRs
CSR_COUNT=$(echo "$PENDING_CSRS" | wc -l)
echo -e "${YELLOW}Found $CSR_COUNT pending CSR(s)${NC}"
echo ""

# Display pending CSRs with details
echo "Pending CSRs:"
echo "$PENDING_CSRS" | while read csr; do
    REQUESTOR=$(oc get csr $csr -o jsonpath='{.spec.username}' 2>/dev/null || echo "unknown")
    AGE=$(oc get csr $csr -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null || echo "unknown")
    echo "  - $csr (requestor: $REQUESTOR, created: $AGE)"
done
echo ""

# Prompt for confirmation
read -p "Approve all $CSR_COUNT CSRs? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Approve CSRs
echo ""
echo "Approving CSRs..."
APPROVED=0
FAILED=0

echo "$PENDING_CSRS" | while read csr; do
    if oc adm certificate approve "$csr" &>/dev/null; then
        echo -e "${GREEN}✓${NC} Approved: $csr"
        ((APPROVED++)) || true
    else
        echo -e "${RED}✗${NC} Failed: $csr"
        ((FAILED++)) || true
    fi
done

echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo "Approved: $APPROVED"
if [ $FAILED -gt 0 ]; then
    echo -e "${YELLOW}Failed: $FAILED${NC}"
fi
echo ""
echo "Current CSR status:"
oc get csr | head -10









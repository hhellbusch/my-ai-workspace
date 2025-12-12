#!/bin/bash
################################################################################
# Watch and Auto-Approve CSRs
################################################################################
# Continuously monitors for pending CSRs and approves them automatically
#
# Usage: ./watch-and-approve.sh [interval]
#
# Arguments:
#   interval - Check interval in seconds (default: 30)
#
# Example: ./watch-and-approve.sh 60
#
# Press Ctrl+C to stop
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

# Default interval
INTERVAL=${1:-30}

# Validate interval
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]]; then
    echo "Error: Interval must be a number"
    exit 1
fi

echo -e "${BLUE}=== CSR Auto-Approval Monitor ===${NC}"
echo ""
echo "Settings:"
echo "  Check interval: ${INTERVAL}s"
echo "  Press Ctrl+C to stop"
echo ""

# Check if logged in
if ! oc whoami &>/dev/null; then
    echo -e "${RED}Error: Not logged into OpenShift cluster${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Logged in as: $(oc whoami)"
echo -e "${GREEN}✓${NC} Cluster: $(oc whoami --show-server)"
echo ""

# Trap Ctrl+C
trap 'echo ""; echo "Stopped"; exit 0' INT TERM

# Statistics
TOTAL_APPROVED=0
CYCLE=0

# Main loop
while true; do
    ((CYCLE++))
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get pending CSRs
    PENDING_CSRS=$(oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' 2>/dev/null || true)
    
    if [ -n "$PENDING_CSRS" ]; then
        CSR_COUNT=$(echo "$PENDING_CSRS" | wc -l)
        echo -e "${YELLOW}[$TIMESTAMP] Cycle $CYCLE: Found $CSR_COUNT pending CSR(s)${NC}"
        
        # Show CSR details
        echo "$PENDING_CSRS" | while read csr; do
            REQUESTOR=$(oc get csr $csr -o jsonpath='{.spec.username}' 2>/dev/null || echo "unknown")
            echo "  - $csr (requestor: $REQUESTOR)"
        done
        
        # Approve
        echo "  Approving..."
        APPROVED_NOW=0
        echo "$PENDING_CSRS" | while read csr; do
            if oc adm certificate approve "$csr" &>/dev/null; then
                ((APPROVED_NOW++)) || true
                ((TOTAL_APPROVED++)) || true
            fi
        done
        
        echo -e "${GREEN}  ✓ Approved $APPROVED_NOW CSR(s)${NC}"
        echo -e "${BLUE}  Total approved this session: $TOTAL_APPROVED${NC}"
    else
        echo "[$TIMESTAMP] Cycle $CYCLE: No pending CSRs (total approved: $TOTAL_APPROVED)"
    fi
    
    # Wait for next cycle
    sleep "$INTERVAL"
done









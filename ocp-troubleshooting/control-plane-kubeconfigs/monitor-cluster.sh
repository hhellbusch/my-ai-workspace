#!/bin/bash
# Cluster Operator Monitoring Script
# Usage: ./monitor-cluster.sh [refresh_interval_seconds]
# Default refresh interval: 5 seconds

REFRESH_INTERVAL=${1:-5}
KUBECONFIG_PATH="/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Export kubeconfig
export KUBECONFIG="${KUBECONFIG_PATH}"

# Check if kubeconfig exists
if [ ! -f "${KUBECONFIG_PATH}" ]; then
    echo -e "${RED}ERROR: Kubeconfig not found at ${KUBECONFIG_PATH}${NC}"
    echo "Are you running this on a control plane node?"
    exit 1
fi

# Check if oc command is available
if ! command -v oc &> /dev/null; then
    echo -e "${RED}ERROR: oc command not found${NC}"
    echo "This script requires the oc CLI to be available"
    exit 1
fi

# Function to check API server health
check_api_health() {
    local health_status=$(curl -k -s https://localhost:6443/healthz 2>/dev/null)
    if [ "$health_status" = "ok" ]; then
        echo -e "${GREEN}✓ API Server Healthy${NC}"
        return 0
    else
        echo -e "${RED}✗ API Server Not Healthy${NC}"
        return 1
    fi
}

# Function to count operator status
count_operators() {
    local available=$(oc get co -o json 2>/dev/null | jq -r '[.items[].status.conditions[] | select(.type=="Available" and .status=="True")] | length')
    local degraded=$(oc get co -o json 2>/dev/null | jq -r '[.items[].status.conditions[] | select(.type=="Degraded" and .status=="True")] | length')
    local progressing=$(oc get co -o json 2>/dev/null | jq -r '[.items[].status.conditions[] | select(.type=="Progressing" and .status=="True")] | length')
    local total=$(oc get co -o json 2>/dev/null | jq -r '.items | length')
    
    echo -e "${GREEN}Available: ${available}/${total}${NC} | ${RED}Degraded: ${degraded}${NC} | ${YELLOW}Progressing: ${progressing}${NC}"
}

# Function to display problematic operators
show_problematic_operators() {
    local problematic=$(oc get co -o json 2>/dev/null | jq -r '.items[] | select(.status.conditions[] | select((.type=="Available" and .status=="False") or (.type=="Degraded" and .status=="True"))) | .metadata.name' | sort -u)
    
    if [ -z "$problematic" ]; then
        echo -e "${GREEN}No problematic operators found${NC}"
    else
        echo -e "${RED}Problematic Operators:${NC}"
        echo "$problematic" | while read -r op; do
            echo -e "  ${RED}✗${NC} $op"
        done
    fi
}

# Main monitoring loop
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}OpenShift Cluster Operator Monitor${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "Refresh Interval: ${REFRESH_INTERVAL} seconds"
echo -e "Press Ctrl+C to exit"
echo -e "${BLUE}======================================${NC}\n"

while true; do
    clear
    echo -e "${BLUE}=== Cluster Monitoring - $(date) ===${NC}\n"
    
    # Check API Server
    check_api_health
    echo ""
    
    # Show operator summary
    echo -e "${BLUE}=== Operator Summary ===${NC}"
    count_operators
    echo ""
    
    # Show all operators
    echo -e "${BLUE}=== All Cluster Operators ===${NC}"
    oc get co 2>/dev/null || echo -e "${RED}Failed to get cluster operators${NC}"
    echo ""
    
    # Show problematic operators
    echo -e "${BLUE}=== Problematic Operators ===${NC}"
    show_problematic_operators
    echo ""
    
    # Show nodes
    echo -e "${BLUE}=== Nodes ===${NC}"
    oc get nodes 2>/dev/null || echo -e "${RED}Failed to get nodes${NC}"
    echo ""
    
    # Show cluster version
    echo -e "${BLUE}=== Cluster Version ===${NC}"
    oc get clusterversion 2>/dev/null || echo -e "${RED}Failed to get cluster version${NC}"
    echo ""
    
    echo -e "${BLUE}======================================${NC}"
    echo -e "Next refresh in ${REFRESH_INTERVAL} seconds..."
    
    sleep "$REFRESH_INTERVAL"
done


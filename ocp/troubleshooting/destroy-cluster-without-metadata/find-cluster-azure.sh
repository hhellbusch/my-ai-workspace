#!/bin/bash
# find-cluster-azure.sh - Find OpenShift cluster resources in Azure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SEARCH_TERM="${1:-}"

usage() {
    cat <<EOF
Usage: $0 <search-term>

Find OpenShift cluster resources in Azure by resource group name or keyword.

Arguments:
    search-term    Resource group name or keyword to search for (required)

Examples:
    $0 my-ocp-cluster-rg
    $0 production
    $0 cluster-abc

Environment Variables:
    AZURE_SUBSCRIPTION_ID    Azure subscription ID (optional, uses default)

Output:
    - Lists all resource groups matching the search term
    - Shows resources in each group
    - Provides resource counts
    - Generates cleanup commands
EOF
}

if [ -z "$SEARCH_TERM" ]; then
    usage
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Azure OpenShift Cluster Resource Finder${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Search Term: ${YELLOW}$SEARCH_TERM${NC}"
echo ""

# Check Azure CLI availability
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found. Please install it first.${NC}"
    echo "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check Azure login status
if ! az account show &>/dev/null; then
    echo -e "${RED}❌ Not logged in to Azure${NC}"
    echo "Run: az login"
    exit 1
fi

SUBSCRIPTION=$(az account show --query name --output tsv)
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

echo -e "Subscription:  ${YELLOW}$SUBSCRIPTION${NC}"
echo -e "Sub ID:        ${YELLOW}$SUBSCRIPTION_ID${NC}"
echo ""
echo -e "${GREEN}✓ Azure credentials valid${NC}"
echo ""

echo -e "${BLUE}🔍 Searching for resource groups...${NC}"
echo ""

# ============================================================================
# RESOURCE GROUPS
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Resource Groups${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

RESOURCE_GROUPS=$(az group list \
    --query "[?contains(name, '${SEARCH_TERM}')].[name,location,properties.provisioningState]" \
    --output tsv 2>/dev/null || echo "")

if [ -z "$RESOURCE_GROUPS" ]; then
    echo -e "${YELLOW}⚠️  No resource groups found matching '$SEARCH_TERM'${NC}"
    echo ""
    echo "All resource groups:"
    az group list --query "[].name" --output table
    echo ""
    echo "Suggestions:"
    echo "  1. Try a different search term"
    echo "  2. Check if you're in the correct subscription"
    echo "  3. Verify Azure credentials have proper permissions"
    exit 1
fi

echo "$RESOURCE_GROUPS" | column -t
RG_COUNT=$(echo "$RESOURCE_GROUPS" | wc -l)
echo ""
echo -e "${GREEN}Found: $RG_COUNT resource group(s)${NC}"
echo ""

# ============================================================================
# RESOURCES IN EACH GROUP
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Resources by Group${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

TOTAL_RESOURCES=0
declare -A RESOURCE_COUNTS

while IFS=$'\t' read -r RG_NAME RG_LOCATION RG_STATE; do
    echo -e "${BLUE}=== Resource Group: $RG_NAME ===${NC}"
    echo -e "Location: $RG_LOCATION | State: $RG_STATE"
    echo ""
    
    # Get resources in this group
    RESOURCES=$(az resource list \
        --resource-group "$RG_NAME" \
        --query "[].{Name:name, Type:type, Location:location}" \
        --output json 2>/dev/null || echo "[]")
    
    RESOURCE_COUNT=$(echo "$RESOURCES" | jq '. | length')
    TOTAL_RESOURCES=$((TOTAL_RESOURCES + RESOURCE_COUNT))
    
    if [ "$RESOURCE_COUNT" -gt 0 ]; then
        echo "$RESOURCES" | jq -r '.[] | "\(.Type)\t\(.Name)\t\(.Location)"' | column -t -s $'\t'
        
        # Count by type
        echo ""
        echo "Resource counts by type:"
        echo "$RESOURCES" | jq -r '.[].Type' | sort | uniq -c | sort -rn
    else
        echo -e "${YELLOW}(empty)${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}Resources in this group: $RESOURCE_COUNT${NC}"
    echo ""
    echo "────────────────────────────────────────"
    echo ""
    
done <<< "$RESOURCE_GROUPS"

# ============================================================================
# SPECIFIC RESOURCE TYPES
# ============================================================================
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Virtual Machines${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

while IFS=$'\t' read -r RG_NAME _rest; do
    VMS=$(az vm list \
        --resource-group "$RG_NAME" \
        --query "[].{Name:name, Size:hardwareProfile.vmSize, State:provisioningState, Location:location}" \
        --output json 2>/dev/null || echo "[]")
    
    VM_COUNT=$(echo "$VMS" | jq '. | length')
    
    if [ "$VM_COUNT" -gt 0 ]; then
        echo -e "${BLUE}Resource Group: $RG_NAME${NC}"
        echo "$VMS" | jq -r '.[] | "\(.Name)\t\(.Size)\t\(.State)\t\(.Location)"' | column -t -s $'\t'
        echo ""
    fi
done <<< "$RESOURCE_GROUPS"

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Load Balancers${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

while IFS=$'\t' read -r RG_NAME _rest; do
    LBS=$(az network lb list \
        --resource-group "$RG_NAME" \
        --query "[].{Name:name, Location:location, SKU:sku.name}" \
        --output json 2>/dev/null || echo "[]")
    
    LB_COUNT=$(echo "$LBS" | jq '. | length')
    
    if [ "$LB_COUNT" -gt 0 ]; then
        echo -e "${BLUE}Resource Group: $RG_NAME${NC}"
        echo "$LBS" | jq -r '.[] | "\(.Name)\t\(.SKU)\t\(.Location)"' | column -t -s $'\t'
        echo ""
    fi
done <<< "$RESOURCE_GROUPS"

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Virtual Networks${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

while IFS=$'\t' read -r RG_NAME _rest; do
    VNETS=$(az network vnet list \
        --resource-group "$RG_NAME" \
        --query "[].{Name:name, Location:location, AddressSpace:addressSpace.addressPrefixes[0]}" \
        --output json 2>/dev/null || echo "[]")
    
    VNET_COUNT=$(echo "$VNETS" | jq '. | length')
    
    if [ "$VNET_COUNT" -gt 0 ]; then
        echo -e "${BLUE}Resource Group: $RG_NAME${NC}"
        echo "$VNETS" | jq -r '.[] | "\(.Name)\t\(.AddressSpace)\t\(.Location)"' | column -t -s $'\t'
        echo ""
    fi
done <<< "$RESOURCE_GROUPS"

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Storage Accounts${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

while IFS=$'\t' read -r RG_NAME _rest; do
    STORAGE=$(az storage account list \
        --resource-group "$RG_NAME" \
        --query "[].{Name:name, Location:location, SKU:sku.name, Kind:kind}" \
        --output json 2>/dev/null || echo "[]")
    
    STORAGE_COUNT=$(echo "$STORAGE" | jq '. | length')
    
    if [ "$STORAGE_COUNT" -gt 0 ]; then
        echo -e "${BLUE}Resource Group: $RG_NAME${NC}"
        echo "$STORAGE" | jq -r '.[] | "\(.Name)\t\(.SKU)\t\(.Kind)\t\(.Location)"' | column -t -s $'\t'
        echo ""
    fi
done <<< "$RESOURCE_GROUPS"

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Search Term:         ${YELLOW}$SEARCH_TERM${NC}"
echo -e "Subscription:        ${YELLOW}$SUBSCRIPTION${NC}"
echo ""
echo -e "Resource Groups:     ${GREEN}$RG_COUNT${NC}"
echo -e "Total Resources:     ${GREEN}$TOTAL_RESOURCES${NC}"
echo ""

# ============================================================================
# COST ESTIMATE
# ============================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}COST INFORMATION${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Try to get actual cost data (requires appropriate permissions)
START_DATE=$(date -d '30 days ago' +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d 2>/dev/null || echo "")
END_DATE=$(date +%Y-%m-%d)

if [ -n "$START_DATE" ]; then
    echo "Attempting to fetch actual costs (last 30 days)..."
    
    while IFS=$'\t' read -r RG_NAME _rest; do
        # Note: This requires Microsoft.Consumption permissions
        COST=$(az consumption usage list \
            --start-date "$START_DATE" \
            --end-date "$END_DATE" \
            2>/dev/null | jq "[.[] | select(.instanceName | contains(\"$RG_NAME\"))] | length" 2>/dev/null || echo "0")
        
        if [ "$COST" != "0" ]; then
            echo "Resource Group: $RG_NAME has $COST usage records"
        fi
    done <<< "$RESOURCE_GROUPS"
fi

echo ""
echo -e "${YELLOW}⚠️  For accurate costs, check Azure Cost Management:${NC}"
echo "https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/costanalysis"
echo ""

# ============================================================================
# NEXT STEPS
# ============================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NEXT STEPS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "To delete these resources, run:"
echo ""

while IFS=$'\t' read -r RG_NAME _rest; do
    echo -e "  ${GREEN}./cleanup-azure-cluster.sh $RG_NAME${NC}"
done <<< "$RESOURCE_GROUPS"

echo ""
echo "Or delete manually:"
echo ""

while IFS=$'\t' read -r RG_NAME _rest; do
    echo "az group delete --name $RG_NAME --yes --no-wait"
done <<< "$RESOURCE_GROUPS"

echo ""
echo -e "${YELLOW}⚠️  WARNING: Deletion is irreversible. Review resources carefully!${NC}"
echo ""

# Save results to file
OUTPUT_FILE="/tmp/azure-cluster-${SEARCH_TERM}-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "Azure Cluster Resources: $SEARCH_TERM"
    echo "Subscription: $SUBSCRIPTION"
    echo "Date: $(date)"
    echo ""
    echo "=== RESOURCE GROUPS ==="
    echo "$RESOURCE_GROUPS"
    echo ""
    echo "=== TOTAL RESOURCES ==="
    echo "Count: $TOTAL_RESOURCES"
} > "$OUTPUT_FILE"

echo -e "📄 Results saved to: ${BLUE}$OUTPUT_FILE${NC}"
echo ""








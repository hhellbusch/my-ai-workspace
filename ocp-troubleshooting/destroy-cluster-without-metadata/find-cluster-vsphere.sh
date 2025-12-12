#!/bin/bash
# find-cluster-vsphere.sh - Find OpenShift cluster resources in vSphere

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SEARCH_TERM="${1:-}"
GOVC="${GOVC:-govc}"

usage() {
    cat <<EOF
Usage: $0 <search-term>

Find OpenShift cluster resources in vSphere by cluster name or keyword.

Arguments:
    search-term    Cluster name or keyword to search for (required)

Prerequisites:
    - govc CLI tool installed (https://github.com/vmware/govmomi/tree/master/govc)
    - vSphere environment variables set:
      export GOVC_URL='vcenter.example.com'
      export GOVC_USERNAME='administrator@vsphere.local'
      export GOVC_PASSWORD='password'
      export GOVC_INSECURE=1  # If using self-signed cert

Examples:
    $0 my-ocp-cluster
    $0 production
    $0 cluster-abc

Output:
    - Lists all VMs matching the search term
    - Shows folders and resource pools
    - Provides storage information
    - Generates cleanup commands
EOF
}

if [ -z "$SEARCH_TERM" ]; then
    usage
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}vSphere OpenShift Cluster Resource Finder${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Search Term: ${YELLOW}$SEARCH_TERM${NC}"
echo ""

# Check govc availability
if ! command -v "$GOVC" &> /dev/null; then
    echo -e "${RED}❌ govc CLI not found${NC}"
    echo ""
    echo "Install govc:"
    echo "  # On Linux:"
    echo "  curl -L -o - 'https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz' | tar -C /usr/local/bin -xvzf - govc"
    echo ""
    echo "  # On macOS:"
    echo "  brew install govmomi/tap/govc"
    echo ""
    exit 1
fi

# Check vSphere connection
if ! $GOVC about &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to vSphere${NC}"
    echo ""
    echo "Set environment variables:"
    echo "  export GOVC_URL='vcenter.example.com'"
    echo "  export GOVC_USERNAME='administrator@vsphere.local'"
    echo "  export GOVC_PASSWORD='password'"
    echo "  export GOVC_INSECURE=1  # If using self-signed cert"
    echo ""
    exit 1
fi

VCENTER_INFO=$($GOVC about)
echo -e "${GREEN}✓ Connected to vSphere${NC}"
echo "$VCENTER_INFO" | grep -E "(Name|Version|Build)"
echo ""

echo -e "${BLUE}🔍 Searching for resources...${NC}"
echo ""

# Initialize counters
VM_COUNT=0
FOLDER_COUNT=0
RP_COUNT=0

# ============================================================================
# VIRTUAL MACHINES
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Virtual Machines${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

VMS=$($GOVC find / -type m -name "*${SEARCH_TERM}*" 2>/dev/null || echo "")

if [ -n "$VMS" ]; then
    echo "$VMS" | while read vm; do
        VM_COUNT=$((VM_COUNT + 1))
        
        # Get VM details
        VM_INFO=$($GOVC vm.info "$vm" 2>/dev/null || echo "")
        
        VM_NAME=$(echo "$VM_INFO" | grep "Name:" | awk '{print $2}')
        VM_STATE=$(echo "$VM_INFO" | grep "State:" | awk '{print $2}')
        VM_CPU=$(echo "$VM_INFO" | grep "CPU:" | awk '{print $2}')
        VM_MEM=$(echo "$VM_INFO" | grep "Memory:" | awk '{print $2$3}')
        VM_IP=$(echo "$VM_INFO" | grep "IP address:" | awk '{print $3}')
        
        echo "  $vm"
        echo "    State: $VM_STATE | CPU: $VM_CPU | Memory: $VM_MEM | IP: $VM_IP"
    done
    
    VM_COUNT=$(echo "$VMS" | wc -l)
    echo ""
    echo -e "${GREEN}Found: $VM_COUNT virtual machines${NC}"
else
    echo -e "${YELLOW}No virtual machines found${NC}"
fi
echo ""

# ============================================================================
# FOLDERS
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Folders${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

FOLDERS=$($GOVC find / -type f -name "*${SEARCH_TERM}*" 2>/dev/null || echo "")

if [ -n "$FOLDERS" ]; then
    echo "$FOLDERS" | while read folder; do
        FOLDER_COUNT=$((FOLDER_COUNT + 1))
        echo "  $folder"
        
        # Count items in folder
        ITEMS=$($GOVC ls "$folder" 2>/dev/null | wc -l)
        echo "    Items: $ITEMS"
    done
    
    FOLDER_COUNT=$(echo "$FOLDERS" | wc -l)
    echo ""
    echo -e "${GREEN}Found: $FOLDER_COUNT folders${NC}"
else
    echo -e "${YELLOW}No folders found${NC}"
fi
echo ""

# ============================================================================
# RESOURCE POOLS
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Resource Pools${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

RESOURCE_POOLS=$($GOVC find / -type p -name "*${SEARCH_TERM}*" 2>/dev/null || echo "")

if [ -n "$RESOURCE_POOLS" ]; then
    echo "$RESOURCE_POOLS" | while read rp; do
        RP_COUNT=$((RP_COUNT + 1))
        echo "  $rp"
        
        # Get resource pool info
        RP_INFO=$($GOVC pool.info "$rp" 2>/dev/null || echo "")
        CPU_USAGE=$(echo "$RP_INFO" | grep "CPU Usage:" | awk '{print $3}')
        MEM_USAGE=$(echo "$RP_INFO" | grep "Memory Usage:" | awk '{print $3}')
        
        echo "    CPU Usage: $CPU_USAGE | Memory Usage: $MEM_USAGE"
    done
    
    RP_COUNT=$(echo "$RESOURCE_POOLS" | wc -l)
    echo ""
    echo -e "${GREEN}Found: $RP_COUNT resource pools${NC}"
else
    echo -e "${YELLOW}No resource pools found${NC}"
fi
echo ""

# ============================================================================
# DATASTORES & STORAGE
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Storage Usage${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -n "$VMS" ]; then
    TOTAL_STORAGE=0
    
    echo "$VMS" | while read vm; do
        # Get VM disk info
        DISK_INFO=$($GOVC vm.info -json "$vm" 2>/dev/null | jq -r '.VirtualMachines[0].Config.Hardware.Device[] | select(.Backing.FileName != null) | .Backing.FileName' 2>/dev/null || echo "")
        
        if [ -n "$DISK_INFO" ]; then
            VM_NAME=$(basename "$vm")
            echo "  $VM_NAME:"
            echo "$DISK_INFO" | while read disk; do
                echo "    $disk"
            done
        fi
    done
    echo ""
else
    echo -e "${YELLOW}No storage information available${NC}"
    echo ""
fi

# ============================================================================
# NETWORKS
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Network Assignments${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -n "$VMS" ]; then
    echo "$VMS" | while read vm; do
        VM_NAME=$(basename "$vm")
        NETWORKS=$($GOVC vm.info -json "$vm" 2>/dev/null | jq -r '.VirtualMachines[0].Guest.Net[].Network' 2>/dev/null || echo "")
        
        if [ -n "$NETWORKS" ]; then
            echo "  $VM_NAME:"
            echo "$NETWORKS" | while read net; do
                echo "    $net"
            done
        fi
    done
    echo ""
else
    echo -e "${YELLOW}No network information available${NC}"
    echo ""
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Search Term:       ${YELLOW}$SEARCH_TERM${NC}"
echo -e "vCenter:           ${YELLOW}$GOVC_URL${NC}"
echo ""
echo -e "Virtual Machines:  ${GREEN}$VM_COUNT${NC}"
echo -e "Folders:           ${GREEN}$FOLDER_COUNT${NC}"
echo -e "Resource Pools:    ${GREEN}$RP_COUNT${NC}"
echo ""

TOTAL_RESOURCES=$((VM_COUNT + FOLDER_COUNT + RP_COUNT))

if [ $TOTAL_RESOURCES -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No resources found matching '$SEARCH_TERM'${NC}"
    echo ""
    echo "Suggestions:"
    echo "  1. Try a different search term or cluster name"
    echo "  2. Verify vSphere credentials have proper permissions"
    echo "  3. Check if resources are in a different datacenter"
    echo ""
    echo "List all VMs:"
    echo "  $GOVC find / -type m"
    exit 1
fi

echo -e "${GREEN}✓ Total resources found: $TOTAL_RESOURCES${NC}"
echo ""

# ============================================================================
# DETAILED VM INFO
# ============================================================================
if [ $VM_COUNT -gt 0 ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}DETAILED VM INFORMATION${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    echo "$VMS" | while read vm; do
        echo -e "${YELLOW}VM: $vm${NC}"
        $GOVC vm.info "$vm" 2>/dev/null | grep -E "(Name|Path|UUID|State|CPU|Memory|IP|Boot|Guest|OS)"
        echo ""
    done
fi

# ============================================================================
# POWER STATE SUMMARY
# ============================================================================
if [ $VM_COUNT -gt 0 ]; then
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}POWER STATE SUMMARY${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    POWERED_ON=0
    POWERED_OFF=0
    SUSPENDED=0
    
    echo "$VMS" | while read vm; do
        STATE=$($GOVC vm.info "$vm" 2>/dev/null | grep "State:" | awk '{print $2}')
        case "$STATE" in
            poweredOn)
                echo "🟢 $vm"
                ;;
            poweredOff)
                echo "🔴 $vm"
                ;;
            suspended)
                echo "🟡 $vm"
                ;;
            *)
                echo "⚪ $vm (unknown)"
                ;;
        esac
    done
    echo ""
fi

# ============================================================================
# NEXT STEPS
# ============================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NEXT STEPS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "To delete these resources, run:"
echo ""
echo -e "  ${GREEN}./cleanup-vsphere-cluster.sh $SEARCH_TERM${NC}"
echo ""
echo "Or manually with govc:"
echo ""
echo "# Power off all VMs:"
if [ -n "$VMS" ]; then
    echo "$VMS" | while read vm; do
        echo "$GOVC vm.power -off \"$vm\""
    done
fi
echo ""
echo "# Delete all VMs:"
if [ -n "$VMS" ]; then
    echo "$VMS" | while read vm; do
        echo "$GOVC vm.destroy \"$vm\""
    done
fi
echo ""
echo "# Delete folders:"
if [ -n "$FOLDERS" ]; then
    echo "$FOLDERS" | while read folder; do
        echo "$GOVC object.destroy \"$folder\""
    done
fi
echo ""
echo "# Delete resource pools:"
if [ -n "$RESOURCE_POOLS" ]; then
    echo "$RESOURCE_POOLS" | while read rp; do
        echo "$GOVC pool.destroy \"$rp\""
    done
fi
echo ""
echo -e "${YELLOW}⚠️  WARNING: Deletion is irreversible. Review resources carefully!${NC}"
echo ""

# Save results to file
OUTPUT_FILE="/tmp/vsphere-cluster-${SEARCH_TERM}-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "vSphere Cluster Resources: $SEARCH_TERM"
    echo "vCenter: $GOVC_URL"
    echo "Date: $(date)"
    echo ""
    echo "=== VIRTUAL MACHINES ==="
    echo "$VMS"
    echo ""
    echo "=== FOLDERS ==="
    echo "$FOLDERS"
    echo ""
    echo "=== RESOURCE POOLS ==="
    echo "$RESOURCE_POOLS"
    echo ""
    
    if [ -n "$VMS" ]; then
        echo "=== VM DETAILS ==="
        echo "$VMS" | while read vm; do
            echo "--- $vm ---"
            $GOVC vm.info "$vm" 2>/dev/null
            echo ""
        done
    fi
} > "$OUTPUT_FILE"

echo -e "📄 Results saved to: ${BLUE}$OUTPUT_FILE${NC}"
echo ""




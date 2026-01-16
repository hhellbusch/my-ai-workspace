#!/bin/bash
# cleanup-baremetal-cluster.sh - Clean up bare metal OpenShift cluster

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CLUSTER_NAME=""
CONFIG_FILE=""
DRY_RUN=false
SKIP_CONFIRM=false
STEPS="all"

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Clean up bare metal OpenShift cluster resources.

Options:
    --cluster-name NAME     Cluster name (required)
    --config FILE           Inventory config file (recommended)
    --steps STEPS           Comma-separated steps to run (default: all)
                           Available: power-off,vms,lb,dns,dhcp,storage,verify
    --dry-run              Show what would be done without doing it
    --yes                  Skip confirmation prompts
    -h, --help             Show this help

Examples:
    # Full cleanup with confirmation
    $0 --cluster-name my-cluster --config cluster-inventory.txt

    # Only power off nodes
    $0 --cluster-name my-cluster --steps power-off

    # Cleanup networking only (DNS and LB)
    $0 --cluster-name my-cluster --steps dns,lb --yes

    # Dry run to see what would happen
    $0 --cluster-name my-cluster --config cluster-inventory.txt --dry-run

Prerequisites:
    1. Run find-cluster-baremetal.sh first to generate inventory
    2. Edit inventory file with your specific details
    3. Ensure you have access to:
       - BMCs (for power-off)
       - Load balancer
       - DNS server
       - DHCP server (if applicable)
       - Hypervisor (if VMs)
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --cluster-name)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --steps)
            STEPS="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --yes)
            SKIP_CONFIRM=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [ -z "$CLUSTER_NAME" ]; then
    echo -e "${RED}Error: --cluster-name is required${NC}"
    usage
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Bare Metal Cluster Cleanup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Cluster Name: ${YELLOW}$CLUSTER_NAME${NC}"
echo -e "Config File:  ${YELLOW}${CONFIG_FILE:-none}${NC}"
echo -e "Dry Run:      ${YELLOW}$DRY_RUN${NC}"
echo -e "Steps:        ${YELLOW}$STEPS${NC}"
echo ""

# Load config file if provided
if [ -n "$CONFIG_FILE" ]; then
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Error: Config file not found: $CONFIG_FILE${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Loading configuration from $CONFIG_FILE...${NC}"
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
    echo -e "${GREEN}✓ Configuration loaded${NC}"
    echo ""
fi

# Safety confirmation
if [ "$SKIP_CONFIRM" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "${RED}⚠️  WARNING: This will destroy cluster resources!${NC}"
    echo ""
    echo "This action will:"
    echo "  - Power off all cluster nodes"
    echo "  - Delete VMs (if applicable)"
    echo "  - Remove load balancer configuration"
    echo "  - Remove DNS records"
    echo "  - Remove DHCP entries (if applicable)"
    echo "  - Remove storage (if requested)"
    echo ""
    echo -e "Cluster to delete: ${RED}$CLUSTER_NAME${NC}"
    echo ""
    read -p "Type 'DELETE' to confirm: " CONFIRM
    
    if [ "$CONFIRM" != "DELETE" ]; then
        echo "Aborted."
        exit 0
    fi
    echo ""
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

run_cmd() {
    local cmd="$1"
    local desc="$2"
    
    echo -e "${BLUE}→${NC} $desc"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${YELLOW}[DRY RUN]${NC} Would run: $cmd"
        return 0
    fi
    
    if eval "$cmd" 2>&1; then
        echo -e "  ${GREEN}✓${NC} Success"
        return 0
    else
        echo -e "  ${RED}✗${NC} Failed (continuing...)"
        return 1
    fi
}

should_run_step() {
    local step="$1"
    
    if [ "$STEPS" = "all" ]; then
        return 0
    fi
    
    if echo "$STEPS" | grep -q "$step"; then
        return 0
    fi
    
    return 1
}

# ============================================================================
# STEP 1: POWER OFF NODES
# ============================================================================

step_power_off() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Step 1: Power Off Nodes${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Try via cluster API first
    if command -v oc &>/dev/null && oc whoami &>/dev/null; then
        echo "Attempting to scale down via cluster API..."
        
        run_cmd "oc get baremetalhost -n openshift-machine-api 2>/dev/null" \
            "Check for BareMetalHost resources"
        
        if [ $? -eq 0 ]; then
            run_cmd "oc get baremetalhost -n openshift-machine-api -o name | xargs -I {} oc patch {} -n openshift-machine-api --type merge -p '{\"spec\":{\"online\":false}}'" \
                "Set all BareMetalHost resources to offline"
        fi
        
        echo ""
    fi
    
    # Via BMC with ipmitool
    if [ -n "${BMC_USER:-}" ] && [ -n "${BMC_PASS:-}" ]; then
        echo "Powering off nodes via BMC..."
        
        # Get all BMC variables
        for var in $(compgen -v | grep "_BMC$"); do
            bmc_ip="${!var}"
            node_name=$(echo "$var" | sed 's/_BMC$//')
            
            if [ -n "$bmc_ip" ] && [ "$bmc_ip" != "TODO" ] && [ "$bmc_ip" != "TODO_BMC_IP" ]; then
                run_cmd "ipmitool -I lanplus -H '$bmc_ip' -U '$BMC_USER' -P '$BMC_PASS' power off" \
                    "Power off $node_name ($bmc_ip)"
            fi
        done
        
        echo ""
        echo "Waiting 10 seconds for power off..."
        [ "$DRY_RUN" = false ] && sleep 10
        
        echo ""
        echo "Verifying power status..."
        for var in $(compgen -v | grep "_BMC$"); do
            bmc_ip="${!var}"
            node_name=$(echo "$var" | sed 's/_BMC$//')
            
            if [ -n "$bmc_ip" ] && [ "$bmc_ip" != "TODO" ] && [ "$bmc_ip" != "TODO_BMC_IP" ]; then
                if [ "$DRY_RUN" = false ]; then
                    status=$(ipmitool -I lanplus -H "$bmc_ip" -U "$BMC_USER" -P "$BMC_PASS" power status 2>/dev/null || echo "unknown")
                    echo "  $node_name: $status"
                fi
            fi
        done
    else
        echo -e "${YELLOW}⚠️  No BMC credentials in config. Skipping BMC power off.${NC}"
        echo "To power off manually:"
        echo "  ipmitool -I lanplus -H <bmc-ip> -U <user> -P <pass> power off"
    fi
    
    echo ""
}

# ============================================================================
# STEP 2: DELETE VMS
# ============================================================================

step_vms() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Step 2: Delete Virtual Machines${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -n "${HYPERVISOR_TYPE:-}" ] && [ "${HYPERVISOR_TYPE}" != "TODO" ]; then
        case "${HYPERVISOR_TYPE}" in
            libvirt|kvm)
                echo "Detected libvirt/KVM hypervisor"
                
                # List VMs
                if command -v virsh &>/dev/null; then
                    vms=$(virsh list --all | grep "$CLUSTER_NAME" | awk '{print $2}' || echo "")
                    
                    if [ -n "$vms" ]; then
                        echo "Found VMs:"
                        echo "$vms"
                        echo ""
                        
                        for vm in $vms; do
                            run_cmd "virsh destroy '$vm' 2>/dev/null || true" \
                                "Force power off VM: $vm"
                            
                            run_cmd "virsh undefine '$vm' --remove-all-storage" \
                                "Delete VM and storage: $vm"
                        done
                    else
                        echo -e "${YELLOW}No VMs found matching cluster name${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠️  virsh command not found${NC}"
                fi
                ;;
                
            vmware|vcenter)
                echo "Detected VMware vCenter"
                echo -e "${YELLOW}Use the vSphere cleanup script instead:${NC}"
                echo "  ./cleanup-vsphere-cluster.sh $CLUSTER_NAME"
                ;;
                
            proxmox)
                echo "Detected Proxmox"
                echo -e "${YELLOW}⚠️  Proxmox cleanup not automated in this script${NC}"
                echo "See BAREMETAL-GUIDE.md for manual Proxmox cleanup"
                ;;
                
            *)
                echo -e "${YELLOW}Unknown hypervisor type: ${HYPERVISOR_TYPE}${NC}"
                ;;
        esac
    else
        echo -e "${YELLOW}No hypervisor configured (physical hardware or manual VM management)${NC}"
    fi
    
    echo ""
}

# ============================================================================
# STEP 3: CLEAN LOAD BALANCER
# ============================================================================

step_lb() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Step 3: Clean Load Balancer${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -n "${LB_HOST:-}" ] && [ "${LB_HOST}" != "TODO" ]; then
        echo -e "${YELLOW}⚠️  Load balancer cleanup requires manual intervention${NC}"
        echo ""
        echo "Load balancer: ${LB_HOST}"
        echo "Type: ${LB_TYPE:-unknown}"
        echo ""
        echo "Manual cleanup steps:"
        echo "  1. SSH to load balancer: ssh admin@${LB_HOST}"
        
        case "${LB_TYPE:-}" in
            haproxy)
                echo "  2. Edit config: sudo vi /etc/haproxy/haproxy.cfg"
                echo "  3. Remove sections for: $CLUSTER_NAME"
                echo "  4. Test config: sudo haproxy -c -f /etc/haproxy/haproxy.cfg"
                echo "  5. Reload: sudo systemctl reload haproxy"
                ;;
            nginx)
                echo "  2. Remove config: sudo rm /etc/nginx/conf.d/${CLUSTER_NAME}.conf"
                echo "  3. Test config: sudo nginx -t"
                echo "  4. Reload: sudo systemctl reload nginx"
                ;;
            *)
                echo "  2. Remove cluster configuration"
                echo "  3. Reload/restart load balancer service"
                ;;
        esac
        
        echo ""
        echo "See BAREMETAL-GUIDE.md for detailed instructions"
    else
        echo -e "${YELLOW}No load balancer configured in inventory${NC}"
    fi
    
    echo ""
}

# ============================================================================
# STEP 4: CLEAN DNS
# ============================================================================

step_dns() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Step 4: Clean DNS Records${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -n "${DNS_SERVER:-}" ] && [ "${DNS_SERVER}" != "TODO" ]; then
        echo -e "${YELLOW}⚠️  DNS cleanup requires manual intervention${NC}"
        echo ""
        echo "DNS server: ${DNS_SERVER}"
        echo "Type: ${DNS_TYPE:-unknown}"
        echo "Domain: ${CLUSTER_DOMAIN:-unknown}"
        echo ""
        echo "Records to remove:"
        echo "  - api.${CLUSTER_NAME}.${CLUSTER_DOMAIN:-example.com}"
        echo "  - api-int.${CLUSTER_NAME}.${CLUSTER_DOMAIN:-example.com}"
        echo "  - *.apps.${CLUSTER_NAME}.${CLUSTER_DOMAIN:-example.com}"
        echo "  - Node A records (all master-*, worker-* entries)"
        echo ""
        
        case "${DNS_TYPE:-}" in
            bind)
                echo "BIND cleanup:"
                echo "  1. SSH to DNS server: ssh admin@${DNS_SERVER}"
                echo "  2. Edit zone file: sudo vi /var/named/${CLUSTER_DOMAIN}.zone"
                echo "  3. Remove cluster entries"
                echo "  4. Increment SOA serial"
                echo "  5. Check zone: sudo named-checkzone ${CLUSTER_DOMAIN} /var/named/${CLUSTER_DOMAIN}.zone"
                echo "  6. Reload: sudo rndc reload ${CLUSTER_DOMAIN}"
                ;;
            dnsmasq)
                echo "dnsmasq cleanup:"
                echo "  1. SSH to DNS server: ssh admin@${DNS_SERVER}"
                echo "  2. Remove config: sudo rm /etc/dnsmasq.d/${CLUSTER_NAME}.conf"
                echo "  3. Restart: sudo systemctl restart dnsmasq"
                ;;
            *)
                echo "Manual DNS cleanup required"
                ;;
        esac
        
        echo ""
        echo "See BAREMETAL-GUIDE.md for detailed instructions"
    else
        echo -e "${YELLOW}No DNS server configured in inventory${NC}"
    fi
    
    echo ""
}

# ============================================================================
# STEP 5: CLEAN DHCP
# ============================================================================

step_dhcp() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Step 5: Clean DHCP Entries${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -n "${DHCP_SERVER:-}" ] && [ "${DHCP_SERVER}" != "TODO" ]; then
        echo -e "${YELLOW}⚠️  DHCP cleanup requires manual intervention${NC}"
        echo ""
        echo "DHCP server: ${DHCP_SERVER}"
        echo "Type: ${DHCP_TYPE:-unknown}"
        echo ""
        echo "Manual cleanup:"
        echo "  1. SSH to DHCP server: ssh admin@${DHCP_SERVER}"
        echo "  2. Remove host entries for cluster nodes"
        echo "  3. Test and restart DHCP service"
        echo ""
        echo "See BAREMETAL-GUIDE.md for detailed instructions"
    else
        echo -e "${YELLOW}No DHCP server configured (static IPs or not applicable)${NC}"
    fi
    
    echo ""
}

# ============================================================================
# STEP 6: CLEAN STORAGE
# ============================================================================

step_storage() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Step 6: Clean Storage${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -n "${NFS_SERVER:-}" ] && [ "${NFS_SERVER}" != "TODO" ]; then
        echo -e "${YELLOW}⚠️  Storage cleanup requires manual intervention${NC}"
        echo ""
        echo "NFS server: ${NFS_SERVER}"
        echo "Export path: ${NFS_EXPORT_PATH:-unknown}"
        echo ""
        echo "⚠️  WARNING: This will delete all data!"
        echo ""
        echo "Manual cleanup:"
        echo "  1. SSH to NFS server: ssh admin@${NFS_SERVER}"
        echo "  2. Backup if needed: sudo tar czf /backup/${CLUSTER_NAME}-$(date +%Y%m%d).tar.gz ${NFS_EXPORT_PATH}/${CLUSTER_NAME}-*"
        echo "  3. Remove data: sudo rm -rf ${NFS_EXPORT_PATH}/${CLUSTER_NAME}-*"
        echo "  4. Update /etc/exports if needed"
        echo "  5. Re-export: sudo exportfs -ra"
    else
        echo -e "${YELLOW}No NFS server configured${NC}"
    fi
    
    echo ""
}

# ============================================================================
# STEP 7: VERIFY
# ============================================================================

step_verify() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Step 7: Verify Cleanup${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ "$DRY_RUN" = false ]; then
        # DNS verification
        echo "Verifying DNS cleanup..."
        if [ -n "${CLUSTER_DOMAIN:-}" ] && [ "${CLUSTER_DOMAIN}" != "TODO" ]; then
            for record in "api" "api-int"; do
                result=$(dig +short "${record}.${CLUSTER_NAME}.${CLUSTER_DOMAIN}" 2>/dev/null || echo "")
                if [ -z "$result" ]; then
                    echo -e "  ${GREEN}✓${NC} ${record}.${CLUSTER_NAME}.${CLUSTER_DOMAIN} - removed"
                else
                    echo -e "  ${RED}✗${NC} ${record}.${CLUSTER_NAME}.${CLUSTER_DOMAIN} - still exists ($result)"
                fi
            done
        fi
        
        # VIP verification
        echo ""
        echo "Verifying VIPs are unreachable..."
        if [ -n "${API_VIP:-}" ] && [ "${API_VIP}" != "TODO" ] && [ "${API_VIP}" != "unknown" ]; then
            if timeout 2 ping -c 1 "${API_VIP}" &>/dev/null; then
                echo -e "  ${RED}✗${NC} API VIP still responding: ${API_VIP}"
            else
                echo -e "  ${GREEN}✓${NC} API VIP not responding: ${API_VIP}"
            fi
        fi
        
        # Node power verification
        echo ""
        echo "Verifying nodes are powered off..."
        if [ -n "${BMC_USER:-}" ] && [ -n "${BMC_PASS:-}" ]; then
            for var in $(compgen -v | grep "_BMC$"); do
                bmc_ip="${!var}"
                node_name=$(echo "$var" | sed 's/_BMC$//')
                
                if [ -n "$bmc_ip" ] && [ "$bmc_ip" != "TODO" ] && [ "$bmc_ip" != "TODO_BMC_IP" ]; then
                    status=$(ipmitool -I lanplus -H "$bmc_ip" -U "$BMC_USER" -P "$BMC_PASS" power status 2>/dev/null || echo "unknown")
                    if echo "$status" | grep -qi "off"; then
                        echo -e "  ${GREEN}✓${NC} $node_name: powered off"
                    else
                        echo -e "  ${RED}✗${NC} $node_name: $status"
                    fi
                fi
            done
        fi
    else
        echo -e "${YELLOW}Skipping verification in dry-run mode${NC}"
    fi
    
    echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

echo -e "${BLUE}Starting cleanup process...${NC}"
echo ""

if should_run_step "power-off"; then
    step_power_off
fi

if should_run_step "vms"; then
    step_vms
fi

if should_run_step "lb"; then
    step_lb
fi

if should_run_step "dns"; then
    step_dns
fi

if should_run_step "dhcp"; then
    step_dhcp
fi

if should_run_step "storage"; then
    step_storage
fi

if should_run_step "verify"; then
    step_verify
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CLEANUP SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
    echo ""
    echo "To perform actual cleanup, remove the --dry-run flag:"
    echo "  $0 --cluster-name $CLUSTER_NAME --config ${CONFIG_FILE:-cluster-inventory.txt}"
else
    echo -e "${GREEN}Automated cleanup steps completed!${NC}"
    echo ""
    echo "⚠️  Some steps require manual intervention:"
    echo "  - Load balancer configuration"
    echo "  - DNS records"
    echo "  - DHCP entries (if applicable)"
    echo "  - Storage cleanup"
    echo ""
    echo "See output above for specific instructions."
    echo ""
    echo "Refer to BAREMETAL-GUIDE.md for detailed procedures."
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo ""







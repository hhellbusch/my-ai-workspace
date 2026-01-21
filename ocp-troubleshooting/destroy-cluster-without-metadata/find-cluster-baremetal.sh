#!/bin/bash
# find-cluster-baremetal.sh - Find OpenShift bare metal cluster resources

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="${1:-}"

usage() {
    cat <<EOF
Usage: $0 <cluster-name>

Find OpenShift bare metal cluster resources.

Arguments:
    cluster-name    Cluster name or keyword to search for (required)

Prerequisites:
    - oc CLI (if cluster is accessible)
    - kubeconfig set (if cluster is accessible)
    - Network access to cluster network

Examples:
    $0 my-ocp-cluster
    $0 production

Output:
    - Node information from cluster (if accessible)
    - DNS records
    - Network connectivity test
    - Generates inventory file
    - Provides cleanup checklist
EOF
}

if [ -z "$CLUSTER_NAME" ]; then
    usage
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Bare Metal Cluster Resource Finder${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Cluster Name: ${YELLOW}$CLUSTER_NAME${NC}"
echo ""

# Initialize counters
CLUSTER_ACCESSIBLE=false
NODE_COUNT=0
BMH_COUNT=0

# ============================================================================
# CHECK CLUSTER ACCESSIBILITY
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Cluster Accessibility Check${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v oc &> /dev/null; then
    echo -e "${GREEN}✓ oc CLI found${NC}"
    
    if oc whoami &>/dev/null; then
        CLUSTER_ACCESSIBLE=true
        echo -e "${GREEN}✓ Cluster is accessible${NC}"
        
        CLUSTER_ID=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}' 2>/dev/null || echo "unknown")
        PLATFORM=$(oc get infrastructure cluster -o jsonpath='{.status.platform}' 2>/dev/null || echo "unknown")
        API_URL=$(oc whoami --show-server 2>/dev/null || echo "unknown")
        
        echo -e "  Infrastructure Name: ${GREEN}$CLUSTER_ID${NC}"
        echo -e "  Platform: ${GREEN}$PLATFORM${NC}"
        echo -e "  API Server: ${GREEN}$API_URL${NC}"
    else
        echo -e "${YELLOW}⚠️  Cluster not accessible (no valid kubeconfig)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  oc CLI not found${NC}"
fi
echo ""

# ============================================================================
# GATHER CLUSTER INFORMATION
# ============================================================================
if [ "$CLUSTER_ACCESSIBLE" = true ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Nodes${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    NODES=$(oc get nodes -o json 2>/dev/null || echo '{"items":[]}')
    NODE_COUNT=$(echo "$NODES" | jq '.items | length')
    
    if [ "$NODE_COUNT" -gt 0 ]; then
        echo "$NODES" | jq -r '.items[] | 
            "\(.metadata.name)\t\(.status.addresses[] | select(.type=="InternalIP") | .address)\t\(.status.nodeInfo.machineID)\t\(.status.conditions[] | select(.type=="Ready") | .status)"' | 
            while IFS=$'\t' read -r name ip machine_id ready; do
                echo "  $name"
                echo "    IP: $ip"
                echo "    Machine ID: $machine_id"
                echo "    Ready: $ready"
                echo ""
            done
        
        echo -e "${GREEN}Found: $NODE_COUNT nodes${NC}"
        
        # Save node data
        echo "$NODES" > /tmp/${CLUSTER_NAME}-nodes.json
        echo -e "  ${BLUE}Node data saved to: /tmp/${CLUSTER_NAME}-nodes.json${NC}"
    else
        echo -e "${YELLOW}No nodes found${NC}"
    fi
    echo ""
    
    # ========================================================================
    # BAREMETALHOST RESOURCES
    # ========================================================================
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}BareMetalHost Resources (IPI)${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    BMH=$(oc get baremetalhosts -n openshift-machine-api -o json 2>/dev/null || echo '{"items":[]}')
    BMH_COUNT=$(echo "$BMH" | jq '.items | length')
    
    if [ "$BMH_COUNT" -gt 0 ]; then
        echo "$BMH" | jq -r '.items[] | 
            "\(.metadata.name)\t\(.spec.bmc.address)\t\(.status.hardwareProfile)\t\(.status.provisioning.state)\t\(.status.powerStatus)"' | 
            while IFS=$'\t' read -r name bmc profile state power; do
                echo "  $name"
                echo "    BMC: $bmc"
                echo "    Profile: $profile"
                echo "    State: $state"
                echo "    Power: $power"
                echo ""
            done
        
        echo -e "${GREEN}Found: $BMH_COUNT BareMetalHost resources${NC}"
        
        # Save BMH data
        echo "$BMH" > /tmp/${CLUSTER_NAME}-bmh.json
        echo -e "  ${BLUE}BMH data saved to: /tmp/${CLUSTER_NAME}-bmh.json${NC}"
        
        # Extract BMC IPs
        echo ""
        echo "BMC IP addresses:"
        echo "$BMH" | jq -r '.items[].spec.bmc.address' | grep -oP '(?<=\/\/)[^/]+' | while read bmc; do
            echo "  $bmc"
        done
    else
        echo -e "${YELLOW}No BareMetalHost resources found (UPI deployment?)${NC}"
    fi
    echo ""
    
    # ========================================================================
    # NETWORK CONFIGURATION
    # ========================================================================
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Network Configuration${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Get network info
    NETWORK_INFO=$(oc get network cluster -o json 2>/dev/null || echo '{}')
    CLUSTER_NETWORK=$(echo "$NETWORK_INFO" | jq -r '.spec.clusterNetwork[0].cidr // "unknown"')
    SERVICE_NETWORK=$(echo "$NETWORK_INFO" | jq -r '.spec.serviceNetwork[0] // "unknown"')
    
    echo "  Cluster Network: $CLUSTER_NETWORK"
    echo "  Service Network: $SERVICE_NETWORK"
    echo ""
    
    # Get VIPs if available
    INFRA=$(oc get infrastructure cluster -o json 2>/dev/null || echo '{}')
    API_VIP=$(echo "$INFRA" | jq -r '.status.platformStatus.baremetal.apiServerInternalIP // "unknown"')
    INGRESS_VIP=$(echo "$INFRA" | jq -r '.status.platformStatus.baremetal.ingressIP // "unknown"')
    
    echo "  API VIP: $API_VIP"
    echo "  Ingress VIP: $INGRESS_VIP"
    echo ""
    
    # DNS info
    BASE_DOMAIN=$(echo "$INFRA" | jq -r '.status.platformStatus.baremetal.apiServerInternalIP // "unknown"')
    CLUSTER_DOMAIN=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}' 2>/dev/null || echo "unknown")
    
    echo "  Base Domain: $CLUSTER_DOMAIN"
    echo ""
fi

# ============================================================================
# DNS LOOKUPS
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}DNS Records${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$CLUSTER_ACCESSIBLE" = true ] && [ "$CLUSTER_DOMAIN" != "unknown" ]; then
    FULL_CLUSTER_DOMAIN="${CLUSTER_NAME}.${CLUSTER_DOMAIN}"
else
    # Try common patterns
    FULL_CLUSTER_DOMAIN="${CLUSTER_NAME}.example.com"
    echo -e "${YELLOW}Note: Using assumed domain ${FULL_CLUSTER_DOMAIN}${NC}"
    echo -e "${YELLOW}      Adjust if your domain is different${NC}"
    echo ""
fi

echo "Checking DNS records for: $FULL_CLUSTER_DOMAIN"
echo ""

# Check API
echo -n "  api.${FULL_CLUSTER_DOMAIN}: "
API_IP=$(dig +short api.${FULL_CLUSTER_DOMAIN} 2>/dev/null | head -1)
if [ -n "$API_IP" ]; then
    echo -e "${GREEN}$API_IP${NC}"
else
    echo -e "${YELLOW}Not found${NC}"
fi

# Check API-INT
echo -n "  api-int.${FULL_CLUSTER_DOMAIN}: "
API_INT_IP=$(dig +short api-int.${FULL_CLUSTER_DOMAIN} 2>/dev/null | head -1)
if [ -n "$API_INT_IP" ]; then
    echo -e "${GREEN}$API_INT_IP${NC}"
else
    echo -e "${YELLOW}Not found${NC}"
fi

# Check wildcard apps
echo -n "  *.apps.${FULL_CLUSTER_DOMAIN}: "
APPS_IP=$(dig +short "test.apps.${FULL_CLUSTER_DOMAIN}" 2>/dev/null | head -1)
if [ -n "$APPS_IP" ]; then
    echo -e "${GREEN}$APPS_IP${NC}"
else
    echo -e "${YELLOW}Not found${NC}"
fi

echo ""

# ============================================================================
# CONNECTIVITY TESTS
# ============================================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Connectivity Tests${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Test API VIP
if [ -n "$API_IP" ] && [ "$API_IP" != "unknown" ]; then
    echo -n "  API Server ($API_IP:6443): "
    if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$API_IP/6443" 2>/dev/null; then
        echo -e "${GREEN}Reachable${NC}"
    else
        echo -e "${RED}Unreachable${NC}"
    fi
fi

# Test Ingress VIP
if [ -n "$APPS_IP" ] && [ "$APPS_IP" != "unknown" ]; then
    echo -n "  Ingress ($APPS_IP:443): "
    if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$APPS_IP/443" 2>/dev/null; then
        echo -e "${GREEN}Reachable${NC}"
    else
        echo -e "${RED}Unreachable${NC}"
    fi
fi

echo ""

# ============================================================================
# GENERATE INVENTORY FILE
# ============================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Generating Inventory File${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

INVENTORY_FILE="/tmp/${CLUSTER_NAME}-inventory.txt"

cat > "$INVENTORY_FILE" <<EOF
# Cluster Inventory for: $CLUSTER_NAME
# Generated: $(date)
# 
# INSTRUCTIONS:
# 1. Fill in missing values (marked with TODO)
# 2. Update with your actual values
# 3. Use with cleanup script: ./cleanup-baremetal-cluster.sh --config $INVENTORY_FILE

# ============================================================================
# CLUSTER INFORMATION
# ============================================================================
CLUSTER_NAME=$CLUSTER_NAME
EOF

if [ "$CLUSTER_ACCESSIBLE" = true ]; then
    cat >> "$INVENTORY_FILE" <<EOF
CLUSTER_ID=$CLUSTER_ID
CLUSTER_DOMAIN=$CLUSTER_DOMAIN
API_VIP=${API_VIP}
INGRESS_VIP=${INGRESS_VIP}

# ============================================================================
# NODES (from cluster)
# ============================================================================
EOF
    
    # Add node information
    if [ "$NODE_COUNT" -gt 0 ]; then
        echo "$NODES" | jq -r '.items[] | 
            .metadata.name as $name | 
            .status.addresses[] | 
            select(.type=="InternalIP") | 
            "\($name)_IP=\(.address)"' >> "$INVENTORY_FILE"
        
        echo "" >> "$INVENTORY_FILE"
        echo "# BMC addresses (fill these in):" >> "$INVENTORY_FILE"
        echo "$NODES" | jq -r '.items[].metadata.name' | while read node; do
            echo "${node}_BMC=TODO_BMC_IP" >> "$INVENTORY_FILE"
        done
    fi
    
    # Add BMH information if available
    if [ "$BMH_COUNT" -gt 0 ]; then
        echo "" >> "$INVENTORY_FILE"
        echo "# ============================================================================" >> "$INVENTORY_FILE"
        echo "# BMC ADDRESSES (from BareMetalHost)" >> "$INVENTORY_FILE"
        echo "# ============================================================================" >> "$INVENTORY_FILE"
        
        echo "$BMH" | jq -r '.items[] | 
            .metadata.name as $name | 
            .spec.bmc.address | 
            gsub(".*://"; "") | 
            gsub("/.*"; "") | 
            "\($name)_BMC=\(.)"' >> "$INVENTORY_FILE"
    fi
else
    cat >> "$INVENTORY_FILE" <<EOF
CLUSTER_DOMAIN=TODO_DOMAIN  # e.g., example.com
API_VIP=${API_IP:-TODO_API_VIP}
INGRESS_VIP=${APPS_IP:-TODO_INGRESS_VIP}

# ============================================================================
# NODES (fill in your node information)
# ============================================================================
# Example format:
# MASTER_0_HOSTNAME=master-0.${CLUSTER_NAME}.example.com
# MASTER_0_IP=10.0.0.10
# MASTER_0_BMC=10.0.1.10
# MASTER_0_MAC=aa:bb:cc:dd:ee:01

EOF
fi

cat >> "$INVENTORY_FILE" <<EOF

# ============================================================================
# INFRASTRUCTURE SERVICES
# ============================================================================
LB_HOST=TODO_LB_HOSTNAME      # Load balancer hostname/IP
LB_TYPE=TODO                  # haproxy, nginx, f5, etc.
LB_CONFIG=TODO                # Path to config file

DNS_SERVER=TODO_DNS_IP        # DNS server IP
DNS_TYPE=TODO                 # bind, dnsmasq, powerdns, etc.

DHCP_SERVER=TODO_DHCP_IP      # DHCP server IP (if used)
DHCP_TYPE=TODO                # isc-dhcp, dnsmasq, etc.

# ============================================================================
# HYPERVISOR (if VMs)
# ============================================================================
HYPERVISOR_HOST=TODO          # Hypervisor hostname (if VMs)
HYPERVISOR_TYPE=TODO          # libvirt, vmware, proxmox, etc.

# ============================================================================
# STORAGE
# ============================================================================
NFS_SERVER=TODO               # NFS server (if used)
NFS_EXPORT_PATH=TODO          # Base export path

# ============================================================================
# CREDENTIALS (use carefully, or reference vault)
# ============================================================================
BMC_USER=TODO                 # BMC username
BMC_PASS=TODO                 # BMC password (or use vault)
EOF

echo -e "${GREEN}✓ Inventory file created: ${BLUE}$INVENTORY_FILE${NC}"
echo ""
echo "Next steps:"
echo "  1. Edit the inventory file and fill in TODO values"
echo "  2. Review the file carefully"
echo "  3. Run: ./cleanup-baremetal-cluster.sh --config $INVENTORY_FILE"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Cluster Name:      ${YELLOW}$CLUSTER_NAME${NC}"
echo -e "Cluster Access:    ${YELLOW}$([ "$CLUSTER_ACCESSIBLE" = true ] && echo "✓ Yes" || echo "✗ No")${NC}"
echo ""

if [ "$CLUSTER_ACCESSIBLE" = true ]; then
    echo -e "Nodes:             ${GREEN}$NODE_COUNT${NC}"
    echo -e "BareMetalHosts:    ${GREEN}$BMH_COUNT${NC}"
    echo -e "Platform:          ${GREEN}$PLATFORM${NC}"
    echo ""
fi

echo "DNS Records Found:"
[ -n "$API_IP" ] && echo -e "  API:             ${GREEN}✓${NC}" || echo -e "  API:             ${YELLOW}✗${NC}"
[ -n "$APPS_IP" ] && echo -e "  Apps Wildcard:   ${GREEN}✓${NC}" || echo -e "  Apps Wildcard:   ${YELLOW}✗${NC}"
echo ""

# ============================================================================
# CLEANUP CHECKLIST
# ============================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CLEANUP CHECKLIST${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "To destroy this cluster, you need to clean up:"
echo ""
echo "  [ ] 1. Power down nodes"
if [ "$BMH_COUNT" -gt 0 ]; then
    echo "        - Via BareMetalHost resources (set spec.online=false)"
fi
echo "        - Via BMC (ipmitool/redfish)"
echo "        - Via hypervisor (if VMs)"
echo ""
echo "  [ ] 2. Clean up load balancer"
echo "        - Remove cluster backend/frontend config"
echo "        - Release VIPs (if using keepalived)"
echo ""
echo "  [ ] 3. Clean up DNS"
[ -n "$API_IP" ] && echo "        - Remove api.${FULL_CLUSTER_DOMAIN}"
[ -n "$API_INT_IP" ] && echo "        - Remove api-int.${FULL_CLUSTER_DOMAIN}"
[ -n "$APPS_IP" ] && echo "        - Remove *.apps.${FULL_CLUSTER_DOMAIN}"
echo "        - Remove node A records"
echo ""
echo "  [ ] 4. Clean up DHCP (if used)"
echo "        - Remove static MAC/IP assignments"
echo ""
echo "  [ ] 5. Clean up PXE/boot files (if used)"
echo "        - Remove TFTP boot files"
echo "        - Remove ignition configs"
echo ""
echo "  [ ] 6. Clean up storage"
echo "        - NFS exports"
echo "        - Local storage (if reprovisioning nodes)"
echo ""
echo "  [ ] 7. Clean up installation artifacts"
echo "        - Remove local install directory"
echo "        - Remove cached ISOs/images"
echo ""
echo "  [ ] 8. Verify cleanup"
echo "        - DNS lookups should fail"
echo "        - VIPs should be unreachable"
echo "        - Nodes should be powered off"
echo ""

echo -e "${YELLOW}See BAREMETAL-GUIDE.md for detailed procedures${NC}"
echo ""

# ============================================================================
# SAVE ALL DATA
# ============================================================================
OUTPUT_FILE="/tmp/${CLUSTER_NAME}-discovery-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "Bare Metal Cluster Discovery: $CLUSTER_NAME"
    echo "Date: $(date)"
    echo ""
    
    if [ "$CLUSTER_ACCESSIBLE" = true ]; then
        echo "=== CLUSTER INFO ==="
        echo "Infrastructure Name: $CLUSTER_ID"
        echo "Platform: $PLATFORM"
        echo "API URL: $API_URL"
        echo ""
        
        echo "=== NODES ==="
        echo "$NODES" | jq -r '.items[] | 
            "\(.metadata.name)\t\(.status.addresses[] | select(.type=="InternalIP") | .address)"'
        echo ""
        
        if [ "$BMH_COUNT" -gt 0 ]; then
            echo "=== BAREMETALHOSTS ==="
            echo "$BMH" | jq -r '.items[] | 
                "\(.metadata.name)\t\(.spec.bmc.address)\t\(.status.provisioning.state)"'
            echo ""
        fi
    fi
    
    echo "=== DNS RECORDS ==="
    echo "api.${FULL_CLUSTER_DOMAIN}: $API_IP"
    echo "api-int.${FULL_CLUSTER_DOMAIN}: $API_INT_IP"
    echo "*.apps.${FULL_CLUSTER_DOMAIN}: $APPS_IP"
} > "$OUTPUT_FILE"

echo -e "📄 Discovery results saved to: ${BLUE}$OUTPUT_FILE${NC}"
echo ""








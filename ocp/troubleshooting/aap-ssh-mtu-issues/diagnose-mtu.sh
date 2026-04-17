#!/bin/bash
#
# diagnose-mtu.sh - Automated MTU diagnostic for AAP SSH issues
#
# Usage: ./diagnose-mtu.sh <aap-namespace> <target-host-ip>
#
# This script performs comprehensive MTU diagnostics for SSH connectivity
# issues from Ansible Automation Platform running on OpenShift.
#
# AI Disclosure: This script was created with AI assistance (Claude 3.5 Sonnet
# via Cursor) on 2026-02-04.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <aap-namespace> <target-host-ip>"
    echo ""
    echo "Example: $0 ansible-automation-platform 192.168.100.50"
    exit 1
fi

AAP_NAMESPACE="$1"
TARGET_HOST="$2"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}AAP SSH MTU Diagnostic Tool${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Namespace: $AAP_NAMESPACE"
echo "Target Host: $TARGET_HOST"
echo ""

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}>>> $1${NC}"
    echo "---"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if we can access the cluster
print_header "Checking cluster access"
if ! oc whoami &>/dev/null; then
    print_error "Not logged into OpenShift cluster"
    exit 1
fi
print_success "Logged in as: $(oc whoami)"

# Check namespace exists
print_header "Checking namespace"
if ! oc get namespace "$AAP_NAMESPACE" &>/dev/null; then
    print_error "Namespace $AAP_NAMESPACE does not exist"
    exit 1
fi
print_success "Namespace exists"

# Find AAP execution pod
print_header "Finding AAP execution pod"
echo "Available pods in namespace:"
oc get pods -n "$AAP_NAMESPACE" 2>/dev/null || {
    print_error "Cannot access namespace $AAP_NAMESPACE"
    exit 1
}

echo ""
echo "Attempting to identify execution/job pods..."

# Try flexible pod selection
AAP_POD=$(oc get pods -n "$AAP_NAMESPACE" --field-selector=status.phase=Running -o name 2>/dev/null | grep -iE "job|executor|task|ee|automation" | head -1)

if [ -z "$AAP_POD" ]; then
    print_error "No running execution/job pod found automatically"
    echo ""
    echo "Please identify your AAP execution pod from the list above and run:"
    echo "  oc exec -n $AAP_NAMESPACE <pod-name> -- ping -M do -s 1472 $TARGET_HOST -c 4"
    exit 1
fi

print_success "Found pod: $AAP_POD"
print_warning "Note: Pod naming varies by AAP version. Verify this is an execution/job pod."

# Check cluster MTU configuration
print_header "Checking cluster MTU configuration"
CLUSTER_MTU=$(oc get network.config.openshift.io cluster -o jsonpath='{.status.clusterNetwork[0].mtu}' 2>/dev/null || echo "unknown")
OVN_MTU=$(oc get network.operator.openshift.io cluster -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.mtu}' 2>/dev/null || echo "unknown")

echo "Cluster Network MTU: $CLUSTER_MTU"
echo "OVN Overlay MTU: $OVN_MTU"

if [ "$CLUSTER_MTU" = "1400" ] || [ "$OVN_MTU" = "1400" ]; then
    print_success "Standard MTU configuration (1400 overlay)"
elif [ "$CLUSTER_MTU" = "8900" ] || [ "$OVN_MTU" = "8900" ]; then
    print_success "Jumbo frame configuration (8900 overlay)"
else
    print_warning "Non-standard MTU configuration"
fi

# Check pod MTU
print_header "Checking pod network MTU"
POD_MTU=$(oc exec -n "$AAP_NAMESPACE" "$AAP_POD" -- ip link show eth0 2>/dev/null | grep -oP 'mtu \K[0-9]+' || echo "unknown")
echo "Pod eth0 MTU: $POD_MTU"

if [ "$POD_MTU" = "1400" ]; then
    print_success "Pod MTU matches expected overlay MTU"
elif [ "$POD_MTU" = "1500" ]; then
    print_error "Pod MTU is 1500 - should be 1400 for OVN overlay!"
else
    print_warning "Pod MTU is non-standard: $POD_MTU"
fi

# Test basic connectivity
print_header "Testing basic connectivity to $TARGET_HOST"
if oc exec -n "$AAP_NAMESPACE" "$AAP_POD" -- ping -c 2 -W 2 "$TARGET_HOST" &>/dev/null; then
    print_success "Basic ping successful"
else
    print_error "Basic ping failed - check network connectivity"
    exit 1
fi

# Test MTU with progressive sizes
print_header "Testing path MTU with progressive packet sizes"
MTU_TESTS=(1472 1450 1428 1400 1350 1300 1250 1200)
MAX_WORKING_SIZE=0

for size in "${MTU_TESTS[@]}"; do
    echo -n "Testing $size bytes (MTU $((size + 28)))... "
    if oc exec -n "$AAP_NAMESPACE" "$AAP_POD" -- ping -M do -s "$size" -c 2 -W 2 "$TARGET_HOST" &>/dev/null; then
        print_success "OK"
        if [ "$MAX_WORKING_SIZE" -eq 0 ]; then
            MAX_WORKING_SIZE=$size
        fi
    else
        print_error "FAILED"
        if [ "$MAX_WORKING_SIZE" -eq 0 ]; then
            MAX_WORKING_SIZE=$((size - 1))
        fi
    fi
done

echo ""
if [ "$MAX_WORKING_SIZE" -ge 1472 ]; then
    print_success "No MTU issues detected (working size: $MAX_WORKING_SIZE bytes)"
    EFFECTIVE_MTU=$((MAX_WORKING_SIZE + 28))
    echo "Effective path MTU: $EFFECTIVE_MTU"
elif [ "$MAX_WORKING_SIZE" -ge 1400 ]; then
    print_warning "Minor MTU constraint detected (working size: $MAX_WORKING_SIZE bytes)"
    EFFECTIVE_MTU=$((MAX_WORKING_SIZE + 28))
    echo "Effective path MTU: ~$EFFECTIVE_MTU"
    echo "This may cause issues with some SSH operations"
else
    print_error "Significant MTU constraint detected (working size: $MAX_WORKING_SIZE bytes)"
    EFFECTIVE_MTU=$((MAX_WORKING_SIZE + 28))
    echo "Effective path MTU: ~$EFFECTIVE_MTU"
    echo "This WILL cause SSH connection issues"
fi

# Test path MTU discovery
print_header "Testing Path MTU Discovery (PMTUD)"
echo "Running tracepath to $TARGET_HOST..."
TRACEPATH_OUTPUT=$(oc exec -n "$AAP_NAMESPACE" "$AAP_POD" -- tracepath -n "$TARGET_HOST" 2>/dev/null || echo "tracepath failed")

if echo "$TRACEPATH_OUTPUT" | grep -q "no reply"; then
    print_error "PMTUD blocked - ICMP responses not reaching pod"
    echo "This is likely the root cause of SSH issues"
elif echo "$TRACEPATH_OUTPUT" | grep -q "pmtu"; then
    DISCOVERED_MTU=$(echo "$TRACEPATH_OUTPUT" | grep -oP 'pmtu \K[0-9]+' | tail -1)
    print_success "PMTUD working - discovered MTU: $DISCOVERED_MTU"
else
    print_warning "PMTUD test inconclusive"
fi

echo ""
echo "Tracepath output:"
echo "$TRACEPATH_OUTPUT"

# Test SSH connection
print_header "Testing SSH connection to $TARGET_HOST"
echo "Attempting SSH connection (will timeout after 10 seconds)..."

SSH_OUTPUT=$(oc exec -n "$AAP_NAMESPACE" "$AAP_POD" -- timeout 10 ssh -v -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$TARGET_HOST" 'echo SSH_SUCCESS' 2>&1 || true)

if echo "$SSH_OUTPUT" | grep -q "SSH_SUCCESS"; then
    print_success "SSH connection successful!"
elif echo "$SSH_OUTPUT" | grep -q "Authentication succeeded"; then
    print_error "SSH authenticates but hangs - classic MTU symptom!"
    echo "Connection established but data transfer fails"
elif echo "$SSH_OUTPUT" | grep -q "Connection timed out"; then
    print_error "SSH connection timeout - check firewall/routing"
elif echo "$SSH_OUTPUT" | grep -q "Connection refused"; then
    print_error "SSH connection refused - SSH service not running or port blocked"
elif echo "$SSH_OUTPUT" | grep -q "Permission denied"; then
    print_warning "SSH authentication failed - check credentials (not MTU issue)"
else
    print_warning "SSH test inconclusive"
fi

# Get node MTU for comparison
print_header "Checking node-level MTU"
NODE=$(oc get pod -n "$AAP_NAMESPACE" "$AAP_POD" -o jsonpath='{.spec.nodeName}')
echo "Pod is running on node: $NODE"

echo "Node interface MTU values:"
oc debug "node/$NODE" -- chroot /host ip link show 2>/dev/null | grep -E "^[0-9]+:|mtu" | head -20

# Summary and recommendations
print_header "DIAGNOSTIC SUMMARY"
echo ""

if [ "$MAX_WORKING_SIZE" -ge 1472 ]; then
    echo -e "${GREEN}✓ No MTU issues detected${NC}"
    echo "The effective path MTU is sufficient (>= 1500 bytes)"
    echo ""
    echo "If you're still experiencing SSH issues, check:"
    echo "  - SSH authentication and credentials"
    echo "  - Firewall rules blocking SSH port 22"
    echo "  - SELinux or security policies"
    echo "  - Target host SSH service status"
elif [ "$MAX_WORKING_SIZE" -ge 1350 ]; then
    echo -e "${YELLOW}⚠ MTU constraints detected but manageable${NC}"
    echo "Effective path MTU: ~$EFFECTIVE_MTU bytes"
    echo ""
    echo "Recommended actions (in priority order):"
    echo "  1. Configure Ansible SSH options (see README.md Strategy 1)"
    echo "     Add to inventory:"
    echo "       ansible_ssh_common_args: '-o IPQoS=throughput -o Compression=yes'"
    echo ""
    echo "  2. Test SSH with fix:"
    echo "     oc exec $AAP_POD -- ssh -o IPQoS=throughput -o Compression=yes $TARGET_HOST"
    echo ""
    echo "  3. Request network team to configure MSS clamping (long-term fix)"
else
    echo -e "${RED}✗ Critical MTU issues detected${NC}"
    echo "Effective path MTU: ~$EFFECTIVE_MTU bytes (too low)"
    echo ""
    echo "Immediate actions required (in priority order):"
    echo "  1. Work with network team:"
    echo "     - Configure MSS clamping on routers/firewalls (MSS = $((EFFECTIVE_MTU - 40)))"
    echo "     - Allow ICMP type 3 code 4 through firewalls"
    echo ""
    echo "  2. Apply Ansible workarounds:"
    echo "     ansible_ssh_common_args: '-o IPQoS=throughput -o Compression=yes'"
    echo "     Enable pipelining in ansible.cfg"
    echo ""
    echo "  3. Consider network architecture review for sustained operations"
fi

echo ""
echo -e "${YELLOW}Note: SSH configuration has limited direct MTU control.${NC}"
echo "Options like IPQoS and Compression influence behavior indirectly."
echo "For persistent issues, network-level fixes (MSS clamping) are most effective."

echo ""
print_header "Next Steps"
echo "1. Review full diagnostics in: ocp-troubleshooting/aap-ssh-mtu-issues/README.md"
echo "2. Check quick fixes in: ocp-troubleshooting/aap-ssh-mtu-issues/QUICK-REFERENCE.md"
echo "3. See real scenarios in: ocp-troubleshooting/aap-ssh-mtu-issues/EXAMPLES.md"
echo ""
echo "To apply recommended SSH configuration:"
echo "  Add to AAP inventory host vars:"
echo "    ansible_ssh_common_args: '-o IPQoS=throughput -o Compression=yes'"
echo ""
echo "  Or in ansible.cfg for project-wide settings:"
echo "    [ssh_connection]"
echo "    pipelining = True"
echo "    ssh_args = -o IPQoS=throughput -o Compression=yes"
echo ""

print_header "Diagnostic complete"

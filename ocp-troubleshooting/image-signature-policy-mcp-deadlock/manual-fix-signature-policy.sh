#!/bin/bash
#
# Manual fix for container signature policy blocking MCP rollout
#
# This script updates /etc/containers/policy.json on all cluster nodes
# to allow Red Hat signed images when MachineConfigPool is deadlocked.
#
# Usage: ./manual-fix-signature-policy.sh
#
# Requirements:
# - Logged into OpenShift cluster with cluster-admin privileges
# - oc CLI available
# - jq installed (for JSON formatting)
#
# AI Disclosure: This script was created with AI assistance.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v oc &> /dev/null; then
        log_error "oc CLI not found. Please install OpenShift CLI."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq not found. JSON formatting will be skipped."
        JQ_AVAILABLE=false
    else
        JQ_AVAILABLE=true
    fi
    
    if ! oc whoami &> /dev/null; then
        log_error "Not logged into OpenShift cluster. Please run: oc login"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create the corrected policy.json
create_policy_json() {
    log_info "Creating corrected policy.json..."
    
    cat > /tmp/policy.json << 'EOF'
{
  "default": [
    {
      "type": "insecureAcceptAnything"
    }
  ],
  "transports": {
    "docker-daemon": {
      "": [{"type": "insecureAcceptAnything"}]
    },
    "docker": {
      "registry.redhat.io": [
        {
          "type": "signedBy",
          "keyType": "GPGKeys",
          "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
        }
      ],
      "registry.access.redhat.com": [
        {
          "type": "signedBy",
          "keyType": "GPGKeys",
          "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
        }
      ],
      "catalog.redhat.com": [
        {
          "type": "signedBy",
          "keyType": "GPGKeys",
          "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
        }
      ]
    }
  }
}
EOF
    
    if [ "$JQ_AVAILABLE" = true ]; then
        log_info "Policy content:"
        jq . /tmp/policy.json
    fi
    
    log_success "Policy file created at /tmp/policy.json"
}

# Get list of all nodes
get_nodes() {
    log_info "Getting list of cluster nodes..."
    
    NODES=$(oc get nodes -o jsonpath='{.items[*].metadata.name}')
    NODE_COUNT=$(echo "$NODES" | wc -w)
    
    if [ -z "$NODES" ]; then
        log_error "No nodes found in cluster"
        exit 1
    fi
    
    log_success "Found $NODE_COUNT nodes: $(echo $NODES | tr ' ' ', ')"
}

# Fix a single node
fix_node() {
    local NODE=$1
    local TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    
    log_info "Processing node: $NODE"
    
    # Backup existing policy
    log_info "  → Backing up existing policy.json..."
    if oc debug node/$NODE -- chroot /host bash -c \
        "cp /etc/containers/policy.json /etc/containers/policy.json.backup.$TIMESTAMP" 2>&1 | grep -v "Starting pod" | grep -v "Removing debug pod"; then
        log_success "  → Backup created: policy.json.backup.$TIMESTAMP"
    else
        log_warning "  → Backup failed, continuing anyway..."
    fi
    
    # Deploy new policy
    log_info "  → Deploying new policy.json..."
    if cat /tmp/policy.json | oc debug node/$NODE -- chroot /host bash -c \
        "cat > /etc/containers/policy.json" 2>&1 | grep -v "Starting pod" | grep -v "Removing debug pod"; then
        log_success "  → New policy deployed"
    else
        log_error "  → Failed to deploy policy to $NODE"
        return 1
    fi
    
    # Restart CRI-O
    log_info "  → Restarting CRI-O service..."
    if oc debug node/$NODE -- chroot /host bash -c \
        "systemctl restart crio && sleep 5 && systemctl is-active crio" 2>&1 | grep -v "Starting pod" | grep -v "Removing debug pod" | tail -1 | grep -q "active"; then
        log_success "  → CRI-O restarted successfully"
    else
        log_error "  → Failed to restart CRI-O on $NODE"
        return 1
    fi
    
    log_success "✓ Node $NODE fixed successfully"
    echo ""
}

# Verify the fix on a single node
verify_node() {
    local NODE=$1
    
    log_info "Verifying node: $NODE"
    
    # Check CRI-O status
    local CRIO_STATUS=$(oc debug node/$NODE -- chroot /host bash -c \
        "systemctl is-active crio" 2>&1 | grep -v "Starting pod" | grep -v "Removing debug pod" | tail -1)
    
    if [ "$CRIO_STATUS" = "active" ]; then
        log_success "  → CRI-O is active"
    else
        log_error "  → CRI-O is not active (status: $CRIO_STATUS)"
        return 1
    fi
    
    # Check policy.json exists and has Red Hat registries
    local REGISTRIES=$(oc debug node/$NODE -- chroot /host bash -c \
        "cat /etc/containers/policy.json | grep -o 'registry\.redhat\.io' | head -1" 2>&1 | grep -v "Starting pod" | grep -v "Removing debug pod" | tail -1)
    
    if [ "$REGISTRIES" = "registry.redhat.io" ]; then
        log_success "  → Policy includes Red Hat registries"
    else
        log_error "  → Policy does not include Red Hat registries"
        return 1
    fi
    
    log_success "✓ Node $NODE verification passed"
}

# Main execution
main() {
    echo "================================================"
    echo "Container Signature Policy Manual Fix Script"
    echo "================================================"
    echo ""
    
    check_prerequisites
    echo ""
    
    create_policy_json
    echo ""
    
    get_nodes
    echo ""
    
    log_warning "This script will:"
    log_warning "  1. Backup existing policy.json on all nodes"
    log_warning "  2. Deploy new policy.json with Red Hat registry support"
    log_warning "  3. Restart CRI-O service on all nodes"
    log_warning ""
    log_warning "Note: CRI-O restart will briefly disrupt pod operations on each node"
    echo ""
    
    read -p "Continue? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        log_info "Aborted by user"
        exit 0
    fi
    
    echo ""
    log_info "Starting node fixes..."
    echo ""
    
    FAILED_NODES=""
    SUCCESS_COUNT=0
    
    for NODE in $NODES; do
        if fix_node "$NODE"; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            FAILED_NODES="$FAILED_NODES $NODE"
        fi
    done
    
    echo ""
    echo "================================================"
    echo "Fix Complete"
    echo "================================================"
    log_success "Successfully fixed: $SUCCESS_COUNT/$NODE_COUNT nodes"
    
    if [ -n "$FAILED_NODES" ]; then
        log_error "Failed nodes:$FAILED_NODES"
    fi
    
    echo ""
    log_info "Verifying fixes..."
    echo ""
    
    for NODE in $NODES; do
        verify_node "$NODE" || true
    done
    
    echo ""
    echo "================================================"
    echo "Next Steps"
    echo "================================================"
    echo "1. Wait 2-3 minutes for pods to restart"
    echo "2. Check for image pull errors:"
    echo "   oc get pods -A | grep -E 'ImagePullBackOff|ErrImagePull'"
    echo ""
    echo "3. Monitor MCP progress:"
    echo "   watch oc get mcp"
    echo ""
    echo "4. After MCP completes, apply permanent MachineConfig:"
    echo "   oc apply -f signature-policy-machineconfig.yaml"
    echo ""
    
    log_success "Script execution complete"
}

# Run main function
main "$@"

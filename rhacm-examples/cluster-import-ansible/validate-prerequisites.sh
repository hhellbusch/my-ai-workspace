#!/bin/bash
# Validation script to check prerequisites before running playbook
#
# Usage: ./validate-prerequisites.sh

set -e

echo "=========================================="
echo "RHACM Cluster Import - Prerequisites Check"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check function
check_command() {
    local cmd=$1
    local name=$2
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name found: $(command -v $cmd)"
        return 0
    else
        echo -e "${RED}✗${NC} $name not found"
        return 1
    fi
}

# Check version function
check_version() {
    local cmd=$1
    local name=$2
    
    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n 1)
        echo -e "${GREEN}✓${NC} $name version: $version"
        return 0
    else
        echo -e "${RED}✗${NC} $name not found"
        return 1
    fi
}

ERRORS=0

# Check Ansible
echo "Checking Ansible installation..."
if check_version ansible --version "Ansible"; then
    # Check Ansible version
    ANSIBLE_VERSION=$(ansible --version | head -n 1 | grep -oP '\d+\.\d+' | head -n 1)
    MAJOR=$(echo $ANSIBLE_VERSION | cut -d. -f1)
    MINOR=$(echo $ANSIBLE_VERSION | cut -d. -f2)
    
    if [ "$MAJOR" -ge 2 ] && [ "$MINOR" -ge 15 ]; then
        echo -e "${GREEN}✓${NC} Ansible version 2.15+ requirement met"
    else
        echo -e "${YELLOW}⚠${NC} Ansible 2.15+ recommended (found $ANSIBLE_VERSION)"
    fi
else
    echo -e "${RED}✗${NC} Ansible not installed. Install with: pip install ansible-core"
    ERRORS=$((ERRORS+1))
fi
echo ""

# Check kubernetes.core collection
echo "Checking Ansible collections..."
if ansible-galaxy collection list | grep -q kubernetes.core; then
    COLLECTION_VERSION=$(ansible-galaxy collection list | grep kubernetes.core | awk '{print $2}')
    echo -e "${GREEN}✓${NC} kubernetes.core collection installed: $COLLECTION_VERSION"
else
    echo -e "${RED}✗${NC} kubernetes.core collection not found"
    echo "Install with: ansible-galaxy collection install kubernetes.core"
    ERRORS=$((ERRORS+1))
fi
echo ""

# Check kubectl/oc
echo "Checking Kubernetes CLI tools..."
if check_command oc "OpenShift CLI"; then
    :
elif check_command kubectl "Kubernetes CLI"; then
    :
else
    echo -e "${RED}✗${NC} Neither 'oc' nor 'kubectl' found"
    echo "Install OpenShift CLI or kubectl"
    ERRORS=$((ERRORS+1))
fi
echo ""

# Check Python dependencies
echo "Checking Python dependencies..."
if python3 -c "import kubernetes" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Python kubernetes module installed"
else
    echo -e "${YELLOW}⚠${NC} Python kubernetes module not found"
    echo "Install with: pip install kubernetes"
fi

if python3 -c "import yaml" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Python yaml module installed"
else
    echo -e "${YELLOW}⚠${NC} Python yaml module not found"
    echo "Install with: pip install pyyaml"
fi
echo ""

# Check inventory file
echo "Checking inventory configuration..."
if [ -f "inventory/hosts.ini" ]; then
    echo -e "${GREEN}✓${NC} Inventory file exists: inventory/hosts.ini"
    
    # Check if default paths are still present
    if grep -q "/path/to/" inventory/hosts.ini; then
        echo -e "${YELLOW}⚠${NC} Inventory contains default placeholder paths"
        echo "Edit inventory/hosts.ini and update kubeconfig paths"
    else
        echo -e "${GREEN}✓${NC} Inventory appears to be configured"
    fi
else
    echo -e "${RED}✗${NC} Inventory file not found: inventory/hosts.ini"
    ERRORS=$((ERRORS+1))
fi
echo ""

# Summary
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All critical prerequisites met${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Edit inventory/hosts.ini with your cluster details"
    echo "2. Edit group_vars/target_clusters.yml with desired configuration"
    echo "3. Run: ansible-playbook -i inventory/hosts.ini import-cluster.yml --limit <cluster-name>"
    exit 0
else
    echo -e "${RED}✗ $ERRORS critical prerequisite(s) missing${NC}"
    echo ""
    echo "Fix the errors above before running the playbook"
    exit 1
fi

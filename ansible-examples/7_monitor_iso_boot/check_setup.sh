#!/bin/bash
# Quick setup verification script

echo "================================================"
echo "Ansible Setup Verification"
echo "================================================"
echo ""

# Check Ansible version
echo "1. Ansible Version:"
if command -v ansible &> /dev/null; then
    ansible --version | head -1
else
    echo "❌ Ansible not installed"
    exit 1
fi
echo ""

# Check Python version
echo "2. Python Version:"
python3 --version
echo ""

# Check collections
echo "3. Installed Collections:"
echo ""

echo "   community.general:"
if ansible-galaxy collection list community.general 2>/dev/null | grep -q "community.general"; then
    version=$(ansible-galaxy collection list community.general 2>/dev/null | grep "community.general" | awk '{print $2}')
    echo "   ✅ Installed (version: $version)"
else
    echo "   ❌ NOT INSTALLED"
    echo "   Install with: ansible-galaxy collection install community.general"
fi
echo ""

echo "   dellemc.openmanage (optional):"
if ansible-galaxy collection list dellemc.openmanage 2>/dev/null | grep -q "dellemc.openmanage"; then
    version=$(ansible-galaxy collection list dellemc.openmanage 2>/dev/null | grep "dellemc.openmanage" | awk '{print $2}')
    echo "   ✅ Installed (version: $version)"
else
    echo "   ⚠️  Not installed (optional)"
    echo "   Install with: ansible-galaxy collection install dellemc.openmanage"
fi
echo ""

# Check module availability
echo "4. Checking redfish_info Module:"
if ansible-doc community.general.redfish_info &>/dev/null; then
    echo "   ✅ Module is available"
else
    echo "   ❌ Module NOT available"
fi
echo ""

# Check collection paths
echo "5. Collection Search Paths:"
ansible-config dump 2>/dev/null | grep COLLECTIONS_PATHS | head -1
echo ""

echo "================================================"
echo "Setup Status"
echo "================================================"

# Determine overall status
if ansible-doc community.general.redfish_info &>/dev/null; then
    echo "✅ Setup is complete - ready to run playbooks!"
    echo ""
    echo "Try: ansible-playbook -i inventory.simple.yml simple_monitor_module.yml"
else
    echo "❌ Setup incomplete - install required collections"
    echo ""
    echo "Run: ansible-galaxy collection install -r requirements.yml"
fi
echo ""

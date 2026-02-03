#!/bin/bash
# Quick setup script for Dell memory validation playbook

set -e

echo "════════════════════════════════════════════════════════════"
echo "  Dell PowerEdge Memory Validation - Setup"
echo "════════════════════════════════════════════════════════════"
echo

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible not found"
    echo "   Install with: sudo dnf install ansible"
    echo "   Or: pip install ansible"
    exit 1
fi

echo "✓ Ansible found: $(ansible --version | head -1)"
echo

# Install required collections
echo "Installing required Ansible collections..."
ansible-galaxy collection install -r requirements.yml
echo "✓ Collections installed"
echo

# Create necessary directories
mkdir -p group_vars/all
mkdir -p reports
echo "✓ Directories created"
echo

# Check if inventory exists
if [ ! -f inventory.yml ]; then
    echo "Creating inventory.yml from example..."
    cp inventory.example.yml inventory.yml
    echo "✓ inventory.yml created"
    echo "⚠ IMPORTANT: Edit inventory.yml with your servers!"
else
    echo "✓ inventory.yml already exists"
fi
echo

# Check if vault exists
if [ ! -f group_vars/all/vault.yml ]; then
    echo "Creating encrypted vault for credentials..."
    echo "You'll be prompted to:"
    echo "1. Create a vault password"
    echo "2. Add your iDRAC credentials"
    echo
    read -p "Press Enter to create vault (or Ctrl+C to skip)..."
    
    ansible-vault create group_vars/all/vault.yml <<EOF || true
# Edit this file to add your iDRAC credentials
# Example:
# vault_idrac_user: root
# vault_idrac_password: your-password-here
EOF
    
    if [ -f group_vars/all/vault.yml ]; then
        echo "✓ Vault created"
    else
        echo "⚠ Vault creation skipped"
        echo "  Create manually: ansible-vault create group_vars/all/vault.yml"
    fi
else
    echo "✓ Vault already exists"
fi
echo

echo "════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════"
echo
echo "Next steps:"
echo "1. Edit inventory.yml with your server details"
echo "2. Verify vault credentials: ansible-vault view group_vars/all/vault.yml"
echo "3. Test connectivity: ansible dell_servers -i inventory.yml -m ping --ask-vault-pass"
echo "4. Run audit: ansible-playbook -i inventory.yml memory_audit.yml --ask-vault-pass"
echo
echo "For detailed instructions, see: README.md"
echo



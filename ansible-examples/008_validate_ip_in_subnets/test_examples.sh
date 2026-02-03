#!/bin/bash
# Test script for IP subnet validation examples

set -e

echo "=========================================="
echo "Testing IP Subnet Validation Examples"
echo "=========================================="
echo ""

# Check if ansible.utils collection is installed
echo "Checking for ansible.utils collection..."
if ansible-galaxy collection list | grep -q "ansible.utils"; then
    echo "✓ ansible.utils collection is installed"
else
    echo "✗ ansible.utils collection not found"
    echo "Installing ansible.utils collection..."
    ansible-galaxy collection install ansible.utils
fi

echo ""
echo "----------------------------------------"
echo "Test 1: Simple Playbook"
echo "----------------------------------------"
ansible-playbook simple_playbook.yml

echo ""
echo "----------------------------------------"
echo "Test 2: Complete Validation"
echo "----------------------------------------"
echo "Note: This will fail because some default IPs are invalid (expected behavior):"
ansible-playbook complete_validation.yml || echo "✓ Validation correctly caught invalid IPs"

echo ""
echo "----------------------------------------"
echo "Test 3: Complete Validation (All Valid IPs)"
echo "----------------------------------------"
echo "Testing with only valid IPs - should succeed:"
ansible-playbook complete_validation.yml -e '{"ip_addresses_to_check": ["10.50.100.25", "172.16.5.10", "192.168.1.50", "203.0.113.15"]}'

echo ""
echo "----------------------------------------"
echo "Test 4: Practical Example"
echo "----------------------------------------"
ansible-playbook practical_example.yml

echo ""
echo "=========================================="
echo "All tests completed!"
echo "=========================================="


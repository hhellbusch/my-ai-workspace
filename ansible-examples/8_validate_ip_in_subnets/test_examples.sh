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
ansible-playbook complete_validation.yml

echo ""
echo "----------------------------------------"
echo "Test 3: Complete Validation (Strict Mode)"
echo "----------------------------------------"
echo "This should fail because some IPs are invalid:"
ansible-playbook complete_validation.yml -e "fail_on_invalid=true" || echo "Expected failure - validation caught invalid IPs"

echo ""
echo "----------------------------------------"
echo "Test 4: Practical Example"
echo "----------------------------------------"
ansible-playbook practical_example.yml

echo ""
echo "=========================================="
echo "All tests completed!"
echo "=========================================="


#!/bin/bash
# Test script to verify iDRAC connectivity and API access

if [ $# -lt 2 ]; then
    echo "Usage: $0 <idrac_ip> <username> [password]"
    echo "Example: $0 192.168.10.101 root"
    exit 1
fi

IDRAC_IP=$1
USERNAME=$2

if [ -z "$3" ]; then
    read -s -p "iDRAC Password: " PASSWORD
    echo
else
    PASSWORD=$3
fi

echo "════════════════════════════════════════════════════════════"
echo "  Testing iDRAC Access: $IDRAC_IP"
echo "════════════════════════════════════════════════════════════"
echo

# Test 1: Basic connectivity
echo "[1/5] Testing network connectivity..."
if ping -c 1 -W 2 "$IDRAC_IP" &> /dev/null; then
    echo "✓ Ping successful"
else
    echo "✗ Ping failed - check network connectivity"
    exit 1
fi
echo

# Test 2: HTTPS accessibility
echo "[2/5] Testing HTTPS access..."
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" "https://${IDRAC_IP}/")
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 301 ] || [ "$HTTP_CODE" -eq 302 ]; then
    echo "✓ HTTPS accessible (HTTP $HTTP_CODE)"
else
    echo "✗ HTTPS not accessible (HTTP $HTTP_CODE)"
    exit 1
fi
echo

# Test 3: Redfish API root
echo "[3/5] Testing Redfish API root..."
REDFISH_RESPONSE=$(curl -k -s -u "${USERNAME}:${PASSWORD}" \
    "https://${IDRAC_IP}/redfish/v1/" 2>&1)

if echo "$REDFISH_RESPONSE" | grep -q "ServiceRoot"; then
    echo "✓ Redfish API accessible"
    REDFISH_VERSION=$(echo "$REDFISH_RESPONSE" | grep -o '"RedfishVersion":"[^"]*"' | cut -d'"' -f4)
    echo "  Redfish Version: ${REDFISH_VERSION:-Unknown}"
else
    echo "✗ Redfish API not accessible"
    echo "  Response: $REDFISH_RESPONSE"
    exit 1
fi
echo

# Test 4: Memory endpoint
echo "[4/5] Testing Memory inventory endpoint..."
MEMORY_RESPONSE=$(curl -k -s -u "${USERNAME}:${PASSWORD}" \
    "https://${IDRAC_IP}/redfish/v1/Systems/System.Embedded.1/Memory")

if echo "$MEMORY_RESPONSE" | grep -q "Members"; then
    echo "✓ Memory endpoint accessible"
    MEMBER_COUNT=$(echo "$MEMORY_RESPONSE" | grep -o '"Members@odata.count":[0-9]*' | cut -d: -f2)
    echo "  Memory modules found: ${MEMBER_COUNT:-Unknown}"
else
    echo "✗ Memory endpoint not accessible"
    echo "  This might be a license limitation (Enterprise required)"
fi
echo

# Test 5: SEL endpoint
echo "[5/5] Testing System Event Log endpoint..."
SEL_RESPONSE=$(curl -k -s -u "${USERNAME}:${PASSWORD}" \
    "https://${IDRAC_IP}/redfish/v1/Managers/iDRAC.Embedded.1/LogServices/Sel/Entries")

if echo "$SEL_RESPONSE" | grep -q "Members"; then
    echo "✓ SEL endpoint accessible"
    SEL_COUNT=$(echo "$SEL_RESPONSE" | grep -o '"Members@odata.count":[0-9]*' | cut -d: -f2)
    echo "  SEL entries: ${SEL_COUNT:-Unknown}"
else
    echo "⚠ SEL endpoint might not be accessible"
fi
echo

echo "════════════════════════════════════════════════════════════"
echo "  Test Summary"
echo "════════════════════════════════════════════════════════════"
echo "✓ iDRAC is accessible and ready for automation"
echo
echo "Next: Run the Ansible playbook:"
echo "  ansible-playbook -i inventory.yml memory_audit.yml --ask-vault-pass"
echo



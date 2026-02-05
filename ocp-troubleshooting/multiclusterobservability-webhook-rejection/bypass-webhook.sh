#!/bin/bash

# Quick script to bypass MCO webhook validation
# Use this when metadata.name IS present but webhook still rejects with "resource name may not be empty"

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== MCO Webhook Bypass Utility ===${NC}"
echo ""
echo "This script disables the validating webhook that's incorrectly rejecting your MCO resource."
echo ""

# Check cluster connection
if ! oc whoami &>/dev/null; then
    echo -e "${RED}✗ Not connected to cluster${NC}"
    echo "  Please login first: oc login <cluster-url>"
    exit 1
fi

echo -e "${GREEN}✓ Connected to cluster as $(oc whoami)${NC}"
echo ""

# Find the webhook
echo -e "${YELLOW}[1/4] Finding webhook...${NC}"
WEBHOOK_NAME=$(oc get validatingwebhookconfigurations 2>/dev/null | grep -i vmulticlusterobservability | awk '{print $1}')

if [ -z "$WEBHOOK_NAME" ]; then
    echo -e "${RED}✗ Could not find vmulticlusterobservability webhook${NC}"
    echo ""
    echo "Available webhooks:"
    oc get validatingwebhookconfigurations | grep -i observability || echo "  None found"
    echo ""
    echo "Trying alternative webhook names..."
    
    # Try alternative patterns
    WEBHOOK_NAME=$(oc get validatingwebhookconfigurations 2>/dev/null | grep -i "multicluster.*observability" | awk '{print $1}' | head -1)
    
    if [ -z "$WEBHOOK_NAME" ]; then
        echo -e "${RED}✗ No observability webhooks found${NC}"
        echo ""
        echo "This might mean:"
        echo "  1. The webhook hasn't been created yet"
        echo "  2. The observability operator isn't running"
        echo "  3. You need different permissions"
        echo ""
        echo "Check operator status:"
        echo "  oc get pods -n open-cluster-management"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Found webhook: $WEBHOOK_NAME${NC}"
echo ""

# Check current policy
echo -e "${YELLOW}[2/4] Checking current webhook policy...${NC}"
CURRENT_POLICY=$(oc get validatingwebhookconfigurations $WEBHOOK_NAME -o jsonpath='{.webhooks[0].failurePolicy}' 2>/dev/null || echo "Unknown")
echo "   Current policy: $CURRENT_POLICY"

if [ "$CURRENT_POLICY" = "Ignore" ]; then
    echo -e "${YELLOW}⚠  Webhook is already set to Ignore failures${NC}"
    echo "   Your operations should already be able to proceed"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi
echo ""

# Disable webhook
echo -e "${YELLOW}[3/4] Disabling webhook validation...${NC}"
if oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]' &>/dev/null; then
    echo -e "${GREEN}✓ Webhook validation disabled${NC}"
    echo "   Policy changed from '$CURRENT_POLICY' to 'Ignore'"
else
    echo -e "${RED}✗ Failed to patch webhook configuration${NC}"
    echo ""
    echo "You may need additional permissions. Try:"
    echo "  oc adm policy add-cluster-role-to-user cluster-admin $(oc whoami)"
    exit 1
fi
echo ""

# Instructions
echo -e "${YELLOW}[4/4] Ready to proceed${NC}"
echo ""
echo -e "${GREEN}✓ Webhook bypass complete!${NC}"
echo ""
echo "You can now run your MCO operations without webhook interference:"
echo ""
echo -e "${BLUE}Examples:${NC}"
echo "  oc delete multiclusterobservability observability"
echo "  oc apply -f your-mco.yaml"
echo "  oc edit multiclusterobservability observability"
echo "  oc patch multiclusterobservability observability -p '{...}'"
echo ""
echo -e "${YELLOW}Note:${NC} The webhook will stay disabled until you re-enable it."
echo ""
echo "To re-enable the webhook later (optional):"
echo "  oc patch validatingwebhookconfigurations $WEBHOOK_NAME --type='json' \\"
echo "    -p='[{\"op\": \"replace\", \"path\": \"/webhooks/0/failurePolicy\", \"value\":\"Fail\"}]'"
echo ""

# Offer to run a command
echo -e "${BLUE}Would you like to run a command now?${NC}"
echo "1) Delete MCO"
echo "2) Edit MCO"  
echo "3) Apply YAML file"
echo "4) Exit (I'll run my own command)"
echo ""
read -p "Choose option (1-4): " -n 1 -r
echo ""
echo ""

case $REPLY in
    1)
        # Get MCO name
        MCO_NAME=$(oc get multiclusterobservability -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
        if [ -z "$MCO_NAME" ]; then
            echo "No MCO resources found"
            exit 0
        fi
        
        echo "Found MCO: $MCO_NAME"
        read -p "Delete $MCO_NAME? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            oc delete multiclusterobservability $MCO_NAME
            echo ""
            echo "Verifying deletion..."
            sleep 2
            oc get multiclusterobservability || echo "✓ Successfully deleted"
        fi
        ;;
    2)
        # Get MCO name
        MCO_NAME=$(oc get multiclusterobservability -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
        if [ -z "$MCO_NAME" ]; then
            echo "No MCO resources found"
            exit 0
        fi
        
        echo "Editing $MCO_NAME..."
        oc edit multiclusterobservability $MCO_NAME
        ;;
    3)
        read -p "Enter YAML file path: " YAML_FILE
        if [ -f "$YAML_FILE" ]; then
            echo "Applying $YAML_FILE..."
            oc apply -f "$YAML_FILE"
            echo ""
            echo "Verifying..."
            sleep 2
            oc get multiclusterobservability
        else
            echo "File not found: $YAML_FILE"
        fi
        ;;
    4)
        echo "Webhook is bypassed. Run your commands now."
        ;;
    *)
        echo "Invalid option. Webhook is bypassed. Run your commands now."
        ;;
esac

echo ""
echo -e "${GREEN}Done!${NC}"

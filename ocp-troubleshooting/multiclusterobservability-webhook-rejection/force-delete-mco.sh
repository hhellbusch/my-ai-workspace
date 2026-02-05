#!/bin/bash

# Force delete MultiClusterObservability when it hangs forever
# This script handles the webhook-finalizer catch-22 situation
#
# Usage: ./force-delete-mco.sh [mco-name]
# If no name provided, will auto-detect

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Force Delete MultiClusterObservability ===${NC}"
echo ""
echo "This script will:"
echo "  1. Disable the validating webhook"
echo "  2. Scale down the observability operator (prevents finalizer re-addition)"
echo "  3. Remove all finalizers from the MCO resource"
echo "  4. Force delete the MCO"
echo "  5. Scale the operator back up"
echo ""

# Check cluster connection
if ! oc whoami &>/dev/null; then
    echo -e "${RED}✗ Not connected to cluster${NC}"
    echo "  Please login first: oc login <cluster-url>"
    exit 1
fi

echo -e "${GREEN}✓ Connected as $(oc whoami)${NC}"
echo ""

# Get MCO name
if [ $# -eq 1 ]; then
    MCO_NAME=$1
else
    MCO_NAME=$(oc get multiclusterobservability -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$MCO_NAME" ]; then
        echo -e "${RED}✗ No MultiClusterObservability resources found${NC}"
        exit 1
    fi
fi

echo -e "Target MCO: ${YELLOW}$MCO_NAME${NC}"
echo ""

# Confirm
read -p "Continue with force deletion? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi
echo ""

# Step 1: Disable webhook
echo -e "${YELLOW}[1/5] Disabling validating webhook...${NC}"
WEBHOOK=$(oc get validatingwebhookconfigurations 2>/dev/null | grep vmulticlusterobservability | awk '{print $1}' || echo "")

if [ -n "$WEBHOOK" ]; then
    if oc patch validatingwebhookconfigurations $WEBHOOK --type='json' \
      -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]' &>/dev/null; then
        echo -e "${GREEN}✓ Webhook disabled: $WEBHOOK${NC}"
    else
        echo -e "${YELLOW}⚠ Could not disable webhook (may not be necessary)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No webhook found (OK)${NC}"
fi
echo ""

# Step 2: Scale down operator
echo -e "${YELLOW}[2/5] Scaling down observability operator...${NC}"
if oc get deployment multicluster-observability-operator -n open-cluster-management &>/dev/null; then
    ORIGINAL_REPLICAS=$(oc get deployment multicluster-observability-operator -n open-cluster-management -o jsonpath='{.spec.replicas}')
    
    if oc scale deployment multicluster-observability-operator -n open-cluster-management --replicas=0 &>/dev/null; then
        echo -e "${GREEN}✓ Operator scaled to 0 (was $ORIGINAL_REPLICAS)${NC}"
        echo "  Waiting 5 seconds for operator to stop..."
        sleep 5
    else
        echo -e "${YELLOW}⚠ Could not scale operator (continuing anyway)${NC}"
        ORIGINAL_REPLICAS=1
    fi
else
    echo -e "${YELLOW}⚠ Operator not found (OK)${NC}"
    ORIGINAL_REPLICAS=1
fi
echo ""

# Step 3: Remove finalizers
echo -e "${YELLOW}[3/5] Removing finalizers...${NC}"
CURRENT_FINALIZERS=$(oc get multiclusterobservability $MCO_NAME -o jsonpath='{.metadata.finalizers}' 2>/dev/null || echo "[]")
echo "  Current finalizers: $CURRENT_FINALIZERS"

if [ "$CURRENT_FINALIZERS" != "[]" ] && [ -n "$CURRENT_FINALIZERS" ]; then
    if oc patch multiclusterobservability $MCO_NAME -p '{"metadata":{"finalizers":null}}' --type=merge &>/dev/null; then
        echo -e "${GREEN}✓ Finalizers removed${NC}"
    else
        echo -e "${RED}✗ Could not remove finalizers${NC}"
        echo "  Trying alternative method..."
        
        # Try with replace
        oc get multiclusterobservability $MCO_NAME -o json | \
          jq 'del(.metadata.finalizers)' | \
          oc replace -f - &>/dev/null && echo -e "${GREEN}✓ Finalizers removed (via replace)${NC}" || echo -e "${RED}✗ Failed${NC}"
    fi
else
    echo -e "${GREEN}✓ No finalizers present${NC}"
fi
echo ""

# Step 4: Force delete
echo -e "${YELLOW}[4/5] Force deleting MCO...${NC}"
oc delete multiclusterobservability $MCO_NAME --grace-period=0 --force --timeout=15s &>/dev/null &
DELETE_PID=$!

# Wait with progress indicator
for i in {1..15}; do
    if ! oc get multiclusterobservability $MCO_NAME &>/dev/null; then
        echo -e "${GREEN}✓ MCO deleted successfully${NC}"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

# Check if still there
if oc get multiclusterobservability $MCO_NAME &>/dev/null; then
    echo -e "${YELLOW}⚠ MCO still exists, trying direct API deletion...${NC}"
    
    API_SERVER=$(oc whoami --show-server)
    TOKEN=$(oc whoami -t)
    
    HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -X DELETE \
      -H "Authorization: Bearer $TOKEN" \
      "${API_SERVER}/apis/observability.open-cluster-management.io/v1beta2/multiclusterobservabilities/$MCO_NAME")
    
    echo "  HTTP response: $HTTP_CODE"
    
    sleep 5
    
    if oc get multiclusterobservability $MCO_NAME &>/dev/null; then
        echo -e "${RED}✗ MCO still exists after direct API call${NC}"
        echo ""
        echo "This requires manual etcd intervention. Options:"
        echo "  1. Contact your cluster administrator"
        echo "  2. Use etcdctl to remove the resource directly"
        echo "  3. Wait for the operator to reconcile (may take time)"
        echo ""
        echo "The resource is stuck in etcd. Current state:"
        oc get multiclusterobservability $MCO_NAME -o yaml | head -30
        
        # Don't scale operator back up if deletion failed
        ORIGINAL_REPLICAS=0
    else
        echo -e "${GREEN}✓ MCO deleted via direct API call${NC}"
    fi
else
    echo -e "${GREEN}✓ MCO successfully deleted${NC}"
fi
echo ""

# Step 5: Scale operator back up
if [ "$ORIGINAL_REPLICAS" -gt 0 ]; then
    echo -e "${YELLOW}[5/5] Scaling operator back to $ORIGINAL_REPLICAS...${NC}"
    if oc scale deployment multicluster-observability-operator -n open-cluster-management --replicas=$ORIGINAL_REPLICAS &>/dev/null; then
        echo -e "${GREEN}✓ Operator scaled back up${NC}"
    else
        echo -e "${YELLOW}⚠ Could not scale operator back up${NC}"
        echo "  Manually restore with:"
        echo "    oc scale deployment multicluster-observability-operator -n open-cluster-management --replicas=$ORIGINAL_REPLICAS"
    fi
else
    echo -e "${YELLOW}[5/5] Skipping operator scale-up (deletion may have failed)${NC}"
fi
echo ""

# Final verification
echo -e "${BLUE}=== Final Status ===${NC}"
if oc get multiclusterobservability $MCO_NAME &>/dev/null; then
    echo -e "${RED}✗ MCO still exists${NC}"
    echo ""
    echo "Resource state:"
    oc get multiclusterobservability $MCO_NAME -o yaml | grep -A 5 "metadata:"
    exit 1
else
    echo -e "${GREEN}✓ MCO successfully removed${NC}"
    echo ""
    echo "Verification:"
    oc get multiclusterobservability 2>&1 || echo "  No MCO resources found (expected)"
    echo ""
    echo "Observability namespace cleanup:"
    oc get pods -n open-cluster-management-observability 2>&1 || echo "  Namespace may be terminating"
fi

# Re-enable webhook (optional)
if [ -n "$WEBHOOK" ]; then
    echo ""
    read -p "Re-enable webhook validation? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        oc patch validatingwebhookconfigurations $WEBHOOK --type='json' \
          -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Fail"}]' &>/dev/null
        echo -e "${GREEN}✓ Webhook re-enabled${NC}"
    else
        echo "Webhook left disabled. Re-enable with:"
        echo "  oc patch validatingwebhookconfigurations $WEBHOOK --type='json' \\"
        echo "    -p='[{\"op\": \"replace\", \"path\": \"/webhooks/0/failurePolicy\", \"value\":\"Fail\"}]'"
    fi
fi

echo ""
echo -e "${GREEN}Done!${NC}"

#!/bin/bash

# Nuclear option for deleting MCO when webhook disable doesn't work
# This tries progressively more aggressive methods

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}=== NUCLEAR MCO DELETION ===${NC}"
echo ""
echo -e "${YELLOW}⚠️  WARNING: This uses aggressive methods to force deletion${NC}"
echo ""

# Check connection
if ! oc whoami &>/dev/null; then
    echo -e "${RED}✗ Not connected to cluster${NC}"
    exit 1
fi

MCO_NAME=$(oc get multiclusterobservability -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$MCO_NAME" ]; then
    echo -e "${GREEN}✓ No MCO resources found (already deleted?)${NC}"
    exit 0
fi

echo "Target: $MCO_NAME"
echo ""
read -p "Continue? (yes/no) " -r
if [ "$REPLY" != "yes" ]; then
    exit 0
fi
echo ""

# Method 1: Delete all observability webhooks
echo -e "${YELLOW}[Method 1] Deleting ALL observability webhooks...${NC}"
WEBHOOKS=$(oc get validatingwebhookconfigurations 2>/dev/null | grep -i observability | awk '{print $1}' || echo "")

if [ -n "$WEBHOOKS" ]; then
    for wh in $WEBHOOKS; do
        echo "  Deleting: $wh"
        oc delete validatingwebhookconfigurations $wh 2>/dev/null || echo "    Failed to delete"
    done
    echo -e "${GREEN}✓ Webhooks deleted${NC}"
else
    echo "  No webhooks found"
fi

# Also check mutating webhooks
MUTATING_WEBHOOKS=$(oc get mutatingwebhookconfigurations 2>/dev/null | grep -i observability | awk '{print $1}' || echo "")
if [ -n "$MUTATING_WEBHOOKS" ]; then
    for wh in $MUTATING_WEBHOOKS; do
        echo "  Deleting mutating webhook: $wh"
        oc delete mutatingwebhookconfigurations $wh 2>/dev/null || echo "    Failed to delete"
    done
fi
echo ""

# Method 2: Scale down operator
echo -e "${YELLOW}[Method 2] Scaling down operator...${NC}"
oc scale deployment multicluster-observability-operator -n open-cluster-management --replicas=0 2>/dev/null || echo "  Operator not found"
sleep 3
echo ""

# Method 3: Remove finalizers via raw API
echo -e "${YELLOW}[Method 3] Removing finalizers via raw API...${NC}"
oc get multiclusterobservability $MCO_NAME -o json > /tmp/mco-backup.json

if jq 'del(.metadata.finalizers)' /tmp/mco-backup.json > /tmp/mco-no-finalizers.json 2>/dev/null; then
    if cat /tmp/mco-no-finalizers.json | oc replace --raw /apis/observability.open-cluster-management.io/v1beta2/multiclusterobservabilities/$MCO_NAME -f - &>/dev/null; then
        echo -e "${GREEN}✓ Finalizers removed via raw API${NC}"
    else
        echo -e "${YELLOW}⚠ Raw API replace failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠ jq not available, trying patch instead${NC}"
    oc patch multiclusterobservability $MCO_NAME -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || echo "  Patch failed"
fi
echo ""

# Method 4: Direct API deletion
echo -e "${YELLOW}[Method 4] Direct API deletion...${NC}"
API_SERVER=$(oc whoami --show-server)
TOKEN=$(oc whoami -t)

HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  "${API_SERVER}/apis/observability.open-cluster-management.io/v1beta2/multiclusterobservabilities/$MCO_NAME")

echo "  HTTP response: $HTTP_CODE"

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 404 ]; then
    echo -e "${GREEN}✓ Deletion accepted${NC}"
else
    echo -e "${YELLOW}⚠ Deletion may have failed${NC}"
fi
echo ""

# Method 5: Force oc delete
echo -e "${YELLOW}[Method 5] Force oc delete...${NC}"
oc delete multiclusterobservability $MCO_NAME --grace-period=0 --force --timeout=10s &>/dev/null &
sleep 10
echo ""

# Check result
echo -e "${BLUE}=== Verification ===${NC}"
if oc get multiclusterobservability $MCO_NAME &>/dev/null; then
    echo -e "${RED}✗ MCO still exists${NC}"
    echo ""
    echo "Remaining options:"
    echo ""
    echo "1. Manual etcd deletion (requires cluster-admin + etcd access):"
    echo "   ETCD_POD=\$(oc get pods -n openshift-etcd -l app=etcd --no-headers | head -1 | awk '{print \$1}')"
    echo "   oc exec -n openshift-etcd \$ETCD_POD -- sh -c \\"
    echo "     \"ETCDCTL_API=3 etcdctl del /kubernetes.io/multiclusterobservabilities/$MCO_NAME\""
    echo ""
    echo "2. Wait for operator reconciliation (may take hours)"
    echo ""
    echo "3. Contact Red Hat Support with this information:"
    echo ""
    echo "Current state:"
    oc get multiclusterobservability $MCO_NAME -o yaml 2>&1 | head -40
    
    exit 1
else
    echo -e "${GREEN}✓✓✓ MCO SUCCESSFULLY DELETED! ✓✓✓${NC}"
    echo ""
    oc get multiclusterobservability 2>&1 || echo "No MCO resources found"
    echo ""
    echo "Cleaning up..."
    
    # Scale operator back up
    oc scale deployment multicluster-observability-operator -n open-cluster-management --replicas=1 2>/dev/null || echo "Manual operator restart needed"
    
    echo ""
    echo -e "${GREEN}Done!${NC}"
fi

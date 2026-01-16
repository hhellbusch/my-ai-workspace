#!/bin/bash
# Diagnostic commands for KubeVirt VM stuck in provisioning due to Velero webhook

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== KubeVirt VM Provisioning Issue Diagnostics ===${NC}\n"

# Section 1: Check VM Status
echo -e "${YELLOW}[1] Checking VirtualMachine status...${NC}"
echo "All VirtualMachines in cluster:"
oc get vm -A -o wide 2>/dev/null || echo "No VMs found or no access"
echo ""

echo "VirtualMachineInstances:"
oc get vmi -A -o wide 2>/dev/null || echo "No VMIs found"
echo ""

# Section 2: Check Webhook Configuration
echo -e "${YELLOW}[2] Checking MutatingWebhookConfiguration...${NC}"
WEBHOOK_NAME=$(oc get mutatingwebhookconfigurations 2>/dev/null | grep velero | grep kubevirt | awk '{print $1}' || echo "")

if [ -z "$WEBHOOK_NAME" ]; then
    echo -e "${GREEN}No Velero KubeVirt webhook found (this might be good if you're not using it)${NC}"
else
    echo -e "${RED}Found webhook: $WEBHOOK_NAME${NC}"
    echo "Webhook details:"
    oc get mutatingwebhookconfigurations "$WEBHOOK_NAME" -o yaml | grep -A 20 "webhooks:"
fi
echo ""

# Section 3: Check for Webhook Service
echo -e "${YELLOW}[3] Checking for webhook service...${NC}"

# Check in common namespaces
for ns in openshift-adp velero-ppdm velero; do
    echo "Checking namespace: $ns"
    if oc get namespace "$ns" &>/dev/null; then
        SERVICES=$(oc get svc -n "$ns" 2>/dev/null | grep kubevirt || echo "none")
        if [ "$SERVICES" = "none" ]; then
            echo -e "  ${RED}No kubevirt-related services found${NC}"
        else
            echo -e "  ${GREEN}Found services:${NC}"
            echo "$SERVICES"
        fi
    else
        echo "  Namespace does not exist"
    fi
    echo ""
done

# Section 4: Check OADP Installation
echo -e "${YELLOW}[4] Checking OADP installation...${NC}"
if oc get namespace openshift-adp &>/dev/null; then
    echo "OADP Operator pods:"
    oc get pods -n openshift-adp
    echo ""
    
    echo "DataProtectionApplication:"
    oc get dataprotectionapplication -n openshift-adp -o wide 2>/dev/null || echo "No DPA found"
    echo ""
    
    echo "Velero deployments:"
    oc get deployment -n openshift-adp | grep -E "NAME|velero" || echo "No Velero deployments"
    echo ""
else
    echo -e "${RED}openshift-adp namespace does not exist${NC}"
fi

# Section 5: Check Velero Plugins
echo -e "${YELLOW}[5] Checking Velero plugins...${NC}"
for ns in openshift-adp velero-ppdm velero; do
    if oc get namespace "$ns" &>/dev/null; then
        echo "Checking $ns namespace:"
        VELERO_POD=$(oc get pod -n "$ns" -l component=velero -o name 2>/dev/null | head -1)
        if [ -n "$VELERO_POD" ]; then
            echo "Velero plugins:"
            oc exec -n "$ns" "$VELERO_POD" -- velero plugin get 2>/dev/null || echo "Could not get plugins"
        else
            echo "  No Velero pod found"
        fi
        echo ""
    fi
done

# Section 6: Check KubeVirt Installation
echo -e "${YELLOW}[6] Checking KubeVirt installation...${NC}"
echo "KubeVirt operator:"
oc get pods -n openshift-cnv 2>/dev/null | grep virt-operator || echo "Not found in openshift-cnv"
echo ""

echo "KubeVirt version:"
oc get kubevirt -A 2>/dev/null || echo "KubeVirt resource not found"
echo ""

# Section 7: Check Recent Events
echo -e "${YELLOW}[7] Checking recent events related to VMs...${NC}"
echo "Recent VM-related events (last 30 minutes):"
oc get events -A --sort-by='.lastTimestamp' 2>/dev/null | \
    grep -i -E "virtualmachine|virt-launcher|kubevirt|velero" | \
    tail -20 || echo "No relevant events"
echo ""

# Section 8: Summary
echo -e "${BLUE}=== Diagnostic Summary ===${NC}"
echo ""

# Determine the issue
if [ -n "$WEBHOOK_NAME" ]; then
    echo -e "${RED}ISSUE CONFIRMED: Webhook configuration exists but service is missing${NC}"
    echo ""
    echo "The mutating webhook '$WEBHOOK_NAME' is configured but the"
    echo "webhook service is not running. This prevents VM pods from being created."
    echo ""
    echo "Recommended actions:"
    echo "1. If you need OADP/Velero for VM backup: Fix the plugin installation"
    echo "   See: REPAIR-VELERO-PLUGIN.md"
    echo ""
    echo "2. If you don't need OADP/Velero for VMs: Remove the webhook"
    echo "   See: REMOVE-WEBHOOK.md"
    echo ""
    echo "Quick fix command:"
    echo "   oc delete mutatingwebhookconfigurations $WEBHOOK_NAME"
else
    echo -e "${GREEN}No webhook issue detected${NC}"
    echo "The Velero webhook is not configured. The VM provisioning issue"
    echo "may be due to a different cause."
fi

echo ""
echo -e "${BLUE}=== End of Diagnostics ===${NC}"


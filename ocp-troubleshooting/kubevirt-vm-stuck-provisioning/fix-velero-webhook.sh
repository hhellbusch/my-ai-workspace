#!/bin/bash
# Quick fix script for Velero KubeVirt webhook issue
# This script provides an interactive fix for VMs stuck due to missing webhook service

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  KubeVirt VM Stuck - Velero Webhook Quick Fix           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    if ! command -v oc &> /dev/null; then
        echo -e "${RED}ERROR: 'oc' command not found. Please install OpenShift CLI.${NC}"
        exit 1
    fi
    
    if ! oc auth can-i get mutatingwebhookconfigurations &>/dev/null; then
        echo -e "${RED}ERROR: Insufficient permissions. Cluster admin access required.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Prerequisites met${NC}"
    echo ""
}

# Function to detect the webhook
detect_webhook() {
    echo -e "${YELLOW}Detecting Velero KubeVirt webhook...${NC}"
    
    WEBHOOK_NAME=$(oc get mutatingwebhookconfigurations 2>/dev/null | \
        grep -i velero | grep -i kubevirt | awk '{print $1}' | head -1 || echo "")
    
    if [ -z "$WEBHOOK_NAME" ]; then
        echo -e "${GREEN}No Velero KubeVirt webhook found.${NC}"
        echo "This issue may not be related to the webhook."
        echo ""
        exit 0
    fi
    
    echo -e "${GREEN}✓ Found webhook: ${WEBHOOK_NAME}${NC}"
    echo ""
    export WEBHOOK_NAME
}

# Function to check webhook service
check_webhook_service() {
    echo -e "${YELLOW}Checking webhook service...${NC}"
    
    # Get service details from webhook config
    SERVICE_INFO=$(oc get mutatingwebhookconfigurations "$WEBHOOK_NAME" -o jsonpath='{.webhooks[0].clientConfig.service}')
    SERVICE_NAME=$(echo "$SERVICE_INFO" | jq -r '.name')
    SERVICE_NAMESPACE=$(echo "$SERVICE_INFO" | jq -r '.namespace')
    
    export SERVICE_NAME
    export SERVICE_NAMESPACE
    
    echo "Expected service: $SERVICE_NAME"
    echo "Expected namespace: $SERVICE_NAMESPACE"
    echo ""
    
    if oc get svc "$SERVICE_NAME" -n "$SERVICE_NAMESPACE" &>/dev/null; then
        echo -e "${GREEN}✓ Service exists!${NC}"
        echo "The service is present. The issue may be elsewhere."
        echo ""
        exit 0
    else
        echo -e "${RED}✗ Service NOT found!${NC}"
        echo "This is the root cause of your VM provisioning issue."
        echo ""
    fi
}

# Function to check OADP installation
check_oadp() {
    echo -e "${YELLOW}Checking OADP/Velero installation...${NC}"
    
    USING_OADP=false
    
    if oc get namespace openshift-adp &>/dev/null; then
        echo "OADP namespace exists: openshift-adp"
        if oc get pods -n openshift-adp -l component=velero &>/dev/null 2>&1; then
            VELERO_POD_COUNT=$(oc get pods -n openshift-adp -l component=velero --no-headers 2>/dev/null | wc -l)
            if [ "$VELERO_POD_COUNT" -gt 0 ]; then
                echo -e "${GREEN}Velero pods found in openshift-adp${NC}"
                USING_OADP=true
            fi
        fi
    fi
    
    export USING_OADP
    echo ""
}

# Function to present options
present_options() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Resolution Options                                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$USING_OADP" = true ]; then
        echo -e "${YELLOW}OADP/Velero is installed on this cluster.${NC}"
        echo ""
        echo "Select an option:"
        echo "  1) Remove webhook (quick fix - VMs will work, backups won't)"
        echo "  2) Repair OADP plugin (proper fix - takes longer)"
        echo "  3) Disable webhook temporarily (for testing)"
        echo "  4) Show manual instructions and exit"
        echo "  5) Exit without changes"
        echo ""
    else
        echo -e "${YELLOW}OADP/Velero does not appear to be properly installed.${NC}"
        echo ""
        echo "Select an option:"
        echo "  1) Remove webhook (recommended - fixes VMs immediately)"
        echo "  2) Show manual installation instructions for OADP"
        echo "  3) Disable webhook temporarily (for testing)"
        echo "  4) Exit without changes"
        echo ""
    fi
    
    read -p "Enter choice: " CHOICE
    echo ""
    
    case $CHOICE in
        1) remove_webhook ;;
        2) 
            if [ "$USING_OADP" = true ]; then
                repair_plugin
            else
                show_oadp_instructions
            fi
            ;;
        3) disable_webhook ;;
        4)
            if [ "$USING_OADP" = true ]; then
                show_manual_instructions
            else
                exit 0
            fi
            ;;
        5|*)
            echo "Exiting without changes."
            exit 0
            ;;
    esac
}

# Function to remove webhook
remove_webhook() {
    echo -e "${YELLOW}Removing webhook configuration...${NC}"
    echo ""
    
    # Backup first
    BACKUP_FILE="webhook-backup-$(date +%Y%m%d-%H%M%S).yaml"
    echo "Creating backup: $BACKUP_FILE"
    oc get mutatingwebhookconfigurations "$WEBHOOK_NAME" -o yaml > "$BACKUP_FILE"
    echo -e "${GREEN}✓ Backup created${NC}"
    echo ""
    
    # Confirm
    read -p "Delete webhook '$WEBHOOK_NAME'? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Cancelled."
        exit 0
    fi
    
    # Delete
    if oc delete mutatingwebhookconfigurations "$WEBHOOK_NAME"; then
        echo ""
        echo -e "${GREEN}✓ Webhook deleted successfully${NC}"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "1. Check if stuck VMs now start automatically"
        echo "2. For stuck VMs, you may need to restart them:"
        echo "   oc patch vm <vm-name> -n <namespace> --type merge -p '{\"spec\":{\"running\":false}}'"
        echo "   oc patch vm <vm-name> -n <namespace> --type merge -p '{\"spec\":{\"running\":true}}'"
        echo ""
        echo "Backup saved to: $BACKUP_FILE"
    else
        echo -e "${RED}Failed to delete webhook${NC}"
        exit 1
    fi
}

# Function to repair plugin
repair_plugin() {
    echo -e "${YELLOW}Repairing OADP KubeVirt plugin...${NC}"
    echo ""
    
    # Check current DPA
    DPA_NAME=$(oc get dpa -n openshift-adp -o name 2>/dev/null | head -1 | cut -d'/' -f2 || echo "")
    
    if [ -z "$DPA_NAME" ]; then
        echo -e "${RED}No DataProtectionApplication found in openshift-adp${NC}"
        echo "OADP may not be properly configured."
        echo ""
        show_oadp_instructions
        exit 1
    fi
    
    echo "Found DPA: $DPA_NAME"
    echo ""
    
    # Check if kubevirt plugin is in the config
    HAS_PLUGIN=$(oc get dpa "$DPA_NAME" -n openshift-adp -o jsonpath='{.spec.configuration.velero.defaultPlugins[*]}' | grep -o kubevirt || echo "")
    
    if [ -n "$HAS_PLUGIN" ]; then
        echo -e "${GREEN}KubeVirt plugin is already in DPA configuration${NC}"
        echo ""
        echo "The plugin is configured but service is missing. Trying to force reconciliation..."
        echo ""
        
        # Force reconciliation by restarting Velero pod
        echo "Restarting Velero pod..."
        oc delete pod -n openshift-adp -l component=velero
        
        echo "Waiting for Velero pod to restart..."
        sleep 5
        oc wait --for=condition=Ready pod -n openshift-adp -l component=velero --timeout=120s
        
        echo ""
        echo "Checking if service was created..."
        sleep 5
        
        if oc get svc "$SERVICE_NAME" -n openshift-adp &>/dev/null; then
            echo -e "${GREEN}✓ Service created successfully!${NC}"
            echo ""
            echo "VM provisioning should now work. Test by starting a VM."
        else
            echo -e "${RED}Service still not created.${NC}"
            echo "This may require manual intervention."
            echo "See: REPAIR-VELERO-PLUGIN.md for detailed steps"
        fi
    else
        echo -e "${YELLOW}KubeVirt plugin is NOT in DPA configuration${NC}"
        echo ""
        echo "To add it, edit the DPA:"
        echo "  oc edit dpa $DPA_NAME -n openshift-adp"
        echo ""
        echo "Add 'kubevirt' to spec.configuration.velero.defaultPlugins list"
        echo ""
        echo "See: REPAIR-VELERO-PLUGIN.md for detailed instructions"
    fi
}

# Function to disable webhook
disable_webhook() {
    echo -e "${YELLOW}Disabling webhook temporarily...${NC}"
    echo ""
    echo "This changes the failure policy to 'Ignore' so VM creation proceeds"
    echo "even if the webhook service is missing."
    echo ""
    
    read -p "Continue? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Cancelled."
        exit 0
    fi
    
    if oc patch mutatingwebhookconfigurations "$WEBHOOK_NAME" --type='json' \
       -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value": "Ignore"}]'; then
        echo ""
        echo -e "${GREEN}✓ Webhook disabled${NC}"
        echo ""
        echo "VM provisioning should now work, but this is a temporary workaround."
        echo "You should still fix the root cause (repair or remove the webhook)."
    else
        echo -e "${RED}Failed to disable webhook${NC}"
        exit 1
    fi
}

# Function to show manual instructions
show_manual_instructions() {
    echo -e "${BLUE}Manual Instructions:${NC}"
    echo ""
    echo "See the following files for detailed steps:"
    echo "  - REMOVE-WEBHOOK.md (quick fix)"
    echo "  - REPAIR-VELERO-PLUGIN.md (proper fix)"
    echo "  - diagnostic-commands.sh (full diagnostics)"
    echo ""
}

# Function to show OADP instructions
show_oadp_instructions() {
    echo -e "${BLUE}OADP Installation Instructions:${NC}"
    echo ""
    echo "To properly install OADP with KubeVirt support:"
    echo "1. Install OADP operator from OperatorHub"
    echo "2. Configure S3 storage for backups"
    echo "3. Create DataProtectionApplication with kubevirt plugin"
    echo ""
    echo "See: REPAIR-VELERO-PLUGIN.md for detailed steps"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    detect_webhook
    check_webhook_service
    check_oadp
    present_options
}

main


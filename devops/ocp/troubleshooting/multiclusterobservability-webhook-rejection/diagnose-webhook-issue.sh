#!/bin/bash

# MultiClusterObservability Webhook Diagnostic Script
# Automatically gathers information about webhook rejection issues

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Output directory
OUTPUT_DIR="mco-webhook-diagnostics-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo -e "${GREEN}=== MultiClusterObservability Webhook Diagnostic ===${NC}"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Function to run command and save output
run_and_save() {
    local description=$1
    local command=$2
    local output_file=$3
    
    echo -e "${YELLOW}Collecting: $description${NC}"
    if eval "$command" > "$OUTPUT_DIR/$output_file" 2>&1; then
        echo -e "${GREEN}✓${NC} Saved to $output_file"
    else
        echo -e "${RED}✗${NC} Failed (saved error to $output_file)"
    fi
}

# 1. Check MultiClusterObservability resources
echo -e "\n${GREEN}[1/9] Checking MultiClusterObservability Resources${NC}"
run_and_save "MCO Resources" \
    "oc get multiclusterobservability -o yaml" \
    "mco-resources.yaml"

run_and_save "MCO Description" \
    "oc describe multiclusterobservability" \
    "mco-describe.txt"

run_and_save "MCO Finalizers" \
    "oc get multiclusterobservability -o json | jq -r '.items[] | \"Name: \" + .metadata.name + \"\nFinalizers: \" + (.metadata.finalizers | tostring)'" \
    "mco-finalizers.txt"

# 2. Check Validating Webhooks
echo -e "\n${GREEN}[2/9] Checking Validating Webhooks${NC}"
run_and_save "All Validating Webhooks" \
    "oc get validatingwebhookconfigurations -o wide" \
    "validating-webhooks-list.txt"

run_and_save "Observability Validating Webhooks" \
    "oc get validatingwebhookconfigurations -o yaml | grep -A 50 observability || echo 'No observability webhooks found'" \
    "observability-validating-webhooks.yaml"

# Get specific webhook details if they exist
if oc get validatingwebhookconfigurations | grep -q observability; then
    WEBHOOK_NAME=$(oc get validatingwebhookconfigurations | grep observability | head -1 | awk '{print $1}')
    run_and_save "Webhook Configuration Details" \
        "oc get validatingwebhookconfigurations $WEBHOOK_NAME -o yaml" \
        "webhook-config-details.yaml"
fi

# 3. Check Mutating Webhooks
echo -e "\n${GREEN}[3/9] Checking Mutating Webhooks${NC}"
run_and_save "Observability Mutating Webhooks" \
    "oc get mutatingwebhookconfigurations -o yaml | grep -A 50 observability || echo 'No observability mutating webhooks found'" \
    "observability-mutating-webhooks.yaml"

# 4. Check CRD Definition
echo -e "\n${GREEN}[4/9] Checking CRD Definition${NC}"
run_and_save "MCO CRD" \
    "oc get crd multiclusterobservabilities.observability.open-cluster-management.io -o yaml" \
    "mco-crd.yaml"

run_and_save "CRD Validation Schema" \
    "oc get crd multiclusterobservabilities.observability.open-cluster-management.io -o jsonpath='{.spec.versions[*].schema.openAPIV3Schema}' | jq ." \
    "mco-crd-schema.json"

# 5. Check Observability Operator
echo -e "\n${GREEN}[5/9] Checking Observability Operator${NC}"
run_and_save "Observability Namespace Pods" \
    "oc get pods -n open-cluster-management-observability -o wide" \
    "observability-pods.txt"

run_and_save "Observability Operator Deployment" \
    "oc get deployment multicluster-observability-operator -n open-cluster-management -o yaml" \
    "observability-operator-deployment.yaml"

run_and_save "Observability Operator Logs" \
    "oc logs -n open-cluster-management deployment/multicluster-observability-operator --tail=200" \
    "observability-operator-logs.txt"

run_and_save "Endpoint Observability Operator Logs" \
    "oc logs -n open-cluster-management-addon-observability deployment/endpoint-observability-operator --tail=200 || echo 'Endpoint operator not found'" \
    "endpoint-operator-logs.txt"

# 6. Check Webhook Services
echo -e "\n${GREEN}[6/9] Checking Webhook Services${NC}"
if oc get validatingwebhookconfigurations | grep -q observability; then
    WEBHOOK_NAME=$(oc get validatingwebhookconfigurations | grep observability | head -1 | awk '{print $1}')
    WEBHOOK_SVC=$(oc get validatingwebhookconfigurations "$WEBHOOK_NAME" -o jsonpath='{.webhooks[0].clientConfig.service.name}' 2>/dev/null || echo "")
    WEBHOOK_NS=$(oc get validatingwebhookconfigurations "$WEBHOOK_NAME" -o jsonpath='{.webhooks[0].clientConfig.service.namespace}' 2>/dev/null || echo "")
    
    if [ -n "$WEBHOOK_SVC" ] && [ -n "$WEBHOOK_NS" ]; then
        run_and_save "Webhook Service" \
            "oc get service $WEBHOOK_SVC -n $WEBHOOK_NS -o yaml" \
            "webhook-service.yaml"
        
        run_and_save "Webhook Endpoints" \
            "oc get endpoints $WEBHOOK_SVC -n $WEBHOOK_NS -o yaml" \
            "webhook-endpoints.yaml"
        
        run_and_save "Webhook Service Pods" \
            "oc get pods -n $WEBHOOK_NS -o wide" \
            "webhook-service-pods.txt"
    fi
fi

# 7. Check ACM Installation
echo -e "\n${GREEN}[7/9] Checking ACM Installation${NC}"
run_and_save "ACM CSV" \
    "oc get csv -n open-cluster-management | grep advanced-cluster-management" \
    "acm-version.txt"

run_and_save "ACM ClusterVersion" \
    "oc get clusterversion -o yaml" \
    "cluster-version.yaml"

run_and_save "Observability CSV" \
    "oc get csv -n open-cluster-management-observability || echo 'No CSV in observability namespace'" \
    "observability-csv.txt"

# 8. Check for Failing Resources
echo -e "\n${GREEN}[8/9] Checking for Failing Resources${NC}"
run_and_save "Non-Running Pods in Observability" \
    "oc get pods -n open-cluster-management-observability --field-selector=status.phase!=Running,status.phase!=Succeeded || echo 'All pods running'" \
    "failing-pods.txt"

run_and_save "Observability Events" \
    "oc get events -n open-cluster-management-observability --sort-by='.lastTimestamp' | tail -50" \
    "observability-events.txt"

# 9. API Resource Check
echo -e "\n${GREEN}[9/9] Checking API Resources${NC}"
run_and_save "MCO API Resources" \
    "oc api-resources | grep multiclusterobservability" \
    "mco-api-resources.txt"

run_and_save "Observability API Groups" \
    "oc api-resources --api-group=observability.open-cluster-management.io" \
    "observability-api-groups.txt"

# Generate Summary Report
echo -e "\n${GREEN}Generating Summary Report${NC}"
cat > "$OUTPUT_DIR/SUMMARY.txt" <<EOF
MultiClusterObservability Webhook Diagnostic Summary
Generated: $(date)

=== Quick Checks ===

1. MultiClusterObservability Resources:
$(oc get multiclusterobservability 2>&1 | head -5 || echo "Failed to retrieve")

2. Validating Webhooks:
$(oc get validatingwebhookconfigurations | grep observability || echo "No observability webhooks found")

3. Observability Operator Status:
$(oc get pods -n open-cluster-management-observability 2>&1 | grep -E "NAME|observability" || echo "Namespace or pods not found")

4. Webhook Service Connectivity:
EOF

if oc get validatingwebhookconfigurations | grep -q observability; then
    WEBHOOK_NAME=$(oc get validatingwebhookconfigurations | grep observability | head -1 | awk '{print $1}')
    WEBHOOK_SVC=$(oc get validatingwebhookconfigurations "$WEBHOOK_NAME" -o jsonpath='{.webhooks[0].clientConfig.service.name}' 2>/dev/null || echo "")
    WEBHOOK_NS=$(oc get validatingwebhookconfigurations "$WEBHOOK_NAME" -o jsonpath='{.webhooks[0].clientConfig.service.namespace}' 2>/dev/null || echo "")
    
    if [ -n "$WEBHOOK_SVC" ] && [ -n "$WEBHOOK_NS" ]; then
        echo "Service: $WEBHOOK_SVC in namespace: $WEBHOOK_NS" >> "$OUTPUT_DIR/SUMMARY.txt"
        oc get service "$WEBHOOK_SVC" -n "$WEBHOOK_NS" >> "$OUTPUT_DIR/SUMMARY.txt" 2>&1 || echo "Service not found" >> "$OUTPUT_DIR/SUMMARY.txt"
        oc get endpoints "$WEBHOOK_SVC" -n "$WEBHOOK_NS" >> "$OUTPUT_DIR/SUMMARY.txt" 2>&1 || echo "Endpoints not found" >> "$OUTPUT_DIR/SUMMARY.txt"
    fi
fi

cat >> "$OUTPUT_DIR/SUMMARY.txt" <<EOF

=== Recommendations ===

Based on collected data, check:
1. See 'mco-resources.yaml' for current MultiClusterObservability configuration
2. See 'webhook-config-details.yaml' for webhook validation rules
3. See 'observability-operator-logs.txt' for operator errors
4. See 'mco-crd-schema.json' for required fields and validation

Common fixes:
- If webhook service is unreachable: See Strategy 2 in README.md (disable webhook temporarily)
- If nested resources missing names: See Strategy 3 in README.md (add names to nested configs)
- If webhook config stale: See Strategy 4 in README.md (recreate webhook)
- If finalizers blocking deletion: See Strategy 1 in README.md (remove finalizers)

Full troubleshooting guide: See README.md in this directory
EOF

# Create archive
echo -e "\n${GREEN}Creating archive${NC}"
tar -czf "mco-webhook-diagnostics-$(date +%Y%m%d-%H%M%S).tar.gz" "$OUTPUT_DIR"

echo -e "\n${GREEN}=== Diagnostic Complete ===${NC}"
echo -e "Results saved to: ${YELLOW}$OUTPUT_DIR${NC}"
echo -e "Archive created: ${YELLOW}mco-webhook-diagnostics-$(date +%Y%m%d-%H%M%S).tar.gz${NC}"
echo -e "\nReview ${YELLOW}$OUTPUT_DIR/SUMMARY.txt${NC} for quick analysis"
echo -e "See ${YELLOW}README.md${NC} for resolution strategies"

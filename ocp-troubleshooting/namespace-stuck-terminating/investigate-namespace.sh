#!/bin/bash

# investigate-namespace.sh
# Investigation script for namespaces stuck in Terminating state
# Usage: ./investigate-namespace.sh <namespace-name>

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${1:-}"
OUTPUT_DIR="./investigation-${NAMESPACE}-$(date +%Y%m%d-%H%M%S)"

# Functions
usage() {
    cat << EOF
Usage: $0 <namespace-name>

Investigates a namespace stuck in Terminating state and generates a report.

Arguments:
  namespace-name    Name of the namespace to investigate

Examples:
  $0 my-namespace

Output:
  Creates directory: investigation-<namespace>-<timestamp>/
  Contains:
    - namespace-info.yaml
    - resources-with-finalizers.txt
    - all-resources.txt
    - namespace-events.txt
    - investigation-report.txt

EOF
    exit 1
}

log_section() {
    echo
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v oc &> /dev/null; then
        log_error "oc command not found"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq command not found"
        exit 1
    fi
    
    if ! oc whoami &> /dev/null; then
        log_error "Not logged into OpenShift cluster"
        exit 1
    fi
    
    log_success "Prerequisites met"
}

setup_output_dir() {
    log_info "Creating output directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
}

get_namespace_info() {
    log_section "1. Namespace Information"
    
    log_info "Fetching namespace details..."
    oc get namespace "$NAMESPACE" -o yaml > "$OUTPUT_DIR/namespace-info.yaml"
    
    local status
    status=$(oc get namespace "$NAMESPACE" -o jsonpath='{.status.phase}')
    echo "Status: $status"
    
    local spec_finalizers
    spec_finalizers=$(oc get namespace "$NAMESPACE" -o json | jq -r '.spec.finalizers // []')
    echo "Spec Finalizers: $spec_finalizers"
    
    local meta_finalizers
    meta_finalizers=$(oc get namespace "$NAMESPACE" -o json | jq -r '.metadata.finalizers // []')
    echo "Metadata Finalizers: $meta_finalizers"
    
    echo
    oc describe namespace "$NAMESPACE" | tee -a "$OUTPUT_DIR/namespace-info.yaml"
}

find_resources_with_finalizers() {
    log_section "2. Resources with Finalizers"
    
    log_info "Scanning all resources in namespace..."
    
    {
        echo "Resources with Finalizers"
        echo "========================="
        echo
        
        local found=0
        
        oc api-resources --verbs=list --namespaced -o name | while read -r resource_type; do
            local items
            items=$(oc get "$resource_type" -n "$NAMESPACE" -o json 2>/dev/null | \
                    jq -r '.items[]? | select(.metadata.finalizers != null) | 
                    "Type: \(.kind)\nName: \(.metadata.name)\nFinalizers: \(.metadata.finalizers)\n---"' \
                    2>/dev/null || true)
            
            if [[ -n "$items" ]]; then
                echo "$items"
                echo "$items" | grep -c "Type:" || true
                found=1
            fi
        done
        
        if [[ $found -eq 0 ]]; then
            echo "No resources with finalizers found"
        fi
    } | tee "$OUTPUT_DIR/resources-with-finalizers.txt"
}

list_all_resources() {
    log_section "3. All Resources in Namespace"
    
    log_info "Listing all resources..."
    
    {
        echo "All Resources in Namespace"
        echo "=========================="
        echo
        
        oc api-resources --verbs=list --namespaced -o name | while read -r resource_type; do
            local items
            items=$(oc get "$resource_type" -n "$NAMESPACE" 2>/dev/null || true)
            
            if [[ -n "$items" ]] && [[ "$items" != *"No resources found"* ]]; then
                echo "--- $resource_type ---"
                echo "$items"
                echo
            fi
        done
    } | tee "$OUTPUT_DIR/all-resources.txt"
}

get_namespace_events() {
    log_section "4. Namespace Events"
    
    log_info "Fetching namespace events..."
    
    {
        echo "Recent Events"
        echo "============="
        echo
        oc get events -n "$NAMESPACE" --sort-by='.lastTimestamp' 2>/dev/null || echo "No events found"
    } | tee "$OUTPUT_DIR/namespace-events.txt"
}

check_operators() {
    log_section "5. Related Operators"
    
    log_info "Checking operator status..."
    
    {
        echo "Operator Pods"
        echo "============="
        echo
        
        # Common operator namespaces
        for ns in openshift-operators openshift-operator-lifecycle-manager; do
            echo "--- Namespace: $ns ---"
            oc get pods -n "$ns" 2>/dev/null || echo "Namespace not found or no access"
            echo
        done
        
        # Check for specific operators based on found finalizers
        echo "Checking for specific operators..."
        
        if grep -q "opentelemetry" "$OUTPUT_DIR/resources-with-finalizers.txt" 2>/dev/null; then
            echo "OpenTelemetry Operator:"
            oc get pods -n openshift-operators -l app.kubernetes.io/name=opentelemetry-operator 2>/dev/null || echo "Not found"
        fi
        
        if grep -q "managedcluster" "$OUTPUT_DIR/resources-with-finalizers.txt" 2>/dev/null; then
            echo "RHACM/ACM Operator:"
            oc get pods -n open-cluster-management 2>/dev/null || echo "Not found"
        fi
    } | tee "$OUTPUT_DIR/operators-info.txt"
}

check_webhooks() {
    log_section "6. Admission Webhooks"
    
    log_info "Checking for relevant webhooks..."
    
    {
        echo "ValidatingWebhookConfigurations"
        echo "==============================="
        oc get validatingwebhookconfigurations -o json | \
            jq -r '.items[] | select(.webhooks[].namespaceSelector != null) | .metadata.name' || true
        
        echo
        echo "MutatingWebhookConfigurations"
        echo "============================="
        oc get mutatingwebhookconfigurations -o json | \
            jq -r '.items[] | select(.webhooks[].namespaceSelector != null) | .metadata.name' || true
    } | tee "$OUTPUT_DIR/webhooks-info.txt"
}

generate_report() {
    log_section "7. Generating Investigation Report"
    
    local report="$OUTPUT_DIR/investigation-report.txt"
    
    {
        echo "======================================"
        echo "Namespace Investigation Report"
        echo "======================================"
        echo
        echo "Namespace: $NAMESPACE"
        echo "Date: $(date)"
        echo "Cluster: $(oc whoami --show-server)"
        echo "User: $(oc whoami)"
        echo
        
        echo "SUMMARY"
        echo "-------"
        
        local status
        status=$(oc get namespace "$NAMESPACE" -o jsonpath='{.status.phase}')
        echo "Namespace Status: $status"
        
        local finalizer_count
        finalizer_count=$(grep -c "Type:" "$OUTPUT_DIR/resources-with-finalizers.txt" 2>/dev/null || echo "0")
        echo "Resources with Finalizers: $finalizer_count"
        
        echo
        echo "NAMESPACE FINALIZERS"
        echo "--------------------"
        oc get namespace "$NAMESPACE" -o json | jq -r '
            "Spec Finalizers: \(.spec.finalizers // [])\n" +
            "Metadata Finalizers: \(.metadata.finalizers // [])"
        '
        
        echo
        echo "RESOURCE FINALIZERS"
        echo "-------------------"
        if [[ $finalizer_count -gt 0 ]]; then
            grep -A 2 "Type:" "$OUTPUT_DIR/resources-with-finalizers.txt" | head -20
            if [[ $finalizer_count -gt 5 ]]; then
                echo "... (see resources-with-finalizers.txt for complete list)"
            fi
        else
            echo "No resources with finalizers found"
        fi
        
        echo
        echo "RECOMMENDATIONS"
        echo "---------------"
        
        if [[ $finalizer_count -gt 0 ]]; then
            echo "1. Remove finalizers from individual resources:"
            echo "   See resources-with-finalizers.txt for specific resources"
            echo "   Use: oc patch <resource-type> <resource-name> -n $NAMESPACE \\"
            echo "        -p '{\"metadata\":{\"finalizers\":[]}}' --type=merge"
            echo
        fi
        
        if [[ $(oc get namespace "$NAMESPACE" -o json | jq -r '.spec.finalizers // [] | length') -gt 0 ]]; then
            echo "2. Remove namespace spec finalizers:"
            echo "   oc patch namespace $NAMESPACE -p '{\"spec\":{\"finalizers\":[]}}' --type=merge"
            echo
        fi
        
        if [[ $(oc get namespace "$NAMESPACE" -o json | jq -r '.metadata.finalizers // [] | length') -gt 0 ]]; then
            echo "3. Remove namespace metadata finalizers:"
            echo "   oc patch namespace $NAMESPACE -p '{\"metadata\":{\"finalizers\":[]}}' --type=merge"
            echo
        fi
        
        echo "4. Use the automated cleanup script:"
        echo "   ./cleanup-namespace-finalizers.sh $NAMESPACE --dry-run"
        echo "   ./cleanup-namespace-finalizers.sh $NAMESPACE"
        echo
        
        echo "5. Check operator logs for errors:"
        echo "   See operators-info.txt for operator pod names"
        echo
        
        echo "FILES GENERATED"
        echo "---------------"
        ls -lh "$OUTPUT_DIR"
        
    } | tee "$report"
    
    log_success "Investigation complete!"
    echo
    log_info "Results saved to: $OUTPUT_DIR"
    log_info "View report: cat $report"
}

# Main execution
main() {
    if [[ -z "$NAMESPACE" ]]; then
        usage
    fi
    
    echo "======================================"
    echo "Namespace Investigation Tool"
    echo "======================================"
    echo
    
    check_prerequisites
    
    if ! oc get namespace "$NAMESPACE" &> /dev/null; then
        log_error "Namespace '$NAMESPACE' not found"
        exit 1
    fi
    
    setup_output_dir
    
    get_namespace_info
    find_resources_with_finalizers
    list_all_resources
    get_namespace_events
    check_operators
    check_webhooks
    generate_report
}

# Run main function
main "$@"


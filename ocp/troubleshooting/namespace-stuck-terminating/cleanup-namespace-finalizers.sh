#!/bin/bash

# cleanup-namespace-finalizers.sh
# Automated script to remove finalizers from resources in a stuck namespace
# Usage: ./cleanup-namespace-finalizers.sh <namespace-name> [--dry-run]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${1:-}"
DRY_RUN=false

if [[ "${2:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Functions
usage() {
    cat << EOF
Usage: $0 <namespace-name> [--dry-run]

Removes finalizers from resources in a stuck namespace.

Arguments:
  namespace-name    Name of the namespace stuck in Terminating state
  --dry-run         Show what would be done without making changes

Examples:
  $0 my-namespace
  $0 my-namespace --dry-run

EOF
    exit 1
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
        log_error "oc command not found. Please install OpenShift CLI."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq command not found. Please install jq."
        exit 1
    fi
    
    if ! oc whoami &> /dev/null; then
        log_error "Not logged into OpenShift cluster."
        exit 1
    fi
    
    log_success "Prerequisites met"
}

check_namespace() {
    log_info "Checking namespace: $NAMESPACE"
    
    if ! oc get namespace "$NAMESPACE" &> /dev/null; then
        log_error "Namespace '$NAMESPACE' not found"
        exit 1
    fi
    
    local status
    status=$(oc get namespace "$NAMESPACE" -o jsonpath='{.status.phase}')
    
    if [[ "$status" != "Terminating" ]]; then
        log_warning "Namespace is in '$status' state, not 'Terminating'"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_success "Namespace found and is in Terminating state"
}

show_namespace_finalizers() {
    log_info "Checking namespace-level finalizers..."
    
    local spec_finalizers
    local meta_finalizers
    
    spec_finalizers=$(oc get namespace "$NAMESPACE" -o json | jq -r '.spec.finalizers // []')
    meta_finalizers=$(oc get namespace "$NAMESPACE" -o json | jq -r '.metadata.finalizers // []')
    
    if [[ "$spec_finalizers" != "[]" ]]; then
        log_warning "Namespace has spec.finalizers: $spec_finalizers"
    fi
    
    if [[ "$meta_finalizers" != "[]" ]]; then
        log_warning "Namespace has metadata.finalizers: $meta_finalizers"
    fi
}

find_resources_with_finalizers() {
    log_info "Searching for resources with finalizers in namespace '$NAMESPACE'..."
    
    local resources_found=false
    
    # Get all namespaced resource types
    oc api-resources --verbs=list --namespaced -o name | while read -r resource_type; do
        # Try to get resources of this type
        local items
        items=$(oc get "$resource_type" -n "$NAMESPACE" -o json 2>/dev/null | \
                jq -r '.items[]? | select(.metadata.finalizers != null) | "\(.kind)/\(.metadata.name):\(.metadata.finalizers)"' 2>/dev/null || true)
        
        if [[ -n "$items" ]]; then
            echo "$items" | while read -r item; do
                resources_found=true
                log_warning "Found: $item"
            done
        fi
    done
    
    if [[ "$resources_found" == "false" ]]; then
        log_info "No resources with finalizers found"
    fi
}

remove_resource_finalizers() {
    log_info "Removing finalizers from resources..."
    
    local count=0
    
    # Get all namespaced resource types
    oc api-resources --verbs=list --namespaced -o name | while read -r resource_type; do
        # Get resources with finalizers
        local resources
        resources=$(oc get "$resource_type" -n "$NAMESPACE" -o json 2>/dev/null | \
                    jq -r '.items[]? | select(.metadata.finalizers != null) | .metadata.name' 2>/dev/null || true)
        
        if [[ -n "$resources" ]]; then
            echo "$resources" | while read -r resource_name; do
                if [[ "$DRY_RUN" == "true" ]]; then
                    log_info "[DRY-RUN] Would remove finalizers from $resource_type/$resource_name"
                else
                    log_info "Removing finalizers from $resource_type/$resource_name"
                    if oc patch "$resource_type" "$resource_name" -n "$NAMESPACE" \
                        -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null; then
                        log_success "Removed finalizers from $resource_type/$resource_name"
                        ((count++))
                    else
                        log_warning "Failed to patch $resource_type/$resource_name (may need raw API call)"
                    fi
                fi
            done
        fi
    done
    
    if [[ $count -gt 0 ]]; then
        log_success "Removed finalizers from $count resource(s)"
    fi
}

remove_namespace_finalizers() {
    log_info "Removing namespace-level finalizers..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would remove finalizers from namespace"
        return
    fi
    
    # Try spec finalizers
    if oc patch namespace "$NAMESPACE" \
        -p '{"spec":{"finalizers":[]}}' --type=merge 2>/dev/null; then
        log_success "Removed spec.finalizers from namespace"
    else
        log_warning "Could not remove spec.finalizers (may not exist)"
    fi
    
    # Try metadata finalizers
    if oc patch namespace "$NAMESPACE" \
        -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null; then
        log_success "Removed metadata.finalizers from namespace"
    else
        log_warning "Could not remove metadata.finalizers (may not exist)"
    fi
}

verify_deletion() {
    log_info "Verifying namespace deletion..."
    
    sleep 2
    
    if oc get namespace "$NAMESPACE" &> /dev/null; then
        local status
        status=$(oc get namespace "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "unknown")
        
        if [[ "$status" == "Terminating" ]]; then
            log_warning "Namespace still in Terminating state"
            log_info "You may need to:"
            log_info "  1. Check for admission webhooks blocking deletion"
            log_info "  2. Investigate controller/operator issues"
            log_info "  3. Use raw API calls for stuck resources"
            return 1
        else
            log_warning "Namespace still exists with status: $status"
            return 1
        fi
    else
        log_success "Namespace successfully deleted!"
        return 0
    fi
}

# Main execution
main() {
    if [[ -z "$NAMESPACE" ]]; then
        usage
    fi
    
    echo "======================================"
    echo "Namespace Finalizer Cleanup Script"
    echo "======================================"
    echo
    
    check_prerequisites
    echo
    
    check_namespace
    echo
    
    show_namespace_finalizers
    echo
    
    find_resources_with_finalizers
    echo
    
    if [[ "$DRY_RUN" == "false" ]]; then
        log_warning "This will remove all finalizers from resources in namespace: $NAMESPACE"
        log_warning "This action bypasses intended cleanup procedures!"
        read -p "Are you sure you want to continue? (yes/N) " -r
        echo
        if [[ ! $REPLY =~ ^yes$ ]]; then
            log_info "Aborted by user"
            exit 0
        fi
    fi
    
    remove_resource_finalizers
    echo
    
    remove_namespace_finalizers
    echo
    
    if [[ "$DRY_RUN" == "false" ]]; then
        verify_deletion
    else
        log_info "[DRY-RUN] No changes were made"
    fi
}

# Run main function
main "$@"


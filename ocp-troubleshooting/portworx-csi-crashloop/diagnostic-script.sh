#!/bin/bash
#
# Portworx CSI Pod CrashLoopBackOff Diagnostic Script
#
# This script collects diagnostic information for troubleshooting
# px-csi-ext pod CrashLoopBackOff issues.
#
# Usage: ./diagnostic-script.sh [output-file]
#
# If no output file is specified, prints to stdout

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_section() {
    echo ""
    echo "============================================================"
    echo "$1"
    echo "============================================================"
    echo ""
}

# Function to print with color (only if output is terminal)
print_color() {
    local color=$1
    shift
    if [ -t 1 ]; then
        echo -e "${color}$*${NC}"
    else
        echo "$*"
    fi
}

# Function to safely execute commands
safe_exec() {
    local cmd="$*"
    echo "$ $cmd"
    if ! eval "$cmd" 2>&1; then
        print_color "$RED" "Command failed: $cmd"
    fi
    echo ""
}

# Function to check command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_color "$RED" "Error: Required command '$1' not found"
        exit 1
    fi
}

# Main diagnostic function
run_diagnostics() {
    print_section "Portworx CSI Diagnostic Report"
    echo "Generated: $(date)"
    echo "Hostname: $(hostname)"
    echo ""

    # Check for required commands
    check_command oc
    check_command jq

    print_section "1. CSI Pod Status"
    
    echo "Finding px-csi-ext pod..."
    if PX_CSI_POD=$(oc get pods -n kube-system -l app=px-csi-driver -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n' | grep 'px-csi-ext-' | grep -v node | head -1); then
        echo "CSI Pod found: $PX_CSI_POD"
        echo ""
    else
        print_color "$RED" "ERROR: Could not find px-csi-ext pod"
        echo "Listing all pods in kube-system namespace with label app=px-csi-driver:"
        safe_exec "oc get pods -n kube-system -l app=px-csi-driver"
        return 1
    fi

    echo "All CSI driver pods:"
    safe_exec "oc get pods -n kube-system -l app=px-csi-driver -o wide"

    echo "Detailed pod status:"
    safe_exec "oc get pod -n kube-system $PX_CSI_POD -o yaml"

    echo "Pod description:"
    safe_exec "oc describe pod -n kube-system $PX_CSI_POD"

    print_section "2. CSI Pod Logs"
    
    echo "Current logs (last 100 lines):"
    safe_exec "oc logs -n kube-system $PX_CSI_POD --all-containers=true --tail=100"

    echo "Previous crash logs (last 100 lines):"
    safe_exec "oc logs -n kube-system $PX_CSI_POD --previous --all-containers=true --tail=100"

    echo "Searching for error patterns in previous logs:"
    if oc logs -n kube-system "$PX_CSI_POD" --previous --all-containers=true 2>/dev/null | grep -i "error\|failed\|fatal\|panic"; then
        :
    else
        echo "No error patterns found (or pod hasn't crashed yet)"
    fi
    echo ""

    print_section "3. Events"
    
    echo "Events for CSI pod:"
    safe_exec "oc get events -n kube-system --field-selector involvedObject.name=$PX_CSI_POD --sort-by='.lastTimestamp'"

    echo "All recent Portworx events (last 30):"
    safe_exec "oc get events -n kube-system --sort-by='.lastTimestamp' | grep -i portworx | tail -30"

    echo "Recent namespace events (last 50):"
    safe_exec "oc get events -n kube-system --sort-by='.lastTimestamp' | tail -50"

    print_section "4. Portworx Cluster Health"
    
    echo "Portworx pods:"
    safe_exec "oc get pods -n kube-system -l name=portworx -o wide"

    echo "Portworx pod restart counts:"
    safe_exec "oc get pods -n kube-system -l name=portworx -o jsonpath='{range .items[*]}{.metadata.name}{\"\t\"}{.status.containerStatuses[0].restartCount}{\"\n\"}{end}'"

    if PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); then
        echo "Portworx cluster status:"
        safe_exec "oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status"

        echo "Portworx cluster list:"
        safe_exec "oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl cluster list"

        echo "Portworx service list:"
        safe_exec "oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl service list"
    else
        print_color "$RED" "ERROR: No Portworx pods found!"
    fi

    echo "Portworx operator:"
    safe_exec "oc get pods -n kube-system | grep portworx-operator"

    print_section "5. CSI Driver Registration"
    
    echo "CSI drivers:"
    safe_exec "oc get csidriver"

    echo "Portworx CSI driver details:"
    safe_exec "oc get csidriver pxd.portworx.com -o yaml"

    echo "CSI nodes:"
    safe_exec "oc get csinode"

    if CSI_NODE=$(oc get pod -n kube-system "$PX_CSI_POD" -o jsonpath='{.spec.nodeName}' 2>/dev/null); then
        echo "CSI node details for $CSI_NODE:"
        safe_exec "oc describe csinode $CSI_NODE"
    fi

    print_section "6. RBAC and Permissions"
    
    echo "Service account:"
    safe_exec "oc get sa -n kube-system px-account"
    safe_exec "oc describe sa -n kube-system px-account"

    echo "Service account secrets:"
    safe_exec "oc get secrets -n kube-system | grep px-account"

    echo "Cluster role bindings for Portworx:"
    safe_exec "oc get clusterrolebinding | grep portworx"

    echo "Detailed cluster role bindings:"
    safe_exec "oc get clusterrolebinding -o yaml | grep -A 30 portworx"

    echo "Testing permissions for px-account:"
    echo "  - Can create persistentvolumes:"
    safe_exec "oc auth can-i --as=system:serviceaccount:kube-system:px-account create persistentvolumes"
    echo "  - Can get csidrivers:"
    safe_exec "oc auth can-i --as=system:serviceaccount:kube-system:px-account get csidrivers"
    echo "  - Can list nodes:"
    safe_exec "oc auth can-i --as=system:serviceaccount:kube-system:px-account list nodes"
    echo "  - Can create csinodes:"
    safe_exec "oc auth can-i --as=system:serviceaccount:kube-system:px-account create csinodes"

    echo "SecurityContextConstraints (OpenShift):"
    safe_exec "oc get scc | grep portworx"
    echo "Who can use portworx-scc:"
    safe_exec "oc adm policy who-can use scc portworx-scc -n kube-system"

    print_section "7. Node and Scheduling"
    
    if CSI_NODE=$(oc get pod -n kube-system "$PX_CSI_POD" -o jsonpath='{.spec.nodeName}' 2>/dev/null); then
        echo "CSI pod scheduled on node: $CSI_NODE"
        
        echo "Node details:"
        safe_exec "oc describe node $CSI_NODE"

        echo "Node labels:"
        safe_exec "oc get node $CSI_NODE --show-labels"

        echo "Portworx pods on this node:"
        safe_exec "oc get pods -n kube-system -l name=portworx -o wide | grep $CSI_NODE"
    fi

    echo "CSI pod node selector:"
    safe_exec "oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeSelector}'"

    echo "CSI pod affinity rules:"
    safe_exec "oc get pod -n kube-system $PX_CSI_POD -o yaml | grep -A 20 'affinity:'"

    echo "CSI pod tolerations:"
    safe_exec "oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.tolerations}' | jq ."

    echo "All node taints:"
    safe_exec "oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{\"\t\"}{.spec.taints}{\"\n\"}{end}'"

    print_section "8. Resources"
    
    echo "CSI pod resource requests and limits:"
    safe_exec "oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.containers[*].resources}' | jq ."

    echo "Container termination reason (check for OOMKilled):"
    safe_exec "oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.status.containerStatuses[*].lastState.terminated}' | jq ."

    if CSI_NODE=$(oc get pod -n kube-system "$PX_CSI_POD" -o jsonpath='{.spec.nodeName}' 2>/dev/null); then
        echo "Node capacity and allocated resources:"
        safe_exec "oc describe node $CSI_NODE | grep -A 15 'Allocated resources:'"
    fi

    print_section "9. Volume Mounts"
    
    echo "CSI pod volumes:"
    safe_exec "oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.volumes}' | jq ."

    echo "CSI pod volume mounts:"
    safe_exec "oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.containers[*].volumeMounts}' | jq ."

    print_section "10. Storage Configuration"
    
    echo "Portworx storage classes:"
    safe_exec "oc get sc | grep portworx"

    echo "All storage classes (YAML):"
    safe_exec "oc get sc -o yaml | grep -A 20 portworx"

    echo "Existing Portworx PVCs:"
    safe_exec "oc get pvc --all-namespaces -o wide | grep portworx"

    echo "Existing Portworx PVs:"
    safe_exec "oc get pv -o wide | grep portworx"

    print_section "11. Controller/DaemonSet Details"
    
    if CONTROLLER=$(oc get pod -n kube-system "$PX_CSI_POD" -o jsonpath='{.metadata.ownerReferences[0].name}' 2>/dev/null); then
        CONTROLLER_KIND=$(oc get pod -n kube-system "$PX_CSI_POD" -o jsonpath='{.metadata.ownerReferences[0].kind}')
        echo "CSI pod controlled by: $CONTROLLER_KIND/$CONTROLLER"
        
        echo "Controller details:"
        safe_exec "oc get $CONTROLLER_KIND/$CONTROLLER -n kube-system -o yaml"

        echo "Controller status:"
        safe_exec "oc describe $CONTROLLER_KIND/$CONTROLLER -n kube-system"
    fi

    print_section "12. Version Information"
    
    echo "OpenShift version:"
    safe_exec "oc version"

    echo "Cluster version:"
    safe_exec "oc get clusterversion"

    echo "CSI driver image:"
    safe_exec "oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.containers[*].image}'"

    if PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); then
        echo "Portworx version:"
        safe_exec "oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl --version"
    fi

    echo "Portworx operator image:"
    safe_exec "oc get pods -n kube-system -l name=portworx-operator -o jsonpath='{.items[*].spec.containers[*].image}'"

    print_section "13. Summary and Recommendations"
    
    echo "=== DIAGNOSTIC SUMMARY ==="
    echo ""
    
    # Check for common issues
    echo "Quick Issue Detection:"
    echo ""
    
    # Check if CSI pod is actually crashing
    if oc get pod -n kube-system "$PX_CSI_POD" -o jsonpath='{.status.containerStatuses[*].state}' 2>/dev/null | grep -q "waiting"; then
        print_color "$RED" "⚠ CSI pod is in waiting state (likely CrashLoopBackOff)"
    else
        print_color "$GREEN" "✓ CSI pod is not in waiting state"
    fi
    
    # Check restart count
    RESTART_COUNT=$(oc get pod -n kube-system "$PX_CSI_POD" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
    if [ "$RESTART_COUNT" -gt 5 ]; then
        print_color "$RED" "⚠ High restart count: $RESTART_COUNT"
    else
        print_color "$GREEN" "✓ Restart count acceptable: $RESTART_COUNT"
    fi
    
    # Check if Portworx is operational
    if PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); then
        if oc exec -n kube-system "$PX_POD" -- /opt/pwx/bin/pxctl status 2>/dev/null | grep -q "PX is operational"; then
            print_color "$GREEN" "✓ Portworx cluster is operational"
        else
            print_color "$RED" "⚠ Portworx cluster may not be operational - CHECK THIS FIRST"
        fi
    else
        print_color "$RED" "⚠ No Portworx pods found"
    fi
    
    # Check if CSI driver exists
    if oc get csidriver pxd.portworx.com &>/dev/null; then
        print_color "$GREEN" "✓ CSI driver registered"
    else
        print_color "$RED" "⚠ CSI driver not registered"
    fi
    
    echo ""
    echo "=== NEXT STEPS ==="
    echo ""
    echo "1. Review the 'CSI Pod Logs' section for error messages"
    echo "2. Check 'Portworx Cluster Health' - must be operational for CSI to work"
    echo "3. Look for specific error patterns in 'Events' section"
    echo "4. Review 'COMMON-ERRORS.md' for error message lookup"
    echo "5. Follow 'INVESTIGATION-WORKFLOW.md' for systematic troubleshooting"
    echo ""
    echo "Quick commands to try:"
    echo ""
    echo "# Check previous crash logs"
    echo "oc logs -n kube-system $PX_CSI_POD --previous --tail=50"
    echo ""
    echo "# Restart CSI pod (if Portworx cluster is healthy)"
    echo "oc delete pod -n kube-system $PX_CSI_POD"
    echo ""
    echo "# Check Portworx status"
    if PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); then
        echo "oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status"
    fi
    echo ""

    print_section "Diagnostic Collection Complete"
    echo "Report generated: $(date)"
    echo ""
    echo "For more help, see:"
    echo "  - QUICKSTART.md for fast fixes"
    echo "  - QUICK-REFERENCE.md for command reference"
    echo "  - COMMON-ERRORS.md for error lookup"
    echo "  - INVESTIGATION-WORKFLOW.md for systematic troubleshooting"
    echo "  - README.md for comprehensive guide"
}

# Main execution
main() {
    if [ $# -gt 0 ]; then
        # Output to file
        OUTPUT_FILE="$1"
        echo "Collecting diagnostics, output will be saved to: $OUTPUT_FILE"
        run_diagnostics > "$OUTPUT_FILE" 2>&1
        echo "Diagnostic collection complete. Output saved to: $OUTPUT_FILE"
        echo ""
        echo "To view the report:"
        echo "  less $OUTPUT_FILE"
        echo ""
        echo "To share with support:"
        echo "  Upload the file to your support case"
    else
        # Output to stdout
        run_diagnostics
    fi
}

# Run main function
main "$@"


#!/bin/bash
#
# OpenShift API Slowness and Web Console Performance Diagnostic Script
#
# This script performs comprehensive diagnostics for API and web console
# performance issues in OpenShift clusters.
#
# Usage: ./diagnostic-script.sh [output-file]
#
# Output: Saves detailed diagnostic report to specified file or
#         api-diagnostics-YYYYMMDD-HHMMSS.txt by default

set -euo pipefail

# Color output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="${1:-api-diagnostics-${TIMESTAMP}.txt}"
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

# Helper functions
log_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
    echo "=== $1 ===" >> "${OUTPUT_FILE}"
}

log_info() {
    echo -e "${GREEN}✓${NC} $1"
    echo "[OK] $1" >> "${OUTPUT_FILE}"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    echo "[WARNING] $1" >> "${OUTPUT_FILE}"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    echo "[ERROR] $1" >> "${OUTPUT_FILE}"
}

log_output() {
    echo "$1" >> "${OUTPUT_FILE}"
}

measure_time() {
    local cmd="$1"
    local description="$2"
    local start=$(date +%s%N)
    
    if eval "$cmd" >/dev/null 2>&1; then
        local end=$(date +%s%N)
        local duration=$(echo "scale=3; ($end - $start) / 1000000000" | bc)
        echo "$duration"
        return 0
    else
        echo "-1"
        return 1
    fi
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "Required command '$1' not found"
        exit 1
    fi
}

# Check prerequisites
echo -e "${BLUE}OpenShift API Performance Diagnostic Tool${NC}"
echo "========================================="
echo "Starting diagnostics at $(date)"
echo "Output file: ${OUTPUT_FILE}"
echo ""

check_command oc
check_command bc
check_command jq

# Initialize output file
cat > "${OUTPUT_FILE}" << EOF
OpenShift API Performance Diagnostic Report
Generated: $(date)
Cluster: $(oc whoami --show-server 2>/dev/null || echo "Unable to determine")
User: $(oc whoami 2>/dev/null || echo "Unable to determine")

EOF

#
# 1. Performance Baseline Measurements
#
log_section "1. API Performance Baseline"

echo "Measuring API response times..."

# Test: oc get nodes
NODE_TIME=$(measure_time "oc get nodes" "Get nodes")
log_output "oc get nodes: ${NODE_TIME}s"
if (( $(echo "$NODE_TIME > 0 && $NODE_TIME < 1" | bc -l) )); then
    log_info "Nodes query: ${NODE_TIME}s (good)"
elif (( $(echo "$NODE_TIME >= 1 && $NODE_TIME < 3" | bc -l) )); then
    log_warning "Nodes query: ${NODE_TIME}s (degraded - target <1s)"
elif (( $(echo "$NODE_TIME >= 3" | bc -l) )); then
    log_error "Nodes query: ${NODE_TIME}s (critical - target <1s)"
else
    log_error "Unable to measure node query time"
fi

# Test: oc get pods (limited)
POD_TIME=$(measure_time "oc get pods -A --limit=100" "Get pods limited")
log_output "oc get pods -A --limit=100: ${POD_TIME}s"
if (( $(echo "$POD_TIME > 0 && $POD_TIME < 1" | bc -l) )); then
    log_info "Pod query (100): ${POD_TIME}s (good)"
elif (( $(echo "$POD_TIME >= 1 && $POD_TIME < 3" | bc -l) )); then
    log_warning "Pod query (100): ${POD_TIME}s (degraded - target <1s)"
else
    log_error "Pod query (100): ${POD_TIME}s (critical - target <1s)"
fi

# Test: API health endpoint
HEALTH_TIME=$(measure_time "oc get --raw /healthz" "Health check")
log_output "API /healthz: ${HEALTH_TIME}s"
if (( $(echo "$HEALTH_TIME > 0 && $HEALTH_TIME < 0.5" | bc -l) )); then
    log_info "Health endpoint: ${HEALTH_TIME}s (good)"
else
    log_warning "Health endpoint: ${HEALTH_TIME}s (target <0.5s)"
fi

# Test: oc whoami
WHOAMI_TIME=$(measure_time "oc whoami" "Authentication check")
log_output "oc whoami: ${WHOAMI_TIME}s"
if (( $(echo "$WHOAMI_TIME > 0 && $WHOAMI_TIME < 0.5" | bc -l) )); then
    log_info "Auth check: ${WHOAMI_TIME}s (good)"
else
    log_warning "Auth check: ${WHOAMI_TIME}s (target <0.5s)"
fi

#
# 2. Cluster Operator Status
#
log_section "2. Cluster Operator Status"

CRITICAL_OPS="kube-apiserver etcd authentication console"
DEGRADED_COUNT=0

for op in $CRITICAL_OPS; do
    STATUS=$(oc get co $op -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "Unknown")
    DEGRADED=$(oc get co $op -o jsonpath='{.status.conditions[?(@.type=="Degraded")].status}' 2>/dev/null || echo "Unknown")
    
    log_output "$op: Available=$STATUS, Degraded=$DEGRADED"
    
    if [ "$STATUS" = "True" ] && [ "$DEGRADED" = "False" ]; then
        log_info "$op: Healthy"
    else
        log_error "$op: Available=$STATUS, Degraded=$DEGRADED"
        DEGRADED_COUNT=$((DEGRADED_COUNT + 1))
    fi
done

log_output ""
ALL_CO_COUNT=$(oc get co --no-headers 2>/dev/null | wc -l)
ALL_DEGRADED=$(oc get co -o json 2>/dev/null | jq -r '.items[] | select(.status.conditions[] | select(.type=="Degraded" and .status=="True")) | .metadata.name' | wc -l)
log_output "Total cluster operators: $ALL_CO_COUNT"
log_output "Degraded operators: $ALL_DEGRADED"

if [ "$ALL_DEGRADED" -gt 0 ]; then
    log_warning "$ALL_DEGRADED operator(s) degraded"
    log_output "\nDegraded operators:"
    oc get co -o json 2>/dev/null | jq -r '.items[] | select(.status.conditions[] | select(.type=="Degraded" and .status=="True")) | .metadata.name' | while read op; do
        log_output "  - $op"
    done
else
    log_info "All operators healthy"
fi

#
# 3. Control Plane Pod Status
#
log_section "3. Control Plane Pod Status"

NAMESPACES="openshift-kube-apiserver openshift-etcd openshift-console openshift-authentication"

for ns in $NAMESPACES; do
    log_output "\nNamespace: $ns"
    
    TOTAL_PODS=$(oc get pods -n $ns --no-headers 2>/dev/null | wc -l)
    RUNNING_PODS=$(oc get pods -n $ns --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    NOT_RUNNING=$((TOTAL_PODS - RUNNING_PODS))
    
    log_output "Pods: $RUNNING_PODS/$TOTAL_PODS running"
    
    if [ $NOT_RUNNING -eq 0 ]; then
        log_info "$ns: All pods running ($RUNNING_PODS/$TOTAL_PODS)"
    else
        log_warning "$ns: $NOT_RUNNING pod(s) not running"
        oc get pods -n $ns 2>/dev/null | grep -v "Running" >> "${OUTPUT_FILE}" || true
    fi
    
    # Check for recent restarts
    RESTARTS=$(oc get pods -n $ns -o json 2>/dev/null | jq -r '.items[].status.containerStatuses[]?.restartCount' | awk '{sum+=$1} END {print sum}')
    log_output "Total restarts: ${RESTARTS:-0}"
    
    if [ "${RESTARTS:-0}" -gt 10 ]; then
        log_warning "$ns: High restart count (${RESTARTS})"
    fi
done

#
# 4. Resource Utilization
#
log_section "4. Control Plane Resource Utilization"

echo "Checking resource usage..."

# Master node resources
log_output "\nMaster Node Resources:"
if oc adm top nodes -l node-role.kubernetes.io/master= &>/dev/null; then
    oc adm top nodes -l node-role.kubernetes.io/master= >> "${OUTPUT_FILE}" 2>&1
    
    # Parse CPU usage
    MAX_CPU=$(oc adm top nodes -l node-role.kubernetes.io/master= --no-headers 2>/dev/null | awk '{print $3}' | sed 's/%//' | sort -rn | head -1)
    MAX_MEM=$(oc adm top nodes -l node-role.kubernetes.io/master= --no-headers 2>/dev/null | awk '{print $5}' | sed 's/%//' | sort -rn | head -1)
    
    log_output "Peak CPU: ${MAX_CPU}%"
    log_output "Peak Memory: ${MAX_MEM}%"
    
    if [ $(echo "$MAX_CPU > 80" | bc) -eq 1 ]; then
        log_error "Master node CPU usage high: ${MAX_CPU}%"
    elif [ $(echo "$MAX_CPU > 60" | bc) -eq 1 ]; then
        log_warning "Master node CPU usage elevated: ${MAX_CPU}%"
    else
        log_info "Master node CPU usage acceptable: ${MAX_CPU}%"
    fi
    
    if [ $(echo "$MAX_MEM > 80" | bc) -eq 1 ]; then
        log_error "Master node memory usage high: ${MAX_MEM}%"
    elif [ $(echo "$MAX_MEM > 60" | bc) -eq 1 ]; then
        log_warning "Master node memory usage elevated: ${MAX_MEM}%"
    else
        log_info "Master node memory usage acceptable: ${MAX_MEM}%"
    fi
else
    log_warning "Metrics server not available - cannot check resource usage"
fi

# API server pod resources
log_output "\nAPI Server Pod Resources:"
if oc adm top pods -n openshift-kube-apiserver &>/dev/null; then
    oc adm top pods -n openshift-kube-apiserver >> "${OUTPUT_FILE}" 2>&1
else
    log_warning "Cannot retrieve API server pod metrics"
fi

# etcd pod resources
log_output "\netcd Pod Resources:"
if oc adm top pods -n openshift-etcd &>/dev/null; then
    oc adm top pods -n openshift-etcd >> "${OUTPUT_FILE}" 2>&1
else
    log_warning "Cannot retrieve etcd pod metrics"
fi

#
# 5. etcd Health
#
log_section "5. etcd Health and Performance"

echo "Checking etcd health..."

# Get first etcd pod
ETCD_POD=$(oc get pods -n openshift-etcd -l app=etcd -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$ETCD_POD" ]; then
    log_info "etcd pod found: $ETCD_POD"
    
    # etcd database size
    log_output "\netcd Database Size:"
    ETCD_SIZE=$(oc exec -n openshift-etcd $ETCD_POD 2>/dev/null -- du -sh /var/lib/etcd 2>/dev/null | cut -f1 || echo "Unable to determine")
    log_output "$ETCD_SIZE"
    
    # Convert size to GB for comparison (rough estimation)
    SIZE_VALUE=$(echo "$ETCD_SIZE" | grep -oE '[0-9.]+')
    SIZE_UNIT=$(echo "$ETCD_SIZE" | grep -oE '[A-Z]+')
    
    if [ "$SIZE_UNIT" = "G" ] && [ $(echo "$SIZE_VALUE > 8" | bc 2>/dev/null) -eq 1 ]; then
        log_warning "etcd database size large: $ETCD_SIZE (consider defragmentation if >8GB)"
    else
        log_info "etcd database size: $ETCD_SIZE"
    fi
    
    # Try to get etcd member health (complex command, may fail)
    log_output "\netcd Member Health:"
    ETCD_NODE=$(echo $ETCD_POD | sed 's/etcd-//')
    
    if oc exec -n openshift-etcd $ETCD_POD 2>/dev/null -- etcdctl endpoint health \
        --cluster \
        --cacert=/etc/kubernetes/static-pod-certs/configmaps/etcd-serving-ca/ca-bundle.crt \
        --cert=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-${ETCD_NODE}.crt \
        --key=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-${ETCD_NODE}.key \
        >> "${OUTPUT_FILE}" 2>&1; then
        log_info "etcd members healthy"
    else
        log_warning "Unable to check etcd member health (may require debug node access)"
    fi
else
    log_error "No etcd pods found"
fi

#
# 6. Object Counts
#
log_section "6. Cluster Object Counts"

echo "Counting cluster objects..."

# Pod count
POD_COUNT=$(oc get pods -A --no-headers 2>/dev/null | wc -l)
log_output "Total pods: $POD_COUNT"
if [ $POD_COUNT -gt 5000 ]; then
    log_warning "High pod count: $POD_COUNT (may impact API performance)"
else
    log_info "Pod count: $POD_COUNT"
fi

# Completed/Failed pods
COMPLETED=$(oc get pods -A --field-selector=status.phase=Succeeded --no-headers 2>/dev/null | wc -l)
FAILED=$(oc get pods -A --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)
log_output "Completed pods: $COMPLETED"
log_output "Failed pods: $FAILED"

if [ $((COMPLETED + FAILED)) -gt 100 ]; then
    log_warning "Many completed/failed pods ($((COMPLETED + FAILED))) - consider cleanup"
fi

# Event count
EVENT_COUNT=$(oc get events -A --no-headers 2>/dev/null | wc -l)
log_output "Events: $EVENT_COUNT"
if [ $EVENT_COUNT -gt 50000 ]; then
    log_error "Excessive events: $EVENT_COUNT (major API performance impact)"
elif [ $EVENT_COUNT -gt 20000 ]; then
    log_warning "High event count: $EVENT_COUNT (may impact API performance)"
else
    log_info "Event count: $EVENT_COUNT"
fi

# Other resources
CM_COUNT=$(oc get configmaps -A --no-headers 2>/dev/null | wc -l)
SECRET_COUNT=$(oc get secrets -A --no-headers 2>/dev/null | wc -l)
RS_COUNT=$(oc get replicasets -A --no-headers 2>/dev/null | wc -l)

log_output "ConfigMaps: $CM_COUNT"
log_output "Secrets: $SECRET_COUNT"
log_output "ReplicaSets: $RS_COUNT"

# Pending CSRs
CSR_PENDING=$(oc get csr 2>/dev/null | grep -c Pending || echo "0")
log_output "Pending CSRs: $CSR_PENDING"
if [ $CSR_PENDING -gt 50 ]; then
    log_warning "Many pending CSRs: $CSR_PENDING (approve them with: oc get csr -o name | xargs oc adm certificate approve)"
elif [ $CSR_PENDING -gt 10 ]; then
    log_info "Some pending CSRs: $CSR_PENDING"
fi

#
# 7. Log Analysis
#
log_section "7. Recent Error Log Analysis"

echo "Analyzing logs for errors..."

# API server errors
log_output "\nAPI Server Errors (last 100 lines):"
API_ERRORS=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=100 2>/dev/null | grep -i "error" | wc -l)
log_output "Error count: $API_ERRORS"

if [ $API_ERRORS -gt 20 ]; then
    log_error "High error rate in API server logs: $API_ERRORS errors in last 100 lines"
    oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=100 2>/dev/null | grep -i "error" | tail -5 >> "${OUTPUT_FILE}"
elif [ $API_ERRORS -gt 5 ]; then
    log_warning "Some errors in API server logs: $API_ERRORS errors in last 100 lines"
else
    log_info "Low error rate in API server logs: $API_ERRORS errors in last 100 lines"
fi

# etcd errors
log_output "\netcd Errors (last 100 lines):"
ETCD_ERRORS=$(oc logs -n openshift-etcd -l app=etcd --tail=100 2>/dev/null | grep -iE "error|slow|latency" | wc -l)
log_output "Error/slow/latency mentions: $ETCD_ERRORS"

if [ $ETCD_ERRORS -gt 10 ]; then
    log_error "High error/latency rate in etcd logs: $ETCD_ERRORS mentions"
    oc logs -n openshift-etcd -l app=etcd --tail=100 2>/dev/null | grep -iE "error|slow|latency" | tail -5 >> "${OUTPUT_FILE}"
elif [ $ETCD_ERRORS -gt 3 ]; then
    log_warning "Some errors/latency in etcd logs: $ETCD_ERRORS mentions"
else
    log_info "Low error/latency rate in etcd logs"
fi

# Console errors (if console-specific issue)
log_output "\nConsole Errors (last 50 lines):"
CONSOLE_ERRORS=$(oc logs -n openshift-console -l app=console --tail=50 2>/dev/null | grep -i "error" | wc -l)
log_output "Error count: $CONSOLE_ERRORS"

if [ $CONSOLE_ERRORS -gt 10 ]; then
    log_warning "Errors in console logs: $CONSOLE_ERRORS errors in last 50 lines"
elif [ $CONSOLE_ERRORS -gt 0 ]; then
    log_info "Some errors in console logs: $CONSOLE_ERRORS"
fi

#
# 8. Network and Connectivity
#
log_section "8. Network and Connectivity"

echo "Checking network connectivity..."

# API endpoint
log_output "\nAPI Endpoint:"
oc get endpoints kubernetes -n default >> "${OUTPUT_FILE}" 2>&1 || log_error "Cannot retrieve API endpoints"

# Check webhook configurations
VALIDATING_WEBHOOKS=$(oc get validatingwebhookconfigurations --no-headers 2>/dev/null | wc -l)
MUTATING_WEBHOOKS=$(oc get mutatingwebhookconfigurations --no-headers 2>/dev/null | wc -l)
log_output "\nWebhook Configurations:"
log_output "Validating webhooks: $VALIDATING_WEBHOOKS"
log_output "Mutating webhooks: $MUTATING_WEBHOOKS"

if [ $((VALIDATING_WEBHOOKS + MUTATING_WEBHOOKS)) -gt 20 ]; then
    log_warning "Many webhooks configured ($((VALIDATING_WEBHOOKS + MUTATING_WEBHOOKS))) - potential for admission delays"
fi

#
# 9. Node Status
#
log_section "9. Node Status"

log_output "\nMaster Nodes:"
oc get nodes -l node-role.kubernetes.io/master= >> "${OUTPUT_FILE}" 2>&1

NOT_READY_MASTERS=$(oc get nodes -l node-role.kubernetes.io/master= --no-headers 2>/dev/null | grep -cv "Ready" || echo "0")
if [ $NOT_READY_MASTERS -gt 0 ]; then
    log_error "$NOT_READY_MASTERS master node(s) not ready"
else
    log_info "All master nodes ready"
fi

log_output "\nAll Nodes Summary:"
TOTAL_NODES=$(oc get nodes --no-headers 2>/dev/null | wc -l)
READY_NODES=$(oc get nodes --no-headers 2>/dev/null | grep -c "Ready" || echo "0")
log_output "Ready nodes: $READY_NODES/$TOTAL_NODES"

#
# 10. Summary and Recommendations
#
log_section "10. Summary and Recommendations"

echo ""
log_output "\n=== DIAGNOSTIC SUMMARY ==="
log_output ""

# Determine severity
CRITICAL_ISSUES=0
WARNINGS=0

# Count issues
if (( $(echo "$NODE_TIME >= 3" | bc -l 2>/dev/null || echo 0) )); then
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
fi

if [ $DEGRADED_COUNT -gt 0 ]; then
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
fi

if [ $NOT_READY_MASTERS -gt 0 ]; then
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
fi

if [ $EVENT_COUNT -gt 50000 ]; then
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
fi

log_output "Critical Issues: $CRITICAL_ISSUES"
log_output "Warnings: (see above)"
log_output ""

# Recommendations
log_output "=== RECOMMENDATIONS ==="
log_output ""

if (( $(echo "$NODE_TIME > 2" | bc -l 2>/dev/null || echo 0) )); then
    log_output "1. API response time critical (${NODE_TIME}s) - Immediate action required"
    log_output "   → Check etcd health first (most common cause)"
    log_output "   → Review 'etcd Health and Performance' section above"
fi

if [ $DEGRADED_COUNT -gt 0 ]; then
    log_output "2. Critical cluster operators degraded"
    log_output "   → Check operator logs: oc logs -n openshift-<operator-namespace>"
    log_output "   → Review 'Cluster Operator Status' section"
fi

if [ $EVENT_COUNT -gt 20000 ]; then
    log_output "3. High event count detected ($EVENT_COUNT)"
    log_output "   → Events can slow API list operations"
    log_output "   → Consider cleaning old events (with caution)"
fi

if [ $CSR_PENDING -gt 10 ]; then
    log_output "4. Pending CSRs detected ($CSR_PENDING)"
    log_output "   → Approve: oc get csr -o name | xargs oc adm certificate approve"
fi

if [ $((COMPLETED + FAILED)) -gt 100 ]; then
    log_output "5. Many completed/failed pods ($((COMPLETED + FAILED)))"
    log_output "   → Clean up: oc delete pods -A --field-selector=status.phase=Succeeded"
    log_output "   → Clean up: oc delete pods -A --field-selector=status.phase=Failed"
fi

if [ $API_ERRORS -gt 10 ] || [ $ETCD_ERRORS -gt 5 ]; then
    log_output "6. High error rate in control plane logs"
    log_output "   → Review 'Recent Error Log Analysis' section above"
    log_output "   → Check for patterns in errors"
fi

log_output ""
log_output "=== NEXT STEPS ==="
log_output ""

if [ $CRITICAL_ISSUES -eq 0 ]; then
    log_output "✓ No critical issues detected"
    log_output "  Performance baseline recorded for future comparison"
else
    log_output "⚠ $CRITICAL_ISSUES critical issue(s) detected"
    log_output ""
    log_output "Recommended actions:"
    log_output "1. Review recommendations above"
    log_output "2. Consult README.md for detailed troubleshooting procedures"
    log_output "3. If issues persist, collect: oc adm must-gather"
    log_output "4. Check QUICK-REFERENCE.md for fast command reference"
fi

log_output ""
log_output "=== END OF REPORT ==="

# Summary to console
echo ""
echo -e "${BLUE}=== Diagnostic Complete ===${NC}"
echo ""
echo "Results saved to: ${OUTPUT_FILE}"
echo ""

if [ $CRITICAL_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ No critical issues detected${NC}"
else
    echo -e "${RED}✗ $CRITICAL_ISSUES critical issue(s) found${NC}"
    echo ""
    echo "Review the output file for detailed recommendations:"
    echo "  cat ${OUTPUT_FILE}"
fi

echo ""
echo "For quick reference:"
echo "  - Fast commands: See QUICK-REFERENCE.md"
echo "  - Detailed procedures: See README.md"
echo "  - Navigation: See INDEX.md"
echo ""

exit 0


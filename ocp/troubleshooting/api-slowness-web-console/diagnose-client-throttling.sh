#!/bin/bash
#
# Client-Side Throttling Diagnostic Script
#
# Diagnoses client-side throttling issues in OpenShift API server
#
# Usage: ./diagnose-client-throttling.sh [output-file]

set -euo pipefail

# Color output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="${1:-client-throttling-diagnostic-${TIMESTAMP}.txt}"

echo -e "${BLUE}=== Client-Side Throttling Diagnostic ===${NC}"
echo "Started: $(date)"
echo "Output: ${OUTPUT_FILE}"
echo ""

# Initialize output file
cat > "${OUTPUT_FILE}" << EOF
Client-Side Throttling Diagnostic Report
Generated: $(date)
Cluster: $(oc whoami --show-server 2>/dev/null || echo "Unable to determine")

EOF

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

#
# 1. Throttling Event Frequency
#
log_section "1. Throttling Event Frequency"

echo "Analyzing API server logs for throttling events..."

THROTTLE_COUNT=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep -c "client-side throttling" || echo "0")

log_output "Throttling events in last 5000 log lines: $THROTTLE_COUNT"

if [ $THROTTLE_COUNT -gt 100 ]; then
    log_error "HIGH: $THROTTLE_COUNT throttling events detected (critical)"
    SEVERITY="CRITICAL"
elif [ $THROTTLE_COUNT -gt 10 ]; then
    log_warning "MODERATE: $THROTTLE_COUNT throttling events detected"
    SEVERITY="WARNING"
else
    log_info "LOW: $THROTTLE_COUNT throttling events"
    SEVERITY="OK"
fi

# Recent throttling rate
RECENT_THROTTLE=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --since=5m 2>/dev/null | \
  grep -c "client-side throttling" || echo "0")

log_output "Throttling events in last 5 minutes: $RECENT_THROTTLE"

if [ $RECENT_THROTTLE -gt 20 ]; then
    log_error "High recent throttling rate: $RECENT_THROTTLE/5min"
fi

#
# 2. Throttled Clients Identification
#
log_section "2. Top Throttled Clients"

echo "Identifying clients being throttled..."

log_output "\nTop 10 throttled clients:"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep "client-side throttling" | \
  grep -oP 'user="[^"]+' | \
  sed 's/user="//' | \
  sort | uniq -c | sort -rn | head -10 | tee -a "${OUTPUT_FILE}"

# Extract most throttled client
TOP_CLIENT=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep "client-side throttling" | \
  grep -oP 'user="[^"]+' | \
  sed 's/user="//' | \
  sort | uniq -c | sort -rn | head -1 | awk '{print $2}')

if [ -n "$TOP_CLIENT" ]; then
    log_output "\nMost throttled client: $TOP_CLIENT"
    log_warning "Focus investigation on: $TOP_CLIENT"
fi

#
# 3. TokenReview Request Analysis
#
log_section "3. TokenReview Request Volume"

echo "Analyzing tokenreview requests..."

TOKENREVIEW_COUNT=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep -c "tokenreviews" || echo "0")

log_output "TokenReview requests in last 5000 lines: $TOKENREVIEW_COUNT"

if [ $TOKENREVIEW_COUNT -gt 1000 ]; then
    log_error "Very high tokenreview volume: $TOKENREVIEW_COUNT"
elif [ $TOKENREVIEW_COUNT -gt 500 ]; then
    log_warning "High tokenreview volume: $TOKENREVIEW_COUNT"
else
    log_info "TokenReview volume: $TOKENREVIEW_COUNT"
fi

# Top service accounts doing tokenreviews
log_output "\nTop 10 service accounts (tokenreviews):"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep "tokenreviews" | \
  grep -oP 'system:serviceaccount:\K[^"]+' | \
  awk -F: '{print $1":"$2}' | \
  sort | uniq -c | sort -rn | head -10 | tee -a "${OUTPUT_FILE}"

#
# 4. Webhook Configuration Analysis
#
log_section "4. Webhook Configuration"

echo "Checking webhook configurations..."

VALIDATING=$(oc get validatingwebhookconfigurations --no-headers 2>/dev/null | wc -l)
MUTATING=$(oc get mutatingwebhookconfigurations --no-headers 2>/dev/null | wc -l)
TOTAL_WEBHOOKS=$((VALIDATING + MUTATING))

log_output "Validating webhooks: $VALIDATING"
log_output "Mutating webhooks: $MUTATING"
log_output "Total webhooks: $TOTAL_WEBHOOKS"

if [ $TOTAL_WEBHOOKS -gt 20 ]; then
    log_warning "High webhook count: $TOTAL_WEBHOOKS (may contribute to throttling)"
elif [ $TOTAL_WEBHOOKS -gt 10 ]; then
    log_info "Moderate webhook count: $TOTAL_WEBHOOKS"
else
    log_info "Webhook count: $TOTAL_WEBHOOKS"
fi

# List webhooks
log_output "\nValidating webhooks:"
oc get validatingwebhookconfigurations --no-headers 2>/dev/null | awk '{print "  - "$1}' >> "${OUTPUT_FILE}"

log_output "\nMutating webhooks:"
oc get mutatingwebhookconfigurations --no-headers 2>/dev/null | awk '{print "  - "$1}' >> "${OUTPUT_FILE}"

# Check webhook call volume
WEBHOOK_CALLS=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=2000 2>/dev/null | \
  grep -c "webhook" || echo "0")

log_output "\nWebhook calls in last 2000 log lines: $WEBHOOK_CALLS"

#
# 5. Pod Churn Analysis
#
log_section "5. Pod Churn and CrashLoops"

echo "Checking for pod churn..."

# CrashLooping pods
CRASHLOOP_COUNT=$(oc get pods -A -o json 2>/dev/null | \
  jq -r '.items[] | 
    select(.status.containerStatuses[]?.state.waiting?.reason == "CrashLoopBackOff") | 
    "\(.metadata.namespace)/\(.metadata.name)"' | wc -l)

log_output "Pods in CrashLoopBackOff: $CRASHLOOP_COUNT"

if [ $CRASHLOOP_COUNT -gt 20 ]; then
    log_error "Many crashlooping pods: $CRASHLOOP_COUNT (amplifies throttling)"
elif [ $CRASHLOOP_COUNT -gt 10 ]; then
    log_warning "Some crashlooping pods: $CRASHLOOP_COUNT"
else
    log_info "CrashLooping pods: $CRASHLOOP_COUNT"
fi

if [ $CRASHLOOP_COUNT -gt 0 ]; then
    log_output "\nCrashLooping pods:"
    oc get pods -A -o json 2>/dev/null | \
      jq -r '.items[] | 
        select(.status.containerStatuses[]?.state.waiting?.reason == "CrashLoopBackOff") | 
        "\(.metadata.namespace)/\(.metadata.name) Restarts:\(.status.containerStatuses[0].restartCount)"' | \
      head -10 >> "${OUTPUT_FILE}"
fi

# Recent pod events
RECENT_POD_EVENTS=$(oc get events -A --sort-by='.lastTimestamp' 2>/dev/null | \
  grep -E "Created|Started" | tail -20 | wc -l)

log_output "\nRecent pod creation events: $RECENT_POD_EVENTS"

#
# 6. API Server Resource Usage
#
log_section "6. API Server Resource Usage"

echo "Checking API server resources..."

log_output "\nAPI Server pod resource usage:"
if oc adm top pods -n openshift-kube-apiserver 2>/dev/null >> "${OUTPUT_FILE}"; then
    # Check for high CPU
    MAX_CPU=$(oc adm top pods -n openshift-kube-apiserver --no-headers 2>/dev/null | \
      awk '{print $2}' | sed 's/m//' | sort -rn | head -1)
    
    if [ -n "$MAX_CPU" ] && [ "$MAX_CPU" -gt 2000 ]; then
        log_warning "High API server CPU: ${MAX_CPU}m"
    fi
else
    log_warning "Metrics not available"
fi

# API server pod count
API_POD_COUNT=$(oc get pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver --no-headers 2>/dev/null | wc -l)
log_output "\nAPI server pods running: $API_POD_COUNT"

#
# 7. API Priority and Fairness
#
log_section "7. API Priority and Fairness Configuration"

echo "Checking APF configuration..."

FLOWSCHEMA_COUNT=$(oc get flowschema --no-headers 2>/dev/null | wc -l)
PRIORITY_COUNT=$(oc get prioritylevelconfiguration --no-headers 2>/dev/null | wc -l)

log_output "FlowSchemas: $FLOWSCHEMA_COUNT"
log_output "PriorityLevelConfigurations: $PRIORITY_COUNT"

# Check for rejected requests (APF)
log_output "\nAPF Metrics (if available):"
oc get --raw /metrics 2>/dev/null | \
  grep "apiserver_flowcontrol_rejected_requests_total" | \
  head -5 >> "${OUTPUT_FILE}" || log_output "  Metrics not available"

#
# 8. Top API Request Types
#
log_section "8. API Request Patterns"

echo "Analyzing API request patterns..."

log_output "\nTop request types (from logs):"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=2000 2>/dev/null | \
  grep -oP 'verb="[^"]+.*resource="[^"]+' | \
  sed 's/verb="//;s/" resource="/ /;s/"//' | \
  awk '{print $1" "$2}' | \
  sort | uniq -c | sort -rn | head -10 >> "${OUTPUT_FILE}"

#
# 9. Summary and Recommendations
#
log_section "9. Summary and Recommendations"

log_output "\n=== DIAGNOSTIC SUMMARY ==="
log_output "Severity: $SEVERITY"
log_output "Throttling events: $THROTTLE_COUNT"
log_output "Recent throttling: $RECENT_THROTTLE/5min"
log_output "TokenReview volume: $TOKENREVIEW_COUNT"
log_output "Webhooks: $TOTAL_WEBHOOKS"
log_output "CrashLooping pods: $CRASHLOOP_COUNT"
log_output ""

log_output "=== RECOMMENDATIONS ==="
log_output ""

if [ "$SEVERITY" = "CRITICAL" ]; then
    log_output "URGENT: Critical client-side throttling detected"
    log_output ""
    log_output "Immediate actions:"
    log_output "1. Investigate top throttled client: $TOP_CLIENT"
    log_output "   - Find pods: oc get pods -A --field-selector spec.serviceAccountName=<sa-name>"
    log_output "   - Check logs: oc logs -n <namespace> <pod-name>"
    log_output ""
    
    if [ $TOKENREVIEW_COUNT -gt 1000 ]; then
        log_output "2. High tokenreview volume detected:"
        log_output "   - Review webhook configurations (section 4)"
        log_output "   - Check for authentication loops"
        log_output ""
    fi
    
    if [ $CRASHLOOP_COUNT -gt 10 ]; then
        log_output "3. Fix crashlooping pods:"
        log_output "   - ./scale-down-crashloops.sh"
        log_output ""
    fi
    
    if [ $TOTAL_WEBHOOKS -gt 15 ]; then
        log_output "4. Optimize webhook configuration:"
        log_output "   - Review if all webhooks are necessary"
        log_output "   - Increase webhook timeouts"
        log_output "   - Set failurePolicy: Ignore for non-critical webhooks"
        log_output ""
    fi
    
elif [ "$SEVERITY" = "WARNING" ]; then
    log_output "Action recommended: Moderate throttling detected"
    log_output ""
    log_output "Recommended actions:"
    log_output "1. Monitor top throttled client: $TOP_CLIENT"
    log_output "2. Review service accounts making excessive tokenreviews (section 3)"
    log_output "3. Consider webhook optimization if count is high"
    log_output "4. Fix crashlooping pods if present"
    
else
    log_output "Status: Throttling levels are acceptable"
    log_output ""
    log_output "Monitoring recommendations:"
    log_output "- Continue to monitor throttling events"
    log_output "- Set up alerts for throttling rate >100/hour"
    log_output "- Monitor tokenreview request volume"
fi

log_output ""
log_output "For detailed troubleshooting:"
log_output "  cat CLIENT-SIDE-THROTTLING.md"
log_output ""
log_output "=== END OF REPORT ==="

# Console summary
echo ""
echo -e "${BLUE}=== Diagnostic Complete ===${NC}"
echo ""
echo "Results saved to: ${OUTPUT_FILE}"
echo ""

if [ "$SEVERITY" = "CRITICAL" ]; then
    echo -e "${RED}✗ CRITICAL${NC}: $THROTTLE_COUNT throttling events detected"
    echo ""
    echo "Immediate action required!"
    echo "Review output file for specific recommendations."
elif [ "$SEVERITY" = "WARNING" ]; then
    echo -e "${YELLOW}⚠ WARNING${NC}: $THROTTLE_COUNT throttling events detected"
    echo ""
    echo "Action recommended."
    echo "Review output file for specific steps."
else
    echo -e "${GREEN}✓ OK${NC}: Throttling levels acceptable ($THROTTLE_COUNT events)"
    echo ""
    echo "Continue monitoring."
fi

echo ""
echo "For detailed guidance:"
echo "  cat CLIENT-SIDE-THROTTLING.md"
echo ""

exit 0


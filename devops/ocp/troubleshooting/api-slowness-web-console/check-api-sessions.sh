#!/bin/bash
#
# Check API Sessions and Connections
#
# Provides comprehensive view of active API server connections,
# inflight requests, watch connections, and client activity
#
# Usage: ./check-api-sessions.sh [output-file]

set -euo pipefail

# Color output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="${1:-api-sessions-${TIMESTAMP}.txt}"

echo -e "${BLUE}=== OpenShift API Server Session Analysis ===${NC}"
echo "Time: $(date)"
echo "Output: ${OUTPUT_FILE}"
echo ""

# Initialize output file
cat > "${OUTPUT_FILE}" << EOF
OpenShift API Server Session Analysis
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
# 1. Inflight Requests
#
log_section "1. Current Inflight Requests"

echo "Checking active API requests..."

MUTATING=$(oc get --raw /metrics 2>/dev/null | \
  grep 'apiserver_current_inflight_requests{requestKind="mutating"}' | \
  grep -oP '\d+$' | head -1 || echo "0")

READONLY=$(oc get --raw /metrics 2>/dev/null | \
  grep 'apiserver_current_inflight_requests{requestKind="readOnly"}' | \
  grep -oP '\d+$' | head -1 || echo "0")

TOTAL_INFLIGHT=$((MUTATING + READONLY))

log_output "Mutating requests: $MUTATING"
log_output "Read-only requests: $READONLY"
log_output "Total inflight: $TOTAL_INFLIGHT"

if [ $TOTAL_INFLIGHT -gt 400 ]; then
    log_error "Very high inflight requests: $TOTAL_INFLIGHT (critical)"
    SEVERITY="CRITICAL"
elif [ $TOTAL_INFLIGHT -gt 200 ]; then
    log_warning "High inflight requests: $TOTAL_INFLIGHT"
    SEVERITY="WARNING"
else
    log_info "Inflight requests: $TOTAL_INFLIGHT"
    SEVERITY="OK"
fi

#
# 2. Long-running Requests
#
log_section "2. Long-running Requests (Watches)"

echo "Checking watch connections..."

LONGRUNNING=$(oc get --raw /metrics 2>/dev/null | \
  grep 'apiserver_longrunning_requests{' | \
  grep -oP '\d+$' | \
  awk '{sum+=$1} END {print sum}' || echo "0")

log_output "Current long-running requests: $LONGRUNNING"

if [ $LONGRUNNING -gt 1000 ]; then
    log_error "Very high long-running requests: $LONGRUNNING"
elif [ $LONGRUNNING -gt 500 ]; then
    log_warning "High long-running requests: $LONGRUNNING"
else
    log_info "Long-running requests: $LONGRUNNING"
fi

# Break down by verb
log_output "\nLong-running requests by verb:"
oc get --raw /metrics 2>/dev/null | \
  grep 'apiserver_longrunning_requests{' | \
  grep -v "^#" | \
  head -10 >> "${OUTPUT_FILE}"

#
# 3. Registered Watchers
#
log_section "3. Registered Watchers by Resource"

echo "Checking registered watchers..."

log_output "\nTop watchers by resource type:"
oc get --raw /metrics 2>/dev/null | \
  grep 'apiserver_registered_watchers{' | \
  grep -v "^#" | \
  sort -t= -k2 -rn | \
  head -15 >> "${OUTPUT_FILE}"

TOTAL_WATCHERS=$(oc get --raw /metrics 2>/dev/null | \
  grep 'apiserver_registered_watchers{' | \
  grep -oP '\d+$' | \
  awk '{sum+=$1} END {print sum}' || echo "0")

log_output "\nTotal registered watchers: $TOTAL_WATCHERS"

if [ $TOTAL_WATCHERS -gt 5000 ]; then
    log_warning "High watcher count: $TOTAL_WATCHERS"
fi

#
# 4. TCP Connections to API Server
#
log_section "4. TCP Connections to API Server Pods"

echo "Checking TCP connections..."

log_output "\nConnections per API server pod:"

TOTAL_CONNECTIONS=0
for pod in $(oc get pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver -o name 2>/dev/null); do
  POD_NAME=${pod#pod/}
  log_output "\n$POD_NAME:"
  
  # Get established connections
  CONN_COUNT=$(oc exec -n openshift-kube-apiserver $pod -c kube-apiserver -- \
    ss -tn sport = :6443 2>/dev/null | tail -n +2 | wc -l || echo "?")
  
  log_output "  Established connections: $CONN_COUNT"
  
  if [ "$CONN_COUNT" != "?" ]; then
    TOTAL_CONNECTIONS=$((TOTAL_CONNECTIONS + CONN_COUNT))
    
    # Connection state breakdown
    log_output "  Connection states:"
    oc exec -n openshift-kube-apiserver $pod -c kube-apiserver -- \
      ss -tn sport = :6443 2>/dev/null | \
      awk 'NR>1 {print $1}' | sort | uniq -c | \
      sed 's/^/    /' >> "${OUTPUT_FILE}"
  fi
done

log_output "\nTotal connections across all API pods: $TOTAL_CONNECTIONS"

if [ $TOTAL_CONNECTIONS -gt 2000 ]; then
    log_warning "High connection count: $TOTAL_CONNECTIONS"
fi

#
# 5. Request Rate Analysis
#
log_section "5. Recent Request Rate"

echo "Analyzing request rate..."

REQUESTS_1K=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=1000 2>/dev/null | \
  grep -c "verb=" || echo "0")

REQUESTS_5K=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep -c "verb=" || echo "0")

log_output "Requests in last 1000 log lines: $REQUESTS_1K"
log_output "Requests in last 5000 log lines: $REQUESTS_5K"

# Estimate rate (very rough)
if [ $REQUESTS_5K -gt 0 ]; then
    log_output "Approximate request rate: ~$((REQUESTS_1K * 6))/min (rough estimate)"
fi

#
# 6. Active Clients
#
log_section "6. Active Clients Analysis"

echo "Analyzing active clients..."

UNIQUE_USERS=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=2000 2>/dev/null | \
  grep -oP 'user="[^"]+' | \
  sed 's/user="//' | \
  sort -u | wc -l)

log_output "Unique users/service accounts (last 2000 requests): $UNIQUE_USERS"

log_output "\nTop 15 active clients by request count:"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep -oP 'user="[^"]+' | \
  sed 's/user="//' | \
  sort | uniq -c | sort -rn | head -15 | \
  tee -a "${OUTPUT_FILE}"

# Identify potential problematic clients
log_output "\nClients with >100 requests in sample:"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep -oP 'user="[^"]+' | \
  sed 's/user="//' | \
  sort | uniq -c | sort -rn | \
  awk '$1 > 100 {print $0}' >> "${OUTPUT_FILE}"

#
# 7. API Priority and Fairness Queue
#
log_section "7. API Priority and Fairness (APF) Status"

echo "Checking APF queues..."

log_output "\nCurrent queued requests:"
oc get --raw /metrics 2>/dev/null | \
  grep 'apiserver_flowcontrol_current_inqueue_requests{' | \
  grep -v "^#" | \
  grep -v ' 0$' | \
  head -10 >> "${OUTPUT_FILE}" || log_output "No queued requests"

log_output "\nRejected requests (if any):"
oc get --raw /metrics 2>/dev/null | \
  grep 'apiserver_flowcontrol_rejected_requests_total{' | \
  grep -v "^#" | \
  grep -v ' 0$' | \
  head -5 >> "${OUTPUT_FILE}" || log_output "No rejected requests"

#
# 8. Request Breakdown by Verb and Resource
#
log_section "8. Request Patterns (Last 2000 Requests)"

echo "Analyzing request patterns..."

log_output "\nTop request types (verb + resource):"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=2000 2>/dev/null | \
  grep -oP 'verb="[^"]+.*?resource="[^"]+' | \
  sed 's/verb="//;s/" resource="/ /;s/"//' | \
  awk '{print $1" "$2}' | \
  sort | uniq -c | sort -rn | head -15 >> "${OUTPUT_FILE}"

#
# 9. OAuth and Authentication Load
#
log_section "9. Authentication Load"

echo "Checking authentication activity..."

OAUTH_REQUESTS=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=2000 2>/dev/null | \
  grep -c "oauth\|authentication" || echo "0")

TOKENREVIEW_REQUESTS=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=2000 2>/dev/null | \
  grep -c "tokenreviews" || echo "0")

log_output "OAuth/auth related requests (last 2000): $OAUTH_REQUESTS"
log_output "TokenReview requests (last 2000): $TOKENREVIEW_REQUESTS"

if [ $TOKENREVIEW_REQUESTS -gt 500 ]; then
    log_warning "High tokenreview volume: $TOKENREVIEW_REQUESTS"
    log_output "  See: ./diagnose-client-throttling.sh"
fi

#
# 10. Summary and Recommendations
#
log_section "10. Summary and Recommendations"

log_output "\n=== SESSION SUMMARY ==="
log_output "Overall Status: $SEVERITY"
log_output ""
log_output "Key Metrics:"
log_output "  - Total inflight requests: $TOTAL_INFLIGHT"
log_output "  - Long-running requests: $LONGRUNNING"
log_output "  - Total watchers: $TOTAL_WATCHERS"
log_output "  - TCP connections: $TOTAL_CONNECTIONS"
log_output "  - Unique active clients: $UNIQUE_USERS"
log_output ""

log_output "=== RECOMMENDATIONS ==="
log_output ""

if [ "$SEVERITY" = "CRITICAL" ]; then
    log_output "CRITICAL: High API load detected"
    log_output ""
    log_output "Immediate actions:"
    
    if [ $TOTAL_INFLIGHT -gt 400 ]; then
        log_output "1. High inflight requests ($TOTAL_INFLIGHT):"
        log_output "   - API server may be overloaded"
        log_output "   - Review top active clients (section 6)"
        log_output "   - Check for runaway controllers/operators"
        log_output ""
    fi
    
    if [ $LONGRUNNING -gt 1000 ]; then
        log_output "2. Many long-running requests ($LONGRUNNING):"
        log_output "   - Excessive watch connections"
        log_output "   - Check for clients not closing watches properly"
        log_output "   - Review controllers with high watch counts"
        log_output ""
    fi
    
    if [ $TOTAL_CONNECTIONS -gt 2000 ]; then
        log_output "3. High connection count ($TOTAL_CONNECTIONS):"
        log_output "   - Many clients connected"
        log_output "   - Check for connection leaks"
        log_output "   - Review if connections are being reused properly"
        log_output ""
    fi
    
elif [ "$SEVERITY" = "WARNING" ]; then
    log_output "Action recommended: Elevated API load"
    log_output ""
    log_output "Recommended actions:"
    log_output "1. Monitor top active clients (section 6)"
    log_output "2. Review long-running request count"
    log_output "3. Check for unusual request patterns"
    
else
    log_output "Status: API session load is normal"
    log_output ""
    log_output "Monitoring recommendations:"
    log_output "- Continue to monitor inflight requests"
    log_output "- Watch for growth in long-running requests"
    log_output "- Set alerts for inflight >300, long-running >800"
fi

log_output ""
log_output "Related diagnostics:"
log_output "  ./diagnostic-script.sh - Full API performance diagnostic"
log_output "  ./diagnose-client-throttling.sh - Client throttling analysis"
log_output "  cat README.md - Complete troubleshooting guide"
log_output ""
log_output "=== END OF REPORT ==="

# Console summary
echo ""
echo -e "${BLUE}=== Analysis Complete ===${NC}"
echo ""
echo "Results saved to: ${OUTPUT_FILE}"
echo ""

if [ "$SEVERITY" = "CRITICAL" ]; then
    echo -e "${RED}✗ CRITICAL${NC}: High API load detected"
    echo "  Inflight: $TOTAL_INFLIGHT | Long-running: $LONGRUNNING"
    echo ""
    echo "Review output file for specific recommendations"
elif [ "$SEVERITY" = "WARNING" ]; then
    echo -e "${YELLOW}⚠ WARNING${NC}: Elevated API load"
    echo "  Inflight: $TOTAL_INFLIGHT | Long-running: $LONGRUNNING"
    echo ""
    echo "Monitor and investigate top clients"
else
    echo -e "${GREEN}✓ OK${NC}: API session load is normal"
    echo "  Inflight: $TOTAL_INFLIGHT | Long-running: $LONGRUNNING"
fi

echo ""
echo "For detailed analysis:"
echo "  cat ${OUTPUT_FILE}"
echo ""

exit 0


#!/bin/bash
#
# Service Account Token Expiry Diagnostic Script
#
# Diagnoses "service account token has expired" errors in OpenShift
#
# Usage: ./diagnose-token-expiry.sh [output-file]

set -euo pipefail

# Color output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="${1:-token-expiry-diagnostic-${TIMESTAMP}.txt}"

echo -e "${BLUE}=== Service Account Token Expiry Diagnostic ===${NC}"
echo "Started: $(date)"
echo "Output: ${OUTPUT_FILE}"
echo ""

# Initialize output file
cat > "${OUTPUT_FILE}" << EOF
Service Account Token Expiry Diagnostic Report
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
# 1. Error Frequency Analysis
#
log_section "1. Token Expiry Error Frequency"

echo "Analyzing API server logs..."

# Count errors in last 5000 lines
ERROR_COUNT=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep -c "service account token has expired" || echo "0")

log_output "Errors in last 5000 log lines: $ERROR_COUNT"

if [ $ERROR_COUNT -gt 100 ]; then
    log_error "HIGH: $ERROR_COUNT token expiry errors detected (critical)"
    SEVERITY="CRITICAL"
elif [ $ERROR_COUNT -gt 10 ]; then
    log_warning "MODERATE: $ERROR_COUNT token expiry errors detected"
    SEVERITY="WARNING"
else
    log_info "LOW: $ERROR_COUNT token expiry errors"
    SEVERITY="OK"
fi

# Recent error rate
echo "Checking recent error rate..."
RECENT_ERRORS=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --since=5m 2>/dev/null | \
  grep -c "service account token has expired" || echo "0")

log_output "Errors in last 5 minutes: $RECENT_ERRORS"

if [ $RECENT_ERRORS -gt 20 ]; then
    log_error "High recent error rate: $RECENT_ERRORS errors/5min"
else
    log_info "Recent error rate: $RECENT_ERRORS errors/5min"
fi

#
# 2. Affected Service Accounts
#
log_section "2. Affected Service Accounts"

echo "Identifying affected service accounts..."

log_output "\nTop 10 affected service accounts:"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep "service account token has expired" | \
  grep -oP 'system:serviceaccount:\K[^"]+' | \
  sort | uniq -c | sort -rn | head -10 | tee -a "${OUTPUT_FILE}"

# Get affected namespaces
log_output "\nAffected namespaces:"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep "service account token has expired" | \
  grep -oP 'system:serviceaccount:\K[^:]+' | \
  sort -u | tee -a "${OUTPUT_FILE}"

#
# 3. Critical Operator Status
#
log_section "3. Critical Operator Status"

echo "Checking cluster operators..."

# service-ca
SERVICE_CA_STATUS=$(oc get co service-ca -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "Unknown")
SERVICE_CA_DEGRADED=$(oc get co service-ca -o jsonpath='{.status.conditions[?(@.type=="Degraded")].status}' 2>/dev/null || echo "Unknown")

log_output "service-ca: Available=$SERVICE_CA_STATUS, Degraded=$SERVICE_CA_DEGRADED"

if [ "$SERVICE_CA_STATUS" = "True" ] && [ "$SERVICE_CA_DEGRADED" = "False" ]; then
    log_info "service-ca-operator: Healthy"
else
    log_error "service-ca-operator: Available=$SERVICE_CA_STATUS, Degraded=$SERVICE_CA_DEGRADED"
fi

# kube-controller-manager
KCM_STATUS=$(oc get co kube-controller-manager -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "Unknown")
KCM_DEGRADED=$(oc get co kube-controller-manager -o jsonpath='{.status.conditions[?(@.type=="Degraded")].status}' 2>/dev/null || echo "Unknown")

log_output "kube-controller-manager: Available=$KCM_STATUS, Degraded=$KCM_DEGRADED"

if [ "$KCM_STATUS" = "True" ] && [ "$KCM_DEGRADED" = "False" ]; then
    log_info "kube-controller-manager: Healthy"
else
    log_error "kube-controller-manager: Available=$KCM_STATUS, Degraded=$KCM_DEGRADED"
fi

#
# 4. Time Synchronization Check
#
log_section "4. Node Time Synchronization"

echo "Checking time sync across nodes..."

BASE_TIME=$(date +%s)
SKEW_DETECTED=0

log_output "\nNode time comparison:"

for node in $(oc get nodes -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    NODE_TIME=$(oc debug node/$node -- chroot /host date +%s 2>/dev/null | grep -v "Starting pod" | tail -1 || echo "0")
    
    if [ "$NODE_TIME" != "0" ]; then
        DIFF=$((NODE_TIME - BASE_TIME))
        ABS_DIFF=${DIFF#-}
        
        log_output "$node: ${DIFF}s difference"
        
        if [ $ABS_DIFF -gt 5 ]; then
            log_warning "$node: Time skew detected (${DIFF}s)"
            SKEW_DETECTED=1
        else
            log_info "$node: Time sync OK (${DIFF}s)"
        fi
    else
        log_warning "$node: Unable to check time"
    fi
done

if [ $SKEW_DETECTED -eq 1 ]; then
    log_error "Time skew detected on one or more nodes"
else
    log_info "All nodes time-synchronized"
fi

#
# 5. Service CA Analysis
#
log_section "5. Service CA Status"

echo "Checking service CA..."

# Signing key age
SIGNING_KEY_AGE=$(oc get secret -n openshift-service-ca signing-key -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null || echo "Unable to determine")
log_output "Signing key created: $SIGNING_KEY_AGE"

# Check service-ca pods
log_output "\nService CA operator pods:"
oc get pods -n openshift-service-ca-operator 2>/dev/null >> "${OUTPUT_FILE}"

# Recent service-ca logs
log_output "\nRecent service-ca errors:"
ERROR_COUNT=$(oc logs -n openshift-service-ca-operator -l app=service-ca-operator --tail=200 2>/dev/null | \
  grep -ic "error" || echo "0")
log_output "Error count in last 200 lines: $ERROR_COUNT"

if [ $ERROR_COUNT -gt 10 ]; then
    log_warning "service-ca-operator has $ERROR_COUNT errors in recent logs"
fi

#
# 6. Token Controller Analysis
#
log_section "6. Token Controller Status"

echo "Checking token controller..."

# kube-controller-manager pods
log_output "\nKube-controller-manager pods:"
oc get pods -n openshift-kube-controller-manager 2>/dev/null >> "${OUTPUT_FILE}"

# Token controller logs
log_output "\nToken controller recent activity:"
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=200 2>/dev/null | \
  grep -i "token\|serviceaccount" | tail -10 >> "${OUTPUT_FILE}"

# Check for errors
TOKEN_ERRORS=$(oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=200 2>/dev/null | \
  grep -ic "error.*token" || echo "0")

log_output "Token-related errors in last 200 lines: $TOKEN_ERRORS"

if [ $TOKEN_ERRORS -gt 5 ]; then
    log_warning "Token controller has $TOKEN_ERRORS errors in recent logs"
fi

#
# 7. Sample Service Account Check
#
log_section "7. Sample Service Account Verification"

echo "Checking sample service accounts..."

# Check if default SA exists in default namespace
if oc get sa default -n default &>/dev/null; then
    log_info "Default service account exists"
    
    # Check for secrets
    SECRET_COUNT=$(oc get sa default -n default -o jsonpath='{.secrets}' | grep -o "name" | wc -l)
    log_output "Default SA has $SECRET_COUNT secret(s)"
else
    log_error "Default service account missing!"
fi

#
# 8. Summary and Recommendations
#
log_section "8. Summary and Recommendations"

log_output "\n=== DIAGNOSTIC SUMMARY ==="
log_output "Severity: $SEVERITY"
log_output "Total errors found: $ERROR_COUNT"
log_output "Recent error rate: $RECENT_ERRORS/5min"
log_output ""

log_output "=== RECOMMENDATIONS ==="
log_output ""

if [ "$SEVERITY" = "CRITICAL" ]; then
    log_output "URGENT: Critical token expiry issue detected"
    log_output ""
    log_output "Immediate actions:"
    log_output "1. Identify and restart affected pods:"
    log_output "   - Review 'Affected Service Accounts' section above"
    log_output "   - oc delete pod -n <namespace> <pod-name>"
    log_output ""
    
    if [ $SKEW_DETECTED -eq 1 ]; then
        log_output "2. Fix time synchronization on affected nodes:"
        log_output "   - oc debug node/<node> -- chroot /host chronyc makestep"
        log_output ""
    fi
    
    if [ "$SERVICE_CA_DEGRADED" = "True" ]; then
        log_output "3. Regenerate service CA:"
        log_output "   - oc delete secret -n openshift-service-ca signing-key"
        log_output ""
    fi
    
    log_output "4. Monitor error rate after fixes:"
    log_output "   - watch 'oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=20 --since=1m | grep \"token has expired\"'"
    
elif [ "$SEVERITY" = "WARNING" ]; then
    log_output "Action needed: Moderate token expiry errors"
    log_output ""
    log_output "Recommended actions:"
    log_output "1. Restart pods for most affected service accounts (see section 2)"
    log_output "2. Verify time synchronization (see section 4)"
    log_output "3. Monitor for increase in error rate"
    
else
    log_output "Status: Token errors are low or zero"
    log_output ""
    log_output "Monitoring recommended:"
    log_output "- Continue to monitor API server logs"
    log_output "- Verify all cluster operators remain healthy"
    log_output "- No immediate action required"
fi

log_output ""
log_output "For detailed troubleshooting, see:"
log_output "  SERVICE-ACCOUNT-TOKEN-EXPIRY.md"
log_output ""
log_output "=== END OF REPORT ==="

# Console summary
echo ""
echo -e "${BLUE}=== Diagnostic Complete ===${NC}"
echo ""
echo "Results saved to: ${OUTPUT_FILE}"
echo ""

if [ "$SEVERITY" = "CRITICAL" ]; then
    echo -e "${RED}✗ CRITICAL${NC}: $ERROR_COUNT token expiry errors detected"
    echo ""
    echo "Immediate action required!"
    echo "Review output file for specific recommendations."
elif [ "$SEVERITY" = "WARNING" ]; then
    echo -e "${YELLOW}⚠ WARNING${NC}: $ERROR_COUNT token expiry errors detected"
    echo ""
    echo "Action recommended."
    echo "Review output file for specific steps."
else
    echo -e "${GREEN}✓ OK${NC}: Token errors are low ($ERROR_COUNT)"
    echo ""
    echo "No immediate action required."
fi

echo ""
echo "For detailed guidance:"
echo "  cat SERVICE-ACCOUNT-TOKEN-EXPIRY.md"
echo ""

exit 0


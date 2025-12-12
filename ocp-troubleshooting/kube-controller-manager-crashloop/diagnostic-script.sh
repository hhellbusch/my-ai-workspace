#!/bin/bash

################################################################################
# OpenShift kube-controller-manager Crash Loop Diagnostic Script
################################################################################
# This script collects diagnostic information and provides recommendations
# for troubleshooting kube-controller-manager crash loop issues.
#
# Usage: ./diagnostic-script.sh
#
# Requirements:
#   - oc CLI installed and configured
#   - Cluster admin access
#   - jq installed (optional, for better JSON parsing)
################################################################################

set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create output directory
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTDIR="kcm-diagnostics-${TIMESTAMP}"
mkdir -p "${OUTDIR}"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}kube-controller-manager Diagnostics${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "Output directory: ${OUTDIR}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo "----------------------------------------"
}

# Function to print OK status
print_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print warning status
print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print error status
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_section "Checking Prerequisites"

if ! command_exists oc; then
    print_error "oc CLI not found. Please install it first."
    exit 1
fi
print_ok "oc CLI found"

if ! oc whoami &>/dev/null; then
    print_error "Not logged into OpenShift cluster"
    exit 1
fi
print_ok "Logged into cluster: $(oc whoami --show-server)"

if ! command_exists jq; then
    print_warn "jq not found. JSON parsing will be limited."
    HAS_JQ=false
else
    print_ok "jq found"
    HAS_JQ=true
fi

# 1. Check kube-controller-manager pod status
print_section "1. Checking kube-controller-manager Pod Status"

KCM_PODS=$(oc get pods -n openshift-kube-controller-manager -l app=kube-controller-manager -o json 2>&1)
if [ $? -ne 0 ]; then
    print_error "Failed to get kube-controller-manager pods"
    echo "${KCM_PODS}" > "${OUTDIR}/error-getting-pods.txt"
    exit 1
fi

echo "${KCM_PODS}" > "${OUTDIR}/kcm-pods.json"
oc get pods -n openshift-kube-controller-manager -o wide > "${OUTDIR}/kcm-pods.txt"

# Check pod status
if echo "${KCM_PODS}" | grep -q "CrashLoopBackOff"; then
    print_error "Pods in CrashLoopBackOff state"
    CRASH_LOOP=true
elif echo "${KCM_PODS}" | grep -q "Error"; then
    print_error "Pods in Error state"
    CRASH_LOOP=true
elif echo "${KCM_PODS}" | grep -q "Running"; then
    # Check restart count
    if $HAS_JQ; then
        RESTARTS=$(echo "${KCM_PODS}" | jq -r '.items[].status.containerStatuses[]?.restartCount // 0' | head -1)
        if [ "${RESTARTS}" -gt 5 ]; then
            print_warn "Pod is Running but has ${RESTARTS} restarts"
            CRASH_LOOP=true
        else
            print_ok "Pods Running with ${RESTARTS} restarts"
            CRASH_LOOP=false
        fi
    else
        print_ok "Pods appear to be Running (check restart count manually)"
        CRASH_LOOP=false
    fi
else
    print_warn "Unusual pod state detected"
    CRASH_LOOP=true
fi

# 2. Check Cluster Operator Status
print_section "2. Checking Cluster Operator Status"

CO_STATUS=$(oc get clusteroperator kube-controller-manager -o json 2>&1)
echo "${CO_STATUS}" > "${OUTDIR}/cluster-operator.json"

if $HAS_JQ; then
    AVAILABLE=$(echo "${CO_STATUS}" | jq -r '.status.conditions[] | select(.type=="Available") | .status')
    DEGRADED=$(echo "${CO_STATUS}" | jq -r '.status.conditions[] | select(.type=="Degraded") | .status')
    PROGRESSING=$(echo "${CO_STATUS}" | jq -r '.status.conditions[] | select(.type=="Progressing") | .status')
    
    if [ "${AVAILABLE}" == "True" ] && [ "${DEGRADED}" == "False" ]; then
        print_ok "Operator Available and not Degraded"
    else
        print_error "Operator status: Available=${AVAILABLE}, Degraded=${DEGRADED}, Progressing=${PROGRESSING}"
    fi
else
    oc get clusteroperator kube-controller-manager
fi

# 3. Collect Logs
print_section "3. Collecting Logs"

echo "Collecting current logs..."
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=500 > "${OUTDIR}/kcm-current.log" 2>&1
if [ $? -eq 0 ]; then
    print_ok "Current logs saved to ${OUTDIR}/kcm-current.log"
else
    print_warn "Failed to collect current logs"
fi

echo "Collecting previous logs..."
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --previous --tail=500 > "${OUTDIR}/kcm-previous.log" 2>&1
if [ $? -eq 0 ]; then
    print_ok "Previous logs saved to ${OUTDIR}/kcm-previous.log"
else
    print_warn "No previous logs available (pod may not have crashed yet)"
fi

# 4. Analyze Logs for Error Patterns
print_section "4. Analyzing Logs for Error Patterns"

LOGS_TO_ANALYZE="${OUTDIR}/kcm-previous.log"
if [ ! -s "${LOGS_TO_ANALYZE}" ]; then
    LOGS_TO_ANALYZE="${OUTDIR}/kcm-current.log"
fi

if [ ! -s "${LOGS_TO_ANALYZE}" ]; then
    print_warn "No logs available to analyze"
else
    # Check for certificate errors
    if grep -qi "x509\|certificate\|tls" "${LOGS_TO_ANALYZE}"; then
        print_error "Certificate/TLS errors detected in logs"
        echo "CERTIFICATE_ISSUE" >> "${OUTDIR}/detected-issues.txt"
        grep -i "x509\|certificate\|tls" "${LOGS_TO_ANALYZE}" | tail -5 > "${OUTDIR}/certificate-errors.txt"
    fi
    
    # Check for connection errors
    if grep -qi "connection refused\|dial tcp\|timeout" "${LOGS_TO_ANALYZE}"; then
        print_error "Connection/timeout errors detected in logs"
        echo "CONNECTIVITY_ISSUE" >> "${OUTDIR}/detected-issues.txt"
        grep -i "connection refused\|dial tcp\|timeout" "${LOGS_TO_ANALYZE}" | tail -5 > "${OUTDIR}/connectivity-errors.txt"
    fi
    
    # Check for OOM
    if grep -qi "OOM\|out of memory\|killed" "${LOGS_TO_ANALYZE}"; then
        print_error "Out of memory errors detected"
        echo "RESOURCE_ISSUE" >> "${OUTDIR}/detected-issues.txt"
        grep -i "OOM\|out of memory\|killed" "${LOGS_TO_ANALYZE}" | tail -5 > "${OUTDIR}/oom-errors.txt"
    fi
    
    # Check for configuration errors
    if grep -qi "invalid\|parse error\|failed to load" "${LOGS_TO_ANALYZE}"; then
        print_error "Configuration errors detected in logs"
        echo "CONFIGURATION_ISSUE" >> "${OUTDIR}/detected-issues.txt"
        grep -i "invalid\|parse error\|failed to load" "${LOGS_TO_ANALYZE}" | tail -5 > "${OUTDIR}/config-errors.txt"
    fi
    
    # Check for etcd errors
    if grep -qi "etcd\|context deadline exceeded" "${LOGS_TO_ANALYZE}"; then
        print_error "etcd/storage errors detected in logs"
        echo "ETCD_ISSUE" >> "${OUTDIR}/detected-issues.txt"
        grep -i "etcd\|context deadline exceeded" "${LOGS_TO_ANALYZE}" | tail -5 > "${OUTDIR}/etcd-errors.txt"
    fi
    
    # Check for webhook errors
    if grep -qi "webhook\|admission" "${LOGS_TO_ANALYZE}"; then
        print_warn "Webhook-related messages detected in logs"
        echo "WEBHOOK_ISSUE" >> "${OUTDIR}/detected-issues.txt"
        grep -i "webhook\|admission" "${LOGS_TO_ANALYZE}" | tail -5 > "${OUTDIR}/webhook-errors.txt"
    fi
fi

# 5. Check Dependencies
print_section "5. Checking Control Plane Dependencies"

echo "Checking etcd..."
oc get pods -n openshift-etcd > "${OUTDIR}/etcd-pods.txt" 2>&1
ETCD_RUNNING=$(oc get pods -n openshift-etcd -o json | grep -c '"phase":"Running"' 2>/dev/null)
ETCD_TOTAL=$(oc get pods -n openshift-etcd --no-headers 2>/dev/null | wc -l)
if [ "${ETCD_RUNNING}" -eq "${ETCD_TOTAL}" ] && [ "${ETCD_TOTAL}" -gt 0 ]; then
    print_ok "etcd pods: ${ETCD_RUNNING}/${ETCD_TOTAL} Running"
else
    print_error "etcd pods: ${ETCD_RUNNING}/${ETCD_TOTAL} Running - CHECK ETCD FIRST"
    echo "DEPENDENCY_ISSUE_ETCD" >> "${OUTDIR}/detected-issues.txt"
fi

echo "Checking API server..."
oc get pods -n openshift-kube-apiserver > "${OUTDIR}/apiserver-pods.txt" 2>&1
API_RUNNING=$(oc get pods -n openshift-kube-apiserver -o json | grep -c '"phase":"Running"' 2>/dev/null)
API_TOTAL=$(oc get pods -n openshift-kube-apiserver --no-headers 2>/dev/null | wc -l)
if [ "${API_RUNNING}" -eq "${API_TOTAL}" ] && [ "${API_TOTAL}" -gt 0 ]; then
    print_ok "API server pods: ${API_RUNNING}/${API_TOTAL} Running"
else
    print_error "API server pods: ${API_RUNNING}/${API_TOTAL} Running - CHECK API SERVER"
    echo "DEPENDENCY_ISSUE_APISERVER" >> "${OUTDIR}/detected-issues.txt"
fi

# 6. Check Certificates
print_section "6. Checking Certificates"

oc get secrets -n openshift-kube-controller-manager > "${OUTDIR}/secrets.txt" 2>&1

if oc get secret kube-controller-manager-client-cert-key -n openshift-kube-controller-manager &>/dev/null; then
    print_ok "Client certificate secret exists"
    
    # Check certificate expiry
    CERT_DATA=$(oc get secret kube-controller-manager-client-cert-key -n openshift-kube-controller-manager -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d 2>/dev/null)
    if [ -n "${CERT_DATA}" ]; then
        echo "${CERT_DATA}" | openssl x509 -text -noout > "${OUTDIR}/certificate-details.txt" 2>&1
        CERT_DATES=$(echo "${CERT_DATA}" | openssl x509 -dates -noout 2>&1)
        echo "${CERT_DATES}" > "${OUTDIR}/certificate-dates.txt"
        
        NOT_AFTER=$(echo "${CERT_DATES}" | grep "notAfter" | cut -d= -f2)
        if [ -n "${NOT_AFTER}" ]; then
            print_ok "Certificate expires: ${NOT_AFTER}"
            
            # Check if expired
            if ! openssl x509 -checkend 0 -noout <<< "${CERT_DATA}" 2>/dev/null; then
                print_error "Certificate has EXPIRED!"
                echo "CERTIFICATE_EXPIRED" >> "${OUTDIR}/detected-issues.txt"
            elif ! openssl x509 -checkend 2592000 -noout <<< "${CERT_DATA}" 2>/dev/null; then
                print_warn "Certificate expires within 30 days"
            fi
        fi
    fi
else
    print_error "Client certificate secret not found"
    echo "CERTIFICATE_MISSING" >> "${OUTDIR}/detected-issues.txt"
fi

# 7. Check Resource Usage
print_section "7. Checking Resource Usage"

echo "Node resources:"
oc adm top nodes > "${OUTDIR}/node-resources.txt" 2>&1
if [ $? -eq 0 ]; then
    cat "${OUTDIR}/node-resources.txt"
    print_ok "Node resource data collected"
else
    print_warn "Could not collect node resource data (metrics-server may not be available)"
fi

echo ""
echo "Checking for OOMKilled..."
oc describe pod -n openshift-kube-controller-manager -l app=kube-controller-manager > "${OUTDIR}/pod-describe.txt" 2>&1
if grep -q "OOMKilled" "${OUTDIR}/pod-describe.txt"; then
    print_error "Pod was OOMKilled - memory exhaustion detected"
    echo "OOM_KILLED" >> "${OUTDIR}/detected-issues.txt"
else
    print_ok "No OOMKilled status found"
fi

# 8. Check Events
print_section "8. Checking Recent Events"

oc get events -n openshift-kube-controller-manager --sort-by='.lastTimestamp' > "${OUTDIR}/events.txt" 2>&1
if [ -s "${OUTDIR}/events.txt" ]; then
    echo "Recent events (last 10):"
    tail -10 "${OUTDIR}/events.txt"
    print_ok "Events collected"
else
    print_warn "No events found or failed to collect"
fi

# 9. Collect Configuration
print_section "9. Collecting Configuration"

oc get kubecontrollermanager cluster -o yaml > "${OUTDIR}/kubecontrollermanager-config.yaml" 2>&1
if [ $? -eq 0 ]; then
    print_ok "Controller manager configuration saved"
else
    print_warn "Could not collect controller manager configuration"
fi

# 10. Generate Summary and Recommendations
print_section "10. Summary and Recommendations"

if [ -f "${OUTDIR}/detected-issues.txt" ]; then
    echo "Detected issues:" > "${OUTDIR}/RECOMMENDATIONS.txt"
    cat "${OUTDIR}/detected-issues.txt" >> "${OUTDIR}/RECOMMENDATIONS.txt"
    echo "" >> "${OUTDIR}/RECOMMENDATIONS.txt"
    echo "Recommended actions:" >> "${OUTDIR}/RECOMMENDATIONS.txt"
    echo "" >> "${OUTDIR}/RECOMMENDATIONS.txt"
    
    # Generate recommendations based on detected issues
    if grep -q "DEPENDENCY_ISSUE_ETCD" "${OUTDIR}/detected-issues.txt"; then
        echo "1. FIX ETCD FIRST - Controller manager depends on etcd" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   Command: oc get pods -n openshift-etcd" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        print_error "Action Required: Fix etcd before addressing controller manager"
    fi
    
    if grep -q "DEPENDENCY_ISSUE_APISERVER" "${OUTDIR}/detected-issues.txt"; then
        echo "2. FIX API SERVER - Controller manager depends on API server" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   Command: oc get pods -n openshift-kube-apiserver" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        print_error "Action Required: Fix API server before addressing controller manager"
    fi
    
    if grep -q "CERTIFICATE_ISSUE\|CERTIFICATE_EXPIRED\|CERTIFICATE_MISSING" "${OUTDIR}/detected-issues.txt"; then
        echo "3. REGENERATE CERTIFICATES" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   Command: oc delete secret kube-controller-manager-client-cert-key -n openshift-kube-controller-manager" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   Wait 2-5 minutes for automatic regeneration" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        print_error "Action Required: Certificate issue detected - delete secret to regenerate"
    fi
    
    if grep -q "OOM_KILLED" "${OUTDIR}/detected-issues.txt"; then
        echo "4. ADDRESS RESOURCE CONSTRAINTS" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - Check master node resources: oc adm top nodes" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - May require scaling master nodes (infrastructure change)" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        print_error "Action Required: Resource exhaustion - may need infrastructure scaling"
    fi
    
    if grep -q "CONNECTIVITY_ISSUE" "${OUTDIR}/detected-issues.txt"; then
        echo "5. CHECK NETWORK CONNECTIVITY" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - Verify API server is reachable" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - Check network policies" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - Verify endpoints: oc get endpoints kubernetes -n default" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        print_error "Action Required: Connectivity issues detected"
    fi
    
    if grep -q "CONFIGURATION_ISSUE" "${OUTDIR}/detected-issues.txt"; then
        echo "6. REVIEW CONFIGURATION" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - Check: ${OUTDIR}/kubecontrollermanager-config.yaml" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - Review recent changes" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - Revert invalid configuration if needed" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        print_error "Action Required: Configuration errors detected"
    fi
    
    if grep -q "ETCD_ISSUE" "${OUTDIR}/detected-issues.txt"; then
        echo "7. CHECK ETCD HEALTH" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - Verify etcd members: oc get etcd" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - Check etcd logs: oc logs -n openshift-etcd -l app=etcd" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "" >> "${OUTDIR}/RECOMMENDATIONS.txt"
        print_error "Action Required: etcd issues detected"
    fi
    
    cat "${OUTDIR}/RECOMMENDATIONS.txt"
else
    print_ok "No critical issues detected in automated analysis"
    echo "However, manual review of logs is recommended:" > "${OUTDIR}/RECOMMENDATIONS.txt"
    echo "- Review: ${OUTDIR}/kcm-previous.log" >> "${OUTDIR}/RECOMMENDATIONS.txt"
    echo "- Review: ${OUTDIR}/kcm-current.log" >> "${OUTDIR}/RECOMMENDATIONS.txt"
fi

# 11. Create archive
print_section "11. Creating Diagnostic Archive"

ARCHIVE="${OUTDIR}.tar.gz"
tar czf "${ARCHIVE}" "${OUTDIR}/" 2>&1
if [ $? -eq 0 ]; then
    print_ok "Diagnostic archive created: ${ARCHIVE}"
    ARCHIVE_SIZE=$(du -h "${ARCHIVE}" | cut -f1)
    echo "Archive size: ${ARCHIVE_SIZE}"
else
    print_warn "Failed to create archive"
fi

# Final summary
print_section "Diagnostic Complete"

echo ""
echo "Diagnostic data saved to: ${OUTDIR}/"
echo "Archive created: ${ARCHIVE}"
echo ""
echo "Next steps:"
echo "1. Review ${OUTDIR}/RECOMMENDATIONS.txt for specific actions"
echo "2. Check logs in ${OUTDIR}/ for detailed error messages"
echo "3. Follow troubleshooting guide for your specific issue"
echo ""

if [ -f "${OUTDIR}/detected-issues.txt" ]; then
    ISSUE_COUNT=$(wc -l < "${OUTDIR}/detected-issues.txt")
    echo -e "${RED}${ISSUE_COUNT} issue(s) detected${NC} - see RECOMMENDATIONS.txt"
else
    echo -e "${GREEN}No automated issues detected${NC} - manual review recommended"
fi

echo ""
echo "For support escalation, provide the archive: ${ARCHIVE}"
echo ""


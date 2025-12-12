#!/bin/bash

################################################################################
# BareMetalHost Inspection Diagnostic Script
################################################################################
# This script diagnoses why a BareMetalHost is stuck in inspecting state
#
# Usage: ./diagnose-bmh.sh [baremetalhost-name]
#        Default: master-2
#
# Requirements:
#   - oc CLI installed and configured
#   - Cluster admin access
#   - jq installed (optional, for better JSON parsing)
#   - curl available for BMC testing
################################################################################

set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BMH_NAME=${1:-master-2}
NAMESPACE="openshift-machine-api"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTDIR="bmh-diagnostics-${BMH_NAME}-${TIMESTAMP}"

mkdir -p "${OUTDIR}"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}BareMetalHost Diagnostic Script${NC}"
echo -e "${BLUE}================================${NC}"
echo "Target BareMetalHost: ${BMH_NAME}"
echo "Namespace: ${NAMESPACE}"
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

# Check if BareMetalHost exists
print_section "1. Checking BareMetalHost Existence"

if ! oc get baremetalhost ${BMH_NAME} -n ${NAMESPACE} &>/dev/null; then
    print_error "BareMetalHost '${BMH_NAME}' not found in namespace '${NAMESPACE}'"
    echo ""
    echo "Available BareMetalHosts:"
    oc get baremetalhost -n ${NAMESPACE}
    exit 1
fi
print_ok "BareMetalHost '${BMH_NAME}' found"

# Get BareMetalHost details
oc get baremetalhost ${BMH_NAME} -n ${NAMESPACE} -o yaml > "${OUTDIR}/bmh-full.yaml"
oc describe baremetalhost ${BMH_NAME} -n ${NAMESPACE} > "${OUTDIR}/bmh-describe.txt"

# Check current state
print_section "2. Current BareMetalHost Status"

STATE=$(oc get baremetalhost ${BMH_NAME} -n ${NAMESPACE} -o jsonpath='{.status.provisioning.state}' 2>/dev/null)
ONLINE=$(oc get baremetalhost ${BMH_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.online}' 2>/dev/null)
POWERED_ON=$(oc get baremetalhost ${BMH_NAME} -n ${NAMESPACE} -o jsonpath='{.status.poweredOn}' 2>/dev/null)

echo "State: ${STATE}"
echo "Spec.Online: ${ONLINE}"
echo "Status.PoweredOn: ${POWERED_ON}"

if [ "$STATE" = "inspecting" ]; then
    print_warn "Host is in 'inspecting' state"
elif [ "$STATE" = "available" ] || [ "$STATE" = "provisioned" ]; then
    print_ok "Host is in '${STATE}' state - not stuck in inspection"
    echo ""
    echo "This host appears to be healthy. No further diagnosis needed."
    exit 0
else
    print_warn "Host is in '${STATE}' state"
fi

# Check for error messages
ERROR_MSG=$(oc get baremetalhost ${BMH_NAME} -n ${NAMESPACE} -o jsonpath='{.status.errorMessage}' 2>/dev/null)
ERROR_TYPE=$(oc get baremetalhost ${BMH_NAME} -n ${NAMESPACE} -o jsonpath='{.status.errorType}' 2>/dev/null)

if [ -n "$ERROR_MSG" ]; then
    print_error "Error Message: ${ERROR_MSG}"
    echo "ERROR_MESSAGE=${ERROR_MSG}" >> "${OUTDIR}/detected-issues.txt"
fi

if [ -n "$ERROR_TYPE" ]; then
    print_error "Error Type: ${ERROR_TYPE}"
    echo "ERROR_TYPE=${ERROR_TYPE}" >> "${OUTDIR}/detected-issues.txt"
fi

# Check BMC configuration
print_section "3. BMC Configuration"

BMC_ADDRESS=$(oc get baremetalhost ${BMH_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.bmc.address}' 2>/dev/null)
BMC_SECRET=$(oc get baremetalhost ${BMH_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.bmc.credentialsName}' 2>/dev/null)
DISABLE_CERT_VERIFY=$(oc get baremetalhost ${BMH_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.bmc.disableCertificateVerification}' 2>/dev/null)

echo "BMC Address: ${BMC_ADDRESS}"
echo "BMC Secret: ${BMC_SECRET}"
echo "Disable Cert Verification: ${DISABLE_CERT_VERIFY}"

# Extract BMC IP
BMC_IP=$(echo ${BMC_ADDRESS} | grep -oP '\d+\.\d+\.\d+\.\d+')

if [ -z "$BMC_IP" ]; then
    print_error "Could not extract BMC IP address from: ${BMC_ADDRESS}"
    echo "BMC_IP_EXTRACTION_FAILED" >> "${OUTDIR}/detected-issues.txt"
else
    print_ok "BMC IP: ${BMC_IP}"
fi

# Check BMC secret
print_section "4. BMC Credentials"

if oc get secret ${BMC_SECRET} -n ${NAMESPACE} &>/dev/null; then
    print_ok "BMC secret '${BMC_SECRET}' exists"
    
    BMC_USER=$(oc get secret ${BMC_SECRET} -n ${NAMESPACE} -o jsonpath='{.data.username}' 2>/dev/null | base64 -d 2>/dev/null)
    BMC_PASS=$(oc get secret ${BMC_SECRET} -n ${NAMESPACE} -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null)
    
    if [ -n "$BMC_USER" ]; then
        echo "Username: ${BMC_USER}"
    else
        print_error "Could not retrieve BMC username from secret"
        echo "BMC_CREDENTIALS_MISSING" >> "${OUTDIR}/detected-issues.txt"
    fi
    
    if [ -n "$BMC_PASS" ]; then
        echo "Password: <redacted> (length: ${#BMC_PASS})"
    else
        print_error "Could not retrieve BMC password from secret"
        echo "BMC_CREDENTIALS_MISSING" >> "${OUTDIR}/detected-issues.txt"
    fi
else
    print_error "BMC secret '${BMC_SECRET}' not found"
    echo "BMC_SECRET_NOT_FOUND" >> "${OUTDIR}/detected-issues.txt"
fi

# Test BMC connectivity
if [ -n "$BMC_IP" ]; then
    print_section "5. BMC Connectivity Tests"
    
    # Ping test
    echo "Testing ping to ${BMC_IP}..."
    if ping -c 2 -W 2 ${BMC_IP} &>/dev/null; then
        print_ok "Ping successful"
    else
        print_error "Ping failed - BMC may be unreachable"
        echo "BMC_PING_FAILED" >> "${OUTDIR}/detected-issues.txt"
    fi
    
    # HTTPS test
    echo "Testing HTTPS connection to ${BMC_IP}..."
    HTTP_RESPONSE=$(curl -k -s -m 5 -w "%{http_code}" -o "${OUTDIR}/bmc-response.txt" https://${BMC_IP}/redfish/v1/Systems 2>&1)
    if [ $? -eq 0 ] && [ "$HTTP_RESPONSE" = "200" ]; then
        print_ok "HTTPS connection successful (HTTP ${HTTP_RESPONSE})"
        if [ -s "${OUTDIR}/bmc-response.txt" ]; then
            print_ok "Redfish endpoint responding"
        fi
    else
        print_error "HTTPS connection failed (HTTP ${HTTP_RESPONSE:-timeout})"
        echo "BMC_HTTPS_FAILED" >> "${OUTDIR}/detected-issues.txt"
    fi
    
    # Authentication test
    if [ -n "$BMC_USER" ] && [ -n "$BMC_PASS" ]; then
        echo "Testing authentication..."
        AUTH_RESPONSE=$(curl -k -s -m 5 -u "${BMC_USER}:${BMC_PASS}" -w "%{http_code}" -o "${OUTDIR}/bmc-auth-response.txt" https://${BMC_IP}/redfish/v1/Systems 2>&1)
        if [ $? -eq 0 ] && [ "$AUTH_RESPONSE" = "200" ]; then
            print_ok "Authentication successful"
        elif [ "$AUTH_RESPONSE" = "401" ]; then
            print_error "Authentication failed - invalid credentials"
            echo "BMC_AUTH_FAILED" >> "${OUTDIR}/detected-issues.txt"
        else
            print_warn "Authentication test inconclusive (HTTP ${AUTH_RESPONSE:-error})"
        fi
    fi
fi

# Check Ironic pods
print_section "6. Checking Ironic Infrastructure"

IRONIC_POD=$(oc get pods -n ${NAMESPACE} -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name 2>/dev/null | head -1)

if [ -z "$IRONIC_POD" ]; then
    print_error "Ironic pod not found"
    echo "IRONIC_POD_NOT_FOUND" >> "${OUTDIR}/detected-issues.txt"
else
    print_ok "Ironic pod found: ${IRONIC_POD}"
    
    # Check if pod is running
    IRONIC_STATUS=$(oc get ${IRONIC_POD} -n ${NAMESPACE} -o jsonpath='{.status.phase}' 2>/dev/null)
    if [ "$IRONIC_STATUS" = "Running" ]; then
        print_ok "Ironic pod is Running"
    else
        print_error "Ironic pod is not Running: ${IRONIC_STATUS}"
        echo "IRONIC_POD_NOT_RUNNING" >> "${OUTDIR}/detected-issues.txt"
    fi
fi

# Check Metal3 operator
echo ""
echo "Checking Metal3 operator..."
if oc get deployment metal3 -n ${NAMESPACE} &>/dev/null; then
    METAL3_READY=$(oc get deployment metal3 -n ${NAMESPACE} -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    if [ "$METAL3_READY" -gt 0 ]; then
        print_ok "Metal3 operator is ready"
    else
        print_error "Metal3 operator not ready"
        echo "METAL3_NOT_READY" >> "${OUTDIR}/detected-issues.txt"
    fi
else
    print_error "Metal3 deployment not found"
fi

# Collect logs
print_section "7. Collecting Logs"

if [ -n "$IRONIC_POD" ]; then
    echo "Collecting Ironic logs..."
    
    oc logs -n ${NAMESPACE} ${IRONIC_POD} -c ironic-inspector --tail=500 > "${OUTDIR}/ironic-inspector.log" 2>&1
    if [ $? -eq 0 ]; then
        print_ok "Ironic inspector logs collected"
    else
        print_warn "Could not collect Ironic inspector logs"
    fi
    
    oc logs -n ${NAMESPACE} ${IRONIC_POD} -c ironic-conductor --tail=500 > "${OUTDIR}/ironic-conductor.log" 2>&1
    if [ $? -eq 0 ]; then
        print_ok "Ironic conductor logs collected"
    else
        print_warn "Could not collect Ironic conductor logs"
    fi
    
    oc logs -n ${NAMESPACE} ${IRONIC_POD} -c ironic-api --tail=500 > "${OUTDIR}/ironic-api.log" 2>&1
fi

echo "Collecting Metal3 operator logs..."
oc logs -n ${NAMESPACE} deployment/metal3 --tail=500 > "${OUTDIR}/metal3-operator.log" 2>&1

echo "Collecting cluster-baremetal-operator logs..."
oc logs -n ${NAMESPACE} deployment/cluster-baremetal-operator --tail=500 > "${OUTDIR}/cluster-baremetal-operator.log" 2>&1

# Analyze logs for patterns
print_section "8. Analyzing Logs for Error Patterns"

LOGS_FOUND=false

if [ -f "${OUTDIR}/ironic-inspector.log" ]; then
    LOGS_FOUND=true
    
    if grep -qi "unable to connect\|connection refused\|connection timeout" "${OUTDIR}/ironic-inspector.log"; then
        print_error "BMC connection errors detected in inspector logs"
        grep -i "unable to connect\|connection refused\|connection timeout" "${OUTDIR}/ironic-inspector.log" | tail -3 > "${OUTDIR}/connection-errors.txt"
        echo "BMC_CONNECTION_ERROR" >> "${OUTDIR}/detected-issues.txt"
    fi
    
    if grep -qi "authentication\|unauthorized\|401\|403" "${OUTDIR}/ironic-inspector.log"; then
        print_error "Authentication errors detected in inspector logs"
        grep -i "authentication\|unauthorized\|401\|403" "${OUTDIR}/ironic-inspector.log" | tail -3 > "${OUTDIR}/auth-errors.txt"
        echo "BMC_AUTH_ERROR" >> "${OUTDIR}/detected-issues.txt"
    fi
    
    if grep -qi "timeout.*inspection\|inspection.*timeout" "${OUTDIR}/ironic-inspector.log"; then
        print_error "Inspection timeout detected"
        grep -i "timeout.*inspection\|inspection.*timeout" "${OUTDIR}/ironic-inspector.log" | tail -3 > "${OUTDIR}/timeout-errors.txt"
        echo "INSPECTION_TIMEOUT" >> "${OUTDIR}/detected-issues.txt"
    fi
    
    if grep -qi "certificate\|ssl\|tls" "${OUTDIR}/ironic-inspector.log"; then
        print_warn "Certificate/SSL/TLS messages detected"
        grep -i "certificate\|ssl\|tls" "${OUTDIR}/ironic-inspector.log" | tail -3 > "${OUTDIR}/cert-issues.txt"
        echo "CERTIFICATE_ISSUE" >> "${OUTDIR}/detected-issues.txt"
    fi
fi

if [ "$LOGS_FOUND" = false ]; then
    print_warn "No logs available for analysis"
fi

# Check recent events
print_section "9. Recent Events"

oc get events -n ${NAMESPACE} --field-selector involvedObject.name=${BMH_NAME} --sort-by='.lastTimestamp' > "${OUTDIR}/events.txt" 2>&1

if [ -s "${OUTDIR}/events.txt" ]; then
    echo "Recent events (last 10):"
    tail -10 "${OUTDIR}/events.txt"
    print_ok "Events collected"
else
    print_warn "No events found"
fi

# Check provisioning configuration
print_section "10. Provisioning Configuration"

oc get provisioning provisioning-configuration -o yaml > "${OUTDIR}/provisioning-config.yaml" 2>&1
if [ $? -eq 0 ]; then
    print_ok "Provisioning configuration collected"
    
    INSPECT_TIMEOUT=$(grep -i "inspectTimeout" "${OUTDIR}/provisioning-config.yaml" | awk '{print $2}')
    if [ -n "$INSPECT_TIMEOUT" ]; then
        echo "Inspection timeout: ${INSPECT_TIMEOUT} seconds"
        if [ "$INSPECT_TIMEOUT" -lt 1800 ]; then
            print_warn "Inspection timeout is quite short (< 30 minutes)"
            echo "SHORT_TIMEOUT" >> "${OUTDIR}/detected-issues.txt"
        fi
    fi
else
    print_warn "Could not retrieve provisioning configuration"
fi

# Compare with working node if exists
print_section "11. Comparison with Other Nodes"

WORKING_NODE=$(oc get baremetalhost -n ${NAMESPACE} -o jsonpath='{.items[?(@.status.provisioning.state=="provisioned")].metadata.name}' 2>/dev/null | awk '{print $1}')

if [ -n "$WORKING_NODE" ]; then
    echo "Found working node: ${WORKING_NODE}"
    echo "Comparing configurations..."
    
    diff -u \
        <(oc get baremetalhost ${WORKING_NODE} -n ${NAMESPACE} -o yaml | grep -A 40 "^spec:" | head -40) \
        <(oc get baremetalhost ${BMH_NAME} -n ${NAMESPACE} -o yaml | grep -A 40 "^spec:" | head -40) \
        > "${OUTDIR}/spec-diff.txt" 2>&1
    
    if [ -s "${OUTDIR}/spec-diff.txt" ]; then
        echo "Differences found (see ${OUTDIR}/spec-diff.txt):"
        cat "${OUTDIR}/spec-diff.txt"
    else
        print_ok "No significant differences in spec"
    fi
else
    print_warn "No provisioned nodes found for comparison"
fi

# Generate recommendations
print_section "12. Recommendations"

if [ -f "${OUTDIR}/detected-issues.txt" ]; then
    echo "Detected issues:" | tee "${OUTDIR}/RECOMMENDATIONS.txt"
    cat "${OUTDIR}/detected-issues.txt" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
    echo "" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
    echo "Recommended actions:" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
    echo "" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
    
    if grep -q "BMC_PING_FAILED\|BMC_HTTPS_FAILED\|BMC_CONNECTION_ERROR" "${OUTDIR}/detected-issues.txt"; then
        echo "1. FIX BMC CONNECTIVITY" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - Verify BMC IP address is correct: ${BMC_IP}" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - Check network connectivity to BMC" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   - Verify BMC is powered on and accessible" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        print_error "Action Required: Fix BMC connectivity"
    fi
    
    if grep -q "BMC_AUTH_FAILED\|BMC_AUTH_ERROR\|BMC_CREDENTIALS_MISSING" "${OUTDIR}/detected-issues.txt"; then
        echo "2. FIX BMC CREDENTIALS" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   Command:" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   oc delete secret ${BMC_SECRET} -n ${NAMESPACE}" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   oc create secret generic ${BMC_SECRET} -n ${NAMESPACE} \\" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "     --from-literal=username=CORRECT_USER \\" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "     --from-literal=password=CORRECT_PASS" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        print_error "Action Required: Fix BMC credentials"
    fi
    
    if grep -q "CERTIFICATE_ISSUE" "${OUTDIR}/detected-issues.txt"; then
        echo "3. DISABLE CERTIFICATE VERIFICATION" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   Command:" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   oc patch baremetalhost ${BMH_NAME} -n ${NAMESPACE} --type merge -p \\" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "     '{\"spec\":{\"bmc\":{\"disableCertificateVerification\":true}}}'" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        print_error "Action Required: Consider disabling certificate verification"
    fi
    
    if grep -q "INSPECTION_TIMEOUT\|SHORT_TIMEOUT" "${OUTDIR}/detected-issues.txt"; then
        echo "4. INCREASE INSPECTION TIMEOUT" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   Command:" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   oc patch provisioning provisioning-configuration --type merge -p \\" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "     '{\"spec\":{\"inspectTimeout\":\"3600\"}}'" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        print_error "Action Required: Consider increasing timeout"
    fi
    
    if grep -q "ERROR_MESSAGE\|ERROR_TYPE" "${OUTDIR}/detected-issues.txt"; then
        echo "5. CLEAR ERROR STATE AND RETRY" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   Commands:" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   oc annotate baremetalhost ${BMH_NAME} -n ${NAMESPACE} baremetalhost.metal3.io/status-" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   oc patch baremetalhost ${BMH_NAME} -n ${NAMESPACE} --type merge -p '{\"spec\":{\"online\":false}}'" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   sleep 10" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "   oc patch baremetalhost ${BMH_NAME} -n ${NAMESPACE} --type merge -p '{\"spec\":{\"online\":true}}'" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        echo "" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
        print_error "Action Required: Clear error state"
    fi
    
else
    print_ok "No critical issues detected in automated analysis"
    echo "Manual review recommended:" | tee "${OUTDIR}/RECOMMENDATIONS.txt"
    echo "- Check logs in ${OUTDIR}/" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
    echo "- Verify BMC is accessible" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
    echo "- Check for hardware-specific issues" | tee -a "${OUTDIR}/RECOMMENDATIONS.txt"
fi

# Create archive
print_section "13. Creating Archive"

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
echo "3. Test BMC connectivity manually if needed"
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


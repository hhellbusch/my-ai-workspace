#!/bin/bash

################################################################################
# Diagnostic Script: Worker Node TLS Certificate Failure
# Purpose: Diagnose TLS certificate verification failures when adding workers
#          to OpenShift bare metal clusters via BareMetalHost
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Output directory
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="tls-diagnostics-${TIMESTAMP}"

# Functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
  echo -e "${RED}[✗]${NC} $1"
}

create_output_dir() {
  mkdir -p "$OUTPUT_DIR"
  log_info "Created output directory: $OUTPUT_DIR"
}

check_prerequisites() {
  log_info "Checking prerequisites..."
  
  if ! command -v oc &> /dev/null; then
    log_error "oc command not found. Please install OpenShift CLI."
    exit 1
  fi
  
  if ! oc whoami &> /dev/null; then
    log_error "Not logged into OpenShift cluster. Run 'oc login' first."
    exit 1
  fi
  
  log_success "Prerequisites met"
}

get_api_vip() {
  log_info "Getting API VIP..."
  API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' 2>/dev/null | cut -d: -f2 | tr -d '/' || echo "")
  
  if [ -z "$API_VIP" ]; then
    log_error "Could not determine API VIP"
    exit 1
  fi
  
  log_success "API VIP: $API_VIP"
  echo "$API_VIP" > "$OUTPUT_DIR/api-vip.txt"
}

check_mcs_pods() {
  log_info "Checking Machine Config Server pods..."
  
  oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server -o wide > "$OUTPUT_DIR/mcs-pods.txt" 2>&1 || true
  
  MCS_RUNNING=$(oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server --no-headers 2>/dev/null | grep -c "Running" || echo "0")
  
  if [ "$MCS_RUNNING" -gt 0 ]; then
    log_success "Machine Config Server pods running: $MCS_RUNNING"
  else
    log_error "No Machine Config Server pods running!"
    echo "CRITICAL: No MCS pods running" >> "$OUTPUT_DIR/ISSUES.txt"
  fi
  
  # Get MCS logs
  log_info "Collecting MCS logs..."
  oc logs -n openshift-machine-config-operator -l k8s-app=machine-config-server --all-containers --tail=200 > "$OUTPUT_DIR/mcs-logs.txt" 2>&1 || true
  
  # Check for errors in logs
  if grep -qi "certificate\|tls\|x509" "$OUTPUT_DIR/mcs-logs.txt"; then
    log_warning "Found certificate-related errors in MCS logs"
    grep -i "certificate\|tls\|x509\|error\|fail" "$OUTPUT_DIR/mcs-logs.txt" > "$OUTPUT_DIR/mcs-cert-errors.txt" 2>&1 || true
  fi
}

check_certificate() {
  log_info "Checking Machine Config Server certificate..."
  
  # Get certificate details
  echo | openssl s_client -connect "${API_VIP}:22623" -servername api.cluster.local 2>/dev/null | openssl x509 -noout -text > "$OUTPUT_DIR/mcs-certificate-full.txt" 2>&1 || {
    log_error "Could not connect to ${API_VIP}:22623"
    echo "CRITICAL: Cannot connect to MCS endpoint" >> "$OUTPUT_DIR/ISSUES.txt"
    return 1
  }
  
  # Check expiration
  echo | openssl s_client -connect "${API_VIP}:22623" 2>/dev/null | openssl x509 -noout -dates > "$OUTPUT_DIR/mcs-certificate-dates.txt" 2>&1 || true
  
  EXPIRY=$(echo | openssl s_client -connect "${API_VIP}:22623" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || echo "")
  
  if [ -n "$EXPIRY" ]; then
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null || echo "0")
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
    
    echo "Certificate expires: $EXPIRY" > "$OUTPUT_DIR/certificate-expiry.txt"
    echo "Days remaining: $DAYS_LEFT" >> "$OUTPUT_DIR/certificate-expiry.txt"
    
    if [ $DAYS_LEFT -lt 0 ]; then
      log_error "Certificate EXPIRED $((DAYS_LEFT * -1)) days ago!"
      echo "CRITICAL: Certificate expired" >> "$OUTPUT_DIR/ISSUES.txt"
    elif [ $DAYS_LEFT -lt 7 ]; then
      log_warning "Certificate expires in $DAYS_LEFT days"
      echo "WARNING: Certificate expires soon ($DAYS_LEFT days)" >> "$OUTPUT_DIR/ISSUES.txt"
    else
      log_success "Certificate valid for $DAYS_LEFT days"
    fi
  fi
  
  # Check if certificate validates
  if echo | openssl s_client -connect "${API_VIP}:22623" 2>&1 | grep -q "Verify return code: 0"; then
    log_success "Certificate validates successfully"
  else
    log_warning "Certificate validation failed"
    echo "WARNING: Certificate validation failed" >> "$OUTPUT_DIR/ISSUES.txt"
  fi
}

test_mcs_endpoint() {
  log_info "Testing MCS endpoint connectivity..."
  
  # Test with curl
  HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" "https://${API_VIP}:22623/healthz" 2>/dev/null || echo "000")
  echo "HTTP Status Code: $HTTP_CODE" > "$OUTPUT_DIR/mcs-endpoint-test.txt"
  
  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    log_success "MCS endpoint reachable (HTTP $HTTP_CODE)"
  else
    log_error "MCS endpoint unreachable or error (HTTP $HTTP_CODE)"
    echo "CRITICAL: MCS endpoint unreachable" >> "$OUTPUT_DIR/ISSUES.txt"
  fi
  
  # Detailed curl test with certificate info
  curl -kv "https://${API_VIP}:22623/healthz" > "$OUTPUT_DIR/mcs-curl-verbose.txt" 2>&1 || true
  
  # Test from a node (if possible)
  log_info "Testing MCS endpoint from cluster node..."
  MASTER_NODE=$(oc get nodes -l node-role.kubernetes.io/master -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
  if [ -n "$MASTER_NODE" ]; then
    oc debug node/"$MASTER_NODE" -- chroot /host curl -kv "https://${API_VIP}:22623/healthz" > "$OUTPUT_DIR/mcs-endpoint-from-node.txt" 2>&1 || true
  fi
}

check_baremetalhosts() {
  log_info "Checking BareMetalHost resources..."
  
  oc get baremetalhost -n openshift-machine-api > "$OUTPUT_DIR/baremetalhosts.txt" 2>&1 || true
  oc get baremetalhost -n openshift-machine-api -o yaml > "$OUTPUT_DIR/baremetalhosts-yaml.txt" 2>&1 || true
  
  # Check for worker BareMetalHosts
  WORKER_BMH_COUNT=$(oc get baremetalhost -n openshift-machine-api --no-headers 2>/dev/null | grep -c "worker" || echo "0")
  log_info "Found $WORKER_BMH_COUNT worker BareMetalHost(s)"
  
  # Check for any in error state
  if oc get baremetalhost -n openshift-machine-api -o jsonpath='{.items[*].status.errorMessage}' 2>/dev/null | grep -q "."; then
    log_warning "Some BareMetalHosts have error messages"
    oc get baremetalhost -n openshift-machine-api -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.errorMessage}{"\n"}{end}' > "$OUTPUT_DIR/bmh-errors.txt" 2>&1 || true
  fi
}

check_machineconfigs() {
  log_info "Checking MachineConfigs..."
  
  oc get machineconfig > "$OUTPUT_DIR/machineconfigs.txt" 2>&1 || true
  oc get machineconfig | grep worker > "$OUTPUT_DIR/worker-machineconfigs.txt" 2>&1 || true
  
  # Get worker MachineConfigPool status
  oc get machineconfigpool worker -o yaml > "$OUTPUT_DIR/worker-mcp.txt" 2>&1 || true
  
  MCP_UPDATED=$(oc get machineconfigpool worker -o jsonpath='{.status.conditions[?(@.type=="Updated")].status}' 2>/dev/null || echo "Unknown")
  MCP_UPDATING=$(oc get machineconfigpool worker -o jsonpath='{.status.conditions[?(@.type=="Updating")].status}' 2>/dev/null || echo "Unknown")
  MCP_DEGRADED=$(oc get machineconfigpool worker -o jsonpath='{.status.conditions[?(@.type=="Degraded")].status}' 2>/dev/null || echo "Unknown")
  
  echo "Worker MachineConfigPool Status:" > "$OUTPUT_DIR/worker-mcp-status.txt"
  echo "  Updated: $MCP_UPDATED" >> "$OUTPUT_DIR/worker-mcp-status.txt"
  echo "  Updating: $MCP_UPDATING" >> "$OUTPUT_DIR/worker-mcp-status.txt"
  echo "  Degraded: $MCP_DEGRADED" >> "$OUTPUT_DIR/worker-mcp-status.txt"
  
  if [ "$MCP_DEGRADED" = "True" ]; then
    log_error "Worker MachineConfigPool is DEGRADED"
    echo "CRITICAL: Worker MachineConfigPool degraded" >> "$OUTPUT_DIR/ISSUES.txt"
  fi
}

check_cluster_operators() {
  log_info "Checking relevant cluster operators..."
  
  oc get clusteroperators machine-config > "$OUTPUT_DIR/mco-operator.txt" 2>&1 || true
  oc get clusteroperators machine-config -o yaml > "$OUTPUT_DIR/mco-operator-yaml.txt" 2>&1 || true
  
  MCO_AVAILABLE=$(oc get clusteroperator machine-config -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "Unknown")
  MCO_PROGRESSING=$(oc get clusteroperator machine-config -o jsonpath='{.status.conditions[?(@.type=="Progressing")].status}' 2>/dev/null || echo "Unknown")
  MCO_DEGRADED=$(oc get clusteroperator machine-config -o jsonpath='{.status.conditions[?(@.type=="Degraded")].status}' 2>/dev/null || echo "Unknown")
  
  echo "Machine Config Operator Status:" > "$OUTPUT_DIR/mco-status.txt"
  echo "  Available: $MCO_AVAILABLE" >> "$OUTPUT_DIR/mco-status.txt"
  echo "  Progressing: $MCO_PROGRESSING" >> "$OUTPUT_DIR/mco-status.txt"
  echo "  Degraded: $MCO_DEGRADED" >> "$OUTPUT_DIR/mco-status.txt"
  
  if [ "$MCO_DEGRADED" = "True" ]; then
    log_error "Machine Config Operator is DEGRADED"
    echo "CRITICAL: Machine Config Operator degraded" >> "$OUTPUT_DIR/ISSUES.txt"
  fi
}

check_haproxy() {
  log_info "Checking HAProxy status on control plane nodes..."
  
  for node in $(oc get nodes -l node-role.kubernetes.io/master -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    log_info "  Checking HAProxy on $node..."
    echo "=== HAProxy status on $node ===" >> "$OUTPUT_DIR/haproxy-status.txt"
    oc debug node/"$node" -- chroot /host systemctl status haproxy >> "$OUTPUT_DIR/haproxy-status.txt" 2>&1 || true
    echo "" >> "$OUTPUT_DIR/haproxy-status.txt"
  done
}

check_metal3_logs() {
  log_info "Checking Metal3 operator logs..."
  
  oc logs -n openshift-machine-api deployment/metal3 --tail=200 > "$OUTPUT_DIR/metal3-logs.txt" 2>&1 || true
  
  # Check for TLS/certificate errors
  if grep -qi "tls\|certificate\|x509" "$OUTPUT_DIR/metal3-logs.txt" 2>/dev/null; then
    log_warning "Found TLS/certificate mentions in Metal3 logs"
    grep -i "tls\|certificate\|x509\|error" "$OUTPUT_DIR/metal3-logs.txt" > "$OUTPUT_DIR/metal3-cert-errors.txt" 2>&1 || true
  fi
}

generate_recommendations() {
  log_info "Generating recommendations..."
  
  RECOMMENDATIONS_FILE="$OUTPUT_DIR/RECOMMENDATIONS.txt"
  
  cat > "$RECOMMENDATIONS_FILE" <<EOF
================================================================================
DIAGNOSTIC RECOMMENDATIONS
Generated: $(date)
================================================================================

EOF
  
  if [ -f "$OUTPUT_DIR/ISSUES.txt" ]; then
    echo "ISSUES FOUND:" >> "$RECOMMENDATIONS_FILE"
    cat "$OUTPUT_DIR/ISSUES.txt" >> "$RECOMMENDATIONS_FILE"
    echo "" >> "$RECOMMENDATIONS_FILE"
  else
    echo "No critical issues detected." >> "$RECOMMENDATIONS_FILE"
    echo "" >> "$RECOMMENDATIONS_FILE"
  fi
  
  # Check for expired certificate
  if grep -q "CRITICAL: Certificate expired" "$OUTPUT_DIR/ISSUES.txt" 2>/dev/null; then
    cat >> "$RECOMMENDATIONS_FILE" <<EOF
🔧 RECOMMENDED ACTION #1: Regenerate Machine Config Server Certificate
------------------------------------------------------------------------
Your MCS certificate has expired. Run these commands:

  oc delete secret machine-config-server-tls -n openshift-machine-config-operator
  oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server
  
Wait 30 seconds, then verify:

  API_VIP=\$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
  echo | openssl s_client -connect \${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

Then retry worker provisioning.

EOF
  fi
  
  # Check for MCS pods not running
  if grep -q "CRITICAL: No MCS pods running" "$OUTPUT_DIR/ISSUES.txt" 2>/dev/null; then
    cat >> "$RECOMMENDATIONS_FILE" <<EOF
🔧 RECOMMENDED ACTION #2: Restart Machine Config Server
--------------------------------------------------------
No MCS pods are running. Check why:

  oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server
  oc describe pods -n openshift-machine-config-operator -l k8s-app=machine-config-server
  
Check Machine Config Operator:

  oc get clusteroperator machine-config
  oc describe clusteroperator machine-config

EOF
  fi
  
  # Check for connectivity issues
  if grep -q "CRITICAL: MCS endpoint unreachable" "$OUTPUT_DIR/ISSUES.txt" 2>/dev/null; then
    cat >> "$RECOMMENDATIONS_FILE" <<EOF
🔧 RECOMMENDED ACTION #3: Fix Network Connectivity
---------------------------------------------------
Cannot reach MCS endpoint. Check:

1. HAProxy status on control plane nodes:
   for node in \$(oc get nodes -l node-role.kubernetes.io/master -o name); do
     oc debug \$node -- chroot /host systemctl status haproxy
   done

2. Verify API VIP is correct:
   oc get infrastructure cluster -o yaml | grep apiVIP

3. Test from a node:
   oc debug node/master-0 -- chroot /host curl -kv https://${API_VIP}:22623/healthz

EOF
  fi
  
  # General recommendations
  cat >> "$RECOMMENDATIONS_FILE" <<EOF
📋 NEXT STEPS
-------------
1. Review all files in: $OUTPUT_DIR
2. Apply recommended actions above (if any)
3. If certificate was expired, wait for new cert before retrying workers
4. Monitor worker BareMetalHost provisioning:
   watch oc get baremetalhost -n openshift-machine-api

📚 ADDITIONAL RESOURCES
-----------------------
- Full troubleshooting guide: README.md
- Quick fixes: QUICK-REFERENCE.md
- Related issue: ../bare-metal-node-inspection-timeout/

EOF
  
  cat "$RECOMMENDATIONS_FILE"
}

main() {
  echo ""
  log_info "=========================================="
  log_info "Worker Node TLS Certificate Diagnostics"
  log_info "=========================================="
  echo ""
  
  create_output_dir
  check_prerequisites
  get_api_vip
  check_mcs_pods
  check_certificate
  test_mcs_endpoint
  check_baremetalhosts
  check_machineconfigs
  check_cluster_operators
  check_haproxy
  check_metal3_logs
  
  echo ""
  log_info "=========================================="
  log_info "Diagnostic collection complete"
  log_info "=========================================="
  echo ""
  
  generate_recommendations
  
  echo ""
  log_success "All diagnostic data saved to: $OUTPUT_DIR"
  echo ""
  log_info "Review RECOMMENDATIONS.txt for next steps"
  echo ""
}

# Run main function
main


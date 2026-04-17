#!/bin/bash
# set-ocm-subscription.sh
#
# Automates setting OCM subscription properties for a registered OpenShift cluster.
# Replaces the manual steps performed at:
#   https://console.redhat.com/openshift/cluster-list
#
# Manual steps automated by this script:
#   1. Select "Premium"
#   2. Select "Red Hat Support (L1-L3)"
#   3. Select "Production" or "Development/Test"
#   4. Select "Cores or vCPUs"
#   5. Click Save
#
# Prerequisites:
#   - ocm CLI installed: https://github.com/openshift-online/ocm-cli/releases
#   - Red Hat offline token from: https://console.redhat.com/openshift/token
#   - CLUSTER_NAME or CLUSTER_ID of the target cluster
#
# Usage:
#   ./set-ocm-subscription.sh --cluster-name my-cluster --token-file ~/rh-offline-token.txt
#   ./set-ocm-subscription.sh --cluster-name my-cluster --support-level Standard --usage "Development/Test"
#   ./set-ocm-subscription.sh --cluster-id abc-123-def --token "$(cat token.txt)"
#
# AI Disclosure: This script was created with AI assistance.

set -euo pipefail

# --------------------------------------------------------------------------
# Defaults
# --------------------------------------------------------------------------
CLUSTER_NAME=""
CLUSTER_ID=""
SUPPORT_LEVEL="Premium"
SERVICE_LEVEL="L1-L3"
USAGE="Production"
SYSTEM_UNITS="Cores/vCPU"
RH_TOKEN=""
TOKEN_FILE=""
DRY_RUN=false
VERBOSE=false
OCM_API="https://api.openshift.com"

# --------------------------------------------------------------------------
# Colors
# --------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
verbose() { [[ "$VERBOSE" == "true" ]] && echo -e "${BLUE}[DEBUG]${NC} $*" || true; }

# --------------------------------------------------------------------------
# Usage / help
# --------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Sets OCM subscription properties for a registered OpenShift cluster.

Required (one of):
  --cluster-name NAME       Cluster name as registered in OCM
  --cluster-id ID           OCM internal cluster ID (skips name lookup)

Authentication (one of):
  --token TOKEN             Red Hat offline token (from console.redhat.com/openshift/token)
  --token-file FILE         Path to file containing offline token

Subscription Settings:
  --support-level LEVEL     Support level (default: Premium)
                            Values: Premium, Standard, Self-Support, None
  --service-level SLA       SLA level (default: L1-L3)
                            Values: L1-L3, L3
  --usage USAGE             Cluster usage (default: Production)
                            Values: Production, Development/Test
  --system-units UNITS      Billing unit (default: Cores/vCPU)
                            Values: Cores/vCPU, Sockets

Options:
  --dry-run                 Show what would be changed without applying
  --verbose                 Enable debug output
  --help                    Show this help

Examples:
  # Set Premium Production (standard enterprise settings)
  $(basename "$0") --cluster-name prod-bm-01 --token-file ~/rh-token.txt

  # Set Development/Test with Standard support
  $(basename "$0") --cluster-name dev-bm-01 --token-file ~/rh-token.txt \\
    --support-level Standard --service-level L3 --usage "Development/Test"

  # Dry run to preview changes
  $(basename "$0") --cluster-name prod-bm-01 --token-file ~/rh-token.txt --dry-run

EOF
  exit 0
}

# --------------------------------------------------------------------------
# Argument parsing
# --------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cluster-name)   CLUSTER_NAME="$2"; shift 2 ;;
    --cluster-id)     CLUSTER_ID="$2";   shift 2 ;;
    --token)          RH_TOKEN="$2";     shift 2 ;;
    --token-file)     TOKEN_FILE="$2";   shift 2 ;;
    --support-level)  SUPPORT_LEVEL="$2"; shift 2 ;;
    --service-level)  SERVICE_LEVEL="$2"; shift 2 ;;
    --usage)          USAGE="$2";         shift 2 ;;
    --system-units)   SYSTEM_UNITS="$2";  shift 2 ;;
    --dry-run)        DRY_RUN=true;       shift ;;
    --verbose)        VERBOSE=true;       shift ;;
    --help|-h)        usage ;;
    *) error "Unknown argument: $1"; usage ;;
  esac
done

# --------------------------------------------------------------------------
# Validation
# --------------------------------------------------------------------------
if [[ -z "$CLUSTER_NAME" && -z "$CLUSTER_ID" ]]; then
  error "Either --cluster-name or --cluster-id is required"
  exit 1
fi

if [[ -n "$TOKEN_FILE" ]]; then
  if [[ ! -f "$TOKEN_FILE" ]]; then
    error "Token file not found: $TOKEN_FILE"
    exit 1
  fi
  RH_TOKEN="$(cat "$TOKEN_FILE")"
fi

if [[ -z "$RH_TOKEN" ]]; then
  error "Either --token or --token-file is required"
  error "Get your offline token at: https://console.redhat.com/openshift/token"
  exit 1
fi

if ! command -v ocm &>/dev/null; then
  error "ocm CLI not found. Install from: https://github.com/openshift-online/ocm-cli/releases"
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  error "python3 not found (required for JSON parsing)"
  exit 1
fi

# Validate enum values
valid_support_levels=("Premium" "Standard" "Self-Support" "None")
valid_service_levels=("L1-L3" "L3")
valid_usages=("Production" "Development/Test")
valid_units=("Cores/vCPU" "Sockets")

check_enum() {
  local value="$1" field="$2"; shift 2
  local valid=("$@")
  for v in "${valid[@]}"; do
    [[ "$value" == "$v" ]] && return 0
  done
  error "Invalid $field: '$value'. Valid values: ${valid[*]}"
  exit 1
}

check_enum "$SUPPORT_LEVEL" "--support-level" "${valid_support_levels[@]}"
check_enum "$SERVICE_LEVEL" "--service-level" "${valid_service_levels[@]}"
check_enum "$USAGE"         "--usage"         "${valid_usages[@]}"
check_enum "$SYSTEM_UNITS"  "--system-units"  "${valid_units[@]}"

# --------------------------------------------------------------------------
# OCM Login
# --------------------------------------------------------------------------
log "Authenticating with Red Hat OCM..."
ocm login --token="$RH_TOKEN" --url="$OCM_API" 2>/dev/null
log "Authenticated successfully"

# --------------------------------------------------------------------------
# Cluster Lookup
# --------------------------------------------------------------------------
if [[ -z "$CLUSTER_ID" ]]; then
  log "Looking up cluster: $CLUSTER_NAME"
  CLUSTER_JSON=$(ocm get /api/clusters_mgmt/v1/clusters \
    --parameter "search=name='${CLUSTER_NAME}'" 2>/dev/null)

  TOTAL=$(echo "$CLUSTER_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total', 0))")

  if [[ "$TOTAL" == "0" ]]; then
    error "Cluster not found in OCM: $CLUSTER_NAME"
    error "Verify the cluster is registered at: https://console.redhat.com/openshift/cluster-list"
    exit 1
  fi

  if [[ "$TOTAL" -gt 1 ]]; then
    warn "Multiple clusters found matching '$CLUSTER_NAME'. Using the first result."
    warn "Use --cluster-id to target a specific cluster."
  fi

  CLUSTER_ID=$(echo "$CLUSTER_JSON" | python3 -c \
    "import sys,json; d=json.load(sys.stdin); print(d['items'][0]['id'])")

  verbose "Resolved cluster ID: $CLUSTER_ID"
fi

log "Target cluster ID: $CLUSTER_ID"

# --------------------------------------------------------------------------
# Subscription Lookup
# --------------------------------------------------------------------------
log "Looking up subscription for cluster..."
SUB_JSON=$(ocm get /api/accounts_mgmt/v1/subscriptions \
  --parameter "search=cluster_id='${CLUSTER_ID}'" 2>/dev/null)

SUB_TOTAL=$(echo "$SUB_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total', 0))")

if [[ "$SUB_TOTAL" == "0" ]]; then
  error "No subscription found for cluster ID: $CLUSTER_ID"
  error "The cluster may not be registered with your Red Hat account."
  error "Check pull secret and insights-operator status on the cluster."
  exit 1
fi

SUB_ID=$(echo "$SUB_JSON" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d['items'][0]['id'])")

CURRENT_SUPPORT=$(echo "$SUB_JSON" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d['items'][0].get('support_level', 'not set'))" 2>/dev/null || echo "not set")
CURRENT_SERVICE=$(echo "$SUB_JSON" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d['items'][0].get('service_level', 'not set'))" 2>/dev/null || echo "not set")
CURRENT_USAGE=$(echo "$SUB_JSON" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d['items'][0].get('usage', 'not set'))" 2>/dev/null || echo "not set")
CURRENT_UNITS=$(echo "$SUB_JSON" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d['items'][0].get('system_units', 'not set'))" 2>/dev/null || echo "not set")

verbose "Subscription ID: $SUB_ID"

# --------------------------------------------------------------------------
# Show current vs desired
# --------------------------------------------------------------------------
echo ""
echo "  Subscription: $SUB_ID"
echo "  ┌──────────────────┬──────────────────────┬──────────────────────┐"
echo "  │ Field            │ Current              │ Desired              │"
echo "  ├──────────────────┼──────────────────────┼──────────────────────┤"
printf "  │ %-16s │ %-20s │ %-20s │\n" "support_level" "$CURRENT_SUPPORT" "$SUPPORT_LEVEL"
printf "  │ %-16s │ %-20s │ %-20s │\n" "service_level" "$CURRENT_SERVICE" "$SERVICE_LEVEL"
printf "  │ %-16s │ %-20s │ %-20s │\n" "usage"         "$CURRENT_USAGE"   "$USAGE"
printf "  │ %-16s │ %-20s │ %-20s │\n" "system_units"  "$CURRENT_UNITS"   "$SYSTEM_UNITS"
echo "  └──────────────────┴──────────────────────┴──────────────────────┘"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  warn "DRY RUN: No changes applied."
  exit 0
fi

# --------------------------------------------------------------------------
# Apply subscription patch
# --------------------------------------------------------------------------
log "Applying subscription settings..."

PATCH_BODY=$(python3 -c "
import json
print(json.dumps({
    'support_level': '${SUPPORT_LEVEL}',
    'service_level': '${SERVICE_LEVEL}',
    'usage':         '${USAGE}',
    'system_units':  '${SYSTEM_UNITS}'
}))
")

verbose "PATCH body: $PATCH_BODY"

ocm patch "/api/accounts_mgmt/v1/subscriptions/${SUB_ID}" \
  --body="$PATCH_BODY" 2>/dev/null

log "Subscription updated successfully"

# --------------------------------------------------------------------------
# Verify
# --------------------------------------------------------------------------
log "Verifying applied settings..."
VERIFY_JSON=$(ocm get "/api/accounts_mgmt/v1/subscriptions/${SUB_ID}" 2>/dev/null)

APPLIED_SUPPORT=$(echo "$VERIFY_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin).get('support_level', 'unknown'))")
APPLIED_SERVICE=$(echo "$VERIFY_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin).get('service_level', 'unknown'))")
APPLIED_USAGE=$(echo "$VERIFY_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin).get('usage', 'unknown'))")
APPLIED_UNITS=$(echo "$VERIFY_JSON" | python3 -c \
  "import sys,json; print(json.load(sys.stdin).get('system_units', 'unknown'))")

FAILED=false
[[ "$APPLIED_SUPPORT" != "$SUPPORT_LEVEL" ]] && { error "support_level mismatch: got $APPLIED_SUPPORT"; FAILED=true; }
[[ "$APPLIED_SERVICE" != "$SERVICE_LEVEL" ]] && { error "service_level mismatch: got $APPLIED_SERVICE"; FAILED=true; }
[[ "$APPLIED_USAGE"   != "$USAGE"         ]] && { error "usage mismatch: got $APPLIED_USAGE";           FAILED=true; }
[[ "$APPLIED_UNITS"   != "$SYSTEM_UNITS"  ]] && { error "system_units mismatch: got $APPLIED_UNITS";    FAILED=true; }

if [[ "$FAILED" == "true" ]]; then
  error "Some settings did not apply correctly. Check your account entitlements."
  exit 1
fi

log "All settings verified successfully"
echo ""
echo -e "  ${GREEN}Next step:${NC} Refresh the cluster's OpenShift web console and verify"
echo -e "  the SLA now shows: ${GREEN}Premium Support Agreement${NC}"
echo ""

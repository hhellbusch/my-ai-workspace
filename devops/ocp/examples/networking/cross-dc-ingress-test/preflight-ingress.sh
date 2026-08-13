#!/usr/bin/env bash
set -euo pipefail

# Read-only pre-flight for cross-dc-ingress-test — validates workstation tools,
# env files, host network, and IngressController prerequisites before
# run-ingress-test.sh applies echo routes. See README.md "Pre-flight".

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="cross-dc-ingress-test"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

log() { printf '%s\n' "$*" >&2; }
pass() { PASS_COUNT=$((PASS_COUNT + 1)); log "  PASS: $*"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); log "  FAIL: $*"; }
warn() { WARN_COUNT=$((WARN_COUNT + 1)); log "  WARN: $*"; }

usage() {
  cat <<'EOF' >&2
Usage: preflight-ingress.sh <dc-a.env> <dc-b.env> [--skip-image-pull]

  Validates prerequisites for run-ingress-test.sh without applying test
  resources. Exits non-zero if any check fails.

  --skip-image-pull   Skip ephemeral probe-image pull test.
EOF
  exit 1
}

require_bin() {
  local bin
  for bin in "$@"; do
    if ! command -v "${bin}" >/dev/null 2>&1; then
      fail "Missing required tool: ${bin}"
      return 1
    fi
  done
  pass "Workstation tools present: $*"
}

dcvar() {
  local side="$1" name="$2" varname="DC${side}_${name}"
  printf '%s' "${!varname}"
}

check_env_side() {
  local side="$1" prefix="DC${side}_"
  local -a required=(
    KUBECONFIG NODE_NAMES BOND_VLAN_IFACE LOCAL_SUBNET REMOTE_SUBNET EXPECTED_MTU
    INGRESS_CONTROLLER_NAME INGRESS_DOMAIN INGRESS_ROUTE_LABEL_KEY INGRESS_ROUTE_LABEL_VALUE
    FRONTEND_MODE FRONTEND_TARGETS INGRESS_EXTERNAL_PORT TEST_ROUTE_HOST
  )
  local name val
  for name in "${required[@]}"; do
    val="$(dcvar "${side}" "${name}")"
    if [[ -z "${val}" ]]; then
      fail "DC-${side}: ${prefix}${name} is empty or unset"
    fi
  done
  if [[ "$(dcvar "${side}" FRONTEND_MODE)" != "vip" && "$(dcvar "${side}" FRONTEND_MODE)" != "dns_lb" ]]; then
    fail "DC-${side}: FRONTEND_MODE must be vip or dns_lb"
  fi
}

check_kubeconfig_side() {
  local side="$1" kubeconfig user
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  if [[ ! -f "${kubeconfig}" ]]; then
    fail "DC-${side}: kubeconfig not found: ${kubeconfig}"
    return
  fi
  if ! user=$(oc --kubeconfig="${kubeconfig}" whoami 2>/dev/null); then
    fail "DC-${side}: oc whoami failed for ${kubeconfig}"
    return
  fi
  pass "DC-${side}: kubeconfig OK (user: ${user})"
}

check_nodes_side() {
  local side="$1" kubeconfig nodes node missing=0
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  nodes="$(dcvar "${side}" NODE_NAMES)"
  for node in ${nodes}; do
    if ! oc --kubeconfig="${kubeconfig}" get node "${node}" >/dev/null 2>&1; then
      fail "DC-${side}: node not found in cluster: ${node}"
      missing=1
    fi
  done
  if [[ "${missing}" -eq 0 ]]; then
    pass "DC-${side}: all NODE_NAMES exist in the cluster"
  fi
}

check_platform_side() {
  local side="$1" kubeconfig
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  for crd in \
    nodenetworkconfigurationpolicies.nmstate.io \
    nodenetworkconfigurationenactments.nmstate.io \
    ingresscontrollers.operator.openshift.io; do
    if oc --kubeconfig="${kubeconfig}" get crd "${crd}" >/dev/null 2>&1; then
      pass "DC-${side}: CRD ${crd} present"
    else
      fail "DC-${side}: CRD ${crd} missing"
    fi
  done
}

check_nnce_side() {
  local side="$1" kubeconfig nodes node status
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  nodes="$(dcvar "${side}" NODE_NAMES)"
  for node in ${nodes}; do
    status=$(oc --kubeconfig="${kubeconfig}" get nnce -o json 2>/dev/null \
      | jq -r --arg n "${node}" \
        '.items[] | select(.metadata.name | endswith($n)) | .status.conditions[]? | select(.type=="Available") | .status' \
      || true)
    if [[ "${status}" == "True" ]]; then
      pass "DC-${side}: NNCE for ${node} is Available"
    else
      fail "DC-${side}: NNCE for ${node} not Available (got: '${status:-<none found>}') — apply NNCP first"
    fi
  done
}

check_host_iface_side() {
  local side="$1" kubeconfig nodes node iface out
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  iface="$(dcvar "${side}" BOND_VLAN_IFACE)"
  nodes="$(dcvar "${side}" NODE_NAMES)"
  node="${nodes%% *}"
  out=$(oc --kubeconfig="${kubeconfig}" debug "node/${node}" -- chroot /host ip link show "${iface}" 2>/dev/null || true)
  if echo "${out}" | grep -q "${iface}:"; then
    pass "DC-${side}: ${iface} exists on ${node}"
  else
    fail "DC-${side}: ${iface} not found on ${node} — check BOND_VLAN_IFACE matches NNCP"
  fi
}

check_ingress_controller_side() {
  local side="$1" kubeconfig name ns available
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  name="$(dcvar "${side}" INGRESS_CONTROLLER_NAME)"
  available=$(oc --kubeconfig="${kubeconfig}" get ingresscontroller "${name}" -n openshift-ingress-operator \
    -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || true)
  if [[ "${available}" == "True" ]]; then
    pass "DC-${side}: IngressController ${name} is Available"
  else
    fail "DC-${side}: IngressController ${name} not Available (got: '${available:-<not found>}')"
  fi
  ns="openshift-ingress-${name}"
  if oc --kubeconfig="${kubeconfig}" get ns "${ns}" >/dev/null 2>&1; then
    pass "DC-${side}: router namespace ${ns} exists"
  else
    fail "DC-${side}: router namespace ${ns} missing — IngressController not reconciled?"
  fi
}

check_permissions_side() {
  local side="$1" kubeconfig
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  if oc --kubeconfig="${kubeconfig}" auth can-i create routes -n "${NAMESPACE}" >/dev/null 2>&1; then
    pass "DC-${side}: can create routes in ${NAMESPACE}"
  else
    warn "DC-${side}: may not be able to create routes in ${NAMESPACE}"
  fi
}

check_image_pull_side() {
  local side="$1" kubeconfig pod_name out
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  pod_name="preflight-ingress-pull-$(echo "${side}" | tr '[:upper:]' '[:lower:]')"
  if out=$(oc --kubeconfig="${kubeconfig}" run "${pod_name}" \
      --rm -i --restart=Never --timeout=120s \
      --image="${TEST_PROBE_IMAGE}" \
      --command -- sleep 2 2>&1); then
    pass "DC-${side}: probe image pull OK (${TEST_PROBE_IMAGE})"
  else
    fail "DC-${side}: probe image pull failed (${TEST_PROBE_IMAGE}) — ${out}"
  fi
}

main() {
  local skip_image_pull=false arg

  if [[ $# -lt 2 ]]; then
    usage
  fi

  local dc_a_env="$1" dc_b_env="$2"
  shift 2
  for arg in "$@"; do
    case "${arg}" in
      --skip-image-pull) skip_image_pull=true ;;
      *) usage ;;
    esac
  done

  if ! require_bin oc jq envsubst; then
    log "Install missing tools and re-run."
    exit 1
  fi

  # shellcheck disable=SC1090
  source "${dc_a_env}"
  # shellcheck disable=SC1090
  source "${dc_b_env}"

  log "=== Layer 0: env file variables ==="
  check_env_side A
  check_env_side B
  if [[ -z "${TEST_PROBE_IMAGE:-}" ]]; then
    fail "TEST_PROBE_IMAGE is unset — build repl-net-probe and set in both env files"
  else
    pass "TEST_PROBE_IMAGE=${TEST_PROBE_IMAGE}"
  fi

  log ""
  log "=== Layer 0: cluster access ==="
  check_kubeconfig_side A
  check_kubeconfig_side B
  check_permissions_side A
  check_permissions_side B

  log ""
  log "=== Layer 0: platform prerequisites ==="
  check_platform_side A
  check_platform_side B

  log ""
  log "=== Layer 1: host network (NNCP must already be applied) ==="
  check_nodes_side A
  check_nodes_side B
  check_nnce_side A
  check_nnce_side B
  check_host_iface_side A
  check_host_iface_side B

  log ""
  log "=== Layer 3: IngressController (must exist before run-ingress-test) ==="
  check_ingress_controller_side A
  check_ingress_controller_side B

  if [[ "${skip_image_pull}" == false ]]; then
    log ""
    log "=== Probe image pull (ephemeral pod per cluster) ==="
    check_image_pull_side A
    check_image_pull_side B
  else
    log ""
    log "=== Probe image pull: skipped (--skip-image-pull) ==="
  fi

  log ""
  log "=== Summary: ${PASS_COUNT} passed, ${FAIL_COUNT} failed, ${WARN_COUNT} warnings ==="
  if [[ "${FAIL_COUNT}" -gt 0 ]]; then
    exit 1
  fi
  exit 0
}

main "$@"

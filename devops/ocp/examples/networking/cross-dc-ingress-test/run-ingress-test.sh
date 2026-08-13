#!/usr/bin/env bash
set -euo pipefail

# Cross-DC ingress test framework — layered verification for the dedicated
# IngressController path (Path B). Isolates failures by layer:
#   L1 host network, L2 frontend VIP/DNS-LB, L3 IngressController/router,
#   L4 route admission, L5 local path through router, L6 cross-DC reachability.
# See README.md.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/manifests"
NAMESPACE="cross-dc-ingress-test"

PASS_COUNT=0
FAIL_COUNT=0

log() { printf '%s\n' "$*" >&2; }
pass() { PASS_COUNT=$((PASS_COUNT + 1)); log "  PASS: $*"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); log "  FAIL: $*"; }

usage() {
  cat <<'EOF' >&2
Usage: run-ingress-test.sh <dc-a.env> <dc-b.env> [--cleanup]

  <dc-a.env> / <dc-b.env>   Copies of dc-*.env.example with real values.
  --cleanup                 Delete cross-dc-ingress-test namespace on both
                            clusters and exit — no tests are run.
EOF
  exit 1
}

require_bin() {
  local bin
  for bin in "$@"; do
    if ! command -v "${bin}" >/dev/null 2>&1; then
      log "Missing required tool: ${bin}. See README.md Prerequisites."
      exit 1
    fi
  done
}

dcvar() {
  local side="$1" name="$2" varname="DC${side}_${name}"
  printf '%s' "${!varname}"
}

router_namespace() {
  local side="$1"
  printf 'openshift-ingress-%s' "$(dcvar "${side}" INGRESS_CONTROLLER_NAME)"
}

host_exec() {
  local side="$1" node="$2" cmd="$3" kubeconfig
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  oc --kubeconfig="${kubeconfig}" debug "node/${node}" -- chroot /host bash -c "${cmd}" 2>/dev/null
}

tcp_check_from_node() {
  local side="$1" node="$2" target="$3" port="$4"
  host_exec "${side}" "${node}" "timeout 5 bash -c 'echo >/dev/tcp/${target}/${port}'"
}

apply_side() {
  local side="$1" kubeconfig label_key label_value
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  label_key="$(dcvar "${side}" INGRESS_ROUTE_LABEL_KEY)"
  label_value="$(dcvar "${side}" INGRESS_ROUTE_LABEL_VALUE)"
  log "Applying test resources to DC-${side}..."

  oc --kubeconfig="${kubeconfig}" apply -f "${MANIFESTS_DIR}/namespace.example.yaml"
  oc --kubeconfig="${kubeconfig}" apply -f "${MANIFESTS_DIR}/echo-service.example.yaml"

  TEST_PROBE_IMAGE="${TEST_PROBE_IMAGE}" \
    envsubst '${TEST_PROBE_IMAGE}' \
    < "${MANIFESTS_DIR}/echo-backend.example.yaml" \
    | oc --kubeconfig="${kubeconfig}" apply -f -

  INGRESS_ROUTE_LABEL_KEY="${label_key}" \
  INGRESS_ROUTE_LABEL_VALUE="${label_value}" \
  TEST_ROUTE_HOST="$(dcvar "${side}" TEST_ROUTE_HOST)" \
    envsubst '${INGRESS_ROUTE_LABEL_KEY} ${INGRESS_ROUTE_LABEL_VALUE} ${TEST_ROUTE_HOST}' \
    < "${MANIFESTS_DIR}/echo-route.example.yaml" \
    | oc --kubeconfig="${kubeconfig}" apply -f -
}

wait_for_echo_ready() {
  local side="$1" kubeconfig
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  log "Waiting for echo deployment on DC-${side}..."
  oc --kubeconfig="${kubeconfig}" -n "${NAMESPACE}" rollout status deployment/echo --timeout=120s
}

cleanup_side() {
  local side="$1" kubeconfig
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  log "Cleaning up DC-${side} (namespace ${NAMESPACE})..."
  oc --kubeconfig="${kubeconfig}" delete namespace "${NAMESPACE}" --ignore-not-found --wait=false
}

# --- Layer 1: host route to remote subnet, not default on repl VLAN ---------
layer1_host_route() {
  local side="$1" kubeconfig iface remote nodes node out
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  iface="$(dcvar "${side}" BOND_VLAN_IFACE)"
  remote="$(dcvar "${side}" REMOTE_SUBNET)"
  nodes="$(dcvar "${side}" NODE_NAMES)"
  for node in ${nodes}; do
    out=$(oc --kubeconfig="${kubeconfig}" debug "node/${node}" -- chroot /host ip route show table main 2>/dev/null || true)
    if echo "${out}" | grep -qE "${remote}.*${iface}"; then
      pass "L1 DC-${side}: ${node} has route to ${remote} via ${iface}"
    else
      fail "L1 DC-${side}: ${node} missing route to ${remote} via ${iface}"
    fi
    if echo "${out}" | grep -qE "^default .*${iface}"; then
      fail "L1 DC-${side}: ${node} has DEFAULT route via ${iface}"
    fi
  done
}

# --- Layer 2: frontend targets reachable from remote DC repl-gateway node ---
layer2_frontend_reachability() {
  local from_side="$1" to_side="$2" node targets target port out
  node="$(dcvar "${from_side}" NODE_NAMES)"
  node="${node%% *}"
  targets="$(dcvar "${to_side}" FRONTEND_TARGETS)"
  port="$(dcvar "${to_side}" INGRESS_EXTERNAL_PORT)"
  for target in ${targets}; do
    if tcp_check_from_node "${from_side}" "${node}" "${target}" "${port}"; then
      pass "L2 DC-${from_side}→DC-${to_side}: TCP ${target}:${port} reachable from ${node}"
    else
      fail "L2 DC-${from_side}→DC-${to_side}: TCP ${target}:${port} NOT reachable from ${node} — check VIP/keepalived/MetalLB, firewall, or dns_lb targets"
    fi
  done
}

# --- Layer 3: IngressController + router pods ------------------------------
layer3_ingress_controller() {
  local side="$1" kubeconfig name ns available ready replicas
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  name="$(dcvar "${side}" INGRESS_CONTROLLER_NAME)"
  ns="$(router_namespace "${side}")"
  available=$(oc --kubeconfig="${kubeconfig}" get ingresscontroller "${name}" -n openshift-ingress-operator \
    -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || true)
  if [[ "${available}" == "True" ]]; then
    pass "L3 DC-${side}: IngressController ${name} Available"
  else
    fail "L3 DC-${side}: IngressController ${name} not Available"
    return
  fi
  ready=$(oc --kubeconfig="${kubeconfig}" -n "${ns}" get deployment router-default \
    -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
  replicas=$(oc --kubeconfig="${kubeconfig}" -n "${ns}" get deployment router-default \
    -o jsonpath='{.status.replicas}' 2>/dev/null || true)
  if [[ -n "${ready}" && "${ready}" -ge 1 ]]; then
    pass "L3 DC-${side}: router deployment ready (${ready}/${replicas:-?} replicas in ${ns})"
  else
    fail "L3 DC-${side}: router deployment not ready in ${ns}"
  fi
  domain="$(dcvar "${side}" INGRESS_DOMAIN)"
  ic_domain=$(oc --kubeconfig="${kubeconfig}" get ingresscontroller "${name}" -n openshift-ingress-operator \
    -o jsonpath='{.spec.domain}' 2>/dev/null || true)
  if [[ "${ic_domain}" == "${domain}" ]]; then
    pass "L3 DC-${side}: IngressController domain matches env (${domain})"
  else
    fail "L3 DC-${side}: IngressController domain '${ic_domain}' != env '${domain}'"
  fi
}

# --- Layer 4: test route admitted by replication shard only ----------------
layer4_route_admission() {
  local side="$1" kubeconfig name host router_name ingress_json admitted=0
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  name="$(dcvar "${side}" INGRESS_CONTROLLER_NAME)"
  host="$(dcvar "${side}" TEST_ROUTE_HOST)"
  ingress_json=$(oc --kubeconfig="${kubeconfig}" -n "${NAMESPACE}" get route repl-test-echo -o json 2>/dev/null || true)
  if [[ -z "${ingress_json}" ]]; then
    fail "L4 DC-${side}: route repl-test-echo not found"
    return
  fi
  if echo "${ingress_json}" | jq -e --arg h "${host}" '.spec.host == $h' >/dev/null 2>&1; then
    pass "L4 DC-${side}: route host is ${host}"
  else
    fail "L4 DC-${side}: route host mismatch"
  fi
  router_name=$(echo "${ingress_json}" | jq -r \
    '.status.ingress[]? | select(.routerName | test("replication")) | .routerName' 2>/dev/null | head -n1 || true)
  if [[ -n "${router_name}" ]]; then
    pass "L4 DC-${side}: route admitted by replication router (${router_name})"
    admitted=1
  else
    fail "L4 DC-${side}: route not admitted by replication shard — check routeSelector labels and IngressController name"
  fi
  if [[ "${admitted}" -eq 1 ]]; then
  default_ingress=$(oc --kubeconfig="${kubeconfig}" get ingresscontroller default -n openshift-ingress-operator \
    -o jsonpath='{.spec.domain}' 2>/dev/null || true)
  if [[ "${host}" != *"${default_ingress}"* ]]; then
    pass "L4 DC-${side}: test host not on default ingress domain (${default_ingress})"
  else
    warn_msg="L4 DC-${side}: test host may overlap default ingress domain — confirm WAN isolation"
    log "  WARN: ${warn_msg}"
  fi
  fi
}

# --- Layer 5: local curl through frontend VIP to test route ----------------
layer5_local_path() {
  local side="$1" node host target port targets out body
  node="$(dcvar "${side}" NODE_NAMES)"
  node="${node%% *}"
  host="$(dcvar "${side}" TEST_ROUTE_HOST)"
  port="$(dcvar "${side}" INGRESS_EXTERNAL_PORT)"
  targets="$(dcvar "${side}" FRONTEND_TARGETS)"
  target="${targets%% *}"
  out=$(host_exec "${side}" "${node}" \
    "curl -sk --max-time 10 --resolve ${host}:${port}:${target} https://${host}/" || true)
  body=$(printf '%s' "${out}" | tail -n1)
  if [[ "${body}" == "ok" ]]; then
    pass "L5 DC-${side}: curl via ${target}:${port} → ${host} returned ok"
  else
    fail "L5 DC-${side}: curl via ${target}:${port} → ${host} failed (got: '${body:-<empty>}') — check VIP→router port mapping (often 443→8443), route TLS, echo backend"
  fi
}

# --- Layer 6: cross-DC curl from remote repl-gateway node ------------------
layer6_cross_dc_path() {
  local from_side="$1" to_side="$2" node host target port targets out body
  node="$(dcvar "${from_side}" NODE_NAMES)"
  node="${node%% *}"
  host="$(dcvar "${to_side}" TEST_ROUTE_HOST)"
  port="$(dcvar "${to_side}" INGRESS_EXTERNAL_PORT)"
  targets="$(dcvar "${to_side}" FRONTEND_TARGETS)"
  target="${targets%% *}"
  out=$(host_exec "${from_side}" "${node}" \
    "curl -sk --max-time 15 --resolve ${host}:${port}:${target} https://${host}/" || true)
  body=$(printf '%s' "${out}" | tail -n1)
  if [[ "${body}" == "ok" ]]; then
    pass "L6 DC-${from_side}→DC-${to_side}: cross-DC curl ${host} via ${target}:${port} returned ok"
  else
    fail "L6 DC-${from_side}→DC-${to_side}: cross-DC curl failed (got: '${body:-<empty>}') — isolate: L2 TCP vs L4 route vs L5 local path"
  fi
}

main() {
  require_bin oc envsubst jq

  if [[ $# -lt 2 ]]; then
    usage
  fi

  local dc_a_env="$1" dc_b_env="$2"
  shift 2

  local cleanup_only=false
  local arg
  for arg in "$@"; do
    case "${arg}" in
      --cleanup) cleanup_only=true ;;
      *) usage ;;
    esac
  done

  # shellcheck disable=SC1090
  source "${dc_a_env}"
  # shellcheck disable=SC1090
  source "${dc_b_env}"

  if [[ -z "${TEST_PROBE_IMAGE:-}" ]]; then
    log "TEST_PROBE_IMAGE must be set in dc-a.env (same value in dc-b.env)."
    exit 1
  fi

  if [[ "${cleanup_only}" == true ]]; then
    cleanup_side A
    cleanup_side B
    exit 0
  fi

  apply_side A
  apply_side B
  wait_for_echo_ready A
  wait_for_echo_ready B

  log ""
  log "=== Layer 1: host routing on repl VLAN ==="
  layer1_host_route A
  layer1_host_route B

  log ""
  log "=== Layer 2: frontend TCP (VIP or dns_lb targets) from remote DC ==="
  layer2_frontend_reachability A B
  layer2_frontend_reachability B A

  log ""
  log "=== Layer 3: IngressController + router ==="
  layer3_ingress_controller A
  layer3_ingress_controller B

  log ""
  log "=== Layer 4: route admission on replication shard ==="
  layer4_route_admission A
  layer4_route_admission B

  log ""
  log "=== Layer 5: local path through frontend (same DC) ==="
  layer5_local_path A
  layer5_local_path B

  log ""
  log "=== Layer 6: cross-DC path through remote frontend ==="
  layer6_cross_dc_path A B
  layer6_cross_dc_path B A

  log ""
  log "=== Summary: ${PASS_COUNT} passed, ${FAIL_COUNT} failed ==="
  if [[ "${FAIL_COUNT}" -gt 0 ]]; then
    log ""
    log "Diagnosis guide: see README.md \"Layer isolation\" — fix lowest failing layer first."
    exit 1
  fi
  exit 0
}

main "$@"

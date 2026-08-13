#!/usr/bin/env bash
set -euo pipefail

# Cross-DC network test framework — validates the host network (NNCP),
# Multus pod attachment (NAD/whereabouts), and MultiNetworkPolicy layers
# across two live OpenShift clusters, using repl-net-probe test pods instead of
# Kafka. Maps 1:1 to the "Verification checklist" in
# ../cross-dc-replication.md and ../messaging/kafka/cross-dc-architecture-overview.md.
# See README.md for prerequisites and how to read results.
#
# Usage:
#   ./run-network-test.sh <dc-a.env> <dc-b.env> [--with-bond-failover-test]
#   ./run-network-test.sh <dc-a.env> <dc-b.env> --cleanup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/manifests"
NAMESPACE="cross-dc-net-test"
TEST_PORT="${TEST_PORT:-9095}"

PASS_COUNT=0
FAIL_COUNT=0

log() { printf '%s\n' "$*" >&2; }
pass() { PASS_COUNT=$((PASS_COUNT + 1)); log "  PASS: $*"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); log "  FAIL: $*"; }

usage() {
  cat <<'EOF' >&2
Usage: run-network-test.sh <dc-a.env> <dc-b.env> [--with-bond-failover-test]
       run-network-test.sh <dc-a.env> <dc-b.env> --cleanup

  <dc-a.env> / <dc-b.env>     Copies of dc-a.env.example / dc-b.env.example
                              with real cluster values filled in.
  --with-bond-failover-test   Also run test 7 (manual, interactive, induces
                              a real fault on a live node). Off by default.
  --cleanup                   Delete the cross-dc-net-test namespace on both
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

# Indirect lookup: dcvar A KUBECONFIG -> value of $DCA_KUBECONFIG.
# Deliberately errors (via set -u) if the env file didn't export the
# variable — better to fail fast than silently test against an empty value.
dcvar() {
  local side="$1" name="$2" varname="DC${side}_${name}"
  printf '%s' "${!varname}"
}

get_pod_test_ip() {
  local side="$1" pod="$2" kubeconfig status
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  status=$(oc --kubeconfig="${kubeconfig}" -n "${NAMESPACE}" get pod "${pod}" \
    -o jsonpath='{.metadata.annotations["k8s.v1.cni.cncf.io/network-status"]}' 2>/dev/null || true)
  if [[ -z "${status}" ]]; then
    return
  fi
  echo "${status}" \
    | jq -r '.[] | select(.name | test("repl-net-test")) | .ips[0] // empty' 2>/dev/null \
    | head -n1 || true
}

apply_side() {
  local side="$1" kubeconfig
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  log "Applying test resources to DC-${side}..."

  oc --kubeconfig="${kubeconfig}" apply -f "${MANIFESTS_DIR}/namespace.example.yaml"

  BOND_VLAN_IFACE="$(dcvar "${side}" BOND_VLAN_IFACE)" \
  LOCAL_GATEWAY="$(dcvar "${side}" LOCAL_GATEWAY)" \
  REMOTE_SUBNET="$(dcvar "${side}" REMOTE_SUBNET)" \
  TEST_POOL_RANGE="$(dcvar "${side}" TEST_POOL_RANGE)" \
  TEST_POOL_START="$(dcvar "${side}" TEST_POOL_START)" \
  TEST_POOL_END="$(dcvar "${side}" TEST_POOL_END)" \
    envsubst '${BOND_VLAN_IFACE} ${LOCAL_GATEWAY} ${REMOTE_SUBNET} ${TEST_POOL_RANGE} ${TEST_POOL_START} ${TEST_POOL_END}' \
    < "${MANIFESTS_DIR}/nad-test.example.yaml" \
    | oc --kubeconfig="${kubeconfig}" apply -f -

  POD_NAME="probe-authorized" POD_ROLE="authorized" TEST_PORT="${TEST_PORT}" \
  TEST_PROBE_IMAGE="${TEST_PROBE_IMAGE}" \
    envsubst '${POD_NAME} ${POD_ROLE} ${TEST_PORT} ${TEST_PROBE_IMAGE}' \
    < "${MANIFESTS_DIR}/probe-pod.example.yaml" \
    | oc --kubeconfig="${kubeconfig}" apply -f -

  POD_NAME="probe-unauthorized" POD_ROLE="unauthorized" TEST_PORT="${TEST_PORT}" \
  TEST_PROBE_IMAGE="${TEST_PROBE_IMAGE}" \
    envsubst '${POD_NAME} ${POD_ROLE} ${TEST_PORT} ${TEST_PROBE_IMAGE}' \
    < "${MANIFESTS_DIR}/probe-pod.example.yaml" \
    | oc --kubeconfig="${kubeconfig}" apply -f -

  REMOTE_SUBNET="$(dcvar "${side}" REMOTE_SUBNET)" TEST_PORT="${TEST_PORT}" \
    envsubst '${REMOTE_SUBNET} ${TEST_PORT}' \
    < "${MANIFESTS_DIR}/multinetworkpolicy-test.example.yaml" \
    | oc --kubeconfig="${kubeconfig}" apply -f -
}

wait_for_pods_ready() {
  local side="$1" kubeconfig
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  log "Waiting for test pods to be Ready on DC-${side}..."
  oc --kubeconfig="${kubeconfig}" -n "${NAMESPACE}" wait \
    --for=condition=Ready pod/probe-authorized pod/probe-unauthorized --timeout=120s
}

cleanup_side() {
  local side="$1" kubeconfig
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  log "Cleaning up DC-${side} (namespace ${NAMESPACE})..."
  oc --kubeconfig="${kubeconfig}" delete namespace "${NAMESPACE}" --ignore-not-found --wait=false
}

# --- Test 1: NNCP/NNCE health --------------------------------------------
test1_nncp_health() {
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
      fail "DC-${side}: NNCE for ${node} not Available (got: '${status:-<none found>}')"
    fi
  done
}

# --- Test 2: host route to remote subnet, not a default route -----------
test2_host_route() {
  local side="$1" kubeconfig iface remote nodes node out
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  iface="$(dcvar "${side}" BOND_VLAN_IFACE)"
  remote="$(dcvar "${side}" REMOTE_SUBNET)"
  nodes="$(dcvar "${side}" NODE_NAMES)"
  for node in ${nodes}; do
    out=$(oc --kubeconfig="${kubeconfig}" debug "node/${node}" -- chroot /host ip route show table main 2>/dev/null || true)
    if echo "${out}" | grep -qE "${remote}.*${iface}"; then
      pass "DC-${side}: ${node} has a route to ${remote} via ${iface}"
    else
      fail "DC-${side}: ${node} missing expected route to ${remote} via ${iface}"
    fi
    if echo "${out}" | grep -qE "^default .*${iface}"; then
      fail "DC-${side}: ${node} has a DEFAULT route via ${iface} — see cross-dc-replication.md#layer-3-routing"
    fi
  done
}

# --- Test 3: pod attachment — second interface, correct IP, no default-route
test3_pod_attachment() {
  local side="$1" kubeconfig pod status entry ip
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  for pod in probe-authorized probe-unauthorized; do
    status=$(oc --kubeconfig="${kubeconfig}" -n "${NAMESPACE}" get pod "${pod}" \
      -o jsonpath='{.metadata.annotations["k8s.v1.cni.cncf.io/network-status"]}' 2>/dev/null || true)
    if [[ -z "${status}" ]]; then
      fail "DC-${side}: ${pod} has no network-status annotation"
      continue
    fi
    entry=$(echo "${status}" | jq -c '.[] | select(.name | test("repl-net-test"))' 2>/dev/null || true)
    if [[ -z "${entry}" ]]; then
      fail "DC-${side}: ${pod} has no repl-net-test entry in network-status"
      continue
    fi
    ip=$(echo "${entry}" | jq -r '.ips[0] // empty' 2>/dev/null || true)
    if [[ -z "${ip}" ]]; then
      fail "DC-${side}: ${pod} repl-net-test entry has no IP"
      continue
    fi
    if echo "${entry}" | jq -e 'has("default-route")' >/dev/null 2>&1; then
      fail "DC-${side}: ${pod} repl-net-test entry unexpectedly has a default-route"
    else
      pass "DC-${side}: ${pod} attached to repl-net-test with IP ${ip}, no default-route"
    fi
  done
}

# --- Test 4: cross-DC reachability (bidirectional TCP handshake) --------
test4_reachability() {
  local ip_a ip_b kc_a kc_b out
  kc_a="$(dcvar A KUBECONFIG)"
  kc_b="$(dcvar B KUBECONFIG)"
  ip_a=$(get_pod_test_ip A probe-authorized)
  ip_b=$(get_pod_test_ip B probe-authorized)
  if [[ -z "${ip_a}" || -z "${ip_b}" ]]; then
    fail "Reachability: missing test pod IP (DC-A=${ip_a:-<none>}, DC-B=${ip_b:-<none>})"
    return
  fi
  if out=$(oc --kubeconfig="${kc_a}" -n "${NAMESPACE}" exec probe-authorized -- ncat -zv -w 5 "${ip_b}" "${TEST_PORT}" 2>&1); then
    pass "DC-A -> DC-B: probe-authorized reached ${ip_b}:${TEST_PORT}"
  else
    fail "DC-A -> DC-B: probe-authorized could NOT reach ${ip_b}:${TEST_PORT} (${out})"
  fi
  if out=$(oc --kubeconfig="${kc_b}" -n "${NAMESPACE}" exec probe-authorized -- ncat -zv -w 5 "${ip_a}" "${TEST_PORT}" 2>&1); then
    pass "DC-B -> DC-A: probe-authorized reached ${ip_a}:${TEST_PORT}"
  else
    fail "DC-B -> DC-A: probe-authorized could NOT reach ${ip_a}:${TEST_PORT} (${out})"
  fi
}

# --- Test 5: real path MTU (ping -M do sweep) ----------------------------
test5_mtu() {
  local kc_a ip_b expected_mtu size ok_size=0 effective_mtu
  kc_a="$(dcvar A KUBECONFIG)"
  expected_mtu="$(dcvar A EXPECTED_MTU)"
  ip_b=$(get_pod_test_ip B probe-authorized)
  if [[ -z "${ip_b}" ]]; then
    fail "MTU: missing DC-B test pod IP"
    return
  fi
  for size in 1472 1400 1200 1000 500; do
    if oc --kubeconfig="${kc_a}" -n "${NAMESPACE}" exec probe-authorized -- \
        ping -M do -s "${size}" -c 2 -W 3 "${ip_b}" >/dev/null 2>&1; then
      ok_size="${size}"
      break
    fi
  done
  if [[ "${ok_size}" -eq 0 ]]; then
    fail "MTU: no ping payload size succeeded down to 500 bytes — check reachability (test 4) first"
    return
  fi
  effective_mtu=$((ok_size + 28))
  if [[ "${effective_mtu}" -ge "${expected_mtu}" ]]; then
    pass "MTU: path supports >= ${effective_mtu} bytes (expected ${expected_mtu})"
  else
    fail "MTU: path only supports ${effective_mtu} bytes, expected ${expected_mtu} — check WAN circuit MTU end-to-end"
  fi
}

# --- Test 6: MultiNetworkPolicy enforcement ------------------------------
# probe-unauthorized sits on the SAME NAD/local subnet as probe-authorized
# and is deliberately NOT selected by the policy's podSelector — the thing
# actually under test is the policy's ipBlock restriction, so the meaningful
# negative case is "a peer whose IP isn't in the allowed remote subnet",
# which a local pod is. See README.md "Why test 6 uses a local peer".
test6_policy_enforcement() {
  local side="$1" kubeconfig ip_local out
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  if ! oc --kubeconfig="${kubeconfig}" -n "${NAMESPACE}" get multi-networkpolicy repl-net-test-restrict >/dev/null 2>&1; then
    fail "DC-${side}: repl-net-test-restrict MultiNetworkPolicy not found — cannot trust the enforcement result"
    return
  fi
  ip_local=$(get_pod_test_ip "${side}" probe-authorized)
  if [[ -z "${ip_local}" ]]; then
    fail "DC-${side}: missing probe-authorized IP for policy test"
    return
  fi
  if out=$(oc --kubeconfig="${kubeconfig}" -n "${NAMESPACE}" exec probe-unauthorized -- ncat -zv -w 5 "${ip_local}" "${TEST_PORT}" 2>&1); then
    fail "DC-${side}: probe-unauthorized (local subnet) unexpectedly REACHED probe-authorized — policy not enforcing (${out})"
  else
    pass "DC-${side}: probe-unauthorized (local subnet, outside the allowed remote ipBlock) correctly blocked"
  fi
}

# --- Test 7: bond failover (manual/opt-in only) --------------------------
test7_bond_failover() {
  local side="$1" kubeconfig nodes node member confirm
  kubeconfig="$(dcvar "${side}" KUBECONFIG)"
  nodes="$(dcvar "${side}" NODE_NAMES)"
  node="${nodes%% *}"
  log ""
  log "=== Test 7 (manual/opt-in): bond failover on DC-${side} node ${node} ==="
  log "This downs one bond member on a LIVE node, re-checks reachability, then restores it."
  read -r -p "Proceed on ${node}? [y/N] " confirm
  if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
    log "Skipped bond failover test for DC-${side}."
    return
  fi
  read -r -p "Bond member interface to down on ${node} (e.g. ens4f0): " member
  oc --kubeconfig="${kubeconfig}" debug "node/${node}" -- chroot /host nmcli device disconnect "${member}"
  log "Downed ${member} on ${node}. Re-running cross-DC reachability..."
  test4_reachability
  log "Restoring ${member} on ${node}..."
  oc --kubeconfig="${kubeconfig}" debug "node/${node}" -- chroot /host nmcli device connect "${member}"
  pass "DC-${side}: bond failover manual test completed — confirm the reachability re-check above passed"
}

main() {
  require_bin oc envsubst jq

  if [[ $# -lt 2 ]]; then
    usage
  fi

  local dc_a_env="$1" dc_b_env="$2"
  shift 2

  local with_bond_failover=false
  local cleanup_only=false
  local arg
  for arg in "$@"; do
    case "${arg}" in
      --with-bond-failover-test) with_bond_failover=true ;;
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
    log "Build repl-net-probe/Containerfile and push to your registry — see repl-net-probe/README.md."
    exit 1
  fi

  if [[ "${cleanup_only}" == true ]]; then
    cleanup_side A
    cleanup_side B
    exit 0
  fi

  apply_side A
  apply_side B
  wait_for_pods_ready A
  wait_for_pods_ready B

  log ""
  log "=== Test 1: NNCP/NNCE health ==="
  test1_nncp_health A
  test1_nncp_health B

  log ""
  log "=== Test 2: host route (not default) ==="
  test2_host_route A
  test2_host_route B

  log ""
  log "=== Test 3: pod attachment (interface, IP, no default-route) ==="
  test3_pod_attachment A
  test3_pod_attachment B

  log ""
  log "=== Test 4: cross-DC reachability ==="
  test4_reachability

  log ""
  log "=== Test 5: real path MTU ==="
  test5_mtu

  log ""
  log "=== Test 6: MultiNetworkPolicy enforcement ==="
  test6_policy_enforcement A
  test6_policy_enforcement B

  if [[ "${with_bond_failover}" == true ]]; then
    test7_bond_failover A
    test7_bond_failover B
  fi

  log ""
  log "=== Summary: ${PASS_COUNT} passed, ${FAIL_COUNT} failed ==="
  if [[ "${FAIL_COUNT}" -gt 0 ]]; then
    exit 1
  fi
  exit 0
}

main "$@"

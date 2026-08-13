#!/usr/bin/env bash
set -euo pipefail

# Local validation for cross-DC rollout artifacts — run before first commit or
# live cluster trial. Does not contact any cluster API.
#
# Usage: ./validate-local.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLES_ROOT="$(cd "${ROOT}/../.." && pwd)"
WS_ROOT="$(cd "${ROOT}/../../../../.." && pwd)"
NNCP_CHART="${EXAMPLES_ROOT}/messaging/kafka/cross-dc-nncp-helm"
KAFKA_NET_CHART="${EXAMPLES_ROOT}/messaging/kafka/cross-dc-kafka-net-helm"
TEST_DIR="${EXAMPLES_ROOT}/networking/cross-dc-network-test"
INGRESS_TEST_DIR="${EXAMPLES_ROOT}/networking/cross-dc-ingress-test"

log() { printf '%s\n' "$*" >&2; }
pass() { log "  PASS: $*"; }

require() {
  local bin
  for bin in "$@"; do
    command -v "${bin}" >/dev/null 2>&1 || {
      log "Missing: ${bin}"
      exit 1
    }
  done
}

log "=== Tools ==="
require python3 helm bash
pass "python3, helm, bash present"

log ""
log "=== Shell scripts ==="
bash -n "${TEST_DIR}/run-network-test.sh"
bash -n "${TEST_DIR}/preflight.sh"
bash -n "${INGRESS_TEST_DIR}/run-ingress-test.sh"
bash -n "${INGRESS_TEST_DIR}/preflight-ingress.sh"
pass "network + ingress test scripts syntax"

log ""
log "=== Inventory validation ==="
python3 "${ROOT}/render-config.py" --inventory "${ROOT}/inventory-dc-a.example.yaml" --validate-only
python3 "${ROOT}/render-config.py" --inventory "${ROOT}/inventory-dc-b.example.yaml" --validate-only
python3 "${ROOT}/render-config.py" --inventory "${ROOT}/inventory-dc-a.static.example.yaml" --validate-only
python3 "${ROOT}/render-config.py" --inventory "${ROOT}/inventory-dc-a.ingress.example.yaml" --validate-only
python3 "${ROOT}/render-config.py" --inventory "${ROOT}/inventory-dc-b.ingress.example.yaml" --validate-only
pass "example inventories validate"

log ""
log "=== Helm lint + template smoke ==="
helm lint "${NNCP_CHART}"
helm lint "${KAFKA_NET_CHART}"
helm template repl-net "${NNCP_CHART}" -f "${NNCP_CHART}/values-dc-a.example.yaml" >/dev/null
helm template kafka-repl-net "${KAFKA_NET_CHART}" -f "${KAFKA_NET_CHART}/values-dc-a.example.yaml" >/dev/null
helm template kafka-repl-net "${KAFKA_NET_CHART}" -f "${KAFKA_NET_CHART}/values-dc-a.static.example.yaml" >/dev/null
pass "NNCP + Kafka net charts lint and template (whereabouts + static)"

log ""
log "=== Review frontmatter (workspace) ==="
if [[ -f "${WS_ROOT}/scripts/check-review-frontmatter.py" ]]; then
  (cd "${WS_ROOT}" && python3 scripts/check-review-frontmatter.py)
  pass "review frontmatter"
else
  log "  SKIP: ${WS_ROOT}/scripts/check-review-frontmatter.py not found"
fi

log ""
log "=== All local checks passed ==="
log "Next against live clusters:"
log "  Path A (multus): inventory → render-config.py → preflight.sh → run-network-test.sh"
log "  Path B (ingress): inventory → render-config.py → preflight-ingress.sh → run-ingress-test.sh"

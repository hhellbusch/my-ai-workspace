#!/usr/bin/env bash
# Run preflight validation gate in live mode against real hub/BMC/network targets.
#
# Usage:
#   export BMC_USERNAME=root BMC_PASSWORD=...
#   ./scripts/run-live.sh examples/live-preflight-vars.json
#
# Optional:
#   INVENTORY=examples/live-inventory.ini  # when network.probe_from is a bastion host
#   PREFLIGHT_REPORT_PATH=/tmp/preflight-live.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG="${1:?usage: run-live.sh <live-vars.json>}"

if [[ ! -f "${CONFIG}" ]]; then
  if [[ -f "${SANDBOX_ROOT}/examples/${CONFIG}" ]]; then
    CONFIG="${SANDBOX_ROOT}/examples/${CONFIG}"
  else
    echo "error: config not found: ${1}" >&2
    exit 1
  fi
fi

REPORT="${PREFLIGHT_REPORT_PATH:-${SANDBOX_ROOT}/artifacts/live/preflight-report.json}"
EXTRA_VARS="${TMPDIR:-/tmp}/bare-metal-live-extra-$$.json"
mkdir -p "$(dirname "${REPORT}")"

python3 "${SCRIPT_DIR}/merge-live-vars.py" "${CONFIG}" --report "${REPORT}" -o "${EXTRA_VARS}"
echo '{"blocking":[],"warnings":[]}' > "${REPORT}"

INVENTORY_ARGS=()
if [[ -n "${INVENTORY:-}" ]]; then
  INVENTORY_ARGS=(-i "${INVENTORY}")
fi

cd "${SANDBOX_ROOT}"
set +e
ansible-playbook playbooks/validation-gate.yml -e "@${EXTRA_VARS}" "${INVENTORY_ARGS[@]}"
EXIT_CODE=$?
set -e

rm -f "${EXTRA_VARS}"

python3 - "${REPORT}" "${EXIT_CODE}" <<'PY'
import json, sys
report_path, exit_code = sys.argv[1], int(sys.argv[2])
report = json.load(open(report_path))
blocking = report.get("blocking", [])
warnings = report.get("warnings", [])
print()
print("── live preflight recap ──")
print(f"  ansible exit code: {exit_code}")
print(f"  blocking findings: {len(blocking)}")
print(f"  warnings:          {len(warnings)}")
for item in blocking:
    print(f"    • [{item['id']}] {item['message']}")
for item in warnings:
    print(f"    • WARN [{item['id']}] {item['message']}")
PY

echo "report: ${REPORT}"
exit "${EXIT_CODE}"

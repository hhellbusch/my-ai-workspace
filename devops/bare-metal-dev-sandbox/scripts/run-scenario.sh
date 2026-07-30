#!/usr/bin/env bash
# Run one preflight scenario against the sandbox harness.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCENARIO="${1:?usage: run-scenario.sh <scenario.yaml>}"

if [[ ! -f "${SCENARIO}" ]]; then
  if [[ -f "${SANDBOX_ROOT}/scenarios/${SCENARIO}" ]]; then
    SCENARIO="${SANDBOX_ROOT}/scenarios/${SCENARIO}"
  elif [[ -f "${SANDBOX_ROOT}/scenarios/${SCENARIO}.yaml" ]]; then
    SCENARIO="${SANDBOX_ROOT}/scenarios/${SCENARIO}.yaml"
  else
    echo "error: scenario not found: ${1}" >&2
    exit 1
  fi
fi

SCENARIO_NAME="$(basename "${SCENARIO}" .yaml)"
ARTIFACT_DIR="${SANDBOX_ROOT}/artifacts/scenarios/${SCENARIO_NAME}"
REPORT="${ARTIFACT_DIR}/preflight-report.json"
EXTRA_VARS="${ARTIFACT_DIR}/extra-vars.json"
mkdir -p "${ARTIFACT_DIR}"

python3 "${SCRIPT_DIR}/load-scenario.py" "${SCENARIO}" --report "${REPORT}" > "${EXTRA_VARS}"

# Avoid stale findings when a prior run aborted before aggregate_gate
echo '{"blocking":[],"warnings":[]}' > "${REPORT}"

NEEDS_REDFISH=false
if grep -q '127.0.0.1' "${EXTRA_VARS}" && grep -q '"bmc"' "${EXTRA_VARS}"; then
  NEEDS_REDFISH=true
fi

cleanup() {
  "${SCRIPT_DIR}/stop-mock-tcp.sh" 2>/dev/null || true
  if [[ "${STARTED_REDFISH:-false}" == true ]]; then
    "${SCRIPT_DIR}/stop-static.sh" 2>/dev/null || true
  fi
}
trap cleanup EXIT

STARTED_REDFISH=false
if [[ "${NEEDS_REDFISH}" == true ]]; then
  "${SCRIPT_DIR}/start-static.sh"
  STARTED_REDFISH=true
  sleep 1
fi

chmod +x scripts/*.sh scripts/*.py

# Start mock TCP listeners declared by scenario (open connections)
LISTENERS=$(python3 "${SCRIPT_DIR}/list-mock-listeners.py" "${EXTRA_VARS}" 2>/dev/null || true)
if [[ -n "${LISTENERS}" ]]; then
  mapfile -t LISTENER_ARRAY <<< "${LISTENERS}"
  "${SCRIPT_DIR}/mock-tcp-ports.sh" "${LISTENER_ARRAY[@]}"
  sleep 0.5
fi

cd "${SANDBOX_ROOT}"
set +e
ansible-playbook playbooks/validation-gate.yml -e "@${EXTRA_VARS}"
EXIT_CODE=$?
set -e

if [[ ! -f "${REPORT}" ]]; then
  echo '{"blocking":[],"warnings":[]}' > "${REPORT}"
fi

python3 - "${REPORT}" "${EXIT_CODE}" "${EXTRA_VARS}" <<'PY'
import json, sys
report_path, exit_code, extra_path = sys.argv[1], int(sys.argv[2]), sys.argv[3]
report = json.load(open(report_path))
extra = json.load(open(extra_path))
mode = extra.get("preflight_validation_mode", "harness")
blocking = report.get("blocking", [])
warnings = report.get("warnings", [])
print()
print("── ansible recap (what it means) ──")
print(f"  ansible exit code: {exit_code}  (0=gate passed, 2=blocking findings — both can be correct)")
print(f"  validation mode:   {mode}")
print(f"  blocking findings: {len(blocking)}")
print(f"  warnings:          {len(warnings)}")
if blocking:
    for item in blocking:
        print(f"    • [{item['id']}] {item['message']}")
if mode == "harness":
    print("  network checks:    simulated via scenario state open/closed (no TCP probe)")
elif mode == "hybrid":
    print("  network checks:    real TCP probes; mock_listener:true = open, false = closed")
else:
    print("  network checks:    real TCP probes against scenario targets")
print("  failed=1 in recap: expected on negative scenarios (validation gate)")
PY

python3 "${SCRIPT_DIR}/assert-scenario.py" "${SCENARIO}" "${REPORT}" "${EXIT_CODE}"
ASSERT_EXIT=$?

echo "report: ${REPORT}"
exit "${ASSERT_EXIT}"

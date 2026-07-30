#!/usr/bin/env bash
# Run all packaged preflight scenarios (harness regression suite).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

FAILURES=0
for scenario in "${SANDBOX_ROOT}"/scenarios/*.yaml; do
  echo "======== $(basename "${scenario}") ========"
  if ! "${SCRIPT_DIR}/run-scenario.sh" "${scenario}"; then
    FAILURES=$((FAILURES + 1))
  fi
  echo
done

if [[ "${FAILURES}" -gt 0 ]]; then
  echo "${FAILURES} scenario(s) failed" >&2
  exit 1
fi

echo "all scenarios passed"

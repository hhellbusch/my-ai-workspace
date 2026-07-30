#!/usr/bin/env bash
# G0 syntax check + full scenario regression suite.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${SANDBOX_ROOT}"
echo "── G0: playbook syntax ──"
for playbook in playbooks/*.yml; do
  echo "  ${playbook}"
  ansible-playbook --syntax-check "${playbook}"
done

echo
echo "── scenario regression ──"
"${SCRIPT_DIR}/run-all-scenarios.sh"

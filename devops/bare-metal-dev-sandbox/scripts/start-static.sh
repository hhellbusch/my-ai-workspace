#!/usr/bin/env bash
# Start static Redfish BMC emulator (sushy-static) for per-developer sandbox work.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FIXTURES="${SANDBOX_ROOT}/fixtures/static-redfish/redfish/v1"
CERTS="${SANDBOX_ROOT}/fixtures/certs"
CONTAINER_NAME="bare-metal-sandbox-redfish"
IMAGE="quay.io/metal3-io/sushy-tools:latest"
BIND_HOST="${BMC_BIND_HOST:-127.0.0.1}"
BIND_PORT="${BMC_BIND_PORT:-8000}"

if [[ ! -f "${FIXTURES}/index.json" ]]; then
  echo "error: fixtures missing at ${FIXTURES}/index.json" >&2
  exit 1
fi

mkdir -p "${CERTS}"
if [[ ! -f "${CERTS}/cert.pem" || ! -f "${CERTS}/key.pem" ]]; then
  openssl req -x509 -newkey rsa:2048 \
    -keyout "${CERTS}/key.pem" -out "${CERTS}/cert.pem" \
    -days 3650 -nodes -subj "/CN=bare-metal-sandbox-local" 2>/dev/null
fi

if podman container exists "${CONTAINER_NAME}" 2>/dev/null; then
  if podman container inspect "${CONTAINER_NAME}" --format '{{.State.Running}}' 2>/dev/null | grep -q true; then
    echo "already running: https://${BIND_HOST}:${BIND_PORT}/redfish/v1/"
    exit 0
  fi
  podman rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  for _ in $(seq 1 10); do
    podman container exists "${CONTAINER_NAME}" 2>/dev/null || break
    sleep 1
  done
fi

podman run -d \
  --name "${CONTAINER_NAME}" \
  --replace \
  -p "${BIND_HOST}:${BIND_PORT}:8000" \
  -v "${FIXTURES}:/mockups:ro,Z" \
  -v "${CERTS}:/certs:ro,Z" \
  "${IMAGE}" \
  sushy-static -i 0.0.0.0 -p 8000 -m /mockups -c /certs/cert.pem -k /certs/key.pem

echo "static Redfish BMC: https://${BIND_HOST}:${BIND_PORT}/redfish/v1/"
echo "smoke test: ansible-playbook ${SANDBOX_ROOT}/playbooks/smoke-redfish.yml"

#!/usr/bin/env bash
# Stop static Redfish BMC emulator container.
set -euo pipefail

CONTAINER_NAME="bare-metal-sandbox-redfish"

if podman container exists "${CONTAINER_NAME}" 2>/dev/null; then
  podman rm -f "${CONTAINER_NAME}" >/dev/null
  echo "stopped ${CONTAINER_NAME}"
else
  echo "container not found: ${CONTAINER_NAME}"
fi

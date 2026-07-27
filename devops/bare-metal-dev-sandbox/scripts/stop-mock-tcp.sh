#!/usr/bin/env bash
# Stop mock TCP listeners started by mock-tcp-ports.sh
set -euo pipefail

PIDFILE="${TMPDIR:-/tmp}/bare-metal-sandbox-mock-tcp.pids"

if [[ -f "${PIDFILE}" ]]; then
  while read -r pid; do
    kill "${pid}" 2>/dev/null || true
  done < "${PIDFILE}"
  rm -f "${PIDFILE}"
  echo "stopped mock TCP listeners"
fi

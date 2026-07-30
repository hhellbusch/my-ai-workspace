#!/usr/bin/env bash
# Start background TCP listeners for mock open connections (host:port endpoints).
# Usage: mock-tcp-ports.sh 127.0.0.1:6180 127.0.0.1:9999
set -euo pipefail

PIDFILE="${TMPDIR:-/tmp}/bare-metal-sandbox-mock-tcp.pids"
: > "${PIDFILE}"

if [[ $# -eq 0 ]]; then
  exit 0
fi

for endpoint in "$@"; do
  if [[ "${endpoint}" != *:* ]]; then
    echo "error: expected host:port, got '${endpoint}'" >&2
    exit 1
  fi
  host="${endpoint%:*}"
  port="${endpoint##*:}"

  python3 -c "
import socket, threading
host, port = '${host}', ${port}
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind((host, port))
s.listen(8)

def serve():
    while True:
        conn, _ = s.accept()
        conn.close()

threading.Thread(target=serve, daemon=True).start()
import time
time.sleep(10**9)
" >/dev/null 2>&1 &
  echo $! >> "${PIDFILE}"
  echo "mock TCP open: ${host}:${port} (pid $!)"
done

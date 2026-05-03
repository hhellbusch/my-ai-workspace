#!/usr/bin/env bash
# serve-llm-https.sh — Start RamaLama + Caddy TLS reverse proxy together.
#
# Usage:
#   ./scripts/serve-llm-https.sh [MODEL] [HTTPS_PORT] [HTTP_PORT]
#
# Examples:
#   ./scripts/serve-llm-https.sh
#   ./scripts/serve-llm-https.sh ollama://qwen2.5-coder:7b
#   ./scripts/serve-llm-https.sh ollama://qwen3:30b-a3b 8443 8080
#
# Defaults:
#   MODEL       = ollama://qwen2.5-coder:latest
#   HTTPS_PORT  = 8443
#   HTTP_PORT   = 8080
#
# Environment overrides:
#   RAMALAMA_IMAGE   — OCI image for ramalama (e.g. localhost/ramalama-rocm:f44)
#   RAMALAMA_PULL    — pull policy passed to --pull (default: never)
#   LLM_CERT_DIR     — directory containing server.crt / server.key (default: ~/llm-certs)
#
# Requirements:
#   - ramalama   (sudo dnf install ramalama)
#   - caddy      (sudo dnf install caddy)
#   - TLS certs  (run scripts/gen-llm-tls-cert.sh first)
#
# The script blocks until you hit Ctrl-C, then shuts down both processes cleanly.
set -euo pipefail

MODEL="${1:-ollama://qwen2.5-coder:latest}"
HTTPS_PORT="${2:-8443}"
HTTP_PORT="${3:-8080}"

# RamaLama options — override via env for custom images or pull policies.
# RAMALAMA_IMAGE: use a locally-built image (e.g. localhost/ramalama-rocm:f44)
#                 to avoid the upstream glibc 2.43 mismatch on Fedora 43/44.
# RAMALAMA_PULL:  "never" avoids pulling a broken upstream image over your local one.
RAMALAMA_IMAGE="${RAMALAMA_IMAGE:-}"
RAMALAMA_PULL="${RAMALAMA_PULL:-never}"

# Cert paths — override via env if you put them elsewhere.
CERT_DIR="${LLM_CERT_DIR:-${HOME}/llm-certs}"
TLS_CERT="${CERT_DIR}/server.crt"
TLS_KEY="${CERT_DIR}/server.key"

# ── Preflight checks ──────────────────────────────────────────────────────────
for cmd in ramalama caddy; do
    if ! command -v "${cmd}" &>/dev/null; then
        echo "ERROR: '${cmd}' not found — install it first." >&2
        exit 1
    fi
done

if [[ ! -f "${TLS_CERT}" || ! -f "${TLS_KEY}" ]]; then
    echo "ERROR: TLS certs not found at ${CERT_DIR}/" >&2
    echo "       Run: ./scripts/gen-llm-tls-cert.sh ${CERT_DIR} $(hostname -I | awk '{print $1}')" >&2
    exit 1
fi

# ── Cleanup on exit ───────────────────────────────────────────────────────────
RAMALAMA_PID=""
CADDY_PID=""

cleanup() {
    echo "" >&2
    echo "==> Shutting down..." >&2
    if [[ -n "${CADDY_PID}" ]] && kill -0 "${CADDY_PID}" 2>/dev/null; then
        echo "    stopping caddy (pid ${CADDY_PID})" >&2
        kill "${CADDY_PID}" 2>/dev/null || true
    fi
    if [[ -n "${RAMALAMA_PID}" ]] && kill -0 "${RAMALAMA_PID}" 2>/dev/null; then
        echo "    stopping ramalama (pid ${RAMALAMA_PID})" >&2
        kill "${RAMALAMA_PID}" 2>/dev/null || true
        wait "${RAMALAMA_PID}" 2>/dev/null || true
    fi
    echo "==> Done." >&2
}
trap cleanup EXIT INT TERM

# ── Caddyfile (written to a temp file so no root needed) ─────────────────────
CADDYFILE="$(mktemp /tmp/caddy-llm-XXXXXX.caddyfile)"
cat > "${CADDYFILE}" <<EOF
{
    auto_https disable_redirects
    admin off
}
:${HTTPS_PORT} {
    tls ${TLS_CERT} ${TLS_KEY}
    reverse_proxy localhost:${HTTP_PORT}
}
EOF

# ── Start RamaLama ────────────────────────────────────────────────────────────
RAMALAMA_ARGS=(serve --pull="${RAMALAMA_PULL}" --port "${HTTP_PORT}")
if [[ -n "${RAMALAMA_IMAGE}" ]]; then
    RAMALAMA_ARGS+=(--image "${RAMALAMA_IMAGE}")
fi
RAMALAMA_ARGS+=("${MODEL}")

echo "==> Starting RamaLama: ${MODEL} on port ${HTTP_PORT}" >&2
[[ -n "${RAMALAMA_IMAGE}" ]] && echo "    image: ${RAMALAMA_IMAGE}" >&2
echo "    pull:  ${RAMALAMA_PULL}" >&2
ramalama "${RAMALAMA_ARGS[@]}" &
RAMALAMA_PID=$!

# Wait until the plain-HTTP API responds (up to 120 s)
echo -n "    Waiting for RamaLama to be ready" >&2
READY=0
for i in $(seq 1 60); do
    if curl -fsS "http://127.0.0.1:${HTTP_PORT}/v1/models" &>/dev/null; then
        READY=1
        break
    fi
    # Exit early if ramalama died
    if ! kill -0 "${RAMALAMA_PID}" 2>/dev/null; then
        echo "" >&2
        echo "ERROR: ramalama exited prematurely." >&2
        exit 1
    fi
    echo -n "." >&2
    sleep 2
done
echo "" >&2

if [[ "${READY}" -eq 0 ]]; then
    echo "ERROR: RamaLama did not become ready after 120 s." >&2
    exit 1
fi
echo "    RamaLama is ready." >&2

# ── Start Caddy ───────────────────────────────────────────────────────────────
echo "==> Starting Caddy on port ${HTTPS_PORT} (TLS termination → localhost:${HTTP_PORT})" >&2
caddy run --config "${CADDYFILE}" &
CADDY_PID=$!

sleep 1
if ! kill -0 "${CADDY_PID}" 2>/dev/null; then
    echo "ERROR: Caddy failed to start — check certs and port availability." >&2
    exit 1
fi

# ── Ready ─────────────────────────────────────────────────────────────────────
HOST_IP="$(hostname -I | awk '{print $1}')"
HOST_NAME="$(hostname -f 2>/dev/null || hostname)"
echo "" >&2
echo "  LLM endpoint (plain HTTP, host only):  http://127.0.0.1:${HTTP_PORT}/v1" >&2
echo "  LLM endpoint (HTTPS, LAN-accessible):  https://${HOST_IP}:${HTTPS_PORT}/v1" >&2
echo "  LLM endpoint (HTTPS, hostname):        https://${HOST_NAME}:${HTTPS_PORT}/v1" >&2
echo "" >&2
echo "  Set in your shell before paude create (prefer hostname for portability):" >&2
echo "    export OPENAI_BASE_URL=https://${HOST_NAME}:${HTTPS_PORT}/v1" >&2
echo "    export OPENAI_API_KEY=local-placeholder" >&2
echo "" >&2
echo "  Press Ctrl-C to stop." >&2

# Block until killed
wait "${RAMALAMA_PID}" 2>/dev/null || true

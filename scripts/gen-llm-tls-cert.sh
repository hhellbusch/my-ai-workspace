#!/usr/bin/env bash
# gen-llm-tls-cert.sh — Generate a private CA + server TLS certificate for a LAN LLM server.
#
# Usage:
#   ./scripts/gen-llm-tls-cert.sh [OUTPUT_DIR] [SAN...]
#
# Examples:
#   ./scripts/gen-llm-tls-cert.sh                          # defaults: ~/llm-certs, 10.0.0.202
#   ./scripts/gen-llm-tls-cert.sh ~/certs 10.0.0.202 llm.lan
#
# Outputs (in OUTPUT_DIR):
#   ca.crt          — CA certificate (inject into paude-proxy via --upstream-ca)
#   ca.key          — CA private key  (keep safe, not needed by paude)
#   server.crt      — Server certificate (configure nginx/caddy with this)
#   server.key      — Server private key  (configure nginx/caddy with this)
#   server.csr      — Intermediate CSR   (can be deleted after generation)
set -euo pipefail

OUT_DIR="${1:-${HOME}/llm-certs}"
shift || true

# Collect SANs from remaining args; default to 10.0.0.202
SANS=("$@")
if [[ ${#SANS[@]} -eq 0 ]]; then
    SANS=("10.0.0.202")
fi

echo "Output directory : ${OUT_DIR}"
echo "SANs             : ${SANS[*]}"
echo ""

mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

# Build the SAN extension string.  Each token is either:
#   - an IPv4/IPv6 address   → IP:x.x.x.x
#   - a hostname             → DNS:hostname
build_san_ext() {
    local san_list=""
    for token in "$@"; do
        if [[ "${token}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
           [[ "${token}" =~ ^[0-9a-fA-F:]+$ ]]; then
            san_list+="IP:${token},"
        else
            san_list+="DNS:${token},"
        fi
    done
    echo "${san_list%,}"
}

SAN_EXT=$(build_san_ext "${SANS[@]}")

# ── 1. Private CA ─────────────────────────────────────────────────────────────
echo "==> Generating private CA..."
openssl req -x509 -newkey rsa:4096 \
    -keyout ca.key -out ca.crt \
    -days 3650 -nodes \
    -subj "/CN=LLM LAN CA/O=paude/OU=local"

# ── 2. Server key + CSR ───────────────────────────────────────────────────────
echo "==> Generating server key and CSR..."
openssl req -newkey rsa:2048 \
    -keyout server.key -out server.csr \
    -nodes \
    -subj "/CN=${SANS[0]}/O=paude/OU=llm-server"

# ── 3. Sign server cert with our CA ───────────────────────────────────────────
echo "==> Signing server certificate (SANs: ${SAN_EXT})..."
openssl x509 -req \
    -in server.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out server.crt \
    -days 825 \
    -extfile <(printf "subjectAltName=%s\nextendedKeyUsage=serverAuth\n" "${SAN_EXT}")

chmod 600 ca.key server.key

echo ""
echo "Done.  Files written to ${OUT_DIR}/:"
ls -1 "${OUT_DIR}"
echo ""
echo "Next steps:"
echo "  1. Configure nginx/caddy to serve TLS with server.crt + server.key"
echo "     (see docs/ai-engineering/local-llm-setup.md for a ready-to-use Caddyfile)"
echo ""
echo "  2. Update OPENAI_BASE_URL to use https://<host>:8443/v1"
echo ""
echo "  3. Create a paude session and trust the CA:"
echo "     export OPENAI_BASE_URL=https://${SANS[0]}:8443/v1"
echo "     export OPENAI_API_KEY=local-placeholder"
echo "     paude create --provider openai --upstream-ca ${OUT_DIR}/ca.crt"

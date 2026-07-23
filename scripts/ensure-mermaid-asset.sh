#!/usr/bin/env bash
# Vendor mermaid.min.js locally so builds do not fetch from unpkg at build time.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/docs-site/assets/mermaid/mermaid.min.js"
URL="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"

if [ -f "$DEST" ]; then
  exit 0
fi

mkdir -p "$(dirname "$DEST")"
echo "Fetching mermaid.min.js (one-time)…"
curl -fsSL "$URL" -o "$DEST"
echo "Wrote ${DEST#$ROOT/}"

#!/usr/bin/env bash
# Refresh site-staging then run mkdocs serve. Use this instead of raw mkdocs serve.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash scripts/stage-docs.sh
echo ""
echo "Starting dev server at http://127.0.0.1:8000 (Ctrl+C to stop)"
echo "  Interactive PoC: http://127.0.0.1:8000/interactive-poc/"
exec mkdocs serve -f mkdocs.effective.yml "$@"

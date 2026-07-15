#!/usr/bin/env bash
# Stage content, generate nav, build static site to site/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash scripts/stage-docs.sh
mkdocs build -f mkdocs.effective.yml "$@"
echo ""
echo "Build complete → site/"
echo "  Preview: bash scripts/serve-docs.sh"
echo "  Note: link checks ignore yaml/sh/library targets (markdown-only site; use GitHub for those)."

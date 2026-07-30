#!/usr/bin/env bash
# Stage markdown and assets into site-staging/, generate nav config.
# Used by build-docs.sh and serve-docs.sh — do not run mkdocs against stale staging.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash scripts/ensure-mermaid-asset.sh
python3 scripts/generate-symptom-index.py
python3 scripts/generate-example-index.py
python3 scripts/export-catalog-json.py
python3 scripts/stage-mkdocs.py
python3 scripts/generate-mkdocs-nav.py

python3 - <<'PY'
from pathlib import Path
import yaml

root = Path(".")
base = yaml.unsafe_load((root / "mkdocs.yml").read_text())
nav = yaml.safe_load((root / "mkdocs.nav.yml").read_text())
base["nav"] = nav
(root / "mkdocs.effective.yml").write_text(yaml.dump(base, sort_keys=False, allow_unicode=True))
print("Wrote mkdocs.effective.yml")
PY

echo "Staged $(find site-staging -name '*.md' | wc -l) markdown files under site-staging/"

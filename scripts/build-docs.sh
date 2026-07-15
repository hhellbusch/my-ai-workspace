#!/usr/bin/env bash
# Stage content, generate nav and symptom index, merge nav into mkdocs build.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 scripts/generate-symptom-index.py
python3 scripts/stage-mkdocs.py
python3 scripts/generate-mkdocs-nav.py

# Merge generated nav into effective mkdocs config
python3 - <<'PY'
from pathlib import Path
import yaml

root = Path(".")
base = yaml.safe_load((root / "mkdocs.yml").read_text())
nav = yaml.safe_load((root / "mkdocs.nav.yml").read_text())
base["nav"] = nav
(root / "mkdocs.effective.yml").write_text(yaml.dump(base, sort_keys=False, allow_unicode=True))
print("Wrote mkdocs.effective.yml")
PY

mkdocs build -f mkdocs.effective.yml "$@"

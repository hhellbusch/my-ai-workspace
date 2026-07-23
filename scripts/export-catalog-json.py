#!/usr/bin/env python3
"""Export devops/catalog.yaml to JSON for client-side interactive demos."""

from __future__ import annotations

import json
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "devops" / "catalog.yaml"
OUT_DIR = ROOT / "docs-site" / "assets" / "poc"


def main() -> None:
    data = yaml.safe_load(CATALOG.read_text())
    guides = []
    for g in data.get("guides", []):
        rel = g["path"].removeprefix("devops/")
        guides.append(
            {
                "id": g["id"],
                "title": g["title"],
                "category": g.get("category", "other"),
                "product": g.get("product", "other"),
                "symptoms": g.get("symptoms", []),
                "tags": g.get("tags", []),
                "readme": f"{rel}/README.md",
                "quickRef": f"{rel}/{g['quick_ref']}" if g.get("quick_ref") else None,
            }
        )

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / "catalog.json"
    out.write_text(json.dumps({"guides": guides}, indent=2) + "\n")
    print(f"Wrote {out.relative_to(ROOT)} ({len(guides)} guides)")


if __name__ == "__main__":
    main()

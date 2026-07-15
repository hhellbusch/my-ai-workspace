#!/usr/bin/env python3
"""Generate devops/SYMPTOM-INDEX.md from devops/catalog.yaml."""

from __future__ import annotations

import datetime
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "devops" / "catalog.yaml"
OUTPUT = ROOT / "devops" / "SYMPTOM-INDEX.md"


def main() -> None:
    data = yaml.safe_load(CATALOG.read_text())
    guides = data.get("guides", [])

    lines = [
        "# DevOps Symptom Index",
        "",
        "Machine-generated lookup table: symptom string → troubleshooting guide.",
        f"Source: [`catalog.yaml`](catalog.yaml). Regenerate: `python3 scripts/generate-symptom-index.py`.",
        "",
        f"*Generated {datetime.date.today().isoformat()}.*",
        "",
        "| Symptom / keyword | Guide | Quick ref |",
        "|-------------------|-------|-----------|",
    ]

    for guide in sorted(guides, key=lambda g: (g.get("category", ""), g.get("title", ""))):
        title = guide["title"]
        rel = guide["path"].removeprefix("devops/")
        readme = f"{rel}/README.md"
        quick = guide.get("quick_ref")
        quick_link = f"[⚡]({rel}/{quick})" if quick else "—"
        for symptom in guide.get("symptoms", []):
            lines.append(f"| {symptom} | [{title}]({readme}) | {quick_link} |")

    lines.extend(
        [
            "",
            "## By category",
            "",
        ]
    )

    by_category: dict[str, list] = {}
    for guide in guides:
        by_category.setdefault(guide.get("category", "other"), []).append(guide)

    for category in sorted(by_category):
        lines.append(f"### {category.replace('-', ' ').title()}")
        lines.append("")
        for guide in sorted(by_category[category], key=lambda g: g["title"]):
            rel = guide["path"].removeprefix("devops/")
            readme = f"{rel}/README.md"
            tags = ", ".join(f"`{t}`" for t in guide.get("tags", []))
            lines.append(f"- [{guide['title']}]({readme}) — {tags}")
        lines.append("")

    OUTPUT.write_text("\n".join(lines) + "\n")
    print(f"Wrote {OUTPUT.relative_to(ROOT)} ({len(guides)} guides)")


if __name__ == "__main__":
    main()

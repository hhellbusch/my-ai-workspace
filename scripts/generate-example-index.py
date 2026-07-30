#!/usr/bin/env python3
"""Generate devops/EXAMPLE-INDEX.md from devops/catalog.yaml examples section."""

from __future__ import annotations

import datetime
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "devops" / "catalog.yaml"
OUTPUT = ROOT / "devops" / "EXAMPLE-INDEX.md"


def catalog_doc_path(catalog_path: str) -> str:
    rel = catalog_path.removeprefix("devops/")
    if rel.endswith(".md"):
        return rel
    return f"{rel}/README.md"


def main() -> None:
    data = yaml.safe_load(CATALOG.read_text())
    examples = data.get("examples", [])

    lines = [
        "# DevOps Example Index",
        "",
        "Machine-generated lookup table: intent / keyword → runnable OCP example.",
        "Source: `devops/catalog.yaml` (`examples:`). Regenerate: `python3 scripts/generate-example-index.py`.",
        "",
        f"*Generated {datetime.date.today().isoformat()}.*",
        "",
        "| Intent / keyword | Example | Topic | Operators |",
        "|------------------|---------|-------|-----------|",
    ]

    for example in sorted(examples, key=lambda e: e.get("title", "")):
        title = example["title"]
        rel = example["path"].removeprefix("devops/")
        readme = catalog_doc_path(example["path"])
        topic = example.get("topic", "—")
        operators = ", ".join(example.get("operators", [])) or "—"
        for intent in example.get("intents", []):
            lines.append(f"| {intent} | [{title}]({readme}) | `{topic}` | {operators} |")

    lines.extend(["", "## By topic", ""])

    by_topic: dict[str, list] = {}
    for example in examples:
        by_topic.setdefault(example.get("topic", "other"), []).append(example)

    for topic in sorted(by_topic):
        lines.append(f"### {topic}")
        lines.append("")
        for example in sorted(by_topic[topic], key=lambda e: e["title"]):
            readme = catalog_doc_path(example["path"])
            tags = ", ".join(f"`{t}`" for t in example.get("tags", []))
            lines.append(f"- [{example['title']}]({readme}) — {tags}")
            for note in example.get("companion_notes", []):
                note_rel = note.removeprefix("devops/")
                note_name = Path(note_rel).stem.replace("-", " ").title()
                lines.append(f"  - Companion: [{note_name}]({note_rel})")
        lines.append("")

    OUTPUT.write_text("\n".join(lines) + "\n")
    print(f"Wrote {OUTPUT.relative_to(ROOT)} ({len(examples)} examples)")


if __name__ == "__main__":
    main()

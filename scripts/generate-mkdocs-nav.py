#!/usr/bin/env python3
"""Generate mkdocs nav YAML and write mkdocs.nav.yml for inclusion."""

from __future__ import annotations

from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "devops" / "catalog.yaml"
NAV_OUT = ROOT / "mkdocs.nav.yml"


def category_label(category: str) -> str:
    return category.replace("-", " ").title()


def main() -> None:
    data = yaml.safe_load(CATALOG.read_text())
    guides = data.get("guides", [])

    by_product: dict[str, dict[str, list]] = {}
    for guide in guides:
        product = guide.get("product", "other")
        category = guide.get("category", "other")
        by_product.setdefault(product, {}).setdefault(category, []).append(guide)

    devops_nav: list = [
        {"DevOps hub": "devops/README.md"},
        {"Organization": "devops/ORGANIZATION.md"},
        {"Symptom index": "devops/SYMPTOM-INDEX.md"},
    ]

    for product in sorted(by_product):
        product_label = product.upper() if product == "ocp" else product.title()
        categories: list = []
        for category in sorted(by_product[product]):
            items = [
                {g["title"]: f"{g['path']}/README.md"}
                for g in sorted(by_product[product][category], key=lambda x: x["title"])
            ]
            categories.append({category_label(category): items})
        devops_nav.append({f"{product_label} troubleshooting": categories})

    devops_nav.append({
        "OCP examples": [
            {"Examples index": "devops/ocp/examples/README.md"},
            {"Bare metal": "devops/ocp/examples/bare-metal/README.md"},
            {"Messaging": "devops/ocp/examples/messaging/README.md"},
            {"Kafka": "devops/ocp/examples/messaging/kafka/README.md"},
            {"Networking": "devops/ocp/examples/networking/README.md"},
            {"Labs": "devops/ocp/examples/labs/README.md"},
        ]
    })

    docs_nav: list = [{"Docs catalogue": "docs/README.md"}]
    for track, label in (
        ("ai-engineering", "AI Engineering"),
        ("philosophy", "Philosophy"),
        ("case-studies", "Case Studies"),
    ):
        track_dir = ROOT / "docs" / track
        items = [{"Track index": f"docs/{track}/README.md"}]
        if track_dir.is_dir():
            for essay in sorted(track_dir.glob("*.md")):
                if essay.name == "README.md":
                    continue
                title = essay.stem.replace("-", " ").title()
                items.append({title: f"docs/{track}/{essay.name}"})
        docs_nav.append({label: items})

    nav = [
        {"Home": "index.md"},
        {"Interactive PoC": "interactive-poc.md"},
        {"DevOps Reference": devops_nav},
        {"Essays": docs_nav},
    ]

    NAV_OUT.write_text(yaml.dump(nav, sort_keys=False, allow_unicode=True))
    print(f"Wrote {NAV_OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

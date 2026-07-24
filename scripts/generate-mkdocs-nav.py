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


def catalog_doc_path(catalog_path: str) -> str:
    if catalog_path.endswith(".md"):
        return catalog_path
    return f"{catalog_path}/README.md"


def build_troubleshooting_nav(guides: list) -> list:
    by_product: dict[str, dict[str, list]] = {}
    for guide in guides:
        product = guide.get("product", "other")
        category = guide.get("category", "other")
        by_product.setdefault(product, {}).setdefault(category, []).append(guide)

    nav: list = []
    for product in sorted(by_product):
        product_label = product.upper() if product == "ocp" else product.title()
        categories: list = []
        for category in sorted(by_product[product]):
            items = [
                {g["title"]: catalog_doc_path(g["path"])}
                for g in sorted(by_product[product][category], key=lambda x: x["title"])
            ]
            categories.append({category_label(category): items})
        nav.append({f"{product_label} troubleshooting": categories})
    return nav


def build_examples_nav(examples: list) -> list:
    ocp_examples = [e for e in examples if e.get("product", "ocp") == "ocp"]
    nav: list = [{"Examples index": "devops/ocp/examples/README.md"}]

    bare_metal = sorted(
        (e for e in ocp_examples if e.get("topic") == "bare-metal"),
        key=lambda x: x["title"],
    )
    if bare_metal:
        items: list = [{"Bare metal index": "devops/ocp/examples/bare-metal/README.md"}]
        items.extend({e["title"]: catalog_doc_path(e["path"])} for e in bare_metal)
        nav.append({"Bare metal": items})

    kafka = sorted(
        (e for e in ocp_examples if e.get("topic") == "messaging/kafka"),
        key=lambda x: x["title"],
    )
    if kafka:
        kafka_items: list = [
            {"Kafka index": "devops/ocp/examples/messaging/kafka/README.md"},
        ]
        kafka_items.extend({e["title"]: catalog_doc_path(e["path"])} for e in kafka)
        nav.append({
            "Messaging": [
                {"Messaging index": "devops/ocp/examples/messaging/README.md"},
                {"Kafka": kafka_items},
            ]
        })

    networking = sorted(
        (e for e in ocp_examples if e.get("topic") == "networking"),
        key=lambda x: x["title"],
    )
    if networking:
        items = [{"Networking index": "devops/ocp/examples/networking/README.md"}]
        items.extend({e["title"]: catalog_doc_path(e["path"])} for e in networking)
        nav.append({"Networking": items})

    labs = sorted(
        (e for e in ocp_examples if e.get("topic") == "labs"),
        key=lambda x: x["title"],
    )
    if labs:
        items = [{"Labs index": "devops/ocp/examples/labs/README.md"}]
        items.extend({e["title"]: catalog_doc_path(e["path"])} for e in labs)
        nav.append({"Labs": items})

    return nav


def build_ocp_notes_nav() -> list:
    notes_dir = ROOT / "devops" / "ocp" / "notes"
    items: list = [{"Notes index": "devops/ocp/notes/README.md"}]
    if notes_dir.is_dir():
        for note in sorted(notes_dir.glob("*.md")):
            if note.name == "README.md":
                continue
            title = note.stem.replace("-", " ").title()
            items.append({title: f"devops/ocp/notes/{note.name}"})
    return items


def main() -> None:
    data = yaml.safe_load(CATALOG.read_text())
    guides = data.get("guides", [])
    examples = data.get("examples", [])

    devops_nav: list = [
        {"DevOps hub": "devops/README.md"},
        {"Organization": "devops/ORGANIZATION.md"},
        {"Symptom index": "devops/SYMPTOM-INDEX.md"},
        {"Example index": "devops/EXAMPLE-INDEX.md"},
        {"Fleet control spectrum": "devops/fleet-control-spectrum.md"},
    ]

    devops_nav.append({
        "Learning paths": [
            {"Learning paths index": "devops/learning-path/README.md"},
            {"VMware admins": "devops/learning-path/vmware-admins/README.md"},
            {"Git curriculum": "devops/learning-path/git/README.md"},
        ]
    })

    devops_nav.append({
        "Pedagogy and setup": [
            {"Git learning guide": "devops/git/git-learning-guide.md"},
            {"KVM on Fedora": "devops/kvm/README.md"},
            {"Local LLM setup": "devops/llm/README.md"},
        ]
    })

    devops_nav.extend(build_troubleshooting_nav(guides))

    devops_nav.append({
        "OpenShift": [
            {"OCP hub": "devops/ocp/README.md"},
            {"Disconnected install": "devops/ocp/disconnected-install/README.md"},
            {"IBM Z": "devops/ocp/ibm-z/README.md"},
            {"GPU artifacts": "devops/ocp/gpu/README.md"},
        ]
    })

    devops_nav.append({"OCP examples": build_examples_nav(examples)})
    devops_nav.append({"OCP notes": build_ocp_notes_nav()})

    devops_nav.append({
        "Products": [
            {"RHACM": "devops/rhacm/README.md"},
            {"Ansible": "devops/ansible/README.md"},
            {"Argo CD": "devops/argo/README.md"},
            {"CoreOS": "devops/coreos/README.md"},
            {"Vault": "devops/vault/README.md"},
        ]
    })

    devops_nav.append({
        "Workspace tooling": [
            {"Pi": "devops/pi/README.md"},
            {"Paude": "devops/paude/README.md"},
            {"Paude proxy": "devops/paude-proxy/README.md"},
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

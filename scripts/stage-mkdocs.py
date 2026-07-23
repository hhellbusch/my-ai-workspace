#!/usr/bin/env python3
"""Stage devops/ and docs/ markdown into site-staging/ for MkDocs build."""

from __future__ import annotations

import os
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGING = ROOT / "site-staging"
SKIP_DIR_NAMES = {"_meta", "install", ".git"}


def should_skip(path: Path) -> bool:
    parts = path.parts
    if any(part in SKIP_DIR_NAMES for part in parts):
        return True
    if "research" in parts and "sources" in parts:
        return True
    return False


def stage_tree(src: Path, dest_prefix: Path) -> None:
    for root, dirs, files in os.walk(src):
        root_path = Path(root)
        if should_skip(root_path):
            dirs.clear()
            continue
        dirs[:] = [d for d in dirs if d not in SKIP_DIR_NAMES]
        rel = root_path.relative_to(src)
        for name in files:
            if not name.endswith(".md"):
                continue
            src_file = root_path / name
            if should_skip(src_file):
                continue
            dest = dest_prefix / rel / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src_file, dest)


def stage_docs_site() -> None:
    """Copy docs-site/ markdown and static assets into site-staging/."""
    src = ROOT / "docs-site"
    if not src.is_dir():
        return
    for md in src.glob("*.md"):
        if md.name == "README.md":
            continue  # avoid site-staging/README.md conflicting with index.md
        shutil.copy2(md, STAGING / md.name)
    assets = src / "assets"
    if assets.is_dir():
        shutil.copytree(assets, STAGING / "assets", dirs_exist_ok=True)


def stage_auxiliary() -> None:
    """Copy small non-markdown files that markdown pages link to."""
    disclosure = ROOT / "AI-DISCLOSURE.md"
    if disclosure.is_file():
        shutil.copy2(disclosure, STAGING / "AI-DISCLOSURE.md")
    catalog = ROOT / "devops" / "catalog.yaml"
    if catalog.is_file():
        dest = STAGING / "devops" / "catalog.yaml"
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(catalog, dest)


def write_index() -> None:
    index = STAGING / "index.md"
    index.write_text(
        """# Field Notes — Technical Reference

Browse **DevOps** runnable guides and **Docs** essays from the sidebar.

- [DevOps hub](devops/README.md) — troubleshooting, examples, labs
- [Symptom index](devops/SYMPTOM-INDEX.md) — lookup by error or symptom
- [Docs catalogue](docs/README.md) — essays and case studies
- [Interactive PoC](interactive-poc.md) — custom JS/CSS, Mermaid, tabs demo

*Markdown source lives in `devops/` and `docs/` at repo root; this site is generated.*
"""
    )


def main() -> None:
    if STAGING.exists():
        shutil.rmtree(STAGING)
    STAGING.mkdir(parents=True)

    write_index()
    stage_tree(ROOT / "devops", STAGING / "devops")
    stage_tree(ROOT / "docs", STAGING / "docs")
    stage_docs_site()
    stage_auxiliary()

    print(f"Staged markdown under {STAGING.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()

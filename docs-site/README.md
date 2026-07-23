# docs-site — MkDocs extensions (not main content trees)

Pages and static assets staged into `site-staging/` by `scripts/stage-mkdocs.py`.

| Path | Purpose |
|------|---------|
| [`interactive-poc.md`](interactive-poc.md) | Demo: custom JS/CSS, Mermaid, tabs, symptom picker |
| [`assets/poc/`](assets/poc/) | Widget CSS/JS; `catalog.json` generated at build time |

**Preview:** `pip install -r requirements-docs.txt && bash scripts/serve-docs.sh` → open **Interactive PoC** in the sidebar.

**Do not run** `mkdocs serve -f mkdocs.effective.yml` directly — it uses `site-staging/` which must be refreshed first via `scripts/stage-docs.sh` or `scripts/serve-docs.sh`.

**Build noise:** `mkdocs.yml` sets `validation.links` to `ignore` because the site stages markdown only — links to `.yaml`, `.sh`, and `library/` are valid on GitHub but not in the site tree. Mermaid JS is vendored on first build via `scripts/ensure-mermaid-asset.sh`.

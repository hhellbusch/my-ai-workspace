# Presentations

Slide decks for sharing workspace concepts with peers. Source format is [Marp](https://marp.app/) (Markdown → PDF/PPTX/HTML).

## Decks

| File | Audience | Notes |
|---|---|---|
| [field-notes-for-peers.md](field-notes-for-peers.md) | Learners & peers | Master learning path: five acts (agents → memory → PKM → discipline → Field Notes) + appendix |

Capture notes and iteration checklist: [`.planning/field-notes-peer-deck/NOTES.md`](../.planning/field-notes-peer-deck/NOTES.md)

## Slide discipline

Slide decks in this folder follow **[SLIDE-RULES.md](SLIDE-RULES.md)** — one primary block per slide, split-not-shrink, PDF export check after edits.

Agents editing decks: [`.cursor/rules/presentations.mdc`](../.cursor/rules/presentations.mdc).

## Export

Install the Marp CLI (`npm install -g @marp-team/marp-cli`), then from this directory:

```bash
marp field-notes-for-peers.md --pdf
marp field-notes-for-peers.md --pptx
marp field-notes-for-peers.md -o field-notes-for-peers.html
```

VS Code/Cursor: install the **Marp for VS Code** extension for live preview and export from the editor.

## Themes

**Default for decks in this folder:** built-in dark mode — no custom CSS required.

```yaml
---
marp: true
theme: gaia
class: invert
---
```

Marp ships three base themes: `default`, `gaia`, `uncover`. The `invert` class flips **Gaia** or **Uncover** to a dark variant. Gaia is the usual choice for readable body text and tables.

| Mode | Frontmatter |
|---|---|
| Dark (default here) | `theme: gaia` + `class: invert` |
| Light | `theme: gaia` (omit `class`) |
| Alternative dark | `theme: uncover` + `class: invert` |

### Custom theme (optional)

For a branded palette, see [themes/field-notes-dark.css](themes/field-notes-dark.css). Register in [`.vscode/settings.json`](../.vscode/settings.json) and export with:

```bash
marp --theme-set themes/field-notes-dark.css field-notes-for-peers.md --pdf
```

## Speaker notes

HTML comments (`<!-- ... -->`) in each slide file are speaker notes — visible in Marp presenter mode, omitted from PDF unless configured otherwise.

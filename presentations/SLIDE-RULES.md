# Slide rules — overflow cheat-sheet

> Scope: `presentations/*.md` · theme `gaia` + `class: invert` · 16:9
> Rule: split slides to preserve ideas; never shrink concepts to fit.

---

## One-slide budget

| Primary block (pick one) | Hard limit |
|---|---|
| Bullet list | **4 items** · ~12 words each |
| Numbered list | **4 items** (5 for section overview slides) |
| Table | **3 data rows** + header · **3 columns** max |
| Blockquote | **1** · 2 lines max |
| Code / ASCII diagram | **5 lines** max |
| Lead slide | `#` title + one `###` subtitle · no body lists |

Plus **≤ 2 supporting lines** (tagline, citation, one-liner). No stacking blocks.

---

## Appendix slides

**2 entries per slide** — bold path + one-line *why* (≤ 20 words). More → new slide with same name + `(continued)`.

---

## Anti-patterns

| Pattern | Fix |
|---|---|
| **Missing `---` between slides** | Next `##` merges into previous — silent overflow |
| Standalone bold intro line before the list | Drop it; the `##` heading already names the topic |
| 5+ bullets after a table | Split: table slide 1, bullets slide 2 |
| 4+ appendix entries on one slide | 2 per slide |
| Long `docs/foo/bar/baz.md` in body text | `baz.md` on slide; full path in speaker notes |
| Preamble paragraph before primary block | Move to speaker notes |

---

## Verification

```bash
marp presentations/<deck>.md --pdf -o /tmp/check.pdf
```

Scroll every slide in Marp preview at 100%. Any clip at edge → split, re-export.

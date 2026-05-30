# Marp slide rules — keep decks export-safe

> **Scope:** `presentations/*.md` · default theme `gaia` + `class: invert` · size `16:9`
> **Goal:** One idea per slide, readable in PDF export — not cramming essay text onto pixels.

These rules come from repeated overflow on `field-notes-for-peers.md` (passes 6–9). **Split slides** to preserve ideas; don't shrink concepts to fit.

---

## The one-slide budget

Each content slide (`##` heading) gets **one primary visual block** plus **at most two** supporting lines.

| Primary block (pick one) | Hard limit |
|---|---|
| Bullet list | **4 items** · one short clause each (~12 words) |
| Numbered list | **4 items** (same) |
| Table | **3 data rows** + header · **3 columns** max |
| Blockquote | **1** · 2 lines max |
| Code / ASCII diagram | **5 lines** max |
| Lead slide (`<!-- _class: lead -->`) | `#` title + **one** `###` subtitle · no body lists |

**Never stack** on one slide: table + bullets, diagram + paragraph + citation, blockquote + 4 bullets + footer link.

**Citation footer** counts as one supporting line. Use filename only on-slide; full path in speaker notes.

---

## When content exceeds the budget

1. **Split** — `Title` / `Title (continued)` or `Title — diagram`
2. **Speaker notes** — qualifications, long paths, second examples, overflow from spar review
3. **Appendix** — reading-map entries, repo file lists, “go deeper” links

Do **not** solve overflow by shrinking font (no custom CSS hacks) or deleting the idea.

---

## Tables

- Prefer bullets when comparing 2 things side-by-side in prose works.
- Wide cells → split row across slides or drop a column (move detail to notes).
- **4-column tables** (e.g. Kind | Question | Examples | Today) → always split or reduce to 3 columns.

---

## Appendix / reading-map slides

- **2 entries per slide** — each entry = **bold path** + one-line *why* (≤ 20 words).
- More entries → new slide with same section name + `(continued)`.

---

## Act / section structure

- **Act divider:** lead slide only (`# Act N` + `###` subtitle).
- **Arc overview slide:** max **5** numbered acts · shorten act blurbs to ~8 words.
- **Through-line / tagline:** one line at bottom, not a sixth block.

---

## Speaker notes (`<!-- ... -->`)

Default home for:

- Qualifications (“not universal when…”)
- Full `docs/...` paths when slide shows filename only
- Second examples, spar/shoshin detail, live-demo script
- Overflow from editorial review

Notes don't appear in default PDF export — **the slide must stand alone** for the audience.

---

## Verification (required after edits)

1. **Marp preview** at 100% in VS Code/Cursor — scroll every slide.
2. **PDF export** before presenting or sharing:
   ```bash
   marp presentations/<deck>.md --pdf -o /tmp/check.pdf
   ```
3. Flag any clip at bottom or right edge → split that slide, re-export.

---

## Anti-patterns (seen in this repo)

| Pattern | Fix |
|---|---|
| **Missing `---` between slides** | Next `##` merges into previous slide — silent overflow |
| 5+ bullets after a table | Split; table on slide 1, top 3 bullets on slide 2 |
| Trust-but-verify + agreement bias + frictionless + 2 essay links | 2 slides minimum |
| ASCII diagram + 2 definitions + promotion rule + library link | Diagram slide + one bullet slide |
| 7 repo directory bullets | Split core / extended |
| 4+ appendix entries | 2 per slide |
| Long `docs/foo/bar/baz.md` in body text | `baz.md` on slide; full path in notes |

---

## Relationship to deck content

- **Main deck** = teach one layer of the arc per slide.
- **Appendix** = syllabus with *why read* — not a dump of every link from the talk.
- **Master learning decks** stay long by **slide count**, not **slide density**.

See also: [`.planning/field-notes-peer-deck/NOTES.md`](../.planning/field-notes-peer-deck/NOTES.md) for deck-specific iteration history.

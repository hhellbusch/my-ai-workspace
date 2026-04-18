# Personal Reference Library

A persistent collection of books, talks, articles, videos, and other sources that inform thinking across projects. Each entry combines personal notes with AI-enriched context (cached summaries, reviews, key themes) so any future session can draw from the source without re-explaining it.

## How It Works

- **Catalog**: [`catalog.md`](catalog.md) is the master table of all references with basic metadata (50+ entries covering books, courses, and training from 2010–present).
- **Enriched entries**: References that need deep context for active projects get their own file with AI-researched summaries, key themes, and cached sources.
- **Adding references**: Use `/reference add <title>` for enriched entries, or add rows directly to `catalog.md` for quick logging.
- **Connecting to projects**: Project-specific reading lists (like `research/zen-karate-philosophy/curated-reading.md`) link to enriched entries rather than duplicating context.
- **Searching**: Use `/reference search <term>` to find references by keyword across both the catalog and enriched entries.

## Enriched Entries

These references have deep AI-researched context (summaries, key themes, notable ideas, cached sources):

| Entry | Type | Tags | Added |
|---|---|---|---|
| [The Zen Way to Martial Arts](zen-way-martial-arts.md) | Book | zen, karate, martial-arts, philosophy | 2026-04-17 |
| [Karate by Jesse (Jesse Enkamp)](karate-by-jesse.md) | Website | karate, okinawa, history, bunkai, shito-ryu | 2026-04-17 |
| [Finding Karate](finding-karate.md) | Book | karate, philosophy, training | 2026-04-17 |
| [Karate Philosophy](karate-philosophy.md) | Book | karate, philosophy, dojo-kun | 2026-04-17 |
| [Simple Lucas](simple-lucas.md) | YouTube | productivity, single-tasking, zen-parallels | 2026-04-17 |
| [Rian Doris / FlowState](rian-doris.md) | YouTube | neuroscience, flow, dopamine, focus | 2026-04-17 |
| [3Blue1Brown — Deep Learning Series](3blue1brown.md) | YouTube | ai, neural-networks, deep-learning, transformers, llm | 2026-04-17 |

See [`catalog.md`](catalog.md) for the complete reference list (50+ books, courses, and training).

## Entry Template

Each entry follows this structure:

```markdown
# [Title]

## Metadata
- **Author:**
- **Type:** Book / Talk / Article / Video / Course / Website
- **Published:**
- **URL:** (if available online)
- **Tags:**
- **Added:** YYYY-MM-DD
- **Projects:** (which workspace projects reference this)

## Why This Matters (personal)
[Your notes on why this source is significant to you]

## Key Themes (AI-enriched)
[AI-researched summary of major themes, drawn from reviews and analyses]

## Notable Ideas
[Specific concepts, quotes, or frameworks worth referencing]

## Sources
[URLs of reviews, summaries, or analyses that were used for enrichment]
```

## Related

- [`research/`](../research/) — Project-specific research workspaces
- [`.planning/`](../.planning/) — Project briefs and roadmaps that may reference library entries
- [`docs/`](../docs/) — Published essays that draw from these sources

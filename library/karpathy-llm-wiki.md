# Andrej Karpathy — LLM Wiki (GitHub Gist)

## Metadata
- **Author:** Andrej Karpathy
- **Type:** Technical Gist / Concept
- **Published:** ~2024
- **URL:** https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- **Tags:** ai-engineering, memory, llm-wiki, knowledge-base, persistent-context, schema, ingest
- **Added:** 2026-04-30
- **Wing:** ai-engineering / memory
- **Projects:** paude-integration, workspace-organization

## Why This Matters (personal)

Directly challenged a lazy assumption: that a flat directory of research notes is a knowledge base. It isn't — it's a pile of drawers. A real wiki requires an LLM-maintained synthesis layer on top of the raw sources, governed by a schema that tells the LLM what to track, how to link entries, and how to lint for drift.

The gist arrived at the right moment — mid-conversation about why research kept feeling unconnected to active work. The answer was structural: raw sources were accumulating without a synthesis step.

## Key Themes (AI-enriched)

### Three-Layer Architecture

```
raw-sources/      ← verbatim captures (transcripts, articles, notes)
wiki/             ← LLM-maintained markdown synthesis (the "wiki layer")
schema/           ← rules the LLM follows when reading and writing the wiki
```

Each layer has a distinct role:
- **Raw sources** = append-only, never modified after ingest
- **Wiki** = incrementally updated, interlinked, queryable — not a dump, a synthesis
- **Schema** = the behavioral contract for the wiki-agent: what sections are required, what links must exist, what to do on ingest

### Core Operations

| Operation | What happens |
|-----------|-------------|
| **ingest** | New raw source → LLM reads schema + existing wiki → updates relevant pages, creates new stubs |
| **query** | User asks question → LLM queries wiki pages, not raw sources |
| **lint** | Periodic job: LLM audits wiki against schema, flags broken links, stale pages, missing cross-references |

### Why Not Just RAG?

RAG retrieves chunks from raw sources. The LLM Wiki pattern maintains a *synthesized* layer — distilled, cross-linked, and governed by schema. Queries hit the wiki, not the pile. The difference is the difference between a library card catalog and a Wikipedia.

### Schema as the Key Innovation

The schema is what separates this from a folder of markdown. It encodes:
- What every page should contain
- How entries should link to other entries
- When a page becomes "stale" and needs updating
- What tags and frontmatter are required

Without the schema, the LLM drifts — it forgets to cross-link, creates duplicate entries, or loses the structure over time.

## Notable Ideas

- **"The wiki is the product, not the notes"** — raw sources are inputs; wiki pages are the persistent artifact.
- **LLM as janitor, not just author** — the lint operation (LLM checking the wiki against its own schema) is underutilized but powerful. It catches drift before it compounds.
- **Schema-first workflow** — don't start collecting notes; start by writing the schema. What do you want the wiki to know about each topic? Only then ingest.
- **Obsidian as the rendering layer** — Karpathy suggests Obsidian as an IDE for the wiki (bidirectional links, graph view), with the LLM maintaining the `.md` files and Obsidian providing the UI.

## How This Maps to This Workspace

| LLM Wiki Layer | This Workspace |
|---------------|----------------|
| `raw-sources/` | `research/*/sources/` — verbatim transcripts and fetched articles |
| `wiki/` | `library/` — enriched entries; the synthesized layer |
| `schema/` | `CLAUDE.md` cross-linking rules + library entry template + `library/log.md` |
| `ingest` operation | `/reference add` + gather-sources workflow |
| `lint` operation | `/audit` command (partial; schema linting not yet explicit) |

**Gap identified (2026-04-30):** The workspace had the raw sources layer and wiki layer, but the schema layer was implicit. The entry template in `library/README.md` and the cross-linking rules in `CLAUDE.md` are the schema — they needed to be made explicit and enforced at workflow phase-boundaries.

## Sources

- Gist: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- Related: [Simon Scrapes — Claude Code Memory Systems](simon-scrapes-claude-code-memory-systems.md) (Level 5: Knowledge Base tier)
- Related: [Andrej Karpathy — Vibe Coding to Agentic Engineering](andrej-karpathy-vibe-coding-to-agentic-engineering.md)

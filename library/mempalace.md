# MemPalace — Local-first AI memory

## Metadata
- **Author:** MemPalace (open-source project)
- **Type:** Open-source Tool / Architecture Reference
- **Published:** Active (latest release v3.3.3, April 2026)
- **URL:** https://github.com/mempalace/mempalace
- **Tags:** ai-engineering, memory, verbatim-storage, semantic-search, chromadb, mcp, wings-rooms-drawers, local-first, agent-memory
- **Added:** 2026-04-30
- **Wing:** ai-engineering / memory
- **Projects:** paude-integration, workspace-organization

## Why This Matters (personal)

The wings/rooms/drawers vocabulary gave a name to a pattern that was already implicit in the workspace's `library/` structure but not yet clearly organized. Before MemPalace, the library was organized by media type (Books, Articles, YouTube). After the MemPalace concept, it's clearer that the library should be organized by *topic wing* first — the format is incidental to retrieval.

Also relevant: MemPalace's "no summarization" stance (verbatim storage, semantic search over raw content) is the opposite of Karpathy's LLM Wiki synthesis stance. Both approaches are valid; they serve different purposes. See the synthesis below.

## Key Themes (AI-enriched)

### Wings / Rooms / Drawers Architecture

The palace metaphor maps directly to retrieval structure:

```
Wing  = top-level context domain (person, project, or topic area)
Room  = subtopic within a wing
Drawer = individual verbatim content item (one conversation, one document, one session)
```

**Why this works for retrieval:** You scope searches to a wing or room, not a flat corpus. "Show me everything from the paude wing" returns only paude-related content — not unrelated conversations that happen to share a keyword.

**Verbatim principle:** MemPalace stores content as-is, without summarization or paraphrase. This is deliberate: summarization loses detail; semantic search over verbatim text recovers it at query time. Retrieval accuracy at 96.6% R@5 with no LLM required — that number validates the verbatim approach.

### Benchmarks (headline)

| Mode | R@5 | Notes |
|------|-----|-------|
| Raw semantic search | 96.6% | No LLM, no API key |
| Hybrid v4 (held-out) | 98.4% | Keyword + temporal boosting, no LLM |
| Hybrid + LLM rerank | ≥99% | Works with Haiku/Sonnet/local models |

The 96.6% raw figure is the honest baseline. The rest is the engineering headroom.

### MCP Integration

29 MCP tools cover:
- Palace reads/writes
- Knowledge-graph operations
- Cross-wing navigation
- Drawer management
- Agent diaries

This means MemPalace can be queried by any MCP-compatible agent without bespoke integration code. For Paude, this is the relevant path.

### Agent Diaries

Each specialist agent gets its own wing and diary. Diaries are discoverable at runtime via `mempalace_list_agents` — agents don't need bloated system prompts to know what other agents remember. This is the multi-agent memory coordination pattern at Level 6 of the Simon Scrapes taxonomy.

### Claude Code Hook Integration

Two Claude Code hooks:
1. **Periodic save** — saves session state to palace at intervals
2. **Pre-compression save** — saves before Claude Code compacts context (critical: this is the moment most memory is lost)

`mempalace sweep <transcript-dir>` — processes transcripts into the palace per-message, idempotent.

### Verbatim vs. LLM Wiki: Complementary, Not Competing

| Approach | MemPalace | LLM Wiki (Karpathy) |
|----------|-----------|---------------------|
| Storage  | Verbatim, no summarization | LLM-synthesized wiki pages |
| Retrieval | Semantic search over raw text | Query hits wiki layer |
| Maintenance | Automated (hooks + sweep) | LLM ingest + lint jobs |
| Best for | Session memory, conversation history | Cross-session knowledge accumulation |
| Loss risk | None (verbatim) | Some (synthesis can lose detail) |
| Gain | Fast, accurate retrieval at query time | Pre-synthesized, cross-linked knowledge |

A complete system uses both: verbatim storage for retrieval (MemPalace layer) + LLM-synthesized wiki for persistent knowledge (library/ layer).

## Notable Ideas

- **Wing-first organization:** People and projects become wings, topics become rooms. This is better for retrieval than organizing by media type or date.
- **"The last moment before compression"** is where most memory is lost. Hooks that fire pre-compression are more valuable than post-session saves.
- **No API key required** for the core benchmark path. Local-first is not a compromise; it's the design goal.
- **`mempalace wake-up`** — generates a context-load document for the start of a new session. This is the equivalent of the `/start` command but drawing from persistent memory rather than a handcrafted orientation file.
- **Agent diaries** solve the multi-agent coordination problem without shared mutable state: each agent writes to its own wing, reads from others via MCP.

## Wing Model Applied to This Workspace

| Wing | Topics | Current library entries |
|------|--------|------------------------|
| `ai-engineering` | harness, context, memory, agents, software-3.0 | Lopopolo, Horthy, Karpathy, Simon Scrapes, LLM Wiki, MemPalace, 3Blue1Brown, Miessler |
| `philosophy-practice` | zen, karate, flow, solitude, martial arts | Zen Way, Finding Karate, Karate Philosophy, Karate by Jesse, Simple Lucas, Rian Doris, Shi Heng Yi, Enkamp × Shi Heng Yi, André Bertel |
| `devops` | git, openshift, rhacm, aap, ansible | Git For Ages 4 And Up, Automate OCP Cluster Deployment, Dan Walsh |
| `leadership-org` | career, AI organizational impact | Hank Green, Miessler Replace Knowledge Workers |

## Evaluation Status

Not yet installed in this workspace. Candidiate for Paude multi-agent memory layer (Phase 4). Key evaluation question: does the MCP interface integrate cleanly with Paude's container isolation model? Verbatim session storage via pre-compression hook is immediately applicable to the Cursor environment.

## Sources

- GitHub: https://github.com/mempalace/mempalace
- Docs: https://mempalaceofficial.com/
- Related: [Simon Scrapes — Claude Code Memory Systems](simon-scrapes-claude-code-memory-systems.md) (Level 6 — cross-tool multi-agent)
- Related: [Karpathy LLM Wiki](karpathy-llm-wiki.md) (complementary synthesis layer)
- Related: `.planning/paude-integration/phases/04-multi-agent/04-01-PLAN.md`

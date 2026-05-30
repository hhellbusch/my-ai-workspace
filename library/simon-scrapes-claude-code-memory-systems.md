# Simon Scrapes — Every Claude Code Memory System Compared (So You Don't Have To)

## Source

- **Channel:** Simon Scrapes
- **URL:** https://www.youtube.com/watch?v=UHVFcUzAGlM
- **Duration:** 41:21
- **Published:** 2026-04-23
- **Transcript:** [cached](../research/pai-kai-paude/sources/ref-02-transcript.md) · [ingest copy](../research/ingest-queue/sources/every-claude-code-memory-system-compared-so-you-dont-have-to.md)
- **Findings:** [full analysis](../research/pai-kai-paude/findings/ref-02-memory-systems.md) — analyzed 2026-04-29

## About the Source

A systematic taxonomy of 6 Claude Code memory architectures, evaluated by storage mechanism and retrieval method. Not specific to any one tool — the 6-level framework gives a vocabulary for comparing approaches and identifying where a given workflow sits on the spectrum.

## The 6-Level Taxonomy

| Level | System | Storage | Retrieval | Key Tool |
|---|---|---|---|---|
| 1 | Native | CLAUDE.md + memory.md | Always-loaded context | Built-in |
| 2 | Structured + hooks | Directory tree by type | SessionStart hook auto-injects index | John/Paweł pattern |
| 3 | Semantic | memory.md + daily notes | UserPromptSubmit hook, top-3 semantic matches | memsearch (Zilliz) |
| 4 | Verbatim | SQL + ChromaDB (memory palace) | AA-language symbolic index, 42ms verbatim recall | MemPalace |
| 5 | Knowledge base | Markdown (raw/ → wiki/) | Claude maintains wiki; Obsidian visualizes | Karpathy LLM Wiki / Recall |
| 6 | Cross-tool | Postgres (thoughts + embeddings) | MCP server → Supabase edge function | OpenBrain / Mem0 |

**Key distinction:** Levels 1–4 solve *operational memory* (what did we decide, how do I work here). Levels 5–6 solve *knowledge accumulation* (what did I read, how do ideas connect). Different problems requiring different tools.

## Key Themes

- **The gap autonomous agents expose** — Levels 1–2 work for interactive human-in-the-loop sessions. They break for YOLO-mode agents running without a human managing handoffs. The dreaming/promotion pattern (Level 3) and verbatim recall (Level 4) close that gap.
- **Dreaming as automated progressive bookkeeping** — Level 3's background pass promotes recurring daily-note content into long-term memory, forgets stale content. This is an automated version of the workspace's manual checkpoint/whats-next pattern.
- **Level 6 is the multi-agent coordination layer** — A shared Postgres brain (one `thoughts` table + embeddings + MCP) lets multiple agent containers read and write to the same memory. $0.10/month on Supabase free tier. Directly relevant to multi-Paude-container orchestration on OpenShift.
- **Chyros (watch-only)** — Leaked Anthropic internal daemon: always-on, watches the project, decides what's worth remembering, consolidates in background. If it ships, changes the calculus on adopting Level 3–4 tooling. File as a signal.

## Connections to This Workspace

### This workspace sits at Level 1–2, manually operated

CLAUDE.md is always-loaded (Level 1). The session-awareness rule, `/checkpoint`, and `whats-next.md` are a hand-rolled Level 2 — but without auto-injection hooks. Everything requires a human to write the handoff. That's deliberate (quality over scale) but breaks in autonomous operation.

### The minimum viable upgrade: Level 2 with hooks

`SessionStart` hook that auto-injects `memory.md` (or equivalent) — a small step that automates what checkpoint/whats-next does manually. Lower risk than Level 3 semantic search; no external dependencies.

### Memory architecture for Paude agents (synthesized from findings)

| Layer | What it holds | Injection mechanism |
|---|---|---|
| Session brief | Task spec + CLAUDE.md | Always-loaded |
| Working memory | Decisions in this session | memsearch daily notes (dreaming promotes) |
| Long-term recall | Decisions across all prior sessions | MemPalace or cavemem — on-demand or auto-inject |
| Multi-agent brain | Shared context across containers | OpenBrain / Mem0 (Level 6) — Phase 4+ |

### cavemem comparison

cavemem (from the caveman ecosystem, in backlog) is SQLite + MCP, cross-agent, local — overlaps with MemPalace (SQL + ChromaDB) but adds cross-tool access via MCP. Evaluate both before adopting either; they may be redundant.

### OpenClaw architecture (deeper dive)

For implementation detail on Level 3's OpenClaw-style patterns (gateway, cron, heartbeat, markdown config), see [Alex Krentsel — OpenClaw Deep Dive](alex-krentsel-openclaw-deep-dive.md). Transcript: [research/openclaw/sources/](../research/openclaw/sources/openclaw-video-sxX8BMscce0.md).

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

# Findings: Claude Code Memory Systems — 6 Levels (Simon Scrapes)

**Source:** https://www.youtube.com/watch?v=UHVFcUzAGlM  
**Channel:** Simon Scrapes  
**Title:** Every Claude Code Memory System Compared (So You Don't Have To)  
**Duration:** 41:21 · Published 2026-04-23  
**Analysis date:** 2026-04-29  
**User timestamp flagged:** t=1166s (~19:26, landing in Level 3 / memsearch)

---

## What the Video Is

A taxonomy of 6 memory levels for Claude Code, evaluated by storage mechanism and retrieval method. Not a Paude video. Shared by the user in the Paude/Claude exploration context because it addresses the memory gap that any autonomous agent workflow needs to solve.

---

## The 6 Levels

| Level | System | Storage | Retrieval | Key tool |
|---|---|---|---|---|
| 1 | Native | CLAUDE.md + memory.md | Always-loaded context | Built-in to Claude Code |
| 2 | Structured + hooks | Directory tree (general/tools/domain) | SessionStart hook auto-injects memory.md index | John/Paweł pattern |
| 3 | Semantic | OpenClaw-style (memory.md + daily notes) | UserPromptSubmit hook: top-3 semantic matches injected | memsearch (Zilliz) |
| 4 | Verbatim | SQL + ChromaDB, memory palace structure (wings/rooms/drawers) | AA-language symbolic index; verbatim retrieval in 42ms | MemPalace |
| 5 | Knowledge base | Markdown folders (raw/ → wiki/) | Claude maintains wiki; Obsidian visualizes connections | Karpathy LLM Wiki / Recall |
| 6 | Cross-tool | Postgres (thoughts table + embeddings) | MCP server → Supabase edge function; any AI tool queries | OpenBrain / Mem0 |

**Key distinction:** Levels 1–4 solve *operational memory* (what did we decide, how do I work). Levels 5–6 solve *knowledge base* (what did I read, how do ideas connect). Different problems.

---

## What the Video Adds for the Workspace

### 1. Names the gap the workspace's current pattern doesn't cover

The workspace uses a hand-rolled Level 1–2: CLAUDE.md (always loaded), `whats-next.md`/checkpoint (manual session handoff), git commits as state externalization. This works for single-session interactive work. It does not scale to:
- Autonomous agents running without human handoff management (Paude/YOLO-mode)
- Multiple concurrent agent sessions that need shared context
- "What was decided three sessions ago?" without reading git history

The video's Level 2–4 are all automated solutions to the same problem. The workspace's current approach is a more deliberate, human-curated version that produces better artifact quality at the cost of not scaling.

### 2. Memsearch (Level 3) is the most immediately relevant tool

**Why it fits:** OpenClaw's memory architecture (memory.md + daily notes + background "dreaming") is structurally similar to what the workspace already does. Memsearch ports this to Claude Code with two additions: semantic vector search and a `UserPromptSubmit` hook that auto-injects the top 3 matches without requiring the user to ask. The folder format is plain markdown — readable, portable, version-controllable.

**The dreaming process** — a background pass that promotes recurring daily-note content into long-term memory.md and forgets stale content — is interesting for YOLO-mode: it's an automated version of the progressive bookkeeping pattern. Instead of the human deciding what's worth capturing, the system scores and promotes.

**Workspace-specific concern:** memsearch's `UserPromptSubmit` hook auto-injects context on every prompt. In the workspace's practitioner-voice writing sessions, injecting memory fragments into every prompt could introduce noise. Probably appropriate for code/technical sessions; less appropriate for essay drafting.

### 3. MemPalace (Level 4) is the verbatim recall option

If the question is "I know we decided this, but I can't find it," MemPalace is the answer. Locally stored (SQL + ChromaDB), no cloud dependency, reported highest benchmark for verbatim retrieval. The AA-language index lets the model scan thousands of "drawers" in a single pass.

Relevant for Paude: if an agent runs a task over multiple sessions, MemPalace gives it word-for-word recall of prior sessions without reading git history or whats-next.md.

**Comparison to cavemem** (from the caveman ecosystem, already in the backlog): cavemem is SQLite + MCP, cross-agent, local. MemPalace is SQL + ChromaDB, local. Both solve the cross-session recall problem; cavemem adds cross-tool via MCP.

### 4. OpenBrain / Mem0 (Level 6) is the multi-agent coordination layer

Level 6's Postgres-based shared brain is the most relevant to the enterprise OpenShift AI use case: multiple Paude containers running different tasks, all reading from and writing to the same memory layer. One table (`thoughts`), embedded vectors, MCP access — any tool can query it. $0.10/month on Supabase free tier.

This is the memory architecture you'd want for "a platform team deploys agent infrastructure for engineering teams" — each team's Paude containers share a brain, and the brain is queryable from any AI tool they use.

### 5. Anthropic's "Chyros" — signal worth watching

The video mentions that leaked Claude Code source contained references to an unreleased daemon called **Chyros**: always-on, watches the project continuously, decides what's worth remembering, consolidates notes in the background. This is Anthropic's internal Level 2–3 equivalent. If it ships, it changes the calculus on adopting memsearch or MemPalace — the built-in system may cover the same ground.

Not actionable now. File as a signal for the next time you evaluate memory tooling.

---

## What This Means for the Paude Orchestration Design

The memory problem in Paude/YOLO-mode is a real architectural gap that the video directly addresses. An agent running fire-and-forget via Paude has the task brief and CLAUDE.md, but no memory of what previous sessions decided. The handoff/checkpoint pattern requires a human to write the handoff. That's a structural dependency that breaks in fully autonomous operation.

**Three-layer memory architecture for Paude agents (synthesized from the video):**

| Layer | What it holds | Tool | Injection mechanism |
|---|---|---|---|
| Session brief | Task scope, constraints, definition of done | task spec + CLAUDE.md | Always-loaded |
| Working memory | Decisions made in this session, open threads | memsearch daily notes | Dreaming promotes to long-term |
| Long-term recall | What was decided across all prior sessions on this topic | MemPalace or cavemem | On-demand retrieval or auto-inject |

For multi-agent coordination (multiple Paude containers), add a Level 6 shared brain (OpenBrain or Mem0) above long-term recall.

**The minimum viable addition for the current workspace:** Level 2 (structured memory + SessionStart hook) is a small step from current practice. It automates what the checkpoint/whats-next pattern does manually. Worth evaluating before jumping to Level 3.

---

## What to Evaluate

| Tool | Effort | Fit | First test |
|---|---|---|---|
| memsearch | Low (2-line install) | Good for technical sessions | Install, have 5 conversations, check daily notes |
| MemPalace | Medium | Verbatim recall across sessions | Compare to git-log-based recall for a specific decision |
| cavemem | Low-Medium | Cross-tool, MCP | Check if it duplicates MemPalace or adds distinct value |
| OpenBrain | High | Multi-agent / enterprise | Defer until Paude multi-agent phase |
| Chyros | Zero | Watch-only | Monitor Anthropic releases |

---

## What the Workspace Already Does That's Equivalent

| Video concept | Workspace equivalent | Gap |
|---|---|---|
| CLAUDE.md always-loaded | CLAUDE.md (simplified, 183 lines) | None — already optimized |
| SessionStart hook | `session-awareness.md` Cursor rule | No auto-injection of memory files; human reads |
| daily notes | `whats-next.md` / checkpoint | Manual write; no automated dreaming/promotion |
| Long-term memory | BACKLOG.md Ideas + case studies | Not queryable by agents; human-readable only |
| Dreaming (auto-promote) | Progressive bookkeeping rule | Manual; depends on human to decide what's worth capturing |
| Cross-tool brain | None | Gap — relevant if adopting Paude at scale |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

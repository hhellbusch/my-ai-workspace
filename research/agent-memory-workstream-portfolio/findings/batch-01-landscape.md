# Batch 01 — Landscape findings

## Taxonomy (from sources)

Three architectural bets show up repeatedly (AgentsCamp / DigitalApplied):

| Bet | Examples | What it is |
|-----|----------|------------|
| **Memory layer** | Mem0 | Bolt-on extract + search; keep your harness |
| **Temporal graph** | Zep / Graphiti | Facts with validity windows; good when truth changes |
| **Memory-as-runtime** | Letta (MemGPT lineage) | Agent self-edits tiered memory; you adopt their loop |
| **Learn + inject (coding-focused)** | Hindsight | Banks from git + sessions; knowledge pages; coding-agent plugins |

Vendor benchmarks disagree; treat scores as marketing unless independently reproduced (Hindsight claims LongMemEval SOTA with Virginia Tech / WaPo reproduction noted in their README — still vendor-framed).

## Hindsight (coding agents)

- Premise: last-mile decisions live in **git history and past conversations**, not only in code (ref-02 / product blog).
- Per-repo banks by default (`coding-agent::{gitProject}`); shared banks possible with tagging for provenance.
- Auto-ingest: commit messages (± diffs), session write-back; **knowledge pages** (architecture, conventions, initiatives).
- Harness coverage matches interest: Codex CLI, Copilot CLI, Cursor CLI, Claude Code, plus others; Pi also listed in some docs.
- Ops: Docker / embedded / cloud; not “just a markdown folder.”
- Fit for Field Notes: interesting **per product/lab repo**. Weak as **cross-customer workstream OS**.

## Mem0 / Letta / Zep (compressed)

- **Mem0:** easiest layer; OpenMemory MCP for local-ish cross-tool; conversational/preference memory, not lab notebooks.
- **Letta:** full runtime; high opinion; wrong layer if staying on Codex/Cursor/Copilot as primary harnesses.
- **Zep:** temporal facts; overkill for consulting journals unless compliance/history of changing truth is the product.

## Git portfolio / workstream (your instinct)

Not a product in these sources — it’s the **default engineering pattern**: intentional files as system of record. Strengths: portable, reviewable, multi-repo linking, works offline, no vendor. Weaknesses: requires discipline to write; agents won’t auto-recall unless prompted to read files.

# Assessment: Agent memory vs workstream portfolio

**Date:** 2026-10-04  
**Question:** For multi-harness work (Codex, Copilot, Cursor), consulting/platform labs, and a desire for journal/repeatability — should we adopt an agent-memory product (e.g. Hindsight), double down on a git portfolio/workstream repo, or combine?

---

## Verdict

**Keep a git portfolio / workstream repo as system of record for intent and lab journals.** Treat Hindsight-class tools as an optional *recall layer* on individual product/lab repos later — not as the portfolio, and not as a near-term spike.

Mem0/Letta/Zep are less aligned for this use case right now: Mem0 is conversational memory; Letta wants you to change harness; Zep is temporal-fact CRM territory.

---

## What the landscape is optimizing for

| Need | Best fit from research |
|------|------------------------|
| “What did we decide in this codebase last month?” | Hindsight (git + session ingest) or disciplined commits + journal |
| “What am I driving across customers this quarter?” | Human-curated portfolio / workstreams (git) |
| “Remember user preferences across chats” | Mem0 / OpenMemory |
| “Agent that manages its own long-term state” | Letta (runtime swap) |
| “What was true when, for changing facts” | Zep |

Your stated style — goal → agent runs → collaborate → frequent commits → lab journal for review/repeatability — maps to **git evidence + explicit journal**, which none of the memory vendors replace. They *augment* recall so the agent sees last-mile facts without re-reading everything.

---

## Hindsight specifically

**Attractive:** harness coverage (Codex / Copilot / Cursor), git-aware ingest, knowledge pages, OSS + local option, problem statement matches “decisions not in the code.”

**Reasons not to spike soon (agree with deferral):**

1. Ops cost (daemon/pg/cloud) vs markdown portfolio.  
2. Portfolio is **cross-repo / cross-customer**; Hindsight defaults to **per-repo banks**.  
3. Lab repeatability needs *authored* procedure/result entries — auto-memory tends to summarize conversations, not produce a re-runnable trial log.  
4. Silent wrong memory risk; git journal is greppable and PR-reviewable.

**When to revisit:** After workstream conventions stabilize, pick one high-churn lab/product repo and evaluate recall quality vs “read journal + `git log`.”

---

## Workstream / portfolio git (recommended next design)

Separate from zanshin. Draft lives on branch `docs/workstream-portfolio-sketch` (see that branch). Core bet:

- One light repo (or section) for **workstreams**: goal, constraints, journal, links to product repos/PRs, status.  
- Product/lab repos keep **commits + optional local journal** for experiments.  
- Agents get context by **reading files** (and skills pointing at the convention), not by a memory server.

Zanshin stays harness-neutral skills (shoshin/spar/craft/checkpoint) — complementary, not competing.

---

## Sources

See [manifest.md](manifest.md). Findings: [findings/batch-01-landscape.md](findings/batch-01-landscape.md).

**Confidence:** Medium — based on public docs and comparison articles; no hands-on eval. Vendor benchmarks not independently re-run here.

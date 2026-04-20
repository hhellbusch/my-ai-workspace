# Handoff — Spar response + framework quality (2026-04-20)

<project_backlog>
**In Progress:**
- Upstream PR: `operators-installer` — `upgradeChain` (chart v3.5.0) — implementation on fork, self-review checklist pending before opening PR

**Up Next:**
- Guide: agentic personal AI infrastructure (PAI/Kai pattern) — blocked on hands-on familiarity
- Local LLM: electricity measurement and case studies (ACTIVE TRACK) — deferred until stable model confirmed
- Zen-karate personal knowledge base — experiential content (CRITICAL PATH)
- Essay: The Way Is in Training (first essay) — blocked on personal experiential content
- Graph splits case study — source material complete in experiment journal, ready to draft

**Ideas count:** ~32 items (added: provenance markers on case studies)

**Review queue (author read-through candidates):**
- `docs/ai-engineering/what-a-context-window-actually-is.md` — unreviewed draft, has current hardware data
- `docs/philosophy/the-full-cup.md` — drafted, marked unreviewed
</project_backlog>

<original_task>
Respond to spar feedback on four arguments from the previous evaluation session. Then bookkeeping.
</original_task>

<work_completed>

**Spar response — four arguments addressed:**

1. **Infrastructure sessions are okay** — user affirmed explicitly. The meta-development loop producing framework quality improvements is valid work, not theater. Convention established: don't need to justify infrastructure sessions as long as the improvements are real.

2. **Gitignore case study — severity understated (strongest argument):**
   - Renamed section from "What This Session Did Right" to "How Close It Was — and Why Most Cases Are Closer"
   - Rewrote to lead with why credentials-only repos have no accidental safety net
   - Added list of common scenarios: `.env`, vault passwords, SSH key dirs, TLS certs — any `path/to/sensitive/` rule breaks silently on `git mv`
   - Closes with: *the recovery here worked because the failure was loud. Credentials-only failures are quiet.*
   - File: `docs/case-studies/directory-move-gitignore-drift.md`

3. **README "Where to Start" — routing reworked against full docs/ collection:**
   - Sparring and Shoshin elevated to first entry — most broadly shareable, no prerequisites, user confirmed it's proving socially valuable with peers
   - The Full Cup replaces The Dojo After the Automation as the cold-read entry for managers/non-technical readers — The Full Cup is self-contained; The Dojo requires prior context from The Shift
   - The Shift stays prominent as the engineer/practitioner entry
   - Ego, AI, and the Zen Antidote kept for the psychological/sycophancy dimension
   - File: `README.md`

4. **docs/README.md sparring entry updated:**
   - Now links to Sparring and Shoshin guide first (practical, for cold readers), then Adversarial Review case study (how it was built, for depth readers)
   - File: `docs/README.md`

5. **/start reconstruction caveat strengthened:**
   - Added explicit warning block naming what git log structurally cannot recover: conversational decisions, pending intent, deferred scope calls, verbally-agreed changes without file commits
   - Prompts to ask rather than assume on ambiguous items
   - File: `.cursor/commands/start.md`

**Bookkeeping:**
- BACKLOG.md header updated to reflect this session
- Added provenance markers idea to Ideas section
- whats-next.md updated (this file)

**Commit:** `9517ac0` — "Strengthen severity framing, README routing, and /start recovery caveat"
</work_completed>

<work_remaining>

**Immediate content candidates:**
- Graph splits case study — source material complete in `research/ai-tooling/local-llm-experiment-journal.md`, backlog entry exists, ready to draft. Core finding: 718 PCIe bus crossings per prefill batch; RAM quantity doesn't rescue hybrid inference when the bus is the bottleneck.
- Context window essay read-through — unreviewed, references this hardware's 4096 auto-cap pattern; author eyes needed.

**Decisions deferred:**
- Provenance markers on case studies — logged as an Ideas item, not yet designed or implemented. Simple frontmatter field; low effort when ready.
- Which local model becomes the electricity measurement baseline: qwen3:30b-a3b (90 tok/s, practical daily driver) vs qwen2.5:32b (19.4 tok/s, possibly better quality for long-form). Decide when electricity measurement session starts.

**Still blocked:**
- Zen-karate essays — need personal experiential content from user
- PAI/Kai guide — needs hands-on familiarity with the architecture
- Essay: The Dojo, Open Source, and Ways of Working — needs agile dojo research
</work_remaining>

<critical_context>

**Hardware baseline (tellurium) — carried from prior session:**
- GPU: AMD Radeon RX 7900 XT, 20 GB VRAM, gfx1100 (RDNA3)
- Confirmed working: `ramalama serve quay.io/ramalama/qwen3:30b-a3b` — ~90 tok/s, ~19.5 GB VRAM
- qwen2.5:32b Q4_K_M: confirmed working at 19.4 tok/s but requires clean boot (VRAM fragmentation causes OOM otherwise)
- qwen2.5:72b hybrid: unusable (718 graph splits per prefill → >6 min to first token)

**Repository state:**
- Git: clean — all work committed
- devops/ contains technical reference (moved from root this session cycle)
- .prompts/ is the hidden prompts directory (renamed from prompts/ this session cycle)
- .planning/whats-next.md is the canonical handoff location

**Key documents for next session:**
- Experiment journal: `research/ai-tooling/local-llm-experiment-journal.md`
- Graph splits source material: 2026-04-20 qwen2.5:72b entry in experiment journal
- Setup guide: `docs/ai-engineering/local-llm-setup.md`
</critical_context>

<assumptions_carried>
- The Dojo After the Automation is now a follow-on read, not a cold entry point in either README. If someone lands on it cold via a direct link, it still works — it's just not the recommended starting point for non-technical readers.
- Sparring and Shoshin guide is intended for peer sharing as a standalone. Keep it self-contained if it's updated.
- Provenance markers idea: the spar identified this as structural, not urgent. Don't implement until there's a clear use case for querying the data.
</assumptions_carried>

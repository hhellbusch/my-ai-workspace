# Backlog

> Last updated: 2026-04-20 (backlog: derivative artifacts from local LLM / vLLM track; experiment-journal meta encoding)

## In Progress

### Upstream PR: `operators-installer` — `upgradeChain` (chart v3.5.0)
- **Product:** argo (OpenShift / OLM GitOps)
- **Context:** Contribution to [redhat-cop/helm-charts](https://github.com/redhat-cop/helm-charts) adding strict, list-position-based operator upgrade sequencing for non-semver CSV names and staged GitOps hops. Implementation lives on fork **`hhellbusch/redhat-cop-helm-charts`** (`main`); open the PR when ready (compare view sometimes times out on GitHub — use local `git diff upstream/main...HEAD` if needed).
- **Compare / PR base:** [redhat-cop/helm-charts `main` ← fork `main`](https://github.com/redhat-cop/helm-charts/compare/main...hhellbusch:redhat-cop-helm-charts:main?expand=1)
- **Long-form PR draft (problem, solution, files, validation narrative):** `argo/examples/examples/operators-installer/docs/upstream-pr-description.md`
- **Related examples in this repo:** `argo/examples/examples/operators-installer/` (catalog values, README chain guidance)
- **Started:** 2026-03

**Commit / scope summary (already on fork):**
- Add `_scripts/installplan-chain-approver.py` — one-hop-ahead enforcement via chain indices (no semver parsing).
- Job template: select chain approver when `upgradeChain` set; incremental when `automaticIntermediateManualUpgrades` only; else default; inject `UPGRADE_CHAIN` for chain path.
- ConfigMap: ship new script; `installplan_utils.py` — clearer errors for non-semver CSV names pointing users to `upgradeChain`.
- CI values for `upgradeChain`; chart bump **3.4.0 → 3.5.0**; README / `values.yaml` docs.

**Before opening or updating the GitHub PR (maintainer self-review):**
1. **Fresh install:** Confirm chain approver behavior when Subscription has no / empty `installedCSV` yet (first hop vs upgrade-only).
2. **Both knobs:** If `upgradeChain` and `automaticIntermediateManualUpgrades` can both be set, document precedence (chain wins, no incremental env) or add a Helm `fail` if you want hard mutual exclusion.
3. **`UPGRADE_CHAIN` encoding:** Comma-separated CSV list — note any edge case if a name could contain commas (unlikely for OLM CSVs).
4. **CI parity:** Run the same checks the upstream repo documents (at minimum `helm lint` + `helm template` with `ci/test-install-operator-with-upgrade-chain-values.yaml`); mention the exact upstream workflow in the PR so reviewers can replay it.

**GitHub PR body (short — paste into “What is this PR About?” / “How do we test this?”):**

*What is this PR About?*  
Adds optional `operators[].upgradeChain` to `operators-installer` (v3.5.0): a user-ordered CSV list and a new `installplan-chain-approver.py` that approves InstallPlans only for the **next** chain hop (by list index), avoiding semver comparison. Improves non-semver error messaging in `installplan_utils.py`, wires script selection in the Job (chain vs incremental vs default), adds CI test values, and documents the feature. Intended for operators whose CSV strings are not safely semver-ordered and for GitOps where each hop should be a deliberate merge.

*How do we test this?*  
From the chart directory: `helm lint .` and `helm template test-release . -f ci/test-install-operator-with-upgrade-chain-values.yaml`. On-cluster: render with that values file, apply to a test cluster with `installPlanApproval: Manual`, verify only the expected hop approves, and verify a skip (target two indices ahead) fails the Job with a clear error. If the repo’s CI uses chart-testing or kubeconform, run those the same way CI does.

**Definition of done:** PR opened against `redhat-cop/helm-charts`, checks green, reviewer feedback incorporated; optional follow-up — bump example comments in this workspace that pin “requires operators-installer >= 3.5.0” once upstream chart is released.

## Up Next

### Guide: agentic personal AI infrastructure (PAI/Kai pattern)
- **Product:** docs
- **Context:** Companion guide to `local-llm-setup.md` for the power-user audience: model and hardware selection for PAI/Kai-style autonomous agent architectures, memory systems (three-tier: session/work/learning), scaffolding design for The Algorithm's two-loop structure. Explicitly scoped to local or hybrid execution (not just API). Draws from [`research/pai-kai-paude/`](research/pai-kai-paude/), [`library/daniel-miessler-pai.md`](library/daniel-miessler-pai.md), and the Kai GitHub. Blocked on the Explore PAI/Kai backlog item making more progress — don't draft until there's hands-on familiarity with the architecture.
- **Links:** `docs/ai-engineering/local-llm-setup.md`, `library/daniel-miessler-pai.md`, `research/pai-kai-paude/`
- **Added:** 2026-04-19

### Local LLM: electricity measurement and case studies (ACTIVE TRACK)
- **Product:** docs / meta / research
- **Context:** Initial setup guide drafted at `docs/ai-engineering/local-llm-setup.md` covering Cursor (Ollama/LM Studio via OpenAI-compatible endpoint) and Claude Code (LiteLLM proxy layer). **What remains:** (1) author documents their actual monitoring hardware and data export setup; (2) run defined workloads against a local model, capture the circuit delta vs. baseline, compare against equivalent API token cost; (3) write case studies as data accumulates — first candidate is a 7B–8B coding model on consumer GPU for a defined task benchmark. Feeds the economics essay idea (real kWh data vs. the Braincuber 87%/API-wins analysis). The existing 12+ months of circuit-level data is a unique anchor — most "self-hosting cost" analyses use estimated TDP rather than measured draw.
- **Links:** `docs/ai-engineering/local-llm-setup.md`, `research/openshift-ai-llm-deployment/sources/ref-61.md`, `docs/ai-engineering/openshift-ai-llm-deployment-summary.md`
- **Added:** 2026-04-19

### Zen-karate personal knowledge base — experiential content
- **Product:** docs
- **Context:** Template and structural scaffolding complete. AI-enriched content in place: training history, lineage maps, teachers/influences (Shihan, Sensei, Inoue, Rika Usami), Athens club context, notes/fragments. **What remains is the experiential core that only the user can provide:** formative moments, philosophical anchors (what concepts mean through practice), life application examples, Shi Heng Yi connection, "what's hard to convey," and the crystallizing moments for Shihan and Sensei. This is the critical path to essay readiness — without it, drafting leans on research rather than practitioner voice.
- **Links:** `research/zen-karate-philosophy/personal-notes.md`, `.planning/zen-karate/`
- **Added:** 2026-04-17

### Essay: The Way Is in Training (first essay)
- **Product:** docs
- **Context:** First essay in the zen-karate series (swapped from second position). The philosophical anchor: what lifelong practice teaches that cannot be learned from books. Inoue's "if kihon can do, any kata can do" as the spine. The Hayashi → Inoue → Usami lineage as visible proof that the Way transmits through training. Rika's 7-year journey, 5-hour train rides, retirement at 27 as non-attachment. The uchi-deshi experience in Inoue's own words. Deshimaru's "every moment of life is kata." The personal return to practice after the gap — what survived, what atrophied, what the body remembers. Draws from threads 2, 4, 5, 7, 12, 13, 15. Source material is deep (3 Inoue sources, Rika bio, Hayashi bio, Jesse Enkamp articles, Deshimaru). **Blocked on personal experiential content in Phase 1.**
- **Source material available:** Inoue comprehensive bio + teaching philosophy, Rika Usami biography, Hayashi biography, Jesse Enkamp articles (5), Enkamp × Shi Heng Yi mastery conversation (ego arc, invisible masters, stages of mastery), Deshimaru, personal practice notes (partial — needs formative moments, philosophical anchors).
- **Links:** `.planning/zen-karate/threads.md`, `.planning/zen-karate/`, `research/zen-karate-philosophy/sources/`
- **Added:** 2026-04-17

### Essay: The Dojo, Open Source, and Ways of Working (second essay)
- **Product:** docs
- **Context:** Second essay in the zen-karate series (moved from first position). Takes the philosophical vocabulary from Essay 1 and applies it: the dojo as "a place of the Way" adopted — sometimes deeply, often superficially — in agile transformation (engineering dojos), open source culture (contributor etiquette, senpai/kohai in PR review), and DevOps practice (code kata, architectural kata). What's lost when teams borrow the vocabulary without the philosophy. Draws from threads 3, 6, 7, 10, 11, 12. Connects to `docs/ai-engineering/ai-assisted-upstream-contributions.md` as a worked example. **Needs targeted research on agile dojo movement (Target, Ford, Pivotal Labs), open source etiquette formalization, code kata origins (Dave Thomas).**
- **Source material available:** Deshimaru, Shi Heng Yi transcripts (3 — Betrayal, Isolation, Enkamp mastery conversation), upstream contributions essay, Inoue "no style" philosophy, Jesse Enkamp articles. Agile dojo research still needed.
- **Links:** `.planning/zen-karate/threads.md`, `.planning/zen-karate/`, `docs/ai-engineering/ai-assisted-upstream-contributions.md`
- **Added:** 2026-04-17

### Zen-karate curated reading list — user annotations
- **Product:** docs
- **Context:** Structural scaffolding complete. AI-enriched entries for 10 teachers/lineage figures, 1 book, 2 talks, 1 blog. What remains: user's personal "why it matters" annotations for each source, additional books/talks/teachers from personal experience. The more specific the annotations, the stronger the research phase.
- **Links:** `research/zen-karate-philosophy/curated-reading.md`, `.planning/zen-karate/`
- **Added:** 2026-04-17

### Headless browser fallback for research fetcher
- **Product:** meta
- **Context:** The research skill's `fetch-sources.py` gets blocked by some sites (HTTP 403/429). A headless browser fallback was designed during the skill validation run but not implemented. Would improve source capture rate beyond the current ~85%.
- **Links:** `.cursor/skills/research-and-analyze/`, `docs/case-studies/building-a-research-skill.md`
- **Added:** 2026-04-10

### Low-content capture improvements for research skill
- **Product:** meta
- **Context:** Some fetched sources return minimal content (login walls, JS-rendered pages). The research skill could detect low-content captures and flag them for manual review or retry with different strategies.
- **Links:** `.cursor/skills/research-and-analyze/`
- **Added:** 2026-04-10

## Ideas

### ~~Encode experiment journals in the meta framework~~ ✓ Done 2026-04-20
- Added trigger + registry row to [`cross-linking.md`](.cursor/rules/cross-linking.md); bullet to [`session-awareness.md`](.cursor/rules/session-awareness.md); category row + notes default to [`review-tracking.md`](.cursor/rules/review-tracking.md); `review:` frontmatter to pilot journal.

### Hybrid local/cloud workflow — task routing and skill optimization
- **Product:** meta
- **Context:** Most workflow tasks fall into two categories: (1) bounded, atomic operations that fit in ~14k context (single-file edits, processing one source, drafting a section, targeted lookups) — these can run locally on `qwen3:30b-a3b` via RamaLama; (2) tasks requiring simultaneous access to many files or cross-corpus awareness (research synthesis across 10+ sources, corpus-level spar, cross-essay voice consistency, session planning) — these need Sonnet. The goal is an explicit routing convention and redesigned skills that work within local context constraints.
- **Concrete work items:**
  1. **Task routing convention** — tag backlog items and skill invocations as `[local]` or `[cloud]` based on context requirement. Define the threshold (single file vs multi-file, <8k tokens vs >8k tokens).
  2. **Local-model skill variants** — stripped versions of key skills (`research-and-analyze`, `create-plans`) that: (a) operate sequentially rather than loading all sources at once, (b) write explicit intermediate state to disk at each step (findings files designed for the next step to read, not just archival), (c) have a compact "context budget aware" prompt (~500 tokens) rather than the full SKILL.md rationale.
  3. **Sequential research pipeline** — redesign the research skill's synthesis step: load one source → extract claims → write to `findings/source-N.md` → repeat → load all findings → synthesize. Each step fits in 14k. Trade-off: loses serendipitous cross-source connections visible only when holding all sources simultaneously.
  4. **Essay section drafting locally** — STYLE.md + 2-3 exemplar paragraphs + current section target ≈ 8-10k tokens. Fits in 14k. Voice within a section is maintainable locally; cross-essay consistency needs cloud or human review pass.
  5. **RAG index** — `ramalama rag add docs/` builds embedding retrieval; model gets top 5-10 relevant chunks per query rather than full files. Cleanest architectural answer for large-repo + small-context.
- **Quality estimate:** ~70% of current workflow coverage with redesigned skills; human review fills the gap on the 30% that genuinely needs large context (cross-source synthesis, corpus-level spar, voice consistency across all essays).
- **First experiment (skill variant):** Build a local-model variant of the research skill (stripped prompt, sequential steps, explicit findings handoff). Run it against a single source. Compare output quality against the Sonnet version on the same source.
- **Second experiment (RAG — see dedicated item below):** Index `research/zen-karate-philosophy/` + `library/` → draft Essay 1 paragraph on Inoue's teaching philosophy. Compare quality against Sonnet drafting from same sources loaded manually.
- **Links:** `research/ai-tooling/local-llm-experiment-journal.md`, `.cursor/skills/research-and-analyze/`, `.cursor/skills/create-plans/`, `BACKLOG.md` (workspace architecture item below)
- **Added:** 2026-04-20

### Case study: model self-report of runtime state — context window edition
- **Product:** docs
- **Context:** During the RamaLama qwen3:30b-a3b experiment (2026-04-20), the model self-reported a context window of 32,768 tokens when asked directly. Actual runtime `n_ctx` confirmed via llama.cpp startup logs: 14,592. The model wasn't fabricating — 32k is a real figure from its training data about its typical configuration. The failure is category confusion: answering "what is your context window?" from training knowledge about the model's usual configuration rather than from actual runtime state. Distinct from the frozen-clock idea (wrong year from training cutoff) — same root mechanism (training knowledge ≠ runtime state), different domain (configuration vs. time). Fix: always verify `n_ctx` from startup logs or `ramalama serve` output; never trust self-report for runtime values.
- **Links:** `research/ai-tooling/local-llm-experiment-journal.md` (2026-04-20 RamaLama entry), `docs/case-studies/` (frozen-clock idea for comparison)
- **Added:** 2026-04-20

### Case study: survivorship bias in recommendations
- **Product:** docs
- **Context:** After a sequence of failures (vLLM FP8 MoE failed, AWQ 32B boots at 1k context, dense 32B OOM), the one model that worked (qwen3:30b-a3b MoE) was initially framed as "the recommended default" — implying deliberate quality selection. The spar caught it: the recommendation was reached by elimination, not evaluation. The AI wasn't lying — it accurately described what worked — but positive framing obscured the selection process. Fix: explicit survivorship language ("best available option on this GPU" vs "recommended"). The pattern transfers: any AI recommendation reached by testing-until-something-works carries this risk, especially in hardware/software compatibility work where failure is the norm and success is convergence on what fits.
- **Links:** `research/ai-tooling/local-llm-experiment-journal.md`, `research/ai-tooling/local-llm-setup-sparring-notes.md` (round 2, argument 1)
- **Added:** 2026-04-20

### Case study: the experiment that can't use its own findings
- **Product:** docs
- **Context:** A full session was spent building infrastructure to run local LLMs and documenting findings. The conclusion: the local models (14k context, 3B active parameters) can't do the work that produced the infrastructure. The journal, guide, sparring notes, and backlog items were all generated using Sonnet 4.6 with large context — the capability the local setup cannot replicate. Worth documenting: using advanced tools to characterize the limits of less-capable tools, then trying to route work to the less-capable tools, while acknowledging the characterization work itself required the advanced tools. Connects to honest accounting of AI-assisted workflows: the meta-level requires better tooling than the object level being analyzed.
- **Links:** `research/ai-tooling/local-llm-experiment-journal.md`, `docs/ai-engineering/local-llm-setup.md`
- **Added:** 2026-04-20

### Essay: What a context window actually is (AI-engineering)
- **Product:** docs
- **Context:** "Context window" is used loosely in most AI writing. This session produced concrete observations: 14k runtime vs 32k self-report vs 1M cloud; KV cache as the real constraint (not a fuel tank, not just a limit — an active memory allocation); how MoE vs dense affects what fits; how `-fit` negotiates between model size and context; why 14k and 1M produce qualitatively different work, not just quantitatively different. A practical essay grounding the term in real observations for engineers who use it loosely. Could be standalone or a companion to `local-llm-setup.md`. Strong anchor: the contrast between the self-reported 32k and actual 14k as the opening hook.
- **Links:** `research/ai-tooling/local-llm-experiment-journal.md`, `docs/ai-engineering/local-llm-setup.md`
- **Added:** 2026-04-20

### Essay: The infrastructure trap (philosophy / bridge)
- **Product:** docs
- **Context:** Building the tools for the work can become more engaging than doing the work. AI makes infrastructure fast, satisfying, and legible — which amplifies the trap. This session is a clean instance: multiple hours on local LLM infrastructure while other work waited. Not a failure — the findings are real and the work was worth doing. But worth naming the pattern: the dojo (the tool, the environment) vs. the practice (the purpose). Connects to "The Full Cup" (organizational bandwidth as barrier to learning), potentially to zen-karate themes (the student who polishes their gi instead of training, or the dojo that becomes an end in itself). Bridge essay between AI-engineering and philosophy tracks. Needs a clear frame: this isn't "infrastructure is bad" — it's "the pull toward infrastructure is worth being conscious of."
- **Links:** `docs/philosophy/the-full-cup.md`, `docs/ai-engineering/local-llm-setup.md`, `.planning/zen-karate/`
- **Added:** 2026-04-20

### RAG index for local LLM — corpus retrieval exploration
- **Product:** meta / docs
- **Context:** RamaLama ships a ROCm-enabled RAG image (`quay.io/ramalama/rocm-rag:latest`, confirmed in `ramalama info`). Instead of loading files manually into context, an embedding index lets the local model retrieve the 3–5 most relevant chunks per query automatically. Fits the hybrid local/cloud architecture: local model handles content retrieval + bounded drafting; cloud handles synthesis that needs simultaneous access to many sources.
- **What to index and what not to:**
  - **Index:** `docs/`, `research/`, `library/`, `BACKLOG.md` — factual content corpus
  - **System prompt only (slim variant):** `.cursor/rules/` — procedural instructions, not factual content; RAG retrieval of a rules file gives text, not behavior
  - **Don't index:** `.cursor/skills/`, `.cursor/commands/` — too procedural; raw YAML configs — semantically thin
- **Known limitations for this repo:** (1) Cross-links invisible to retrieval — RAG gets the chunk that *references* another file but not the linked content; (2) Frontmatter YAML noise — review blocks get indexed as chunks; consider stripping before indexing; (3) Index freshness — needs rebuilding as content grows; (4) Doesn't solve synthesis (holding source 3 + source 11 simultaneously to notice a tension) or voice consistency (needs more than retrieved examples).
- **First experiment:** Index `research/zen-karate-philosophy/` + `library/` only. Ask: "Summarise Inoue's teaching philosophy and how Rika Usami's practice exemplifies it." Compare output against Sonnet drafting from same sources loaded manually. If quality is acceptable → expand index. If not → identify what the retrieval missed and whether the gap is chunking, embedding model quality, or fundamentally a synthesis problem RAG can't solve.
  ```bash
  ramalama rag add research/zen-karate-philosophy/
  ramalama rag add library/
  ramalama rag serve ollama://qwen3:30b-a3b
  ```
- **Second experiment (if first passes):** Full corpus index (`docs/`, `research/`, `library/`). Try: cross-case-study query, backlog synthesis, essay section drafting with style guide as system prompt.
- **Links:** `research/ai-tooling/local-llm-experiment-journal.md`, `research/zen-karate-philosophy/`, `library/`, `BACKLOG.md` (hybrid workflow item above)
- **Blocked on:** qwen3:30b-a3b serve working (confirmed ✓) and ramalama rag command availability (check `ramalama rag --help`)
- **Added:** 2026-04-20

### Workspace architecture for local LLM efficiency — exploration track
- **Product:** meta
- **Context:** This workspace was designed for large-context frontier models (Sonnet 4.6, 1M context beta). Running it against a local model (14k–32k context) exposes structural mismatches: `.cursorrules` is enormous, rules files load on every request, skills are thousands of tokens, cross-file reasoning requires loading multiple large files. Three complementary directions to explore:
  1. **RAG index** — `ramalama rag add docs/` builds an embedding index; local model retrieves relevant 3–5 chunks instead of loading files whole. `ramalama info` confirms RAG image available (`quay.io/ramalama/rocm-rag:latest`). Proper architectural answer for large-repo + small-context. Try: `ramalama rag add docs/ && ramalama rag run ollama://qwen3:30b-a3b`.
  2. **Slim `.cursorrules` variant** — a `local-llm` mode config (~300 tokens) that strips to task-essential orientation. Current `.cursorrules` is ~3k+ tokens and loads on every request. A local-model branch would describe only what's needed for the current task type (DevOps edit vs. research vs. essay).
  3. **Atomic task decomposition** — bounded, self-contained tasks that fit in 14k context: "edit this file, here's current content, here's the change." Explicit model routing: `[local]` vs `[cloud]` tag on backlog tasks based on context requirement. Long-session work (sparring, research pipelines, cross-file reasoning) stays on cloud; targeted edits go local.
- **Hardware note:** Current Z690-P platform limits to single-GPU. For 70B fully on GPU need platform rebuild (Threadripper Pro WRX90 + 2× RTX 3090 NVLink ≈ $5–10k, or 2× RTX 5090 PCIe ≈ $7–18k total). Hybrid CPU+GPU offload on current hardware (~15–25 tok/s for 70B Q4) is the near-term path — see experiment journal.
- **Division of labor (current recommended):** Local model for single-file edits, quick lookups, config generation with known schema. Sonnet for research pipelines, sparring, essays, session planning, anything requiring workspace-wide context.
- **Self-referential note:** Some workspace complexity (meta-framework depth, inter-file dependency chains) emerged because large-context models made it tractable. Worth a future `/spar` pass: is the complexity serving the work, or has the work started serving the complexity?
- **Links:** `research/ai-tooling/local-llm-experiment-journal.md`, `docs/ai-engineering/local-llm-setup.md`, `.cursorrules`, `.cursor/rules/`
- **Added:** 2026-04-20

### Local LLM / vLLM track — derivative artifacts
- **Product:** docs / meta / research
- **TL;DR (logged only, no drafting now):** From the journal + guide, later consider: (1) **case study** — Radeon vLLM (FP8 MoE gap, eager/KV limits, Ollama vs vLLM vs RamaLama); (2) **meta case study** — guide vs experiment journal; (3) **short essay** — stack choice under real VRAM/kernel constraints; (4) **electricity** backlog + **spar** notes if drafting; (5) **meta essay** — "a customer could have this conversation" (see dedicated backlog item); (6) **Red Hat ecosystem comparison** — RamaLama / Podman AI Lab / InstructLab / RHEL AI as a landscape piece.
- **"A customer could have this conversation" — session material now rich enough to draft:** The full arc from this track: try vLLM → hit FP8 MoE gap → find AWQ barely works at 1k context → discover RamaLama → auto-detects ROCm → realize context ceiling (14k vs 1M cloud) → understand hybrid architecture path → model enterprise vs consumer hardware gap. That's exactly the evaluation journey an enterprise customer runs — compressed into one session. No pricing claims needed; the pattern is the point. The experiment journal is the primary source. See also: enterprise cost caveat in journal (⚠️ non-authoritative); Red Hat employment disclosure consideration.
- **Detail — candidate artifacts:** The ROCm + Radeon + vLLM work is producing **raw material** in [`research/ai-tooling/local-llm-experiment-journal.md`](research/ai-tooling/local-llm-experiment-journal.md) and [`docs/ai-engineering/local-llm-setup.md`](docs/ai-engineering/local-llm-setup.md). When the track settles, decide what to publish — not everything belongs in the long-form guide.
  - **Case study (`docs/case-studies/`):** Consumer **AMD + vLLM** — FP8 MoE backend gap vs **AWQ** path; **Inductor/HIP OOM** vs **`--enforce-eager`**; **KV cache** when weights ~**18.26 GiB** on **20 GB**; **Ollama vs vLLM** by constraint (context, kernels, ops). Cite the journal as timeline; keep claims **commands-verified** before publishing.
  - **Case study (meta):** **Stable guide vs experiment journal** — why the split, cross-linking, when to promote journal findings into the guide (avoid orphan logs).
  - **Essay / short (`docs/ai-engineering/`):** **Choosing a local inference stack** under real hardware limits: throughput vs comfort, “loads” vs “fits your prompt,” FOSS-first bias in [`workspace-ethos.md`](.cursor/rules/workspace-ethos.md).
  - **Spar / audit:** [`research/ai-tooling/local-llm-setup-sparring-notes.md`](research/ai-tooling/local-llm-setup-sparring-notes.md) (e.g. performed-honesty language) may merge with the **performed honesty** case-study idea already in this backlog when drafting.
  - **Electricity / economics:** *Local LLM: electricity measurement and case studies* (Up Next) — measured workload write-up can use the same hardware; journal records the **software** stack for that run.
- **Links:** `research/ai-tooling/local-llm-experiment-journal.md`, `docs/ai-engineering/local-llm-setup.md`, `research/ai-tooling/local-llm-setup-sparring-notes.md`, `docs/case-studies/README.md`, `BACKLOG.md` (electricity track), `.cursor/rules/workspace-ethos.md`
- **Added:** 2026-04-20

### Formalize draft status in review-tracking frontmatter
- **Product:** meta
- **Status:** not sure if wanted yet
- **Context:** Review frontmatter currently tracks verification status (`unreviewed`, `direction-reviewed`, `reviewed`) but has no boolean for document completeness. "Working draft" only appears as freetext in the `notes` field — readable by humans, invisible to `/audit` and the agent. Adding `draft: true` would make it queryable: `/audit` could separate "actively in progress" from "stable but unverified." Change is small: one field added to the frontmatter format in `.cursor/rules/review-tracking.md`, one category added to `/audit` Layer 5 scan. Evaluate when several working drafts are in flight simultaneously and the current notes-based approach becomes insufficient.
- **Links:** `.cursor/rules/review-tracking.md`, `.cursor/commands/audit.md`
- **Added:** 2026-04-19

### Case study: curated corpus bias — invisible orientation from what was never included
- **Product:** docs
- **Context:** When an AI assistant synthesizes from a pre-selected corpus (e.g. NotebookLM fed Red Hat docs + Lenovo whitepapers), the output is fluent and internally consistent but structurally oriented by what the curator chose to include. The bias isn't in what the model does with the sources — it's in what sources were *never* in the room. The model can't notice an absence. The Jared Burck article is the triggering instance: architecturally accurate (the corpus had good architecture docs), economically optimistic (the corpus had vendor marketing but not the Braincuber counter-argument), maturity-blind (the corpus mixed GA and Tech Preview docs without that distinction). **Distinct from** [case study 9](docs/case-studies/context-stripped-citations.md) (*When the Source Says the Opposite of the Claim*) — that case has the source present but the conclusion stripped; this case has the counter-evidence absent from the start. See also: `research/openshift-ai-llm-deployment/assessment.md` (Finding 2, Finding 3 as exemplars).
  - **Self-referential concern:** This workspace is also a curated corpus. The library is hand-selected. Research workspaces fetch sources from articles that already have a POV. AI enriches what's present. If the initial selection is advocacy-skewed, enrichment amplifies it invisibly. The [`shoshin.md`](.cursor/rules/shoshin.md) rule and [`/spar`](.cursor/commands/spar.md) command are partial mitigations — but they operate *within* the corpus, not on its composition. The honest question for any research or essay here: **what did we not include, and why?** The case study should surface that question as a named practice, not just a risk.
  - **Mitigation angle to document:** Adversarial corpus selection — deliberately sourcing opposing views before synthesis, not after; the "what is the strongest case against this?" prompt *before* drafting; the `/spar` command as post-hoc recovery vs. a pre-inclusion question as prevention.
- **Links:** `docs/case-studies/context-stripped-citations.md`, `research/openshift-ai-llm-deployment/assessment.md`, `.cursor/rules/shoshin.md`, `.cursor/commands/spar.md`
- **Added:** 2026-04-20

### Case study: performed honesty — AI self-labels as honest while making unverified claims
- **Product:** docs
- **Context:** When generating content, the AI signals its own trustworthiness through language ("the common framing often gets the math wrong," "Honest Assessment" section headers, "this is where real data changes the conversation") while simultaneously making unverified claims. The honesty label becomes a rhetorical move rather than a earned quality. The pattern: self-referential honesty claims appear in body text where readers encounter them with full confidence, while the actual verification status lives in frontmatter or a footer most readers never reach. Observed in `docs/ai-engineering/local-llm-setup.md` round 1 spar. The interesting system question: can a pre-commit check or spar rule be added to flag self-referential honesty language in new content, prompting the author to ask whether the language is earning its keep? Needs a well-documented real instance — this one is the candidate. See `research/ai-tooling/local-llm-setup-sparring-notes.md` argument #4.
- **Links:** `docs/case-studies/README.md`, `research/ai-tooling/local-llm-setup-sparring-notes.md`, `.cursor/rules/pre-commit-review.md`
- **Added:** 2026-04-19

### Case study: the frozen clock — LLM defaults to stale current-year
- **Product:** docs
- **Context:** LLMs frequently produce the wrong current year, defaulting to what was "current" during training (2024 as of this writing) even when context clues suggest otherwise. The failure is subtle: the model doesn't say "I don't know the date" — it confidently answers with a stale value. Manifests as: incorrect "as of [year]" citations, wrong age/tenure calculations, stale "latest version" claims, and date-math errors. Interesting dimension: this workspace has today's date injected in system context, so an in-session reference can catch it — but any generated artifact intended for external audiences carries the risk. The case study should capture: what triggered the observation, the specific failure mode, why the model doesn't self-correct (training-time anchoring vs. runtime context), and what mitigations exist (explicit date injection, skeptical review of year references in generated content). Needs a real instance; don't construct one.
- **Links:** `docs/case-studies/README.md`
- **Added:** 2026-04-19

### Case study: the implicit "yes" — context without agreement treated as consent
- **Product:** docs
- **Context:** When the user provides additional thoughts or context without explicitly agreeing or disagreeing, the agent interprets the continued engagement as implicit approval and proceeds. This is a consent assumption that may produce unwanted work or drift. Distinct from "yes" (explicit approval) and "no" (explicit rejection) — it's the ambiguous middle where the agent fills in the gap with optimism. Needs a real instance to document; don't construct one. Watch for: user asks a clarifying question back, user adds a related idea, user provides scope context, agent treats all of these as "proceed."
- **Links:** `docs/case-studies/README.md`
- **Added:** 2026-04-19

### Research: agile dojo movement — verified outcomes (Essay 2 blocker)
- **Product:** docs / research
- **Context:** Essay 2 (The Dojo, Open Source, and Ways of Working) cites Target, Ford, and Pivotal Labs as engineering dojo programs. The current framing assumes mixed or failed outcomes — that the programs borrowed vocabulary without philosophy. If research shows success, the essay thesis changes. Do not draft Essay 2 without verified outcomes. Research scope: What happened to Target's dojo program? Ford's dojo? Pivotal's pairing model? Were they continued, scaled, discontinued, or evolved? What do practitioners say about outcomes? Also covers code kata origins (Dave Thomas) and open source etiquette formalization (contributor guidelines history). See `.planning/zen-karate/essay-outlines.md` (Essay 2 outline, Research Needed section).
- **Links:** `.planning/zen-karate/essay-outlines.md`, `BACKLOG.md` (Essay 2 Up Next entry)
- **Added:** 2026-04-19

### Case study: genuine net loss — no recovery
- **Product:** docs
- **Context:** The case study collection has survivorship bias: every documented example was noticed, named, and addressed. A case study about a session that produced a net loss without useful recovery — a tool built and abandoned, work that had to be redone, an AI-assisted approach that made things worse — would make the collection more honest. Needs real material when it presents itself; don't construct one. The survivorship note is now in the case studies README and docs/README.md evidence scope block.
- **Links:** `docs/case-studies/README.md`, `docs/README.md`
- **Added:** 2026-04-18


### Essay: The economics of AI — tokens, context windows, and what it actually costs
- **Product:** docs
- **Context:** Tokens are both the computational unit (what the model processes) and the billing unit (what you pay for). This dual meaning confuses engineers new to AI. A dedicated piece could cover: token pricing models, context window economics (the 128K window isn't a fuel tank — it's simultaneous visibility), the gas analogy (Ethereum gas, fuel), how cost shapes architectural decisions (self-hosted vs. API, model selection, prompt engineering for efficiency). The recovered Braincuber source provides concrete anchor data: 733x cost difference at low volume (1M tokens/day), 5x advantage only at industrial scale (500M+ tokens/day), API winning for 87% of use cases, GPU underutilization inflating costs 10x — numbers that tell a much more nuanced story than most "self-host to save money" advice. Could be a companion to The Shift section 5 or a standalone essay in the AI-engineering track.
- **Links:** `docs/ai-engineering/the-shift.md` (section 5), `docs/ai-engineering/openshift-ai-llm-deployment-summary.md`, `research/openshift-ai-llm-deployment/sources/ref-61.md`
- **Added:** 2026-04-17

### Guiding stars as meta-framework concept
- **Product:** meta
- **Context:** Projects need explicit "guiding stars" — primary purposes that drive prioritization. When a project has multiple tracks (AI-engineering, philosophy, personal research), the guiding star determines what gets attention first and what supports vs. leads. Encode this into session orientation (`/start`), backlog prioritization (`/backlog`), and planning docs. Prevents supporting interests from consuming the budget meant for primary work. This session's shoshin review revealed the zen-karate track had been consuming attention disproportionate to its role as a supporting interest.
- **Links:** `.planning/zen-karate/STYLE.md` (Guiding Stars section), `.cursor/commands/start.md`, `.cursor/commands/backlog.md`
- **Added:** 2026-04-18

### Research-to-essay pipeline — collect, sort, discard, rewrite loop
- **Product:** meta
- **Context:** Formalize the research flow pattern: collect resources and material → sort and order → evaluate and throw away → rewrite and distill → add more → repeat until essay-ready. This mirrors traditional academic writing process (how you were taught in school) and is already happening informally across the project. Could become a slash command, a skill, or just a documented workflow in the planning docs. Evaluate whether this can integrate with the existing `create-meta-prompts` pipeline stages or if it's a distinct loop.
- **Links:** `.planning/zen-karate/workflow-notes.md`, `.cursor/skills/create-meta-prompts/`, `.cursor/skills/research-and-analyze/`
- **Added:** 2026-04-18

### Mobility and recovery resource library
- **Product:** docs / research
- **Context:** Catalog of health, mobility, strength, and recovery resources discovered during return to practice after extended illness. New learning validated against early karate training. Feeds Thread 12 (The Forgotten Body) and the embodied-knowledge themes across the essay series. Template at `research/zen-karate-philosophy/mobility-and-recovery.md` — needs user to populate as resources are found.
- **Links:** `research/zen-karate-philosophy/mobility-and-recovery.md`, `.planning/zen-karate/thread-development.md` (Thread 12)
- **Added:** 2026-04-18

### Essay: The Full Cup — organizational bandwidth as the barrier to learning (DRAFTED — needs author review)
- **Product:** docs (bridge: philosophy ↔ AI-engineering)
- **Context:** Thread 19. Drafted as `docs/philosophy/the-full-cup.md`. Needs author to add: specific stories, which Goal/Phoenix Project strategies map most directly, a real "right words" instance (bottom-right quadrant), and whether the "bow at the door" section needs a real professional example. Voice-approved validation required for any experiential content added.
- **Links:** `docs/philosophy/the-full-cup.md`, `.planning/zen-karate/threads.md` (thread 19)
- **Added:** 2026-04-18

### Essay: Five Hindrances
- **Product:** docs
- **Context:** Shi Heng Yi's five hindrances to self-mastery (sensual desire, ill will, dullness/heaviness, restlessness, doubt) mapped to everyday life and work. How a martial artist recognizes and works through these in practice and in professional life.
- **Links:** `.planning/zen-karate/`
- **Added:** 2026-04-17

### Essay: Discipline as Freedom
- **Product:** docs
- **Context:** The paradox that restriction enables growth. Structure in the dojo, structure in work. How kata (prescribed forms) build the foundation for spontaneous, creative action. Connects to Shi Heng Yi's teaching that freedom grows inside discipline.
- **Links:** `.planning/zen-karate/`
- **Added:** 2026-04-17

### Essay: The Dojo and the Team (merged into priority essay)
- **Product:** docs
- **Context:** Originally a standalone bridge essay. Core themes (mutual respect, senpai/kohai, cleaning the floor, presence over performance) are now absorbed into the priority essay "The Dojo, Open Source, and Ways of Working" at the top of Up Next. May re-emerge as a separate essay if the priority essay can't cover the team dynamics depth, but for now treat as merged.
- **Links:** `.planning/zen-karate/`, `.planning/zen-karate/threads.md`
- **Added:** 2026-04-17

### Essay: Beginner's Mind in the Age of AI (partially absorbed into ego/AI essay)
- **Product:** docs
- **Context:** Shoshin (beginner's mind) as the essential posture for working with AI. The core shoshin concept is now a key section in the in-progress ego/AI essay. May still emerge as a standalone essay if there's enough material beyond the ego angle — e.g., shoshin applied to learning new domains with AI, approaching unfamiliar codebases.
- **Links:** `.planning/zen-karate/`, `docs/ai-engineering/the-shift.md`
- **Added:** 2026-04-17

### YouTube transcript MCP server
- **Product:** meta
- **Context:** `jkawamoto/mcp-youtube-transcript` MCP server could enable fetching transcripts directly during conversations without running the script manually. Lower priority since `fetch-transcript.py` covers the need and caches to disk (which MCP wouldn't do automatically).
- **Links:** `.cursor/skills/research-and-analyze/scripts/fetch-transcript.py`
- **Added:** 2026-04-17

### Gemini API video understanding integration
- **Product:** meta
- **Context:** Future option for native video understanding via Gemini API. Can process YouTube videos directly by URL — visual understanding, not just transcripts. Useful for martial arts demonstrations or content where visuals matter. Requires API key and has per-request costs. Lower priority than transcript-based approaches.
- **Links:** `library/`
- **Added:** 2026-04-17

### Zen-karate concept glossary
- **Product:** docs
- **Context:** Shared glossary of Japanese/Zen terms (mushin, zanshin, fudoshin, shoshin, kata, kihon, kumite, senpai/kohai, dojo kun, etc.) extracted after Essay 1 is drafted. Keeps definitions consistent across the series so later essays don't re-explain foundational vocabulary.
- **Links:** `research/zen-karate-philosophy/`
- **Added:** 2026-04-17

### Zen-essay slash command
- **Product:** meta
- **Context:** Dedicated slash command encoding the proven essay pipeline after 2-3 essays have been written manually. Pulls from shared research library and personal-notes.md, applies voice/style guide, enforces docs/ conventions, prompts for personal content at the right points.
- **Links:** `.cursor/commands/`
- **Added:** 2026-04-17

### Explore Miessler's PAI/Kai architecture — learn, compare, integrate
- **Product:** meta
- **Context:** Daniel Miessler's [PAI (Personal AI Infrastructure)](https://danielmiessler.com/blog/personal-ai-infrastructure) is an open-source agentic AI system built on Claude Code. Seven components: Intelligence (model + scaffolding), Context (three-tier memory: session/work/learning), Personality (quantified traits), Tools (67 skills, 333 workflows, Fabric patterns), Security (defense-in-depth), Orchestration (17 hooks, 7 lifecycle events), Interface (CLI-first + voice). Core engine is "The Algorithm" — two nested loops (current→desired state + 7-phase scientific method) driven by Ideal State Criteria (granular, binary, testable). **Kai** is his personal implementation ([GitHub](https://github.com/danielmiessler/PAI), 11k+ stars). This workspace is converging on similar patterns independently (skills, hooks, slash commands, session orientation, review tracking). Key learning areas: (1) three-tier memory system vs. our flat planning/research structure, (2) explicit rating/signal capture for learning from failures, (3) the Algorithm's ISC approach vs. our review/validate system, (4) Fabric patterns vs. our slash commands. Key philosophical divergence: PAI is optimization-focused (close the gap faster); this workspace is development-focused (the person grows through closing the gap) — voice input #15. Explore intersection with Paude (containerized execution) and what this workspace could adopt without losing the developmental philosophy.
- **Links:** https://danielmiessler.com/blog/personal-ai-infrastructure, https://github.com/danielmiessler/PAI, `library/daniel-miessler-ai-replace-knowledge-workers.md`, `.planning/zen-karate/thread-development.md` (voice #15)
- **Added:** 2026-04-18

### Explore Paude for containerized agent workflows
- **Product:** meta
- **Context:** [Paude](https://github.com/bbrowning/paude) runs AI coding agents (Claude Code, Cursor CLI, Gemini CLI, OpenClaw) in secure containers with git-based sync. Could strengthen the meta-prompting system by enabling isolated, parallelizable agent sessions — e.g., running research, drafting, and review agents concurrently in containers with `--yolo` safely enabled, or orchestrating fire-and-forget agent tasks against this workspace. Worth exploring whether its orchestration model (harvest, PRs, multi-session) maps to the multi-stage meta-prompt pipelines already in use here. Also explore intersection with PAI/Kai — Paude provides the containerized execution environment; PAI provides the scaffolding architecture. Could Paude containers run PAI-style agents with structured memory and learning loops?
- **Links:** https://github.com/bbrowning/paude, `.planning/paude-integration/`
- **Added:** 2026-04-17

### Repo reorganization: move DevOps technical samples into a subfolder
- **Product:** meta
- **Context:** As the audience for this repo widens (peers, non-technical collaborators, general readers), the current flat top-level structure mixes operational DevOps reference material (argo, ansible, ocp, rhacm, vault, coreos) with general-audience content (docs/, library/, research/). Moving the technical samples under a single folder (e.g., `devops/` or `technical/`) would make the repo navigable for non-technical visitors without breaking the value for technical peers. Considerations: (1) all internal cross-links in docs and README would need updating; (2) git history is preserved with `git mv`; (3) `.cursorrules` references would need auditing. Evaluate whether the README becomes the landing page for all audiences or splits into audience-specific entry points.
- **Links:** `README.md`, `.cursorrules`, `docs/`
- **Added:** 2026-04-19

### Expand OCP troubleshooting guides
- **Product:** ocp
- **Context:** Several existing troubleshooting guides could be expanded with additional detail or new guides added for common issues encountered in the field. The troubleshooting section is one of the most practical parts of the repo for peers.
- **Links:** `ocp/troubleshooting/`
- **Added:** 2026-04-17


### CoreOS troubleshooting section
- **Product:** coreos
- **Context:** Currently only have `coreos/examples/` with Butane configurations. No troubleshooting guides yet. Could document common ignition/butane issues encountered during deployments.
- **Links:** `coreos/examples/`
- **Added:** 2026-04-17

### Paude as external executor for meta-prompting pipelines
- **Product:** meta
- **Context:** If the Paude evaluation succeeds (see `.planning/paude-integration/`), explore wiring it into the meta-prompting architecture as an alternative execution backend. Integration points: a `/paude` slash command wrapping create -> assign -> harvest; a `--paude` flag in `/run-prompt` to delegate to a container session instead of a Task subagent; a Paude variant for `/run-plan` strategy C (plans without interactive checkpoints); a "containerized executor" pattern in the orchestration references; multi-agent comparison (`--agent claude` vs `--agent gemini`) as a first-class option for adversarial review. Fundamentally different from in-session Task subagents — Paude is fire-and-forget with git sync, not shared-context pipelines.
- **Links:** https://github.com/bbrowning/paude, `.planning/paude-integration/`, `.cursor/skills/create-subagents/references/orchestration-patterns.md`
- **Blocked on:** Paude evaluation Phase 5 assessment
- **Added:** 2026-04-17

## Done

Rolling cap: at most **15** items stay here (newest first). Older completions live in `BACKLOG-ARCHIVE.md` (see `/backlog` command — **Done retention**). Git history remains authoritative.

### Research: Miessler Single DA Thesis — transcript, full pipeline, Thread 21
- **Product:** library / research / docs
- **Context:** Fetched and fully analyzed Miessler's "We're All Building a Single Digital Assistant" (32 min, Unsupervised Learning). Ran complete research-and-analyze pipeline: proper directory structure (`research/miessler-single-da-thesis/`), manifest, transcript in `sources/`, batch findings (core thesis + workspace connections), assessment. Created library entry with confidence table and upstream cross-reference into PAI entry. Cross-linked into Dojo After the Automation essay (Sources + Related Reading). Added Thread 21 (The Amplification Line) to zen-karate threads — the question of when DA delegation amplifies vs. forecloses development. Also documented and remediated systematic skill compliance failures from the initial fetch session.
- **Links:** `research/miessler-single-da-thesis/`, `library/daniel-miessler-single-da-thesis.md`, `library/catalog.md`, `docs/philosophy/the-dojo-after-the-automation.md`, `.planning/zen-karate/threads.md`
- **Completed:** 2026-04-18

### Case study: spar-distortion — when the sparring partner shapes the fighter
- **Product:** docs
- **Context:** Self-spar (#13-18) caught that the Dojo After the Automation essay's oppositional framing was a distortion created by the spar-driven drafting process. Essay revised from "I disagree" to "I agree AND." Case study documents tool-induced bias: the same tool that catches bias created it. Labeled `failure` — adversarial energy absorbed into structure. Registered as case study #17 (failure) in case studies README and #19 in docs reading order.
- **Links:** `docs/case-studies/spar-distortion.md`, `docs/philosophy/the-dojo-after-the-automation.md`, `research/zen-karate-philosophy/sparring-notes.md`
- **Completed:** 2026-04-18

### Dojo After the Automation — revised from opposition to extension
- **Product:** docs
- **Context:** Major reframe after self-spar: "Two Prescriptions" → "The Same Direction." Human 3.0 as shared destination; essay asks who builds the humans. Future A reattributed to cost-reduction CFO, not Miessler. Capability stack engaged directly. Federation/Borg replaced with middle-ground acknowledgment. Library entries updated: "counter-tension" → "shared direction." Sparring notes round 2 (#13-18) logged.
- **Links:** `docs/philosophy/the-dojo-after-the-automation.md`, `library/daniel-miessler-ai-replace-knowledge-workers.md`, `library/daniel-miessler-pai.md`
- **Completed:** 2026-04-18

### Case study: spar-to-essay pipeline (spar #9 → Thread 20 → drafted essay)
- **Product:** docs
- **Context:** Published case study documenting how adversarial argument #9 escalated from counter-position through voice inputs to Thesis D, Thread 20, and a fully drafted essay in one session. Spar as generative pressure, not just quality gate. Registered as case study #16 in both READMEs.
- **Links:** `docs/case-studies/spar-to-essay-pipeline.md`, `docs/philosophy/the-dojo-after-the-automation.md`, `research/zen-karate-philosophy/sparring-notes.md`
- **Completed:** 2026-04-18

### Enriched library entry for PAI (Personal AI Infrastructure)
- **Product:** library
- **Context:** Full seven-component architecture breakdown, The Algorithm's two-loop structure, convergent patterns with this workspace (skills, hooks, memory, review), key divergences (rating/signal capture, personality, formalized algorithm), mutual learning opportunities. Catalog updated with enriched link.
- **Links:** `library/daniel-miessler-pai.md`, `library/catalog.md`
- **Completed:** 2026-04-18

### Session boundary anchoring — /start and /whats-next improvements
- **Product:** meta
- **Context:** Three fixes implemented: (1) `/start` reordered — backlog snapshot is now Step 1 before handoff check (Step 2), giving project-level context structural primacy over session-level continuity; (2) `/whats-next` now has a Step 0 gate that evaluates whether a handoff is genuinely needed — if work is fully committed and backlog is current, it skips handoff creation and offers to clean up stale files; (3) handoff staleness check — `/start` compares `whats-next.md` mtime against latest commit and cross-references against the backlog. Session-awareness rule updated with staleness warning.
- **Links:** `.cursor/commands/start.md`, `.cursor/commands/whats-next.md`, `.cursor/rules/session-awareness.md`
- **Completed:** 2026-04-18

### Cross-link Dojo After the Automation into four essays
- **Product:** docs
- **Context:** Added the new essay to Related Reading in The Shift, The Full Cup, Ego/AI/Zen, and The Meta-Development Loop with tailored descriptions for each connection.
- **Links:** `docs/ai-engineering/the-shift.md`, `docs/philosophy/the-full-cup.md`, `docs/philosophy/ego-ai-and-the-zen-antidote.md`, `docs/ai-engineering/the-meta-development-loop.md`
- **Completed:** 2026-04-18

### Essay draft: The Dojo After the Automation — what are we building people for? (Thread 20)
- **Product:** docs (bridge: philosophy ↔ AI-engineering)
- **Context:** Drafted `docs/philosophy/the-dojo-after-the-automation.md`. Philosophical position paper: AI will automate execution; learning investment determines liberation vs. disposal. The co-development loop as the strongest argument. Draws from voice inputs #5-16, spar #9 response, Miessler's PAI architecture, and the Full Cup predecessor. Evidence base (*Accelerate*, displacement data) builds over time. Updated philosophy README, docs README (renumbered 10→25), archived oldest Done item.
- **Links:** `docs/philosophy/the-dojo-after-the-automation.md`, `.planning/zen-karate/threads.md` (thread 20)
- **Completed:** 2026-04-18

### Case study: landscape pass and corpus-level spar
- **Product:** docs
- **Context:** Two new case studies. (14) The thread development landscape pass: assessing all 16 essay threads before drafting any, revealing thread contradictions, the 20/80 ratio, and merge candidates invisible from inside any single thread. (15) The corpus-level spar: running `/spar` across all essays simultaneously, catching scope overclaims, conditional universals, and framing drift that per-document review missed.
- **Links:** `docs/case-studies/landscape-before-depth.md`, `docs/case-studies/corpus-level-spar.md`
- **Completed:** 2026-04-18

### Workflows essay: spar follow-up and author validation
- **Product:** docs
- **Context:** Adversarial review follow-through on `ai-assisted-development-workflows.md`: clarified Purpose (transferable patterns vs. this repo as reference implementation), scope line for slash commands and files, collaborator metaphor + verification framing, removed unmeasured “80%” claim, product-version caveat on instruction paths, iteration sequencing for multi-constraint infra prompts, economics section reframed against cargo-cult breakeven numbers (Braincuber / assessment cross-check), illustrative branch-triage disclaimer, Argo CD naming. Recorded `read` + `fact-checked` review metadata and updated disclosure footer.
- **Links:** `docs/ai-engineering/ai-assisted-development-workflows.md`
- **Completed:** 2026-04-18

### AI disclosure footer check and DevOps notice harmonization
- **Product:** meta / docs
- **Context:** Added AI disclosure footer check to pre-commit review (always-applied rule step 4, /review command step 9). Normalized 16 DevOps READMEs with inconsistent disclosure patterns to the standard italic footer linking to AI-DISCLOSURE.md. Added the footer to 6 top-level product READMEs that had none. Individual example READMEs without existing disclosure left as-is — top-level coverage is sufficient.
- **Links:** `.cursor/rules/pre-commit-review.md`, `.cursor/commands/review.md`, `AI-DISCLOSURE.md`
- **Completed:** 2026-04-18

### Source recovery: ref-61 economics claim verification
- **Product:** research
- **Context:** Recovered the braincuber.com source (ref-61) that was previously unreachable (Vercel security checkpoint blocked automated fetching). User copied the article from their browser. Key finding: the 11B token/month breakeven is real, but the source argues API wins for 87% of cases — the Jared Burck article reversed the framing. Updated verification notes, assessment, and added inline caveats to the workflows essay and deployment summary.
- **Links:** `research/openshift-ai-llm-deployment/sources/ref-61.md`, `research/openshift-ai-llm-deployment/assessment.md`, `docs/ai-engineering/ai-assisted-development-workflows.md`
- **Completed:** 2026-04-18

### Case study: heavy safety nets — when review processes are too rigid to follow
- **Product:** docs
- **Context:** The pre-commit review rule required full 11-step `/review` for every commit, which caused it to be skipped for small changes — silently invalidating `the-shift.md`'s review status across three commits. Fix: scaled review depth (full vs. quick), three-layer staleness detection (edit-time, commit-time, retroactive), and SHA tracking for precise "diff since last review."
- **Links:** `docs/case-studies/heavy-safety-nets.md`, `.cursor/rules/pre-commit-review.md`, `.cursor/commands/review.md`
- **Completed:** 2026-04-18

### Review staleness detection and SHA tracking
- **Product:** meta
- **Context:** Scaled pre-commit review to be proportional (full for big changes, quick for small). Added three-layer staleness detection: agent warns at edit time, `/review` step 7 catches at commit time, `/audit` layer 5d catches retroactively. `/validate` now records git SHA (`at:` field) enabling `git diff SHA..HEAD -- file` for precise re-review.
- **Links:** `.cursor/rules/pre-commit-review.md`, `.cursor/rules/review-tracking.md`, `.cursor/commands/review.md`, `.cursor/commands/validate.md`, `.cursor/commands/audit.md`
- **Completed:** 2026-04-18

### Case study: stale context in multi-agent sessions
- **Product:** docs
- **Context:** AI agent removed the backlog archive system, another session restored it, and the first agent continued editing based on stale assumptions — overwriting the rolling cap and exceeding the item limit. Documented as a case study exploring anchoring on session memory vs. repository state.
- **Links:** `docs/case-studies/stale-context-in-long-sessions.md`, `.cursor/rules/shoshin.md`, `BACKLOG.md`
- **Completed:** 2026-04-17



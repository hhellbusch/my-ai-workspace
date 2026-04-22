# Backlog

> **State:** 4 in progress · 8 up next · 70 ideas · Last done: Meta full content audit + systemic link/registry fixes (2026-04-20)
> Last updated: 2026-04-21 (meta system optimization ideas; zanshin-kit Phase 3; workspace STYLE.md)

## In Progress

### Zanshin Kit — portable working style (Phase 3: output format anchoring)
- **Product:** meta / tooling
- **Context:** Phase 1 and 2 complete. Phase 3 in progress: spar output templates added (Type/argument/why it matters/Strength + Self-Audit block) to anchor format consistency across tools; collaboration style section added (brevity, cut before adding). Root cause of Phase 3: same model (Claude), different output quality in Copilot Chat vs. Cursor — diagnosed as missing output templates, not model capability. Pending: close-out mode with real accumulated context still untested. Scope items deferred: cross-linking portable form, backlog capture, Copilot keyword registration. See `.planning/zanshin-kit/ROADMAP.md` for full findings.
- **Links:** `zanshin-kit/WORKING-STYLE.md`, `.planning/zanshin-kit/BRIEF.md`, `.planning/zanshin-kit/ROADMAP.md`
- **Started:** 2026-04-20

### Upstream PR: `operators-installer` — `upgradeChain` (chart v3.5.0)
- **Product:** argo (OpenShift / OLM GitOps)
- **Context:** Contribution to [redhat-cop/helm-charts](https://github.com/redhat-cop/helm-charts) adding strict, list-position-based operator upgrade sequencing for non-semver CSV names and staged GitOps hops. Implementation lives on fork **`hhellbusch/redhat-cop-helm-charts`** (`main`); open the PR when ready (compare view sometimes times out on GitHub — use local `git diff upstream/main...HEAD` if needed).
- **Compare / PR base:** [redhat-cop/helm-charts `main` ← fork `main`](https://github.com/redhat-cop/helm-charts/compare/main...hhellbusch:redhat-cop-helm-charts:main?expand=1)
- **Long-form PR draft (problem, solution, files, validation narrative):** `devops/argo/examples/examples/operators-installer/docs/upstream-pr-description.md`
- **Related examples in this repo:** `devops/argo/examples/examples/operators-installer/` (catalog values, README chain guidance)
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

### Zanshin Kit — Phase 3 scope definition: cross-linking and backlog capture
- **Product:** meta / tooling
- **Context:** Deferred train of thought from 2026-04-21. Two behaviors present in Field Notes rules but absent from the kit were flagged for possible inclusion: (1) cross-linking in portable form — when creating a new file, add it to relevant README/index; when renaming, update markdown links; verify external URLs before committing; link named files on first mention; (2) backlog capture — when user defers something, write it to BACKLOG.md immediately; create with standard sections if none exists; commit separately with `backlog:` prefix. Questions to settle before writing: always-on or invoke-only for each? Phase 3 addition (clean record) or revised BRIEF? Document growth is a known risk (Phase 2 ROADMAP). Also pending: assess whether spar output quality in the kit matches the source — separate concern, see adjacent backlog item.
- **Links:** `zanshin-kit/WORKING-STYLE.md`, `.planning/zanshin-kit/BRIEF.md`, `.planning/zanshin-kit/ROADMAP.md`
- **Added:** 2026-04-21

### Zanshin Kit — assess spar output quality divergence
- **Product:** meta / tooling
- **Context:** Deferred train of thought from 2026-04-21. Symptom: spar output in the kit (Copilot Chat) may differ in quality from spar output in the source workspace (Cursor/Claude). Phase 1 ROADMAP noted spar mechanism transferred — vocabulary and discipline present. But the user wants to assess this more carefully. Key questions: is the divergence in argument classification, self-audit depth, steel-manning quality, or something else? Is it model-dependent (Copilot vs. Claude) or document-dependent (mechanism not fully encoded)? See `research/framework-efficacy/` for controlled comparison protocol.
- **Links:** `zanshin-kit/WORKING-STYLE.md`, `.planning/zanshin-kit/ROADMAP.md`, `research/framework-efficacy/`
- **Added:** 2026-04-21

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

### Meta system optimization — faster start, lower token usage
- **Product:** meta / tooling
- **Context:** Brainstorm from 2026-04-21. Willing to entertain trade-offs. Key tension: always-on rules exist because opt-in behaviors get missed; conditional loading trades recall precision for speed. Ideas by category:
  - **Rule loading:** fold `cross-linking.md` into `/review` (only matters at commit time); merge `backlog-capture.md` + `case-study-reflection.md` into one rule; fold `feedback-checkpoints.md` into `session-awareness.md`; tiered model (lightweight label always loaded, full spec loaded on activation); audit `repo-structure.md` for always-on value
  - **Context compression:** BACKLOG summary header (counts + recent Done) read first by `/start`, full detail on demand; `.cursorrules` TÂCHES section → pointer to `.cursor/README.md`; compressed whats-next.md variant (5 lines: in-progress, next step, key decision) as default
  - **Session start:** minimum viable start = BACKLOG summary + git log, everything else deferred; session type detection (docs/writing → load style rules; technical → skip them); gate planning one-liners on whether session has planning relevance
  - **Handoff/state:** whats-next staleness threshold — surface archive prompt if >N commits stale; SHA-anchored workspace state snapshot as single diff target; more aggressive Done rolling cap (3–5 items)
- **Added:** 2026-04-21

### Source review: Zanshin — Traditional Aikido of Colorado Springs
- **URL:** https://cos-aikido.com/2023/05/11/zanshin-remaining-mind-cultivating-a-budo-mindset-part-2/
- **Why:** Best philosophical treatment of zanshin found in research — Saito Sensei's "shooting a tiger" example, the natural-state framing ("it's about overcoming bad mental habits, not learning to do something new"), the relational "connection" quality, and the two-second hold practice. All of these have direct implications for the essay and potentially for how the framework is described. Read before finalizing `docs/philosophy/zanshin.md`.
- **Possible library entry:** `library/aikido-colorado-springs-zanshin.md` — primary source for the philosophical tradition
- **Added:** 2026-04-20

### Source review: Context Window Management and Session Lifecycle — Zylos Research (2026)
- **URL:** https://zylos.ai/research/2026-03-31-context-window-management-session-lifecycle-long-running-agents
- **Why:** Directly challenges the "practice not engineering" framing in `docs/philosophy/zanshin.md`. Key finding: Anthropic found compaction alone sufficient for multi-session continuity with capable models. StatePlane adds "adaptive forgetting" and "goal-conditioned retrieval" — judgment operations. The Carnival9 pattern ("execution trace is source of truth; memory is derived state") independently converges on "commits as truth anchors." Covers context rot, the lost-in-the-middle effect, compaction strategies (observation masking vs. LLM summarization), and the warm vs. cold start spectrum.
- **Possible library entry:** `library/zylos-session-lifecycle-2026.md`
- **Research track:** Part of the AI agent memory research avenue — see below
- **Added:** 2026-04-20

### Source review: Cross-Session Persistence — EngineersOfAI
- **URL:** https://engineersofai.com/docs/agentic-ai/agent-memory/Cross-Session-Persistence
- **Why:** Full engineering architecture for cross-session agent memory — what state must/should/should-not persist, storage backend selection (Redis for core facts, PostgreSQL for session history, vector DB for archival search), session restoration warm-restart pattern, schema versioning across memory evolution, GDPR/privacy (right to erasure). The five-layer handoff model (state snapshot + narrative context + decision log + priority queue + warnings) is directly comparable to the Zanshin framework's `/whats-next` structure.
- **Possible library entry:** `library/engineersofai-cross-session-persistence.md`
- **Research track:** Part of the AI agent memory research avenue — see below
- **Added:** 2026-04-20

### Source review: Memory Management for AI Agents — Chenyu Zhang (Medium, Feb 2026)
- **URL:** https://medium.com/@fred-zhang/memory-management-for-ai-agents-from-cognitive-architectures-to-context-engineering-to-293ef6a4ccab
- **Why:** Survey of memory management approaches from cognitive architectures → context engineering → reinforcement-learned memory. Covers layered memory model (working / episodic / semantic / procedural / long-term), MemGPT's core/archival split as first formal treatment of cross-session persistence in LLM agents (Packer et al., 2023). Good conceptual foundation for the research avenue.
- **Possible library entry:** `library/zhang-ai-agent-memory-2026.md`
- **Research track:** Part of the AI agent memory research avenue — see below
- **Added:** 2026-04-20

### Source review: StatePlane — Cognitive State Plane for Long-Horizon AI (arxiv, 2026)
- **URL:** https://arxiv.org/html/2603.13644v1
- **Why:** Academic paper proposing a model-agnostic cognitive state plane for episodic, semantic, and procedural memory. Formalizes episodic segmentation, selective encoding, goal-conditioned retrieval, and adaptive forgetting. Most directly relevant to the "judgment not retrieval" distinction in the Zanshin essay — this is a technical paper doing exactly what the essay says engineering approaches don't do. Worth reading carefully before making claims about where the engineering gap is.
- **Possible library entry:** `library/stateplane-cognitive-state-2026.md`
- **Research track:** Part of the AI agent memory research avenue — see below
- **Added:** 2026-04-20

### Framework: two-second hold — add a session-close pause ritual to /whats-next and /checkpoint
- **Product:** meta (commands)
- **Context:** From Saito Sensei's Aikido instruction: "hold your form for two seconds after the technique finishes. Don't relax. Don't look for confirmation. Remain connected." The framework equivalent: before running `/whats-next` or `/checkpoint`, a brief deliberate prompt — "what did this session actually produce?" — before documentation begins. Currently the commands go immediately to capturing; the trained layer of zanshin requires a moment of genuine reflection first. Implementation: add a Step 0 to both commands that prompts this pause before any writing begins. Small change, high leverage on the trained vs. instrumented distinction.
- **Links:** `.cursor/commands/whats-next.md`, `.cursor/commands/checkpoint.md`, `docs/philosophy/zanshin.md` (instrumented/trained section)
- **Added:** 2026-04-20

### Framework: before/during/after organizing principle in session-framework.md
- **Product:** docs (ai-engineering)
- **Context:** The session framework document currently organizes behaviors around preventing failure modes (statelessness, compaction, frictionlessness). The zanshin research surfaces a better organizing principle: before (session-start orientation — `/start`, shoshin), during (checkpoint, SHA anchoring, compaction awareness), after (whats-next, handoff). This maps directly to zanshin's before/during/after structure and is more intuitive for new readers — it answers "when do I do what?" rather than "what failure mode does this prevent?" Consider restructuring `session-framework.md` around this three-moment axis, or adding a summary table at the top that maps each behavior to before/during/after.
- **Links:** `docs/ai-engineering/session-framework.md`, `docs/philosophy/zanshin.md`
- **Added:** 2026-04-20

### Framework: "natural state restored" framing in framework-bootstrap.md
- **Product:** docs (ai-engineering)
- **Context:** The bootstrap document is the single-file entry point for new users and other tools. Its current framing implies the framework installs something new. The zanshin natural-state framing is more accurate and more compelling for external readers: "You wouldn't forget what you decided yesterday if you were working with a human collaborator. The model forgets by design. The framework restores the conditions under which coherent work naturally happens." One sentence that makes the case without requiring background. Consider adding this to the opening or rationale section of `framework-bootstrap.md`.
- **Links:** `docs/ai-engineering/framework-bootstrap.md`, `docs/philosophy/zanshin.md`
- **Added:** 2026-04-20

### Framework: "connection" framing in sparring-and-shoshin.md
- **Product:** docs (ai-engineering)
- **Context:** The Aikido source frames zanshin as *connection* — staying connected to the work and the opponent through the technique. This sharpens how the two practices relate: shoshin is about staying connected to what the work is actually about (not what you've assumed it's about); sparring is about staying connected to whether the work is doing what you think it's doing. Both are "maintained connection to what's real" — a framing that makes their complementary relationship clearer than the current "sparring challenges outputs, shoshin challenges starting frames" description. Worth adding a sentence or two to `sparring-and-shoshin.md` that names this shared root.
- **Links:** `docs/ai-engineering/sparring-and-shoshin.md`, `docs/philosophy/zanshin.md`
- **Added:** 2026-04-20

### Research avenue: AI agent memory and cross-session coherence
- **Product:** research (new directory)
- **Context:** Four sources found during Zanshin essay spar research represent an active, fast-moving area of AI engineering directly relevant to this framework. What others are building addresses the same problem the Zanshin framework addresses from the practitioner side — but from the engineering side. Reading this literature would: (1) sharpen what claims the essay can and can't make, (2) surface techniques worth adopting or adapting in the framework, (3) provide external evidence and counterpoint for the `research/framework-efficacy/` track. The Carnival9 convergence ("execution trace is source of truth; memory is derived state") is the most interesting data point — an independently developed system arrived at the same architectural principle as "commits as truth anchors." That's worth understanding more deeply.
- **Proposed directory:** `research/ai-agent-memory/` — sources, notes, and synthesis
- **First step:** Read the four backlog sources above; pull any worth keeping into `library/`; open a synthesis note on where the engineering solutions end and the practice gap begins
- **Added:** 2026-04-20

### ~~Case study: link depth drift — when a folder move silently breaks navigation~~ ✓ Done 2026-04-20
- Published as `docs/case-studies/link-depth-drift.md`. Companion to the gitignore drift case: same directory reorganization, different failure surface. 23 links off by exactly one `../`, none signaled at commit time, found by audit months later. Covers the mechanism (relative upward links encode depth), the silence signature (uniformity), and the pre-commit check now in `repo-structure.md`. Registered in case studies README.

### Case study: when the framework became tool-portable
- **Product:** docs (case-studies)
- **Context:** The peer parallel problem session (Ansible playbook from a manual procedure) showed that the Zanshin framework can be loaded into GitHub Copilot by cloning the repo alongside a project on the filesystem. First evidence the framework is tool-agnostic. The `framework-bootstrap.md` doc was built as a direct result — a single-file entry point designed for exactly this load pattern. Case study would cover: the accidental discovery, the bootstrap design decisions, what "minimum viable load" means, and the open question of which framework components drove the generation quality difference. Connects to the cross-tool portability claim in the framework efficacy track.
- **Links:** `docs/ai-engineering/framework-bootstrap.md`, `research/framework-efficacy/intervention-log.md`
- **Added:** 2026-04-20

### Framework bootstrap: peer comparison follow-up
- **Product:** research / meta
- **Context:** In a parallel problem session, Henry loaded the framework into GitHub Copilot by cloning this repo alongside a private project and asking Copilot to read it. Peer used standard Copilot. Copilot compared both solutions; Henry's was preferred on first pass. First cross-practitioner, cross-tool comparative event — logged in `research/framework-efficacy/intervention-log.md`. **Follow-up needed:** (1) record what problem was being solved, (2) confirm exactly which files Copilot loaded, (3) repeat with the same or different peer, using `framework-bootstrap.md` as the explicit single-file load, (4) log the comparison in the counterfactual protocol. The bootstrap doc now exists — this is about repeating and instrumenting the experiment, not about building more infrastructure.
- **Links:** `research/framework-efficacy/intervention-log.md`, `docs/ai-engineering/framework-bootstrap.md`
- **Added:** 2026-04-20

### ~~Essay: "Prompting is necessary but not sufficient — tackling state management"~~ ✓ Done 2026-04-20
- Published as `docs/ai-engineering/prompting-and-state.md`. Argues the two failure modes (within-session quality vs. cross-session coherence) are independent and compound when both are addressed. Companion to `session-framework.md` (the how) — this argues the why it matters and what the gap is. Registered in `docs/ai-engineering/README.md` and `docs/README.md`.

### Essay / guide: crafting a public identity for an AI workspace — the ABOUT.md pattern
- **Product:** docs (meta / AI-engineering)
- **Context:** This session produced a real workflow: resume → collaborative ABOUT.md → person-first public context that the AI reads and humans can share. The process involved sparring on labels ("systems engineer" vs. "engineer" vs. "omni-competent"), shoshin on what an external reader actually needs, and two rounds of cuts (too wordy, too much lifted input). The output — a short, honest about page that describes the person rather than the current corpus — is a generalizable pattern for any AI workspace intended as a public record. Worth documenting: what makes a good ABOUT.md, why it's different from a resume, how it affects AI behavior, and the specific failure mode it prevents (corpus-to-identity conflation). Companion to the "When the Repository Becomes the Resume" case study.
- **Links:** `docs/case-studies/when-the-repository-becomes-the-resume.md`, `ABOUT.md`, `.cursor/rules/cross-linking.md`
- **Added:** 2026-04-20

### ~~Case study: feedback from an AI is still a symptom report, not a diagnosis~~ ✓ Done 2026-04-20
- Published as `docs/case-studies/ai-self-diagnosis-symptom-report.md`. Registered in `docs/case-studies/README.md` and `docs/README.md`.

### Case study: language precision matters — how /spar sharpened a framework artifact
- **Product:** docs (case-studies)
- **Context:** The 2026-04-20 session that produced the session-brief pattern ran three full spar rounds on the same framework artifacts, each finding genuine structural issues — not presentation problems. Round 1 (private session, pre-switch): caught "clean room" as an inaccurate metaphor, lifecycle ceremony front-loading, and premature stability claims in the concept doc. All fixed before the public session opened. Rounds 2–3 (public session, post-implementation): caught the opt-in shoshin defeat (making the brief alignment check opt-in removes the mechanism that made it valuable), the table inconsistency introduced by adding the guardrail, and the ordering problem (state check should run before absorbing the brief's framing, not after). Each round found structural issues, not style issues — suggesting the initial spec was genuinely underspecified, not just imprecisely expressed. The meta-lessons: (1) clear language in framework artifacts matters — imprecise metaphors propagate as if precise; (2) framework artifacts benefit from adversarial review loops before being treated as stable; (3) the scope/state distinction (briefings provide scope, state checks provide accuracy) only emerged under adversarial pressure — it wasn't obvious at design time. Connects to: prompt engineering as precision engineering; the spar-before-committing pattern as hygiene, not exception.
- **Links:** `docs/ai-engineering/interaction-patterns.md`, `docs/case-studies/spar-finds-the-assumption.md`
- **Added:** 2026-04-20

### Essay: the public AI workspace as a professional record — questions of identity, authorship, and audience
- **Product:** docs (philosophy / AI-engineering bridge)
- **Context:** This session surfaced several interconnected questions: What does it mean to have a public AI-assisted workspace? Who is the audience? Is it a resume, a portfolio, a journal, a resource for others? How do you name yourself in a space where AI has contributed substantially to the content? The "Field Notes" branding conversation, the ABOUT.md drafting, and the corpus-to-identity case study all circle the same question: in a public AI workspace, how do you establish authorship and identity when the work is collaborative by design? Distinct from the "AI writes in your voice" case study — that's about a specific failure mode; this is about the broader philosophical question of what it means to have a public AI-assisted body of work.
- **Added:** 2026-04-20

### Idea: provenance markers on case studies — who noticed the failure?
- **Product:** docs / meta
- **Context:** The strongest argument from a `/spar` session: AI assistants write the case studies about AI failures, which creates a structural conflict of interest. An AI describing its own failure is likelier to frame recovery as the story and downplay severity. The gitignore case study was a clean example — originally titled "What This Session Did Right," which minimized. The fix required explicit user feedback to reframe. A provenance marker on each case study (`noticed_by: user | AI | external tool | reviewer`) would surface this pattern over the collection: if most failure-mode case studies are AI-noticed, that's worth knowing. Could also flag which case studies have had their framing challenged by the user vs. published as-is. Not a blocking concern — but worth encoding before the collection grows large enough that auditing it manually becomes hard.
- **Possible implementation:** One line in frontmatter. No UI needed — just a convention for cross-collection analysis later.
- **Added:** 2026-04-20

### ~~Case study: The Frictionless Entity~~ ✓ Done 2026-04-20
- Published as `docs/case-studies/frictionless-entity.md`. Names the core failure mode sparring and shoshin defend against: AI is structurally optimized to be frictionless, and naive use atrophies the capacity for friction-dependent judgment in both professional and personal contexts. Cross-domain source: Kate Cassidy's analysis of AI in relationships. Registered in case studies README (#22). Linked from `sparring-and-shoshin.md` starting points table.

### ~~Case study: When the System Boundary Is the Argument~~ ✓ Done 2026-04-20
- Published as `docs/case-studies/spar-lifecycle-boundary.md`. Documents the lifecycle boundary question as a named sparring move: where you draw the system boundary determines what the number says, and the boundary choice is where the actual argument is often happening. Illustrated by Hank Green's AI water use analysis. Registered in case studies README (#23).

### ~~Library entry: Hank Green — AI Water Use~~ ✓ Done 2026-04-20
- Added `library/hank-green-ai-water-use.md` and catalog row. Models intellectual humility in technical discourse (shoshin applied publicly) and provides the worked example for the lifecycle boundary sparring methodology.

### ~~Essay 2 planning: AI training attribution thread~~ ✓ Done 2026-04-20
- Added sub-bullet to Thread 11 in `.planning/zen-karate/threads.md`. The attribution/compensation problem (AI companies building on expert communities without credit or payment) is a contemporary instantiation of the dojo's lineage obligation. Source: "The Mythos Situation" (TheStandup/PrimeTime, 2026).

### ~~Intro page: sparring and shoshin (shareable with peers)~~ ✓ Done 2026-04-20
- Published as `docs/ai-engineering/sparring-and-shoshin.md`. Covers both practices, how they complement each other, and links to the deeper case studies and philosophy essays. Added to `docs/README.md` index as a companion guide to the engineering track.

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

### ~~Case study: model self-report of runtime state~~ ✓ Done 2026-04-20
- Published as `docs/case-studies/model-self-report-runtime-state.md`. Cross-linked from `local-llm-setup.md`. Source: experiment journal 2026-04-20 RamaLama entry.

### ~~Case study: model self-report of runtime state — context window edition~~ ✓ Done 2026-04-20
- Covered in `docs/case-studies/model-self-report-runtime-state.md` (the 32k self-report vs. 14k actual `n_ctx` is the central example of that case study). No separate document needed.

### ~~Case study: survivorship bias in recommendations~~ ✓ Done 2026-04-20
- Published as `docs/case-studies/survivorship-bias-recommendations.md`. Documents elimination-framing dressed as quality recommendation, with the local LLM failure sequence as the worked example. Registered in case studies README.

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

### Essay: AI as a restructuring technology — navigating the transition from inside it
- **Product:** docs (philosophy / bridge)
- **Track:** Philosophy and Practice — anchor essay for the track
- **Context:** Every transformative technology has followed the same pattern: initially looks like a faster version of what existed, then it becomes clear it's restructuring the substrate — what gets valued, what atrophies, what new capacities become possible. Printing press restructured authority and religious power. Industrial revolution restructured labor and embodied skill. Internet restructured attention, expertise, and community. AI is doing this now, and most discourse treats it as a productivity tool rather than a substrate change. This essay names the pattern, draws the parallels explicitly, and then asks the practitioner's question: what is it like to be *inside* one of these transitions rather than looking back on it? What did the monks who copied manuscripts feel when printing arrived? What did the craftsmen feel during industrialization? The collection's philosophical core — Zen, karate, beginner's mind, non-attachment — is most defensible not as "nice ideas for engineers" but as practices developed specifically for maintaining orientation when the ground shifts. This essay makes that case directly and gives the philosophy track a proper anchor that explains *why* contemplative practice applies to an AI transition.
- **How it unifies the collection:** *The Shift* documents tool-level changes. *The Dojo After the Automation* asks what happens to people. *Ego, AI, and the Zen Antidote* addresses the psychological layer. This essay provides the frame that makes them cohere: not three takes on AI productivity, but three levels of the same restructuring — practice, institution, person.
- **Starting points for research:** history of printing press adoption (practitioners' experience, not just outcomes), industrial revolution skill displacement accounts, internet's restructuring of expertise and attention (Clay Shirky's *Here Comes Everybody* is a candidate), Zen and martial arts as transition practices (the connection is in the literature, not just analogy).
- **Links:** `docs/philosophy/the-dojo-after-the-automation.md`, `docs/philosophy/ego-ai-and-the-zen-antidote.md`, `docs/ai-engineering/the-shift.md`, `.planning/zen-karate/`
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
- **Hardware note:** Current Z690-P platform limits to single-GPU. For 70B fully on GPU need platform rebuild (Threadripper Pro WRX90 + 2× RTX 3090 NVLink ≈ $5–10k, or 2× RTX 5090 PCIe ≈ $7–18k total). Hybrid CPU+GPU offload is possible but **requires native Ollama container, not RamaLama** — RamaLama forces `n_gpu_layers=999` (GPU-only); hybrid needs Ollama's automatic layer splitting. See experiment journal for 72B RamaLama failure.
- **Division of labor (current recommended):** Local model for single-file edits, quick lookups, config generation with known schema. Sonnet for research pipelines, sparring, essays, session planning, anything requiring workspace-wide context.
- **Self-referential note:** Some workspace complexity (meta-framework depth, inter-file dependency chains) emerged because large-context models made it tractable. Worth a future `/spar` pass: is the complexity serving the work, or has the work started serving the complexity?
- **Links:** `research/ai-tooling/local-llm-experiment-journal.md`, `docs/ai-engineering/local-llm-setup.md`, `.cursorrules`, `.cursor/rules/`
- **Added:** 2026-04-20

### Watch: vLLM FP8 MoE support for gfx1100 (RDNA3)
- **Product:** meta / research
- **Context:** vLLM's fused MoE kernels (`fused_moe_fp8`) are tuned for MI300X (gfx942/CDNA3) and don't work on RX 7900 XT (gfx1100/RDNA3). The hardware has FP8 silicon capability (RDNA3 matrix accelerator includes FP8 dot products); the gap is Triton kernel autotuning configs for gfx1100. This blocks running Qwen3-Coder-Next-FP8 (and similar FP8 MoE models) via vLLM on consumer AMD hardware. Unlock: either vLLM ROCm team expands gfx1100 support, or someone contributes Triton kernel configs for gfx1100 to vLLM's fused_moe layer. Current workaround: llama.cpp/RamaLama (GGUF Q4 path — fully working, ~90 tok/s on qwen3:30b-a3b). **No action needed now — check periodically when evaluating vLLM upgrades.**
- **How to check:** `pip install --upgrade vllm && vllm serve Qwen/Qwen3-Coder-Next-FP8 --dtype fp8` and watch for gfx1100 in the supported device list or working inference.
- **Links:** `research/ai-tooling/local-llm-experiment-journal.md`, `docs/ai-engineering/local-llm-setup.md`
- **Added:** 2026-04-20

### Quality comparison: qwen2.5:32b vs qwen3:30b-a3b on real tasks
- **Product:** research / docs
- **Context:** Speed benchmarked (2026-04-20): qwen2.5:32b = 19.4 tok/s generation; qwen3:30b-a3b = ~90 tok/s. qwen2.5:32b is 4.7× slower but dense — may outperform MoE on complex multi-step reasoning. Both cap at n_ctx=4096 on this hardware. **What remains:** run a real representative task (multi-file reasoning, essay drafting) on both models; assess output quality difference; decide which becomes the electricity measurement baseline.
- **Links:** `research/ai-tooling/local-llm-experiment-journal.md`
- **Added:** 2026-04-20

### Case study: graph splits — why hybrid CPU+GPU inference fails at scale
- **Product:** docs
- **Context:** qwen2.5:72b on RX 7900 XT (20 GB VRAM): 36% GPU / 64% CPU split, 718 graph switches per prefill batch, >6 minutes to first token on a short prompt. The bottleneck isn't compute — it's PCIe bus saturation from the activation hand-offs between the 29 GPU layers and 52 CPU layers. Counterintuitive finding: 62 GB system RAM provides no meaningful help when the bus is the constraint. Contrast with bs=1 (generation phase) which has only 3 graph splits — the asymmetry explains why prefill is brutal and generation *might* be tolerable if you ever reached it. Good explainer material for engineers who assume "more RAM = can run bigger models." Also documents the contrast with full-GPU inference (qwen3:30b-a3b: ~90 tok/s, 3–5 splits). Source: experiment journal 2026-04-20.
- **Links:** `research/ai-tooling/local-llm-experiment-journal.md`, `docs/ai-engineering/local-llm-setup.md`
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

### ~~`/audit`: detect orphaned docs not referenced in master index~~ ✓ Done 2026-04-20
- Implemented as a two-tier check in `/audit` Layer 2d: **true orphan** (not in any README — structural bug) vs. **curated omission** (in track README but not master index — intentional). Uses PCRE extraction for clean path parsing. Verified against current corpus: zero true orphans, zero stale master refs. Three files (`local-llm-setup.md`, `local-llm-vllm.md`, `youtube-video-analysis.md`) confirmed as intentional curated omissions from the master reading path. Also fixed Layer 1 link-check regex (was capturing link text + path; now captures path only via lookbehind).

### Index: surface review status as a trust signal (undecided)
- **Product:** meta
- **Status:** idea — undecided whether to pursue
- **Context:** Most docs are unreviewed or direction-reviewed; only 3 files have `status: reviewed` as of 2026-04-20. Surfacing review status in `docs/README.md` as a sorting key or trust signal was considered and deferred — too few reviewed files for it to be meaningful signal, and risks optimizing reviews for index position rather than quality. Revisit when reviewed coverage improves meaningfully (rough threshold: 30%+ of docs fully reviewed). Possible implementation: "(author reviewed)" parenthetical in descriptions of fully-reviewed pieces; not a sorting key.
- **Added:** 2026-04-20

### ~~docs/README.md — consider unordered lists for case study categories~~ ✓ Done 2026-04-20
- Converted all three case study categories (Build / Failure / Workflow) to unordered lists. Essays (1–11 across AI-engineering and philosophy tracks) remain numbered — reading order matters there. The cross-ref audit found numeric references only in `BACKLOG.md` internal notes; those have been updated to use titles. Sparring-and-shoshin guide moved from awkward sub-bullet to a "Companion guides" unordered section after the AI-Engineering essays.

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
- **Context:** When generating content, the AI signals its own trustworthiness through language ("the common framing often gets the math wrong," "Honest Assessment" section headers, "this is where real data changes the conversation") while simultaneously making unverified claims. The honesty label becomes a rhetorical move rather than an earned quality. The pattern: self-referential honesty claims appear in body text where readers encounter them with full confidence, while the actual verification status lives in frontmatter or a footer most readers never reach. Observed in `docs/ai-engineering/local-llm-setup.md` round 1 spar. **New instance (2026-04-20):** `docs/ai-engineering/session-framework.md` originally contained "Five minutes to write, thirty seconds to read" describing `/checkpoint` — a specific-sounding claim asserted with no measurement, designed to make the tool feel lightweight. Caught by the user ("for a human or for you?"), removed as a fabricated metric. This is a clean documented instance: precise numbers that weren't measured, used rhetorically. A related sub-pattern also appeared in the same document: the opening sentence stated "two structural characteristics" while the following paragraph listed three — confident assertion of a number directly contradicted by adjacent content. Both are variants of performed precision: using specific figures to project accuracy the content doesn't have.
- **Links:** `docs/case-studies/README.md`, `research/ai-tooling/local-llm-setup-sparring-notes.md`, `.cursor/rules/pre-commit-review.md`, `docs/ai-engineering/session-framework.md`
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
- **Context:** Thread 19. Drafted as `docs/philosophy/the-full-cup.md`. Needs author to add: specific stories, which Goal/Phoenix Project strategies map most directly, a real "right words" instance (bottom-right quadrant), and whether the "bow at the door" section needs a real professional example. Voice-approved validation required for any experiential content added. A professional instance of the cups-too-full pattern in platform migration work is in development — will be added at pattern level only (not instance-specific) when ready.
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

### ~~Repo reorganization: move DevOps technical samples into a subfolder~~ ✓ Done 2026-04-20
- Moved `ansible/`, `argo/`, `coreos/`, `ocp/`, `rhacm/`, `vault/` → `devops/{name}/`. Updated all cross-references in README, docs, .cursor/ commands/rules, .cursorrules, BACKLOG. Root directory now: `devops/ docs/ examples/ library/ research/`. Also produced a case study on the gitignore drift failure mode that emerged from the move.

### Expand OCP troubleshooting guides
- **Product:** ocp
- **Context:** Several existing troubleshooting guides could be expanded with additional detail or new guides added for common issues encountered in the field. The troubleshooting section is one of the most practical parts of the repo for peers.
- **Links:** `devops/ocp/troubleshooting/`
- **Added:** 2026-04-17

### Expand RHACM troubleshooting guides
- **Product:** rhacm
- **Context:** Two guides created 2026-04-21 from a live ACM 2.15 EUS upgrade session: managed cluster lease not updated (registration agent stopped updating its lease) and MCH stuck in Pending during upgrade (including the frozen `Progressing: False` condition scenario, stale ClusterRole conflict, and KB 7116241). The frozen-condition case is unresolved — open support case with Red Hat engineering citing KB 7116241 for a production-safe remediation path that does not require MCH delete/recreate. Update guides with outcome once resolved.
- **Links:** `devops/rhacm/troubleshooting/`
- **Added:** 2026-04-21


### CoreOS troubleshooting section
- **Product:** coreos
- **Context:** Currently only have `devops/coreos/examples/` with Butane configurations. No troubleshooting guides yet. Could document common ignition/butane issues encountered during deployments.
- **Links:** `devops/coreos/examples/`
- **Added:** 2026-04-17

### Paude as external executor for meta-prompting pipelines
- **Product:** meta
- **Context:** If the Paude evaluation succeeds (see `.planning/paude-integration/`), explore wiring it into the meta-prompting architecture as an alternative execution backend. Integration points: a `/paude` slash command wrapping create -> assign -> harvest; a `--paude` flag in `/run-prompt` to delegate to a container session instead of a Task subagent; a Paude variant for `/run-plan` strategy C (plans without interactive checkpoints); a "containerized executor" pattern in the orchestration references; multi-agent comparison (`--agent claude` vs `--agent gemini`) as a first-class option for adversarial review. Fundamentally different from in-session Task subagents — Paude is fire-and-forget with git sync, not shared-context pipelines.
- **Links:** https://github.com/bbrowning/paude, `.planning/paude-integration/`, `.cursor/skills/create-subagents/references/orchestration-patterns.md`
- **Blocked on:** Paude evaluation Phase 5 assessment
- **Added:** 2026-04-17

## Done

Rolling cap: at most **15** items stay here (newest first). Older completions live in `BACKLOG-ARCHIVE.md` (see `/backlog` command — **Done retention**). Git history remains authoritative.

### Meta: full content audit + systemic link/registry fixes ✓ Done 2026-04-20
- Ran `/audit` across 717 committed markdown files. Fixed 29 files: 23 `AI-DISCLOSURE.md` link depth errors (all caused by devops folder move — paths uniformly off by one `../`), 5 docs missing from `docs/README.md` (including `framework-bootstrap.md`), 3 research dirs missing from `research/README.md`, missing Zanshin anchor links in `the-shift.md`, 6 devops internal cross-links. Root-caused the false-positive problem (260/353 "broken links" were scraped web content + fenced code blocks). Applied three systemic fixes: audit Layer 1 exclusions, `/whats-next` registry sync check, `repo-structure.md` link-depth-drift guidance for directory moves.
- **Links:** commits `624d386`, `d948f78`, `c9201fa`

### Framework: spar trigger evaluation hook ✓ Done 2026-04-20
- Added Step 2.4 to `/checkpoint` and Step 1.3 to `/whats-next`: evaluate six (seven at session close) spar trigger conditions and surface a recommendation if two or more fire. Distinguishes necessary (argumentative + external-facing, or load-bearing claim + trade-off decision) from beneficial (any two triggers) from skip (mechanical session). Never auto-runs — always asks first.
- **Links:** `.cursor/commands/checkpoint.md`, `.cursor/commands/whats-next.md`

### Framework: /start simplification audit ✓ Done 2026-04-20
- Audited all `/start` steps against "does the user need this every session?" Steps 2.5 (brief alignment) and 4 (ROADMAP status) both load every planning project file on every session start — cost grows proportionally as the workspace grows. Made both opt-in: Step 2.5 now announces planning projects without reading BRIEFs; Step 4 only reads ROADMAPs when the user is resuming a specific project. Steps 0, 1, 2, 3, 5 stay always-on (ABOUT.md, backlog, handoff, git log, suggestions — all genuinely needed every session).
- **Links:** `.cursor/commands/start.md`

### Framework: stack-based conversation tracking ✓ Done 2026-04-20
- Added push/pop posture to `.cursor/rules/session-awareness.md` — recognizes depth-first navigation as a conversational posture, not a state machine; agent surfaces "that feels resolved — want to return to X?" when a branch concludes. Added optional `**Open threads (stack):**` field to both `/checkpoint` and `/whats-next` formats.
- **Links:** `.cursor/rules/session-awareness.md`, `.cursor/commands/checkpoint.md`, `.cursor/commands/whats-next.md`

### Research: Miessler Single DA Thesis — transcript, full pipeline, Thread 21
- **Product:** library / research / docs
- **Context:** Fetched and fully analyzed Miessler's "We're All Building a Single Digital Assistant" (32 min, Unsupervised Learning). Ran complete research-and-analyze pipeline: proper directory structure (`research/miessler-single-da-thesis/`), manifest, transcript in `sources/`, batch findings (core thesis + workspace connections), assessment. Created library entry with confidence table and upstream cross-reference into PAI entry. Cross-linked into Dojo After the Automation essay (Sources + Related Reading). Added Thread 21 (The Amplification Line) to zen-karate threads — the question of when DA delegation amplifies vs. forecloses development. Also documented and remediated systematic skill compliance failures from the initial fetch session.
- **Links:** `research/miessler-single-da-thesis/`, `library/daniel-miessler-single-da-thesis.md`, `library/catalog.md`, `docs/philosophy/the-dojo-after-the-automation.md`, `.planning/zen-karate/threads.md`
- **Completed:** 2026-04-18

### Case study: spar-distortion — when the sparring partner shapes the fighter
- **Product:** docs
- **Context:** Self-spar (#13-18) caught that the Dojo After the Automation essay's oppositional framing was a distortion created by the spar-driven drafting process. Essay revised from "I disagree" to "I agree AND." Case study documents tool-induced bias: the same tool that catches bias created it. Labeled `failure` — adversarial energy absorbed into structure. Registered in case studies README (failure category) and docs reading order.
- **Links:** `docs/case-studies/spar-distortion.md`, `docs/philosophy/the-dojo-after-the-automation.md`, `research/zen-karate-philosophy/sparring-notes.md`
- **Completed:** 2026-04-18

### Dojo After the Automation — revised from opposition to extension
- **Product:** docs
- **Context:** Major reframe after self-spar: "Two Prescriptions" → "The Same Direction." Human 3.0 as shared destination; essay asks who builds the humans. Future A reattributed to cost-reduction CFO, not Miessler. Capability stack engaged directly. Federation/Borg replaced with middle-ground acknowledgment. Library entries updated: "counter-tension" → "shared direction." Sparring notes round 2 (#13-18) logged.
- **Links:** `docs/philosophy/the-dojo-after-the-automation.md`, `library/daniel-miessler-ai-replace-knowledge-workers.md`, `library/daniel-miessler-pai.md`
- **Completed:** 2026-04-18

### Case study: spar-to-essay pipeline (spar #9 → Thread 20 → drafted essay)
- **Product:** docs
- **Context:** Published case study documenting how adversarial argument #9 escalated from counter-position through voice inputs to Thesis D, Thread 20, and a fully drafted essay in one session. Spar as generative pressure, not just quality gate. Registered in both READMEs.
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

### Framework efficacy measurement system
- **Product:** meta / research
- **Context:** Built `research/framework-efficacy/` research track: `intervention-log.md` (append-only log of intervention events, seeded with IPv8 session), `counterfactual-protocol.md` (5-dimension rubric for `/spar --measure` controlled comparison), `README.md` (what the track can and can't claim). Hooked into `/whats-next` (Step 1.5), `/checkpoint` (Step 2.5), and `/spar` (`--measure` flag for naive+structured comparison). Seeded with first entry from the IPv8 spar session.
- **Links:** `research/framework-efficacy/`, `.cursor/commands/whats-next.md`, `.cursor/commands/checkpoint.md`, `.cursor/commands/spar.md`
- **Completed:** 2026-04-20


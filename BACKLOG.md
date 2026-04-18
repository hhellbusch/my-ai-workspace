# Backlog

> Last updated: 2026-04-18

## In Progress

### Helm chart upstream contribution
- **Product:** argo
- **Context:** Improving chart templates in `git-projects/helm-charts/`. Working branch has changes ready for review and testing before submitting upstream.
- **Links:** `git-projects/helm-charts/`, `git-projects/README.md`
- **Started:** 2026-03

## Up Next

### Add AI disclosure check to pre-commit review
- **Product:** meta
- **Context:** The pre-commit review rule (`.cursor/rules/pre-commit-review.md`) checks file placement, READMEs, cross-references, content quality, secrets, and backlog alignment — but doesn't verify that new `docs/` files include the standard AI disclosure footer. Adding a step would catch missing footers before commit.
- **Links:** `.cursor/rules/pre-commit-review.md`, `.planning/zen-karate/STYLE.md` (footer template), `AI-DISCLOSURE.md`
- **Added:** 2026-04-18

### Harmonize DevOps README disclosure notices
- **Product:** docs
- **Context:** DevOps READMEs (ansible, ocp, argo, coreos, rhacm, vault) have various disclosure notices — some link to `AI-DISCLOSURE.md`, some have inline notices, some have nothing. Predates the current standard. Evaluate whether to normalize to the new footer or leave as-is (they serve a different audience than the essays).
- **Links:** `AI-DISCLOSURE.md`
- **Added:** 2026-04-18

### Zen-karate personal knowledge base — experiential content (CRITICAL PATH)
- **Product:** docs
- **Context:** Template and structural scaffolding complete. AI-enriched content in place: training history, lineage maps, teachers/influences (Shihan, Sensei, Inoue, Rika Usami), Athens club context, notes/fragments. **What remains is the experiential core that only the user can provide:** formative moments, philosophical anchors (what concepts mean through practice), life application examples, Shi Heng Yi connection, "what's hard to convey," and the crystallizing moments for Shihan and Sensei. This is the critical path to essay readiness — without it, drafting leans on research rather than practitioner voice.
- **Links:** `research/zen-karate-philosophy/personal-notes.md`, `.planning/zen-karate/`
- **Added:** 2026-04-17

### Essay: The Way Is in Training (PRIORITY — first essay)
- **Product:** docs
- **Context:** First essay in the zen-karate series (swapped from second position). The philosophical anchor: what lifelong practice teaches that cannot be learned from books. Inoue's "if kihon can do, any kata can do" as the spine. The Hayashi → Inoue → Usami lineage as visible proof that the Way transmits through training. Rika's 7-year journey, 5-hour train rides, retirement at 27 as non-attachment. The uchi-deshi experience in Inoue's own words. Deshimaru's "every moment of life is kata." The personal return to practice after the gap — what survived, what atrophied, what the body remembers. Draws from threads 2, 4, 5, 7, 12, 13, 15. Source material is deep (3 Inoue sources, Rika bio, Hayashi bio, Jesse Enkamp articles, Deshimaru). **Blocked on personal experiential content in Phase 1.**
- **Source material available:** Inoue comprehensive bio + teaching philosophy, Rika Usami biography, Hayashi biography, Jesse Enkamp articles (5), Deshimaru, personal practice notes (partial — needs formative moments, philosophical anchors).
- **Links:** `.planning/zen-karate/threads.md`, `.planning/zen-karate/`, `research/zen-karate-philosophy/sources/`
- **Added:** 2026-04-17

### Essay: The Dojo, Open Source, and Ways of Working (second essay)
- **Product:** docs
- **Context:** Second essay in the zen-karate series (moved from first position). Takes the philosophical vocabulary from Essay 1 and applies it: the dojo as "a place of the Way" adopted — sometimes deeply, often superficially — in agile transformation (engineering dojos), open source culture (contributor etiquette, senpai/kohai in PR review), and DevOps practice (code kata, architectural kata). What's lost when teams borrow the vocabulary without the philosophy. Draws from threads 3, 6, 7, 10, 11, 12. Connects to `docs/ai-engineering/ai-assisted-upstream-contributions.md` as a worked example. **Needs targeted research on agile dojo movement (Target, Ford, Pivotal Labs), open source etiquette formalization, code kata origins (Dave Thomas).**
- **Source material available:** Deshimaru, Shi Heng Yi transcript, upstream contributions essay, Inoue "no style" philosophy, Jesse Enkamp articles. Agile dojo research still needed.
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

### Session boundary anchoring — /start and /whats-next improvements
- **Product:** meta
- **Context:** `/start` checks for `whats-next.md` as Step 1 — before the backlog, before planning status — and asks "Want to pick up where you left off?" This gives the previous session's framing structural primacy, anchoring the next session on continuity rather than first-principles priority assessment. Same mechanism as the prioritization bias problem: AI writes the handoff, AI reads the handoff, AI weights it highly. Three identified fixes: (1) reorder `/start` to show backlog first, handoff second (context before continuity); (2) make `/whats-next` conditional — only create handoffs when there's genuinely in-flight state not captured in committed artifacts; (3) add a staleness/decay check for old handoffs. Related concern: reflexive handoff creation adds noise when a session's work is fully persisted in `.planning/` and `BACKLOG.md`.
- **Links:** `.cursor/commands/start.md`, `.cursor/commands/whats-next.md`, `.cursor/rules/session-awareness.md`
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

### Explore Paude for containerized agent workflows
- **Product:** meta
- **Context:** [Paude](https://github.com/bbrowning/paude) runs AI coding agents (Claude Code, Cursor CLI, Gemini CLI, OpenClaw) in secure containers with git-based sync. Could strengthen the meta-prompting system by enabling isolated, parallelizable agent sessions — e.g., running research, drafting, and review agents concurrently in containers with `--yolo` safely enabled, or orchestrating fire-and-forget agent tasks against this workspace. Worth exploring whether its orchestration model (harvest, PRs, multi-session) maps to the multi-stage meta-prompt pipelines already in use here.
- **Links:** https://github.com/bbrowning/paude, `.planning/paude-integration/`
- **Added:** 2026-04-17

### Expand OCP troubleshooting guides
- **Product:** ocp
- **Context:** Several existing troubleshooting guides could be expanded with additional detail or new guides added for common issues encountered in the field. The troubleshooting section is one of the most practical parts of the repo for peers.
- **Links:** `ocp/troubleshooting/`
- **Added:** 2026-04-17

### Case study: the thread development pass — landscape assessment before depth
- **Product:** docs
- **Context:** Documents how a full-pass landscape assessment of 16 essay threads — with integrated sparring, gap categorization, and honest ratio assessment — produced better triage than sequential deep dives would have. Reveals the ~20/80 practitioner-vs-research ratio, surfaces thread contradictions only visible at landscape scale, and demonstrates sparring-during-development as distinct from sparring-after-review. Connects to meta-development loop and adversarial review patterns.
- **Links:** `.planning/zen-karate/workflow-notes.md`, `.planning/zen-karate/thread-development.md`, `docs/case-studies/adversarial-review-meta-development.md`, `docs/ai-engineering/the-meta-development-loop.md`
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

### Case study: fabricated URL in the sycophancy section
- **Product:** docs
- **Context:** AI fabricated a plausible Anthropic URL while defining sycophancy, demonstrating a related failure mode in the same paragraph. Documented as a case study tracing the immediate fix (corrected URL) and systemic fix (external URL verification rule and /review check).
- **Links:** `docs/case-studies/fabricated-references.md`, `.cursor/rules/cross-linking.md`, `.cursor/commands/review.md`
- **Completed:** 2026-04-17

### Case study: biographical content concern → voice-approved system
- **Product:** docs
- **Context:** Concern about AI-generated biographical claims (professional titles, experience statements, personal opinions) led to the voice-approved validation type. Documented as a case study exploring why "read" validation isn't sufficient for identity claims and how the distinction was integrated at every workflow checkpoint.
- **Links:** `docs/case-studies/who-is-speaking.md`, `.cursor/rules/review-tracking.md`, `AI-DISCLOSURE.md`
- **Completed:** 2026-04-17

### AI disclosure rewrite — honest review status
- **Product:** docs
- **Context:** Rewrote AI-DISCLOSURE.md from 270-line checklist to honest 50-line disclosure with three review tiers and validation types. Updated README notice, STYLE.md footer template, .cursorrules.
- **Links:** `AI-DISCLOSURE.md`, `README.md`
- **Completed:** 2026-04-18

### Biographical content tracking — `voice-approved` validation type
- **Product:** meta
- **Context:** Added `voice-approved` as an elevated-priority validation type for content that speaks in the author's voice. Integrated across the full workflow: generation guidance (review-tracking rule, STYLE.md), pre-commit detection (`/review` biographical scan), content audit (`/audit` Layer 5b), validation command (`/validate` prompts for voice-approved), and disclosure policy (`AI-DISCLOSURE.md`). AI is now instructed to minimize unsolicited biographical content and flag it when generated.
- **Links:** `.cursor/rules/review-tracking.md`, `.cursor/commands/review.md`, `.cursor/commands/audit.md`, `.cursor/commands/validate.md`, `AI-DISCLOSURE.md`, `.planning/zen-karate/STYLE.md`
- **Completed:** 2026-04-18

### Review validation tracking system
- **Product:** meta
- **Context:** Built per-file review tracking via YAML frontmatter. New `/validate` command, `review-tracking` rule, Layer 5 in `/audit` for coverage reporting, coverage one-liner in `/start`, direction-reviewed note in `/review`. Validation types by content category: read, tested, fact-checked, commands-verified, used-in-practice, sources-checked.
- **Links:** `.cursor/commands/validate.md`, `.cursor/rules/review-tracking.md`, `AI-DISCLOSURE.md`
- **Completed:** 2026-04-18

### Update essay footers to new disclosure standard
- **Product:** docs
- **Context:** Updated all 16 essay footers from "written with AI assistance" to "created with AI assistance and has not been fully reviewed by the author." Preserved per-file context notes (GitHub Copilot attribution, source verification, real session note). Normalized `building-a-research-skill.md` custom section to include the standard link.
- **Links:** `AI-DISCLOSURE.md`, `.planning/zen-karate/STYLE.md`
- **Completed:** 2026-04-18

### Repository organization tooling
- **Product:** meta
- **Context:** Created `.cursor/rules/repo-structure.md` conventions rule and `/organize` audit command to keep the repo tidy.
- **Links:** `.cursor/rules/repo-structure.md`, `.cursor/commands/organize.md`
- **Completed:** 2026-04-17

### Product-based directory nesting
- **Product:** meta
- **Context:** Reorganized all technology-specific content under product directories (`ansible/`, `argo/`, `coreos/`, `ocp/`, `rhacm/`, `vault/`) with content-type subdirectories. Updated all internal references.
- **Links:** `.cursor/rules/repo-structure.md`
- **Completed:** 2026-04-17

### Remove non-functional iso-server tool
- **Product:** ocp
- **Context:** Removed `tools/iso-server.py` — HTTPS ISO server didn't work against Dell iDRAC virtual media for several reasons.
- **Completed:** 2026-04-17

### Move labs into product directories
- **Product:** argo
- **Context:** Moved `labs/lab-argocd-sync/` and `labs/lab-gitops/` into `argo/labs/` for consistency with product-based nesting.
- **Completed:** 2026-04-17

### Consolidate .prompts/ into prompts/
- **Product:** meta
- **Context:** Removed hidden `.prompts/` directory (leftover from older TACHES import) and moved the dell memory validation research prompt into the visible `prompts/` directory.
- **Completed:** 2026-04-17

### Project tracking system
- **Product:** meta
- **Context:** Designed and implemented `BACKLOG.md` with `/backlog` slash command, replacing the unused TACHES TO-DOS.md pattern with a persistent, shareable project board.
- **Links:** `BACKLOG.md`, `.cursor/commands/backlog.md`
- **Completed:** 2026-04-17

### Zen-karate essay library scaffolding
- **Product:** docs
- **Context:** Created planning artifacts (BRIEF, ROADMAP, STYLE guide), research workspace (personal-notes.md, curated-reading.md templates), and backlog items for the zen-karate essay series.
- **Links:** `.planning/zen-karate/`, `research/zen-karate-philosophy/`
- **Completed:** 2026-04-17

### Essay: Ego, AI, and the Zen Antidote
- **Product:** docs
- **Context:** Companion essay to *The Shift*. Connects Shi Heng Yi's teaching on ego as "a collection of thoughts," the mechanism of "hooking" onto identity, and zen practices (mushin, shoshin, non-attachment) as structural resistance to AI-fueled sycophancy. Bridges the AI essay track and the martial arts/zen track. Published at `docs/philosophy/ego-ai-and-the-zen-antidote.md`, cross-linked from *The Shift* and added to `docs/README.md`.
- **Links:** `docs/philosophy/ego-ai-and-the-zen-antidote.md`, `docs/ai-engineering/the-shift.md`, `.planning/zen-karate/threads.md` (thread 14)
- **Completed:** 2026-04-17

### AI prioritization bias — meta-system guard
- **Product:** meta
- **Context:** Implemented zero-base evaluation in `/backlog prioritize`: strips current section labels, scores items on merits, compares zero-base ranking against current ranking, and flags anchoring bias. Addresses the observed behavior where AI weights prior priorities into re-prioritization.
- **Links:** `.cursor/commands/backlog.md`
- **Completed:** 2026-04-17


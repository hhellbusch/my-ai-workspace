# Backlog

> Last updated: 2026-04-18

## In Progress

### Helm chart upstream contribution
- **Product:** argo
- **Context:** Improving chart templates in `git-projects/helm-charts/`. Working branch has changes ready for review and testing before submitting upstream.
- **Links:** `git-projects/helm-charts/`, `git-projects/README.md`
- **Started:** 2026-03

## Up Next

### Essay: The Dojo, Open Source, and Ways of Working (PRIORITY — first essay)
- **Product:** docs
- **Context:** First essay in the zen-karate series. The dojo as "a place of the Way" and how that concept has been adopted — sometimes deeply, often superficially — in agile transformation (engineering dojos), open source culture (contributor etiquette, senpai/kohai in PR review), and DevOps practice (code kata, architectural kata). Explores what's lost when teams borrow the vocabulary without the philosophy: cleaning the floor as shared ownership, kata as embodied learning not rote repetition, mutual respect within hierarchy. Draws from threads 2, 3, 6, 7, 10 as supporting ideas. Connects to the existing upstream contributions essay as a real worked example. This leads with because it's the most applied and accessible entry point — grounded in business outcomes (team capability, learning organizations, reducing key-person dependency) while introducing the philosophical foundation that deeper essays will build on.
- **Source material available:** Deshimaru (dojo, kata, gyodo), Shi Heng Yi transcript (master-student, teaching fish, lonely wolf), `docs/ai-assisted-upstream-contributions.md` (real open source example), agile dojo movement (needs targeted research). Personal notes will enrich but aren't blocking.
- **Links:** `.planning/zen-karate/threads.md`, `.planning/zen-karate/`, `docs/ai-assisted-upstream-contributions.md`
- **Added:** 2026-04-17

### Zen-karate personal knowledge base
- **Product:** docs
- **Context:** Structured template for capturing training history, key teachers, formative moments, philosophical anchors, and examples of how martial arts philosophy has guided life and work decisions. This is the most critical input to the essay series — everything downstream gets better when it has real personal experience to draw from. Template created at `research/zen-karate-philosophy/personal-notes.md`, needs user to populate.
- **Links:** `research/zen-karate-philosophy/personal-notes.md`, `.planning/zen-karate/`
- **Added:** 2026-04-17

### Zen-karate curated reading list
- **Product:** docs
- **Context:** Annotated bibliography of books, teachers, passages, and media that shaped a lifelong karate practice. Goes beyond what web research can find — captures why each source matters, not just what it says. Feeds directly into the research manifest. Template at `research/zen-karate-philosophy/curated-reading.md`, needs user to populate.
- **Links:** `research/zen-karate-philosophy/curated-reading.md`, `.planning/zen-karate/`
- **Added:** 2026-04-17

### Zen-karate essay voice/style guide
- **Product:** docs
- **Context:** Reference document defining the blended voice for the essay series: personal first-person for philosophical/experiential sections, practitioner tone for applied sections. Includes structural conventions, Japanese terminology approach, and "this, not that" examples. Referenced by all meta-prompts in the drafting pipeline.
- **Links:** `.planning/zen-karate/STYLE.md`, `.planning/zen-karate/`
- **Added:** 2026-04-17

### Headless browser fallback for research fetcher
- **Product:** meta
- **Context:** The research skill's `fetch-sources.py` gets blocked by some sites (HTTP 403/429). A headless browser fallback was designed during the skill validation run but not implemented. Would improve source capture rate beyond the current ~85%.
- **Links:** `.cursor/skills/research-and-analyze/`, `docs/building-a-research-skill.md`
- **Added:** 2026-04-10

### Low-content capture improvements for research skill
- **Product:** meta
- **Context:** Some fetched sources return minimal content (login walls, JS-rendered pages). The research skill could detect low-content captures and flag them for manual review or retry with different strategies.
- **Links:** `.cursor/skills/research-and-analyze/`
- **Added:** 2026-04-10

## Ideas

### Essay: The Way Is in Training
- **Product:** docs
- **Context:** Foundation essay for the zen-karate series. The historical and philosophical connection between Zen Buddhism and karate. Core concepts: mushin (no-mind), zanshin (awareness), fudoshin (immovable mind). What lifelong practice teaches that cannot be learned from books. This is the personal anchor essay that establishes vocabulary for the rest of the series.
- **Links:** `.planning/zen-karate/`, `research/zen-karate-philosophy/`
- **Added:** 2026-04-17

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
- **Links:** `.planning/zen-karate/`, `docs/the-shift.md`
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

### Case study: adversarial review as a meta-development pattern
- **Product:** docs
- **Context:** Building the `/spar` command, `spar-patterns.md`, and zero-base de-biasing in a single session demonstrated the same meta-development loop documented in `building-a-research-skill.md` — gap identified (AI prioritization bias, lack of pushback), tool built (`/spar`, spar pipeline stage), immediately applied (adversarial review of the ego/AI essay, which produced 7 counterarguments and a sparring notes document). The sparring itself then became material for the essay it was critiquing. Could extend the AI-Assisted Development Workflows essay or become a standalone piece on adversarial review as a development practice.
- **Links:** `.cursor/commands/spar.md`, `.cursor/skills/create-meta-prompts/references/spar-patterns.md`, `docs/building-a-research-skill.md`, `docs/ai-assisted-development-workflows.md`, `research/zen-karate-philosophy/sparring-notes.md`
- **Added:** 2026-04-18

### Case study: from conversation to essay in one session
- **Product:** docs
- **Context:** The ego/AI/zen essay went from thread ideation to published essay with source provenance and adversarial review in a single session. The process: (1) user noticed a connection between existing content (The Shift's sycophancy section) and the zen research, (2) thread 14 crystallized the idea, (3) essay drafted drawing from cached sources, (4) adversarial review challenged it immediately, (5) sparring notes created for user response. This is a concrete example of the essay pipeline working end-to-end — and of the provenance convention (Sources/References, Open Review sections) keeping things connected. Connects to the workflows essay and could demonstrate the full write-challenge-revise cycle.
- **Links:** `docs/ego-ai-and-the-zen-antidote.md`, `.planning/zen-karate/threads.md`, `research/zen-karate-philosophy/sparring-notes.md`, `docs/ai-assisted-development-workflows.md`
- **Added:** 2026-04-18

### Case study: building a personal knowledge management system with AI
- **Product:** docs
- **Context:** In a single extended session, the repo gained: project tracking (BACKLOG.md + /backlog), a personal reference library (library/ + /reference), session orientation (/start + session-awareness rule), pre-commit review (/review + /audit), proactive backlog capture, and cross-linking conventions. This is AI building the infrastructure for its own productivity — the meta-development system section of ai-assisted-development-workflows.md in action. The interesting angle: the human identifies the organizational need, the AI builds the tooling, and then both immediately use it. What does it look like when you let AI build the system that organizes AI-assisted work?
- **Links:** `BACKLOG.md`, `library/`, `.cursor/commands/`, `.cursor/rules/`, `docs/ai-assisted-development-workflows.md`
- **Added:** 2026-04-18

### Case study: debugging your AI assistant's judgment
- **Product:** docs
- **Context:** The user noticed AI was anchoring on prior priorities during re-prioritization — a systematic behavioral flaw, not a one-off error. That observation led to naming the problem precisely ("AI sycophancy toward its own prior outputs"), building a structural guard (zero-base de-biasing), and connecting it to the ego/AI essay's thesis. This is The Shift's "skepticism as a habit" practiced against the tool itself. The deeper story: how do you notice, name, and fix systematic AI judgment failures? Connects to the-shift.md (section 6-7), ego-ai-and-the-zen-antidote.md (the essay it produced), and the sparring integration.
- **Links:** `.cursor/commands/backlog.md`, `docs/the-shift.md`, `docs/ego-ai-and-the-zen-antidote.md`
- **Added:** 2026-04-18

### Case study: how AI handles evolving creative scope across sessions
- **Product:** docs
- **Context:** The zen-karate project started as "Zen and Karate," broadened to "Martial Arts, Zen, and the Way of Working" when the user's learning expanded beyond Japan/Okinawa, then self-corrected with "Funakoshi's karate is still karate" to prevent the broadening from being dismissive. Multiple planning documents updated across sessions to reflect evolving nuance. This is shoshin (beginner's mind) practiced at the project level — the scope itself is learning. The case study angle: how does AI maintain coherence across documents when the human's understanding is evolving mid-project? What conventions help vs. hinder?
- **Links:** `.planning/zen-karate/BRIEF.md`, `.planning/zen-karate/STYLE.md`, `research/zen-karate-philosophy/personal-notes.md`, `.planning/zen-karate/threads.md`
- **Added:** 2026-04-18

### Case study: choosing scripts over services — the YouTube transcript decision
- **Product:** docs
- **Context:** The transcript tooling went through an architectural decision: MCP server vs. Python script. The script won because it caches to disk (persistent across sessions), works in batch mode, and integrates with the existing research skill's file-based workflow. The MCP server was deferred to Ideas. Small decision, but demonstrates the problem decomposition principle from The Shift — choosing the simpler tool that fits the actual workflow rather than the architecturally elegant one. Also an example of AI presenting options and the human making the judgment call.
- **Links:** `.cursor/skills/research-and-analyze/scripts/fetch-transcript.py`, `docs/the-shift.md`
- **Added:** 2026-04-18

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

### Session-start context loading
- **Product:** meta
- **Context:** Built `/start` command for session orientation (loads backlog, checks handoffs, shows planning state, suggests focus) and `session-awareness` cursor rule for passive context. Complements `/whats-next` (session end) with a session-begin workflow.
- **Links:** `.cursor/commands/start.md`, `.cursor/rules/session-awareness.md`
- **Completed:** 2026-04-17

### Personal reference library
- **Product:** meta
- **Context:** Built `library/` directory with README, entry template, `/reference` command (add, search, enrich, link), and first enriched entry (Deshimaru's "The Zen Way to Martial Arts"). Integrated with repo-structure rule, cross-linking rule, and project curated-reading lists.
- **Links:** `library/`, `.cursor/commands/reference.md`
- **Completed:** 2026-04-17

### Proactive backlog capture rule
- **Product:** meta
- **Context:** Created `backlog-capture` cursor rule that reminds agent to capture ideas and deferred tasks as backlog entries during conversation, not after.
- **Links:** `.cursor/rules/backlog-capture.md`
- **Completed:** 2026-04-17

### Pre-commit review and content audit tooling
- **Product:** meta
- **Context:** Built `/review` (pre-commit quality gate), `/audit` (content health check), `pre-commit-review` rule (enforcement), and `cross-linking` rule (cross-reference maintenance). First audit run caught 6 registry drift issues.
- **Links:** `.cursor/commands/review.md`, `.cursor/commands/audit.md`, `.cursor/rules/pre-commit-review.md`, `.cursor/rules/cross-linking.md`
- **Completed:** 2026-04-17

### YouTube transcript tooling
- **Product:** meta
- **Context:** Built `fetch-transcript.py` script using `youtube-transcript-api` — fetches YouTube transcripts as timestamped markdown with metadata. Supports single video and batch mode. Integrated into the research skill's scripts index and the `/reference` command's video enrichment workflow. Tested successfully with Shi Heng Yi interview (2142 segments, 1:37:35 duration). MCP server option deferred to Ideas as the script-based approach covers the immediate need.
- **Links:** `.cursor/skills/research-and-analyze/scripts/fetch-transcript.py`, `.cursor/commands/reference.md`
- **Completed:** 2026-04-17

### Adversarial review (sparring) meta-system integration
- **Product:** meta
- **Context:** Integrated adversarial review into the workflow system at four points: (1) `/spar` slash command for on-demand adversarial review, (2) Spar as a fifth purpose in the `create-meta-prompts` skill with `spar-patterns.md` reference and chain integration (research → spar → plan → do), (3) zero-base de-biasing in `/backlog prioritize` to counter AI anchoring on prior priorities, (4) "Assumptions to challenge" subsection in `/review` for documentation commits.
- **Links:** `.cursor/commands/spar.md`, `.cursor/skills/create-meta-prompts/references/spar-patterns.md`, `.cursor/commands/backlog.md`, `.cursor/commands/review.md`
- **Completed:** 2026-04-17

### AI prioritization bias — meta-system guard
- **Product:** meta
- **Context:** Implemented zero-base evaluation in `/backlog prioritize`: strips current section labels, scores items on merits, compares zero-base ranking against current ranking, and flags anchoring bias. Addresses the observed behavior where AI weights prior priorities into re-prioritization.
- **Links:** `.cursor/commands/backlog.md`
- **Completed:** 2026-04-17

### Essay: Ego, AI, and the Zen Antidote
- **Product:** docs
- **Context:** Companion essay to *The Shift*. Connects Shi Heng Yi's teaching on ego as "a collection of thoughts," the mechanism of "hooking" onto identity, and zen practices (mushin, shoshin, non-attachment) as structural resistance to AI-fueled sycophancy. Bridges the AI essay track and the martial arts/zen track. Published at `docs/ego-ai-and-the-zen-antidote.md`, cross-linked from *The Shift* and added to `docs/README.md`.
- **Links:** `docs/ego-ai-and-the-zen-antidote.md`, `docs/the-shift.md`, `.planning/zen-karate/threads.md` (thread 14)
- **Completed:** 2026-04-17

### Zen-karate essay library scaffolding
- **Product:** docs
- **Context:** Created planning artifacts (BRIEF, ROADMAP, STYLE guide), research workspace (personal-notes.md, curated-reading.md templates), and backlog items for the zen-karate essay series.
- **Links:** `.planning/zen-karate/`, `research/zen-karate-philosophy/`
- **Completed:** 2026-04-17

### Project tracking system
- **Product:** meta
- **Context:** Designed and implemented `BACKLOG.md` with `/backlog` slash command, replacing the unused TACHES TO-DOS.md pattern with a persistent, shareable project board.
- **Links:** `BACKLOG.md`, `.cursor/commands/backlog.md`
- **Completed:** 2026-04-17

### Consolidate .prompts/ into prompts/
- **Product:** meta
- **Context:** Removed hidden `.prompts/` directory (leftover from older TACHES import) and moved the dell memory validation research prompt into the visible `prompts/` directory.
- **Completed:** 2026-04-17

### Move labs into product directories
- **Product:** argo
- **Context:** Moved `labs/lab-argocd-sync/` and `labs/lab-gitops/` into `argo/labs/` for consistency with product-based nesting.
- **Completed:** 2026-04-17

### Remove non-functional iso-server tool
- **Product:** ocp
- **Context:** Removed `tools/iso-server.py` — HTTPS ISO server didn't work against Dell iDRAC virtual media for several reasons.
- **Completed:** 2026-04-17

### Product-based directory nesting
- **Product:** meta
- **Context:** Reorganized all technology-specific content under product directories (`ansible/`, `argo/`, `coreos/`, `ocp/`, `rhacm/`, `vault/`) with content-type subdirectories. Updated all internal references.
- **Links:** `.cursor/rules/repo-structure.md`
- **Completed:** 2026-04-17

### Repository organization tooling
- **Product:** meta
- **Context:** Created `.cursor/rules/repo-structure.md` conventions rule and `/organize` audit command to keep the repo tidy.
- **Links:** `.cursor/rules/repo-structure.md`, `.cursor/commands/organize.md`
- **Completed:** 2026-04-17

### ArgoCD diff preview upstream contribution
- **Product:** argo
- **Context:** Explored feasibility improvement in `git-projects/argocd-diff-preview/`. Resulted in [upstream issue #381](https://github.com/dag-andersen/argocd-diff-preview/issues/381).
- **Links:** `git-projects/argocd-diff-preview/`
- **Completed:** 2026-03

### Research and verification skill
- **Product:** meta
- **Context:** Built a reusable research automation skill that fetches sources, runs parallel analysis, and produces structured assessments. Validated against 53 of 62 cited sources from an enterprise LLM deployment article.
- **Links:** `.cursor/skills/research-and-analyze/`, `docs/building-a-research-skill.md`
- **Completed:** 2026-04

### Documentation suite
- **Product:** meta
- **Context:** Created six interconnected essays covering AI-assisted development, working outside expertise, legacy system improvement, LLM deployment analysis, and the research skill meta case study.
- **Links:** `docs/README.md`
- **Completed:** 2026-04

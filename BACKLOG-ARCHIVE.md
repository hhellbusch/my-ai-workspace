# Backlog archive

Completed items moved out of `BACKLOG.md` so **`## Done`** stays a short rolling window (at most **15** entries). Git history on `BACKLOG.md` and this file remains authoritative; this file is an index for quick lookup without replaying large diffs.

New archival batches are prepended below (newest batch first).

---

## Archived 2026-04-18 (2 items — batch 10)

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

---

## Archived 2026-04-18 (1 item — batch 9)

### Biographical content tracking — `voice-approved` validation type
- **Product:** meta
- **Context:** Added `voice-approved` as an elevated-priority validation type for content that speaks in the author's voice. Integrated across the full workflow: generation guidance (review-tracking rule, STYLE.md), pre-commit detection (`/review` biographical scan), content audit (`/audit` Layer 5b), validation command (`/validate` prompts for voice-approved), and disclosure policy (`AI-DISCLOSURE.md`). AI is now instructed to minimize unsolicited biographical content and flag it when generated.
- **Links:** `.cursor/rules/review-tracking.md`, `.cursor/commands/review.md`, `.cursor/commands/audit.md`, `.cursor/commands/validate.md`, `AI-DISCLOSURE.md`, `.planning/zen-karate/STYLE.md`
- **Completed:** 2026-04-18

---

## Archived 2026-04-18 (3 items — batch 8)

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

### Practitioner's guide: The Full Cup — transformation arc for remote teams
- **Product:** docs
- **Context:** Companion to the Full Cup essay. Four-phase transformation arc: diagnose the quadrant (observable signals for each, remote diagnostic), intervene (tap controls at kickoff vs. mid-flight), facilitate (structural bows for cameras-off remote sessions), sustain (keeping the tap off through organizational entropy). Remote-first framing throughout. Added bridge section to the essay and updated reading orders.
- **Links:** `docs/philosophy/the-full-cup-practitioners-guide.md`, `docs/philosophy/the-full-cup.md`
- **Completed:** 2026-04-18

---

## Archived 2026-04-18 (1 item — batch 7)

### Essay draft: The Full Cup — organizational bandwidth as barrier to learning
- **Product:** docs
- **Context:** Drafted `docs/philosophy/the-full-cup.md` — Thread 19. Reframes "empty the cup" as organizational engineering. Includes shoshin × capacity matrix, "cutting off the tap" via theory of constraints, dojo's bow at the door, AI as overload source or capacity creator. Updated philosophy README, docs README cross-track reading order. Draft uses "a practitioner might" framing where author hasn't provided specific stories — ready for voice input and revision.
- **Links:** `docs/philosophy/the-full-cup.md`, `.planning/zen-karate/threads.md` (thread 19), `docs/philosophy/README.md`, `docs/README.md`
- **Completed:** 2026-04-18

---

## Archived 2026-04-18 (1 item — batch 6)

### Repository organization tooling
- **Product:** meta
- **Context:** Created `.cursor/rules/repo-structure.md` conventions rule and `/organize` audit command to keep the repo tidy.
- **Links:** `.cursor/rules/repo-structure.md`, `.cursor/commands/organize.md`
- **Completed:** 2026-04-17

---

## Archived 2026-04-18 (2 items — batch 5)

### Product-based directory nesting
- **Product:** meta
- **Context:** Reorganized all technology-specific content under product directories (`ansible/`, `argo/`, `coreos/`, `ocp/`, `rhacm/`, `vault/`) with content-type subdirectories. Updated all internal references.
- **Links:** `.cursor/rules/repo-structure.md`
- **Completed:** 2026-04-17

### Remove non-functional iso-server tool
- **Product:** ocp
- **Context:** Removed `tools/iso-server.py` — HTTPS ISO server didn't work against Dell iDRAC virtual media for several reasons.
- **Completed:** 2026-04-17

---

## Archived 2026-04-18 (1 item — batch 4)

### Move labs into product directories
- **Product:** argo
- **Context:** Moved `labs/lab-argocd-sync/` and `labs/lab-gitops/` into `argo/labs/` for consistency with product-based nesting.
- **Completed:** 2026-04-17

---

## Archived 2026-04-18 (1 item — batch 3)

### Consolidate .prompts/ into prompts/
- **Product:** meta
- **Context:** Removed hidden `.prompts/` directory (leftover from older TACHES import) and moved the dell memory validation research prompt into the visible `prompts/` directory.
- **Completed:** 2026-04-17

---

## Archived 2026-04-18 (1 item — batch 2)

### Project tracking system
- **Product:** meta
- **Context:** Designed and implemented `BACKLOG.md` with `/backlog` slash command, replacing the unused TACHES TO-DOS.md pattern with a persistent, shareable project board.
- **Links:** `BACKLOG.md`, `.cursor/commands/backlog.md`
- **Completed:** 2026-04-17

---

## Archived 2026-04-18 (2 items)

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

---

## Archived 2026-04-17 (3 items)

### AI prioritization bias — meta-system guard
- **Product:** meta
- **Context:** Implemented zero-base evaluation in `/backlog prioritize`: strips current section labels, scores items on merits, compares zero-base ranking against current ranking, and flags anchoring bias. Addresses the observed behavior where AI weights prior priorities into re-prioritization.
- **Links:** `.cursor/commands/backlog.md`
- **Completed:** 2026-04-17

### Adversarial review (sparring) meta-system integration
- **Product:** meta
- **Context:** Integrated adversarial review into the workflow system at four points: (1) `/spar` slash command for on-demand adversarial review, (2) Spar as a fifth purpose in the `create-meta-prompts` skill with `spar-patterns.md` reference and chain integration (research → spar → plan → do), (3) zero-base de-biasing in `/backlog prioritize` to counter AI anchoring on prior priorities, (4) "Assumptions to challenge" subsection in `/review` for documentation commits.
- **Links:** `.cursor/commands/spar.md`, `.cursor/skills/create-meta-prompts/references/spar-patterns.md`, `.cursor/commands/backlog.md`, `.cursor/commands/review.md`
- **Completed:** 2026-04-17

### YouTube transcript tooling
- **Product:** meta
- **Context:** Built `fetch-transcript.py` script using `youtube-transcript-api` — fetches YouTube transcripts as timestamped markdown with metadata. Supports single video and batch mode. Integrated into the research skill's scripts index and the `/reference` command's video enrichment workflow. Tested successfully with Shi Heng Yi interview (2142 segments, 1:37:35 duration). MCP server option deferred to Ideas as the script-based approach covers the immediate need.
- **Links:** `.cursor/skills/research-and-analyze/scripts/fetch-transcript.py`, `.cursor/commands/reference.md`
- **Completed:** 2026-04-17

## Archived 2026-04-18 (17 items) — rolling Done cap restored

### ArgoCD diff preview upstream contribution
- **Product:** argo
- **Context:** Explored feasibility improvement in `git-projects/argocd-diff-preview/`. Resulted in [upstream issue #381](https://github.com/dag-andersen/argocd-diff-preview/issues/381).
- **Links:** `git-projects/argocd-diff-preview/`
- **Completed:** 2026-03

### Research and verification skill
- **Product:** meta
- **Context:** Built a reusable research automation skill that fetches sources, runs parallel analysis, and produces structured assessments. Validated against 53 of 62 cited sources from an enterprise LLM deployment article.
- **Links:** `.cursor/skills/research-and-analyze/`, `docs/case-studies/building-a-research-skill.md`
- **Completed:** 2026-04

### Documentation suite
- **Product:** meta
- **Context:** Created six interconnected essays covering AI-assisted development, working outside expertise, legacy system improvement, LLM deployment analysis, and the research skill meta case study.
- **Links:** `docs/README.md`
- **Completed:** 2026-04

### Zen-karate essay voice/style guide
- **Product:** docs
- **Context:** Blended voice reference: personal first-person for philosophical/experiential sections, practitioner tone for applied sections. Structural conventions, Japanese terminology approach, "this, not that" examples, cross-linking conventions. Referenced by all meta-prompts in the drafting pipeline.
- **Links:** `.planning/zen-karate/STYLE.md`
- **Completed:** 2026-04-17

### Zen-karate source library (Inoue, Rika Usami, Hayashi, Athens lineage)
- **Product:** docs
- **Context:** 10 cached source files covering Inoue Yoshimi (3 files — comprehensive bio, Jesse Enkamp seminar recap, 42 secrets), Rika Usami (biography + career + coaching), Teruo Hayashi (biography), Athens Shotokan lineage (Golden, Kanazawa, Okazaki), Jesse Enkamp articles (3 — Okinawan vs. Japanese, mushin, modern karate history), Shi Heng Yi transcript. Plus 5 library entries (Karate by Jesse, Finding Karate, Karate Philosophy, Deshimaru book, curated reading list). Built across multiple research sessions.
- **Links:** `research/zen-karate-philosophy/sources/`, `library/`
- **Completed:** 2026-04-17

### AI-engineering track updates — behavioral failure modes, meta-development loop, multi-session management
- **Product:** docs
- **Context:** Three updates driven by case study analysis: (1) expanded The Shift section 6 with behavioral failure modes beyond sycophancy — anchoring on own outputs, framing drift, self-reinforcing infrastructure — with structural mitigations and case study references; (2) new essay "The Meta-Development Loop" synthesizing the gap → tool → apply → reshape pattern from all 8 case studies into a teachable engineering pattern; (3) expanded AI-Assisted Development Workflows section 2 with multi-session project management patterns — zero-base evaluation, session orientation with drift checks, handoffs that name their assumptions, set-based scope updates, planning evolution logs.
- **Links:** `docs/ai-engineering/the-shift.md`, `docs/ai-engineering/the-meta-development-loop.md`, `docs/ai-engineering/ai-assisted-development-workflows.md`
- **Completed:** 2026-04-17

### Case study: when case studies generate system improvements
- **Product:** docs
- **Context:** Published case study documenting how writing the evolving-scope case study surfaced three concrete gaps, how the user's shoshin observation became a design principle with five integration points, and how the case study format itself functions as a discovery mechanism.
- **Links:** `docs/case-studies/case-studies-as-discovery.md`, `docs/case-studies/evolving-creative-scope.md`, `.cursor/rules/shoshin.md`
- **Completed:** 2026-04-17

### Case study: adversarial review as a meta-development pattern
- **Product:** docs
- **Context:** Published case study documenting how the absence of pushback in the essay workflow led to building `/spar`, spar pipeline stage, and zero-base de-biasing — then immediately applying it to the ego/AI essay, producing 7 counterarguments that feed back into the essay's Open Review section.
- **Links:** `docs/case-studies/adversarial-review-meta-development.md`, `.cursor/commands/spar.md`, `research/zen-karate-philosophy/sparring-notes.md`
- **Completed:** 2026-04-17

### Case study: debugging your AI assistant's judgment
- **Product:** docs
- **Context:** Published case study documenting how noticing AI anchoring on prior priorities led to naming the mechanism (sycophancy toward own outputs), building a structural fix (zero-base evaluation in `/backlog prioritize`), and connecting it to the philosophical thesis on ego and non-attachment.
- **Links:** `docs/case-studies/debugging-ai-judgment.md`, `.cursor/commands/backlog.md`, `docs/ai-engineering/the-shift.md`
- **Completed:** 2026-04-17

### Case study: from conversation to essay in one session
- **Product:** docs
- **Context:** Published case study tracing how the ego/AI/zen essay went from a conversational observation to a published essay with source provenance and adversarial review in one session. Demonstrates the full write-challenge-revise cycle and how project infrastructure (cached sources, style guide, cross-linking rules, sparring system) compounds.
- **Links:** `docs/case-studies/conversation-to-essay.md`, `docs/philosophy/ego-ai-and-the-zen-antidote.md`, `.planning/zen-karate/threads.md`
- **Completed:** 2026-04-17

### Case study: choosing scripts over services — the YouTube transcript decision
- **Product:** docs
- **Context:** Published case study documenting the architectural decision between MCP server, Gemini API, and Python script for YouTube transcript fetching. The script won because it fit the file-based research workflow — persistent output, batch mode, same conventions as `fetch-sources.py`. Demonstrates problem decomposition and workflow-fit thinking.
- **Links:** `docs/case-studies/choosing-scripts-over-services.md`, `.cursor/skills/research-and-analyze/scripts/fetch-transcript.py`
- **Completed:** 2026-04-17

### Case study: building a personal knowledge management system with AI
- **Product:** docs
- **Context:** Published case study documenting how one extended session produced six interlocking organizational tools (backlog, library, session orientation, pre-commit review, content audit, cross-linking). Explores the meta-development loop applied to infrastructure and the self-reinforcing nature of AI building systems that organize AI work.
- **Links:** `docs/case-studies/building-knowledge-management-with-ai.md`, `BACKLOG.md`, `library/`, `.cursor/commands/`
- **Completed:** 2026-04-17

### Case study: how AI handles evolving creative scope across sessions
- **Product:** docs
- **Context:** Published case study documenting how the zen-karate project broadened from "Zen and Karate" to "Martial Arts, Zen, and the Way of Working" as the user's learning expanded. Covers cascade effects through planning documents, what conventions (set updates, stable names, nuanced framing) help maintain coherence, and what's missing (evolution logs, tonal drift detection).
- **Links:** `docs/case-studies/evolving-creative-scope.md`, `.planning/zen-karate/BRIEF.md`, `.planning/zen-karate/STYLE.md`
- **Completed:** 2026-04-17

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

### Case study: fabricated URL in the sycophancy section
- **Product:** docs
- **Context:** AI fabricated a plausible Anthropic URL while defining sycophancy, demonstrating a related failure mode in the same paragraph. Documented as a case study tracing the immediate fix (corrected URL) and systemic fix (external URL verification rule and /review check).
- **Links:** `docs/case-studies/fabricated-references.md`, `.cursor/rules/cross-linking.md`, `.cursor/commands/review.md`
- **Completed:** 2026-04-17

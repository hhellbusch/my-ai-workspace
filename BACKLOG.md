# Backlog

> Last updated: 2026-04-17

## In Progress

### Helm chart upstream contribution
- **Product:** argo
- **Context:** Improving chart templates in `git-projects/helm-charts/`. Working branch has changes ready for review and testing before submitting upstream.
- **Links:** `git-projects/helm-charts/`, `git-projects/README.md`
- **Started:** 2026-03

## Up Next

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

### Essay: The Dojo and the Team
- **Product:** docs
- **Context:** Bridge essay connecting martial arts philosophy to engineering team culture. How dojo culture (mutual respect, senpai/kohai, cleaning the floor, showing up) translates to ways of working and leadership. Presence over performance. Non-attachment to outcomes in collaborative work.
- **Links:** `.planning/zen-karate/`
- **Added:** 2026-04-17

### Essay: Beginner's Mind in the Age of AI
- **Product:** docs
- **Context:** Explicit bridge to the existing AI-focused essay track. Shoshin (beginner's mind) as the essential posture for working with AI. Connects back to themes in The Shift and AI-Assisted Development Workflows.
- **Links:** `.planning/zen-karate/`, `docs/the-shift.md`, `docs/ai-assisted-development-workflows.md`
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

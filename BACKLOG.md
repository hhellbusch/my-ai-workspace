# Backlog

> Last updated: 2026-04-17

## In Progress

### Helm chart upstream contribution
- **Product:** argo
- **Context:** Improving chart templates in `git-projects/helm-charts/`. Working branch has changes ready for review and testing before submitting upstream.
- **Links:** `git-projects/helm-charts/`, `git-projects/README.md`
- **Started:** 2026-03

## Up Next

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

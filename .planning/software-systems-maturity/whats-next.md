# Software Systems Maturity — session handoff

> **Written:** 2026-08-12 · **Status:** First pass **complete** (author skim OK) · **Thread:** closed pending PR merge

## Summary

Resurrected a 2016–2017 maturity deck as a **trailhead + 14 axis deep dives + Joel appendix**, mapped to this repo's corpus, and wired as a **navigation lens** (not certification). Author skimmed content — good enough to ship as first pass.

**Merge when ready:** [PR #9](https://github.com/hhellbusch/my-ai-workspace/pull/9) · branch `feature/software-systems-maturity-trailhead`

---

## Start here (next agent)

| Need | File |
|---|---|
| Model intro | [docs/ai-engineering/software-systems-maturity.md](../../docs/ai-engineering/software-systems-maturity.md) |
| Per-axis detail | [docs/ai-engineering/maturity/README.md](../../docs/ai-engineering/maturity/README.md) |
| Repo ↔ axis index | [research/.../artifact-map.md](../../research/software-systems-maturity/findings/artifact-map.md) |
| Team self-assessment | [docs/ai-engineering/maturity/worksheet.md](../../docs/ai-engineering/maturity/worksheet.md) |
| Devops placement rules | [devops/ORGANIZATION.md#maturity-lens](../../devops/ORGANIZATION.md#maturity-lens) |
| Agent behavior | [AGENTS.md](../../AGENTS.md) § Software Systems Maturity |
| Design decisions | [2026-resurrection-notes.md](../../research/software-systems-maturity/findings/2026-resurrection-notes.md) |
| DORA / Accelerate / AI map | [dora-accelerate-and-ai-systems.md](../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md) |
| Project brief | [BRIEF.md](BRIEF.md) |

---

## What shipped (first pass)

| Deliverable | Location |
|---|---|
| Trailhead (axis map, DevOps/GitOps, platform accelerator) | `docs/ai-engineering/software-systems-maturity.md` |
| 14 deep dives + Joel appendix | `docs/ai-engineering/maturity/` |
| Research ingest + deck text export | `research/software-systems-maturity/` |
| Artifact map (corpus richness by axis) | `research/.../findings/artifact-map.md` |
| Meta-framework D1/D4/D5 | AGENTS, devops README/ORGANIZATION, cross-link + review skills |
| Assessment worksheet | `docs/ai-engineering/maturity/worksheet.md` |
| SLO/runbook primer (monitoring 3→4) | `devops/slo-and-runbooks.md` |

---

## Explicit non-goals (do not reopen without user ask)

- Domain-specific maturity ladders (Kafka, cluster links, etc.)
- Org-wide level scores or certification framing
- GitOps as a top-level axis (lives under Deployment & release)

---

## Axis iteration (ongoing)

Second pass: one axis at a time — expand deep dive, reconcile trailhead, map DORA/corpus evidence.

| Axis | Status |
|---|---|
| Source control | **v2** — [deep dive](../../docs/ai-engineering/maturity/source-control.md) · [DORA note](../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md) |
| Deployment & release | **v2** — [deep dive](../../docs/ai-engineering/maturity/deployment-and-release.md) · DORA § deployment axis in research note |
| Builds & artifacts | **v2** — [deep dive](../../docs/ai-engineering/maturity/builds-and-artifacts.md) · DORA § builds axis in research note |
| Testing & verification | **v2** — [deep dive](../../docs/ai-engineering/maturity/testing-and-verification.md) · DORA § testing axis in research note |
| Next suggested | Code quality (thin, deck xkcd) or Architecture & change |

---

## Optional follow-ups (not blocking merge)

| Item | Notes |
|---|---|
| **Merge PR #9** | Primary close-out action for this thread |
| Deck **PDF** | Diagram-only slides for code quality, testing, data — not in repo today |
| Worked **SLO YAML** examples | Primer exists; concrete fleet examples still open |
| **D2** `maturity:` frontmatter | ~10 rich corpus paths — only if tags will stay maintained |
| **D3** Generated artifact map | JBGE; defer unless D2 is in use |
| **Product discovery** corpus | Optional axis — thin by design |
| **Essay / case study** | "Maturity as workspace architecture" — seed in BACKLOG if desired |
| **`/validate read`** on key docs | Formal review metadata after merge |
| Run **worksheet** on a `.planning/` project | Validates the model in practice |

---

## How to resume work

1. Check PR #9 is merged (or merge it).
2. Read [artifact-map.md](../../research/software-systems-maturity/findings/artifact-map.md) for corpus gaps.
3. New substantive `devops/` content → name primary axis, update artifact map + deep dive if corpus grows.
4. For deep rubric changes, edit deep dives first — then consider D2 frontmatter.

---

## Git

```
Branch:  feature/software-systems-maturity-trailhead
PR:      https://github.com/hhellbusch/my-ai-workspace/pull/9
After merge: delete branch; handoff remains in .planning/software-systems-maturity/
```

**Related PR (separate thread):** Kafka cluster-link GitOps — PR #10 on `feature/cluster-link-gitops`.

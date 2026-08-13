# Maturity artifact map — repository cross-reference

**Purpose:** Connect [software systems maturity](../../../docs/ai-engineering/software-systems-maturity.md) axes to artifacts in this workspace.

**Status:** v2 iteration complete on all axes — author skim OK on v1; merge PR #9 when ready.

---

## Legend

| Corpus | Meaning |
|---|---|
| **Rich** | Multiple dedicated docs usable as level evidence |
| **Partial** | Some material; deep dive uses external canon |
| **Thin** | Little in-repo; framework + external refs |

---

## Axis → deep dive → corpus

| Axis | Deep dive | Corpus |
|---|---|---|
| Source control | [source-control.md](../../../docs/ai-engineering/maturity/source-control.md) | Partial — [git-learning-guide](../../../devops/git/git-learning-guide.md), [branching rules](../../../rules/branching.md), argo/rhacm GitOps |
| Code quality | [code-quality.md](../../../docs/ai-engineering/maturity/code-quality.md) | Thin — craft skill, deck xkcd links |
| Testing & verification | [testing-and-verification.md](../../../docs/ai-engineering/maturity/testing-and-verification.md) | Partial+ — bare-metal harness, cross-dc network test, argo CI/labs |
| Architecture & change | [architecture-and-change.md](../../../docs/ai-engineering/maturity/architecture-and-change.md) | Partial — argo GUIDELINES, fleet notes |
| Builds & artifacts | [builds-and-artifacts.md](../../../docs/ai-engineering/maturity/builds-and-artifacts.md) | Partial+ — argo CI/promotion, operators-installer, framework render pipeline |
| Deployment & release | [deployment-and-release.md](../../../docs/ai-engineering/maturity/deployment-and-release.md) | **Rich** — [devops/argo/](../../../devops/argo/README.md) |
| Data management | [data-management.md](../../../docs/ai-engineering/maturity/data-management.md) | Thin — Fowler evodb external |
| Monitoring & reliability | [monitoring-and-reliability.md](../../../docs/ai-engineering/maturity/monitoring-and-reliability.md) | Partial — ocp troubleshooting, [slo-and-runbooks](../../../devops/slo-and-runbooks.md) |
| Security & secrets | [security-and-secrets.md](../../../docs/ai-engineering/maturity/security-and-secrets.md) | Partial — vault, RHACM secrets |
| Documentation & knowledge | [documentation-and-knowledge.md](../../../docs/ai-engineering/maturity/documentation-and-knowledge.md) | **Rich** — docs track, AGENTS, research rules |
| Platform & fleet | [platform-as-accelerator.md](../../../docs/ai-engineering/maturity/platform-as-accelerator.md) | **Rich** — rhacm, ocp examples, fleet spectrum |
| AI agents & harnesses | [ai-agents-and-harnesses.md](../../../docs/ai-engineering/maturity/ai-agents-and-harnesses.md) | **Rich** — Shift, skills, paude |
| Team practices | [team-practices.md](../../../docs/ai-engineering/maturity/team-practices.md) | **Rich** — session framework, spar/shoshin |
| Product discovery *(opt)* | [product-discovery.md](../../../docs/ai-engineering/maturity/product-discovery.md) | Thin — by design |

**Appendix:** [joel-test-appendix.md](../../../docs/ai-engineering/maturity/joel-test-appendix.md)

---

## DevOps / GitOps stack

Primary home: [deployment-and-release.md](../../../docs/ai-engineering/maturity/deployment-and-release.md). Key artifacts: app-of-apps, multi-cluster, promotion, PR workflow, RHACM policy generation — see deployment deep dive table.

---

## Remaining work (optional — not blocking v1)

- [x] Author first pass (skim OK 2026-08-12)  
- [ ] Merge [PR #9](https://github.com/hhellbusch/my-ai-workspace/pull/9)  
- [ ] Deck PDF → restore diagrams into code quality, testing, data deep dives  
- [ ] Worked SLO YAML / error-budget alert examples in devops  
- [ ] Optional: expand product discovery corpus  
- [x] Cross-link from [devops/README.md](../../../devops/README.md) to maturity trailhead  
- [x] Central SLO/runbook primer — [slo-and-runbooks.md](../../../devops/slo-and-runbooks.md)

---

## Meta-framework integration (post-review)

| Phase | Work | Status |
|---|---|---|
| D1 | Navigation hub — devops/README, ORGANIZATION, AGENTS | Done |
| D4 | Skill hooks — cross-link, review | Done |
| D5 | [Assessment worksheet](../../../docs/ai-engineering/maturity/worksheet.md) | Done |
| D2 | Optional `maturity:` frontmatter on rich corpus files | Deferred until author review |
| D3 | Generated artifact map from frontmatter | Deferred |
| Planning | [`.planning/software-systems-maturity/`](../../../.planning/software-systems-maturity/BRIEF.md) | Done |

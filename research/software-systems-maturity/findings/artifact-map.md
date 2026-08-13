# Maturity artifact map — repository cross-reference

**Purpose:** Connect [software systems maturity](../../../docs/ai-engineering/software-systems-maturity.md) axes to artifacts in this workspace — evidence for deep dives, gaps for future writing.

**Status:** In progress — updated as deep dives ship.

---

## Legend

| Corpus | Meaning |
|---|---|
| **Rich** | Multiple dedicated docs/examples usable as level evidence |
| **Partial** | Some material; deep dive needs external canon |
| **Thin** | Little in-repo; deep dive mostly external + practice |

---

## Axis → artifacts

| Axis | Corpus | Workspace paths | Gap |
|---|---|---|---|
| **Source control** | Partial | [devops/git/git-learning-guide.md](../../../devops/git/git-learning-guide.md) | No branching/review maturity ladder |
| **Code quality** | Thin | Engineering craft in [AGENTS.md](../../../AGENTS.md), [.agents/skills/craft/](../../../.agents/skills/craft/SKILL.md) | Deck teaching stories not ingested |
| **Testing & verification** | Thin | Scattered in examples; network test scripts in [cross-dc-network-test](../../../devops/ocp/examples/networking/cross-dc-network-test/) | No central testing maturity doc |
| **Architecture & change** | Partial | [argo/examples/framework/GUIDELINES.md](../../../devops/argo/examples/framework/GUIDELINES.md), [architecture-opinions.md](../../../devops/argo/examples/helm-component-pattern/docs/architecture-opinions.md), [greenfield-fleet-architecture.md](../../../devops/rhacm/notes/greenfield-fleet-architecture.md) | ADR template/workflow not formalized |
| **Builds & artifacts** | Partial | [argo GitHub workflows](../../../devops/argo/examples/github-workflows/README.md), [operators-installer](../../../devops/argo/examples/examples/operators-installer/README.md) | SBOM/provenance not a first-class doc |
| **Deployment & release** | **Rich** | [devops/argo/](../../../devops/argo/README.md) | [deployment deep dive](../../../docs/ai-engineering/maturity/deployment-and-release.md) |
| **Data management** | Thin | Cross-DC design touches persistence | Evolutionary DB deep dive external |
| **Monitoring & reliability** | Partial | [ocp/troubleshooting/](../../../devops/ocp/troubleshooting/) | [monitoring deep dive](../../../docs/ai-engineering/maturity/monitoring-and-reliability.md) — SLO doc gap |
| **Security & secrets** | Partial | [vault/integration/](../../../devops/vault/integration/README.md), [rhacm secret-management/](../../../devops/rhacm/examples/secret-management/README.md) | [security deep dive](../../../docs/ai-engineering/maturity/security-and-secrets.md) |
| **Documentation & knowledge** | **Rich** | [docs/ai-engineering/](../../../docs/ai-engineering/README.md) | [documentation deep dive](../../../docs/ai-engineering/maturity/documentation-and-knowledge.md) |
| **Platform & fleet** | **Rich** | [rhacm/](../../../devops/rhacm/README.md), [fleet-control-spectrum.md](../../../devops/fleet-control-spectrum.md) | [platform accelerator](../../../docs/ai-engineering/maturity/platform-as-accelerator.md) |
| **AI agents & harnesses** | **Rich** | [The Shift](../../../docs/ai-engineering/the-shift.md), skills | [AI agents deep dive](../../../docs/ai-engineering/maturity/ai-agents-and-harnesses.md) |
| **Team practices** | **Rich** | [session-framework.md](../../../docs/ai-engineering/session-framework.md) | [team practices deep dive](../../../docs/ai-engineering/maturity/team-practices.md) |
| **Product discovery** | Thin | Philosophy essays tangential | Needs deliberate corpus or stay optional |

---

## DevOps / GitOps stack (cross-axis)

Primary home: **Deployment & release**. Secondary: **Platform & fleet**.

| Concept | Key artifacts |
|---|---|
| App-of-apps | [APP-OF-APPS-PATTERN.md](../../../devops/argo/examples/docs/patterns/APP-OF-APPS-PATTERN.md) |
| Multi-cluster | [multi-cluster-deployment.md](../../../devops/argo/examples/docs/deployment/multi-cluster-deployment.md) |
| Promotion | [framework/pipelines/promotion/](../../../devops/argo/examples/framework/pipelines/promotion/) |
| Diff / PR workflow | [PR-WORKFLOW-GUIDE.md](../../../devops/argo/examples/docs/workflows/PR-WORKFLOW-GUIDE.md) |
| RHACM + policy generation | [ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md](../../../devops/argo/examples/docs/patterns/ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md) |
| Fleet spectrum | [fleet-control-spectrum.md](../../../devops/fleet-control-spectrum.md) |
| Labs | [argo/labs/](../../../devops/argo/labs/README.md) |
| API reconcile pattern | Declarative spec + idempotent Job/script (see deployment deep dive) |

---

## Deep dive draft order (recommended)

1. ~~Deployment & release~~  
2. ~~Documentation & knowledge~~  
3. ~~Platform accelerator~~  
4. ~~Security & secrets~~  
5. ~~Team practices~~  
6. ~~AI agents & harnesses~~  
7. ~~Monitoring & reliability~~  
8. **Classic build track** — source control, code quality, testing, builds  
9. Architecture & change  
10. Data management  
11. Product discovery (optional; thin corpus)

---

## Next actions

- [ ] Joel Test → axis mapping appendix  
- [ ] Classic nine deep dives (source control through monitoring deck stories)  
- [ ] Architecture & change deep dive  
- [ ] Product discovery (optional) — decide stay thin or expand  
- [ ] Central SLO/runbook guide (monitoring gap)  
- [ ] Restore deck teaching diagrams when PDF available  

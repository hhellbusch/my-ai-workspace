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
| **Deployment & release** | **Rich** | [devops/argo/](../../../devops/argo/README.md) entire tree; [bigfix-gitops-on-ocp.md](../../../devops/bigfix-gitops-on-ocp.md) | See [deployment deep dive](../../../docs/ai-engineering/maturity/deployment-and-release.md) |
| **Data management** | Thin | Cross-DC design touches persistence; no DB migration guide | Evolutionary DB deep dive external |
| **Monitoring & reliability** | Partial | [ocp/troubleshooting/](../../../devops/ocp/troubleshooting/) (reactive); RHACM observability troubleshooting | SLO/runbook maturity not unified |
| **Security & secrets** | Partial | [devops/vault/](../../../devops/vault/README.md); [rhacm/examples/secret-management/](../../../devops/rhacm/examples/secret-management/README.md) | AppSec track thin |
| **Documentation & knowledge** | **Rich** | [docs/ai-engineering/](../../../docs/ai-engineering/README.md), [library/](../../../library/README.md), [research conventions](../../../rules/research.md) | See [documentation deep dive](../../../docs/ai-engineering/maturity/documentation-and-knowledge.md) |
| **Platform & fleet** | **Rich** | [devops/rhacm/](../../../devops/rhacm/README.md), [fleet-control-spectrum.md](../../../devops/fleet-control-spectrum.md), [ocp/examples/](../../../devops/ocp/examples/README.md) | See [platform accelerator](../../../docs/ai-engineering/maturity/platform-as-accelerator.md) |
| **AI agents & harnesses** | **Rich** | [The Shift](../../../docs/ai-engineering/the-shift.md), [artifact discipline](../../../docs/ai-engineering/artifact-discipline-and-ai.md), [paude docs](../../../docs/ai-engineering/paude-getting-started.md), skills | Eval/metrics immature |
| **Team practices** | **Rich** | [session-framework.md](../../../docs/ai-engineering/session-framework.md), [sparring-and-shoshin.md](../../../docs/ai-engineering/sparring-and-shoshin.md), [framework-bootstrap.md](../../../docs/ai-engineering/framework-bootstrap.md) | Not yet mapped to levels in deep dive |
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
| API reconcile pattern | Example scaffolds under kafka cluster-link-gitops (devops reference only — pattern, not domain maturity) |

---

## Deep dive draft order (recommended)

1. ~~Deployment & release~~ — draft shipped  
2. ~~Documentation & knowledge~~ — draft shipped  
3. ~~Platform accelerator~~ — draft shipped  
4. Security & secrets (vault + RHACM)  
5. Team practices  
6. AI agents & harnesses  
7. Monitoring & reliability  
8. Classic build/test/quality axes (refresh 2016 levels)  
9. Product discovery (optional; may stay thin)

---

## Next actions

- [ ] Joel Test → axis mapping appendix (trailhead or deployment deep dive)  
- [ ] Security & secrets deep dive using vault + secret-management examples  
- [ ] Team practices deep dive linking session framework  
- [ ] Restore deck teaching diagrams into relevant deep dives when PDF available  

# 2026 resurrection notes — Software Systems Maturity

**Source:** [deck-text-export.txt](../sources/deck-text-export.txt)

---

## What survived well from 2016

- **Trailhead framing** — assess current level, prioritize the *next* level up ([Fowler mixologist](https://martinfowler.com/bliki/MaturityModel.html)).
- **Multi-axis model** — maturity is not one number; teams can be level 4 on builds and level 1 on monitoring.
- **Practitioner tone** — XKCD, Boy Scout Rule, tradable quality hypothesis — keep in deep dives.
- **CMM skepticism** — document-heavy, certification ≠ competence.

---

## 2026 revision decisions (Aug 2026)

| Decision | Rationale |
|---|---|
| **No domain-specific ladders** in trailhead | e.g. cluster-link — use generic declarative/API reconcile pattern instead |
| **GitOps under Deployment**, not top-level axis | Evolution of DevOps/CI/CD; "we use Git" ≠ GitOps |
| **Merge observability→action into Monitoring & reliability** | Avoid thin duplicate axes |
| **Supply chain at Builds L4–5 + Security** | Not standalone axis |
| **Documentation & knowledge — dual audience** | Humans + agent session orientation |
| **Platform accelerator doc** | K8s/OCP newcomers and non-K8s teams |
| **Team practices + optional product discovery** | Deck promised team performance |
| **Level 0 optional; L5 aspirational** on monitoring | Honest assessment |
| **Artifact map + argo corpus** | Deep dives link to devops/argo, rhacm, vault, docs track |

---

## Deep dive status

See [artifact-map.md](artifact-map.md) and [maturity/README.md](../../../docs/ai-engineering/maturity/README.md).

Shipped drafts: all axes in [maturity/README.md](../../../docs/ai-engineering/maturity/README.md) + Joel appendix.

---

## Still owed (optional)

- Merge [PR #9](https://github.com/hhellbusch/my-ai-workspace/pull/9)
- Deck PDF for diagram-only slides (CMM, sandbox "too late", quality continuum)
- Worked SLO YAML examples (primer shipped: [slo-and-runbooks.md](../../../devops/slo-and-runbooks.md))
- D2/D3 metadata automation — only if corpus tags will be maintained

Handoff: [.planning/software-systems-maturity/whats-next.md](../../../.planning/software-systems-maturity/whats-next.md)

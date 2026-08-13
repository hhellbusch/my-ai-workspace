---
review:
  status: unreviewed
  notes: "Joel Test mapped to software systems maturity axes — appendix."
---

# Joel Test — axis mapping appendix

> **Audience:** Readers familiar with [Joel Spolsky's 12-step test](https://www.joelonsoftware.com/2000/08/09/the-joel-test-12-steps-to-better-code/) who want to see how it relates to the [multi-axis model](../software-systems-maturity.md).
>
> **Purpose:** Conversation starter — not a scorecard replacement.

---

## Mapped to this model

| # | Joel Test item | Primary axis | Notes |
|---|---|---|---|
| 1 | Source control | [Source control](source-control.md) | Binary yes/no — maps to L1+ here, not L4; see deep dive |
| 2 | One-step build | [Builds & artifacts](builds-and-artifacts.md) | Level 2–3 |
| 3 | Daily builds | [Builds & artifacts](builds-and-artifacts.md) | CI = level 3+ |
| 4 | Bug database | [Team practices](team-practices.md) / code quality | Tracking discipline |
| 5 | Fix bugs before new code | [Code quality](code-quality.md) | WIP discipline |
| 6 | Up-to-date schedule | [Product discovery](product-discovery.md) | Planning honesty |
| 7 | Spec | [Product discovery](product-discovery.md) | Lightweight spec |
| 8 | Quiet working conditions | — | **Out of scope** (workplace) |
| 9 | Best tools | Partial | Enables several axes; not scored |
| 10 | Testers | [Testing & verification](testing-and-verification.md) | Or automated equivalent |
| 11 | Hire the best | — | **Out of scope** (hiring) |
| 12 | Hallway usability testing | [Product discovery](product-discovery.md) | Feedback loop |

---

## What Joel doesn't cover

The Joel Test predates fleet GitOps, Vault-class secrets, AI agents, and dual-audience documentation. Use it as a **historical bridge**, not a complete systems model.

For 2026 systems work, prioritize axes with **low scores that hurt most** — often deployment, security/secrets, monitoring, and documentation/knowledge before chasing Joel item 9.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

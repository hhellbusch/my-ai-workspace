---
review:
  status: unreviewed
  notes: "Product discovery deep dive — optional axis, validated learning before build."
---

# Product Discovery — maturity deep dive *(optional)*

> **Audience:** Product-engineering hybrids — teams that build what stakeholders ask for without validating problems first. **Mark N/A** for pure platform/infra teams.
>
> **Purpose:** Address Joel Test "spec" and "schedule" items without returning to big upfront design.

**Related:** [Architecture & change](architecture-and-change.md) · [Joel Test appendix](joel-test-appendix.md) · [Trailhead](../software-systems-maturity.md#product-discovery-optional)

---

## What this axis answers

*Do we know **what** to build and **why** before implementation — and do we learn as we ship?*

[The Shift](../the-shift.md): when implementation is cheap, **knowing what to build** can become the bottleneck — this axis names that explicitly.

Not a return to months of specification ([Agile Manifesto — working software](http://www.ambysoft.com/essays/agileManifesto.html)). **Validated learning** before expensive build.

---

## Levels

| Level | Posture |
|---|---|
| **1** | Build requests directly; success = shipped |
| **2** | Conversations with stakeholders; informal priority |
| **3** | Written problem statement + success criteria before build |
| **4** | Thin experiments/prototypes; data informs priority |
| **5** | Continuous discovery tied to outcome metrics (not output counts) |

---

## Joel Test mapping

| Joel item | Maps here |
|---|---|
| Do you have a spec? | Level 3+ — lightweight, living |
| Do you have an up-to-date schedule? | Level 2–3 planning honesty |
| Hallway usability testing | Level 4–5 feedback loops |

Items like "quiet workspace" and "hire the best" — **out of scope** for this technical maturity model ([appendix](joel-test-appendix.md)).

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| AI generates epic nobody asked for | TAGRI failure — see [artifact discipline](../artifact-discipline-and-ai.md) |
| Build full feature to "learn" | Skip level 4 experiments |
| Success = story points closed | Output not outcome |
| No one talks to operators/users | Discovery in vacuum |

---

## Repo corpus

**Thin** — philosophy and workflow essays tangential ([The Shift](../the-shift.md), [ai-for-unfamiliar-domains](../ai-for-unfamiliar-domains.md) shows verification, not product discovery).

Treat this deep dive as **framework for conversation** until deliberate product content is added.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

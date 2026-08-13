---
review:
  status: unreviewed
  notes: "Product discovery v2 — optional axis, AI TAGRI, thin corpus by design."
---

# Product Discovery — maturity deep dive *(optional)*

> **Audience:** Product-engineering hybrids. **N/A** for pure platform/infra teams.
>
> **Purpose:** Joel spec/schedule items; validated learning before expensive build.

**Related:** [Architecture & change](architecture-and-change.md) · [Joel appendix](joel-test-appendix.md) · [The Shift](../the-shift.md) · [DORA / AI systems](../../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md)

---

## What this axis answers

*Do we know **what** to build and **why** before implementation — and learn as we ship?*

[The Shift](../the-shift.md): when implementation is cheap, **knowing what to build** can become the bottleneck.

Not big upfront design ([Agile Manifesto](http://www.ambysoft.com/essays/agileManifesto.html)) — **validated learning**.

---

## Levels

| Level | Posture |
|---|---|
| **0** | Build without problem statement |
| **1** | Build requests directly; success = shipped |
| **2** | Stakeholder conversations; informal priority |
| **3** | Written problem + success criteria before build |
| **4** | Thin experiments/prototypes; data informs priority |
| **5** | Continuous discovery tied to **outcomes**, not output counts |

---

## Joel mapping

| Item | Level |
|---|---|
| Spec | 3+ lightweight, living |
| Up-to-date schedule | 2–3 planning honesty |
| Hallway usability | 4–5 feedback |

---

## DORA

DORA measures **delivery** of what you build — not whether you built the right thing. Low discovery maturity can yield high deployment frequency on the **wrong** features. Use this axis when DORA metrics look good but outcomes don't.

---

## AI era

| Anti-pattern | Why |
|---|---|
| Agent-generated epic nobody asked for | [TAGRI](../artifact-discipline-and-ai.md) failure |
| Build full feature to "learn" | Skip L4 experiments |
| Success = story points | Output not outcome |
| Fluent plan, no operator contact | [ai-for-unfamiliar-domains](../ai-for-unfamiliar-domains.md) — verification ≠ discovery |

**Shoshin before build:** [spar](../sparring-and-shoshin.md) on problem frame.

---

## Corpus

**Thin by design** — [The Shift](../the-shift.md), workflow essays; no product management library wing yet.

Framework for conversation until deliberate product content added.

---

## Cross-axis

```text
Product discovery ──feeds──▶ Architecture (what to build)
                  ──feeds──▶ Deployment (what to ship)
                  ──optional──▶ Documentation (problem briefs)
```

Mark **N/A** on [worksheet](worksheet.md) for pure infra teams.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

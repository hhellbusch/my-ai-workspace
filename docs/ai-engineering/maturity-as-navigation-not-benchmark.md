---
review:
  status: unreviewed
  notes: "Spar follow-up — corpus framing; draft essay 2026-08-12."
---

# Maturity as navigation — not a benchmark for this workspace

> **Audience:** Readers of [Software Systems Maturity](software-systems-maturity.md) who wonder whether Field Notes is claiming to be "level N" on its own rubric.
>
> **Purpose:** Separate three jobs the maturity content does — and state plainly what this repository is **not** scoring.

**Related:** [Trailhead](software-systems-maturity.md) · [Artifact map](../../research/software-systems-maturity/findings/artifact-map.md) · [Assessment worksheet](maturity/worksheet.md) · [DORA research note](../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md)

---

## Three jobs (do not collapse them)

| Job | Question | Where it lives |
|---|---|---|
| **Rubric** | What does level 3 vs 4 mean on an axis? | Trailhead summaries + [deep dives](maturity/README.md) |
| **Example evidence** | Which paths in Field Notes illustrate a practice? | Deep dive "example evidence" sections + [artifact map](../../research/software-systems-maturity/findings/artifact-map.md) |
| **Your assessment** | Where is *our* team or service today? | [Worksheet](maturity/worksheet.md) — your links, your scores, your disagreement |

The rubric is **generic** — it should work for a VM shop, a product team, or a fleet platform group.
Example evidence is **local** — it points at `devops/`, `docs/`, skills, and `.planning/` in this repo only.
Your assessment is **yours** — Field Notes does not publish or defend a maturity score for itself.

---

## What Field Notes is not claiming

This workspace hosts a maturity **trailhead** and a **corpus** of GitOps, OpenShift, fleet, and AI-session patterns.
That does **not** mean:

- "Field Notes is L4 on documentation" — the repo demonstrates *some* L4-shaped practices while other axes stay thin or unmeasured.
- "If you copy these paths you are L4" — context, production load, and team practice still determine your level.
- "Rich corpus = high maturity" — we wrote more about deployment and platform because that is where the author's practice lives, not because those axes are "finished."

**Example evidence** answers: *"Where in this repo can I see a pattern that matches level N language?"*
It does not answer: *"How mature is Field Notes?"*

If you need a single number for this workspace, the model is the wrong tool — by design.

---

## Corpus bias (honest)

The [artifact map](../../research/software-systems-maturity/findings/artifact-map.md) labels corpus **rich**, **partial**, or **thin** per axis.

| Bias | Effect on readers |
|---|---|
| **GitOps / OpenShift / fleet-heavy** | Deployment, platform, and Argo examples dominate; VM or serverless teams get vocabulary, not parity of proof |
| **Meta-framework-heavy** | Documentation, AI agents, and team-practice "example evidence" often cites AGENTS, skills, spar/shoshin — this workspace's session architecture, not a typical product backlog |
| **Thin by choice** | Product discovery and data management stay framework + external canon until real corpus appears |

Levels transfer; examples do not — unless you deliberately reuse a pattern and re-assess in *your* context.

---

## The documentation circularity (and why it is still useful)

The documentation deep dive describes dual-audience knowledge (humans + agents) and cites this repo's own structure as **example evidence**.
That looks circular: the model describing itself as proof of the model.

It is useful if you read it as a **case study**, not a **certificate**:

- **Case study:** "Here is one way a practitioner organized docs, handoffs, and skills for AI-assisted work — judge fit for your team."
- **Certificate:** "This repo passed level 4" — **not** what we intend.

Same for AI agents and team practices: the corpus is autobiographical practice notes, not an audit result.

---

## DORA alongside this model (optional, not verdict)

[DORA](https://dora.dev/) and *Accelerate* measure **delivery outcomes** on a defined service or pipeline — deployment frequency, lead time, MTTR, change failure rate — and correlate them with capabilities in studied populations.

Use DORA when you have metrics and a bounded scope.
Use per-axis maturity when work spans platform, fleet, documentation-for-agents, or AI harnesses that DORA does not name.

Do not merge the two into one score.
Correlation in published research is not a guarantee in your org — see the [working research note](../../research/software-systems-maturity/findings/dora-accelerate-and-ai-systems.md) for limits and open AI-era questions.

---

## How to read example-evidence tables

In each deep dive, **Example evidence for this workspace** lists paths that **illustrate** rubric language.

When using them:

1. Read the **level table** first — decide if the practice matches the level for *your* situation.
2. Open example paths as **patterns to study or fork**, not as proof Field Notes (or you) "passed."
3. Check **artifact map richness** — thin axes need external canon ([Fowler](https://martinfowler.com/), *Accelerate*, vendor docs), not more repo links.
4. Fill the **worksheet** with *your* evidence URLs — pipelines, runbooks, incident reviews — not links back to this essay.

Disagreement about level on a single axis is often the most valuable workshop output.

---

## Draft rubric disclaimer

Level tables in the trailhead and deep dives are a **draft resurrection** of a 2016 deck, iterated for 2026 (platform, agents, dual-audience docs).
They are meant for **prioritization and conversation**, not certification, benchmarking Field Notes, or org-wide league tables.

Peer review of rubrics is welcome if the framework spreads beyond this workspace — until then, treat numbers as hypotheses you test in practice.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

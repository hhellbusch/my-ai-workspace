# Framework Efficacy Research

**Purpose:** Systematic measurement of whether this workspace's session framework produces meaningfully better outcomes than unstructured AI-assisted work — and specifically, what kinds of failures it catches and what it misses.

**Thesis under test:** "The primary challenge in long-horizon AI-assisted work isn't prompting skill — it's state management across sessions, context windows, and domain boundaries."

---

## What's being measured

The framework consists of several structural interventions. Each has a claimed failure mode it defends against. This research track measures whether those claims hold in practice.

| Intervention | Claimed failure mode addressed | Measurable signal |
|---|---|---|
| `/spar` | Sycophancy — AI validates framing instead of challenging it | Arguments found, structural vs. surface ratio, internal contradictions detected |
| Shoshin / `/start` | Stale framing inherited from prior session | Stale assumptions caught before scope was set |
| SHA-anchored briefings | Brief is outdated relative to current repo state | SHA drift events caught |
| Compaction detection | Compressed in-context memory drives wrong decisions | Compaction surfaced and re-read triggered |
| `/checkpoint` + `/whats-next` | Context loss at session boundary | Context reconstructed from artifacts alone |
| Thread tracking | Depth-first conversation loses parent thread | Threads returned to after resolution |

---

## Evidence sources

1. **[Intervention log](intervention-log.md)** — Append-only record of framework interventions that fired and what they caught. One entry per notable event. Updated via `/whats-next` and `/checkpoint`.

2. **[Counterfactual comparisons](counterfactual-protocol.md)** — Controlled comparison: same task run with structured intervention vs. naive baseline. Currently used for `/spar`; extendable to other interventions. Provides comparative rather than observational evidence.

3. **Case studies** — `docs/case-studies/` contains documented instances of failures caught and patterns validated. These predate this research track and are observational (no baseline). They function as existence proofs, not rates.

---

## What this can and can't claim

**Can claim:** Specific failure modes occur in AI-assisted work; specific interventions catch them when they occur; here is the incidence rate over N sessions.

**Cannot claim (without counterfactual data):** The framework produces better outputs than baseline on a given task; the framework is worth its overhead cost; any specific intervention is necessary vs. sufficient.

Counterfactual protocol data (see `counterfactual-protocol.md`) is required to make the stronger comparative claim.

---

## Related

- `docs/ai-engineering/session-framework.md` — Human-facing explanation of why each behavior exists
- `docs/case-studies/README.md` — Pre-existing observational case study library
- `docs/ai-engineering/the-meta-development-loop.md` — The engineering loop that produced this framework

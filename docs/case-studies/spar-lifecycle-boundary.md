---
review:
  status: unreviewed
---

# When the System Boundary Is the Argument

`workflow` — A named sparring methodology move: the lifecycle boundary question. When evaluating a claim, the most important thing to ask is often not whether the number is right but where the analysis drew its boundary — and why.

---

## The Pattern

A spar generates counterarguments typed by the kind of weakness they represent: structural flaw, evidence gap, scope problem, consistency issue, presentation issue. One of the most common and hardest-to-spot weakness types sits between "evidence gap" and "scope problem": **the lifecycle boundary question**.

When an argument presents a number, a benchmark, a cost estimate, or a resource usage figure, the number is almost always technically correct within the boundary the analysis drew. The question the spar should force is: *which boundary did they draw, and why?*

Different lifecycle inclusions produce numbers that are all defensible and all wildly different. The person presenting the small number is not lying. The person presenting the large number is not fabricating. They drew different lines around what counts as part of the system.

---

## A Worked Example: AI Water Use

Hank Green's 2026 video ["Why is Everyone So Wrong About AI Water Use??"](https://www.youtube.com/watch?v=H_c6MWk7PQc) provides a clear illustration of this pattern in public technical discourse.

Sam Altman stated that the average ChatGPT query uses roughly 1/15th of a teaspoon of water. A Morgan Stanley projection estimated that AI data centers could reach a trillion liters of annual water use by 2028 — an 11-fold increase from 2024 estimates.

Both numbers were described as approximately correct. They are not contradicting each other. They drew different boundaries.

**The narrow boundary (Altman's):** Count only the water consumed at the moment of inference — cooling the GPU cluster during the query itself.

**The wider boundaries (leading toward Morgan Stanley's):**
- Include training runs, which never stop (one model's training can account for ~50% of its total resource use, per UC estimates)
- Include infrastructure cooling for the buildings housing the servers
- Include power plant cooling water for the electricity the data centers draw — thermoelectric plants intake and release enormous quantities of water from rivers and lakes; US electricity generation accounts for 40% of all freshwater withdrawals nationally

Each step outward from "just the query" multiplies the number significantly. At the widest boundary, you can reach trillion-liter scale. No individual step requires any deception. The lie, as Hank frames it, is in presenting the narrow number without naming the boundary.

---

## The Sparring Move

When running a spar against any document, design decision, or argument that relies on a quantitative claim, add this to the standard probe set:

> **Where is the boundary drawn?** What lifecycle phases, external dependencies, or amortized costs are included — and which are excluded? If they had drawn the boundary one step wider, or one step narrower, how would the number change? Is the boundary choice made explicit, or is it invisible?

This question is productive in both directions:
- If the analysis draws a **narrow** boundary (e.g., only inference, only runtime, only direct costs), the spar should ask what's excluded and whether it's material.
- If the analysis draws a **wide** boundary (e.g., allocating training costs, including upstream supply chain), the spar should ask whether those costs are genuinely attributable and whether the comparison base uses the same boundary.

The goal is not to make every number look large or small. It is to make the boundary choice visible so the argument can be evaluated on its actual terms.

---

## What Good Looks Like

Hank Green models intellectual honesty on this explicitly — mid-video, after providing his own analysis:

> *"Like I know next to nothing about this. Like I have a master's degree in environmental studies that's old by the way... I still know basically nothing. Like, if an expert watches this video, they're going to see a ton of holes in it."*

He then names what he is not including, explains why each category is distinct (municipal water vs. industrial vs. agricultural), and redirects to what he thinks is actually the larger concern (power demand, not water). This is what a well-boundaried argument looks like: the boundary is named, the exclusions are acknowledged, and the analysis is explicit about what level of expertise it carries.

The practical equivalent in a spar response: when the strongest counterargument is a lifecycle boundary objection, the revision should name the boundary explicitly — "this analysis covers X but excludes Y because Z" — rather than either defending the narrow number as complete or abandoning it.

---

## Applications

This pattern generalizes across work types in this project:

**Essay arguments:** Claims like "AI assistance speeds up development" often draw a narrow boundary (time at keyboard) and exclude a wider one (time verifying AI output, correcting hallucinations, architectural decisions still requiring human judgment). A spar should ask for the full lifecycle.

**Design decisions:** "This caching layer reduces latency" — does that include cold start, cache invalidation, increased memory pressure, and deployment complexity? What did the benchmark not count?

**Cost analyses:** "Self-hosting is cheaper than API" — does that include maintenance time, hardware depreciation, model upgrade cycles, and the opportunity cost of the engineering hours spent? (The Braincuber 87% API-wins finding is relevant here — see `docs/ai-engineering/ai-assisted-development-workflows.md`.)

**Benchmarks:** AI model benchmark scores are particularly prone to invisible boundary drawing — models may be trained on benchmark-adjacent data, benchmarks measure narrow competency, and "performance" rarely accounts for inference cost or failure modes outside the test distribution.

---

## When This Applies — and When It Doesn't

The lifecycle boundary question applies when:
- The argument relies on a quantitative claim that drives a recommendation
- The claim could plausibly look very different if the scope were drawn differently
- The analysis doesn't name its scope assumptions explicitly

It does not apply when:
- The argument is qualitative and the scope is explicit
- The number is clearly illustrative rather than decisive
- The scope is domain-standard and uncontroversial (e.g., "we measured wall-clock time on this hardware")

The failure mode to avoid: treating every number as suspect until the entire causal chain is included. Some analyses have a natural and obvious scope. The lifecycle boundary question is for when the scope feels narrow in a way that's doing rhetorical work.

---

## Related

- [Hank Green — AI Water Use (library entry)](../../library/hank-green-ai-water-use.md)
- [Sparring and Shoshin](../ai-engineering/sparring-and-shoshin.md)
- [When the Source Says the Opposite of the Claim](context-stripped-citations.md)
- [Adversarial Review as a Meta-Development Pattern](adversarial-review-meta-development.md)

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

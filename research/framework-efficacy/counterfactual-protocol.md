# Counterfactual Protocol — Controlled Comparison

**Purpose:** Generate comparative (not just observational) evidence that framework interventions produce meaningfully different outputs than unstructured baseline interactions on the same task.

**Primary use case:** `/spar` — the adversarial review command, where the output is analyzable on a rubric. Extendable to other interventions as measurement needs grow.

---

## Protocol for `/spar` baseline comparison

### Step 1: Run the naive baseline first

**Before** invoking `/spar`, ask the model a plain, unstructured question:

> "What are the main weaknesses of [target]? Give me your honest assessment."

Or for documents:
> "Read this and tell me where the argument breaks down or where the claims are unsupported."

Capture the full output. Label it **Naive Pass**.

**Why first:** If the structured spar runs first, the naive pass will be contaminated — the model has already done the analysis and will pattern-match toward the same arguments. The naive pass must be genuinely naive.

### Step 2: Run the full `/spar`

Run `/spar [target]` normally. Full methodology, self-audit, strength ratings. Label this **Structured Pass**.

### Step 3: Score both on the rubric

Apply the scoring rubric below to both outputs independently.

### Step 4: Log the comparison

Add an entry to `intervention-log.md` with:
- What the naive pass found
- What the structured pass found that the naive pass missed
- Rubric scores for both
- Judgment: did the structure add value, add noise, or make no difference?

---

## Scoring rubric

Score each output on five dimensions, 1–3:

| Dimension | 1 — Surface | 2 — Substantive | 3 — Structural |
|---|---|---|---|
| **Argument depth** | General concerns ("this is complex," "adoption might be hard") | Specific claims with mechanisms ("X fails because Y") | Identifies what breaks if the argument is valid |
| **Internal targeting** | Argues against a strawman or the weakest claims | Argues against real claims in the target | Finds places where the target contradicts itself |
| **Load-bearing awareness** | Treats all claims equally | Distinguishes important from minor claims | Explicitly identifies which claim is load-bearing and attacks it |
| **Evidence vs. assertion** | Accepts assertions at face value | Notes where claims are asserted without support | Correctly names specific assertions dressed as evidence |
| **Self-awareness** | No self-critique | Acknowledges some arguments are stronger than others | Explicitly audits its own work and names the weakest argument |

**Total range:** 5–15. A naive pass typically scores 5–8. A well-executed structured spar should score 10–15. Gap of 4+ is meaningful signal.

---

## Protocol for other interventions (future)

The same structure applies. For each intervention, define:
1. **Naive baseline procedure** — what would an unstructured interaction look like?
2. **Output to compare** — what artifact or behavior is being measured?
3. **Rubric** — what dimensions distinguish quality?

Candidates for future counterfactual protocols:

| Intervention | Naive baseline | Output to compare |
|---|---|---|
| Shoshin / `/start` | Start session without reading source docs; ask "what should I work on?" | Accuracy of session framing vs. actual repo state |
| SHA briefing check | Start from briefing without checking SHA drift | How many stale assumptions were inherited vs. caught |
| Compaction detection | Continue session without re-reading — rely on in-context summary | Decision accuracy in second half of long session vs. after re-read |

---

## Comparison log

*Add entries here after each controlled comparison. Date and brief summary; full detail in `intervention-log.md`.*

| Date | Intervention | Target | Naive score | Structured score | Key delta |
|---|---|---|---|---|---|
| *(none yet)* | | | | | |

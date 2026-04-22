# Style Guide

> Template — customize each section for your project. Delete sections that don't apply.
> Add a `> Version:` line at the top when you publish this for your team.
>
> Reference this at session start for any writing work. The shoshin practice checks this
> file before writing — having it populated means those checks land on something real.

---

## Writing defaults

These apply across all content types unless a section below overrides them.

**Brevity:** Prefer shorter over longer. Cut before adding. One sentence that lands is worth more than three that circle.

**Voice:** [DEFINE — first person / second person / inclusive "we" / observer voice. Pick a default for this project.]

**Audience:** [DEFINE — who reads this and what they already know. Write to that reader, not to all possible readers.]

**Tone:** [DEFINE — calibrate with an example: what's too formal, what's too casual, what's the target. A useful starting point: write for a skeptical peer who values precision over enthusiasm.]

**Claims:** Pair assertions with their limits. "This works in X context" is more useful than "this works." If something is unverified, say so.

**AI-generated content:** [DEFINE — your policy on AI disclosure, review status, and what "unreviewed" means here. If there is no policy, see `WORKING-STYLE.md` verification section for a starting point.]

**What this content is not:** [DEFINE — the failure mode you want to avoid. Examples: not a marketing pitch, not a technical manual for experts only, not a running log of decisions, not memoir.]

---

## Documentation

Guides, READMEs, concept docs, how-tos.

**READMEs:** Orient, don't document. A README tells the reader what's here and where to go next — not everything the system does. If the README is long, the structure probably needs work.

**How-to guides:**
- Task-oriented — title starts with a verb
- Each step is one action
- State the expected output for steps where it isn't obvious
- State what done looks like at the end

**Concept docs:**
- Explain why, not just what
- State what problem the concept solves — not just its definition
- One concept per doc; link to related concepts rather than embedding them

**Structure defaults:**
- `#` for title
- `##` for main sections, `###` for subtopics
- [DEFINE — any project-specific structural conventions, frontmatter, or headers]

---

## Project management

Briefs, roadmaps, backlog items, handoffs.

**Briefs:** One-liner first, then: problem, hypothesis, success criteria, known risks, scope. Written once and updated when scope actually changes — not a running log.

**Roadmaps:** Phase-based. Each phase has a goal, deliverables, and a status that stays current. A roadmap where all phases are marked "complete" but the work isn't done is worse than no roadmap.

**Backlog items:** Include enough context that a fresh session understands the item without the original conversation. Link to relevant files. State definition of done.

**Handoffs:** Orient the next session, don't summarize this one. What's in flight, what's decided, what the next step is. See `WORKING-STYLE.md` for the checkpoint format.

**Changelogs:** Append-only. Each entry: date, what changed, why. Short.

---

## Architecture Decision Records (ADRs)

Write an ADR when a significant decision has real trade-offs and future contributors would be confused without context. Not for obvious choices.

**Format:**

```
# ADR-NNN: [Title — state the decision, not the question]

**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-NNN

**Context:**
What situation forced this decision. What constraints are real.
What was tried or considered.

**Decision:**
What was decided. One clear statement.

**Consequences:**
What gets better. What gets worse. What is now constrained.
```

**Where ADRs live:** [DEFINE — e.g., `docs/adr/`, `docs/decisions/`]

Reference: [MADR](https://adr.github.io/madr/) if you want a more structured template.

---

## Technical resources

Runbooks, troubleshooting guides, examples.

**Runbooks:**
- Imperative steps — each step is one action
- State prerequisites before step 1
- State what done looks like
- For each step that can fail: what to check, what to do

**Troubleshooting guides:**
- Start with the symptom, not the cause
- Structure: symptom → investigation steps → root cause → resolution → prevention
- Include the diagnostic commands, not just the concepts

**Examples:**
- Minimal — the smallest thing that demonstrates the point
- Labeled — state what the example is for, not just what it does
- Working — examples that don't run are worse than no example

---

## Code style

[DEFINE — language-specific conventions, linter config, naming patterns, comment policy.]

**Comment policy default:** Comments explain why, not what. If a comment restates what the code does, delete it. If it explains a constraint or trade-off the code can't express, keep it.

---

## Cross-linking

When mentioning a specific file, doc, or resource by name in prose, link it on first mention in that section. The reader should be able to follow the reference without searching.

[DEFINE — any project-specific registries to keep current when new content is added. Common ones: a `docs/README.md` reading list, a `docs/adr/README.md` ADR index.]

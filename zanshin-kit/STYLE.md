# Style Guide

> Version: 2026-04-21
> Working defaults — adjust for your project. Project-specific supplements extend these
> in `.planning/{project}/STYLE.md` or equivalent. To start from scratch, copy `STYLE.template.md`.

---

## Writing defaults

**Voice:** Practitioner voice — observation from practice, not prescription. "This is what I've found" rather than "you should do this." Second person or inclusive "we" for applied sections; first person only when the author has directly provided that content.

**Brevity:** Prefer shorter over longer. Cut before adding. One precise sentence beats three that circle.

**Claims:** Pair assertions with their limits. "This works in X context" is more useful than "this works." If something is unverified, say so. Fluent prose is not evidence.

**Audience:** Peers who are skeptical of jargon and value precision. Write for someone landing on a single file via a direct link — not for someone with full project context.

**Tone:** Between too academic and too casual. Target: a skeptical peer who values precision over enthusiasm. Observation, not prescription. Not motivational speaker energy.

**What this content is not:** Not prescriptive. Not motivational. Not academic. Insight from practice that the reader can evaluate and use — not a system they have to buy into.

**AI-generated content:** All AI-assisted content carries a disclosure notice. Unreviewed content is labeled as such. Before sharing any AI-generated content externally, confirm review status. Standard footer for new documents:

*This document was created with AI assistance and has not been fully reviewed by the author.*

Update to "has been reviewed by the author" when the author has read and validated the content.

---

## Documentation

Guides, READMEs, concept docs, how-tos.

**READMEs:** Orient, don't document. A README tells the reader what's here and where to go next — not everything the system does. If the README is long, the structure probably needs work.

**How-to guides:**
- Task-oriented — title starts with a verb
- Each step is one action
- State expected output for steps where it isn't obvious
- State what done looks like at the end

**Concept docs:**
- Explain why, not just what
- State what problem the concept solves — not just its definition
- One concept per doc; link to related concepts rather than embedding them

**Structure defaults:**
- `#` for title, optionally with an em-dash subtitle
- Front matter: brief audience and purpose statement near the top
- `##` for main sections, `###` for subtopics
- Horizontal rules `---` between major thematic blocks

---

## Project management

Briefs, roadmaps, backlog items, handoffs.

**Briefs:** One-liner first, then: problem, hypothesis, success criteria, known risks, scope. Written once and updated when scope actually changes — not a running log.

**Roadmaps:** Phase-based. Each phase has a goal, deliverables, and a status that stays current. A roadmap where all phases are marked complete but the work isn't done is worse than no roadmap.

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

**Where ADRs live:** `docs/adr/` or `docs/decisions/` — pick one and keep it consistent.

Reference: [MADR](https://adr.github.io/madr/) for a more structured template.

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
- Include diagnostic commands, not just concepts

**Examples:**
- Minimal — the smallest thing that demonstrates the point
- Labeled — state what the example is for, not just what it does
- Working — examples that don't run are worse than no example

---

## Biographical content

Any first-person claim a reader would attribute directly to the author needs explicit review before sharing:

- Professional titles or role descriptions
- Claims about personal experience ("in my years of practice...")
- Opinions presented as the author's
- Biographical details

When biographical content is needed and the author hasn't provided the specific detail, use general framing ("a practitioner might notice...") rather than fabricating a claim. Flag it: "This draft contains biographical statements on lines N–M that need author review."

---

## Code style

**Comment policy:** Comments explain why, not what. If a comment restates what the code does, delete it. If it explains a constraint or trade-off the code can't express, keep it.

Language-specific conventions, linter config, and naming patterns: define these when the project has established conventions worth encoding here.

---

## Cross-linking

When mentioning a specific file, doc, or resource by name in prose, link it on first mention in that section. Do not repeat the link within the same section. The reader should be able to follow the reference without searching.

When new content is added, check whether any registry needs updating — a reading list, an ADR index, a changelog. Registries that aren't updated when content is added silently degrade.

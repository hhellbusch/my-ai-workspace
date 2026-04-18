# Anonymized patterns — high-throughput AI collaboration

**Purpose:** Distill recurring **patterns** observed in building this workspace — drawn from the `docs/ai-engineering/` essays, case studies, and the upstream contributions work documented there. Use this file when drafting essays, workflows, or onboarding: it is a **pattern catalog**, not a biography or external survey.

**Sources:** [`docs/ai-engineering/ai-assisted-development-workflows.md`](../../docs/ai-engineering/ai-assisted-development-workflows.md), [`docs/ai-engineering/ai-assisted-upstream-contributions.md`](../../docs/ai-engineering/ai-assisted-upstream-contributions.md), [`docs/ai-engineering/the-meta-development-loop.md`](../../docs/ai-engineering/the-meta-development-loop.md), and the [`docs/case-studies/`](../../docs/case-studies/) track.

**Relationship to verification:** These patterns are observable in the artifacts above. If a pattern cannot be traced back to a specific essay or case study, it should be treated as inference and labeled as such.

---

## Patterns (paraphrased)

1. **Stacked assistants** — Use one tool for hands-on editing and another for review or diff critique. Different models or modes catch different classes of mistake; the value is in **separation of concerns**, not in collecting tools.

2. **Deliberately unfamiliar ground** — It can be rational to task an assistant with a platform or toolchain you do not run locally (e.g. another OS or vendor stack), **if** validation happens elsewhere: CI, a colleague’s machine, or a cloud runner. The human’s role shifts to **specification, review, and integration** — not typing every line in that environment.

3. **Async “intern” cadence** — Assign a bounded change, disconnect, return later to inspect diffs and run checks. Wall-clock human time stays small; calendar time may span hours. This only works when the task boundary and success criteria are clear enough that “come back and see what happened” is safe.

4. **Issue-first delegation** — For mature repos, a tracker link, log excerpt, or crisp failure description plus repository context is often enough for a useful first pass. The human still **reproduces**, **tests**, and **merges**.

5. **Closing the review loop** — After review feedback (from a person, from automation, or from a second assistant), the editing assistant applies follow-up fixes in a tight loop. Productivity comes from **treating review as input to the same pipeline**, not as a separate rewrite session — again with a human gate on the final result.

6. **Compounding through habit** — Reported gains track less with “one clever prompt” than with **defaulting** to the assistant for unfamiliar work, review churn, and mechanical fixups — always paired with verification habits that match risk.

---

## What this file is not

- Not a transcript, interview, or citable quote source.
- Not evidence that any particular stack or vendor is “best.”
- Not permission to skip `voice-approved` content, fabricated URLs, or cluster-unverified claims elsewhere in the repo.

## Related workspace material

- [`docs/ai-engineering/ai-assisted-development-workflows.md`](../../docs/ai-engineering/ai-assisted-development-workflows.md) — full workflow guide. The *Six patterns at a glance* table (§ Core Mental Shift) uses the vocabulary from this file with section-level coverage pointers.
- [`.cursor/rules/workspace-ethos.md`](../../.cursor/rules/workspace-ethos.md) — default collaboration posture.
- [`library/dan-walsh-devconf-2025-career-lessons.md`](../../library/dan-walsh-devconf-2025-career-lessons.md) — **public** primary narrative (talk transcript); complementary to this pattern list, not the same provenance.

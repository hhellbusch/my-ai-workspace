# Engineering Principles

Guiding principles for making engineering tradeoffs. These are judgment aids, not rigid rules — they exist to help reason about design decisions, not to mandate specific outcomes.

---

## DRY — Don't Repeat Yourself

Duplicate code, logic, or configuration is a maintenance burden waiting to manifest. When you copy-paste the same pattern three times, extract it. When two files need the same config value, parameterize it.

**Don't confuse DRY with DFO (Don't Fracture Over).** Over-engineering abstractions to avoid a single duplication point often creates more problems than it solves. Abstraction for abstraction's sake is just complexity with a slogan. Ask: does this duplication represent a real risk (it will change at different times), or is it just noise?

**Rule of thumb:** One duplication = coincidence. Two = question. Three = extract. But only extract if the duplicated parts are likely to diverge.

---

## KISS — Keep It Stupid Simple

Prefer the simplest solution that works. If a three-line script solves a problem that a framework would solve, use the script. Complexity should be earned, not assumed.

Simple does not mean naive. It means the solution doesn't introduce unnecessary layers of indirection, abstraction, or ceremony. A solution is simple when a new team member can understand it in ten minutes, not when it's a few lines of clever code.

**Rule of thumb:** If you'd need more than three sentences to explain why your approach is simpler, it isn't.

---

## SRP — Single Responsibility Principle

A module, function, or component should have one and only one reason to change. If a file does two things, it has two responsibilities. Separate them.

This applies to guards, scripts, config files, and documentation — not just code. A guard that handles secrets, review loops, and scope warnings violates SRP. A README that documents architecture, conventions, and release procedures violates SRP.

**Rule of thumb:** If you can't name the thing in a single noun phrase ("credential scanner", "link validator", "context injection"), it probably has too many responsibilities.

---

## Broken Windows

Leave things better than you found them. When you notice technical debt, a broken link, a stale comment, or a misnamed file — fix it while you're there. Small improvements accumulate.

This doesn't mean rewriting everything. It means: if you're touching line 42, fix the typo on line 43. If you're reading this file to understand the format, add a comment for the next person. If you notice a guard that's not doing what its name implies, rename it.

**Rule of thumb:** Your footprint should be smaller than when you arrived.

**Practical constraint:** If the fix requires more than 5 minutes or would pull you into scope creep, note it in the backlog and move on. Broken windows doesn't mean you're responsible for everything broken.

---

## How to Use These

These are not a checklist. They are lenses — look through the one that illuminates the problem at hand. When two principles conflict (DRY vs. KISS, for instance), the conflict is the signal — the right answer usually involves accepting the tension rather than resolving it.

---

## Related

- `rules/shell-strict-mode.md` — technical enforcement of a KISS principle (simple header, hard consequences)
- `rules/structured-edit.md` — DRY applied to file modification (edit in-place rather than copy-modify-write)
- `BACKLOG.md` — engineering principles violations worth documenting and fixing

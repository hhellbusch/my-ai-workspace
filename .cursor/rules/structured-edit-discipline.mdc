---
description: Discipline for insertion-vs-replacement edits in structured files (Python and others)
globs:
alwaysApply: true
---

# Structured Edit Discipline

Applies to any edit where the goal is **inserting** code before or after an existing block — not replacing it.

## The anchor rule

When using `old_str` (or any edit anchor) to locate an insertion point:

- Every line in `old_str` that should survive the edit **must appear verbatim in `new_str`**.
- If a line is in `old_str` but absent from `new_str`, that is a **deletion** — verify it is intentional before proceeding.
- "Context lines" used only to locate the anchor are not context if they disappear. They are casualties.

## Python file safety net

After any Write or StrReplace on a `.py` file, the PostToolUse hook at `.claude/hooks/py-edit-check.sh` runs automatically and injects two signals into context:

1. **AST parse result** — catches syntax breakage immediately
2. **Top-level function inventory** — `grep -n "^def "` output so a dropped function is visible in the next turn, not at commit time

The hook output is the detection layer. The anchor rule above is what prevents the failure in the first place.

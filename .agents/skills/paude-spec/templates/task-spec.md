# Task: <title>

**Session:** `<session-name>`
**Harvest branch:** `harvest/<slug>`
**Agent:** pi (default)

## Objective

<One paragraph — outcome, not implementation.>

## Scope

**In:**

-

**Out:**

-

## Repos

| Repo | Expected changes |
|------|------------------|
| Main workspace | |
| submodules/ | none / list |

## Constraints

-

## Success criteria

- [ ]
- [ ]

## Commit discipline

- Work on `harvest/<slug>` in the main repo — **not** `main`
- Submodule changes: commit inside submodule first, then update pointer in parent
- Submodule defaults: `paude-proxy` → `develop`, `paude` → `main`, `pelorus` → `maci0-main`
- Do **not** push unless explicitly instructed
- Do **not** run `git submodule update --remote`

## When finished

Follow the harvest prep checklist in `devops/paude/harvest-prep-prompt.md` (or the copy at `.agents/skills/paude-spec/templates/harvest-prep-prompt.md`).

Write `AGENT-NOTES.md` and print:

```text
HARVEST READY
session: <session-name>
branch: harvest/<slug>
commits: <N>
submodules: <list>
patches: <path or none>
notes: AGENT-NOTES.md
```

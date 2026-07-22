# Review tracking

YAML frontmatter on markdown in `docs/` and `devops/` records human review status.
Pair with the AI disclosure footer at the bottom of each file.

## Required on new files

Every new `.md` file under `docs/` or `devops/` must open with:

```yaml
---
review:
  status: unreviewed
  notes: "One-line provenance: how created, what still needs validation."
---
```

If the file already has YAML frontmatter (e.g. `description:`), add the `review:` block inside the same `---` fence — do not create a second frontmatter block.

## Status values

| Status | Meaning |
|--------|---------|
| `unreviewed` | Default for new or backfilled content; author has not read line-by-line |
| `direction-reviewed` | Author shaped intent; full output not re-read |
| `reviewed` | Author has read and recorded validation type(s) via `/validate` |

## After human review

Use `/validate <path> <type>` to merge validation metadata.
See `.agents/skills/validate/SKILL.md` and `AI-DISCLOSURE.md` for validation types (`read`, `commands-verified`, `voice-approved`, etc.).

Example after review:

```yaml
---
review:
  status: reviewed
  read: 2026-07-22
  at: abc1234
  notes: "Verified against OCP 4.18 lab."
---
```

## Legacy content

Files without `review:` frontmatter are treated as **direction-reviewed** until backfilled or validated.
Backfill uses `status: unreviewed` with a dated notes line — not an assertion that content is wrong, only that review metadata was missing.

## Disclosure footer alignment

When `status` advances to `reviewed`, update the AI disclosure footer if it still says "has not been fully reviewed" — see `/validate` skill step 5.

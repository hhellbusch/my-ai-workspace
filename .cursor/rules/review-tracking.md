---
description: Convention for tracking human review and validation status of AI-generated content
globs:
alwaysApply: true
---

# Review Tracking Convention

## Frontmatter Format

Files that have been reviewed by the author use a `review:` block in YAML frontmatter:

```yaml
---
review:
  status: reviewed
  read: 2026-04-18
  tested: 2026-04-18
  notes: "Verified on OCP 4.14"
---
```

Fields:
- `status` — one of: `reviewed`, `direction-reviewed`, `unreviewed`
- Validation type fields — date values (YYYY-MM-DD) for each validation performed
- `notes` — optional free-text context

For files that already have frontmatter (commands, skills, rules), add `review:` to the existing block. For files without frontmatter, add a new `---` block at the top of the file.

## Validation Types by Content Category

| Category | Location | Types |
|---|---|---|
| Essays / case studies | `docs/**` | `read`, `fact-checked` |
| DevOps examples | `{product}/examples/**` | `read`, `tested` |
| Troubleshooting guides | `{product}/troubleshooting/**` | `read`, `commands-verified` |
| Meta-system | `.cursor/commands/`, `.cursor/skills/`, `.cursor/rules/` | `read`, `used-in-practice` |
| Research / library | `research/**`, `library/**` | `read`, `sources-checked` |

Additional types can be added per file when relevant.

## Default Assumption

Files without a `review:` block are assumed to be **direction-reviewed** — the author guided creation but has not read the full output. See `AI-DISCLOSURE.md` for the full policy.

## Agent Behavior

- **Do NOT add `review:` frontmatter when generating new files.** Review status is the author's responsibility, applied via `/validate` or manually.
- **Do NOT modify existing `review:` blocks** unless the user explicitly asks.
- When the `/validate` command updates a file to `status: reviewed`, offer to update the AI disclosure footer if one exists (change "has not been fully reviewed" to "has been reviewed by the author").

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
  at: abc1234
  notes: "Verified on OCP 4.14"
---
```

Fields:
- `status` — one of: `reviewed`, `direction-reviewed`, `unreviewed`
- Validation type fields — date values (YYYY-MM-DD) for each validation performed
- `at` — short git SHA of HEAD at validation time, auto-recorded by `/validate`. Enables `git diff <sha>..HEAD -- <file>` to see exactly what changed since the last review.
- `notes` — optional free-text context

For files that already have frontmatter (commands, skills, rules), add `review:` to the existing block. For files without frontmatter, add a new `---` block at the top of the file.

## Validation Types by Content Category

| Category | Location | Types |
|---|---|---|
| Essays / case studies | `docs/**` | `read`, `fact-checked`, `voice-approved` |
| DevOps examples | `{product}/examples/**` | `read`, `tested` |
| Troubleshooting guides | `{product}/troubleshooting/**` | `read`, `commands-verified` |
| Meta-system | `.cursor/commands/`, `.cursor/skills/`, `.cursor/rules/` | `read`, `used-in-practice` |
| Research / library | `research/**`, `library/**` | `read`, `sources-checked` |

Additional types can be added per file when relevant.

### Biographical and Voice Content — Elevated Priority

Content that speaks in the author's voice, makes claims about the author's background, experience, professional identity, or personal opinions requires **`voice-approved`** validation. This is higher priority than a general `read` because readers will attribute these statements directly to the author.

Patterns that require `voice-approved`:
- Professional titles or role descriptions ("an infrastructure engineer," "a consultant")
- Claims about personal experience ("in my years of practice," "I trained in...")
- Opinions presented as the author's ("I believe," "I've found that")
- Biographical details (training history, career path, personal philosophy)
- Any first-person claim a reader would take as autobiography

Files with biographical content that have only `read` validation (not `voice-approved`) should be flagged during `/audit` as needing elevated review.

## Default Assumption

**New generated files** carry an explicit `status: unreviewed` frontmatter block (added by the agent at creation time — see Agent Behavior below).

**Legacy files without a `review:` block** (created before this convention was adopted) are assumed to be **direction-reviewed** — the author guided creation but has not read the full output. See `AI-DISCLOSURE.md` for the full policy.

## Agent Behavior

- **Add `status: unreviewed` frontmatter when generating new content files.** Every new `.md` file in `docs/`, `library/`, `research/`, or product directories (`{product}/examples/`, `{product}/troubleshooting/`) should open with a `review:` block. Do not add it to meta-system files (`.cursor/commands/`, `.cursor/skills/`, `.cursor/rules/`) that manage their own frontmatter schema.

  Use a `notes` field that names the specific verifications the file needs, matched to its content category:

  ```yaml
  ---
  review:
    status: unreviewed
    notes: "AI-generated draft. Needs read and fact-checked before sharing."
  ---
  ```

  Content-category defaults for the `notes` field:

  | Category | Default notes text |
  |---|---|
  | Essays / case studies (`docs/**`) | `"AI-generated draft. Needs read and fact-checked before sharing."` |
  | DevOps examples (`{product}/examples/**`) | `"AI-generated. Needs read and tested before use."` |
  | Troubleshooting guides (`{product}/troubleshooting/**`) | `"AI-generated. Needs read and commands-verified before use."` |
  | Research / library (`research/**`, `library/**`) | `"AI-generated summary. Needs read and sources-checked before citing."` |

  Add specifics when known: e.g., `"Power draw figures and LiteLLM setup steps need hands-on verification."` is more useful than the category default.

- **Do NOT modify existing `review:` blocks** unless the user explicitly asks.
- When the `/validate` command updates a file to `status: reviewed`, offer to update the AI disclosure footer if one exists (change "has not been fully reviewed" to "has been reviewed by the author").
- **Minimize unsolicited biographical content.** When generating essays or documentation, avoid fabricating biographical claims about the author (professional titles, experience claims, training history, personal opinions). If personal voice is needed and the author hasn't provided the specific detail, use general framing ("a practitioner might notice...") rather than inventing first-person claims. When biographical content is necessary, flag it explicitly so the author can review it.
- **Flag biographical content at generation time.** When new content contains first-person biographical claims, note this in your response: "This draft contains biographical statements on lines N-M that need your `voice-approved` review."
- **Flag when editing a reviewed file.** Before editing any file that has a `review:` block with `status: reviewed`, note to the user: "This file has been reviewed (read: DATE). This edit will make the review stale — you'll need to re-read the changes." This is not a blocker — proceed with the edit — but make the staleness visible so the author knows re-review is needed. Collect all edits to reviewed files and summarize at commit time: "N reviewed files were modified in this session and need re-review."

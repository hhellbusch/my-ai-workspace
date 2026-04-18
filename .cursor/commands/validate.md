---
description: Mark files as human-reviewed with specific validation types
argument-hint: "<file-or-directory> <validation-type> [validation-type...] [--notes 'context']"
allowed-tools:
  - Read
  - Write
  - StrReplace
  - Shell
  - Glob
  - Grep
---

# Validate — Mark Content as Human-Reviewed

<objective>
Record that the author has reviewed and validated specific files, tracking what kind of validation was performed and when. Updates YAML frontmatter in the target files. This is how review status grows organically — files start as direction-reviewed (no metadata) and gain validation records as the author works through them.
</objective>

<context>
- Review tracking convention: @.cursor/rules/review-tracking.md
- Disclosure policy: @AI-DISCLOSURE.md (Review Status and Validation Types sections)
</context>

<process>

### Step 1: Parse arguments

Parse `$ARGUMENTS` to extract:

- **Target**: file path or directory path
- **Validation types**: one or more of `read`, `fact-checked`, `tested`, `commands-verified`, `used-in-practice`, `sources-checked`, `voice-approved`
- **Notes**: optional, after `--notes` flag

Examples:
- `/validate docs/ai-engineering/the-shift.md read`
- `/validate docs/philosophy/ego-ai-and-the-zen-antidote.md read voice-approved`
- `/validate ocp/troubleshooting/api-slowness-web-console/ read commands-verified --notes "Verified on OCP 4.14"`
- `/validate .cursor/commands/backlog.md read used-in-practice`

If no validation type is provided, ask: "What kind of validation? Options: `read`, `fact-checked`, `tested`, `commands-verified`, `used-in-practice`, `sources-checked`, `voice-approved`"

**Special note on `voice-approved`**: This type means the author has reviewed content that speaks in their voice — biographical claims, professional identity, personal opinions, experience statements. If a `docs/` file contains biographical content and the user validates with `read` but not `voice-approved`, note: "This file contains biographical content. Consider also running `/validate <path> voice-approved` after reviewing those sections."

If the target is a directory, expand to all `.md` files in that directory (non-recursive by default; ask if the user wants recursive).

### Step 2: Read each target file

For each file:

1. Check if YAML frontmatter already exists (file starts with `---`)
2. Check if a `review:` block already exists within the frontmatter
3. Note the current state for the confirmation prompt

### Step 3: Preview changes

Show the user what will be updated:

```
## Validation Preview

### file-path.md
- Current status: [no metadata / direction-reviewed / reviewed]
- Adding: read (2026-04-18), commands-verified (2026-04-18)
- New status: reviewed
- Notes: "Verified on OCP 4.14"

### another-file.md
- Current status: reviewed (read: 2026-04-15)
- Adding: fact-checked (2026-04-18)
- Notes: none

Proceed? [y/n]
```

### Step 4: Apply changes

For each confirmed file:

**If file has no frontmatter** — add a new frontmatter block at the top:

```yaml
---
review:
  status: reviewed
  read: 2026-04-18
---
```

**If file has frontmatter but no `review:` block** — add `review:` to the existing frontmatter block.

**If file already has a `review:` block** — merge new validation types with existing ones. Do not overwrite existing dates; only add new types or update types explicitly being re-validated.

Set `status: reviewed` whenever any validation type is present.

### Step 5: Update disclosure footer (essays only)

For files in `docs/` that have the standard AI disclosure footer:

If the footer says "has not been fully reviewed by the author", offer to update it:

"This file now has review metadata. Want me to update the disclosure footer to say it has been reviewed?"

If yes, replace:
- *"...and has not been fully reviewed by the author..."*
with:
- *"...and has been reviewed by the author..."*

### Step 6: Summary

After applying all changes, show:

```
## Validation Complete

Updated N files:
- file-path.md — reviewed (read, commands-verified)
- another-file.md — reviewed (read, fact-checked)

Disclosure footers updated: M files
```

</process>

<success_criteria>
- Frontmatter correctly added or updated in all target files
- Existing frontmatter preserved (no data loss from merge)
- Validation dates use today's date (YYYY-MM-DD)
- User confirms before any writes
- Disclosure footer update offered for docs/ files
</success_criteria>

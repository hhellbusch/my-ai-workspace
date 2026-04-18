---
description: Review before committing — scale the review to the change
globs:
alwaysApply: true
---

# Pre-Commit Review Requirement

Every commit should be reviewed, but the depth of review scales with the change. A one-line fix doesn't need the same scrutiny as a new essay.

## Full `/review` — required for:
- New files (especially in `docs/`, `research/`, or product directories)
- Changes touching 5+ files
- Structural changes (new directories, moved files, renamed content)
- Any commit the user explicitly asks to review

Run the full `/review` command process: file placement, README coverage, cross-references, external URLs, content quality, secrets scan, biographical check, review status, backlog alignment.

## Quick review — sufficient for:
- Small edits to existing files (1-3 files, focused changes)
- Backlog updates
- Frontmatter-only changes
- Typo fixes, link corrections, inline definitions

A quick review means: read the diff, verify internal links resolve, check for secrets, and flag if any changed file has `review:` frontmatter (indicating the author's review is now stale). Present the diff summary to the user.

## Always, regardless of scale:
1. **Check for reviewed files.** If any staged file has `review: status: reviewed` in its frontmatter, flag it: "This commit modifies N reviewed file(s) — the author will need to re-read the changes." This is the most important check because it's the easiest to miss.
2. **Verify external URLs.** Any new http/https links must be fetched before committing. AI fabricates URLs.
3. **No secrets.** Scan for credentials, tokens, sensitive data patterns.

If the user asks you to "commit" without saying "review," apply the appropriate level above. Don't skip review entirely, but don't run a 10-step process for a one-line change.

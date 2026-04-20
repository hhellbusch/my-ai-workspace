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

**For directory moves specifically (`git mv`):** Before staging the commit, run `git status` and scan for any newly-tracked files that shouldn't be committed — particularly in directories that were previously gitignored. Path-based `.gitignore` rules break silently on moves. Look for: large binaries, credential files (kubeconfig, pull-secret, vault files, private keys), install directories. If unexpected files appear, fix the `.gitignore` before committing. See `docs/case-studies/directory-move-gitignore-drift.md`.

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
4. **AI disclosure footer on new `docs/` files.** Any new markdown file under `docs/` (excluding READMEs) must include the standard AI disclosure footer linking to `AI-DISCLOSURE.md`. The standard footer: *This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.* Adjust the relative path based on file depth. This is easy to forget when creating new case studies or essays.
5. **Flag performed-honesty language.** Scan new `docs/` content for self-referential honesty signals: phrases like "honest assessment," "the real story," "unlike other guides," "gets the math wrong," or "real data changes the conversation." These are not problems in themselves, but flag them to the author: "This document contains N self-referential honesty claims — verify that each one is earned by the surrounding content, not just asserted." The pattern to watch for: honesty language appearing in body text where unverified claims also appear. See `docs/case-studies/` for the "performed honesty" case study when written.

If the user asks you to "commit" without saying "review," apply the appropriate level above. Don't skip review entirely, but don't run a 10-step process for a one-line change.

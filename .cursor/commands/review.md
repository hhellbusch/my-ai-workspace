---
description: Review all pending changes against repo conventions before committing
allowed-tools:
  - Shell
  - Read
  - Glob
  - Grep
---

# Review — Pre-Commit Quality Gate

<objective>
Systematically review all staged and unstaged changes before committing. Catches misplaced files, missing READMEs, convention violations, stale cross-references, and content issues before they enter the commit history.

This command is read-only. It reports findings and asks for confirmation before any commit proceeds.
</objective>

<context>
- Repo conventions: @.cursor/rules/repo-structure.md
- Current changes: !`git status`
- Staged diff: !`git diff --cached --stat`
- Unstaged diff: !`git diff --stat`
- Untracked files: !`git ls-files --others --exclude-standard`
</context>

<process>
1. **Inventory changes** — List all new, modified, and deleted files from git status. Group by: new files, modified files, deleted files.

2. **Placement check** — For each new file, verify it belongs in its directory per the repo-structure rule:
   - Is a product-specific file in the right `{product}/` directory?
   - Is research output in `research/{topic}/`?
   - Is documentation in `docs/`?
   - Are repo root files limited to the allowed set?
   - Flag any misplaced files with suggested locations.

3. **README coverage** — For each new directory, check it has a README.md. For each new file in an existing directory, check the directory's README is updated to mention it (if the README maintains a contents list).

4. **Cross-reference and registry check** — For new content, verify the registries from `.cursor/rules/cross-linking.md` are updated:
   - If new doc in `docs/`: is it in the track `README.md` and `docs/README.md` cross-track list?
   - If new file in `library/`: is it in `library/README.md` enriched entries table AND `library/catalog.md`?
   - If new research directory: is it listed in `research/README.md`?
   - If new command in `.cursor/commands/`: is `.cursorrules` command count and list updated?
   - If new project in `.planning/`: is it in `.cursorrules` planning section?
   - If new prompt: is it numbered correctly in `.prompts/` and listed in `.cursorrules`?
   - If new backlog items: are dates and product tags present?
   - **Quick link spot-check**: For each new or modified markdown file, verify any internal links (relative paths) resolve to files that exist. Flag broken links.
   - **External URL verification**: For each new or modified markdown file, identify any new external URLs (http/https). Fetch each URL to confirm it resolves (not 404, not redirect to unrelated page). AI models fabricate plausible-looking URLs — this is a known failure mode, not an edge case. Flag any unverified or broken external links.

5. **Content quality** — For each new or modified file:
   - Markdown files: check for title heading, no obvious structural issues
   - Config files: check for valid syntax if tooling is available
   - No secrets, credentials, or sensitive data (flag `.env`, `*secret*`, `*credential*`, `*password*`, `*token*` patterns in content)

6. **Biographical/voice check** — For new or modified files in `docs/`, scan for content that speaks in the author's voice or makes biographical claims. Flag lines containing:
   - Professional titles or role descriptions applied to the author
   - First-person claims about experience, training, or career ("I trained," "in my years of")
   - Personal opinions stated as fact ("I believe," "I've found that")
   - Biographical details (training history, personal philosophy, specific life events)

   Present flagged lines with their file and line number under a **"Biographical Content — Needs `voice-approved`"** section. This is the highest-priority review item — readers will attribute these statements to the author. This is NOT a blocker, but it must be visible.

7. **Review staleness check** — For each **modified** file (not new), read its frontmatter. If it contains `review: status: reviewed`, flag it prominently:
   - "**Stale review**: `file.md` was reviewed on DATE but is being modified in this commit. The author needs to re-read the changes."
   - If the frontmatter includes an `at:` SHA, include the diff command: "Run `git diff SHA..HEAD -- file.md` to see what changed since last review."
   - This is the **highest-priority informational item** — it's the easiest thing to miss and the hardest to recover from. Present it above other findings.

8. **Review status note** — For new files in `docs/`, `research/`, or product directories (`devops/ansible/`, `devops/ocp/`, `devops/argo/`, etc.):
   - Note that these files will start as **direction-reviewed** (no `review:` frontmatter)
   - Remind: "Run `/validate <path> read` after you've reviewed these files"
   - If biographical content was flagged in step 6, remind: "Run `/validate <path> voice-approved` after reviewing the biographical content"
   - This is informational, not a blocker — new files are expected to lack review metadata

9. **AI disclosure footer check** — For each **new** markdown file under `docs/` (excluding README.md files), check that it includes the standard AI disclosure footer:
   - The footer should be an italic line at the end of the file linking to `AI-DISCLOSURE.md`
   - Standard text: *This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
   - The relative path to `AI-DISCLOSURE.md` depends on file depth (e.g., `../../` for files two levels below repo root)
   - Flag missing footers: "**Missing AI disclosure**: `file.md` — new docs file without standard footer"
   - This is a quick fix (add the footer) but easy to forget when creating new essays or case studies

10. **Backlog alignment** — Read `BACKLOG.md` and check if the work being committed relates to a tracked item. If not, note it (not a blocker, just a reminder).

11. **Present findings** as a structured report:

```
## Pre-Commit Review

### Changes Summary
- N new files, M modified, D deleted

### Stale Reviews (re-read needed)
- [ ] `file.md` — reviewed DATE, modified in this commit → `git diff SHA..HEAD -- file.md`
(or: No reviewed files modified.)

### Biographical Content — Needs `voice-approved`
- [ ] `file.md` line N: "quote of biographical claim"
(or: No biographical content detected in changed files.)

### Issues Found
- [ ] [severity] Description — suggested fix

### Verified
- File placement: OK / issues
- README coverage: OK / issues
- Cross-references: OK / issues
- External URLs: N verified / M broken or unverified
- Content quality: OK / issues
- Secrets scan: OK / issues
- Biographical scan: N lines flagged / clean
- Stale reviews: N reviewed files modified (re-read needed) / none
- Review status: N new files start as direction-reviewed (run `/validate` after reading)
- AI disclosure footer: OK / N new docs files missing footer
- Backlog alignment: tracked / untracked
```

12. **Assumptions to challenge** (for documentation and essay commits) — If the changes include `docs/`, `research/`, or essay-type content, add 1-3 brief adversarial observations. These are not blockers — they surface things the author should have considered:

```
### Assumptions to Challenge
- [observation] — e.g., "The central claim in section 3 is asserted without evidence"
- [observation] — e.g., "This contradicts the framing in docs/ai-engineering/the-shift.md section 6"
- [observation] — e.g., "The example assumes a single-region deployment"
```

Skip this section entirely for purely mechanical changes (config files, tooling, scaffolding). This is only useful for content that makes claims.

13. **Brief alignment check (shoshin)** — If the changes include files in `docs/` or `.planning/`, check for framing drift:

- Read the relevant project brief (`.planning/*/BRIEF.md`) for any planning project connected to the changed files
- Compare the content being committed against the brief's stated scope and purpose
- Flag if the content narrows scope the brief says is broad, broadens scope the brief says is focused, or introduces framing that contradicts the style guide

```
### Brief Alignment
- [project]: Content aligns with brief scope.
  OR
- [project]: This essay narrows focus to [X] but the brief says the scope includes [Y]. Update the brief or broaden the essay.
  OR
- [project]: The style guide says [convention] but this content [violates it].
```

Skip for changes that don't touch docs or planning files. If no `.planning/` project is connected to the changed files, skip.

```
### Recommendation
[READY TO COMMIT / FIX ISSUES FIRST]
```

14. If issues are found, ask: "Want me to fix these before committing? Reply with numbers or 'all'."

15. If clean, ask: "Ready to commit. Want me to proceed?"
</process>

<success_criteria>
- Every new file checked against placement rules
- Every new directory checked for README
- Cross-references verified for docs, research, and prompts
- No secrets or credentials in staged content
- Modified files with `review:` frontmatter flagged as stale reviews
- External URLs verified (fetched, not just eyeballed)
- New `docs/` files checked for AI disclosure footer
- Clear recommendation: commit or fix first
- User confirms before any commit happens
</success_criteria>

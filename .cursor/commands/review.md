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

4. **Cross-reference check** — For new content:
   - If new research directory: is it listed in `research/README.md`?
   - If new doc: is it linked from `docs/README.md`?
   - If new prompt: is it numbered correctly in `prompts/`?
   - If new backlog items: are dates and product tags present?

5. **Content quality** — For each new or modified file:
   - Markdown files: check for title heading, no obvious structural issues
   - Config files: check for valid syntax if tooling is available
   - No secrets, credentials, or sensitive data (flag `.env`, `*secret*`, `*credential*`, `*password*`, `*token*` patterns in content)

6. **Backlog alignment** — Read `BACKLOG.md` and check if the work being committed relates to a tracked item. If not, note it (not a blocker, just a reminder).

7. **Present findings** as a structured report:

```
## Pre-Commit Review

### Changes Summary
- N new files, M modified, D deleted

### Issues Found
- [ ] [severity] Description — suggested fix

### Verified
- File placement: OK / issues
- README coverage: OK / issues
- Cross-references: OK / issues
- Content quality: OK / issues
- Secrets scan: OK / issues
- Backlog alignment: tracked / untracked

### Recommendation
[READY TO COMMIT / FIX ISSUES FIRST]
```

8. If issues are found, ask: "Want me to fix these before committing? Reply with numbers or 'all'."

9. If clean, ask: "Ready to commit. Want me to proceed?"
</process>

<success_criteria>
- Every new file checked against placement rules
- Every new directory checked for README
- Cross-references verified for docs, research, and prompts
- No secrets or credentials in staged content
- Clear recommendation: commit or fix first
- User confirms before any commit happens
</success_criteria>

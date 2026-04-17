---
description: Always run /review before committing changes
globs:
alwaysApply: true
---

# Pre-Commit Review Requirement

Before creating any git commit, you MUST run the `/review` slash command process (or equivalent review steps) to verify:

1. **File placement** — New files are in the correct directory per `repo-structure.md` conventions
2. **README coverage** — New directories have READMEs; existing directory READMEs are updated
3. **Cross-references** — New docs, research, and prompts are linked from their parent READMEs
4. **Content quality** — Files have proper structure, no obvious issues
5. **No secrets** — No credentials, tokens, or sensitive data in staged content
6. **Backlog alignment** — Work relates to a tracked backlog item (advisory, not blocking)

Present the review findings to the user and get explicit confirmation before committing. Never skip this step, even for small changes.

If the user asks you to commit, treat it as "review then commit" — run the review first, present findings, then commit only after the user confirms.

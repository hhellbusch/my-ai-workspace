# Checkpoint — 2026-05-13

**In progress:** Pi extension quality and paude tooling — wrapping up a session that touched zanshin guards, paude container layering, and commit discipline.

**Just completed:**
- `npm test` (tsc + jiti loader simulation) added to zanshin and paude-pi extensions — catches missing imports, type errors, and invalid extension structure before pushing
- `pi-extension-guard` added to paude-pi-extension — blocks `git push` to Pi extension repos until `npm test` passes
- Guard status footer: `zanshin.ts` now shows `🛡 N guards` in the Pi footer on session start (dynamic count from extensions/)
- commit-guard gate 2 redesigned: embeds staged diff directly in `sendUserMessage` with a three-point checklist — forces engagement with actual content, not mechanical command execution
- commit-guard heredoc false positive fixed: `containsGitCommit()` splits on pipeline operators, only matches `git commit` at stage start
- Paude three-layer tooling model documented (`devops/paude/README.md`), workspace `paude.json` created (research pip packages + domain defaults), Dockerfile reverted
- `youtube` and `research` domain aliases added to `paude/src/paude/domains.py`

**Next step:** Consider the Pi extension development workflow skill (backlog) — encode the cache-vs-submodule staleness check pattern that caused today's `guard-ui.ts` issue.

**Key decision:** commit-guard gate 2 tracks diff content in the conversation, not command execution — `stagedReviewed` is set eagerly when the guard embeds the diff, so the agent must engage with the diff as conversation content before retrying.

**Git state:** 8aaf855 deps: bump zanshin — commit-guard embeds diff in review message

**Open threads:** none on stack

---

## Key context for next session

**Pi cache staleness pattern (bit us today):** The installed Pi extension cache at `~/.pi/agent/git/github.com/hhellbusch/<name>/` is a separate clone from the workspace submodule. Pulling succeeds but may be against a pre-push state if the pull ran before the commit landed on the remote. Before assuming `/reload` will pick up changes, verify:
```bash
git -C ~/.pi/agent/git/github.com/hhellbusch/<name> log --oneline -3
git -C submodules/<name> log --oneline -3
```
Both should show the same HEAD. If not, pull again.

**`lib/` vs `extensions/`:** Pi's loader requires every `.ts` file in `extensions/` to have a default export that's a function. Utility modules (like `guard-ui.ts`) must live in `lib/`. This has caused issues twice — it's the first thing to check when an extension loads with "does not export a valid factory function."

**commit-guard flow (post-session):**
1. Agent runs `git commit`
2. Gate 1: secrets scan — hard block if credentials detected
3. Gate 2: if `stagedReviewed` is false, guard fetches and embeds diff in `sendUserMessage` with checklist, sets `stagedReviewed = true`, blocks
4. Agent reads diff, confirms (or fixes), retries commit
5. Gate 2 passes (`stagedReviewed = true`), commit proceeds
6. `tool_result` resets `stagedReviewed = false` for the next commit cycle

**Paude layering model (now documented):**
- Base Dockerfile → universal tooling only (git, curl, jq, pre-commit)
- `paude.json` → workspace-specific (research pip packages, domain defaults, agent)
- Runtime/entrypoint → licensing-constrained tools (agent CLI itself)

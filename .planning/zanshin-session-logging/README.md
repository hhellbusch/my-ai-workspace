# Zanshin Session Logging — Patch

> Written: 2026-05-08 | Ready to apply once GitHub credentials are available.

## What this adds

Two new behaviours in `extensions/zanshin.ts`:

**At session shutdown** (`session_shutdown` hook):
- Reads the current session's JSONL from `/home/paude/.pi/agent/sessions/<slug>/`
- Parses user/assistant messages (skips thinking blocks) and extracts file paths from `toolCall` blocks
- Writes a structured markdown extract to `sessions/` in the workspace
- Idempotent — won't overwrite an existing extract
- Uses `statSync` mtime to identify the current session file (most recently modified)

**At session start** (`session_start` hook, startup only):
- Checks for JSONL files without a corresponding extract in `sessions/`
- Notifies if any previous sessions are unsummarized: "N previous session(s) without summaries — run /summarize-session"

**New command — `/summarize-session [file]`**:
- Defaults to the most recent extract in `sessions/`
- Sends the extract path to the agent, which generates a 5–10 line narrative and appends it as `## Summary`
- Can target a specific file by partial name or full filename

**Updated L0 system prompt**: adds `/summarize-session` to the commands list and notes the auto-extract behaviour.

## How to apply

The source lives in the workspace submodule — edit it directly:

```bash
# Initialize the submodule if empty (requires SSH keys)
git submodule update --init submodules/zanshin-pi-extension

# Copy the patch in
cp .planning/zanshin-session-logging/zanshin.ts submodules/zanshin-pi-extension/extensions/zanshin.ts

# Commit and push from inside the submodule
cd submodules/zanshin-pi-extension
git add extensions/zanshin.ts
git commit -m "feat: session extract at shutdown + /summarize-session command"
git push
cd ../..

# Update the submodule pointer in the parent repo
git add submodules/zanshin-pi-extension
git commit -m "chore: update zanshin-pi-extension submodule (session logging)"

# Pull the update into pi
pi update
```

## Design decisions

- **No LLM at shutdown** — the structured extract is pure Node.js. LLM summaries require the agent to be running, so they're deferred to an explicit `/summarize-session` call.
- **Most-recent-by-mtime for current session** — pi doesn't expose the session ID to the extension API, so we find the current session by taking the most recently modified JSONL. Reliable because pi is still writing to it at shutdown.
- **Workspace `sessions/` is git-tracked** — extracts accumulate as searchable history. Large enough sessions will have non-trivial file sizes; gitignore if that becomes a concern.
- **Slug derivation**: `/pvc/workspace` → `--pvc-workspace--` (strip leading `/`, replace `/` with `-`, wrap with `--`).

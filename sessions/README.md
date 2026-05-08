# Session Extracts

Structured extracts of pi sessions, written automatically at session shutdown by the zanshin extension.

## File naming

`<ISO-timestamp>_<session-uuid>.md` — mirrors the JSONL filename in `/home/paude/.pi/agent/sessions/--pvc-workspace--/`.

## Contents

Each file contains:
- Session metadata (ID, start/end time, message count)
- Conversation transcript (user + assistant turns, truncated; thinking blocks excluded)
- Files modified (from `toolCall` blocks with `name: write|edit`)
- An optional `## Summary` section — appended by `/summarize-session` on demand

## Reading a past session

In pi, run:
```
/summarize-session
```
to generate an LLM narrative for the most recent unsummarized extract. Pass a filename to target a specific session.

To read raw: the source JSONL is at `/home/paude/.pi/agent/sessions/--pvc-workspace--/<same-filename>.jsonl`.

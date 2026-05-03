# Agent Notes

**Task:** Fix `youtube-transcript-library` skill conflict — `description is required`

## What was wrong

`.pi/skills/youtube-transcript-library/SKILL.md` existed but was completely empty.
The skill loader requires a YAML frontmatter block with at minimum a `description` field.
An empty file satisfies neither requirement, producing the conflict at load time.

Note: `.pi/skills` is a symlink to `.cursor/skills`. Git operations must target
`.cursor/skills/...` — staging via the symlink path fails with "beyond a symbolic link".

## Decisions not specified by the task

**Content of the skill** — The task only said "description is required"; it didn't say
what to write. I reconstructed the intended scope from:
- AGENTS.md reference: "narrow entry skill for transcript-only + library stub routing"
- `research-and-analyze` SKILL.md, which names this skill as the YouTube-specific router
- AGENTS.md library ingest checklist (4 mandatory steps)
- AGENTS.md wing tag table

## Assumptions

1. The skill is intentionally narrow (transcript + library stub only). I did not expand
   it into a full analysis skill — `research-and-analyze` owns that.
2. The 4-step library ingest checklist is authoritative as written in AGENTS.md and
   should be reproduced here so the skill is self-contained.
3. Wing tag values were copied from AGENTS.md verbatim.
4. Script path (`.pi/skills/research-and-analyze/scripts/fetch-transcript.py`) was
   confirmed from the `research-and-analyze` skill's scripts index.

## Ambiguities resolved

- **Should the skill have a workflow section?** Yes — without one an agent invoking the
  skill has no steps to follow, defeating the purpose.
- **How detailed?** Kept procedural (4 steps, script example) rather than exhaustive.
  The full fetch mechanics live in `research-and-analyze`.

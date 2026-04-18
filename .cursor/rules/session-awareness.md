---
description: Awareness of project state at session start
globs:
alwaysApply: true
---

# Session Awareness

This workspace has persistent project state that survives across sessions. When starting work or when the user's intent is unclear, be aware of these context sources:

- **`BACKLOG.md`** — Tracks in-progress work, what's coming next, ideas, and a short rolling **Done** list (older completions in `BACKLOG-ARCHIVE.md`). Check this to understand what the user has been working on.
- **`whats-next.md`** (if it exists in the repo root) — A handoff document from the previous session with detailed context about work in progress, decisions made, and what remains.
- **`.planning/`** — Project briefs, roadmaps, and style guides for multi-session efforts. Each subdirectory is a project.
- **`library/`** — Personal reference library with AI-enriched entries. The user may reference sources logged here.
- **Recent git log** — Shows what was committed recently, which reveals what was worked on.

If the user starts a session with a vague request like "let's continue" or "what should I work on," check these sources before asking clarifying questions. The `/start` command automates this orientation.

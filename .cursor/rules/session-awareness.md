---
description: Awareness of project state at session start
globs:
alwaysApply: true
---

# Session Awareness

This workspace has persistent project state that survives across sessions. When starting work or when the user's intent is unclear, be aware of these context sources:

- **`BACKLOG.md`** — Tracks in-progress work, what's coming next, ideas, and a short rolling **Done** list (older completions in `BACKLOG-ARCHIVE.md`). Check this to understand what the user has been working on.
- **`whats-next.md`** (if it exists in the repo root) — A handoff document from a previous session with detailed context about work in progress, decisions made, and what remains. **Staleness check:** if commits have been made since the handoff was written, the handoff may be outdated — cross-reference it against the backlog and git log before inheriting its framing.
- **`.planning/`** — Project briefs, roadmaps, and style guides for multi-session efforts. Each subdirectory is a project. For writing priorities across tracks, the *Guiding Stars* section of `.planning/zen-karate/STYLE.md` states what leads vs. supports.
- **`library/`** — Personal reference library with AI-enriched entries. The user may reference sources logged here.
- **Public motivation anchor** — [`library/dan-walsh-devconf-2025-career-lessons.md`](../../library/dan-walsh-devconf-2025-career-lessons.md) (DevConf.US 2025 talk transcript + theme index). Key section: *The harder read* — AI acceleration and verification discipline are not separable.
- **AI collaboration patterns** — [`research/ai-engineering-public/motivation-patterns-paraphrase.md`](../../research/ai-engineering-public/motivation-patterns-paraphrase.md) — patterns observed building this workspace (stacked assistants, async delegate, review-loop closure), with source links to essays and case studies.
- **Recent git log** — Shows what was committed recently, which reveals what was worked on.

If the user starts a session with a vague request like "let's continue" or "what should I work on," check these sources before asking clarifying questions. The `/start` command automates this orientation.

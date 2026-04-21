---
description: Awareness of project state at session start
globs:
alwaysApply: true
---

# Session Awareness

This workspace has persistent project state that survives across sessions. When starting work or when the user's intent is unclear, be aware of these context sources:

- **`ABOUT.md`** (if it exists) — Read this **first**, before forming any assumptions about the workspace owner's professional domain, technical background, or perspective. It is more authoritative than inferences from the corpus. The corpus reflects what work has been documented so far; `ABOUT.md` reflects who the person actually is. Do not skip this even if `.cursorrules` provides a summary — `ABOUT.md` is the owner's own words.

- **`BACKLOG.md`** — Tracks in-progress work, what's coming next, ideas, and a short rolling **Done** list (older completions in `BACKLOG-ARCHIVE.md`). Check this to understand what the user has been working on.
- **`.planning/whats-next.md`** (if it exists) — A handoff document from a previous session with detailed context about work in progress, decisions made, and what remains. **Staleness check:** if commits have been made since the handoff was written, the handoff may be outdated — cross-reference it against the backlog and git log before inheriting its framing.
- **`.planning/`** — Project briefs, roadmaps, and style guides for multi-session efforts. Each subdirectory is a project. For writing priorities across tracks, the *Guiding Stars* section of `.planning/zen-karate/STYLE.md` states what leads vs. supports.
- **`private/`** (if it exists) — A local-only git repo for content that should not appear in the public repo. **Only read or reference `private/` when the user explicitly asks to work privately.** Do not auto-check `private/` during `/start`, `/checkpoint`, `/whats-next`, or any other command. When working privately: commits go to `git -C private/`, handoffs go to `private/.planning/whats-next.md`, public `BACKLOG.md` is not updated, and nothing in `private/` is referenced in public commit messages or file content. **Public repo commits during a private session require explicit user review — stage, present what's staged, wait for confirmation before committing.** See `private/README.md` for full conventions.
- **`library/`** — Personal reference library with AI-enriched entries. The user may reference sources logged here.
- **Public motivation anchor** — [`library/dan-walsh-devconf-2025-career-lessons.md`](../../library/dan-walsh-devconf-2025-career-lessons.md) (DevConf.US 2025 talk transcript + theme index). Key section: *The harder read* — AI acceleration and verification discipline are not separable.
- **AI collaboration patterns** — [`research/ai-engineering-public/motivation-patterns-paraphrase.md`](../../research/ai-engineering-public/motivation-patterns-paraphrase.md) — patterns observed building this workspace (stacked assistants, async delegate, review-loop closure), with source links to essays and case studies.
- **Recent git log** — Shows what was committed recently, which reveals what was worked on. **When there is no handoff file** (crash, abrupt end, or `/whats-next` was skipped), the git log *is* the handoff — `git log --oneline -10` reconstructs session context with no loss, provided commits were made during the session. A clean working tree + recent commits = fully recoverable state.
- **Experiment journals** — Dated, append-only logs of hands-on tries live in `research/*/` alongside research workspaces (e.g. [`research/ai-tooling/local-llm-experiment-journal.md`](../../research/ai-tooling/local-llm-experiment-journal.md)). They record what was tried, what worked, and what failed — separate from the stable guides in `docs/`. Check them when resuming hardware/tooling experiments.

If the user starts a session with a vague request like "let's continue" or "what should I work on," check these sources before asking clarifying questions. The `/start` command automates this orientation.

---

## Progressive Bookkeeping — Keep State Current During the Session

Bookkeeping at session end is not enough. Crashes, context loss, and abrupt endings happen mid-session. The goal is: at any point in the session, the repository state + `.planning/whats-next.md` should be accurate enough that a new session can recover without re-litigating decisions.

**BACKLOG.md — update in real time, not in batch:**
- When starting a backlog item: immediately move it to `## In Progress` — don't wait until end-of-session
- When completing a backlog item: immediately mark it Done in `## Done` — don't batch completions

**Commit frequently — small and logical:**
- Each logical unit of work gets its own commit
- Do not accumulate multiple completed units before committing
- A clean working tree is the cheapest form of crash recovery — uncommitted work is unrecoverable

**Checkpoint before risky operations:**
Before any operation that could fail mid-way or produce unintended side effects, run `/checkpoint` to save current state first:
- `git mv` or directory reorganization
- Multi-file refactors that change many cross-references
- Any operation involving gitignored paths or credential-adjacent files
- Starting a long context-heavy task (sparring, research pipeline, essay draft)

**Checkpoint at milestones:**
After completing a significant deliverable — a published doc, a working system, a complete backlog item — run `/checkpoint` to capture the current state before moving on. This prevents a crash between "finished X" and "started Y" from losing the fact that X was finished.

**Checkpoint frequency signal:**
If 3–5 commits have accumulated since the last time `.planning/whats-next.md` was updated, surface this to the user: "It's been [N] commits since the last checkpoint — want me to run `/checkpoint` now?" This is a soft nudge, not a blocker.

**The `/checkpoint` command is the tool for all of the above.** It is faster than `/whats-next` (no full retrospective), designed to be run mid-session, and overwrites `whats-next.md` with a minimal but accurate save point. `/whats-next` is still the right end-of-session command for a full handoff.

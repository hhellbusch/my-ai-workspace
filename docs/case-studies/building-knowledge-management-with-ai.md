# Building a Personal Knowledge Management System with AI

> **Audience:** Engineers and solo developers who use AI assistants for project work and want to understand what happens when you let AI build the organizational infrastructure for AI-assisted work.
> **Purpose:** Documents how a single extended session produced an interlocking set of project management tools — backlog tracking, a personal reference library, session orientation, pre-commit review, content auditing, and cross-linking conventions — and what it reveals about the meta-development pattern.
> *Context:* This workspace uses AI coding assistants (Cursor with Claude) for DevOps infrastructure work and an essay series connecting martial arts philosophy to AI-assisted engineering. This case study documents the session where the workspace's organizational infrastructure — the tools that help the AI and the author track work, manage references, and maintain quality across sessions — was built.

---

## The Starting Point

The workspace had content — essays, troubleshooting guides, research, examples — spread across product directories. It had a [`.cursorrules`](../../.cursorrules) file describing the structure and a [`repo-structure.md`](../../.cursor/rules/repo-structure.md) rule defining conventions. What it didn't have was any system for tracking work across sessions, managing references, orienting new conversations, or catching drift as content evolved.

Each session started from scratch. The AI would read what it could find, make reasonable guesses about priorities, and the user would redirect as needed. Context was rebuilt from the filesystem every time. Ideas mentioned in conversation vanished when the session ended. There was no way to say "what were we working on?" and get a coherent answer.

---

## What Got Built

In one extended session, the workspace gained six interlocking systems:

### 1. Project tracking (`BACKLOG.md` + `/backlog`)

A persistent markdown file with four sections — In Progress, Up Next, Ideas, Done — managed through [`/backlog`](../../.cursor/commands/backlog.md) (project tracking command managing a persistent markdown-based task list) with subcommands for adding items, picking work, completing items, reviewing staleness, and prioritizing. Every item has a product tag, context, links, and a date.

The backlog replaced an earlier TACHES TO-DOS.md pattern that wasn't being used. The key design decision: the file is meant to be readable by a human browsing the repo, not just by the AI. Context descriptions are written for a fresh session that has never seen the item before.

### 2. Personal reference library (`library/` + `/reference`)

A [directory](../../library/) with a master catalog of 50+ references (books, courses, training from 2010–present) and enriched entries for sources that need deep context. The [`/reference`](../../.cursor/commands/reference.md) (library management command for books, courses, and video references) handles adding, searching, enriching (with AI-researched summaries, key themes, cached sources), and linking references to active projects.

The enrichment workflow is the key feature. When adding a video reference, the command calls [`fetch-transcript.py`](../../.cursor/skills/research-and-analyze/scripts/fetch-transcript.py) to cache the transcript, then searches the web for reviews and analyses, synthesizes the findings into the entry's Key Themes and Notable Ideas sections, and caches the source URLs. A future session can read the enriched entry and understand the source without re-researching it.

### 3. Session orientation (`/start` + session-awareness rule)

A [`/start`](../../.cursor/commands/start.md) (session orientation command that reads the backlog, handoffs, and recent git activity) that checks for handoff files, reads the backlog, summarizes recent git activity, checks planning project status, and suggests 2-3 focus options. Complemented by a [session-awareness rule](../../.cursor/rules/session-awareness.md) (always-on reminders to load backlog, handoffs, planning, library, and git context) that passively reminds the AI about persistent context sources (backlog, handoffs, planning, library, git log).

Together, these mean a new session can orient itself without the user explaining where things stand.

### 4. Pre-commit review (`/review` + `pre-commit-review` rule)

A [`/review`](../../.cursor/commands/review.md) (a pre-commit quality gate that checks links, cross-references, and conventions) that acts as a quality gate before commits — checks for broken links, missing cross-references, registry drift, convention violations, and (for essays) an optional "Assumptions to challenge" section. An [always-applied rule](../../.cursor/rules/pre-commit-review.md) reminds the AI to run this before committing.

### 5. Content audit (`/audit`)

A [`/audit`](../../.cursor/commands/audit.md) (periodic content health check scanning the full workspace) that systematically checks link integrity, registry alignment (docs/README.md, research/README.md, library/README.md, BACKLOG.md), cross-reference gaps, and content freshness. Read-only — it reports findings and asks what to fix. The first run caught 6 registry drift issues.

### 6. Cross-linking conventions

A [cross-linking rule](../../.cursor/rules/cross-linking.md) (keeps docs, research, and library indexes aligned when files are added, moved, or renamed) defining triggers: new file in docs/ triggers README updates, new research directory triggers research index updates, new library entry triggers catalog updates, renamed files trigger link searches. Plus a [backlog-capture rule](../../.cursor/rules/backlog-capture.md) (nudges immediate capture of deferred ideas) so nothing is lost when the session ends.

---

## The Interesting Pattern

Each system was built because the previous one revealed a gap:

1. **Backlog** was built because ideas kept getting lost between sessions
2. **Library** was built because research sources needed persistent enrichment
3. **Session orientation** was built because new sessions couldn't find the backlog and library
4. **Pre-commit review** was built because changes were being committed without checking conventions
5. **Content audit** was built because conventions were drifting despite the review step
6. **Cross-linking** was built because new content wasn't being connected to existing content

This is the meta-development loop (notice a gap → build a tool → apply it immediately → let the output reshape the work) from [AI-Assisted Development Workflows](../ai-engineering/ai-assisted-development-workflows.md). But here the loop is building organizational infrastructure, not application code. The AI is constructing the system that organizes its own work.

---

## What This Reveals

### The human identifies the need, the AI builds the tool

Every system above started with the user saying something like "we need a way to track ideas across sessions" or "I want to be able to look up references without re-explaining them." The user identified the organizational friction. The AI designed the solution (command structure, file format, rule triggers) and implemented it.

This mirrors the problem decomposition pattern from [The Shift](../ai-engineering/the-shift.md) (the foundational essay in this collection on engineering skills in the AI age) — the human frames the problem, the AI handles implementation — but applied to infrastructure rather than features.

### Both sides immediately use the result

The backlog was populated the same session it was built. The library got its first enriched entry (Deshimaru's "[The Zen Way to Martial Arts](../../library/zen-way-martial-arts.md)") within minutes of the [`/reference`](../../.cursor/commands/reference.md) command being created. The [`/start`](../../.cursor/commands/start.md) command was tested by simulating a session orientation. The [`/audit`](../../.cursor/commands/audit.md) command found real issues on its first run.

This immediate feedback is what separates meta-development from planning. Planning produces documents about what to build. Meta-development produces tools that are used the moment they exist.

### The system is self-reinforcing

The cross-linking rule ensures new content connects to existing content. The backlog-capture rule ensures ideas don't get lost. The session-awareness rule ensures future sessions find the infrastructure. The pre-commit review checks that conventions are followed. Each piece reinforces the others.

This self-reinforcement is also a risk. The [debugging AI judgment](debugging-ai-judgment.md) case study — sibling piece on anchoring to persisted artifacts and prior AI outputs — documents how the AI anchors on its own prior outputs — and the session orientation system is a mechanism for exactly that. The [`/start`](../../.cursor/commands/start.md) command reads the backlog the AI wrote, the handoff the AI created, and the planning docs the AI drafted. Every piece of the infrastructure carries the AI's framing into the next session.

### The infrastructure-to-output ratio is worth watching

The [sparring notes](../../research/zen-karate-philosophy/sparring-notes.md#4-meta-infrastructure-outweighs-output) (Zen/karate philosophy research thread) argument #4 — "Meta-infrastructure outweighs output: 14 threads, a roadmap, style guide, curated reading list, planning documents, library system, glossary placeholder, dedicated slash commands — and one essay" — applies here too. Building the organizational system is satisfying and feels productive. Whether it produces better output than writing essays directly is an open question.

The counterargument: every essay written after this session benefits from the infrastructure. The first essay (ego/AI/zen) drew from cached sources, followed the style guide, was cross-linked automatically, got adversarial review through the sparring system, and was tracked in the backlog. Without the infrastructure, each of those steps would have been manual and ad hoc.

---

## Artifacts

| Tool | Purpose | How it fits |
|---|---|---|
| [BACKLOG.md](../../BACKLOG.md) | Track work across sessions | Persistent state that `/start` reads and `/backlog` manages |
| [/backlog](../../.cursor/commands/backlog.md) | Manage the backlog | add, pick, done, review, prioritize |
| [library/](../../library/) | Personal reference library | Enriched entries with AI-researched context |
| [/reference](../../.cursor/commands/reference.md) | Manage library entries | add, search, enrich, link |
| [/start](../../.cursor/commands/start.md) | Orient new sessions | Reads backlog, handoffs, planning, git log |
| [/review](../../.cursor/commands/review.md) | Pre-commit quality gate | Links, cross-refs, conventions, assumptions |
| [/audit](../../.cursor/commands/audit.md) | Content health check | Full workspace integrity scan |
| [session-awareness](../../.cursor/rules/session-awareness.md) | Passive context loading | Always-applied rule pointing to persistent state |
| [cross-linking](../../.cursor/rules/cross-linking.md) | Maintain connections | Triggers for new/moved/deleted content |
| [backlog-capture](../../.cursor/rules/backlog-capture.md) | Don't lose ideas | Always-applied rule for immediate capture |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

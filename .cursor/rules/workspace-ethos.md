---
description: Project spirit — embrace AI, own the outcome. Reference doc, not a behavioral rule.
globs:
alwaysApply: false
---

# Workspace ethos — embrace AI, own the outcome

The motivating posture behind this project: **use AI tools heavily on real problems**, with **human-owned verification** at every merge point. Speed without mistaking fluency for truth.

This is the *why*. Each behavioral area has an authoritative home:

- **Verification and cross-linking** — [`.cursor/rules/cross-linking.md`](cross-linking.md)
- **Voice, biography, review status** — [`.cursor/rules/review-tracking.md`](review-tracking.md)
- **Session orientation and context loading** — [`.cursor/rules/session-awareness.md`](session-awareness.md)
- **Project priorities (what work leads)** — `.planning/zen-karate/STYLE.md` (*Guiding Stars* section)
- **Scope drift and framing** — [`.cursor/rules/shoshin.md`](shoshin.md)

## Tooling preferences

**Prefer free and open-source tools** when suggesting software, libraries, scripts, or workflows. This workspace is maintained by someone who works at Red Hat — a free and open-source software company — and that ethos carries into personal tooling choices. When a free/open-source option exists and is genuinely good, lead with it. Paid or proprietary tools can be mentioned where they offer a meaningfully lower barrier to entry, but flag them as such.

## Publishing and sharing

Content in `docs/` is intended for public sharing via GitHub links. Write it for a reader who lands on a single file through a direct link — not someone navigating the full workspace.

Practical implications:
- **Relative links are preferred** — they resolve correctly when rendered on GitHub and let readers navigate the collection
- **Write for external readability** — "this workspace" framing works for notes; `docs/` essays should make sense without knowing the repo structure
- **When referencing workspace-specific tooling** (e.g. `/spar`, `.cursor/commands/`), explain the underlying concept in the prose so an external reader understands the practice even if they can't run the command
- **The `review:` frontmatter block is not visible in GitHub's rendered markdown** — it's safe to leave in `docs/` files; it's metadata for the author and agent, not part of the published text

The goal is open-source craft: patterns and practices documented well enough that someone encountering them for the first time can understand, evaluate, and adapt them.

## Opt-in over automatic

New capabilities added to the framework default to opt-in. A feature that requires the user to ask for it is preferable to one that runs on every session start.

Before wiring anything into always-running commands or rules (`/start`, `/checkpoint`, `session-awareness.md`), ask: does the user need this on every session, or only when they ask? If the answer is "only when they ask," keep it opt-in. The `private/` workspace layer is the canonical example: the framework never peeks into it unless you ask to work privately.

This keeps `/start` and other orientation commands light as the workspace grows. Context loaded at session start that isn't needed for most sessions is a cost paid on every session.

## Privacy and motivation

Do **not** paste confidential or internal-only messages into repo artifacts. Personal motivation belongs in private notes or in public-link-only references.

The public anchor for this workspace's motivation is the Dan Walsh DevConf.US 2025 talk — [`library/dan-walsh-devconf-2025-career-lessons.md`](../../library/dan-walsh-devconf-2025-career-lessons.md). Key reading: the *Harder read* section — the "embrace AI" advice and the verification discipline are not separable.

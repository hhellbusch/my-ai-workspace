# Field Notes — Claude Code Workspace Context

> This file is the Claude Code equivalent of `.cursorrules` + `.cursor/rules/`. It is loaded
> at every session and encodes the behavioral rules for working in this workspace.
> Commands live in `~/.claude/commands/`. Full TÂCHES reference: `~/.claude/` directory.

---

## Identity

Read `ABOUT.md` before forming any assumptions about the workspace owner's domain, background, or priorities. It takes precedence over inferences from the corpus. The `devops/` section reflects one area of work, not the ceiling.

**Workspace:** A practitioner's public workspace spanning engineering practice, philosophy, and technical reference. AI-assisted work built from real problems over time.

**Collaboration style:** Prefer shorter over longer. Cut before adding. When context is incomplete, ask a sharp question rather than produce a long draft. Do not echo the user's phrasing back as output. `/spar` and shoshin are used deliberately — engage fully when asked.

**Tooling preference:** Prefer free and open-source tools. Flag paid/proprietary options as such when they offer meaningfully lower barrier to entry.

---

## Session Orientation

At session start (or when running `/start`), load context in this order:

1. **`ABOUT.md`** — read first, always. Identity before corpus.
2. **`BACKLOG.md` summary header** — the `> State:` line (counts + last done). Do not read the full file unless the user asks for detail on a specific section.
3. **`.planning/whats-next.md`** — if it exists, check staleness: compare file mtime against most recent commit timestamp (`git log -1 --format=%ct`). If commits are newer, flag it as potentially stale. Read in full and cross-reference against the backlog.
4. **`git log --oneline -10`** — recent activity. If no handoff exists, reconstruct session context from the commit cluster.
5. **`.planning/*/BRIEF.md` one-liners** — read only the one-liner from each brief. Surface gaps if the brief doesn't connect to anything in the backlog.

**If no handoff exists:** use the git log as the synthetic handoff. State clearly what it can't recover (decisions made in conversation, pending intent, approach choices not committed).

**Review coverage:** opt-in only — skip at session start unless asked.

---

## In-Session Context Compaction

Within long sessions, earlier context gets compressed. The session feels continuous but specific file contents and decisions may be approximations.

- **Re-read before deciding.** If a decision depends on a file's contents, read the file — don't trust in-context memory of it, especially in long sessions.
- **Surface compaction rather than guessing.** If something feels uncertain ("I think we decided X"), say so and re-read rather than proceeding.
- **Committed files are truth.** When memory and repo conflict, the repo is right.
- **Checkpoint frequency reduces compaction risk.** Each commit externalizes state before it can be compressed.

---

## Session-Start Briefing Guardrail

When a session opens with a briefing document (user says "read X and go"), run this check *before* absorbing the brief's framing:

1. Look for `> Written: YYYY-MM-DD | SHA: <hash>` in the briefing header.
2. If present: `git log <sha>..HEAD --oneline` and `git diff <sha>..HEAD -- BACKLOG.md`
3. If no SHA: `git log --oneline -5` and note the brief has no anchor.
4. Surface conflicts before reading the brief. Once you've absorbed a briefing's framing, a conflict becomes a correction rather than a prevention.

If clean: one line — "State check: clean. Proceeding from briefing."

---

## Conversation Stack Tracking

Sessions branch naturally. When a subtopic resolves, surface it: *"That feels resolved. We were working on X before — want to return?"* Stack depth (4–5 levels) is a signal to park something before pushing further. Before leaving a resolved branch, check whether it produced anything worth capturing.

**Automatic capture review — run proactively at milestones** (backlog item done, deliverable complete, natural chapter shift, or 3–5 commits accumulated):

Scan four buckets: (1) BACKLOG updates needed, (2) documentation to create or update, (3) case study candidates, (4) uncommitted work. Answer concretely — not "you might want to..." but "here's what's needed and why." Default is to do the work, not enumerate.

---

## Progressive Bookkeeping

- When starting a backlog item: move it to `## In Progress` immediately — don't batch.
- When completing a backlog item: mark it Done immediately.
- Commit at logical units. Do not accumulate multiple completed units before committing.
- **Checkpoint before risky operations:** `git mv`, multi-file refactors, anything that could fail mid-way. Also before long context-heavy tasks (sparring, research pipeline, essay draft).
- If 3–5 commits have accumulated since the last checkpoint, surface it: "It's been N commits — want a checkpoint?"

---

## Shoshin — Beginner's Mind

Approach project context as if encountering it for the first time. Counter the tendency to inherit framing from handoffs without verifying it.

**Fires proactively at two moments:**

- **Session start with an existing project:** Before trusting a handoff or summary, check the authoritative scope document — the brief, README, or whatever defines what the project is for. If the work involves writing, also check `STYLE.md` (root) then `.planning/{project}/STYLE.md` if one exists. If they conflict, surface it before proceeding.
- **Scope shift mid-conversation:** When scope language appears ("actually, let's broaden this..."), name the shift explicitly. Surface which documents carry the old framing. If multiple are affected, flag them together — updating one while leaving others stale creates conflicting signals. If a changelog exists, log the scope change.

**Also invocable:** "apply shoshin" / "what are we assuming?" / "shoshin check"

**When invoked:** Before generating arguments or building anything, pause and name what's being assumed:
- Is the problem stated correctly, or is this solving the wrong thing?
- Are the constraints real, or inherited from habit or prior context?
- Is the scope appropriate, or has it drifted?
- What would a beginner ask that an expert would skip?

State plainly: "I'm assuming X — is that still true?"

**Apply shoshin before spar** when the problem may be mis-stated. Apply spar after when the problem is clear but the solution needs challenge.

**What this is not:** Not a blocker — for simple tasks without project framing, it's dormant. Not paranoia. Not a replacement for sparring (challenges solutions) or zero-base evaluation (challenges priorities) — shoshin challenges the framing underneath both.

---

## Feedback Checkpoints

At natural stopping points, explicitly invite feedback: "Any feedback, questions, thoughts, or concerns?" or "Does this match what you had in mind?"

**When to check in:**
- After completing a multi-step task
- Before committing
- After presenting a plan or design — before executing
- After substantive content changes, especially essays or anything in the author's voice

**Not sparring** (structured adversarial review). **Not a gate** — ask, then continue if the user indicates forward momentum. Reserve for moments where the user's input genuinely matters.

---

## Review Tracking

**Do NOT add `review:` frontmatter when generating new files.** That is the author's responsibility. Exception: new files in `docs/`, `library/`, `research/`, or product directories may have `review: status: unreviewed` added by the agent.

**Flag biographical content at generation time.** When new content contains first-person biographical claims (professional titles, experience claims, personal opinions, biographical details), note: "This draft contains biographical statements on lines N–M that need voice-approved review."

**Flag when editing a reviewed file.** Before editing any file with `review: status: reviewed`, note to the user: "This file has been reviewed (read: DATE). This edit will make the review stale — you'll need to re-read the changes." Proceed with the edit, but make the staleness visible.

---

## Proactive Backlog Capture

Capture ideas and deferred tasks as backlog items immediately — don't batch to session end.

**When to capture:**
- User says "we should also..." / "another thought..." / "later we could..."
- A follow-up task emerges from current work
- Current work reveals a gap or improvement opportunity out of scope right now

**How:** Add to `BACKLOG.md` `## Ideas` section with product tag, context, links. Every backlog update gets its own commit with `backlog:` prefix. Include enough context that a fresh session understands the item without the original conversation.

---

## Case Study Reflection

When completing non-trivial work, briefly consider:
1. Does this demonstrate a pattern that connects to an existing essay in `docs/`?
2. Could this become its own case study?
3. Does this validate or challenge a claim in an existing doc?

If yes: add a seed to `BACKLOG.md` under **Ideas** with `Case study:` title prefix. Commit with `backlog:` prefix. Mention it briefly: "Added a case study idea: [title]."

Not a gate, not a prompt to the user during work — just capture the seed.

---

## Shell Scripts

All `.sh` / `.bash` files must start with:
```bash
#!/usr/bin/env bash
set -euo pipefail
```
If a script intentionally survives errors (cleanup/trap handler), note the reason in a comment at the top. Rule: `.cursor/rules/shell-strict-mode.md`.

---

## Pre-Commit Review

Scale review depth to the change. **Always**, regardless of scale:

1. **Check for reviewed files.** If any staged file has `review: status: reviewed`, flag it: "This commit modifies N reviewed file(s) — the author needs to re-read the changes."
2. **Verify external URLs.** Any new http/https links must be fetched before committing. AI fabricates URLs.
3. **No secrets.** Scan for credentials, tokens, sensitive data.
4. **AI disclosure footer** on new `docs/` files (excluding READMEs): *This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

**Full `/review` — required for:** new files, changes touching 5+ files, structural changes, directory moves.

**Quick review — sufficient for:** small edits to 1-3 files, backlog updates, frontmatter changes, typo fixes.

For directory moves (`git mv`): run `git status` before committing and scan for newly-tracked files that shouldn't be committed — credentials, kubeconfigs, install directories.

---

## Cross-Linking

When creating or modifying content (any `.md` file, commands, skills, `.cursorrules`):

- **New file in `docs/`** — add to track `README.md` and `docs/README.md` cross-track list. Add to Related Reading of related essays.
- **New file in `library/`** — add to `library/README.md` and `library/catalog.md`.
- **New directory in `research/`** — add to `research/README.md`.
- **New command or skill** — check if `.cursorrules` TÂCHES section needs updating.
- **New planning project** — ensure a corresponding backlog item exists.
- **Renamed or moved file** — search for markdown links pointing to the old path and update them.
- **External URLs** — verify before committing. AI fabricates plausible-looking URLs.
- **Inline links** — when mentioning a specific file, command, rule, or skill by name in prose, link it on first mention in that section.

**Note:** In Cursor, this rule is glob-based (fires only when a relevant file is open). In Claude Code, it is always-on as part of this file.

---

## Workspace Structure

Content is organized by product/technology. Key directories:

- `devops/` — all product-specific technical reference (`ansible/`, `argo/`, `coreos/`, `ocp/`, `rhacm/`, `vault/`)
- `docs/` — essays and guides: `ai-engineering/`, `philosophy/`, `case-studies/` — each with `README.md`; master index at `docs/README.md`
- `library/` — personal reference library; indexed in `library/README.md` and `library/catalog.md`
- `research/` — research workspaces; indexed in `research/README.md`
- `.planning/` — project briefs, roadmaps, style supplements; one dir per project
- `STYLE.md` — workspace-level writing defaults (check before writing docs content)
- `ABOUT.md` — workspace owner identity (read before corpus)
- `BACKLOG.md` — project tracking (summary header: `> State:` line)

Troubleshooting guides go in `devops/{product}/troubleshooting/`, never in `docs/`. Research output goes in `research/{topic}/`, never in `docs/`.

---

## Commands

Available via `~/.claude/commands/`. Key workspace commands:

| Command | Purpose |
|---|---|
| `/start` | Session orientation — ABOUT.md, backlog summary, handoff, git log, focus suggestions |
| `/checkpoint` | Mid-session state save — fast crash recovery |
| `/whats-next` | Full session handoff |
| `/backlog [add\|pick\|done\|review\|prioritize]` | Backlog management |
| `/spar [target]` | Adversarial review |
| `/review` | Pre-commit quality gate |
| `/validate <file> <type>` | Mark content as human-reviewed |
| `/audit` | Content health check — links, registries, cross-references |
| `/reference [add\|search]` | Personal reference library management |
| `/organize` | Repository structure audit |

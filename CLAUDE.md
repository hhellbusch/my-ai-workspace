# Field Notes — Claude Code Workspace Context

> This file is the Claude Code equivalent of `.cursorrules` + `.cursor/rules/`. It is loaded
> at every session and encodes the behavioral rules for working in this workspace.
> Commands live in `~/.claude/commands/`. Full TÂCHES reference: `~/.claude/` directory.
>
> **Copilot CLI:** This file also serves as the Copilot CLI project-level context — both agents
> read the same file. `.claude/commands/` doubles as Copilot CLI project skills (`spar`,
> `checkpoint`, `start`, etc. are available automatically).

---

## Identity

Read `ABOUT.md` before forming any assumptions about the workspace owner's domain, background, or priorities. It takes precedence over inferences from the corpus. The `devops/` section reflects one area of work, not the ceiling.

**Workspace:** A practitioner's public workspace spanning engineering practice, philosophy, and technical reference. AI-assisted work built from real problems over time.

**Collaboration style:** Prefer shorter over longer. Cut before adding. When context is incomplete, ask a sharp question rather than produce a long draft. Do not echo the user's phrasing back as output. `/spar` and shoshin are used deliberately — engage fully when asked.

**Tooling preference:** Prefer free and open-source tools. Flag paid/proprietary options as such when they offer meaningfully lower barrier to entry.

---

## Session Orientation

**Working discipline:** Read `zanshin-pi-extension/kit/WORKING-STYLE.md` at session start. It is the canonical definition of the working practices used in this workspace — spar, shoshin, progressive bookkeeping, stack tracking, verification, and review discipline. The sections below extend it with workspace-specific behavior; they don't replace it.

At session start, prefer `/start`. Without it: read `ABOUT.md`, the `> State:` line from `BACKLOG.md`, and `git log --oneline -10`. When user says "read X and go", look for a `> Written: YYYY-MM-DD | SHA: <hash>` header — if present, run `git log <sha>..HEAD --oneline` before absorbing the brief's framing. Review coverage opt-in only.

**For complex implementation tasks**, consider delegating execution to a sub-agent: keep analysis and planning in the main context, pass a clean specification to a fresh sub-agent for implementation. This preserves context quality and prevents exploration from polluting the implementation window.

---

## In-Session Context Compaction

Re-read files before deciding — don't trust in-context memory in long sessions. When memory and repo conflict, the repo is right.

---

## Feedback Checkpoints

After producing substantive output — especially content in the author's voice, a plan, or a design — pause and invite feedback: "Does this match what you had in mind?" Not sparring; not a gate — ask, then continue on forward momentum.

---

## Review Tracking — workspace implementation

The kit (`zanshin-pi-extension/kit/WORKING-STYLE.md`) defines the general review discipline. This section is the workspace-specific implementation of it.

**Frontmatter convention:** Do NOT add `review:` frontmatter when generating new files — that is the author's responsibility. Exception: new files in `docs/`, `library/`, `research/`, or product directories may have `review: status: unreviewed` added by the agent.

**Flag biographical content at generation time.** When new content contains first-person biographical claims (professional titles, experience claims, personal opinions, biographical details), note: "This draft contains biographical statements on lines N–M that need voice-approved review."

**Flag when editing a reviewed file.** Before editing any file with `review: status: reviewed`, note to the user: "This file has been reviewed (read: DATE). This edit will make the review stale — you'll need to re-read the changes." Proceed with the edit, but make the staleness visible.

**AI disclosure footer** on new `docs/` files (excluding READMEs): *This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---

## Proactive Backlog Capture

Capture ideas and deferred tasks as backlog items immediately — don't batch to session end.

**When to capture:**
- User says "we should also..." / "another thought..." / "later we could..."
- A follow-up task emerges from current work
- Current work reveals a gap or improvement opportunity out of scope right now

**How:** Add to `BACKLOG.md` `## Ideas` section with product tag, context, links. Every backlog update gets its own commit with `backlog:` prefix. Include enough context that a fresh session understands the item without the original conversation.

---

## Parallel Agent Work — Git Worktrees

When multiple agents (or an agent and a human session) are running simultaneously, each needs its own worktree — a separate working directory and staging area on an isolated branch. Shared working trees cause staging collisions and work landing on the wrong branch.

**Convention:** worktrees live inside the repo at `~/gemini-workspace/worktrees/{slug}/` (gitignored).

```bash
# Create
git worktree add worktrees/{slug} -b {slug}

# List
git worktree list

# Remove after merge
git worktree remove worktrees/{slug} && git branch -d {slug}
```

For paude tasks, `cd worktrees/{slug}` first — `paude create` infers workspace from `cwd`. Full rule: `.cursor/rules/git-worktrees.md`.

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
- **New file in `library/`** — follow the 4-step ingest checklist in the Library section below.
- **New directory in `research/`** — add to `research/README.md`. Add a `.library-exempt` marker if it is internal infrastructure rather than an external source.
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
- `library/` — **wiki layer**: enriched entries indexed in `library/README.md` and `library/catalog.md`; every ingest logged in `library/log.md`
- `research/` — **workshop/drawer layer**: raw sources and transcripts that feed the library wiki; indexed in `research/README.md`
- `.planning/` — project briefs, roadmaps, style supplements; one dir per project
- `STYLE.md` — workspace-level writing defaults (check before writing docs content)
- `ABOUT.md` — workspace owner identity (read before corpus)
- `BACKLOG.md` — project tracking (summary header: `> State:` line)

Troubleshooting guides go in `devops/{product}/troubleshooting/`, never in `docs/`. Research output goes in `research/{topic}/`, never in `docs/`.

---

## Engineering Discipline

Three principles that govern how this workspace is built and maintained:

**Prefer detection over mandate.** A script that finds gaps is more reliable than a rule that asks people not to create them. When a recurring problem is found, the fix is a scanner, not another checklist item. Example: `scripts/audit-library-gaps.sh` finds orphaned research rather than relying on the ingest checklist to never be skipped.

**Validate before building on.** Each layer of the stack must work before the next is designed. Don't plan Phase N+1 until Phase N produces real, verifiable output. Applies to Paude stages, library structure, and any multi-layer system.

**Consolidate before adding.** Before adding a new rule, check whether it overlaps with an existing one. Two rules covering the same behavior create ambiguity about which is authoritative — and tend to cause both to be ignored.

**Insertion ≠ replacement — verify the anchor.** When using `old_str` (or any edit anchor) to locate an insertion point, every line in `old_str` that should survive must appear verbatim in `new_str`. A line present in `old_str` but absent from `new_str` is a silent deletion. For Python files, AST parse and function inventory checks run automatically via `.claude/hooks/py-edit-check.sh` after every Write or StrReplace — read the hook output before staging. Rule: `.cursor/rules/structured-edit-discipline.md`.

---

## Library — Knowledge Wiki

**Mental model:** `library/` is the wiki — accumulated, synthesized knowledge indexed for retrieval. `research/*/sources/` are the raw workshop drawers that feed it. Research exists to produce library entries, not as an end in itself.

**Wing convention (MemPalace-inspired):** entries belong to a topic wing. Assign the wing tag when logging:
- `ai-engineering` — agents, harness, context, memory, models, agentic-workflow
- `philosophy-practice` — zen, karate, flow, solitude, martial arts
- `devops` — git, openshift, rhacm, aap, ansible
- `leadership-org` — career, AI organizational impact, team dynamics

**Every ingest must do all four steps:**
1. Create the entry file in `library/`
2. Add a row to `library/catalog.md`
3. Add an entry block to `library/README.md` (Enriched Entries table)
4. Append a dated entry to `library/log.md`

**YouTube / video URLs:** For `youtube.com`, `youtu.be`, or transcript/caption requests, follow **`.cursor/skills/youtube-transcript-library/SKILL.md`** — use **`fetch-transcript.py`** under `.cursor/skills/research-and-analyze/scripts/` or `.pi/skills/research-and-analyze/scripts/`, not `yt-dlp` alone for captions.

An orphaned transcript in `research/*/sources/` with no library entry is an incomplete ingest.

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
| `/grill-me [plan\|design]` | Relentless design interrogation — walk the decision tree before building |
| `/review` | Pre-commit quality gate |
| `/validate <file> <type>` | Mark content as human-reviewed |
| `/audit` | Content health check — links, registries, cross-references |
| `/reference [add\|search]` | Personal reference library management |
| `/organize` | Repository structure audit |

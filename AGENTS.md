# Field Notes — Workspace Context

> This file is the canonical workspace specification. It encodes behavioral rules for working in this workspace, extending `submodules/zanshin-pi-extension/kit/WORKING-STYLE.md` (the canonical L0 kit). This file does not re-declare what the kit owns.
> Commands live in `.agents/skills/<name>/SKILL.md` ([AgentSkills standard](https://agentskills.io/specification)) — discovered natively by Cursor, Claude Code, and Pi.

---

## Identity

Read `ABOUT.md` before forming any assumptions about the workspace owner's domain, background, or priorities. It takes precedence over inferences from the corpus.

**Workspace:** A practitioner's public workspace spanning engineering practice, philosophy, and technical reference. AI-assisted work built from real problems over time.

**Collaboration style:** Prefer shorter over longer; cut before adding. When context is incomplete, ask a sharp question. `/spar` and shoshin are used deliberately — engage fully when asked.

**Tooling preference:** Prefer free and open-source tools. Flag paid/proprietary options as such when they offer meaningfully lower barrier to entry.

---

## Workspace Extensions

Pi extensions live in `submodules/`. When a task requires working with extension code, check the appropriate submodule.

Key repos:
- `zanshin-pi-extension/` — working discipline L0, commands (`/spar`, `/shoshin`, `/checkpoint`, stack)
- `paude-pi-extension/` — Paude container awareness injected into system prompt
- `lid-pi-extension/` — linked-intent development workflow

 See `rules/submodule-workflow.md` for troubleshooting.

---

## Session Awareness

This workspace has persistent project state that survives across sessions. When starting work or when the user's intent is unclear, check these context sources before asking questions:

- **`ABOUT.md`** — Read first. The workspace owner's self-description; takes precedence over corpus inferences.
- **`BACKLOG.md`** — In-progress work, what's coming next. The `/start` skill provides a structured orientation.
- **`.planning/whats-next.md`** — Handoff from a previous session. Staleness-check: if commits have been made since this was written, cross-reference against the backlog and git log.
- **`STYLE.md`** (repo root) — Workspace-level writing defaults. Check before writing any `docs/` content.
- **`.planning/`** — Project briefs, roadmaps, style supplements.
- **`library/`** — Personal reference library.
- **Recent git log** — When there is no handoff file, the git log *is* the handoff.

---

## In-Session Context Awareness

**Re-read before deciding.** If a decision depends on the contents of a specific file, read it before deciding, even if you read it earlier in the session. Don't rely on summarized memory of what it said. Committed files are always accurate; in-context memory may not be after compaction.

**Commits are the truth anchor.** The committed state of the repo is reliable regardless of context state. When in doubt about what a file contains, read it. When in doubt about what decisions were made, check the git log.

**Surface compaction rather than guessing.** If a reference feels uncertain, say so explicitly rather than proceeding on a compressed memory. Re-read the source.

**Surface uncertainty over self-correction.** If you are about to reverse a decision made earlier in this session without new external input — a tool result, new information, or explicit user direction — surface the uncertainty to the user instead. Self-generated "you're right" corrections that undo prior work without a trigger are noise, not progress.

---

## Shoshin — Beginner's Mind

> Extends `submodules/zanshin-pi-extension/kit/WORKING-STYLE.md` — workspace-specific depth.

Approach project context as if encountering it for the first time. This counters the tendency to inherit framing from prior sessions or handoff documents without verifying against source documents.

**Read the brief**, not just the backlog or handoff. The brief is the authoritative statement of scope and purpose. If the backlog says one thing and the brief says another, surface the conflict.

**Don't trust the handoff alone.** `.planning/whats-next.md` captures one session's framing. It may carry assumptions that have drifted from the brief.

**When scope language appears** — "actually, let's broaden this to...", "I've been rethinking..." — acknowledge the shift explicitly, surface which documents need updating, and update as a set. If a `.planning/*/CHANGELOG.md` exists, add an entry capturing what changed and why.

---

## Case Study Reflection

When completing a non-trivial piece of work — building a tool, solving a multi-step problem, creating a new workflow pattern — briefly consider:

1. Does this work demonstrate a pattern that connects to an existing essay in `docs/`?
2. Could this work become its own case study?
3. Does this work validate or challenge a claim made in an existing doc?

When yes, add a seed to `BACKLOG.md` under **Ideas** with the `Case study:` prefix, then commit immediately with a `backlog:` prefix. Mention it briefly to the user.

**Not for trivial work** — don't capture every config change or file rename.

---

## Feedback Checkpoints

After producing substantive output — especially content in the author's voice, a plan, or a design — pause and invite feedback: "Does this match what you had in mind?" Not sparring; not a gate — ask, then continue on forward momentum.

---

## Cross-Linking

When creating or modifying content, see the `/cross-link` skill for the full process. The key principle: every new doc needs a home in the appropriate README's table of contents.

- **New file in `docs/`** — add to track `README.md` and `docs/README.md`. Add to Related Reading of related essays.
- **New file in `library/`** — follow the 4-step ingest checklist in the Library section.
- **New directory in `research/`** — add to `research/README.md`.
- **Renamed or moved file** — search for and update markdown links pointing to the old path.

---

## Workspace Structure

- `devops/` — product-specific technical reference (`ansible/`, `argo/`, `coreos/`, `ocp/`, `rhacm/`, `vault/`)
- `docs/` — essays and guides: `ai-engineering/`, `philosophy/`, `case-studies/` — each with `README.md`; master index at `docs/README.md`
- `library/` — **wiki layer**: enriched entries indexed in `library/README.md` and `library/catalog.md`
- `research/` — **workshop/drawer layer**: raw sources and transcripts that feed the library wiki; indexed in `research/README.md`
- `.planning/` — project briefs, roadmaps, style supplements
- `rules/` — technical reference rules (branching, shell strict mode, structured edits, worktrees, submodules). Referenced by AGENTS.md, not embedded.
- `STYLE.md` — workspace-level writing defaults
- `ABOUT.md` — workspace owner identity
- `BACKLOG.md` — project tracking (`> State:` line)

Troubleshooting guides go in `devops/{product}/troubleshooting/`, never in `docs/`. Research output goes in `research/{topic}/`, never in `docs/`.

**`git-projects/`** (gitignored) — external repo cache. Before fetching from the web, check if it's already cloned here. Offer to clone new repos for future sessions.

---

## Library — Knowledge Wiki

**Mental model:** `library/` is the wiki; `research/*/sources/` are the raw drawers that feed it. Research exists to produce library entries.

**4-step ingest (every time):**
1. Create the entry file in `library/`
2. Add a row to `library/catalog.md`
3. Add an entry block to `library/README.md`
4. Append a dated entry to `library/log.md`

**YouTube / video URLs:** Follow `.agents/skills/youtube-transcript-library/SKILL.md` — use `fetch-transcript.py` under `.agents/skills/research-and-analyze/scripts/`.

An orphaned transcript in `research/*/sources/` with no library entry is an incomplete ingest.

---

## Context Memory

Maintain a brief engineering journal for decisions and context that matter across sessions. Log when you: choose an approach or tool, change scope mid-task, make an architectural decision, or encounter a non-obvious constraint. Keep it short — one paragraph is enough.

---

## Intent First

Before touching 3+ files or adding commands, skills, or rules: write a one-paragraph intent note in `.planning/` or the commit message that answers *why* — not just *what*. This prevents the pattern where a future agent can't tell why something exists and refactors it away.

For structured changes: see the `/lid` skill for touch/change/restructure scaling.

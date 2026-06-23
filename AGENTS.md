# Field Notes — Workspace Context

> This file is the canonical workspace specification. It encodes behavioral rules for working in this workspace, extending `submodules/zanshin-pi-extension/kit/WORKING-STYLE.md` (the canonical L0 kit). This file does not re-declare what the kit owns.
> Commands live in `.agents/skills/<name>/SKILL.md` ([AgentSkills standard](https://agentskills.io/specification)) — discovered natively by Cursor, Claude Code, and Pi.

---

## Identity

Read `ABOUT.md` before forming any assumptions about the workspace owner's domain, background, or priorities. It takes precedence over inferences from the corpus.

**Workspace:** A practitioner's public workspace spanning engineering practice, philosophy, and technical reference. AI-assisted work built from real problems over time.

**Collaboration style:** Shorter over longer; cut before adding. When context is incomplete, ask a sharp question — don't infer silently. Ambient shoshin below; `/shoshin` for deliberate depth; `/spar` when framing is settled.

**Tooling preference:** Prefer free and open-source tools. Flag paid/proprietary options as such when they offer meaningfully lower barrier to entry.

---

## Workspace Extensions

Pi extensions live in `submodules/`. When a task requires working with extension code, check the appropriate submodule.

Key repos:
- `zanshin-pi-extension/` — working discipline L0, commands (`/spar`, `/shoshin`, `/craft`, `/checkpoint`, stack); dev workflow at `docs/PI-EXT-DEV.md`
- `paude-pi-extension/` — Paude container awareness injected into system prompt
- `lid-pi-extension/` — linked-intent development workflow

See `rules/submodule-workflow.md` for troubleshooting.

**Paude (host):** Containerized agent sessions — models do not know this tool by default. Use `.agents/skills/paude-{launch,spec,harvest,triage}/` and `rules/paude-workflow.md` for session lifecycle, harvest, and merge. Narrative: `docs/ai-engineering/paude-getting-started.md`.

**After pushing changes to a Pi extension submodule**, pull the update into the Pi package cache so the user can `/reload` to test immediately:

```bash
git -C ~/.pi/agent/git/github.com/hhellbusch/<repo-name> pull origin main
```

Which submodules are registered as Pi packages: check `~/.pi/agent/settings.json` → `packages`. The cache lives at `~/.pi/agent/git/github.com/<org>/<name>/`. See `devops/pi/README.md` for the full dev workflow.

---

## Session Awareness

This workspace has persistent project state that survives across sessions. When starting work or when the user's intent is unclear, check these context sources before asking questions:

- **`ABOUT.md`** — Read first. The workspace owner's self-description; takes precedence over corpus inferences.
- **`BACKLOG.md`** — In-progress work, what's coming next. The `/start` skill provides a structured orientation.
- **`.planning/<project>/whats-next.md`** — Handoff from a previous session. The project dir is the one with the most recently modified `BRIEF.md`. If no project BRIEF exists, falls back to root `.planning/`. Staleness-check: if commits have been made since it was written, cross-reference against the backlog and git log.
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

> Ambient posture (always on). Invoked depth: `.agents/skills/shoshin/SKILL.md` or `/shoshin`. Portable core: `submodules/zanshin-pi-extension/skills/shoshin/SKILL.md`.

Default posture: approach project context as if encountering it for the first time. **Ask a sharp question before building** when context is incomplete — collaborative, not silent inference. Dormant on simple tasks.

**Verify against sources**, not summaries or handoffs alone:

- **Read the brief** (`.planning/<project>/BRIEF.md`), not just the backlog or handoff. If they conflict, surface it.
- **Don't trust the handoff alone.** `.planning/<project>/whats-next.md` may have drifted from the brief.
- **Re-read before deciding** when a choice depends on file contents (see In-Session Context Awareness).

**When scope language appears** — "actually, let's broaden this to...", "I've been rethinking..." — acknowledge the shift, surface which documents need updating, update as a set. Log in `.planning/*/CHANGELOG.md` if it exists.

**When the document itself may be wrong** (don't run routinely — specific signals):

- External feedback: peer can't find the organizing question, not just unclear wording
- Something survives review unchanged but still feels off
- Author intent evolved beyond what the brief expresses
- Major transition: first external review, publish, new contributor

Ask: *"Is this asking the right question — or a well-written answer to the wrong one?"* Shoshin catches drift between sessions and documents; a wrong frame *inside* the documents needs user pushback or explicit reframing.

**Deep mode:** say "apply shoshin" or `/shoshin` — follow the shoshin skill. Use before `/spar` when the problem may be mis-stated.

---

## Engineering Craft

> Ambient posture (on code work). Invoked depth: `.agents/skills/craft/SKILL.md` or `/craft`. Full reference: `submodules/zanshin-pi-extension/kit/ENGINEERING-PRINCIPLES.md`.

Default on code and design changes: **KISS** over clever; **SRP** (one reason to change); **DRY** when duplication will diverge — not on first coincidence; **YAGNI** for imagined requirements; **leave it slightly better** when already touching a file (≤5 min). Principles are lenses, not a checklist — name tensions when they conflict (DRY vs YAGNI, SRP vs KISS).

Respect phase: make it work → make it right → make it fast. Don't mix refactor, features, and optimization in one pass without reason.

**Deep mode:** say "apply craft" or `/craft` on a file, diff, or design. Use `/review` separately for repo convention compliance before commit.

---

## Artifact Discipline

> Ambient posture (on docs, plans, epics). Invoked: JBGE lens in `/craft`; audience/purpose in `/shoshin`. Reference: `submodules/zanshin-pi-extension/kit/AGILE-ARTIFACT-DISCIPLINE.md`. Peer essay: `docs/ai-engineering/artifact-discipline-and-ai.md`.

Derived from Scott Ambler's Agile Modeling / Agile Data work. AI makes artifact production cheap — default to **JBGE** (just barely good enough): sufficient for the task, no more. Context: invest more for complexity, risk, pragmatic compliance; invest less for skilled audience, easy change, high collaboration, likely change.

**TAGRI** (they ain't gonna read it): before creating or expanding a doc, name the **reader** and the **decision or action** it enables. If unclear, ask — don't draft.

**Travel light:** fewer artifacts; discard models/docs once purpose is served. **Document late:** envision lightly, build, then document what proved true.

**Deep mode:** `/shoshin` for audience/purpose on a plan; `/craft` with JBGE lens on a draft; `/review` includes TAGRI check on new markdown.

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
- `rules/` — technical reference rules (branching, shell strict mode, structured edits, worktrees, submodules, research conventions). Referenced by AGENTS.md, not embedded.

- `STYLE.md` — workspace-level writing defaults
- `ABOUT.md` — workspace owner identity
- `BACKLOG.md` — project tracking (`> State:` line)

Troubleshooting guides go in `devops/{product}/troubleshooting/`, never in `docs/`. Research output goes in `research/{topic}/`, never in `docs/`.

**`git-projects/`** (gitignored) — external repo cache. Before fetching from the web, check if it's already cloned here. Offer to clone new repos for future sessions.

---

## Library — Knowledge Wiki

**Mental model:** `library/` is the wiki; `research/*/sources/` are the raw drawers that feed it. Research exists to produce library entries or docs essays. See `rules/research.md` for full conventions: directory structure, source vs. operational artifact distinction, and linking discipline (prefer original URLs over local copies).

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

Before touching 3+ files or adding commands, skills, or rules: write a one-paragraph intent note in `.planning/` or the commit message that answers *why* — not just *what*. For new artifacts (briefs, epics, docs): also name *who reads it* and *what decision it enables* (TAGRI). This prevents the pattern where a future agent can't tell why something exists and refactors it away.

For structured changes: see the `/lid` skill for touch/change/restructure scaling.

## Project Brief Threshold

Work that crosses any of these thresholds warrants a `BRIEF.md` — create it before continuing, not at the end:

- Task touches **5+ files** across a session
- Work **spans multiple sessions** (context was compacted)
- A **new directory** is created under `devops/`, `docs/`, `research/`, or `library/`
- Scope language appears mid-task: "actually, let's also...", "while we're here..."

Use the `/brief` skill to scaffold `.planning/<project>/BRIEF.md` and an initial `whats-next.md`. The brief is the anchor — handoff files reference it, they don't replace it.

If a brief is missing for active work, surface it at the next natural pause rather than waiting until session end.

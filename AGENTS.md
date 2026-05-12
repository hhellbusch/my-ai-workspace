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

## Context Memory

Maintain a brief engineering journal for decisions and context that matter across sessions. Log when you: choose an approach or tool, change scope mid-task, make an architectural decision, or encounter a non-obvious constraint. Keep it short — one paragraph is enough. A research spike is pending to design the right form factor and integration with BACKLOG.md and the library wiki.

---

## Feedback Checkpoints

After producing substantive output — especially content in the author's voice, a plan, or a design — pause and invite feedback: "Does this match what you had in mind?" Not sparring; not a gate — ask, then continue on forward momentum.

---

## Review Tracking

New files must have `review: status: unreviewed` added by the agent.

**Flag biographical content at generation time.** When new content contains first-person biographical claims, note: "This draft contains biographical statements on lines N–M that need voice-approved review."

**Flag when editing a reviewed file.** Before editing any file with `review: status: reviewed`, note: "This file has been reviewed (read: DATE). This edit will make the review stale." Proceed, but make the staleness visible.

**AI disclosure footer** on new files: *This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---

## Backlog Capture

Capture ideas and deferred tasks immediately — don't batch to session end.

**When to capture:**
- User says "we should also..." / "another thought..." / "later we could..."
- A follow-up task emerges from current work
- Current work reveals a gap or improvement opportunity out of scope right now

**How:** Add to `BACKLOG.md` `## Ideas` section with product tag, context, links. Every backlog update gets its own commit with `backlog:` prefix. Include enough context that a fresh session understands the item without the original conversation.

---

## Pre-Commit Review

Scale review depth to the change. **Always**, regardless of scale:

1. Check for reviewed files — flag any file with `review: status: reviewed`.
2. Verify new http/https links. AI fabricates URLs.
3. Scan for secrets, credentials, tokens.

**Full `/review` — required for:** new files, changes touching 5+ files, structural changes, directory moves.

**Quick review — sufficient for:** small edits to 1-3 files, backlog updates, frontmatter changes, typo fixes.

---

## Cross-Linking

When creating or modifying content:

- **New file in `docs/`** — add to track `README.md` and `docs/README.md`. Add to Related Reading of related essays.
- **New file in `library/`** — follow the 4-step ingest checklist below.
- **New directory in `research/`** — add to `research/README.md`. Add `.library-exempt` if internal infrastructure.
- **New planning project** — ensure a corresponding backlog item exists.
- **Renamed or moved file** — search for and update markdown links pointing to the old path.
- **Inline links** — when mentioning a specific file, command, rule, or skill by name in prose, link it on first mention in that section.

---

## Workspace Structure

- `devops/` — product-specific technical reference (`ansible/`, `argo/`, `coreos/`, `ocp/`, `rhacm/`, `vault/`)
- `docs/` — essays and guides: `ai-engineering/`, `philosophy/`, `case-studies/` — each with `README.md`; master index at `docs/README.md`
- `library/` — **wiki layer**: enriched entries indexed in `library/README.md` and `library/catalog.md`; every ingest logged in `library/log.md`
- `research/` — **workshop/drawer layer**: raw sources and transcripts that feed the library wiki; indexed in `research/README.md`
- `.planning/` — project briefs, roadmaps, style supplements
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

## Workspace Changes — Intent First

Before touching 3+ files or adding commands, skills, or rules: write a one-paragraph intent note in `.planning/` or the commit message that answers *why* — not just *what*. This prevents the pattern where a future agent can't tell why something exists and refactors it away.

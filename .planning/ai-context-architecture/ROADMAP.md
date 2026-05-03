# AI context architecture — roadmap

> Last updated: 2026-05-03

**Done:** Phases 0–1 (baseline + portable docs). **Next:** Phase 3 — Zanshin L0 Pi extension in a **standalone GitHub repo** (normal install: `pi install git:…`). Local `~/.config/paude/defaults.json` is optional personal setup — **not tracked in this plan**. **Later:** Phase 4 (BACKLOG hygiene), Phase 5 (cross-tool parity).

---

## Phase 0 — Baseline (done)

**Goal:** Per-repo Pi bootstrap is token-aware and consistent with `CLAUDE.md` session orientation.

**Done:**
- `.pi/SYSTEM.md` — `> State:`-only backlog bootstrap; skim-then-deep-read for kit; pointer to `CLAUDE.md`.
- `paude` fork: `GOOGLE_CLOUD_LOCATION` derived from `CLOUD_ML_REGION` for google-vertex model discovery.
- `.pi/skills` / `.pi/prompts` → symlinks to `.cursor/` (DRY).

**Verify:** `wc -c .pi/SYSTEM.md` ≲ 2.5 KB; `rg "BACKLOG" .pi/SYSTEM.md` shows on-demand rule.

---

## Phase 1 — Portable docs alignment

**Status:** Complete — 2026-05-03

**Goal:** One story for humans and Copilot-style “read this file” loads; no contradiction with Pi’s narrow backlog rule.

| Task | Action | Verify |
|------|--------|--------|
| 1.1 | Update `docs/ai-engineering/framework-bootstrap.md` “Starting a session” bullet: **first** read `> State:` block from `BACKLOG.md` (or `rg '^> '` first N lines); full backlog only when triaging or asked. | Done |
| 1.2 | Add a short “Context layers” subsection linking here: `.planning/ai-context-architecture/` and stating Pi vs Claude vs portable file. | Done |
| 1.3 | `docs/ai-engineering/paude-getting-started.md`: Pi + `.pi/SYSTEM.md`; `--agent` table includes `pi` / `copilot`; defaults example includes `"git": true`. | Done |

**Checkpoint:** None unless you want to voice-check `framework-bootstrap.md` tone for external readers.

---

## Phase 3 — Zanshin L0 Pi extension (portable)

**Status:** In progress — scaffold on `main` at [hhellbusch/zanshin-pi-extension](https://github.com/hhellbusch/zanshin-pi-extension) (`85ca55e` initial).

**Goal:** Same minimal zanshin contract **on every Pi session**, any repo, without copying `.pi/SYSTEM.md` into customer trees.

**Distribution:** **Standalone GitHub repository** — [github.com/hhellbusch/zanshin-pi-extension](https://github.com/hhellbusch/zanshin-pi-extension). Consumers: `pi install git:https://github.com/hhellbusch/zanshin-pi-extension.git` (pin `#<sha>` once stable). Monorepo subfolder is out of scope for this track.

| Task | Action | Verify |
|------|--------|--------|
| 3.1 | **Spec:** Freeze L0 text (max ~400–600 tokens) sourced from `zanshin-kit/WORKING-STYLE.md` § “Why these practices exist” + collaboration line + one sentence: “Read kit path when user asks or work is high-stakes.” | Human approves L0 in a PR or issue comment |
| 3.2 | **Scaffold:** New **standalone** repo — Pi extension entrypoint per `pi-caveman-mode` pattern (`before_agent_start` → `systemPrompt`). README: install + link to canonical kit. | Done — push `main`; local clone lives beside workspace (`zanshin-pi-extension/`, gitignored here) |
| 3.3 | **Supply chain:** Pin git SHA in README after L0 text is approved; host `pi install` is default. Baking into paude image only if a product decision says so later. | Update README with `#85ca55e` or newer once L0 frozen |
| 3.4 | **Trim this repo’s `.pi/SYSTEM.md`:** Remove L0 duplication once the extension is installed everywhere you care about. | `.pi/SYSTEM.md` only repo-specific |

**Checkpoint:** None for repo shape — **standalone remote** is decided.

---

## Phase 4 — BACKLOG hygiene (optional)

**Goal:** Keep `BACKLOG.md` from growing into an accidental full-context read even when someone mis-runs instructions.

| Task | Action | Verify |
|------|--------|--------|
| 4.1 | Audit: move stale **Ideas** blocks to `BACKLOG-archive.md` or split `BACKLOG-ideas.md` with a link from main header. | Main file shrinks; `> State:` still at top |
| 4.2 | Add to `.pi/SYSTEM.md` or `CLAUDE.md`: “Ideas live in …” if split. | No broken references |

**Checkpoint:** `checkpoint:decision` — archive vs split (your preference for grepability vs file count).

---

## Phase 5 — Cross-tool parity (backlog / later)

- Finish remaining **meta-simplification** items (`CLAUDE.md` ~140 line target, Cursor `alwaysApply` toggles per `.planning/meta-simplification.md` open questions).
- Reconcile **Cursor `session-awareness.md`** with Pi `.pi/SYSTEM.md` wording (same backlog rule).

---

## Context for executors

@.planning/ai-context-architecture/BRIEF.md  
@.planning/meta-simplification.md  
@.pi/SYSTEM.md  
@zanshin-kit/WORKING-STYLE.md (lines 1–42 for L0 source material)

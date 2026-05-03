# AI context architecture — brief

> Written: 2026-05-03

## Objective

Define how **always-on context** vs **on-demand workspace context** is split across **Pi**, **paude**, **Cursor / Claude Code**, and the **Zanshin kit** (`zanshin-pi-extension` git submodule / `pi install`), so that:

1. **Token budget stays low** at session start (no accidental full-file reads of large artifacts).
2. **Zanshin behavioral contract** is available **everywhere Pi runs** (not only repos that ship `.pi/`).
3. **Per-repo truth** (backlog header, `private/`, `docs/`, handoffs) lives in **project-local** files without duplicating the full kit.

## Principles

| Layer | Responsibility |
|--------|----------------|
| **Global (Pi extension, future)** | Portable L0: three failure modes, collaboration line, “when to read the kit” — same injection on any machine / any cwd. |
| **Project `.pi/SYSTEM.md`** | This repo’s contract: paths, guardrails, backlog bootstrap (`> State:` only), pointers to `CLAUDE.md` / kit. |
| **`zanshin-pi-extension/kit/WORKING-STYLE.md`** | Canonical deep manual (git submodule) — read when the user asks or the task needs practices in full. |
| **Heavy workspace** (`BACKLOG` body, large `docs/`, research trees) | **Tools / explicit user request** — never implied “read everything at start.” |

## Success criteria

- [ ] Written plan (this track + `ROADMAP.md`) is the single place an agent or you checks for “what loads when.”
- [ ] `.pi/SYSTEM.md` stays under ~2 KB and does not restate the full kit.
- [ ] Portable bootstrap doc (`docs/ai-engineering/framework-bootstrap.md`) does not contradict the `> State:` backlog rule once updated.
- [ ] Optional: Pi extension published or installable from git with a pinned SHA; documented in `docs/ai-engineering/` or paude fork docs.

## Constraints

- Corporate / shared GCP: no secrets in repo; paude continues to use ADC + proxy patterns already validated.
- **DRY:** kit remains canonical; extension is a **distilled** surface (small intentional overlap).
- Plans stay **small phases** (see `ROADMAP.md`) so execution does not burn a whole context window in one pass.
- **Pi extension distribution:** **Standalone GitHub repository** — not a monorepo subfolder. Local paude `defaults.json` is personal preference and **out of scope** for this track.

## Links

- `.planning/meta-simplification.md` — obligation density for `CLAUDE.md` (aligned intent).
- `.planning/zanshin-kit/ROADMAP.md` — kit content evolution (separate from *where* context loads).
- `.planning/paude-integration/ROADMAP.md` — container / harvest / backends.
- `BACKLOG.md` — backlog item “Zanshin-kit as Pi extension” (deferred implementation; this track refines scope).

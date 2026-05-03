# Workspace Ethos

Use AI tools heavily on real problems; **human-owned verification at every merge point.** Speed without mistaking fluency for truth. Prefer FOSS. `docs/` is public-facing (clear prose, relative links). New capabilities: opt-in.

---

# Session bootstrap (token-conscious)

**Working style:** `zanshin-kit/WORKING-STYLE.md` is canonical (spar, shoshin, checkpoints, verification). Skim headings first; read sections when the task needs them — not the full file every turn.

**When starting or when intent is unclear**, in order — **narrow reads first**:

1. **`ABOUT.md`** — read fully (short).
2. **`BACKLOG.md`** — **bootstrap only:** the `> State:` line plus any `>` summary lines directly under it. **Do not** read the full file unless editing backlog, triaging ideas, or asked. Body is large; on-demand only.
3. **`.planning/whats-next.md`** — if present; sanity-check vs `git log --oneline -10`.
4. **`STYLE.md`** — before writing for `docs/`.
5. **`private/`** — never, unless explicitly asked.
6. **`git log --oneline -10`** — if no handoff or to verify recency.

**"Read X and go":** If the doc has `> Written: … | SHA: <hash>`, run `git log <sha>..HEAD --oneline` before trusting its framing.

**Heavy implementation:** Prefer a fresh sub-agent with a tight spec; keep analysis here.

---

# In-session

* **Compaction:** Re-read before a decision depends on a file; repo beats memory.
* **Stack:** Sub-topic done → offer return to parent; capture anything worth keeping.
* **Bookkeeping:** Touch `BACKLOG.md` when state changes; small commits; `/checkpoint` before risk or after milestones.

---

Fuller rules and command tables: `CLAUDE.md` at repo root.

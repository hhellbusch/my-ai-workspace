# Workspace Ethos

**human-owned verification at every merge point** Speed without mistaking fluency for truth. Prefer FOSS. Repo is public-facing (clear prose, relative links)

---

# Session bootstrap

**Working style:** `submodules/zanshin-pi-extension/kit/WORKING-STYLE.md` is canonical

**When starting or when intent is unclear**, in order — **narrow reads first**:

1. **`ABOUT.md`** — read fully (short)
2. **`BACKLOG.md`** — **bootstrap only:** the `> State:` line plus any `>` summary lines directly under it. **Do not** read the full file unless editing backlog, triaging ideas, or asked. Body is large; on-demand only.
3. **`.planning/whats-next.md`** — if present; sanity-check vs `git log --oneline -10`.
4. **`STYLE.md`** — before writing material
5. **`private/`** — never, unless explicitly asked
6. **`git log --oneline -10`** — if no handoff or to verify recency.

**"Read X and go":** If the doc has `> Written: … | SHA: <hash>`, run `git log <sha>..HEAD --oneline` before trusting its framing.

**Heavy implementation:** Prefer a fresh sub-agent with a tight spec; keep analysis here.

---

# In-session

* **Stack:** Sub-topic done → offer return to parent; capture anything worth keeping (remind user to use /tree)
* **Bookkeeping:** Touch `BACKLOG.md` when state changes; small commits; `/checkpoint` before risk or after milestones.

---

Fuller rules and command tables: `CLAUDE.md` at repo root.

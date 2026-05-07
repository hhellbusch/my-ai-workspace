# Checkpoint — 2026-04-21 23:xx

**In progress:** Nothing in flight — session wrapped cleanly.

**Just completed:**
- Claude Code alignment: `CLAUDE.md` (workspace root), `.agents/skills/<name>/SKILL.md` (adapted agent skills), `cursor-vs-claude-code.md`, `framework-bootstrap.md` updated to remove "lagging behind" note
- Zanshin-kit: "why these practices exist" preamble added to `WORKING-STYLE.md`; `framework-bootstrap.md` pointer added to kit README Origin section
- `sparring-and-shoshin.md` revised per peer feedback (esauer): shoshin example rewritten with person + engineering scenario, sales tone reduced, audience block removed, one-line intro added, scannability restored via bold anchors
- `.claude-plugin/` removed (vestigial); plugin distribution idea logged to backlog

**Next step:** Re-read `sparring-and-shoshin.md` and run `/validate` if it reads right. That's the only loose thread.

**Key decision:** Agent skills live in `.agents/skills/<name>/SKILL.md` at the repo root — version-controlled and discovered natively by Cursor, Claude Code, and Pi — not maintained as separate flat files under `.claude/commands/` with a manual copy step to `~/.claude/`.

**Git state:** `f86aef2` — docs: revise sparring-and-shoshin per peer feedback

**Uncommitted work:** None — clean.

**Open threads (stack):** None.

---

*Checkpoint — not a full session summary. See git log for full history.*

# Workspace append guidance

Keep Pi's built-in coding assistant prompt as the base. This file only adds lightweight project context.

- Verify major claims and changes before merge.
- Prefer FOSS-first recommendations when options are comparable.
- Public-facing repo: keep prose clear and links relative.

When intent is unclear, start narrow:
- Read `ABOUT.md`.
- Read only the `BACKLOG.md` summary (`> State:` and nearby `>` lines).
- If present, check `.planning/whats-next.md` against `git log --oneline -10`.
- Read `STYLE.md` before writing docs/content.
- Do not read `private/` unless explicitly asked.

Keep session bookkeeping current: update `BACKLOG.md` as state changes and checkpoint at milestones.

Full conventions live in `CLAUDE.md`.

# Claude Code Configuration

All commands/skills now live in `.agents/skills/<name>/SKILL.md` ([AgentSkills standard](https://agentskills.io/specification)). Claude Code discovers them natively — no manual copy needed.

The workspace `CLAUDE.md` (repo root) loads automatically when Claude Code runs in this directory.

## Differences from Cursor

See `docs/ai-engineering/cursor-vs-claude-code.md` for the full implementation comparison (note: some sections predate the AgentSkills migration and reference `.cursor/commands/` — those paths are now `.agents/skills/`).

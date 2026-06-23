# Paude Host Skills

> **Status:** In Progress
> **Started:** 2026-06-11
> **Owner:** Henry Hellbusch

## Problem Statement

Paude is a custom containerized agent runner — models have no training-data knowledge of it.
Host-side agents (Cursor, Claude Code) routinely guess wrong on harvest, submodule discipline, worktrees, and session lifecycle.
Container-side agents (Pi in paude) produce handoffs that break harvest (wrong branches, `git submodule update --remote`, misleading commits).

We have narrative docs (`docs/ai-engineering/paude-getting-started.md`) and a harvest-prep prompt draft, but no **discoverable skills** that route when a user says "harvest the workspace session" or "start a paude task."

## Scope

**In scope:**

- Four host skills under `.agents/skills/`: `paude-harvest`, `paude-launch`, `paude-spec`, `paude-triage`
- Thin vocabulary rule: `rules/paude-workflow.md` (linked from `AGENTS.md`)
- Harvest-prep template for container agents (referenced by `paude-spec`, not duplicated)
- Cross-links in `devops/paude/README.md`

**Out of scope:**

- Pi extension / slash command inside paude (future: `/harvest-prep` in zanshin kit)
- Replacing `paude-getting-started.md` — skills link to it
- OpenShift backend workflows
- Auto-push / PR creation (local merge is the default path)

## Success Criteria

- [ ] Each skill has AgentSkills-compliant frontmatter with routing keywords (paude, harvest, session, container, submodule)
- [ ] `paude-harvest` encodes real failure modes from ocp-sno and workspace sessions (submodule fetch, branch name collision, stale base)
- [ ] `paude-launch` enforces worktree-first + absolute `--prompt-file` paths
- [ ] `paude-spec` produces task specs that end with harvest-prep instructions
- [ ] `paude-triage` covers Active/Idle, blocked domains, uncommitted work
- [ ] Skills stay under 500 lines each (router + workflows pattern for harvest)

## Constraints

- Follow existing workspace skill style (`lid`, `start` — markdown headings OK in body)
- Skills are host-only; container awareness stays in `paude-pi-extension` L0
- Submodule merge targets are workspace-specific (see `references/submodule-targets.md` in harvest skill)
- Do not commit unless user asks

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Skill count | Four focused skills, not one mega-skill | Clear routing; harvest vs launch are different intents |
| Harvest merge | Local merge default in skill | User preference from ocp-sno/workspace sessions |
| Container prep | Template file, not a host skill | Host skill references it; container agent reads path when told |
| Branch naming | Avoid `harvest/foo` if `harvest` branch exists | Hit real collision in workspace session |
| Docs vs skills | Skills = procedures; docs = narrative | Progressive disclosure |

## Related

- [SKILLS-SPEC.md](SKILLS-SPEC.md) — detailed requirements per skill
- [docs/ai-engineering/paude-getting-started.md](../../docs/ai-engineering/paude-getting-started.md)
- [rules/git-worktrees.md](../../rules/git-worktrees.md)
- [rules/submodule-workflow.md](../../rules/submodule-workflow.md)
- [.planning/paude-integration/BRIEF.md](../paude-integration/BRIEF.md)

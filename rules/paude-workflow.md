# Paude Workflow (host)

Paude runs AI agents in isolated Podman containers. Models have no built-in knowledge of it — use the paude skills in `.agents/skills/`.

## Vocabulary

| Term | Meaning |
|------|---------|
| Session | Named container (`paude list`) — e.g. `workspace`, `ocp-sno` |
| Harvest | Pull agent commits from container to host via `paude harvest` or `paude-<session>` git remote |
| Worktree | Host git isolation under `worktrees/<slug>` — required before `paude create` |
| Harvest branch | Container commits on `harvest/<slug>` — not `main` |

## Host skills

| Skill | When |
|-------|------|
| `paude-launch` | Start a session (worktree + spec + create) |
| `paude-spec` | Write task spec + harvest-prep instructions |
| `paude-triage` | Session stuck, empty harvest, 403 blocks |
| `paude-harvest` | Pull and merge session work locally |

## Rules

- Fetch/pull host `main` before harvest.
- Submodule: commit inside submodule first, then update parent pointer.
- Never `git submodule update --remote` when integrating harvested work.
- Container agent prep: `devops/paude/harvest-prep-prompt.md`

## Docs

- Narrative: `docs/ai-engineering/paude-getting-started.md`
- Planning spec: `.planning/paude-skills/SKILLS-SPEC.md`
- Worktrees: `rules/git-worktrees.md`

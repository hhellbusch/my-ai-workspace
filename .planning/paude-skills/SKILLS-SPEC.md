# Paude Skills — Requirements Spec

Design document for host-side AgentSkills that make Paude operable without model prior knowledge.
Implementation lives in `.agents/skills/paude-{harvest,launch,spec,triage}/`.

---

## Design principles

1. **Routing keywords in descriptions** — every skill `description` must include terms users actually say: `paude`, `harvest`, `session`, `container`, `submodule`, `worktree`, `podman`.
2. **Procedures in skills, narrative in docs** — skills link to `paude-getting-started.md`; they do not duplicate install/prerequisites.
3. **Encode failures from practice** — requirements below cite real incidents (ocp-sno, workspace sessions).
4. **Two audiences** — host operator (these skills) vs container agent (harvest-prep template + `paude-pi-extension` L0).
5. **Local merge default** — harvest skill assumes merge on host unless user asks for PR/push.

---

## Skill 1: `paude-harvest`

### Purpose

Pull committed work from a running paude session into the host repo and merge it locally — including submodule changes that only exist in the container.

### When to invoke

- User says harvest, pull from paude, merge session changes
- After agent reports `HARVEST READY` or user believes session is Idle
- `paude harvest` failed or produced empty diff

### Arguments

```
paude-harvest <session-name> [--slug <task-slug>] [--merge] [--no-merge]
```

- `session-name` — e.g. `workspace`, `ocp-sno` (from `paude list`)
- `--slug` — task slug for branch naming; default: infer from container branch or ask
- `--merge` — merge into host `main` after harvest (default if user said "merge locally")
- `--no-merge` — stop on harvest branch / worktree for review

### Required knowledge (reference files)

| File | Contents |
|------|----------|
| `references/failure-modes.md` | Submodule fetch failure, branch `harvest` vs `harvest/foo` collision, stale container base vs host-ahead main, misleading commits, `.orig` files from patch |
| `references/submodule-targets.md` | This workspace's submodule → merge branch map |
| `references/commands.md` | `paude harvest`, manual fetch, `podman exec`, bundle import |

### Workflow: `workflows/harvest.md`

**Pre-flight (host)**

1. `git fetch origin && git pull origin main` on host main worktree
2. Stash or commit unrelated host dirty state if pull blocked
3. `paude status <session>` — confirm Idle, read SUMMARY

**Inspect container (before harvest)**

```bash
podman exec paude-<session> bash -lc 'cd /pvc/workspace && git branch && git log --oneline -5 && git status -sb'
```

4. Read `AGENT-NOTES.md` if present
5. Note container branch (often `harvest/<slug>` not `main`)
6. List patch exports under `devops/paude-proxy/harvest/<slug>/` if any

**Harvest**

7. Try `paude harvest <session> -b <harvest-branch>`
8. On submodule fetch failure → `git fetch paude-<session> <container-branch> --no-recurse-submodules` then `git checkout -B <harvest-branch> paude-<session>/<container-branch>`
9. If branch name `harvest/<slug>` fails (existing `harvest` branch) → use `harvest-<slug>` instead

**Submodule import (when SHAs not on remote)**

10. Bundle from container: `git bundle create` in submodule, `git fetch` bundle on host
11. Or apply patches from `devops/paude-proxy/harvest/<slug>/`

**Verify harvest**

12. `git log --oneline main..<harvest-branch>`
13. `git diff --stat main..<harvest-branch>` — flag if paude/paude-proxy pointers would **revert** host-ahead work

### Workflow: `workflows/merge-locally.md`

1. Merge each touched submodule on its target branch (see `submodule-targets.md`)
2. Update submodule pointers in main repo only for repos actually changed
3. Commit on host `main` — do not use `git submodule update --remote`
4. Optional: remove harvest worktree / branch after merge

### Success criteria

- Harvest branch exists with expected commits
- Submodule changes applied on correct branches
- Host `main` pointers match merged submodule SHAs
- No accidental revert of unrelated submodule updates

### Do not

- Push unless user asks
- Trust container handoff without `git show` / `git diff` verification
- Use `git submodule update --remote`

---

## Skill 2: `paude-launch`

### Purpose

Start a paude session correctly: worktree isolation, `--git`, task spec, domains, naming.

### When to invoke

- User wants to run work in paude, create session, fire-and-forget task
- Before long-running or parallel agent work

### Arguments

```
paude-launch <session-name> [--slug <slug>] [--spec <path>] [--agent pi|claude|gemini]
```

### Required knowledge

| File | Contents |
|------|----------|
| `references/decision-gate.md` | Paude vs in-session Task subagent |
| `references/create-flags.md` | `--git`, `--yolo`, `--prompt-file`, `--allowed-domains`, `--pi-extension` |

### Process

1. **Decision gate** — read `decision-gate.md`; confirm paude is right tool
2. **Worktree** — `git worktree add worktrees/<slug> -b <slug>` from host main (see `rules/git-worktrees.md`)
3. **cd** into worktree — paude infers workspace from cwd
4. **Create** — `paude create <session-name> --git --yolo --agent <agent> --prompt-file <absolute-path>`
5. **Domains** — merge `paude.json` allowlist; add session-specific domains (OCP API hosts, etc.)
6. **Verify** — `paude status`, optional `paude wait`

### Success criteria

- Session running, workspace synced, spec path was absolute
- Worktree slug matches branch name
- Host `main` not checked out to task branch

### Do not

- Run `paude create` from host `main` while other sessions active on same tree
- Use relative `--prompt-file` paths

---

## Skill 3: `paude-spec`

### Purpose

Write a task spec file for a paude agent — scoped, committable, harvest-ready.

### When to invoke

- User describes work to delegate to paude
- Before `paude-launch`
- When refining a `.planning/` task into an executable prompt

### Arguments

```
paude-spec [--project <name>] [--output <path>]
```

### Template: `templates/task-spec.md`

Sections:

1. **Objective** — one paragraph, outcome not implementation
2. **Scope in / out** — explicit boundaries
3. **Repos likely touched** — main only, or which submodules
4. **Constraints** — versions, patterns, do-not-touch list
5. **Success criteria** — checkable
6. **Commit discipline** — harvest branch name, submodule rules, no push
7. **Harvest prep** — instruct agent to follow `templates/harvest-prep-prompt.md` when done

### Default output path

`.planning/<project>/task-specs/<slug>.md` or `.planning/paude-integration/task-specs/<slug>.md`

### Success criteria

- Spec is self-contained for a fresh container agent
- Includes `<session-name>` and `harvest/<slug>` placeholders filled in
- Ends with explicit "run harvest prep when done"

---

## Skill 4: `paude-triage`

### Purpose

Diagnose a running or stalled paude session — decide wait, nudge, harvest, or reset.

### When to invoke

- Session seems stuck, idle too long, harvest empty, 403 errors
- User asks "what is paude doing"

### Arguments

```
paude-triage <session-name>
```

### Process

1. `paude status <session>` — Active vs Idle, SUMMARY, last activity
2. `paude blocked-domains <session>` if network suspected
3. Container git state — uncommitted? wrong branch?
4. Read last lines of agent output if available (`paude connect` alternative: check tmux via podman if needed)
5. Recommend: wait / send prompt / add domain / harvest prep / reset

### Decision table

| Signal | Action |
|--------|--------|
| Active + recent output | Wait |
| Idle + clean commits on harvest branch | Harvest |
| Idle + dirty tree | Connect or send harvest-prep prompt |
| 403 on domain | `paude allowed-domains --add` |
| Empty submodule dir | `git submodule update --init` in container |
| Wrong session name in AGENT-NOTES | Correct before harvest |

### Success criteria

- User gets a single recommended next action with command

---

## Shared: `templates/harvest-prep-prompt.md`

Container-agent prompt (paste or reference at end of task spec).
Lives in `paude-spec/templates/` and is copied to `devops/paude/harvest-prep-prompt.md` for human visibility.

Content: the validated harvest-prep checklist from ocp-sno lessons (branch discipline, submodule commits, patch export, AGENT-NOTES, HARVEST READY block).

---

## Shared: `rules/paude-workflow.md`

~20 lines, always-referenced from `AGENTS.md`:

- Paude = isolated container executor at `/pvc/workspace`
- Host harvests via git remote `paude-<session>`
- Container commits on `harvest/<slug>`, not `main`
- Submodule: commit inside submodule first, then pointer in parent
- `paude list` / `paude status` for session inventory

---

## Build order

1. `paude-harvest` (highest ROI)
2. `paude-launch`
3. `paude-spec` + harvest-prep template
4. `paude-triage`
5. `rules/paude-workflow.md` + cross-links

---

## Acceptance checklist (project complete)

- [x] Four host skills implemented under `.agents/skills/`
- [x] `devops/paude/README.md` links to skills
- [x] `AGENTS.md` mentions paude skills
- [x] `rules/paude-workflow.md` added
- [x] Harvest-prep template at `paude-spec/templates/` + `devops/paude/`
- [ ] All four skills pass `audit-skill` without critical issues
- [ ] Used on live harvest (`workspace` session) to validate

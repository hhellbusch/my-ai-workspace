---
name: paude-launch
description: Start a paude container session for fire-and-forget agent work. Use when
  creating a paude session, delegating a task to paude, running work in an isolated
  container, setting up a paude worktree, or launching pi/claude/gemini in podman.
argument-hint: "<session-name> [--slug <slug>] [--spec <absolute-path>] [--agent pi|claude|gemini]"
allowed-tools: Read Write Shell Glob Grep
---

# Paude Launch

<objective>
Start a paude session with correct worktree isolation, git sync, task spec, and domain allowlist — so harvest works later.
</objective>

<essential_principles>

- Always launch from a **worktree**, never host `main` while other sessions may run.
- `--prompt-file` paths must be **absolute** — cwd changes inside worktrees.
- `--git` is required for harvest; without it the container workspace is empty.
- Session name (`paude connect <name>`) is separate from git branch slug — record both.

</essential_principles>

<context>
- Decision gate: `references/decision-gate.md`
- Flags: `references/create-flags.md`
- Worktrees: `rules/git-worktrees.md`
- Task specs: `.agents/skills/paude-spec/SKILL.md`
- Narrative: `docs/ai-engineering/paude-getting-started.md`
</context>

<process>

### 1. Decision gate

Read `references/decision-gate.md`. If paude is not the right tool, say so and stop.

### 2. Parse arguments

From `$ARGUMENTS`:

- `<session-name>` — required
- `--slug <slug>` — default: ask or derive from spec filename
- `--spec <path>` — task spec; if missing, invoke `paude-spec` first or ask
- `--agent` — default `pi` for this workspace

### 3. Ensure spec exists

If no spec file, run or point user to `paude-spec` before continuing.

Spec must include session name, harvest branch slug, and harvest-prep instructions.

### 4. Create worktree

From host workspace root (on current `main`):

```bash
git fetch origin && git pull origin main
git worktree add worktrees/<slug> -b <slug>
```

If worktree exists, ask: resume in existing worktree or new slug?

### 5. Create session

```bash
cd worktrees/<slug>
paude create <session-name> --git --yolo --agent <agent> \
  --prompt-file <absolute-path-to-spec>
```

Read `references/create-flags.md` for domains, fork image, optional flags.

### 6. Verify

```bash
paude status <session-name>
```

Confirm: running, project path matches worktree.

### 7. Hand off to user

Report:

- Session name and worktree path
- How to monitor: `paude status`, `paude wait`
- How to finish: `paude-harvest <session-name> --slug <slug> --merge`

</process>

<success_criteria>
- Session running with `--git` sync from correct worktree
- Spec path was absolute
- User knows session name, slug, and harvest command
</success_criteria>

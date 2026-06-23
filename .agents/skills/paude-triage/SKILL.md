---
name: paude-triage
description: Diagnose a running or stalled paude container session. Use when paude
  seems stuck, harvest returned empty, checking paude status, debugging 403 proxy
  blocks, or deciding wait vs harvest vs reset.
argument-hint: "<session-name>"
allowed-tools: Read Shell Glob Grep
---

# Paude Triage

<objective>
Determine what a paude session is doing and recommend one next action — wait, nudge, add domain, harvest prep, harvest, or reset.
</objective>

<essential_principles>

- `Active` = agent may still be working; `Idle` = done or waiting for input.
- Empty harvest almost always means uncommitted work in the container.
- Network 403 at CONNECT layer = domain not on allowlist — not a git problem.
- Read `AGENT-NOTES.md` and container `git log` before trusting agent handoff prose.

</essential_principles>

<context>
- Commands: `.agents/skills/paude-harvest/references/commands.md`
- Harvest: `.agents/skills/paude-harvest/SKILL.md`
- Narrative: `docs/ai-engineering/paude-getting-started.md`
</context>

<process>

### 1. Session status

```bash
paude status <session-name>
paude list
```

Record: STATE (Active/Idle), ACTIVITY, SUMMARY.

If `<session-name>` missing from `$ARGUMENTS`, list sessions and ask.

### 2. Network blocks

```bash
paude blocked-domains <session-name>
```

If recent 403s, recommend:

```bash
paude allowed-domains <session-name> --add <host>
```

### 3. Container git state

```bash
podman exec paude-<session-name> bash -lc 'cd /pvc/workspace && git branch && git log --oneline -3 && git status -sb'
```

Check for `AGENT-NOTES.md`:

```bash
podman exec paude-<session-name> bash -lc 'test -f /pvc/workspace/AGENT-NOTES.md && head -40 /pvc/workspace/AGENT-NOTES.md'
```

### 4. Submodule health

```bash
podman exec paude-<session-name> bash -lc 'git -C /pvc/workspace submodule status | head -15'
```

Empty submodule dirs (`-` prefix) → init needed in container.

### 5. Decide

| Signal | Recommendation |
|--------|----------------|
| Active, recent agent output | `paude wait <session>` — check back |
| Idle, commits on `harvest/*`, clean tree | `paude-harvest <session> --merge` |
| Idle, dirty tree, no commits | Send harvest-prep prompt (`paude-spec/templates/harvest-prep-prompt.md`) |
| Idle, HARVEST READY in notes | `paude-harvest` — verify SHAs first |
| 403 blocked domains | `paude allowed-domains --add` then reconnect |
| Empty submodule | `git submodule update --init` inside container |
| Wrong branch (on `main` with WIP) | Send harvest-prep or manual commit instructions |
| User wants to abandon | `paude reset <session>` — warn about unharvested work |

### 6. Report

One paragraph: state, finding, **single recommended command**.

</process>

<success_criteria>
- User knows Active vs Idle and whether commits exist
- Exactly one recommended next action with command
- Blocked domains and dirty tree ruled in or out
</success_criteria>

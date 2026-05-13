---
name: start
description: Quick session orientation — state, handoff, focus
argument-hint: "[--detail | --brief <project> | --handoff [path] | --reconstruct]"
allowed-tools: Read Shell Glob Grep
---

# Start — Session Orientation

<objective>
Surface what's actionable so the user can decide what to work on. Minimal default output. Optional flags for deeper context. This is the complement to `/whats-next` (which creates the handoff at session end).

Run this at the beginning of a new session, or whenever you need to re-orient.
</objective>

## Context

- Backlog summary: `head -4 BACKLOG.md` (the `> State:` line — ground truth)
- Handoff files: `find .planning -maxdepth 2 -name whats-next.md -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -5`
- Planning projects: `ls -d .planning/*/ 2>/dev/null || echo "none"`
- Recent commits: `git log --oneline -10`
- Uncommitted changes: `git status --short`

## Process

Parse `$ARGUMENTS` to determine the mode. If empty, default to **minimal**.

---

### `minimal` — default, ~3 tool calls

Present a compact snapshot:

```
## Where Things Stand

> [State line from BACKLOG.md — already in context]

## Handoff

[Most recent whats-next.md — one paragraph. If stale: "Handoff may be stale — X commits since written."]
[If multiple handoffs exist: note the others briefly.]

## Suggested Focus

1. **[Continue: title]** — [what's in the handoff]
2. **[Next: title]** — [highest priority Up Next backlog item]
3. **[Quick win: title]** — [small item, low effort]

What are you working on?
```

**Rules:**
- Do NOT read ABOUT.md (already in context via AGENTS.md)
- Do NOT read full BACKLOG.md — the `> State:` line is sufficient
- Do NOT do brief alignment unless `--detail`
- Do NOT run env readiness — rare need
- Do NOT check branch commit mode — user controls this
- Present max 3 suggestions, always ending with a question

If no handoff exists: skip the Handoff section entirely. The user can run `--detail` for git-log reconstruction if they need it.

---

### `--detail` — include brief alignment

After the minimal output, add:

```
## Brief Alignment

- **[project]**: [one-liner] — [aligns / ⚠ no backlog item]
- **[project]**: [one-liner] — [aligns / ⚠ scope drift?]
```

For each planning project:
1. Read the BRIEF.md **one-liner only** (first non-blank line after the title)
2. Compare against In Progress / Up Next backlog items
3. Surface gaps — if everything aligns, one line per project is enough
4. If drift is detected: flag it but don't resolve it automatically

---

### `--brief [project]` — read full BRIEF.md for a specific project

1. Read `.planning/<project>/BRIEF.md` in full
2. Present: problem statement, success criteria, current state
3. Ask: "Is this still the right scope, or has it evolved?"

If no project is specified, default to the one with the most recent whats-next.md.

---

### `--handoff [path]` — dump the handoff content

1. Read the specified whats-next.md (or the most recent if no path given)
2. Present it in full
3. Ask: "Pick up from here?"

---

### `--reconstruct` — git-log-based context reconstruction

When there's no handoff file (crash, abrupt end, or `/whats-next` was skipped):

1. From `git log --oneline -10`, identify the cluster of commits from the last session
2. Synthesize: what was being worked on, what's in-flight (backlog items that connect to recent commits)
3. Note limitations concisely: "Git log shows *what landed*, not what was decided-but-deferred."
4. Ask: "Does this match what you had in mind?"

---

## When to use which mode

| Situation | Mode |
|---|---|
| New session, user knows what they're working on | `minimal` (default) |
| User is returning to a previous project | `minimal` → they'll pick from suggestions |
| User wants to check if scope drifted | `--detail` |
| User is resuming a specific project, wants context | `--brief <project>` |
| User wants to see what the handoff says | `--handoff` |
| No handoff file, session needs context from git log | `--reconstruct` |

## What to skip

- **ABOUT.md** — already loaded via AGENTS.md
- **Full BACKLOG.md** — the `> State:` line is the summary; read sections on request
- **Roadmaps** — never read automatically; one-liners only in `--detail`
- **Continue-here files** — only if the user asks about a specific project
- **Environment readiness** — only if the user is in a new machine/container
- **Commit mode** — the user controls this; stating it adds friction without value

## Success criteria

- Default output fits in ~10 lines
- User can decide what to work on without asking follow-up questions
- Detail is available via flags, not forced on every start
- One-liner brief alignment catches drift at low cost

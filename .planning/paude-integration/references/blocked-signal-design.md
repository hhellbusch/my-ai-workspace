# Design: Agent "Blocked" Signal — Human-in-the-Loop for Autonomous Tasks

## Problem

When a Paude agent runs a task autonomously, it hits decision points the spec didn't cover.
Today it has two bad options: guess (and possibly produce wrong output) or stall (go Idle with
no commits). Neither is useful. The agent needs a way to surface a structured question to a
human operator and either wait for a reply or proceed with documented defaults after a timeout.

This is distinct from failure (`on_failure`) — blocked is not an error, it is a **spec gap**
discovered at runtime.

---

## Core Concept: The Blocked State

A new terminal state alongside `pass` and `fail`:

```
task lifecycle:
  create → running → idle → [ pass | fail | BLOCKED ]
```

**Blocked** means: the agent has done as much as it can, has a specific question, and cannot
proceed safely without an answer. It is a first-class outcome, not a degraded failure.

---

## Signal Contract

### Agent side — `.paude-blocked.json`

The agent writes this file to the workspace root before exiting with code `42`:

```json
{
  "schema": "paude-blocked/v1",
  "task_id": "observability-platform-metrics",
  "session": "task-observability-platform-metrics",
  "blocked_at": "2026-04-30T15:23:00Z",

  "question": {
    "summary": "PVC target size not specified in the spec.",
    "detail": "The spec says to expand the prometheus-k8s PVC but does not give a target size. Current size is 50Gi at 98% usage. The storage class supports online expansion.",
    "options": [
      { "id": "A", "label": "2x current size (100Gi)" },
      { "id": "B", "label": "Fixed 150Gi" },
      { "id": "C", "label": "Let me specify a custom value" }
    ]
  },

  "work_completed": [
    "Identified the full PVC list on the spoke cluster",
    "Confirmed storage class supports online expansion",
    "Drafted the oc patch command, pending target size"
  ],

  "default_assumption": {
    "if_no_reply_within": "30m",
    "assumption": "Use 2x current size (100Gi)",
    "rationale": "Industry convention for headroom on monitoring storage"
  }
}
```

Exit code `42` is the sentinel. The orchestrator (`paude run`) detects it and transitions the
session to `blocked` rather than `fail`.

### Orchestrator side — result file

```json
{
  "task_id": "observability-platform-metrics",
  "status": "blocked",
  "blocked": {
    "question": "...",
    "default_assumption": { ... },
    "deadline": "2026-04-30T15:53:00Z"
  }
}
```

`paude run` exits with code `3` (distinct from `0`=pass, `1`=fail, `2`=error) so CI/pipelines
can route blocked tasks to a human approval queue rather than treating them as build failures.

---

## Reply Mechanism

### CLI: `paude reply <session> --message "..."`

```bash
paude reply task-observability-platform-metrics --message "Use option A — 100Gi is fine."
```

Internally this:
1. Writes `.paude-answer.json` to the session workspace (via `inject_file`)
2. Pushes the answer as a git commit on the task branch
3. Re-runs the agent headless with the original spec PLUS the answer injected into context

The agent on restart sees:

```
[Previous context]
Human reply to your blocked question:
  "Use option A — 100Gi is fine."
Continue from where you left off. Your work_completed list above is already done.
```

This is constructed by `paude reply` reading `.paude-blocked.json` and `.paude-answer.json` and
building a resume prompt.

### Timeout path

`paude run --blocked-timeout 30m` (or from the task YAML `blocked_timeout: 30m`) triggers
a background watcher. After the timeout:

1. The orchestrator reads `default_assumption` from `.paude-blocked.json`
2. Synthesizes a reply: `"No human reply received. Proceeding with default: <assumption>"`
3. Calls the same `paude reply` flow with the synthetic answer
4. Records `"resumed_from": "default_assumption"` in the result file

This means tasks never hang indefinitely in CI — they either get a human answer or fall back
to the documented default.

---

## Task YAML additions

```yaml
id: observability-platform-metrics
intent: >
  Add a troubleshooting guide covering Prometheus PVC full...

blocked_timeout: 30m        # how long to wait for a human reply before using defaults
on_blocked: notify_human    # vs on_failure — different routing, different urgency
on_blocked_timeout: resume_with_defaults  # or: fail | escalate

claims:
  - id: GUIDE-001
    check: git_committed
  # ...
```

---

## Multi-Agent Routing

In a team-composition model, not all blocked questions need a human. The task YAML can declare
a routing policy:

```yaml
blocked_routing:
  - match: "naming convention|style|format"
    route_to: agent:style-reviewer   # another Paude session answers
  - match: "size|capacity|resource"
    route_to: human                  # only these go to a person
  - default: human
```

The orchestrator evaluates `question.summary` against the routing rules (simple keyword match
or a small `agent_review` call) to decide who answers. Low-stakes clarifications are routed to
a specialist agent; high-stakes or ambiguous ones go to a human. This is the "team" model
from LID — agents can answer each other's clarification requests, and humans are only in the
loop for decisions they actually need to make.

---

## Relationship to Claims

Claims are *post-hoc* verification: did the agent do what we asked?
Blocked signals are *mid-task* interruptions: can the agent do what we asked?

They compose naturally:

```
task outcome = f(exit_code, claims, blocked_file)

if exit_code == 42 and blocked_file exists:
    status = blocked
elif all claims pass:
    status = pass
elif any claim fails:
    status = fail
```

A blocked task skips claim evaluation — it hasn't finished yet. Claims only run after a clean
exit (code 0) or a default-resumption.

---

## Implementation Phases

| Phase | What | Notes |
|-------|------|-------|
| 1 | Exit code 42 detection in `run_task` | Trivial — just check returncode |
| 2 | `.paude-blocked.json` schema + `paude run` result | New result status field |
| 3 | `paude reply` CLI command | Inject answer + resume agent |
| 4 | Blocked timeout watcher | Background timer in `run_task` |
| 5 | Multi-agent routing table | Needs `agent_review` plumbing already done |

Phases 1–2 can be done without any container changes — pure orchestrator-side work. The agent
just needs to write the file and exit with 42; the container doesn't need to know about it.

---

## Agent Instruction in the Spec

The system prompt (or a standard addendum to every spec) would include:

```
If you reach a decision point not covered by the spec and the wrong choice would cause
irreversible or hard-to-reverse changes, STOP. Write a .paude-blocked.json file following
the schema at CLAUDE.md#blocked-signal, then exit with code 42. Do not guess. Do not
proceed with an irreversible action unless you have explicit instructions.

Safe to proceed without asking: naming, formatting, minor structural choices, addenda.
Must ask: destructive operations, resource sizing, credentials, external system changes.
```

---

## Open Questions

1. **Resume context size** — for long tasks, the "work_completed" list + spec could exceed
   context limits. Need a summary strategy for resumption.

2. **Idempotency** — the agent resumes from a checkpoint. If it re-runs work it already did,
   it should detect and skip it. AGENT-NOTES.md helps here but isn't guaranteed.

3. **Multiple blocks** — can a single task block more than once? Probably yes. The YAML could
   have `max_blocks: 3` to prevent infinite back-and-forth.

4. **Paude pipeline integration** — a blocked stage should pause the whole pipeline, not just
   the current session. The pipeline runner needs a `blocked` gate type.

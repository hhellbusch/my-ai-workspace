# Roadmap: Paude Integration Evaluation

## Overview

A structured evaluation progressing from basic mechanics through real autonomous tasks to a go/no-go assessment. Each phase builds on the previous — no phase should start until the prior one is complete, since later phases depend on comfort with Paude's workflow. The final phase produces the decision document that unblocks (or closes) the systemic integration backlog item.

## Phases

- [x] **Phase 1: Mechanics** — Install Paude, smoke-test full session lifecycle
- [ ] **Phase 2: Real Task** — Autonomous task against this workspace, harvest and review
- [ ] **Phase 3: Orchestration** — Fire-and-forget -> harvest -> PR -> reset cycle
- [ ] **Phase 4: Multi-Agent** — Same task with Claude and Gemini, compare outputs
- [ ] **Phase 5: Assessment** — Write findings, update backlog, decide keep/skip/integrate

## Phase Details

### Phase 1: Mechanics
**Goal**: Paude installed and working locally, full session lifecycle exercised
**Depends on**: Nothing (first phase)
**Plans**: 1 plan

Plans:
- [x] 01-01: Install Paude via `uv tool install paude`, verify Podman, create throwaway session against a test directory, exercise create -> connect -> status -> harvest -> stop -> delete

**Key questions to answer:**
- How fast is session creation after images are cached?
- What does the git remote workflow feel like (push in, pull out)?
- How does `--yolo` behave inside the container?
- Does container isolation map to "principal protection" in practice, or does it shift review burden without reducing it? (PAI signal: principal-at-center framing)

### Phase 2: Real Task
**Goal**: A real bounded task completed autonomously against this workspace, output quality assessed
**Depends on**: Phase 1 (comfortable with session lifecycle)
**Plans**: 1 plan

Plans:
- [x] 02-01: Push this workspace to a Paude session with `--git`, assign a bounded task via `-a` (e.g., expand an OCP troubleshooting guide or create a CoreOS troubleshooting README), let it run, harvest to a branch, review diff
- [ ] 02-02: Assign a "Pi upgrade–shaped" task — ecosystem survey (scan a topic, diff against an existing workspace resource, propose specific changes) — to test whether `.cursorrules` suffices for high-autonomy, broad-scope, bounded-output work without interactive steering

**Key questions to answer:**
- Does `.cursorrules` give the agent enough context without interactive steering? **Yes — agent read `.cursorrules` and adapted correctly (e.g., detected STYLE.md applies to `docs/` not `devops/` and adjusted tone accordingly)**
- How does output quality compare to an interactive session? **High — AGENT-NOTES showed deliberate, defensible decisions. Output was merge-worthy on first successful run.**
- What's the overhead of the harvest-review-merge cycle vs direct editing? **Low once workflow is understood. The friction was spec quality, not tool overhead.**
- Does harvesting a Paude session feel like "talking to Kai" or "managing contractors"? **Closer to Kai when the spec is good — single review point, agent self-assessed via AGENT-NOTES. Felt like contractors only during the failed attempts when spec was underspecified.**

**Failure modes surfaced (2026-04-29):**
1. Prompt starting with a workspace slash command keyword ("Review…") — agent ran `/review` instead of the task
2. Ambiguous phrasing in headless mode — agent stalled waiting for clarification it couldn't get
3. No explicit commit instruction — agent wrote files but didn't commit; harvest produced empty diff
4. `paude reset` after a failed attempt wipes any work before harvest — reset only after harvesting

**Workflow pattern established:** Craft → Gate → Hand off → Monitor → Harvest → Analyze. Documented in `docs/ai-engineering/paude-getting-started.md`.

### Phase 3: Orchestration
**Goal**: Full fire-and-forget workflow tested, including the reset -> reassign cycle
**Depends on**: Phase 2 (know what a good task assignment looks like)
**Plans**: 1 plan

Plans:
- [ ] 03-01: Create session, assign task, disconnect immediately, come back later, harvest to feature branch with `--pr`, review PR via `gh`, then reset session and assign a second task

**Key questions to answer:**
- Is the orchestration overhead worth it for solo dev?
- How smooth is the reset -> reassign cycle for sequential tasks?
- Does `paude status` provide enough visibility into agent progress?
- What level of task specification is required to match interactive session quality — how much "Kai world model" must be written into the brief? (PAI signal: task brief as surrogate DA context)
- When disconnected, does the task brief + `.cursorrules` give the agent enough "ideal state" context to make good prioritization calls, or does it drift without steering?

### Phase 4: Multi-Agent
**Goal**: Same task run with different agents, outputs compared
**Depends on**: Phase 2 (know how to frame effective task assignments)
**Plans**: 1 plan

Plans:
- [ ] 04-01: Pick a task suitable for comparison (e.g., write a troubleshooting guide), run with `--agent claude` and `--agent gemini` in parallel sessions, harvest both, diff outputs

**Key questions to answer:**
- Do different agents produce meaningfully different outputs for documentation/content tasks?
- Is multi-agent comparison practical or just interesting?
- Does this inform the "AI prioritization bias" backlog item?
- Run two Claude sessions on two different tasks concurrently: does aggregate throughput justify parallelism at a two-session scale? (PAI signal: "army of agents" value at realistic scope — not just different models, but concurrent same-model instances)

### Phase 5: Assessment
**Goal**: Written findings document, backlog items updated, clear keep/skip/integrate decision
**Depends on**: Phases 1-4 (all evaluation data collected)
**Plans**: 1 plan

Plans:
- [ ] 05-01: Write assessment document summarizing findings across all phases, update the "Explore Paude" backlog item (complete or refine), unblock or close the "Paude as external executor" backlog item

**Assessment dimensions:**
- **Keep**: Which use cases justify the container overhead?
- **Skip**: Which workflows are better served by the current in-session approach?
- **Integrate**: If keeping, what specific integration points (slash command, config, orchestration patterns)?
- **Artifacts**: If keeping, add `paude.json` to workspace, `~/.config/paude/defaults.json` setup, possibly `ocp/examples/paude-agent-sessions/` guide
- **PAI/Kai lens**: Does the full evaluation support Paude as "the fire-and-forget leaf executor layer" in a Kai-like system, or is it better described as "isolated Claude for specific bounded tasks"? Does the harvest workflow recreate army-of-agents overhead or genuinely consolidate it behind a single review point? (See `research/pai-kai-paude/assessment.md` for the evaluation framework.)

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Mechanics | 1/1 | Complete | 2026-04-29 |
| 2. Real Task | 1/2 | In progress | - |
| 3. Orchestration | 0/1 | In progress | - |
| 4. Multi-Agent | 0/1 | Not started | - |
| 5. Assessment | 0/1 | Not started | - |

## Orchestration infrastructure completed (2026-04-30)

The following were built and validated before moving to Phase 3 proper:

- **`paude run`** — atomic `create → wait → harvest → claims` command in `workflow.py`
- **`paude wait`** — programmatic session idle detection (polls tmux pane activity)
- **`paude tail`** — structured `.paude-events.jsonl` stream for agent observability
- **Claims-based verification** — `git_committed`, `file_exists`, `file_contains`, `agent_review` types
- **Timestamp session names** — `task-{id}-{YYYYMMDD-HHMMSS}` suffix prevents collision on reruns; cleanup is deferred to the janitor
- **Git worktree convention** — `worktrees/{slug}/` inside repo, gitignored; `paude run` works correctly from worktree (`exists()` not `is_dir()` for `.git` check)
- **Headless prompt quoting fix** — launcher script on disk sidesteps host shell expansion of multi-line prompts with backticks
- **`paude-janitor.sh`** — sweeps stopped containers, orphaned volumes/networks, stale git remotes, stale registry entries, and merged worktrees; dry-run by default

**Validated end-to-end:**
- Observability platform metrics troubleshooting guide — all 5 claims passed (including 2 `agent_review` claims)
- Hello-world smoke test — clean fast-forward merge, correct shared history (no orphan commits)

## Pi agent added to fork (2026-05-02)

`--agent pi` is now available in the fork (`feature/wait-and-prompt-file`). Supports four providers: `vertex` (Claude via `basnijholt/pi-anthropic-vertex` extension + Gemini natively), `anthropic`, `google`, `github`. Vertex+ADC auth uses the same proxy mechanism as Claude Code and OpenClaw — no new infrastructure needed.

Implication for Phase 4: multi-agent comparison now has three viable agents (claude, gemini, pi) with the same Vertex backend. Pi is the current primary interactive agent for this workspace.

Pi docs: `paude/docs/PI.md`.

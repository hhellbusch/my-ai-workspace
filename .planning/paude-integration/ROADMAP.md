# Roadmap: Paude Integration Evaluation

## Overview

A structured evaluation progressing from basic mechanics through real autonomous tasks to a go/no-go assessment. Each phase builds on the previous — no phase should start until the prior one is complete, since later phases depend on comfort with Paude's workflow. The final phase produces the decision document that unblocks (or closes) the systemic integration backlog item.

## Phases

- [ ] **Phase 1: Mechanics** — Install Paude, smoke-test full session lifecycle
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
- [ ] 01-01: Install Paude via `uv tool install paude`, verify Podman, create throwaway session against a test directory, exercise create -> connect -> status -> harvest -> stop -> delete

**Key questions to answer:**
- How fast is session creation after images are cached?
- What does the git remote workflow feel like (push in, pull out)?
- How does `--yolo` behave inside the container?

### Phase 2: Real Task
**Goal**: A real bounded task completed autonomously against this workspace, output quality assessed
**Depends on**: Phase 1 (comfortable with session lifecycle)
**Plans**: 1 plan

Plans:
- [ ] 02-01: Push this workspace to a Paude session with `--git`, assign a bounded task via `-a` (e.g., expand an OCP troubleshooting guide or create a CoreOS troubleshooting README), let it run, harvest to a branch, review diff

**Key questions to answer:**
- Does `.cursorrules` give the agent enough context without interactive steering?
- How does output quality compare to an interactive session?
- What's the overhead of the harvest-review-merge cycle vs direct editing?

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

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Mechanics | 0/1 | Not started | - |
| 2. Real Task | 0/1 | Not started | - |
| 3. Orchestration | 0/1 | Not started | - |
| 4. Multi-Agent | 0/1 | Not started | - |
| 5. Assessment | 0/1 | Not started | - |

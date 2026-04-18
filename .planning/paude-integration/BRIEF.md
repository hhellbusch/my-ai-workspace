# Paude Integration Evaluation

**One-liner**: Evaluate Paude as a peripheral executor for the meta-prompting architecture — isolated containers, safe autonomous mode, multi-agent comparison.

## Problem

All orchestration in this workspace is currently in-process: Task subagents run inside Cursor sessions on the host machine, sharing context and conversation history. This works well for tightly-coupled pipelines (research -> spar -> plan -> implement) but has gaps:

- **No isolation** — subagents run on the host with full filesystem access. There's no sandbox boundary between the orchestrator and the executor.
- **No safe autonomous mode** — `--yolo` equivalent doesn't exist for Task subagents. Every execution carries the same trust level.
- **No fire-and-forget** — long-running tasks (research fetching, large drafts, code refactors) tie up the session. You can't assign work and walk away.
- **No multi-agent comparison** — everything runs through the same model. There's no mechanism to run the same task against Claude, Gemini, and Cursor CLI and compare outputs.

[Paude](https://github.com/bbrowning/paude) (v0.15.0) runs AI coding agents in network-filtered containers with git-based sync. It supports Claude Code, Cursor CLI, Gemini CLI, and OpenClaw. Its orchestration model — create, assign, harvest, PR — maps to the "leaf task executor" gap in the current architecture without replacing the core pipeline.

## Success Criteria

How we know it worked:

- [ ] Session lifecycle completed end-to-end (install, create, connect, status, harvest, stop, delete)
- [ ] Real autonomous task harvested from this workspace, output quality assessed against interactive baseline
- [ ] Fire-and-forget -> harvest -> PR workflow tested, including reset -> reassign cycle
- [ ] Multi-agent comparison completed (same task, different agents, outputs diffed)
- [ ] Written assessment documenting keep/skip/integrate decisions with specific integration points identified

## Constraints

- Requires Podman (available on Fedora) or Docker as container runtime
- Auth credentials needed for at least one provider (Anthropic API key or Vertex AI)
- Agent sessions get a fresh clone — no shared conversation history between stages
- Container image pull on first run takes several minutes
- Evaluation is learning-oriented, not building production tooling

## Out of Scope

- OpenShift backend exploration (deferred unless local evaluation succeeds)
- Building integration tooling (`/paude` slash command, external executor pattern) — separate backlog item, blocked on this evaluation
- Replacing the in-session Task subagent pattern for tightly-coupled pipelines
- Production deployment or team workflow design

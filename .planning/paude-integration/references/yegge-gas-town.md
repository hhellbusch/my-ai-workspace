# Reference: "Welcome to Gas Town" — Steve Yegge (Jan 2026)

**Source:** https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04  
**Author:** Steve Yegge (ex-Amazon, ex-Google, ex-Sourcegraph)  
**Published:** January 1, 2026  
**Read time:** ~34 min

---

## Summary

Gas Town is Yegge's fourth complete agent orchestrator, written in Go. It coordinates 20–30 Claude Code instances simultaneously for sustained, high-throughput software development. Built on top of his earlier [Beads](https://github.com/steveyegge/beads) project (a Git-backed issue tracker / data plane), Gas Town layers in worker roles, workflow orchestration, and a merge queue.

---

## Core Architecture

### Worker Roles (7 + the Overseer)

| Role | Scope | Job |
|------|-------|-----|
| **Mayor** | Town | Primary concierge / chief-of-staff; you talk to it most |
| **Polecats** | Per-rig | Ephemeral workers that swarm tasks and produce Merge Requests |
| **Refinery** | Per-rig | Merge Queue manager; intelligently merges MRs one at a time |
| **Witness** | Per-rig | Watches polecats, helps them get un-stuck |
| **Deacon** | Town | Daemon beacon; runs patrols in a loop; propagates "do your job" signal |
| **Dogs** | Town | Deacon's crew; handles maintenance and plugin execution |
| **Crew** | Per-rig | Long-lived named agents for the Overseer; direct replacement for old Claude Code workflow |
| **Overseer** | — | That's you |

### The MEOW Stack (Molecular Expression of Work)

Gas Town's core abstraction layer:

- **Beads**: Atomic work units. Git-backed JSON issue tracker. IDs, descriptions, status, assignees.
- **Epics**: Beads with children. Parallel by default, explicit dependencies for sequencing.
- **Molecules**: Workflows chained with Beads. Arbitrary DAG shapes; survive agent crashes/restarts.
- **Protomolecules**: Molecule templates (classes). Variable substitution creates real workflows.
- **Formulas**: TOML source format for workflows; "cooked" into protomolecules. Macro-expansion, loops, gates. Turing-complete.
- **Wisps**: Ephemeral Beads. In the DB but not persisted to Git; burned after use. Used for high-velocity orchestration (patrol loops) to avoid Git noise.

### GUPP — Gastown Universal Propulsion Principle

> **If there is work on your hook, YOU MUST RUN IT.**

Every worker has a **Hook** (a pinned Bead). Work is "slung" onto the hook via `gt sling`. GUPP ensures agents pick up their hook work on startup, across session boundaries. In practice, Claude Code sometimes waits for user input; a GUPP Nudge (`gt nudge`) sends a tmux keystroke to kick the agent. Boot the Dog pings the Deacon every 5 min as a watchdog.

### Nondeterministic Idempotence (NDI)

Agents are persistent (Beads in Git); sessions are ephemeral cattle. When an agent restarts, it picks up its hook and finds its place in the molecule. Even if the path is nondeterministic, the workflow eventually finishes as long as you keep throwing sessions at it. NDI is Gas Town's alternative to Temporal's deterministic durable replay.

### Convoys

The top-level work-order unit. Every slung task gets wrapped in a Convoy for tracking. A Convoy has a dashboard (Charmbracelet TUI) showing tracked issues and their states. Convoys land when all their work is done.

---

## Developer Stage Model (Fig. 2)

Yegge's "Evolution of the Programmer" — useful framing for thinking about where Paude fits in the adoption curve:

| Stage | Description |
|-------|-------------|
| 1 | Zero/near-zero AI |
| 2 | Agent in IDE, permissions on |
| 3 | Agent in IDE, YOLO mode |
| 4 | In IDE, wide agent (fills screen) |
| 5 | CLI, single agent, YOLO |
| 6 | CLI, 3–5 parallel agents |
| 7 | 10+ agents, hand-managed |
| 8 | Building your own orchestrator |

Gas Town targets Stage 7+ operators. Below Stage 6, you "will not be able to use Gas Town."

---

## Comparison to Kubernetes

Yegge draws an explicit parallel:

| Kubernetes | Gas Town |
|------------|----------|
| etcd | Beads (Git data plane) |
| kube-scheduler / controller-manager | Mayor / Deacon |
| Nodes | Rigs |
| kubelet | Witness |
| Pods | Polecats |
| "Is it running?" | "Is it done?" |
| Optimizes for uptime | Optimizes for completion |

---

## Relevance to Paude Exploration

Gas Town is the most mature public example of what the paude-integration brief is asking about — a "peripheral executor" for running isolated, autonomous agentic workloads. Key points of contact:

- **Isolation model**: Gas Town uses per-rig worktrees; Paude uses containers. Different implementation, same intent.
- **Workflow durability**: MEOW molecules give Gas Town crash-resilient workflows. This is a gap to probe in Paude — does it have equivalent?
- **Merge Queue / conflict resolution**: Refinery agent is a dedicated role. Multi-agent parallelism requires some equivalent.
- **Cost model**: Yegge runs 20–30 agents; notes needing multiple Claude Code accounts. Relevant to the cost/benefit framing in the brief.
- **Orchestration complexity**: Gas Town is complicated by Yegge's own admission. The brief question "does complexity of orchestration exceed value of parallelism?" is directly relevant.
- **"Stage" prerequisite**: Gas Town requires Stage 7 proficiency. Paude may have a similar prerequisite curve — worth evaluating whether the meta-prompting architecture is ready for it.
- **Pluggability**: Gas Town has a plugin model for Deacon/Witness patrols. Paude integration into meta-prompting pipelines is analogous.

---

## Key Quotes

> "Gas Town is an industrialized coding factory manned by superintelligent robot chimps."

> "Work in Gas Town can be chaotic and sloppy... you are churning forward relentlessly on huge, huge piles of work."

> "You are a Product Manager, and Gas Town is an Idea Compiler."

> "The focus is throughput: creation and correction at the speed of thought."

> "Gas Town is not a replacement for Temporal."

---

## Links

- Gas Town repo: https://github.com/steveyegge/gastown
- Beads repo: https://github.com/steveyegge/beads
- Earlier prediction: [Revenge of the Junior Developer](https://sourcegraph.com/blog/revenge-of-the-junior-developer)

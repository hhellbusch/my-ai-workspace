# EngineersOfAI — What are AI Agents?

## Metadata

- **Creator:** EngineersOfAI
- **Type:** Online course module (Agentic AI, Module 1 — Agentic Foundations)
- **URL:** https://engineersofai.com/docs/agentic-ai/agentic-foundations/What-are-AI-Agents
- **Series:** Agentic AI track — [Module 01: Agentic Foundations](https://engineersofai.com/docs/agentic-ai/agentic-foundations/Module-01-Agentic-Foundations)
- **Published:** 2026
- **Tags:** agentic-ai, foundations, agent-loop, tool-use, memory, scaffolding, react, reliability, production-engineering, llm
- **Added:** 2026-04-21
- **Projects:** `research/ai-agent-memory/`, PAI/Kai exploration, local LLM track

## Why This Matters (personal)

*(Author: add a note on why this foundation matters to you — e.g., what it clarifies about how you are already using these systems, or which of the 5 properties maps most directly to what you have observed in practice.)*

## Key Concepts (AI-enriched from source)

### The precise definition

An **AI agent** is a system that:

1. Perceives its environment (through tool outputs, memory, context)
2. Reasons about what it perceives (using an LLM)
3. Takes action to change its environment (through tool calls)
4. Repeats this loop autonomously until a goal is achieved or a stopping condition is met

The critical word is **autonomously**. A system that requires human approval at every step is not an agent — it is a human-in-the-loop system. A system that runs a fixed sequence of steps is not an agent — it is a workflow. The test: does the system dynamically decide what to do next based on what it observes?

### The 5 key properties

**Goal-directed** — agents have an objective that persists across multiple steps and guides every decision. Disambiguating between options happens by asking: which choice brings me closer to the goal?

**Environment-aware** — agents perceive the current state of the world through tools (files, databases, APIs, web), not just what the user provided in the initial message.

**Action-capable** — agents change the world, not just describe it. This is what separates an agent from a sophisticated chatbot: the chatbot tells you how to fix the bug; the agent fixes it.

**Adaptive** — agents respond to what actually happens, not what they expected to happen. If every step was predictable, you would write a script, not an agent.

**Persistent** — agents maintain state across multiple steps. The accumulated context allows coherent decisions across a long trajectory. Without memory, each action is made in isolation.

### Agent taxonomy

**Reactive** — maps observations directly to actions without maintaining an internal model. Fast and simple. Most basic tool-using LLM applications.

**Deliberative** — builds an internal model of the world and plans before acting. Slower, more resource-intensive, better at complex tasks requiring foresight.

**Hybrid** — fast reactive layer for simple/time-sensitive decisions; slow deliberative planner for complex reasoning. How the best production agents work. (Claude Code is a documented example: immediately reads a file you reference (reactive), deliberates extensively before changing core logic (deliberative).)

**Learning** — updates behavior based on experience. RLHF is one mechanism; Reflexion agents (Shinn et al., 2023) explicitly reflect on failures and update approach within a single run.

### The agent stack

Every production agent has four components:

- **LLM (Brain)** — reads observations, decides what to do next, generates tool calls, interprets results, determines when the task is complete
- **Tools (Hands)** — read/write files, execute code, call APIs, query databases, run searches
- **Memory (State)** — short-term: conversation history (accumulating record of observations, thoughts, actions); long-term: vector database, structured database, filesystem artifacts
- **Scaffolding (Body)** — the code that orchestrates the loop, executes tools, handles errors, manages the context window, decides when to stop

### Historical context

- 1971: Dennett's intentional systems theory (philosophy)
- 1986: Brooks' subsumption architecture (robotics)
- 1993: Shoham's agent-oriented programming (AI research)
- 1990s: Software agents — brittle, narrow-domain, rule-crafted; the missing piece was a general-purpose reasoning engine
- 2022: ReAct paper (Yao et al., Princeton/Google Brain) — LLMs interleaving reasoning and acting dramatically outperformed either alone
- 2023: AutoGPT (proof of concept), ChatGPT plugins, GitHub Copilot multi-file suggestions
- 2024: Devin (~14% SWE-bench), Claude 3.5 Sonnet (~49% SWE-bench), Claude Code ships
- 2025: Best systems ~55–65% SWE-bench; production use at real companies

### The compound reliability problem

A single LLM call is roughly 95–99% reliable for well-specified tasks. Agents compound this multiplicatively:

- At 99% per step across 20 steps: 0.99²⁰ = 82% success rate
- At 95% per step across 20 steps: 0.95²⁰ = 36% success rate

This is not a peripheral concern — it is a fundamental constraint of multi-step agent architectures. Build reliability expectations and architecture choices around this from day one, not as an afterthought.

### Production engineering notes from the source

**Max iterations is not optional** — every agent loop needs an explicit limit. Set it based on task complexity (simple tasks: 10, complex: 50, never unlimited).

**Context window pressure is real** — 200,000 tokens sounds large until 50 files averaging 4,000 tokens each consume it. Build context management (summarization, pruning) from day one.

**Never give agents irreversible write access by default** — always start read-only, add write tools only when needed, require explicit confirmation for destructive operations.

### Common mistakes (from the source)

**Calling anything that uses an LLM an "agent"** — the test: (1) dynamic tool selection based on observations, (2) variable number of steps determined at runtime, (3) goal-directed autonomous execution. If you can predict the exact sequence before the run starts, it is not an agent.

**No stopping condition** — task completion detected by LLM, max iterations, timeout, or error threshold. An agent without stopping conditions will run forever.

**Treating agent reliability like deterministic code reliability** — see compound reliability above.

## Connections to This Work

**AI agent memory research avenue:** The Memory (State) component maps directly to the research avenue at `research/ai-agent-memory/`. Short-term (conversation history as accumulated observations) and long-term (vector DB, structured DB, filesystem artifacts) are the two tiers this workspace is exploring through the cross-session persistence sources. The agent stack framing gives a precise vocabulary for that research.

**Persistent property and the Zanshin framework:** The "Persistent" property — agents must maintain state across steps to make coherent decisions — is exactly the problem the Zanshin session framework addresses from the practitioner side. The framework is a human-operated scaffolding layer that compensates for what the model's memory cannot do natively. Naming it as a property makes the gap more precise: the model's native persistence is the context window; `/checkpoint` and `/whats-next` extend that into cross-session persistence by other means.

**Context window pressure → local LLM track:** The note about 200,000-token context being consumed by 50 files at 4,000 tokens each is a clean articulation of why the local LLM experiment (14k context) hits architectural limits so quickly. The agent can't hold the whole codebase. This is the constraint the hybrid local/cloud workflow and RAG index items in the backlog are trying to address.

**Compound reliability → sparring methodology:** The 0.95²⁰ = 36% success rate is a rigorous argument for why long agent trajectories need adversarial review. Not because each step is bad, but because error compounds. Spar is one mechanism for catching compounded error before it ships.

**PAI/Kai exploration:** Miessler's PAI architecture maps directly onto this agent stack: Intelligence (LLM + scaffolding), Tools (67 skills), Memory (three-tier), Scaffolding (17 hooks, 7 lifecycle events). The EngineersOfAI framing gives the canonical vocabulary; PAI is one production instantiation of it.

**Agent vs. chatbot vs. workflow distinction:** The source's precision on what distinguishes an agent from a workflow maps to the `/start` command discussion: loading a briefing and executing a fixed sequence of steps is a workflow; dynamically deciding what to check based on what you observe (shoshin, spar triggers) is closer to agent behavior. This framing may be useful in the session-framework.md and interaction-patterns.md docs.

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

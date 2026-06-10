# LangChain vs. Behavioral Skills — Two Layers, One Mistake

> **Audience:** Engineers deciding between application frameworks and agent behavioral instructions for workflow automation. Skeptical of jargon. Values precision over enthusiasm.
> **Purpose:** Names the failure mode where frameworks and skills are treated as interchangeable tools, explains why they live on different layers, and provides a decision rule for when each is appropriate.

---

## The Question

A peer asked whether LangChain or a behavioral skill (like a Pi skill — see [skills README](../../.agents/skills/README.md)) is the right tool for workflow development. The question assumes they're alternatives. They're not. They solve different layers of the problem.

Treating them as competing options is the same pattern as choosing an MCP server over a Python script without asking what the workflow actually needs. The architecturally elegant option isn't always the workflow-fit option — [choosing the simpler tool](../case-studies/choosing-scripts-over-services.md) is. But choosing between them also isn't a choice between elegant and crude. It's a category error.

---

## What Each Layer Does

### LangChain — Application Framework

LangChain is about *what your application does*. It provides chains, tools, memory, and agent loops — structures that orchestrate LLM API calls as part of a running product. Its concerns are runtime: managing state across requests, serializing prompts to different providers, parsing structured output, handling multi-step execution paths, implementing RAG pipelines over a data source.

The framework manages the *execution graph* of an LLM-powered application. It doesn't care about the developer's workflow. It cares about what the end-user experiences when the system runs.

### Pi Skills — Behavioral Context

A skill is a file that says "when you encounter X, do Y." It's loaded into an agent's context at session start. It doesn't manage API calls — the agent decides what to call. It doesn't orchestrate runtime execution — it shapes the agent's reasoning within a single session.

Skills are instructions for *how an agent-thinks*, not for what a system-executes. They live in YAML and XML. They're human-readable. They get loaded into context, not into a process runtime.

---

## The Layers

| | LangChain | Pi Skills |
|---|---|---|
| **Layer** | Application / production | Developer workflow |
| **Scope** | Multi-app, long-running, user-facing | Single session, dev-facing |
| **State** | Runtime (memory, DB, cache) | Context (YAML + file I/O) |
| **Execution** | Framework-managed chains/agents | Agent decides what to call |
| **Language** | Python/JS SDK | Human-readable YAML+XML |
| **Ownership** | Users and customers | Developer and agent |

The cleanest way to think about this: LangChain produces outputs that end-users interact with. Skills produce outputs that developers and agents interact with.

---

## When Each Wins

LangChain is the right tool when:

- You're building something that runs in production
- The system needs persistent state across requests (user memory, conversation history, cached retrievals)
- Multiple tools or steps execute as part of a user-facing product, not just a developer's session
- You need RAG over a data source that changes independently of your agent's context
- You're routing between providers dynamically and need the SDK to handle schema differences

A skill is the right tool when:

- The workflow lives in an agent's reasoning, not in a runtime pipeline
- You need to teach an agent how to do something repeatedly in a development context
- The output is a file, a decision, or a structured review — not an end-user experience
- One file of instructions replaces 200 lines of orchestrating code

**Rule of thumb:** If the workflow is about what the agent thinks, a skill is usually enough. If it's about what the system executes, that's when you reach for a framework.

---

## The Intersection

This is where the distinction matters most: cases where you *could* build either.

Imagine a workflow for ingesting YouTube transcripts. A LangChain equivalent would be ~200 lines of Python — orchestrating API calls to YouTube, parsing the response, writing files to disk, handling rate limits, managing output formats. It would be a production-grade service.

A skill is a YAML file that says: "when given a YouTube URL, run [`fetch-transcript.py`](../../.agents/skills/research-and-analyze/scripts/fetch-transcript.py), save the output to [`research/{topic}/sources/`](../../research/README.md), and update the library [`catalog.md`](../../library/catalog.md)." The agent reads the skill, understands the instruction, and calls the right tool.

Both produce a transcript file. The skill does it in one pass with full context awareness. The LangChain equivalent would need to manage its own state, handle its own errors, maintain its own retry logic — for something an agent can already understand as a behavioral directive.

If the workflow is file-based (fetch once, cache to disk, read from filesystem in subsequent sessions), the script + skill pattern is simpler. The script produces the file. The skill tells the agent how to use it.

If the workflow is user-facing (a product that fetches, analyzes, and displays transcripts on demand), that's where LangChain's execution model matters.

---

## Why the Confusion

The confusion comes from framing both as "automation." They are, but they automate different things:

- LangChain automates *what a system does when a user triggers it*
- A skill automates *what an agent does when a developer asks it to*

The "automation" that a developer is thinking about when choosing between these tools is usually about their own workflow, not about an end-user experience. When you're the user, the skill *is* the automation — there's no separation between the developer and the operator.

This is also why the question gets asked in AI-assisted work contexts: the developer is simultaneously the operator and the consumer. The boundary between "workflow" and "product" collapses. That collapse is why the category error happens.

---

## The Vendor Lock-In Angle

LangChain is provider-agnostic by design. You swap the LLM component by changing an import. The framework handles prompt serialization, output parsing, and token counting across OpenAI, Anthropic, Google, AWS, Ollama, and dozens more.

The trade-off: each provider has different capabilities, and a chain tuned for one provider's function calling schema might need rework for a provider that handles tool use differently. The abstraction is real, but it's not free. You trade multi-provider flexibility for adaptation overhead.

Skills have no vendor lock-in at all. They're just files. They don't call any API — they instruct the agent, which chooses its own tools and providers. A skill written for one model works with any model that understands the instruction. The agent is the abstraction layer, not the framework.

---

## What Doesn't Translate

There are things LangChain does that a skill can't, and vice versa. Knowing the boundary helps avoid trying to force one into the other's problem space.

**LangChain handles things skills can't:**
- Persistent state across user sessions (RAG pipelines, conversation memory, tool state)
- Multi-app execution (the same chain runs for every user, not just the developer)
- Structured output that feeds into downstream services (API responses, database writes, user-facing dashboards)
- Error handling at the application level (retry logic, fallback chains, timeout management)

**Skills handle things LangChain can't:**
- Session-aware reasoning (the agent adapts its behavior based on what it just did, not just what the pipeline says)
- Full context access (a skill file can read other files, check git status, verify claims against source documents)
- One-file behavioral instructions that get loaded into context (no installation, no runtime, no dependency management)
- Developer-facing workflows that don't have end-users (code review, documentation, research)

---

## The Choice Isn't Binary

These tools aren't mutually exclusive. A production system might use LangChain to orchestrate a RAG pipeline for end-users while using skills to teach the developer's agent how to maintain that pipeline. The LangChain app handles the user-facing execution graph. The skills handle the developer-facing behavioral context.

The failure mode isn't choosing one over the other. It's trying to use LangChain for a problem that a skill file solves, or trying to use a skill for a problem that requires runtime execution.

---

## What the Decision Looks Like in Practice

When a peer asked about LangChain vs. skills, the answer wasn't "pick one." It was "what layer are you solving for?"

If the question is about automating your own development workflow — fetching transcripts, auditing files, managing a backlog, cross-linking documentation — you don't need a framework. You need a file that tells the agent how to think.

If the question is about building a product that processes user input, maintains state, and returns structured output — that's where framework choices matter.

The same principle that governs choosing scripts over services: [the simplest tool that fits the actual workflow](../case-studies/choosing-scripts-over-services.md) is usually the right tool. It's just that "the actual workflow" depends on which layer you're operating on.

---

## Related Reading

- [The Shift — Engineering Skills in the Age of AI](the-shift.md) — when AI handles implementation, the bottleneck moves to problem decomposition and verification; this piece is a decision rule within that problem space
- [AI-Assisted Development Workflows](ai-assisted-development-workflows.md) — transferable patterns for using AI coding assistants effectively across multi-session projects
- [Choosing Scripts Over Services](../case-studies/choosing-scripts-over-services.md) — the same judgment pattern: choosing the simpler tool that fits the workflow, not the one that fits an architectural vision
- [The Session Framework — Patterns, Behaviors, and Why](session-framework.md) — the framework that defines how behavioral skills operate in this workspace

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

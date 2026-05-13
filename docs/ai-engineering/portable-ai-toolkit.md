# A Portable AI Toolkit — My Agent, Anywhere

> **Status:** Working draft — direction-reviewed, awaiting author review
> **Audience:** Engineers using AI assistants for multi-session projects who want to understand the architecture described here
> **Purpose:** Explains how Paude + Pi + Zanshin form a portable toolkit that travels with you to any workspace, and why that matters

---

## The Problem

AI assistants are stateless. Every session starts fresh. Context from prior sessions — decisions made, approaches tried, scope defined — doesn't carry over unless it was committed to a file. This works fine for single tasks. It compounds into drift for work that spans days or weeks: the session produces good output that doesn't connect to prior work, or re-litigates decisions that were already settled.

The friction is real but usually handled piecemeal. Some people write handoff docs. Others use prompt templates. Some save notes. None of these solve the deeper problem: **you can't move your working style to a new project without rebuilding it from scratch every time.**

The skills, practices, and tools that make AI-assisted work actually compound — that prevent context resets, catch fluent-but-wrong output, track decisions across sessions — they live in one place and stay there. They don't travel with you to a new repo, a new team, a new problem.

What if they did?

---

## The Solution

Containerize the agent runtime, containerize the working discipline, and push your accumulated knowledge into the container as the workspace context. One command:

```bash
paude create workspace --agent pi --provider vertex --git
```

Now you have an agent in a container with:
- Your working practices (adversarial review, session tracking, verification discipline)
- Your installed tools (skills for research, sparring, backlog management)
- Your accumulated context (the workspace itself — essays, case studies, troubleshooting guides, library entries)
- Your provider auth (Vertex AI, API keys, whatever backend you use)

Wherever you can run Linux containers (Docker, Podman, or OpenShift/Kubernetes) and reach your inference provider, you have the same toolkit. Not a clone of the repo and hope you wired it right. Not a prompt template that works once and degrades. A containerized environment with everything configured, tested, and ready to use on a new problem.

This is what the architecture below is for.

---

## The Three Layers

The toolkit is three layers, each solving a different problem:

### Layer 1: Runtime (Paude + Pi)

**Paude** is a container orchestrator for AI coding agents. It runs agents in isolated, network-filtered containers (Linux containers — Docker, Podman, or OpenShift/Kubernetes) with git-based sync. You push your code in, assign a task, disconnect, and pull the output back as a branch when the agent is done.

**Pi** is a minimal terminal coding agent — no built-in permission system, designed to run in containers. It's the day-to-day agent in this workspace. Paude installs it automatically inside containers; no local Pi installation is needed. Unlike most coding agents locked to one provider, Pi supports multiple LLM backends: Vertex AI (Claude + Gemini), Anthropic API, Google AI, GitHub Copilot. Switch backends with a flag; no config rebuild.

Together they provide:
- **Isolation** — the agent runs without your files exposed to the host network; container-level boundaries replace permission dialogs
- **Git-based sync** — workspace is pushed into the container, agent commits to git, you harvest back as a branch
- **Provider flexibility** — swap between Vertex AI, Anthropic, Google AI, GitHub Copilot without rebuilding anything; each backend can be selected at session creation time
- **Fire-and-forget** — assign a task, disconnect, harvest later. No session tied up waiting

The runtime layer solves the "where does the agent live and how do I get its output" problem. It doesn't solve "how do I make the agent actually good at this work."

### Layer 2: Discipline (Zanshin Kit)

**Zanshin** (残心) — "remaining mind" — is the working discipline that keeps AI-assisted work coherent after a session ends. It's the practices that prevent the three failure modes that break multi-session work:

| Failure mode | What it is | How Zanshin defends |
|---|---|---|
| Cross-session statelessness | Decisions made in one session don't persist to the next | Session tracking, checkpoints, backlog state capture |
| Context compaction | Earlier content gets compressed as context fills mid-session | Re-read files before deciding; repo is truth, not conversation memory |
| Fluent-but-wrong | Confident output covering unverified claims | Adversarial review (spar), verification discipline, pre-commit review |

The Zanshin kit is portable. Install it in any workspace:
```bash
pi install git:https://github.com/hhellbusch/zanshin-pi-extension.git
```

It injects a minimal behavioral contract into every agent turn — collaboration style, failure mode awareness, slash commands for sparring and tracking — without loading large files into every prompt. Full practices are read on demand. This matters at context budget: the agent gets the discipline without burning tokens on content it doesn't need every turn.

The discipline layer solves "how do I make the agent consistently good" — not smarter, not more capable, just consistently aligned with how this work should be done.

### Layer 3: Workspace (Accumulated Context)

The workspace is the accumulated knowledge and tools that the agent builds over time. In this repo, it includes:

- **20+ essays** on AI-assisted engineering, philosophy, and ways of working
- **25+ case studies** documenting tools built, failures caught, and process decisions
- **100+ library entries** — enriched summaries and annotations from books, talks, and articles
- **Troubleshooting guides** across OpenShift, ArgoCD, RHACM, Ansible, and other infrastructure
- **Skills** for research, auditing, cross-linking, backlog management, YouTube analysis
- **Planning documents** — briefs, roadmaps, and phase plans for active projects

This layer is the compounding part. Each session adds to it; each session builds on it. It's what makes later sessions faster and better than earlier ones. Without it, the agent is just a smart editor with good documentation — useful, but not compounding.

The workspace layer solves "how does the work actually get better over time."

---

## How It Works in Practice

### Starting a session

```bash
cd /path/to/project
paude create session-name --agent pi --provider vertex --yolo --git
```

Paude:
1. Creates a container with Pi installed
2. Pushes the current workspace into the container
3. Sets up network filtering (allows only the domains the agent needs)
4. Injects Zanshin practices via the installed extension
5. Points the agent at the provider (Vertex AI, API key, etc.)

Pi has no built-in permission system — it doesn't ask before running commands. Zanshin's behavioral contract (adversarial review, verification discipline) provides the guardrails, not a yolo flag.

The agent now has access to:
- The full workspace — essays, case studies, skills, library, troubleshooting guides
- Zanshin practices — behavioral contract injected into every prompt
- Provider auth — ADC for Vertex, or API keys for other providers
- Network filtering — only allowed domains, preventing accidental data leakage

### Running a task

The agent reads the workspace context (essays explain the philosophy, case studies show what works, skills provide structured workflows). It works on whatever problem is in front of it. When done, it commits to git.

You harvest back:
```bash
paude harvest session-name -b feature/new-work
```

The agent's output is a git branch you can review, diff, and merge. Protected branch names (main, master, release) are blocked from harvest — you can't accidentally overwrite working code with agent output.

### Why the layers matter together

Drop any one layer and the system degrades:

- **Without runtime isolation**, the agent has unfettered filesystem access. No container boundary means no principled separation between "this is the agent" and "this is my work."
- **Without discipline**, the agent is a capable editor with no guardrails. It follows the prompt but doesn't check its assumptions, doesn't verify claims, doesn't track what it's decided.
- **Without accumulated context**, the agent is smart but ungrounded. It can write well-structured text but doesn't know what's been tried before, what's failed, what the actual patterns are.

All three are needed for the compounding effect. The runtime makes the agent safe to use. The discipline makes it consistently good. The workspace makes it better over time.

---

## Why This Matters

The default model for AI-assisted work is disposable. You open a chat, describe a problem, get output, close the tab. The work is done but nothing compounds. The next session starts from zero.

This architecture is for a different model: **AI work that adds up**. Where each session builds on the last. Where the agent knows what's been tried, what's failed, what practices are being followed. Where the skills, tools, and knowledge from one project are available in the next.

Is this the only way to do it? No. You can build cross-session continuity with handoff docs, prompt templates, and careful commit practices. You can install working discipline as Cursor rules or VS Code plugins. You can accumulate knowledge in a wiki or a reading list.

What this approach does is **package it all into a single unit that travels**. Not a set of practices you remember and try to reapply. Not a collection of files you hope you set up correctly. A containerized environment that comes with everything configured, tested, and ready to use.

When the container is built and the workspace is pushed, the agent isn't just "Claude Code with some files on disk." It's a configured system with a known behavioral contract, a known set of tools, and a known body of accumulated knowledge. You know what you're working with because you built it yourself.

---

## What You Get

Practical benefits, not abstract ones:

- **Isolated sessions** — experiment without risk. The agent can't touch your host files; the container boundary is the only boundary that matters
- **Git-based sync** — every agent output is a branch you can diff, review, and merge. No black-box changes
- **Reusable skills** — research pipelines, adversarial review, backlog management, YouTube analysis. Skills that work the same way in every workspace
- **Cross-session continuity** — the agent knows what's been tried, what's failed, what practices you follow. It doesn't start from zero
- **Fire-and-forget** — assign a task, disconnect, harvest later. No session tied up waiting
- **Agent flexibility** — swap between Claude Code, Gemini CLI, Cursor CLI, GitHub Copilot CLI, or Pi. Same container, same workspace, different agent
- **LLM backend flexibility** — swap between Vertex AI (Claude + Gemini), Anthropic API, Google AI, GitHub Copilot. Pi supports multiple backends natively; switch with a flag, no config rebuild needed

None of these are impossible without this architecture. They're all harder, more fragile, and require rebuilding for each new project.

---

## What This Is Not

**A product.** There's no roadmap, no versioning, no SLA. The Paude fork and Pi extensions work for this workspace — they may not work for yours, and they may change. This is a practitioner's toolkit, not a commercial offering.

**A pitch for you to adopt it.** The value is in understanding the architecture — why each layer exists, what problem it solves, how they fit together — not in copying the setup. The specific tools (Paude, Pi, Zanshin) are implementations of the pattern, not the pattern itself. You could replace any of them tomorrow; the architecture remains.

**An essay.** This document describes how something works, not why the underlying philosophy matters. For the philosophical framing — what AI means for engineering, learning, and ways of working — see [The Shift](the-shift.md) and [Ego, AI, and the Zen Antidote](../philosophy/ego-ai-and-the-zen-antidote.md).

---

## Where to Go From Here

- **[The Shift](the-shift.md)** — the foundational essay on what changes when AI handles implementation
- **[The Session Framework](session-framework.md)** — how the collaboration works, layer by layer
- **[Sparring and Shoshin](sparring-and-shoshin.md)** — two practical behaviors for catching the most common ways AI-assisted work goes wrong
- **[Zanshin — Portable Session Context](framework-bootstrap.md)** — how to install and use the working discipline kit in any project
- **[Paude Getting Started](paude-getting-started.md)** — the practical manual for running agents in containers

---

*This document was created with AI assistance and has not been fully reviewed by the author.*

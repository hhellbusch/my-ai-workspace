# AI-Assisted Engineering

Essays on using AI effectively in engineering work — skills, workflows, risks, and practical patterns.

## Essays

*These build on each other — [The Shift](the-shift.md) is the foundation, [The Meta-Development Loop](the-meta-development-loop.md) synthesizes the pattern. Each works as a standalone; the order matters if you're reading straight through.*

- **[The Shift — Engineering Skills in the Age of AI](the-shift.md)** — When AI handles implementation, the bottleneck moves. Covers the skills that matter more now (problem decomposition, systematic debugging, QA thinking, communication), the risks that come with AI adoption (sycophancy, ego reinforcement, erosion of critical thinking), and practical mitigations for engineers and leaders.

- **[Prompting Is Necessary but Not Sufficient](prompting-and-state.md)** — The standard advice on AI-assisted work centers on prompting skill. For single-session tasks, prompting is the primary lever. For work that spans multiple sessions, the harder problem is state management: what does the next session start from? Prompting determines quality within a session; state management determines whether sessions add up to coherent long-horizon work. Both compound together.

- **[AI-Assisted Development Workflows](ai-assisted-development-workflows.md)** — Transferable patterns for using AI coding assistants effectively; tool-specific paths (Copilot, Cursor, Claude Code) appear where they help you start. Examples skew to infrastructure (Ansible, Argo CD, Helm, Kubernetes). From *Beyond context sharing…* onward, this repository is also used as a **reference implementation** of multi-session habits — patterns to re-create with your own conventions, not a stack requirement.

- **[Using AI to Work Outside Your Expertise](ai-for-unfamiliar-domains.md)** — A real, step-by-step case study demonstrating the skills from *The Shift* in action. Someone uses AI to solve an image processing problem (recoloring animated GIFs) with zero prior domain knowledge, through iterative conversation. The implementation is trivial — the interesting part is the debugging and verification process.

- **[AI-Driven Continuous Improvement for Legacy Systems](ai-legacy-improvement.md)** — When AI compresses implementation cost, the economics of improvement change. Explores how conversational AI and exploratory "vibe coding" can unlock previously deprioritized work on legacy systems — frozen backlogs, undocumented processes, configuration drift, missing test coverage, and incremental modernization.

- **[AI-Assisted Open Source Contributions](ai-assisted-upstream-contributions.md)** — A framework for using AI to lower the barrier to upstream open source contribution while respecting maintainers and community norms. Includes a walkthrough of contributing to the argocd-diff-preview project and in-progress Helm chart improvements.

- **[The Meta-Development Loop](the-meta-development-loop.md)** — Names and teaches the engineering pattern behind building AI tools that improve AI workflows: notice a gap, build a tool, apply it immediately, let the output reshape the work. Synthesizes the pattern from 8 case studies, documents when it compounds productively and when it becomes infrastructure theater.

- **[Drop a YouTube Link, Get a Structured Analysis](youtube-video-analysis.md)** — A non-technical explainer for the YouTube transcript analysis workflow: how it works, what the output looks like (with a real example), and how it differs from asking an AI to "just summarize" a video. Includes a note on Copilot compatibility for colleagues on different tools.

- **[Running a Local LLM: Setup, Tradeoffs, and Real Electricity Cost](local-llm-setup.md)** — How to point Cursor and Claude Code at a locally-running model (Ollama, RamaLama, LM Studio, LiteLLM proxy), with **Qwen3** as the default family for DevOps/coding in this workspace. Covers hardware requirements, model selection (with measured tok/s on RX 7900 XT), electricity measurement methodology, and when local wins vs. cloud.
  - **[vLLM Reference: Server-Grade Local Inference](local-llm-vllm.md)** — Full vLLM install (NVIDIA CUDA + AMD ROCm), serve commands, Docker/Podman container setup, context window limits, the AMD FP8 MoE gap, `cursor agent` CLI limitation, and cluster topology. *(Technical companion to the setup guide — skip if you're not running your own inference server.)*

- **[What a Context Window Actually Is](what-a-context-window-actually-is.md)** — Three different figures appeared during a local LLM session: 32,768 (model self-report), 262,144 (training metadata), 14,592 (actual runtime allocation). Explains what each figure means, how KV cache allocation works, why MoE changes the picture, and why 14k and 1M context are qualitatively different rather than quantitatively comparable.

- **[Enterprise LLM Deployment on OpenShift AI — Summary](openshift-ai-llm-deployment-summary.md)** — Layered summary of Jared Burck's comprehensive architecture guide for self-hosting LLMs on OpenShift. Includes inline verification caveats with a link to the [full assessment](../../research/openshift-ai-llm-deployment/assessment.md). *(Specific to self-hosted enterprise infrastructure — skip if that's not your context.)*

- **[The Case for Local: Disk Management as a Privacy-First AI Task](local-llm-sysadmin.md)** — A case study of using a local LLM to diagnose and plan disk space cleanup. Covers why filesystem data is private by nature, the iterative `du → interpret → drill down → decide` loop, and what a recurring local disk agent would look like. Includes a table of when local beats cloud and the irony of AI experimentation being one of the fastest ways to fill a disk.

## Companion Guides

- **[The Session Framework — Patterns, Behaviors, and Why](session-framework.md)** — Human-facing map of the full collaboration framework: what each behavior defends against, how they connect, and the ethos behind them. Covers session orientation, handoffs, conversation stack tracking, adversarial pressure, structured session entries, and the meta-development loop. Start here if you want to understand the framework as a whole before reading the individual guides.

- **[Sparring and Shoshin — Two Practices for AI-Assisted Work](sparring-and-shoshin.md)** — Introduction to the two structural practices for resisting AI's characteristic failure modes: sparring (adversarial review) challenges outputs after drafting; shoshin (beginner's mind) challenges starting frames before work begins. Self-contained entry point; links to the deeper case studies and philosophy essays for each.

- **[Interaction Patterns for AI Sessions](interaction-patterns.md)** — Two structured patterns for AI-assisted work (the meta-prompt pipeline and the session-start briefing), the default unstructured mode, and how to choose between them. Covers the briefing guardrail (scope vs. state), the privacy-filtered handoff, and practical guidance for choosing between patterns.

- **[Zanshin — Portable Session Context (Bootstrap)](framework-bootstrap.md)** — Single-file entry point for loading the Zanshin framework into any AI tool. Clone this repository alongside a project, point your AI at this file, and operate with the framework's posture without Cursor-specific setup. Includes minimum viable load (four sentences), full behavioral dispositions, tool-specific loading instructions (Copilot, Claude Code, chat-based AI), and links to deeper reading.

- **[Cursor vs. Claude Code — Implementation Differences](cursor-vs-claude-code.md)** — Structural comparison of the two native implementations: where rules live, how commands are loaded, tool name differences, and known gaps. Reference when porting changes between environments or diagnosing behavioral divergence.

## Primary Narratives (Public)

- **Dan Walsh — *Lessons learned with a career in software?*** (DevConf.US 2025) — [YouTube](https://www.youtube.com/watch?v=YKDi-ePTmRA). Full transcript and theme index: [`research/ai-engineering-public/sources/youtube-YKDi-ePTmRA-transcript.md`](../../research/ai-engineering-public/sources/youtube-YKDi-ePTmRA-transcript.md), [`library/dan-walsh-devconf-2025-career-lessons.md`](../../library/dan-walsh-devconf-2025-career-lessons.md). Useful as a **public** anchor for security-through-containers history, mentorship/succession, and late-career AI tooling (e.g. RamaLama) without relying on private correspondence.
- **Anonymized collaboration patterns** — [`research/ai-engineering-public/motivation-patterns-paraphrase.md`](../../research/ai-engineering-public/motivation-patterns-paraphrase.md). Paraphrased **ideas** only (stacked assistants, async delegate, issue-first work, review-loop closure); no private quotations — for essays and ethos alongside the workflows guide.

## Cross-Track Links

- *The Shift* sections 6-7 (sycophancy, ego reinforcement, anchoring, self-reinforcing infrastructure) connect to [Ego, AI, and the Zen Antidote](../philosophy/ego-ai-and-the-zen-antidote.md) in the philosophy track
- The meta-development loop is demonstrated by every case study in the [case-studies track](../case-studies/) — the essay synthesizes the pattern, the case studies show it in action
- *AI-Assisted Development Workflows* section 2 (multi-session management) connects to [Debugging AI Judgment](../case-studies/debugging-ai-judgment.md), [Evolving Creative Scope](../case-studies/evolving-creative-scope.md), and [Building Knowledge Management](../case-studies/building-knowledge-management-with-ai.md)

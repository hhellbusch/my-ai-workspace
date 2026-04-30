# Source Manifest

**Subject:** AI Engineering Talks — April 2026 (AI Engineer London + Sequoia Capital)
**Analysis started:** 2026-04-30
**Total sources:** 3 transcripts

---

## Sources

| ref_id | url | status | file | notes |
| --- | --- | --- | --- | --- |
| ref-01 | https://www.youtube.com/watch?v=am_oeAoUhew | fetched | sources/harness-engineering-how-to-build-software-when-humans-steer-agents-execute-ryan-.md | Ryan Lopopolo, OpenAI — Harness Engineering keynote + Q&A — AI Engineer London |
| ref-02 | https://www.youtube.com/watch?v=rmvDxxNubIg | fetched | sources/no-vibes-allowed-solving-hard-problems-in-complex-codebases-dex-horthy-humanlaye.md | Dex Horthy, HumanLayer — No Vibes Allowed — AI Engineer London |
| ref-03 | https://www.youtube.com/watch?v=96jN2OCOfLs | fetched | sources/andrej-karpathy-from-vibe-coding-to-agentic-engineering.md | Andrej Karpathy — From Vibe Coding to Agentic Engineering — Sequoia Capital interview |

---

## Claims — ref-01: Ryan Lopopolo, Harness Engineering

| claim_id | type | assertion |
| --- | --- | --- |
| R-C1 | Framework | "Code is free" — implementation is no longer the scarce resource; the scarce resources are human time, human/model attention, and context window |
| R-C2 | Factual | GPT 5.2 was the inflection point — models now "isomorphic" to humans in ability to produce high-quality code in real codebases |
| R-C3 | Framework | Labs post-train models specifically in the context of their first-party harnesses (e.g., Codex) — there is leverage in depending on them directly |
| R-C4 | Framework | Every time a human must interact with (type "continue" to) an agent is a failure of the harness to provide sufficient context |
| R-C5 | Framework | Code is a disposable build artifact; LLM is a "fuzzy compiler"; codebase constraints are optimization passes |
| R-C6 | Factual | Token spend breakdown: ~1/3 planning/ticket curation, 1/3 documentation/implementation, 1/3 CI |
| R-C7 | Framework | Reviewer agents (per persona: front-end, reliability, security) triggered on every push are how you automate human code review feedback back into the repo |

## Claims — ref-02: Dex Horthy, No Vibes Allowed

| claim_id | type | assertion |
| --- | --- | --- |
| D-C1 | Factual | Eigor surveyed 100,000 developers and found most AI-assisted software engineering produces rework/churn rather than net-new progress — especially in brownfield codebases |
| D-C2 | Factual | Team of 3 achieved 2–3x throughput after 8 weeks of retooling their workflow around context engineering |
| D-C3 | Framework | ~40% context window fill is the "dumb zone" threshold — diminishing returns begin around that mark (Claude Code as reference model) |
| D-C4 | Framework | Sub-agents are for controlling context, not for anthropomorphizing roles (front-end sub-agent, QA sub-agent, etc. is an anti-pattern) |
| D-C5 | Framework | Research → Plan → Implement keeps context small and quality high; compaction at each phase boundary |
| D-C6 | Framework | "AI cannot replace thinking. It can only amplify the thinking you have done or the lack of thinking you have done." |
| D-C7 | Framework | "Spec-driven development" is semantically diffused to the point of uselessness — semantic diffusion is a structural risk for any useful term in AI engineering |

## Claims — ref-03: Andrej Karpathy, Vibe Coding to Agentic Engineering

| claim_id | type | assertion |
| --- | --- | --- |
| K-C1 | Factual | December 2025 was the clear inflection point for agentic coding workflows becoming reliably functional |
| K-C2 | Framework | Software 1.0 = explicit code; 2.0 = neural network weights; 3.0 = prompts/context window — a new computing paradigm, not just faster coding |
| K-C3 | Architectural | LLMs automate what is verifiable — jagged capability profile follows verifiability + what labs happen to prioritize in training data |
| K-C4 | Framework | Vibe coding raises the floor for everyone; agentic engineering preserves the professional quality bar — these are distinct disciplines |
| K-C5 | Predictive | The 10x engineer multiplier is understated — good agentic engineers peak significantly more than 10x |
| K-C6 | Framework | "You can outsource your thinking but you can't outsource your understanding" — direction and taste remain the human bottleneck |
| K-C7 | Predictive | Everything currently written for humans must be rewritten agent-native; current infrastructure (docs, deployment, services) is fundamentally human-oriented |

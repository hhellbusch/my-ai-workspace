# AI-Assisted Engineering

Essays on using AI effectively in engineering work — skills, workflows, risks, and practical patterns.

## Reading Order

1. **[The Shift — Engineering Skills in the Age of AI](the-shift.md)** — When AI handles implementation, the bottleneck moves. Covers the skills that matter more now (problem decomposition, systematic debugging, QA thinking, communication), the risks that come with AI adoption (sycophancy, ego reinforcement, erosion of critical thinking), and practical mitigations for engineers and leaders.

2. **[AI-Assisted Development Workflows](ai-assisted-development-workflows.md)** — Practical, tool-agnostic patterns for using AI coding assistants effectively in infrastructure and platform engineering work. Covers daily editor workflows, context sharing across sessions, GitOps and Ansible patterns, and the meta-development system (Skills, Commands, Agents).

3. **[Using AI to Work Outside Your Expertise](ai-for-unfamiliar-domains.md)** — A real, step-by-step case study demonstrating the skills from *The Shift* in action. An infrastructure engineer uses AI to solve an image processing problem (recoloring animated GIFs) with zero prior domain knowledge, through iterative conversation.

4. **[AI-Driven Continuous Improvement for Legacy Systems](ai-legacy-improvement.md)** — When AI compresses implementation cost, the economics of improvement change. Explores how conversational AI and exploratory "vibe coding" can unlock previously deprioritized work on legacy systems — frozen backlogs, undocumented processes, configuration drift, missing test coverage, and incremental modernization.

5. **[Enterprise LLM Deployment on OpenShift AI — Summary](openshift-ai-llm-deployment-summary.md)** — Layered summary of Jared Burck's comprehensive architecture guide for self-hosting LLMs on OpenShift. Includes inline verification caveats with a link to the [full assessment](../../research/openshift-ai-llm-deployment/assessment.md). Based on the [full article](https://jaredburck.me/blog/openshift-ai-llm-enterprise-deployment/).

6. **[AI-Assisted Open Source Contributions](ai-assisted-upstream-contributions.md)** — A framework for using AI to lower the barrier to upstream open source contribution while respecting maintainers and community norms. Includes a walkthrough of contributing to the argocd-diff-preview project and in-progress Helm chart improvements.

7. **[The Meta-Development Loop](the-meta-development-loop.md)** — Names and teaches the engineering pattern behind building AI tools that improve AI workflows: notice a gap, build a tool, apply it immediately, let the output reshape the work. Synthesizes the pattern from 8 case studies, documents when it compounds productively and when it becomes infrastructure theater.

## Cross-Track Links

- *The Shift* sections 6-7 (sycophancy, ego reinforcement, anchoring, self-reinforcing infrastructure) connect to [Ego, AI, and the Zen Antidote](../philosophy/ego-ai-and-the-zen-antidote.md) in the philosophy track
- The meta-development loop is demonstrated by every case study in the [case-studies track](../case-studies/) — the essay synthesizes the pattern, the case studies show it in action
- *AI-Assisted Development Workflows* section 2 (multi-session management) connects to [Debugging AI Judgment](../case-studies/debugging-ai-judgment.md), [Evolving Creative Scope](../case-studies/evolving-creative-scope.md), and [Building Knowledge Management](../case-studies/building-knowledge-management-with-ai.md)

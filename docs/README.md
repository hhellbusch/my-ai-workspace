# Docs

Shared documentation on AI-assisted engineering and practical patterns.

## Contents

Start here and read in order, or jump to what's relevant.

1. **[The Shift — Engineering Skills in the Age of AI](the-shift.md)** — When AI handles implementation, the bottleneck moves. Covers the skills that matter more now (problem decomposition, systematic debugging, QA thinking, communication), the risks that come with AI adoption (sycophancy, ego reinforcement, erosion of critical thinking), and practical mitigations for engineers and leaders.

2. **[AI-Assisted Development Workflows](ai-assisted-development-workflows.md)** — Practical, tool-agnostic patterns for using AI coding assistants effectively in infrastructure and platform engineering work. Covers daily editor workflows, context sharing across sessions, GitOps and Ansible patterns, and the meta-development system (Skills, Commands, Agents).

3. **[Using AI to Work Outside Your Expertise](ai-for-unfamiliar-domains.md)** — A real, step-by-step case study demonstrating the skills from *The Shift* in action. An infrastructure engineer uses AI to solve an image processing problem (recoloring animated GIFs) with zero prior domain knowledge, through iterative conversation.

4. **[AI-Driven Continuous Improvement for Legacy Systems](ai-legacy-improvement.md)** — When AI compresses implementation cost, the economics of improvement change. Explores how conversational AI and exploratory "vibe coding" can unlock previously deprioritized work on legacy systems — frozen backlogs, undocumented processes, configuration drift, missing test coverage, and incremental modernization.

5. **[Enterprise LLM Deployment on OpenShift AI — Summary](openshift-ai-llm-deployment-summary.md)** — Layered summary of Jared Burck's comprehensive architecture guide for self-hosting LLMs on OpenShift. Executive overview at the top, architecture decision matrices in the middle, practitioner detail at the bottom. Includes inline verification caveats for economic claims and maturity assertions, with a link to the [full assessment](../research/openshift-ai-llm-deployment/assessment.md). Based on the [full article](https://jaredburck.me/blog/openshift-ai-llm-enterprise-deployment/).

6. **[Building a Research and Verification Skill](building-a-research-skill.md)** — Meta case study documenting how a failed manual verification attempt led to building a reusable research automation skill. Covers the problem discovery, skill design, fetcher engineering, parallel analysis architecture, and a validation run that verified 53 of 62 cited sources across 8 parallel analysis batches. Connects back to patterns from *The Shift* and *AI-Assisted Development Workflows*.

7. **[AI-Assisted Open Source Contributions](ai-assisted-upstream-contributions.md)** — A framework for using AI to lower the barrier to upstream open source contribution while respecting maintainers and community norms. Covers disclosure, quality, and engagement as three pillars of responsible contribution. Includes a walkthrough of contributing to the argocd-diff-preview project (issue-first pattern leading to a new feature in v0.2.2) and a second example of in-progress Helm chart improvements.

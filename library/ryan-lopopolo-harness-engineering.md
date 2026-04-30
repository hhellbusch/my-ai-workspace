# Ryan Lopopolo — Harness Engineering: How to Build Software When Humans Steer, Agents Execute

## Source

- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=am_oeAoUhew
- **Event:** AI Engineer World's Fair (London, 2026)
- **Duration:** 46:15 (keynote + Q&A)
- **Published:** 2026
- **Transcript:** [cached](../research/ai-engineering-talks-apr-2026/sources/harness-engineering-how-to-build-software-when-humans-steer-agents-execute-ryan-.md)

## About the Speaker

Ryan Lopopolo is a Member of Technical Staff at OpenAI. For nine months prior to this talk, he built software exclusively with coding agents — his team was banned from touching editors directly. He spends over a billion output tokens per day (~$1,000+/day), earning the self-described title "token billionaire." He wrote a companion piece called "Harness Engineering" and was featured on the Latent Space podcast.

## Key Themes

- **Code is free** — Implementation is no longer the scarce resource. The scarce resources are: human time, human/model attention, and model context window. Engineers should think like staff engineers delegating to an infinitely parallel team.
- **The harness is the job** — Building the structures, documentation, lint rules, review agents, and CI that give agents the right context at the right time. The harness shouldn't do more than surface instructions to the model; do the minimum needed and let model capability handle the rest.
- **Just-in-time context injection** — Don't frontload all requirements. Let the agent work, then surface constraints via failing lints or test time. React components should be free to prototype first; decomposition requirements surface at lint/test time, not in the system prompt.
- **Reviewer agents as the quality loop** — Persona-keyed review agents (front-end architect, reliability engineer, security) trigger on every push, check the proposed patch against persona documentation, and surface blockers. This converts synchronous human code review feedback into durable, automatically-surfaced documentation.
- **Garbage collection day** — One day per week where the team takes every slop pattern observed during the week and categorically eliminates it: review feedback → document → lint/test/reviewer agent. This is how you close the loop.
- **Code as disposable build artifact** — The LLM is a "fuzzy compiler." The constraints and documentation in the repo are the optimization passes. Swapping models is like swapping code generation backends — the spec should produce acceptable output regardless.
- **Every agent interaction is a harness failure** — If you have to type "continue" to an agent, the harness didn't give it enough context to finish. The goal is 50 agents running 24/7 with no human button-clicks.

## Notable Ideas

> "The important thing is not the code but the prompt and the guardrails that got you there."

> "Every time I have to type 'continue' to the agent is a failure of the harness to provide enough context around what it means to continue to completion."

> "Is code a disposable build artifact?" "Yes."

> "All the leverage you're encoding into your repository, your team, and the agents in this way stacks incredibly well."

**The bitter lesson applied to harnesses:** Don't over-engineer harnesses around today's model quirks. The harness should be about giving the model the right text at the right time — that won't be obsoleted by model improvements. Detailed mechanical workarounds will be.

**File size as a context constraint:** Lopopolo enforces a structural test limiting files to 350 lines — adapting the codebase to the model's attention constraints, not the other way around.

**Token split:** Roughly 1/3 each across: planning/ticket curation/documentation, implementation, and CI work.

## Connections to This Workspace

### Direct alignment with this workspace's tooling

The harness engineering practice described here is functionally identical to what this workspace does: CLAUDE.md, `.cursor/rules/`, skills, and review hooks are the harness. The insight that "every bit of leverage stacks" maps directly to the compound value observed when skills, rules, and documentation accumulate.

### Context as the durable abstraction

Lopopolo's thesis — that context management won't be obsoleted by model improvements — matches this workspace's approach of investing heavily in structured context (CLAUDE.md, .cursorrules, shoshin, session framework) rather than relying on ad-hoc prompting.

### Reviewer agents → this workspace's pre-commit review behavior

The persona-keyed reviewer agents described here are the CI/CD version of the pre-commit review described in CLAUDE.md. Both solve the same problem: converting implicit human review knowledge into durable, always-running, automatically-surfaced feedback.

### The "garbage collection day" rhythm

The weekly elimination of slop patterns maps to the checkpoint/backlog capture rhythm in this workspace — don't let compounding failures accumulate; address them at the root when observed.

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

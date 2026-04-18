# Case Studies

Documented examples of meta-development patterns, workflow decisions, and AI-assisted processes in action. Each case study traces a real piece of work from this repository — what happened, what pattern it demonstrates, and what it connects to.

## Published

1. **[Building a Research and Verification Skill](building-a-research-skill.md)** — Meta case study documenting how a failed manual verification attempt led to building a reusable research automation skill. Covers the problem discovery, skill design, fetcher engineering, parallel analysis architecture, and a validation run that verified 53 of 62 cited sources across 8 parallel analysis batches.

2. **[Adversarial Review as a Meta-Development Pattern](adversarial-review-meta-development.md)** — How the absence of pushback in an AI-assisted essay workflow led to building a reusable sparring system (`/spar` command, spar pipeline stage, zero-base de-biasing), immediately applying it to the ego/AI essay, and watching the output feed back into the content it was critiquing.

3. **[Debugging Your AI Assistant's Judgment](debugging-ai-judgment.md)** — A user noticed the AI was anchoring on prior priorities during re-prioritization — a systematic behavioral flaw, not a one-off error. Naming the mechanism led to a structural fix (zero-base evaluation) and a deeper connection to the project's philosophical thesis on ego and non-attachment.

## Planned

See `BACKLOG.md` for case study seeds (items with `Case study:` title prefix). Current candidates:

- From conversation to essay in one session
- Building a personal knowledge management system with AI
- How AI handles evolving creative scope across sessions
- Choosing scripts over services — the YouTube transcript decision

# Dex Horthy — No Vibes Allowed: Solving Hard Problems in Complex Codebases

## Source

- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=rmvDxxNubIg
- **Event:** AI Engineer World's Fair (London, 2026)
- **Duration:** 20:32
- **Published:** 2026
- **Transcript:** [cached](../research/ai-engineering-talks-apr-2026/sources/no-vibes-allowed-solving-hard-problems-in-complex-codebases-dex-horthy-humanlaye.md)

## About the Speaker

Dex Horthy is co-founder at HumanLayer, building an agentic IDE to help teams reach 99% AI-generated code. His prior AI Engineer talk "12 Factor Agents" (June 2025) was one of the most-watched from that event. He coined or popularized "context engineering" as a discipline. His "no slop" system (research → plan → implement prompts) went viral on HackerNews and has been adopted by thousands of teams.

## Key Themes

- **Context engineering as the core discipline** — The most naive way to use a coding agent is to steer it by correction in a single context window until you run out of tokens or give up. Everything after that is context engineering: intentional compaction, fresh starts, sub-agents, research → plan → implement.
- **The dumb zone** — Beyond ~40% context window fill (using Claude Code as reference), you start seeing diminishing returns. Too many MCPs or verbose tool outputs mean you're doing all your work in the dumb zone. The whole workflow should be built around staying in the smart zone.
- **Sub-agents are for context control, not role-play** — "If you have a front-end sub-agent and a backend sub-agent and a QA sub-agent, please stop." Sub-agents fork a fresh context window to do expensive searching/reading, then return a succinct message. They control context, not organizational structure.
- **Research → Plan → Implement (RPI)** — Frequent intentional compaction at each phase boundary. Research: understand the system, find the right files. Plan: outline exact steps with file names and line snippets, include test criteria. Implement: execute from the plan with minimal context. The plan serves as a compaction artifact.
- **Mental alignment is what code review is actually for** — Code review isn't primarily about catching bugs; it's about keeping the team on the same page about how the codebase is changing and why. At 2–3x shipping velocity, maintaining mental alignment requires sharing plans (not just diffs) so technical leads can stay oriented without reading every line.
- **Don't outsource the thinking** — AI amplifies the thinking you've done (or the lack of it). A bad line in the research misunderstands the system and sends the model in the wrong direction. A bad line in the plan can generate 100 bad lines of code. Human effort should concentrate at the highest-leverage points in the pipeline: verifying research accuracy and approving plans.
- **Semantic diffusion kills useful terms** — "Spec-driven development" is already dead as a term because it means everything from "better prompt" to "PRD" to "markdown file." The same will happen to any precise concept that gets popular. Practitioners need to define their own terms and hold them precisely.

## Notable Ideas

> "AI cannot replace thinking. It can only amplify the thinking you have done or the lack of thinking you have done."

> "A bad line of research — a misunderstanding of how the system works — and your whole thing is going to be hosed."

> "The more you use the context window, the worse outcomes you'll get." — Jeff Huntley, cited by Horthy

> "There will never be a year of agents because of semantic diffusion." — citing Martin Fowler (2006) on how good terms get diluted to uselessness.

**Trajectory matters:** If you correct an agent repeatedly for making the same mistake, the context now contains a pattern of "I made an error → human corrected me → I made an error → human corrected me." The model predicts the pattern continues. Start fresh; don't accumulate a failure trajectory.

**On-demand compressed context vs. static onboarding docs:** Static CLAUDE.md/AGENTS.md files for large repos eventually become lies — they drift from the codebase truth. Prefer on-demand research: launch sub-agents to take vertical slices through the relevant parts of the codebase and generate a snapshot. "We are compressing truth."

**Plans should include actual code snippets:** Not just descriptions of changes, but the actual code expected to change. If you can read the plan and a junior model would get it right, the plan is good.

## Connections to This Workspace

### RPI maps to this workspace's planning habit

The research → plan → implement structure described here is structurally identical to what this workspace does with `.planning/` briefs, session checkpoints, and the create-plans skill. The insight that bad research poisons the plan and bad plans poison the implementation maps directly to why the workspace invests in briefs before execution.

### "Dumb zone" explains context management in long sessions

The 40% threshold concept explains observed behavior in long Cursor sessions: the workspace's CLAUDE.md note to "re-read files before deciding — don't trust in-context memory in long sessions" is a behavioral response to this same phenomenon. Compaction (the `/checkpoint` command) is the equivalent of Horthy's intentional compaction.

### Mental alignment and the shoshin practice

Horthy's emphasis on mental alignment — keeping the team's mental model of the codebase consistent — has a direct parallel in the shoshin practice: "before trusting a handoff or summary, check the authoritative scope document." Both are about preventing the accumulated drift between what someone thinks the system does and what it actually does.

### Don't outsource the thinking

This aligns with the workspace's human-owned verification posture (from `.cursorrules`): "speed without mistaking fluency for truth." Horthy's point that AI only amplifies the thinking you've done is the same observation — the human's conceptual clarity is the ceiling, not the floor.

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

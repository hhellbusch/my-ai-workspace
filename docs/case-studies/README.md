# Case Studies

Documented examples of meta-development patterns, workflow decisions, and AI-assisted processes in action. Each case study traces a real piece of work from this repository — what happened, what pattern it demonstrates, and what it connects to.

## Published

1. **[Building a Research and Verification Skill](building-a-research-skill.md)** — Meta case study documenting how a failed manual verification attempt led to building a reusable research automation skill. Covers the problem discovery, skill design, fetcher engineering, parallel analysis architecture, and a validation run that verified 53 of 62 cited sources across 8 parallel analysis batches.

2. **[Adversarial Review as a Meta-Development Pattern](adversarial-review-meta-development.md)** — How the absence of pushback in an AI-assisted essay workflow led to building a reusable sparring system (`/spar` command, spar pipeline stage, zero-base de-biasing), immediately applying it to the ego/AI essay, and watching the output feed back into the content it was critiquing.

3. **[Debugging Your AI Assistant's Judgment](debugging-ai-judgment.md)** — A user noticed the AI was anchoring on prior priorities during re-prioritization — a systematic behavioral flaw, not a one-off error. Naming the mechanism led to a structural fix (zero-base evaluation) and a deeper connection to the project's philosophical thesis on ego and non-attachment.

4. **[From Conversation to Essay in One Session](conversation-to-essay.md)** — Traces how a single conversational observation ("what if Zen concepts help with the AI sycophancy problem?") turned into a published essay with source provenance and adversarial review in one session. Demonstrates the full write-challenge-revise cycle and how project infrastructure compounds.

5. **[Choosing Scripts Over Services](choosing-scripts-over-services.md)** — A small architectural decision — MCP server vs. Python script for YouTube transcripts — that demonstrates problem decomposition and workflow-fit thinking. The simpler tool won because it fit the file-based research workflow without adaptation.

6. **[Building a Personal Knowledge Management System with AI](building-knowledge-management-with-ai.md)** — How one extended session produced six interlocking organizational tools (backlog, library, session orientation, pre-commit review, content audit, cross-linking) and what it reveals about AI building the infrastructure for its own productivity.

7. **[How AI Handles Evolving Creative Scope Across Sessions](evolving-creative-scope.md)** — A project broadened from "Zen and Karate" to "Martial Arts, Zen, and the Way of Working" as the user's learning expanded mid-project. Documents how scope changes cascade through planning documents, what conventions help maintain coherence, and what's still missing.

8. **[When Case Studies Generate System Improvements](case-studies-as-discovery.md)** — Writing the evolving-scope case study surfaced three concrete gaps. The user noticed the philosophical connection (shoshin) was a design principle, not just an observation. That led to five system enhancements. The case study format itself became a discovery mechanism.

9. **[When AI Fabricates the Evidence for Its Own Argument](fabricated-references.md)** — AI fabricated a plausible Anthropic URL while defining sycophancy — demonstrating a related failure mode in the same paragraph it was being explained. The fix addressed both the immediate 404 and the systemic gap: external URL verification in the cross-linking rule and pre-commit review.

10. **[Who Is Speaking? — When AI Writes in Your Voice](who-is-speaking.md)** — A concern about AI-generated biographical claims — professional titles, experience statements, personal opinions readers attribute to the author — led to a new `voice-approved` validation type integrated at generation, commit, audit, and validation checkpoints. The distinction: reading content and approving content that speaks *as you* are different acts.

11. **[When AI Ignores Changes Made by Other Sessions](stale-context-in-long-sessions.md)** — An AI agent removed the backlog archive system, then another session restored it. The first agent continued editing based on its stale model, overwriting the rolling cap and exceeding the item limit. Explores anchoring on session memory vs. repository state, and why the existing shoshin rule needed broader application.

12. **[When the Safety Net Is Too Heavy to Use](heavy-safety-nets.md)** — A pre-commit review process designed to catch everything was too heavy for small changes, so it got skipped — silently invalidating a reviewed file across three commits. The fix: scaled review depth, three-layer staleness detection, and SHA-based "diff since last review" for precise re-review.

13. **[When the Source Says the Opposite of the Claim](context-stripped-citations.md)** — A cited economic claim (11B token/month breakeven) was real and the source existed, but the source's conclusion was the *opposite* of how the article used it. The source argues API wins for 87% of cases; the article presented the number as supporting self-hosting economics. Traces the propagation chain through article, AI summary, and essay — and why context stripping is harder to catch than fabrication.

14. **[The Landscape Pass — Assess All Threads Before Drafting Any](landscape-before-depth.md)** — A creative project with 16 essay threads had deep research accumulated and a strong drafting urge. Instead of starting with the most interesting thread, all 16 were assessed in one pass first. What the aerial view revealed: a structural contradiction between two threads that was invisible from inside either, a 20/80 practitioner-to-research ratio that would have produced the wrong kind of essay, and merge candidates that per-thread drafting would have missed. The pattern: landscape assessment before depth.

15. **[What the Corpus Sees That the Document Can't](corpus-level-spar.md)** — After 13 case studies and several essays, each reviewed on its own terms, a spar was run across the entire collection simultaneously. Per-document review asks "is this document right?" Corpus review asks "what does this collection claim about the world?" The corpus found scope overclaims in the reading path, a conditional universal in the cornerstone essay, a missing theater-detection check, and an incomplete sycophancy model. Documents can be individually coherent while collectively misleading.

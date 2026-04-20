# Case Studies

Documented examples of meta-development patterns, workflow decisions, and AI-assisted processes in action. Each case study traces a real piece of work from this repository — what happened, what pattern it demonstrates, and what it connects to.

**Survivorship note:** Every case study here documents something that was noticed, named, and addressed. Sessions that produced net losses without useful recovery, work that had to be abandoned, or tools that made things worse without a recoverable fix are not represented — not because they didn't happen, but because a clean failure record didn't emerge. This is a selection effect worth naming. The `failure` label below means *AI failure mode that was caught and fixed*, not *unrecovered loss*.

**Attribution convention:** Where the human contribution is clearly traceable — a specific observation, question, or judgment that the AI could not have originated — case studies include a `## What the Human Brought` section before the artifacts table. Where the record isn't clear, that section is omitted rather than manufactured. New case studies should include it when the human's contribution is documentable.

**Scope convention:** Workflow and process case studies (the `workflow` label) should include a `## When This Applies — and When It Doesn't` section. Unlike build and failure case studies, where the scope is bounded by the gap and the fix, workflow patterns have fuzzier applicability — naming when the pattern helps and when it's overhead makes the case study transferable rather than just descriptive.

**Labels:** `build` — built a tool or system from a gap · `failure` — AI failure mode and its fix · `workflow` — process discipline or design decision

## Building Tools and Systems

1. `build` **[Building a Research and Verification Skill](building-a-research-skill.md)** — Manual source verification failed; the fix was a reusable research skill that fetched and analyzed 53 of 62 cited sources across 8 parallel batches. Covers the problem discovery, skill design, fetcher engineering, and parallel analysis architecture.

2. `build` **[Adversarial Review as a Meta-Development Pattern](adversarial-review-meta-development.md)** — The essay workflow had no structural pushback. Built a `/spar` command, a spar pipeline stage, and zero-base de-biasing — then applied all three immediately and watched the output feed back into the content it was critiquing.

3. `build` **[Debugging Your AI Assistant's Judgment](debugging-ai-judgment.md)** — Re-prioritization always confirmed existing priorities — a systematic behavioral flaw, not a one-off error. Naming the anchoring mechanism led to a structural fix (zero-base evaluation) and a connection to the philosophical thesis on ego and non-attachment.

4. `build` **[Building a Personal Knowledge Management System with AI](building-knowledge-management-with-ai.md)** — One extended session produced six interlocking organizational tools (backlog, library, session orientation, pre-commit review, content audit, cross-linking). What it reveals about AI building the infrastructure for its own productivity.

5. `build` **[When Case Studies Generate System Improvements](case-studies-as-discovery.md)** — Writing the evolving-scope case study surfaced three concrete gaps; the user noticed the philosophical connection (shoshin) was a design principle, and it produced five system enhancements. The case study format as discovery mechanism — with a pass/fail test for when reflection becomes theater.

## AI Failure Modes

6. `failure` **[When AI Fabricates the Evidence for Its Own Argument](fabricated-references.md)** — AI fabricated a plausible Anthropic URL while defining sycophancy — in the same paragraph the failure mode was being explained. Fix: external URL verification rule and pre-commit review step.

7. `failure` **[Who Is Speaking? — When AI Writes in Your Voice](who-is-speaking.md)** — AI-generated biographical claims speak as the author, not about the author. Reading content and approving content that speaks *as you* are different acts. Led to a `voice-approved` validation type integrated at every workflow checkpoint.

8. `failure` **[When AI Ignores Changes Made by Other Sessions](stale-context-in-long-sessions.md)** — One agent removed the backlog archive system; another restored it; the first agent continued editing from its stale model, overwriting the rolling cap. Explores anchoring on session memory vs. repository state.

9. `failure` **[When the Source Says the Opposite of the Claim](context-stripped-citations.md)** — A cited economic number was real and the source existed, but the source's conclusion was the reverse of how the article used it. Traces the propagation chain through article, AI summary, and essay — and why context stripping is harder to catch than fabrication.

10. `failure` **[When the Sparring Partner Shapes the Fighter](spar-distortion.md)** — The spar that generated the essay also distorted its framing — oppositional structure when the author's position was extension. The same tool that catches bias created it. Self-spar caught the mismatch; the fix was reframing from "I disagree" to "I agree AND."

11. `failure` **[When How-To Instructions Outlive the Interface](decayed-how-to.md)** — AI described a YouTube UI step confidently from training data; the author couldn't find the button. Distinct from fabricated references (invented vs. decayed); same root — AI asserting time-sensitive information without flagging it can't verify currency. Fix: route around the UI dependency entirely using the transcript API.

## Workflow and Process Decisions

12. `workflow` **[From Conversation to Essay in One Session](conversation-to-essay.md)** — A single conversational observation turned into a published essay with source provenance and adversarial review in one session. Demonstrates the full write-challenge-revise cycle and how project infrastructure compounds.

13. `workflow` **[Choosing Scripts Over Services](choosing-scripts-over-services.md)** — MCP server vs. Python script for YouTube transcripts. The simpler tool won because it fit the file-based research workflow without adaptation. Demonstrates problem decomposition and workflow-fit thinking.

14. `workflow` **[How AI Handles Evolving Creative Scope Across Sessions](evolving-creative-scope.md)** — A project broadened mid-session as the user's research expanded. Documents how scope changes cascade through planning documents, what conventions help maintain coherence, and what's still missing.

15. `workflow` **[When the Safety Net Is Too Heavy to Use](heavy-safety-nets.md)** — A pre-commit review requiring 11 steps for every commit got skipped for small changes, silently invalidating a reviewed file. Fix: scaled review depth, three-layer staleness detection, SHA-based "diff since last review."

16. `workflow` **[The Landscape Pass — Assess All Threads Before Drafting Any](landscape-before-depth.md)** — A 16-thread creative project had research ready and a drafting urge. Assessing all threads first revealed a structural contradiction between two threads, a 20/80 practitioner-to-research ratio, and merge candidates invisible from inside any single thread.

17. `workflow` **[What the Corpus Sees That the Document Can't](corpus-level-spar.md)** — Sparring the full essay collection simultaneously caught scope overclaims, conditional universals, and framing drift that per-document review had missed. Documents can be individually coherent while collectively misleading.

18. `workflow` **[When a Spar Argument Outgrows Its Essay](spar-to-essay-pipeline.md)** — A single adversarial argument (#9) escalated from counter-position through voice inputs to a new thesis, a new thread, and a fully drafted essay in one session. Spar as generative pressure, not just quality gate.

19. `failure` **[When the Model Describes a Configuration It Isn't Running](model-self-report-runtime-state.md)** — A model asked about its context window reported 32,768 tokens. The actual runtime value was 14,592. The model wasn't fabricating — the number exists in its training data. It answered a runtime question with a training-time answer. Documents the mechanism, the fix (startup logs over self-report), and the broader pattern: models cannot observe their own runtime state.

20. `failure` **[When the Survivor Becomes the Recommendation](survivorship-bias-recommendations.md)** — After a sequence of failures (FP8 MoE unsupported, AWQ at 1k context, dense 32B OOM), the one model that loaded was labeled "the recommended default." The AI wasn't wrong about what worked. It was wrong about what that means. Documents how elimination framing gets dressed as quality selection, and how to write survivorship-honest recommendations.

21. `workflow` **[The Experiment That Can't Use Its Own Findings](experiment-cant-use-findings.md)** — A full session characterized the limits of a 14k-context local model. The journal, guide, sparring notes, and case studies that document those limits were produced using the large-context frontier capabilities those limits exclude. The data is real; the meta-work required a different tool. Also names the self-referential problem: this observation was made by the tool that benefits from the conclusion.

22. `workflow` **[What Survives a Crash](session-crash-recovery.md)** — A 511-message session crashed mid-renumber. The artifact trail (commits, journals, JSONL transcript) enabled partial recovery; the working context did not. Documents what is and isn't recoverable, and how conventions built for human handoff between sessions also function as crash recovery infrastructure.

23. `workflow` **[When the Bus Is the Bottleneck](graph-splits-hybrid-inference.md)** — A 72B model loaded successfully across GPU and system RAM, then took six minutes to produce a first token. The constraint wasn't capacity — it was 718 PCIe bus crossings per prefill batch. Documents why RAM quantity doesn't rescue hybrid inference at scale, and where the actual throughput ceiling is.

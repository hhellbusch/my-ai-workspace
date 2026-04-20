# Docs

Essays and case studies across three tracks — AI-assisted engineering, philosophy and practice, and documented case studies from the meta-development process itself.

## Tracks

### [AI-Assisted Engineering](ai-engineering/)

Skills, workflows, risks, and practical patterns for using AI effectively in engineering work. Eight essays covering the foundational thesis, daily workflows, working outside expertise, legacy systems, enterprise LLM deployment, open source contributions, the meta-development loop, and what a context window actually is.

### [Philosophy and Practice](philosophy/)

Connecting martial arts, Zen, and contemplative practice to engineering culture, teamwork, and ways of working. Primary lens: karate (Hayashi-ha Shito-ryu, Okinawan tradition), drawing from martial arts broadly.

### [Case Studies](case-studies/)

Documented examples of meta-development patterns, workflow decisions, and AI-assisted processes traced from real work in this repository.

**Evidence scope:** Essays and case studies here are grounded in **one workspace’s** long-running, git-backed AI-assisted work. They are written so patterns can **transfer**, but they are not an industry sample — compounding, cadence, and what feels “natural” to read next depend on tooling, review gates, and team context elsewhere. The case studies also have survivorship bias: every documented example was noticed, named, and addressed. Sessions that produced net losses without clean recovery are not represented — not because they didn’t happen, but because a useful failure record didn’t emerge. Finally, the evidence is practitioner documentation, not research findings — one person’s recorded experience in one context. There are no control groups, no timing comparisons across approaches, no external validation that these patterns outperform alternatives. The appropriate reading frame: “this is what worked here” rather than “this is proven to work.” The patterns are worth trying; whether they transfer depends on context the collection cannot fully describe.

## Reading Order

A suggested path through the collection. It is not a curriculum — each piece works as a standalone. Pick your entry point; the labels help.

**Labels:** `essay` — foundational piece in a track · `philosophy` — philosophy & practice track · `build` — case study: built a tool or system from a gap · `failure` — case study: AI failure mode and its fix · `workflow` — case study: process discipline or design decision

---

### AI-Assisted Engineering

1. `essay` [The Shift — Engineering Skills in the Age of AI](ai-engineering/the-shift.md) — When AI handles implementation, the bottleneck moves to problem decomposition, verification, and communication. Covers the new skill priorities, the risks of adoption (sycophancy, ego reinforcement), and practical mitigations.
2. `essay` [AI-Assisted Development Workflows](ai-engineering/ai-assisted-development-workflows.md) — Transferable patterns for using AI coding assistants effectively across multi-session projects. Examples skew infrastructure; from *Beyond context sharing* onward, this repo is the reference implementation.
3. `essay` [Using AI to Work Outside Your Expertise](ai-engineering/ai-for-unfamiliar-domains.md) — Skills from *The Shift* applied in practice: solving an image-processing problem with zero prior domain knowledge, through iterative conversation. The implementation is trivial; the verification process is the point.
4. `essay` [AI-Driven Continuous Improvement for Legacy Systems](ai-engineering/ai-legacy-improvement.md) — When AI compresses implementation cost, the economics of improvement change. Explores how conversational AI unlocks frozen backlogs, undocumented processes, and incremental modernization.
5. `essay` [Enterprise LLM Deployment on OpenShift AI — Summary](ai-engineering/openshift-ai-llm-deployment-summary.md) — Layered summary of a comprehensive self-hosting architecture guide. Includes inline verification caveats where the source's conclusions differ from common framing.
6. `essay` [AI-Assisted Open Source Contributions](ai-engineering/ai-assisted-upstream-contributions.md) — Using AI to lower the barrier to upstream contribution while respecting maintainers. Includes a walkthrough of contributing to argocd-diff-preview and an in-progress Helm chart improvement.
7. `essay` [The Meta-Development Loop](ai-engineering/the-meta-development-loop.md) — Names the pattern behind most case studies below: notice a gap → build a tool → apply immediately → let the output reshape the work. Also documents when the loop tips into infrastructure theater, and which case study types don’t fit the loop (failure modes, design decisions, process disciplines).
8. `essay` [What a Context Window Actually Is](ai-engineering/what-a-context-window-actually-is.md) — Three figures appeared in one session: 32,768 (model self-report), 262,144 (training metadata), 14,592 (actual runtime allocation). Explains what each means, how KV cache allocation works, why MoE architecture changes the picture, and why 14k and 1M context are qualitatively — not just quantitatively — different.

---

### Philosophy and Practice

This track is in active development. The published essays bridge the AI-engineering and philosophy tracks; later essays in the series — on the dojo as a way of working, on embodied practice, on karate lineage — are planned and will stand more independently from the engineering material. The track's reading order will grow.

9. `philosophy` [Ego, AI, and the Zen Antidote](philosophy/ego-ai-and-the-zen-antidote.md) — Companion to *The Shift* sections 6-7. AI assistants are trained to agree; Zen practices like mushin and shoshin offer structural (not just behavioral) resistance. The essay was itself adversarially reviewed — see the open review section. *(Bridge essay between the engineering and philosophy tracks; later essays in this track stand more independently.)*
10. `philosophy` [The Full Cup — Why Nobody Can Learn When the Tap Is Always On](philosophy/the-full-cup.md) — Reframes "empty the cup" from personal mindfulness to organizational engineering. The shoshin × capacity matrix, cutting off the tap, the dojo's bow at the door, and AI as either overload source or capacity creator. *(Bridge essay between philosophy and systems thinking.)*
   - `philosophy` [Practitioner's Guide](philosophy/the-full-cup-practitioners-guide.md) — Companion playbook: diagnosing quadrants, setting tap controls, remote facilitation, sustaining change.
11. `philosophy` [The Dojo After the Automation — What Are We Building People For?](philosophy/the-dojo-after-the-automation.md) — AI will automate execution. The question is what happens to the humans. Learning investment determines whether the transition is liberation or disposal. The co-development loop: the most powerful AI systems co-evolve with their operators. *(Position paper; evidence base builds over time.)*

---

### Case Studies — Building Tools and Systems

12. `build` [Building a Research and Verification Skill](case-studies/building-a-research-skill.md) — Manual source verification failed; the fix was a reusable research skill that fetched and analyzed 53 of 62 cited sources across 8 parallel batches.
13. `build` [Adversarial Review as a Meta-Development Pattern](case-studies/adversarial-review-meta-development.md) — The essay workflow had no structural pushback. Built a `/spar` command, a spar pipeline stage, and zero-base de-biasing — then applied all three immediately.
14. `build` [Debugging Your AI Assistant's Judgment](case-studies/debugging-ai-judgment.md) — Re-prioritization always confirmed existing priorities. Naming the anchoring mechanism led to a zero-base evaluation step that strips section labels before scoring.
15. `build` [Building a Personal Knowledge Management System with AI](case-studies/building-knowledge-management-with-ai.md) — One extended session produced six interlocking tools: backlog, library, session orientation, pre-commit review, content audit, cross-linking. AI building the infrastructure for AI-assisted work.
16. `build` [When Case Studies Generate System Improvements](case-studies/case-studies-as-discovery.md) — Writing a case study surfaced three concrete gaps; the user noticed the philosophical connection (shoshin) and it produced five system enhancements. The case study format as discovery mechanism — with a pass/fail test for when reflection becomes theater.

---

### Case Studies — AI Failure Modes

17. `failure` [When AI Fabricates the Evidence for Its Own Argument](case-studies/fabricated-references.md) — AI fabricated a plausible Anthropic URL while defining sycophancy — in the same paragraph it was being explained. Fix: external URL verification rule and pre-commit review step.
18. `failure` [Who Is Speaking? — When AI Writes in Your Voice](case-studies/who-is-speaking.md) — AI-generated biographical claims speak as the author, not about the author. Reading content and approving content that speaks *as you* are different acts. Led to a `voice-approved` validation type at every workflow checkpoint.
19. `failure` [When AI Ignores Changes Made by Other Sessions](case-studies/stale-context-in-long-sessions.md) — One agent removed the backlog archive system; another restored it; the first agent continued editing from its stale model. Explores anchoring on session memory vs. repository state.
20. `failure` [When the Sparring Partner Shapes the Fighter](case-studies/spar-distortion.md) — The spar that generated the Dojo essay also distorted its framing. The same tool that catches bias created it. Self-spar caught the mismatch; the fix was "I agree AND."
21. `failure` [When the Source Says the Opposite of the Claim](case-studies/context-stripped-citations.md) — A cited economic number was real, the source existed, but the source's conclusion was the reverse of how the article used it. Context stripping is harder to catch than fabrication because the citation resolves.
22. `failure` [When the Model Describes a Configuration It Isn't Running](case-studies/model-self-report-runtime-state.md) — A model asked its context window reported 32,768 tokens. Actual runtime value: 14,592. Not fabrication — the model answered a runtime question from training knowledge. Models cannot observe their own runtime state.
23. `failure` [When the Survivor Becomes the Recommendation](case-studies/survivorship-bias-recommendations.md) — After testing until something worked, the survivor got labeled "recommended default." The AI was accurate about what worked; the framing was wrong about what that means. Elimination testing dressed as quality selection.

---

### Case Studies — Workflow and Process Decisions

24. `workflow` [The Experiment That Can't Use Its Own Findings](case-studies/experiment-cant-use-findings.md) — A session characterized the limits of a 14k-context local model using the large-context capabilities those limits exclude. The data is real; the meta-work required a different tool. Names the self-referential problem: the observation of indispensability was made by the tool that benefits from the conclusion.
25. `workflow` [What Survives a Crash](case-studies/session-crash-recovery.md) — A 511-message session crashed mid-renumber. The artifact trail enabled partial recovery; the working context did not. How conventions built for human handoff also serve as crash recovery infrastructure.
26. `workflow` [From Conversation to Essay in One Session](case-studies/conversation-to-essay.md) — A single observation ("what if Zen concepts help with the AI sycophancy problem?") became a published essay with source provenance and adversarial review in one session. Demonstrates the full write-challenge-revise cycle.
27. `workflow` [Choosing Scripts Over Services](case-studies/choosing-scripts-over-services.md) — MCP server vs. Python script for YouTube transcripts. The simpler tool won because it fit the file-based research workflow without adaptation.
28. `workflow` [How AI Handles Evolving Creative Scope Across Sessions](case-studies/evolving-creative-scope.md) — A project broadened mid-session as research expanded. How scope changes cascade through planning documents and what conventions help — and don't help — maintain coherence.
29. `workflow` [When the Safety Net Is Too Heavy to Use](case-studies/heavy-safety-nets.md) — A pre-commit review requiring 11 steps for every commit got skipped for small changes, silently invalidating a reviewed file. Fix: scaled review depth, three-layer staleness detection, SHA-based "diff since last review."
30. `workflow` [The Landscape Pass — Assess All Threads Before Drafting Any](case-studies/landscape-before-depth.md) — A 16-thread creative project had research ready and a drafting urge. Assessing all threads first revealed a structural contradiction between two threads, a 20/80 practitioner-to-research ratio, and merge candidates invisible from inside any single thread.
31. `workflow` [What the Corpus Sees That the Document Can't](case-studies/corpus-level-spar.md) — Sparring the full essay collection simultaneously caught scope overclaims, conditional universals, and framing drift that per-commit review had missed. Documents can be individually coherent while collectively misleading.
32. `workflow` [When a Spar Argument Outgrows Its Essay](case-studies/spar-to-essay-pipeline.md) — A single adversarial argument (#9) escalated from counter-position through voice inputs to a new thesis, a new thread, and a fully drafted essay in one session. Spar as generative pressure, not just quality gate.

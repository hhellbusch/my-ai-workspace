# Docs

Essays and case studies across three tracks — AI-assisted engineering, philosophy and practice, and documented case studies from the meta-development process itself.

## Tracks

### [AI-Assisted Engineering](ai-engineering/)

Skills, workflows, risks, and practical patterns for using AI effectively in engineering work. Seven essays covering the foundational thesis, daily workflows, working outside expertise, legacy systems, enterprise LLM deployment, open source contributions, and the meta-development loop.

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

---

### Philosophy and Practice

This track is in active development. The current published essay connects directly to the AI-engineering track. Later essays in the series — on the dojo as a way of working, on embodied practice, on karate lineage — are planned and will stand more independently from the engineering material. The track's reading order will grow.

8. `philosophy` [Ego, AI, and the Zen Antidote](philosophy/ego-ai-and-the-zen-antidote.md) — Companion to *The Shift* sections 6-7. AI assistants are trained to agree; Zen practices like mushin and shoshin offer structural (not just behavioral) resistance. The essay was itself adversarially reviewed — see the open review section. *(Bridge essay between the engineering and philosophy tracks; later essays in this track stand more independently.)*
9. `philosophy` [The Full Cup — Why Nobody Can Learn When the Tap Is Always On](philosophy/the-full-cup.md) — Reframes "empty the cup" from personal mindfulness to organizational engineering. The shoshin × capacity matrix, cutting off the tap, the dojo's bow at the door, and AI as either overload source or capacity creator. *(Bridge essay between philosophy and systems thinking.)*

---

### Case Studies — Building Tools and Systems

10. `build` [Building a Research and Verification Skill](case-studies/building-a-research-skill.md) — Manual source verification failed; the fix was a reusable research skill that fetched and analyzed 53 of 62 cited sources across 8 parallel batches.
11. `build` [Adversarial Review as a Meta-Development Pattern](case-studies/adversarial-review-meta-development.md) — The essay workflow had no structural pushback. Built a `/spar` command, a spar pipeline stage, and zero-base de-biasing — then applied all three immediately.
12. `build` [Debugging Your AI Assistant's Judgment](case-studies/debugging-ai-judgment.md) — Re-prioritization always confirmed existing priorities. Naming the anchoring mechanism led to a zero-base evaluation step that strips section labels before scoring.
13. `build` [Building a Personal Knowledge Management System with AI](case-studies/building-knowledge-management-with-ai.md) — One extended session produced six interlocking tools: backlog, library, session orientation, pre-commit review, content audit, cross-linking. AI building the infrastructure for AI-assisted work.
14. `build` [When Case Studies Generate System Improvements](case-studies/case-studies-as-discovery.md) — Writing a case study surfaced three concrete gaps; the user noticed the philosophical connection (shoshin) and it produced five system enhancements. The case study format as discovery mechanism — with a pass/fail test for when reflection becomes theater.

---

### Case Studies — AI Failure Modes

15. `failure` [When AI Fabricates the Evidence for Its Own Argument](case-studies/fabricated-references.md) — AI fabricated a plausible Anthropic URL while defining sycophancy — in the same paragraph it was being explained. Fix: external URL verification rule and pre-commit review step.
16. `failure` [Who Is Speaking? — When AI Writes in Your Voice](case-studies/who-is-speaking.md) — AI-generated biographical claims speak as the author, not about the author. Reading content and approving content that speaks *as you* are different acts. Led to a `voice-approved` validation type at every workflow checkpoint.
17. `failure` [When AI Ignores Changes Made by Other Sessions](case-studies/stale-context-in-long-sessions.md) — One agent removed the backlog archive system; another restored it; the first agent continued editing from its stale model. Explores anchoring on session memory vs. repository state.
18. `failure` [When the Source Says the Opposite of the Claim](case-studies/context-stripped-citations.md) — A cited economic number was real, the source existed, but the source's conclusion was the reverse of how the article used it. Context stripping is harder to catch than fabrication because the citation resolves.

---

### Case Studies — Workflow and Process Decisions

19. `workflow` [From Conversation to Essay in One Session](case-studies/conversation-to-essay.md) — A single observation ("what if Zen concepts help with the AI sycophancy problem?") became a published essay with source provenance and adversarial review in one session. Demonstrates the full write-challenge-revise cycle.
20. `workflow` [Choosing Scripts Over Services](case-studies/choosing-scripts-over-services.md) — MCP server vs. Python script for YouTube transcripts. The simpler tool won because it fit the file-based research workflow without adaptation.
21. `workflow` [How AI Handles Evolving Creative Scope Across Sessions](case-studies/evolving-creative-scope.md) — A project broadened mid-session as research expanded. How scope changes cascade through planning documents and what conventions help — and don't help — maintain coherence.
22. `workflow` [When the Safety Net Is Too Heavy to Use](case-studies/heavy-safety-nets.md) — A pre-commit review requiring 11 steps for every commit got skipped for small changes, silently invalidating a reviewed file. Fix: scaled review depth, three-layer staleness detection, SHA-based "diff since last review."
23. `workflow` [The Landscape Pass — Assess All Threads Before Drafting Any](case-studies/landscape-before-depth.md) — A 16-thread creative project had research ready and a drafting urge. Assessing all threads first revealed a structural contradiction between two threads, a 20/80 practitioner-to-research ratio, and merge candidates invisible from inside any single thread.
24. `workflow` [What the Corpus Sees That the Document Can't](case-studies/corpus-level-spar.md) — Sparring the full essay collection simultaneously caught scope overclaims, conditional universals, and framing drift that per-document review had missed. Documents can be individually coherent while collectively misleading.

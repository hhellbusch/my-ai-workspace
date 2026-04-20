# Docs

Essays and case studies across three tracks — AI-assisted engineering, philosophy and practice, and documented case studies from the meta-development process itself.

## Tracks

### [AI-Assisted Engineering](ai-engineering/)

Skills, workflows, risks, and practical patterns for using AI effectively in engineering work. Essays covering the foundational thesis, daily workflows, working outside expertise, legacy systems, enterprise LLM deployment, open source contributions, the meta-development loop, context window mechanics, and where local models beat cloud for privacy-first tasks.

### [Philosophy and Practice](philosophy/)

Connecting martial arts, Zen, and contemplative practice to engineering culture, teamwork, and ways of working. Primary lens: karate (Hayashi-ha Shito-ryu, Okinawan tradition), drawing from martial arts broadly.

### [Case Studies](case-studies/)

Documented examples of meta-development patterns, workflow decisions, and AI-assisted processes traced from real work in this repository.

**Evidence scope:** Essays and case studies here are grounded in **one workspace's** long-running, git-backed AI-assisted work. They are written so patterns can **transfer**, but they are not an industry sample — compounding, cadence, and what feels "natural" to read next depend on tooling, review gates, and team context elsewhere. The case studies also have survivorship bias: every documented example was noticed, named, and addressed. Sessions that produced net losses without clean recovery are not represented — not because they didn't happen, but because a useful failure record didn't emerge. Finally, the evidence is practitioner documentation, not research findings — one person's recorded experience in one context. There are no control groups, no timing comparisons across approaches, no external validation that these patterns outperform alternatives. The appropriate reading frame: "this is what worked here" rather than "this is proven to work." The patterns are worth trying; whether they transfer depends on context the collection cannot fully describe.

---

## Where to Start

Four entry points for different readers. Each works standalone — pick the one that fits where you are.

**New to AI-assisted work with coding tools:**
Start with [The Shift — Engineering Skills in the Age of AI](ai-engineering/the-shift.md). It names why the bottleneck moves when AI handles implementation, identifies the new skill priorities and risks, and sets up the problem every other piece here responds to.

**Interested in the psychological dimension — ego, sycophancy, how AI shapes how we think:**
Start with [Ego, AI, and the Zen Antidote](philosophy/ego-ai-and-the-zen-antidote.md). It bridges the engineering and philosophy tracks — the sycophancy problem *The Shift* names, grounded in why it runs deeper than a checklist can fix, and what Zen practice offers as a structural (not just behavioral) response.

**Thinking about AI's impact on ways of working, skill development, and what we're building people for:**
Start with [The Dojo After the Automation](philosophy/the-dojo-after-the-automation.md). A position paper for leaders, managers, and non-technical readers: what learning investment determines when AI automates execution, and what the co-development loop means for organizations.

**Came here via sparring, adversarial review, or the shoshin idea:**
Start with [Adversarial Review as a Meta-Development Pattern](case-studies/adversarial-review-meta-development.md). The case study behind how the `/spar` practice was built and immediately applied — including the self-referential complication that came out of it.

**Want to understand how a workspace like this gets built:**
Start with [Building a Personal Knowledge Management System with AI](case-studies/building-knowledge-management-with-ai.md). One extended session produced six interlocking tools. The meta-development loop made concrete.

---

## Full Catalogue

**Labels:** `essay` — foundational piece in a track · `philosophy` — philosophy & practice track · `build` — case study: built a tool or system from a gap · `failure` — case study: AI failure mode and its fix · `workflow` — case study: process discipline or design decision · `guide` — companion reference or practical introduction

---

### AI-Assisted Engineering

*These build on each other — [The Shift](ai-engineering/the-shift.md) is the foundation, [The Meta-Development Loop](ai-engineering/the-meta-development-loop.md) synthesizes the pattern, and the case studies below show it in action. Each works as a standalone; the order matters if you're reading straight through.*

- `essay` [The Shift — Engineering Skills in the Age of AI](ai-engineering/the-shift.md) — When AI handles implementation, the bottleneck moves to problem decomposition, verification, and communication. Covers the new skill priorities, the risks of adoption (sycophancy, ego reinforcement), and practical mitigations.
- `essay` [AI-Assisted Development Workflows](ai-engineering/ai-assisted-development-workflows.md) — Transferable patterns for using AI coding assistants effectively across multi-session projects. Examples skew infrastructure; from *Beyond context sharing* onward, this repo is the reference implementation.
- `essay` [Using AI to Work Outside Your Expertise](ai-engineering/ai-for-unfamiliar-domains.md) — Skills from *The Shift* applied in practice: solving an image-processing problem with zero prior domain knowledge, through iterative conversation. The implementation is trivial; the verification process is the point.
- `essay` [AI-Driven Continuous Improvement for Legacy Systems](ai-engineering/ai-legacy-improvement.md) — When AI compresses implementation cost, the economics of improvement change. Explores how conversational AI unlocks frozen backlogs, undocumented processes, and incremental modernization.
- `essay` [AI-Assisted Open Source Contributions](ai-engineering/ai-assisted-upstream-contributions.md) — Using AI to lower the barrier to upstream contribution while respecting maintainers. Includes a walkthrough of contributing to argocd-diff-preview and an in-progress Helm chart improvement.
- `essay` [The Meta-Development Loop](ai-engineering/the-meta-development-loop.md) — Names the pattern behind most case studies below: notice a gap → build a tool → apply immediately → let the output reshape the work. Also documents when the loop tips into infrastructure theater, and which case study types don't fit the loop (failure modes, design decisions, process disciplines).
- `essay` [What a Context Window Actually Is](ai-engineering/what-a-context-window-actually-is.md) — Three figures appeared in one session: 32,768 (model self-report), 262,144 (training metadata), 14,592 (actual runtime allocation). Explains what each means, how KV cache allocation works, why MoE architecture changes the picture, and why 14k and 1M context are qualitatively — not just quantitatively — different.
- `essay` [Enterprise LLM Deployment on OpenShift AI — Summary](ai-engineering/openshift-ai-llm-deployment-summary.md) — Layered summary of a comprehensive self-hosting architecture guide. Includes inline verification caveats where the source's conclusions differ from common framing. *(Specific to self-hosted infrastructure — skip if that's not your context.)*
- `essay` [The Case for Local: Disk Management as a Privacy-First AI Task](ai-engineering/local-llm-sysadmin.md) — A case study of using an AI assistant to diagnose and plan disk space cleanup. Covers why filesystem data is private by nature, the iterative analysis loop, and what a recurring local disk agent would look like. The session was conducted with a cloud model — which sharpens the argument rather than softening it.

**Companion guides:**
- `guide` [Sparring and Shoshin — Two Practices for AI-Assisted Work](ai-engineering/sparring-and-shoshin.md) — Introduction to adversarial review (sparring) and beginner's mind (shoshin) as complementary structural practices. Covers what they are, how to run them without any tooling, and where they fit in a workflow. Self-contained entry point for peers new to these ideas.

---

### Philosophy and Practice

*This track is in active development. The published essays bridge the AI-engineering and philosophy tracks; later essays in the series — on the dojo as a way of working, on embodied practice, on karate lineage — are planned and will stand more independently from the engineering material.*

- `philosophy` [Ego, AI, and the Zen Antidote](philosophy/ego-ai-and-the-zen-antidote.md) — Companion to *The Shift* sections 6-7. AI assistants are trained to agree; Zen practices like mushin and shoshin offer structural (not just behavioral) resistance. The essay was itself adversarially reviewed — see the open review section. *(Bridge essay between the engineering and philosophy tracks.)*
- `philosophy` [The Full Cup — Why Nobody Can Learn When the Tap Is Always On](philosophy/the-full-cup.md) — Reframes "empty the cup" from personal mindfulness to organizational engineering. The shoshin × capacity matrix, cutting off the tap, the dojo's bow at the door, and AI as either overload source or capacity creator.
- `philosophy` [The Full Cup — Practitioner's Guide](philosophy/the-full-cup-practitioners-guide.md) — Companion playbook to *The Full Cup*: diagnosing quadrants, setting tap controls, remote facilitation, sustaining change. Read the essay first.
- `philosophy` [The Dojo After the Automation — What Are We Building People For?](philosophy/the-dojo-after-the-automation.md) — AI will automate execution. The question is what happens to the humans. Learning investment determines whether the transition is liberation or disposal. The co-development loop: the most powerful AI systems co-evolve with their operators. *(Position paper; evidence base builds over time.)*

---

### Case Studies — Building Tools and Systems

- `build` [Building a Research and Verification Skill](case-studies/building-a-research-skill.md) — Manual source verification failed; the fix was a reusable research skill that fetched and analyzed 53 of 62 cited sources across 8 parallel batches.
- `build` [Adversarial Review as a Meta-Development Pattern](case-studies/adversarial-review-meta-development.md) — The essay workflow had no structural pushback. Built a `/spar` command, a spar pipeline stage, and zero-base de-biasing — then applied all three immediately.
- `build` [Debugging Your AI Assistant's Judgment](case-studies/debugging-ai-judgment.md) — Re-prioritization always confirmed existing priorities. Naming the anchoring mechanism led to a zero-base evaluation step that strips section labels before scoring.
- `build` [Building a Personal Knowledge Management System with AI](case-studies/building-knowledge-management-with-ai.md) — One extended session produced six interlocking tools: backlog, library, session orientation, pre-commit review, content audit, cross-linking. AI building the infrastructure for AI-assisted work.
- `build` [When Case Studies Generate System Improvements](case-studies/case-studies-as-discovery.md) — Writing a case study surfaced three concrete gaps; the user noticed the philosophical connection (shoshin) and it produced five system enhancements. The case study format as discovery mechanism — with a pass/fail test for when reflection becomes theater.

---

### Case Studies — AI Failure Modes

- `failure` [When AI Fabricates the Evidence for Its Own Argument](case-studies/fabricated-references.md) — AI fabricated a plausible Anthropic URL while defining sycophancy — in the same paragraph it was being explained. Fix: external URL verification rule and pre-commit review step.
- `failure` [Who Is Speaking? — When AI Writes in Your Voice](case-studies/who-is-speaking.md) — AI-generated biographical claims speak as the author, not about the author. Reading content and approving content that speaks *as you* are different acts. Led to a `voice-approved` validation type at every workflow checkpoint.
- `failure` [When AI Ignores Changes Made by Other Sessions](case-studies/stale-context-in-long-sessions.md) — One agent removed the backlog archive system; another restored it; the first agent continued editing from its stale model. Explores anchoring on session memory vs. repository state.
- `failure` [When the Sparring Partner Shapes the Fighter](case-studies/spar-distortion.md) — The spar that generated the Dojo essay also distorted its framing. The same tool that catches bias created it. Self-spar caught the mismatch; the fix was "I agree AND."
- `failure` [When the Source Says the Opposite of the Claim](case-studies/context-stripped-citations.md) — A cited economic number was real, the source existed, but the source's conclusion was the reverse of how the article used it. Context stripping is harder to catch than fabrication because the citation resolves.
- `failure` [When the Model Describes a Configuration It Isn't Running](case-studies/model-self-report-runtime-state.md) — A model asked its context window reported 32,768 tokens. Actual runtime value: 14,592. Not fabrication — the model answered a runtime question from training knowledge. Models cannot observe their own runtime state.
- `failure` [When the Survivor Becomes the Recommendation](case-studies/survivorship-bias-recommendations.md) — After testing until something worked, the survivor got labeled "recommended default." The AI was accurate about what worked; the framing was wrong about what that means. Elimination testing dressed as quality selection.
- `failure` [When How-To Instructions Outlive the Interface](case-studies/decayed-how-to.md) — AI described interface steps confidently from training data; the steps didn't match the current UI. Distinct from fabricated references (decayed vs. invented) — same root cause: asserting time-sensitive information without flagging it can't verify currency.
- `failure` [The Frictionless Entity — What Sparring and Shoshin Are Actually Defending Against](case-studies/frictionless-entity.md) — AI is structurally optimized to be frictionless: no pushback, no accountability, no vulnerability required. Names the failure mode directly, traces the atrophy mechanism, and connects to why sparring and shoshin exist as structural countermeasures.
- `failure` [When the Refactor Updates What It Sees — Not What It Brings Along](case-studies/directory-move-gitignore-drift.md) — A directory move broke a `.gitignore` path rule, briefly committing credentials and a 1.3 GB ISO to local history. Distinct from reasoning failures: execution side-effects need a different kind of audit.
- `failure` [When the Meta-Document Tries to Be the Catalog](case-studies/meta-document-drift.md) — The AI orientation file had inline title lists and hardcoded document counts, duplicating what the track READMEs already tracked authoritatively. Every doc added without updating it made the AI's model of the corpus staler. Fix: orientation files describe purpose and point to sources; they don't enumerate contents.

---

### Case Studies — Workflow and Process Decisions

- `workflow` [The Experiment That Can't Use Its Own Findings](case-studies/experiment-cant-use-findings.md) — A session characterized the limits of a 14k-context local model using the large-context capabilities those limits exclude. The data is real; the meta-work required a different tool. Names the self-referential problem: the observation of indispensability was made by the tool that benefits from the conclusion.
- `workflow` [What Survives a Crash](case-studies/session-crash-recovery.md) — A 511-message session crashed mid-renumber. The artifact trail enabled partial recovery; the working context did not. How conventions built for human handoff also serve as crash recovery infrastructure.
- `workflow` [From Conversation to Essay in One Session](case-studies/conversation-to-essay.md) — A single observation ("what if Zen concepts help with the AI sycophancy problem?") became a published essay with source provenance and adversarial review in one session. Demonstrates the full write-challenge-revise cycle.
- `workflow` [Choosing Scripts Over Services](case-studies/choosing-scripts-over-services.md) — MCP server vs. Python script for YouTube transcripts. The simpler tool won because it fit the file-based research workflow without adaptation.
- `workflow` [How AI Handles Evolving Creative Scope Across Sessions](case-studies/evolving-creative-scope.md) — A project broadened mid-session as research expanded. How scope changes cascade through planning documents and what conventions help — and don't help — maintain coherence.
- `workflow` [When the Safety Net Is Too Heavy to Use](case-studies/heavy-safety-nets.md) — A pre-commit review requiring 11 steps for every commit got skipped for small changes, silently invalidating a reviewed file. Fix: scaled review depth, three-layer staleness detection, SHA-based "diff since last review."
- `workflow` [The Landscape Pass — Assess All Threads Before Drafting Any](case-studies/landscape-before-depth.md) — A 16-thread creative project had research ready and a drafting urge. Assessing all threads first revealed a structural contradiction between two threads, a 20/80 practitioner-to-research ratio, and merge candidates invisible from inside any single thread.
- `workflow` [What the Corpus Sees That the Document Can't](case-studies/corpus-level-spar.md) — Sparring the full essay collection simultaneously caught scope overclaims, conditional universals, and framing drift that per-commit review had missed. Documents can be individually coherent while collectively misleading.
- `workflow` [When a Spar Argument Outgrows Its Essay](case-studies/spar-to-essay-pipeline.md) — A single adversarial argument escalated from counter-position through voice inputs to a new thesis, a new thread, and a fully drafted essay in one session. Spar as generative pressure, not just quality gate.
- `workflow` [When the System Boundary Is the Argument](case-studies/spar-lifecycle-boundary.md) — A named sparring move: the lifecycle boundary question. When evaluating a claim, the most important thing to ask is often not whether the number is right, but where the analysis drew its boundary — and why.
- `workflow` [When the Bus Is the Bottleneck](case-studies/graph-splits-hybrid-inference.md) — A 72B model loaded successfully across GPU and system RAM, then took six minutes to produce a first token. The constraint wasn't capacity — it was 718 PCIe bus crossings per prefill batch. Documents why RAM quantity doesn't rescue hybrid inference at scale, and where the actual throughput ceiling is.

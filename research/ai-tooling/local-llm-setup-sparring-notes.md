---
review:
  status: unreviewed
  notes: "AI-generated sparring notes. Needs read and author response sections filled in before revisions are made to the source document."
---

# Sparring Notes — local-llm-setup.md

**Source document:** [`docs/ai-engineering/local-llm-setup.md`](../../docs/ai-engineering/local-llm-setup.md)
**Sparred:** 2026-04-19
**Round:** 1

---

## 1. The electricity framing front-runs the evidence

**Type:** Structural
**Strength:** Strong

**The argument:** The document's strongest differentiating claim — "real circuit-level data changes the conversation" — is a promise about evidence that doesn't yet exist. No LLM workload has been measured against the circuit monitor. The monitoring setup is described in detail; the methodology is outlined; the first case study is planned. But the document is structured as if the data asset already validates the thesis. "Having real circuit-level data changes the conversation" is true only after the measurements are taken. Right now, this is a well-instrumented intention, not a finding.

**Why it matters:** Readers who trust the document's "honest" framing will assume the electricity argument has been grounded in something measured. It hasn't. If the case studies eventually show that local inference costs are comparable to or worse than API fees even at moderate usage, the electricity angle deflates. The document has already published the conclusion before the data exists.

**Author response:**

> Agreed — it's just an intention at this point. The electricity section should clearly signal "research plan, not finding."

**Resolution:**
- [x] Add explicit "this is the research plan, not the finding" language — revised opening of electricity section

---

## 2. The model-size complexity table is assertion dressed as reference

**Type:** Evidence
**Strength:** Strong

**The argument:** The complexity spectrum table ("Multi-file reasoning: 13B–32B minimum", "Agentic multi-step: 70B+") carries the visual authority of a data table but has no citations, no benchmark methodology, no experimental basis. These are reasonable expert judgments — but the table format implies they're findings rather than estimates. The document correctly flags its power draw figures as unverified. The complexity table carries no equivalent caveat.

**Why it matters:** Readers will use this table to make hardware purchase decisions. If the thresholds are wrong, someone over-invests on the document's authority.

**Author response:**

> Agreed with this concern. The table should be clearly flagged as estimated, not benchmarked.

**Resolution:**
- [x] Added note after table: "estimated thresholds based on task analysis, not benchmarked — test a smaller model first"

---

## 3. "32B minimum for this workspace" is unfalsifiable as stated

**Type:** Structural
**Strength:** Moderate

**The argument:** The claim that this workspace specifically requires 32B as a realistic minimum has no counterfactual. Nobody has run a 7B or 13B model on this workspace and measured where it fails. The argument is built from complexity proxies (file count, domain breadth, agentic workflow depth) rather than from observed model behavior. It's also convenient: 32B is above the threshold of most consumer hardware, which implicitly validates continued cloud API use.

**Why it matters:** If a reader has an RTX 4070 (12 GB VRAM, max ~13B), the document tells them their hardware is insufficient for meaningful work here — which may discourage experimentation entirely, contradicting the document's stated motivation.

**Author response:**

> This guide is intended to answer this question — it's the starting point for figuring out what to try first. No 7B/13B experimentation has been done yet. 32B should be framed as a hypothesis to test, not a minimum.

**Resolution:**
- [x] Reframed: "32B is the threshold where we expect quality to become consistent — but that's a hypothesis, not a finding." Explicitly frames the guide as the vehicle for answering the question through experimentation.

---

## 4. The "honest assessment" framing is itself a rhetorical move

**Type:** Presentation
**Strength:** Moderate

**The argument:** The document signals its own honesty repeatedly — "the common framing often gets the math wrong," "Honest Assessment" section header, "this is where real circuit-level data changes the conversation." Performed skepticism is still performance. The document makes multiple unverified claims while signaling throughout that it's more careful than typical guides. The label doesn't substitute for the verification.

**Why it matters:** A reader who trusts the "honest" framing will treat unverified claims as verified ones. The direction-reviewed callout partially addresses this, but body text like "this is where real data changes the conversation" appears before most readers reach the footer.

**Author response:**

> Honesty is a primary driver. Interesting that the attempt to signal honesty is itself a rhetorical pattern the spar flagged. Worth capturing as a case study — and possibly improving the system to catch this behavior proactively.

**Resolution:**
- [ ] Backlog: case study candidate — "performed honesty" pattern (AI self-labels as honest while making unverified claims)
- [ ] Backlog: explore system-level check — pre-commit or spar rule that flags self-referential honesty claims in new docs
- Note: section is already "What to Expect (Honest Assessment)" — no rename needed. The deeper issue is structural, captured in the case study candidate.

---

## 5. The document has three audiences and serves none of them fully

**Type:** Scope
**Strength:** Moderate

**The argument:** The stated audience is "anyone curious about running an AI model on their own hardware" but the document assumes CLI literacy, VRAM knowledge, and familiarity with agentic AI architecture. A genuinely non-technical reader hits a wall at the Linux commands section. An expert reader finds the hardware section elementary. The document is actually written for a technical practitioner who doesn't yet know about local LLMs — a narrower audience than claimed.

**Why it matters:** The audience framing sets expectations the document doesn't fulfill for either end of the spectrum.

**Author response:**

> The audience will likely be more technical in practice — the VRAM/RAM requirements self-select. Most non-technical readers won't be able to run this anyway.

**Resolution:**
- [x] Narrowed audience statement to "Technical practitioners curious about running AI locally" with explicit note about hardware requirements as the natural filter.

---

## 6. The privacy argument borrows legitimacy it hasn't earned for this context

**Type:** Scope
**Strength:** Moderate (context-dependent)

**The argument:** "Your code, your prompts, your context never leave your network" leads the reasons-to-run-locally list with no qualification. For a workspace that is public on GitHub and discusses philosophy and DevOps tooling for open products, the privacy argument is much weaker than for proprietary enterprise codebases. The document imports the strongest-sounding justification for local inference without interrogating whether it applies.

**Why it matters:** Privacy as the lead argument frames local inference as a safety decision rather than a tradeoff decision — nudging readers regardless of their actual threat model.

**Author response:**

> This workspace is public, but there are other audiences and contexts where privacy does matter (some work does care about it — just not this repo). The privacy argument is valid for the general audience even if it doesn't apply here specifically.

**Resolution:**
- [x] Added qualifier inline: "Privacy matters most when your work involves proprietary code, customer data, or regulated information. For public or open-source work the argument is weaker, but it's relevant to anyone who uses the same tools across contexts."

---

## Spar Self-Audit

**Strongest:** #1 (electricity framing front-runs evidence) — the document's core differentiator hasn't delivered yet; this is structural, not stylistic.

**Weakest:** #6 (privacy argument) — pattern-matches into "the document isn't honest about its own context" but the general-audience framing makes privacy a legitimate lead argument for many readers.

**Blind spot in the spar:** The direction-reviewed status and ⚠️ callout do real mitigation work that the spar underweights. These arguments land harder on a finished document than on one that openly flags its own incompleteness.

---

*Sparring notes generated with AI assistance (Cursor). Response sections to be filled in by the author.*

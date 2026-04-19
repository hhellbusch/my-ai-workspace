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

> _[Fill in: Is this a valid critique? Does the framing need qualifying? Or is the "coming measurement" framing intentional — setting up the track rather than claiming results?]_

**Resolution:**
- [ ] Revise framing to make the "planned, not yet measured" status clearer in the electricity section
- [ ] Leave as-is — direction-reviewed status covers this
- [ ] Add explicit "this is the research plan, not the finding" language

---

## 2. The model-size complexity table is assertion dressed as reference

**Type:** Evidence
**Strength:** Strong

**The argument:** The complexity spectrum table ("Multi-file reasoning: 13B–32B minimum", "Agentic multi-step: 70B+") carries the visual authority of a data table but has no citations, no benchmark methodology, no experimental basis. These are reasonable expert judgments — but the table format implies they're findings rather than estimates. The document correctly flags its power draw figures as unverified. The complexity table carries no equivalent caveat.

**Why it matters:** Readers will use this table to make hardware purchase decisions. If the thresholds are wrong, someone over-invests on the document's authority.

**Author response:**

> _[Fill in: Should a caveat be added to the table — e.g., "estimated thresholds, not benchmarked"? Or are you comfortable with the expert-judgment framing?]_

**Resolution:**
- [ ] Add a table caption: "Estimated thresholds based on task analysis — not benchmarked"
- [ ] Leave as-is — consistent with the direction-reviewed status
- [ ] Add inline note after table explaining these are judgment-based estimates

---

## 3. "32B minimum for this workspace" is unfalsifiable as stated

**Type:** Structural
**Strength:** Moderate

**The argument:** The claim that this workspace specifically requires 32B as a realistic minimum has no counterfactual. Nobody has run a 7B or 13B model on this workspace and measured where it fails. The argument is built from complexity proxies (file count, domain breadth, agentic workflow depth) rather than from observed model behavior. It's also convenient: 32B is above the threshold of most consumer hardware, which implicitly validates continued cloud API use.

**Why it matters:** If a reader has an RTX 4070 (12 GB VRAM, max ~13B), the document tells them their hardware is insufficient for meaningful work here — which may discourage experimentation entirely, contradicting the document's stated motivation.

**Author response:**

> _[Fill in: Has any 7B/13B experimentation been done here? Is the 32B claim a floor or a recommendation? Should the language be softened to "32B is where we expect quality to become consistent" rather than "minimum"?]_

**Resolution:**
- [ ] Soften "realistic minimum" to "where quality becomes consistent"
- [ ] Add: "Testing a smaller model first is a reasonable starting point — the degradation is gradual, not a cliff"
- [ ] Leave as-is — the workspace complexity survey is honest and the judgment is defensible

---

## 4. The "honest assessment" framing is itself a rhetorical move

**Type:** Presentation
**Strength:** Moderate

**The argument:** The document signals its own honesty repeatedly — "the common framing often gets the math wrong," "Honest Assessment" section header, "this is where real circuit-level data changes the conversation." Performed skepticism is still performance. The document makes multiple unverified claims while signaling throughout that it's more careful than typical guides. The label doesn't substitute for the verification.

**Why it matters:** A reader who trusts the "honest" framing will treat unverified claims as verified ones. The direction-reviewed callout partially addresses this, but body text like "this is where real data changes the conversation" appears before most readers reach the footer.

**Author response:**

> _[Fill in: Does the existing direction-reviewed callout in the header adequately cover this? Or does the body text's confident tone create a misleading signal?]_

**Resolution:**
- [ ] Rename "Honest Assessment" section to something less self-congratulatory — e.g., "What to Expect"
- [ ] Already done — section is called "What to Expect (Honest Assessment)" which is fine
- [ ] Add a qualifier to the electricity section's opening line

---

## 5. The document has three audiences and serves none of them fully

**Type:** Scope
**Strength:** Moderate

**The argument:** The stated audience is "anyone curious about running an AI model on their own hardware" but the document assumes CLI literacy, VRAM knowledge, and familiarity with agentic AI architecture. A genuinely non-technical reader hits a wall at the Linux commands section. An expert reader finds the hardware section elementary. The document is actually written for a technical practitioner who doesn't yet know about local LLMs — a narrower audience than claimed.

**Why it matters:** The audience framing sets expectations the document doesn't fulfill for either end of the spectrum.

**Author response:**

> _[Fill in: Is the actual target audience "technical practitioner unfamiliar with local LLMs"? Should the audience statement be updated? Or is the wide-audience framing intentional given the repo's stated goal of reaching non-technical peers?]_

**Resolution:**
- [ ] Narrow the audience statement: "Technical practitioners curious about running AI locally"
- [ ] Add brief explanations of CLI flags for non-technical readers (e.g., explain `-s pcut`)
- [ ] Leave as-is — direction-reviewed status and the ⚠️ callout manage expectations

---

## 6. The privacy argument borrows legitimacy it hasn't earned for this context

**Type:** Scope
**Strength:** Moderate (context-dependent)

**The argument:** "Your code, your prompts, your context never leave your network" leads the reasons-to-run-locally list with no qualification. For a workspace that is public on GitHub and discusses philosophy and DevOps tooling for open products, the privacy argument is much weaker than for proprietary enterprise codebases. The document imports the strongest-sounding justification for local inference without interrogating whether it applies.

**Why it matters:** Privacy as the lead argument frames local inference as a safety decision rather than a tradeoff decision — nudging readers regardless of their actual threat model.

**Author response:**

> _[Fill in: Does privacy matter for your actual use case? Should it stay as the lead argument with a note that its force depends on what you're working with? Or reorder so privacy isn't first?]_

**Resolution:**
- [ ] Add qualifier: "Privacy matters most when your codebase contains proprietary IP or regulated data"
- [ ] Reorder: lead with "Offline work" or "Experimentation" instead
- [ ] Leave as-is — the document addresses a general audience and privacy is legitimately important for many of them

---

## Spar Self-Audit

**Strongest:** #1 (electricity framing front-runs evidence) — the document's core differentiator hasn't delivered yet; this is structural, not stylistic.

**Weakest:** #6 (privacy argument) — pattern-matches into "the document isn't honest about its own context" but the general-audience framing makes privacy a legitimate lead argument for many readers.

**Blind spot in the spar:** The direction-reviewed status and ⚠️ callout do real mitigation work that the spar underweights. These arguments land harder on a finished document than on one that openly flags its own incompleteness.

---

*Sparring notes generated with AI assistance (Cursor). Response sections to be filled in by the author.*

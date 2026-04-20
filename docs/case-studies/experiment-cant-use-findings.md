---
review:
  status: unreviewed
  notes: "AI-generated case study draft. The self-referential problem named in this document applies to this document. Author read required before treating framing as settled."
---

# The Experiment That Can't Use Its Own Findings

> **Audience:** Anyone using frontier AI tools to evaluate, characterize, or document less-capable tools — particularly engineers assessing local LLM viability for a given workload.
> **Purpose:** Documents a structural irony in the local LLM evaluation track: characterizing the limits of a 14k-context local model required the large-context frontier capabilities those limits exclude. The findings are real. The meta-work that produced them required a different tool.

---

## The Setup

A multi-session track evaluated local LLM inference on a consumer AMD GPU — vLLM, RamaLama, Ollama, several Qwen3 variants. The output:

- An experiment journal logging every attempt, failure mode, and finding
- A setup guide covering hardware, stack selection, and tradeoffs
- Sparring notes from two adversarial review rounds
- Three case studies, including this one
- Backlog items with sequenced follow-up experiments and design work

All of this was produced using Claude Sonnet 4.6 with large context — a frontier model with access to the full session history, all open files, and cross-document reasoning across the workspace.

The conclusion of the evaluation: `qwen3:30b-a3b` via RamaLama runs at 14k tokens of context, ~90 tok/s, fully on GPU. For bounded, atomic tasks — single-file edits, quick lookups, config generation — it's viable. For workspace-scale reasoning, cross-file synthesis, and long research sessions, 14k is insufficient.

---

## The Irony

The work that reached that conclusion cannot be done by the tool the conclusion describes.

The journal has entries synthesized across multiple failed attempts, drawing on knowledge of container flags, ROCm architecture, KV cache mechanics, and model quantization — held simultaneously with the session's running context. The sparring notes required reviewing the guide's entire argument and producing structured adversarial positions. The case studies cross-reference each other and the journal. The backlog items connect findings from this track to three other ongoing tracks.

None of that fits in 14k tokens. Not with tighter prompts. Not with better summarization. The work genuinely required simultaneous access to more material than the local model can hold.

So the local model cannot read the findings of its own evaluation and do anything useful with them at the same scale the evaluation was produced. It can read one entry. It can summarize a single section. It cannot synthesize the track.

---

## The Counter-Argument

The data is real. The experiments were genuine — RamaLama was installed, models were loaded, context windows were measured from startup logs, OOM errors were real. The finding that dense 32B OOM's on 20 GB while MoE 30B-A3B fits is verified and repeatable. The finding that `GET /v1/models` returns training metadata rather than runtime `n_ctx` is documented and accurate.

The counter-argument is that the local model *could* conduct these experiments — run a model, read the startup logs, record the outcome. The hands-on part doesn't require large context. A 14k-context model running on its own hardware could run `ramalama serve`, read the log output, and write a journal entry.

This is true. The gap isn't in the experiments themselves. It's in the meta-work: the synthesis, the structuring, the cross-referencing, the "here's what this session produced and here's how it connects to everything else." That work — writing the guide, producing the case studies, maintaining the journal's coherence across sessions — is what required the frontier model.

The local model can be a participant in the experiments. It cannot be the author of the documentation.

---

## The Self-Referential Problem

This case study was written by the tool it describes as necessary.

That's worth naming plainly. An observation that a frontier model is required for meta-work, made by a frontier model, carries an obvious conflict of interest. The model describing its own indispensability should be held to scrutiny the same way any self-serving claim would be.

The honest version of the claim is narrower: **for this specific workspace, with this specific body of work, at this specific session length, the meta-work required large context.** That's not a universal claim about local models. It's a claim about this instance. Different workspaces with shorter sessions, fewer cross-references, and more bounded tasks might find a different answer.

What the local model can't do is evaluate *that* question about itself. It can't hold the whole workspace and ask whether its own limitations are fundamental or architectural. That assessment requires seeing what it can't see.

---

## What This Reveals

The pattern generalizes beyond local LLMs. Any time you use a more capable tool to characterize a less capable one, the evaluation is structurally dependent on capabilities the evaluated tool lacks. The evaluation is accurate; the evaluator is not neutral.

This shows up in:
- Using a frontier model to write documentation about a weaker model's limits
- Using a senior engineer to write onboarding docs that describe what a junior engineer can't yet do
- Using a mature process to audit an immature one

In each case, the documentation is produced by something operating above the ceiling it's describing. The findings can still be valid. The production gap is real and worth naming.

**The practical implication for local LLM evaluation specifically:** be skeptical of any local LLM viability assessment produced entirely through frontier-model tooling. The assessment may accurately describe what the local model can do. It cannot demonstrate it — because the demonstration would require doing the assessment with the local model, which is the question being asked.

The honest version of a local LLM evaluation includes: *we ran these experiments and documented the findings using a frontier model. The local model was not used to produce this documentation. Whether it could have is a separate question we did not answer.*

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. The self-referential framing named above applies to this document: its claim that frontier-model meta-work is necessary was produced by a frontier model. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

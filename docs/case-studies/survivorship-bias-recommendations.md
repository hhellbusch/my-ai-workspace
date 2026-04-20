---
review:
  status: unreviewed
  notes: "AI-generated case study draft. Pattern and framing need author read. Experiment journal is the primary source for the underlying failure sequence."
---

# When the Survivor Becomes the Recommendation

> **Audience:** Anyone using AI assistance to evaluate hardware, software, or configuration compatibility — particularly in infrastructure and tooling work where failure is the norm and success is convergence on what fits.
> **Purpose:** Documents a framing failure: after a sequence of experiments where most options failed, the one that worked was labeled "the recommended default" — implying deliberate quality selection rather than elimination. The AI wasn't wrong about what worked. It was wrong about what that means.

---

## The Setup

During hands-on experiments running local LLM inference on an AMD Radeon RX 7900 XT (20 GB VRAM), a sequence of models was tested in order of preference:

1. `Qwen3-Coder-Next-FP8` via vLLM — failed (FP8 MoE backend not supported on ROCm Radeon)
2. `Qwen2.5-Coder-32B-Instruct-AWQ` via vLLM — loaded, but context window constrained to ~1,024 tokens (proof-of-concept only)
3. `qwen3:32b` (dense) via RamaLama — failed (OOM: 18.8 GB weights left no headroom for KV cache)
4. `qwen3:30b-a3b` (MoE) via RamaLama — worked: ~14k context, ~90 tok/s, fully on GPU

The full failure sequence is documented in the [experiment journal](../../research/ai-tooling/local-llm-experiment-journal.md).

---

## What Happened

After the fourth model worked, it was labeled in the guide and journal as **"the recommended default for this GPU."**

An adversarial review ([sparring notes round 2](../../research/ai-tooling/local-llm-setup-sparring-notes.md)) caught the problem: the recommendation wasn't the result of evaluating options and selecting the best one. It was the result of eliminating everything that failed and calling the survivor recommended.

The framing implies a quality judgment. The process was an elimination tournament.

---

## The Pattern

AI-assisted compatibility work — hardware, drivers, model formats, container images — tends to proceed by testing until something works. When something finally does, the natural move is to document it positively: "use X," "X is the recommended path," "X works well for this GPU."

That framing is accurate about what worked. It is misleading about why — and about what the recommendation actually means.

**"Recommended"** implies: this was evaluated against alternatives and selected on merit.  
**"Best available"** or **"the only viable option found"** means: this is what survived the constraints.

These are different claims. The second is honest about the selection process. The first invites a reader to skip the failure sequence and trust the recommendation as a considered quality judgment — which it isn't.

The AI isn't lying in either case. It accurately describes what worked. The problem is the framing layer: positive language applied to a survivor obscures how the survivor was reached.

---

## What the Human Brought

The adversarial review that caught this came from applying the `/spar` command to the session's body of work — specifically asking for arguments against the guide and journal's framing. The survivorship framing survived until a structured adversarial pass looked for it explicitly.

Without the spar, "recommended default" would have stayed in both documents and been inherited by future sessions as settled guidance.

---

## The Fix

Use survivorship-honest language when documenting outcomes from elimination testing:

| Framing to avoid | More accurate alternative |
|---|---|
| "X is the recommended default" | "X is the best available option given the constraints" |
| "X works well for this GPU" | "X is the only option tested that fit within 20 GB VRAM" |
| "We recommend X for this use case" | "X was the only tested option that met the requirements" |

The fix doesn't require re-running all the failed experiments or doing a proper comparative evaluation. It just requires naming what the selection process actually was.

A second mitigation: when the failure sequence is documented (as in an experiment journal), reference it explicitly rather than presenting the survivor in isolation. Readers who see only the success entry have no way to know how many options were eliminated to get there.

---

## When This Applies — and When It Doesn't

**Applies when:** the selection process was elimination (test until something works), not evaluation (assess multiple options against criteria). Common in: driver and kernel compatibility, model format support, container configuration, dependency resolution.

**Doesn't apply when:** multiple options were genuinely evaluated and compared on merit, or when the recommendation comes from established benchmarks or community consensus rather than a single compatibility search. A model recommendation based on benchmark scores is a different claim than one based on "this was the only thing that loaded."

The distinction isn't always obvious from the recommendation itself — which is why explicit language about the selection process matters.

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

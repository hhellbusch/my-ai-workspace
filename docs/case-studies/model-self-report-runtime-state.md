---
review:
  status: unreviewed
  notes: "AI-generated case study draft. Commands and log excerpts verified at runtime by author. Narrative framing needs author read before citing."
---

# When the Model Describes a Configuration It Isn't Running

> **Audience:** Engineers running local inference with llama.cpp-based tools (Ollama, RamaLama, llama-server). Anyone who has asked a model a question about its own runtime state.
> **Purpose:** Documents a specific failure mode: a model answering a question about its current configuration from training knowledge rather than from actual runtime state. The model wasn't wrong in the way fabrication is wrong — the number it cited exists and is meaningful — but it answered a runtime question with a training-time answer.

---

## The Setup

During a hands-on experiment running `qwen3:30b-a3b` locally via RamaLama on a Radeon RX 7900 XT (20 GB VRAM), the model was asked directly:

```
What is your context window size in tokens?
```

The response was immediate and confident:

```
My context window size is 32768 tokens.
```

This was noted as promising — 32k tokens is a meaningful context window for local inference. The number was logged and briefly cited as the context window for this GPU configuration.

---

## What Happened

The number was wrong — not fabricated, but wrong for the wrong reason.

Verification via `ramalama serve` startup logs revealed the actual runtime value:

```
llama_context: n_ctx         = 14592
llama_context: n_ctx_seq (14592) < n_ctx_train (262144) -- the full capacity of the model will not be utilized
```

llama.cpp's `-fit` algorithm had reduced the context from the model's training context (262,144 tokens) to fit within available VRAM. After loading 17.5 GB of weights onto a 20 GB card, approximately 2.7 GB remained — enough for a 14,592-token KV cache, not 32,768.

The model self-reported 32,768. The actual runtime `n_ctx` was 14,592. A factor of 2.2× off.

---

## The Mechanism

The model wasn't fabricating. 32,768 is a real figure that appears in the model's training data — it's likely the default context configuration used in benchmarks, documentation, or the model card for this model family.

The failure is a category confusion: the model answered a question about its **runtime configuration** using knowledge about its **typical configuration from training**. These are different things.

At inference time, the model has no introspective access to the parameters llama.cpp used to initialize its context. It doesn't know what `n_ctx` was set to. When asked, it answers the way it would answer "what is Paris?" — from memory, confidently, without flagging that this is something it cannot actually observe.

The same gap applies to other runtime questions a model cannot answer reliably:
- What is your current temperature setting?
- How many tokens have been used in this conversation?
- Are you running in streaming mode?
- What GPU are you running on?

For all of these, the model answers from training knowledge about typical configurations — not from actual runtime state.

---

## What the Human Brought

After the model's confident 32k self-report was noted in the session, the follow-up question was: **"can we trust that output?"**

That instinct — to distrust a model's self-report about its own runtime state — was what triggered the verification step. Without it, 32k would have been logged as the context window for this GPU configuration, which would have been wrong and potentially misleading for anyone using that figure in future experiments.

The model cannot catch this class of error itself. The skepticism had to come from outside.

---

## The Fix

Never trust a model's self-reported context window. Verify from the runtime source:

**From llama.cpp startup logs** (the most reliable source):
```
llama_context: n_ctx         = 14592
```

**From `GET /v1/models`** — not sufficient. The API response returns `n_ctx_train` (the model's training context), not the runtime `n_ctx`:
```json
"meta": { "n_ctx_train": 262144 }
```
This is a training-time property, not what llama.cpp allocated.

**From `ramalama serve` logs** — scroll up past the `🦭 >` prompt or watch the startup output when using `ramalama serve`. The `n_ctx` line appears during context initialization.

The figure is also **runtime-variable**: llama.cpp's `-fit` algorithm sets `n_ctx` based on free VRAM at launch time. Other processes consuming VRAM when the server starts will result in a lower `n_ctx`. The same model on the same GPU may report different context sizes across launches.

---

## The Broader Pattern: Training Knowledge ≠ Runtime State

This failure mode is a specific instance of a general pattern: models answering questions about their current runtime state from training-time knowledge.

A related case is the **frozen clock** — a model defaulting to a stale year when asked the current date, because the training cutoff is the most recent "current year" the model has strong signal for. Same root mechanism, different domain: the model answers from what was true at training time, not from what is true now.

The context window case is subtler because:
1. The number isn't stale — it's plausible for the model family
2. The model has no way to know the answer is wrong
3. The question sounds like a factual query the model should be able to answer

The distinguishing question is: **does the answer require observing the current runtime environment, or does it require recalling training knowledge?** Models can do the latter; they cannot do the former.

---

## When to Trust Model Self-Reports — and When Not To

**Generally trustworthy:** questions about training data, capabilities, limitations, how the model works architecturally, what the model was designed for. These draw on training knowledge the model actually has.

**Not trustworthy:** questions about current runtime configuration, current session state, system resources, current date/time (unless injected into context), or anything that requires observing the live environment rather than recalling from training.

The practical rule: if the answer could vary depending on how the model was started, how much VRAM is available, or what time it is — don't ask the model. Check the runtime source directly.

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

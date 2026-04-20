---
review:
  status: unreviewed
  notes: "AI-generated draft. All figures drawn from the experiment journal (2026-04-20). Numbers are accurate to that session; runtime behavior may vary with different VRAM usage or software versions. Framing and voice need author read."
---

# What a Context Window Actually Is

Most explanations of context windows describe them as a limit — a maximum number of tokens a model can "see" at once. That framing is accurate but thin. It doesn't explain why the number on the model card, the number the model reports when you ask it, and the number you actually get at runtime are often three different figures. It doesn't explain why adding more VRAM changes the number. It doesn't explain why a 32B dense model and a 30B MoE model have very different practical ceilings on identical hardware.

This is an attempt to be more precise.

---

## The Three Numbers

During a session running `qwen3:30b-a3b` on a 20 GB Radeon RX 7900 XT, three different context window figures appeared:

**32,768** — what the model said when asked directly.

**262,144** — what `GET /v1/models` returned in the `n_ctx_train` field.

**14,592** — what llama.cpp reported in the startup logs as `n_ctx`.

These are not three versions of the same fact. They are answers to three different questions.

`n_ctx_train` (262,144) is a property of how the model was trained — the sequence length the training process used. It tells you what the model has seen during training. It says nothing about what can be loaded at runtime.

The self-reported 32,768 is drawn from training knowledge — somewhere in the model's training data, 32k appears as a context window figure for this model family. The model answered a question about its current configuration using that remembered figure, because it has no mechanism to observe its own runtime state. It wasn't wrong that 32,768 is a real number associated with Qwen3; it was answering the wrong question. [(See case study: When the Model Describes a Configuration It Isn't Running)](../case-studies/model-self-report-runtime-state.md)

`n_ctx` (14,592) is the actual allocated context length for that specific launch — the size of the KV cache that was allocated given the VRAM remaining after weights loaded. This is the only figure that matters for how much text you can work with in a single session.

---

## What the KV Cache Is

The context window isn't a reading window the model slides over text. It's a fixed-size allocation that grows with each token — a memory region that holds the key-value pairs from every previous token in the conversation, which the attention mechanism uses to relate new tokens to old ones.

When llama.cpp starts a model, it:

1. Loads the weights into VRAM (~17.5 GB for qwen3:30b-a3b Q4_K)
2. Measures what VRAM remains (~2.5 GB)
3. Allocates a KV cache that fits in the remaining space (~1.4 GB, yielding ~14k tokens)

The KV cache is not dynamically resized as the conversation grows. It's reserved at startup. If your conversation eventually reaches 14,592 tokens, you've filled it. Earlier tokens start getting evicted (using a sliding window or similar strategy depending on configuration).

This is why `n_ctx` is variable. It's not a fixed property of the model — it's determined at launch time by how much VRAM is left after weights load. A second process consuming GPU memory before launch will lower it. A system with 24 GB VRAM instead of 20 GB will get a larger allocation.

---

## Why MoE Changes the Picture

A Mixture-of-Experts model like `qwen3:30b-a3b` routes each token through only a subset of its parameters — 3 billion active parameters per forward pass out of a 30 billion total. The full weights still load into VRAM (17.5 GB in this case), but the *active computation* per token uses far less.

The relevance to context is indirect but significant: because the weight footprint for an MoE model is proportionally smaller than a comparably capable dense model, more VRAM remains for the KV cache. `qwen3:32b` dense loaded 18.8 GB of weights on the same GPU, leaving ~1.2 GB — not enough for a usable KV cache at any context length. The MoE variant's 17.5 GB left 2.5 GB, which accommodated a 14k-token cache.

On a 20 GB card, the 2 GB difference between those two footprints is the difference between a model that runs and one that doesn't. Dense 32B is a 24 GB+ problem; MoE 30B-A3B fits in 20 GB with room for a real conversation.

---

## Why 14k and 1M Are Not the Same Thing Bigger

A common framing: frontier models have 1M context now, so local models with 14k context are just behind. This makes it sound like a quantitative gap — the local model could do similar things with less room to maneuver.

It's a qualitative gap.

At 14k tokens, you can hold approximately:
- One well-scoped task with relevant files
- A few hundred lines of code plus the conversation about it
- A focused debugging session with error context

At 1M tokens, you can hold:
- An entire codebase
- The full history of a multi-session project
- Multiple documents being written simultaneously and cross-referenced
- The kind of workspace-wide context this repository was designed around

The difference isn't just more tokens — it's whether certain workflows are tractable at all. Cross-file reasoning at scale, corpus-level review, session continuity across documents — these are not things that can be approximated by working harder with less context. The architecture of a project like this workspace exists because large context makes it feasible. Adapting the workspace to a 14k-token model would require fundamental redesign, not just tighter prompts.

The practical implication isn't that local models are inferior — it's that they serve different use cases. 14k tokens is enough for most focused coding tasks, single-file review, question-answering against a specific document. It is not enough for workspace-scale reasoning. A clear division of labor — local for private/offline/low-stakes work, frontier API for large-context collaborative reasoning — is more honest than pretending 14k and 1M are interchangeable.

---

## What to Check

When you need to know your actual context window:

**Check the startup logs.** llama.cpp prints `n_ctx = NNNN` during server initialization. This is the authoritative figure. Look for lines like:
```
llm_load_tensors: offloaded 49/49 layers to GPU
...
llama_context: n_ctx      = 14592
```

**Don't ask the model.** It will report a figure from training data, not runtime configuration.

**Don't trust `GET /v1/models`.** The `context_length` or `n_ctx_train` field reflects training metadata, not the allocated KV cache.

**Expect variability.** The same model on the same GPU can allocate different `n_ctx` values depending on what else is using VRAM at launch time. The figure in the startup logs for *this launch* is what you have; future launches may differ slightly.

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. All numerical figures (model sizes, context lengths, token throughput) are drawn from the experiment journal entry dated 2026-04-20 and are accurate to that specific hardware and software configuration. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

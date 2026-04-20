---
review:
  status: unreviewed
  notes: "AI-generated case study draft. Technical figures drawn from the experiment journal (2026-04-20). Pattern and framing need author read."
---

# When the Bus Is the Bottleneck

> **Audience:** Engineers considering hybrid CPU+GPU inference to run large language models their GPU can't fully contain.
> **Purpose:** Documents a failure that looked like a resource availability win — enough RAM to hold the model — but produced an unusable result. The constraint wasn't capacity. It was throughput on the path between resources.

---

## The Setup

The target was `qwen2.5:72b` — a 44 GB model that clearly exceeded the 20 GB GPU. But a 20 GB GPU paired with 62 GB of system RAM suggested a viable path: split the layers between GPU and CPU, run inference with partial hardware offload.

Ollama supports this automatically. When a model exceeds VRAM, it distributes layers between GPU and CPU RAM without user configuration. On paper, the hardware looked adequate:

- GPU: AMD Radeon RX 7900 XT — 20 GB VRAM
- RAM: 62 GB — more than enough for the remaining layers
- Model: 44 GB total — fits across the combined pool

What loaded:

```
load_tensors: offloaded 29/81 layers to GPU
load_tensors: ROCm0 model buffer size  = 16,013.58 MiB  (GPU)
load_tensors: ROCm_Host model buffer size = 28,531.62 MiB  (pinned host RAM)
```

36% on GPU, 64% on CPU. The model was in memory. The server was running.

Time to first token on a short prompt: **more than six minutes.**

---

## What Happened

The model didn't fail. It responded — eventually. But six minutes to first token is not a usable interactive workflow. The experiment was abandoned.

The startup logs showed the reason immediately:

```
llama_context: graph splits = 718 (with bs=512), 3 (with bs=1)
```

718 graph splits.

---

## Why This Number Matters

A graph split is a boundary crossing in the compute graph — a point where execution transfers from GPU to CPU or CPU to GPU. Each crossing moves activations (the intermediate computed values) from one memory domain to the other over the PCIe bus.

During prefill (processing the input prompt), llama.cpp executes 512 tokens at a time by default (`bs=512`). With 29 GPU layers and 52 CPU layers, the layer-by-layer handoff pattern produces **718 PCIe transfers per prefill batch**.

The PCIe bus on this system has a real-world bandwidth of roughly 20–30 GB/s. That sounds fast. But 718 small, synchronous activation transfers per batch — rather than one large sequential transfer — means the bus is constantly interrupted, not streaming. At sequence lengths where batching compounds the effect, the latency compounds with it.

This is not a compute problem. The GPU wasn't too slow. The RAM wasn't too small. The bottleneck was the number of times the activation data had to cross the PCIe bridge between them.

For comparison: generation (single-token decoding, `bs=1`) produced only 3 graph splits — because decoding one token at a time crosses fewer layer boundaries per pass. Generation would have been measurably faster than prefill. But prefill — the step that processes your entire prompt before producing any output — was the chokepoint.

---

## The Counterintuitive Part

The assumption that led here was reasonable: *I have enough combined memory. If the model fits, it should work.*

RAM capacity is the right question to ask about whether a model will load. It's the wrong question to ask about whether it will be usable.

The actual question for hybrid inference is: *how many times per forward pass does execution cross the boundary between the two memory domains?* That's a function of how many layers land on each side, how large the activation tensors are, and what batch size the inference engine uses during prefill.

With a 72B model at 36/64 split, the answer was 718 times per input batch. Adding more RAM — even if available — would have shifted more layers to CPU and made the crossing count worse, not better. The only way to improve throughput from here is to reduce crossings, which means putting more layers on GPU, which means fitting a smaller model fully on GPU.

The fundamental constraint is not capacity. It is **bus bandwidth between heterogeneous memory domains under high-crossing-count inference patterns**.

---

## What the Human Brought

The experiment was designed to test a hypothesis — that hybrid offload could make a 72B model interactive on 20 GB VRAM. The result falsified it conclusively with a specific mechanism and a specific number. The observation that 718 graph splits explained the latency (rather than attributing it to compute speed or RAM bandwidth) was drawn from the startup log data and cross-referenced against llama.cpp's behavior.

The journal entry that documented this — including the six-minute first-token measurement, the layer split breakdown, the graph split count, and the conclusion — provided the factual foundation. What the narrative pass added was the isolation of the **bus crossing count** as the primary variable, distinct from the capacity questions (will it load?) and quality questions (how good are the results?) that typically frame hardware selection discussions.

---

## The Fix

The practical recommendation in the experiment journal was direct: do not attempt hybrid 70B+ inference for interactive use on a single-GPU consumer system.

This isn't a configuration problem with a configuration fix. The graph split count follows from the architecture of the model, the VRAM ceiling, and the batch size. All three are effectively fixed for a given model and GPU pair. The only lever is to choose a different model — one that fits fully on GPU, eliminating the CPU offload path and its associated bus crossings.

On 20 GB VRAM, that means models in the 20–25 GB footprint range. In practice on this hardware: `qwen3:30b-a3b` (MoE, 17.5 GB weights, ~90 tok/s, 14k context) or `qwen2.5:32b` (dense, 18.5 GB weights, 19.4 tok/s, 4k context — requires clean boot for reliable load). Both run fully on GPU, producing 2–3 graph splits rather than 718.

The 72B model remained relevant for batch workloads where time-to-first-token doesn't matter — but that's a different use case and a different setup than a personal coding assistant.

---

## When This Applies — and When It Doesn't

**Applies when:**
- A single GPU with PCIe-connected CPU RAM is the only hardware available
- The model requires layer offload to CPU — any layers running on CPU introduce crossing overhead
- The use case is interactive (prompt-response loop where prefill latency is felt)
- Batch size during prefill is larger than 1 (the default for most inference engines)

**Doesn't apply when:**
- The model fits fully on GPU — GPU-only execution has negligible graph splits regardless of model size
- NVLink connects the GPU and CPU or multiple GPUs — NVLink bandwidth (~112 GB/s bidirectional for RTX 3090 NVLink) reduces but doesn't eliminate the crossing cost; datacenter NVLink/InfiniBand (~600–900 GB/s) changes the calculus entirely
- The workload is batch inference where long prefill times are acceptable — offline summarization, document processing
- `batch_size=1` prefill is explicitly configured and latency on small prompts is the only concern

The graph split count scales with: number of CPU/GPU boundary crossings in the layer graph × batch size × activation tensor size. For interactive use on a single PCIe-connected consumer system, any substantial CPU offload under the default batch sizes produces unusable prefill latency at 70B+ scale.

---

## Related

- [When the Survivor Becomes the Recommendation](survivorship-bias-recommendations.md) — the same experiment sequence produced a second failure mode: framing the only-thing-that-worked as "the recommended default"
- [What a Context Window Actually Is](../ai-engineering/what-a-context-window-actually-is.md) — the MoE model that replaced the 72B target also revealed the three-number context window problem
- [Running a Local LLM: Setup, Tradeoffs, and Real Electricity Cost](../ai-engineering/local-llm-setup.md) — the broader hardware setup guide, including the model selection table that resulted from these experiments
- [Local LLM Experiment Journal](../../research/ai-tooling/local-llm-experiment-journal.md) — the source data: exact commands, layer split counts, graph split measurements, and tok/s figures

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. Technical figures are drawn from the experiment journal entry dated 2026-04-20 and are accurate to that specific hardware and software configuration. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

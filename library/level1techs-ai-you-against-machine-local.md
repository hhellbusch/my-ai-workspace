# Level1Techs — AI and You Against the Machine: Guide so you can own Big AI and Run Local

## Source

- **Channel:** Level1Techs (Wendell)
- **URL:** https://www.youtube.com/watch?v=T17bpGItqXw
- **Duration:** 15:01
- **Published:** 2026
- **Transcript:** [cached](../research/youtube-sources-apr2026/sources/youtube-T17bpGItqXw-transcript.md)
- **Forum tie-in:** [Looking for tips for local LLM — post #2](https://forum.level1techs.com/t/looking-for-tips-for-local-llm/246807/2) (companion tips: MoE picks, llama.cpp Vulkan, LM Studio, gpt-oss)

## Summary

Walkthrough of running a **very large MoE reasoning model** (DeepSeek-class, **~500B total / MoE active subset**) **locally** using **aggressive community quantization** (~20% of original size), **high system RAM** (demo: **128 GB** on AM5 **9800X3D**), **24 GB VRAM** (**RTX 3090**), and a **fork of llama.cpp** tuned for **single-user desktop** throughput and **long context** (demo claims **~48k tokens** “if you get creative,” with GPU KV acting partly as cache). Contrasts **quantization of the real checkpoint** with **distillation** (teacher → smaller student in Ollama/LM Studio): distilled models are **not** the same next-token engine. Argues for **grounding** (paste long documents) to reduce hallucination vs “ask the void.” Notes **AMD 7900 XTX** path still rough for their specific quants on ROCm; praises **Vulkan** path speed on long context.

## Key Themes

- **Own the stack** — Offline, no subscription, reprogrammable; “hope” framed as **local agency** vs corporate AI.
- **MoE + quant + RAM bandwidth** — Big MoE does not activate all parameters per token; **CPU RAM bandwidth** matters because much of the run is **CPU-weighted** in their setup; GPU still helps **KV / depth**.
- **Quantization ≠ distillation** — Their variable-bitweight quant keeps the **original model family** behavior; distilled “DeepSeek teaches Llama/Qwen” checkpoints in Ollama/LM Studio are a **different** product.
- **Software path** — **Community llama.cpp fork** the video brands as “IK” / “kraow” (ASR varies in transcript—**confirm the exact GitHub repo from the Level1 forum how-to** before cloning) for desktop-oriented optimizations; Ollama/LM Studio do not run **their** variable-bitweight quants as-shipped. **Ubuntu 24.04** + NVIDIA driver notes (5000-series / OEM kernel caveats in video).
- **AMD status (as stated in video)** — **7900 XTX “left out for now”** for their quantized workflow: needs **llama.cpp plumbing for ROCm** that was not ready at filming; **Vulkan** on llama.cpp reported **faster than CUDA on NVIDIA** for very long context in their testing; **RDNA + ROCm** still producing bad numerics (“NaN”) in their attempts — **forum collaboration** invited.
- **Use pattern** — Long pasted context (e.g. Wikipedia + injected facts), **RAG-like grounding** before tool-calling; quantized models **worse for codegen** vs Q4/Q8 on perplexity (“no free lunch”).

## Notable Ideas

> “This is how you get AI without hallucinations. You give the AI context for the questions that you're going to ask it.”

> “With Ollama and LM Studio, you're often pretty limited… maybe a few thousand words or tokens worth of context.”

> “Our quantized creation with a variable bitweight doesn't work in Ollama or LM Studio. Need different software.”

> “The Vulkan backend for llama.cpp is actually faster than CUDA even on Nvidia hardware for these really long context windows.”

> “Yeah, they kind of are left out for now.” — on **7900 XTX** vs the featured NVIDIA path for their quants + ROCm.

## Connections to This Workspace

- **Experiment journal:** [`research/ai-tooling/local-llm-experiment-journal.md`](../research/ai-tooling/local-llm-experiment-journal.md) — same problem domain (local Qwen/MoE, **vLLM FP8 MoE** dead end on **gfx1100**, **RamaLama** working path). The video’s **AMD quant gap** rhymes with our **vLLM kernel gap**: different layer of the stack, same lesson (**pick tooling that matches the weights and the GPU**).
- **Stable setup doc:** [`docs/ai-engineering/local-llm-setup.md`](../docs/ai-engineering/local-llm-setup.md) — Ollama/RamaLama/vLLM framing; this video argues a **fourth lane** (custom llama.cpp fork + forum quants) when Ollama/LM Studio caps context or weight format.
- **Hardware delta:** Demo is **128 GB RAM + 24 GB VRAM**; this workspace baseline is **20 GB VRAM** — anything that **spills to CPU** or needs **huge KV** should be scaled with skepticism.

## Personal “Why” (placeholder)

*(Add 2–4 sentences: what you want to borrow from this channel—long-context grounding, distillation vs quant clarity, AMD forum follow-up, etc.)*

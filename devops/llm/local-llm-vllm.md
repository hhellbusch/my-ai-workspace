---
review:
  status: unreviewed
  notes: "AI-generated reference extracted from local-llm-setup.md. Install steps and serve commands mirror the upstream vLLM docs as of 2026-04-20 — verify against live docs before running. AMD ROCm Radeon (consumer gfx1100) commands not verified hands-on on this hardware; Ollama/RamaLama are the verified AMD path."
---

# vLLM Reference: Server-Grade Local Inference

> **Audience:** Engineers who want maximum serving throughput, continuous batching, or a production-grade OpenAI-compatible endpoint. If you just want to run a model for Cursor or Claude Code, start with [the main setup guide](local-llm-setup.md) — Ollama and RamaLama are easier.

**vLLM** targets Linux with a discrete GPU (NVIDIA CUDA or AMD ROCm) and is built for serving throughput via continuous batching and PagedAttention. It pulls models from Hugging Face by ID and serves an OpenAI-compatible HTTP API (default `http://localhost:8000/v1`).

Tradeoffs vs. Ollama/RamaLama: more moving parts (Python environment, GPU stack matched to the exact vLLM build, occasional `hf` CLI login for gated models), stricter hardware requirements, no native Windows build.

---

## Install

The authoritative steps are **[GPU → Set up using Python](https://docs.vllm.ai/en/latest/getting_started/installation/gpu.html#set-up-using-python)**. The commands below mirror that section; if anything disagrees, **trust the live docs** (they change with releases).

### Create a Python environment

Upstream recommends **[uv](https://docs.astral.sh/uv/#getting-started)**:

```bash
uv venv --python 3.12 --seed --managed-python
source .venv/bin/activate
```

### NVIDIA (CUDA)

`uv` selects the PyTorch / CUDA wheel automatically:

```bash
uv pip install vllm --torch-backend=auto
```

With `pip` instead of `uv`, install against the CUDA 12.9 PyTorch index:

```bash
pip install vllm --extra-index-url https://download.pytorch.org/whl/cu129
```

### AMD (ROCm)

vLLM's ROCm wheel bundles a matched PyTorch — don't mix it with an existing ROCm PyTorch build. Requires Python 3.12, glibc ≥ 2.35, and a ROCm version matching the wheel variant (see the **Prebuilt Wheels** table on the upstream GPU install page):

```bash
uv pip install vllm --extra-index-url https://wheels.vllm.ai/rocm/ --upgrade
```

Upstream also documents pinning a specific version/variant and ROCm nightly wheels under `https://wheels.vllm.ai/rocm/nightly/`. Read that subsection before using nightly.

**AMD consumer Radeon note:** The [GPU requirements](https://docs.vllm.ai/en/latest/getting_started/installation/gpu.html#requirements) list supported architectures; if your GPU is not listed, assume build-from-source or unsupported. For RX 7900 XT / gfx1100 (RDNA3), the FP8 MoE kernel path does not work today (see AMD / FP8 MoE section below) — use Ollama or RamaLama for the smoother consumer-AMD experience.

---

## Serve

Pass the Hugging Face model id as a positional argument (not `--model` — deprecated). See the [vLLM `serve` CLI reference](https://docs.vllm.ai/en/latest/cli/serve.html) for all flags.

### NVIDIA — Qwen3-Coder-Next-FP8 (preferred)

```bash
vllm serve Qwen/Qwen3-Coder-Next-FP8 \
  --host 127.0.0.1 \
  --port 8000 \
  --tensor-parallel-size 1 \
  --max-model-len 32768 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder
```

### AMD (ROCm) — Qwen2.5-Coder-32B-Instruct-AWQ (fallback)

vLLM currently errors with `NotImplementedError: No FP8 MoE backend supports the deployment configuration` for `Qwen3-Coder-Next-FP8` on ROCm Radeon. Use AWQ instead:

```bash
vllm serve Qwen/Qwen2.5-Coder-32B-Instruct-AWQ \
  --host 127.0.0.1 \
  --port 8000 \
  --quantization awq \
  --tensor-parallel-size 1 \
  --max-model-len 8192
```

> **Practical reality on 20 GB cards (e.g. RX 7900 XT):** At `max-model-len 1024`, this server boots and answers short prompts — proof-of-concept, not a production interactive workflow. Weights consume ~18.3 GiB, leaving ~0.3 GiB for KV cache (~1.2k tokens). For longer context on the same GPU, `qwen3:30b-a3b` via Ollama or RamaLama is the practical alternative.

Smaller sanity check: `Qwen/Qwen2.5-Coder-7B-Instruct` (no tool-parser flags required).

---

## Container (Docker / Podman)

vLLM publishes OpenAI-compatible images on Docker Hub. Authoritative run flags: [Using Docker](https://docs.vllm.ai/en/latest/deployment/docker.html) (works with Podman too). Prefer a pinned tag over `latest` once you have a known-good build.

### AMD (ROCm)

Image: `docker.io/vllm/vllm-openai-rocm` (`:latest` or `:nightly`). Pass the model id as the first argument after the image — `--model` as a flag is deprecated.

```bash
# Optional: export HF_TOKEN=hf_... if the model requires auth

podman run --rm -it \
  --group-add=video \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  --device /dev/kfd \
  --device /dev/dri \
  -v "${HOME}/.cache/huggingface:/root/.cache/huggingface" \
  --env "HF_TOKEN=${HF_TOKEN:-}" \
  -p 8000:8000 \
  --ipc=host \
  docker.io/vllm/vllm-openai-rocm:latest \
  Qwen/Qwen2.5-Coder-32B-Instruct-AWQ \
  --quantization awq \
  --tensor-parallel-size 1 \
  --max-model-len 1024 \
  --gpu-memory-utilization 0.98 \
  --max-num-seqs 1 \
  --enforce-eager
```

Add `--security-opt label=disable` on SELinux hosts if the cache volume fails. Lower `--max-model-len` if the engine OOMs. For Qwen3 Coder FP8, use NVIDIA + `docker.io/vllm/vllm-openai` or Ollama on AMD.

### NVIDIA (CUDA)

Image: `docker.io/vllm/vllm-openai`. Upstream documents `docker run --runtime nvidia --gpus all` and `podman run --device nvidia.com/gpu=all` with `--ipc=host`. Use `VLLM_ENABLE_CUDA_COMPATIBILITY` if you rely on NVIDIA compatibility mode for older drivers. CUDA is where `Qwen3-Coder-Next-FP8` works today.

---

## AMD ROCm — FP8 MoE gap

`Qwen3-Coder-Next-FP8` and similar FP8 MoE models fail on ROCm Radeon consumer cards (gfx1100) with:

```
NotImplementedError: No FP8 MoE backend supports the deployment configuration
```

The hardware (RDNA3) does support FP8 at the silicon level. The gap is in software: vLLM's `fused_moe_fp8` Triton kernels are tuned for MI300X (gfx942/CDNA3), not RDNA3. No one has contributed gfx1100 autotuning configs for the fused MoE path. See [vLLM #36105](https://github.com/vllm-project/vllm/issues/36105).

**Workarounds for AMD Radeon:**
- Use `qwen2.5-coder:32b-instruct-awq` in vLLM (non-FP8 path)
- Use `qwen3:30b-a3b` via Ollama or RamaLama (llama.cpp, no vLLM FP8 requirement)

**Unlock condition:** vLLM ships gfx1100 Triton kernel configs, or the community contributes them. Watch the vLLM ROCm issue tracker.

---

## Context window limits

With vLLM, the served context cap appears in `GET /v1/models` as `max_model_len`. On a 20 GB card with a large checkpoint:

- Weights consume most of the VRAM (e.g. AWQ 32B: ~18.3 GiB)
- KV cache gets what remains: ~0.3 GiB → ~1.2k tokens at `max-model-len 1024`
- For longer context on 20 GB AMD, use Ollama `qwen3:30b-a3b` (~14k context via llama.cpp auto-fit)

Self-hosting 1M context requires ~128 GB KV cache for a 7B model (6–8× RTX 4090), plus inter-GPU bandwidth that PCIe (~20–30 GB/s) cannot match at interactive speeds. Frontier APIs remain the practical path for 1M context. The consumer cluster sweet spot for interactive use is 32k–128k context on 4–8× high-end consumer GPUs.

---

## Cursor and Claude Code integration

**Cursor:** Settings → Models → OpenAI Base URL → `http://localhost:8000/v1`. Model ID is the Hugging Face repo name (not Ollama tag syntax) or `--served-model-name` if you override it.

**Claude Code:** Use the LiteLLM proxy with the `hosted_vllm/` prefix — see the [main setup guide](local-llm-setup.md#setup-claude-code-with-a-local-model).

**`cursor agent` CLI limitation:** The Cursor IDE supports a custom OpenAI base URL; the `cursor agent` CLI does not. There is no `--openai-base-url` flag or config field to redirect it to a local endpoint. To use a local model from the terminal, reach the API directly via `curl`, [`aichat`](https://github.com/sigoden/aichat), [`llm`](https://github.com/simonw/llm), or any tool that honours `OPENAI_BASE_URL`. As of vLLM 0.19.1 + Cursor CLI (verified 2026-04-20), this remains an open gap.

---

## Cluster topology (buying new hardware)

> ⚠️ *Prices and context figures are rough estimates from an AI-assisted research session (2026-04-20). GPU prices are volatile. Context figures assume a specific KV cache formula and vary with quantization and vLLM version. Treat as order-of-magnitude only.*

**RTX 5090 (Blackwell, 32 GB GDDR7, ~$2,000 MSRP)** is the current single-GPU ceiling. A single card runs 70B Q4 comfortably. NVLink is not supported on consumer cards (dropped after RTX 3090) — multi-GPU means PCIe tensor parallelism.

| Config | VRAM | Approx cost | Context (7B) | Context (70B) | Notes |
|---|---|---|---|---|---|
| 1× RTX 5090 | 32 GB | ~$2,000–4,500 | ~64k | ~4k | Best single-GPU; no multi-GPU pain |
| 2× RTX 5090 (PCIe) | 64 GB | ~$4,000–9,000 | ~128k | ~8k | PCIe bandwidth limit; ~27 tok/s 70B Q4 |
| 4× RTX 5090 (PCIe) | 128 GB | ~$8,000–18,000 | ~256k | ~16k | Diminishing returns on PCIe |

**For K8s / OCP:** A single fat node with 2–4 GPUs and a lightweight 3-node control plane is usually right at this budget — it avoids inter-node network bandwidth penalties. Multi-node pays off when you need more GPU workers than fit one machine, or when OpenShift AI features (model registry, multi-tenancy, auto-scaling) justify the complexity.

**NVLink:** Requires RTX PRO 6000 (workstation tier, 96 GB, ~$6,000–10,000+). Even 4× RTX 5090 at 128 GB is ~8× short of 1M context for a 70B model.

---

*This document was created with AI assistance (Cursor) and has not been reviewed by the author. Install steps mirror upstream vLLM docs as of 2026-04-20. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

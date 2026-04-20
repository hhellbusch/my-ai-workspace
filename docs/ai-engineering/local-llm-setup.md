---
review:
  status: direction-reviewed
  notes: "Author has read and directed this draft. Technical claims (model sizes, VRAM requirements, power draw figures, LiteLLM setup steps, Ollama and vLLM commands — including vLLM on AMD ROCm) need hands-on verification before citing. Electricity measurement methodology not yet validated against real circuit data. Needs fact-checked and commands-verified to reach reviewed."
---

# Running a Local LLM: Setup, Tradeoffs, and Real Electricity Cost

> **Audience:** Technical practitioners curious about running AI locally. The hardware requirements (8 GB VRAM minimum for useful GPU inference) mean this is most relevant to those already comfortable with system administration.
> **Purpose:** Covers why you might want to, what it takes to set it up with Cursor and Claude Code, and how to design an electricity measurement approach using circuit-level monitoring. Setup steps are a starting point for experimentation, not a verified how-to.
>
> ⚠️ **Direction-reviewed.** The direction and content have been read and guided by the author, but the setup steps, model recommendations, and power figures have not been tested on this hardware. Treat as a research starting point, not a verified how-to.

**Experiment journal:** Dated, machine-specific tries (commands, image tags, what worked, what failed) live in [`research/ai-tooling/local-llm-experiment-journal.md`](../../research/ai-tooling/local-llm-experiment-journal.md). Use that file as the running log; keep this article as the stable reference.

---

## The Question Behind the Question

Cloud AI tools (Cursor, Claude, Copilot) work by sending your text to a remote server, getting a response back, and billing you per token or per subscription. For most people, most of the time, that's the right tradeoff — fast, maintained, no hardware to manage.

But there are legitimate reasons to want the model running locally, on your own hardware:

- **Privacy.** Your code, your prompts, your context never leave your network. This matters most when your work involves proprietary code, customer data, or regulated information — for public or open-source work the argument is weaker, but it's relevant to anyone who uses the same tools across contexts.
- **Offline work.** No internet connection required once the model is downloaded.
- **Cost at scale.** At high enough usage, the electricity cost of a local GPU can undercut API fees — but the crossover point is higher than most people expect.
- **Experimentation.** You can run models that aren't available via any API, or run them in ways APIs don't permit.
- **Understanding.** You learn how these systems actually work at the seam between software and hardware.

The electricity angle is the most interesting piece to measure honestly, because the common framing ("self-host to save money") often gets the math wrong.

---

## Two Tools, Two Different Paths

### Cursor with a Local LLM

Cursor has native support for this. Under Settings → Models, you can point Cursor at any OpenAI-compatible API endpoint — and that's exactly what local inference tools expose.

**[Ollama](https://ollama.com/)** is the easiest starting point. It runs as a local server, serves an OpenAI-compatible API at `http://localhost:11434/v1`, and manages model downloads with a single command:

```bash
# Default for this workspace: Qwen3 MoE (~30B class, efficient on ~20 GB VRAM)
ollama pull qwen3:30b-a3b

# Lighter option: Qwen2.5 Coder 7B
# ollama pull qwen2.5-coder:7b
```

In Cursor, set the OpenAI Base URL to `http://localhost:11434/v1` and add the model name. Cursor sends requests to your local machine instead of Anthropic or OpenAI. No internet connection required during use.

**[RamaLama](https://github.com/containers/ramalama)** is Red Hat's CLI tool for running AI models in containers. Instead of manually constructing `podman run` commands with the right device flags, image tags, and model arguments, RamaLama detects your GPU (CUDA, ROCm, or CPU), pulls the appropriate container image, and fetches the model in one command:

```bash
# Available in Fedora repos
sudo dnf install ramalama

ramalama run ollama://qwen3:30b-a3b
```

It supports Ollama and Hugging Face model registries, and multiple inference backends (llama.cpp and vLLM). Useful on Fedora / RHEL systems where it's packaged natively. The tradeoff vs. manual `podman run`: less direct control over fine-grained inference flags (`--enforce-eager`, `--max-model-len`, `--gpu-memory-utilization`), which matter when you're at the edge of available VRAM. For routine model runs where defaults work, it significantly reduces friction.

To serve an OpenAI-compatible API endpoint (for Cursor or LiteLLM):

```bash
ramalama serve ollama://qwen3:30b-a3b
# API at http://127.0.0.1:8080/v1  (use 127.0.0.1, not localhost — IPv4 only)
# Model ID: library/qwen3
```

llama.cpp auto-fits context to available VRAM — on a 20 GB card with `qwen3:30b-a3b`, runtime `n_ctx` is ~14,592 tokens (reduced from 262k training context). Check actual `n_ctx` in startup logs, not `GET /v1/models` (that returns `n_ctx_train`, not the runtime value).

**[LM Studio](https://lmstudio.ai/)** takes the same approach with a graphical interface — useful if you prefer not to use the command line. Its local server runs at `http://localhost:1234/v1`.

**[vLLM](https://docs.vllm.ai/)** targets **Linux** machines with a **discrete GPU** — **NVIDIA (CUDA)** or **AMD (ROCm)** — not CPU-only setups. It pulls models from the **Hugging Face Hub** by ID, serves an **OpenAI-compatible** HTTP API (default `http://localhost:8000/v1`), and is built for **serving throughput** (continuous batching, PagedAttention). Tradeoffs versus Ollama: more moving parts (Python environment and **GPU stack matched to the exact vLLM build** — CUDA *or* ROCm wheels, occasional `hf` CLI login for gated models). Upstream does **not** ship native Windows builds; see the [GPU install guide](https://docs.vllm.ai/en/latest/getting_started/installation/gpu.html) (WSL note there).

**Install vLLM (follow upstream):** the authoritative steps are **[GPU → Set up using Python](https://docs.vllm.ai/en/latest/getting_started/installation/gpu.html#set-up-using-python)**. The commands below mirror that section so this article stays consistent with it; if anything disagrees, **trust the live docs** (they change with releases).

1. **Create a new Python environment** — upstream recommends **[uv](https://docs.astral.sh/uv/#getting-started)**:

```bash
uv venv --python 3.12 --seed --managed-python
source .venv/bin/activate
```

2. **Pre-built wheels**

**NVIDIA (CUDA)** — `uv` selects the PyTorch / CUDA wheel from the driver (see upstream note on `--torch-backend=auto`):

```bash
uv pip install vllm --torch-backend=auto
```

If you use **pip** instead of `uv`, upstream documents installing against the CUDA 12.9 PyTorch index, for example:

```bash
pip install vllm --extra-index-url https://download.pytorch.org/whl/cu129
```

**AMD (ROCm)** — vLLM’s ROCm wheel **bundles** a matched PyTorch; upstream warns not to mix it with an arbitrary pre-existing ROCm PyTorch build. Install from the ROCm wheel index (Python **3.12**, **glibc ≥ 2.35**, and a **ROCm version that matches the wheel variant** you pick — see the **Prebuilt Wheels** table on the same page):

```bash
uv pip install vllm --extra-index-url https://wheels.vllm.ai/rocm/ --upgrade
```

Upstream also documents **pinning** a version and variant (e.g. `…/rocm/${VLLM_VERSION}/${VLLM_ROCM_VARIANT}`), **discovering** the current variant via `https://wheels.vllm.ai/rocm/vllm`, and **ROCm nightly** wheels under `https://wheels.vllm.ai/rocm/nightly/` (with additional constraints — read that subsection before using it). If you must use **pip** against ROCm, upstream requires an **exact** wheel version and `--extra-index-url`; see the **Caveats for using pip** note on that page.

**AMD personally:** vLLM’s ROCm path is **stricter than Ollama’s**. The [GPU requirements](https://docs.vllm.ai/en/latest/getting_started/installation/gpu.html#requirements) list supported architectures (for example **Radeon RX 7900 / RX 9000**, MI series, Ryzen AI — exact set and ROCm floor change by release). If your GPU is not listed, assume **build-from-source or unsupported** and prefer **Ollama with ROCm** for a smoother consumer-AMD experience. When vLLM does match your hardware, install **system ROCm** to match the wheel variant you install, then use the commands above.

**Serve** (either vendor — see the [vLLM `serve` CLI reference](https://docs.vllm.ai/en/latest/cli/serve.html) for `--gpu-memory-utilization`, `--max-model-len`, `--tensor-parallel-size`, quantization, and ROCm-specific flags if any). Pass the **Hugging Face model id as a positional argument** (not `--model`), per current `vllm serve` CLI warnings.

**NVIDIA (CUDA)** — **`Qwen/Qwen3-Coder-Next-FP8`** (FP8 MoE) is the workspace’s preferred Qwen3 Coder build when vLLM can load it:

```bash
vllm serve Qwen/Qwen3-Coder-Next-FP8 \
  --host 127.0.0.1 \
  --port 8000 \
  --tensor-parallel-size 1 \
  --max-model-len 32768 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder
```

**AMD (ROCm), consumer Radeon (e.g. RX 7900 XT):** vLLM currently errors with **`NotImplementedError: No FP8 MoE backend supports the deployment configuration`** for **`Qwen3-Coder-Next-FP8`** — observed on **stable and `vllm-openai-rocm:nightly`** (FP8 MoE paths still effectively **MI-class–oriented**). See [vLLM #36105](https://github.com/vllm-project/vllm/issues/36105). Use a **non–FP8-MoE** checkpoint instead, for example **AWQ**:

```bash
vllm serve Qwen/Qwen2.5-Coder-32B-Instruct-AWQ \
  --host 127.0.0.1 \
  --port 8000 \
  --quantization awq \
  --tensor-parallel-size 1 \
  --max-model-len 8192
```

Other practical paths on AMD: **RamaLama** or **Ollama** with `qwen3:30b-a3b`. On **Fedora / RHEL**, **[RamaLama](https://github.com/containers/ramalama)** (`sudo dnf install ramalama`) is the best-tested single-command path — it auto-detects ROCm, pulls `quay.io/ramalama/rocm:latest`, and provides **~10k–15k context** on a 20 GB card (runtime variable; llama.cpp fits context to available VRAM at launch). Verified on RX 7900 XT / gfx1100. Note: native Ollama container path not directly compared in testing — RamaLama was adopted early and not benchmarked against the manual `podman run ollama/ollama:rocm` alternative. See [experiment journal](../../research/ai-tooling/local-llm-experiment-journal.md) for full results.

Smaller HF sanity check: `Qwen/Qwen2.5-Coder-7B-Instruct` (no tool-parser flags required).

In **Cursor** → Settings → Models, set the OpenAI base URL to `http://localhost:8000/v1` and choose a model id that matches what the server exposes — typically the same string you passed to `vllm serve` (or `--served-model-name` if you override it). vLLM does not use Ollama’s tag syntax (`qwen3:30b-a3b`); you map by Hugging Face repo name instead.

**Local context vs Cursor chat:** With a typical **cloud** model, Cursor can fold a lot into each turn — long thread history, workspace rules, files you reference, and tool output — within a large managed budget. With a **local** vLLM endpoint, the model only sees what fits the server’s **`max_model_len`** and the **KV cache** your GPU can actually hold. On a large checkpoint with tight VRAM, that can shrink to **roughly a thousand tokens** or so — enough for short prompts, not a substitute for a sprawling IDE session. The served cap appears in **`GET /v1/models`** (e.g. `max_model_len`). If you need longer coherent context on consumer hardware without fighting VRAM, **Ollama** or a **smaller** model in vLLM (so you can raise `max_model_len`) is usually the better match.

This isn't just a quantitative gap — it's a qualitative one. Frontier models available via Cursor or the Anthropic API (e.g. **Claude Sonnet 4.6 with adaptive thinking**, which has a **1M token context in beta as of early 2026**) can operate at context windows roughly **1,000×** what a large-checkpoint/tight-VRAM local server can sustain. Adaptive thinking adds a further dimension: a dynamic reasoning budget that scales with problem complexity, improving multi-step logic, planning, and ambiguous problems. Local models (including 32B class) don't have an equivalent mode. The local value proposition is **privacy, zero marginal token cost, and offline availability** — not raw capability parity with frontier models. Both can be the right tool; they're not interchangeable. *(Note: the 1M context figure is specific to Sonnet 4.6 in beta; earlier Sonnet versions have ~200k context. Verify current limits at [platform.claude.com/docs](https://platform.claude.com/docs/en/build-with-claude/context-windows).)*

**Can you self-host 1M context?** Technically, but with severe constraints. The KV cache for a 7B model at 1M tokens is **~128 GB** — already requiring 6–8× RTX 4090 (24 GB each). The real blocker is not VRAM count but **inter-GPU bandwidth**: consumer GPUs communicate over PCIe (~20–30 GB/s real), while datacenter hardware uses NVLink/NVSwitch (900 GB/s) or InfiniBand. At 1M context, shuffling KV cache across PCIe on every decode step makes throughput painful. A multi-node **OpenShift / vLLM** cluster on consumer GPUs *could* sustain 1M context for batch workloads; for interactive use it would be very slow. The **realistic consumer cluster sweet spot** for interactive use is **32k–128k context** on 4–8× high-end consumer GPUs. For true 1M context at reasonable throughput, **frontier APIs remain the practical path** — H100 nodes run ~$200k+, and even the AMD MI300X (192 GB HBM3, single card — theoretically fits 1M context for a 7B model) is enterprise-only hardware at ~$10–15k, not consumer-purchasable.

**`cursor agent` CLI limitation:** The **Cursor IDE** supports a custom OpenAI base URL (Settings → Models), which is how you point it at a local vLLM or Ollama server. The **`cursor agent` CLI** does not — it routes through Cursor's own agent backend; there is no `--openai-base-url` flag or `cli-config.json` field to redirect it to a local endpoint. To use a local model from the terminal, reach the OpenAI-compatible API directly via `curl`, [`aichat`](https://github.com/sigoden/aichat), [`llm`](https://github.com/simonw/llm), or any other tool that honours `OPENAI_BASE_URL` / `OPENAI_API_KEY`. As of **vLLM 0.19.1 + Cursor CLI** (verified 2026-04-20), this remains an open gap.

**Upstream container (Docker / Podman):** vLLM publishes OpenAI-compatible images on Docker Hub; the authoritative run flags are in **[Using Docker](https://docs.vllm.ai/en/latest/deployment/docker.html)**. That page states the image works with **Podman** as well as Docker. Prefer a **pinned tag** (not only `latest`) once you have a known-good build.

**AMD (ROCm)** — image **`docker.io/vllm/vllm-openai-rocm`** (`:latest` or `:nightly`). Run shape matches upstream (devices, `ipc`, HF cache). On **Radeon**, do **not** expect **`Qwen3-Coder-Next-FP8`** to load (FP8 MoE backend gap); the example below uses **`Qwen2.5-Coder-32B-Instruct-AWQ`** instead. **`--model` as a flag is deprecated** — pass the model id as the **first argument** after the image.

> **Practical reality on 20 GB cards (e.g. Radeon RX 7900 XT):** `Qwen2.5-Coder-32B-Instruct-AWQ` at 1024 max tokens is a **server that boots and answers short prompts** — a working proof-of-concept, not a production interactive workflow. Weights consume ~18.3 GiB, leaving only ~0.3 GiB for KV cache (~1.2k tokens). For longer context on the same GPU, `qwen3:30b-a3b` via Ollama is the practical alternative until FP8 MoE lands on ROCm Radeon. See the [experiment journal](../../research/ai-tooling/local-llm-experiment-journal.md) for the full failure path and what it took to get here.

```bash
# Optional: export HF_TOKEN=hf_... if the model or your HF policy requires auth

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

Add `--security-opt label=disable` on SELinux hosts if the cache volume fails. Lower **`--max-model-len`** if the engine OOMs. For **Qwen3 Coder FP8** specifically, use **NVIDIA** + **`docker.io/vllm/vllm-openai`** or **Ollama** on AMD.

**NVIDIA (CUDA)** — image **`docker.io/vllm/vllm-openai`**; upstream documents `docker run --runtime nvidia --gpus all` and **`podman run --device nvidia.com/gpu=all`** with `--ipc=host` (or `--shm-size` instead — see the same page). Use **`VLLM_ENABLE_CUDA_COMPATIBILITY`** there if you rely on NVIDIA’s compatibility mode for older drivers. **CUDA** is where **`Qwen3-Coder-Next-FP8`** is expected to work in vLLM today.

### Claude Code with a Local LLM

Claude Code is harder because it's hardcoded to call Anthropic's servers. There's no native "use a different endpoint" setting. The workaround is a proxy layer: **[LiteLLM](https://litellm.ai/)** sits between Claude Code and your local model, accepting Anthropic-formatted requests and translating them for whatever backend you're running.

The architecture looks like this:

```
Claude Code → LiteLLM Proxy (port 4000) → Ollama / vLLM → local GPU
```

Setup:

```bash
pip install 'litellm[proxy]'
```

Create a `config.yaml` that maps Claude model names to your local model.

**Backend: Ollama**

```yaml
model_list:
  - model_name: claude-3-5-sonnet-20241022
    litellm_params:
      model: ollama/qwen3:30b-a3b
      api_base: 'http://localhost:11434'
```

**Backend: vLLM** — LiteLLM routes these with the [`hosted_vllm/` prefix](https://docs.litellm.ai/docs/providers/vllm) (OpenAI-compatible HTTP server). Use the **same model id** vLLM was started with (or `--served-model-name`). On **ROCm Radeon**, match whatever you actually serve (often **AWQ** Qwen2.5 Coder 32B, not Qwen3 FP8):

```yaml
model_list:
  - model_name: claude-3-5-sonnet-20241022
    litellm_params:
      model: hosted_vllm/Qwen/Qwen2.5-Coder-32B-Instruct-AWQ
      api_base: 'http://localhost:8000'
```

Start the proxy:

```bash
litellm --config config.yaml --port 4000
```

Point Claude Code at it:

```bash
export ANTHROPIC_BASE_URL="http://localhost:4000"
export ANTHROPIC_API_KEY="sk-anything"
claude
```

The `ANTHROPIC_API_KEY` value doesn't matter — LiteLLM ignores it since there's no cloud authentication happening.

---

## What Hardware You Actually Need

The critical constraint is **VRAM** — the memory on your GPU. The model weights have to fit there.

| VRAM | Model size you can run | Examples |
|------|----------------------|---------|
| 6–8 GB | 7–9B parameters | Qwen 2.5 Coder 7B, Llama 3.1 8B |
| 10–12 GB | 12–14B parameters | Gemma 3 12B, Phi-4 14B |
| 16–24 GB | 22–35B parameters | Qwen 32B, DeepSeek-R1 32B |
| 48 GB+ | 70B+ parameters | Llama 3.3 70B, Qwen 72B |

Common consumer GPUs: RTX 4060 (8 GB), RTX 4070 (12 GB), RTX 4090 (24 GB).

For coding assistance specifically, a 7B–8B quantized model (4-bit, Q4_K_M) running on a mid-range GPU gives roughly 40–80 tokens per second — fast enough for interactive use. The quality gap between a local 7B model and a frontier cloud model (Claude 3.5 Sonnet, GPT-4o) is real and meaningful for complex work; less so for routine tasks.

**Without a GPU:** Ollama will use CPU-only mode if no GPU is available. Expect 7–15 tokens per second on a modern CPU, which is usable but noticeably slower. You need enough system RAM to hold the model — 16 GB minimum for a 7B model, 32 GB for a 13B. vLLM is not aimed at that path; use Ollama, LM Studio, or `llama.cpp`-style runners instead.

Apple Silicon (M-series Macs) uses unified memory — the same memory pool serves CPU and GPU, so even base configurations with 16–32 GB can run meaningful models efficiently, and the power draw is dramatically lower than a desktop GPU setup.

---

## Evaluating Your Current Setup on Linux

Before choosing a model or tool, run these commands to understand what you're working with. The GPU section is the most important — VRAM is the hard constraint everything else follows from.

### GPU — the critical check

First, identify whether you have a GPU and which vendor:

```bash
lspci | grep -Ei "vga|3d|display"
```

**If you have an NVIDIA GPU** (and the drivers are installed):

```bash
nvidia-smi
```

This gives you the GPU model, total VRAM, free VRAM, current power draw in watts, and temperature. For a one-line summary you can script against:

```bash
nvidia-smi --query-gpu=name,memory.total,memory.free,power.draw,temperature.gpu \
  --format=csv,noheader
```

Example output: `NVIDIA GeForce RTX 4070, 12288 MiB, 11800 MiB, 15.23 W, 42 C`

Cross-reference the `memory.total` value against the VRAM table above. `memory.free` tells you what's available *right now* — if the desktop environment is consuming GPU memory, it shows up here.

To watch power draw live in one-second intervals (useful for establishing your baseline before running a model):

```bash
nvidia-smi dmon -s pcut -d 1 -c 10
```

`-s pcut` selects power, compute utilization, memory utilization, and temperature. `-c 10` captures 10 samples and exits. This is your pre-inference baseline — run it before starting Ollama or vLLM to get a steady-state number.

**If you have an AMD GPU** (and ROCm is installed):

```bash
rocm-smi
```

If ROCm is not installed, `radeontop` provides similar real-time GPU metrics:

```bash
sudo dnf install radeontop   # Fedora
radeontop
```

**If no discrete GPU is detected:** Ollama will run in CPU-only mode automatically; vLLM is unlikely to be viable here. Continue to the RAM and CPU sections — those become the relevant constraints.

---

### RAM — needed for CPU-only mode, also KV cache overhead

```bash
free -h
```

The `total` value under `Mem:` is what you have. For GPU inference, this matters less (model weights live in VRAM); for CPU-only inference, system RAM *is* the VRAM equivalent and must hold the entire model.

For more detail on what's installed (speed, number of channels):

```bash
sudo dmidecode -t memory | grep -E "Size|Speed|Type:|Locator:" | grep -v "No Module"
```

Dual-channel RAM (two populated slots) meaningfully improves CPU-only inference throughput because memory bandwidth is the bottleneck during token generation.

---

### CPU — throughput when no GPU is available

```bash
lscpu | grep -E "Model name|^CPU\(s\)|Thread\(s\) per core|Cache"
```

The L3 cache size is particularly relevant — larger L3 cache improves throughput for the matrix operations that dominate inference. For a quick benchmark of raw memory bandwidth (the actual bottleneck for CPU inference):

```bash
sudo dnf install stream   # Fedora — may need epel
stream
```

If `stream` isn't available, the tokens-per-second number Ollama reports when you first run a model is a practical benchmark you already have.

---

### Storage — model download size and load time

Models are large. A 7B quantized model (Q4_K_M) is roughly 4–5 GB; a 13B is 8–9 GB; a 70B is 40+ GB. Check available space and whether your drive is NVMe (fast load times) or SATA (slower, but adequate once loaded):

```bash
df -h ~
lsblk -d -o NAME,SIZE,ROTA,MODEL
```

`ROTA=0` means SSD or NVMe; `ROTA=1` means spinning disk. Model load time from NVMe is seconds; from spinning disk it can be 30–60 seconds for a large model. Once loaded into VRAM, storage type doesn't affect inference speed.

---

### Putting it together

After running the above, you can locate yourself in the requirements table:

- **VRAM ≥ 8 GB:** You can run a 7B–8B model fully on GPU — fast, interactive, good for coding tasks.
- **VRAM 4–6 GB:** Small models only (3–4B), or partial GPU offload for larger models with degraded speed.
- **No discrete GPU, RAM ≥ 16 GB:** CPU-only, 7–15 tokens/second — usable for non-interactive tasks, patience required for chat.
- **No discrete GPU, RAM ≥ 32 GB:** CPU-only 13B model — better quality, similar speed constraints.

The `nvidia-smi dmon` baseline power reading from before you start Ollama or vLLM is directly useful for the electricity measurement work on **NVIDIA**: it establishes what the system draws at idle, so you can subtract it from the inference-load reading to isolate the model's actual cost. On **AMD**, capture the same idea with `rocm-smi` (power and utilization) at idle before you launch the server, then again under load.

---

## Matching Model Size to Task Complexity

VRAM determines what you *can* run. Task complexity determines what you *should* run. Those are different questions, and conflating them is the most common mistake in local LLM setup guides.

### The task complexity spectrum

| Complexity tier | Example tasks | Minimum model size |
|----------------|--------------|-------------------|
| **Syntax / lookup** | Code completion, docstring generation, explaining a single function, answering a factual question | 7B–8B |
| **Single-file reasoning** | Refactoring one file, writing a troubleshooting guide, summarizing a document | 7B–8B |
| **Multi-file reasoning** | Cross-referencing configs across a repo, writing YAML that depends on values in other files, editing while preserving patterns elsewhere | 13B–32B |
| **Domain synthesis** | Kubernetes networking diagnosis across YAML + logs + docs, Helm chart authorship with OLM upgrade chain logic, Ansible playbook design against an existing role structure | 32B |
| **Agentic multi-step** | Multi-stage research pipelines (fetch → analyze → cross-reference → file), spar/adversarial review across a document corpus, planning and executing a session handoff autonomously | 70B+ |
| **Voice-consistent writing** | Essay drafting that must sound like a specific person, maintaining tone and stance across multiple documents in a series | 70B+ |

Quality doesn't fall off a cliff — it degrades gradually. A 7B model will attempt any of these; it just produces noticeably weaker results as complexity increases, and becomes unreliable for agentic workflows (it loses track of what it was doing mid-task).

*These are estimated thresholds based on task analysis, not benchmarked results. Actual degradation depends on the specific model, quantization level, and prompt quality. Testing a smaller model first is the right approach — your own observations are more reliable than this table.*

### Where this workspace sits

This workspace is not a simple coding assistant use case. An honest survey:

- **790 markdown files across 12 product domains** — cross-file reasoning is the norm, not the exception
- **235 YAML files** (Ansible playbooks, Helm charts, ArgoCD apps, OCP configs) — generating or modifying any of these correctly requires understanding relationships with other files
- **Agentic workflows** (research-and-analyze skill, multi-stage meta-prompt pipelines, 27 slash commands) — these are multi-step autonomous tasks; a model that loses coherence mid-chain produces silently wrong output, which is worse than an error
- **Essay writing with preserved voice** — the philosophy and AI-engineering essay tracks require consistency in stance and tone across sessions; a smaller model will drift toward generic prose

**32B is the threshold where we expect quality to become consistent** for this workspace — but that's a hypothesis, not a finding. The purpose of the electricity measurement work and this guide is to answer that question through experimentation. Start with whatever model fits your hardware, observe where it degrades, and use that as your actual calibration point. A 7B or 13B model may handle more than the complexity table suggests for your specific tasks; a 32B may still struggle with the agentic workflows. There's no substitute for running it.

### Recommended models by use case (2026)

**A note on MoE (Mixture of Experts):** Several models in this table use MoE architecture — `qwen3:30b-a3b`, `Qwen3-Coder-Next-FP8`. Instead of every token passing through all of the model's parameters, a MoE model has many small "expert" sub-networks and a router that activates only a few per token. For `qwen3:30b-a3b`: 30B total parameters across 128 experts, but only ~3B active per token (the `a3b` suffix). This matters for consumer hardware in two ways: (1) **speed** — compute per token is equivalent to a 3B dense model, so throughput is much higher than a true dense 30B; (2) **VRAM** — the full 30B still has to fit in VRAM (all experts stored), but active compute is small. The tradeoff is that MoE routing can be less consistent than dense models on unusual inputs; in practice for coding and technical tasks the difference is small. This is the architecture behind Mixtral, and is widely believed to underlie GPT-4 (unconfirmed by OpenAI), among other recent large models.

For coding and DevOps work specifically, **this workspace targets the Qwen3 line** where the stack allows it; on **AMD + vLLM**, **`Qwen2.5-Coder-32B-Instruct-AWQ`** is the practical default until FP8 MoE works on Radeon.

| Model | Size | VRAM needed | Good for |
|-------|------|------------|---------|
| `Qwen/Qwen3-Coder-Next-FP8` (vLLM / HF) | ~80B total, small active MoE | ~20 GB (tune `--max-model-len`; may OOM on marginal cards) | **Primary on NVIDIA vLLM:** repo-scale edits, tool use — [model card](https://huggingface.co/Qwen/Qwen3-Coder-Next-FP8). **Not for vLLM + ROCm Radeon** today (no FP8 MoE backend; nightly does not fix on 7900-class). |
| `Qwen/Qwen2.5-Coder-32B-Instruct-AWQ` (vLLM / HF) | 32B AWQ | ~20 GB | **Primary on AMD vLLM:** same workload intent as above when FP8 Qwen3 cannot load. **On 20 GB cards (e.g. 7900 XT), weights consume ~18.3 GB, leaving ~1k tokens of KV cache** — server boots and answers short prompts, but this is effectively a proof-of-concept, not a production interactive workflow. For longer context on the same GPU, Ollama `qwen3:30b-a3b` is the practical alternative. |
| `qwen3:30b-a3b` (Ollama / RamaLama) | 30B-class MoE | ~19.5 GB | **Best available on 20 GB AMD cards:** ~14k context (runtime variable — llama.cpp auto-fits from 262k training context based on free VRAM at launch; expect 10k–15k depending on system state). 1-command setup via RamaLama. Thinking variant. Verified on RX 7900 XT / gfx1100. Note: thinking mode adds latency on short prompts — faster for complex reasoning, slower for routine completions. |
| `qwen2.5-coder:7b` | 7B | 6–8 GB | Quick lookups, simple edits, learning the workflow |
| `qwen2.5-coder:32b` / `qwen3:32b` | 32B dense | **24 GB+** | Dense 32B needs 24 GB+ VRAM. Weights (~18.5 GB) load fully onto GPU, but KV cache + compute graph reservation overflows the remaining ~1.7 GiB (verified OOM on RX 7900 XT with `ramalama serve`, which sets n_parallel=4 × KV cache). `ramalama run` (n_parallel=1) or Q3_K_M quantization (~13–14 GB) may fit — untested. For reliable full-quality 32B, RTX 4090/5090 class (24 GB+) required. |
| `llama3.3:70b` | 70B | 48 GB+ | Agentic tasks, research synthesis, essay writing |
| `deepseek-r1:32b` | 32B | 20–24 GB | Reasoning-heavy tasks; slower but stronger on multi-step logic |

**Qwen3-Coder-Next FP8** is aimed at coding agents and IDE-style tool loops when **vLLM runs it** (typically **CUDA**). On **ROCm Radeon**, use **AWQ Qwen2.5 Coder 32B** in vLLM or **Qwen3 MoE** (`qwen3:30b-a3b`) in Ollama. For essay and research work, a general-purpose **70B** is still a better fit than a coding-specialized model.

### What this means for hardware

The 32B threshold is the inflection point. Getting there requires approximately 20–24 GB VRAM — two RTX 4070s (24 GB combined), a single RTX 4090 (24 GB), or a professional card like the RTX A5000 or 6000. The 70B threshold requires 48 GB+ — typically two RTX 4090s or a single A100/H100.

If your current hardware lands below 20 GB VRAM, the practical options are:
1. Run a 7B–13B model locally for routine tasks, stay on cloud APIs for complex work
2. Use CPU+GPU split offloading for 32B models (Ollama supports this automatically) — slower, but functional
3. Treat local inference as a privacy/offline capability, not a quality replacement for frontier models

### Building a cluster — cost vs. context sweet spot (if buying new)

If you're building rather than using existing hardware, the landscape as of **early 2026** looks like this:

**Latest consumer flagship:** The **RTX 5090** (Blackwell, 32 GB GDDR7, 1,792 GB/s memory bandwidth, ~$2,000 MSRP / $2,000–4,500 real) is the current single-GPU ceiling. A single card comfortably runs **70B Q4** and handles reasonable context without multi-GPU complexity. **NVLink is not supported** — NVIDIA dropped it from consumer cards after the RTX 3090; multi-GPU on consumer hardware means PCIe tensor parallelism.

**Multi-GPU (PCIe tensor parallel):** Two RTX 5090s (64 GB combined) via PCIe yield ~27 tok/s on 70B Q4 models. Workable, but the PCIe bandwidth ceiling (~20–30 GB/s real) means context length and throughput are both constrained compared to NVLink-connected hardware. For NVLink you need the **RTX PRO 6000** (workstation tier, 96 GB, ~$6,000–10,000+).

**Cluster topology sweet spot (latest gen, new hardware):**

> ⚠️ *All prices and context figures in this table are rough estimates from an AI-assisted research session (2026-04-20). GPU prices are volatile. Context figures assume a specific KV cache budget formula and will vary with quantization, model architecture, and vLLM version. Treat as order-of-magnitude only — verify against current retailer prices and vLLM docs before purchasing.*

| Config | VRAM | Approx cost | Context (7B) | Context (70B) | Notes |
|---|---|---|---|---|---|
| 1× RTX 5090 | 32 GB | ~$2,000–4,500 | ~64k | ~4k | Best single-GPU buy; no multi-GPU pain |
| 2× RTX 5090 (1 node, PCIe) | 64 GB | ~$4,000–9,000 | ~128k | ~8k | PCIe bandwidth limit; ~27 tok/s 70B Q4 |
| 4× RTX 5090 (1 node, PCIe) | 128 GB | ~$8,000–18,000 | ~256k | ~16k | PCIe bottleneck compounds; diminishing returns |
| 4× RTX 5090 + OCP/K8s cluster | 128 GB | ~$12,000–22,000 | ~128k (network hurt) | ~8k | Multi-node adds 25GbE cost + latency |

**For K8s/OCP specifically:** A single fat node with 2–4 GPUs and a lightweight 3-node control plane (cheap mini PCs or VMs) is usually the right call at this budget — it avoids inter-node network bandwidth penalties. Multi-node only pays off when you need more GPU workers than fit one machine, or when OCP features (model registry, multi-tenancy, auto-scaling) justify the complexity.

**The honest ceiling:** Even 4× RTX 5090 at 128 GB is still ~8× short of 1M token context for a 70B model. Frontier-class long context remains cloud territory unless you can get **datacenter hardware** (MI300X at 192 GB/card, H100 80 GB SXM) funded — typically a business or research institution purchase.

---

## PAI / Kai and Agentic Personal AI

Daniel Miessler's [PAI (Personal AI Infrastructure)](https://danielmiessler.com/blog/personal-ai-infrastructure) architecture (and his personal implementation, Kai) represents the upper end of the personal use case. It's worth understanding as a reference point for where local AI infrastructure is heading.

PAI's core is "The Algorithm" — two nested loops: a Current State → Desired State outer loop, and a seven-phase scientific method inner loop (Observe, Think, Plan, Build, Execute, Verify, Learn). Every task is decomposed into granular, binary, testable Ideal State Criteria. The system uses 67 skills, 333 workflows, 17 hooks, and a three-tier memory architecture (session, work, learning). Kai runs on Claude Code, primarily against the Anthropic API.

**What this requires from a local model:** The two-loop Algorithm is demanding in specific ways. The model must:
- Decompose goals correctly and maintain that decomposition across many steps
- Select and invoke tools reliably without drifting off task
- Self-verify outputs against binary criteria without prompting
- Manage context across a large system prompt (PAI's assembled `SKILL.md` is substantial)

In practice, running a PAI-style architecture reliably against a local model requires **70B+ or a frontier-class model via API**. Miessler himself notes that when output is bad, it's almost never the model — it's the scaffolding. That's true, but only once you're above the coherence threshold. Below 32B, the model itself becomes the bottleneck for agentic tasks.

The library entry at [`library/daniel-miessler-pai.md`](../../library/daniel-miessler-pai.md) has a full breakdown of the architecture components and where this workspace's patterns converge and diverge from PAI. The relevant backlog item ("Explore Miessler's PAI/Kai architecture") is the active thread for going deeper on this.

---

## A Note on Guide Scope and Audiences

This guide covers the **personal/home hardware** use case. But local model deployment spans a much wider range. Three distinct audiences, three distinct guides:

**This guide — Personal / hobbyist**
Home hardware, Ollama or LM Studio (or **vLLM on a single Linux workstation with an NVIDIA or supported AMD GPU** if you want maximum serving throughput and can manage the stack), circuit-level electricity monitoring, privacy and experimentation. The entry point for most individuals.

**Agentic personal AI (PAI/Kai pattern) — *forthcoming***
Model selection and hardware for autonomous agent architectures. Memory systems, scaffolding design, running The Algorithm reliably. The power-user extension of this guide. Will draw from the PAI/Kai research in [`research/pai-kai-paude/`](../../research/pai-kai-paude/) and [`library/daniel-miessler-pai.md`](../../library/daniel-miessler-pai.md).

**Enterprise inference serving — OpenShift AI**
The same vLLM *binary* can run on a laptop or a cluster, but **operations at scale** — vLLM on GPU-enabled Kubernetes nodes, KServe, Red Hat OpenShift AI (RHOAI), multi-tenancy, compliance, governance — is a different problem space from a single-user desktop. That tier is documented in [Enterprise LLM Deployment on OpenShift AI](openshift-ai-llm-deployment-summary.md) with a full verification assessment of the economics and architecture claims.

The questions sound similar — "how do I run a model locally?" — but the hardware, the tooling, the tradeoffs, and the right answer differ enough that a single guide would have to be long and qualified to the point of being unusable.

---

## The Electricity Picture

This is where having real circuit-level data *will* change the conversation — once the measurements are taken. The monitoring setup is in place and has been capturing whole-home circuit data for over a year. What follows is the research plan: the methodology for isolating LLM inference cost from baseline draw. No LLM workloads have been measured yet; the case studies come later.

Published estimates for system-level power draw under AI inference load:

| Hardware | Approx. draw under load |
|----------|------------------------|
| Mac Studio M4 Max | 60–100 W |
| RTX 4060 Ti system | 140–175 W |
| RTX 4080 Super system | ~340 W |
| RTX 4090 system (stock) | 500–600 W |
| RTX 4090 (power-limited) | 350–400 W |

At US average electricity rates (~$0.15/kWh as of 2026), a 24/7 RTX 4090 setup costs roughly $55–75/month just in electricity — before accounting for hardware amortization. An M4 Max Mac Studio running continuously would be around $9/month.

The break-even against Anthropic API costs depends entirely on how much you use the API. The [Braincuber economics analysis](../../research/openshift-ai-llm-deployment/sources/ref-61.md) that's part of the LLM deployment research in this workspace found that API wins for 87% of real-world use cases — the crossover to self-hosting only makes economic sense at industrial scale (roughly 500M+ tokens/day).

**What's different here:** the circuit monitoring in this setup captures actual draw from known hardware, at known times, correlated against real workloads. That's a much more honest dataset than published TDP specs or synthetic benchmarks. As local LLM experiments run, those circuits will tell the actual story.

### The monitoring setup

Circuit-level whole-home monitoring provides sub-minute granularity going back over a year. The data includes every circuit in the panel — which means AI workloads can be isolated from baseline (networking, refrigeration, lighting) and from other variable loads (HVAC, kitchen). When a GPU is running inference, that circuit's delta over baseline is the actual inference cost.

The planned approach: run defined workloads (specific tasks, specific models, specific durations), record the circuit delta, and compare against the equivalent token cost at current API pricing. The goal is a dataset that answers: *for this type of work, at current electricity rates, what does it actually cost?*

Case studies will be written as the data accumulates. The first will likely focus on a 7B–8B coding model on consumer GPU hardware running a defined workload — a benchmark that can be repeated over time as models and hardware improve.

---

## What to Expect (Honest Assessment)

Local models are improving fast, but the quality gap with frontier models remains significant for complex reasoning tasks. For routine code completion, documentation drafting, and simple refactoring, a good 7B–8B model is surprisingly capable. For architectural reasoning, multi-file refactors, and tasks requiring broad knowledge, the frontier models are noticeably better.

The privacy and offline arguments are strong independent of cost. If your use case involves proprietary code that you're genuinely uncomfortable sending to a third-party server, local inference answers that concern regardless of the economics.

The cost argument requires honest accounting: hardware purchase, power draw, cooling, the time spent on configuration and model management. The API subscription often wins on total cost of ownership unless the privacy case or the scale case is compelling.

---

## Related Reading

- [Enterprise LLM Deployment on OpenShift AI — Summary](openshift-ai-llm-deployment-summary.md) — the enterprise side of the same question: when does self-hosting at scale make sense?
- [AI-Assisted Development Workflows](ai-assisted-development-workflows.md) — broader patterns for AI-assisted work, including tool comparison
- [The Meta-Development Loop](the-meta-development-loop.md) — on using AI to build better AI workflows
- [When the Model Describes a Configuration It Isn't Running](../case-studies/model-self-report-runtime-state.md) — case study on the self-reported context window failure mode discovered during the experiments documented here

---

*This document was created with AI assistance (Cursor) and has been direction-reviewed by the author. Setup steps, model recommendations, and power figures have not been verified against real hardware. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

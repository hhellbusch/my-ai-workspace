---
review:
  status: unreviewed
  notes: "Experiment log. Commands verified by author at runtime; outcomes may change with new software versions."
---

# Local LLM experiment journal

Hands-on log: what was tried, what worked, and what failed. Complements the general setup guide, which stays stable; **this file is meant to grow** as you test new stacks, models, and images.

**Linked guide:** [`docs/ai-engineering/local-llm-setup.md`](../../docs/ai-engineering/local-llm-setup.md)

---

## Planned experiments (next up)

- **RAG index** — `ramalama rag add research/zen-karate-philosophy/ library/` → query Inoue/Rika content → compare against Sonnet on same sources. See backlog: *RAG index for local LLM*.
- **qwen2.5:32b Q3_K_M** — lower quant (~13–14 GiB weights) would leave ~6 GiB for KV + compute — should fit cleanly with meaningful headroom. Trade-off: reduced output quality vs Q4_K_M. Low priority — qwen3:30b-a3b MoE is the confirmed practical ceiling on this hardware.
- **Non-thinking qwen3 variant** — test latency difference on short prompts (routine completions) vs thinking variant.
- **Electricity baseline** — deferred until a stable, usable model is confirmed running. Plan: once a model is in daily use (candidate: qwen2.5:32b if it fits), capture circuit-level draw at idle vs. inference across representative task types (coding, essay, research queries). Data source: whole-home circuit monitoring (>1 year of history available). Compare against GPU idle (38W confirmed from prior session) and published TDP estimates.

---

## How to add an entry

- Append under **Entries** with **newest first** (add a new `### YYYY-MM-DD — short label` block at the top of that section).
- Include enough detail that a future you (or another machine) can reproduce: **host OS**, **GPU**, **ROCm / driver / container tag**, **exact model id**, **command line**, and **outcome** (success, failure, partial).
- For failures, paste or paraphrase the **root error** (one or two lines is enough).

Keep **Environment (baseline)** updated when the machine or driver stack changes.

---

## Environment (baseline)

| Field | Value |
|--------|--------|
| Host OS | Fedora 43 (linux **6.18.10-200.fc43.x86_64**) |
| CPU | 13th Gen Intel Core i5-13600K |
| GPU | AMD Radeon RX 7900 XT, 20 GB VRAM (**gfx1100**) |
| ROCm (host) | **6.4.2** (most packages) / **6.4.4** (`rocm-core`), from Fedora repos |
| Goal | Local coding/DevOps LLM; prefer vLLM + Qwen3 where possible |

---

## Entries (newest first)

### 2026-04-20 — RamaLama, qwen2.5:32b full-GPU (**OOM at KV cache — confirmed fails**)

- **Tool:** RamaLama (native), `ramalama serve ollama://qwen2.5:32b`
- **Model:** `qwen2.5:32b` — Q4_K_M, 18.48 GiB, 32.76B params, 64 layers
- **Goal:** Full-GPU inference on 20 GB VRAM
- **Status:** Failed. OOM during KV cache + compute graph reservation.

**What succeeded:**
```
load_tensors: offloaded 65/65 layers to GPU   ← all layers fit
load_tensors: ROCm0 model buffer size = 18,508.35 MiB
```
The 18.5 GB of weights loaded fully onto the GPU. That part worked.

**What failed:**
```
llama_params_fit_impl: projected to use 27091 MiB vs 20252 MiB free
llama_params_fit_impl: context size reduced from 32768 to 4096 → need 7252 MiB less
llama_params_fit: failed: n_gpu_layers already set by user to 999, abort
...
ROCm error: out of memory
  hipStreamCreateWithFlags  ← crash at compute graph reservation
```

**Root cause — the math:**
| Component | Memory |
|---|---|
| GPU free at load time | 20,252 MiB |
| Model weights | 18,508 MiB |
| Remaining | **1,744 MiB** |
| KV cache (4096 ctx × 4 parallel seqs) | 1,024 MiB |
| Compute graph (streams, buffers) | >720 MiB needed |
| **Shortfall** | **~300–500 MiB over limit** |

**Why `-fit` couldn't save it:** llama.cpp's `-fit` algorithm tried to negotiate — it correctly identified it needed to reduce 7,863 MiB and tried reducing context from 32768→4096 (saving 7,252 MiB). But RamaLama hard-sets `n_gpu_layers=999`, which blocked the fit algorithm from making further adjustments. Fit aborted, load continued, crashed on the compute graph stream allocation.

**Follow-up attempt 1 — `ramalama serve` post-reboot (early, same session):**
After first reboot (~600 MiB VRAM in use), retried with `ramalama serve`. Server appeared to start loading but port 8080 was unreachable and system locked up. Killed. Suspected cause: VRAM fragmentation from the series of failed loads earlier in the session (Ollama container, first RamaLama attempt) rather than a fundamental hardware limit.

**Follow-up attempt 2 — `ramalama serve` post-reboot (clean state, confirmed working):**
After a full clean reboot with no prior failed loads, `ramalama serve ollama://qwen2.5:32b` loaded successfully and served on **port 8098**.

**Actual memory breakdown (from Ctrl+C cleanup output):**
```
ROCm0 (RX 7900 XT) | 20464 = 382 + (19839 = 18508 + 1024 + 307) + 242
```
| Component | MiB |
|---|---|
| Model weights | 18,508 |
| KV cache (n_parallel=4, n_ctx=4096) | 1,024 |
| Compute buffer | **307** (much lower than 750+ MiB estimated) |
| Unaccounted | 242 |
| **Free after load** | **382** |

**Graph splits: 2** — almost entirely GPU, negligible PCIe overhead. Compare to 72B hybrid: 718 splits.

**Corrected conclusion:** qwen2.5:32b Q4_K_M **does work** on RX 7900 XT with 382 MiB to spare. Earlier OOM failures were likely due to VRAM fragmentation from repeated failed loads in the same session, not a fundamental hardware incompatibility. Margin is tight — a fresh boot is required; don't attempt after other GPU workloads have run and failed.

**⚠️ tok/s not yet measured** — server was killed with Ctrl+C before benchmarking. Next session: restart and benchmark against qwen3:30b-a3b (~90 tok/s). Port: **8098**.

**Note on registry:** `quay.io/ramalama/qwen2.5:32b` does not exist — used `ollama://qwen2.5:32b` instead.

---

### 2026-04-20 — Ollama ROCm container, qwen2.5:72b hybrid offload (**loaded, slow**)

- **Tool:** Native Ollama container (`docker.io/ollama/ollama:rocm`, version **0.21.0**)
- **Model:** `qwen2.5:72b` — Q4_K_M quantization, 44.15 GiB, 72.71B parameters
- **Goal:** Hybrid CPU+GPU offload for qwen2.5:72b — RamaLama can't do this (GPU-only), Ollama handles layer split automatically
- **Status:** Model loaded and responding. Measurably slow. See analysis below.

**Layer split (actual):**
```
load_tensors: offloading 29 repeating layers to GPU
load_tensors: offloaded 29/81 layers to GPU
load_tensors:          CPU model buffer size =   668.25 MiB
load_tensors:        ROCm0 model buffer size = 16,013.58 MiB  (~15.6 GiB on GPU)
load_tensors:    ROCm_Host model buffer size = 28,531.62 MiB  (~27.9 GiB in pinned host RAM)
```
**36% GPU / 64% CPU (29 of 81 layers on GPU)**

**Context window (actual vs. max):**
```
llama_context: n_ctx = 4096
n_ctx_seq (4096) < n_ctx_train (32768) -- the full capacity of the model will not be utilized
```
Ollama defaulted to 4096 based on available VRAM. Model supports 32K — but expanding context requires more KV cache memory, which would need either more VRAM or more RAM allocation.

**KV cache split:**
- CPU: 816 MiB
- ROCm0: 464 MiB
- Total: 1,280 MiB for 4096-token context

**Why it's slow — graph splits:**
```
llama_context: graph splits = 718 (with bs=512), 3 (with bs=1)
```
718 graph splits means the compute graph switches between GPU and CPU **718 times per prefill batch**. Each switch is a PCIe bus transfer of activations. This is the fundamental bottleneck of hybrid inference on a single PCIe bus — not compute speed, but bus bandwidth between the 29 GPU layers and the 52 CPU layers. Generation (bs=1) only has 3 splits and will be comparatively faster, but prompt ingestion will be very slow.

**Flash Attention:** auto-enabled — good, this helps KV cache efficiency.

**Observed performance:**
- Time to first token: **>6 minutes on a short prompt — effectively hung**
- Generation tok/s: not measured; experiment abandoned as unusable for interactive work

**Conclusion:** 36% GPU / 64% CPU hybrid with 718 graph splits is not viable for interactive use on this hardware. The PCIe bus cannot sustain the activation transfers fast enough for the model to produce output in a usable timeframe. This is not a configuration problem — it is a fundamental constraint of the 72B model size vs. 20 GB VRAM.

**What actually fits in 20 GB VRAM (for full-GPU, interactive performance):**

| Model | Size (Q4_K_M) | VRAM needed | Expected tok/s |
|-------|--------------|-------------|---------------|
| `qwen3:30b-a3b` (MoE) | ~20 GB | 20 GB | ~90 tok/s (confirmed) |
| `qwen2.5:32b` | ~18–20 GB | 20 GB | ~40–60 tok/s (untested) |
| `qwen2.5:72b` | 44 GB | 44 GB | **unusable hybrid** |

**Next experiment:** `qwen2.5:32b` — should fit fully on GPU and be meaningfully better quality than the 30B MoE for multi-file reasoning tasks.

**Recommendation for anyone with 20 GB VRAM:** Do not attempt hybrid 70B+ models for interactive use. The graph split overhead makes it impractical regardless of how much system RAM you have. Use the largest model that fits fully on GPU.

**Working command:**
```bash
mkdir -p ~/.ollama
podman run -d --name ollama \
  --group-add=video \
  --device /dev/kfd \
  --device /dev/dri \
  --security-opt label=disable \
  -e HSA_OVERRIDE_GFX_VERSION=11.0.0 \
  -p 11434:11434 \
  -v "${HOME}/.ollama:/root/.ollama:Z" \
  docker.io/ollama/ollama:rocm
podman exec -it ollama ollama pull qwen2.5:72b
```

**GPU detection confirmed:**
```
inference compute id=GPU-9687a20323f09899 library=ROCm compute=gfx1100
name=ROCm0 description="AMD Radeon RX 7900 XT" total="20.0 GiB" available="18.5 GiB"
```

**Two required flags for AMD ROCm on Fedora (SELinux) — both needed:**

| Flag | Why |
|------|-----|
| `-e HSA_OVERRIDE_GFX_VERSION=11.0.0` | RDNA3 (`gfx1100`) requires explicit version hint; without it Ollama's ROCm runtime falls back to CPU. RamaLama handles this automatically. |
| `--security-opt label=disable` | SELinux blocks container access to `/dev/kfd` and `/dev/dri` device nodes even when passed via `--device`. The `:Z` volume flag handles *file* SELinux labels but not device nodes. |

**⚠️ Security note — `--security-opt label=disable`:**
This flag disables SELinux process labeling for the container. Normally, Podman containers run with the `container_t` SELinux type, which enforces device access restrictions. Disabling this removes that defense-in-depth layer.

*What this means in practice:*
- The container process can access any device that Unix permissions allow — not just the ones explicitly passed via `--device`
- If the Ollama container image were compromised or malicious, SELinux would not contain its device access
- Seccomp profile and Unix permissions still apply — this isn't `--privileged` — but the SELinux boundary is gone

*Acceptable for this use case because:*
- Running a known, pinned image from a trusted source
- Single-user local development machine
- Ollama is a network-exposed service regardless (port 11434)

*Better long-term alternative:*
Write or install a targeted SELinux policy module that grants `container_t` access to `kfd_t` and `dri_t` device types specifically, rather than disabling labels entirely. The `container-selinux` package on Fedora may have a GPU policy; worth checking. This is the right fix for any multi-user or production deployment.

**Disk/memory state at experiment start:**
- Disk: 283 GB free on `/home` (after freeing space pre-session)
- RAM: 62 GB total, 47 GB available
- Swap: 8 GB, nearly full from prior session — watch for pressure during hybrid offload
- Prior incomplete pull (40 GB orphaned blobs, no manifests) cleared before restart

---

### 2026-04-20 — RamaLama, qwen2.5:72b, hybrid CPU+GPU offload (**failed — wrong tool**)

- **Tool:** `ramalama`
- **Command:** `ramalama serve ollama://qwen2.5:72b`
- **Outcome:** **Failed.** `cudaMalloc failed: out of memory` — tried to allocate 44,545 MiB on a 20 GB card.
- **Root cause:** **RamaLama forces `n_gpu_layers=999` — GPU-only by design.** The `-fit` algorithm can reduce context window but cannot offload layers to CPU RAM. With 44 GB weights and 20 GB VRAM, there is no fit. Same mechanism as dense 32B failure but more extreme (projected 55,194 MiB needed vs 20,252 MiB free).
- **Key finding: RamaLama cannot do hybrid CPU+GPU offload.** It is a GPU-only serving tool. The hybrid offload premise was wrong for this tool.
- **Corrected path:** **Native Ollama container** (`docker.io/ollama/ollama:rocm`) handles CPU layer offload automatically — when a model exceeds VRAM, Ollama splits layers between GPU and CPU RAM without user intervention. This is the correct tool for the hybrid offload experiment. Also closes the "RamaLama vs native Ollama" comparison gap from sparring notes.
  ```bash
  podman run -d --name ollama \
    --group-add=video --device /dev/kfd --device /dev/dri \
    -p 11434:11434 -v "${HOME}/.ollama:/root/.ollama" \
    docker.io/ollama/ollama:rocm
  podman exec -it ollama ollama pull qwen2.5:72b
  podman exec -it ollama ollama run qwen2.5:72b
  ```
- **Setup note — SELinux volume label required:** First attempt failed: `Error: open /root/.ollama/id_ed25519: permission denied`. Fix: add `:Z` to volume mount for SELinux relabeling. Also requires `~/.ollama` directory to exist before running. Working command:
  ```bash
  mkdir -p ~/.ollama
  podman run -d --name ollama \
    --group-add=video --device /dev/kfd --device /dev/dri \
    -p 11434:11434 -v "${HOME}/.ollama:/root/.ollama:Z" \
    docker.io/ollama/ollama:rocm
  podman exec -it ollama ollama pull qwen2.5:72b
  ```
  RamaLama abstracts all of this — no `:Z`, no mkdir, no manual device flags. This is the setup friction RamaLama eliminates.
- **Pending:** Log actual layer split, tok/s, VRAM + RAM usage once pull completes.

### 2026-04-20 — RamaLama, qwen3:32b dense (**failed — OOM**)

- **Tool:** `ramalama`
- **Command:** `ramalama serve ollama://qwen3:32b`
- **Outcome:** **Failed.** KV cache allocation OOM: `cudaMalloc failed: out of memory`.
- **Root cause:** Dense 32B weights consume **18,842 MiB** on ROCm0, leaving only ~1,410 MiB free. Auto-fit reduced context to 4096 (needing 1,024 MiB KV cache) but ramalama forces `n_gpu_layers=999` which blocked the fit algorithm from offloading layers to free VRAM — no fallback. 1,024 MiB needed, ~1,410 MiB available in theory, but not enough contiguous.
- **Key finding:** Dense 32B is right at the 20 GB ceiling — **weights alone (18.8 GB) leave insufficient headroom for KV cache**. Compare: MoE 30B-A3B weights = 17.5 GB → 2.7 GB headroom → works. Dense 32B needs a GPU with 24 GB+ to serve with meaningful context.
- **Lesson:** MoE architecture is more VRAM-efficient for serving on consumer hardware — fewer active parameters per token means smaller weight footprint. For 20 GB cards, **MoE 30B-A3B is the practical quality ceiling**; dense 32B requires 24 GB+ (e.g. RTX 4090/5090).

### 2026-04-20 — RamaLama, qwen3:30b-a3b (**worked**)

- **Tool:** `ramalama` (from Fedora dnf repos)
- **Install:** `sudo dnf install ramalama`
- **Command:** `ramalama run ollama://qwen3:30b-a3b`
- **Goal:** Compare against the vLLM AWQ 32B baseline — easier path, llama.cpp backend, Qwen3 MoE model.
- **GPU detection:** **ROCm confirmed.** `ramalama info` reports `"Accelerator": "hip"` (HIP = AMD ROCm API). Auto-pulled `quay.io/ramalama/rocm:latest` — no manual `--device` flags needed. `rocm-smi` shows **VRAM 98%** (~19.5 GB of 20 GB used); GPU% 1% at idle. Temperature 44°C, power 38W idle. RamaLama version: **0.17.1**.
- **Outcome:** **Working.** Model responds at chat prompt (`🦭 >`). Single command: `ramalama run ollama://qwen3:30b-a3b` — no `podman run` flags, no image tag hunting, no device pass-through.
- **Context window (verified):** Runtime `n_ctx = **14,592 tokens**` — confirmed via `ramalama serve` startup logs at this specific launch. llama.cpp's `-fit` algorithm reduces context based on free VRAM at launch time; expect **~10k–15k tokens** depending on system state (other processes consuming VRAM will lower this). Model self-reported **32,768** when asked directly — that was wrong, drawn from training knowledge not runtime config. **Lesson: never trust a model's self-reported context window; check `n_ctx` in llama.cpp startup logs. The figure is runtime-variable, not a fixed property of the model+GPU combination.**
- **GPU offload:** `offloaded 49/49 layers to GPU`. Weights on ROCm0: **17,524 MiB**. KV cache on ROCm0: **1,368 MiB** (f16). Flash Attention: **enabled** (auto). All compute on GPU.
- **API endpoint:** `ramalama serve` exposes OpenAI-compatible server at `http://0.0.0.0:8080`. **Use `http://127.0.0.1:8080/v1` — not `http://localhost:8080/v1`** (server binds IPv4 only; `localhost` resolves to `::1` IPv6 → connection reset). Model ID for Cursor/LiteLLM: **`library/qwen3`**. Note: `GET /v1/models` returns `n_ctx_train: 262144` (training metadata), not the runtime `n_ctx` (14,592) — startup logs are the only source for the actual configured context.
- **Thinking model:** `Qwen3 30B A3B Thinking 2507` — this is a **reasoning variant** with `<think>` scratchpad support (`thinking = 1` in chat template). Extended chain-of-thought available, unlike the standard instruct variant.
- **Tokens/sec:** **~90 tok/s generation** (`predicted_per_second: 90.35`), **~153 tok/s prompt processing** — confirmed via `POST /v1/chat/completions` smoke test (21 prompt tokens, 274 completion tokens including thinking). Interactive use is fluid at this speed.
- **Thinking model confirmed:** API response includes `reasoning_content` field with full `<think>` scratchpad. Model chain-of-thought is available and working. Reasoning is hidden from Cursor UI but influences response quality on complex prompts.
- **Model download:** 17.28 GB at 71 MB/s. Quantization: Q4_K (Medium), 4.86 BPW.
- **Lesson (RamaLama vs vLLM on 20 GB AMD):** For single-user interactive use on a 20 GB consumer Radeon, **RamaLama + llama.cpp is the practical winner**:

  | | vLLM AWQ 32B | RamaLama qwen3:30b-a3b |
  |---|---|---|
  | Context | ~1,024 tokens | **~14,592 tokens** |
  | Generation speed | not measured (server barely started) | **~90 tok/s** |
  | Setup | 10-flag `podman run` + 3 failed attempts | **1 command** |
  | Model generation | Qwen2.5 (older) | **Qwen3 Thinking 2507** |
  | Thinking mode | No | **Yes** |
  | API endpoint | `http://127.0.0.1:8000/v1` | `http://127.0.0.1:8080/v1` |

  vLLM's value is serving throughput and batching for multi-user workloads — not relevant for a personal coding assistant. **RamaLama + `qwen3:30b-a3b` is the best available option on this GPU** — not a deliberate quality selection but the only path that fits and runs usefully within 20 GB VRAM (dense 32B OOMs; vLLM AWQ 32B boots at 1k context only). Until FP8 MoE lands on ROCm Radeon, this is the practical ceiling. Gap: native Ollama container was not compared against RamaLama in this experiment record.

### 2026-04-20 — vLLM OpenAI ROCm container, Qwen2.5-Coder-32B-Instruct-AWQ (**worked**)

- **Image:** `docker.io/vllm/vllm-openai-rocm:latest` (vLLM **0.19.1**).
- **Command:**
  ```bash
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
  (Without `--enforce-eager`: **Inductor autotune HIP OOM**; without tight context/utilization: **KV cache negative** at 4k+.)
- **Observed at runtime:** weights **`~18.26 GiB`**; **`Available KV cache memory: 0.3 GiB`**; **GPU KV cache ~1,232 tokens**; **~1.20×** concurrency at **1,024** tokens/request; **`Application startup complete`**, server **`http://0.0.0.0:8000`**.
- **Tradeoff:** **32B AWQ on 20 GB** leaves **very little KV** — practical **context ceiling ~1k** unless smaller model / more VRAM / future quant KV. For longer context at similar quality, **Ollama `qwen3:30b-a3b`** remains the easier path on this GPU.
- **Lesson (IDE):** **Cursor + cloud** = large managed context per turn; **Cursor + this vLLM** = only what fits **`max_model_len`** / KV — not comparable for long repo sessions. Communicated in [`local-llm-setup.md`](../../docs/ai-engineering/local-llm-setup.md) (*Local context vs Cursor chat*).
- **Lesson (frontier comparison):** **Claude Sonnet 4.6 (1M token context, in beta as of early 2026) with adaptive thinking** is not a quantitative step up from this setup — it's a different category. Local 32B AWQ at ~1k context = **privacy, no cost, offline**. Frontier model at 1M context + dynamic reasoning budget = **capability**. Neither replaces the other; they're complementary. Note: 1M context is specific to Sonnet 4.6 beta; earlier Sonnet versions max at ~200k. Documented in guide (*Local context vs Cursor chat*).
- **Lesson (1M context self-hosting):** Theoretically achievable on a consumer GPU cluster (OpenShift / vLLM tensor parallel), but **PCIe bandwidth** — not VRAM count — is the real blocker for interactive use. 7B model at 1M tokens needs ~128 GB KV cache across ~6–8× RTX 4090; throughput is painful over PCIe. Practical consumer cluster target: **32k–128k context**. True 1M at speed needs NVLink/InfiniBand (datacenter) or a single AMD MI300X (192 GB HBM3, enterprise-only, ~$10–15k, not consumer-purchasable). H100 nodes ~$200k+. **Frontier API is the practical path for 1M context today.**
- **Lesson (latest gen cluster, 2026):** If buying new, **RTX 5090** (32 GB GDDR7, ~$2–4.5k) is the single-GPU ceiling — runs 70B Q4 comfortably, no NVLink (dropped after RTX 3090; multi-GPU = PCIe tensor parallel only). Dual 5090 ~27 tok/s on 70B Q4. **Sweet spot**: single node 1–2× RTX 5090 + lightweight K8s control plane. 4× 5090 (128 GB) still ~8× short of 1M context on 70B. Datacenter hardware (MI300X, H100) required for true long context — business/institutional purchase territory. Documented in guide (*Building a cluster — cost vs. context sweet spot*).
- **Lesson (enterprise stack cost — rough session estimates, NOT authoritative):**
  > ⚠️ **These numbers are the product of a single AI-assisted research session (2026-04-20) using web search results.** They are illustrative only. The author works at Red Hat and explicitly does not endorse these figures as accurate, current, or representative of any actual Red Hat pricing or sales guidance. **Consult Red Hat directly for real quotes and product information.**

  With that caveat: a minimal production RHOAI cluster (OCP + RHOAI + 8× H100 PCIe + control plane + storage + networking) runs roughly **$300,000–340,000 hardware** + **~$96,000–166,000/year software** → **~$590,000–840,000 over 3 years**. Full DGX H100 deployments run **$1,000,000–2,000,000+ over 3 years**. Cloud H100 rental (~$3/hr) breaks even vs. purchase at ~12–18 months of sustained high utilization. Red Hat's value proposition is the *operational platform* (OCP + RHOAI + GPU Operator + model serving pipelines + lifecycle management), not the GPU hardware itself — partners (Dell, HPE, NVIDIA) supply the hardware under validated configurations.

- **Lesson (mobo/platform constraint):** The **ASUS PRIME Z690-P + i5-13600K** is effectively a **single-GPU inference platform**. Secondary PCIe slots run at **x4 via chipset** (PCIe 3.0/4.0), all sharing a **DMI 4.0 x8** link to the CPU. Inter-GPU tensor parallel path: `GPU1 → PCIe 5.0 x16 → CPU → DMI x8 → PCIe x4 → GPU2` — DMI bottleneck makes vLLM tensor parallelism impractical. **Adding more 7900 XTs to this board is not worth it.** Multi-GPU inference requires a platform rebuild: new CPU (Threadripper Pro), mobo (WRX90), chassis (EEB/SSI-EEB), PSU (1600W+), and RAM. See *best card for multi-GPU* lesson below.
- **Lesson (best card for multi-GPU inference, 2026):**
  - **Best older gen (NVLink, used market):** **RTX 3090** — last consumer NVIDIA card with NVLink (2-way, ~112 GB/s total bidirectional via 2× NVLink 3.0 links; significantly less than the A100 SXM's 600 GB/s which uses 12× links, but well above PCIe's ~20–30 GB/s). 24 GB GDDR6X. ~$600–1,000 used. Two NVLink-paired 3090s = 48 GB with much better intra-pair bandwidth than PCIe tensor parallel. Still need a platform with proper x16 slots per card (Threadripper Pro / server board). Blower-style models (e.g. Gigabyte 3090 Turbo) better for multi-card thermals. *(~112 GB/s is a session estimate — verify against GA102 whitepaper for exact figures.)*
  - **Best current gen (no NVLink, new):** **RTX 5090** — 32 GB GDDR7, ~$2–4.5k. No NVLink, but 32 GB on a single card means many workloads don't need multi-GPU at all.
  - **Best bang for multi-GPU (used, NVLink):** 2× RTX 3090 + NVLink bridge on a proper platform ≈ $1,200–2,000 GPUs; add Threadripper Pro workstation ~$3,000–6,000. Total ~$4,000–8,000 for 48 GB NVLink-paired. Better inter-GPU bandwidth than PCIe tensor parallel; competitive with 1× RTX 5090 in total VRAM at roughly similar price, with bandwidth advantage.
  - **Platform needed:** AMD Threadripper PRO 7000 (WRX90) — 128 PCIe 5.0 lanes, up to 7× full x16 slots (e.g. ASUS Pro WS WRX90E-SAGE SE). Budget: CPU ~$1,500–5,000 (7945WX–7995WX), mobo ~$1,000–2,000, chassis (EEB) ~$300–600, PSU 1600W+ ~$300–500, DDR5 ECC ~$400–800. **Platform alone ~$3,500–9,000 before GPUs.**
- **Lesson (CLI gap):** **`cursor agent` CLI cannot be pointed at a local OpenAI-compatible endpoint** (no `--openai-base-url` / `cli-config.json` field; routes to Cursor's own backend). **Cursor IDE** (Settings → Models) does support it. Terminal alternatives: `curl`, `aichat`, `llm`, or any tool that honours `OPENAI_BASE_URL`. Verified 2026-04-20 against `cursor agent --help` and config docs.
- **Smoke test:** `GET /v1/models` → **200**; **`POST /v1/chat/completions`** (short prompt) → **200**, assistant reply OK (e.g. **2026-04-20**, ~38 tokens on hello).

### 2026-04-20 — vLLM OpenAI ROCm container, Qwen2.5-Coder-32B-Instruct-AWQ (failed attempts before success)

- **Failure A — default compile:** **`max-model-len 8192`**, no eager → **`HIP out of memory`** during **`torch._inductor` autotuning** after weights loaded (**~18.26 GiB**).
- **Failure B — eager, 4k context:** **`enforce_eager` + `max-model-len 4096`** → **`Available KV cache memory: -1.43 GiB`**, `ValueError: No available memory for the cache blocks`.
- **Resolution:** see **worked** entry above (eager + **1024** context + high **`gpu_memory_utilization`** + **`max_num_seqs` 1**).

### 2026-04-20 — vLLM OpenAI ROCm container, Qwen3-Coder-Next-FP8 (nightly)

- **Image:** `docker.io/vllm/vllm-openai-rocm:nightly` (vLLM **0.19.2rc1.dev8** in logs).
- **Model:** `Qwen/Qwen3-Coder-Next-FP8` with `--max-model-len 16384`, `--enable-auto-tool-choice`, `--tool-call-parser qwen3_coder`.
- **Outcome:** **Failed** at engine init.
- **Error:** `NotImplementedError: No FP8 MoE backend supports the deployment configuration` from `vllm.model_executor.layers.fused_moe.oracle.fp8.select_fp8_moe_backend` while constructing `SharedFusedMoE` / `Fp8MoEMethod` for `Qwen3NextForCausalLM`.
- **Notes:** Same class of failure as stable; **nightly did not unlock FP8 MoE on this Radeon config**. Doc guidance: use non–FP8-MoE weights on ROCm Radeon (e.g. AWQ Qwen2.5 Coder 32B), Ollama Qwen3 MoE, or CUDA for FP8 Qwen3 Coder. See [vllm#36105](https://github.com/vllm-project/vllm/issues/36105).

### 2026-04-20 — vLLM OpenAI ROCm container, Qwen3-Coder-Next-FP8 (stable)

- **Image:** `docker.io/vllm/vllm-openai-rocm:latest` (implied from earlier attempt in same session; align tag with what you actually ran).
- **Model:** `Qwen/Qwen3-Coder-Next-FP8`.
- **Outcome:** **Failed** — same FP8 MoE backend error as nightly (see above).

### 2026-04-* — Native venv, vLLM + ROCm PyTorch on Fedora

- **Outcome:** **Failed early** — `OSError: libmpi_cxx.so.40` when importing `torch` (or vLLM pulling in torch). OpenMPI from distro may not provide that soname (e.g. Fedora Open MPI 5.x vs older ABI expectations from wheels).
- **Notes:** Container path avoids host torch/OpenMPI coupling; if revisiting native install, match **exact** wheel variant to ROCm and resolve MPI deps deliberately—or use **uv**/upstream docs for the current supported combo.

### *(template — delete when unused)*

- **Image / install:**
- **Model:**
- **Command:**
- **Outcome:** Worked / Failed / Partial
- **Notes:**

---

## Summary strip (optional)

One-line rollup you can refresh when the picture changes:

| Stack | Qwen3-Coder-Next-FP8 | Practical alternative on this GPU |
|--------|----------------------|-----------------------------------|
| vLLM + ROCm Radeon | No (FP8 MoE backend) | **AWQ 32B works** with **`--enforce-eager`**, **`--max-model-len 1024`**, high **`gpu-memory-utilization`**, **`--max-num-seqs 1`** — **~1.2k KV tokens** only on **20 GB**; longer context → **Ollama** or smaller model |
| vLLM + CUDA | Expected yes | *(not tested on this journal host)* |

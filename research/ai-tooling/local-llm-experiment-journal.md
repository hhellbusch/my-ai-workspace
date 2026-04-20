---
review:
  status: unreviewed
  notes: "Experiment log. Commands verified by author at runtime; outcomes may change with new software versions."
---

# Local LLM experiment journal

Hands-on log: what was tried, what worked, and what failed. Complements the general setup guide, which stays stable; **this file is meant to grow** as you test new stacks, models, and images.

**Linked guide:** [`docs/ai-engineering/local-llm-setup.md`](../../docs/ai-engineering/local-llm-setup.md)

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

### 2026-04-20 — RamaLama, qwen3:72b, hybrid CPU+GPU offload (**pending**)

- **Tool:** `ramalama`
- **Command:** `ramalama run ollama://qwen3:72b`
- **Why qwen3:72b over llama3.3:70b:** Same ~43 GB Q4 size and hybrid offload profile, but Qwen3 is stronger on coding/technical reasoning and has thinking mode — consistent with the rest of the workspace's model choices. Llama 3.3 is a general-purpose Western-corpus model; Qwen3 is better suited to DevOps/coding workloads.
- **Goal:** Characterize 70B hybrid offload on current hardware — 20 GB VRAM (7900 XT) + ~62 GB system RAM. llama.cpp auto-fits layers: ~36 of 80 transformer layers on GPU, remainder on CPU RAM.
- **Expected:** Model loads (~43 GB Q4_K_M); generation speed ~15–25 tok/s (DDR5 bandwidth bottleneck on CPU layers vs GPU's 896 GB/s). Usable for non-interactive tasks; slower for back-and-forth.
- **Outcome:** *(to be filled)*
- **Notes:** *(to be filled — actual tok/s, layer split reported by llama.cpp, VRAM + RAM usage, subjective quality)*

### 2026-04-20 — RamaLama, qwen3:30b-a3b (**in progress**)

- **Tool:** `ramalama` (from Fedora dnf repos)
- **Install:** `sudo dnf install ramalama`
- **Command:** `ramalama run ollama://qwen3:30b-a3b`
- **Goal:** Compare against the vLLM AWQ 32B baseline — easier path, llama.cpp backend, Qwen3 MoE model.
- **GPU detection:** **ROCm confirmed.** `ramalama info` reports `"Accelerator": "hip"` (HIP = AMD ROCm API). Auto-pulled `quay.io/ramalama/rocm:latest` — no manual `--device` flags needed. `rocm-smi` shows **VRAM 98%** (~19.5 GB of 20 GB used); GPU% 1% at idle. Temperature 44°C, power 38W idle. RamaLama version: **0.17.1**.
- **Outcome:** **Working.** Model responds at chat prompt (`🦭 >`). Single command: `ramalama run ollama://qwen3:30b-a3b` — no `podman run` flags, no image tag hunting, no device pass-through.
- **Context window (verified):** Runtime `n_ctx = **14,592** tokens** — confirmed via `ramalama serve` startup logs. llama.cpp's `-fit` algorithm reduced the model's native training context (262,144 tokens) to fit available VRAM: projected 42,892 MiB needed vs 20,252 MiB free → context reduced by ~248k. Model self-reported **32,768** when asked directly — that was wrong, drawn from training knowledge not runtime config. **Lesson: never trust a model's self-reported context window; check `n_ctx` in llama.cpp startup logs or `GET /v1/models`.**
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

  vLLM's value is serving throughput and batching for multi-user workloads — not relevant for a personal coding assistant. **RamaLama + `qwen3:30b-a3b` is the recommended default for this GPU** until FP8 MoE lands on ROCm Radeon and vLLM can serve Qwen3 Coder with meaningful context.

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

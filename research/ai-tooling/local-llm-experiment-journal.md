---
review:
  status: unreviewed
  notes: "Experiment log. Commands verified by author at runtime; outcomes may change with new software versions."
---

# Local LLM experiment journal

Hands-on log: what was tried, what worked, and what failed. Complements the general setup guide, which stays stable; **this file is meant to grow** as you test new stacks, models, and images.

**Linked guide:** [`docs/ai-engineering/local-llm-setup.md`](../../docs/ai-engineering/local-llm-setup.md)

---

## Prioritized experiments — pick a daily-driver model

**Goal:** Pick **one** primary local model (and optionally one **fast** secondary) for **Pi + harness** work, based on **measured `n_ctx`**, **speed**, and **a few fixed coding/reasoning probes** — not vibes.

**Protocol (reuse every run)** — log in a new **Entries** block after each experiment:

1. **Clean GPU state** — reboot or ensure no leaked VRAM consumers before “max context” runs (journal: fragmentation mattered for `qwen2.5:32b`).
2. **Serve** — `ramalama serve ollama://<tag>` (or Ollama container); capture **startup line with `n_ctx`**.
3. **Numbers** — note **`n_ctx`**, **VRAM** from `rocm-smi` (or cleanup line on exit), **~90 tok/s** class figure from a **short** `POST /v1/chat/completions` if you care about latency.
4. **Probes (same every model)** — e.g. (a) **small refactor** in a known file, (b) **explain error** from a trimmed stack trace, (c) **multi-hop** “use context A + B” — score **pass / partial / fail** without changing the prompts between models.
5. **Pi** — set **`models.json` `contextWindow`** to the **measured `n_ctx`** for that model (see **2026-05-05**); then one **long-context** harness run to confirm no silent truncation.

| Priority | Experiment | Why it matters | Decision signal |
|----------|------------|----------------|-----------------|
| **P0** | **Baseline — `ollama://qwen3:30b-a3b`** (RamaLama, current best) | Known-good on **gfx1100**; all other candidates compare here. | Log **fresh `n_ctx`** (expect **~10k–15k**). If this already meets quality + speed → **default** unless a lower tier wins on *latency* or a smaller model wins on *context*. |
| **P1** | **Pi wiring + one characterization pass** | Validates **harness ∩ server** before sweeping models. | **`models.json`** + server model id + **`OPENAI_BASE_URL`** (LAN or **`127.0.0.1:8080/v1`**); **`contextWindow` ≈ `n_ctx`**; **`paude create --agent pi --provider openai`** (allowlist auto-merges API host from **`OPENAI_BASE_URL`** when domains are restricted); one **12k-token**-class task completes without garbage. |
| **P2** | **Fast tier — `gpt-oss:20b` or `qwen2.5-coder:7b`** (Ollama tags via RamaLama) | Cheap **latency** checks and **larger `n_ctx`** than 30B MoE; good **second model** for quick turns. | **`qwen2.5-coder:7b` unblocked** — **2026-05-08**: local ROCm image **`localhost/ramalama-rocm:f44`** (glibc **2.43**) + upstream **RamaLama venv ~0.20**; measured **`n_ctx` = 32,768** (full training context on 20 GB). **`gpt-oss:20b`:** retry with **`--runtime-args '--no-jinja'`** (template issue, journal). Quay **`rocm:latest`** still **2.42** until upstream rebuild. |
| **P3** | **Non-thinking Qwen3** (if available on registry as distinct tag) | Same MoE family, **less thinking latency** on short prompts (journal backlog). | If **latency** improves **measurably** and quality holds → consider **replacing** thinking variant as daily driver. |
| **P4** | **Ollama ROCm container vs RamaLama** on **same tag** (`qwen3:30b-a3b`) | Same weights, different wrapper — settles **“which serve path”** for Pi. | Prefer stack with **same or higher `n_ctx`**, **simpler ops**, **fewer surprises** (SELinux, ports). |
| **P5** | **`qwen2.5:32b` Q3_K_M** (if tag exists) or next **lighter quant** that fits | Trades quality for **KV headroom** → often **higher `n_ctx`** than Q4 32B on 20 GB. | If **`n_ctx` ≫ 4096** (Apr Q4 result) **and** probes ≥ baseline on **P0** for your tasks → candidate for **“long context dense”** slot; else skip. |
| **P6** | **`qwen2.5:32b` Q4** (repeat Apr with **clean boot** only if pursuing dense 32B) | Already logged **4096 `n_ctx`** full-GPU; only if you **need** dense over MoE. | Win only if **probe quality** beats **P0** *enough* to justify **~5× slower** generation (journal). |
| **P7** | **Vulkan `llama.cpp`** on **one MoE GGUF** | Level1 path; may beat ROCm for **some** long-context shapes — **extra build friction**. | Pursue only if **P0–P5** leave a **specific gap** (e.g. long-doc RAG + local). |
| **P8** | **Larger MoE tags** (`qwen3.5-*`, vision) | May **not fit** 20 GB full-GPU; risk **hybrid slowness**. | Try only after **P2** shows you need **capability** over **fit**; accept **CPU spill** only if measured **tok/s** is still usable. |
| **Watchlist** | **`Qwen3-Coder-Next`** family (HF **`Qwen/Qwen3-Coder-Next`**, **`…-FP8`**) | **Same “want”** as cloud docs / AMD Instinct guides — **not** in P0–P8 until a **runnable artifact** exists on **gfx1100 + 20 GB**. | **Requeue when:** (1) **`ollama://` / RamaLama** (or GGUF) ships a **quantized Coder-Next** that **fits** and serves — **pull + `n_ctx` log** like any other candidate; (2) **vLLM ROCm** release notes claim **FP8 MoE on RDNA3** — rerun minimal **`Qwen3-Coder-Next-FP8`** container; (3) **hardware** changes (e.g. **24 GB+**, **gfx12**, Instinct). **Current state:** **FP8** on vLLM **blocked** (**2026-05-03**); **BF16** full weights **oversized** for one 20 GB card (**2026-05-04** table). |

**Likely outcome (hypothesis)** — **Primary:** `qwen3:30b-a3b` (thinking) **or** non-thinking variant if P3 wins. **Secondary:** `gpt-oss:20b` or `qwen2.5-coder:7b`. **Skip unless needed:** dense 32B, vLLM on this GPU for MoE. **Coder-Next:** **watchlist**, not daily-driver queue, until a **local** path works.

---

## Backlog (not blocking model choice)

- **RAG index** — `ramalama rag add research/zen-karate-philosophy/ library/` → compare to cloud Sonnet on same sources.
- **Electricity baseline** — after a daily driver is chosen; circuit-level idle vs inference (journal Apr plan).
- **Strix Halo / 128 GB unified** — hardware TCO; see **2026-05-05** entry.
- **vLLM FP8 MoE upstream** — contribution idea only; see **2026-05-05**.
- **SGLang ROCm** — only if a release explicitly targets **gfx1100 + your model class**.
- **Qwen3-Coder-Next** — periodic **Ollama library / HF** check for a **served** quant on **20 GB**; **vLLM** smoke on **new major** `vllm-openai-rocm` tags only if upstream signals **gfx1100 FP8 MoE** (see **Watchlist** row above).
- **RamaLama ROCm image** — after P2 unblocks, consider **pinning image digest** (avoid `:latest` drift vs host libc).

### Writing ideas (someday — from journal + guide material)

If the track settles and something feels worth publishing, these are the seeds. No drafting pressure — just noting what the raw material could become.

- **Case study — consumer AMD + vLLM:** FP8 MoE backend gap vs AWQ path; Inductor/HIP OOM vs `--enforce-eager`; KV cache when weights ~18.26 GiB on 20 GB; Ollama vs vLLM by constraint. Cite this journal as timeline; keep claims commands-verified.
- **Case study (meta) — stable guide vs experiment journal:** Why the split, cross-linking discipline, when to promote journal findings into the guide (avoid orphan logs).
- **Short essay — choosing a local inference stack** under real hardware limits: throughput vs comfort, "loads" vs "fits your prompt."
- **Essay — "a customer could have this conversation":** The full arc: try vLLM → hit FP8 MoE gap → AWQ barely works at 1k context → discover RamaLama → auto-detects ROCm → realize context ceiling (14k vs 1M cloud) → understand hybrid architecture path → model enterprise vs consumer hardware gap. The pattern is the point. Red Hat employment disclosure consideration applies.
- **Landscape piece — Red Hat ecosystem comparison:** RamaLama / Podman AI Lab / InstructLab / RHEL AI.
- **Spar notes:** [`local-llm-setup-sparring-notes.md`](local-llm-setup-sparring-notes.md) (performed-honesty language) may merge with the performed honesty case-study idea if either gets drafted.

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
| Host OS | **Fedora 44** + **glibc 2.43**; **RamaLama** upstream **venv** (~**0.20**); ROCm serve image **`localhost/ramalama-rocm:f44`** (local build, glibc **2.43** in image) — see **2026-05-08** |
| CPU | 13th Gen Intel Core i5-13600K |
| GPU | AMD Radeon RX 7900 XT, 20 GB VRAM (**gfx1100**) |
| ROCm (host) | **6.4.2** (most packages) / **6.4.4** (`rocm-core`), from Fedora repos |
| Goal | Local coding/DevOps LLM; prefer vLLM + Qwen3 where possible |

---

## Entries (newest first)

### 2026-05-03 — **Home LLM topology (flat LAN)** + **paude → Pi → OpenAI-compatible**

- **Topology:** Single **trusted flat LAN** (no VLAN split for now). **Dedicated LLM host** later: **DHCP reservation + local DNS** (e.g. `llm.lan`) on the router; **host firewall** on the LLM box (**inbound** allow only **LAN CIDR** to the serve port, default **no WAN** port-forward). Optional **reverse proxy + bearer** in front of llama.cpp/RamaLama for defense in depth against casual LAN abuse; **pfSense** not relied on for east-west filtering on a flat segment.
- **Client URL:** Pi / OpenAI SDK need a **stable base** — e.g. `http://llm.lan:8080/v1` (IPv4); avoid assuming **`127.0.0.1`** when the server runs in another container or on another machine.
- **Context:** For **`library/qwen2.5-coder`** via RamaLama, logs showed **`n_ctx = 32768`** — align Pi **`models.json`** **`contextWindow`** with that id when using long prompts (see **2026-05-08**).
- **paude (this repo):** **`--agent pi --provider openai`** — passthrough **`OPENAI_BASE_URL`** / **`OPENAI_API_BASE`**, secret **`OPENAI_API_KEY`**; default **`--model openai/library/qwen2.5-coder`**. **`paude create`** expands **paude-proxy** allowlists from **`OPENAI_BASE_URL` / `OPENAI_API_BASE`** (hostname appended, same idea as **`--otel-endpoint`**) unless **`--allowed-domains all`**. Agent **`NO_PROXY`** stays **loopback-only** so outbound HTTP(S) goes through **paude-proxy**; same-host LLM → **`http://host.containers.internal:8080/v1`** (proxy can reach the host; agent often cannot use the host’s own LAN IP). Extra hosts via **`--allowed-domains`** / **`paude.json`**.
- **Smoke:** from repo root, **`scripts/smoke-local-openai-api.sh`** (or pass base URL) — **`GET …/v1/models`** against a running server.

---

### 2026-05-08 — **P2 fast tier works:** `ollama://qwen2.5-coder:7b` + **local ROCm image** + upstream RamaLama

- **Stack:** **`ramalama serve --pull=never --image localhost/ramalama-rocm:f44 ollama://qwen2.5-coder:7b`** (upstream RamaLama from **editable venv**, not dnf **0.17.1**).
- **Image:** **`localhost/ramalama-rocm:f44`** — built from **containers/ramalama** `container-images/rocm/Containerfile` (**Fedora 44** base); **`podman run … ldd --version` → 2.43** (fixes **2026-05-06 / 2026-05-07** glibc mismatch vs **`quay.io/ramalama/rocm:*`** still on **2.42**).
- **GPU:** **RX 7900 XT gfx1100**; **`load_backend: … libggml-hip.so`** — ROCm path healthy.
- **Measured runtime context:** **`llama_context: n_ctx = 32768`** (matches **`n_ctx_train`** 32768 from GGUF metadata for this 7B Q4_K — KV ~**1792 MiB**, ~**4.2 GiB** weights on GPU per log).
- **Server:** listens **`http://:::8080`** — Pi / clients that need IPv4 should use **`http://127.0.0.1:8080/v1`**; confirm **`GET /v1/models`** id for this alias (often **`library/…`** style, not the Ollama tag string).
- **Still open:** **`gpt-oss:20b`** — **chat template / Jinja** parse failure on llama-server without **`--runtime-args '--no-jinja'`** (separate from libc); **`qwen2.5-coder:7b`** loaded template successfully (log shows **`chat template, thinking = 0`**).
- **Next:** Pi **`models.json`** → set **`contextWindow`** to **32768** for this server model id; run **P2 probes** (latency + coding tasks); optional **P0** re-smoke **`qwen3:30b-a3b`** on same **`f44`** image for apples-to-apples.

---

### 2026-05-07 — RamaLama **`GLIBC_2.43`**: root cause is **container image**, not host (**P2**)

- **After Fedora 44:** host **`ldd --version`** → **2.43**; **`readelf -V /lib64/libm.so.6`** shows **GLIBC_2.43** — host is fine.
- **`LD_DEBUG=libs`** showed **host** helpers loading **`/lib64/libm.so.6`**; **`llama-server`** error still appears — consistent with **`llama-server` running inside Podman** where **`/lib64`** is the **image** rootfs, not the host inode.
- **Measured inside default ROCm image:**  
  `podman run --rm quay.io/ramalama/rocm:latest ldd --version | head -1` → **`ldd (GNU libc) 2.42`**. So **`libllama.so` / `libggml-base.so` / `libmtmd.so`** in that image were built expecting **`libm`** symbols versioned **GLIBC_2.43**, but the **image ships glibc 2.42** — **ABI mismatch inside the OCI image** (upstream packaging / `:latest` drift). **Upgrading the host** does not change the image’s libc.
- **Supersedes (partially) the 2026-05-06 “host too old” reading** — F43 host was *also* 2.42, but the **decisive** check is **glibc inside the image** RamaLama runs.

**Follow-ups**

```bash
# Confirm any alternate default image (if RamaLama switched default)
podman run --rm quay.io/ramalama/rocm-fedora:latest ldd --version | head -1

podman pull quay.io/ramalama/rocm:latest   # refresh; retry only if upstream bumped base
ramalama serve ollama://gpt-oss:20b
```

- **If still 2.42 in image:** file or find **[containers/ramalama](https://github.com/containers/ramalama)** issue — **ROCm image userspace must be ≥ build libc of bundled llama stack**; use **Ollama ROCm container** for fast tier until fixed.

---

### 2026-05-06 — Fast tier smoke (**P2**): `gpt-oss:20b` + `qwen2.5-coder:7b` via RamaLama (**blocked — glibc**)

- **Goal:** Start **fast tier** from prioritized ladder — pull **`ollama://gpt-oss:20b`** (then **`qwen2.5-coder:7b`**) with **`ramalama serve`**, log **`n_ctx`** and run probes.
- **Tool:** `ramalama` (Fedora dnf); pulls **`quay.io/ramalama/rocm:latest`** then Ollama blobs.
- **Status:** **Failed before model load** (both tags). Same error path after download.

**Root error**

```
llama-server: /lib64/libm.so.6: version `GLIBC_2.43' not found (required by /lib64/libmtmd.so.0)
llama-server: /lib64/libm.so.6: version `GLIBC_2.43' not found (required by /lib64/libllama.so.0)
llama-server: /lib64/libm.so.6: version `GLIBC_2.43' not found (required by /lib64/libggml-base.so.0)
```

- **Interpretation (initial):** `llama-server` + **`libllama.so`** expect **GLIBC_2.43** from **`libm`** — **ABI mismatch**, not an Ollama model issue.
- **Correction — see 2026-05-07:** The **`/lib64/libm.so.6`** in the error is the **container rootfs’s** `libm` (default **`quay.io/ramalama/rocm:latest`** still **glibc 2.42** inside the image), not “host bind too old” as the only story. Host **F43** was **2.42**; host **F44** is **2.43** but **does not fix** serve until the **image** libc matches what the **bundled** `.so` files need.
- **Measured (F43 session):** host `ldd --version` → **2.42**. **`qwen2.5-coder:7b`** failed the same way — not model-specific.
- **Author follow-up:** **`podman run --rm <ramalama-default-rocm-image> ldd --version`**; **`podman pull`**; newer **RamaLama** / image tag if upstream fixes; **`podman run … ollama/ollama:rocm`** (Apr journal) for fast tier. Pin **image digest** once a good combo is found.

**Commands (retry when glibc / image aligned)**

```bash
# Prefer: one model at a time; read n_ctx from first screenful of logs after load.
ramalama serve ollama://gpt-oss:20b
# or
ramalama serve ollama://qwen2.5-coder:7b
```

**P2 status (as of 2026-05-06 handoff):** Blocked on glibc — **2026-05-07** shows the real gate is **image** glibc, not host **F44**.

**Session handoff (superseded by 2026-05-07):** F44 upgrade done for host; **retry P2** only after **ROCm OCI image** ships **glibc ≥ 2.43** inside the rootfs (or alternate runner).

---

### 2026-05-05 — Strix Halo (128 GB) “affordable?” + context knob + upstream contribution (idea)

- **Status:** Planning / literature — **no purchase decision here**; prices move; verify before checkout.

**Is Strix Halo + 128 GB the most affordable path for big local models?**

- **Cannot confirm as globally “most affordable.”** It is **competitive for a prebuilt with 128 GB unified memory** in a **small form factor** — aligns with Level1’s demo narrative (RAM bandwidth + huge pool for **llama.cpp**-class loads). Your **$2.5k–3.5k** band matches **2026** street pricing for flagship configs, but **flagship Corsair-class prebuilts have climbed** (e.g. press coverage of **~$3,399** for **Ryzen AI Max+ 395** / **128 GB** tier amid memory cost pressure: [Tom’s Hardware on Corsair AI Workstation 300](https://www.tomshardware.com/desktops/mini-pcs/corsairs-strix-halo-ai-workstation-300-gets-even-more-expensive-amid-the-rampocalypse-ryzen-ai-max-395-flagship-now-sits-at-usd3-399)). Lower tiers (**64 GB**, smaller iGPU) land **much lower** but **do not** give the same “feed Wikipedia” headroom.
- **Often cheaper in absolute dollars:** **DIY tower** — used **RTX 3090 24 GB** + **128 GB DDR5** + mainstream CPU can beat **$3k** if you optimize used parts — but **worse unified-memory story**, more power/noise, and **PCIe split** still matters for multi-GPU (see journal **Apr 2026** mobo lesson).
- **Does Halo solve our vLLM FP8 MoE blocker?** **Do not assume yes.** Maintainer thread on [vLLM #36105](https://github.com/vllm-project/vllm/issues/36105) classifies **gfx1151 / Strix Halo–class iGPU** as **without native FP8** for the FP8 MoE backend story — same *class* of limitation as **gfx1100** for **`Qwen3-Coder-Next-FP8`**. Halo still shines for **unified RAM + iGPU** when the **software path is llama.cpp / Vulkan / Ollama-style** (Level1’s line of work), not automatically for **vLLM FP8 MoE on ROCm**.

**Level1Techs video (user link)**

- [Best 120b Model for Offline Use? Nemotron 3 Super Out Now](https://www.youtube.com/watch?v=J5nwl38pev8) — Level1Techs (oEmbed title; **not** exclusively a “Halo buyer’s guide,” but in the same **offline / big-model** orbit). Transcript not fetched this session; add under `research/youtube-sources-apr2026/sources/` if you want it indexed like `T17bpGItqXw`.

**“Context management is the bottleneck” — tune this knob first (software)**

Hardware buys RAM; **harness** buys effective context. Workspace pointers:

- [**Dex Horthy — No Vibes Allowed**](../../library/dex-horthy-no-vibes-allowed.md) — stay out of the **dumb zone** (~40%+ fill), **RPI** (research → plan → implement), **sub-agents for context fork** not cosplay.
- [**Karpathy — Agentic Engineering**](../../library/andrej-karpathy-vibe-coding-to-agentic-engineering.md) — **jagged intelligence**, verification.
- [**MemPalace**](../../library/mempalace.md) — **local-first memory** outside the model window.
- **Local inference:** maximize **`n_ctx` you actually use** (paste only what matters; summarize tiers; retrieval before prompt) — same lesson as Level1 “paste the article” in [`library/level1techs-ai-you-against-machine-local.md`](../../library/level1techs-ai-you-against-machine-local.md).

**RamaLama — measured runtime context (Apr 2026, this GPU)**

| Model / command | Runtime `n_ctx` (llama.cpp logs) | Notes |
|-----------------|----------------------------------|--------|
| **`ollama://qwen3:30b-a3b`** | **`14,592` tokens** (one verified `ramalama serve` launch) | Expect **~10k–15k** depending on **free VRAM at launch**; always read **`n_ctx` from startup logs**, not `GET /v1/models` (`n_ctx_train` is training metadata). |
| **`ollama://qwen2.5:32b`** (when load succeeded) | **`4096`** | Tight VRAM; journal has full memory breakdown. |

**Harness (Paude / Pi) + local OpenAI-compatible server — characterization (planned)**

- **Serve:** `ramalama serve ollama://qwen3:30b-a3b` → **`http://127.0.0.1:8080/v1`** (use **127.0.0.1**, not `localhost`). **Model id:** `library/qwen3` (per Apr log).
- **Characterization goal:** sweep **prompt sizes** (e.g. 2k / 6k / 12k / 14k tokens of filler + one task) and log **latency, truncation, tool errors** — effective **agent** context is min(**harness budget**, **`n_ctx`**).
- **Wiring:** Any OpenAI-compatible client needs **`OPENAI_BASE_URL`** (or product-specific equivalent) **+** a placeholder **`OPENAI_API_KEY`** if the server ignores it. **LiteLLM** proxy pattern in [`docs/ai-engineering/local-llm-setup.md`](../../docs/ai-engineering/local-llm-setup.md) if the agent stack expects Anthropic-shaped traffic. *Exact Pi / OpenClaw env names — confirm in product docs when wiring;* append a row here after first successful run.

**Pi monorepo (local clone) — `models.json` vs real `n_ctx`**

- **Path:** [`git-projects/pi`](../../git-projects/pi) — upstream [earendil-works/pi](https://github.com/earendil-works/pi); coding agent under **`packages/coding-agent`**.
- **Custom models file:** `~/.pi/agent/models.json` — see **[`packages/coding-agent/docs/models.md`](../../git-projects/pi/packages/coding-agent/docs/models.md)** (Ollama, vLLM, LM Studio, `baseUrl`, `api: "openai-completions"`, **`contextWindow`** / **`maxTokens`**, **`modelOverrides`** for built-ins).
- **Registry behavior:** `ModelDefinitionSchema` allows per-model **`contextWindow`**; `parseModels` defaults **`contextWindow` → 128000** and **`maxTokens` → 16384** when omitted (`model-registry.ts`). **`applyModelOverride`** can lower **`contextWindow`** on a built-in model via **`modelOverrides`**.
- **Important:** Pi’s **`contextWindow`** is the **client / harness budget** (compaction, UI, “how much history to plan for”) — it does **not** increase llama.cpp **`n_ctx`**. If **`contextWindow` ≫ server `n_ctx`**, Pi may **assume** more headroom than the server has → tune **`contextWindow` ≈ measured `n_ctx`** (e.g. **~14_500** for **`qwen3:30b-a3b`**) so characterization matches reality.
- **Larger *real* context on same GPU** → usually **smaller / leaner weights** (more KV headroom): e.g. **`qwen2.5-coder:7b`**, **`gemma3:12b`**, **`gpt-oss:20b`**, or **lower quant** (journal backlog: **qwen2.5:32b Q3_K_M**) — each needs a **fresh `n_ctx` readout** from serve logs after pull.

**Idea (not now): modify upstream**

- **vLLM:** contribute **ROCm gfx11 FP8 MoE** support in `select_fp8_moe_backend` / `TritonExperts.is_supported_config` / tuned configs — **high effort**, needs **repro on gfx1100 or gfx1151**, tests, AMD coordination; track [vLLM #36105](https://github.com/vllm-project/vllm/issues/36105) / follow-on PRs.
- **llama.cpp:** Level1 called out **ROCm + variable-bitweight quants** plumbing gap for **7900 XTX** — potentially **smaller surface area** than full vLLM MoE if the goal is **run their GGUFs**.
- **When to revisit:** after you have a **minimal repro + perf numbers** and a **clear upstream issue** so maintainers can adopt; until then, **software context engineering** + **RamaLama** path stays higher ROI.

---

### 2026-05-04 — MoE on RX 7900 XT: alternate runtimes (**inventory**, not yet re-run)

- **Context:** After **2026-05-03** confirmed **vLLM 0.20.1** still cannot select an **FP8 MoE** backend for **`Qwen/Qwen3-Coder-Next-FP8`** on **gfx1100**, ask: *what other ways could we run a MoE model on this hardware?*
- **Status:** Planning only — **author picks one row to execute next** and replaces this block’s status.

**Clarify the goal**

| If you mean… | Reality on 20 GB + gfx1100 |
|--------------|-----------------------------|
| **Same HF weights** `Qwen/Qwen3-Coder-Next-FP8` | **vLLM ROCm** is the blocker today; **changing container flags** will not add an MoE kernel. Other servers (**TensorRT-LLM**, **TGI**) are **NVIDIA-first** or different packaging — not a quick win on Radeon. |
| **Same *class*** — large **MoE**, coding-ish, local | **Already works:** **`ramalama run ollama://qwen3:30b-a3b`** (llama.cpp / Ollama registry, **Q4**, ~90 tok/s in Apr log). Different checkpoint than Coder-Next, same *stack family*. |
| **Even larger MoE** (e.g. Qwen3.5 35B A3B) | Try **`ollama://`** or GGUF only if weights fit; expect **CPU spill** or OOM — same discipline as **72B hybrid** journal entry. |

**Practical alternate *stacks* (MoE-capable)**

| Stack | Role | MoE on AMD? | Next step to try |
|-------|------|-------------|------------------|
| **RamaLama** | Default low-friction | **Yes** (`ollama://qwen3:30b-a3b` proven) | Keep as baseline; optional **`ramalama serve`** vs **`run`** A/B. |
| **Ollama (Podman ROCm)** | Same llama.cpp ecosystem, layer-split for oversized | **Yes** | **A/B vs RamaLama:** `podman … ollama/ollama:rocm` + `ollama pull qwen3:30b-a3b` — journal Apr entry documents **SELinux + `HSA_OVERRIDE_GFX_VERSION`** flags. |
| **`llama.cpp` + Vulkan** | Level1Techs / forum: sometimes **better on AMD** for long context; avoids some ROCm quant paths | **Yes**, if **GGUF** exists for the model | Build or distro package with **`-ngl`**, compare to ROCm backend on same GGUF; see [`library/level1techs-ai-you-against-machine-local.md`](../../library/level1techs-ai-you-against-machine-local.md). |
| **`llama.cpp` + ROCm** | Manual control vs RamaLama wrapper | **Yes** | Only if you need flags RamaLama does not expose; else redundant. |
| **LM Studio** | GUI wrapper around llama.cpp–class servers | **Yes** | Same models as Ollama/GGUF; convenience only. |
| **vLLM ROCm + AWQ dense** | Throughput server, not Coder-Next MoE | **MoE no**; dense **yes** (tight context) | Already logged: **32B AWQ ~1k context** — use when you need OpenAI API + batching, not long chat. |
| **SGLang / mlx / etc.** | Alternatives | **MLX = Apple only**; **SGLang** ROCm = *verify current docs* before investing | Low priority unless a release note explicitly lists **gfx1100 + target MoE**. |

**What does *not* bypass the vLLM FP8 MoE gap**

- Another **vLLM-only** flag set on **`Qwen3-Coder-Next-FP8`** — failure is **kernel support**, not tuning.
- **`Qwen/Qwen3-Coder-Next`** (non-FP8 **BF16** full weights) on **one 20 GB card** — weights alone exceed VRAM; would need **multi-GPU**, **CPU hybrid** (journal: painful for huge splits), or **smaller / quantized non-vLLM** artifact.

**Suggested next run (pick one)**

1. **Parity:** Ollama container vs RamaLama on **`qwen3:30b-a3b`** — latency, `n_ctx`, VRAM headroom.  
2. **Vulkan:** one MoE GGUF (e.g. from [Bartowski](https://huggingface.co/bartowski) or Ollama-exported) via `llama.cpp` **`-ngl 99`** with **Vulkan** backend — log tok/s vs ROCm path.  
3. **Model exploration:** `ollama show` / library pull for **`qwen3` coder-tagged** variants that still fit **20 GB** — update journal with **exact tag** and outcome.

---

### 2026-05-03 — vLLM ROCm + Qwen3-Coder-Next-FP8 (hands-on) + upstream notes + Level1Techs

- **Goal:** Re-check whether **Qwen3-Coder-Next-FP8** on **vLLM + ROCm** works on **RX 7900 XT (gfx1100)** after pulling current `vllm-openai-rocm:latest`; keep **repeatable commands** and **community** references in one place.
- **Status (hands-on):** **Failed** at model load — same failure class as **2026-04-20** (`NotImplementedError: No FP8 MoE backend supports the deployment configuration`). **vLLM 0.20.1** (was **0.19.x** in Apr container logs) — version moved; **gfx1100 outcome unchanged** for this checkpoint.

**Hands-on — Podman, `docker.io/vllm/vllm-openai-rocm:latest`, `Qwen/Qwen3-Coder-Next-FP8`**

- **Command:** Journal block below (`--tensor-parallel-size 1`, `--max-model-len 4096`, `--gpu-memory-utilization 0.95`, `--max-num-seqs 1`, `--enforce-eager`).
- **Image:** `docker.io/vllm/vllm-openai-rocm:latest` (record digest anytime with `podman images --digests | grep vllm-openai-rocm`).
- **Observed:** Engine **V1** / `Initializing a V1 LLM engine (v0.20.1)`; `Resolved architecture: Qwen3NextForCausalLM`; **`Selected TritonFp8BlockScaledMMKernel for Fp8LinearMethod`** — linear FP8 path selects a Triton kernel; stack then dies building **`Qwen3NextSparseMoeBlock` → `FusedMoE` → `Fp8MoEMethod` → `select_fp8_moe_backend`** (`fp8.py`, MoE oracle).
- **Root error (one line):** `NotImplementedError: No FP8 MoE backend supports the deployment configuration.`
- **Lesson:** FP8 **non-MoE** pieces can be farther along than FP8 **MoE** on this stack; do not infer MoE support from linear-layer logs alone.

**vLLM / ROCm — what changed upstream (Apr 2026)**

- [vLLM #36105](https://github.com/vllm-project/vllm/issues/36105): same class of failure as our Apr session (`NotImplementedError: No FP8 MoE backend supports the deployment configuration`). Closed **2026-04-02** by work targeting **gfx1201 (Radeon R9700)** — [PR #38086](https://github.com/vllm-project/vllm/pull/38086) / commit [`551b3fb`](https://github.com/vllm-project/vllm/commit/551b3fb39f3a95ff3dc3feca9528ab4c90649316): Triton FP8 MoE **configs** for `AMD_Radeon_R9700`, tuned for **Qwen3-30B-A3B-FP8** and **Qwen3.5-35B-A3B-FP8** at **TP=2**. **gfx1100 is not in that enablement path** (RDNA3 vs RDNA4 gfx12).
- Maintainer thread: **RX 7900 XTX / Strix Halo class** described as lacking **native FP8** for this stack; **gfx1151** explicitly called out as unsupported for the same reason ([issue comment 2026-04-09](https://github.com/vllm-project/vllm/issues/36105#issuecomment-2795847029)).
- [AMD Day 0 Qwen3-Coder-Next](https://www.amd.com/en/developer/resources/technical-articles/2026/day-0-support-for-qwen3-coder-next-on-amd-instinct-gpus.html): **Instinct MI300X+** + ROCm 7 + vLLM — not a consumer 20 GB Radeon guarantee.

**Hypothesis for gfx1100:** Software upgrades alone are **unlikely** to unlock **Qwen3-Coder-Next-FP8** on vLLM ROCm until a backend explicitly supports this arch + MoE layout; **RamaLama + `qwen3:30b-a3b`** remains the documented working path on this GPU.

**Commands — retry FP8 MoE on latest vLLM ROCm image (expect failure on gfx1100; proves image rev)**

Record the image digest after pull (`podman images --digests`).

```bash
# Optional: fresh pull
podman pull docker.io/vllm/vllm-openai-rocm:latest

# Minimal repro: Qwen3-Coder-Next-FP8 (same failure class as Apr 2026)
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
  Qwen/Qwen3-Coder-Next-FP8 \
  --tensor-parallel-size 1 \
  --max-model-len 4096 \
  --gpu-memory-utilization 0.95 \
  --max-num-seqs 1 \
  --enforce-eager
```

**2026-05-03 run:** Confirmed at **`version 0.20.1`** in banner — then stop; no point tuning inductor/KV until MoE backend selection passes.

**Commands — confirm known-good stack (RamaLama, no vLLM)**

```bash
ramalama run ollama://qwen3:30b-a3b
# or serve:
# ramalama serve ollama://qwen3:30b-a3b
# API: http://127.0.0.1:8080/v1  (not localhost); model id library/qwen3
```

**Level1Techs video (same ecosystem):** [AI and You Against the Machine: Guide so you can own Big AI and Run Local](https://www.youtube.com/watch?v=T17bpGItqXw) — Level1Techs. **Transcript:** [`research/youtube-sources-apr2026/sources/youtube-T17bpGItqXw-transcript.md`](../youtube-sources-apr2026/sources/youtube-T17bpGItqXw-transcript.md). **Library entry:** [`library/level1techs-ai-you-against-machine-local.md`](../../library/level1techs-ai-you-against-machine-local.md) (see [`library/log.md`](../../library/log.md) **2026-05-03**). Themes in the table below stay high-level; use the transcript for quotes and chapter-level detail.

**Level1Techs forum — what we can learn** ([post #2 by lambda, Mar 2026](https://forum.level1techs.com/t/looking-for-tips-for-local-llm/246807/2))

| Idea | Takeaway for this workspace |
|------|-------------------------------|
| Prefer **newer** open models over small old dense checkpoints | Aligns with our move toward **Qwen3** / MoE; still need **VRAM-aware** picks (we already hit dense 32B ceiling). |
| **Qwen3.5-35B-A3B** MoE + vision | Same *family* direction as upstream FP8 MoE work, but **on gfx1100** prefer **llama.cpp / Ollama / RamaLama** with a tag that **fits**; forum notes model may **spill to CPU** if VRAM insufficient — treat like our **72B hybrid** lesson (usable only if split is acceptable). |
| **llama.cpp + Vulkan** first, ROCm optional | Useful **portability** and driver isolation on Linux; orthogonal to vLLM FP8 MoE — worth an experiment if ROCm path is painful. |
| **LM Studio** | Same role as Ollama/RamaLama for local OpenAI-compatible serve; GUI tradeoff. |
| **gpt-oss:20B** for speed / VRAM | Smaller active footprint — plausible **fast** tier on 20 GB; separate quality eval from Qwen MoE. |

**Unsloth / HF links from that thread (for follow-up, not verified here):** [unsloth/Qwen3.5-35B-A3B-GGUF](https://huggingface.co/unsloth/Qwen3.5-35B-A3B-GGUF), [Unsloth Qwen3.5 local guide](https://unsloth.ai/docs/models/qwen3-how-to-run-and-fine-tune), [gpt-oss-20b GGUF](https://huggingface.co/unsloth/gpt-oss-20b-GGUF), [gpt-oss run guide](https://unsloth.ai/docs/models/gpt-oss-how-to-run-and-fine-tune).

---

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

**Benchmark results (2+2 prompt, 8 completion tokens):**
```
prompt_per_second:    125.5 tok/s  (prefill)
predicted_per_second:  19.4 tok/s  (generation)
prompt_tokens: 36 | completion_tokens: 8
```

| Model | Generation tok/s | Notes |
|---|---|---|
| qwen3:30b-a3b (MoE) | ~90 | 3B active params per token |
| **qwen2.5:32b (dense)** | **19.4** | All 32B params active per token |

**4.7× slower generation than qwen3:30b-a3b.** The speed cost of dense vs MoE is significant for interactive use. Whether the quality gain justifies it depends on the task — dense models tend to be more consistent on complex reasoning; MoE can be faster but less reliable on unusual inputs. Port observed: 8080 (ramalama serve may vary port by instance).

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
| vLLM + ROCm Radeon | No (FP8 MoE backend) — **retest 2026-05-03 v0.20.1**, same `select_fp8_moe_backend` error on gfx1100 | **AWQ 32B works** with **`--enforce-eager`**, **`--max-model-len 1024`**, high **`gpu-memory-utilization`**, **`--max-num-seqs 1`** — **~1.2k KV tokens** only on **20 GB**; longer context → **Ollama/RamaLama** or smaller model |
| vLLM + CUDA | Expected yes | *(not tested on this journal host)* |

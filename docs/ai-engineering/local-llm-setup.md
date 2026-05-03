---
review:
  status: direction-reviewed
  notes: "Author has read and directed this draft. Ollama/RamaLama commands partially verified hands-on (qwen3:30b-a3b and qwen2.5:32b on RX 7900 XT, 2026-04-20). LiteLLM proxy steps, vLLM commands, and power figures not yet verified on this hardware. Electricity measurement methodology not yet validated against real circuit data. See experiment journal for verified command output."
---

# Running a Local LLM: Setup, Tradeoffs, and Real Electricity Cost

> **Audience:** Technical practitioners curious about running AI locally. Useful if you have GPU hardware (8 GB VRAM minimum for meaningful performance) and are comfortable with system administration.
> **Purpose:** Why you might want to, what it takes, how to set it up with Cursor and Claude Code, and how to design an electricity measurement approach using circuit-level monitoring.
>
> ⚠️ **Direction-reviewed.** Setup steps are a starting point for experimentation, not a verified how-to. Ollama and RamaLama commands have been tested on AMD RX 7900 XT / Fedora 43. LiteLLM and vLLM steps have not been run on this hardware. See the [experiment journal](../../research/ai-tooling/local-llm-experiment-journal.md) for what was actually run.

**Experiment journal:** Dated, machine-specific logs (commands, image tags, what worked, what failed) live in [`research/ai-tooling/local-llm-experiment-journal.md`](../../research/ai-tooling/local-llm-experiment-journal.md). This article is the stable reference; the journal is the running log.

**vLLM reference:** The vLLM install, serve commands, and container setup are in a separate page — [vLLM Reference: Server-Grade Local Inference](local-llm-vllm.md). Start here first; go there if you need maximum serving throughput or a production-grade setup.

---

## Why Run Locally

Cloud AI tools (Cursor, Claude, Copilot) work by sending your text to a remote server, getting a response back, and billing you per token or per subscription. For most people, most of the time, that's the right tradeoff.

But there are legitimate reasons to want the model running on your own hardware:

- **Privacy.** Your code, prompts, and context never leave your network. This matters most when your work involves proprietary code, customer data, or regulated information.
- **Offline work.** No internet connection required once the model is downloaded.
- **Cost at scale.** At high enough usage, electricity cost can undercut API fees — but the crossover point is higher than most people expect.
- **Experimentation.** Run models not available via any API, or in ways APIs don't permit.
- **Understanding.** You learn how these systems actually work at the seam between software and hardware.

The electricity angle is the most interesting piece to measure honestly, because the common framing ("self-host to save money") often gets the math wrong.

---

## Hardware Requirements

The critical constraint is **VRAM** — the memory on your GPU. The model weights have to fit there.

| VRAM | What fits | Examples |
|------|-----------|---------|
| 6–8 GB | 7–9B parameters | Qwen2.5 Coder 7B, Llama 3.1 8B |
| 10–12 GB | 12–14B parameters | Gemma 3 12B, Phi-4 14B |
| 16–24 GB | 22–35B parameters | Qwen3 30B MoE, Qwen2.5 32B, DeepSeek-R1 32B |
| 48 GB+ | 70B+ parameters | Llama 3.3 70B, Qwen2.5 72B |

Common consumer GPUs: RTX 4060 (8 GB), RTX 4070 (12 GB), RTX 4090 (24 GB).

**Without a discrete GPU:** Ollama runs in CPU-only mode automatically. Expect 7–15 tok/s on a modern CPU — usable for non-interactive tasks. You need enough system RAM to hold the model: 16 GB minimum for 7B, 32 GB for 13B. vLLM is not aimed at CPU-only.

**Apple Silicon:** Unified memory means even base M-series configurations (16–32 GB) run meaningful models efficiently, and power draw is dramatically lower than a desktop GPU.

**Evaluating your current setup on Linux:** Run `lspci | grep -Ei "vga|3d"` to identify your GPU, then `nvidia-smi` (NVIDIA) or `rocm-smi` (AMD) for VRAM and power baseline. For RAM: `free -h`. For storage: `df -h ~ && lsblk -d -o NAME,SIZE,ROTA,MODEL`. The experiment journal and [`local-llm-sysadmin.md`](local-llm-sysadmin.md) have more context on interpreting these outputs.

---

## Setup: Cursor with a Local Model

Cursor has native support for custom endpoints. Under Settings → Models, point it at any OpenAI-compatible API — which is exactly what local inference tools expose.

### Ollama

**[Ollama](https://ollama.com/)** is the easiest starting point. It runs as a local server, serves an OpenAI-compatible API at `http://localhost:11434/v1`, and manages model downloads with a single command:

```bash
ollama pull qwen3:30b-a3b
```

In Cursor, set the OpenAI Base URL to `http://localhost:11434/v1` and add the model name. No internet connection required during use.

### RamaLama (Fedora / RHEL)

**[RamaLama](https://github.com/containers/ramalama)** detects your GPU (CUDA, ROCm, or CPU), pulls the right container image, and fetches the model in one command:

```bash
sudo dnf install ramalama

# Interactive
ramalama run ollama://qwen3:30b-a3b

# Serve an OpenAI-compatible API
ramalama serve ollama://qwen3:30b-a3b
# API at http://127.0.0.1:8080/v1  (use 127.0.0.1, not localhost — IPv4 only)
# Model ID: library/qwen3
```

> **Registry note:** Not all models are mirrored at `quay.io/ramalama/`. For models not mirrored there, use the `ollama://` prefix to pull from Ollama's registry directly (e.g. `ollama://qwen2.5:32b`).

llama.cpp auto-fits context to available VRAM. On a 20 GB card with `qwen3:30b-a3b`, runtime `n_ctx` is ~14k tokens (not the 32k or 262k figures the model self-reports — those are training configuration values, not runtime allocations). Always check actual `n_ctx` in startup logs. See [What a Context Window Actually Is](what-a-context-window-actually-is.md).

RamaLama tradeoffs vs. manual `podman run`: less control over fine-grained inference flags (`--enforce-eager`, `--max-model-len`, `--gpu-memory-utilization`), which matter at the edge of available VRAM. For routine model runs, it significantly reduces friction.

> **Fedora / glibc / RamaLama:** If `ramalama serve` fails with **`GLIBC_2.43` not found** from **`libllama.so` / `libggml-base.so`**, check **both** host **and** the **default ROCm OCI image**: `podman run --rm quay.io/ramalama/rocm:latest ldd --version`. The error paths look like **`/lib64/...`** but **`llama-server` usually runs inside the container**, so **image glibc** can stay **2.42** while the **bundled** llama `.so` files expect **2.43** — **upgrading the host** (e.g. to Fedora 44) **may not fix it** until the **image** userspace catches up. Workaround: **Ollama ROCm container** or another image/tag/digest. See [experiment journal](../../research/ai-tooling/local-llm-experiment-journal.md) (**2026-05-06**, **2026-05-07**).

### LM Studio

**[LM Studio](https://lmstudio.ai/)** takes the same approach with a graphical interface. Its local server runs at `http://localhost:1234/v1`.

### vLLM (server-grade)

**[vLLM](https://docs.vllm.ai/)** targets Linux with a discrete GPU and is built for serving throughput (continuous batching, PagedAttention). It's more complex to set up but gives the most control. Install and serve commands are in the [vLLM Reference](local-llm-vllm.md).

Point Cursor at the vLLM server: Settings → Models → OpenAI Base URL → `http://localhost:8000/v1`. Model ID is the Hugging Face repo name (not Ollama tag syntax).

### Pi + paude (OpenAI-compatible server on the LAN)

**[paude](https://github.com/bbrowning/paude)** (this workspace’s fork) can run **[Pi](https://github.com/badlogic/pi-mono)** against any **OpenAI-compatible** HTTP API — including **RamaLama** / **llama.cpp** on the same machine or on a **dedicated LLM host** (flat home LAN, DHCP reservation + DNS such as `llm.lan`, host firewall allowing only the LAN CIDR). See the [experiment journal](../../research/ai-tooling/local-llm-experiment-journal.md) (**2026-05-03**, **2026-05-08**) for image / `n_ctx` notes.

1. **Serve** the model (example: RamaLama with a ROCm image that matches host libc — journal).
2. **On the host** (same shell you use for `paude create`):

   ```bash
   export OPENAI_BASE_URL=http://127.0.0.1:8080/v1    # or http://llm.lan:8080/v1
   export OPENAI_API_KEY=sk-local-placeholder        # if the server does not enforce keys
   ```

   **Pi detail:** Pi’s OpenAI client uses each model’s **`baseUrl`** from its catalog (built-ins default to **`https://api.openai.com/v1`**). Setting **`OPENAI_BASE_URL`** alone does not change that. Pi expects **`providers.openai.baseUrl`** in **`~/.pi/agent/models.json`** (see Pi [models.md](https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/models.md) — *Overriding built-in providers*). **paude** injects that merge from **`OPENAI_BASE_URL`** when you use **`--agent pi --provider openai`** (first container start / sandbox script).

3. **Create a session** (Podman/Docker backend):

   ```bash
   paude create --agent pi --provider openai
   ```

   Default model flag matches RamaLama’s **`GET /v1/models`** id for the Ollama-style alias (e.g. **`openai/library/qwen2.5-coder`**); override with **`--agent-args '--model openai/…'`** if your server reports a different id.

4. **Egress proxy (paude-proxy):** Agent traffic uses **`HTTP_PROXY` / `HTTPS_PROXY`** with **`NO_PROXY`** limited to **loopback** so **all** other destinations go through the forward proxy. For restricted **`--allowed-domains`**, paude **appends the hostname** from **`OPENAI_BASE_URL`** / **`OPENAI_API_BASE`** to the **proxy allowlist** (unless **`all`**). Same-host LLM: use **`http://host.containers.internal:8080/v1`** in **`OPENAI_BASE_URL`** so the **proxy** can reach the host from its network namespace (the agent often cannot route to the host’s own LAN IP). Add **`--allowed-domains`** entries for any other hosts you need.

5. **Quick check** that the API is reachable from the host:

   ```bash
   ./scripts/smoke-local-openai-api.sh "$OPENAI_BASE_URL"
   ```

6. **Pi `models.json`:** Set **`contextWindow`** to the **measured runtime `n_ctx`** for that model id (journal); otherwise long prompts can truncate silently.

#### Serving the LLM over HTTPS (required for paude-proxy)

**Why it's required:** `paude-proxy` does TLS MITM on all `CONNECT` tunnel requests. Pi's Node.js `undici` client uses `CONNECT` tunneling for **all** proxied traffic — including plain `http://` targets. The proxy's MITM then opens a TLS session to the upstream, which fails with `tls: first record does not look like a TLS handshake` when the LLM server only speaks plain HTTP.

The solution is to put a TLS-terminating reverse proxy in front of the LLM server, backed by a private CA cert that the proxy container is told to trust.

**Step 1 — Generate a private CA and server cert:**

```bash
./scripts/gen-llm-tls-cert.sh ~/llm-certs 10.0.0.202 llm.lan
# Writes ca.crt, server.crt, server.key to ~/llm-certs/
```

**Step 2 — Run a TLS reverse proxy in front of RamaLama.**  [Caddy](https://caddyserver.com/) is the simplest option on Fedora:

```bash
sudo dnf install caddy

cat > /tmp/Caddyfile <<'EOF'
{
    auto_https disable_redirects
}
:8443 {
    tls /home/USER/llm-certs/server.crt /home/USER/llm-certs/server.key
    reverse_proxy localhost:8080
}
EOF

caddy run --config /tmp/Caddyfile
```

Or nginx:

```nginx
server {
    listen 8443 ssl;
    ssl_certificate     /home/USER/llm-certs/server.crt;
    ssl_certificate_key /home/USER/llm-certs/server.key;
    location / {
        proxy_pass http://127.0.0.1:8080;
    }
}
```

**Step 3 — Point `OPENAI_BASE_URL` at the HTTPS port:**

```bash
export OPENAI_BASE_URL=https://10.0.0.202:8443/v1
export OPENAI_API_KEY=local-placeholder
```

**Step 4 — Create a paude session, injecting the CA cert into the proxy container:**

```bash
paude create --provider openai --upstream-ca ~/llm-certs/ca.crt
```

The `--upstream-ca` flag mounts the CA file into the proxy container at startup and runs `update-ca-trust` before the proxy process starts.  The Go TLS client inside the proxy then trusts the cert when it opens its upstream connection to the LLM server.  The cert path is persisted in a container label so proxy recreation (e.g. `paude allowed-domains --add`) re-mounts it automatically.

> **Port note:** port 443 is already open in the proxy's default port filter.  If you serve on 8443, paude auto-adds that port to `ALLOWED_OTEL_PORTS` (the same mechanism used for OTEL ports) when `--provider openai` is set.

---

## Setup: Claude Code with a Local Model

Claude Code is hardcoded to call Anthropic's servers. The workaround is **[LiteLLM](https://litellm.ai/)** — a proxy that sits between Claude Code and your local model, accepting Anthropic-formatted requests and translating them for whatever backend you're running.

```
Claude Code → LiteLLM Proxy (port 4000) → Ollama / vLLM → local GPU
```

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

**Backend: vLLM** — use the [`hosted_vllm/` prefix](https://docs.litellm.ai/docs/providers/vllm) with the same model id vLLM was started with:

```yaml
model_list:
  - model_name: claude-3-5-sonnet-20241022
    litellm_params:
      model: hosted_vllm/Qwen/Qwen2.5-Coder-32B-Instruct-AWQ
      api_base: 'http://localhost:8000'
```

Start the proxy and point Claude Code at it:

```bash
litellm --config config.yaml --port 4000

export ANTHROPIC_BASE_URL="http://localhost:4000"
export ANTHROPIC_API_KEY="sk-anything"
claude
```

The `ANTHROPIC_API_KEY` value doesn't matter — LiteLLM ignores it since there's no cloud authentication happening.

---

## Choosing a Model

### Performance tiers on 20 GB VRAM (verified, AMD RX 7900 XT)

| Model | Architecture | VRAM | tok/s (gen) | n_ctx | Notes |
|-------|-------------|------|-------------|-------|-------|
| `qwen3:30b-a3b` | MoE (3B active) | ~19.5 GB | **~90** | ~14k | Best interactive speed; 1-command RamaLama. Thinking variant — adds latency on short prompts. |
| `qwen2.5:32b` | Dense | ~19.8 GB | **19.4** | 4096 | Works on 20 GB with tight margin; system state at launch matters. Slower but dense. |

**Why MoE is faster:** `qwen3:30b-a3b` has 30B total parameters but only ~3B active per token (MoE routing). Compute per token equals a 3B dense model; all 30B still live in VRAM. This is the architecture behind Mixtral and (likely) GPT-4. For coding and DevOps tasks on consumer hardware, the quality difference vs. dense 32B is small; the speed difference is 4–5×.

### Full model reference (2026)

| Model | Size | VRAM | Good for |
|-------|------|------|---------|
| `Qwen/Qwen3-Coder-Next-FP8` (vLLM / NVIDIA) | ~80B MoE, ~3B active | ~20 GB | Primary NVIDIA vLLM: repo-scale edits, tool use. Not for vLLM + ROCm Radeon today (FP8 MoE gap). |
| `Qwen/Qwen2.5-Coder-32B-Instruct-AWQ` (vLLM / AMD) | 32B AWQ | ~20 GB | Primary AMD vLLM. On 20 GB cards, weights consume ~18.3 GB leaving ~1k tokens KV — proof-of-concept, not interactive workflow. For longer context use Ollama `qwen3:30b-a3b`. |
| `qwen3:30b-a3b` (Ollama / RamaLama) | 30B MoE | ~19.5 GB | **Best for 20 GB AMD cards.** ~14k context, ~90 tok/s, 1-command setup. Verified RX 7900 XT / gfx1100. |
| `qwen2.5:32b` (Ollama / RamaLama) | 32B dense | ~19.8 GB | 19.4 tok/s, 4096 context, full GPU. Works on 20 GB with tight VRAM margin. See experiment journal. |
| `qwen2.5-coder:7b` | 7B | 6–8 GB | Quick lookups, simple edits, learning the workflow. |
| `llama3.3:70b` | 70B | 48 GB+ | Agentic tasks, research synthesis, essay writing. |
| `deepseek-r1:32b` | 32B | 20–24 GB | Reasoning-heavy tasks; slower but strong on multi-step logic. |

### Matching model size to task complexity

VRAM determines what you *can* run. Task complexity determines what you *should* run.

| Complexity tier | Example tasks | Minimum model |
|----------------|--------------|---------------|
| **Syntax / lookup** | Code completion, docstring, explain a function | 7B–8B |
| **Single-file reasoning** | Refactor one file, summarize a document | 7B–8B |
| **Multi-file reasoning** | Cross-reference configs, edit while preserving patterns elsewhere | 13B–32B |
| **Domain synthesis** | Kubernetes diagnosis across YAML + logs + docs, Helm chart authorship | 32B |
| **Agentic multi-step** | Research pipelines, adversarial review across a corpus, session handoffs | 70B+ |
| **Voice-consistent writing** | Essay drafting with preserved tone across a series | 70B+ |

*These are estimated thresholds, not benchmarks. A 7B model will attempt any of these — it just degrades as complexity increases. Test a smaller model first; your observations beat the table.*

### PAI / Kai and agentic use cases

Daniel Miessler's [PAI architecture](https://danielmiessler.com/blog/personal-ai-infrastructure) — 67 skills, 333 workflows, three-tier memory, The Algorithm's two-loop structure — represents the upper end of the personal use case. Running it reliably against a local model requires **70B+ or a frontier API**. Below 32B, the model itself becomes the coherence bottleneck for agentic tasks. The library entry at [`library/daniel-miessler-pai.md`](../../library/daniel-miessler-pai.md) has the full breakdown.

---

## The Electricity Picture

This is where having real circuit-level data *will* change the conversation — once the measurements are taken. The monitoring setup is in place with over a year of whole-home circuit data. What follows is the methodology. No LLM workloads have been measured yet; the case studies come later.

Published estimates for system-level power draw under inference load:

| Hardware | Approx. draw under load |
|----------|------------------------|
| Mac Studio M4 Max | 60–100 W |
| RTX 4060 Ti system | 140–175 W |
| RTX 4080 Super system | ~340 W |
| RTX 4090 system | 500–600 W |
| RTX 4090 (power-limited) | 350–400 W |

At US average electricity rates (~$0.15/kWh), a 24/7 RTX 4090 setup costs roughly $55–75/month in electricity alone. An M4 Max Mac Studio running continuously is around $9/month.

Break-even against API costs depends on usage volume. The [Braincuber economics analysis](../../research/openshift-ai-llm-deployment/sources/ref-61.md) found that API wins for 87% of real-world use cases — the crossover to self-hosting only makes economic sense at industrial scale (~500M+ tokens/day).

**What's different here:** circuit monitoring captures actual draw from known hardware at known times, correlated against real workloads — more honest than published TDP specs. As experiments run, the delta between GPU-at-idle and GPU-under-inference becomes the actual cost figure. Case studies will follow.

---

## Honest Assessment

Local models are improving fast, but the quality gap with frontier models remains real for complex reasoning. For routine code completion, documentation, and simple refactoring, a good 7B–8B model is surprisingly capable. For architectural reasoning, multi-file refactors, and tasks requiring broad knowledge, frontier models are noticeably better.

The privacy and offline arguments are strong independent of cost. If your use case involves proprietary code you're uncomfortable sending to a third-party server, local inference answers that concern regardless of economics.

The cost argument requires honest accounting: hardware purchase, power draw, cooling, time spent on configuration and model management. The API subscription often wins on total cost of ownership unless the privacy case or the scale case is genuinely compelling.

---

## Related Reading

- [vLLM Reference: Server-Grade Local Inference](local-llm-vllm.md) — full vLLM install, serve commands, container setup (NVIDIA + AMD), context limits, and cluster topology
- [What a Context Window Actually Is](what-a-context-window-actually-is.md) — why the model's self-reported context window and the actual runtime allocation are usually different numbers
- [The Case for Local: Disk Management as a Privacy-First AI Task](local-llm-sysadmin.md) — a worked example of a task that belongs on local inference, and the privacy argument made concrete
- [Enterprise LLM Deployment on OpenShift AI](openshift-ai-llm-deployment-summary.md) — the enterprise side of the same question: vLLM on Kubernetes, multi-tenancy, economics at scale
- [AI-Assisted Development Workflows](ai-assisted-development-workflows.md) — broader patterns for AI-assisted work
- [Local LLM Experiment Journal](../../research/ai-tooling/local-llm-experiment-journal.md) — dated logs of what was actually run: commands, failures, layer splits, tok/s numbers
- [Level1Techs — AI and You Against the Machine](../../library/level1techs-ai-you-against-machine-local.md) — long-context local MoE + quant framing; AMD vs NVIDIA paths (library entry + cached transcript)

---

*This document was created with AI assistance (Cursor) and has been direction-reviewed by the author. Ollama and RamaLama commands are partially verified; LiteLLM proxy, vLLM commands, and power figures have not been tested on this hardware. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
review:
  status: direction-reviewed
  notes: "Author has read and directed this draft. Technical claims (model sizes, VRAM requirements, power draw figures, LiteLLM setup steps, Ollama commands) need hands-on verification before citing. Electricity measurement methodology not yet validated against real circuit data. Needs fact-checked and commands-verified to reach reviewed."
---

# Running a Local LLM: Setup, Tradeoffs, and Real Electricity Cost

> **Audience:** Technical practitioners curious about running AI locally. The hardware requirements (8 GB VRAM minimum for useful GPU inference) mean this is most relevant to those already comfortable with system administration.
> **Purpose:** Covers why you might want to, what it takes to set it up with Cursor and Claude Code, and how to design an electricity measurement approach using circuit-level monitoring. Setup steps are a starting point for experimentation, not a verified how-to.
>
> ⚠️ **Direction-reviewed.** The direction and content have been read and guided by the author, but the setup steps, model recommendations, and power figures have not been tested on this hardware. Treat as a research starting point, not a verified how-to.

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
ollama pull qwen2.5-coder:7b
```

In Cursor, set the OpenAI Base URL to `http://localhost:11434/v1` and add the model name. Cursor sends requests to your local machine instead of Anthropic or OpenAI. No internet connection required during use.

**[LM Studio](https://lmstudio.ai/)** takes the same approach with a graphical interface — useful if you prefer not to use the command line. Its local server runs at `http://localhost:1234/v1`.

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

Create a `config.yaml` that maps Claude model names to your local model:

```yaml
model_list:
  - model_name: claude-3-5-sonnet-20241022
    litellm_params:
      model: ollama/qwen2.5-coder:7b
      api_base: 'http://localhost:11434'
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

**Without a GPU:** Ollama will use CPU-only mode if no GPU is available. Expect 7–15 tokens per second on a modern CPU, which is usable but noticeably slower. You need enough system RAM to hold the model — 16 GB minimum for a 7B model, 32 GB for a 13B.

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

`-s pcut` selects power, compute utilization, memory utilization, and temperature. `-c 10` captures 10 samples and exits. This is your pre-inference baseline — run it before starting Ollama to get a steady-state number.

**If you have an AMD GPU** (and ROCm is installed):

```bash
rocm-smi
```

If ROCm is not installed, `radeontop` provides similar real-time GPU metrics:

```bash
sudo dnf install radeontop   # Fedora
radeontop
```

**If no discrete GPU is detected:** Ollama will run in CPU-only mode automatically. Continue to the RAM and CPU sections — those become the relevant constraints.

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

The `nvidia-smi dmon` baseline power reading from before you start Ollama is directly useful for the electricity measurement work: it establishes what the system draws at idle, so you can subtract it from the inference-load reading to isolate the model's actual cost.

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

For coding and DevOps work specifically:

| Model | Size | VRAM needed | Good for |
|-------|------|------------|---------|
| `qwen2.5-coder:7b` | 7B | 6–8 GB | Quick lookups, simple edits, learning the workflow |
| `qwen2.5-coder:32b` | 32B | 20–24 GB | Multi-file DevOps work, Helm, Ansible, OCP YAML |
| `llama3.3:70b` | 70B | 48 GB+ | Agentic tasks, research synthesis, essay writing |
| `deepseek-r1:32b` | 32B | 20–24 GB | Reasoning-heavy tasks; slower but stronger on multi-step logic |
| `qwen3:30b-a3b` | 30B (MoE) | ~20 GB | Efficient alternative — mixture-of-experts, faster than dense 30B |

The Qwen 2.5 Coder series is specifically trained on code and technical documentation, which matters for this workspace's DevOps content. For essay and research work, a general-purpose 70B is better than a coding-specialized 32B.

### What this means for hardware

The 32B threshold is the inflection point. Getting there requires approximately 20–24 GB VRAM — two RTX 4070s (24 GB combined), a single RTX 4090 (24 GB), or a professional card like the RTX A5000 or 6000. The 70B threshold requires 48 GB+ — typically two RTX 4090s or a single A100/H100.

If your current hardware lands below 20 GB VRAM, the practical options are:
1. Run a 7B–13B model locally for routine tasks, stay on cloud APIs for complex work
2. Use CPU+GPU split offloading for 32B models (Ollama supports this automatically) — slower, but functional
3. Treat local inference as a privacy/offline capability, not a quality replacement for frontier models

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
Home hardware, Ollama or LM Studio, circuit-level electricity monitoring, privacy and experimentation. The entry point for most individuals.

**Agentic personal AI (PAI/Kai pattern) — *forthcoming***
Model selection and hardware for autonomous agent architectures. Memory systems, scaffolding design, running The Algorithm reliably. The power-user extension of this guide. Will draw from the PAI/Kai research in [`research/pai-kai-paude/`](../../research/pai-kai-paude/) and [`library/daniel-miessler-pai.md`](../../library/daniel-miessler-pai.md).

**Enterprise inference serving — OpenShift AI**
vLLM on GPU-enabled Kubernetes nodes, KServe, Red Hat OpenShift AI (RHOAI), multi-tenancy, compliance, governance. A completely different problem space — about serving models at scale, not running them interactively. Already documented in [Enterprise LLM Deployment on OpenShift AI](openshift-ai-llm-deployment-summary.md) with a full verification assessment of the economics and architecture claims.

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

---

*This document was created with AI assistance (Cursor) and has been direction-reviewed by the author. Setup steps, model recommendations, and power figures have not been verified against real hardware. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

# Local LLM Setup — Consumer Inference

Practical setup guides for running large language models locally: Ollama, RamaLama, LM Studio, LiteLLM proxy, and vLLM for maximum serving throughput.

**What belongs here:** Runnable setup commands, configuration reference, hardware matching, integration patterns for local inference tools. Not essays about the implications of local AI (those live in [`docs/`](../../docs/)) and not enterprise deployment (OpenShift AI is covered elsewhere).

---

### [Running a Local LLM: Setup, Tradeoffs, and Real Electricity Cost](local-llm-setup.md)

How to point Cursor and Claude Code at a locally-running model (Ollama, RamaLama, LM Studio, LiteLLM proxy), with **Qwen3** as the default family for DevOps/coding in this workspace. Covers hardware requirements, model selection (with measured tok/s on RX 7900 XT), electricity measurement methodology, and when local wins vs. cloud.

### [vLLM Reference: Server-Grade Local Inference](local-llm-vllm.md)

Full vLLM install (NVIDIA CUDA + AMD ROCm), serve commands, Docker/Podman container setup, context window limits, the AMD FP8 MoE gap, `cursor agent` CLI limitation, and cluster topology.

---

## Troubleshooting

- **[LiteMaaS / LiteLLM — Streaming Limitations with Thinking Models](litemaas-streaming-limitations.md)** — Qwen3 reasoning content is stripped from streaming responses by LiteLLM; the model reasons but Pi never sees the chain. Documents the workaround, the upstream fix path, and why reasoning visibility matters for diagnosing behavioral failures.

---

## Related

- [What a Context Window Actually Is](../../docs/ai-engineering/what-a-context-window-actually-is.md) — why the model's self-reported context window and the actual runtime allocation are usually different numbers
- [The Case for Local: Disk Management as a Privacy-First AI Task](../../docs/ai-engineering/local-llm-sysadmin.md) — a case study of using a local LLM to diagnose and plan disk space cleanup
- [Enterprise LLM Deployment on OpenShift AI — Summary](../../docs/ai-engineering/openshift-ai-llm-deployment-summary.md) — the enterprise side: vLLM on Kubernetes, multi-tenancy, economics at scale
- [Local LLM Experiment Journal](../../research/ai-tooling/local-llm-experiment-journal.md) — dated logs of what was actually run

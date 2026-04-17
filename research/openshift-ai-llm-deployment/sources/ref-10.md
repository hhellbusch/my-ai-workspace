# Source: ref-10

**URL:** https://developers.redhat.com/articles/2025/10/06/optimize-and-deploy-llms-production-openshift-ai
**Fetched:** 2026-04-17 (WebFetch fallback)

---

# Optimize and deploy LLMs for production with OpenShift AI

October 6, 2025

## Overview

Organizations running LLMs on their own infrastructure face challenges related to GPU availability, capacity, and cost. Models like Qwen3-Coder-30B-A3B-Instruct require multiple NVIDIA L40S GPUs using tensor parallelism. Long context windows cause the KV cache to consume gigabytes of GPU memory.

Quantization reduces the model's memory footprint by compressing numerical weights to lower-precision values. The pipeline uses LLM Compressor from Red Hat AI Inference Server to quantize using activation-aware quantization (AWQ), which redistributes weight scales to minimize quantization error. This enables single-GPU serving with strong accuracy retention.

## Workflow Stages:

1. Model download and conversion
2. Quantization (AWQ)
3. Validation and evaluation (lm_eval, GuideLLM)
4. Packaging in ModelCar format
5. Pushing to OCI registry
6. Deployment on OpenShift AI with vLLM
7. Performance benchmarking

## Key Results:

- File size: 64 GB to 16.7 GB (quantized)
- HumanEval pass@1: Quantized = 0.933, Unquantized ≈ 0.930 (slight accuracy increase)
- Max throughput: Quantized ~8,056 tokens/sec (1 GPU) vs Unquantized ~6,032 tokens/sec (4 GPUs)
- TTFT consistently reduced in quantized model

## AWQ Recipe:

```python
recipe = [
    AWQModifier(
        duo_scaling=False,
        ignore=["lm_head", "re:.*mlp.gate$", "re:.*mlp.shared_expert_gate$"],
        scheme="W4A16",
        targets=["Linear"],
    ),
]
```

## Summary

AWQ quantization enables significant compression without performance trade-offs. The end-to-end pipeline on OpenShift AI automates downloading, quantizing, evaluating, packaging in ModelCar format, and deploying with vLLM—turning complex LLM deployment into a repeatable, production-ready process.

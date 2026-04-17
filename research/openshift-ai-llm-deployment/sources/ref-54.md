# Source: ref-54

**URL:** https://developers.redhat.com/articles/2025/01/30/compressed-granite-3-1-powerful-performance-small-package
**Fetched:** 2026-04-17 (WebFetch fallback)

---

# Compressed Granite 3.1: Powerful performance in a small package

January 30, 2025

Neural Magic is excited to join Red Hat, combining our expertise in AI optimization and inference with Red Hat's legacy of open-source innovation.

Our first contribution is the release of compressed Granite 3.1 8B and 2B models. Building on the Granite 3.0 series, IBM's Granite 3.1 introduced significant upgrades including competitive OpenLLM leaderboard scores, expanded 128K token context length, multilingual support for 12 languages, and enhanced functionality for RAG and agentic workflows.

## Compressed summary

- Neural Magic is now part of Red Hat, accelerating our mission to deliver open and efficient AI.
- New compressed Granite 3.1 models achieve 3.3X smaller models, up to 2.8X better performance, and 99% accuracy recovery.
- Models and recipes are open-sourced on Hugging Face, deployment-ready with vLLM, and extensible using LLM Compressor.

## Available options:

- FP8 weights and activations (FP8 W8A8): Optimized for server and throughput-based scenarios on NVIDIA Ada Lovelace and Hopper GPUs.
- INT8 weights and activations (INT W8A8): Ideal for servers using NVIDIA Ampere and earlier GPUs.
- INT4 weight-only models (INT W4A16): Tailored for latency-sensitive applications or limited GPU resources.

Extensive evaluations confirm that the up to 3.3X smaller, compressed Granite 3.1 models deliver 99% accuracy recovery, on average, and up to 2.8X better inference performance.

Models, recipes, and full evaluations are on Hugging Face, freely available under the Apache 2.0 license.

## Compressed Granite in action

The models integrate seamlessly with the vLLM ecosystem. LLM Compressor can further customize compression recipes.

## Key performance results:

For smaller request sizes (256 prompt tokens, 128 output tokens):
- Single Stream, Latency: W4A16 achieves 2.7X (A5000) to 1.5X (L40) lower latency
- Multi-Stream: W8A8 models perform best after 6 RPS on A5000; W4A16 performs best on L40 enabling up to 8X more RPS

For larger requests (4096 prompt tokens, 512 output tokens):
- Single stream, latency: W4A16 achieves 2.4X (A5000) to 1.7X (A100) lower latency
- Multi-stream: W8A8 models offer up to 4X (A5000) to 3X (A100) more requests at the same performance

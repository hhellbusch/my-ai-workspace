# Enterprise LLM Deployment on OpenShift AI — Summary

> **Source:** [Enterprise Generative AI: Architecting and Self-Hosting Large Language Models on Red Hat OpenShift](https://jaredburck.me/blog/openshift-ai-llm-enterprise-deployment/) by Jared Burck (March 2026)
>
> **What this is:** A layered summary of a comprehensive architecture guide. Start at the top for the strategic picture, go deeper for architecture decisions and practitioner detail.
>
> **Verification note:** This summary has been checked against the article's 62 cited sources. The architecture and operational content is well-sourced; the economic claims and some agentic AI maturity assertions carry caveats. See the [full verification assessment](../../research/openshift-ai-llm-deployment/assessment.md) for details. Inline notes below flag the key areas where the original article's claims required qualification.

---

## Executive Summary

Enterprises are moving from consuming LLMs via public APIs (OpenAI, Anthropic, etc.) to self-hosting them on controlled infrastructure. The drivers are data sovereignty, regulatory compliance (HIPAA, PCI DSS, FedRAMP), latency predictability, and cost at scale.

**The core principle:** bring the AI platform to the data, not the data to the AI platform.

**Red Hat OpenShift AI (RHOAI)** is the Kubernetes-native platform for this. It extends OpenShift with MLOps capabilities for deploying, scaling, and governing LLMs across hybrid cloud environments.

**Key economics:** The article claims self-hosting breaks even at approximately **11 billion tokens per month**, with up to **18x cost advantage** and ROI in under 4 months. *These figures carry significant caveats: the 11B threshold is verified in the [cited source](https://www.braincuber.com/blog/self-hosted-llms-vs-api-based-llms-cost-performance-analysis), but that source actually argues API wins for 87% of use cases — the article reversed the framing. The 18x figure compares on-prem hardware against GPT-5 mini API pricing (~$2/M tokens), a budget tier — not premium APIs. The <4 month ROI applies specifically to on-demand cloud pricing at high utilization (6-10 months against reserved instances). See the [verification assessment](../../research/openshift-ai-llm-deployment/assessment.md#finding-2-economics-built-on-vendor-marketing) for the full analysis.*

**The decision isn't binary.** Most organizations prototype with APIs or RHEL AI (single-server), then transition to OpenShift AI when they need distributed serving, multi-tenancy, autoscaling, and governance.

---

## Architecture Decisions

These are the key tradeoffs a platform team needs to evaluate. Each depends on organizational context — there is no universally correct answer.

### Platform: RHEL AI vs. OpenShift AI

| | RHEL AI | OpenShift AI |
|---|---|---|
| **Topology** | Single server (bare-metal or VM) | Distributed Kubernetes clusters |
| **Use case** | Prototyping, fine-tuning, small-scale | Production serving, multi-tenant MLOps |
| **Orchestration** | Systemd | Kubernetes (KServe, Knative, Service Mesh) |
| **Complexity** | Low — rapid provisioning | High — requires networking, RBAC, Day 2 ops |
| **When to choose** | Early experimentation, single-model validation | Enterprise production, compliance-driven environments |

The natural path: start on RHEL AI for experimentation, move to OpenShift AI for production serving.

### Inference Runtime: vLLM vs. TGIS vs. Caikit-TGIS

| | vLLM | Standalone TGIS | Caikit-TGIS |
|---|---|---|---|
| **Core optimization** | PagedAttention (near-zero VRAM waste) | Continuous batching, tensor parallelism | Abstraction layer over TGIS |
| **OpenAI API compatible** | Yes (native) | No (needs proxy) | No |
| **Hardware support** | NVIDIA, AMD, Intel Gaudi, CPU | NVIDIA, CPU | NVIDIA, CPU |
| **Model format** | Native Hugging Face (safetensors) | Native Hugging Face | Requires Caikit format conversion |
| **When to choose** | Default for most deployments | Legacy or specific tensor parallelism needs | Existing Caikit pipeline investments |

**vLLM is the de facto standard.** Its native OpenAI API compatibility means existing applications built on OpenAI SDKs can redirect to self-hosted endpoints by changing only the base URL.

### Model Storage: S3 vs. ModelCar

| | S3-Compatible Storage | ModelCar (OCI Images) |
|---|---|---|
| **How it works** | Model weights stored in S3 bucket; init-container downloads to pod on startup | Model weights baked into a container image; pulled and cached like any other image |
| **Cold start** | Full network download every scale-out event | First pull is slow; subsequent pods use node cache (significantly faster) |
| **Infra overhead** | Requires provisioning and maintaining separate S3 infrastructure | Uses existing container registry (e.g., Quay) |
| **CI/CD alignment** | Loose files in buckets; awkward to promote across environments | Immutable OCI artifact; can be versioned, signed, scanned like app images |
| **When to choose** | Existing S3 infrastructure already in place; very large models where image builds are impractical | New deployments; teams with existing DevSecOps container pipelines |

**ModelCar is the direction.** It eliminates the S3 dependency, aligns with GitOps, and benefits from Kubernetes node caching. Red Hat provides pre-built ModelCar images for popular models at `quay.io/redhat-ai-services/modelcar-catalog`.

### Infrastructure: On-Premise vs. Hyperscaler (ROSA/ARO)

| | On-Premise | ROSA / ARO |
|---|---|---|
| **Cost model** | CapEx (hardware purchase) | OpEx (hourly, elastic) |
| **GPU provisioning** | Fixed capacity; lead times for procurement | On-demand; spot instances for batch work |
| **Control** | Full — including air-gapped/disconnected | Managed — Red Hat SRE operates the control plane |
| **Compliance** | Required for air-gapped/FedRAMP/STIG environments | Inherits cloud provider certifications (FedRAMP, HIPAA, SOC 2) |
| **Scaling** | Limited by physical hardware | Dynamic MachineSets, scale-to-zero for non-GPU workloads |
| **When to choose** | Strict data sovereignty requirements, existing DC investment, disconnected environments | Elastic workloads, teams without DC operations staff, global low-latency serving |

**Platform consistency is the key advantage:** the same KServe, ServingRuntime, ModelCar, and rate-limiting definitions work identically on-prem and in the cloud. Fine-tune on-prem where sensitive data lives; serve globally from the cloud.

---

## Serving Architecture Stack

For those implementing: here's how the components fit together.

```
Request → Gateway API (Kuadrant/Envoy) → AuthPolicy + RateLimitPolicy
    ↓
Knative (request routing, buffering, autoscaling)
    ↓
KServe InferenceService (abstraction layer)
    ↓
ServingRuntime (vLLM) → GPU (discovered by NFD Operator, managed by GPU Operator)
    ↓
Model weights (loaded from ModelCar OCI image or S3 init-container)
```

**KServe** provides the `InferenceService` CRD — the single object that data scientists use to deploy a model without configuring Deployments, Services, and Ingress manually.

**Knative** (via OpenShift Serverless) handles request-driven autoscaling. For LLMs, scale-to-zero is impractical due to cold-start latency from reloading model weights — configure a minimum of one replica for user-facing endpoints.

**Service Mesh** (Istio-based) enforces mTLS between all pods and enables canary/A/B traffic splitting for model rollouts.

---

## Hardware and GPU Management

1. **Node Feature Discovery (NFD) Operator** — scans PCI bus on every node, labels nodes with hardware capabilities (e.g., `feature.node.kubernetes.io/pci-10de.present=true` for NVIDIA). Enables scheduler affinity rules.

2. **GPU Operator** (NVIDIA, AMD, or Intel) — deploys container toolkit, device plugins, and DCGM telemetry exporter. Must create a `ClusterPolicy` CR after installation. The legacy NVIDIA GPU add-on is deprecated and must be removed first.

3. **AcceleratorProfile** — bridges physical hardware to the RHOAI dashboard. Defines the resource identifier (e.g., `nvidia.com/gpu`) that users select when requesting GPU resources.

4. **GPU partitioning** — for smaller models or embedding workloads, NVIDIA MIG or time-slicing can split one physical GPU into multiple isolated logical instances.

---

## Agentic AI and MCP

RHOAI supports autonomous agent workflows beyond simple inference:

**Function calling** — vLLM 0.6.3+ supports tool/function calling. The model outputs structured JSON describing which function to call and with what arguments, instead of generating text. Requires three ServingRuntime flags: `--enable-auto-tool-choice`, `--tool-call-parser`, and `--chat-template`. Guided decoding ensures the JSON output strictly conforms to the provided schema.

**Model Context Protocol (MCP)** — an open standard for LLM-to-tool communication. Instead of writing bespoke integrations for every enterprise system, deploy standardized MCP Servers that handle auth, API translation, and execution routing. *Note: the original article compares MCP to USB-C as a "universal standard," but MCP's actual specification (modelcontextprotocol.io) does not support this analogy — MCP defines a protocol between hosts and servers, not a universal connector standard. The analogy overpromises. MCP is useful and gaining adoption, but it is still early-stage and not a solved interoperability problem.*

**Llama Stack** (Technology Preview) — end-to-end agentic framework deployed via `LlamaStackDistribution` CR. Provides inference, vector storage (Milvus), and document ingestion (Docling). Exposes an OpenAI-compatible API layer including the experimental Responses API for RAG.

**Security for agents** — agents are non-deterministic and execute code based on probabilistic generation. RHOAI provides kernel-level sandbox isolation via Kata Containers (GA as a layered product). *Note: per-session agent sandbox integration and Kagenti identity injection via SPIFFE/SPIRE are described as planned/roadmap capabilities in Red Hat's source material, not shipping features. The original article does not distinguish these maturity levels.*

---

## Day 2: Governance, Rate Limiting, Observability

### Gateway API and Kuadrant

- **AuthPolicy** — enforces identity validation per request via service account tokens or SSO. Uses `kubernetesSubjectAccessReview` to verify permissions for specific inference services.
- **RateLimitPolicy** — algorithmic rate limits based on identity. Example: 5 req/min for a departmental service account, 500 req/min for a production app. Enforced at the Envoy proxy layer — overages get HTTP 429 before the request ever reaches the GPU.

### Observability

- **Metrics** — Prometheus scrapes vLLM runtime metrics: request latency, time-to-first-token (TTFT), tokens/second throughput, queue depth, hardware utilization. RHOAI provides a pre-built Grafana dashboard.
- **Distributed tracing** — OpenTelemetry traces requests end-to-end through MaaS Gateway → Responses API → LLM → MCP Servers → synthesis. Essential for debugging latency in multi-step agentic workflows.

---

## Model Compression

Serving uncompressed models wastes GPU resources. Key optimization techniques:

| Format | Target hardware | Use case |
|---|---|---|
| **FP8 (W8A8)** | NVIDIA Ada Lovelace, Hopper | Maximum throughput on modern GPUs |
| **INT8 (W8A8)** | NVIDIA Ampere and earlier | Broad compatibility across older data centers |
| **INT4 (W4A16)** | VRAM-constrained / edge | Ultra-low latency, maximum memory reduction |
| **AWQ** | General GPU | Single-GPU deployment of large models with high accuracy retention |

Red Hat provides pre-compressed Granite 3.1 models optimized for each hardware tier. Compressed Granite 3.1 achieves **up to 3.3x size reduction** and **up to 2.8x throughput improvement** while maintaining **99% accuracy recovery on average** vs. uncompressed FP16. *These are best-case figures that vary by quantization format, hardware, and workload. The original article presents them without the "up to" and "on average" qualifiers found in the [source material](https://developers.redhat.com/articles/2025/01/30/compressed-granite-3-1-powerful-performance-small-package).*

---

## Support Lifecycle Quick Reference

- **OCP minor releases** — ~4 month cadence. Full Support for 6+ months, then Maintenance until 18 months post-GA.
- **EUS (Extended Update Support)** — even-numbered OCP releases only (4.16, 4.18, 4.20). Additional 6 months of support. Allows skipping odd-numbered releases entirely.
- **RHOAI** — independent release cycle, but mapped to supported OCP versions. Example: RHOAI 2.25 supports OCP 4.16–4.20.
- **Managed services (ROSA/ARO)** — auto-updated; SLA voided if cluster falls behind supported versions.

---

## TCO Decision Framework

The article presents a clear breakeven model. The directional logic is sound — self-hosting economics improve with volume — but the specific numbers require scrutiny.

```
                Token volume per month
                        |
       Low volume       |    High, sustained volume
                |               |
         API consumption    Self-hosting becomes viable
         (pure OpEx,        (but breakeven depends heavily on
          zero infra)        hardware, utilization, cloud pricing tier,
                             and API comparator — see caveats below)
```

**Low volume:** Use APIs. Zero infrastructure burden, pay-per-token.

**High volume:** Self-hosting can be significantly cheaper, but the economics depend on hardware utilization, whether you're comparing against on-demand or reserved cloud instances, and which API tier you benchmark against. The article's headline numbers (18x, <4 months ROI) come from a [Lenovo vendor whitepaper](https://lenovopress.lenovo.com/lp2368-on-premise-vs-cloud-generative-ai-total-cost-of-ownership-2026-edition) with specific assumptions — run your own TCO analysis for your workload profile.

**Hybrid approach:** Prototype and validate with APIs or RHEL AI. Transition to OpenShift AI when token volume, compliance, or latency requirements justify the infrastructure investment. A GPU at low utilization is far more expensive per token than one at full load — continuous batching (vLLM) is critical to keep utilization high.

---

*This summary was created with AI assistance (Cursor) and has not been fully reviewed by the author. Based on the [original article](https://jaredburck.me/blog/openshift-ai-llm-enterprise-deployment/) by Jared Burck. Claims were verified against the article's 62 cited sources — see the [full verification assessment](../../research/openshift-ai-llm-deployment/assessment.md) for methodology and detailed findings. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

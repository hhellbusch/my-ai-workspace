# Source: original-article

**URL:** https://jaredburck.me/blog/openshift-ai-llm-enterprise-deployment/
**Fetched:** 2026-04-17 (manual)

---

# Enterprise Generative AI: Architecting and Self-Hosting Large Language Models on Red Hat OpenShift

March 18, 2026 — Jared Burck

The transition from experimenting with commercial, public Application Programming Interfaces (APIs) to self-hosting Large Language Models (LLMs) within controlled enterprise infrastructure represents a profound maturation in organizational artificial intelligence strategy. Initial generative AI adoption has been overwhelmingly characterized by reliance on Model-as-a-Service (MaaS) offerings from hyperscalers and specialized AI vendors. While these API-based solutions provide immediate access to state-of-the-art models and require zero infrastructure management, they introduce profound challenges regarding data sovereignty, regulatory compliance, latency predictability, and long-term economic viability.

For enterprises operating within highly regulated sectors such as healthcare, finance, and the public sector, the fundamental challenge of data gravity often precludes the use of external APIs. Regulatory frameworks like HIPAA, PCI DSS, and FedRAMP dictate strict rules for data handling, jurisdiction, and encryption. Sending sensitive corporate telemetry, proprietary source code, or protected health information over the public internet to a multi-tenant AI provider introduces unacceptable compliance risks. The strategic imperative, therefore, is to invert the operational model: rather than moving the data to the AI platform, the enterprise must bring the AI platform directly to the data.

Red Hat OpenShift AI (RHOAI) provides the foundational, Kubernetes-native platform necessary to execute this architectural inversion. By extending the Red Hat OpenShift Container Platform with specialized machine learning operations (MLOps) capabilities, RHOAI enables the deployment, scaling, and governance of LLMs, SLMs, and complex agentic AI systems across hybrid cloud environments.

## Sections covered:
- Strategic Platform Selection: RHEL AI vs OpenShift AI
- Single-Model Serving Platform Architecture (KServe, Knative, Service Mesh)
- Hardware Acceleration Discovery and Node Telemetry (NFD, GPU Operator)
- Inference Runtimes (vLLM, TGIS, Caikit)
- Storage Architectures (S3 vs ModelCar)
- Disconnected/Air-Gapped Deployments
- Hyperscaler Architectures (ROSA, ARO)
- Advanced Agentic Workflows (Function Calling, MCP, Llama Stack)
- Day 2 Operations (Gateway API, Kuadrant, Rate Limiting)
- Observability and Telemetry
- Model Compression and Granite Ecosystem
- Enterprise Support Lifecycles
- TCO Economics

## Works Cited (62 references)
See manifest.md for the complete reference list and fetch status.

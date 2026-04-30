# Jared Burck — Enterprise Generative AI: LLMs on Red Hat OpenShift

## Metadata
- **Author:** Jared Burck
- **Type:** Technical article / architecture reference
- **Published:** March 18, 2026
- **URL:** https://jaredburck.me/blog/openshift-ai-llm-enterprise-deployment/
- **Tags:** devops, openshift, openshift-ai, llm, enterprise, kserve, vllm, rhoai, knative, service-mesh, mlops, on-prem, data-sovereignty
- **Added:** 2026-04-30
- **Wing:** devops / ai-engineering
- **Projects:** openshift-ai-llm-deployment (research done 2026-04-17)

## Why This Matters (personal)

The most comprehensive single-article overview of the RHOAI LLM serving stack available as of Q1 2026. Covers the full path from strategic justification (why on-prem vs. API) through the serving architecture (KServe, Knative, Service Mesh, vLLM) to operational concerns. High reference value for the OpenShift AI/LLM deployment track.

**Reliability caveat:** Research analysis (see `research/openshift-ai-llm-deployment/assessment.md`) found three systemic issues — qualifier stripping on performance figures, maturity flattening (TP/GA mixed without distinction), and vendor marketing cited as independent economic analysis. Use for architecture and operations; verify independently for economic claims and maturity assertions.

## Key Themes (AI-enriched)

### Strategic Framing: Data Gravity Inversion

The central thesis: regulated enterprises can't send sensitive data to external API providers (HIPAA, PCI DSS, FedRAMP). The only solution is to bring the AI platform to the data, not the data to the platform. RHOAI is framed as the mechanism for this "architectural inversion."

This framing holds up — the constraint is real for healthcare, finance, and public sector. The economic analysis supporting it is less rigorous (Lenovo and Red Hat whitepapers cited as independent research).

### RHOAI Serving Architecture

High-confidence content per the research assessment:

```
OpenShift Container Platform
  └── Red Hat OpenShift AI (RHOAI)
        ├── Model Serving: KServe (ServingRuntime + InferenceService CRDs)
        │     ├── Single-Model Serving (KServe + Knative Serving)
        │     └── Multi-Model Serving (ModelMesh)
        ├── Runtime: vLLM (OpenAI-compatible endpoint)
        ├── Service Mesh: Istio/Red Hat Service Mesh
        └── Hardware: NFD + GPU Operator (NVIDIA primary)
```

The OpenAI API compatibility layer (vLLM) is the key integration point — existing tools using the OpenAI SDK can point at a self-hosted endpoint with no code changes.

### ModelCar Pattern

Packages model weights as an OCI image alongside the serving container. Enables GitOps-native model deployment: model versions are container tags, rollbacks are standard Kubernetes operations. Reduces the "blob storage + manual sync" anti-pattern.

### Agentic AI Maturity (low confidence)

The article presents agentic AI and multi-agent orchestration on RHOAI as more mature than the evidence supports. The research found these sections lean on roadmap content and Technology Preview features presented alongside GA capabilities. Treat with caution.

## Research Outputs

| Artifact | Location |
|---------|---------|
| Source article | `research/openshift-ai-llm-deployment/sources/original-article.md` |
| 62-reference manifest | `research/openshift-ai-llm-deployment/manifest.md` |
| Full assessment (confidence table, systemic issues) | `research/openshift-ai-llm-deployment/assessment.md` |
| Docs output | `docs/ai-engineering/openshift-ai-llm-deployment-summary.md` |
| Verification notes | `research/openshift-ai-llm-deployment/verification-notes-v1.md` |

**Sources captured:** 53 of 62 cited references (85%). Full results in `research/openshift-ai-llm-deployment/findings/`.

## Sources

- Research: `research/openshift-ai-llm-deployment/`
- Docs output: `docs/ai-engineering/openshift-ai-llm-deployment-summary.md`
- Related: [Automate OCP Cluster Deployment — RHACM + AAP](automate-ocp-cluster-deployment-rhacm-aap.md)

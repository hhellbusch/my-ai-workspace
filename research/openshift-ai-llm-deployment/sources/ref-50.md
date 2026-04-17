# Source: ref-50

**URL:** https://www.redhat.com/en/blog/operationalizing-bring-your-own-agent-red-hat-ai-openclaw-edition
**Fetched:** 2026-04-17 17:54:53

---

# Operationalizing "Bring Your Own Agent" on Red Hat AI, the OpenClaw edition

March 16, 2026[Adel Zaalouk](/en/authors/adel-zaalouk "See more by Adel Zaalouk")*5*-minute read

[Artificial intelligence](/en/blog?f[0]=taxonomy_topic_tid:75501#rhdc-search-listing)

Share



Subscribe to RSS

The AI agent world is messy. Teams are reaching for [LangChain](https://github.com/langchain-ai/langchain), [LlamaIndex](https://github.com/run-llama/llama_index), [CrewAI](https://github.com/crewAIInc/crewAI), [AutoGen](https://github.com/microsoft/autogen), or building custom solutions from scratch. Good. That's how it should be during the creative phase. But once an agent leaves a developer's laptop and starts talking to production data, calling external application programming interfaces (APIs), or running on shared infrastructure, freedom without guardrails stops being a feature and starts being a liability.

We've watched the industry go through waves: Model APIs (such as chat completions), agentic APIs (such as assistants and later the OpenAI responses API), the age of frameworks, and now the age of harnesses and coding agents. The top layer keeps changing. It's becoming fungible. What doesn't change is the gap between "it works on my laptop" and "it runs in production, securely, at scale, with audit trails."

Our AgentOps strategy is built on a core principle: Bring Your Own Agent (BYOA). The platform is framework-agnostic. What matters is that the agent has identity, runs under least-privilege, gets observed, passes safety checks, and can be audited after the fact. The platform provides security, governance, observability, and lifecycle management. The agent stays yours.

## What [Red Hat AI](/en/products/ai) provides

This series previews how BYOA works in practice, covering what is available now and what we are building next.

We take [OpenClaw](https://github.com/openclaw/openclaw), a personal AI assistant that routes agent interactions across channels (WhatsApp, Telegram, Slack, Discord, and more) through a central WebSocket Gateway, and we operationalize it on Red Hat AI. We aren’t wrapping it in a proprietary framework, we’re wrapping it in platform infrastructure. OpenClaw is just the example—this approach works for any agent runtime.

OpenClaw doesn't sandbox much by default. It doesn't enforce role-based access control (RBAC), trace tool calls, or gate access to external services. Red Hat AI adds each of those layers using [Red Hat OpenShift](/en/technologies/cloud-computing/openshift) and [Red Hat OpenShift AI](https://www.redhat.com/en/technologies/cloud-computing/openshift/openshift-ai) native capabilities, without touching the agent's code. The rest of the post walks through each of those layers.

### Repurposing cloud-native to agent-native

We're not building agent infrastructure from scratch. We're repurposing the tools and deployment patterns that OpenShift already has and extending them for agentic workloads with Red Hat AI.

**Agents need isolation**: [OpenShift sandboxed containers](https://docs.openshift.com/container-platform/latest/sandboxed_containers/understanding-sandboxed-containers.html) (based on the [Kata Containers](https://katacontainers.io/) project, and a GA layered product) and the upcoming agent-sandbox integration provide kernel-isolated execution per agent session. The host and other agents' data are protected against a compromised agent.

**Agents need identity**: Scoped service-account tokens, with [SPIFFE](https://spiffe.io/)/[SPIRE](https://spiffe.io/docs/latest/spire-about/spire-concepts/) for cryptographic workload identity. No hardcoded keys. Instead, the platform will verify the agent and inject short‑lived, scoped service‑account tokens at the platform level. This is planned with the Kagenti integration for agent lifecycle as part of Red Hat AI.

**Agents need multitenancy**: Namespace isolation, NetworkPolicy, ResourceQuota, with verification that boundaries hold under adversarial testing.

**Agents need policy guardrails at multiple layers**: [OPA/Gatekeeper](https://open-policy-agent.github.io/gatekeeper/) and [Kyverno](https://kyverno.io/) policies at the Kubernetes level. The [Model Context Protocol](/en/topics/ai/what-is-model-context-protocol-mcp) (MCP) [Gateway](https://github.com/Kuadrant/mcp-gateway) for tool-level authorization. The Guardrails Orchestrator and NeMo Guardrails at the model inference boundary (more on that in the next section).

### Making agents safer and ready for production

For many enterprise teams, safety is becoming a primary blocker for getting agents and models to production. Not performance. Not cost. Trust. Enterprises need confidence that their AI remains compliant with regulations and protects their brand from reputational and legal risks, especially once it's consumed by external users.

Red Hat AI provides a portfolio approach to safety that covers the full lifecycle, including detection, testing, and risk mitigation before they reach production, and guards against threats that emerge at runtime.

**Before an agent goes live**: [Garak](https://github.com/NVIDIA/garak) (planned as part of Red Hat AI) provides adversarial vulnerability scanning for jailbreaks, prompt injection, and other attack vectors at the model level. Integration is planned through the TrustyAI operator, and consumable via [EvalHub](https://github.com/eval-hub) (an evaluation control plane), and Kubeflow Pipelines, enabling adversarial scans in CI/CD before promotion.

**At runtime (guardrails at the inference boundary)**: The TrustyAI [Guardrails Orchestrator](https://github.com/trustyai-explainability/trustyai-service-operator) (generally available as of OpenShift AI 3.0) screens model inputs and outputs. [NeMo Guardrails (tech preview)](https://github.com/NVIDIA/NeMo-Guardrails)adds programmable conversational rails. Both operate at the inference boundary, intercepting individual large language model (LLM) calls to enforce safety before a response ever reaches the agent. A planned model-risk view in the model catalog will surface these safety signals alongside model metadata, so teams can factor in use-case risk before choosing a model.

### Observability, tracing, and evaluation

Agents are stochastic. You cannot debug or trust them in production without execution traces.

Red Hat AI is providing the foundation for agent observability, starting with first-party support for [MLflow](https://mlflow.org/), which is currently in [developer preview,](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.2/html/release_notes/developer-preview-features_relnotes) and planned for general availability in an upcoming release.

[MLflow Tracing](https://mlflow.org/docs/latest/llms/tracing/index.html) captures prompts, reasoning steps, tool invocations, LLM API requests, and token costs. All traces are [OpenTelemetry](https://opentelemetry.io/) compatible, so any OTEL-compatible sink can integrate. Beyond tracing, MLflow capabilities for scoring and evaluation can be used to assess agent quality over time, and these workflows are planned to be invoked through [Eval Hub,](https://github.com/eval-hub/eval-hub) an evaluation control plane that is part of OpenShift AI.

### Governing tool calls at scale

Agents call tools. The question is how to govern those calls.

The MCP Gateway (built with the OpenShift networking team, Envoy-based), currently in developer preview, sits in front of all your MCP servers as a single, secure endpoint. It adds identity-based tool filtering so agents only see authorized tools, OAuth2 token exchange for scoped per-backend access, and credential management so sensitive tool calls go through proper authorization. The platform enforces access. The application manages credentials, so there is no cross-server leakage.

Authorization is enforced through [Kuadrant](https://kuadrant.io/)'s AuthPolicy, which integrates [Authorino](https://github.com/Kuadrant/authorino) for JSON Web Token (JWT) validation and Open Policy Agent (OPA) rule evaluation at the [Gateway API](https://gateway-api.sigs.k8s.io/) level.

For OpenClaw, this means the agent sets one `MCP_URL`environment variable and gets access to an aggregated tool catalog. Which tools it can actually call is determined by its token claims, not by the prompt. Prompt injection attacks that try to trick the agent into calling unauthorized tools get stopped at the infrastructure layer, because the gateway ignores prompt content entirely. It validates token claims.

### Choosing API surfaces for production agents

A lot of teams started with chat, moved to chat completions and OpenAI APIs, then to frameworks, and now to agent harnesses. The APIs agents use are consolidating. One of the leading APIs for agentic workloads is the [Responses API](https://platform.openai.com/docs/api-reference/responses), and OpenAI has now opened that direction through the [OpenResponses specification.](https://www.openresponses.org/)

Red Hat AI is providing an implementation that is fully conformant with the OpenResponses specification. This creates a path for teams to run agent workloads on self-hosted or hybrid-model infrastructure, rather than routing every prompt, tool call, and reasoning artifact through third-party services.

OpenResponses-compatible runtimes for self-managed and hybrid environments are still limited. Red Hat AI provides one of the most mature implementations of the specification that targets that gap, making it a practical route for OpenClaw users who want to preserve OpenAI responses API-oriented agent behavior while moving execution to infrastructure they control.

For teams that want a self-hosted path without a Responses API orchestration layer, [vLLM](https://github.com/vllm-project/vllm), part of Red Hat AI, provides an OpenAI-compatible`/v1/chat/completions`endpoint that OpenClaw can consume directly.

### Agent lifecycle with Kagenti

Many teams get stuck moving an agent from laptop to production. [Kagenti](https://github.com/kagenti/kagenti), planned as part of OpenShift AI, bridges that gap. The [kagenti-operator](https://github.com/kagenti/kagenti-operator) auto-discovers agents via [A2A](https://google.github.io/A2A/)-based AgentCard CRDs and injects identity (SPIFFE/SPIRE), tracing, and tool governance (MCP Gateway) without changes to agent code via an AgentRuntime construct. The full lifecycle, from discovery to runtime governance, is managed by the platform. Agent catalog and registry are on the roadmap for the OpenShift AI UI, alongside an MCP catalog for tool servers

## This series

This blog series walks you through these layers in detail with OpenClaw as an example agent runtime. Each post is self-contained. Read them in order or jump to whatever matches your current problem.

The only constant across every post is the BYOA principle. We never ask you to rewrite your agent. We bring enterprise rigor to the agent, not the other way around.

For more information about the Red Hat AI product stack for building, evaluating, and enforcing safety for AI applications, check the [official product documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.2/) as well as the following upstream projects that are key to the Red Hat AI AgentOps story:

* [vLLM](https://github.com/vllm-project/vllm)
* [MCP Gateway](https://github.com/Kuadrant/mcp-gateway)
* [Open Responses](https://www.openresponses.org/)/[Llama Stack](https://github.com/llamastack/llama-stack)
* [Authorino](https://github.com/Kuadrant/authorino)
* [Garak](https://github.com/NVIDIA/garak)
* [TrustyAI Service Operator](https://github.com/trustyai-explainability/trustyai-service-operator)
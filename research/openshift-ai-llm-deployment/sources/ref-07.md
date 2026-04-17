# Source: ref-07

**URL:** https://www.redhat.com/en/blog/ai-scale-without-price-tag-why-enterprises-are-turning-models-service
**Fetched:** 2026-04-17 17:54:32

---

# AI at scale, without the price tag: Why enterprises are turning to Models-as-a-Service

June 10, 2025[Ishu Verma](/en/authors/ishu-verma "See more by Ishu Verma"), [Ritesh Shah](/en/authors/ritesh-shah "See more by Ritesh Shah"), [Juliano Mohr](/en/authors/juliano-mohr "See more by Juliano Mohr")*6*-minute read

[Artificial intelligence](/en/blog?f[0]=taxonomy_topic_tid:75501#rhdc-search-listing)

Share



Subscribe to RSS

As AI solutions accelerate across enterprises, it becomes increasingly expensive to use public models, which have the added risk of enterprise data potentially being exposed to third parties. The Models-as-a-Service (MaaS) approach enables enterprises to offer open source models (and the required AI technology stack) that can be used as a shared resource by the entire company.

Additionally, as an enterprise's AI adoption accelerates, there’s often a lack of consistency as each business group strives to build their own bespoke AI solutions covering a wide range of use cases (Chatbot, code assistant, text/image generation, etc.).

[Models-as-a-Service explained](/en/topics/ai/what-is-models-as-a-service)

IDC’s insights on AI adoption trends describes how enterprises transition from opportunistic to managed solutions that can transform the entire organization.

Each business group often requires different types of AI models to address their specific use cases. Here are a few examples:

* **Generative AI (gen AI) models:** Used to create new content, such as text or images
* **Predictive AI models:** Used to classify or predict patterns in data
* **Fine-tuned AI models:** These are models customized with company or domain-specific data
* **Retrieval-augmented generation (RAG):** This enhances generic model information with company or domain-specific data

Gen AI models that can be accessed through third-party hosted services, like OpenAI, Claude and Gemini, are easy to get started with but become very expensive when used at scale. There are also data privacy and security issues as the enterprise data may be exposed to these other parties. Gen AI and other models can also be self-hosted by the enterprise, but this can lead to a duplication of effort across various business groups resulting in increased costs and time to market.

With new gen AI models being released every other week and the speed of AI advancements, it’s becoming nearly impossible for enterprises to keep up. There are dozens of options for models, from very large size (450B parameters) to smaller versions of these models (quantized or fewer parameters) to a mixture of expert models. Many developers lack the expertise needed to choose the right model or to make optimal use of expensive resources (e.g. GPUs).

With each business group building their own AI solutions, enterprises face several challenges:

* **High costs:** Deploying and maintaining AI models requires expensive GPU clusters, machine learning (ML) expertise and ongoing fine-tuning. Training and fine-tuning models in-house can cost millions in compute, storage and talent. Additionally, the model costs can become unpredictable without centralized governance.
* **Duplication:** Duplication or underutilization of scarce AI resources can lead to wasted budgets.
* **Complexity:** Developers just want access to the model and don’t want to deal with infrastructure complexity or continually evolving AI stack.
* **Skill shortage:** Enterprises lack the ML engineers, data scientists and AI researchers that are needed to build custom models.
* **Operational control:** As multiple groups work on their own independent AI efforts, enterprises struggle with scaling, version control and model drift.

There needs to be a better approach for enterprises to take advantage of AI momentum without breaking the bank.

## MaaS to the rescue

MaaS enables enterprises to offer open source models (and the required AI stack) that can be used as  a shared resource. In effect, enterprise IT becomes the service provider of AI services that can be consumed by the entire company.

Users can choose from state-of-the-art frontier models to quantized or small language models (SLMs) that are orders of magnitude smaller but provide similar performance at a fraction of the cost. The models can be tuned and customized with private enterprise data and can run on less powerful hardware, consuming less energy. There can be multiple instances of models to address different use cases and deployment environments. All of these models are served efficiently to make most of the available hardware resources.

The models can be easily accessed by developers who can now focus on building AI apps and don’t have to be concerned with the underlying infrastructure complexities (e.g. GPUs).

Enterprise IT can monitor model usage by various business groups and charge back for their consumption of AI services. IT can also apply AI management best practices to streamline model deployment and maintenance (e.g. versioning, regression testing).

Here are some of the advantages of IT becoming the private AI provider for the enterprise:

* **Reduced complexity:** Centralized MaaS helps eliminate AI infrastructure complexity for users
* **Lower costs:** Helps reduce costs by centrally serving model inference services
* **Increased security:** Compliance with existing security, data and privacy policies by not using third-party hosted models
* **Faster innovation:** Faster model deployment and innovation around it result in faster time to market for AI applications
* **Non-duplication:** Avoids duplication of scarce AI resources across various groups—data scientists can provide optimized models needed for common enterprise tasks
* **Freedom of choice:** Eliminates vendor lock-in while keeping AI workloads portable

## Looking under the MaaS hood

This MaaS solution stack consists of [Red Hat OpenShift AI](/en/products/ai/openshift-ai), API Gateway (part of [Red Hat 3scale API Management](/en/technologies/jboss-middleware/3scale)) and Red Hat single sign-on (SSO). It delivers end-to-end AI governance, zero-trust access ([Red Hat build of Keycloak](https://access.redhat.com/products/red-hat-build-of-keycloak)), an AI Inference server ([vLLM](/en/topics/ai/what-is-vllm)) and hybrid cloud flexibility (OpenShift AI) on a single platform. It also uses consistent tooling to deploy the solution on-prem and to the cloud with [Red Hat OpenShift](/en/technologies/cloud-computing/openshift).

Let’s look at each of these components in more detail.

### API Gateway

API Gateway provides enterprise-grade model API control. This solution stack is based on 3Scale API Gateway, but any enterprise grade API Gateway can be used instead. Here are some of the benefits of this API Gateway:

* **Security and compliance**
  + Enforce API authentication via JWT/OAuth2 for LLM access
  + Encrypt all API traffic to/from LLM services
  + Audit logs for compliance (GDPR, HIPAA, SOC2)
* **Usage optimization**
  + Set rate limits and quotas to prevent cost overruns
  + Monitor LLM API consumption by team/project
  + Identify unused or overused endpoints
* **Hybrid deployment support**
  + Manage APIs consistently across cloud/on-prem (via OpenShift integration)
  + Deploy dedicated API gateways for private LLM instances
* **Developer enablement**
  + Self-service developer portal for LLM API discovery
  + Automated API documentation and testing
* **OpenShift AI integration**
  + Enforce governance for models deployed on OpenShift AI
  + Track AI/ML API usage alongside traditional services

### Authentication

The authentication component provides unified identity management for LLM services. This solution stack is based on Red Hat SSO but any other enterprise grade authentication solution can be used instead. Here are some of the benefits of authentication:

* Zero-trust security
  + Centralized authentication for all LLM tools (OIDC/SAML)
  + Role-based access control (RBAC) for fine-grained permissions
  + Multifactor authentication (MFA) support for sensitive AI workloads
* Enterprise identity integration
  + Connect to Active Directory, LDAP or other identity providers
  + Automate user provisioning/deprovisioning
* Scalable access management
  + Single sign-on for all internal AI portals
  + Session management for compliance
* Hybrid cloud-ready
  + Secure access to LLMs running anywhere (public cloud/on-prem)
  + Consistent policies across environments

OpenShift AI integration

* SSO for OpenShift AI dashboards and model endpoints
* Unified identity for both platform users and API consumers

### Inference server

This solution stack uses [vLLM](/en/topics/ai/what-is-vllm) as the inference server. The vLLM framework supports multimodal models, embeddings and reward modeling, and is increasingly used in reinforcement learning with human feedback (RLHF) workflows. With features such as advanced scheduling, chunk prefill, Multi-LoRA batching and structured outputs, vLLM is optimized for both inference acceleration and enterprise-scale deployment.

vLLM also provides LLM compression tools so customers can optimize their own tuned models.

### AI platform

This solution stack uses OpenShift AI to serve models and deliver innovative applications. OpenShift AI helps enterprises with all aspects of AI, including data acquisition and preparation, model training and fine-tuning, model serving and model monitoring and hardware acceleration.

The [latest release of OpenShift AI](/en/about/press-releases/red-hat-boosts-enterprise-ai-across-hybrid-cloud-red-hat-ai) is designed to increase efficiency by providing access to smaller, pre-optimized models. Additionally, it helps manage inferencing costs with distributed serving through a vLLM framework.

OpenShift AI is offered as either self-managed software or as a fully managed cloud service on top of OpenShift and provides a secure and flexible platform that gives you the choice of where you develop and deploy your models–whether on-premise, in the public cloud or even at the edge.
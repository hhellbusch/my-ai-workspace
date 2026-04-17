# Source: ref-48

**URL:** https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/working_with_llama_stack/overview-of-llama-stack_rag
**Fetched:** 2026-04-17 17:54:53

---

1. [Home](/)
2. [Products](/en/products)
3. [Red Hat OpenShift AI Self-Managed](/en/documentation/red_hat_openshift_ai_self-managed/)
4. [2.25](/en/documentation/red_hat_openshift_ai_self-managed/2.25/)
5. [Working with Llama Stack](/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/working_with_llama_stack/)
6. Chapter 1. Overview of Llama Stack

# Chapter 1. Overview of Llama Stack

---

Llama Stack is a unified AI runtime environment designed to simplify the deployment and management of generative AI workloads on OpenShift AI. Llama Stack integrates LLM inference servers, vector databases, and retrieval services in a single stack, optimized for Retrieval-Augmented Generation (RAG) and agent-based AI workflows. In OpenShift, the Llama Stack Operator manages the deployment lifecycle of these components, ensuring scalability, consistency, and integration with OpenShift AI projects.

Important

Llama Stack integration is currently available in Red Hat OpenShift AI 2.25 as a Technology Preview feature. Technology Preview features are not supported with Red Hat production service level agreements (SLAs) and might not be functionally complete. Red Hat does not recommend using them in production. These features provide early access to upcoming product features, enabling customers to test functionality and provide feedback during the development process.

For more information about the support scope of Red Hat Technology Preview features, see [Technology Preview Features Support Scope](https://access.redhat.com/support/offerings/techpreview/).

Llama Stack includes the following components:

* **Inference model servers** such as vLLM, designed to efficiently serve large language models.
* **Vector storage** solutions, primarily Milvus, to store embeddings generated from your domain data.
* **Retrieval and embedding management** workflows using integrated tools, such as Docling, to handle continuous data ingestion and synchronization.
* **Integration with OpenShift AI** by using the `LlamaStackDistribution` custom resource, simplifying configuration and deployment.

For information about how to deploy Llama Stack in OpenShift AI, see [Deploying a RAG stack in a data science project](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/working_with_llama_stack/deploying-a-rag-stack-in-a-data-science-project_rag).

## [1.1. The LlamaStackDistribution custom resource API providers](#the_llamastackdistribution_custom_resource_api_providers) Copy linkLink copied to clipboard!

The `LlamaStackDistribution` custom resource includes various API types and providers that you can use in OpenShift AI. The following table displays the supported providers that are included in the distribution:

Expand

| **API type** | **Providers** | **How to Enable** | **Support status** |
| --- | --- | --- | --- |
| Agents | `inline::meta-reference` | Enabled by default | Technology Preview |
| DatasetIO | `inline::localfs` | Enabled by default | Technology Preview |
| `remote::huggingface` | Enabled by default | Technology Preview |
| Evaluation | `remote::trustyai_lmeval` | Set the `EMBEDDING_MODEL` environment variable | Technology Preview |
| Files | `inline::localfs` | Enabled by default | Technology Preview |
| Inference | `inline::sentence-transformers` | Enabled by default | Technology Preview |
| `remote::vllm` | Set the `VLLM_URL` environment variable | Technology Preview |
| `remote::azure` | Set the `AZURE_API_KEY` environment variable | Technology Preview |
| `remote::bedrock` | Set the `AWS_ACCESS_KEY_ID` environment variable | Technology Preview |
| `remote::openai` | Set the `OPENAI_API_KEY` environment variable | Technology Preview |
| `remote::vertexai` | Set the `VERTEX_AI_PROJECT` environment variable | Technology Preview |
| `remote::watsonx` | Set the `WATSONX_API_KEY` environment variable | Technology Preview |
| Safety | `remote::trustyai_fms` | Enabled by default | Technology Preview |
| Scoring | `inline::llm-as-a-judge` | Enabled by default | Technology Preview |
| `inline::basic` | Enabled by default | Technology Preview |
| `inline::braintrust` | Enabled by default | Technology Preview |
| Telemetry | `inline::meta-reference` | Enabled by default | Technology Preview |
| Tool\_runtime | `inline::rag-runtime` | Enabled by default | Technology Preview |
| `remote::brave-search` | Enabled by default | Technology Preview |
| `remote::tavily-search` | Enabled by default | Technology Preview |
| `remote::model-context-protocol` | Enabled by default | Technology Preview |
| VectorIO | `inline::milvus` | Enabled by default | Technology Preview |
| `remote::milvus` | Set the `MILVUS_ENDPOINT` environment variable | Technology Preview |

Show more

## [1.2. OpenAI compatibility for RAG APIs in Llama Stack](#openai-compatibility-for-rag-apis-in-llama-stack_rag) Copy linkLink copied to clipboard!

OpenShift AI supports OpenAI-compatible request and response schemas for Llama Stack RAG workflows. You can use OpenAI clients and schemas for files, vector stores, and Responses API file search end-to-end.

OpenAI compatibility enables the following capabilities:

* You can use OpenAI SDKs and tools with Llama Stack by setting the client `base_url` to the Llama Stack OpenAI path, `/v1/openai/v1`.
* You can manage files and vector stores by using OpenAI-compatible endpoints. You can then invoke RAG workflows by using the Responses API with the `file_search` tool.

## [1.3. OpenAI-compatible APIs in Llama Stack](#openai-compatible-apis-in-Llama-Stack_rag) Copy linkLink copied to clipboard!

OpenShift AI includes a Llama Stack component that exposes OpenAI-compatible APIs. These APIs enable you to reuse existing OpenAI SDKs, tools, and workflows directly within your OpenShift environment, without changing your client code. This compatibility layer supports retrieval-augmented generation (RAG), inference, and embedding workloads by using the same endpoints, schemas, and authentication model as OpenAI.

This compatibility layer has the following capabilities:

* **Standardized endpoints**: REST API paths align with OpenAI specifications.
* **Schema parity:** Request and response fields follow OpenAI data structures.

Note

When connecting OpenAI SDKs or third-party tools to OpenShift AI, you must update the client configuration to use your deployment’s Llama Stack route as the `base_url`. This ensures that API calls are sent to the OpenAI-compatible endpoints that run inside your OpenShift cluster, rather than to the public OpenAI service.

### [1.3.1. Supported OpenAI-compatible APIs in OpenShift AI](#supported_openai_compatible_apis_in_openshift_ai) Copy linkLink copied to clipboard!

#### [1.3.1.1. Chat Completions API](#chat_completions_api) Copy linkLink copied to clipboard!

* **Endpoint:** `/v1/openai/v1/chat/completions`.
* **Providers:** All inference back ends deployed through OpenShift AI.
* **Support level:** Technology Preview.

The Chat Completions API enables conversational, message-based interactions with models served by Llama Stack in OpenShift AI.

#### [1.3.1.2. Completions API](#completions_api) Copy linkLink copied to clipboard!

* **Endpoint:** `/v1/openai/v1/completions`.
* **Providers:** All inference backends managed by OpenShift AI.
* **Support level:** Technology Preview.

The Completions API supports single-turn text generation and prompt completion.

#### [1.3.1.3. Embeddings API](#embeddings_api) Copy linkLink copied to clipboard!

* **Endpoint:** `/v1/openai/v1/embeddings`.
* **Providers:** All embedding models enabled in OpenShift AI.

The Embeddings API generates numerical embeddings for text or documents that can be used in downstream semantic search or RAG applications.

#### [1.3.1.4. Files API](#files_api) Copy linkLink copied to clipboard!

* **Endpoint:** `/v1/openai/v1/files`.
* **Providers:** File system-based file storage provider for managing files and documents stored locally in your cluster.
* **Support level:** Technology Preview.

The Files API manages file uploads for use in embedding and retrieval workflows.

#### [1.3.1.5. Vector Stores API](#vector_stores_api) Copy linkLink copied to clipboard!

* **Endpoint:** `/v1/openai/v1/vector_stores/`.
* **Providers:** Inline and Remote Milvus configured in OpenShift AI.
* **Support level:** Technology Preview.

The Vector Stores API manages the creation, configuration, and lifecycle of vector store resources in Llama Stack. Through this API, you can create new vector stores, list existing ones, delete unused stores, and query their metadata, all using OpenAI-compatible request and response formats.

#### [1.3.1.6. Vector Store Files API](#vector_store_files_api) Copy linkLink copied to clipboard!

* **Endpoint:** `/v1/openai/v1/vector_stores/{vector_store_id}/files`.
* **Providers:** Local inline provider configured for file storage and retrieval.
* **Support level:** Developer Preview.

The Vector Store Files API implements the OpenAI Vector Store Files interface and manages the link between document files and Milvus vector stores used for RAG.

#### [1.3.1.7. Models API](#models_api) Copy linkLink copied to clipboard!

* **Endpoint:** `/v1/openai/v1/models`.
* **Providers:** All model-serving back ends configured within OpenShift AI.
* **Support level:** Technology Preview.

The Models API lists and retrieves available model resources from the Llama Stack deployment running on OpenShift AI. By using the Models API, you can enumerate models, view their capabilities, and verify deployment status through a standardized OpenAI-compatible interface.

#### [1.3.1.8. Responses API](#responses_api) Copy linkLink copied to clipboard!

* **Endpoint:** `/v1/openai/v1/responses`.
* **Providers:** All inference and retrieval providers configured in OpenShift AI.
* **Support level:** Developer Preview.

The Responses API generates model outputs by combining inference, file search, and tool-calling capabilities through a single OpenAI-compatible endpoint. It is particularly useful for retrieval-augmented generation (RAG) workflows that rely on the `file_search` tool to retrieve context from vector stores.

Note

The Responses API is an experimental feature that is still under active development in OpenShift AI. While the API is already functional and suitable for evaluation, some endpoints and parameters remain under implementation and might change in future releases. This API is provided for testing and feedback purposes only and is not recommended for production use.
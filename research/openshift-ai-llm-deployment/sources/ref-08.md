# Source: ref-08

**URL:** https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models
**Fetched:** 2026-04-17 17:54:29

---

1. [Home](/)
2. [Products](/en/products)
3. [Red Hat OpenShift AI Self-Managed](/en/documentation/red_hat_openshift_ai_self-managed/)
4. [2.16](/en/documentation/red_hat_openshift_ai_self-managed/2.16/)
5. [Serving models](/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/)
6. Chapter 3. Serving large models

# Chapter 3. Serving large models

---

For deploying large models such as large language models (LLMs), Red Hat OpenShift AI includes a *single model serving platform* that is based on the KServe component. Because each model is deployed from its own model server, the single model serving platform helps you to deploy, monitor, scale, and maintain large models that require increased resources.

## [3.1. About the single-model serving platform](#about-the-single-model-serving-platform_serving-large-models) Copy linkLink copied to clipboard!

For deploying large models such as large language models (LLMs), OpenShift AI includes a single-model serving platform that is based on the [KServe](https://github.com/kserve/kserve) component. Because each model is deployed on its own model server, the single-model serving platform helps you to deploy, monitor, scale, and maintain large models that require increased resources.

## [3.2. Components](#components) Copy linkLink copied to clipboard!

* [KServe](https://github.com/opendatahub-io/kserve): A Kubernetes custom resource definition (CRD) that orchestrates model serving for all types of models. KServe includes model-serving runtimes that implement the loading of given types of model servers. KServe also handles the lifecycle of the deployment object, storage access, and networking setup.
* [Red Hat OpenShift Serverless](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/serverless/about-serverless): A cloud-native development model that allows for serverless deployments of models. OpenShift Serverless is based on the open source [Knative](https://knative.dev/docs/) project.
* [Red Hat OpenShift Service Mesh](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/service_mesh/service-mesh-2-x#ossm-understanding-service-mesh_ossm-architecture): A service mesh networking layer that manages traffic flows and enforces access policies. OpenShift Service Mesh is based on the open source [Istio](https://istio.io/) project.

## [3.3. Installation options](#installation-options) Copy linkLink copied to clipboard!

To install the single-model serving platform, you have the following options:

Automated installation
:   If you have not already created a `ServiceMeshControlPlane` or `KNativeServing` resource on your OpenShift cluster, you can configure the Red Hat OpenShift AI Operator to install KServe and configure its dependencies.

    For more information about automated installation, see [Configuring automated installation of KServe](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed/installing-the-single-model-serving-platform_component-install#configuring-automated-installation-of-kserve_component-install).

Manual installation
:   If you have already created a `ServiceMeshControlPlane` or `KNativeServing` resource on your OpenShift cluster, you *cannot* configure the Red Hat OpenShift AI Operator to install KServe and configure its dependencies. In this situation, you must install KServe manually.

    For more information about manual installation, see [Manually installing KServe](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed/installing-the-single-model-serving-platform_component-install#manually-installing-kserve_component-install).

## [3.4. Authorization](#authorization) Copy linkLink copied to clipboard!

You can add [Authorino](https://github.com/kuadrant/authorino) as an authorization provider for the single-model serving platform. Adding an authorization provider allows you to enable token authorization for models that you deploy on the platform, which ensures that only authorized parties can make inference requests to the models.

To add Authorino as an authorization provider on the single-model serving platform, you have the following options:

* If automated installation of the single-model serving platform is possible on your cluster, you can include Authorino as part of the automated installation process.
* If you need to manually install the single-model serving platform, you must also manually configure Authorino.

For guidance on choosing an installation option for the single-model serving platform, see [Installation options](serving-large-models_serving-large-models#installation-options "3.3. Installation options").

## [3.5. Monitoring](#monitoring) Copy linkLink copied to clipboard!

You can configure monitoring for the single-model serving platform and use Prometheus to scrape metrics for each of the pre-installed model-serving runtimes.

## [3.6. Model-serving runtimes](#model-serving-runtimes_serving-large-models) Copy linkLink copied to clipboard!

You can serve models on the single-model serving platform by using model-serving runtimes. The configuration of a model-serving runtime is defined by the **ServingRuntime** and **InferenceService** custom resource definitions (CRDs).

### [3.6.1. ServingRuntime](#servingruntime) Copy linkLink copied to clipboard!

The **ServingRuntime** CRD creates a serving runtime, an environment for deploying and managing a model. It creates the templates for pods that dynamically load and unload models of various formats and also exposes a service endpoint for inferencing requests.

The following YAML configuration is an example of the **vLLM ServingRuntime for KServe** model-serving runtime. The configuration includes various flags, environment variables and command-line arguments.

```
apiVersion: serving.kserve.io/v1alpha1
kind: ServingRuntime
metadata:
  annotations:
    opendatahub.io/recommended-accelerators: '["nvidia.com/gpu"]'
```

1

```
    openshift.io/display-name: vLLM ServingRuntime for KServe
```

2

```
  labels:
    opendatahub.io/dashboard: "true"
  name: vllm-runtime
spec:
     annotations:
          prometheus.io/path: /metrics
```

3

```
          prometheus.io/port: "8080"
```

4

```
     containers :
          - args:
               - --port=8080
               - --model=/mnt/models
```

5

```
               - --served-model-name={{.Name}}
```

6

```
             command:
```

7

```
                  - python
                  - '-m'
                  - vllm.entrypoints.openai.api_server
             env:
                  - name: HF_HOME
                     value: /tmp/hf_home
             image:
```

8

```
quay.io/modh/vllm@sha256:8a3dd8ad6e15fe7b8e5e471037519719d4d8ad3db9d69389f2beded36a6f5b21
          name: kserve-container
          ports:
               - containerPort: 8080
                   protocol: TCP
    multiModel: false
```

9

```
    supportedModelFormats:
```

10

```
        - autoSelect: true
           name: vLLM
```

[1](#CO1-1)
:   The recommended accelerator to use with the runtime.

[2](#CO1-2)
:   The name with which the serving runtime is displayed.

[3](#CO1-3)
:   The endpoint used by Prometheus to scrape metrics for monitoring.

[4](#CO1-4)
:   The port used by Prometheus to scrape metrics for monitoring.

[5](#CO1-5)
:   The path to where the model files are stored in the runtime container.

[6](#CO1-6)
:   Passes the model name that is specified by the `{{.Name}}` template variable inside the runtime container specification to the runtime environment. The `{{.Name}}` variable maps to the `spec.predictor.name` field in the `InferenceService` metadata object.

[7](#CO1-7)
:   The entrypoint command that starts the runtime container.

[8](#CO1-8)
:   The runtime container image used by the serving runtime. This image differs depending on the type of accelerator used.

[9](#CO1-9)
:   Specifies that the runtime is used for single-model serving.

[10](#CO1-10)
:   Specifies the model formats supported by the runtime.

### [3.6.2. InferenceService](#inferenceservice) Copy linkLink copied to clipboard!

The **InferenceService** CRD creates a server or inference service that processes inference queries, passes it to the model, and then returns the inference output.

The inference service also performs the following actions:

* Specifies the location and format of the model.
* Specifies the serving runtime used to serve the model.
* Enables the passthrough route for gRPC or REST inference.
* Defines HTTP or gRPC endpoints for the deployed model.

The following example shows the InferenceService YAML configuration file that is generated when deploying a granite model with the vLLM runtime:

```
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  annotations:
    openshift.io/display-name: granite
    serving.knative.openshift.io/enablePassthrough: 'true'
    sidecar.istio.io/inject: 'true'
    sidecar.istio.io/rewriteAppHTTPProbers: 'true'
  name: granite
  labels:
    opendatahub.io/dashboard: 'true'
spec:
  predictor:
    maxReplicas: 1
    minReplicas: 1
    model:
      modelFormat:
        name: vLLM
      name: ''
      resources:
        limits:
          cpu: '6'
          memory: 24Gi
          nvidia.com/gpu: '1'
        requests:
          cpu: '1'
          memory: 8Gi
          nvidia.com/gpu: '1'
      runtime: vLLM ServingRuntime for KServe
      storage:
        key: aws-connection-my-storage
        path: models/granite-7b-instruct/
    tolerations:
      - effect: NoSchedule
        key: nvidia.com/gpu
        operator: Exists
```

## [3.7. Supported model-serving runtimes](#supported-model-serving-runtimes_serving-large-models) Copy linkLink copied to clipboard!

OpenShift AI includes several preinstalled model-serving runtimes. You can use preinstalled model-serving runtimes to start serving models without modifying or defining the runtime yourself. You can also add a custom runtime to support a model.

For help adding a custom runtime, see [Adding a custom model-serving runtime for the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#adding-a-custom-model-serving-runtime-for-the-single-model-serving-platform_serving-large-models).

Expand

Table 3.1. Model-serving runtimes

| Name | Description | Exported model format |
| --- | --- | --- |
| Caikit Text Generation Inference Server (Caikit-TGIS) ServingRuntime for KServe (1) | A composite runtime for serving models in the Caikit format | Caikit Text Generation |
| Caikit Standalone ServingRuntime for KServe (2) | A runtime for serving models in the Caikit embeddings format for embeddings tasks | Caikit Embeddings |
| OpenVINO Model Server | A scalable, high-performance runtime for serving models that are optimized for Intel architectures | PyTorch, TensorFlow, OpenVINO IR, PaddlePaddle, MXNet, Caffe, Kaldi |
| Text Generation Inference Server (TGIS) Standalone ServingRuntime for KServe (3) | A runtime for serving TGI-enabled models | PyTorch Model Formats |
| vLLM ServingRuntime for KServe | A high-throughput and memory-efficient inference and serving runtime for large language models | [Supported models](https://docs.vllm.ai/en/latest/models/supported_models.html) |
| vLLM ServingRuntime with Gaudi accelerators support for KServe | A high-throughput and memory-efficient inference and serving runtime that supports Intel Gaudi accelerators | [Supported models](https://docs.vllm.ai/en/latest/models/supported_models.html) |
| vLLM ROCm ServingRuntime for KServe | A high-throughput and memory-efficient inference and serving runtime that supports AMD GPU accelerators | [Supported models](https://docs.vllm.ai/en/latest/models/supported_models.html) |

Show more

1. The composite Caikit-TGIS runtime is based on [Caikit](https://github.com/opendatahub-io/caikit) and [Text Generation Inference Server (TGIS)](https://github.com/IBM/text-generation-inference). To use this runtime, you must convert your models to Caikit format. For an example, see [Converting Hugging Face Hub models to Caikit format](https://github.com/opendatahub-io/caikit-tgis-serving/blob/main/demo/kserve/built-tip.md#bootstrap-process) in the [caikit-tgis-serving](https://github.com/opendatahub-io/caikit-tgis-serving/tree/main) repository.
2. The Caikit Standalone runtime is based on [Caikit NLP](https://github.com/caikit/caikit-nlp/tree/main). To use this runtime, you must convert your models to the Caikit embeddings format. For an example, see [Tests for text embedding module](https://github.com/caikit/caikit-nlp/blob/main/tests/modules/text_embedding/test_embedding.py).
3. [Text Generation Inference Server (TGIS)](https://github.com/IBM/text-generation-inference) is based on an early fork of [Hugging Face TGI](https://github.com/huggingface/text-generation-inference). Red Hat will continue to develop the standalone TGIS runtime to support TGI models. If a model is incompatible in the current version of OpenShift AI, support might be added in a future version. In the meantime, you can also add your own custom runtime to support a TGI model. For more information, see [Adding a custom model-serving runtime for the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#adding-a-custom-model-serving-runtime-for-the-single-model-serving-platform_serving-large-models).

Expand

Table 3.2. Deployment requirements

| Name | Default protocol | Additonal protocol | Model mesh support | Single node OpenShift support | Deployment mode |
| --- | --- | --- | --- | --- | --- |
| Caikit Text Generation Inference Server (Caikit-TGIS) ServingRuntime for KServe | REST | gRPC | No | Yes | Raw and serverless |
| Caikit Standalone ServingRuntime for KServe | REST | gRPC | No | Yes | Raw and serverless |
| OpenVINO Model Server | REST | None | Yes | Yes | Raw and serverless |
| Text Generation Inference Server (TGIS) Standalone ServingRuntime for KServe | gRPC | None | No | Yes | Raw and serverless |
| vLLM ServingRuntime for KServe | REST | None | No | Yes | Raw and serverless |
| vLLM ServingRuntime with Gaudi accelerators support for KServe | REST | None | No | Yes | Raw and serverless |
| vLLM ROCm ServingRuntime for KServe | REST | None | No | Yes | Raw and serverless |

Show more

## [3.8. Tested and verified model-serving runtimes](#tested-verified-runtimes_serving-large-models) Copy linkLink copied to clipboard!

Tested and verified runtimes are community versions of model-serving runtimes that have been tested and verified against specific versions of OpenShift AI.

Red Hat tests the current version of a tested and verified runtime each time there is a new version of OpenShift AI. If a new version of a tested and verified runtime is released in the middle of an OpenShift AI release cycle, it will be tested and verified in an upcoming release.

A list of the tested and verified runtimes and compatible versions is available in the [OpenShift AI release notes](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html-single/release_notes).

Note

Tested and verified runtimes are not directly supported by Red Hat. You are responsible for ensuring that you are licensed to use any tested and verified runtimes that you add, and for correctly configuring and maintaining them.

For more information, see [Tested and verified runtimes in OpenShift AI](https://access.redhat.com/articles/7089743).

Expand

Table 3.3. Model-serving runtimes

| Name | Description | Exported model format |
| --- | --- | --- |
| NVIDIA Triton Inference Server | An open-source inference-serving software for fast and scalable AI in applications. | TensorRT, TensorFlow, PyTorch, ONNX, OpenVINO, Python, RAPIDS FIL, and more |

Show more

Expand

Table 3.4. Deployment requirements

| Name | Default protocol | Additonal protocol | Model mesh support | Single node OpenShift support | Deployment mode |
| --- | --- | --- | --- | --- | --- |
| NVIDIA Triton Inference Server | gRPC | REST | Yes | Yes | Raw and serverless |

Show more

## [3.9. Inference endpoints](#inference-endpoints_serving-large-models) Copy linkLink copied to clipboard!

These examples show how to use inference endpoints to query the model.

Note

If you enabled token authorization when deploying the model, add the `Authorization` header and specify a token value.

### [3.9.1. Caikit TGIS ServingRuntime for KServe](#caikit_tgis_servingruntime_for_kserve) Copy linkLink copied to clipboard!

* `:443/api/v1/task/text-generation`
* `:443/api/v1/task/server-streaming-text-generation`

**Example command**

```
curl --json '{"model_id": "<model_name__>", "inputs": "<text>"}' https://<inference_endpoint_url>:443/api/v1/task/server-streaming-text-generation -H 'Authorization: Bearer <token>'
```

### [3.9.2. Caikit Standalone ServingRuntime for KServe](#caikit_standalone_servingruntime_for_kserve) Copy linkLink copied to clipboard!

If you are serving multiple models, you can query `/info/models` or `:443 caikit.runtime.info.InfoService/GetModelsInfo` to view a list of served models.

**REST endpoints**

* `/api/v1/task/embedding`
* `/api/v1/task/embedding-tasks`
* `/api/v1/task/sentence-similarity`
* `/api/v1/task/sentence-similarity-tasks`
* `/api/v1/task/rerank`
* `/api/v1/task/rerank-tasks`
* `/info/models`
* `/info/version`
* `/info/runtime`

**gRPC endpoints**

* `:443 caikit.runtime.Nlp.NlpService/EmbeddingTaskPredict`
* `:443 caikit.runtime.Nlp.NlpService/EmbeddingTasksPredict`
* `:443 caikit.runtime.Nlp.NlpService/SentenceSimilarityTaskPredict`
* `:443 caikit.runtime.Nlp.NlpService/SentenceSimilarityTasksPredict`
* `:443 caikit.runtime.Nlp.NlpService/RerankTaskPredict`
* `:443 caikit.runtime.Nlp.NlpService/RerankTasksPredict`
* `:443 caikit.runtime.info.InfoService/GetModelsInfo`
* `:443 caikit.runtime.info.InfoService/GetRuntimeInfo`

Note

By default, the Caikit Standalone Runtime exposes REST endpoints. To use gRPC protocol, manually deploy a custom Caikit Standalone ServingRuntime. For more information, see [Adding a custom model-serving runtime for the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#adding-a-custom-model-serving-runtime-for-the-single-model-serving-platform_serving-large-models).

An example manifest is available in the [caikit-tgis-serving GitHub repository](https://github.com/opendatahub-io/caikit-tgis-serving/blob/main/demo/kserve/custom-manifests/caikit/caikit-standalone/caikit-standalone-servingruntime-grpc.yaml).

**REST**

```
curl -H 'Content-Type: application/json' -d '{"inputs": "<text>", "model_id": "<model_id>"}' <inference_endpoint_url>/api/v1/task/embedding -H 'Authorization: Bearer <token>'
```

**gRPC**

```
grpcurl -d '{"text": "<text>"}' -H \"mm-model-id: <model_id>\" <inference_endpoint_url>:443 caikit.runtime.Nlp.NlpService/EmbeddingTaskPredict -H 'Authorization: Bearer <token>'
```

### [3.9.3. TGIS Standalone ServingRuntime for KServe](#tgis_standalone_servingruntime_for_kserve) Copy linkLink copied to clipboard!

* `:443 fmaas.GenerationService/Generate`
* `:443 fmaas.GenerationService/GenerateStream`

  Note

  To query the endpoint for the TGIS standalone runtime, you must also download the files in the [proto](https://github.com/opendatahub-io/text-generation-inference/blob/main/proto) directory of the OpenShift AI `text-generation-inference` repository.

**Example command**

```
grpcurl -proto text-generation-inference/proto/generation.proto -d '{"requests": [{"text":"<text>"}]}' -H 'Authorization: Bearer <token>' -insecure <inference_endpoint_url>:443 fmaas.GenerationService/Generate
```

### [3.9.4. OpenVINO Model Server](#openvino_model_server) Copy linkLink copied to clipboard!

* `/v2/models/<model-name>/infer`

**Example command**

```
curl -ks <inference_endpoint_url>/v2/models/<model_name>/infer -d '{ "model_name": "<model_name>", "inputs": [{ "name": "<name_of_model_input>", "shape": [<shape>], "datatype": "<data_type>", "data": [<data>] }]}' -H 'Authorization: Bearer <token>'
```

### [3.9.5. vLLM ServingRuntime for KServe](#vllm_servingruntime_for_kserve) Copy linkLink copied to clipboard!

* `:443/version`
* `:443/docs`
* `:443/v1/models`
* `:443/v1/chat/completions`
* `:443/v1/completions`
* `:443/v1/embeddings`
* `:443/tokenize`
* `:443/detokenize`

  Note

  + The vLLM runtime is compatible with the OpenAI REST API. For a list of models that the vLLM runtime supports, see [Supported models](https://docs.vllm.ai/en/latest/models/supported_models.html).
  + To use the embeddings inference endpoint in vLLM, you must use an embeddings model that the vLLM supports. You cannot use the embeddings endpoint with generative models. For more information, see [Supported embeddings models in vLLM](https://github.com/vllm-project/vllm/pull/3734).
  + As of vLLM v0.5.5, you must provide a chat template while querying a model using the `/v1/chat/completions` endpoint. If your model does not include a predefined chat template, you can use the `chat-template` command-line parameter to specify a chat template in your custom vLLM runtime, as shown in the example. Replace `<CHAT_TEMPLATE>` with the path to your template.

    ```
    containers:
      - args:
          - --chat-template=<CHAT_TEMPLATE>
    ```

    You can use the chat templates that are available as `.jinja` files [here](https://github.com/opendatahub-io/vllm/tree/main/examples) or with the vLLM image under `/apps/data/template`. For more information, see [Chat templates](https://huggingface.co/docs/transformers/main/chat_templating).

  As indicated by the paths shown, the single-model serving platform uses the HTTPS port of your OpenShift router (usually port 443) to serve external API requests.

**Example command**

```
curl -v https://<inference_endpoint_url>:443/v1/chat/completions -H "Content-Type: application/json" -d '{ "messages": [{ "role": "<role>", "content": "<content>" }] -H 'Authorization: Bearer <token>'
```

### [3.9.6. vLLM ServingRuntime with Gaudi accelerators support for KServe](#vllm_servingruntime_with_gaudi_accelerators_support_for_kserve) Copy linkLink copied to clipboard!

See [vLLM ServingRuntime for KServe](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#vllm_servingruntime_for_kserve).

### [3.9.7. vLLM ROCm ServingRuntime for KServe](#vllm_rocm_servingruntime_for_kserve) Copy linkLink copied to clipboard!

See [vLLM ServingRuntime for KServe](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#vllm_servingruntime_for_kserve).

### [3.9.8. NVIDIA Triton Inference Server](#nvidia_triton_inference_server) Copy linkLink copied to clipboard!

**REST endpoints**

* `v2/models/[/versions/<model_version>]/infer`
* `v2/models/<model_name>[/versions/<model_version>]`
* `v2/health/ready`
* `v2/health/live`
* `v2/models/<model_name>[/versions/]/ready`
* `v2`

Note

ModelMesh does not support the following REST endpoints:

* `v2/health/live`
* `v2/health/ready`
* `v2/models/<model_name>[/versions/]/ready`

**Example command**

```
curl -ks <inference_endpoint_url>/v2/models/<model_name>/infer -d '{ "model_name": "<model_name>", "inputs": [{ "name": "<name_of_model_input>", "shape": [<shape>], "datatype": "<data_type>", "data": [<data>] }]}' -H 'Authorization: Bearer <token>'
```

**gRPC endpoints**

* `:443 inference.GRPCInferenceService/ModelInfer`
* `:443 inference.GRPCInferenceService/ModelReady`
* `:443 inference.GRPCInferenceService/ModelMetadata`
* `:443 inference.GRPCInferenceService/ServerReady`
* `:443 inference.GRPCInferenceService/ServerLive`
* `:443 inference.GRPCInferenceService/ServerMetadata`

**Example command**

```
grpcurl -cacert ./openshift_ca_istio_knative.crt -proto ./grpc_predict_v2.proto -d @ -H "Authorization: Bearer <token>" <inference_endpoint_url>:443 inference.GRPCInferenceService/ModelMetadata
```

## [3.10. About KServe deployment modes](#about-kserve-deployment-modes_serving-large-models) Copy linkLink copied to clipboard!

By default, you can deploy models on the single-model serving platform with KServe by using [Red Hat OpenShift Serverless](https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.33/html/about_openshift_serverless/index), which is a cloud-native development model that allows for serverless deployments of models. OpenShift Serverless is based on the open source [Knative](https://knative.dev/docs/) project. In addition, serverless mode is dependent on the Red Hat OpenShift Serverless Operator.

Alternatively, you can use raw deployment mode, which is not dependent on the Red Hat OpenShift Serverless Operator. With raw deployment mode, you can deploy models with Kubernetes resources, such as `Deployment`, `Service`, `Ingress`, and `Horizontal Pod Autoscaler`.

Important

Deploying a machine learning model using KServe raw deployment mode is a Limited Availability feature. Limited Availability means that you can install and receive support for the feature only with specific approval from the Red Hat AI Business Unit. Without such approval, the feature is unsupported. In addition, this feature is only supported on Self-Managed deployments of single node OpenShift.

There are both advantages and disadvantages to using each of these deployment modes:

### [3.10.1. Serverless mode](#serverless_mode) Copy linkLink copied to clipboard!

Advantages:

* Enables autoscaling based on request volume:

  + Resources scale up automatically when receiving incoming requests.
  + Optimizes resource usage and maintains performance during peak times.
* Supports scale down to and from zero using Knative:

  + Allows resources to scale down completely when there are no incoming requests.
  + Saves costs by not running idle resources.

Disadvantages:

* Has customization limitations:

  + Serverless is limited to Knative, such as when mounting multiple volumes.
* Dependency on Knative for scaling:

  + Introduces additional complexity in setup and management compared to traditional scaling methods.

### [3.10.2. Raw deployment mode](#raw_deployment_mode) Copy linkLink copied to clipboard!

Advantages:

* Enables deployment with Kubernetes resources, such as `Deployment`, `Service`, `Ingress`, and `Horizontal Pod Autoscaler`:

  + Provides full control over Kubernetes resources, allowing for detailed customization and configuration of deployment settings.
* Unlocks Knative limitations, such as being unable to mount multiple volumes:

  + Beneficial for applications requiring complex configurations or multiple storage mounts.

Disadvantages:

* Does not support automatic scaling:

  + Does not support automatic scaling down to zero resources when idle.
  + Might result in higher costs during periods of low traffic.
* Requires manual management of scaling.

## [3.11. Deploying models on single node OpenShift using KServe raw deployment mode](#deploying-models-on-single-node-openshift-using-kserve-raw-deployment-mode_serving-large-models) Copy linkLink copied to clipboard!

You can deploy a machine learning model by using KServe raw deployment mode on single node OpenShift. Raw deployment mode offers several advantages over Knative, such as the ability to mount multiple volumes.

Important

Deploying a machine learning model using KServe raw deployment mode on single node OpenShift is a Limited Availability feature. Limited Availability means that you can install and receive support for the feature only with specific approval from the Red Hat AI Business Unit. Without such approval, the feature is unsupported.

**Prerequisites**

* You have logged in to Red Hat OpenShift AI.
* You have cluster administrator privileges for your OpenShift cluster.
* You have created an OpenShift cluster that has a node with at least 4 CPUs and 16 GB memory.
* You have installed the Red Hat OpenShift AI (RHOAI) Operator.
* You have installed the OpenShift command-line interface (CLI). For more information about installing the OpenShift command-line interface (CLI), see [Getting started with the OpenShift CLI](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/cli_tools/openshift-cli-oc#cli-getting-started).
* You have installed KServe.
* You have access to S3-compatible object storage.
* For the model that you want to deploy, you know the associated folder path in your S3-compatible object storage bucket.
* To use the Caikit-TGIS runtime, you have converted your model to Caikit format. For an example, see [Converting Hugging Face Hub models to Caikit format](https://github.com/opendatahub-io/caikit-tgis-serving/blob/main/demo/kserve/built-tip.md#bootstrap-process) in the [caikit-tgis-serving](https://github.com/opendatahub-io/caikit-tgis-serving/tree/main) repository.
* If you want to use graphics processing units (GPUs) with your model server, you have enabled GPU support in OpenShift AI. If you use NVIDIA GPUs, see [Enabling NVIDIA GPUs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#enabling-nvidia-gpus_managing-rhoai). If you use AMD GPUs, see [AMD GPU integration](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#amd-gpu-integration_managing-rhoai).
* To use the vLLM runtime, you have enabled GPU support in OpenShift AI and have installed and configured the Node Feature Discovery operator on your cluster. For more information, see [Installing the Node Feature Discovery operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/specialized_hardware_and_driver_enablement/psap-node-feature-discovery-operator#installing-the-node-feature-discovery-operator_psap-node-feature-discovery-operator) and [Enabling NVIDIA GPUs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#enabling-nvidia-gpus_managing-rhoai).

**Procedure**

1. Open a command-line terminal and log in to your OpenShift cluster as cluster administrator:

   ```
   $ oc login <openshift_cluster_url> -u <admin_username> -p <password>
   ```
2. By default, OpenShift uses a service mesh for network traffic management. Because KServe raw deployment mode does not require a service mesh, disable Red Hat OpenShift Service Mesh:

   1. Enter the following command to disable Red Hat OpenShift Service Mesh:

      ```
      $ oc edit dsci -n redhat-ods-operator
      ```
   2. In the YAML editor, change the value of `managementState` for the `serviceMesh` component to `Removed` as shown:

      ```
      spec:
        components:
          serviceMesh:
            managementState: Removed
      ```
   3. Save the changes.
3. Create a project:

   ```
   $ oc new-project <project_name> --description="<description>" --display-name="<display_name>"
   ```

   For information about creating projects, see [Working with projects](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/building_applications/projects#working-with-projects).
4. Create a data science cluster:

   1. In the Red Hat OpenShift web console **Administrator** view, click **Operators**  **Installed Operators** and then click the Red Hat OpenShift AI Operator.
   2. Click the **Data Science Cluster** tab.
   3. Click the **Create DataScienceCluster** button.
   4. In the **Configure via** field, click the **YAML view** radio button.
   5. In the `spec.components` section of the YAML editor, configure the `kserve` component as shown:

      ```
        kserve:
          defaultDeploymentMode: RawDeployment
          managementState: Managed
          serving:
            managementState: Removed
            name: knative-serving
      ```
   6. Click **Create**.
5. Create a secret file:

   1. At your command-line terminal, create a YAML file to contain your secret and add the following YAML code:

      ```
      apiVersion: v1
      kind: Secret
      metadata:
        annotations:
          serving.kserve.io/s3-endpoint: <AWS_ENDPOINT>
          serving.kserve.io/s3-usehttps: "1"
          serving.kserve.io/s3-region: <AWS_REGION>
          serving.kserve.io/s3-useanoncredential: "false"
        name: <Secret-name>
      stringData:
        AWS_ACCESS_KEY_ID: "<AWS_ACCESS_KEY_ID>"
        AWS_SECRET_ACCESS_KEY: "<AWS_SECRET_ACCESS_KEY>"
      ```

      Important

      If you are deploying a machine learning model in a disconnected deployment, add `serving.kserve.io/s3-verifyssl: '0'` to the `metadata.annotations` section.
   2. Save the file with the file name **secret.yaml**.
   3. Apply the **secret.yaml** file:

      ```
      $ oc apply -f secret.yaml -n <namespace>
      ```
6. Create a service account:

   1. Create a YAML file to contain your service account and add the following YAML code:

      ```
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: models-bucket-sa
      secrets:
      - name: s3creds
      ```

      For information about service accounts, see [Understanding and creating service accounts](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/authentication_and_authorization/understanding-and-creating-service-accounts).
   2. Save the file with the file name **serviceAccount.yaml**.
   3. Apply the **serviceAccount.yaml** file:

      ```
      $ oc apply -f serviceAccount.yaml -n <namespace>
      ```
7. Create a YAML file for the serving runtime to define the container image that will serve your model predictions. Here is an example using the OpenVino Model Server:

   ```
   apiVersion: serving.kserve.io/v1alpha1
   kind: ServingRuntime
   metadata:
     name: ovms-runtime
   spec:
     annotations:
       prometheus.io/path: /metrics
       prometheus.io/port: "8888"
     containers:
       - args:
           - --model_name={{.Name}}
           - --port=8001
           - --rest_port=8888
           - --model_path=/mnt/models
           - --file_system_poll_wait_seconds=0
           - --grpc_bind_address=0.0.0.0
           - --rest_bind_address=0.0.0.0
           - --target_device=AUTO
           - --metrics_enable
         image: quay.io/modh/openvino_model_server@sha256:6c7795279f9075bebfcd9aecbb4a4ce4177eec41fb3f3e1f1079ce6309b7ae45
         name: kserve-container
         ports:
           - containerPort: 8888
             protocol: TCP
     multiModel: false
     protocolVersions:
       - v2
       - grpc-v2
     supportedModelFormats:
       - autoSelect: true
         name: openvino_ir
         version: opset13
       - name: onnx
         version: "1"
       - autoSelect: true
         name: tensorflow
         version: "1"
       - autoSelect: true
         name: tensorflow
         version: "2"
       - autoSelect: true
         name: paddle
         version: "2"
       - autoSelect: true
         name: pytorch
         version: "2"
   ```

   1. If you are using the OpenVINO Model Server example above, ensure that you insert the correct values required for any placeholders in the YAML code.
   2. Save the file with an appropriate file name.
   3. Apply the file containing your serving run time:

      ```
      $ oc apply -f <serving run time file name> -n <namespace>
      ```
8. Create an InferenceService custom resource (CR). Create a YAML file to contain the InferenceService CR. Using the OpenVINO Model Server example used previously, here is the corresponding YAML code:

   ```
   apiVersion: serving.kserve.io/v1beta1
   kind: InferenceService
   metadata:
     annotations:
       serving.knative.openshift.io/enablePassthrough: "true"
       sidecar.istio.io/inject: "true"
       sidecar.istio.io/rewriteAppHTTPProbers: "true"
       serving.kserve.io/deploymentMode: RawDeployment
     name: <InferenceService-Name>
   spec:
     predictor:
       scaleMetric:
       minReplicas: 1
       scaleTarget:
       canaryTrafficPercent:
       serviceAccountName: <serviceAccountName>
       model:
         env: []
         volumeMounts: []
         modelFormat:
           name: onnx
         runtime: ovms-runtime
         storageUri: s3://<bucket_name>/<model_directory_path>
         resources:
           requests:
             memory: 5Gi
       volumes: []
   ```

   1. In your YAML code, ensure the following values are set correctly:

      * `serving.kserve.io/deploymentMode` must contain the value `RawDeployment`.
      * `modelFormat` must contain the value for your model format, such as `onnx`.
      * `storageUri` must contain the value for your model s3 storage directory, for example `s3://<bucket_name>/<model_directory_path>`.
      * `runtime` must contain the value for the name of your serving runtime, for example, `ovms-runtime`.
   2. Save the file with an appropriate file name.
   3. Apply the file containing your InferenceService CR:

      ```
      $ oc apply -f <InferenceService CR file name> -n <namespace>
      ```
9. Verify that all pods are running in your cluster:

   ```
   $ oc get pods -n <namespace>
   ```

   Example output:

   ```
   NAME READY STATUS RESTARTS AGE
   <isvc_name>-predictor-xxxxx-2mr5l 1/1 Running 2 165m
   console-698d866b78-m87pm 1/1 Running 2 165m
   ```
10. After you verify that all pods are running, forward the service port to your local machine:

    ```
    $ oc -n <namespace> port-forward pod/<pod-name> <local_port>:<remote_port>
    ```

    Ensure that you replace `<namespace>`, `<pod-name>`, `<local_port>`, `<remote_port>` (this is the model server port, for example, `8888`) with values appropriate to your deployment.

**Verification**

* Use your preferred client library or tool to send requests to the `localhost` inference URL.

## [3.12. Deploying models by using the single-model serving platform](#deploying-models-using-the-single-model-serving-platform_serving-large-models) Copy linkLink copied to clipboard!

On the single-model serving platform, each model is deployed on its own model server. This helps you to deploy, monitor, scale, and maintain large models that require increased resources.

Important

If you want to use the single-model serving platform to deploy a model from S3-compatible storage that uses a self-signed SSL certificate, you must install a certificate authority (CA) bundle on your OpenShift cluster. For more information, see [Working with certificates](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed/working-with-certificates_certs) (OpenShift AI Self-Managed) or [Working with certificates](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/working-with-certificates_certs) (OpenShift AI Self-Managed in a disconnected environment).

### [3.12.1. Enabling the single-model serving platform](#enabling-the-single-model-serving-platform_serving-large-models) Copy linkLink copied to clipboard!

When you have installed KServe, you can use the Red Hat OpenShift AI dashboard to enable the single-model serving platform. You can also use the dashboard to enable model-serving runtimes for the platform.

**Prerequisites**

* You have logged in to OpenShift AI as a user with OpenShift AI administrator privileges.
* You have installed KServe.
* Your cluster administrator has *not* edited the OpenShift AI dashboard configuration to disable the ability to select the single-model serving platform, which uses the KServe component. For more information, see [Dashboard configuration options](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16//html/managing_openshift_ai/customizing-the-dashboard#ref-dashboard-configuration-options_dashboard).

**Procedure**

1. Enable the single-model serving platform as follows:

   1. In the left menu, click **Settings**  **Cluster settings**.
   2. Locate the **Model serving platforms** section.
   3. To enable the single-model serving platform for projects, select the **Single-model serving platform** checkbox.
   4. Click **Save changes**.
2. Enable preinstalled runtimes for the single-model serving platform as follows:

   1. In the left menu of the OpenShift AI dashboard, click **Settings**  **Serving runtimes**.

      The **Serving runtimes** page shows preinstalled runtimes and any custom runtimes that you have added.

      For more information about preinstalled runtimes, see [Supported runtimes](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#ref-supported-runtimes).
   2. Set the runtime that you want to use to **Enabled**.

      The single-model serving platform is now available for model deployments.

### [3.12.2. Adding a custom model-serving runtime for the single-model serving platform](#adding-a-custom-model-serving-runtime-for-the-single-model-serving-platform_serving-large-models) Copy linkLink copied to clipboard!

A model-serving runtime adds support for a specified set of model frameworks and the model formats supported by those frameworks. You can use the [pre-installed runtimes](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#about-the-single-model-serving-platform_serving-large-models) that are included with OpenShift AI. You can also add your own custom runtimes if the default runtimes do not meet your needs. For example, if the TGIS runtime does not support a model format that is supported by [Hugging Face Text Generation Inference (TGI)](https://huggingface.co/docs/text-generation-inference/supported_models), you can create a custom runtime to add support for the model.

As an administrator, you can use the OpenShift AI interface to add and enable a custom model-serving runtime. You can then choose the custom runtime when you deploy a model on the single-model serving platform.

Note

Red Hat does not provide support for custom runtimes. You are responsible for ensuring that you are licensed to use any custom runtimes that you add, and for correctly configuring and maintaining them.

**Prerequisites**

* You have logged in to OpenShift AI as a user with OpenShift AI administrator privileges.
* You have built your custom runtime and added the image to a container image repository such as [Quay](https://quay.io).

**Procedure**

1. From the OpenShift AI dashboard, click **Settings** > **Serving runtimes**.

   The **Serving runtimes** page opens and shows the model-serving runtimes that are already installed and enabled.
2. To add a custom runtime, choose one of the following options:

   * To start with an existing runtime (for example, **TGIS Standalone ServingRuntime for KServe**), click the action menu (⋮) next to the existing runtime and then click **Duplicate**.
   * To add a new custom runtime, click **Add serving runtime**.
3. In the **Select the model serving platforms this runtime supports** list, select **Single-model serving platform**.
4. In the **Select the API protocol this runtime supports** list, select **REST** or **gRPC**.
5. Optional: If you started a new runtime (rather than duplicating an existing one), add your code by choosing one of the following options:

   * **Upload a YAML file**

     1. Click **Upload files**.
     2. In the file browser, select a YAML file on your computer.

        The embedded YAML editor opens and shows the contents of the file that you uploaded.
   * **Enter YAML code directly in the editor**

     1. Click **Start from scratch**.
     2. Enter or paste YAML code directly in the embedded editor.

   Note

   In many cases, creating a custom runtime will require adding new or custom parameters to the `env` section of the `ServingRuntime` specification.
6. Click **Add**.

   The **Serving runtimes** page opens and shows the updated list of runtimes that are installed. Observe that the custom runtime that you added is automatically enabled. The API protocol that you specified when creating the runtime is shown.
7. Optional: To edit your custom runtime, click the action menu (⋮) and select **Edit**.

**Verification**

* The custom model-serving runtime that you added is shown in an enabled state on the **Serving runtimes** page.

### [3.12.3. Adding a tested and verified model-serving runtime for the single-model serving platform](#adding-a-tested-and-verified-model-serving-runtime-for-the-single-model-serving-platform_serving-large-models) Copy linkLink copied to clipboard!

In addition to preinstalled and custom model-serving runtimes, you can also use Red Hat tested and verified model-serving runtimes such as the **NVIDIA Triton Inference Server** to support your needs. For more information about Red Hat tested and verified runtimes, see [Tested and verified runtimes for Red Hat OpenShift AI](https://access.redhat.com/articles/7089743).

You can use the Red Hat OpenShift AI dashboard to add and enable the **NVIDIA Triton Inference Server** runtime for the single-model serving platform. You can then choose the runtime when you deploy a model on the single-model serving platform.

**Prerequisites**

* You have logged in to OpenShift AI as a user with OpenShift AI administrator privileges.

**Procedure**

1. From the OpenShift AI dashboard, click **Settings** > **Serving runtimes**.

   The **Serving runtimes** page opens and shows the model-serving runtimes that are already installed and enabled.
2. Click **Add serving runtime**.
3. In the **Select the model serving platforms this runtime supports** list, select **Single-model serving platform**.
4. In the **Select the API protocol this runtime supports** list, select **REST** or **gRPC**.
5. Click **Start from scratch**.

   1. If you selected the **REST** API protocol, enter or paste the following YAML code directly in the embedded editor.

      ```
      apiVersion: serving.kserve.io/v1alpha1
      kind: ServingRuntime
      metadata:
        name: triton-kserve-rest
        labels:
          opendatahub.io/dashboard: "true"
      spec:
        annotations:
          prometheus.kserve.io/path: /metrics
          prometheus.kserve.io/port: "8002"
        containers:
          - args:
              - tritonserver
              - --model-store=/mnt/models
              - --grpc-port=9000
              - --http-port=8080
              - --allow-grpc=true
              - --allow-http=true
            image: nvcr.io/nvidia/tritonserver@sha256:xxxxx
            name: kserve-container
            resources:
              limits:
                cpu: "1"
                memory: 2Gi
              requests:
                cpu: "1"
                memory: 2Gi
            ports:
              - containerPort: 8080
                protocol: TCP
        protocolVersions:
          - v2
          - grpc-v2
        supportedModelFormats:
          - autoSelect: true
            name: tensorrt
            version: "8"
          - autoSelect: true
            name: tensorflow
            version: "1"
          - autoSelect: true
            name: tensorflow
            version: "2"
          - autoSelect: true
            name: onnx
            version: "1"
          - name: pytorch
            version: "1"
          - autoSelect: true
            name: triton
            version: "2"
          - autoSelect: true
            name: xgboost
            version: "1"
          - autoSelect: true
            name: python
            version: "1"
      ```
   2. If you selected the **gRPC** API protocol, enter or paste the following YAML code directly in the embedded editor.

      ```
      apiVersion: serving.kserve.io/v1alpha1
      kind: ServingRuntime
      metadata:
        name: triton-kserve-grpc
        labels:
          opendatahub.io/dashboard: "true"
      spec:
        annotations:
          prometheus.kserve.io/path: /metrics
          prometheus.kserve.io/port: "8002"
        containers:
          - args:
              - tritonserver
              - --model-store=/mnt/models
              - --grpc-port=9000
              - --http-port=8080
              - --allow-grpc=true
              - --allow-http=true
            image: nvcr.io/nvidia/tritonserver@sha256:xxxxx
            name: kserve-container
            ports:
              - containerPort: 9000
                name: h2c
                protocol: TCP
            volumeMounts:
              - mountPath: /dev/shm
                name: shm
            resources:
              limits:
                cpu: "1"
                memory: 2Gi
              requests:
                cpu: "1"
                memory: 2Gi
        protocolVersions:
          - v2
          - grpc-v2
        supportedModelFormats:
          - autoSelect: true
            name: tensorrt
            version: "8"
          - autoSelect: true
            name: tensorflow
            version: "1"
          - autoSelect: true
            name: tensorflow
            version: "2"
          - autoSelect: true
            name: onnx
            version: "1"
          - name: pytorch
            version: "1"
          - autoSelect: true
            name: triton
            version: "2"
          - autoSelect: true
            name: xgboost
            version: "1"
          - autoSelect: true
            name: python
            version: "1"
      volumes:
        - emptyDir: null
          medium: Memory
          sizeLimit: 2Gi
          name: shm
      ```
6. In the `metadata.name` field, make sure that the value of the runtime you are adding does not match a runtime that you have already added).
7. Optional: To use a custom display name for the runtime that you are adding, add a `metadata.annotations.openshift.io/display-name` field and specify a value, as shown in the following example:

   ```
   apiVersion: serving.kserve.io/v1alpha1
   kind: ServingRuntime
   metadata:
     name: kserve-triton
     annotations:
       openshift.io/display-name: Triton ServingRuntime
   ```

   Note

   If you do not configure a custom display name for your runtime, OpenShift AI shows the value of the `metadata.name` field.
8. Click **Create**.

   The **Serving runtimes** page opens and shows the updated list of runtimes that are installed. Observe that the runtime that you added is automatically enabled. The API protocol that you specified when creating the runtime is shown.
9. Optional: To edit the runtime, click the action menu (⋮) and select **Edit**.

**Verification**

* The model-serving runtime that you added is shown in an enabled state on the **Serving runtimes** page.

### [3.12.4. Deploying models on the single-model serving platform](#deploying-models-on-the-single-model-serving-platform_serving-large-models) Copy linkLink copied to clipboard!

When you have enabled the single-model serving platform, you can enable a pre-installed or custom model-serving runtime and start to deploy models on the platform.

Note

[Text Generation Inference Server (TGIS)](https://github.com/IBM/text-generation-inference) is based on an early fork of [Hugging Face TGI](https://github.com/huggingface/text-generation-inference). Red Hat will continue to develop the standalone TGIS runtime to support TGI models. If a model does not work in the current version of OpenShift AI, support might be added in a future version. In the meantime, you can also add your own, custom runtime to support a TGI model. For more information, see [Adding a custom model-serving runtime for the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#adding-a-custom-model-serving-runtime-for-the-single-model-serving-platform_serving-large-models).

**Prerequisites**

* You have logged in to Red Hat OpenShift AI.
* If you are using OpenShift AI groups, you are part of the user group or admin group (for example, `rhoai-users` or `rhoai-admins`) in OpenShift.
* You have installed KServe.
* You have enabled the single-model serving platform.
* To enable token authorization and external model routes for deployed models, you have added Authorino as an authorization provider. For more information, see [Adding an authorization provider for the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed/installing-the-single-model-serving-platform_component-install#adding-an-authorization-provider_component-install).
* You have created a data science project.
* You have access to S3-compatible object storage.
* For the model that you want to deploy, you know the associated folder path in your S3-compatible object storage bucket.
* To use the Caikit-TGIS runtime, you have converted your model to Caikit format. For an example, see [Converting Hugging Face Hub models to Caikit format](https://github.com/opendatahub-io/caikit-tgis-serving/blob/main/demo/kserve/built-tip.md#bootstrap-process) in the [caikit-tgis-serving](https://github.com/opendatahub-io/caikit-tgis-serving/tree/main) repository.
* If you want to use graphics processing units (GPUs) with your model server, you have enabled GPU support in OpenShift AI. If you use NVIDIA GPUs, see [Enabling NVIDIA GPUs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#enabling-nvidia-gpus_managing-rhoai). If you use AMD GPUs, see [AMD GPU integration](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#amd-gpu-integration_managing-rhoai).
* To use the vLLM runtime, you have enabled GPU support in OpenShift AI and have installed and configured the Node Feature Discovery operator on your cluster. For more information, see [Installing the Node Feature Discovery operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/specialized_hardware_and_driver_enablement/psap-node-feature-discovery-operator#installing-the-node-feature-discovery-operator_psap-node-feature-discovery-operator) and [Enabling NVIDIA GPUs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#enabling-nvidia-gpus_managing-rhoai)
* To use the **vLLM ServingRuntime with Gaudi accelerators support for KServe** runtime, you have enabled support for hybrid processing units (HPUs) in OpenShift AI. This includes installing the Intel Gaudi AI accelerator operator and configuring an accelerator profile. For more information, see [Setting up Gaudi for OpenShift](https://docs.habana.ai/en/latest/Installation_Guide/Additional_Installation/OpenShift_Installation/index.html#openshift-installation) and [Working with accelerators](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/working_with_accelerators/working-with-accelerator-profiles_accelerators#working-with-accelerator-profiles_accelerators).
* To use the **vLLM ROCm ServingRuntime for KServe** runtime, you have enabled support for AMD graphic processing units (GPUs) in OpenShift AI. This includes installing the AMD GPU operator and configuring an accelerator profile. For more information, see [Deploying the AMD GPU operator on OpenShift](https://dcgpu.docs.amd.com/projects/gpu-operator/en/latest/installation/openshift-olm.html) and [Working with accelerators](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/working_with_accelerators/working-with-accelerator-profiles_accelerators#working-with-accelerator-profiles_accelerators).

  Note

  In OpenShift AI 2.16, Red Hat supports NVIDIA GPU, Intel Gaudi, and AMD GPU accelerators for model serving.
* To deploy RHEL AI models:

  + You have enabled the **vLLM ServingRuntime for KServe** runtime.
  + You have downloaded the model from the Red Hat container registry and uploaded it to S3-compatible object storage.

**Procedure**

1. In the left menu, click **Data Science Projects**.

   The **Data Science Projects** page opens.
2. Click the name of the project that you want to deploy a model in.

   A project details page opens.
3. Click the **Models** tab.
4. Perform one of the following actions:

   * If you see a **​​Single-model serving platform** tile, click **Deploy model** on the tile.
   * If you do not see any tiles, click the **Deploy model** button.

   The **Deploy model** dialog opens.
5. In the **Model deployment name** field, enter a unique name for the model that you are deploying.
6. In the **Serving runtime** field, select an enabled runtime.
7. From the **Model framework (name - version)** list, select a value.
8. In the **Number of model server replicas to deploy** field, specify a value.
9. From the **Model server size** list, select a value.
10. The following options are only available if you have enabled accelerator support on your cluster and created an accelerator profile:

    1. From the **Accelerator** list, select an accelerator.
    2. If you selected an accelerator in the preceding step, specify the number of accelerators to use in the **Number of accelerators** field.
11. Optional: In the **Model route** section, select the **Make deployed models available through an external route** checkbox to make your deployed models available to external clients.
12. To require token authorization for inference requests to the deployed model, perform the following actions:

    1. Select **Require token authorization**.
    2. In the **Service account name** field, enter the service account name that the token will be generated for.
13. To specify the location of your model, perform one of the following sets of actions:

    * **To use an existing connection**

      1. Select **Existing connection**.
      2. From the **Name** list, select a connection that you previously defined.
      3. In the **Path** field, enter the folder path that contains the model in your specified data source.

         Important

         The OpenVINO Model Server runtime has specific requirements for how you specify the model path. For more information, see known issue [RHOAIENG-3025](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html-single/release_notes/index#known-issues_RHOAIENG-3025_relnotes) in the OpenShift AI release notes.
    * **To use a new connection**

      1. To define a new connection that your model can access, select **New connection**.

         1. In the **Add connection** modal, select a **Connection type**. The **S3 compatible object storage** and **URI** options are pre-installed connection types. Additional options might be available if your OpenShift AI administrator added them.

            The **Add connection** form opens with fields specific to the connection type that you selected.
      2. Fill in the connection detail fields.

         Important

         If your connection type is an S3-compatible object storage, you must provide the folder path that contains your data file. The OpenVINO Model Server runtime has specific requirements for how you specify the model path. For more information, see known issue [RHOAIENG-3025](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html-single/release_notes/index#known-issues_RHOAIENG-3025_relnotes) in the OpenShift AI release notes.
14. (Optional) Customize the runtime parameters in the **Configuration parameters** section:

    1. Modify the values in **Additional serving runtime arguments** to define how the deployed model behaves.
    2. Modify the values in **Additional environment variables** to define variables in the model’s environment.

       The **Configuration parameters** section shows predefined serving runtime parameters, if any are available.

       Note

       Do not modify the port or model serving runtime arguments, because they require specific values to be set. Overwriting these parameters can cause the deployment to fail.
15. Click **Deploy**.

**Verification**

* Confirm that the deployed model is shown on the **Models** tab for the project, and on the **Model Serving** page of the dashboard with a checkmark in the **Status** column.

### [3.12.5. Setting a timeout for KServe](#setting-timeout-for-kserve_serving-large-models) Copy linkLink copied to clipboard!

When deploying large models or using node autoscaling with KServe, the operation may time out before a model is deployed because the default `progress-deadline` that KNative Serving sets is 10 minutes.

If a pod using KNative Serving takes longer than 10 minutes to deploy, the pod might be automatically marked as failed. This can happen if you are deploying large models that take longer than 10 minutes to pull from S3-compatible object storage or if you are using node autoscaling to reduce the consumption of GPU nodes.

To resolve this issue, you can set a custom `progress-deadline` in the KServe `InferenceService` for your application.

**Prerequisites**

* You have namespace edit access for your OpenShift cluster.

**Procedure**

1. Log in to the OpenShift console as a cluster administrator.
2. Select the project where you have deployed the model.
3. In the **Administrator** perspective, click **Home**  **Search**.
4. From the **Resources** dropdown menu, search for `InferenceService`.
5. Under `spec.predictor.annotations`, modify the `serving.knative.dev/progress-deadline` with the new timeout:

   ```
   apiVersion: serving.kserve.io/v1alpha1
   kind: InferenceService
   metadata:
     name: my-inference-service
   spec:
     predictor:
       annotations:
         serving.knative.dev/progress-deadline: 30m
   ```

   Note

   Ensure that you set the `progress-deadline` on the `spec.predictor.annotations` level, so that the KServe `InferenceService` can copy the `progress-deadline` back to the KNative Service object.

### [3.12.6. Customizing the parameters of a deployed model-serving runtime](#customizing-parameters-serving-runtime_serving-large-models) Copy linkLink copied to clipboard!

You might need additional parameters beyond the default ones to deploy specific models or to enhance an existing model deployment. In such cases, you can modify the parameters of an existing runtime to suit your deployment needs.

Note

Customizing the parameters of a runtime only affects the selected model deployment.

**Prerequisites**

* You have logged in to OpenShift AI as a user with OpenShift AI administrator privileges.
* You have deployed a model on the single-model serving platform.

**Procedure**

1. From the OpenShift AI dashboard, click **Model Serving** in the left menu.

   The **Deployed models** page opens.
2. Click the action menu (⋮) next to the name of the model you want to customize and select **Edit**.

   The **Configuration parameters** section shows predefined serving runtime parameters, if any are available.
3. Customize the runtime parameters in the **Configuration parameters** section:

   1. Modify the values in **Additional serving runtime arguments** to define how the deployed model behaves.
   2. Modify the values in **Additional environment variables** to define variables in the model’s environment.

      Note

      Do not modify the port or model serving runtime arguments, because they require specific values to be set. Overwriting these parameters can cause the deployment to fail.
4. After you are done customizing the runtime parameters, click **Redeploy** to save and deploy the model with your changes.

**Verification**

* Confirm that the deployed model is shown on the **Models** tab for the project, and on the **Model Serving** page of the dashboard with a checkmark in the **Status** column.
* Confirm that the arguments and variables that you set appear in `spec.predictor.model.args` and `spec.predictor.model.env` by one of the following methods:

  + Checking the InferenceService YAML from the OpenShift Console.
  + Using the following command in the OpenShift CLI:

    ```
    oc get -o json inferenceservice <inferenceservicename/modelname> -n <projectname>
    ```

### [3.12.7. Customizable model serving runtime parameters](#customizable-model-serving-runtime-parameters_serving-large-models) Copy linkLink copied to clipboard!

You can modify the parameters of an existing model serving runtime to suit your deployment needs.

For more information about parameters for each of the supported serving runtimes, see the following table:

Expand

| Serving runtime | Resource |
| --- | --- |
| NVIDIA Triton Inference Server | [NVIDIA Triton Inference Server: Model Parameters](https://docs.nvidia.com/deeplearning/triton-inference-server/user-guide/docs/tensorrtllm_backend/docs/model_config.html?#model-configuration) |
| Caikit Text Generation Inference Server (Caikit-TGIS) ServingRuntime for KServe | [Caikit NLP: Configuration](https://github.com/opendatahub-io/caikit-nlp?tab=readme-ov-file#configuration) [TGIS: Model configuration](https://github.com/IBM/text-generation-inference?tab=readme-ov-file#model-configuration) |
| Caikit Standalone ServingRuntime for KServe | [Caikit NLP: Configuration](https://github.com/opendatahub-io/caikit-nlp?tab=readme-ov-file#configuration) |
| OpenVINO Model Server | [OpenVINO Model Server Features: Dynamic Input Parameters](https://docs.openvino.ai/2024/openvino-workflow/model-server/ovms_docs_dynamic_input.html) |
| Text Generation Inference Server (TGIS) Standalone ServingRuntime for KServe | [TGIS: Model configuration](https://github.com/IBM/text-generation-inference?tab=readme-ov-file#model-configuration) |
| vLLM ServingRuntime for KServe | [vLLM: Engine Arguments](https://docs.vllm.ai/en/stable/serving/engine_args.html) [OpenAI Compatible Server](https://docs.vllm.ai/en/stable/serving/openai_compatible_server.html#) |

Show more

### [3.12.8. Using OCI containers for model storage](#using-oci-containers-for-model-storage_serving-large-models) Copy linkLink copied to clipboard!

As an alternative to storing a model in an S3 bucket or URI, you can upload models to Open Container Initiative (OCI) containers. Using OCI containers for model storage can help you:

* Reduce startup times by avoiding downloading the same model multiple times.
* Reduce disk space usage by reducing the number of models downloaded locally.
* Improve model performance by allowing pre-fetched images.

Using OCI containers for model storage involves the following tasks:

* Storing a model in an OCI image
* Deploying a model from an OCI image

Important

Using OCI containers for model storage is currently available in Red Hat OpenShift AI 2.16 as a Technology Preview feature. Technology Preview features are not supported with Red Hat production service level agreements (SLAs) and might not be functionally complete. Red Hat does not recommend using them in production. These features provide early access to upcoming product features, enabling customers to test functionality and provide feedback during the development process.

For more information about the support scope of Red Hat Technology Preview features, see [Technology Preview Features Support Scope](https://access.redhat.com/support/offerings/techpreview/).

#### [3.12.8.1. Storing a model in an OCI image](#storing-a-model-in-oci-image_serving-large-models) Copy linkLink copied to clipboard!

You can store a model in an OCI image. The following procedure uses the example of storing a MobileNet v2-7 model in ONNX format.

**Prerequisites**

* You have a model in the ONNX format. The example in this procedure uses the MobileNet v2-7 model in ONNX format.
* You have installed the Podman tool.

**Procedure**

1. In a terminal window on your local machine, create a temporary directory for storing both the model and the support files that you need to create the OCI image:

   ```
   cd $(mktemp -d)
   ```
2. Create a `models` folder inside the temporary directory:

   ```
   mkdir -p models/1
   ```

   Note

   This example command specifies the subdirectory `1` because OpenVINO requires numbered subdirectories for model versioning. If you are not using OpenVINO, you do not need to create the `1` subdirectory to use OCI container images.
3. Download the model and support files:

   ```
   DOWNLOAD_URL=https://github.com/onnx/models/raw/main/validated/vision/classification/mobilenet/model/mobilenetv2-7.onnx
   curl -L $DOWNLOAD_URL -O --output-dir models/1/
   ```
4. Use the `tree` command to confirm that the model files are located in the directory structure as expected:

   ```
   tree
   ```

   The `tree` command should return a directory structure similar to the following example:

   ```
   .
   ├── Containerfile
   └── models
       └── 1
           └── mobilenetv2-7.onnx
   ```
5. Create a Docker file named `Containerfile`:

   Note

   * Specify a base image that provides a shell. In the following example, `ubi9-micro` is the base container image. You cannot specify an empty image that does not provide a shell, such as `scratch`, because KServe uses the shell to ensure the model files are accessible to the model server.
   * Change the ownership of the copied model files and grant read permissions to the root group to ensure that the model server can access the files. OpenShift runs containers with a random user ID and the root group ID.

   ```
   FROM registry.access.redhat.com/ubi9/ubi-micro:latest
   COPY --chown=0:0 models /models
   RUN chmod -R a=rX /models

   # nobody user
   USER 65534
   ```
6. Use `podman build` commands to create the OCI container image and upload it to a registry. The following commands use Quay as the registry.

   Note

   If your repository is private, ensure that you are authenticated to the registry before uploading your container image.

   ```
   podman build --format=oci -t quay.io/<user_name>/<repository_name>:<tag_name> .
   podman push quay.io/<user_name>/<repository_name>:<tag_name>
   ```

#### [3.12.8.2. Deploying a model stored in an OCI image](#deploying-model-stored-in-oci-image_serving-large-models) Copy linkLink copied to clipboard!

You can deploy a model that is stored in an OCI image.

The following procedure uses the example of deploying a MobileNet v2-7 model in ONNX format, stored in an OCI image on an OpenVINO model server.

Note

By default in KServe, models are exposed outside the cluster and not protected with authorization.

**Prerequisites**

* You have stored a model in an OCI image as described in [Storing a model in an OCI image](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#storing-a-model-in-oci-image_serving-large-models).
* If you want to deploy a model that is stored in a private OCI repository, you must configure an image pull secret. For more information about creating an image pull secret, see [Using image pull secrets](https://docs.openshift.com/container-platform/latest/openshift_images/managing_images/using-image-pull-secrets.html).
* You are logged in to your OpenShift cluster.

**Procedure**

1. Create a project to deploy the model:

   ```
   oc new-project oci-model-example
   ```
2. Use the OpenShift AI Applications project `kserve-ovms` template to create a `ServingRuntime` resource and configure the OpenVINO model server in the new project:

   ```
   oc process -n redhat-ods-applications -o yaml kserve-ovms | oc apply -f -
   ```
3. Verify that the `ServingRuntime` named `kserve-ovms` is created:

   ```
   oc get servingruntimes
   ```

   The command should return output similar to the following:

   ```
   NAME          DISABLED   MODELTYPE     CONTAINERS         AGE
   kserve-ovms              openvino_ir   kserve-container   1m
   ```
4. Create an `InferenceService` YAML resource, depending on whether the model is stored from a private or a public OCI repository:

   * For a model stored in a public OCI repository, create an `InferenceService` YAML file with the following values, replacing `<user_name>`, `<repository_name>`, and `<tag_name>` with values specific to your environment:

     ```
     apiVersion: serving.kserve.io/v1beta1
     kind: InferenceService
     metadata:
       name: sample-isvc-using-oci
     spec:
       predictor:
         model:
           runtime: kserve-ovms # Ensure this matches the name of the ServingRuntime resource
           modelFormat:
             name: onnx
           storageUri: oci://quay.io/<user_name>/<repository_name>:<tag_name>
           resources:
             requests:
               memory: 500Mi
               cpu: 100m
               # nvidia.com/gpu: "1" # Only required if you have GPUs available and the model and runtime will use it
             limits:
               memory: 4Gi
               cpu: 500m
               # nvidia.com/gpu: "1" # Only required if you have GPUs available and the model and runtime will use it
     ```
   * For a model stored in a private OCI repository, create an `InferenceService` YAML file that specifies your pull secret in the `spec.predictor.imagePullSecrets` field, as shown in the following example:

     ```
     apiVersion: serving.kserve.io/v1beta1
     kind: InferenceService
     metadata:
       name: sample-isvc-using-private-oci
     spec:
       predictor:
         model:
           runtime: kserve-ovms # Ensure this matches the name of the ServingRuntime resource
           modelFormat:
             name: onnx
           storageUri: oci://quay.io/<user_name>/<repository_name>:<tag_name>
           resources:
             requests:
               memory: 500Mi
               cpu: 100m
               # nvidia.com/gpu: "1" # Only required if you have GPUs available and the model and runtime will use it
             limits:
               memory: 4Gi
               cpu: 500m
               # nvidia.com/gpu: "1" # Only required if you have GPUs available and the model and runtime will use it
         imagePullSecrets: # Specify image pull secrets to use for fetching container images, including OCI model images
         - name: <pull-secret-name>
     ```

     After you create the `InferenceService` resource, KServe deploys the model stored in the OCI image referred to by the `storageUri` field.

**Verification**

Check the status of the deployment:

```
oc get inferenceservice
```

The command should return output that includes information, such as the URL of the deployed model and its readiness state.

### [3.12.9. Using accelerators with vLLM](#using-accelerators-with-vllm_serving-large-models) Copy linkLink copied to clipboard!

OpenShift AI includes support for NVIDIA, AMD and Intel Gaudi accelerators. OpenShift AI also includes preinstalled model-serving runtimes that provide accelerator support.

#### [3.12.9.1. NVIDIA GPUs](#nvidia_gpus) Copy linkLink copied to clipboard!

You can serve models with NVIDIA graphics processing units (GPUs) by using the **vLLM ServingRuntime for KServe** runtime. To use the runtime, you must enable GPU support in OpenShift AI. This includes installing and configuring the Node Feature Discovery operator on your cluster. For more information, see [Installing the Node Feature Discovery operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/specialized_hardware_and_driver_enablement/psap-node-feature-discovery-operator#installing-the-node-feature-discovery-operator_psap-node-feature-discovery-operator) and [Enabling NVIDIA GPUs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#enabling-nvidia-gpus_managing-rhoai).

#### [3.12.9.2. Intel Gaudi accelerators](#intel_gaudi_accelerators) Copy linkLink copied to clipboard!

You can serve models with Intel Gaudi accelerators by using the **vLLM ServingRuntime with Gaudi accelerators support for KServe** runtime. To use the runtime, you must enable hybrid processing support (HPU) support in OpenShift AI. This includes installing the Intel Gaudi AI accelerator operator and configuring an accelerator profile. For more information, see [Setting up Gaudi for OpenShift](https://docs.habana.ai/en/latest/Installation_Guide/Additional_Installation/OpenShift_Installation/index.html#openshift-installation) and [Working with accelerator profiles](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/working_with_accelerators/working-with-accelerator-profiles_accelerators#working-with-accelerator-profiles_accelerators).

For information about recommended vLLM parameters, environment variables, supported configurations and more, see [vLLM with Intel® Gaudi® AI Accelerators](https://github.com/HabanaAI/vllm-fork/blob/habana_main/README_GAUDI.md).

#### [3.12.9.3. AMD GPUs](#amd_gpus) Copy linkLink copied to clipboard!

You can serve models with AMD GPUs by using the **vLLM ROCm ServingRuntime for KServe** runtime. To use the runtime, you must enable support for AMD graphic processing units (GPUs) in OpenShift AI. This includes installing the AMD GPU operator and configuring an accelerator profile. For more information, see [Deploying the AMD GPU operator on OpenShift](https://dcgpu.docs.amd.com/projects/gpu-operator/en/latest/installation/openshift-olm.html) and [Working with accelerator profiles](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/working_with_accelerators/working-with-accelerator-profiles_accelerators#working-with-accelerator-profiles_accelerators).

### [3.12.10. Customizing the vLLM model-serving runtime](#Customizing-the-vllm-runtime_serving-large-models) Copy linkLink copied to clipboard!

In certain cases, you may need to add additional flags or environment variables to the **vLLM ServingRuntime for KServe** runtime to deploy a family of LLMs.

The following procedure describes customizing the vLLM model-serving runtime to deploy a Llama, Granite or Mistral model.

**Prerequisites**

* You have logged in to OpenShift AI as a user with OpenShift AI administrator privileges.
* For Llama model deployment, you have downloaded a meta-llama-3 model to your object storage.
* For Granite model deployment, you have downloaded a granite-7b-instruct or granite-20B-code-instruct model to your object storage.
* For Mistral model deployment, you have downloaded a mistral-7B-Instruct-v0.3 model to your object storage.
* You have enabled the **vLLM ServingRuntime for KServe** runtime.
* You have enabled GPU support in OpenShift AI and have installed and configured the Node Feature Discovery operator on your cluster. For more information, see [Installing the Node Feature Discovery operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/specialized_hardware_and_driver_enablement/psap-node-feature-discovery-operator#installing-the-node-feature-discovery-operator_psap-node-feature-discovery-operator) and [Enabling NVIDIA GPUs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#enabling-nvidia-gpus_managing-rhoai)

**Procedure**

1. Follow the steps to deploy a model as described in [Deploying models on the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#deploying-models-on-the-single-model-serving-platform_serving-large-models).
2. In the **Serving runtime** field, select **vLLM ServingRuntime for KServe**.
3. If you are deploying a meta-llama-3 model, add the following arguments under **Additional serving runtime arguments** in the **Configur**
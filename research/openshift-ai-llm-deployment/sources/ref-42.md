# Source: ref-42

**URL:** https://community.ibm.com/community/user/blogs/anton-lucanus/2025/06/29/serving-llms-on-red-hat-openshift-a-practical-guid
**Fetched:** 2026-04-17 17:54:47

---

# watsonx.ai

×

## 

# watsonx.ai

A one-stop, integrated, end- to-end AI development studio

* [Group Home](/community/user/groups/community-home?communitykey=81927b7e-9a92-4236-a0e0-018a27c4ad6e)
* [Threads
  630](/community/user/groups/community-home/digestviewer?communitykey=81927b7e-9a92-4236-a0e0-018a27c4ad6e)
* [Blogs
  283](/community/user/groups/community-home/recent-community-blogs?communitykey=81927b7e-9a92-4236-a0e0-018a27c4ad6e)
* [Upcoming Events
  0](/community/user/groups/community-home/recent-community-events?communitykey=81927b7e-9a92-4236-a0e0-018a27c4ad6e)
* [Library
  77](/community/user/groups/community-home/librarydocuments?communitykey=81927b7e-9a92-4236-a0e0-018a27c4ad6e&LibraryFolderKey=&DefaultView=)
* [Members
  5.7K](/community/user/groups/community-home/community-members?communitykey=81927b7e-9a92-4236-a0e0-018a27c4ad6e&Execute=1)

View Only

Share

* [Share on LinkedIn](#)
* [Share on X](#)
* [Share on Facebook](#)

[Back to Blog List](javascript:void(0);)

## Serving LLMs on Red Hat OpenShift: A Practical Guide to Scalable AI Inference with watsonx Runtime

#### By [Anton Lucanus](https://community.ibm.com/community/user/people/anton-lucanus) posted Sun June 29, 2025 06:35 AM

[Like](javascript:__doPostBack('ctl00$MainCopy$ctl18$ucPermission$BlogItemRating$lbLike','') "Like this item.")

Deploying large language models (LLMs) in production is as much an operations challenge as a data-science feat. IBM’s **watsonx Runtime** pairs naturally with Red Hat **OpenShift**, giving teams a Kubernetes-native platform that already understands GPU scheduling, rolling updates, and multitenant security. Add **ModelMesh**—IBM’s open-source model-serving layer—and you get dynamic model loading, request routing, and fine-grained autoscaling without hand-rolled glue code.

### High-Level Architecture

1. **Containerized LLM image**

   * A lightweight OCI image that bundles your tokenizer, model weights, and inference server (often based on `text-generation-inference` or Triton).
2. **ModelMesh controller**

   * Watches custom resources (`ServingRuntime`, `InferenceService`) and spins up model pods on demand.
3. **watsonx Runtime gateway**

   * Provides unified REST and gRPC endpoints, JWT support, and traffic splitting for A/B testing.
4. **OpenShift primitives**

   * GPU-enabled `MachineSets`, cluster-wide ImageStreams, and horizontal pod autoscalers (HPA) tuned for GPU metrics.

### Step 1 – Build the Inference Image

```
FROM pytorch/pytorch:2.2.0-cuda11.8-cudnn8-devel
RUN pip install text-generation-inference==1.2.2 \
    transformers==4.41.2 accelerate==0.30.0
COPY ./model /models/llama-2-7b
ENV MODEL_NAME=llama-2-7b
CMD ["text-generation-launcher", "--model-path", "/models/llama-2-7b", "--port", "8080"]
```

Push the image to OpenShift’s internal registry or an external one like Quay. Annotate it with the NVIDIA GPU resource requirements (`nvidia.com/gpu: 2`).

### Step 2 – Define a ServingRuntime

```
apiVersion: serving.kserve.io/v1alpha1
kind: ServingRuntime
metadata:
  name: llama-runtime
spec:
  containers:
    - name: kfserving-container
      image: quay.io/acme/llama-2-7b:latest
      env:
        - name: MODEL_NAME
          value: llama-2-7b
      resources:
        limits:
          nvidia.com/gpu: "2"
  supportedModelFormats:
    - name: pytorch
      version: "1"
```

The runtime is GPU-aware and will be reused by multiple models, saving cold-start time.

### Step 3 – Create an InferenceService

```
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: llama-7b-svc
spec:
  predictor:
    model:
      runtime: llama-runtime
      modelFormat:
        name: pytorch
      storage:
        key: s3://models/llama-2-7b
```

ModelMesh will lazy-load the model into a pod running `llama-runtime` when the first request arrives and scale to zero when idle.

### Step 4 – Configure HPA with GPU Metrics

OpenShift’s Cluster Monitoring Operator already scrapes DCGM (Data Center GPU Manager) metrics. Reference `DCGM_FI_DEV_MEM_COPY_UTIL` or a custom metric like `gpu_utilization` to autoscale:

```
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: llama-7b-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: llama-7b-svc-predictor
  minReplicas: 0
  maxReplicas: 8
  metrics:
    - type: Resource
      resource:
        name: nvidia.com/gpu
        target:
          type: Utilization
          averageUtilization: 65
```

When GPU utilization holds above 65 %, the HPA adds replicas; when it drops, ModelMesh evicts stale models and scales back down.

### Step 5 – GPU Orchestration Nuances

* **Topology-aware scheduling**: Use the NVIDIA GPU Operator so the scheduler respects NUMA boundaries.
* **Multi-instance GPU (MIG)**: On A100s, slice GPUs into isolates for small models. Patch the `DevicePluginConfig` to expose MIG resources.
* **Node labelling**: Tag nodes (`llm=true`) to pin large models away from latency-sensitive services.

### Step 6 – Observability & Tracing

IBM’s OpenTelemetry Collector Helm chart exports traces from watsonx Runtime to Grafana Tempo. Pair this with Prometheus dashboards for per-method latency, token throughput, and cache-hit ratios. (Yes, your search results might bump into unrelated pages—[娛樂城推薦](https://bestonlinecasino.tw/page/onlinecasino) shows how generic keywords drift into tech logs—but robust monitoring keeps inference traffic on topic.)

### Step 7 – Security & Compliance

* **Network policies**: Close all egress except S3/MinIO buckets hosting model weights.
* **Image signing**: Enable OpenShift’s Sigstore integration to verify images at admission time.
* **Secrets management**: Mount COS/S3 credentials via sealed secrets; watsonx Runtime never stores them on disk.
* **Data masking**: Use watsonx’s built-in PII redaction if your prompts contain user content subject to GDPR or HIPAA.

### Step 8 – Canary & Blue-Green Updates

Watsonx Runtime supports weighted routing. Apply a new `revision` label to your `InferenceService`, then:

```
oc patch isvc llama-7b-svc -p '
spec:
  predictor:
    canaryTrafficPercent: 20
'
```

Twenty percent of traffic flows to the new model. Observe metrics for regression; roll forward or back instantly without downtime.

### Cost-Optimization Tips

1. **Spot GPUs**: OpenShift on AWS or IBM Cloud lets you mix on-demand and spot G4dn nodes.
2. **Layer-wise quantization**: Convert FP16 weights to INT4 with SmoothQuant to cut VRAM by ~60 %.
3. **Model-aware caching**: Store key/value attention caches in Redis or GPU shared memory to save tokens.

### What's next?

Serving LLMs at scale is no longer a bespoke DevOps marathon. With watsonx Runtime, ModelMesh, and OpenShift’s native GPU orchestration, you get a production-grade stack that auto-scales, secures, and observably manages even multibillion-parameter transformers. By containerizing the model once and letting the platform orchestrate everything else—compute, rollout strategy, monitoring—you free data-science teams to iterate on prompts and fine-tuning while SREs sleep easier. Whether you’re deploying a concise 7-billion-parameter assistant or a sprawling 70-billion-parameter knowledge engine, this practical guide should help you ship reliable, elastic inference into production with confidence.

[#watsonx.ai](https://community.ibm.com/community/user/search?s=tags%3A%22watsonx.ai%22&executesearch=true)

0 comments

20 views

## Permalink

Copy

## 

https://community.ibm.com/community/user/blogs/anton-lucanus/2025/06/29/serving-llms-on-red-hat-openshift-a-practical-guid
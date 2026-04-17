# Source: ref-51

**URL:** https://medium.com/@shrishs/models-as-a-service-how-to-deploy-and-govern-llm-apis-on-openshift-ai-ed965acc7036
**Fetched:** 2026-04-17 17:54:52

---

# Models-as-a-Service: How to Deploy and Govern LLM APIs on OpenShift AI

[Shrishs](/@shrishs?source=post_page---byline--ed965acc7036---------------------------------------)

6 min read

·

Dec 9, 2025

--

[Listen](/m/signin?actionUrl=https%3A%2F%2Fmedium.com%2Fplans%3Fdimension%3Dpost_audio_button%26postId%3Ded965acc7036&operation=register&redirect=https%3A%2F%2Fmedium.com%2F%40shrishs%2Fmodels-as-a-service-how-to-deploy-and-govern-llm-apis-on-openshift-ai-ed965acc7036&source=---header_actions--ed965acc7036---------------------post_audio_button------------------)

Share

OpenShift AI 3.0, Red Hat has introduced [**Model-as-a-Service**](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.0/html-single/release_notes/index#developer-preview-features_relnotes) **(MaaS)** — a powerful pattern that solves a very real enterprise problem: how do you serve LLMs efficiently *and* enforce proper governance?

In this article, we break down how MaaS works behind the scenes and walk through one of its most important features: applying **user-level rate limits** to manage and protect your model workloads.

**Gateway API:**  
 Starting with Openshift [release 4.19](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/release_notes/index#ocp-4-19-networking-gateway-api-controller_release-notes), managing ingress traffic with Gateway API is fully supported and GA. Gateway API offers a standardized, Kubernetes-native way to control L4 and L7 traffic across the cluster.

**Red Hat Connectivity Link:**  
 Built on the [Kuadrant](https://kuadrant.io/) project, Connectivity Link provides the control plane for configuring Gateway API–based ingress. It adds Kubernetes-native policies for TLS, authentication, authorization, rate limiting, DNS, and multicluster health checks.

**llm-d**

Distributed Inference with llm-d is a Kubernetes-native, open-source framework designed for serving large language models (LLMs) at scale. One can use Distributed Inference with llm-d to simplify the deployment of generative AI, focusing on high performance and cost-effectiveness across various hardware accelerators.It Integrates into a standard Kubernetes environment, where it leverages specialized components like the Envoy proxy to handle networking and routing

In the next section we will

* Deploy the LLM Model using *Distributed Inference Server with llm-d*
* How does the Gateway object is created.
* How the RateLimiting Policy on this Gateway object(HTTPRoute) is applied using Kuadrant.

### Deploy the model using Distributed Inference

Prerequisites are defined [here](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.0/html/deploying_models/deploying_models#deploying-models-using-distributed-inference_rhoai-user).

* Configuring authentication with Red Hat Connectivity Link.

```
apiVersion: kuadrant.io/v1beta1  
kind: Kuadrant  
metadata:  
  name: kuadrant  
  namespace: kuadrant-system  
spec: {}
```

```
oc get pods -n kuadrant-system  
NAME                                  READY   STATUS    RESTARTS   AGE  
authorino-56df78f5fb-sbtvs            1/1     Running   0          77s  
limitador-limitador-546f7c5bb-bw4rx   1/1     Running   0          77s  
  
oc get svc -n kuadrant-system  
NAME                                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)              AGE  
authorino-authorino-authorization   ClusterIP   172.30.25.47     <none>        50051/TCP,5001/TCP   111s  
authorino-authorino-oidc            ClusterIP   172.30.165.172   <none>        8083/TCP             111s  
authorino-controller-metrics        ClusterIP   172.30.12.42     <none>        8080/TCP             111s  
limitador-limitador                 ClusterIP   None             <none>        8080/TCP,8081/TCP    111s
```

* Create the Gateway Class and Gateway

```
apiVersion: gateway.networking.k8s.io/v1  
kind: GatewayClass  
metadata:  
  annotations:  
    platform.opendatahub.io/instance.name: default-gateway  
    platform.opendatahub.io/instance.uid: 49d4f4d1-087f-4802-ac15-6cd2536747a5  
    platform.opendatahub.io/type: OpenShift AI Self-Managed  
    platform.opendatahub.io/version: 3.0.0  
  name: data-science-gateway-class  
  labels:  
    platform.opendatahub.io/part-of: gatewayconfig  
spec:  
  controllerName: openshift.io/gateway-controller/v1
```

```
apiVersion: gateway.networking.k8s.io/v1  
kind: Gateway  
metadata:  
  name: openshift-ai-inference  
  namespace: openshift-ingress  
  labels:  
    istio.io/rev: openshift-gateway  
    platform.opendatahub.io/part-of: gatewayconfig  
spec:  
  gatewayClassName: data-science-gateway-class  
  listeners:  
    - allowedRoutes:  
        namespaces:  
          from: Selector  
          selector:  
            matchExpressions:  
              - key: kubernetes.io/metadata.name  
                operator: In  
                values:  
                  - openshift-ingress  
                  - redhat-ods-applications  
                  - demo-ai  
      name: https  
      port: 443  
      protocol: HTTPS  
      tls:  
        certificateRefs:  
          - group: ''  
            kind: Secret  
            name: default-gateway-tls  
        mode: Terminate
```

* A corresponding svc is also created.

```
bash-3.2$ oc get svc openshift-ai-inference-data-science-gateway-class -n openshift-ingress  
NAME                                                TYPE           CLUSTER-IP      EXTERNAL-IP                                                             PORT(S)                         AGE  
openshift-ai-inference-data-science-gateway-class   LoadBalancer   172.30.43.253   ac1be10b222d54eb18ca5b48ad5d98b2-95298441.us-east-2.elb.amazonaws.com   15021:30782/TCP,443:32544/TCP   9h
```

* Above two objects automatically creates the authpolicy

```
apiVersion: kuadrant.io/v1  
kind: AuthPolicy  
metadata:  
  name: openshift-ai-inference-authn  
  namespace: openshift-ingress  
  ownerReferences:  
    - apiVersion: gateway.networking.k8s.io/v1  
      blockOwnerDeletion: true  
      controller: true  
      kind: Gateway  
      name: openshift-ai-inference  
  labels:  
    app.kubernetes.io/component: llminferenceservice-policies  
    app.kubernetes.io/managed-by: odh-model-controller  
    app.kubernetes.io/name: llminferenceservice-auth  
    app.kubernetes.io/part-of: llminferenceservice  
spec:  
  rules:  
    authentication:  
      kubernetes-user:  
        credentials: {}  
        kubernetesTokenReview:  
          audiences:  
            - 'https://kubernetes.default.svc'  
        metrics: false  
        priority: 0  
    authorization:  
      inference-access:  
        kubernetesSubjectAccessReview:  
          authorizationGroups:  
            expression: auth.identity.user.groups  
          resourceAttributes:  
            group:  
              value: serving.kserve.io  
            name:  
              expression: 'request.path.split("/")[2]'  
            namespace:  
              expression: 'request.path.split("/")[1]'  
            resource:  
              value: llminferenceservices  
            subresource: {}  
            verb:  
              value: get  
          user:  
            expression: auth.identity.user.username  
        metrics: false  
        priority: 1  
  targetRef:  
    group: gateway.networking.k8s.io  
    kind: Gateway  
    name: openshift-ai-inference
```

* Deploy a Model -*RedHatAI/Qwen3–8B-FP8-dynamic*

Press enter or click to view image in full size

* Select the Serving Runtime as -*Distributed Inference Server with llm-d*

Press enter or click to view image in full size

Press enter or click to view image in full size

* Distributed Inference Server with llm-d creates LLMInferenceService

```
apiVersion: serving.kserve.io/v1alpha1  
kind: LLMInferenceService  
metadata:  
  annotations:  
    opendatahub.io/connections: secret-mt1uy1  
    opendatahub.io/hardware-profile-name: gpu-small  
    opendatahub.io/hardware-profile-namespace: redhat-ods-applications  
    opendatahub.io/model-type: generative  
    openshift.io/display-name: RedHatAI/Qwen3-8B-FP8-dynamic  
  name: redhataiqwen3-8b-fp8-dynamic  
  namespace: demo-ai  
  finalizers:  
    - serving.kserve.io/llmisvc-finalizer  
  labels:  
    opendatahub.io/dashboard: 'true'  
    opendatahub.io/genai-asset: 'true'  
spec:  
  model:  
    name: redhataiqwen3-8b-fp8-dynamic  
    uri: 'hf://RedHatAI/Qwen3-8B-FP8-dynamic'  
  replicas: 1  
  router:  
    gateway: {}  
    route: {}  
    scheduler: {}  
  template:  
    containers:  
      - name: main  
        resources:  
          limits:  
            cpu: '2'  
            memory: 8Gi  
            nvidia.com/gpu: '1'  
          requests:  
            cpu: '2'  
            memory: 8Gi  
            nvidia.com/gpu: '1'  
    tolerations:  
      - effect: NoSchedule  
        key: nvidia.com/gpu  
        operator: Exists  
status:  
  addresses:  
    - url: 'https://ac1be10b222d54eb18ca5b48ad5d98b2-95298441.us-east-2.elb.amazonaws.com/demo-ai/redhataiqwen3-8b-fp8-dynamic'  
  conditions:  
    - lastTransitionTime: '2025-12-09T10:01:42Z'  
      severity: Info  
      status: 'True'  
      type: HTTPRoutesReady  
    - lastTransitionTime: '2025-12-09T10:01:42Z'  
      severity: Info  
      status: 'True'  
      type: InferencePoolReady  
    - lastTransitionTime: '2025-12-09T18:48:00Z'  
      severity: Info  
      status: 'True'  
      type: MainWorkloadReady  
    - lastTransitionTime: '2025-12-09T09:51:17Z'  
      severity: Info  
      status: 'True'  
      type: PresetsCombined  
    - lastTransitionTime: '2025-12-09T18:48:00Z'  
      status: 'True'  
      type: Ready  
    - lastTransitionTime: '2025-12-09T10:01:42Z'  
      status: 'True'  
      type: RouterReady  
    - lastTransitionTime: '2025-12-09T09:51:54Z'  
      severity: Info  
      status: 'True'  
      type: SchedulerWorkloadReady  
    - lastTransitionTime: '2025-12-09T18:48:00Z'  
      status: 'True'  
      type: WorkloadsReady  
  observedGeneration: 2  
  url: 'https://ac1be10b222d54eb18ca5b48ad5d98b2-95298441.us-east-2.elb.amazonaws.com/demo-ai/redhataiqwen3-8b-fp8-dynamic'
```

* Corrsponding HTTPRoute is also created

```
apiVersion: gateway.networking.k8s.io/v1  
kind: HTTPRoute  
metadata:  
  name: redhataiqwen3-8b-fp8-dynamic-kserve-route  
  namespace: demo-ai  
  ownerReferences:  
    - apiVersion: serving.kserve.io/v1alpha1  
      blockOwnerDeletion: true  
      controller: true  
      kind: LLMInferenceService  
      name: redhataiqwen3-8b-fp8-dynamic  
      uid: ea1c8538-30a2-43b5-b515-50c8bb97de80  
  labels:  
    app.kubernetes.io/component: llminferenceservice-router  
    app.kubernetes.io/name: redhataiqwen3-8b-fp8-dynamic  
    app.kubernetes.io/part-of: llminferenceservice  
spec:  
  parentRefs:  
    - group: gateway.networking.k8s.io  
      kind: Gateway  
      name: openshift-ai-inference  
      namespace: openshift-ingress  
  rules:  
    - backendRefs:  
        - group: inference.networking.x-k8s.io  
          kind: InferencePool  
          name: redhataiqwen3-8b-fp8-dynamic-inference-pool  
          port: 8000  
          weight: 1  
      filters:  
        - type: URLRewrite  
          urlRewrite:  
            path:  
              replacePrefixMatch: /v1/completions  
              type: ReplacePrefixMatch  
      matches:  
        - path:  
            type: PathPrefix  
            value: /demo-ai/redhataiqwen3-8b-fp8-dynamic/v1/completions  
      timeouts:  
        backendRequest: 0s  
        request: 0s  
    - backendRefs:  
        - group: inference.networking.x-k8s.io  
          kind: InferencePool  
          name: redhataiqwen3-8b-fp8-dynamic-inference-pool  
          port: 8000  
          weight: 1  
      filters:  
        - type: URLRewrite  
          urlRewrite:  
            path:  
              replacePrefixMatch: /v1/chat/completions  
              type: ReplacePrefixMatch  
      matches:  
        - path:  
            type: PathPrefix  
            value: /demo-ai/redhataiqwen3-8b-fp8-dynamic/v1/chat/completions  
      timeouts:  
        backendRequest: 0s  
        request: 0s  
    - backendRefs:  
        - group: ''  
          kind: Service  
          name: redhataiqwen3-8b-fp8-dynamic-kserve-workload-svc  
          port: 8000  
          weight: 1  
      filters:  
        - type: URLRewrite  
          urlRewrite:  
            path:  
              replacePrefixMatch: /  
              type: ReplacePrefixMatch  
      matches:  
        - path:  
            type: PathPrefix  
            value: /demo-ai/redhataiqwen3-8b-fp8-dynamic  
      timeouts:  
        backendRequest: 0s  
        request: 0s  
status:  
  parents:  
    - conditions:  
        - lastTransitionTime: '2025-12-09T09:51:17Z'  
          message: 'Object affected by AuthPolicy [openshift-ingress/openshift-ai-inference-authn]'  
          observedGeneration: 1  
          reason: Accepted  
          status: 'True'  
          type: kuadrant.io/AuthPolicyAffected  
        - lastTransitionTime: '2025-12-09T14:51:10Z'  
          message: 'Object affected by RateLimitPolicy [demo-ai/redhataiqwen3-8b-fp8-dynamic-rl]'  
          observedGeneration: 1  
          reason: Accepted  
          status: 'True'  
          type: kuadrant.io/RateLimitPolicyAffected  
      controllerName: kuadrant.io/policy-controller  
      parentRef:  
        group: gateway.networking.k8s.io  
        kind: Gateway  
        name: openshift-ai-inference  
        namespace: openshift-ingress  
    - conditions:  
        - lastTransitionTime: '2025-12-09T10:01:32Z'  
          message: Route was valid  
          observedGeneration: 1  
          reason: Accepted  
          status: 'True'  
          type: Accepted  
        - lastTransitionTime: '2025-12-09T09:51:17Z'  
          message: All references resolved  
          observedGeneration: 1  
          reason: ResolvedRefs  
          status: 'True'  
          type: ResolvedRefs  
      controllerName: openshift.io/gateway-controller/v1  
      parentRef:  
        group: gateway.networking.k8s.io  
        kind: Gateway  
        name: openshift-ai-inference  
        namespace: openshift-ingress
```

* Test the inference service

```
TOKEN=$(oc whoami -t)  
curl -k     https://ac1be10b222d54eb18ca5b48ad5d98b2-95298441.us-east-2.elb.amazonaws.com/demo-ai/redhataiqwen3-8b-fp8-dynamic/v1/completions     -H "Authorization: Bearer $TOKEN"     -H "Content-Type: application/json"     -d '{"model":"redhataiqwen3-8b-fp8-dynamic","prompt":"capital of France","max_tokens":20}'    
{"choices":[{"finish_reason":"length","index":0,"logprobs":null,"prompt_logprobs":null,"prompt_token_ids":null,"stop_reason":null,"text":" is Paris, and the capital of Italy is Rome.  The capital of Spain is Madrid. ","token_ids":null}],"created":1765307782,"id":"cmpl-3308ccf3-dca3-494c-acef-3fa7f86ac282","kv_transfer_params":null,"model":"redhataiqwen3-8b-fp8-dynamic","object":"text_completion","service_tier":null,"system_fingerprint":null,"usage":{"completion_tokens":20,"prompt_tokens":3,"prompt_tokens_details":null,"total_tokens":23}}
```

### RateLimiting

* Creat a RateLimitPolicy

```
apiVersion: kuadrant.io/v1  
kind: RateLimitPolicy  
metadata:  
  name: redhataiqwen3-8b-fp8-dynamic-rl  
  namespace: demo-ai  
spec:  
  targetRef:  
    group: gateway.networking.k8s.io  
    kind: HTTPRoute  
    name: redhataiqwen3-8b-fp8-dynamic-kserve-route  
  
  limits:  
    per-user:  
      rates:  
        - limit: 5      # 5 requests per minute per user  
          window: 1m  
      counters:  
        - expression: "auth.identity.user.username"
```

* Try the request more tan 5 time in a min.And it will deny the request ny saying “**Too Many Requests**”

```
bash-3.2$ curl -k     https://ac1be10b222d54eb18ca5b48ad5d98b2-95298441.us-east-2.elb.amazonaws.com/demo-ai/redhataiqwen3-8b-fp8-dynamic/v1/completions     -H "Authorization: Bearer $TOKEN"     -H "Content-Type: application/json"     -d '{"model":"redhataiqwen3-8b-fp8-dynamic","prompt":"capital of France","max_tokens":20}'    
Too Many Requests
```

What’s Next: In the next article we will be configuring [different Tiers](https://opendatahub-io.github.io/maas-billing/0.0.1/configuration-and-management/tier-configuration/#1-configure-tier-mapping)
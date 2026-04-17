# Batch 02 Findings: Single-model serving architecture (KServe, vLLM, storage, accelerators)

**Sources analyzed:** ref-08, ref-12, ref-27  
**Date:** 2026-04-17

**Original article:** `research/openshift-ai-llm-deployment/sources/original-article.md` (Jared Burck, “Enterprise Generative AI…”, 2026-03-18)

**Architecture claims under review:**

1. KServe-based single-model serving with Knative (OpenShift Serverless) and Istio (OpenShift Service Mesh).
2. vLLM as primary runtime with PagedAttention for KV-cache / memory efficiency.
3. ModelCar as an OCI-container approach alternative to S3 for model artifacts.
4. `AcceleratorProfile` CR for mapping accelerators (e.g. `nvidia.com/gpu`) for dashboard selection.
5. `ServingRuntime` and `InferenceService` CRDs for defining runtimes and deploying models.

---

## ref-08: Red Hat Documentation — RHOAI Self-Managed 2.16, “Serving large models”

**Article claims:** The single-model stack is KServe-centric; OpenShift Serverless (Knative) supplies serverless scaling; OpenShift Service Mesh (Istio) handles traffic, mTLS, and advanced routing; deployments use `ServingRuntime` / `InferenceService`; vLLM is the high-throughput path with PagedAttention; ModelCar-style OCI packaging is a first-class alternative to S3; accelerator profiles bridge hardware to the UI.

**Source actually says:**

- Explicitly defines a **single-model serving platform based on KServe**, with each model on its own server (Chapter 3 intro, §3.1).
- Lists stack components: **KServe** (CRD orchestration, runtimes, lifecycle, storage, networking), **Red Hat OpenShift Serverless** (Knative-based), **Red Hat OpenShift Service Mesh** (Istio-based traffic management and policies) (§3.2).
- States model-serving configuration is defined by the **`ServingRuntime`** and **`InferenceService`** CRDs, with detailed YAML examples including Knative passthrough and **Istio sidecar injection** annotations on `InferenceService` (§3.6).
- Describes **vLLM ServingRuntime for KServe** as a **“high-throughput and memory-efficient inference and serving runtime”** and documents OpenAI-compatible endpoints; it does **not** name **PagedAttention** in the captured chapter.
- Documents **OCI images as an alternative to S3/URI** for model storage (`storageUri: oci://…`), benefits (startup time, disk, pre-fetched images), and labels the feature **Technology Preview in 2.16** with SLA caveats (§3.12.8). Wording is **“OCI containers for model storage”**, not the marketing term **“ModelCar.”**
- For **Intel Gaudi** and **AMD GPU** vLLM variants, prerequisites include installing the respective operator and **“configuring an accelerator profile,”** with a link to *Working with accelerator profiles*; the dashboard deploy flow also references selecting an accelerator when a profile exists (§3.12.4, §3.12.9).
- Adds important nuance the article only partially covers: **default serverless mode depends on the OpenShift Serverless Operator**; **raw deployment mode** exists (Limited Availability, approval-gated) and **does not require** Serverless; raw mode on SNO can **disable Service Mesh** in `DataScienceCluster` (§3.10–§3.11).

**Verdict:** **VERIFIED WITH CAVEATS**

**Details:** Claims 1, 4 (accelerator profile as operational requirement / UI bridge), and 5 are directly supported. Claim 3 is supported for **OCI-in-image** workflows and as an **S3 alternative**, with two caveats: the doc uses **OCI container storage**, not the **ModelCar** brand name, and **Technology Preview** status contradicts any implication of fully supported GA behavior. Claim 2 is **only partly** supported: vLLM’s **efficiency** is stated, but **PagedAttention** is **not stated** in this source file.

**Impact:** The article’s architectural stack description aligns strongly with Red Hat’s own 2.16 serving chapter; the main credibility gaps here are **optional raw mode / mesh-off** paths and **absence of PagedAttention** wording in the cited doc excerpt.

---

## ref-12: Piotr Minkowski — “OpenShift AI with vLLM and Spring AI” (May 2025)

**Article claims:** Same five-point bundle as above, especially practical use of **ModelCar** / OCI images, **KServe + Knative + Istio**, **AcceleratorProfile**, and **`ServingRuntime` + `InferenceService`** for real deployments.

**Source actually says:**

- States OpenShift AI includes a **single-model serving platform based on KServe**; runtimes are how models are served; **only vLLM** is called out among preinstalled runtimes as **OpenAI REST API compatible** (therefore chosen for Spring AI).
- Prerequisites: install **OpenShift Serverless** and **OpenShift Service Mesh**; **“KServe uses Knative to scale models on demand and integrates with Istio to secure model routing and versioning.”**
- Walks through creating an **`AcceleratorProfile`** (`dashboard.opendatahub.io/v1`) with `spec.identifier: nvidia.com/gpu`, aligned with `opendatahub.io/recommended-accelerators` on `ServingRuntime`.
- Uses **KServe ModelCar** phrasing: serve **“directly from a container without using the S3 bucket,”** with `storageUri: 'oci://quay.io/redhat-ai-services/modelcar-catalog:…'` on **`InferenceService`**; references Red Hat Developer **ModelCar** article and **`quay.io/.../modelcar-catalog`** images.
- Provides concrete **`ServingRuntime`** and **`InferenceService`** manifests; notes models run as **Knative `Service`**, external exposure via **Knative Route**, `serving.kserve.io/deploymentMode: Serverless`, Istio sidecar annotations.
- Discusses **vLLM** integration and OpenAI-compatible Spring AI config; **does not** explain **PagedAttention** or KV-cache mechanics.

**Verdict:** **VERIFIED WITH CAVEATS**

**Details:** Strong independent confirmation for claims **1, 3 (ModelCar / OCI path), 4, and 5** in a field-style walkthrough. Caveats: (a) **blog / practitioner content**, not authoritative product docs; (b) absolute statement that **only vLLM** among preinstalled runtimes is OpenAI-compatible is **narrower** than the original article, which still documents Caikit/TGIS (with proxy caveats)—accurate for the author’s integration goal but not a full catalog statement; (c) **PagedAttention (claim 2)** is **not present**.

**Impact:** Corroborates the article’s “happy path” story (Serverless + Service Mesh + vLLM + OCI model images + accelerator profile + KServe CRDs) from someone who actually wired Spring AI to it; does not substantiate the **PagedAttention** deep dive.

---

## ref-27: ai-on-openshift.io — “LLM Serving”

**Article claims:** Architecture centered on **KServe single-model serving**, **Knative/Istio mesh**, **vLLM + PagedAttention**, **ModelCar vs S3**, **`AcceleratorProfile`**, **`ServingRuntime` / `InferenceService`**.

**Source actually says:**

- High-level orientation to **LLM serving on OpenShift** with **ODH or RHOAI**, pointing to the **`llm-on-openshift`** GitHub repo for recipes.
- Distinguishes **“Single Stack Model Serving”** vs **standalone deployments**; lists **vLLM** and **Hugging Face TGI** as importable custom runtimes alongside **Caikit+TGIS / TGIS** built-ins.
- Notes different servers expose **REST vs gRPC**, different APIs, and **“some solutions offering an OpenAI compatible”** API—**no** statement that vLLM is the sole OpenAI-compatible option.
- **Does not** name **KServe**, **Knative**, **Istio**, **Service Mesh**, **InferenceService**, **ServingRuntime**, **AcceleratorProfile**, **ModelCar**, **OCI**, or **PagedAttention**.

**Verdict:** **UNSUPPORTED** (for the specific five architecture claims)

**Details:** This page is a **curated index / explainer** and repo pointer. It supports only very generic ideas (LLM serving on OpenShift; multiple server choices; OpenAI compatibility exists somewhere in the ecosystem). It **cannot** be used to verify the article’s detailed **platform stack** or **CRD-level** architecture.

**Impact:** Listing ref-27 in works cited would **not**, on its own, justify the article’s precise KServe/Knative/Istio/ModelCar/AcceleratorProfile narrative; it backs **broad “LLM on OpenShift”** context only.

---

## Batch Summary

- **Verified:** 0 (no source fully substantiates all five claims without qualification)
- **Verified with caveats:** 2 (ref-08, ref-12)
- **Problematic:** 0
- **Unsupported:** 1 (ref-27 for the targeted architecture claims)
- **Unverifiable:** 0 (within this batch; PagedAttention remains unverified *here* but is widely documented elsewhere—not part of these three files)

**Key pattern in this batch:** **Red Hat 2.16 docs (ref-08)** and the **Minkowski blog (ref-12)** mutually reinforce the article’s **KServe + Serverless + Service Mesh + ServingRuntime/InferenceService + OCI model images + accelerator profiles** storyline. **Gaps:** (1) **PagedAttention** is asserted in the original article but **does not appear** in ref-08 or ref-12; (2) **“ModelCar”** as a branded concept is **explicit in ref-12**, **implicit** (“OCI containers for model storage”) in ref-08; (3) ref-08 documents **alternatives** (raw deployment, mesh optional in that path) that the article’s sweeping “composite stack” prose tends to **background**; (4) **ref-27** is the wrong granularity to defend the article’s architecture section.

*AI disclosure: This assessment was drafted with AI assistance; claims were checked against the local source copies in `research/openshift-ai-llm-deployment/sources/`.*

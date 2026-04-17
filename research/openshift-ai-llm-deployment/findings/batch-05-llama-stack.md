# Batch 05 Findings: Llama Stack (RHOAI docs)

**Sources analyzed:** ref-25, ref-48, ref-47  
**Date:** 2026-04-17

**Original article:** `research/openshift-ai-llm-deployment/sources/original-article.md` (section on MCP and Llama Stack / OpenAI compatibility).

**Claims under review (from the article):**

1. Deployment via `LlamaStackDistribution` custom resource.  
2. OpenAI-compatible APIs exposed under `/v1/openai/v1`.  
3. Responses API with `file_search` for RAG.  
4. Milvus for vector storage.  
5. Schema parity with OpenAI.

---

## ref-25: Red Hat OpenShift AI Self-Managed 2.25 — *Working with Llama Stack* (HTML single)

**URL (source file header):** https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html-single/working_with_llama_stack/index

**Article claims:** Llama Stack is integrated with OpenShift AI; deployment uses `LlamaStackDistribution`; OpenAI-compatible layer at `/v1/openai/v1`; Responses API with `file_search` for RAG; Milvus for vectors; “absolute schema parity”; framed as strategic for enterprise / migration from OpenAI SDKs (with footnote to this doc).

**Source actually says:**

- **Maturity:** Llama Stack integration in RHOAI **2.25** is explicitly a **Technology Preview**. Red Hat states it is **not** covered by production SLAs, may be incomplete, and **is not recommended for production**. The same **Important** notice is repeated for the RAG deployment chapter.  
- **Claim 1 (`LlamaStackDistribution`):** Confirmed. The overview lists integration “by using the `LlamaStackDistribution` custom resource,” and later chapters document creating `LlamaStackDistribution` instances (including YAML examples, `apiVersion: llamastack.io/v1alpha1`).  
- **Claim 2 (`/v1/openai/v1`):** Confirmed. The doc instructs setting the client `base_url` to the Llama Stack OpenAI path **`/v1/openai/v1`** and lists concrete endpoints under that prefix (e.g. `.../chat/completions`, `.../responses`).  
- **Claim 3 (Responses API + `file_search`):** Partially confirmed with stronger caveats than the article’s single “experimental” word. The source describes using the Responses API with the **`file_search`** tool for RAG, but assigns the Responses API **Developer Preview** support level, labels it **experimental**, notes **active development**, warns that **endpoints and parameters may change**, and states it is **for testing and feedback only** and **not recommended for production**.  
- **Claim 4 (Milvus):** Confirmed. Vector storage is **“primarily Milvus”**; VectorIO providers include **`inline::milvus`** and **`remote::milvus`** (Technology Preview in the provider table). The guide distinguishes **inline Milvus Lite** (embedded, limited persistence) vs **remote Milvus** (recommended for production-grade RAG *from a data architecture perspective* — not the same as Red Hat product GA for Llama Stack overall).  
- **Claim 5 (schema parity):** Mostly confirmed with nuance. The source states **“Schema parity: Request and response fields follow OpenAI data structures”** and that paths align with OpenAI. It also **requires** updating client configuration so `base_url` points at the **deployment’s Llama Stack route** — i.e. clients are not literally “unchanged” if they still point at `api.openai.com`; they must be retargeted. Individual APIs carry **Technology Preview** or **Developer Preview** (e.g. Vector Store Files API **Developer Preview**).

**Verdict:** **VERIFIED WITH CAVEATS**

**Details:** Factual alignment on CR name, path prefix, Milvus-centric RAG, and OpenAI-oriented schemas is strong. Gaps vs a “production feature” reading: repeated **Technology Preview** disclaimers for Llama Stack; **Developer Preview** / non-production guidance for **Responses API**; per-API support tiers; and the explicit **base_url** reconfiguration note vs any implication of zero client changes.

**Impact:** The article’s inline citation to ref-25 is appropriate for *mechanism* descriptions, but **enterprise readers relying on the conclusion** (broader “secure, governed” production narrative) could **underweight** Technology Preview / Developer Preview limits unless they read the body’s TP sentence and the Responses API caveat together with Red Hat’s non-production recommendations.

---

## ref-48: Red Hat OpenShift AI Self-Managed 2.25 — *Chapter 1. Overview of Llama Stack*

**URL (source file header):** https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/working_with_llama_stack/overview-of-llama-stack_rag

**Article claims:** Same cluster of claims as for ref-25 (subset of the same documentation set).

**Source actually says:** Content in the captured ref-48 file **matches** the corresponding **Chapter 1 / overview and OpenAI compatibility** portions of ref-25: **Technology Preview** warning for Llama Stack in 2.25; components including **`LlamaStackDistribution`**; **`/v1/openai/v1`**; files/vector stores and **Responses API** with **`file_search`**; **schema parity** and standardized endpoints; per-API **Technology Preview** vs **Developer Preview** (Responses API **Developer Preview** + experimental / not for production note); provider table including **Milvus** as Technology Preview.

**Verdict:** **VERIFIED WITH CAVEATS** (same as ref-25 for overlapping material)

**Details:** ref-48 is effectively a **duplicate slice** of ref-25 for the claims checked; no contradiction between the two artifacts.

**Impact:** Corroborates ref-25; does not resolve the **support-status** tension on its own because it carries the **same** TP/DP disclaimers.

---

## ref-47: Captured “Working with Llama Stack” fetch (metadata mismatch)

**URL (source file header):** https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.0/html-single/working_with_llama_stack/index

**Article claims:** (via works cited ref 47) RHOAI documentation for **3.0** *Working with Llama Stack* as a reference for current product behavior.

**Source actually says:** The saved `ref-47.md` body is **not** the in-depth Llama Stack guide. It presents **Red Hat OpenShift AI Self-Managed 3.4** hub navigation (“Early Access,” release notes, etc.) and only **brief** Llama-related blurbs, for example: **“Build AI/Agentic Applications with Llama Stack”** and **“Deploy the RAG stack for projects”** (activate operator, OpenAI-compatible RAG APIs, vector store, secure endpoints). There are **no** excerpts in this file for **`LlamaStackDistribution`**, **`/v1/openai/v1`**, **Responses API**, **Milvus**, **schema parity**, or **Technology Preview / GA** language.

**Verdict:** **UNVERIFIABLE** (from this artifact) for claims 1–5 and for **support tier** comparison on 3.0/3.x; **UNSUPPORTED** as evidence that the **3.0** guide text says what ref-25/ref-48 say, because the **captured content does not match** the cited 3.0 deep-doc expectation.

**Details:** For verification, **re-fetch** or replace `ref-47.md` with the actual **Working with Llama Stack** body for the intended version (3.0 or current 3.x chapter), or use ref-25/ref-48 for **substantive** claim-by-claim checks.

**Impact:** The article’s bibliography entry for ref-47 **cannot be audited** against the stored file for the five technical claims; doing so would require a corrected source capture.

---

## Batch Summary

- **Verified:** 0 (no claim passes without material support-status or client-config caveats in the primary docs)  
- **Verified with caveats:** 2 (ref-25, ref-48 — strong factual match, important maturity and production-use disclaimers)  
- **Problematic:** 0 (sources do not contradict the mechanisms; they qualify production readiness)  
- **Unverifiable:** 1 (ref-47 artifact insufficient / version mismatch)  
- **Key pattern in this batch:** Red Hat’s **2.25** Llama Stack documentation **substantiates** the article’s **technical mechanisms** (CR, path, Milvus, OpenAI-shaped APIs) but **contradicts a “treat as GA production platform” reading** via explicit **Technology Preview** and **Developer Preview** / experimental language. The **original article partially discloses** Technology Preview for Llama Stack in the same paragraph as ref-25, yet still uses **strong enterprise outcome language**; readers should cross-check **per-API** support levels (e.g. Responses vs Chat Completions) and the **base_url** requirement.

---

*AI disclosure: This batch assessment was produced with AI assistance for structured comparison of the cited sources to the original article.*

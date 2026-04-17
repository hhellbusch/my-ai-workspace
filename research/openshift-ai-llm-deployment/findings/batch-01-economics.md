# Batch 01 Findings: Economics and TCO

**Sources analyzed:** ref-01, ref-60, ref-62 (ref-61 unavailable)  
**Date:** 2026-04-17

---

## ref-01: A Cost-Benefit Analysis of On-Premise Large Language Model Deployment: Breaking Even with Commercial LLM Services (arXiv:2509.18101v3)

**Article claims:** Commercial LLM API costs are operating expenditure, billed on a consumption basis per million tokens of input and output (per article’s mapping to ref-01).

**Source actually says:** Section IV (“Commercial LLM Pricing Models”) states that the API subscription model “charges per processed token (input and output),” with costs that “vary by usage, batching, and model choice,” and Table I lists API pricing as separate input/output rates in USD per 1M tokens. The paper’s API cost model (Equations 4–6) scales monthly spend with token throughput using per-million-token input and output prices and a fixed 1:2 input:output token ratio for normalization—not a universal bill shape for every vendor contract.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** The source supports the core idea that public API pricing is usage-linked and expressed per million tokens, with distinct input and output rates. It does not use the exact framing “pure OpEx” for APIs (it focuses on pricing mechanics and TCO math). Qualifiers the article omits include batching, model tier choice, and the paper’s explicit 1:2 input:output assumption when comparing to local throughput. The paper also notes enterprise-relevant complexity (hybrid strategies, provider price dispersion) elsewhere, which undercuts any implication that billing is uniformly “strict” or simple in real procurement.

**Impact:** The article’s directional statement is consistent with ref-01, but words like “strictly” and “pure OpEx” overstate the paper’s precision and ignore caveats (batching, tiering, workload mix). Credibility is mostly intact if phrased as “typically metered per token / per million tokens with separate input/output rates.”

---

## ref-60: IntuitionLabs — LLM API Pricing Comparison (2025/2026 PDF extract)

**Article claims:** Self-hosting is a “fundamental requirement for financial viability” at scale, with ref-60 among the citations (alongside ref-62).

**Source actually says:** The document is a vendor-neutral-style survey of public list prices for major LLM APIs (OpenAI, Gemini, Claude, Grok, DeepSeek): token-based “pay-as-you-go” billing, wide price dispersion by model tier, caching and long-context surcharges, batch discounts, tiered volume pricing (e.g., Gemini above 200K input tokens), and non-token charges (e.g., grounded search). It recommends continuous repricing checks, multi-provider strategies, and hybrid routing (cheap models for bulk work, expensive models for edge cases). It states some providers experiment with non-token billing for certain APIs. Marketing footer mentions private/on-premise offerings for regulated industries but does not argue mathematically that self-hosting is required for financial viability at scale.

**Verdict:** UNSUPPORTED

**Details:** Nothing in the analyzed text establishes self-hosting as a *necessary* condition for financial viability; the thrust is comparative API economics and optimization tactics. If anything, the report highlights paths (DeepSeek, Flash tiers, fast Grok, enterprise discounts) that can keep API-only stacks economically workable depending on workload and risk tolerance. Using ref-60 to warrant “fundamental requirement” language is therefore not evidenced by this source.

**Impact:** This weakens the article’s rhetorical coupling of ref-60 to a strong necessity claim. ref-60 is better cited for “API price dispersion, token metering, and operator tactics,” not for an imperative about self-hosting.

---

## ref-62: Lenovo Press LP2368 — On-Premise vs Cloud Generative AI TCO (2026 Edition)

**Article claims:** (a) On-prem CapEx can achieve ROI in under four months (ref-62); (b) “up to” ~18× lower cost per million tokens vs sustained use of premium Model-as-a-Service APIs (ref-62); (c) self-hosting as financially imperative at scale (ref-62 paired with ref-60).

**Source actually says:**  
- **Breakeven / velocity:** The abstract and executive summary state breakeven in under four months for “high-utilization workloads,” with an explicit threshold “utilization >20%” for the “Accelerated Breakeven Velocity” bullet. Case 1 (Config A: 8× H100 on-prem vs Azure ND96isr H100 v5) computes **~3.7 months** breakeven vs **on-demand** cloud, **~6 months** vs 1-year reserved, **~9.3 months** vs 3-year reserved, **~10.4 months** vs 5-year reserved. The conclusion repeats **“<4 months”** against **on-demand** pricing for high utilization—not a blanket statement for all cloud commitment types.  
- **18×:** Token Economics “Scenario B: Proprietary API Comparison” compares **GPT-5 mini API** at “~$2.00 / 1M output tokens” to **Lenovo Config A** serving a **70B** model at **$0.11 / 1M output tokens**, yielding **“18x Cheaper”** on-prem. The abstract/conclusion summarize **up to 18×** vs “frontier Model-as-a-Service APIs” alongside **8×** vs cloud IaaS for another scenario.  
- **Strategic framing:** The whitepaper is Lenovo-specific TCO marketing: chosen configs, 5-year amortization, MLPerf throughput assumptions, US commercial electricity, exclusion of some cloud costs (storage, egress, support) “to demonstrate that Lenovo infrastructure remains superior even under the most charitable cloud assumptions,” and Dec 2025 / Jan 2026 price snapshots.

**Verdict:** VERIFIED WITH CAVEATS

**Details:**  
- **Under four months:** Supported only for the documented scenario class (sustained/high utilization, and in the detailed case, **vs cloud on-demand** for a specific 8×H100 vs Azure pairing). The article risks overgeneralization if it presents “under four months ROI” without naming utilization, commitment type, and hardware/cloud pairing. “ROI” vs Lenovo’s “breakeven” terminology is close but not identical (the paper amortizes CapEx over five years for token $/1M elsewhere).  
- **18× vs “premium” APIs:** The numeric **18×** is reproduced faithfully from the whitepaper’s Scenario B, but the **comparator named in the source is GPT-5 mini**, a **budget/efficient** tier in the same industry pricing surveys—not an obvious “premium” flagship tier (e.g., high-priced Pro/Opus-class list rates). If the article states “premium MaaS” without naming GPT-5 mini / output-only framing / 70B on 8×H100 assumptions, that is **cherry-picked framing** relative to the actual footnoted comparison in ref-62.  
- **Financial imperative:** ref-62’s conclusion uses strong marketing language (“financial imperative,” “owning the factory”) for **sustained inference / fine-tuning** on Lenovo TCO assumptions—**opinion/positioning**, not independent proof. It is still more on-point than ref-60 for a self-hosting economics argument.

**Impact:** ref-62 credibly backs “sub-four-month breakeven is plausible under stated vendor assumptions” and “large multipliers vs some API list economics are claimed in vendor scenario math.” Article credibility suffers if readers infer universal ROI timelines or think the 18× figure was computed against premium-tier flagship APIs without reading Lenovo’s fine print.

---

## ref-61: braincuber.com analysis (not retrieved — HTTP 429)

**Article claims:** (1) Strict breakeven at ~11 billion tokens/month (~500 million/day); (5) a GPU at ~10% load inflates per-token inference cost by ~10×.

**Source actually says:** *Source file unavailable in this research corpus; content not analyzed.*

**Verdict:** UNVERIFIABLE

**Details:** No cross-check against the article’s primary citation for these two quantitative claims is possible from this batch. For orientation only (not a substitute for ref-61): ref-01 frames break-even in **months** across model/API scenarios and mentions **≥50M tokens/month** as a high-volume regime in its introduction—it does **not** corroborate an **11B tokens/month** “strict” breakeven threshold.

**Impact:** Assertions (1) and (5) should be treated as **uncited for verification purposes** until ref-61 is retrieved or replaced with an accessible primary source; ref-01 cannot fill that gap without over-claiming.

---

## Batch Summary

- **Verified:** 0  
- **Verified with caveats:** 2 (ref-01; ref-62 — especially if the article narrows Lenovo’s conditions when quoting)  
- **Problematic:** 1 (ref-60 cited for a financial-viability *necessity* the PDF does not establish; separately, **18× vs “premium” APIs** is easy to over-read unless the article names Lenovo’s **GPT-5 mini / $/M output** baseline)  
- **Unverifiable:** 1 unavailable source (ref-61) covering **2** dependent numeric claims (11B-token/month breakeven; 10% GPU load → ~10× per-token cost)  

- **Key pattern in this batch:** The article mixes **peer-reviewed / analytical** material (ref-01) with **vendor TCO collateral** (ref-62) and a **commercial pricing digest** (ref-60). Numbers like **18×** and **<4 months** are traceable to ref-62 but carry **heavy scenario dependence** (hardware config, utilization, cloud price type, specific API SKU). A second pattern is **category drift**: “premium MaaS” in prose vs **budget-tier API** in the cited scenario. Third, **ref-61-dependent quantitative thresholds** cannot be validated from the provided corpus.

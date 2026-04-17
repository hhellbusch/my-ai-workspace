# Batch 07 Findings: Disconnected install, hyperscalers, and support boundaries

**Sources analyzed:** ref-34, ref-38, ref-43, ref-41  
**Date:** 2026-04-17

---

## ref-34: Red Hat Docs — Installing and uninstalling OpenShift AI Self-Managed in a disconnected environment (2.25)

**Article claims:** Disconnected RHOAI uses a connected bastion-style host with `oc-mirror` v2, `imageset-config.yaml`, tarball transfer, internal mirror registry, and cluster redirection via `ImageContentSourcePolicy` / `ImageDigestMirrorSet`; mirror archive about 75 GB; STIG-related umask 0022 for catalog builds; RHOAI runs on managed offerings including ROSA and ARO; NVIDIA workloads use the GPU Operator (mirrored). Model weights at tens-to-hundreds of GB and ModelCar-style registry promotion are part of the broader narrative.

**Source actually says:** Chapter 1 states OpenShift AI Self-Managed is available on OpenShift Container Platform and on Red Hat–managed cloud environments including OpenShift Dedicated (CCS), **ROSA (classic or HCP)**, and **Microsoft Azure Red Hat OpenShift**. Disconnected install uses a **private registry** to mirror images; high-level steps include mirroring with **`oc-mirror` v2** (v1 deprecated), optional **mirror registry for Red Hat OpenShift**, `imageset-config.yaml`, `file://` then `docker://<registry>`, verification that total tarball size is **around 75 GB**, and generated **`ImageDigestMirrorSet`** plus **`CatalogSource`** under `working-dir/cluster-resources`. The doc refers to an **Internet-connected “mirroring machine”** (Linux, **100 GB** free space), not the word “bastion.” Prerequisites: mirror **NVIDIA GPU Operator** if using NVIDIA GPUs; mirror **OpenShift Serverless** and **Service Mesh** for single-model serving; mirror **Ray** image for distributed workloads. **Object storage** (S3-compatible, on the disconnected network) remains **required** for single- / multi-model serving “to deploy stored models,” pipelines, and other components—**no mention of ModelCar**, **STIG**, or **umask** in this capture.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** ROSA/ARO as supported deployment targets for the product family: **verified** in Chapter 1. Disconnected mirroring workflow, ~75 GB check, `oc-mirror` v2, IDMS/catalog resources: **verified**; article’s optional **ImageContentSourcePolicy** wording is **narrowed** here to the generated **ImageDigestMirrorSet** (plus CatalogSource) in the procedure shown. **“Bastion host”** is **reasonable shorthand** but **not the doc term** (“mirroring machine”). **STIG / 0077 / 0022:** **not present** in ref-34 (the article’s footnote for that point is ref-36 in the works cited, not ref-34). **ModelCar images in the mirror registry:** **not stated**; practitioners would infer **additionalImages** / custom image inclusion, but large model OCI layers are **not** discussed. **Operational gaps vs article:** minimum **2 workers @ 8 CPU / 32 GiB** (SNO 32 CPU / 128 GiB); **no Open Data Hub** on cluster; **no second RHOAI instance**; **Operator vs Add-on** not on same cluster; **Authorino** disconnected upgrade caveat (RHOAIENG-24786) appears later in the doc; **FIPS** pipeline image base (UBI 9 / RHEL 9); optional NVIDIA registry domains for custom CUDA builds.

**Impact:** The article’s disconnected section is **largely aligned** with 2.25 disconnected install mechanics where it cites the same doc family, but **over-specific** on bastion naming and **does not reflect** ref-34’s continued **object storage requirement** for model deployment paths—important context next to a **ModelCar eliminates S3** storyline. **STIG/umask** should **not** be attributed to ref-34.

---

## ref-38: Red Hat Docs — Deploying OpenShift AI in a disconnected environment (3.3)

**Article claims:** Same disconnected themes (mirror registry, hyperscaler RHOAI); GPU-related operator story on managed / enterprise OpenShift.

**Source actually says:** Same **private-registry / `oc-mirror` v2** pattern as 2.25: mirroring machine with **100 GB**, **~75 GB** image set check, **ImageDigestMirrorSet** + **CatalogSource**, optional mirror registry for OpenShift. **Supported OCP:** **4.19–4.20** (with **Distributed Inference / llm-d requiring 4.20+**). **Major version constraint:** **cannot upgrade from 2.25 or earlier to 3.0**; 3.0 for new installs; upgrade path from 2.25 to stable 3.x **promised in a later release**—**not** in ref-38’s “supported now” sense. **OpenShift Kubernetes Engine (OKE):** licensing **exception** only for operators supporting RHOAI; a table lists **3.x** dependencies including **“GPU Operator (with custom configurations)”** as **not supported on OKE** without exception—**relevant** to “GPU Operator on managed clusters” generalizations. **Llama Stack / RAG:** requires **NFD**, **NVIDIA GPU Operator**, GPU nodes, cert-manager, Service Mesh 3.x, etc. **DNS:** manual **A/CNAME** for OpenStack, CRC, private clouds without external DNS after LoadBalancer IP. **ROSA** appears only in **CLI install doc links** (e.g., installing `oc`). **No ARO** callout in the mirrored chapter body. **No STIG/umask.** **Object storage** still **required** for single-model serving (storing/deploying models) and pipelines.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** Disconnected mirroring: **aligned** with the article’s technical sequence at a high level. **Version / upgrade reality for 3.x** is a **material omission** if the article implies uniform lifecycle across 2.25 and 3.x. **GPU Operator:** documented as **first-class** for Llama Stack; **qualified** for **OKE** (exception, custom configurations). **ModelCar / mirror:** **not discussed**. **Hyperscaler:** **not** used here to assert RHOAI-on-ARO the way ref-34 Chapter 1 does—batch readers should **pair ref-38 with ref-34** for platform list.

**Impact:** Strengthens **operator mirroring** and **GPU** prerequisites for disconnected **3.3**; **weakens** any implicit “upgrade from 2.25 to 3.x in place” reading. **Hyperscaler + RHOAI** claim is **better supported by ref-34** than by this chapter alone.

---

## ref-43: Microsoft Learn — Azure Red Hat OpenShift 4 cluster support policy

**Article claims:** ARO (with ROSA) as managed hyperscaler option for RHOAI; strict **3 master / 3 worker** minimum, **250 worker** maximum, no scaling workers to zero or cluster shutdown, no ad-hoc master changes—violations void Microsoft/Red Hat support; GPU elasticity on hyperscalers.

**Source actually says:** **ARO-only** support policy (not RHOAI-specific). **Compute:** minimum **three worker and three master** nodes; **do not scale workers to zero** or **cluster shutdown** / deallocate VMs in cluster RG; **max 250 worker nodes**; **non-RHCOS workers not supported**; **do not remove/replace/add/modify master nodes**; keep **≥ double** current control-plane **vCPU quota** for scale-up; **three infrastructure nodes** recommended across zones if using infra nodes. **Operators:** **all cluster operators must remain managed** (`oc get clusteroperators`). **Workload:** **custom workloads (including from OperatorHub) on infrastructure nodes are not supported**; don’t taint nodes such that default OpenShift components can’t schedule; don’t run extra workloads on control plane. **Network:** cluster VMs need **direct outbound internet** (at least to **Azure Resource Manager** and logging); **cluster-wide HTTPS proxy for all required traffic is not supported** (see doc for proxy nuances). **OCP Technology Preview features not supported on ARO.** **GPU workload** SKUs listed (NC/ND families); some marked **day-2 only** or **4.19+** for certain H100/H200 SKUs.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** **Cluster size / masters / workers / shutdown / masters:** **matches** the article’s ARO bullets **closely** (article’s “void SLA” is **“void support”** in Microsoft wording—same idea). **ROSA / RHOAI / GPU Operator:** **not named**; **GPU** is **VM SKUs**, not **NVIDIA GPU Operator compatibility** text. **“ARM”** in the user query sense: doc uses **ARM** as **Azure Resource Manager**, not CPU architecture. **Article omissions:** **infra node** workload restrictions, **managed cluster operators** requirement, **outbound connectivity** constraints, **TP feature** ban, **tagging** limits (≤10 user tags on managed RG resources), **day-2-only** GPU sizes.

**Impact:** **Strong verification** for **ARO operational guardrails** the article quotes; **does not verify** RHOAI-on-ARO or **GPU Operator** specifically—those need **Red Hat RHOAI + ARO** support matrices elsewhere. **Air-gapped ARO** is **not** described as supported in this policy excerpt (outbound internet emphasized).

---

## ref-41: Red Hat blog — Optimize cloud costs with OpenShift Virtualization and ROSA on AWS

**Article claims:** ROSA as managed hyperscaler path for OpenShift; **OpEx** elasticity; **OpenShift Virtualization on ROSA** for overcommit; **joint support** and **Red Hat SRE** for day-2; **dynamic GPU** provisioning and spot-style cost patterns (article cites ref-41/42 for economics and GPUs).

**Source actually says:** **ROSA** plus **OpenShift Virtualization** enables **hardware overcommit** in AWS to run **more VMs on fewer cloud resources**; **pay-as-you-go**, committed spend, **RIs**, **Savings Plans**, unified billing. **ROSA is jointly supported by Red Hat and AWS**; **Red Hat SRE** handles **upgrades, monitoring, scaling, incident response**. For **AI/GPU**, **ROSA** allows **provisioning GPU instances on demand** for planned work and paying for **consumption**, reducing **CapEx** vs on-prem and encouraging **high utilization**—**no** mention of **RHOAI**, **ARO**, **NVIDIA GPU Operator**, **KServe**, or **spot instances** by name.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** **ROSA + SRE + cost + GPU on demand:** **supported** by the blog at a **marketing / architectural** level. **OpenShift Virtualization overcommit on ROSA:** **supported**. **Mapping to article:** “**ephemeral spot instances**” is **not** in ref-41 (article may blend other sources). **ARO:** **absent**. **GPU Operator on hyperscaler:** **not discussed**.

**Impact:** **Credible reinforcement** for **ROSA managed service and GPU elasticity** themes **without** verifying **RHOAI-specific** or **GPU Operator** support statements. Use **additional Red Hat/AWS RHOAI** references for **product-level** claims.

---

## Batch Summary

- **Verified:** 0 (no source fully substantiates all five claims without qualification)
- **Verified with caveats:** 4
- **Problematic:** 0
- **Unverifiable (in this batch):** 0 — but **partially unsupported** elements appear **per-topic** (e.g., **STIG/umask** not in ref-34/38/41/43; **ModelCar-in-mirror** not explicit)

- **Key pattern in this batch:** **Red Hat disconnected docs (ref-34, ref-38)** align with the article’s **mirror / oc-mirror / ~75 GB / private registry** arc but use **“mirroring machine”**, stress **object storage** and **extra operator mirrors**, and add **version / upgrade (2.x → 3.0)** and **OKE/GPU Operator exception** nuance. **Microsoft ARO policy (ref-43)** **nails** the **node and supportability** constraints the article lists for ARO but **does not** address **RHOAI** or **GPU Operator**. **ROSA blog (ref-41)** supports **managed SRE and GPU on demand** at a **high level**, not **Operator-level** compatibility.

**AI disclosure:** This assessment was produced with AI assistance to compare the cited source captures to the original article text.

# Batch 03 Findings: GPU hardware discovery, operators, and partitioning

**Sources analyzed:** ref-15, ref-16, ref-18, ref-19  
**Date:** 2026-04-17

**Scope:** The original article’s “Hardware Acceleration Discovery and Node Telemetry” section (NFD, NVIDIA GPU Operator, `AcceleratorProfile`, MIG, and GPU time-slicing) as compared to each listed source.

---

## ref-15: Install the Node Feature Discovery (NFD) Operator (NVIDIA documentation)

**URL:** https://docs.nvidia.com/ai-enterprise/deployment/red-hat-ai-factory/latest/nfd-operator.html

**Article claims:** The NFD Operator is a prerequisite for accelerated workloads; it continuously audits hardware, queries the host to find devices (including PCI vendor IDs such as `0x10de` and `15b3` for NVIDIA), and applies node labels (for example `feature.node.kubernetes.io/pci-10de.present=true`) so the scheduler can enforce placement (e.g., `nodeAffinity`) for GPU workloads.

**Source actually says:** NFD is a prerequisite for the NVIDIA GPU and Network Operators; it runs a “discovery and reconciliation loop” and applies node labels describing hardware configuration. It “uses vendor PCI IDs to identify hardware,” naming `0x10de` and `15b3` as “the PCI vendor IDs assigned to NVIDIA.” It instructs verifying labels such as `feature.node.kubernetes.io/pci-10de.present=true` and shows CLI output that also includes `pci-15b3` labels. After install, an instance of the `NodeFeatureDiscovery` CR is required to deploy NFD pods.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** PCI-based discovery and NVIDIA-oriented labels (`pci-10de`) match the article closely. The source does not use the article’s phrasing “continuous hardware auditor” or explicitly document Kubernetes `nodeAffinity`; those are reasonable operational implications but not quoted. The source’s grouping of `15b3` with “NVIDIA” is reproduced by the article; readers should treat that sentence as “per NVIDIA’s page,” not as independent PCI-registry fact-checking (the excerpt does not define `15b3` further). The source adds an install step (create `NodeFeatureDiscovery` CR) that the article omits.

**Impact:** Core claim (NFD labels nodes from PCI vendor IDs for GPU-related discovery) is supported by ref-15. Minor over-precision in the article (scheduler mechanics, “auditor” metaphor) is not contradicted but is not fully spelled out in this page alone.

---

## ref-16: Chapter 8 Enabling NVIDIA GPUs (Red Hat OpenShift AI Self-Managed 2.16)

**URL:** https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed/enabling-nvidia-gpus_install

**Article claims:** After NFD, deploy the NVIDIA GPU Operator; a `ClusterPolicy` is the declarative configuration that deploys the NVIDIA Container Toolkit, Kubernetes device plugins, and DCGM telemetry into the monitoring stack; OpenShift AI is accelerator-agnostic with operator-specific setup; `AcceleratorProfile` maps hardware identifiers (e.g., `nvidia.com/gpu`) for dashboard and runtimes; MIG and time-slicing enable partitioning/multiplexing.

**Source actually says:** NVIDIA GPUs require the NVIDIA GPU Operator. Administrators must install NFD, create a `NodeFeatureDiscovery` instance, install the GPU Operator, and create a `ClusterPolicy` populated with defaults (details deferred to NVIDIA’s “NVIDIA GPU Operator on Red Hat OpenShift Container Platform” documentation). Post-install steps include dashboard cleanup/restart. Verification includes `AcceleratorProfile` CRD UI checks and `oc describe node` showing `nvidia.com/gpu` capacity. It explicitly points to “Working with accelerator profiles” after installing the GPU Operator. A note states that in 2.16, accelerators on the same cluster only are supported; RDMA across accelerators (e.g., GPUDirect/NVLink-style use cases) is not supported.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** `ClusterPolicy`, NFD + instance, GPU Operator, and accelerator profiles are directly aligned with the article. The source does not, in this chapter, enumerate Container Toolkit, device plugin, or DCGM/Prometheus wiring—that level of component detail is delegated to NVIDIA docs, so those sub-claims are not independently confirmed here. MIG and time-slicing are not mentioned in ref-16. The RDMA/non-support note is an omission relative to the article’s generalized “enterprise GPU” story.

**Impact:** High-confidence alignment on the RHOAI 2.16 enablement path (operators + `AcceleratorProfile` follow-on). The article’s specific breakdown of what `ClusterPolicy` deploys should be treated as NVIDIA-documentation territory unless another Red Hat excerpt is cited.

---

## ref-18: NVIDIA AI Enterprise with OpenShift — NVIDIA GPU Operator on Red Hat OpenShift Container Platform

**URL:** https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/nvaie-with-ocp.html

**Article claims:** The NVIDIA GPU Operator (via `ClusterPolicy`) delivers drivers, device plugins, and monitoring components for GPU-enabled OpenShift clusters.

**Source actually says:** Documents NFD and NVIDIA GPU Operator installation and creation of a `ClusterPolicy` (with substantial vGPU/licensing detail on one path). States that the “GPU Operator installs all the required components to set up the NVIDIA GPUs in the OpenShift Container Platform cluster.” Example `oc get pods -n nvidia-gpu-operator` output lists `nvidia-driver-daemonset`, `nvidia-device-plugin-daemonset`, `nvidia-dcgm-exporter`, `nvidia-dcgm`, and related pods—evidence of driver stack, device plugin, and DCGM-based monitoring.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** Driver daemonset, device plugin, and DCGM exporter pods substantiate the article’s triad (drivers, device plugins, monitoring). The fetched page does not discuss the NVIDIA Container Toolkit by name, Prometheus scrape configuration, or RHOAI `AcceleratorProfile` / workbench integration. Much of the page focuses on vSphere vGPU licensing and `ClusterPolicy` fields not referenced by the article.

**Impact:** Strong corroboration for “GPU Operator brings up drivers + device plugin + DCGM-class telemetry” at the OpenShift/NVIDIA layer. RHOAI-specific claims (dashboard resource identifiers, MIG/time-slicing) are outside this excerpt.

---

## ref-19: Red Hat OpenShift AI: Supported Configurations

**URL:** https://access.redhat.com/articles/rhoai-supported-configs

**Article claims:** Broadly, OpenShift AI integrates with diverse accelerators via operators and profiles; operational context includes supported stacks (components, dependencies) relevant to GPU-backed serving and workbenches.

**Source actually says:** Catalog-style article: supported platforms/architectures, component GA/TP matrices, vLLM versions per RHOAI release, training and workbench images, model-serving runtime support tables, and operator dependency links—including Node Feature Discovery Operator documentation and NVIDIA GPU Operator documentation. Explicit statement: “Red Hat OpenShift AI does not directly support any specific accelerators. To use accelerator functionality in OpenShift AI, the relevant accelerator Operators are required,” with integration support and images including NVIDIA, AMD, Gaudi, and Spyre libraries.

**Source actually says (relevant negatives):** Does not define NFD labeling rules, `ClusterPolicy` contents, MIG, or time-slicing in the captured content.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** The “no direct accelerator support; operators required” message harmonizes with the article’s hardware-agnostic framing, and dependency links include NFD and the NVIDIA GPU Operator. Lists KServe and Workbenches as supported components (support matrices), which is weakly consistent with accelerators feeding serving and notebook-style workstreams, but this page does not define `AcceleratorProfile` fields or scheduling semantics. Relative to the five numbered article claims, this excerpt does **not** substantiate PCI ID labeling rules, `ClusterPolicy` internals, MIG isolation, or time-slicing versus memory isolation—those require other documents.

**Impact:** ref-19 backs the ecosystem/support story at a catalog level but cannot substantiate the article’s finer technical claims in this batch; citing ref-19 alone would be insufficient for MIG/time-slicing or NFD PCI details.

---

## Batch Summary

- **Verified:** 0 (no source fully confirms all five target claims without gaps)
- **Verified with caveats:** 4 (ref-15, ref-16, ref-18, ref-19—each supports a slice of the narrative; ref-19 only for operator/accelerator dependency framing)
- **Problematic:** 0
- **Unverifiable:** 0

**Unsupported by this batch (need other citations):**  
- **Claim 4 (MIG):** No hit in ref-15, ref-16, ref-18, or ref-19 excerpts.  
- **Claim 5 (GPU time-slicing as software multiplexing without memory isolation):** No hit in these sources.

**Key pattern in this batch:** NVIDIA and Red Hat install docs (ref-15, ref-16, ref-18) align well on the operator chain (NFD → GPU Operator → `ClusterPolicy`) and observable cluster signals (`nvidia.com/gpu`, DCGM/device-plugin/driver pods). The supported-configurations article (ref-19) validates the *support model* (operator-mediated accelerators, dependency pointers) but not low-level partitioning or PCI labeling mechanics. For MIG and time-slicing, the article’s citations in the full work point elsewhere (e.g., ref-17 in the article bibliography); this batch does not verify those sentences.

---

*AI disclosure: This assessment was produced with AI assistance for the research verification exercise.*

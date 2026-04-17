# Batch 03 Findings: Hardware Acceleration and GPU

**Sources analyzed:** ref-15, ref-16, ref-18, ref-19  
**Date:** 2026-04-17

---

## ref-15: Install the Node Feature Discovery (NFD) Operator (NVIDIA AI Enterprise on Red Hat AI Factory)

**URL (from source file):** https://docs.nvidia.com/ai-enterprise/deployment/red-hat-ai-factory/latest/nfd-operator.html

**Article claims:** The NFD Operator scans the PCI bus for vendor IDs `0x10de` and `15b3`; those IDs identify NVIDIA hardware; nodes receive labels such as `feature.node.kubernetes.io/pci-10de.present=true`, supporting scheduling (for example `nodeAffinity`).

**Source actually says:** NFD “uses vendor PCI IDs to identify hardware in a node” and states that ``0x10de`` and `15b3` “are the PCI vendor IDs assigned to NVIDIA.” It documents verification of `feature.node.kubernetes.io/pci-10de.present=true` in the console and, in the CLI example, also `feature.node.kubernetes.io/pci-10de.sriov.capable=true`, `feature.node.kubernetes.io/pci-15b3.present=true`, and `feature.node.kubernetes.io/pci-15b3.sriov.capable=true`. It does not use the exact phrase “scans the Peripheral Component Interconnect (PCI) bus,” and it does not mention `nodeAffinity` (scheduling use is a reasonable inference from node labels, not a direct citation).

**Verdict:** **VERIFIED WITH CAVEATS**

**Details:**

- **0x10de:** This is the well-known PCI vendor ID for NVIDIA Corporation; the source’s statement and the example label `pci-10de` are consistent.
- **15b3:** In the PCI SIG registry, **0x15b3 is Mellanox Technologies** (NVIDIA networking). NVIDIA’s documentation here collapses Mellanox and NVIDIA GPU IDs under “assigned to NVIDIA,” which reflects **corporate ownership** after the Mellanox acquisition, not the historical vendor name on the bus. For technical audiences, calling `15b3` “NVIDIA hardware” without noting **Mellanox / ConnectX (NVIDIA networking)** is **imprecise** compared to strict PCI-vendor semantics (GPU vs NIC).
- **Label name:** The source explicitly gives `feature.node.kubernetes.io/pci-10de.present=true` as the label to verify; this matches the article’s example label.
- **“NFD Operator scans…”:** The source attributes PCI-ID–based identification to the Node Feature Discovery Operator context but describes it as using vendor PCI IDs rather than detailing an internal “PCI bus scan” mechanism.

**Impact:** Readers who need exact PCI semantics (GPU `10de` vs NIC `15b3`) may be misled if they equate `15b3` with “NVIDIA GPU.” The scheduling angle is plausible but is **editorial inference** beyond the cited page.

---

## ref-16: Chapter 8. Enabling NVIDIA GPUs (Red Hat OpenShift AI Self-Managed 2.16)

**URL (from source file):** https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed/enabling-nvidia-gpus_install

**Article claims:** (1) Legacy NVIDIA GPU add-on deprecated and must be uninstalled before modern RHOAI, replaced by NVIDIA GPU Operator (article cites ref-17; batch checks ref-16). (2) `ClusterPolicy` custom resource deploys “NVIDIA Container Toolkit, Kubernetes device plugins, and DCGM exporter.” (3) Broader platform / accelerator narrative sometimes tied to ref-17; ref-16 is relevant for GPU enablement and `AcceleratorProfile`.

**Source actually says:** Before using NVIDIA GPUs you must install the **NVIDIA GPU Operator**. Procedure: follow NVIDIA’s “NVIDIA GPU Operator on Red Hat OpenShift Container Platform” documentation; after NFD, create a `NodeFeatureDiscovery` instance; after the GPU Operator, create a **`ClusterPolicy`** and populate it with **default values**. It instructs deleting the **`migration-gpu-status`** ConfigMap and restarting the **`rhods-dashboard`** rollout. Verification mentions the **`AcceleratorProfile`** CRD (“reset **migration-gpu-status** instance” wording appears on that CRD’s details page), expected operators (NVIDIA GPU, NFD, KMM), and `oc describe node` showing `nvidia.com/gpu` in capacity/allocatable. It notes that in 2.16, accelerators in the **same cluster only** are supported and **RDMA between accelerators** (e.g. GPUDirect/NVLink across a network) is **not** supported.

**Verdict:** **UNSUPPORTED** (for the specific `ClusterPolicy` component list); **UNSUPPORTED** (for “legacy NVIDIA GPU add-on deprecated” as stated in the article for this citation path)

**Details:**

- **`ClusterPolicy` and the named trio:** ref-16 **does not** name the NVIDIA Container Toolkit, Kubernetes device plugins, or DCGM exporter. It only requires creating a `ClusterPolicy` with defaults and defers implementation detail to **NVIDIA’s** documentation. So the **exact enumeration** in the article is **not verified by ref-16**.
- **Legacy GPU add-on deprecation:** This chapter **does not** state that a legacy NVIDIA GPU add-on is deprecated, must be uninstalled, or is replaced by the GPU Operator. No substitute for broken ref-17 appears here.
- **`AcceleratorProfile`:** ref-16 points to “Working with accelerator profiles” after installing the GPU Operator and references the CRD in verification; that **supports** the idea that accelerator profiles matter for RHOAI, but it **does not** by itself prove the article’s full multi-vendor “each accelerator needs an `AcceleratorProfile`” wording.

**Impact:** If the article presents ref-16 as the authority for **what** `ClusterPolicy` deploys at the component level, that overstates what Red Hat’s 2.16 chapter actually documents; readers should rely on **NVIDIA GPU Operator** documentation for that breakdown. Deprecation of a legacy add-on remains **uncited** in this batch.

---

## ref-18: NVIDIA AI Enterprise with OpenShift

**URL (from source file):** https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/nvaie-with-ocp.html

**Article claims:** Operational pattern for NVAIE on OpenShift: NFD, GPU Operator, secrets, **`ClusterPolicy`**; GPU Operator brings up the NVIDIA stack on the cluster.

**Source actually says:** Describes installing NFD, then the NVIDIA GPU Operator, NGC and licensing secrets, and creating a **`ClusterPolicy`** instance (default name `gpu-cluster-policy`). States: “The **GPU Operator installs all the required components** to set up the NVIDIA GPUs in the OpenShift Container Platform cluster.” Example `oc get pods -n nvidia-gpu-operator` output includes **`nvidia-device-plugin-daemonset`**, **`nvidia-dcgm-exporter`**, **`nvidia-dcgm`**, **`nvidia-driver-daemonset`**, **`gpu-feature-discovery`**, etc. It does **not** explicitly name “NVIDIA Container Toolkit” or a generic “Kubernetes device plugins” heading in the excerpt—those are plausible parts of the stack but **not spelled out** on this page.

**Verdict:** **VERIFIED WITH CAVEATS**

**Details:**

- **ClusterPolicy / operator stack:** Strong support that **`ClusterPolicy`** is the policy object used with the GPU Operator and that the operator deploys multiple daemons, including **device plugin** and **DCGM exporter** pods in the example.
- **Article’s exact trio:** **Device plugin** and **DCGM exporter** align with the example pod list; **“NVIDIA Container Toolkit”** as a named deliverable of `ClusterPolicy` is **not directly quoted** in the captured ref-18 text.
- **Legacy NVIDIA GPU add-on:** **Not mentioned** in ref-18.

**Impact:** ref-18 backs a **high-level** “GPU Operator + ClusterPolicy installs NVIDIA GPU stack” narrative better than it backs a **laundry list** of three specific product names unless tightened against NVIDIA’s GPU Operator architecture docs.

---

## ref-19: Red Hat OpenShift AI supported configurations (Knowledgebase article)

**URL (from source file):** https://access.redhat.com/articles/rhoai-supported-configs

**Article claims:** RHOAI is a **hardware-agnostic** platform with **broad accelerator ecosystem** support (Intel Gaudi, AMD GPUs, IBM Spyre, NVIDIA), each tied to an **`AcceleratorProfile`** custom resource (article cites ref-17 for some of this; ref-19 is checked as overlap). Also relevant: **GA vs Technology Preview** for components, and **MIG / GPU time-slicing** (ref-17 gap).

**Source actually says:**

- “Red Hat OpenShift AI **does not directly support any specific accelerators**. To use accelerator functionality in OpenShift AI, the **relevant accelerator Operators** are required. OpenShift AI supports **integration** with the relevant Operators, and provides many images … that include the libraries to work with **NVIDIA GPUs, AMD GPUs, Intel Gaudi AI accelerators and IBM Spyre**.”
- Lists dependencies/documentation pointers including **NVIDIA GPU Operator**, **Intel Gaudi Base Operator**, **AMD GPU Operator**, **IBM Spyre Operator**, **NVIDIA Network Operator**, and **Node Feature Discovery Operator**.
- **vLLM** compatibility table includes **CUDA, ROCm, Power/Z, Gaudi** columns for various RHOAI versions.
- **Operator/component tables** mix **GA**, **TP** (Technology Preview), Deprecated, etc., for RHOAI components (version-dependent).
- **No mention** in the captured text of **MIG**, **time-slicing**, or **partitioning an H100** into isolated logical instances.
- **No statement** that every accelerator family **must** use an **`AcceleratorProfile`** CR; that concept is not defined on this page in the excerpt.

**Verdict:** **VERIFIED WITH CAVEATS** (multi-vendor integration and images); **UNSUPPORTED** (strict “hardware-agnostic platform” phrasing and mandatory `AcceleratorProfile` per vendor from this page alone); **UNVERIFIABLE** (MIG / time-slicing from this batch)

**Details:**

- **Multi-vendor:** **Supported** in the sense of documented **operator integration** and **images/runtimes** (e.g. vLLM NVIDIA / AMD / Gaudi / Spyre serving runtimes in the tables). This is **not** the same as claiming every pathway is **GA** or uniformly supported at the same support level—ref-19 repeatedly marks features as **TP** or architecture-specific.
- **`AcceleratorProfile`:** ref-19 **does not** establish the article’s rule that **each** of Gaudi / AMD / Spyre **requires** an `AcceleratorProfile` CR; that may be true in product docs elsewhere but is **not evidenced** here.
- **GA vs TP:** Ref-19 is explicit that many items are **Technology Preview** depending on version and architecture; a blanket “comprehensive GA ecosystem” reading would **conflict** with the tables’ TP entries for portions of the product surface.
- **MIG / time-slicing:** **Absent** from ref-19 excerpt → **UNVERIFIABLE** within this source batch.

**Impact:** ref-19 is strong for “**RHOAI integrates with multiple accelerator operators and ships multi-vendor images/runtimes**,” weak for **exact CR requirements per vendor** and **not usable** for **MIG/time-slicing** claims without other sources.

---

## Batch Summary

- **Verified:** 1  
- **Verified with caveats:** 3  
- **Problematic:** 2  
- **Unverifiable:** 1  

**Claim-level mapping (headline totals):** The **VERIFIED** item is the exact **`pci-10de.present=true`** label in ref-15. **VERIFIED WITH CAVEATS** covers ref-15 PCI/`15b3` wording, ref-18’s operator/`ClusterPolicy`/example pods (without the article’s full component naming), and ref-19’s multi-vendor operator-and-image story (with GA/TP nuance). **Problematic** counts two **UNSUPPORTED** citation problems in this batch: the **`ClusterPolicy` → Container Toolkit + device plugins + DCGM** list **as supportable from ref-16**, and **legacy NVIDIA GPU add-on deprecation** (sought where ref-17 failed; **not** stated in ref-16, ref-18, or ref-19). **Unverifiable** is **MIG / GPU time-slicing / H100 partitioning** (no support in these four sources). The article’s **`AcceleratorProfile` required for each vendor** phrasing is **not evidenced by ref-19** alone (see ref-19 section); if the article cites ref-19 for that rule, treat it as **UNSUPPORTED** for that citation unless another doc is supplied.

- **Key pattern in this batch:** **Upstream NVIDIA docs (ref-15)** use **vendor branding** (“NVIDIA” for `15b3`) that **does not match strict PCI vendor naming** (Mellanox). **Red Hat’s enabling chapter (ref-16)** stays at **procedural** level (`ClusterPolicy` exists, defaults, migration ConfigMap) and **does not** substantiate **low-level component lists** or **legacy add-on deprecation**. **ref-19** emphasizes **operator-mediated** accelerator support and **versioned GA/TP** reality, which should temper broad “hardware-agnostic / comprehensive GA” language unless qualified.

# openshift-gpu

**Purpose:** Research supporting the guide on managing GPU nodes on bare-metal OpenShift — installation, configuration, scheduling, monitoring, and troubleshooting.
**Status:** Complete
**Output:** [`docs/ai-engineering/openshift-gpu-node-management.md`](../../docs/ai-engineering/openshift-gpu-node-management.md)

---

Sources fetched from NVIDIA GPU Operator docs, OpenShift docs, and the GPU Operator GitHub repo (v24.9.1). Sources are no longer present — they were either:

- Dead weight (nav-only scrapes, wrong-platform content) — deleted
- Scraped docs — article references now point to the original upstream URLs
- Operational artifacts — moved to [`devops/ocp/gpu/`](../../devops/ocp/gpu/)

## 2026-05-13 — Virt/GPU update pass

Added a second round of source material from NVIDIA and Red Hat covering
GPU passthrough and vGPU for OpenShift Virtualization.

| Source | Status | Notes |
|--------|--------|-------|
| [NVIDIA GPU Operator with OpenShift Virtualization](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/openshift-virtualization.html) | fetched to `sources/virt-gpu-update/` | 641 lines — full GPU Operator approach: node types, HyperConverged, vGPU profiles |
| [Red Hat OCP 4.18 — Configuring virtual GPUs](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-configuring-virtual-gpus) | blocked (WAF) | Referenced by URL in the guide; NVIDIA source describes this approach |

Output: Updated `docs/ai-engineering/openshift-gpu-node-management.md` — vGPU section expanded from ~15 lines to ~220 lines covering both approaches, node workload types, HyperConverged CR, vGPU profile management, and VM spec examples.

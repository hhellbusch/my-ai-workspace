# GPU Operator — Operational Reference

Operational artifacts for deploying and configuring the NVIDIA GPU Operator
on bare-metal OpenShift clusters.

For the full guide, see:
[`docs/ai-engineering/openshift-gpu-node-management.md`](../../../docs/ai-engineering/openshift-gpu-node-management.md)

For the ArgoCD/GitOps deployment pattern (helm-component-pattern),
see `devops/argo/examples/helm-component-pattern/components/nvidia-gpu-operator/`.

---

## Files

| File | Purpose |
|------|---------|
| `clusterpolicy-baremetal.yaml` | Full ClusterPolicy CRD template — configure all GPU Operator components |
| `nvidia-gpu-operator-values.yaml` | Complete Helm values reference for the GPU Operator chart |
| `nodefeaturerules-baremetal.yaml` | NFD NodeFeatureRule — GPU hardware detection labels |
| `nvidiadriver-baremetal.yaml` | NVIDIADriver CR template — per-node driver configuration |

These files are derived from the [NVIDIA GPU Operator](https://github.com/NVIDIA/gpu-operator)
Helm chart at v24.9.1. Review against current upstream before applying.

---

## Related

- Upstream: [NVIDIA GPU Operator on OpenShift](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/openshift/contents.html)
- Upgrade procedure: [GPU Driver Upgrades](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-driver-upgrades.html)

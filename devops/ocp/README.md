---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
description: OpenShift troubleshooting, configuration examples, and quick references
---

# OpenShift

Install, operations, and troubleshooting for enterprise OpenShift — 25 symptom guides, disconnected install, GPU, and runnable examples.

## Troubleshooting (25 guides)

Symptom → cause → fix guides with quick references and diagnostic scripts.

| Category | Guides |
|----------|--------|
| Installation | [Failed OCP install](troubleshooting/failed-ocp-install/README.md) |
| Control plane | [API slowness](troubleshooting/api-slowness-web-console/README.md), [apiserver cert deadlock](troubleshooting/apiserver-cert-deadlock/README.md), [kubeconfigs](troubleshooting/control-plane-kubeconfigs/README.md), [kube-controller-manager crashloop](troubleshooting/kube-controller-manager-crashloop/README.md), [OAuth healthz](troubleshooting/oauth-healthz-unavailable/README.md) |
| Bare metal | [Inspection timeout](troubleshooting/bare-metal-node-inspection-timeout/README.md), [stale node IP](troubleshooting/bare-metal-stale-node-ip-conflict/README.md), [RHCOS disk wipe](troubleshooting/bare-metal-rhcos-disk-wipe/README.md), [worker TLS](troubleshooting/worker-node-tls-cert-failure/README.md) |
| Storage | [NVMe host NQN](troubleshooting/nvme-host-nqn-duplicate/README.md), [NVMe/TCP network](troubleshooting/nvme-tcp-storage-network/README.md), [Portworx CSI](troubleshooting/portworx-csi-crashloop/README.md), [NFS proxy PVC](troubleshooting/nfs-portworx-proxy-pvc-slow-ready/README.md), [Prometheus storage](troubleshooting/prometheus-monitoring-storage/README.md) |
| Registry / images | [Image registry auth](troubleshooting/image-registry-auth/README.md), [Signature policy MCP deadlock](troubleshooting/image-signature-policy-mcp-deadlock/README.md) |
| Other | [CSR management](troubleshooting/csr-management/README.md), [CoreOS networking](troubleshooting/coreos-networking-issues/README.md), [Namespace terminating](troubleshooting/namespace-stuck-terminating/README.md), [KubeVirt provisioning](troubleshooting/kubevirt-vm-stuck-provisioning/README.md), [MCO webhook](troubleshooting/multiclusterobservability-webhook-rejection/README.md), [Destroy without metadata](troubleshooting/destroy-cluster-without-metadata/README.md), [Debug toolbox](troubleshooting/debug-toolbox-container/README.md), [AAP SSH MTU](troubleshooting/aap-ssh-mtu-issues/README.md) |

**Full catalog with quick-ref links:** [troubleshooting/README.md](troubleshooting/README.md) · **Symptom lookup:** [SYMPTOM-INDEX.md](../SYMPTOM-INDEX.md) · **Site:** [OpenShift on Field Notes](https://hhellbusch.github.io/gemini-workspace/devops/ocp/)

## Install and configuration

- [VLAN Network Segmentation](vlan-network-segmentation.md) — What install-config VLANs become on the cluster, day-2 VLAN management via Multus/NAD
- [Disconnected install (Quay + oc-mirror)](disconnected-install/) — mirror-registry, oc-mirror v2, ImageSet examples, phased working guide
- [IBM Z / LinuxONE](ibm-z/) — s390x vocabulary, CIM ABI LPAR, AOP fork notes, ACM vs Metal3 ([index](ibm-z/README.md))
- [GPU operator artifacts](gpu/) — ClusterPolicy, MachineConfig, vGPU runbooks
- [Examples](examples/) — Configuration examples and templates ([Kafka + Portworx rack-aware](examples/kafka-bare-metal-portworx/README.md))
- [Notes](notes/) — Informal quick references ([MachineConfig pools](notes/machine-config-pools.md), useful `oc` commands)
- **`install/`** *(gitignored)* — Local install working directory; never committed

Browse the full technical reference index → [devops/README.md](../README.md)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

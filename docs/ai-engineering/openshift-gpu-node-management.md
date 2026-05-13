# OpenShift GPU Node Management — Bare Metal Guide

> **Audience:** Platform engineers running OpenShift on bare-metal GPU nodes (NVIDIA). Not a tutorial — a reference for the decision points, state machines, and configuration tradeoffs that matter during installation, scheduling, and upgrades.
>
> **Purpose:** Consolidates installation patterns, GPU scheduling configuration, upgrade procedures, monitoring, and troubleshooting into a single working document. Sources are pulled from NVIDIA GPU Operator docs, OpenShift documentation, and the operator's source code (v24.9.1).

---

## Scope

This guide covers bare-metal GPU management on Red Hat OpenShift Container Platform (OCP). It assumes:

- OCP 4.x with GPU-capable bare-metal worker nodes
- NVIDIA GPUs (Tesla, A100, H100, L4, etc.)
- GPU workloads include both containerized pods and VMs (via OpenShift Virtualization/KubeVirt)
- No cloud provider abstractions — this is about configuring the nodes and the operator

---

## On this page

- [Scope](#scope)
- [Installation — What Actually Happens](#installation---what-actually-happens)
  - [The components](#the-components)
  - [Order of operations](#order-of-operations)
  - [The IOMMU consideration](#the-iommu-consideration)
  - [Canary deployment pattern](#canary-deployment-pattern)
  - [Pre-installation prerequisites](#pre-installation-prerequisites)
- [GPU Scheduling](#gpu-scheduling)
  - [ClusterPolicy — the central configuration object](#clusterpolicy---the-central-configuration-object)
  - [GPU modes of operation](#gpu-modes-of-operation)
  - [Time-slicing](#time-slicing)
  - [MIG (Multi-Instance GPU)](#mig-multi-instance-gpu)
  - [Device plugin configuration](#device-plugin-configuration)
  - [vGPU for VMs](#vgpu-for-vms)
- [GPU Driver Upgrades](#gpu-driver-upgrades)
  - [The upgrade state machine](#the-upgrade-state-machine)
  - [Upgrade controller configuration](#upgrade-controller-configuration)
  - [Updating the driver version](#updating-the-driver-version)
  - [Monitoring upgrade progress](#monitoring-upgrade-progress)
  - [Pausing and skipping upgrades](#pausing-and-skipping-upgrades)
  - [Failing an upgrade](#failing-an-upgrade)
- [Monitoring](#monitoring)
  - [DCGM Exporter](#dcgm-exporter)
  - [Node Status Exporter](#node-status-exporter)
  - [Prometheus integration](#prometheus-integration)
- [Troubleshooting](#troubleshooting)
  - [Node states](#node-states)
  - [Driver pod won't start](#driver-pod-wont-start)
  - [Driver not loading after pod restart](#driver-not-loading-after-pod-restart)
  - [VM GPU passthrough not working](#vm-gpu-passthrough-not-working)
- [References](#references)

---

## Installation — What Actually Happens

### The components

The NVIDIA GPU Operator installs several components as DaemonSets:

- **Node Feature Discovery (NFD)** — Detects GPUs on the host and labels nodes with `nvidia.com/gpu.present=true`
- **GPU Operator itself** — Installs driver, device plugin, DCGM exporter, toolkit, validator
- **Driver DaemonSet** — Installs NVIDIA kernel modules and userspace drivers on each GPU node

These components live in the `nvidia-gpu-operator` namespace (OCP default) or `gpu-operator` (upstream/Kubernetes).

### Order of operations

```
1. Install NFD Operator first
2. Label GPU nodes (or let NFD do it automatically)
3. Install GPU Operator (only labeled nodes are affected)
4. Apply ClusterPolicy (this is when the driver starts installing)
```

**Key insight:** The operator pods start and sit idle until you label nodes with `nvidia.com/gpu.present=true`. The operator only targets labeled nodes — non-GPU nodes are unaffected by the initial installation.

### The IOMMU consideration

If your GPU nodes require IOMMU (required for SR-IOV, vGPU, and some passthrough configurations), IOMMU is a **host-level kernel parameter** set via `MachineConfig`. Enabling it triggers a **rolling node reboot**.

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-master-configure-iommu
spec:
  kernelArguments:
    - intel_iommu=on
    - iommu=pt
```

**This is the step that brings VMs down.** Without Live Migration configured in OpenShift Virtualization, nodes rebooting with new IOMMU settings will terminate any running VMs. Plan accordingly.

### Canary deployment pattern

Label one worker node first:

```bash
kubectl label node <node-name> nvidia.com/gpu.present=true
```

Watch the driver installation:

```bash
kubectl get pods -n nvidia-gpu-operator -w
```

Verify the node is healthy before labeling the rest. This catches driver version mismatches, repository access issues, and hardware compatibility problems before they propagate cluster-wide.

### Pre-installation prerequisites

Before applying `ClusterPolicy`:

1. **NFD Operator** must be running — the GPU Operator depends on NFD for node detection
2. **Driver Toolkit** must reach Red Hat repositories with valid entitlements — if it can't pull, the driver pod will fail to start (this won't crash the node, but the driver won't come up)
3. **Node labels** must be correct — `nvidia.com/gpu.present=true` is the signal that tells the operator to install the driver on a node

---

## GPU Scheduling

### ClusterPolicy — the central configuration object

The `ClusterPolicy` custom resource controls how the operator behaves across the cluster. It's the primary interface for GPU scheduling, driver management, and upgrade behavior.

```yaml
apiVersion: nvidia.com/v1
kind: ClusterPolicy
metadata:
  name: cluster-policy
  namespace: nvidia-gpu-operator
spec:
  driver:
    enabled: true
    version: "580.95.05"
    upgradePolicy:
      autoUpgrade: false
      maxParallelUpgrades: 1
      maxUnavailable: "25%"
  devicePlugin:
    enabled: true
  migManager:
    enabled: false
  vgpuManager:
    enabled: false
```

### GPU modes of operation

The operator supports three modes for exposing GPU resources to workloads:

| Mode | Use case | Multi-tenancy | VM passthrough |
|------|----------|---------------|----------------|
| **Full GPU** | Single workload per GPU | No | Limited (requires SR-IOV) |
| **Time-slicing** | Multiple light workloads share one GPU | Yes | No |
| **MIG (Multi-Instance GPU)** | Isolated GPU partitions on A100/H100 | Yes | No |

#### Time-slicing

Split a single GPU into smaller pieces. Configure in `ClusterPolicy`:

```yaml
devicePlugin:
  config:
    name: ""
    default: 4
```

This splits each GPU into 4 equal pieces. Pods requesting `nvidia.com/gpu: 0.25` get one piece; pods requesting `nvidia.com/gpu: 1` get the full GPU.

#### MIG (Multi-Instance GPU)

> **OCP version requirement:** MIG support in OpenShift requires **OCP 4.20+**.
Clusters running OCP 4.18 or earlier will fail ClusterPolicy validation if `mig.strategy` is set.
Do not enable MIG on pre-4.20 clusters.

Available on A100 and H100 GPUs. Splits a GPU into up to 7 isolated instances. Each instance has dedicated memory and compute:

```yaml
mig:
  strategy: single   # single | mixed
```

- `single` — all GPU partitions on a node use the same MIG profile (simpler scheduling)
- `mixed` — partitions on a node can use different profiles (more flexible, requires explicit pod resource requests)

MIG profiles define how the GPU is partitioned. NVIDIA ships with predefined profiles (e.g. `1g.10gb`, `2g.20gb`, `4g.40gb` for A100 80GB); you can also create custom profiles.
Per-node partition configuration is managed by the `nvidia-mig-manager` DaemonSet after the ClusterPolicy is applied.

### Device plugin configuration

The device plugin is what Kubernetes uses to discover and schedule GPU resources. It reads GPU health, allocates devices to pods, and reports capacity.

```yaml
devicePlugin:
  enabled: true
  config:
    name: ""          # Empty = use defaults
    default: ""       # Default GPU type to expose
```

### vGPU for VMs

For GPU passthrough to VMs (OpenShift Virtualization / KubeVirt), you need vGPU support. This requires:

1. **NVIDIA vGPU host driver** (12.0+) installed on all hypervisors
2. **NVIDIA License Service** — Cloud License Service (CLS) or Delegated License Service (DLS)
3. **Custom driver container image** built from the vGPU guest driver

The vGPU driver container image is **not** public — it requires an NVIDIA Enterprise license and must be built from source using the `gpu-driver-container` repository.

**EULA note:** Uploading the vGPU driver to a public repository violates the NVIDIA vGPU EULA.

See the [NVIDIA vGPU Passthrough reference](resources/nvidia-vgpu-passthrough.md) for the full installation flow.

---

## GPU Driver Upgrades

### The upgrade state machine

This is the most operationally important section. GPU driver upgrades are not a simple pod restart — they require unloading kernel modules and loading new ones, which means **all GPU clients must be stopped first**.

The NVIDIA GPU Operator upgrade controller manages this through a well-defined state machine. Each node has a label `nvidia.com/gpu-driver-upgrade-state` that shows its current state.

**Upgrade states (in order):**

| State | Meaning |
|-------|---------|
| `upgrade-required` | Driver pod is stale; upgrade is queued but no action taken yet |
| `cordon-required` | Node marked Unschedulable |
| `wait-for-jobs-required` | Waiting for user-defined pods/jobs to complete |
| `pod-deletion-required` | GPU-allocated pods are being evicted |
| `drain-required` | Full node drain (fallback if pod deletion fails) |
| `pod-restart-required` | Driver pod restarts with new version |
| `validation-required` | New driver is validated by the operator |
| `uncordon-required` | Node marked Schedulable again |
| `upgrade-done` | Driver is running at the new version |
| `upgrade-failed` | Upgrade failed; manual intervention required |

### Upgrade controller configuration

The `upgradePolicy` field in `ClusterPolicy` controls upgrade behavior:

```yaml
driver:
  upgradePolicy:
    autoUpgrade: true          # Enable/disable auto-upgrade
    maxParallelUpgrades: 1     # Nodes upgraded simultaneously (default: 1)
    maxUnavailable: "25%"      # Max nodes unavailable during upgrade (default: 25%)

    waitForCompletion:
      timeoutSeconds: 0        # 0 = wait indefinitely
      podSelector: ""          # Label selector for pods to wait on

    gpuPodDeletion:
      force: false             # Delete unmanaged pods
      timeoutSeconds: 300      # Wait 5 min before force-delete
      deleteEmptyDir: false    # Don't delete emptyDir volumes

    drain:
      enable: false            # Cluster-wide drain (disruptive!)
      force: false
      podSelector: ""
      timeoutSeconds: 300
      deleteEmptyDir: false
```

**Critical settings for production:**

- Set `autoUpgrade: false` for manual upgrade control — recommended for production clusters with VMs
- Set `maxParallelUpgrades: 1` to upgrade one node at a time
- Set `maxUnavailable: "25%"` (or lower) to limit the blast radius
- **Do not enable `drain`** unless `gpuPodDeletion` is insufficient — drain evicts *all* pods on the node, not just GPU pods. It's a cluster-wide setting that disrupts non-GPU workloads too.

### Updating the driver version

To trigger an upgrade, patch the `ClusterPolicy`:

```bash
# Standard Kubernetes
kubectl patch clusterpolicies.nvidia.com/cluster-policy \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/driver/version", "value":"580.95.05"}]'

# OpenShift — also update repository and image
kubectl patch clusterpolicies.nvidia.com/cluster-policy \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/driver/version", "value":"580.95.05"},
        {"op": "replace", "path": "/spec/driver/repository", "value":"nvcr.io/nvidia"},
        {"op": "replace", "path": "/spec/driver/image", "value":"driver"}]'
```

### Monitoring upgrade progress

```bash
# Check upgrade state per node
kubectl get node -l nvidia.com/gpu.present \
  -ojsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.nvidia\.com/gpu-driver-upgrade-state}{"\n"}{end}'

# Expected output during upgrade:
# k8s-node-1    upgrade-required
# k8s-node-2    upgrade-required
# k8s-node-3    upgrade-required

# Expected output after completion:
# k8s-node-1    upgrade-done
# k8s-node-2    upgrade-done
# k8s-node-3    upgrade-done
```

### Pausing and skipping upgrades

```bash
# Pause all pending upgrades
kubectl patch clusterpolicies.nvidia.com/cluster-policy \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/driver/upgradePolicy/autoUpgrade", "value":false}]'

# Skip upgrade on a single node
kubectl label node <node-name> nvidia.com/gpu-driver-upgrade.skip=true
```

### Failing an upgrade

If an upgrade fails on a node, it's labeled `upgrade-failed`. To retry:

```bash
kubectl label node <node-name> nvidia.com/gpu-driver-upgrade-state=upgrade-required --overwrite
```

Check the upgrade controller logs:

```bash
kubectl logs -n nvidia-gpu-operator gpu-operator-xxxxx | grep controllers.Upgrade
```

---

## Monitoring

### DCGM Exporter

The Data Center GPU Manager (DCGM) exporter runs as a sidecar on each GPU node and exposes GPU metrics to Prometheus:

- GPU utilization, memory, temperature, power
- ECC errors
- NVLink health
- GPU topology

It's enabled by default when you install the operator. Metrics are exposed on port `9400` at `/metrics`.

### Node Status Exporter

Runs on each GPU node and reports GPU health status as node labels. Useful for monitoring tools that read node status rather than scraping pod metrics.

### Prometheus integration

The operator ships with a ServiceMonitor resource that integrates with OCP's Prometheus stack. Metrics are exposed in the `nvidia-gpu-operator` namespace.

Key metrics:

| Metric | Description |
|--------|-------------|
| `gpu_operator_auto_upgrade_enabled` | 1 if auto-upgrade is enabled, 0 if not |
| `gpu_operator_nodes_upgrades_in_progress` | Nodes currently being upgraded |
| `gpu_operator_nodes_upgrades_done` | Nodes successfully upgraded |
| `gpu_operator_nodes_upgrades_failed` | Nodes with failed upgrades |
| `gpu_operator_nodes_upgrades_available` | Nodes ready for upgrade |
| `gpu_operator_nodes_upgrades_pending` | Nodes with pending upgrades |

---

## Troubleshooting

### Node states

The most useful diagnostic is the upgrade state label on each node:

```bash
kubectl get nodes -l nvidia.com/gpu.present \
  -o custom-columns=NAME:.metadata.name,STATE:.metadata.labels.nvidia\.com/gpu-driver-upgrade-state
```

If a node is stuck in a particular state, check events:

```bash
kubectl get events -n nvidia-gpu-operator --sort-by='.lastTimestamp' | grep GPUDriverUpgrade
```

### Driver pod won't start

Common causes:

1. **Missing entitlements** — Driver Toolkit can't reach Red Hat repositories. Check the `nvidia-driver` pod logs.
2. **Wrong driver version** — The driver version in `ClusterPolicy` doesn't match the available images in the repository.
3. **IOMMU not configured** — If you're using vGPU or SR-IOV but IOMMU isn't enabled at the kernel level.
4. **Conflicting driver installation** — A pre-installed NVIDIA driver on the host can conflict with the operator. The operator only manages containerized drivers.

### Driver not loading after pod restart

The driver kernel modules must be unloaded and reloaded when the driver pod restarts. If this fails:

1. Check that the driver pod has the `nvidia.com/gpu-driver-upgrade-state` label in `pod-restart-required` or `upgrade-done`
2. Verify the host has the correct kernel headers for the driver version
3. Check dmesg for kernel module load errors
4. Ensure no other GPU driver (e.g., `nouveau`) is loaded and blocking

### VM GPU passthrough not working

If VMs can't see the GPU after vGPU configuration:

1. Verify the vGPU host driver is installed on all hypervisors
2. Check that the licensing service is reachable
3. Verify the custom vGPU driver container image is in your private registry
4. Confirm SR-IOV is enabled on the NICs and IOMMU is active
5. Check the VM's virt-launcher pod for GPU device injection errors

---

## References

- [NVIDIA GPU Driver Upgrades](resources/nvidia-gpu-driver-upgrades.md) — Full upgrade state machine, all configuration options, metrics, and troubleshooting
- [NVIDIA vGPU Passthrough](resources/nvidia-vgpu-passthrough.md) — vGPU installation for VMs
- [NVIDIA GPU Operator ClusterPolicy](resources/clusterpolicy-baremetal.yaml) — Full ClusterPolicy CRD template
- [NVIDIA GPU Operator values.yaml](resources/nvidia-gpu-operator-values.yaml) — Complete Helm values reference
- [NFD Node Feature Rules](resources/nodefeaturerules-baremetal.yaml) — GPU detection rules for NFD
- [OpenShift GPU Installation](resources/openshift-gpu-install-latest.txt) — OpenShift-specific GPU operator installation guide
- [GCP GKE GPU Nodes](resources/gcp-gke-gpu-nodes.txt) — GPU node management patterns (reference)

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

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
  - [vGPU and GPU passthrough for VMs](#vgpu-and-gpu-passthrough-for-vms)
    - [Two approaches](#two-approaches)
    - [Node workload types](#node-workload-types)
    - [High-level workflow](#high-level-workflow)
    - [Prerequisites](#prerequisites-virt)
    - [Building the vGPU Manager image](#building-the-vgpu-manager-image)
    - [ClusterPolicy for VM workloads](#clusterpolicy-for-vm-workloads)
    - [HyperConverged CR configuration](#hyperconverged-cr-configuration)
    - [Assigning GPUs to a VirtualMachine](#assigning-gpus-to-a-virtualmachine)
    - [vGPU profile selection](#vgpu-profile-selection)
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
  - [VM GPU passthrough or vGPU not working](#vm-gpu-passthrough-or-vgpu-not-working)
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

### vGPU and GPU passthrough for VMs

OpenShift Virtualization (KubeVirt) supports two ways to give a VM direct GPU access: **GPU passthrough** (the whole physical GPU is assigned to one VM) and **vGPU** (the GPU is partitioned into virtual GPU slices, each assignable to a different VM). Both require IOMMU — and therefore a node reboot — as described in [The IOMMU consideration](#the-iommu-consideration).

#### Two approaches {#two-approaches}

There are two distinct approaches for configuring GPU access for OCP Virt VMs. They are **mutually exclusive per node** — pick one and disable the other on that node.

| | GPU Operator approach | OCP Virt native approach |
|---|---|---|
| **Who configures GPU components** | GPU Operator DaemonSets | OCP Virtualization's built-in mediated device support |
| **Supports passthrough** | Yes (VFIO Manager) | Yes (OCP Virt PCI passthrough) |
| **Supports vGPU** | Yes (vGPU Manager + vGPU Device Manager) | Yes (OCP Virt configures mdev directly) |
| **Driver install** | GPU Operator handles via vGPU Manager DaemonSet | Manual or OCP Virt-managed |
| **When to use** | When you already have GPU Operator managing the cluster | When your workload is primarily OCP Virt and Red Hat support coverage is the priority |

> **Mixing is not supported.** If you use the OCP Virt native approach, the GPU Operator's operands must be **disabled** on that node to avoid conflicts. If you use the GPU Operator approach on a node, OCP Virt will not configure mediated devices on it.

This guide covers the **GPU Operator approach**. For the OCP Virt native approach, see the [Red Hat OCP 4.18 Virtualization documentation — Configuring virtual GPUs](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-configuring-virtual-gpus).

#### Node workload types {#node-workload-types}

The GPU Operator uses the label `nvidia.com/gpu.workload.config` on each worker node to decide which operands to deploy. **A node can only run one workload type** — container, VM passthrough, or VM vGPU, not a combination.

| Label value | What the node runs | Operands deployed |
|---|---|---|
| `container` (default) | GPU-accelerated containers | Datacenter Driver, Container Toolkit, Device Plugin, DCGM |
| `vm-passthrough` | VMs with direct GPU passthrough | VFIO Manager, Sandbox Device Plugin, Sandbox Validator |
| `vm-vgpu` | VMs with vGPU slices | vGPU Manager, vGPU Device Manager, Sandbox Device Plugin, Sandbox Validator |

If the label is absent, the node is treated as `container`. To change the default cluster-wide, set `sandboxWorkloads.defaultWorkload` in ClusterPolicy.

Label a node:

```bash
# GPU passthrough
oc label node <node-name> --overwrite nvidia.com/gpu.workload.config=vm-passthrough

# vGPU
oc label node <node-name> --overwrite nvidia.com/gpu.workload.config=vm-vgpu
```

#### High-level workflow {#high-level-workflow}

**For GPU passthrough:**

1. Enable IOMMU via MachineConfig (triggers reboot — see [The IOMMU consideration](#the-iommu-consideration))
2. Label nodes: `nvidia.com/gpu.workload.config=vm-passthrough`
3. Install GPU Operator with `sandboxWorkloads.enabled=true`
4. Add GPU passthrough resources to HyperConverged CR
5. Create VirtualMachine with GPU device spec

**For vGPU:**

1. Enable IOMMU via MachineConfig (triggers reboot)
2. Build the vGPU Manager image and push to a private registry
3. Label nodes: `nvidia.com/gpu.workload.config=vm-vgpu`
4. Install GPU Operator with `sandboxWorkloads.enabled=true` and vGPU Manager image reference
5. Add vGPU resources to HyperConverged CR
6. (Optional) Set per-node vGPU profile via `nvidia.com/vgpu.config` label
7. Create VirtualMachine with vGPU device spec

#### Prerequisites {#prerequisites-virt}

- OpenShift Virtualization Operator installed
- `virtctl` client installed
- Starting with OCP Virtualization 4.12.3 / 4.13.0, enable the `disableMDevConfiguration` feature gate:

  ```bash
  oc patch hyperconverged -n openshift-cnv kubevirt-hyperconverged \
    --type='json' \
    -p='[{"op": "add", "path": "/spec/featureGates/disableMDevConfiguration", "value": true}]'
  ```

- **For vGPU on Ampere-architecture GPUs (A100, A10, etc.):** SR-IOV must be enabled in the BIOS. Check the [NVIDIA vGPU prerequisites](https://docs.nvidia.com/grid/latest/grid-vgpu-user-guide/index.html#prereqs-vgpu).

- **For vGPU:** An NVIDIA AI Enterprise license (or NVIDIA vGPU Software license) — the vGPU Manager image is not public.

#### Building the vGPU Manager image {#building-the-vgpu-manager-image}

Required for `vm-vgpu` only. Skip this section if you are using GPU passthrough.

The vGPU Manager image packages the NVIDIA vGPU kernel module (`vgpu-kvm.run`) into a container that the GPU Operator DaemonSet installs on each vGPU node. The run file is not publicly distributable.

1. Download the Linux KVM vGPU driver (`.run` file) from the [NVIDIA Licensing Portal](https://nvid.nvidia.com/dashboard/). NVIDIA AI Enterprise customers use the `aie` variant; rename it to `NVIDIA-Linux-x86_64-<version>-vgpu-kvm.run`.
2. Build the vGPU Manager container image using the build instructions in the [NVIDIA vGPU Software documentation](https://docs.nvidia.com/grid/latest/grid-vgpu-user-guide/index.html).
3. Push the image to your private registry.
4. Reference the image in your ClusterPolicy `vgpuManager.driver.repository` and `tag`.

> **EULA:** Uploading the vGPU driver or Manager image to a public registry violates the NVIDIA vGPU EULA.

#### ClusterPolicy for VM workloads {#clusterpolicy-for-vm-workloads}

To enable the GPU Operator to manage VM workloads, set `sandboxWorkloads.enabled=true` in the ClusterPolicy:

```yaml
spec:
  sandboxWorkloads:
    enabled: true
    defaultWorkload: container  # cluster-wide default; override per node with the label
  vgpuManager:
    enabled: true
    driver:
      repository: <your-private-registry>
      image: vgpu-manager
      tag: "<version>"
    driverManager:
      repository: nvcr.io/nvidia/cloud-native
      image: k8s-driver-manager
```

For passthrough-only clusters, `vgpuManager.enabled` can be `false`; only the VFIO Manager and Sandbox Device Plugin are needed.

#### HyperConverged CR configuration {#hyperconverged-cr-configuration}

The `HyperConverged` CR (in the `openshift-cnv` namespace) must be updated to permit GPU devices before VMs can use them.

**GPU passthrough:**

```bash
# Discover the resource name on the node
oc get node <node-name> -o json | \
  jq '.status.allocatable | with_entries(select(.key | startswith("nvidia.com/"))) | with_entries(select(.value != "0"))'
# Example output: { "nvidia.com/GA102GL_A10": "1" }

# Discover the PCI device ID
lspci -nnk -d 10de:
# Example: 65:00.0 3D controller [0302]: NVIDIA Corporation GA102GL [A10] [10de:2236]
```

```yaml
# kubectl patch hyperconverged kubevirt-hyperconverged -n openshift-cnv --type merge --patch:
spec:
  featureGates:
    disableMDevConfiguration: true
  permittedHostDevices:
    pciHostDevices:
    - pciDeviceSelector: "10DE:2236"       # replace with your GPU's PCI ID
      resourceName: nvidia.com/GA102GL_A10  # replace with your resource name
      externalResourceProvider: true        # device is managed by sandbox-device-plugin
```

**vGPU:**

```bash
# Discover vGPU resource names (after GPU Operator has created the devices)
oc get node <node-name> -o json | \
  jq '.status.allocatable | with_entries(select(.key | startswith("nvidia.com/"))) | with_entries(select(.value != "0"))'
# Example output: { "nvidia.com/NVIDIA_A10-12Q": "4" }
```

```yaml
spec:
  featureGates:
    disableMDevConfiguration: true
  permittedHostDevices:
    mediatedDevices:
    - mdevNameSelector: "NVIDIA A10-12Q"          # replace with your vGPU type
      resourceName: nvidia.com/NVIDIA_A10-12Q     # replace with your resource name
      externalResourceProvider: true
```

#### Assigning GPUs to a VirtualMachine {#assigning-gpus-to-a-virtualmachine}

Once permitted in HyperConverged, GPU devices can be assigned in the `VirtualMachine` or `VirtualMachineInstance` spec:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
      domain:
        devices:
          gpus:
          - name: gpu1
            deviceName: nvidia.com/GA102GL_A10    # passthrough
          # or for vGPU:
          # - name: gpu1
          #   deviceName: nvidia.com/NVIDIA_A10-12Q
```

#### vGPU profile selection {#vgpu-profile-selection}

The **vGPU Device Manager** controls which vGPU profile (size and type) is created on each node. It reads a ConfigMap and applies it based on a per-node label.

**Default behavior:** If the node has no `nvidia.com/vgpu.config` label, the default configuration creates Q-series vGPU devices with half the physical GPU memory. On an A10 (24 GB), the default produces two **A10-12Q** devices per GPU.

**Override per node:**

```bash
# Create A10-4Q devices instead (6 per A10 GPU)
oc label node <node-name> --overwrite nvidia.com/vgpu.config=A10-4Q
```

After the vGPU Device Manager applies the new configuration, the Sandbox Device Plugin and Sandbox Validator pods restart. Verify with:

```bash
oc get node <node-name> -o json | \
  jq '.status.allocatable | with_entries(select(.key | startswith("nvidia.com/"))) | with_entries(select(.value != "0"))'
```

> **Changing profiles requires VM shutdown.** If any VM is using a vGPU on the node, it must be stopped or live-migrated before changing the `nvidia.com/vgpu.config` label. The vGPU Device Manager will wait for devices to be free before applying the new profile.

**Custom profiles:** Create a ConfigMap with your configuration and set `vgpuDeviceManager.config.name` in ClusterPolicy:

```yaml
# ConfigMap format
version: v1
vgpu-configs:
  custom-A10-config:
    - devices: all
      vgpu-devices:
        "A10-4Q": 3
        "A10-6Q": 2
```

```bash
oc create configmap custom-vgpu-config -n gpu-operator --from-file=config.yaml=/path/to/file
```

For concrete A40 (48 GB) examples with full configuration files and verification steps, see the [A40 vGPU profile runbook](../../devops/ocp/gpu/vgpu-a40-profiles.md).

On GPUs that support MIG, you can also select MIG-backed vGPU profiles — label the node with the MIG-backed profile name (e.g., `nvidia.com/vgpu.config=A100-4-40C`).

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

### VM GPU passthrough or vGPU not working

**GPU Operator approach — check operator pods first:**

```bash
# Verify workload-specific pods are running on the node
oc get pods -n gpu-operator -o wide | grep <node-name>
# vm-passthrough nodes should show: nvidia-vfio-manager, nvidia-sandbox-device-plugin, nvidia-sandbox-validator
# vm-vgpu nodes should show: nvidia-vgpu-manager-daemonset, nvidia-vgpu-device-manager, nvidia-sandbox-device-plugin
```

**Common causes:**

1. **Wrong node label** — confirm `nvidia.com/gpu.workload.config` is set to `vm-passthrough` or `vm-vgpu` (not `container`, not absent)
2. **IOMMU not active** — reboot happened but IOMMU not confirmed: check `dmesg | grep -i iommu` on the node
3. **`sandboxWorkloads.enabled` not set** — the GPU Operator won't deploy VM-specific operands without it
4. **HyperConverged CR not updated** — devices must be listed in `permittedHostDevices` before the kubevirt scheduler will offer them to VMs
5. **`disableMDevConfiguration` not patched** — for OCP Virt 4.12.3+, this feature gate must be enabled or OCP Virt and the GPU Operator conflict on mdev configuration
6. **SR-IOV not enabled in BIOS** — required for vGPU on Ampere and later architectures; check BIOS settings, not just kernel modules
7. **vGPU Manager image missing or wrong version** — check the vGPU Manager DaemonSet pod logs: `oc logs -n gpu-operator -l app=nvidia-vgpu-manager-daemonset`
8. **Licensing service unreachable** — vGPU requires an active NVIDIA license; check connectivity to your CLS or DLS endpoint from the node
9. **VirtualMachine spec uses wrong `deviceName`** — must match the exact resource name from `oc get node -o json | jq '.status.allocatable'`
10. **Profile change with running VMs** — changing `nvidia.com/vgpu.config` while VMs are running leaves vGPU Device Manager blocked; stop/migrate VMs first

---

## References

- [NVIDIA GPU Driver Upgrades](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-driver-upgrades.html) — Full upgrade state machine, all configuration options, metrics, and troubleshooting
- [NVIDIA GPU Operator with OpenShift Virtualization](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/openshift-virtualization.html) — GPU Operator approach for vGPU and passthrough: node workload types, HyperConverged CR configuration, vGPU profile management
- [Red Hat OCP 4.18 Virtualization — Configuring virtual GPUs](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-configuring-virtual-gpus) — OCP Virt native approach (alternative to GPU Operator approach)
- [NVIDIA GPU Operator vGPU / NVAIE](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/openshift/nvaie-with-ocp.html) — vGPU installation for VMs with NVIDIA AI Enterprise
- [NVIDIA GPU Operator ClusterPolicy](../../devops/ocp/gpu/clusterpolicy-baremetal.yaml) — Full ClusterPolicy CRD template
- [NVIDIA GPU Operator values.yaml](../../devops/ocp/gpu/nvidia-gpu-operator-values.yaml) — Complete Helm values reference
- [NFD Node Feature Rules](../../devops/ocp/gpu/nodefeaturerules-baremetal.yaml) — GPU detection rules for NFD
- [NVIDIA GPU Operator on OpenShift](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/openshift/contents.html) — Official NVIDIA documentation for OCP-specific installation and management (live upstream)

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

# Runbook: A40 vGPU Profiles

> **Target:** OpenShift 4.18+ with GPU Operator + OpenShift Virtualization
> **GPU:** NVIDIA A40 (48 GB VRAM)
> **Reference:** [GPU Operator vGPU docs](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/openshift-virtualization.html)

---

## A40 Profile Mapping

The A40 has 48 GB VRAM. The Q-series naming convention uses the **framebuffer size in GB** (not the slice count), so the profile name is `A40-<GB_per_slice>Q`.

Source: [NVIDIA Grid vGPU User Guide — Virtual GPU Types for NVIDIA A40](https://docs.nvidia.com/vgpu/latest/grid-vgpu-user-guide/#virtual-gpu-types-grid)

| Profile | Framebuffer | VMs per GPU | Notes |
|---------|-----------|-------------|-------|
| `A40-48Q` | 48 GB | 1 | Full GPU |
| `A40-24Q` | 24 GB | 2 | |
| `A40-16Q` | 16 GB | 3 | |
| `A40-12Q` | 12 GB | 4 | |
| **`A40-8Q`** | **8 GB** | **6** | ← target |
| `A40-6Q` | 6 GB | 8 | |
| `A40-4Q` | 4 GB | 12 | |
| `A40-3Q` | 3 GB | 16 | |
| `A40-2Q` | 2 GB | 24 | |
| `A40-1Q` | 1 GB | 32 | |

**An 8 GB vGPU slice = `A40-8Q` (6 VMs per A40 GPU).**

### vGPU Series

Each A40 is available in multiple **series** (Q, B, A, C), each optimized for a different workload and requiring a different license. The series letter is the **last character** of the profile name (`A40-8Q`, `A40-8B`, etc.).

| Series | Letter | Purpose | Max FPS | License | Display |
|--------|--------|---------|---------|---------|--------|
| **Q-series** | Q | Virtual workstations (CAD, video, design) | 60 FPS | vWS | Full |
| **B-series** | B | Virtual desktops (office, business) | 45 FPS | vPC | Full |
| **A-series** | A | App streaming / session-based (RDSH, Citrix) | 60 FPS | vApps | Single low-res console |
| **C-series** | C | Compute only — no display | — | vCS | None |

**Key differences:**

- **Same framebuffer, different license** — `A40-8Q`, `A40-8B`, `A40-8A`, and `A40-8C` all have 8 GB/framebuffer and fit 6 VMs per GPU, but require different license editions.
- **Q-series is the default** — the GPU Operator only enables Q and C profiles out of the box. B and A series may require additional DRM/license configuration.
- **C-series has no display** — use this for VMs that are pure CUDA/ML compute workloads with no graphical output.

Source: [NVIDIA Grid vGPU User Guide — Virtual GPU Types Reference](https://docs.nvidia.com/vgpu/latest/grid-vgpu-user-guide/#virtual-gpu-types-grid)

---

## Prerequisites

1. GPU Operator installed with `vgpuManager` and `vgpuDeviceManager` enabled
2. NVIDIA vGPU license server (NLS) configured in ClusterPolicy
3. A40 hardware detected by NFD (`feature.node.kubernetes.io/pci-10de.present=true`)
4. IOMMU enabled on host (BIOS + kernel parameter)
5. Node labeled for vGPU workloads: `nvidia.com/gpu.workload.config=vm-vgpu`

---

## Method 1: Per-Node Label (Quick Test)

One node, quick to validate:

```bash
# Label the node — changes profile to 8 GB slices (A40-8Q)
oc label node <gpu-node> --overwrite nvidia.com/vgpu.config=A40-8Q

# Verify vGPU Device Manager is applying the change
oc logs -n nvidia-gpu-operator -l app=nvidia-vgpu-device-manager --tail=50

# Check mediated devices created
oc debug node/<gpu-node>
chroot /host
ls /sys/bus/mdev/devices/
```

**What happens:** The vGPU Device Manager watches the label, destroys existing vGPU devices, and recreates them with the new profile. **VMs using vGPU on the node must be stopped or migrated first.**

---

## Method 2: ConfigMap-Backed (Multi-Node)

Explicit, auditable, scales to many nodes:

### Step 1: Create ConfigMap

```yaml
# vgpu-a40-8q-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: a40-8q-config
  namespace: nvidia-gpu-operator
data:
  config.yaml: |
    version: v1
    vgpu-configs:
      a40-8q:
        - devices: all
          vgpu-devices:
            "A40-8Q": 6
```

```bash
oc create -f vgpu-a40-8q-config.yaml
```

### Step 2: Reference in ClusterPolicy

```yaml
# Edit or create the ClusterPolicy
oc edit clusterpolicy gpu-cluster-policy -n nvidia-gpu-operator
# Or create it:
```

```yaml
apiVersion: nvidia.com/v1
kind: ClusterPolicy
metadata:
  name: gpu-cluster-policy
  namespace: nvidia-gpu-operator
spec:
  vgpuDeviceManager:
    enabled: true
    config:
      name: a40-8q-config
      default: "a40-8q"
```

### Step 3: Label Nodes

```bash
# Apply the label — the value is the config key from the ConfigMap
oc label node <gpu-node> --overwrite nvidia.com/vgpu.config=a40-8q

# Or apply to multiple nodes at once
for node in $(oc get nodes -l nvidia.com/gpu-node=true --no-headers -o name); do
  oc label node "$node" --overwrite nvidia.com/vgpu.config=a40-8q
done
```

---

## Verify vGPU Profile is Active

### Check node allocatable resources

```bash
oc get node <gpu-node> -o json | jq '.status.allocatable | to_entries[] | select(.key | startswith("nvidia.com/"))'
# Should show: "nvidia.com/A40-8Q": "6"
```

### Check vGPU Device Manager logs

```bash
oc logs -n nvidia-gpu-operator -l app=nvidia-vgpu-device-manager --tail=100
```

### Check mediated devices on the node

```bash
oc debug node/<gpu-node>
chroot /host
ls -la /sys/bus/mdev/devices/
# Should show 6 vGPU devices
```

### Check NFD labels

```bash
oc get node <gpu-node> --show-labels | grep nvidia
```

---

## VM Configuration

### VirtualMachine CR

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: a40-vm
  namespace: default
spec:
  running: true
  template:
    spec:
      nodeSelector:
        nvidia.com/vgpu.config: a40-8q
      domain:
        devices:
          gpus:
            - deviceName: nvidia.com/A40-8Q
              name: gpu1
        resources:
          requests:
            memory: 8Gi
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/containerdisks/fedora:latest
```

### Guest driver (VM boot step)

After the VM boots, install the NVIDIA vGPU guest driver inside the VM:

1. Download from [NVIDIA Licensing Portal](https://nvid.nvidia.com/dashboard/)
2. Rename to `NVIDIA-Linux-x86_64-<version>-vgpu-kvm.run`
3. Install: `./NVIDIA-Linux-x86_64-<version>-vgpu-kvm.run`
4. Verify: `nvidia-smi` inside the VM

---

## Troubleshooting

### vGPU Device Manager blocked (VMs still using vGPU)

```bash
# Check for running VMs on the node
oc get vmi -A -o wide | grep <gpu-node>

# Stop/migrate VMs first
virtctl stop <vm-name> -n <namespace>

# Then retry the profile change
oc label node <gpu-node> --overwrite nvidia.com/vgpu.config=A40-8Q
```

### NLS licensing not configured

vGPU devices won't activate without a license server. Configure in ClusterPolicy:

```yaml
spec:
  driver:
    licensingConfig:
      configMapName: nls-config
      nlsEnabled: true
```

### Profile not found (wrong name)

The exact profile name depends on the driver version and license bundle. Check what's available:

```bash
# List profiles supported by the current driver
oc debug node/<gpu-node>
chroot /host
ls /sys/bus/mdev/devices
nvidia-smi --query-gpu=uuid,name --format=csv

# Check vgpu-device-manager logs for rejected profiles
oc logs -n nvidia-gpu-operator -l app=nvidia-vgpu-device-manager --tail=50
```

### Mediated devices not created

```bash
# Check if the node is labeled for vGPU workloads
oc get node <gpu-node> --show-labels | grep gpu.workload

# If missing:
oc label node <gpu-node> nvidia.com/gpu.workload.config=vm-vgpu

# Check vgpuManager is enabled in ClusterPolicy
oc get clusterpolicy -n nvidia-gpu-operator -o yaml | grep vgpuManager

# Restart the vgpu-manager DaemonSet if needed
oc delete pod -n nvidia-gpu-operator -l app=nvidia-vgpu-manager --force
```

---

## Profile Changes (Production)

**Profile changes require VM shutdown.** The vGPU Device Manager will block if any VM on the node is using a vGPU.

1. **Stop/migrate VMs:**
   ```bash
   # For VMs without GPU
   virtctl migrate <vm-name> -n <namespace>
   
   # For VMs with GPU (must stop)
   virtctl stop <vm-name> -n <namespace>
   ```

2. **Apply profile change:**
   ```bash
   oc label node <gpu-node> --overwrite nvidia.com/vgpu.config=<new-profile>
   ```

3. **Verify:**
   ```bash
   oc logs -n nvidia-gpu-operator -l app=nvidia-vgpu-device-manager --tail=20
   ```

4. **Start VMs:**
   ```bash
   virtctl start <vm-name> -n <namespace>
   ```

---

## Related

- [Full GPU node management guide](../../../docs/ai-engineering/openshift-gpu-node-management.md)
- [vGPU User Guide](https://docs.nvidia.com/grid/latest/grid-vgpu-user-guide/index.html)
- [GPU Operator + OCP Virt](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/openshift-virtualization.html)

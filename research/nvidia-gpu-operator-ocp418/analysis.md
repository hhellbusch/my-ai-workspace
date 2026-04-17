# NVIDIA GPU Operator Installation Impact Analysis
## OpenShift Container Platform 4.18 with OpenShift Virtualization

**Document Version:** 1.0  
**Date:** January 22, 2026  
**Target Environment:** Production OCP 4.18 cluster with OpenShift Virtualization workloads

---

## 1. Executive Summary

### High-Level Impact Assessment

Installing the NVIDIA GPU Operator on your production OpenShift 4.18 cluster running OpenShift Virtualization will have **MODERATE-to-HIGH impact** on running workloads, depending on your deployment strategy. The installation requires node-level changes including driver deployment and kernel module loading, which necessitates node reboots.

### Go/No-Go Recommendation

**CONDITIONAL GO** - Proceed with installation using a phased approach with the following conditions:

✅ **Proceed if:**
- You can schedule maintenance windows for node reboots
- You have capacity to migrate or temporarily shut down VMs on GPU-designated nodes
- Your OCP version is 4.18.24 or later (NOT 4.18.22 or 4.18.23)
- You understand and can accommodate the node workload segregation requirement
- You have bare metal worker nodes available if enabling GPU support for VMs

⚠️ **Defer if:**
- Your cluster is running OCP 4.18.22 or 4.18.23 (upgrade first to 4.18.24+)
- You cannot afford any VM downtime during installation
- You need to mix GPU containers and GPU VMs on the same worker nodes
- All worker nodes are currently at capacity with critical production VMs

### Critical Risks and Mitigations Summary

| Risk | Severity | Mitigation |
|------|----------|------------|
| Node reboots causing VM downtime | HIGH | Phased rollout, scheduled maintenance windows, VM migration to non-GPU nodes |
| Known issue with OCP 4.18.22-23 | CRITICAL | Verify cluster version; upgrade to 4.18.24+ before GPU Operator installation |
| Workload type mixing not supported | HIGH | Proper node labeling and segregation before installation |
| No automatic VM live migration with GPU passthrough | MEDIUM | Plan for manual VM migration or scheduled downtime |
| Manual vGPU guest driver installation required | LOW | Document post-installation VM configuration steps |

---

## 2. Environment Overview

### Cluster Configuration Summary
- **Platform:** OpenShift Container Platform 4.18.x
- **Current State:** Production capacity with active workloads
- **Primary Workload:** OpenShift Virtualization (OCP Virt) with multiple running VMs
- **Worker Node Type:** Must verify if bare metal (required for GPU-accelerated VMs)

### Current Workload Profile
- Multiple virtual machines running on worker nodes
- Assumed: No current GPU acceleration in use
- Production environment requiring high availability

### Specific Concerns Addressed
1. Impact on currently running virtual machines
2. Node reboot requirements and timing
3. Potential service interruptions during installation
4. Performance impacts during and after installation
5. Rollback capabilities if issues occur
6. Version compatibility with OCP 4.18

---

## 3. Pre-Installation Analysis

### Prerequisites and Requirements

#### Mandatory Prerequisites

**1. OpenShift Version Verification** ⚠️ CRITICAL
```bash
oc version
```
**Required Action:** Ensure you are running OCP 4.18.24 or later
- **Known Issue:** OCP versions 4.18.22 and 4.18.23 have a breaking change in `crun` that causes GPU Operator failures
- **Source:** NVIDIA GPU Operator Installation and Upgrade Overview (v25.3.3)
- **Resolution:** Upgrade to OCP 4.18.24 or later before proceeding

**2. Node Feature Discovery (NFD) Operator**
- Must be installed before GPU Operator deployment
- Automatically deployed by GPU Operator as a dependency
- Check if already installed:
```bash
oc get operators -n openshift-nfd
oc get nodefeaturediscovery -A
```

**3. Cluster Administrator Access**
```bash
oc auth can-i '*' '*' --all-namespaces
```

**4. Bare Metal Worker Nodes (for GPU VMs)**
- Worker nodes running GPU-accelerated VMs must be bare metal
- Virtual worker nodes can run GPU-accelerated containers but NOT GPU VMs
- Verify node type:
```bash
oc get nodes -o wide
oc describe node <node-name> | grep -i "virt\|metal"
```

**5. IOMMU Driver Enablement (for GPU Passthrough/vGPU)**
- Required on host systems for GPU device assignment to VMs
- Must be enabled in BIOS and kernel parameters

#### Optional but Recommended

**6. Additional Worker Node Capacity**
- Ability to migrate VMs to non-GPU nodes during installation
- Node capacity for workload redistribution

**7. Monitoring and Observability**
- Ensure Prometheus is functioning
- Verify monitoring stack health:
```bash
oc get pods -n openshift-monitoring
```

### Compatibility Verification Checklist

- [ ] OCP version is 4.18.24 or later (NOT 4.18.22 or 4.18.23)
- [ ] Cluster has cluster-admin access available
- [ ] At least one worker node with NVIDIA GPU hardware
- [ ] Worker nodes for GPU VMs are bare metal
- [ ] IOMMU enabled on hosts (if using GPU passthrough/vGPU)
- [ ] NFD Operator prerequisites understood
- [ ] Existing GPU Add-on NOT installed (deprecated, must be removed)
- [ ] Sufficient node capacity for workload migration during maintenance
- [ ] Network policies allow operator communication
- [ ] Storage available for container images (~10-15 GB per node)

### Pre-Installation Testing Recommendations

**1. Version Verification**
```bash
oc version --short
```

**2. Node Resource Check**
```bash
oc adm top nodes
oc describe nodes | grep -A 5 "Allocated resources"
```

**3. GPU Hardware Detection** (after NFD installation)
```bash
oc describe node <gpu-node-name> | grep -i nvidia
```

**4. Test VM Migration** (if planning to migrate VMs)
```bash
virtctl migrate <vm-name> --dry-run
```

**5. Create Test Namespace**
```bash
oc create namespace gpu-operator-test
oc delete namespace gpu-operator-test
```

---

## 4. Impact Assessment by Area

### 4.1 Node Impact

#### Which Nodes Will Be Affected

**All GPU-designated worker nodes will be affected** during installation. The GPU Operator uses node labeling to determine which nodes receive GPU components.

**Node Selection Strategy:**
- By default, GPU Operator targets all nodes with NVIDIA GPU hardware detected by NFD
- Can be restricted using ClusterPolicy node selectors
- Recommended: Use explicit node labeling to control rollout

**Nodes NOT Affected:**
- Nodes without GPU hardware
- Nodes not labeled for GPU workloads (if using selective deployment)
- Control plane nodes (never receive GPU Operator components)

#### What Changes Occur on Nodes

**DaemonSet Deployments:**

The GPU Operator deploys multiple DaemonSets on target nodes depending on workload configuration:

**For GPU Container Workloads:**
- **nvidia-driver-daemonset:** Installs NVIDIA datacenter drivers and kernel modules
- **nvidia-container-toolkit-daemonset:** Container runtime integration
- **nvidia-device-plugin-daemonset:** Kubernetes GPU resource advertisement
- **nvidia-dcgm-exporter:** GPU metrics and monitoring
- **gpu-feature-discovery:** GPU property detection and labeling

**For GPU Passthrough VMs:**
- **nvidia-vfio-manager:** VFIO device management for PCI passthrough
- **nvidia-sandbox-device-plugin:** Device plugin for VM GPU assignment

**For vGPU VMs:**
- **nvidia-vgpu-manager:** NVIDIA vGPU Manager driver
- **nvidia-vgpu-device-manager:** vGPU device lifecycle management
- **nvidia-sandbox-device-plugin:** Device plugin for vGPU assignment

**Filesystem Changes:**
- Driver installation in `/run/nvidia` (ephemeral)
- Kernel modules loaded (`nvidia`, `nvidia-uvm`, etc.)
- Device nodes created in `/dev` (`/dev/nvidia0`, `/dev/nvidiactl`, etc.)

#### Node Reboot Requirements

**Yes, node reboots are typically required** during initial GPU driver installation.

**When Reboots Occur:**
- During driver DaemonSet rollout when kernel modules are first loaded
- After driver updates or GPU Operator upgrades
- When switching between driver configurations (e.g., datacenter driver ↔ vGPU Manager)

**Reboot Behavior:**
- Nodes are cordoned and drained before driver installation
- Workloads are evicted from nodes during the drain process
- Node reboots to load new kernel modules
- Node rejoins cluster after successful driver initialization
- Validation pods confirm proper driver installation

**Timeline:**
- Driver installation + reboot: 10-20 minutes per node
- Validation: 2-5 minutes per node
- Total per-node impact: 15-25 minutes

**Mitigation:**
- Phased rollout across node pools
- Scheduled maintenance windows
- Ensure adequate capacity on non-GPU nodes

---

### 4.2 OCP Virt Impact

#### GPU Passthrough vs vGPU Considerations

**GPU Passthrough:**
- Entire GPU assigned to single VM
- Best performance (native GPU access)
- Limited scalability (one GPU per VM)
- Requires VFIO Manager component
- VM cannot be live migrated while GPU attached

**vGPU (Virtual GPU):**
- GPU partitioned into multiple virtual instances
- Multiple VMs share single physical GPU
- Better density and resource utilization
- Requires NVIDIA vGPU Manager driver and license
- VM may support live migration (depends on vGPU type)
- Manual guest driver installation required in each VM

**Recommendation for OCP Virt:** Start with GPU passthrough for simplicity unless VM density requirements dictate vGPU.

#### Critical Constraint: Workload Type Segregation

**⚠️ MOST IMPORTANT CONSTRAINT FOR YOUR ENVIRONMENT:**

**A worker node can run ONE of the following, but NOT a combination:**
1. GPU-accelerated containers
2. GPU-accelerated VMs with GPU passthrough
3. GPU-accelerated VMs with vGPU

**Source:** NVIDIA GPU Operator with OpenShift Virtualization documentation (all versions)

**Implications:**
- Nodes must be dedicated to either container workloads OR VM workloads
- Cannot mix GPU containers and GPU VMs on same node
- Requires careful architecture planning before installation
- Node labeling controls which components are deployed

**Implementation:**
```bash
# Label nodes for VM passthrough workloads
oc label node <node-name> nvidia.com/gpu.workload.config=vm-passthrough

# Label nodes for VM vGPU workloads
oc label node <node-name> nvidia.com/gpu.workload.config=vm-vgpu

# Label nodes for container workloads (default if no label)
# No label needed - receives standard container components
```

#### Impact on Running VMs During Installation

**Direct Impact:**
- VMs running on nodes designated for GPU Operator installation will be disrupted
- Node drain operation will trigger VM shutdown or migration
- Downtime: 15-25 minutes per node during installation

**No Impact Scenario:**
- VMs running on nodes NOT designated for GPU installation are unaffected
- Recommended: Keep existing VMs on non-GPU nodes during initial rollout

**VM Behavior During Node Drain:**
```bash
# Check VM eviction strategy
oc get vmi <vm-name> -o jsonpath='{.spec.evictionStrategy}'
```
- `LiveMigrate`: VM attempts live migration to another node (if possible)
- `None` or missing: VM is shut down and must be manually restarted
- GPU-attached VMs cannot live migrate (must be shut down)

#### VM Migration Requirements

**VMs Without GPU:**
- Can be live migrated to non-GPU nodes before installation
- No special requirements

**VMs With GPU Passthrough:**
- **Cannot be live migrated** while GPU device is attached
- Must be shut down, GPU detached, then migrated
- Plan for service interruption

**VMs With vGPU:**
- Live migration support depends on vGPU type and configuration
- Most vGPU profiles do NOT support live migration
- Assume migration not possible; plan for downtime

**Migration Commands:**
```bash
# Live migrate VM (only works if no GPU attached)
virtctl migrate <vm-name>

# Stop VM before GPU node maintenance
virtctl stop <vm-name>

# Remove GPU device from VM (edit VirtualMachine spec)
oc edit vm <vm-name>
# Remove hostDevices or gpus section

# Start VM on different node
virtctl start <vm-name>
```

#### PCI Device Assignment Implications

**For GPU Passthrough:**
- Requires PCI device to be available on host
- Device must be bound to VFIO driver
- One device per VM (1:1 mapping)
- VM sees physical GPU directly

**VirtualMachine Configuration Example:**
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: gpu-vm
spec:
  template:
    spec:
      domain:
        devices:
          gpus:
            - deviceName: nvidia.com/GP102GL_Tesla_P40
              name: gpu1
```

**For vGPU:**
- Virtual GPU instance assigned to VM
- Multiple vGPU instances per physical GPU
- Requires vGPU Manager and license server
- VM sees virtual GPU device

#### Host Device Management

**HostPathConfig:**
- GPU Operator manages device nodes automatically
- Devices exposed via `/dev/nvidia*`
- Managed by sandbox-device-plugin for VMs

**Device Permissions:**
- Automatic via GPU Operator
- No manual SELinux or permission configuration needed

**Device Discovery:**
```bash
# List available GPU devices on node
oc debug node/<node-name>
chroot /host
ls -la /dev/nvidia*
```

**Device Allocation:**
- Tracked by Kubernetes device plugin
- Visible in node capacity:
```bash
oc describe node <node-name> | grep nvidia.com
```

---

### 4.3 Workload Impact

#### Which Workloads Are Affected

**Directly Affected:**
- VMs running on nodes designated for GPU Operator installation
- Pods running on nodes during drain/reboot cycle
- Any workload requiring node resources during maintenance window

**Indirectly Affected:**
- Services with reduced replica count during node maintenance
- Workloads experiencing increased resource pressure on remaining nodes
- Monitoring and logging systems (increased load during rollout)

**Not Affected:**
- Workloads on nodes not designated for GPU installation
- Control plane components (API server, etcd, etc.)
- Cluster-wide services with sufficient replica distribution

#### Node Drain Requirements

**Yes, nodes are drained** before driver installation to ensure clean driver loading.

**Drain Process:**
1. Node is cordoned (marked unschedulable)
2. Grace period applied to running pods
3. Pods are gracefully terminated
4. VMs are migrated or shut down (depending on eviction strategy)
5. Node drain completes
6. Driver installation proceeds
7. Node reboots
8. Node uncordoned after successful validation

**Control Drain Behavior:**
```bash
# Manual drain (if needed for testing)
oc adm drain <node-name> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force \
  --grace-period=300

# Uncordon after maintenance
oc adm uncordon <node-name>
```

#### Pod Eviction Behavior

**Standard Pods:**
- Graceful termination with configured grace period (default 30s)
- Rescheduled on other available nodes automatically
- May experience brief interruption during migration

**StatefulSet Pods:**
- Terminated in reverse ordinal order
- Rescheduled according to pod management policy
- May wait for storage to detach before rescheduling

**DaemonSet Pods:**
- Ignored during drain (continue running)
- GPU Operator DaemonSets exempt from eviction

**VirtualMachineInstance Pods:**
- Behavior depends on eviction strategy (see VM section above)
- May trigger live migration or shutdown

#### Scheduling Changes

**GPU Nodes (After Installation):**
- Advertise GPU resources in node capacity
```yaml
nvidia.com/gpu: "1"  # Number of GPUs per node
```
- Pods must request GPU resources to be scheduled on GPU nodes
- Non-GPU pods may still schedule on GPU nodes unless taints applied

**Recommended: Apply Taints**
```bash
# Prevent non-GPU workloads from scheduling on GPU nodes
oc adm taint nodes <node-name> nvidia.com/gpu=present:NoSchedule
```

**Tolerations for GPU Workloads:**
```yaml
apiVersion: v1
kind: Pod
spec:
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  containers:
    - name: gpu-app
      resources:
        limits:
          nvidia.com/gpu: 1
```

#### Resource Allocation Impacts

**Node Resources Consumed by GPU Operator:**
- CPU: ~500m per node (combined across all DaemonSets)
- Memory: ~1-2 GB per node (driver + monitoring + device plugins)
- Storage: ~10-15 GB per node (container images)

**GPU Resource Tracking:**
- GPUs tracked as extended resources
- Visible in `oc describe node`
- Schedulable like CPU/memory

**Cluster-Wide Impact:**
- Slight increase in control plane load during rollout
- Image pulls across nodes (registry traffic)
- Increased monitoring metrics volume (DCGM exporter)

---

### 4.4 Performance Impact

#### During Installation

**Network:**
- Container image pulls (10-15 GB per node)
- Increased API server traffic during DaemonSet rollout
- Workload migration network traffic

**CPU:**
- Driver compilation (if required)
- Container runtime overhead during image extraction
- Pod rescheduling and initialization

**Memory:**
- Driver loading and initialization
- Temporary spike during pod migration

**Timeline:**
- Peak impact during node drain and driver installation (15-25 min per node)
- Gradual return to normal as nodes complete installation

**Mitigation:**
- Stagger node maintenance (don't drain all nodes simultaneously)
- Perform installation during low-traffic periods
- Pre-pull images if possible

#### Steady-State (Post-Installation)

**Positive Impacts:**
- GPU-accelerated workloads gain access to GPU resources
- Improved performance for GPU-enabled applications
- Better resource utilization (GPUs previously unused)

**Neutral/Negative Impacts:**
- Slight CPU overhead from GPU monitoring (DCGM exporter)
- Memory consumed by GPU Operator components (~1-2 GB per node)
- Additional metrics in monitoring system (minimal impact)

**No Impact on Non-GPU Workloads:**
- Existing workloads without GPU requests unaffected
- No performance degradation for CPU/memory-only workloads

---

### 4.5 Network/Storage Impact

#### Network Considerations

**During Installation:**
- Large image pulls from registry (~10-15 GB per node)
- API server traffic increase (DaemonSet coordination)
- Pod migration traffic (if VMs/pods migrate)

**Steady-State:**
- Minimal additional network traffic
- DCGM metrics export to Prometheus (minor)
- GPU Operator health checks and leader election

**No Special Network Requirements:**
- No additional firewall rules needed
- No external connectivity required (except image registry)
- Existing cluster networking sufficient

#### Storage Considerations

**Node-Local Storage:**
- Container images: ~10-15 GB per GPU node
- Driver cache: ~2-3 GB per node
- Logs: ~500 MB per node (rotated automatically)

**Persistent Storage:**
- Not required for GPU Operator itself
- GPU workloads may require storage (application-dependent)

**Registry Impact:**
- Multiple nodes pulling large images simultaneously
- Ensure registry has sufficient bandwidth and storage

**Cleanup:**
```bash
# Remove unused GPU Operator images (if needed)
oc adm prune images --confirm
```

---

## 5. Risk Matrix

| Risk ID | Risk Description | Severity | Likelihood | Impact | Mitigation Strategy |
|---------|------------------|----------|------------|--------|---------------------|
| R-1 | OCP version 4.18.22 or 4.18.23 incompatibility with GPU Operator | **CRITICAL** | Medium | Complete failure of GPU Operator installation | Verify OCP version before installation; upgrade to 4.18.24+ if on affected versions |
| R-2 | Node reboots causing VM downtime | **HIGH** | High | 15-25 minutes downtime per node; service interruption | Phased rollout, scheduled maintenance windows, migrate VMs to non-GPU nodes before installation |
| R-3 | Mixing GPU workload types on same node | **HIGH** | Medium | GPU Operator misconfiguration, workload failures | Proper node labeling before installation; use `nvidia.com/gpu.workload.config` label |
| R-4 | Insufficient node capacity during rollout | **HIGH** | Medium | Cascading failures, pod evictions, service degradation | Verify capacity before installation; ensure headroom on non-GPU nodes |
| R-5 | VMs cannot live migrate with GPU attached | **MEDIUM** | High | Planned downtime required for GPU VM maintenance | Document requirement; plan maintenance windows; design for downtime |
| R-6 | Driver installation failure | **MEDIUM** | Low | Node remains in NotReady state; GPU unavailable | Pre-validate hardware compatibility; ensure RHCOS kernel compatibility; monitor validator pods |
| R-7 | Conflicting existing GPU configuration | **MEDIUM** | Low | Installation conflict, unpredictable behavior | Remove deprecated GPU Add-on; verify no manual driver installation exists |
| R-8 | Insufficient storage for images | **MEDIUM** | Low | Image pull failures, incomplete installation | Verify node storage before installation; clean up unused images |
| R-9 | Cluster performance degradation during rollout | **LOW** | Medium | Temporary performance impact during installation | Install during maintenance window; stagger node updates |
| R-10 | Manual vGPU guest driver installation forgotten | **LOW** | High | VMs with vGPU don't see GPU device | Document post-installation vGPU VM configuration steps; create runbook |
| R-11 | IOMMU not enabled on hosts | **MEDIUM** | Medium | GPU passthrough/vGPU will not work | Pre-validate IOMMU configuration; enable in BIOS and kernel parameters |
| R-12 | Incorrect namespace deployment | **LOW** | Low | Prometheus monitoring not automatic | Use recommended `nvidia-gpu-operator` namespace; manually enable monitoring if using different namespace |

### Risk Assessment Summary

**Critical Risks:** 1  
**High Risks:** 4  
**Medium Risks:** 5  
**Low Risks:** 2  

**Overall Risk Level:** **MEDIUM-HIGH** (with proper mitigation planning)

---

## 6. Installation Strategy Recommendations

### Phased Rollout Plan

#### Phase 1: Pre-Installation Validation (1-2 hours)

**Objectives:**
- Verify cluster readiness
- Confirm hardware compatibility
- Validate prerequisites

**Tasks:**
1. Check OCP version (must be 4.18.24+)
```bash
oc version
```

2. Verify cluster health
```bash
oc get nodes
oc get co  # All cluster operators should be Available=True
```

3. Check for existing GPU configuration
```bash
oc get operators | grep -i gpu
oc get subscription -A | grep -i nvidia
```

4. Identify GPU-capable nodes
```bash
# After NFD installation
oc get nodes -l feature.node.kubernetes.io/pci-10de.present=true
```

5. Verify node capacity and VM distribution
```bash
oc get vmi -A -o wide
oc adm top nodes
```

6. Document current state
- List of GPU-capable nodes
- Current VM placement
- Node resource utilization
- Backup of critical VM configurations

---

#### Phase 2: Install Node Feature Discovery (NFD) Operator (30 minutes)

**If not already installed:**

1. Install NFD Operator
```bash
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: nfd
  namespace: openshift-nfd
spec:
  channel: stable
  installPlanApproval: Automatic
  name: nfd
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

2. Create NodeFeatureDiscovery instance
```bash
cat <<EOF | oc apply -f -
apiVersion: nfd.openshift.io/v1
kind: NodeFeatureDiscovery
metadata:
  name: nfd-instance
  namespace: openshift-nfd
spec:
  operand:
    image: registry.redhat.io/openshift4/ose-node-feature-discovery:v4.18
EOF
```

3. Verify NFD is running
```bash
oc get pods -n openshift-nfd
oc get nodes --show-labels | grep feature.node.kubernetes.io
```

---

#### Phase 3: Label GPU Nodes for Workload Type (15 minutes)

**Critical Step:** Determine which nodes will support which GPU workload types.

**Decision Matrix:**
| Use Case | Label | Driver Installed |
|----------|-------|------------------|
| GPU containers (default) | None needed | NVIDIA Datacenter Driver |
| GPU passthrough VMs | `nvidia.com/gpu.workload.config=vm-passthrough` | VFIO Manager |
| vGPU VMs | `nvidia.com/gpu.workload.config=vm-vgpu` | NVIDIA vGPU Manager |

**Labeling Commands:**
```bash
# For GPU passthrough VMs (recommended for OCP Virt)
oc label node <node-name> nvidia.com/gpu.workload.config=vm-passthrough

# For vGPU VMs (if using vGPU licensing)
oc label node <node-name> nvidia.com/gpu.workload.config=vm-vgpu

# For GPU containers (no label needed, this is default)
# Just don't label the node
```

**Recommendation for Your Environment:**
- Start with 1-2 nodes labeled for GPU passthrough VMs
- Keep remaining nodes without GPU labels (for existing VMs)
- Expand GPU node pool after successful validation

---

#### Phase 4: Install GPU Operator (30 minutes)

1. Create namespace (recommended)
```bash
oc create namespace nvidia-gpu-operator
```

2. Install GPU Operator via OperatorHub
```bash
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: gpu-operator-certified
  namespace: nvidia-gpu-operator
spec:
  channel: v24.9
  installPlanApproval: Manual  # Use Manual for production control
  name: gpu-operator-certified
  source: certified-operators
  sourceNamespace: openshift-marketplace
EOF
```

3. Approve install plan (manual approval)
```bash
oc get installplan -n nvidia-gpu-operator
oc patch installplan <install-plan-name> -n nvidia-gpu-operator \
  --type merge --patch '{"spec":{"approved":true}}'
```

4. Wait for operator to be ready
```bash
oc get csv -n nvidia-gpu-operator
oc get pods -n nvidia-gpu-operator
```

---

#### Phase 5: Create ClusterPolicy with Node Selector (15 minutes)

**For Controlled Rollout:** Use node selector to target specific nodes initially.

1. Create ClusterPolicy with node selector
```bash
cat <<EOF | oc apply -f -
apiVersion: nvidia.com/v1
kind: ClusterPolicy
metadata:
  name: gpu-cluster-policy
spec:
  operator:
    defaultRuntime: crio
    initContainer:
      image: cuda
      repository: nvcr.io/nvidia
      version: 12.3.1-base-ubi8
  daemonsets:
    tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
    priorityClassName: system-node-critical
  driver:
    enabled: true
    repository: nvcr.io/nvidia
    version: "545.23.08"
    nodeSelector:
      nvidia.com/gpu-node: "true"  # Only target labeled nodes initially
  toolkit:
    enabled: true
  devicePlugin:
    enabled: true
  dcgm:
    enabled: true
  dcgmExporter:
    enabled: true
  nodeStatusExporter:
    enabled: true
  gfd:
    enabled: true
  vgpuManager:
    enabled: false  # Enable if using vGPU
  vgpuDeviceManager:
    enabled: false  # Enable if using vGPU
  sandboxDevicePlugin:
    enabled: true  # Enable for VM workloads
  vfioManager:
    enabled: true  # Enable for GPU passthrough VMs
EOF
```

2. Apply node selector label to target nodes
```bash
oc label node <gpu-node-1> nvidia.com/gpu-node=true
oc label node <gpu-node-2> nvidia.com/gpu-node=true
```

3. Monitor DaemonSet rollout
```bash
oc get daemonsets -n nvidia-gpu-operator
oc get pods -n nvidia-gpu-operator -w
```

---

#### Phase 6: Monitor Installation and Validate (30-45 minutes)

1. Watch DaemonSet rollout progress
```bash
oc get pods -n nvidia-gpu-operator -o wide -w
```

2. Check for node reboots
```bash
oc get nodes -w
# Nodes will show NotReady during reboot, then return to Ready
```

3. Verify driver installation
```bash
oc get pods -n nvidia-gpu-operator | grep nvidia-driver-daemonset
oc logs -n nvidia-gpu-operator <driver-pod-name>
```

4. Wait for validator pod success
```bash
oc get pods -n nvidia-gpu-operator | grep nvidia-operator-validator
oc logs -n nvidia-gpu-operator <validator-pod-name>
```

5. Confirm GPU resources visible on nodes
```bash
oc describe node <gpu-node-name> | grep nvidia.com/gpu
```

Expected output:
```
nvidia.com/gpu:  1
```

6. Check GPU feature labels
```bash
oc get node <gpu-node-name> -o json | jq '.metadata.labels' | grep nvidia
```

---

#### Phase 7: Test GPU Functionality (1 hour)

**For GPU Containers (if applicable):**
```bash
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vectoradd
  namespace: default
spec:
  restartPolicy: OnFailure
  containers:
    - name: cuda-vectoradd
      image: "nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda11.7.1-ubi8"
      resources:
        limits:
          nvidia.com/gpu: 1
EOF
```

Check output:
```bash
oc logs cuda-vectoradd
# Should see "Test PASSED"
```

**For GPU Passthrough VMs:**
1. Create test VM with GPU attached
```bash
cat <<EOF | oc apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: test-gpu-vm
  namespace: default
spec:
  running: true
  template:
    spec:
      nodeSelector:
        nvidia.com/gpu-node: "true"
      domain:
        devices:
          gpus:
            - deviceName: "nvidia.com/TU104GL_Tesla_T4"
              name: gpu1
        resources:
          requests:
            memory: 4Gi
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/containerdisks/fedora:latest
EOF
```

2. Verify VM starts and GPU is visible
```bash
oc get vmi test-gpu-vm
virtctl console test-gpu-vm
# Inside VM: lspci | grep -i nvidia
```

3. Clean up test resources
```bash
oc delete vm test-gpu-vm
oc delete pod cuda-vectoradd
```

---

#### Phase 8: Expand to Additional Nodes (As Needed)

1. Label additional nodes for GPU workloads
```bash
oc label node <next-node> nvidia.com/gpu-node=true
oc label node <next-node> nvidia.com/gpu.workload.config=vm-passthrough
```

2. GPU Operator will automatically deploy to newly labeled nodes

3. Repeat validation for each new node

4. Once satisfied, remove node selector from ClusterPolicy (optional)
```bash
oc patch clusterpolicy gpu-cluster-policy --type json \
  -p='[{"op": "remove", "path": "/spec/driver/nodeSelector"}]'
```

---

### Node Selection and Isolation

**Recommended Approach for OCP Virt Production:**

1. **Identify GPU Hardware Inventory**
```bash
# Use NFD to find nodes with NVIDIA GPUs
oc get nodes -l feature.node.kubernetes.io/pci-10de.present=true
```

2. **Classify Nodes by Purpose**
- **GPU Nodes:** Dedicated to GPU workloads (VMs or containers)
- **Non-GPU Nodes:** Continue running existing non-GPU VMs

3. **Apply Taints to GPU Nodes** (prevent non-GPU workload scheduling)
```bash
oc adm taint node <gpu-node> nvidia.com/gpu=present:NoSchedule
```

4. **VM Placement Strategy**
- VMs requiring GPU: Schedule on GPU nodes with appropriate tolerations
- Existing VMs without GPU: Remain on non-GPU nodes (unaffected)

5. **Use NodeSelector for VMs**
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
spec:
  template:
    spec:
      nodeSelector:
        nvidia.com/gpu-node: "true"
```

---

### Maintenance Window Recommendations

**Minimum Maintenance Window:**
- **Per Node:** 30-45 minutes (includes drain, reboot, validation)
- **Initial Setup:** 2-3 hours (prerequisites, operator install, first node)
- **Subsequent Nodes:** 30-45 minutes each (can be done in parallel with careful planning)

**Recommended Window:**
- **Initial Installation:** 4 hours (buffer for troubleshooting)
- **Per-Node Rollout:** 1 hour per node (conservative estimate)

**Timing:**
- **Low-Traffic Period:** Off-peak hours or scheduled maintenance window
- **Weekday vs. Weekend:** Weekend preferred for production environments
- **Staggered Rollout:** 1-2 nodes per maintenance window initially

**Communication:**
- Notify stakeholders 1 week in advance
- Provide expected downtime for VMs on affected nodes
- Have rollback plan ready

---

### Step-by-Step Approach Minimizing Impact

**Pre-Maintenance (1 week before):**
1. Complete Phase 1 validation
2. Identify target nodes for Phase 1 rollout
3. Document VM placement and dependencies
4. Schedule maintenance window
5. Notify stakeholders

**Maintenance Day (Day 1):**
1. Execute Phases 1-5 (prerequisites, NFD, GPU Operator install)
2. Deploy to first 1-2 nodes only
3. Validate successful installation
4. Monitor for 24 hours

**Day 2-3:**
5. If validation successful, expand to next 2-4 nodes
6. Monitor for issues
7. Validate GPU functionality on each node

**Week 2:**
8. Expand to remaining GPU nodes
9. Complete testing and validation
10. Document final configuration
11. Train operations team

**Rollback Triggers:**
- GPU Operator pods in CrashLoopBackOff for >30 minutes
- Node stuck in NotReady after 1 hour
- Critical VM failures
- OCP version incompatibility discovered

---

## 7. Testing and Validation Plan

### Pre-Production Testing Steps

#### Lab Environment Testing (If Available)

**Ideal:** Test in non-production environment first

1. Deploy identical OCP 4.18 cluster
2. Install GPU Operator following phases above
3. Test VM GPU passthrough functionality
4. Measure actual node downtime
5. Validate monitoring and metrics collection
6. Test rollback procedures
7. Document any issues encountered

#### Production Pre-Flight Checks

**If no lab environment available:**

1. **Version Verification**
```bash
oc version | grep "Server Version"
# Must NOT be 4.18.22 or 4.18.23
```

2. **Capacity Verification**
```bash
oc adm top nodes
oc get vmi -A -o wide
# Ensure sufficient capacity on non-GPU nodes
```

3. **Backup Critical VM Configurations**
```bash
oc get vm -A -o yaml > vm-backup-$(date +%Y%m%d).yaml
oc get vmi -A -o yaml > vmi-backup-$(date +%Y%m%d).yaml
```

4. **Network Policy Check**
```bash
oc get networkpolicies -A
# Ensure no policies block GPU Operator communication
```

5. **Image Registry Verification**
```bash
oc get imageregistry cluster -o yaml
# Ensure registry is available and has storage
```

6. **Storage Check**
```bash
oc debug node/<gpu-node>
chroot /host
df -h /var/lib/containers
# Ensure at least 20 GB available
```

7. **Test VM Migration** (if planning to migrate)
```bash
virtctl migrate <test-vm> --dry-run
```

---

### Validation Criteria

#### Installation Success Criteria

**GPU Operator Level:**
- [ ] GPU Operator CSV shows `Phase: Succeeded`
```bash
oc get csv -n nvidia-gpu-operator
```

- [ ] ClusterPolicy exists and reports `State: ready`
```bash
oc get clusterpolicy
```

- [ ] All required DaemonSets deployed successfully
```bash
oc get daemonsets -n nvidia-gpu-operator
# Expected: nvidia-driver-daemonset, nvidia-container-toolkit-daemonset,
# nvidia-device-plugin-daemonset, nvidia-dcgm-exporter, gpu-feature-discovery,
# nvidia-vfio-manager (for VMs), etc.
```

**Node Level:**
- [ ] GPU nodes show GPUs in capacity
```bash
oc describe node <gpu-node> | grep "nvidia.com/gpu:"
# Should show: nvidia.com/gpu: 1 (or number of GPUs)
```

- [ ] GPU feature labels present
```bash
oc get node <gpu-node> --show-labels | grep nvidia
```

- [ ] Driver pods running successfully
```bash
oc get pods -n nvidia-gpu-operator -l app=nvidia-driver-daemonset
```

- [ ] Validator pod completed successfully
```bash
oc get pods -n nvidia-gpu-operator | grep nvidia-operator-validator
# Should show Status: Completed
```

**Functional Level:**
- [ ] Test GPU container runs successfully (if using containers)
- [ ] Test VM with GPU passthrough boots and sees GPU (if using VMs)
- [ ] GPU metrics available in Prometheus
```bash
oc get servicemonitor -n nvidia-gpu-operator
```

- [ ] No CrashLoopBackOff pods
```bash
oc get pods -n nvidia-gpu-operator | grep -i crash
```

---

### Success Metrics

#### Quantitative Metrics

**Installation Metrics:**
- Time to install per node: < 45 minutes
- Number of failed nodes: 0
- Number of rollbacks required: 0

**Availability Metrics:**
- VM downtime: < 1 hour per affected VM
- Cluster API availability: 100% (control plane not affected)
- Non-GPU workload availability: 100% (unaffected nodes)

**Performance Metrics:**
- GPU utilization visible in metrics: Yes
- GPU-accelerated workload performance: Baseline established
- Cluster overhead from GPU Operator: < 2% CPU, < 1 GB memory per node

#### Qualitative Metrics

**Operational Readiness:**
- [ ] Operations team trained on GPU Operator management
- [ ] Monitoring dashboards configured for GPU metrics
- [ ] Alerting rules created for GPU failures
- [ ] Runbooks documented for common issues
- [ ] Backup and recovery procedures tested

**Documentation Completeness:**
- [ ] Node labeling strategy documented
- [ ] VM GPU assignment procedure documented
- [ ] Troubleshooting guide created
- [ ] Rollback procedures verified
- [ ] Vendor support contact information available

---

## 8. Rollback and Recovery Procedures

### How to Uninstall GPU Operator If Needed

#### Complete Removal Procedure

**⚠️ Warning:** Uninstalling GPU Operator will remove GPU access from all workloads.

**Step 1: Remove GPU Workloads**
```bash
# Stop VMs using GPUs
oc get vm -A -o json | jq -r '.items[] | select(.spec.template.spec.domain.devices.gpus != null) | .metadata.name'
# Stop each identified VM
virtctl stop <vm-name>

# Delete GPU-using pods
oc get pods -A -o json | jq -r '.items[] | select(.spec.containers[].resources.limits."nvidia.com/gpu" != null) | "\(.metadata.namespace) \(.metadata.name)"'
# Delete each identified pod
oc delete pod <pod-name> -n <namespace>
```

**Step 2: Delete ClusterPolicy**
```bash
oc delete clusterpolicy gpu-cluster-policy
```

Wait for all DaemonSets to terminate:
```bash
oc get daemonsets -n nvidia-gpu-operator
# Wait until all are deleted
```

**Step 3: Uninstall GPU Operator**
```bash
oc delete subscription gpu-operator-certified -n nvidia-gpu-operator
oc delete csv -n nvidia-gpu-operator $(oc get csv -n nvidia-gpu-operator -o name | grep gpu-operator)
```

**Step 4: Clean Up Resources**
```bash
# Remove finalizers if stuck
oc patch clusterpolicy gpu-cluster-policy -p '{"metadata":{"finalizers":[]}}' --type=merge

# Delete namespace
oc delete namespace nvidia-gpu-operator

# Remove node labels
oc label node <gpu-node> nvidia.com/gpu.workload.config-
oc label node <gpu-node> nvidia.com/gpu-node-

# Remove taints
oc adm taint node <gpu-node> nvidia.com/gpu:NoSchedule-
```

**Step 5: Reboot Nodes (if driver loaded)**
```bash
# Drain node
oc adm drain <gpu-node> --ignore-daemonsets --delete-emptydir-data

# Reboot via debug pod
oc debug node/<gpu-node>
chroot /host
systemctl reboot

# Wait for node to return
oc get nodes -w

# Uncordon node
oc adm uncordon <gpu-node>
```

**Step 6: Verify Clean Removal**
```bash
# No GPU resources should be visible
oc describe node <gpu-node> | grep nvidia.com/gpu
# Should return nothing

# No GPU driver kernel modules loaded
oc debug node/<gpu-node>
chroot /host
lsmod | grep nvidia
# Should return nothing after reboot
```

---

### VM Recovery Procedures

#### Scenario 1: VM Failed to Migrate

**Symptoms:**
- VM stuck in "Migrating" state
- Migration pod in Error state

**Recovery:**
```bash
# Cancel migration
virtctl migrate-cancel <vm-name>

# Restart VM
virtctl restart <vm-name>

# If still stuck, force delete VMI and recreate
oc delete vmi <vm-name> --force --grace-period=0
virtctl start <vm-name>
```

#### Scenario 2: VM Won't Start After GPU Node Installation

**Symptoms:**
- VM in "Scheduling" state indefinitely
- Pod fails to schedule with "Insufficient nvidia.com/gpu" error

**Recovery:**
```bash
# Check if VM is requesting GPU resources incorrectly
oc get vm <vm-name> -o yaml | grep -A5 gpus

# If GPU not actually needed, remove GPU device from VM
oc edit vm <vm-name>
# Delete the 'gpus:' section under spec.template.spec.domain.devices

# If GPU is needed, verify node has GPU available
oc describe node <gpu-node> | grep nvidia.com/gpu
# Check Allocatable vs. Allocated

# Restart VM
virtctl stop <vm-name>
virtctl start <vm-name>
```

#### Scenario 3: VM Lost Connection to Storage

**Symptoms:**
- VM boot fails with disk attachment errors
- DataVolume in error state

**Recovery:**
```bash
# Check DataVolume status
oc get dv <datavolume-name> -o yaml

# If DV is stuck, restart CDI pods
oc delete pod -n cdi -l app=containerized-data-importer

# Restart VM
virtctl restart <vm-name>
```

#### Scenario 4: All VMs Need to be Evacuated from a Node

**Procedure:**
```bash
# Live migrate all VMs from node (if possible)
for vm in $(oc get vmi -A -o json | jq -r --arg NODE "<node-name>" '.items[] | select(.status.nodeName == $NODE) | "\(.metadata.namespace)/\(.metadata.name)"'); do
  namespace=$(echo $vm | cut -d'/' -f1)
  vmname=$(echo $vm | cut -d'/' -f2)
  echo "Migrating $vmname in $namespace"
  virtctl migrate $vmname -n $namespace
done

# For VMs that cannot migrate (e.g., with GPU), stop them
virtctl stop <vm-name>
```

---

### Timeline for Rollback Operations

#### Quick Rollback (Remove ClusterPolicy Only)

**Duration:** 15-30 minutes  
**Scope:** Stop GPU Operator components but keep operator installed

**Steps:**
1. Delete ClusterPolicy: 2 minutes
2. Wait for DaemonSets to terminate: 5-10 minutes
3. Verify cleanup: 3 minutes
4. Remove node taints: 2 minutes
5. Verify workloads can reschedule: 5-10 minutes

**Total:** 17-27 minutes

**Use When:** GPU Operator is causing issues but you want to keep it installed for future use.

---

#### Full Uninstall

**Duration:** 45-60 minutes  
**Scope:** Complete removal of GPU Operator and all components

**Steps:**
1. Remove GPU workloads: 5-10 minutes
2. Delete ClusterPolicy: 2 minutes
3. Wait for DaemonSets cleanup: 5-10 minutes
4. Uninstall operator: 5 minutes
5. Clean up resources: 5 minutes
6. Reboot nodes (one at a time): 10-15 minutes per node
7. Verify cleanup: 10 minutes

**Total:** 42-57 minutes (plus additional time if multiple nodes need rebooting)

**Use When:** GPU Operator cannot be stabilized, incompatibility discovered, or change in requirements.

---

#### Emergency Rollback (Critical Failure)

**Duration:** 20-30 minutes  
**Scope:** Rapid restoration of cluster stability

**Steps:**
1. Force delete ClusterPolicy: 1 minute
```bash
oc delete clusterpolicy gpu-cluster-policy --force --grace-period=0
oc patch clusterpolicy gpu-cluster-policy -p '{"metadata":{"finalizers":[]}}' --type=merge
```

2. Force delete GPU Operator namespace: 2 minutes
```bash
oc delete namespace nvidia-gpu-operator --force --grace-period=0
```

3. Remove finalizers from stuck resources: 5 minutes
```bash
oc get crd | grep nvidia | awk '{print $1}' | xargs -I {} oc delete crd {} --force --grace-period=0
```

4. Reboot affected nodes immediately: 10-15 minutes
```bash
oc adm drain <gpu-node> --ignore-daemonsets --delete-emptydir-data --force
oc debug node/<gpu-node> -- chroot /host systemctl reboot
```

5. Uncordon nodes as they return: 2 minutes
```bash
oc adm uncordon <gpu-node>
```

**Total:** 20-27 minutes

**Use When:** Cluster stability is at risk, cascading failures occurring, or critical production impact.

---

### Rollback Decision Matrix

| Symptom | Severity | Recommended Action | Timeline |
|---------|----------|-------------------|----------|
| Single node driver failure | Low | Investigate logs, retry on that node only | 30 min |
| Multiple nodes in NotReady state | High | Quick rollback (remove ClusterPolicy) | 20 min |
| Cluster API degradation | Critical | Emergency rollback | 20 min |
| VM workload failures on GPU nodes | Medium | Migrate VMs, investigate, proceed cautiously | 1 hour |
| GPU Operator pods CrashLoopBackOff | Medium | Check logs, adjust ClusterPolicy, or rollback | 30-45 min |
| Incompatible OCP version discovered | Critical | Full uninstall, upgrade OCP, reinstall | 2-3 hours |
| Performance degradation cluster-wide | High | Quick rollback, investigate capacity | 30 min |
| GPU Operator stuck in "Installing" state | Low | Wait 30 min, check logs, force delete if needed | 45 min |

---

## 9. Documentation References

### Red Hat OpenShift Documentation

1. **OpenShift Container Platform 4.18 - Hardware Accelerators**
   - Title: "NVIDIA GPU architecture"
   - URL: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/hardware_accelerators/nvidia-gpu-architecture
   - Relevance: OCP 4.18-specific GPU architecture and requirements

2. **Red Hat OpenShift AI - GPU Support**
   - Title: "Enabling NVIDIA GPUs"
   - URL: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_cloud_service/1/html/working_with_accelerators/enabling-nvidia-gpus_accelerators
   - Relevance: Node Feature Discovery and ClusterPolicy configuration

3. **Red Hat AI Inference Server - GPU Operator Installation**
   - Title: "Installing the NVIDIA GPU Operator"
   - URL: https://docs.redhat.com/en/documentation/red_hat_ai_inference_server/3.2/html/deploying_red_hat_ai_inference_server_in_openshift_container_platform/installing-nvidia-gpu-operator_install
   - Relevance: Detailed installation steps and prerequisites

4. **OpenShift Virtualization Documentation**
   - URL: https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/virtualization/
   - Relevance: OCP Virt configuration, VM management, device assignment

### NVIDIA GPU Operator Documentation

5. **NVIDIA GPU Operator - OpenShift Installation (Latest)**
   - URL: https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/install-gpu-ocp.html
   - Version: Latest
   - Relevance: Current installation procedures and best practices

6. **NVIDIA GPU Operator - OpenShift Installation (v24.9.1)**
   - URL: https://docs.nvidia.com/datacenter/cloud-native/openshift/24.9.1/install-gpu-ocp.html
   - Version: 24.9.1
   - Relevance: Stable version documentation, namespace configuration

7. **NVIDIA GPU Operator - OpenShift Virtualization Integration (Latest)**
   - URL: https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/openshift-virtualization.html
   - Version: Latest
   - Relevance: OCP Virt-specific configuration and constraints

8. **NVIDIA GPU Operator - OpenShift Virtualization (v24.9.1)**
   - URL: https://docs.nvidia.com/datacenter/cloud-native/openshift/24.9.1/openshift-virtualization.html
   - Version: 24.9.1
   - Relevance: Workload type segregation, node labeling, VM GPU configuration

9. **NVIDIA GPU Operator - OpenShift Virtualization (v23.9.2)**
   - URL: https://docs.nvidia.com/datacenter/cloud-native/openshift/23.9.2/openshift-virtualization.html
   - Version: 23.9.2
   - Relevance: Historical reference, vGPU Manager configuration

10. **NVIDIA GPU Operator - Installation Overview (v25.3.3)**
    - URL: https://docs.nvidia.com/datacenter/cloud-native/openshift/25.3.3/steps-overview.html
    - Version: 25.3.3
    - Relevance: **CRITICAL - Contains OCP 4.18.22/23 incompatibility warning**

11. **NVIDIA GPU Operator - General Installation Guide**
    - URL: https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/25.3.0/getting-started.html
    - Version: 25.3.0
    - Relevance: General architecture, component descriptions, troubleshooting

12. **NVIDIA GPU Operator - Historical Version (v1.8)**
    - URL: https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/1.8/openshift/install-gpu-ocp.html
    - Version: 1.8
    - Relevance: Installation timeline estimates (10-20 minutes)

### Key Red Hat Knowledge Base Articles

13. **NVIDIA GPU Operator Support on OpenShift**
    - Search: Red Hat Customer Portal → "GPU Operator OpenShift 4.18"
    - Relevance: Known issues, compatibility matrix, support statements

14. **OpenShift Virtualization GPU Passthrough Configuration**
    - Search: Red Hat Customer Portal → "OpenShift Virtualization GPU passthrough"
    - Relevance: PCI device assignment, IOMMU configuration

15. **Node Feature Discovery Troubleshooting**
    - Search: Red Hat Customer Portal → "Node Feature Discovery operator troubleshooting"
    - Relevance: NFD prerequisite installation issues

### Community and Additional Resources

16. **NVIDIA NGC Catalog - GPU Operator Images**
    - URL: https://catalog.ngc.nvidia.com/orgs/nvidia/containers/gpu-operator
    - Relevance: Container image versions, changelogs

17. **OpenShift Commons - GPU Enablement Best Practices**
    - Search: YouTube → "OpenShift GPU enablement"
    - Relevance: Community experiences, deployment patterns

### Version Compatibility Matrix

| Component | Version | Compatibility | Notes |
|-----------|---------|---------------|-------|
| OpenShift Container Platform | 4.18.24+ | ✅ Supported | Avoid 4.18.22 and 4.18.23 |
| NVIDIA GPU Operator | v24.9.x | ✅ Recommended | Current stable version |
| NVIDIA GPU Operator | v25.3.x | ✅ Supported | Latest version |
| OpenShift Virtualization | 4.18 (included) | ✅ Supported | Bundled with OCP 4.18 |
| Node Feature Discovery | Included | ✅ Supported | Auto-deployed by GPU Operator |
| NVIDIA Driver | 545.x+ | ✅ Supported | Deployed by GPU Operator |

---

## 10. Appendices

### Appendix A: Sample Commands and Configurations

#### A.1 Pre-Installation Validation Script

```bash
#!/bin/bash
# gpu-operator-preflight-check.sh
# Validates cluster readiness for GPU Operator installation

echo "=== GPU Operator Pre-Flight Check for OCP 4.18 ==="
echo

# Check 1: OCP Version
echo "1. Checking OpenShift version..."
OCP_VERSION=$(oc version -o json | jq -r '.openshiftVersion')
echo "   OCP Version: $OCP_VERSION"

if [[ "$OCP_VERSION" == "4.18.22" ]] || [[ "$OCP_VERSION" == "4.18.23" ]]; then
  echo "   ❌ CRITICAL: OCP version $OCP_VERSION has known incompatibility with GPU Operator"
  echo "   ACTION REQUIRED: Upgrade to OCP 4.18.24 or later before installing GPU Operator"
  exit 1
else
  echo "   ✅ OCP version is compatible"
fi
echo

# Check 2: Cluster Health
echo "2. Checking cluster health..."
NOT_AVAILABLE=$(oc get co --no-headers | grep -v "True.*False.*False" | wc -l)
if [ "$NOT_AVAILABLE" -gt 0 ]; then
  echo "   ⚠️  WARNING: Some cluster operators are not in healthy state:"
  oc get co | grep -v "True.*False.*False"
  echo "   RECOMMENDATION: Investigate cluster operator health before proceeding"
else
  echo "   ✅ All cluster operators are healthy"
fi
echo

# Check 3: Node Status
echo "3. Checking node status..."
NOT_READY=$(oc get nodes --no-headers | grep -v " Ready" | wc -l)
if [ "$NOT_READY" -gt 0 ]; then
  echo "   ⚠️  WARNING: Some nodes are not Ready:"
  oc get nodes | grep -v " Ready"
  echo "   RECOMMENDATION: Investigate node health before proceeding"
else
  echo "   ✅ All nodes are Ready"
fi
echo

# Check 4: Check for existing GPU configuration
echo "4. Checking for existing GPU configuration..."
GPU_ADDONS=$(oc get subscription -A | grep -i "gpu\|nvidia" || true)
if [ -n "$GPU_ADDONS" ]; then
  echo "   ⚠️  WARNING: Existing GPU-related subscriptions found:"
  echo "$GPU_ADDONS"
  echo "   ACTION REQUIRED: Remove deprecated GPU Add-on before installing GPU Operator"
else
  echo "   ✅ No conflicting GPU configuration found"
fi
echo

# Check 5: Node capacity
echo "5. Checking node capacity..."
echo "   Current node resource utilization:"
oc adm top nodes 2>/dev/null || echo "   ⚠️  WARNING: Metrics not available. Install metrics-server."
echo

# Check 6: Storage availability
echo "6. Checking storage on worker nodes..."
for node in $(oc get nodes -l node-role.kubernetes.io/worker --no-headers | awk '{print $1}'); do
  AVAILABLE=$(oc debug node/$node -- chroot /host df -h /var/lib/containers 2>/dev/null | tail -1 | awk '{print $4}')
  echo "   Node $node: $AVAILABLE available in /var/lib/containers"
done
echo

# Check 7: Image registry
echo "7. Checking image registry availability..."
REGISTRY_STATUS=$(oc get imageregistry cluster -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "Unknown")
if [ "$REGISTRY_STATUS" = "True" ]; then
  echo "   ✅ Image registry is available"
else
  echo "   ⚠️  WARNING: Image registry status: $REGISTRY_STATUS"
  echo "   RECOMMENDATION: Verify image registry configuration"
fi
echo

# Check 8: VirtualMachine inventory
echo "8. Checking VirtualMachine inventory..."
VM_COUNT=$(oc get vm -A --no-headers 2>/dev/null | wc -l || echo "0")
VMI_COUNT=$(oc get vmi -A --no-headers 2>/dev/null | wc -l || echo "0")
echo "   VirtualMachines: $VM_COUNT"
echo "   Running VirtualMachineInstances: $VMI_COUNT"
if [ "$VMI_COUNT" -gt 0 ]; then
  echo "   VM distribution by node:"
  oc get vmi -A -o wide --no-headers 2>/dev/null | awk '{print $8}' | sort | uniq -c || true
fi
echo

# Summary
echo "=== Pre-Flight Check Complete ==="
echo "Review warnings above before proceeding with GPU Operator installation."
echo
```

**Usage:**
```bash
chmod +x gpu-operator-preflight-check.sh
./gpu-operator-preflight-check.sh
```

---

#### A.2 ClusterPolicy Examples

**Basic ClusterPolicy for GPU Passthrough VMs:**
```yaml
apiVersion: nvidia.com/v1
kind: ClusterPolicy
metadata:
  name: gpu-cluster-policy
spec:
  operator:
    defaultRuntime: crio
  driver:
    enabled: true
    repository: nvcr.io/nvidia
    version: "545.23.08"
  toolkit:
    enabled: true
  devicePlugin:
    enabled: true
  dcgm:
    enabled: true
  dcgmExporter:
    enabled: true
  gfd:
    enabled: true
  vfioManager:
    enabled: true  # Required for GPU passthrough
    repository: nvcr.io/nvidia
  sandboxDevicePlugin:
    enabled: true  # Required for VM workloads
    repository: nvcr.io/nvidia
  vgpuManager:
    enabled: false  # Not using vGPU
  vgpuDeviceManager:
    enabled: false  # Not using vGPU
  daemonsets:
    tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
```

**ClusterPolicy for vGPU VMs:**
```yaml
apiVersion: nvidia.com/v1
kind: ClusterPolicy
metadata:
  name: gpu-cluster-policy-vgpu
spec:
  operator:
    defaultRuntime: crio
  driver:
    enabled: false  # Disabled when using vGPU Manager
  toolkit:
    enabled: true
  devicePlugin:
    enabled: true
  dcgm:
    enabled: true
  dcgmExporter:
    enabled: true
  gfd:
    enabled: true
  vfioManager:
    enabled: false  # Not used with vGPU
  sandboxDevicePlugin:
    enabled: true  # Required for VM workloads
    repository: nvcr.io/nvidia
  vgpuManager:
    enabled: true  # Enable for vGPU
    repository: nvcr.io/nvidia
    version: "525.105.17"
    image: vgpu-manager
    env:
      - name: LICENSE_SERVER_URL
        value: "http://license-server.example.com:7070"  # Your license server
  vgpuDeviceManager:
    enabled: true  # Enable for vGPU
    repository: nvcr.io/nvidia
  daemonsets:
    tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
```

**ClusterPolicy with Node Selector (Phased Rollout):**
```yaml
apiVersion: nvidia.com/v1
kind: ClusterPolicy
metadata:
  name: gpu-cluster-policy-phased
spec:
  operator:
    defaultRuntime: crio
  driver:
    enabled: true
    repository: nvcr.io/nvidia
    version: "545.23.08"
    nodeSelector:
      nvidia.com/gpu-node: "true"  # Only deploy to labeled nodes
  toolkit:
    enabled: true
    nodeSelector:
      nvidia.com/gpu-node: "true"
  devicePlugin:
    enabled: true
    nodeSelector:
      nvidia.com/gpu-node: "true"
  dcgm:
    enabled: true
    nodeSelector:
      nvidia.com/gpu-node: "true"
  dcgmExporter:
    enabled: true
    nodeSelector:
      nvidia.com/gpu-node: "true"
  gfd:
    enabled: true
    nodeSelector:
      nvidia.com/gpu-node: "true"
  vfioManager:
    enabled: true
    nodeSelector:
      nvidia.com/gpu-node: "true"
  sandboxDevicePlugin:
    enabled: true
    nodeSelector:
      nvidia.com/gpu-node: "true"
  daemonsets:
    tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
```

---

#### A.3 VirtualMachine GPU Configuration Examples

**VM with GPU Passthrough:**
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: gpu-passthrough-vm
  namespace: default
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/vm: gpu-passthrough-vm
    spec:
      nodeSelector:
        nvidia.com/gpu-node: "true"  # Schedule on GPU nodes only
      tolerations:
        - key: nvidia.com/gpu
          operator: Exists
          effect: NoSchedule
      domain:
        cpu:
          cores: 4
        memory:
          guest: 8Gi
        devices:
          gpus:
            - deviceName: "nvidia.com/TU104GL_Tesla_T4"  # GPU device name
              name: gpu1
          disks:
            - disk:
                bus: virtio
              name: containerdisk
            - disk:
                bus: virtio
              name: cloudinitdisk
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/containerdisks/fedora:latest
        - name: cloudinitdisk
          cloudInitNoCloud:
            userData: |
              #cloud-config
              user: fedora
              password: fedora
              chpasswd: { expire: False }
              runcmd:
                - dnf install -y pciutils
```

**VM with vGPU:**
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vgpu-vm
  namespace: default
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/vm: vgpu-vm
    spec:
      nodeSelector:
        nvidia.com/gpu.workload.config: vm-vgpu
      tolerations:
        - key: nvidia.com/gpu
          operator: Exists
          effect: NoSchedule
      domain:
        cpu:
          cores: 2
        memory:
          guest: 4Gi
        devices:
          gpus:
            - deviceName: "nvidia.com/GRID_T4-1Q"  # vGPU profile name
              name: vgpu1
          disks:
            - disk:
                bus: virtio
              name: containerdisk
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/containerdisks/ubuntu:latest
```

---

#### A.4 Monitoring and Troubleshooting Commands

**Check GPU Operator Status:**
```bash
# Operator installation status
oc get csv -n nvidia-gpu-operator

# ClusterPolicy status
oc get clusterpolicy

# All GPU Operator pods
oc get pods -n nvidia-gpu-operator -o wide

# DaemonSet status
oc get daemonsets -n nvidia-gpu-operator

# Operator logs
oc logs -n nvidia-gpu-operator deployment/gpu-operator
```

**Check Node GPU Status:**
```bash
# GPU resources on nodes
oc get nodes -o json | jq '.items[] | {name: .metadata.name, gpu: .status.capacity."nvidia.com/gpu"}'

# Detailed node GPU info
oc describe node <node-name> | grep -A 10 "nvidia.com"

# GPU feature labels
oc get nodes --show-labels | grep nvidia

# Node conditions
oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

**Check Driver Status:**
```bash
# Driver pods
oc get pods -n nvidia-gpu-operator -l app=nvidia-driver-daemonset

# Driver logs
oc logs -n nvidia-gpu-operator <driver-pod-name>

# Validator status
oc get pods -n nvidia-gpu-operator -l app=nvidia-operator-validator
oc logs -n nvidia-gpu-operator <validator-pod-name>

# Check driver on node
oc debug node/<node-name>
chroot /host
lsmod | grep nvidia
nvidia-smi
```

**Check VM GPU Status:**
```bash
# List VMs with GPU
oc get vm -A -o json | jq -r '.items[] | select(.spec.template.spec.domain.devices.gpus != null) | "\(.metadata.namespace)/\(.metadata.name)"'

# VM GPU configuration
oc get vm <vm-name> -o jsonpath='{.spec.template.spec.domain.devices.gpus}'

# VirtualMachineInstance status
oc get vmi <vm-name> -o yaml

# VM console (to check GPU inside VM)
virtctl console <vm-name>
# Inside VM: lspci | grep -i nvidia
```

**Check GPU Metrics:**
```bash
# DCGM exporter pods
oc get pods -n nvidia-gpu-operator -l app=nvidia-dcgm-exporter

# ServiceMonitor
oc get servicemonitor -n nvidia-gpu-operator

# Query Prometheus for GPU metrics (if Prometheus accessible)
oc exec -n openshift-monitoring prometheus-k8s-0 -- curl -s 'http://localhost:9090/api/v1/query?query=DCGM_FI_DEV_GPU_UTIL'

# Check metrics endpoint
oc port-forward -n nvidia-gpu-operator <dcgm-exporter-pod> 9400:9400
curl http://localhost:9400/metrics | grep DCGM
```

---

### Appendix B: Troubleshooting Quick Reference

#### Common Issues and Resolutions

**Issue: GPU Operator pods in CrashLoopBackOff**

**Symptoms:**
```bash
oc get pods -n nvidia-gpu-operator
# Shows pods in CrashLoopBackOff state
```

**Diagnosis:**
```bash
oc logs -n nvidia-gpu-operator <crashing-pod-name>
oc describe pod -n nvidia-gpu-operator <crashing-pod-name>
```

**Common Causes & Resolutions:**

1. **Incompatible OCP version (4.18.22 or 4.18.23)**
   - Resolution: Upgrade to OCP 4.18.24+

2. **Driver compilation failure**
   - Check: `oc logs <driver-pod> | grep -i error`
   - Resolution: Verify kernel-devel packages, check RHCOS version compatibility

3. **Insufficient permissions**
   - Check: `oc describe pod <pod-name> | grep -i "SecurityContext"`
   - Resolution: Verify ServiceAccount and SecurityContextConstraints

4. **Image pull failures**
   - Check: `oc describe pod <pod-name> | grep -i "ImagePull"`
   - Resolution: Verify network connectivity to nvcr.io, check image pull secrets

---

**Issue: Node stuck in NotReady after GPU driver installation**

**Symptoms:**
```bash
oc get nodes
# GPU node shows NotReady status for >30 minutes
```

**Diagnosis:**
```bash
oc describe node <node-name>
oc debug node/<node-name>
chroot /host
systemctl status kubelet
journalctl -u kubelet -n 100
```

**Common Causes & Resolutions:**

1. **Driver loading failure**
   ```bash
   lsmod | grep nvidia  # Should show nvidia modules
   dmesg | grep -i nvidia  # Check for errors
   ```
   - Resolution: Check kernel compatibility, review driver logs

2. **Kubelet can't communicate with container runtime**
   ```bash
   crictl ps  # Should show running containers
   systemctl status crio
   ```
   - Resolution: Restart crio service, check crio logs

3. **Node out of memory or disk**
   ```bash
   free -h
   df -h
   ```
   - Resolution: Clean up disk space, investigate memory leaks

---

**Issue: VirtualMachine won't start after GPU Operator installation**

**Symptoms:**
```bash
oc get vmi
# VMI stuck in "Scheduling" or "Pending" state
```

**Diagnosis:**
```bash
oc describe vmi <vm-name>
oc get events -n <namespace> | grep <vm-name>
```

**Common Causes & Resolutions:**

1. **GPU resource not available**
   ```bash
   oc describe node <node-name> | grep nvidia.com/gpu
   # Check Allocatable vs. Allocated
   ```
   - Resolution: Verify GPU is not already allocated, check device plugin status

2. **Node selector not matching**
   ```bash
   oc get vm <vm-name> -o yaml | grep nodeSelector
   ```
   - Resolution: Verify node has required labels

3. **Toleration missing for tainted GPU nodes**
   ```bash
   oc describe node <node-name> | grep Taints
   ```
   - Resolution: Add toleration to VM spec

4. **GPU device name incorrect**
   ```bash
   oc get node <node-name> -o json | jq '.status.allocatable'
   ```
   - Resolution: Use correct GPU device name from node allocatable resources

---

**Issue: GPU not visible inside VM**

**Symptoms:**
- VM starts successfully but `lspci` doesn't show GPU inside VM

**Diagnosis:**
```bash
# On host
oc debug node/<node-name>
chroot /host
lspci | grep -i nvidia  # GPU should be visible on host

# Check vfio binding
ls -la /sys/bus/pci/drivers/vfio-pci/

# Inside VM
lspci | grep -i nvidia  # GPU not visible
```

**Common Causes & Resolutions:**

1. **IOMMU not enabled**
   ```bash
   # On host
   cat /proc/cmdline | grep iommu
   # Should show: intel_iommu=on or amd_iommu=on
   ```
   - Resolution: Enable IOMMU in BIOS and kernel parameters

2. **GPU not bound to VFIO**
   ```bash
   # Check device driver binding
   lspci -k | grep -A 3 -i nvidia
   ```
   - Resolution: Verify vfio-manager is running, check device binding

3. **Wrong GPU device specified in VM**
   ```bash
   oc get vm <vm-name> -o jsonpath='{.spec.template.spec.domain.devices.gpus}'
   ```
   - Resolution: Update VM spec with correct device name

---

**Issue: GPU metrics not appearing in Prometheus**

**Symptoms:**
- DCGM exporter pods running but metrics not visible in Prometheus

**Diagnosis:**
```bash
# Check DCGM exporter status
oc get pods -n nvidia-gpu-operator -l app=nvidia-dcgm-exporter

# Check ServiceMonitor
oc get servicemonitor -n nvidia-gpu-operator

# Test metrics endpoint
oc port-forward -n nvidia-gpu-operator <dcgm-pod> 9400:9400
curl http://localhost:9400/metrics
```

**Common Causes & Resolutions:**

1. **Namespace monitoring not enabled**
   ```bash
   oc get namespace nvidia-gpu-operator -o yaml | grep openshift.io/cluster-monitoring
   ```
   - Resolution:
   ```bash
   oc label namespace nvidia-gpu-operator openshift.io/cluster-monitoring=true
   ```

2. **ServiceMonitor not created**
   ```bash
   oc get servicemonitor -n nvidia-gpu-operator
   ```
   - Resolution: Verify ClusterPolicy has `dcgmExporter.enabled: true`

3. **Prometheus can't scrape pods**
   ```bash
   # Check Prometheus scrape config
   oc get secret -n openshift-monitoring prometheus-k8s -o jsonpath='{.data.prometheus\.yaml\.gz}' | base64 -d | gunzip | grep nvidia
   ```
   - Resolution: Verify NetworkPolicies allow Prometheus → nvidia-gpu-operator

---

### Appendix C: Vendor Support Contact Information

#### Red Hat Support

**Red Hat Customer Portal:**
- URL: https://access.redhat.com/
- Case Creation: https://access.redhat.com/support/cases/

**Support Scope:**
- OpenShift Container Platform issues
- OpenShift Virtualization issues
- Integration issues with certified operators (including GPU Operator)
- Cluster configuration and troubleshooting

**Required Information for Support Cases:**
- OpenShift version (`oc version`)
- GPU Operator version (`oc get csv -n nvidia-gpu-operator`)
- Must-gather output:
  ```bash
  oc adm must-gather --image=registry.redhat.io/openshift4/ose-must-gather:v4.18
  oc adm must-gather --image=quay.io/openshift/origin-must-gather:4.18
  ```
- GPU-specific must-gather (if available)

**Support Severity Levels:**
- **Urgent (Severity 1):** Production environment down
- **High (Severity 2):** Major functionality impaired
- **Medium (Severity 3):** Partial functionality loss
- **Low (Severity 4):** General usage questions

#### NVIDIA Support

**NVIDIA Enterprise Support:**
- URL: https://www.nvidia.com/en-us/support/enterprise/
- Support Portal: https://nvid.nvidia.com/

**Support Scope:**
- GPU Operator functionality issues
- Driver problems
- GPU hardware issues
- vGPU licensing issues

**Support Eligibility:**
- Requires active NVIDIA AI Enterprise or vGPU license for enterprise support
- Community support available via NGC forums for basic issues

**Required Information for Support Cases:**
- GPU Operator version
- Driver version
- GPU hardware model
- Output from:
  ```bash
  nvidia-smi -q > nvidia-smi-output.txt
  nvidia-bug-report.sh  # If accessible on node
  ```

#### Joint Red Hat + NVIDIA Issues

**Escalation Path:**
1. Open case with Red Hat first (for OpenShift/OCP Virt issues)
2. Red Hat support may engage NVIDIA on your behalf
3. For clear GPU hardware/driver issues, open NVIDIA case directly

**Common Joint Issues:**
- Driver compatibility with RHCOS kernel
- GPU Operator integration with OpenShift Virtualization
- Performance tuning for GPU workloads on OpenShift

#### Community Resources

**Red Hat Community:**
- OpenShift Commons: https://commons.openshift.org/
- Red Hat Developer Portal: https://developers.redhat.com/products/openshift
- OpenShift YouTube: Community presentations and demos

**NVIDIA Community:**
- NVIDIA Developer Forums: https://forums.developer.nvidia.com/
- NGC Forums: https://forums.developer.nvidia.com/c/container-runtime/cloud-native/
- GitHub Issues: https://github.com/NVIDIA/gpu-operator/issues

**Documentation Feedback:**
- Report doc issues: feedback links on official documentation pages
- Contribute to community docs and knowledge bases

---

## Conclusion

This impact analysis provides comprehensive guidance for installing the NVIDIA GPU Operator on your production OpenShift Container Platform 4.18 cluster running OpenShift Virtualization workloads.

### Key Takeaways

1. **Critical Version Check:** Verify your cluster is NOT running OCP 4.18.22 or 4.18.23 before proceeding

2. **Node Workload Segregation:** Plan carefully which nodes will run GPU containers vs. GPU VMs—they cannot be mixed

3. **Phased Rollout Essential:** Install on a subset of nodes initially to minimize production impact

4. **VM Downtime Expected:** VMs on GPU-designated nodes will experience 15-25 minutes downtime during installation

5. **Comprehensive Testing:** Validate each phase before expanding to additional nodes

### Recommended Next Steps

1. Review this document with your operations team
2. Run the pre-flight validation script (Appendix A.1)
3. Schedule maintenance windows with stakeholders
4. Prepare rollback procedures and emergency contacts
5. Proceed with Phase 1 (Pre-Installation Validation)
6. Execute phased rollout as documented in Section 6

### Success Factors

- Careful planning and node capacity assessment
- Clear communication with stakeholders about expected impacts
- Adherence to phased rollout approach
- Thorough validation at each step
- Prepared rollback procedures

Your production OCP Virt environment can successfully integrate GPU capabilities with proper planning and execution of the strategies outlined in this analysis.

---

**Document Metadata:**
- Author: AI Analysis based on official vendor documentation
- Sources: 17+ official Red Hat and NVIDIA documentation references
- Last Updated: January 22, 2026
- Review Cycle: Recommended quarterly review for documentation updates


# vGPU Node Label Methods

> Applies to: OpenShift 4.18+ with NVIDIA GPU Operator + OpenShift Virtualization

The NVIDIA vGPU Device Manager reads `nvidia.com/vgpu.config` from each node's
labels to determine which vGPU profile to create on that node. This document
covers the methods available for applying and managing these labels.

**Quick reference:**

| Method | When it applies | Dynamic? | Requires node in GitOps? |
|--------|----------------|---------|--------------------------|
| [BMH nodeLabels](#1-bmh-nodelabels) | Provision time | ❌ | ✅ Yes |
| [NFD NodeFeatureRule](#2-nfd-nodefeaturerule) | Continuously | ✅ Yes | ❌ No |
| [RHACM ConfigurationPolicy](#3-rhacm-configurationpolicy) | Continuously enforced | ✅ Yes | ❌ No |
| [Ansible](#4-ansible) | On-demand / playbook | ✅ Yes | ❌ No |
| [ArgoCD pre-sync hook](#5-argocd-pre-sync-hook) | Before every sync | ✅ Yes | ❌ No |
| [Manual](#6-manual-oc-label) | Immediate | ✅ Yes | ❌ No |

Related: [A40 vGPU profile runbook](vgpu-a40-profiles.md)

---

## 1. BMH nodeLabels

**Best for:** Clusters where BareMetalHost resources are GitOps-managed.
Provisioning-time only — labels are applied when Metal3 provisions the node.
Changing them in Git after provisioning requires reprovisioning the node.

Labels defined in `$host.labels` in the cluster's `values.yaml` are merged
into the `BareMetalHost.spec.nodeLabels` by the `baremetal-hosts` Helm chart
and flow to the Kubernetes Node when Metal3 provisions it.

```yaml
# clusters/<cluster-name>/values.yaml
baremetal-hosts:
  cluster:
    baremetal:
      workers:
        - name: gpu-node-1
          role: gpu
          labels:
            nvidia.com/gpu.workload.config: vm-vgpu
            nvidia.com/vgpu.config: a40-8q
```

**Advantage:** Fully declarative, no external tooling. The same GitOps sync that
provisions the hardware also sets the label.

**Limitation:** One-time at provisioning. Profile changes on live nodes need
a different mechanism (Ansible, RHACM, or manual). Reprovisioning to apply a
new label means a node reboot.

---

## 2. NFD NodeFeatureRule

**Best for:** Clusters NOT in GitOps repo, or where all nodes of a given GPU
model should get the same default profile automatically.

NFD already scans each node's PCI bus. A `NodeFeatureRule` matches on PCI
vendor/device IDs and applies labels automatically and continuously. If the
label is removed, NFD reapplies it.

```yaml
apiVersion: nfd.k8s-sigs.io/v1alpha1
kind: NodeFeatureRule
metadata:
  name: a40-vgpu-default-profile
  namespace: nvidia-gpu-operator
spec:
  rules:
    - name: nvidia-a40-default
      labels:
        nvidia.com/vgpu.config: a40-8q
        nvidia.com/gpu.workload.config: vm-vgpu
      matchFeatures:
        - feature: pci.device
          matchExpressions:
            id:
              op: In
              value: ["2235"]     # NVIDIA A40 PCI device ID
            vendor:
              op: In
              value: ["10de"]     # NVIDIA vendor ID
```

This rule is templated in `components/nvidia-gpu-operator/instance/templates/vgpu-nfd-rule.yaml`
and driven by `clusterPolicy.vgpu.nfdRule` in the cluster values.

**Advantage:** Fully automatic. No per-node configuration. Nodes joining the
cluster get labeled immediately on hardware detection.

**Limitation:** One profile per GPU model. Cannot distinguish between two A40
nodes that should have different profiles (hardware is identical). Use BMH
labels or Ansible to override specific nodes.

**PCI device IDs for common datacenter GPUs:**

| GPU | PCI Device ID |
|-----|---------------|
| A40 | 2235 |
| A10 | 2236 |
| A100 PCIe 40GB | 20b3 |
| A100 PCIe 80GB | 20b2 |
| A100 SXM4 80GB | 20b5 |
| L40 | 26b5 |
| L40S | 26b9 |
| H100 PCIe 80GB | 2331 |
| H100 SXM5 80GB | 2330 |

---

## 3. RHACM ConfigurationPolicy

**Best for:** Multi-cluster environments where RHACM is the management plane.
Enforces labels continuously across all matching clusters — corrects drift.

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: vgpu-node-labels
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: gpu-node-vgpu-label
        spec:
          remediationAction: enforce
          severity: low
          object-templates-raw: |
            {{- range (lookup "v1" "Node" "" "").items }}
            {{- if eq (index .metadata.labels "nvidia.com/gpu.present") "true" }}
            - complianceType: musthave
              objectDefinition:
                apiVersion: v1
                kind: Node
                metadata:
                  name: {{ .metadata.name }}
                  labels:
                    nvidia.com/gpu.workload.config: vm-vgpu
                    nvidia.com/vgpu.config: a40-8q
            {{- end }}
            {{- end }}
```

**Advantage:** Continuous enforcement. Drift is corrected on every policy evaluation
cycle. Works across all managed clusters without per-cluster configuration.

**Limitation:** Policy applies the same label to all matching nodes in the cluster.
Per-node profile differences require a more complex policy with node-specific
targeting or a separate policy per profile tier.

---

## 4. Ansible

**Best for:** Post-provision profile changes, clusters not in GitOps repo, or
when per-node assignments need human review before applying.

An Ansible playbook can read the desired state from the `vgpu-node-profiles`
ConfigMap (rendered by ArgoCD) and apply the labels on the cluster:

```yaml
# roles/gpu-node-labels/tasks/main.yml
- name: Read vGPU node profile ConfigMap
  kubernetes.core.k8s_info:
    api_version: v1
    kind: ConfigMap
    name: "{{ vgpu_node_profiles_configmap }}"
    namespace: nvidia-gpu-operator
  register: node_profiles_cm

- name: Parse node assignments
  set_fact:
    node_assignments: "{{ node_profiles_cm.resources[0].data.nodes | from_yaml }}"

- name: Apply vGPU profile labels to nodes
  kubernetes.core.k8s:
    api_version: v1
    kind: Node
    name: "{{ item.key }}"
    definition:
      metadata:
        labels:
          nvidia.com/vgpu.config: "{{ item.value }}"
          nvidia.com/gpu.workload.config: vm-vgpu
  loop: "{{ node_assignments | dict2items }}"
  when: node_assignments is defined
```

**Usage:**

```bash
# Apply profile labels from the ConfigMap declared in Git
ansible-playbook site.yml -e vgpu_node_profiles_configmap=a40-vgpu-node-profiles

# Override a single node (profile change)
ansible-playbook gpu-label.yml \
  -e node_name=gpu-node-3 \
  -e vgpu_profile=a40-6q
```

**Advantage:** Explicit operator control. Gate changes behind a review step.
Read desired state from GitOps (the ConfigMap) so Ansible is the execution
layer, not the source of truth.

**Limitation:** Not continuous — requires a playbook run. Combine with a
pre-flight check that verifies no VMs are using vGPU before changing labels.

---

## 5. ArgoCD Pre-Sync Hook

**Best for:** Fully automated profile changes in a GitOps pipeline when you
trust the pipeline to drain VMs safely.

A pre-sync hook Job applies node labels before the main sync runs. This
ensures labels are set before the vGPU Device Manager ConfigMap change takes
effect.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: vgpu-node-labeler
  namespace: nvidia-gpu-operator
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      serviceAccountName: vgpu-node-labeler
      restartPolicy: OnFailure
      containers:
        - name: labeler
          image: registry.redhat.io/openshift4/ose-cli:latest
          command:
            - /bin/bash
            - -c
            - |
              set -euo pipefail

              # Read desired assignments from the ConfigMap
              NODES=$(oc get cm vgpu-node-profiles -n nvidia-gpu-operator \
                -o jsonpath='{.data.nodes}')

              # Apply labels — yq parses the YAML node map
              echo "$NODES" | yq e 'to_entries[] | [.key, .value] | @tsv' - | \
              while IFS=$'\t' read -r node profile; do
                echo "Labeling $node with vgpu.config=$profile"
                oc label node "$node" \
                  nvidia.com/vgpu.config="$profile" \
                  nvidia.com/gpu.workload.config=vm-vgpu \
                  --overwrite
              done
```

**Required RBAC:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: vgpu-node-labeler
rules:
  - apiGroups: [""]
    resources: [nodes]
    verbs: [get, list, patch, update]
  - apiGroups: [""]
    resources: [configmaps]
    verbs: [get]
```

**Advantage:** Fully automated, tied to the GitOps sync cycle. Labels are
always applied before the ConfigMap change that triggers profile changes.

**Limitation:** Requires cluster-admin-scoped ServiceAccount for the Job.
Does NOT gate behind VM drain — pair with a separate pre-sync hook that checks
for running VMs with attached vGPU before proceeding.

---

## 6. Manual (`oc label`)

For one-off changes, testing, or emergency profile overrides:

```bash
# Apply a single node label
oc label node <node-name> \
  nvidia.com/vgpu.config=a40-8q \
  nvidia.com/gpu.workload.config=vm-vgpu \
  --overwrite

# Verify
oc get node <node-name> -o json | \
  jq '.metadata.labels | to_entries[] | select(.key | startswith("nvidia.com/"))'

# Check vGPU Device Manager picked it up
oc logs -n nvidia-gpu-operator -l app=nvidia-vgpu-device-manager --tail=30

# Verify allocatable resources updated
oc get node <node-name> -o json | \
  jq '.status.allocatable | to_entries[] | select(.key | startswith("nvidia.com/"))'
```

**Warning:** Manual labels are not tracked in Git and will drift from the
declared state. NFD NodeFeatureRules or RHACM policies will overwrite manual
labels on their next evaluation cycle if a conflicting rule exists.

---

## Profile Change Procedure (Any Method)

Regardless of how the label is applied, changing an existing vGPU profile
on a live node follows this sequence:

1. **Stop or migrate VMs** using vGPU on the target node
   ```bash
   # Find VMs on node
   oc get vmi -A -o wide | grep <node-name>
   
   # Stop each VM (GPU VMs cannot live migrate)
   virtctl stop <vm-name> -n <namespace>
   ```

2. **Apply the new label** (via whichever method above)

3. **Confirm vGPU Device Manager is applying the change**
   ```bash
   oc logs -n nvidia-gpu-operator -l app=nvidia-vgpu-device-manager --tail=50
   ```

4. **Verify new allocatable resources**
   ```bash
   oc get node <node-name> -o json | \
     jq '.status.allocatable | to_entries[] | select(.key | startswith("nvidia.com/"))'
   ```

5. **Start VMs** with the updated `deviceName` in their spec

---

## Layering Multiple Methods

These methods are not mutually exclusive. A common production pattern:

```
BMH labels          → initial provisioning (default profile per node)
NFD NodeFeatureRule → catch any nodes not covered by BMH (bare-metal re-add, etc.)
RHACM Policy        → drift enforcement across clusters
Ansible             → profile change execution (gated behind VM drain check)
```

GitOps (`vgpu-node-profiles` ConfigMap) remains the **source of truth** — 
all other mechanisms read from it or respect the same values.

# SNO Local Storage — Reference

> **Audience:** Operators running the home-lab SNO cluster (`sno.hell`) on KVM.
> **Purpose:** Document the **bootstrap** Local Storage setup — how it was configured, verified, and torn down when migrating to dynamic storage.

This is **phase 1** storage only (static, one PV per disk).
**Superseded** by HPP on this cluster — see [dynamic-storage.md](dynamic-storage.md) for the active setup and reproduction steps.

Companion to the [SNO KVM lab setup guide](README.md).
Cluster kubeconfig: `devops/ocp/install/exec/auth/kubeconfig`.

---

## On this page

- [Summary](#summary)
- [Architecture](#architecture)
- [Why Local Storage Operator (not LVMS)](#why-local-storage-operator-not-lvms)
- [Prerequisites](#prerequisites)
- [Host: add a storage disk](#host-add-a-storage-disk)
- [Cluster: install and configure](#cluster-install-and-configure)
- [Verification](#verification)
- [Using storage in workloads](#using-storage-in-workloads)
- [DevSpaces](#devspaces)
- [Limitations](#limitations)
- [Operations](#operations)
- [Troubleshooting](#troubleshooting)
- [Related reading](#related-reading)

---

## Summary

| Item | Value |
|------|-------|
| Cluster | `sno` on `sno.hell` (OCP 4.22.0) |
| Node | Single node `sno` (control-plane + worker) |
| OS disk | `vda` — 200 GiB virtio (`/sysroot`) |
| Storage disk | `vdb` — 50 GiB virtio (dedicated, unpartitioned) |
| Operator | Local Storage Operator (`openshift-local-storage`) |
| LocalVolume | `sno-local` |
| StorageClass | `local-storage` (**default**) |
| PV | `local-pv-32cef17a` — 50 GiB, RWO, Filesystem |
| Binding mode | `WaitForFirstConsumer` |

Fresh SNO installs ship with **no StorageClass**.
PVCs stay `Pending` until a provisioner or static PV exists.
This setup was triggered by [OpenShift Dev Spaces](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces) workspace PVCs that could not bind.

---

## Architecture

```
KVM host
└── VM: sno
    ├── vda (200G)  → OCP install, /sysroot (xfs)
    └── vdb (50G)   → Local Storage PV (ext4, whole disk)
            │
            ▼
    Local Storage Operator (openshift-local-storage)
            │
            ▼
    StorageClass: local-storage (default)
            │
            ▼
    PVCs (e.g. DevSpaces claim-devworkspace)
```

Local Storage is **static provisioning**: one PersistentVolume is created per physical disk.
There is no dynamic expansion or multi-PVC slicing on a single disk.

---

## Why Local Storage Operator (not LVMS)

For SNO labs, Red Hat commonly recommends **LVM Storage (LVMS)** — lightweight, thin-provisioned local volumes.
On this cluster (OCP 4.22.0), `lvms-operator` was **not present** in the `redhat-operators` catalog:

```bash
oc get packagemanifest lvms-operator -n openshift-marketplace
# Error from server (NotFound)
```

`local-storage-operator` **was** available and fits a single dedicated virtio disk without LVM overhead.

If `lvms-operator` appears in a future catalog refresh, LVMS remains the better long-term option for multiple PVCs from one disk.
This document records what is actually deployed today.

---

## Prerequisites

- Healthy SNO cluster with `cluster-admin` access
- **Second virtio disk** attached to the VM — storage must not share the root filesystem
- Pull secret / registry access for `registry.redhat.io` (operator images)

---

## Host: add a storage disk

Run on the **KVM host** (not inside the cluster).
Requires `sudo`.

```bash
# Create a dedicated qcow2 (adjust size as needed)
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/sno-storage.qcow2 50G

# Attach to the running VM (--persistent survives reboots)
sudo virsh attach-disk sno \
  /var/lib/libvirt/images/sno-storage.qcow2 vdb \
  --driver qemu --subdriver qcow2 --targetbus virtio --persistent
```

Confirm the disk is visible inside the guest:

```bash
export KUBECONFIG=~/gemini-workspace/devops/ocp/install/exec/auth/kubeconfig

oc debug node/sno -- chroot /host lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
```

Expected: `vdb` ~50G, no `FSTYPE`, no `MOUNTPOINT`.

Capture the stable device path (used in `LocalVolume`):

```bash
oc debug node/sno -- chroot /host ls -la /dev/disk/by-path/ | grep vdb
# Example: virtio-pci-0000:07:00.0 -> ../../vdb
```

> **Note:** The `virtio-pci-0000:…` address depends on PCI slot order.
> If you remove and re-attach disks, re-check this path before applying `LocalVolume`.

---

## Cluster: install and configure

Manifests are also saved at [local-storage.yaml](local-storage.yaml).

### 1. Install Local Storage Operator

```bash
export KUBECONFIG=~/gemini-workspace/devops/ocp/install/exec/auth/kubeconfig

oc apply -f local-storage.yaml
# Applies namespace, OperatorGroup, Subscription, LocalVolume, and default StorageClass annotation
```

Or step by step:

```bash
oc apply -f - <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-local-storage
  labels:
    openshift.io/cluster-monitoring: "true"
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/warn: privileged
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-local-storage
  namespace: openshift-local-storage
spec:
  targetNamespaces:
  - openshift-local-storage
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: local-storage-operator
  namespace: openshift-local-storage
spec:
  channel: stable
  name: local-storage-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  installPlanApproval: Automatic
EOF
```

Wait for the CSV:

```bash
oc get csv -n openshift-local-storage -l operators.coreos.com/local-storage-operator
oc get pods -n openshift-local-storage
```

### 2. Create LocalVolume

Replace `devicePaths` if your `by-path` symlink differs:

```bash
oc apply -f - <<'EOF'
apiVersion: local.storage.openshift.io/v1
kind: LocalVolume
metadata:
  name: sno-local
  namespace: openshift-local-storage
spec:
  nodeSelector:
    nodeSelectorTerms:
    - matchExpressions:
      - key: kubernetes.io/hostname
        operator: In
        values:
        - sno
  storageClassDevices:
  - devicePaths:
    - /dev/disk/by-path/virtio-pci-0000:07:00.0
    fsType: ext4
    storageClassName: local-storage
    volumeMode: Filesystem
EOF
```

The diskmaker DaemonSet formats the disk and creates a PersistentVolume.

### 3. Set default StorageClass

```bash
oc patch storageclass local-storage \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

---

## Verification

```bash
oc get storageclass
# local-storage (default)   kubernetes.io/no-provisioner   WaitForFirstConsumer

oc get localvolume -n openshift-local-storage
# sno-local   Available

oc get pv
# local-pv-32cef17a   50Gi   RWO   Bound (or Available if no claims)

oc get pods -n openshift-local-storage
# diskmaker-manager-*   2/2 Running
# local-storage-operator-*   1/1 Running
```

Quick functional test:

```bash
oc apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: storage-smoke-test
  namespace: default
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: storage-smoke-test
  namespace: default
spec:
  containers:
  - name: test
    image: registry.redhat.io/ubi9/ubi-minimal:latest
    command: ["sleep", "120"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: storage-smoke-test
  restartPolicy: Never
EOF

oc wait --for=condition=Ready pod/storage-smoke-test -n default --timeout=120s
oc exec storage-smoke-test -n default -- df -h /data

oc delete pod, pvc storage-smoke-test -n default
```

With `WaitForFirstConsumer`, the PVC stays `Pending` until a pod that uses it is scheduled.

---

## Using storage in workloads

Omit `storageClassName` to use the default:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-data
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  volumeMode: Filesystem
```

Platform components that need persistent volumes (e.g. Prometheus) can reference `local-storage` explicitly.
See [Prometheus monitoring storage](../../troubleshooting/prometheus-monitoring-storage/README.md).

---

## DevSpaces

OpenShift Dev Spaces (`CheCluster`) uses `pvcStrategy: per-user`.
Each workspace gets a PVC (e.g. `claim-devworkspace`).

Before storage was configured:

```
0/1 nodes are available: 1 node(s) didn't find available persistent volumes to bind
```

After `local-storage` was in place, the DevSpaces PVC bound and the workspace pod scheduled.
DevSpaces may still fail on **other** prerequisites (e.g. internal image registry removed) — that is separate from storage.

---

## Limitations

| Topic | Behavior on this cluster |
|-------|--------------------------|
| PVC count per disk | **One PV per physical disk** — only one bound claim at a time on `vdb` |
| Access mode | **RWO** only — no ReadWriteMany |
| Capacity | PVC `requests.storage` can be less than 50 GiB, but the PV is still the full disk |
| Binding | `WaitForFirstConsumer` — PVC binds when a pod is scheduled |
| Reclaim policy | `Delete` — deleting the PVC releases the PV; data on disk may need manual wipe before reuse |
| High availability | None — data lives on the single SNO node |

For multiple concurrent PVCs, migrate to dynamic storage per [dynamic-storage.md](dynamic-storage.md) (LVMS target, HPP fallback).

---

## Operations

### Check what is using the volume

```bash
oc get pv -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CLAIM:.spec.claimRef.namespace/.spec.claimRef.name
oc get pvc -A | grep local-storage
```

### Add a second storage disk

1. Create and attach another qcow2 as `vdc` on the KVM host
2. Discover its `by-path` symlink on the node
3. Add another entry under `storageClassDevices` in `LocalVolume` **or** create a second `LocalVolume` with a different `storageClassName`

### Remove storage (destructive)

```bash
# Delete all PVCs using local-storage first
oc delete localvolume sno-local -n openshift-local-storage
oc delete sub local-storage-operator -n openshift-local-storage
oc delete ns openshift-local-storage
```

On the KVM host, detach and remove the qcow2 if no longer needed.

### Lab cleanup (VM teardown)

If destroying the VM per the [SNO lab cleanup](README.md#cleanup), also remove the storage disk:

```bash
sudo rm /var/lib/libvirt/images/sno-storage.qcow2
```

---

## Troubleshooting

### PVC stuck in Pending — no StorageClass

```bash
oc get storageclass
```

No default class → apply `LocalVolume` and patch default annotation (see above).

### PVC stuck in Pending — WaitForFirstConsumer

Normal until a pod references the claim.
Create or start the workload that mounts the PVC.

### Pod event: didn't find available persistent volumes to bind

- Confirm a PV exists: `oc get pv`
- Confirm PV `storageClassName` matches the PVC
- Confirm PV is `Available` or bound to this claim
- With one disk, only **one** PVC can bind at a time

### Wrong device path after disk change

```bash
oc debug node/sno -- chroot /host ls -la /dev/disk/by-path/
```

Update `LocalVolume` `devicePaths` and re-apply.
Do not point at `vda` or any mounted partition.

### PV status Released after PVC delete

Local PVs may need manual reclaim:

```bash
oc patch pv <pv-name> -p '{"spec":{"claimRef": null}}'
```

Or wipe the disk and let diskmaker recreate the PV.

### LVMS not in OperatorHub

Observed on OCP 4.22.0 — use Local Storage Operator or wait for catalog update.
Verify with:

```bash
oc get packagemanifest -n openshift-marketplace | grep -E 'lvms|local-storage'
```

---

## Related reading

- [dynamic-storage.md](dynamic-storage.md) — LVMS target, HPP fallback, migration procedures
- [SNO KVM lab setup](README.md) — cluster install, networking, DNS
- [local-storage.yaml](local-storage.yaml) — committed manifests for this setup
- [lvms.yaml](lvms.yaml) — LVMS subscription template (when catalog has `lvms-operator`)
- [hpp.yaml](hpp.yaml) — HPP fallback manifests
- [Prometheus monitoring storage](../../troubleshooting/prometheus-monitoring-storage/README.md) — CMO `storageClassName` configuration
- [Red Hat — Persistent storage using local storage (OCP 4.19)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/storage/persistent-storage-using-local-storage)

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author.
See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

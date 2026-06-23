# SNO Dynamic Storage — Strategy and Migration

> **Audience:** Operators running the home-lab SNO cluster (`sno.hell`) on KVM.
> **Purpose:** Record the storage roadmap (LVMS target, HPP fallback), why each option was evaluated, and how to migrate off the bootstrap [Local Storage](local-storage.md) setup.

Companion to the [SNO KVM lab setup guide](README.md).
Cluster kubeconfig: `devops/ocp/install/exec/auth/kubeconfig`.

---

## On this page

- [Decision summary](#decision-summary)
- [Current state (bootstrap)](#current-state-bootstrap)
- [Target: LVMS](#target-lvms)
- [Fallback: HostPath Provisioner (HPP)](#fallback-hostpath-provisioner-hpp)
- [Avoided: full ODF (Ceph)](#avoided-full-odf-ceph)
- [Option comparison](#option-comparison)
- [Migration overview](#migration-overview)
- [LVMS procedure](#lvms-procedure)
- [HPP procedure (reproduce end-to-end)](#hpp-procedure-reproduce-end-to-end)
- [Post-storage: internal image registry](#post-storage-internal-image-registry)
- [Manifest index](#manifest-index)
- [Experiment checklist](#experiment-checklist)
- [Related reading](#related-reading)

---

## Decision summary

| Phase | Provisioner | Status |
|-------|-------------|--------|
| **Bootstrap** | Local Storage Operator | **Retired** — superseded by HPP |
| **Target** | LVM Storage (LVMS) | **Blocked** — `lvms-operator` not in OCP 4.22 catalog |
| **Active** | HostPath Provisioner (HPP) | **Deployed** — `hostpath-csi` default; pool on `vdb` at `/var/hpvolumes` (2026-06-11) |

**Goal:** Dynamic provisioning — multiple PVCs from one disk (DevSpaces, image registry, apps).

Local Storage was the right **bootstrap** (unblocked DevSpaces PVC binding).
It is not the long-term answer (one PV per disk, no slicing).

---

## Current state (deployed)

| Item | Value |
|------|-------|
| Disk | `vdb` — 50 GiB virtio, ext4, mounted at `/var/hpvolumes` |
| Provisioner | HostPath Provisioner (`hostpath-provisioner` namespace) |
| StorageClass | `hostpath-csi` (**default**) |
| Pool path | `/var/hpvolumes` on `vdb` |
| Bootstrap (retired) | Local Storage Operator — removed after HPP cutover; see [local-storage.md](local-storage.md) for history |

**Original trigger:** DevSpaces workspace PVC stayed `Pending` with no default StorageClass.

**Post-storage fix:** Internal image registry enabled for DevSpaces — see [image-registry-sno-lab.md](image-registry-sno-lab.md).

---

## Target: LVMS

**LVM Storage (LVMS)** is Red Hat's supported dynamic local storage for SNO.
It uses TopoLVM + LVM thin pools on dedicated block device(s).

```
vdb (50G, empty disk — no filesystem)
  └── LVM volume group
        └── thin pool (~90% of VG)
              ├── PVC: devspaces (15Gi)
              ├── PVC: image-registry (10Gi)
              └── PVC: other apps
```

### Why LVMS

- Dynamic PVC provisioning (true StorageClass provisioner)
- Multiple concurrent PVCs from one disk
- Thin provisioning with overcommit (lab-friendly)
- Red Hat documented SNO path (successor to "ODF LVM Operator" on single node)
- Uses raw block devices — fits dedicated `vdb` without sharing root `/var`

### Blocker (OCP 4.22.0, verified 2026-06-11)

```bash
oc get packagemanifest lvms-operator -n openshift-marketplace
# Error from server (NotFound)

oc apply -f lvms.yaml   # Subscription
# constraints not satisfiable: no operators found in package lvms-operator
```

Confirmed inside `redhat-operator-index:v4.22` catalog pod: no `lvms-operator` package directory.
This is a **catalog content gap**, not a cluster misconfiguration.

### LVMS chase list

1. Re-check OperatorHub after catalog pod refresh / OCP z-stream upgrade
2. Confirm pull secret / developer subscription entitlements with Red Hat
3. Ask Red Hat whether LVMS was intentionally dropped from 4.22 index
4. Evaluate supplemental `CatalogSource` from an older index that included LVMS (lab-only, unsupported)
5. When installable → follow [LVMS procedure](#lvms-procedure) below

Manifest template: [lvms.yaml](lvms.yaml)

---

## Fallback: HostPath Provisioner (HPP)

**HostPath Provisioner** is what **CRC** (OpenShift Local) uses for default dynamic storage (`crc-csi-hostpath-provisioner`).

HPP creates a subdirectory per PVC under a **host path** (e.g. `/var/hpvolumes`).
It is **dynamic** and supports **multiple concurrent PVCs**.

### Why HPP as fallback

- Solves the multi-PVC problem immediately
- Well understood from CRC / dev clusters
- Does not require `lvms-operator` in catalog
- Can back the pool with mounted `vdb` (keeps storage off root `/var`)

### HPP caveats

| Topic | Detail |
|-------|--------|
| Support | Community operator ([kubevirt/hostpath-provisioner-operator](https://github.com/kubevirt/hostpath-provisioner-operator)); also bundled with OpenShift Virtualization (CNV) |
| Access mode | RWO only, node-local |
| Production | Lab/dev — not a production storage platform |
| Prerequisites | cert-manager (for HPP operator webhook, v0.11+) |
| Pool path | Directory on node filesystem — prefer `vdb` mounted at `/var/hpvolumes`, not root `/var` free space |
| Coexistence | Cannot share `vdb` with Local Storage PV — migrate, don't run both on same disk |

### HPP vs CRC

CRC pre-installs HPP and wires `crc-csi-hostpath-provisioner` as default.
On full OCP SNO you install HPP yourself (standalone operator or via CNV).

Manifest template: [hpp.yaml](hpp.yaml)

---

## Avoided: full ODF (Ceph)

`odf-operator` **is** in the catalog (`stable-4.21`) but deploys **Ceph/Rook** — not the SNO dynamic-local path.

| Factor | This cluster |
|--------|--------------|
| Red Hat SNO guidance | LVMS for dynamic local — not full Ceph |
| RAM | 32 GiB — below ODF compact minimums (72 GiB+ per node on 3-node compact) |
| Disks | 2 (OS + one storage) — Ceph-on-SNO lab guides want 3+ |
| Ops cost | Heavy (OSDs, mon, mgr, tuning) for DevSpaces + registry |

**Verdict:** Do not install `odf-operator` / `StorageCluster` on this SNO unless the lab is deliberately expanded (64 GiB+ RAM, additional disks).

---

## Option comparison

| Option | Dynamic | Multi-PVC | Uses `vdb` | In 4.22 catalog | Lab fit |
|--------|---------|-----------|------------|-----------------|---------|
| Local Storage (retired) | No | No | Yes (raw) | Yes | Bootstrap only |
| **LVMS (target)** | **Yes** | **Yes** | Yes (raw) | **No** | **Best** |
| **HPP (fallback)** | **Yes** | **Yes** | Yes (mounted path) | Via CNV or community | **Good** |
| NFS provisioner | Yes | Yes | N/A | Yes | Good if NAS available |
| Full ODF Ceph | Yes | Yes | Yes | Yes | Poor on this hardware |

---

## Migration overview

Both LVMS and HPP require **releasing `vdb` from Local Storage** first.

```
1. Stop workloads using local-storage PVCs (DevSpaces workspace, etc.)
2. Delete PVCs bound to local-pv-*
3. Delete LocalVolume sno-local
4. (Optional) Remove openshift-local-storage operator
5. Wipe vdb OR remount for HPP:
   - LVMS: disk must be empty (no filesystem signature)
   - HPP: format + mount vdb at /var/hpvolumes (MachineConfig)
6. Install LVMS or HPP
7. Set new StorageClass as default
8. Recreate workloads
```

**Do not skip step 5** — LVMS ignores disks with existing filesystems; HPP needs a directory mount, not a raw PV.

---

## LVMS procedure

Run when `lvms-operator` is installable.

### 1. Tear down Local Storage

```bash
export KUBECONFIG=~/gemini-workspace/devops/ocp/install/exec/auth/kubeconfig

# Stop DevSpaces workspace and delete its PVC first
oc delete devworkspace --all -A --wait=true
oc delete pvc -A -l <selector-if-needed>

oc delete localvolume sno-local -n openshift-local-storage
oc patch storageclass local-storage -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

### 2. Wipe vdb on the node

```bash
oc debug node/sno -- chroot /host wipefs -a /dev/vdb
oc debug node/sno -- chroot /host lsblk -o NAME,FSTYPE /dev/vdb
# FSTYPE must be empty
```

### 3. Install LVMS

```bash
oc apply -f lvms.yaml
oc get csv -n openshift-storage -w
```

Adjust `channel` in [lvms.yaml](lvms.yaml) to match your OCP minor (e.g. `stable-4.22`).

### 4. Create LVMCluster

Update device path after `lsblk` / `by-path` check:

```bash
oc apply -f - <<'EOF'
apiVersion: lvm.topolvm.io/v1alpha1
kind: LVMCluster
metadata:
  name: sno-lvmcluster
  namespace: openshift-storage
spec:
  storage:
    deviceClasses:
    - name: vg1
      deviceSelector:
        paths:
        - /dev/disk/by-path/virtio-pci-0000:07:00.0
      thinPoolConfig:
        name: thin-pool-1
        sizePercent: 90
        overprovisionRatio: 10
      volumeGroup:
        name: vg1
  default: true
EOF
```

### 5. Verify

```bash
oc get storageclass
# Expect lvms-vg1 or similar

oc apply -f storage-smoke-test.yaml
```

---

## HPP procedure (reproduce end-to-end)

Run this if LVMS is unavailable (current lab path).
All manifests live in this directory — see [manifest index](#manifest-index).

**Prerequisites:** SNO cluster healthy; second virtio disk (`vdb`) attached on KVM host — [local-storage.md § Host](local-storage.md#host-add-a-storage-disk).

```bash
export KUBECONFIG=~/gemini-workspace/devops/ocp/install/exec/auth/kubeconfig
cd ~/gemini-workspace/devops/ocp/examples/sno-kvm-lab
```

### Step 0 — Tear down Local Storage (skip if fresh install, never had it)

```bash
oc delete devworkspace --all -A --wait=true
oc delete pvc claim-devworkspace -n che-kube-admin-devspaces-qcgubv --ignore-not-found
oc delete localvolume sno-local -n openshift-local-storage --ignore-not-found
# Optional: oc delete ns openshift-local-storage
```

### Step 1 — Discover vdb device path

```bash
oc debug node/sno -- chroot /host ls -la /dev/disk/by-path/ | grep vdb
# Example: virtio-pci-0000:07:00.0 -> ../../vdb
```

Update `What=` in [hpp-vdb-mount.yaml](hpp-vdb-mount.yaml) if your path differs.

### Step 2 — Format vdb (once)

The mount unit expects ext4.
After Local Storage removal, `vdb` may have **no filesystem** — the mount unit will fail without this.

```bash
oc debug node/sno -- chroot /host bash -c \
  'lsblk -o NAME,FSTYPE /dev/vdb; mkfs.ext4 -F /dev/vdb'
```

> **Note:** `mkfs` is destructive.
> Only run when `vdb` has no data you need.
> On a **brand-new** disk, always format before first mount.

### Step 3 — Apply MachineConfig (persistent mount at boot)

```bash
oc apply -f hpp-vdb-mount.yaml
```

Wait for the master pool (SNO reboots the node — can take several minutes):

```bash
watch oc get machineconfigpool master
# UPDATED=True  UPDATING=False

oc get node sno -o jsonpath='{.metadata.annotations.machineconfiguration\.openshift\.io/state}{"\n"}'
# Done
```

If the mount unit failed at boot, fix manually then verify:

```bash
oc debug node/sno -- chroot /host bash -c \
  'mkdir -p /var/hpvolumes && systemctl start var-hpvolumes.mount && df -h /var/hpvolumes && chcon -R -t container_file_t /var/hpvolumes'
```

**MCO pitfall:** Do not add `storage.directories` for `/var/hpvolumes` in the MachineConfig — MCO rejects it (`ignition directories section contains changes`).
The mount unit creates the mount point.

### Step 4 — Install cert-manager (if not present)

HPP operator v0.11+ requires cert-manager for its validating webhook.

```bash
oc get pods -n cert-manager
# All Running — skip if already installed (this cluster has OpenShift cert-manager Operator)
```

If missing, install **cert-manager Operator for Red Hat OpenShift** from OperatorHub.

### Step 5 — Install HPP operator (upstream — not in hpp.yaml)

```bash
oc apply -f https://raw.githubusercontent.com/kubevirt/hostpath-provisioner-operator/main/deploy/namespace.yaml
oc apply -f https://raw.githubusercontent.com/kubevirt/hostpath-provisioner-operator/main/deploy/webhook.yaml -n hostpath-provisioner
oc apply -f https://raw.githubusercontent.com/kubevirt/hostpath-provisioner-operator/main/deploy/operator.yaml -n hostpath-provisioner

oc wait --for=condition=Available hostpathprovisioner/hostpath-provisioner \
  -n hostpath-provisioner --timeout=300s 2>/dev/null || \
  oc get pods -n hostpath-provisioner -w
```

### Step 6 — Apply HPP CR + StorageClass

```bash
oc apply -f hpp.yaml
```

This creates the `HostPathProvisioner` CR (pool `local` → `/var/hpvolumes`) and `hostpath-csi` StorageClass (default).

If you migrated from Local Storage, unset the old default (StorageClass may already be gone):

```bash
oc patch storageclass local-storage \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' \
  --ignore-not-found
```

Restart CSI if pods are stale after node reboot:

```bash
oc delete pod -n hostpath-provisioner -l app=hostpath-provisioner-csi --force --grace-period=0
```

### Step 7 — Verify

```bash
oc get storageclass
oc get pods -n hostpath-provisioner

oc apply -f storage-smoke-test.yaml
oc wait --for=condition=Ready pod -l app=storage-smoke -n default --timeout=180s
oc get pvc -n default | grep storage-smoke   # both Bound

oc delete -f storage-smoke-test.yaml
```

Expected: two PVCs bound concurrently on `hostpath-csi`; PV capacity reports ~filesystem size on `vdb` (~48–49 GiB), not the 1 GiB request.

---

## Post-storage: internal image registry

After storage works, **DevSpaces** (and some operators) may still fail — PVCs bind, but init containers cannot pull `openshift/cli` from the internal registry.

SNO often ships with the registry **Removed**. Enable it as a follow-up step:

| Step | Doc |
|------|-----|
| Enable registry + import `cli` | [image-registry-sno-lab.md](image-registry-sno-lab.md) |
| External push/pull auth | [image-registry-auth](../../troubleshooting/image-registry-auth/README.md) |

Quick version:

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge -p '{
  "spec": {"managementState": "Managed", "replicas": 1, "storage": {"emptyDir": {}}}
}'
oc import-image cli:latest -n openshift --confirm
oc delete devworkspace --all -A --ignore-not-found   # retry from dashboard
```

---

## Manifest index

| File | Purpose |
|------|---------|
| [hpp-vdb-mount.yaml](hpp-vdb-mount.yaml) | MachineConfig — mount `vdb` at `/var/hpvolumes` on boot |
| [hpp.yaml](hpp.yaml) | `HostPathProvisioner` CR + `hostpath-csi` StorageClass |
| [storage-smoke-test.yaml](storage-smoke-test.yaml) | Two-PVC concurrent bind test |
| [lvms.yaml](lvms.yaml) | LVMS subscription (when catalog has `lvms-operator`) |
| [local-storage.yaml](local-storage.yaml) | Bootstrap only — static Local Storage (superseded by HPP) |
| [local-storage.md](local-storage.md) | Bootstrap history + host disk attach steps |

---

## Experiment checklist

Track progress when validating on the live cluster.
Last run: **2026-06-11**.

### LVMS

- [x] `oc get packagemanifest lvms-operator` — **NotFound** on OCP 4.22.0
- [ ] Subscription in `openshift-storage` reaches CSV `Succeeded` — blocked on catalog
- [ ] `LVMCluster` reports healthy / `lvms-vg1` StorageClass appears
- [ ] Multi-PVC smoke test: two PVCs bind concurrently

### HPP (active provisioner)

- [x] cert-manager operational
- [x] HPP operator + CSI daemonset Running
- [x] `vdb` mounted at `/var/hpvolumes` via `99-sno-hpp-vdb-mount` MachineConfig
- [x] `mkfs.ext4` on `vdb` required once after Local Storage removal (disk had no filesystem)
- [x] `hostpath-csi` set as **default** StorageClass
- [x] Local Storage (`sno-local`) removed
- [x] Multi-PVC smoke test passed on `vdb` pool (~48 GiB reported per PV — filesystem capacity, not request size)
- [x] Internal image registry enabled — [image-registry-sno-lab.md](image-registry-sno-lab.md)
- [ ] DevSpaces workspace recreated from dashboard after registry fix

**Notes:**

- MCO pool status can lag behind node `state=Done` during SNO reboot — wait or check node annotations
- Operator from [kubevirt/hostpath-provisioner-operator](https://github.com/kubevirt/hostpath-provisioner-operator) upstream manifests

---

## Related reading

- [local-storage.md](local-storage.md) — bootstrap history (superseded)
- [hpp-vdb-mount.yaml](hpp-vdb-mount.yaml) — vdb mount MachineConfig
- [hpp.yaml](hpp.yaml) — HPP CR + StorageClass
- [storage-smoke-test.yaml](storage-smoke-test.yaml) — verification
- [lvms.yaml](lvms.yaml) — LVMS subscription (future)
- [Red Hat — ODF on SNO (LVMS lineage)](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.11/html-single/deploying_and_managing_openshift_data_foundation_on_single_node_openshift_clusters/index)
- [KubeVirt HPP operator](https://github.com/kubevirt/hostpath-provisioner-operator)
- [HostPath Provisioner cookbook](https://redhatquickcourses.github.io/ocp-virt-cookbook/ocp-virt-cookbook/1/storage/hostpath-provisioner.html)
- [image-registry-sno-lab.md](image-registry-sno-lab.md) — enable internal registry (DevSpaces `oc-cli`)
- [Image registry auth](../../troubleshooting/image-registry-auth/README.md) — external push/pull and RBAC

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author.
See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

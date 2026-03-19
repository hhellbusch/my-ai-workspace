# NFS Portworx Proxy PVC Takes 20+ Minutes to Report Ready

## Overview

Workloads using storage via a **NFS Portworx proxy PVC** may experience 20+ minute delays before the PVC is considered ready—either the PVC stays in `Pending` before binding, or the pod stays in a mounting/waiting state after the PVC is `Bound`. This guide helps you isolate whether the delay is in **provisioning** (CSI/Portworx creating the proxy volume) or **mount** (NFS mount on the node when the pod schedules).

## Quick Links

- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Diagnostic commands and quick checks ⚡

---

## Architecture Context

### NFS Portworx Proxy Volume Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│  PVC (proxy volume)  →  CSI (Portworx)  →  Proxy volume created         │
│  Pod scheduled       →  Portworx on node →  NFS mount to external server  │
└─────────────────────────────────────────────────────────────────────────┘
```

- **Provisioning**: Portworx CSI creates a proxy volume that references the external NFS share (`proxy_endpoint`, `proxy_nfs_exportpath`). This can be slow if NFS endpoint validation or Portworx cluster response is slow.
- **Mount (first use)**: When a pod using the PVC is scheduled on a node, the Portworx pod on that node performs the actual NFS mount using the host’s NFS client. This is where **20+ minute** delays often occur—NFS server unreachable, DNS resolution, timeouts, or retries.

---

## Symptoms

- PVC remains `Pending` for 20+ minutes before becoming `Bound`, or
- PVC is `Bound` but the pod stays in `ContainerCreating` or similar for 20+ minutes with volume mount in progress.
- Events on the PVC or pod mention provisioning, waiting for volume, or mount timeouts.

---

## Investigation Workflow

### Phase 1: Pinpoint Where the Delay Occurs

**1. Check PVC and pod state**

```bash
# Replace with your namespace and PVC/pod names
NAMESPACE="<your-namespace>"
PVC_NAME="<your-pvc-name>"
POD_NAME="<pod-using-the-pvc>"

oc get pvc -n $NAMESPACE $PVC_NAME
oc get pod  -n $NAMESPACE $POD_NAME
oc describe pvc -n $NAMESPACE $PVC_NAME
oc describe pod -n $NAMESPACE $POD_NAME
```

- If **PVC is Pending** for a long time → delay is in **provisioning** (CSI/Portworx).
- If **PVC is Bound** but **pod is stuck** (e.g. `ContainerCreating`, `MountVolume.SetUp` or similar) → delay is in **mount** (NFS mount on node).

**2. Check events**

```bash
oc get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -40
oc get events -n kube-system --sort-by='.lastTimestamp' | grep -i portworx | tail -30
```

Look for repeated “waiting for volume”, “provisioning”, “mount”, or timeout messages.

---

### Phase 2: If Delay Is in Provisioning (PVC Stuck Pending)

**2.1 StorageClass and provisioner**

```bash
# StorageClass used by the PVC
oc get pvc -n $NAMESPACE $PVC_NAME -o jsonpath='{.spec.storageClassName}'
SC=$(oc get pvc -n $NAMESPACE $PVC_NAME -o jsonpath='{.spec.storageClassName}')
oc get storageclass $SC -o yaml
```

Confirm the StorageClass is for Portworx proxy volumes (e.g. `provisioner: pxd.portworx.com`, proxy parameters such as `proxy_endpoint`, `proxy_nfs_exportpath`).

**2.2 Portworx CSI controller**

```bash
# CSI controller (provisioning)
oc get pods -n kube-system -l app=px-csi-driver
oc logs -n kube-system -l app=px-csi-driver --tail=200 --prefix=true | grep -i "provision\|proxy\|nfs\|error"
```

**2.3 Portworx cluster health**

```bash
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status
```

If the cluster is degraded or slow to respond, provisioning will be slow. See [portworx-csi-crashloop](../portworx-csi-crashloop/README.md) for Portworx-focused troubleshooting.

---

### Phase 3: If Delay Is in Mount (PVC Bound, Pod Stuck Mounting)

This is the most common cause of “20+ minutes until ready” with NFS proxy volumes: the NFS mount on the node where the pod runs is slow or timing out.

**3.1 Identify the node and Portworx pod**

```bash
NODE=$(oc get pod -n $NAMESPACE $POD_NAME -o jsonpath='{.spec.nodeName}')
echo "Pod node: $NODE"
oc get pods -n kube-system -l name=portworx -o wide | grep $NODE
PX_NODE_POD=$(oc get pods -n kube-system -l name=portworx -o wide | grep $NODE | awk '{print $1}')
echo "Portworx pod on node: $PX_NODE_POD"
```

**3.2 Portworx logs on that node (mount/NFS errors)**

```bash
oc logs -n kube-system $PX_NODE_POD --tail=300 | grep -i "nfs\|mount\|proxy\|timeout\|error"
```

**3.3 NFS connectivity from the cluster**

- **DNS**: If `proxy_endpoint` is a hostname, resolution from the node (or from the Portworx pod’s network) must be fast and correct.

  ```bash
  # Run from a pod on the same node, or check node's resolv.conf
  oc run -n default nfs-dns-test --rm -it --restart=Never --image=registry.access.redhat.com/ubi9/ubi-minimal -- \
    sh -c "getent hosts <your-nfs-server-hostname>"
  ```

- **Reachability/port**: NFS server must be reachable on the required ports (e.g. 2049 for NFS, plus portmapper if used) from worker nodes.

**3.4 NFS mount options (StorageClass)**

Slow or flaky NFS often benefits from explicit timeouts and retries. Check the StorageClass used by the PVC:

```bash
oc get storageclass $SC -o yaml
```

Look for `mount_options`. Common options that can reduce perceived “hang” and avoid long defaults:

- `timeo=600` — NFS client timeout (deciseconds). Defaults can be large; 600 = 60 seconds.
- `retrans=5` — Number of retries before failure.
- `nfsvers=4` or `vers=4.0` — Use NFSv4 if your server supports it (often simpler firewall and better behavior).
- `noresvport` — Use non-reserved ports for NFS; can avoid timeouts on some networks/firewalls.

If `mount_options` is missing or has very high effective timeouts, the first mount can take many minutes on a slow or unreachable NFS server.

---

## Common Causes and Mitigations

| Cause | What to check | Mitigation |
|-------|----------------|------------|
| **NFS server slow or unreachable** | Events, Portworx logs on node, connectivity from node to NFS server | Fix NFS server/network; add `timeo`/`retrans` in `mount_options` to fail faster and retry more predictably. |
| **DNS resolution slow or failing** | Resolve NFS hostname from cluster/node | Fix DNS; or use NFS server IP in `proxy_endpoint` to avoid DNS. |
| **Default NFS timeouts too large** | StorageClass `mount_options` | Add e.g. `timeo=600,retrans=5` (and `noresvport` if needed). |
| **Portworx cluster degraded** | `pxctl status`, Portworx/CSI logs | Resolve Portworx health first (see [portworx-csi-crashloop](../portworx-csi-crashloop/README.md)). |
| **First mount per node** | First pod on a node using this NFS export | First mount can be slower; subsequent pods on same node reuse the mount. Consider node affinity to concentrate workloads. |
| **Firewall/security** | NFS ports (2049, portmapper) from workers to NFS server | Open required ports; consider `noresvport` if privileged ports are blocked. |

---

## Recommended StorageClass Tuning (NFS Proxy)

If your StorageClass does not already set mount options, add or adjust them. Example (adjust to your NFS version and environment):

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-nfs-proxy
provisioner: pxd.portworx.com
parameters:
  proxy_endpoint: "nfs://<nfs-server>"
  proxy_nfs_exportpath: "/exported/path"
  mount_options: "vers=4.0,timeo=600,retrans=5,noresvport"
```

- **vers=4.0** — Use NFSv4 if supported (matches Portworx examples).
- **timeo=600** — 60 s timeout per NFS request (tune down for faster failure, up if network is legitimately slow).
- **retrans=5** — Retries before hard failure.
- **noresvport** — Avoids privileged port binding issues on some setups.

**Source of the timeout/retrans/noresvport recommendation:** Portworx’s proxy-volume docs only show `mount_options: "vers=4.0"` and do not mention `timeo`, `retrans`, or `noresvport`. The recommendation above comes from **general Linux NFS client behavior** (the host’s NFS utilities that Portworx uses to perform the mount): Linux `mount.nfs` and kernel NFS options document `timeo` (deciseconds) and `retrans`, and NFS troubleshooting guidance elsewhere (e.g. timeout issues with NFS mounts, firewall/privileged-port problems) often suggests explicit timeouts and `noresvport`. So this is **inferred from standard NFS client tuning**, not from Portworx documentation. Whether the absence in Portworx docs is an oversight is unclear—they may assume a healthy NFS endpoint or avoid prescribing kernel-specific options. If you open a case with Portworx or Red Hat, ask whether they recommend or support these options for proxy volumes.

After changing the StorageClass, **existing PVCs keep their existing mount options**; new PVCs (or recreated ones) will use the new options.

---

## Verification After Changes

1. Create a new test PVC using the same (or updated) StorageClass.
2. Create a pod that mounts the PVC.
3. Measure time until:
   - PVC is `Bound`
   - Pod is `Running` and volume is mounted (e.g. `oc get pod -w`, then `oc exec ... -- df -h /path`).

If the delay is still 20+ minutes, capture:

- `oc describe pvc` and `oc describe pod` (and pod events).
- Portworx CSI controller logs and Portworx node pod logs (on the node where the pod schedules).
- NFS server logs and network path (latency, packet loss) from a worker to the NFS server.

---

## Escalation

- **Portworx**: Use Portworx must-gather and share with support:  
  `oc adm must-gather --image=registry.connect.redhat.com/portworx/must-gather:latest`
- **Red Hat**: Include the above diagnostics and reference this guide when opening a case.

---

## Related Guides

- [Portworx CSI CrashLoopBackOff](../portworx-csi-crashloop/README.md) — Portworx/CSI health and provisioning issues.
- [CoreOS Networking Issues](../coreos-networking-issues/README.md) — Network/DNS issues on nodes.

---

*AI-assisted content. Validate commands and StorageClass parameters against your cluster and Portworx/NFS documentation.*

# Quick Reference: NFS Portworx Proxy PVC Slow Ready (20+ Minutes)

## Where Is the Delay?

```bash
# Set these
NAMESPACE="<namespace>"
PVC_NAME="<pvc-name>"
POD_NAME="<pod-using-pvc>"

# PVC still Pending? → provisioning slow (CSI/Portworx)
oc get pvc -n $NAMESPACE $PVC_NAME

# PVC Bound but pod stuck? → mount slow (NFS on node)
oc get pod -n $NAMESPACE $POD_NAME
oc describe pod -n $NAMESPACE $POD_NAME | tail -30
```

## Quick Diagnostics

### PVC and events

```bash
oc describe pvc -n $NAMESPACE $PVC_NAME
oc get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -30
oc get events -n kube-system --sort-by='.lastTimestamp' | grep -i portworx | tail -20
```

### StorageClass (proxy + mount options)

```bash
SC=$(oc get pvc -n $NAMESPACE $PVC_NAME -o jsonpath='{.spec.storageClassName}')
oc get storageclass $SC -o yaml
# Look for: proxy_endpoint, proxy_nfs_exportpath, mount_options
```

### Portworx cluster health

```bash
oc get pods -n kube-system -l name=portworx -o wide
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status
```

### Mount delay: node and Portworx logs

```bash
NODE=$(oc get pod -n $NAMESPACE $POD_NAME -o jsonpath='{.spec.nodeName}')
PX_NODE_POD=$(oc get pods -n kube-system -l name=portworx -o wide | grep $NODE | awk '{print $1}')
oc logs -n kube-system $PX_NODE_POD --tail=200 | grep -i "nfs\|mount\|proxy\|timeout\|error"
```

### NFS reachability (replace NFS server hostname)

```bash
# From a pod (same cluster network)
oc run nfs-test --rm -it --restart=Never --image=registry.access.redhat.com/ubi9/ubi-minimal -- \
  getent hosts <nfs-server-hostname>
```

## Quick Mitigation: Mount options

If the delay is at **mount** time and the StorageClass has no or weak `mount_options`, add timeouts and retries so the NFS client fails or succeeds more predictably:

```yaml
# In StorageClass parameters (new PVCs only)
mount_options: "vers=4.0,timeo=600,retrans=5,noresvport"
```

- `timeo=600` — 60 s per NFS request (tune as needed).
- `retrans=5` — retries.
- `noresvport` — use high ports (avoids some firewall/timeout issues).

Existing PVCs keep their original mount options; new PVCs get the updated ones.

## Decision Snapshot

| Observation | Next step |
|-------------|-----------|
| PVC Pending 20+ min | Check CSI/Portworx logs; Portworx cluster health |
| PVC Bound, pod stuck 20+ min | Check Portworx node logs; NFS connectivity; add/tune `mount_options` |
| Portworx not operational | Fix Portworx first — see [portworx-csi-crashloop](../portworx-csi-crashloop/README.md) |
| NFS server unreachable / DNS | Fix network/DNS or use NFS server IP in `proxy_endpoint` |

## Full guide

[README.md](./README.md) — Investigation workflow, causes, and escalation.

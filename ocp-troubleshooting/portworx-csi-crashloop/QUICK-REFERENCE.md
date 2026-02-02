# Quick Reference - Portworx CSI CrashLoopBackOff

Fast command reference for troubleshooting `px-csi-ext` pod issues.

---

## Essential Commands

### Get Pod Name

```bash
# Get CSI pod name
PX_CSI_POD=$(oc get pods -n kube-system -l app=px-csi-driver -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep 'px-csi-ext-' | grep -v node | head -1)
echo $PX_CSI_POD

# Get all CSI pods
oc get pods -n kube-system -l app=px-csi-driver
```

### Check Status

```bash
# Pod status
oc get pod -n kube-system $PX_CSI_POD

# Detailed description
oc describe pod -n kube-system $PX_CSI_POD

# Node where scheduled
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}'
```

### Check Logs

```bash
# Current logs
oc logs -n kube-system $PX_CSI_POD --tail=100

# Previous crash logs
oc logs -n kube-system $PX_CSI_POD --previous --tail=100

# All containers
oc logs -n kube-system $PX_CSI_POD --all-containers=true

# Follow logs
oc logs -n kube-system $PX_CSI_POD -f

# Search for errors
oc logs -n kube-system $PX_CSI_POD --previous | grep -i "error\|failed\|fatal\|panic"
```

### Check Events

```bash
# Events for this pod
oc get events -n kube-system --field-selector involvedObject.name=$PX_CSI_POD --sort-by='.lastTimestamp'

# All Portworx events
oc get events -n kube-system --sort-by='.lastTimestamp' | grep -i portworx | tail -30

# Recent namespace events
oc get events -n kube-system --sort-by='.lastTimestamp' | tail -50
```

---

## Portworx Cluster Health

### Status Check

```bash
# Get Portworx pod
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')

# Check status
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status

# Cluster list
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl cluster list

# Node list
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl cluster provision-status

# Service status
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl service list
```

### All Portworx Pods

```bash
# List all Portworx pods
oc get pods -n kube-system -l name=portworx -o wide

# Check for restarts
oc get pods -n kube-system -l name=portworx -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}'

# Portworx operator
oc get pods -n kube-system | grep portworx-operator
```

---

## CSI Driver Registration

### Check CSI Driver

```bash
# List CSI drivers
oc get csidriver

# Check Portworx CSI driver
oc get csidriver pxd.portworx.com

# Describe CSI driver
oc describe csidriver pxd.portworx.com

# Check CSI nodes
oc get csinode

# Describe CSI node
oc describe csinode $(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}')
```

---

## RBAC and Permissions

### Service Account

```bash
# Check service account
oc get sa -n kube-system px-account

# Describe service account
oc describe sa -n kube-system px-account

# Check secrets
oc get secrets -n kube-system | grep px-account
```

### Cluster Role Bindings

```bash
# List Portworx cluster role bindings
oc get clusterrolebinding | grep portworx

# Check specific permissions
oc auth can-i --as=system:serviceaccount:kube-system:px-account create persistentvolumes
oc auth can-i --as=system:serviceaccount:kube-system:px-account get csidrivers
oc auth can-i --as=system:serviceaccount:kube-system:px-account list nodes
```

### SecurityContextConstraints (OpenShift)

```bash
# List Portworx SCCs
oc get scc | grep portworx

# Describe Portworx SCC
oc describe scc portworx-scc

# Who can use the SCC
oc adm policy who-can use scc portworx-scc -n kube-system
```

---

## Node and Scheduling

### Node Information

```bash
# Get node where CSI pod is scheduled
CSI_NODE=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}')
echo "CSI pod on node: $CSI_NODE"

# Node details
oc describe node $CSI_NODE

# Node labels
oc get node $CSI_NODE --show-labels

# Portworx pods on this node
oc get pods -n kube-system -l name=portworx -o wide | grep $CSI_NODE
```

### Scheduling Details

```bash
# Check node selector
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeSelector}'

# Check affinity rules
oc get pod -n kube-system $PX_CSI_POD -o yaml | grep -A 20 "affinity:"

# Check tolerations
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.tolerations}' | jq .
```

---

## Volume and Socket

### Debug Node (Check Socket)

```bash
# Start debug pod on the node
oc debug node/$CSI_NODE

# In the debug pod, check socket
chroot /host
ls -la /var/lib/kubelet/plugins/pxd.portworx.com/
ls -la /var/lib/kubelet/plugins_registry/
exit
```

### Volume Mounts

```bash
# Check volume mounts
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.volumes}' | jq .

# Check container mounts
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.containers[*].volumeMounts}' | jq .
```

---

## Resource Usage

### Resources

```bash
# Check resource requests/limits
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.containers[*].resources}' | jq .

# Node capacity
oc describe node $CSI_NODE | grep -A 15 "Allocated resources:"

# Check if OOMKilled
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.status.containerStatuses[*].lastState.terminated.reason}'
```

---

## Quick Fixes

### Restart CSI Pod

```bash
# Simple restart
oc delete pod -n kube-system $PX_CSI_POD

# Watch recovery
oc get pod -n kube-system $PX_CSI_POD -w
```

### Restart All CSI Pods

```bash
# Restart all CSI driver pods
oc delete pod -n kube-system -l app=px-csi-driver

# Watch
oc get pods -n kube-system -l app=px-csi-driver -w
```

### Restart Portworx Pod on Same Node

```bash
# Find Portworx pod on same node as CSI
CSI_NODE=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}')
PX_NODE_POD=$(oc get pods -n kube-system -l name=portworx -o wide | grep $CSI_NODE | awk '{print $1}')

# Restart it
oc delete pod -n kube-system $PX_NODE_POD

# Wait for ready
oc wait --for=condition=Ready pod $PX_NODE_POD -n kube-system --timeout=300s
```

### Restart Operator

```bash
# Restart Portworx operator
oc delete pod -n kube-system -l name=portworx-operator

# Watch recovery
oc get pods -n kube-system -l name=portworx-operator -w
```

### Force Rollout Restart

```bash
# Restart entire DaemonSet
oc rollout restart daemonset/px-csi-ext -n kube-system

# Check status
oc rollout status daemonset/px-csi-ext -n kube-system
```

---

## Testing

### Test PVC Creation

```bash
# Create test PVC
cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc-portworx
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: portworx-sc
EOF

# Watch PVC
oc get pvc test-pvc-portworx -w

# Check PVC events
oc describe pvc test-pvc-portworx

# Clean up
oc delete pvc test-pvc-portworx
```

### Test Pod with PVC

```bash
# Create test pod
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-portworx
  namespace: default
spec:
  containers:
  - name: test
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: test-volume
      mountPath: /data
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: test-pvc-portworx
EOF

# Watch pod
oc get pod test-pod-portworx -w

# Check if volume mounted
oc exec test-pod-portworx -- df -h /data

# Clean up
oc delete pod test-pod-portworx
oc delete pvc test-pvc-portworx
```

---

## Diagnostics Collection

### Must-Gather

```bash
# Portworx must-gather
oc adm must-gather --image=registry.connect.redhat.com/portworx/must-gather:latest

# Standard must-gather
oc adm must-gather

# Inspect specific namespace
oc adm inspect ns/kube-system
```

### Manual Diagnostics

```bash
# Create diagnostic output file
DIAG_FILE="px-csi-diagnostics-$(date +%Y%m%d-%H%M%S).txt"

{
  echo "=== Date ==="
  date
  echo ""
  
  echo "=== CSI Pod Status ==="
  oc get pods -n kube-system -l app=px-csi-driver
  echo ""
  
  echo "=== CSI Pod Details ==="
  oc describe pod -n kube-system $PX_CSI_POD
  echo ""
  
  echo "=== CSI Pod Logs ==="
  oc logs -n kube-system $PX_CSI_POD --tail=200
  echo ""
  
  echo "=== CSI Pod Previous Logs ==="
  oc logs -n kube-system $PX_CSI_POD --previous --tail=200
  echo ""
  
  echo "=== Portworx Pods ==="
  oc get pods -n kube-system -l name=portworx -o wide
  echo ""
  
  echo "=== Portworx Status ==="
  PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
  oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status
  echo ""
  
  echo "=== CSI Driver ==="
  oc get csidriver pxd.portworx.com -o yaml
  echo ""
  
  echo "=== Recent Events ==="
  oc get events -n kube-system --sort-by='.lastTimestamp' | tail -50
  echo ""
  
  echo "=== Storage Classes ==="
  oc get sc | grep portworx
  echo ""
  
} > $DIAG_FILE

echo "Diagnostics saved to: $DIAG_FILE"
```

---

## Decision Tree

```
Is px-csi-ext pod CrashLoopBackOff?
│
├─ YES → Check logs: oc logs -n kube-system $PX_CSI_POD --previous
│        │
│        ├─ "failed to connect to socket" → Check Portworx pod health
│        │                                  → Restart Portworx pod, then CSI pod
│        │
│        ├─ "CSI driver not found" → Check: oc get csidriver pxd.portworx.com
│        │                          → Restart operator or create CSI driver
│        │
│        ├─ "Unauthorized" / "forbidden" → Check RBAC
│        │                                → Verify service account and bindings
│        │
│        ├─ "ImagePullBackOff" → Check image pull secrets
│        │                      → Fix registry access
│        │
│        └─ "FailedScheduling" → Check node selector/affinity
│                                → Verify node labels
│
└─ NO → Check if pod is running but unhealthy
        → Check Portworx cluster health
        → Test PVC creation
```

---

## Common Error Messages

| Error Message | Quick Fix |
|--------------|-----------|
| `failed to connect to /var/lib/kubelet/plugins/pxd.portworx.com/csi.sock` | Restart Portworx pod, then CSI pod |
| `csidrivers.storage.k8s.io "pxd.portworx.com" not found` | Restart operator or create CSI driver |
| `User "system:serviceaccount:kube-system:px-account" cannot` | Fix RBAC bindings |
| `ImagePullBackOff` | Add image pull secrets |
| `0/X nodes are available` | Fix node labels or affinity rules |
| `OOMKilled` | Increase memory limits |

---

## Emergency Contacts

```bash
# Quick status check
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status

# If Portworx cluster is healthy → CSI issue (restart CSI)
# If Portworx cluster is unhealthy → Fix Portworx first
```

**Priority**: Always fix Portworx cluster health BEFORE attempting to fix CSI issues.

---

## Related Documentation

- [README.md](./README.md) - Complete troubleshooting guide
- [QUICKSTART.md](./QUICKSTART.md) - Fast fixes
- [COMMON-ERRORS.md](./COMMON-ERRORS.md) - Error lookup table
- [INVESTIGATION-WORKFLOW.md](./INVESTIGATION-WORKFLOW.md) - Systematic process


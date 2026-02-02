# Portworx CSI Pod CrashLoopBackOff Troubleshooting Guide

## Overview

The `px-csi-ext` pod is part of the Portworx CSI (Container Storage Interface) driver deployment. When this pod crashes repeatedly, it prevents:

- New PVC provisioning using Portworx storage classes
- Volume expansion operations
- Volume snapshot operations
- Pod attachment to existing Portworx volumes (in some cases)

This guide provides systematic troubleshooting for the `px-csi-ext` pod CrashLoopBackOff issue.

## Quick Links

- **[QUICKSTART.md](./QUICKSTART.md)** - Fast fixes for common issues (⚡ START HERE)
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Command cheat sheet
- **[COMMON-ERRORS.md](./COMMON-ERRORS.md)** - Error message lookup table
- **[INVESTIGATION-WORKFLOW.md](./INVESTIGATION-WORKFLOW.md)** - Systematic troubleshooting process

---

## Architecture Context

### Portworx CSI Components

```
┌─────────────────────────────────────────────────────────┐
│                    OpenShift Cluster                     │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │  CSI Controller Pod (px-csi-ext)                 │   │
│  │  - Provisioning                                  │   │
│  │  - Deletion                                      │   │
│  │  - Volume Expansion                              │   │
│  │  - Snapshots                                     │   │
│  └──────────────────┬───────────────────────────────┘   │
│                     │                                     │
│                     ▼ (Unix Socket)                       │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Portworx Node Pods (DaemonSet)                  │   │
│  │  - Storage backend                               │   │
│  │  - CSI node plugin                               │   │
│  │  - Socket: /var/lib/kubelet/plugins/pxd.*.sock  │   │
│  └──────────────────────────────────────────────────┘   │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

### Key Dependencies

The `px-csi-ext` pod depends on:

1. **Portworx cluster health** - Main Portworx pods must be running and healthy
2. **Unix socket communication** - Socket at `/var/lib/kubelet/plugins/pxd.portworx.com/csi.sock`
3. **RBAC permissions** - Service account `px-account` with proper cluster role bindings
4. **CSI driver registration** - `CSIDriver` object must exist in the cluster
5. **Network connectivity** - Communication with kube-apiserver
6. **Node scheduling** - Must be able to schedule on nodes running Portworx

---

## Quick Diagnosis

### Step 1: Check Pod Status

```bash
# Get the CSI pod name
oc get pods -n kube-system -l app=px-csi-driver

# Expected output shows multiple pods:
# px-csi-ext-xxxxxxxxxx        5/5     Running            0          5d
# px-csi-ext-node-xxxxx        2/2     Running            0          5d
# ...

# Check specific pod details
PX_CSI_POD=$(oc get pods -n kube-system -l app=px-csi-driver -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep 'px-csi-ext-' | grep -v node | head -1)
oc describe pod -n kube-system $PX_CSI_POD
```

### Step 2: Extract Error Messages

```bash
# Current logs
oc logs -n kube-system $PX_CSI_POD --tail=100

# Previous crash logs (most important!)
oc logs -n kube-system $PX_CSI_POD --previous --tail=100

# All containers if pod has multiple
oc logs -n kube-system $PX_CSI_POD --all-containers=true --tail=50

# Check for specific error patterns
oc logs -n kube-system $PX_CSI_POD --previous | grep -i "error\|failed\|fatal\|panic"
```

### Step 3: Check Portworx Cluster Health

```bash
# List all Portworx pods
oc get pods -n kube-system -l name=portworx

# Check Portworx cluster status (critical!)
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status

# Expected healthy output:
# Status: PX is operational
# Cluster Summary:
#   Cluster ID: <cluster-id>
#   Cluster UUID: <uuid>
#   Scheduler: kubernetes
#   Nodes: X node(s) with storage (X online)
```

### Step 4: Check Events

```bash
# Recent events for the CSI pod
oc get events -n kube-system --field-selector involvedObject.name=$PX_CSI_POD --sort-by='.lastTimestamp'

# All Portworx-related events
oc get events -n kube-system --sort-by='.lastTimestamp' | grep -i portworx | tail -30
```

---

## Common Root Causes

### 1. Unix Socket Connection Failure

**Symptoms:**
```
Error: failed to connect to /var/lib/kubelet/plugins/pxd.portworx.com/csi.sock
Error: rpc error: code = Unavailable desc = connection error
```

**Diagnosis:**

```bash
# Check if socket exists on the node where CSI pod is scheduled
CSI_NODE=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}')
echo "CSI pod scheduled on node: $CSI_NODE"

# Check Portworx pods on that node
oc get pods -n kube-system -l name=portworx -o wide | grep $CSI_NODE

# Debug node access (if you have SSH)
oc debug node/$CSI_NODE
# Then on the debug pod:
chroot /host
ls -la /var/lib/kubelet/plugins/pxd.portworx.com/
```

**Resolution:**

**Option A: Restart CSI Pod** (if Portworx cluster is healthy)
```bash
# Check Portworx health first
oc exec -n kube-system $(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}') -- /opt/pwx/bin/pxctl status

# If healthy, restart CSI pod
oc delete pod -n kube-system $PX_CSI_POD

# Watch recovery
oc get pod -n kube-system $PX_CSI_POD -w
```

**Option B: Restart Portworx Pod** (if main Portworx pod is unhealthy)
```bash
# Find unhealthy Portworx pod on the same node
PX_NODE_POD=$(oc get pods -n kube-system -l name=portworx -o wide | grep $CSI_NODE | awk '{print $1}')

# Restart it
oc delete pod -n kube-system $PX_NODE_POD

# Wait for it to come back
oc get pod -n kube-system $PX_NODE_POD -w

# Then restart CSI pod
oc delete pod -n kube-system $PX_CSI_POD
```

---

### 2. CSI Driver Not Registered

**Symptoms:**
```
Error: failed to get CSIDriver: csidrivers.storage.k8s.io "pxd.portworx.com" not found
Error: CSI driver registration failed
```

**Diagnosis:**

```bash
# Check if CSI driver exists
oc get csidriver pxd.portworx.com

# Check CSI node objects
oc get csinode

# Check if Portworx operator is running
oc get pods -n kube-system | grep portworx-operator
```

**Resolution:**

**Option A: Wait for Operator to Register** (if operator is running)
```bash
# Operator might be in the process of registering
oc logs -n kube-system -l name=portworx-operator --tail=50

# Give it 2-3 minutes, then check again
oc get csidriver pxd.portworx.com
```

**Option B: Restart Operator** (if CSI driver still missing)
```bash
# Restart the operator
oc delete pod -n kube-system -l name=portworx-operator

# Wait for operator to be ready
oc wait --for=condition=Ready pod -l name=portworx-operator -n kube-system --timeout=300s

# Verify CSI driver appears
oc get csidriver pxd.portworx.com
```

**Option C: Manual CSI Driver Creation** (last resort)
```bash
# Create CSI driver object if it doesn't exist
cat <<EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: CSIDriver
metadata:
  name: pxd.portworx.com
spec:
  attachRequired: true
  podInfoOnMount: true
  volumeLifecycleModes:
  - Persistent
  - Ephemeral
EOF
```

---

### 3. RBAC / Service Account Issues

**Symptoms:**
```
Error: Unauthorized
Error: forbidden: User "system:serviceaccount:kube-system:px-account" cannot ...
Error: unable to authenticate
```

**Diagnosis:**

```bash
# Check service account exists
oc get sa -n kube-system px-account

# Check associated secrets
oc describe sa -n kube-system px-account

# Check cluster role binding
oc get clusterrolebinding | grep portworx

# Verify permissions
oc adm policy who-can create persistentvolumes
oc adm policy who-can get csidrivers
```

**Resolution:**

**Option A: Verify and Recreate ClusterRoleBindings**
```bash
# Get the current cluster role bindings for Portworx
oc get clusterrolebinding -o yaml | grep -A 20 portworx

# If missing, check Portworx installation YAML
# You may need to reapply the Portworx operator installation

# Restart CSI pod after fixing RBAC
oc delete pod -n kube-system $PX_CSI_POD
```

**Option B: Check SecurityContextConstraints (OpenShift-specific)**
```bash
# Check if SCC is assigned
oc get scc | grep portworx

# Verify px-account can use the SCC
oc adm policy who-can use scc portworx-scc -n kube-system

# If not assigned, add it
oc adm policy add-scc-to-user portworx-scc system:serviceaccount:kube-system:px-account
```

---

### 4. Container Image Pull Issues

**Symptoms:**
```
Error: ImagePullBackOff
Error: ErrImagePull
Warning  Failed     Pod    Failed to pull image ...
```

**Diagnosis:**

```bash
# Check image pull status
oc describe pod -n kube-system $PX_CSI_POD | grep -A 10 "Image:"

# Check for image pull errors
oc get events -n kube-system | grep -i "image\|pull"

# Verify image exists and is accessible
IMAGE=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.containers[0].image}')
echo "CSI Image: $IMAGE"

# Check if image pull secrets are needed
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.imagePullSecrets}'
```

**Resolution:**

**Option A: Fix Image Pull Secret** (if using private registry)
```bash
# Check if px-account has image pull secrets
oc describe sa -n kube-system px-account | grep "Image pull secrets"

# If missing, create and attach
oc create secret docker-registry px-registry-secret \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password> \
  -n kube-system

# Add to service account
oc patch sa px-account -n kube-system -p '{"imagePullSecrets": [{"name": "px-registry-secret"}]}'

# Restart pod
oc delete pod -n kube-system $PX_CSI_POD
```

**Option B: Fix Registry Access** (if using disconnected/airgap)
```bash
# Verify image is mirrored to internal registry
oc get imagestreams -n openshift

# If using imageContentSourcePolicy, verify it's configured
oc get imagecontentsourcepolicy

# Check if nodes can pull from the configured registry
```

---

### 5. Node Scheduling / Affinity Issues

**Symptoms:**
```
Warning  FailedScheduling  Pod  0/X nodes are available: ...
Error: pod affinity/anti-affinity rules not satisfied
```

**Diagnosis:**

```bash
# Check scheduling details
oc describe pod -n kube-system $PX_CSI_POD | grep -A 20 "Events:"

# Check node selectors and affinity rules
oc get pod -n kube-system $PX_CSI_POD -o yaml | grep -A 10 "nodeSelector\|affinity"

# Check which nodes have Portworx
oc get pods -n kube-system -l name=portworx -o wide

# Verify node labels match requirements
oc get nodes --show-labels | grep -i portworx
```

**Resolution:**

**Option A: Fix Node Labels** (if required labels are missing)
```bash
# Check what labels the CSI pod requires
NODE_SELECTOR=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeSelector}')
echo "Required node selector: $NODE_SELECTOR"

# Add missing labels to nodes running Portworx
oc label node <node-name> <key>=<value>

# Example:
oc label node worker-1 px/enabled=true
```

**Option B: Fix Deployment Affinity** (if affinity rules are too restrictive)
```bash
# This requires editing the deployment/daemonset
# First, identify what created the CSI pod
CONTROLLER=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.metadata.ownerReferences[0].name}')
CONTROLLER_KIND=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.metadata.ownerReferences[0].kind}')

echo "Controlled by: $CONTROLLER_KIND/$CONTROLLER"

# Edit the controller (be careful!)
oc edit $CONTROLLER_KIND/$CONTROLLER -n kube-system

# Look for nodeSelector or affinity sections and adjust as needed
```

---

### 6. Resource Constraints (CPU/Memory)

**Symptoms:**
```
Warning  FailedScheduling  Pod  Insufficient cpu
Warning  FailedScheduling  Pod  Insufficient memory
Status: OOMKilled
```

**Diagnosis:**

```bash
# Check resource requests and limits
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.containers[*].resources}' | jq .

# Check node capacity
oc describe node $(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}') | grep -A 10 "Allocated resources:"

# Check if pod was OOMKilled
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.status.containerStatuses[*].lastState.terminated.reason}'
```

**Resolution:**

**Option A: Free Up Node Resources**
```bash
# Find pods that can be evicted or scaled down
oc get pods --all-namespaces -o wide | grep $(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}')

# Scale down non-critical workloads temporarily
oc scale deployment <deployment-name> -n <namespace> --replicas=0
```

**Option B: Adjust Resource Limits** (if they're too low)
```bash
# Get the deployment/daemonset
CONTROLLER=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.metadata.ownerReferences[0].name}')
CONTROLLER_KIND=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.metadata.ownerReferences[0].kind}')

# Edit resource limits
oc edit $CONTROLLER_KIND/$CONTROLLER -n kube-system

# Adjust resources section (example):
# resources:
#   limits:
#     cpu: 500m
#     memory: 512Mi
#   requests:
#     cpu: 200m
#     memory: 256Mi
```

---

### 7. Volume Mount Issues

**Symptoms:**
```
Error: Unable to attach or mount volumes
Error: MountVolume.SetUp failed
Warning  FailedMount  Pod  ...
```

**Diagnosis:**

```bash
# Check volume mounts for the CSI pod
oc describe pod -n kube-system $PX_CSI_POD | grep -A 30 "Mounts:"

# Check if host paths exist
oc debug node/$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}')
# In debug pod:
chroot /host
ls -la /var/lib/kubelet/plugins/
ls -la /var/lib/kubelet/plugins_registry/
```

**Resolution:**

```bash
# Usually requires Portworx node pods to be healthy first
# Restart Portworx pod on the same node
PX_NODE_POD=$(oc get pods -n kube-system -l name=portworx -o wide | grep $(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}') | awk '{print $1}')

oc delete pod -n kube-system $PX_NODE_POD

# Wait for Portworx pod to be ready
oc wait --for=condition=Ready pod $PX_NODE_POD -n kube-system --timeout=300s

# Then restart CSI pod
oc delete pod -n kube-system $PX_CSI_POD
```

---

## Emergency Recovery Procedures

### Critical: PVC Provisioning Completely Broken

If your cluster can't provision any new PVCs:

```bash
# 1. Verify Portworx cluster health (THIS IS CRITICAL)
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status

# If Portworx cluster shows issues, FIX THAT FIRST before CSI

# 2. If Portworx cluster is healthy, force restart CSI
oc delete pod -n kube-system --selector=app=px-csi-driver

# 3. Wait for all CSI pods to recover
oc get pods -n kube-system -l app=px-csi-driver -w

# 4. Test PVC provisioning
cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: emergency-test-pvc
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: portworx-sc
EOF

# 5. Monitor PVC
oc get pvc emergency-test-pvc -w

# 6. Clean up
oc delete pvc emergency-test-pvc
```

### Nuclear Option: Reinstall CSI Driver

⚠️ **WARNING**: Only do this if all other options have failed and you have a backup plan.

```bash
# 1. Collect diagnostics first
oc adm must-gather --image=registry.connect.redhat.com/portworx/must-gather:latest

# 2. Delete CSI driver deployment
oc delete deployment px-csi-ext -n kube-system
oc delete daemonset px-csi-ext-node -n kube-system

# 3. Wait for operator to recreate (if using operator)
# This can take 5-10 minutes
oc get pods -n kube-system -l app=px-csi-driver -w

# If operator doesn't recreate, you may need to reinstall Portworx
# Follow Portworx installation documentation
```

---

## Prevention

### Monitoring

Set up monitoring for CSI health:

```bash
# Create a simple monitoring script
cat > /usr/local/bin/check-px-csi.sh <<'EOF'
#!/bin/bash
NAMESPACE="kube-system"
CSI_PODS=$(kubectl get pods -n $NAMESPACE -l app=px-csi-driver --no-headers)

echo "=== Portworx CSI Pod Status ==="
echo "$CSI_PODS"

if echo "$CSI_PODS" | grep -q "CrashLoopBackOff\|Error\|ImagePullBackOff"; then
  echo "ERROR: CSI pods are unhealthy!"
  exit 1
fi

echo "All CSI pods are healthy"
exit 0
EOF

chmod +x /usr/local/bin/check-px-csi.sh
```

### Alerting

Create a Prometheus alert (if using OpenShift monitoring):

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: portworx-csi-alerts
  namespace: openshift-monitoring
spec:
  groups:
  - name: portworx-csi
    interval: 30s
    rules:
    - alert: PortworxCSIPodCrashLooping
      annotations:
        description: 'Portworx CSI pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is crash looping'
        summary: 'Portworx CSI pod is in CrashLoopBackOff'
      expr: |
        rate(kube_pod_container_status_restarts_total{namespace="kube-system",pod=~"px-csi-ext.*"}[15m]) > 0
      for: 5m
      labels:
        severity: critical
```

### Best Practices

1. **Always check Portworx cluster health first** - CSI is just a layer on top
2. **Monitor restarts** - CSI pods shouldn't restart frequently
3. **Keep versions aligned** - Portworx and CSI versions should be compatible
4. **Test after upgrades** - Always test PVC provisioning after cluster upgrades
5. **Document custom configurations** - Node selectors, taints, tolerations, etc.

---

## Additional Resources

### Documentation

- [Portworx on OpenShift](https://docs.portworx.com/portworx-enterprise/install-portworx/openshift)
- [Portworx Troubleshooting Guide](https://docs.portworx.com/portworx-enterprise/operations/operate-kubernetes/troubleshooting)
- [Kubernetes CSI Documentation](https://kubernetes-csi.github.io/docs/)
- [OpenShift Storage Documentation](https://docs.openshift.com/container-platform/latest/storage/index.html)

### Support

- **Red Hat Support**: https://access.redhat.com/support/cases/
- **Portworx Support**: https://support.purestorage.com/

### Must-Gather

Collect comprehensive diagnostics:

```bash
# Portworx-specific must-gather
oc adm must-gather --image=registry.connect.redhat.com/portworx/must-gather:latest

# Standard OpenShift must-gather
oc adm must-gather
```

---

## Related Issues

This guide is focused on `px-csi-ext` pod issues. For other Portworx issues, see:

- Portworx node pods crash looping
- Portworx cluster not forming (quorum issues)
- Volume attachment failures
- Performance issues
- License problems

Each requires separate troubleshooting approaches.


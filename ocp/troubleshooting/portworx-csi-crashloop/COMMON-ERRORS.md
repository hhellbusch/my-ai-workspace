# Common Error Messages - Portworx CSI CrashLoopBackOff

Quick lookup table for error messages and their solutions.

---

## Socket Connection Errors

### Error: Failed to connect to CSI socket

```
Error: failed to connect to /var/lib/kubelet/plugins/pxd.portworx.com/csi.sock
Error: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing dial unix /var/lib/kubelet/plugins/pxd.portworx.com/csi.sock: connect: no such file or directory"
```

**Root Cause**: Portworx node pod not running or socket not created

**Quick Fix**:
```bash
# Check Portworx pod on same node
CSI_NODE=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}')
oc get pods -n kube-system -l name=portworx -o wide | grep $CSI_NODE

# Restart Portworx pod
PX_NODE_POD=$(oc get pods -n kube-system -l name=portworx -o wide | grep $CSI_NODE | awk '{print $1}')
oc delete pod -n kube-system $PX_NODE_POD

# Wait and restart CSI
oc wait --for=condition=Ready pod $PX_NODE_POD -n kube-system --timeout=300s
oc delete pod -n kube-system $PX_CSI_POD
```

**Documentation**: [README.md#1-unix-socket-connection-failure](./README.md#1-unix-socket-connection-failure)

---

## CSI Driver Registration Errors

### Error: CSI driver not found

```
Error: failed to get CSIDriver: csidrivers.storage.k8s.io "pxd.portworx.com" not found
Error: CSI driver pxd.portworx.com not registered
```

**Root Cause**: CSIDriver object not created or deleted

**Quick Fix**:
```bash
# Check if CSI driver exists
oc get csidriver pxd.portworx.com

# If not found, restart operator
oc delete pod -n kube-system -l name=portworx-operator

# Wait 2-3 minutes and check again
oc get csidriver pxd.portworx.com

# If still missing, create manually
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

**Documentation**: [README.md#2-csi-driver-not-registered](./README.md#2-csi-driver-not-registered)

---

## RBAC / Permission Errors

### Error: Unauthorized

```
Error: Unauthorized
Error: the server doesn't have a resource type "csidrivers"
```

**Root Cause**: Service account lacks proper permissions

**Quick Fix**:
```bash
# Verify service account exists
oc get sa -n kube-system px-account

# Check permissions
oc auth can-i --as=system:serviceaccount:kube-system:px-account create persistentvolumes
oc auth can-i --as=system:serviceaccount:kube-system:px-account get csidrivers

# Check cluster role bindings
oc get clusterrolebinding | grep portworx

# If missing, you may need to reapply Portworx installation
```

**Documentation**: [README.md#3-rbac--service-account-issues](./README.md#3-rbac--service-account-issues)

---

### Error: Forbidden

```
Error: forbidden: User "system:serviceaccount:kube-system:px-account" cannot create resource "csinodes" in API group "storage.k8s.io" at the cluster scope
Error: forbidden: User "system:serviceaccount:kube-system:px-account" cannot list resource "nodes" in API group "" at the cluster scope
```

**Root Cause**: Missing or incorrect ClusterRoleBinding

**Quick Fix**:
```bash
# Check existing cluster role bindings
oc get clusterrolebinding -o yaml | grep -A 30 portworx

# Verify the px-account has proper bindings
oc describe clusterrolebinding portworx-cluster-role-binding

# If missing, check Portworx operator logs
oc logs -n kube-system -l name=portworx-operator --tail=100
```

**Documentation**: [README.md#3-rbac--service-account-issues](./README.md#3-rbac--service-account-issues)

---

### Error: SecurityContextConstraints

```
Error: unable to validate against any security context constraint
Warning  FailedCreate  Unable to create pods: pods "px-csi-ext-" is forbidden: unable to validate against any security context constraint
```

**Root Cause**: OpenShift SCC not assigned to service account

**Quick Fix**:
```bash
# Check SCC assignment
oc adm policy who-can use scc portworx-scc -n kube-system

# Add SCC to service account
oc adm policy add-scc-to-user portworx-scc system:serviceaccount:kube-system:px-account

# Restart CSI pod
oc delete pod -n kube-system $PX_CSI_POD
```

**Documentation**: [README.md#3-rbac--service-account-issues](./README.md#3-rbac--service-account-issues)

---

## Image Pull Errors

### Error: ImagePullBackOff

```
Warning  Failed     Pod    Failed to pull image "docker.io/portworx/px-enterprise:...": rpc error: code = Unknown desc = Error reading manifest
Error: ErrImagePull
Status: ImagePullBackOff
```

**Root Cause**: Cannot pull CSI driver container image

**Quick Fix**:
```bash
# Check image
IMAGE=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.containers[0].image}')
echo "Image: $IMAGE"

# Check for image pull secrets
oc describe sa -n kube-system px-account | grep "Image pull secrets"

# If using private registry, create secret
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

**Documentation**: [README.md#4-container-image-pull-issues](./README.md#4-container-image-pull-issues)

---

## Scheduling Errors

### Error: Node affinity/selector

```
Warning  FailedScheduling  Pod  0/6 nodes are available: 6 node(s) didn't match Pod's node affinity/selector
```

**Root Cause**: Node labels don't match pod's nodeSelector or affinity rules

**Quick Fix**:
```bash
# Check node selector
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeSelector}'

# Check which nodes have Portworx
oc get pods -n kube-system -l name=portworx -o wide

# Check node labels
oc get nodes --show-labels | grep -i portworx

# Add missing label if needed
oc label node <node-name> px/enabled=true
```

**Documentation**: [README.md#5-node-scheduling--affinity-issues](./README.md#5-node-scheduling--affinity-issues)

---

### Error: Insufficient resources

```
Warning  FailedScheduling  Pod  0/6 nodes are available: 3 Insufficient cpu, 3 Insufficient memory
```

**Root Cause**: Not enough CPU or memory on nodes

**Quick Fix**:
```bash
# Check resource requests
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.containers[*].resources}' | jq .

# Check node capacity
oc describe node $(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}') | grep -A 10 "Allocated resources:"

# Scale down non-critical workloads or add capacity
```

**Documentation**: [README.md#6-resource-constraints-cpumemory](./README.md#6-resource-constraints-cpumemory)

---

### Error: Taints

```
Warning  FailedScheduling  Pod  0/6 nodes are available: 6 node(s) had taint {key: value}, that the pod didn't tolerate
```

**Root Cause**: Nodes have taints that CSI pod doesn't tolerate

**Quick Fix**:
```bash
# Check node taints
oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints}{"\n"}{end}'

# Check pod tolerations
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.tolerations}' | jq .

# Either remove taints or add tolerations to deployment
# To edit deployment:
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.metadata.ownerReferences[0].name}'
# Then edit that resource to add tolerations
```

**Documentation**: [README.md#5-node-scheduling--affinity-issues](./README.md#5-node-scheduling--affinity-issues)

---

## Volume Mount Errors

### Error: Unable to mount volumes

```
Warning  FailedMount  Pod  Unable to attach or mount volumes: unmounted volumes=[socket-dir]
Warning  FailedMount  Pod  MountVolume.SetUp failed for volume "socket-dir" : hostPath type check failed: /var/lib/kubelet/plugins/pxd.portworx.com is not a directory
```

**Root Cause**: Host path doesn't exist or Portworx not running

**Quick Fix**:
```bash
# Ensure Portworx pod is running on same node
CSI_NODE=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}')
oc get pods -n kube-system -l name=portworx -o wide | grep $CSI_NODE

# Restart Portworx pod first
PX_NODE_POD=$(oc get pods -n kube-system -l name=portworx -o wide | grep $CSI_NODE | awk '{print $1}')
oc delete pod -n kube-system $PX_NODE_POD

# Wait for ready, then restart CSI
oc wait --for=condition=Ready pod $PX_NODE_POD -n kube-system --timeout=300s
oc delete pod -n kube-system $PX_CSI_POD
```

**Documentation**: [README.md#7-volume-mount-issues](./README.md#7-volume-mount-issues)

---

## Resource Limit Errors

### Error: OOMKilled

```
State:          Terminated
  Reason:       OOMKilled
  Exit Code:    137
```

**Root Cause**: Container exceeded memory limit

**Quick Fix**:
```bash
# Check current limits
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.containers[*].resources}' | jq .

# Get controller
CONTROLLER=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.metadata.ownerReferences[0].name}')
CONTROLLER_KIND=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.metadata.ownerReferences[0].kind}')

# Edit to increase memory limits
oc edit $CONTROLLER_KIND/$CONTROLLER -n kube-system

# Find resources section and increase limits:
# resources:
#   limits:
#     memory: 1Gi  # Increase this
```

**Documentation**: [README.md#6-resource-constraints-cpumemory](./README.md#6-resource-constraints-cpumemory)

---

### Error: CrashLoopBackOff with Exit Code 1

```
State:          Waiting
  Reason:       CrashLoopBackOff
Last State:     Terminated
  Reason:       Error
  Exit Code:    1
```

**Root Cause**: Various - check logs for specific error

**Quick Fix**:
```bash
# ALWAYS check previous logs for crash cause
oc logs -n kube-system $PX_CSI_POD --previous --tail=100

# Look for the actual error message at the end
oc logs -n kube-system $PX_CSI_POD --previous | tail -20

# Then reference this guide for that specific error
```

**Documentation**: [README.md#quick-diagnosis](./README.md#quick-diagnosis)

---

## Portworx Cluster Errors

### Error: Portworx cluster not operational

```
Error: failed to initialize driver: PX cluster is not operational
```

**Root Cause**: Portworx backend cluster is unhealthy

**Quick Fix**:
```bash
# Check Portworx cluster status (MOST IMPORTANT)
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status

# Expected: "Status: PX is operational"
# If not operational, FIX PORTWORX FIRST before addressing CSI

# Check for quorum issues
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl cluster list

# CSI will not work until Portworx cluster is healthy
```

**Note**: This is a Portworx cluster issue, not a CSI issue. Fix the Portworx cluster before troubleshooting CSI.

---

### Error: Unable to get storage node list

```
Error: rpc error: code = Unavailable desc = error getting storage node list
Error: failed to enumerate nodes
```

**Root Cause**: Cannot communicate with Portworx cluster

**Quick Fix**:
```bash
# Verify Portworx pods are running
oc get pods -n kube-system -l name=portworx

# Check Portworx service
oc get svc -n kube-system | grep portworx

# Verify Portworx cluster health
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status

# If cluster is healthy, restart CSI
oc delete pod -n kube-system $PX_CSI_POD
```

---

## API Server Connection Errors

### Error: Unable to connect to API server

```
Error: dial tcp <ip>:6443: connect: connection refused
Error: Unable to connect to the server: dial tcp <ip>:6443: i/o timeout
```

**Root Cause**: Network connectivity to kube-apiserver

**Quick Fix**:
```bash
# Check node network connectivity
CSI_NODE=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}')

# Check if API server is accessible from the node
oc debug node/$CSI_NODE
# In debug pod:
chroot /host
curl -k https://api.cluster.example.com:6443/healthz

# Check kube-apiserver pods
oc get pods -n openshift-kube-apiserver

# This might be a cluster-wide issue, not just CSI
```

**Note**: This typically indicates broader cluster networking issues.

---

## Version Compatibility Errors

### Error: Unsupported CSI spec version

```
Error: unsupported CSI spec version
Error: CSI driver version mismatch
```

**Root Cause**: Version incompatibility between CSI driver and Kubernetes/OpenShift

**Quick Fix**:
```bash
# Check versions
oc version
oc get csidriver pxd.portworx.com -o yaml | grep csiDriverVersion

# Check Portworx operator version
oc get pods -n kube-system -l name=portworx-operator -o jsonpath='{.items[0].spec.containers[0].image}'

# May need to upgrade/downgrade Portworx
# Consult Portworx documentation for compatible versions
```

**Documentation**: Portworx documentation - version compatibility matrix

---

## License Errors

### Error: License expired or invalid

```
Error: portworx license expired
Error: invalid license
```

**Root Cause**: Portworx license issue

**Quick Fix**:
```bash
# Check Portworx license
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl license list

# This is a Portworx licensing issue, not CSI-specific
# Contact Portworx support or renew license
```

**Note**: CSI will not work without a valid Portworx license.

---

## Quick Error Lookup Table

| Error Keyword | Root Cause | Quick Action |
|--------------|------------|--------------|
| `socket` | Socket connection | Restart Portworx pod |
| `CSIDriver not found` | Missing CSI driver | Restart operator |
| `Unauthorized` | RBAC issue | Check service account |
| `forbidden` | Permission denied | Fix cluster role bindings |
| `ImagePullBackOff` | Cannot pull image | Add pull secrets |
| `FailedScheduling` | Cannot schedule | Fix node labels/taints |
| `OOMKilled` | Out of memory | Increase limits |
| `FailedMount` | Volume mount issue | Check Portworx health |
| `not operational` | Portworx cluster down | Fix Portworx cluster |
| `connection refused` | Network issue | Check cluster networking |

---

## General Troubleshooting Pattern

For ANY CrashLoopBackOff:

```bash
# 1. Get the error
oc logs -n kube-system $PX_CSI_POD --previous | tail -50

# 2. Check Portworx health FIRST
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status

# 3. If Portworx is healthy, restart CSI
oc delete pod -n kube-system $PX_CSI_POD

# 4. If Portworx is unhealthy, FIX THAT FIRST
```

**Priority**: Always verify Portworx cluster health before troubleshooting CSI.

---

## Related Documentation

- [README.md](./README.md) - Complete troubleshooting guide
- [QUICKSTART.md](./QUICKSTART.md) - Fast fixes
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Command reference
- [INVESTIGATION-WORKFLOW.md](./INVESTIGATION-WORKFLOW.md) - Systematic approach


# Investigation Workflow - Portworx CSI Pod CrashLoopBackOff

Systematic troubleshooting workflow for diagnosing `px-csi-ext` pod issues.

---

## Investigation Principles

1. **Check Portworx cluster health FIRST** - CSI is a layer on top of Portworx
2. **Collect evidence before acting** - Logs, events, status
3. **Follow the dependency chain** - Portworx → Socket → CSI → API Server
4. **One change at a time** - Verify results before next action
5. **Document findings** - What you found and what you tried

---

## Phase 1: Initial Assessment (5 minutes)

### Step 1.1: Confirm the Problem

```bash
# Get CSI pod status
PX_CSI_POD=$(oc get pods -n kube-system -l app=px-csi-driver -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep 'px-csi-ext-' | grep -v node | head -1)

oc get pod -n kube-system $PX_CSI_POD

# Expected problem indicators:
# - Status: CrashLoopBackOff
# - READY: 0/5 or similar
# - RESTARTS: High number (>5)
```

**Document**:
- Pod name: `_________________`
- Restart count: `_________________`
- Current status: `_________________`
- How long in this state: `_________________`

---

### Step 1.2: Get the Error Message

```bash
# Previous crash logs (MOST IMPORTANT)
oc logs -n kube-system $PX_CSI_POD --previous --tail=100 > csi-error.log

# Check last 20 lines for error
tail -20 csi-error.log

# Search for critical errors
grep -i "error\|failed\|fatal\|panic" csi-error.log
```

**Document**:
- Primary error message: `_________________`
- Error timestamp: `_________________`
- Which container crashed (if multiple): `_________________`

---

### Step 1.3: Check Recent Events

```bash
# Events for this specific pod
oc get events -n kube-system --field-selector involvedObject.name=$PX_CSI_POD --sort-by='.lastTimestamp' | tail -20

# All recent Portworx events
oc get events -n kube-system --sort-by='.lastTimestamp' | grep -i portworx | tail -30
```

**Document**:
- Any scheduling issues: `_________________`
- Any resource warnings: `_________________`
- Any volume mount failures: `_________________`

---

### Step 1.4: Critical - Check Portworx Cluster Health

```bash
# List all Portworx pods
oc get pods -n kube-system -l name=portworx -o wide

# Check Portworx cluster status
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status

# Expected healthy output:
# Status: PX is operational
# Cluster UUID: <uuid>
# Nodes: X node(s) with storage (X online)
```

**DECISION POINT**:

```
Is Portworx cluster operational?
│
├─ NO → STOP. Fix Portworx cluster first.
│       Go to Phase 2: Portworx Cluster Issues
│       CSI cannot work without healthy Portworx cluster.
│
└─ YES → Continue to Phase 3: CSI-Specific Investigation
```

**Document**:
- Portworx cluster status: `_________________`
- Number of Portworx nodes online: `_________________`
- Any Portworx warnings: `_________________`

---

## Phase 2: Portworx Cluster Issues

**Note**: If Portworx cluster is not operational, CSI will never work. Fix this first.

### Step 2.1: Diagnose Portworx Issues

```bash
# Check all Portworx pods
oc get pods -n kube-system -l name=portworx -o wide

# Check for pod failures
oc get pods -n kube-system -l name=portworx -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}'

# Check logs of unhealthy Portworx pods
for pod in $(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== $pod ==="
  oc logs -n kube-system $pod --tail=50 | grep -i "error\|failed\|fatal"
done
```

**Common Portworx Issues**:
- Quorum loss (etcd issues)
- Storage backend problems
- Network partition
- Node failures
- License issues

**Action**: Fix Portworx cluster issues first. Refer to Portworx troubleshooting documentation.

**After Portworx is healthy**, return to Phase 3.

---

## Phase 3: CSI-Specific Investigation

Portworx cluster is confirmed healthy. Now investigate CSI.

### Step 3.1: Identify Error Category

Based on the error message from Step 1.2, categorize the issue:

| Error Contains | Category | Go To |
|----------------|----------|-------|
| `socket` or `connection` | Socket Issues | Step 3.2 |
| `CSIDriver not found` | Registration | Step 3.3 |
| `Unauthorized` or `forbidden` | RBAC | Step 3.4 |
| `ImagePull` | Image Issues | Step 3.5 |
| `FailedScheduling` | Scheduling | Step 3.6 |
| `OOMKilled` or `Insufficient` | Resources | Step 3.7 |
| `FailedMount` | Volume Mounts | Step 3.8 |
| Other | General | Step 3.9 |

---

### Step 3.2: Investigate Socket Connection Issues

**Symptoms**: Error contains `socket`, `connection`, `dial unix`

```bash
# Check which node CSI pod is on
CSI_NODE=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}')
echo "CSI pod on node: $CSI_NODE"

# Check if Portworx pod is running on that node
oc get pods -n kube-system -l name=portworx -o wide | grep $CSI_NODE

# Get the Portworx pod on this node
PX_NODE_POD=$(oc get pods -n kube-system -l name=portworx -o wide | grep $CSI_NODE | awk '{print $1}')
echo "Portworx pod on same node: $PX_NODE_POD"

# Check if Portworx pod is healthy
oc get pod -n kube-system $PX_NODE_POD
oc logs -n kube-system $PX_NODE_POD --tail=50 | grep -i "socket\|csi"

# Verify socket exists (requires node access)
oc debug node/$CSI_NODE
# In debug pod:
chroot /host
ls -la /var/lib/kubelet/plugins/pxd.portworx.com/
exit
```

**Resolution Path**:

```
Is Portworx pod on same node healthy?
│
├─ NO → Restart Portworx pod:
│       oc delete pod -n kube-system $PX_NODE_POD
│       Wait for ready: oc wait --for=condition=Ready pod $PX_NODE_POD -n kube-system --timeout=300s
│       Then restart CSI: oc delete pod -n kube-system $PX_CSI_POD
│
└─ YES → Socket might be in bad state:
        Restart both: oc delete pod -n kube-system $PX_NODE_POD $PX_CSI_POD
```

**Verification**:
```bash
# Wait 2-3 minutes, then check
oc get pod -n kube-system $PX_CSI_POD
oc logs -n kube-system $PX_CSI_POD --tail=20

# Should see: "CSI driver started" or similar success message
```

---

### Step 3.3: Investigate CSI Driver Registration Issues

**Symptoms**: Error contains `CSIDriver not found`, `not registered`

```bash
# Check if CSI driver exists
oc get csidriver pxd.portworx.com

# If not found, check operator
oc get pods -n kube-system | grep portworx-operator

# Check operator logs
oc logs -n kube-system -l name=portworx-operator --tail=100 | grep -i "csi\|driver"

# Check if operator is creating CSI driver
oc logs -n kube-system -l name=portworx-operator --tail=100 | grep -i "error\|failed"
```

**Resolution Path**:

```
Does CSIDriver object exist?
│
├─ NO → Is operator running?
│       │
│       ├─ NO → Start operator:
│       │       oc get deployment -n kube-system | grep portworx-operator
│       │       oc scale deployment <operator-name> -n kube-system --replicas=1
│       │
│       └─ YES → Restart operator:
│               oc delete pod -n kube-system -l name=portworx-operator
│               Wait 2-3 minutes
│               Check: oc get csidriver pxd.portworx.com
│
└─ YES → CSI driver exists but pod can't see it
        → Check RBAC (go to Step 3.4)
```

**If CSI driver still missing after 5 minutes**, create manually:

```bash
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

# Restart CSI pod
oc delete pod -n kube-system $PX_CSI_POD
```

---

### Step 3.4: Investigate RBAC Issues

**Symptoms**: Error contains `Unauthorized`, `forbidden`, `cannot`

```bash
# Check service account
oc get sa -n kube-system px-account
oc describe sa -n kube-system px-account

# Check cluster role bindings
oc get clusterrolebinding | grep portworx
oc get clusterrolebinding -o yaml | grep -A 30 portworx

# Test specific permissions
oc auth can-i --as=system:serviceaccount:kube-system:px-account create persistentvolumes
oc auth can-i --as=system:serviceaccount:kube-system:px-account get csidrivers
oc auth can-i --as=system:serviceaccount:kube-system:px-account list nodes
oc auth can-i --as=system:serviceaccount:kube-system:px-account create csinodes

# Check SecurityContextConstraints (OpenShift)
oc get scc | grep portworx
oc adm policy who-can use scc portworx-scc -n kube-system
```

**Resolution Path**:

Common missing permissions:
- `csidrivers` - get, list
- `csinodes` - get, list, create, update
- `persistentvolumes` - get, list, create, delete
- `nodes` - get, list
- `volumeattachments` - get, list, create, update, delete

**If permissions are missing**:

```bash
# Check Portworx installation manifests
# You may need to reapply operator installation

# Or manually create cluster role binding (example)
# Note: Get the correct role from Portworx documentation
oc create clusterrolebinding portworx-cluster-role-binding \
  --clusterrole=portworx-cluster-role \
  --serviceaccount=kube-system:px-account
```

**For SCC issues** (OpenShift):

```bash
# Add SCC to service account
oc adm policy add-scc-to-user portworx-scc system:serviceaccount:kube-system:px-account

# Verify
oc adm policy who-can use scc portworx-scc -n kube-system

# Restart CSI pod
oc delete pod -n kube-system $PX_CSI_POD
```

---

### Step 3.5: Investigate Image Pull Issues

**Symptoms**: `ImagePullBackOff`, `ErrImagePull`

```bash
# Get image details
IMAGE=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.containers[0].image}')
echo "CSI Image: $IMAGE"

# Check image pull events
oc get events -n kube-system | grep -i "image\|pull" | grep $PX_CSI_POD

# Check for image pull secrets
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.imagePullSecrets}'
oc describe sa -n kube-system px-account | grep "Image pull secrets"

# Check if using private registry
echo $IMAGE | grep -E "^(docker.io|quay.io|registry.connect.redhat.com)"
```

**Resolution Path**:

```
Is this a private registry?
│
├─ YES → Does service account have pull secret?
│       │
│       ├─ NO → Create and attach pull secret:
│       │       oc create secret docker-registry px-registry-secret \
│       │         --docker-server=<registry> \
│       │         --docker-username=<user> \
│       │         --docker-password=<pass> \
│       │         -n kube-system
│       │       oc patch sa px-account -n kube-system \
│       │         -p '{"imagePullSecrets": [{"name": "px-registry-secret"}]}'
│       │       oc delete pod -n kube-system $PX_CSI_POD
│       │
│       └─ YES → Check if secret is valid:
│               oc get secret px-registry-secret -n kube-system -o yaml
│               # May need to recreate with correct credentials
│
└─ NO → Public registry
        → Check node network connectivity
        → Check if cluster uses imageContentSourcePolicy
        → May need to mirror image to internal registry
```

**For disconnected/airgap environments**:

```bash
# Check image content source policies
oc get imagecontentsourcepolicy

# Check if image is mirrored
oc get imagestreams -n openshift
```

---

### Step 3.6: Investigate Scheduling Issues

**Symptoms**: `FailedScheduling`, `node(s) didn't match`, `node(s) had taint`

```bash
# Check scheduling details
oc describe pod -n kube-system $PX_CSI_POD | grep -A 20 "Events:"

# Check node selector
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeSelector}'

# Check affinity rules
oc get pod -n kube-system $PX_CSI_POD -o yaml | grep -A 30 "affinity:"

# Check tolerations
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.tolerations}' | jq .

# Check nodes running Portworx
oc get pods -n kube-system -l name=portworx -o wide

# Check node labels
oc get nodes --show-labels

# Check node taints
oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints}{"\n"}{end}'
```

**Resolution Path**:

**For node selector issues**:
```bash
# Add required labels to nodes
NODE_SELECTOR=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeSelector}')
echo "Required labels: $NODE_SELECTOR"

# Example: add label to nodes running Portworx
for node in $(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[*].spec.nodeName}' | tr ' ' '\n' | sort -u); do
  oc label node $node px/enabled=true
done

# Restart CSI pod
oc delete pod -n kube-system $PX_CSI_POD
```

**For taint issues**:
```bash
# Option 1: Remove taints from nodes
oc adm taint node <node-name> <key>-

# Option 2: Add tolerations to deployment
CONTROLLER=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.metadata.ownerReferences[0].name}')
CONTROLLER_KIND=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.metadata.ownerReferences[0].kind}')
oc edit $CONTROLLER_KIND/$CONTROLLER -n kube-system

# Add tolerations:
# spec:
#   template:
#     spec:
#       tolerations:
#       - key: "node.kubernetes.io/unschedulable"
#         operator: "Exists"
#         effect: "NoSchedule"
```

---

### Step 3.7: Investigate Resource Issues

**Symptoms**: `OOMKilled`, `Insufficient cpu`, `Insufficient memory`

```bash
# Check resource requests and limits
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.containers[*].resources}' | jq .

# Check if OOMKilled
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.status.containerStatuses[*].lastState.terminated.reason}'

# Check node capacity
CSI_NODE=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}')
oc describe node $CSI_NODE | grep -A 15 "Allocated resources:"

# Check what's using resources on this node
oc describe node $CSI_NODE | grep -A 50 "Non-terminated Pods:"
```

**Resolution Path**:

**If OOMKilled**:
```bash
# Increase memory limits
CONTROLLER=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.metadata.ownerReferences[0].name}')
CONTROLLER_KIND=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.metadata.ownerReferences[0].kind}')
oc edit $CONTROLLER_KIND/$CONTROLLER -n kube-system

# Increase memory in resources section:
# resources:
#   limits:
#     memory: 1Gi  # Increase this
#   requests:
#     memory: 512Mi  # And this
```

**If insufficient node resources**:
```bash
# Option 1: Free up resources
# Scale down non-critical workloads temporarily
oc get pods -n <namespace> --sort-by=.spec.nodeName | grep $CSI_NODE

# Option 2: Reduce CSI resource requests (if they're too high)
# Edit deployment to lower requests

# Option 3: Add more node capacity
# Add worker nodes or resize existing nodes
```

---

### Step 3.8: Investigate Volume Mount Issues

**Symptoms**: `FailedMount`, `Unable to attach or mount volumes`

```bash
# Check volume mounts
oc describe pod -n kube-system $PX_CSI_POD | grep -A 30 "Mounts:"

# Check volumes
oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.volumes}' | jq .

# Verify host paths exist
CSI_NODE=$(oc get pod -n kube-system $PX_CSI_POD -o jsonpath='{.spec.nodeName}')
oc debug node/$CSI_NODE
# In debug pod:
chroot /host
ls -la /var/lib/kubelet/plugins/
ls -la /var/lib/kubelet/plugins_registry/
ls -la /var/lib/kubelet/plugins/pxd.portworx.com/
exit
```

**Resolution Path**:

Usually indicates Portworx pod not running properly on that node:

```bash
# Find Portworx pod on same node
PX_NODE_POD=$(oc get pods -n kube-system -l name=portworx -o wide | grep $CSI_NODE | awk '{print $1}')

# Check its health
oc get pod -n kube-system $PX_NODE_POD
oc logs -n kube-system $PX_NODE_POD --tail=100

# Restart Portworx pod first
oc delete pod -n kube-system $PX_NODE_POD

# Wait for ready
oc wait --for=condition=Ready pod $PX_NODE_POD -n kube-system --timeout=300s

# Then restart CSI
oc delete pod -n kube-system $PX_CSI_POD
```

---

### Step 3.9: General Investigation (Unknown Error)

For errors not covered above:

```bash
# Collect comprehensive information
mkdir -p portworx-investigation
cd portworx-investigation

# Pod details
oc get pod -n kube-system $PX_CSI_POD -o yaml > csi-pod.yaml
oc describe pod -n kube-system $PX_CSI_POD > csi-pod-describe.txt

# Logs
oc logs -n kube-system $PX_CSI_POD --all-containers=true > csi-pod-logs.txt
oc logs -n kube-system $PX_CSI_POD --previous --all-containers=true > csi-pod-logs-previous.txt

# Events
oc get events -n kube-system --sort-by='.lastTimestamp' | grep portworx > events.txt

# Portworx status
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status > px-status.txt

# CSI driver
oc get csidriver pxd.portworx.com -o yaml > csidriver.yaml

# CSI nodes
oc get csinode -o yaml > csinodes.yaml

# Storage classes
oc get sc -o yaml > storageclasses.yaml

# Review error patterns
grep -i "error\|failed\|fatal\|panic" csi-pod-logs-previous.txt

# Search for similar issues online
# Share diagnostics with Red Hat or Portworx support
```

---

## Phase 4: Verification

After applying any fix, verify the resolution:

### Step 4.1: Verify Pod Health

```bash
# Check pod status
oc get pod -n kube-system $PX_CSI_POD

# Should show:
# - STATUS: Running
# - READY: 5/5 (or appropriate number)
# - RESTARTS: Should not increase

# Wait 5 minutes and check again
sleep 300
oc get pod -n kube-system $PX_CSI_POD

# Check logs are clean
oc logs -n kube-system $PX_CSI_POD --tail=50
# Should see: "CSI driver started successfully" or similar
```

---

### Step 4.2: Test CSI Functionality

```bash
# Test PVC creation
cat <<EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc-verification
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: portworx-sc
EOF

# Watch PVC bind
oc get pvc test-pvc-verification -w

# Should transition to: Bound

# Check PV was created
oc get pv | grep test-pvc-verification

# Test pod attachment
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-verification
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
      claimName: test-pvc-verification
EOF

# Watch pod start
oc get pod test-pod-verification -w

# Verify volume mounted
oc exec test-pod-verification -- df -h /data
oc exec test-pod-verification -- touch /data/test-file
oc exec test-pod-verification -- ls -la /data/

# Clean up
oc delete pod test-pod-verification
oc delete pvc test-pvc-verification
```

---

### Step 4.3: Monitor for Stability

```bash
# Monitor CSI pod for 15 minutes
watch -n 30 'oc get pod -n kube-system -l app=px-csi-driver'

# Check restart counts don't increase
oc get pods -n kube-system -l app=px-csi-driver -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}'

# Monitor events
oc get events -n kube-system --sort-by='.lastTimestamp' | grep portworx | tail -20
```

---

## Phase 5: Documentation

Document your findings and resolution:

### Investigation Summary Template

```
Date: _______________
Investigator: _______________

PROBLEM:
- Pod name: _______________
- Initial status: _______________
- Error message: _______________

INVESTIGATION:
- Portworx cluster status: _______________
- Root cause identified: _______________
- Category: [Socket / Registration / RBAC / Image / Scheduling / Resources / Mount / Other]

RESOLUTION:
- Actions taken: _______________
- Commands run: _______________
- Configuration changes: _______________

VERIFICATION:
- Pod status after fix: _______________
- Test PVC creation: [Success / Failed]
- Stability check (15 min): [Stable / Unstable]

FOLLOW-UP:
- Any remaining concerns: _______________
- Monitoring recommendations: _______________
- Prevention measures: _______________
```

---

## Escalation Criteria

Escalate to Red Hat or Portworx support if:

1. **Portworx cluster is unhealthy** and basic restarts don't fix it
2. **CSI crashes persist** after fixing obvious issues (RBAC, image, scheduling)
3. **Data corruption or loss** is suspected
4. **Issue impacts production** and quick resolution needed
5. **Complex version compatibility** issues
6. **Unknown error messages** not covered in documentation

**Before escalating, collect**:
```bash
# Must-gather
oc adm must-gather --image=registry.connect.redhat.com/portworx/must-gather:latest

# Investigation summary
# All logs and diagnostics collected
```

---

## Common Patterns and Lessons

### Pattern 1: Socket Issues After Node Reboot

**Symptom**: CSI pod crashes with socket errors after node maintenance

**Root Cause**: Portworx pod not fully initialized before CSI tries to connect

**Resolution**: Restart CSI pod after confirming Portworx is ready

---

### Pattern 2: CSI Fails After Cluster Upgrade

**Symptom**: CSI pods crash after OpenShift upgrade

**Root Cause**: Version incompatibility or API changes

**Resolution**: Upgrade Portworx operator to compatible version

---

### Pattern 3: Intermittent Crashes

**Symptom**: CSI pod crashes occasionally, not consistently

**Root Cause**: Usually network or resource pressure

**Resolution**: Increase resource limits and monitor network connectivity

---

### Pattern 4: Multiple CSI Pods Crashing

**Symptom**: All CSI pods in CrashLoopBackOff

**Root Cause**: Usually Portworx cluster-wide issue or RBAC change

**Resolution**: Check Portworx cluster health first, then RBAC

---

## Related Workflows

- **Portworx Cluster Troubleshooting** - For Portworx backend issues
- **PVC Provisioning Issues** - For storage provisioning problems
- **Volume Attachment Failures** - For pod volume mount issues
- **Performance Issues** - For slow storage operations

---

## Workflow Completion Checklist

- [ ] Problem confirmed and documented
- [ ] Logs and events collected
- [ ] Portworx cluster health verified
- [ ] Root cause identified
- [ ] Fix applied
- [ ] Pod health verified
- [ ] CSI functionality tested
- [ ] Stability monitored (15+ minutes)
- [ ] Documentation completed
- [ ] Prevention measures identified

---

## Additional Resources

- [README.md](./README.md) - Complete troubleshooting guide
- [QUICKSTART.md](./QUICKSTART.md) - Fast fixes
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Command reference
- [COMMON-ERRORS.md](./COMMON-ERRORS.md) - Error lookup table


# Quick Start - Fix Portworx CSI Pod CrashLoopBackOff

**Problem**: `px-csi-ext` pod in CrashLoopBackOff, preventing PVC provisioning and volume operations

**Quick Diagnosis (2 minutes)**:

```bash
# 1. Get pod name and check status
PX_CSI_POD=$(oc get pods -n kube-system -l app=px-csi-driver -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep px-csi-ext)
oc get pod -n kube-system $PX_CSI_POD

# 2. Check the actual error
oc logs -n kube-system $PX_CSI_POD --tail=50
oc logs -n kube-system $PX_CSI_POD --previous --tail=50

# 3. Verify Portworx cluster health
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status
```

---

## Common Quick Fixes

### Fix 1: Socket Connection Issues (Most Common)

**Symptom**: Logs show `failed to connect to /var/lib/kubelet/plugins/pxd.portworx.com/csi.sock`

```bash
# Check if Portworx main pods are healthy
oc get pods -n kube-system -l name=portworx

# If Portworx pods are running, restart the CSI pod
oc delete pod -n kube-system $PX_CSI_POD

# Watch it recover
oc get pod -n kube-system $PX_CSI_POD -w
```

### Fix 2: Missing CSI Driver Registration

**Symptom**: Logs show CSI driver registration failures

```bash
# Check CSI driver exists
oc get csidriver pxd.portworx.com

# If missing, check if Portworx operator is healthy
oc get pods -n kube-system | grep portworx-operator

# Restart operator if needed
oc delete pod -n kube-system -l name=portworx-operator
```

### Fix 3: RBAC/Service Account Issues

**Symptom**: Logs show permission denied or authentication errors

```bash
# Verify service account exists
oc get sa -n kube-system px-account

# Check cluster role bindings
oc get clusterrolebinding | grep portworx

# If using specific SCC, verify it's assigned
oc get scc | grep portworx
oc adm policy who-can use scc portworx-scc -n kube-system
```

### Fix 4: Node Selector / Affinity Issues

**Symptom**: Pod shows `0/X nodes available` or scheduling errors

```bash
# Check where pod is trying to schedule
oc describe pod -n kube-system $PX_CSI_POD | grep -A 10 "Node-Selectors\|Affinity"

# Check which nodes have Portworx running
oc get pods -n kube-system -l name=portworx -o wide

# Verify node labels
oc get nodes --show-labels | grep -i portworx
```

---

## Emergency Recovery

If the cluster is in critical state (can't provision PVCs):

```bash
# 1. Check Portworx cluster status first (most important)
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status

# 2. If Portworx cluster is healthy but CSI is failing
# Force restart the entire Portworx CSI driver DaemonSet
oc rollout restart daemonset/px-csi-ext -n kube-system

# 3. Verify recovery (wait 2-3 minutes)
oc rollout status daemonset/px-csi-ext -n kube-system
oc get pods -n kube-system -l app=px-csi-driver
```

---

## Verification

After applying fixes:

```bash
# 1. Verify pod is running
oc get pod -n kube-system $PX_CSI_POD

# 2. Check logs are clean (no errors)
oc logs -n kube-system $PX_CSI_POD --tail=20

# 3. Test PVC creation
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

# 4. Verify PVC binds
oc get pvc test-pvc-portworx -n default -w

# 5. Clean up test
oc delete pvc test-pvc-portworx -n default
```

---

## Full Documentation

- **[README.md](./README.md)** - Complete troubleshooting guide
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Fast command reference
- **[COMMON-ERRORS.md](./COMMON-ERRORS.md)** - Error messages and solutions
- **[INVESTIGATION-WORKFLOW.md](./INVESTIGATION-WORKFLOW.md)** - Systematic troubleshooting

## Diagnostic Script

```bash
chmod +x diagnostic-script.sh
./diagnostic-script.sh > portworx-diagnostics-$(date +%Y%m%d-%H%M%S).txt
```

Share the output with your team or Red Hat support.

---

## What If Nothing Works?

1. **Collect must-gather**:
   ```bash
   oc adm must-gather --image=registry.connect.redhat.com/portworx/must-gather:latest
   ```

2. **Check Red Hat and Portworx documentation**:
   - [Portworx on OpenShift Documentation](https://docs.portworx.com/portworx-enterprise/install-portworx/openshift)
   - [Red Hat Storage Documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_container_platform/)

3. **Open a support case** with Red Hat or Portworx with the must-gather data


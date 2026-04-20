# 🚨 CRITICAL UPDATE - December 3, 2025

## Control Plane Failure Detected

**Original Issue:** master-2 stuck in inspection (NVIDIA ConnectX NIC error)  
**NEW CRITICAL ISSUE:** etcd degraded - master-1 etcd member missing

---

## Current Cluster State

### Control Plane Status
- **master-0:** ✅ Appears healthy
- **master-1:** 🔴 **CRITICAL - etcd operand missing**
- **master-2:** ❓ Never completed inspection (hardware issue)

### Failure Cascade Discovered

```
1. etcd degraded on master-1 (GuardControllerDegraded)
   ↓
2. kube-controller-manager affected
   ↓
3. Deployment controller can't create replicasets
   ↓
4. metal3 deployment can't recreate pods
   ↓
5. Cannot manage BareMetalHosts (including master-2)
```

### What Happened

User deleted metal3 pod to restart it → pod didn't come back → discovered etcd is degraded.

**The master-2 inspection issue is now SECONDARY to the etcd failure.**

---

## 🎯 **NEW Priority: Fix etcd on master-1**

### Immediate Actions Required

1. **Diagnose etcd Status**
   ```bash
   oc get pods -n openshift-etcd
   oc get clusteroperator etcd -o yaml
   oc describe node master-1
   ```

2. **Check etcd Member List**
   ```bash
   oc debug node/master-0
   chroot /host
   # Check if master-1 is in etcd cluster
   ```

3. **Determine Recovery Path**
   - If etcd pod exists but failing → Restart
   - If etcd manifest missing → Force operator reconciliation
   - If master-1 node unhealthy → Investigate node issues

### Cluster Risk Level

**CRITICAL - Quorum at Risk**
- Current: 2/3 etcd members potentially healthy (master-0, and maybe master-2 if it has etcd?)
- Risk: Loss of one more etcd member = total cluster failure
- Action: Fix master-1 etcd IMMEDIATELY before continuing other work

---

## 📋 **Revised Troubleshooting Order**

### Phase 1: Stabilize Control Plane (URGENT)
1. ✅ Identify etcd issue on master-1
2. ⏳ Fix etcd on master-1
3. ⏳ Verify etcd cluster quorum restored
4. ⏳ Verify kube-controller-manager healthy
5. ⏳ Verify metal3 operator can function

### Phase 2: Restore metal3 (After etcd Fixed)
1. Restart cluster-baremetal-operator
2. Verify metal3 deployment recreates
3. Verify metal3 pod starts successfully

### Phase 3: Resume master-2 Inspection (After Control Plane Stable)
1. Return to NVIDIA ConnectX NIC hardware investigation
2. Fix hardware configuration
3. Retry inspection
4. Complete cluster installation

---

## ⚠️ **Do NOT Proceed with master-2 Until etcd is Fixed**

Attempting to fix master-2 inspection while etcd is degraded will:
- Not work (metal3 can't function properly)
- Risk making things worse
- Waste time

**Fix the foundation first.**

---

## 🔍 **Diagnostic Commands for etcd**

```bash
# Save these outputs:

# 1. Current etcd status
oc get pods -n openshift-etcd -o wide > etcd-pods.txt

# 2. etcd operator status
oc get clusteroperator etcd -o yaml > etcd-operator.yaml

# 3. master-1 node status
oc describe node master-1 > master-1-node.txt

# 4. Check if etcd pod exists on master-1
oc get pod -n openshift-etcd --field-selector spec.nodeName=master-1 > master-1-etcd-pod.txt

# 5. All cluster operators
oc get clusteroperators > all-operators.txt

# 6. Check master-1 from inside
oc debug node/master-1 << 'EOF'
chroot /host
echo "=== Kubelet Status ==="
systemctl status kubelet
echo "=== etcd Manifest ==="
ls -la /etc/kubernetes/manifests/etcd-pod.yaml
echo "=== Kubelet Logs ==="
journalctl -u kubelet -n 50
EOF
```

---

## 📞 **This May Require Support**

If etcd cannot be recovered easily:
- This is a control plane failure scenario
- May need Red Hat support
- Have must-gather ready:
  ```bash
  oc adm must-gather
  ```

**etcd recovery is complex and critical. Don't guess - follow proven recovery procedures.**

---

## 🔗 **Related Documentation**

- [OpenShift etcd Recovery](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/backup_and_restore/control-plane-backup-and-restore)
- etcd cluster quorum requirements
- Force etcd member replacement procedures

---

**Session Status:** ⏸️ PAUSED - Control plane stabilization required  
**Next Action:** Fix etcd on master-1  
**Timeline:** Unknown - depends on etcd recovery complexity


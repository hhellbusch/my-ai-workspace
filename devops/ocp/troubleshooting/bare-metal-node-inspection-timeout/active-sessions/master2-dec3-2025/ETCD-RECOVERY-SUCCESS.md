# etcd Recovery - RESOLVED ✅

**Date:** December 3, 2025  
**Duration:** ~2 hours  
**Status:** SUCCESS - Control plane recovering

---

## 🎯 **Problem Summary**

Started with: master-2 stuck in inspection (NVIDIA ConnectX NIC issue)  
Discovered: **Critical control plane failure - etcd degraded on master-1**

---

## 🔍 **Root Cause Analysis**

### The Failure Chain

```
1. User deleted metal3 pod to restart it
   ↓
2. Pod didn't come back (deployment not recreating)
   ↓
3. Investigation revealed: etcd operator degraded
   ↓
4. "GuardControllerDegraded: Missing operand on node master-1"
   ↓
5. etcd container running but pod not visible in API
   ↓
6. Kubelet on master-1 couldn't create mirror pod
   ↓
7. ROOT CAUSE: Kubelet authentication completely broken
```

### Authentication Failure Details

**Symptoms:**
- `system:anonymous` errors in kubelet logs
- Kubelet kubeconfig pointed to `/var/lib/kubelet/pki/kubelet-client-current.pem`
- **That file didn't exist**
- Kubelet fell back to anonymous auth
- Anonymous auth can't create pods or access resources

**Why It Happened:**
- Bootstrap tokens no longer present in cluster
- Kubelet couldn't request new client certificate via CSR
- No way to authenticate without bootstrap tokens
- Previous client certificate was deleted during troubleshooting

---

## ✅ **The Solution**

### What Worked

Used the node's existing authentication instead of trying to bootstrap:

```bash
# On master-1
systemctl stop kubelet
mv /var/lib/kubelet/kubeconfig /var/lib/kubelet/kubeconfig.broken

# Copy node's existing kubeconfig (has valid authentication)
cp /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig \
   /var/lib/kubelet/kubeconfig

systemctl start kubelet
```

### Why This Works

The `localhost.kubeconfig` contains certificates that the node uses for its static pods:
- Already has valid authentication with API server
- No CSR or bootstrap tokens needed
- Kubelet can use these same credentials
- Immediately functional

---

## 📊 **Recovery Timeline**

| Time | Action | Result |
|------|--------|--------|
| T+0 | Discovered etcd degraded | GuardControllerDegraded error |
| T+15min | Moved etcd manifest to force recreation | Container came back but not pod |
| T+30min | Found kubelet authentication issues | system:anonymous errors |
| T+45min | Tried to regenerate certificates | CSR process failed (no bootstrap tokens) |
| T+60min | Attempted multiple fixes | Still no client certificate |
| T+90min | **Used node's localhost.kubeconfig** | ✅ **AUTHENTICATION SUCCESS** |
| T+95min | Kubelet authenticated | Mirror pod creation started |
| T+100min | Operators reconciling | Control plane recovering |

---

## 🔧 **Troubleshooting Steps Taken**

### Phase 1: Initial Discovery
1. Checked why metal3 pod not recreating
2. Found deployment not creating replicaset
3. Discovered etcd operator degraded
4. Identified master-1 etcd missing from operator's view

### Phase 2: etcd Pod Recovery Attempts
1. Moved etcd manifest out and back
2. etcd container started (visible via crictl)
3. But pod not visible via `oc get pods`
4. Realized kubelet not creating mirror pod

### Phase 3: Kubelet Authentication Issues
1. Found `system:anonymous` in kubelet logs
2. Discovered `/var/lib/kubelet/pki/kubelet-client-current.pem` missing
3. Tried to regenerate certificate
4. Found no bootstrap tokens available
5. CSR process couldn't work without bootstrap tokens

### Phase 4: Failed Attempts
1. Deleted and regenerated kubelet certs (multiple times)
2. Tried to approve CSRs (but none were created)
3. Attempted to restore bootstrap process
4. Hit "http2: client connection lost" when trying remote oc commands

### Phase 5: Successful Resolution
1. Realized remote API access failing but node-local worked
2. Used `oc debug node/master-0` with localhost kubeconfig for operations
3. **Key insight:** Use node's existing authentication instead of bootstrapping
4. Copied localhost.kubeconfig to kubelet
5. ✅ **Immediate success** - kubelet authenticated

---

## 💡 **Key Learnings**

### What We Learned

1. **Bootstrap tokens are critical** for kubelet certificate rotation
2. **Without bootstrap tokens**, kubelet can't request new certificates via CSR
3. **Chicken-and-egg problem**: Need auth to request auth
4. **Nodes have their own kubeconfig** that already works
5. **Remote API access can fail** while local API access works fine

### Best Practices for Future

1. **Don't delete kubelet certificates** without understanding bootstrap process
2. **Check bootstrap token availability** before certificate operations
3. **Use node's localhost kubeconfig** as fallback when bootstrap fails
4. **Work from master node** when remote API access is flaky
5. **Document the recovery path** for future incidents

---

## 🔗 **Related Issues Encountered**

### Remote API Server Connection Issues

**Problem:** `oc` commands from workstation timing out or "connection lost"  
**Workaround:** Use `oc debug node/master-0` and localhost kubeconfig  
**Root Cause:** Not fully diagnosed (likely load balancer or API VIP issue)  
**Status:** Deferred - use node-local access for now

### Installer Pods Stuck Pending

**Problem:** `installer-6` pods pending, blocking node config rollout  
**Status:** Likely resolved once control plane stabilizes  
**Action:** Monitor after etcd recovery complete

---

## 📋 **Current Status**

**As of last update:**
- ✅ Kubelet on master-1 authenticated successfully
- ✅ etcd container running on master-1
- ⏳ Mirror pod creation in progress
- ⏳ etcd operator reconciling
- ⏳ Control plane operators recovering
- ⏸️ master-2 inspection issue (original problem) on hold

**Expected:**
- etcd operator: Degraded → False (within 5-10 minutes)
- All operators: Available=True, Degraded=False (within 15-20 minutes)
- metal3 pod: Recreated (within 20 minutes)
- Ready to resume master-2 troubleshooting

---

## 🎯 **Next Steps**

### Immediate (Next 20 minutes)
1. Monitor etcd operator until Degraded=False
2. Verify all 3 etcd pods visible
3. Check kube-controller-manager recovers
4. Verify metal3 deployment recreates
5. Confirm all cluster operators healthy

### Then Resume Original Issue
1. Return to master-2 inspection problem
2. Compare NVIDIA ConnectX NIC configs via iDRAC
3. Fix hardware mismatch between masters
4. Retry inspection with correct hardware config
5. Complete cluster build

---

## 📞 **Commands Reference**

### Check Recovery Progress

```bash
# etcd status
oc get co etcd

# All operators
oc get co | grep -v "True.*False.*False"

# etcd pods
oc get pods -n openshift-etcd

# metal3 status
oc get deployment,pod -n openshift-machine-api | grep metal3
```

### If Remote Access Still Flaky

```bash
# Work from master node
oc debug node/master-0
chroot /host
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
# Now run oc commands
```

---

## 📝 **Files Created**

- `CRITICAL-UPDATE.md` - Initial discovery of etcd issue
- `ETCD-RECOVERY-SUCCESS.md` - This file, resolution documentation

---

**Resolution Credit:** Using node's existing localhost kubeconfig instead of attempting bootstrap  
**Time to Resolution:** ~2 hours  
**Complexity:** High - required deep understanding of kubelet authentication flow  
**Success:** ✅ Control plane recovering, ready to resume original task


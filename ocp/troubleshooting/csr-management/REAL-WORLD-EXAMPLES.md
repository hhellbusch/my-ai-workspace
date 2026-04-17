# Real-World CSR Examples from Field Experience

## Overview

This document contains actual CSR scenarios encountered during OpenShift troubleshooting, including the specific errors, diagnostics, and resolutions.

---

## Example 1: Kubelet Authentication Failure After etcd Recovery

### Scenario
**Date:** December 3, 2025  
**Situation:** master-1 node recovered from etcd failure, but kubelet couldn't authenticate  
**Error:** `User "system:anonymous" cannot get resource...`

### Problem Details

**Kubelet logs showed:**
```
I1203 21:55:35.453854  701002 csi_plugin.go:884] Failed to contact API server when waiting for CSINode publishing: 
csinodes.storage.k8s.io "master-1" is forbidden: 
User "system:anonymous" cannot get resource "csinodes" in API group "storage.k8s.io" at the cluster scope
```

**Root cause:**
- Kubelet kubeconfig pointed to: `/var/lib/kubelet/pki/kubelet-client-current.pem`
- **File didn't exist**
- Bootstrap tokens were gone (expired/removed)
- Kubelet couldn't create CSR without authentication
- Fell back to anonymous auth

### Expected CSRs (But None Appeared)

Should have seen:
```
NAME           AGE   SIGNERNAME                                    REQUESTOR              CONDITION
csr-master-1   1m    kubernetes.io/kube-apiserver-client-kubelet   system:node:master-1   Pending
```

But got: **No CSRs created** (kubelet couldn't authenticate to create them)

### Attempted Solutions That Failed

1. **Tried to regenerate certificate:**
   ```bash
   systemctl stop kubelet
   rm -f /var/lib/kubelet/pki/kubelet-client*.pem
   systemctl start kubelet
   ```
   **Result:** No CSR created (no bootstrap tokens)

2. **Tried to approve non-existent CSRs:**
   ```bash
   oc get csr | grep Pending
   ```
   **Result:** No CSRs pending

3. **Tried from workstation:**
   ```bash
   oc adm certificate approve <csr>
   ```
   **Result:** "http2: client connection lost" (API server connection issues)

### Successful Resolution

**Bypassed the CSR process entirely:**

```bash
# On master-1
systemctl stop kubelet
mv /var/lib/kubelet/kubeconfig /var/lib/kubelet/kubeconfig.broken

# Use node's existing authentication
cp /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig \
   /var/lib/kubelet/kubeconfig

systemctl start kubelet
```

**Result:** ✅ Kubelet authenticated immediately (no CSR needed)

**Outcome:**
- Kubelet could create mirror pods
- etcd-master-1 pod appeared in API server
- etcd operator became healthy
- Cluster recovered

### Lessons Learned

1. **Bootstrap tokens are critical** for normal CSR flow
2. **Localhost kubeconfig is a fallback** when bootstrap fails
3. **CSRs won't appear** if kubelet can't authenticate to create them
4. **Working from master node** when remote API access fails
5. **Sometimes bypassing the problem** is better than fighting it

---

## Example 2: Multiple Nodes After Maintenance Window

### Scenario
**Situation:** Certificate rotation during maintenance  
**Issue:** 10 worker nodes all need certificate renewal simultaneously

### CSR Status Before

```bash
$ oc get csr
NAME            AGE   SIGNERNAME                                    REQUESTOR              CONDITION
csr-worker-0    2m    kubernetes.io/kube-apiserver-client-kubelet   system:node:worker-0   Pending
csr-worker-1    2m    kubernetes.io/kube-apiserver-client-kubelet   system:node:worker-1   Pending
csr-worker-2    2m    kubernetes.io/kube-apiserver-client-kubelet   system:node:worker-2   Pending
[... 7 more ...]
```

### Actions Taken

```bash
# Step 1: Verify all requestors are known nodes
oc get nodes | grep worker

# Step 2: Approve all pending
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve

# Step 3: Verify approval
oc get csr | grep Approved | tail -10
```

### Result

All 10 CSRs approved in ~2 seconds, all nodes authenticated successfully.

---

## Example 3: New Node Addition

### Scenario
**Situation:** Adding new worker node to existing cluster  
**Expected:** CSRs for client and serving certificates

### Timeline

**T+0: Node boots and joins**
```bash
$ oc get csr | grep worker-5
csr-h8k2x   10s   kubernetes.io/kube-apiserver-client-kubelet   system:node:worker-5   Pending
```

**T+1min: Approve client CSR**
```bash
$ oc adm certificate approve csr-h8k2x
certificatesigningrequest.certificates.k8s.io/csr-h8k2x approved
```

**T+2min: Node creates serving CSR**
```bash
$ oc get csr | grep worker-5
csr-h8k2x   2m    kubernetes.io/kube-apiserver-client-kubelet   system:node:worker-5   Approved,Issued
csr-m9n3y   20s   kubernetes.io/kubelet-serving                 system:node:worker-5   Pending
```

**T+3min: Approve serving CSR**
```bash
$ oc adm certificate approve csr-m9n3y
certificatesigningrequest.certificates.k8s.io/csr-m9n3y approved
```

**T+4min: Node Ready**
```bash
$ oc get node worker-5
NAME       STATUS   ROLES    AGE     VERSION
worker-5   Ready    worker   4m22s   v1.29.0
```

### Key Points

- **Two CSRs per node:** client (first), then serving (second)
- **Serving CSR appears** only after client CSR approved
- **Order matters:** Approve client first

---

## Example 4: CSR Approval During Remote API Failure

### Scenario
**Situation:** Remote `oc` commands timing out, but cluster still running  
**Error:** `Unable to connect to the server: http2: client connection lost`

### Problem

```bash
# From workstation
$ oc get csr
Unable to connect to the server: http2: client connection lost

# Command hangs or fails intermittently
```

### Solution

**Work from master node with local API access:**

```bash
# Step 1: Debug into master node
oc debug node/master-0

# Step 2: Use localhost kubeconfig
chroot /host
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Step 3: Now commands work instantly
oc get csr

# Step 4: Approve pending CSRs
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve

# Result: Completed in <1 second
```

### Why This Works

- **localhost.kubeconfig** connects to local API server (bypasses load balancer)
- **Direct connection** avoids network issues
- **Works even when** remote API access is degraded

### When to Use This

- Remote API timeouts
- Load balancer issues
- VIP problems
- Network instability
- Emergency recovery situations

---

## Example 5: Suspicious CSR (Security)

### Scenario
**Situation:** Unknown CSR appears during normal operations  
**Action:** Investigation before approval

### The CSR

```bash
$ oc get csr | grep Pending
csr-x7y2z   1m   kubernetes.io/kube-apiserver-client   system:node:unknown-node   Pending
```

### Investigation Steps

```bash
# Step 1: Check if node exists
$ oc get node unknown-node
Error from server (NotFound): nodes "unknown-node" not found

# RED FLAG: Node doesn't exist!

# Step 2: Check requestor details
$ oc describe csr csr-x7y2z
Requestor: system:node:unknown-node
Username: system:node:unknown-node

# Step 3: View certificate request
$ oc get csr csr-x7y2z -o jsonpath='{.spec.request}' | base64 -d | openssl req -text -noout
Subject: O = system:nodes, CN = system:node:unknown-node

# Step 4: Check cluster events
$ oc get events --all-namespaces | grep -i "unknown-node"
# No events found

# Step 5: Check machines
$ oc get machines -n openshift-machine-api | grep unknown
# Not found
```

### Decision

**DO NOT APPROVE**

This CSR is from an unknown, unexpected node. Could be:
- Misconfigured node trying to join
- Security incident
- Typo in node configuration
- Test node that shouldn't join production

### Actions Taken

```bash
# Deny the CSR
oc adm certificate deny csr-x7y2z

# Delete it
oc delete csr csr-x7y2z

# Investigate source
# - Check DHCP logs
# - Check BMC access logs
# - Verify no unauthorized hardware
```

---

## Example 6: Bulk CSR Approval After Cluster Upgrade

### Scenario
**Situation:** After cluster upgrade, all nodes need new certificates  
**Scale:** 50 nodes (3 masters, 47 workers)

### The Challenge

```bash
$ oc get csr | grep Pending | wc -l
50
```

50 pending CSRs need approval!

### Solution

```bash
# Step 1: Verify this is expected (upgrade in progress)
$ oc get clusterversion
VERSION   AVAILABLE   PROGRESSING   SINCE
4.14.10   True        True          10m

# Step 2: Quick audit of requestors
$ oc get csr -o json | jq -r '.items[] | select(.status == {}) | .spec.username' | sort | uniq -c
  47 system:node:worker-*
   3 system:node:master-*

# Step 3: All requestors are known nodes - bulk approve
$ oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve

certificatesigningrequest.certificates.k8s.io/csr-xxxxx approved
[... 49 more ...]

# Step 4: Verify all approved
$ oc get csr | grep Pending
# None remaining

# Step 5: Check nodes are Ready
$ oc get nodes | grep NotReady
# None
```

### Timing

- **50 CSRs approved in ~10 seconds**
- **All nodes Ready within 2 minutes**
- **Upgrade proceeded successfully**

---

## Example 7: Kubelet Can't Create CSR (No Bootstrap Tokens)

### Scenario
**Situation:** Node kubelet needs new certificate but can't create CSR  
**Issue:** Bootstrap tokens expired/removed

### Problem

```bash
# On the node
$ journalctl -u kubelet | grep -i csr
# No CSR creation attempts

$ journalctl -u kubelet | grep -i certificate
# Certificate errors but no CSR creation

$ oc get csr | grep <node-name>
# No CSRs for this node
```

### Diagnosis

```bash
# Check kubeconfig
$ cat /var/lib/kubelet/kubeconfig | grep -A 3 "user:"
users:
- name: default-auth
  user:
    client-certificate: /var/lib/kubelet/pki/kubelet-client-current.pem
    client-key: /var/lib/kubelet/pki/kubelet-client-current.pem

# Check if certificate exists
$ ls -la /var/lib/kubelet/pki/kubelet-client-current.pem
ls: cannot access '/var/lib/kubelet/pki/kubelet-client-current.pem': No such file or directory

# Check for bootstrap token in kubeconfig
$ grep token /var/lib/kubelet/kubeconfig
# None found

# Check bootstrap tokens in cluster
$ oc get secrets -n kube-system | grep bootstrap-token
# None or expired
```

### Solution (No CSR Involved)

Since CSR creation is impossible without bootstrap tokens:

```bash
# Use alternative authentication
cp /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig \
   /var/lib/kubelet/kubeconfig

systemctl restart kubelet
```

**Result:** ✅ No CSR needed, kubelet uses node's existing auth

---

## Example 8: CSR Approval from Node (API Access Issues)

### Scenario
**Situation:** Workstation can't reach API server, but cluster is running  
**Need:** Approve CSRs for recovering nodes

### From Workstation (Failing)

```bash
$ oc get csr
Unable to connect to the server: http2: client connection lost
```

### From Master Node (Working)

```bash
# Step 1: Access master node
$ oc debug node/master-0
Creating debug namespace/openshift-debug-node-xxxxx ...
Starting pod/master-0-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.x.x.x
If you don't see a command prompt, try pressing enter.

sh-4.4# chroot /host

# Step 2: Use local kubeconfig
sh-4.4# export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Step 3: Check CSRs (works instantly)
sh-4.4# oc get csr
NAME        AGE   SIGNERNAME                                    REQUESTOR              CONDITION
csr-abc     5m    kubernetes.io/kube-apiserver-client-kubelet   system:node:master-1   Pending

# Step 4: Approve
sh-4.4# oc adm certificate approve csr-abc
certificatesigningrequest.certificates.k8s.io/csr-abc approved

# Step 5: Verify
sh-4.4# oc get csr csr-abc
NAME      AGE   SIGNERNAME                                    REQUESTOR              CONDITION
csr-abc   6m    kubernetes.io/kube-apiserver-client-kubelet   system:node:master-1   Approved,Issued
```

**Completion time:** <1 second (vs timing out from workstation)

---

## Example 9: Auto-Approval During Node Scaling

### Scenario
**Situation:** Adding 20 worker nodes via MachineSet  
**Challenge:** Don't want to manually approve 40 CSRs (2 per node)

### Solution: Automated Approval Script

```bash
# Start the auto-approval monitor
./watch-and-approve.sh 15

# Output:
=== CSR Auto-Approval Monitor ===

Settings:
  Check interval: 15s
  Press Ctrl+C to stop

✓ Logged in as: admin
✓ Cluster: https://api.cluster.example.com:6443

[2025-12-03 22:00:00] Cycle 1: No pending CSRs (total approved: 0)
[2025-12-03 22:00:15] Cycle 2: Found 3 pending CSR(s)
  - csr-h7k2m (requestor: system:node:worker-10)
  - csr-j8m3n (requestor: system:node:worker-11)
  - csr-k9n4p (requestor: system:node:worker-12)
  Approving...
  ✓ Approved 3 CSR(s)
  Total approved this session: 3

[... continues for all 20 nodes ...]

[2025-12-03 22:10:00] Cycle 40: No pending CSRs (total approved: 40)

^C
Stopped
```

**Result:** ✅ All 20 nodes joined cluster without manual intervention

---

## Example 10: Investigating Stuck CSR

### Scenario
**Situation:** CSR pending for 30 minutes, not auto-approved  
**Question:** Why isn't it being approved?

### Investigation

```bash
# Step 1: View the CSR
$ oc describe csr csr-stuck123

Name:         csr-stuck123
Labels:       <none>
Annotations:  <none>
API Version:  certificates.k8s.io/v1
Kind:         CertificateSigningRequest
Metadata:
  Creation Timestamp:  2025-12-03T20:30:00Z
  UID:                 xxxxx-xxxxx-xxxxx
Spec:
  Request:     <base64-encoded-csr>
  Signer Name: kubernetes.io/kube-apiserver-client-kubelet
  Usages:
    client auth
  Username:    system:node:worker-8
Status:        <none>    # ← Still pending
Events:        <none>

# Step 2: Check auto-approver
$ oc get pods -n openshift-cluster-machine-approver
NAME                                 READY   STATUS    RESTARTS   AGE
machine-approver-controller-xxxxx    1/1     Running   0          2d

# Step 3: Check auto-approver logs
$ oc logs -n openshift-cluster-machine-approver deployment/machine-approver-controller --tail=50

# Found in logs:
Cannot approve CSR csr-stuck123: node worker-8 not found in machine list

# Step 4: Check machines
$ oc get machine -n openshift-machine-api | grep worker-8
# Not found!

# Step 5: Check if node exists
$ oc get node worker-8
NAME       STATUS   ROLES    AGE   VERSION
worker-8   Ready    worker   5m    v1.29.0
```

### Root Cause

- Node exists and is Ready
- But no corresponding Machine object
- Auto-approver requires Machine object to approve
- Node was manually added (not via Machine API)

### Resolution

```bash
# Manually approve since node is legitimate
oc adm certificate approve csr-stuck123

# For future manual nodes, always approve manually
# Or create corresponding Machine objects
```

---

## Example 11: CSR After Kubelet Certificate Deletion

### Scenario
**Situation:** Manually deleted kubelet certificate to force rotation  
**Goal:** Approve new CSR quickly

### Steps

```bash
# Step 1: On the node - delete certificate
$ systemctl stop kubelet
$ rm -f /var/lib/kubelet/pki/kubelet-client*.pem
$ systemctl start kubelet

# Step 2: Watch kubelet logs for CSR creation
$ journalctl -u kubelet -f | grep -i csr
I1203 22:15:23.123456  12345 certificate_manager.go:456] Requesting client certificate
I1203 22:15:23.234567  12345 certificate_manager.go:789] Created CSR for client certificate

# Step 3: From another terminal - approve immediately
$ oc get csr | grep master-0
csr-newcert   5s   kubernetes.io/kube-apiserver-client-kubelet   system:node:master-0   Pending

$ oc adm certificate approve csr-newcert
certificatesigningrequest.certificates.k8s.io/csr-newcert approved

# Step 4: Verify on node - certificate received
$ ls -la /var/lib/kubelet/pki/kubelet-client-current.pem
... created 10 seconds ago

# Step 5: Verify authentication working
$ journalctl -u kubelet -n 20 | grep -i "success\|certificate"
I1203 22:15:30.123456  12345 certificate_manager.go:234] Certificate rotation succeeded
```

**Total time:** ~10 seconds from deletion to new working certificate

---

## Summary of Patterns

### Pattern 1: Standard CSR Flow
1. Node/component needs certificate
2. Creates CSR
3. CSR appears as Pending
4. Admin or auto-approver approves
5. Certificate issued and used

### Pattern 2: No Bootstrap Tokens
1. Node needs certificate
2. **CSR cannot be created** (no auth)
3. Must use alternative authentication (localhost kubeconfig)
4. Bypass CSR process entirely

### Pattern 3: Remote API Failure
1. CSRs exist but can't be accessed remotely
2. Work from master node
3. Use localhost kubeconfig
4. Approve with fast local API access

### Pattern 4: Auto-Approval Failure
1. CSR pending but not auto-approved
2. Check auto-approver logs
3. Identify why (no Machine object, policy, etc.)
4. Manually approve if legitimate

---

## Quick Command Reference from Examples

### Safe Approval (Recommended)
```bash
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
```

### From Master Node (When Remote Fails)
```bash
oc debug node/master-0
chroot /host
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
```

### Node-Specific
```bash
./approve-by-node.sh master-1
```

### Watch and Auto-Approve
```bash
./watch-and-approve.sh 30
```

---

## Example 12: All Control Plane Nodes NotReady - Circular Dependency Recovery

### Scenario
**Date:** December 8-9, 2025  
**Situation:** All 3 master nodes NotReady after weekend, kubelet authentication broken cluster-wide  
**Challenge:** Circular dependency preventing recovery

### The Problem Chain

```
kubelet needs certificate
    ↓
requires CSR approval + signing
    ↓
requires kube-controller-manager healthy
    ↓
controller-manager degraded due to networking
    ↓
networking requires CNI config
    ↓
CNI config created by ovnkube-node pod
    ↓
ovnkube-node pod requires kubelet working
    ↓
CIRCULAR DEPENDENCY
```

### Initial State

```bash
# All nodes NotReady
$ oc get nodes
NAME       STATUS      ROLES    AGE   VERSION
master-0   NotReady    master   10d   v1.29.0
master-1   NotReady    master   10d   v1.29.0
master-2   NotReady    master   10d   v1.29.0

# Kubelet logs showing authentication failure
$ oc debug node/master-1 -- chroot /host journalctl -u kubelet -n 20
User "system:anonymous" cannot get resource...
http2: client connection lost

# CSRs approved but no certificate issued
$ oc get csr
NAME        AGE   SIGNERNAME                                    REQUESTOR            CONDITION
csr-abc     10m   kubernetes.io/kube-apiserver-client-kubelet   node-bootstrapper    Approved

$ oc get csr csr-abc -o jsonpath='{.status.certificate}'
# Empty - no certificate issued!

# Network operator healthy, but nodes can't use it
$ oc get co network
NAME      VERSION   AVAILABLE   PROGRESSING   DEGRADED
network   4.18.14   True        False         False

# Controller-manager degraded due to networking
$ oc get co kube-controller-manager
NAME                      VERSION   AVAILABLE   PROGRESSING   DEGRADED
kube-controller-manager   4.18.14   True        False         True

# No CNI config on any node
$ oc debug node/master-0 -- chroot /host ls /etc/kubernetes/cni/net.d/
# Only whereabouts.d/ present, no 10-ovn-kubernetes.conf
```

### Root Cause Analysis

**Problem:** Bootstrap secrets missing, certificates expired

```bash
# Bootstrap kubeconfig missing
$ oc debug node/master-0 -- chroot /host ls /etc/kubernetes/bootstrap-secrets/
ls: cannot access '/etc/kubernetes/bootstrap-secrets/': No such file or directory

# Kubelet certificates expired
$ oc debug node/master-0 -- chroot /host openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -enddate
notAfter=Dec 5 18:00:00 2025 GMT  # Expired!

# CSRs approved but controller-manager can't sign due to network degradation
```

### Why Simple Fixes Don't Work

**Attempted: Delete certificates and restart kubelet**
```bash
systemctl stop kubelet
rm -f /var/lib/kubelet/pki/kubelet-client*.pem
systemctl start kubelet
```
**Result:** ❌ Kubelet can't create CSR without bootstrap tokens (no authentication)

**Attempted: Approve CSRs multiple times**
```bash
oc adm certificate approve csr-abc
```
**Result:** ❌ Controller-manager can't sign certificates due to networking degradation

**Attempted: Reboot without prep**
```bash
systemctl reboot
```
**Result:** ❌ Same problem after reboot (no bootstrap secrets, expired cert)

### The Solution: localhost.kubeconfig Bootstrap

Used localhost.kubeconfig as emergency bootstrap credential to break the cycle.

#### Step 1: Backup Everything (master-0)

```bash
oc debug node/master-0
chroot /host

# Create timestamped backup
BACKUP_DIR="/root/kubelet-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup configurations
cp -a /var/lib/kubelet/kubeconfig $BACKUP_DIR/kubeconfig.original
cp -a /var/lib/kubelet/config.yaml $BACKUP_DIR/config.yaml.original
cp -a /var/lib/kubelet/pki/ $BACKUP_DIR/pki-original/

# Document state
systemctl status kubelet > $BACKUP_DIR/kubelet-status-before.txt
journalctl -u kubelet -n 100 > $BACKUP_DIR/kubelet-logs-before.txt
crictl pods > $BACKUP_DIR/crictl-pods-before.txt
```

#### Step 2: Apply localhost.kubeconfig

```bash
# Stop kubelet
systemctl stop kubelet

# Apply localhost.kubeconfig (uses static pod credentials)
cp /var/lib/kubelet/kubeconfig /var/lib/kubelet/kubeconfig.expired-$(date +%Y%m%d)
cp /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig \
   /var/lib/kubelet/kubeconfig

# Delete expired certificates
rm -f /var/lib/kubelet/pki/kubelet-client*.pem

# Start kubelet
systemctl start kubelet

# Monitor
journalctl -u kubelet -f
```

#### Step 3: Verify Recovery (master-0)

```bash
# After 2-3 minutes, check node status
$ oc get node master-0
NAME       STATUS   ROLES    AGE   VERSION
master-0   Ready    master   10d   v1.29.0  # ✅ Ready!

# Check CNI config created
$ ls -la /etc/kubernetes/cni/net.d/
-rw-r--r--. 1 root root  242 Dec  9 15:30 10-ovn-kubernetes.conf  # ✅ Created!

# Check OVN pods running
$ oc get pods -n openshift-ovn-kubernetes -o wide | grep master-0
ovnkube-node-abc    5/5   Running   master-0  # ✅ Running!

# Initial "no sandbox for pod" errors are normal (stale pod cleanup)
$ journalctl -u kubelet -n 20 | grep "no sandbox"
# These will clear after a few minutes
```

#### Step 4: Sequential Recovery of Other Nodes

**Important:** Never reboot all control plane nodes simultaneously!

**Order:** master-0 → master-2 → master-1 (most problematic last)

```bash
# Repeat for master-2
oc debug node/master-2
chroot /host
# [Same backup and localhost.kubeconfig procedure]

# Wait for master-2 Ready, then master-1
oc debug node/master-1
chroot /host
# [Same backup and localhost.kubeconfig procedure]
```

#### Step 5: Verify Cluster Health

```bash
# All nodes Ready
$ oc get nodes
NAME       STATUS   ROLES    AGE   VERSION
master-0   Ready    master   10d   v1.29.0
master-1   Ready    master   10d   v1.29.0
master-2   Ready    master   10d   v1.29.0

# Cluster operators healthy
$ oc get co
NAME                      VERSION   AVAILABLE   PROGRESSING   DEGRADED
kube-controller-manager   4.18.14   True        False         False
network                   4.18.14   True        False         False
# ... all healthy

# CNI present on all nodes
$ for node in master-0 master-1 master-2; do
    echo "=== $node ==="
    oc debug node/$node -- chroot /host ls /etc/kubernetes/cni/net.d/
done
# All show 10-ovn-kubernetes.conf
```

### Timeline

- **T+0:** Discovered all nodes NotReady, system:anonymous errors
- **T+15min:** Identified circular dependency, approved CSRs not issuing certificates
- **T+30min:** Confirmed bootstrap secrets missing, controller-manager degraded
- **T+45min:** Applied localhost.kubeconfig to master-0
- **T+48min:** master-0 Ready, CNI created
- **T+55min:** Applied to master-2
- **T+58min:** master-2 Ready
- **T+65min:** Applied to master-1
- **T+68min:** master-1 Ready
- **T+75min:** All cluster operators healthy ✅

### Key Lessons

#### 1. Approved CSR ≠ Issued Certificate

CSRs can be approved but not signed if controller-manager is unhealthy:

```bash
# Check if certificate was actually issued
oc get csr <csr-name> -o jsonpath='{.status.certificate}' | base64 -d

# Empty output = approved but not signed
# Certificate content = fully processed
```

#### 2. localhost.kubeconfig Has Limitations

**Pros:**
- ✅ Bypasses CSR/bootstrap token requirement
- ✅ Uses existing static pod credentials
- ✅ Works when bootstrap secrets missing

**Cons:**
- ⚠️ Not intended for kubelet node authentication
- ⚠️ May have RBAC quirks for some operations
- ⚠️ Should be temporary solution

**Proper Fix Later:** Restore bootstrap tokens or certificate rotation

#### 3. Network Operator Healthy ≠ Networking Works

Network operator can be Available=True while nodes can't use networking:
- Operator is healthy and ready
- But CNI config not deployed (no pods running)
- Requires working kubelet to deploy CNI

#### 4. Controller-Manager Can Be Degraded Without Being Unavailable

```bash
$ oc get co kube-controller-manager
AVAILABLE   PROGRESSING   DEGRADED
True        False         True      # ← Can be Available + Degraded
```

Degraded controllers may still function for some operations (like pod management) but fail others (like CSR signing).

#### 5. Control Plane Recovery Order Matters

**Best Practice:**
1. Start with most stable node (usually master-0)
2. Verify successful before proceeding
3. End with most problematic node
4. **Never reboot all masters simultaneously** (lose quorum)

#### 6. Container/Kubelet Desync Common After Auth Failures

```bash
# Kubernetes API shows pods
$ oc get pods -n openshift-etcd
installer-1-master-1   Pending

# But crictl shows nothing
$ crictl pods | grep installer
# Empty

# Solution: Kubelet restart usually resolves after auth fixed
```

### Prevention

**To avoid this scenario:**

1. **Monitor certificate expiration:**
```bash
# Check kubelet cert expiry on all nodes
for node in master-{0..2}; do
  oc debug node/$node -- chroot /host openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -enddate
done
```

2. **Verify certificate rotation enabled:**
```bash
oc debug node/master-0 -- chroot /host grep rotateCertificates /var/lib/kubelet/config.yaml
# Should show: rotateCertificates: true
```

3. **Monitor controller-manager health:**
```bash
watch oc get co kube-controller-manager
```

4. **Check CSR approval/signing working:**
```bash
# Periodically verify CSRs are being signed
oc get csr | grep -v "Approved,Issued"
```

### Revert Procedure (If Needed)

If localhost.kubeconfig causes issues:

```bash
# Stop kubelet
systemctl stop kubelet

# Restore from backup
BACKUP_DIR="/root/kubelet-backup-YYYYMMDD-HHMMSS"
cp $BACKUP_DIR/kubeconfig.original /var/lib/kubelet/kubeconfig
cp -a $BACKUP_DIR/pki-original/* /var/lib/kubelet/pki/

# Start kubelet
systemctl start kubelet
```

---

## Example 13: CSR Approval Hanging From Bastion

### Scenario
**Situation:** CSRs pending but `oc adm certificate approve` hangs/times out from bastion  
**Related:** master-1 has authentication issues, network instability

### Problem

```bash
# From bastion
$ oc get csr
# Works fine

$ oc adm certificate approve csr-abc
# Hangs for 2+ minutes, then:
Unable to connect to the server: http2: client connection lost
```

### Solution: Work From Master Node

```bash
# Debug into master-0 (or any healthy master)
oc debug node/master-0
chroot /host

# Use localhost kubeconfig (fast local API access)
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Now commands are instant
oc get csr
oc adm certificate approve csr-abc

# Completes in <1 second
```

### Why This Works

- localhost.kubeconfig connects to 127.0.0.1:6443 (local API server)
- Bypasses load balancer/VIP/network issues
- Direct connection to API server on same node
- Always available even during network instability

### When To Use

- Remote API timeouts
- Load balancer issues
- VIP connectivity problems
- Network instability
- Emergency recovery

---

**These examples are from actual troubleshooting sessions and represent real scenarios you may encounter.**






# kube-controller-manager Crash Loop - Troubleshooting Flowchart

## Visual Decision Tree

```
START: kube-controller-manager Pod Crash Loop
│
├─[1] Check if other control plane components are healthy
│     │
│     ├─── etcd pods not Running?
│     │    └──> FIX etcd FIRST, then return here
│     │
│     ├─── API server pods not Running?
│     │    └──> FIX API server FIRST, then return here
│     │
│     └─── Both healthy? → Continue to [2]
│
├─[2] Collect logs from controller manager
│     │
│     │   COMMAND: oc logs -n openshift-kube-controller-manager 
│     │            -l app=kube-controller-manager --previous
│     │
│     └──> Analyze logs → Go to [3]
│
├─[3] Identify error pattern in logs
│     │
│     ├─── Contains "x509" or "certificate" or "TLS"?
│     │    └──> GO TO [4A] Certificate Issues
│     │
│     ├─── Contains "connection refused" or "dial tcp" or "timeout"?
│     │    └──> GO TO [4B] Connectivity Issues
│     │
│     ├─── Contains "OOM" or "killed" or pod shows OOMKilled?
│     │    └──> GO TO [4C] Resource Issues
│     │
│     ├─── Contains "invalid" or "parse error" or "failed to load config"?
│     │    └──> GO TO [4D] Configuration Issues
│     │
│     ├─── Contains "etcd" or "context deadline exceeded"?
│     │    └──> GO TO [4E] Storage/etcd Issues
│     │
│     ├─── Contains webhook names or "admission webhook"?
│     │    └──> GO TO [4F] Webhook Issues
│     │
│     └─── No clear pattern?
│          └──> GO TO [5] Advanced Diagnostics
│
│
├─[4A] Certificate Issues
│     │
│     ├── DIAGNOSE:
│     │   $ oc get secrets -n openshift-kube-controller-manager
│     │   $ oc get secret kube-controller-manager-client-cert-key \
│     │       -n openshift-kube-controller-manager \
│     │       -o jsonpath='{.data.tls\.crt}' | base64 -d | \
│     │       openssl x509 -dates -noout
│     │
│     ├── FIX:
│     │   $ oc delete secret kube-controller-manager-client-cert-key \
│     │       -n openshift-kube-controller-manager
│     │
│     └── VERIFY:
│         $ watch oc get pods -n openshift-kube-controller-manager
│         Wait 2-5 minutes for automatic certificate regeneration
│         │
│         ├─── Fixed? → GO TO [6] Verification
│         └─── Still failing? → GO TO [5] Advanced Diagnostics
│
│
├─[4B] Connectivity Issues
│     │
│     ├── DIAGNOSE:
│     │   $ oc get pods -n openshift-kube-apiserver
│     │   $ oc get endpoints kubernetes -n default
│     │   $ oc get nodes
│     │
│     ├── CHECK:
│     │   ├─── API server pods not Running? → Fix API server first
│     │   ├─── Endpoints empty? → Check API server service
│     │   ├─── Network policy blocking? → Review network policies
│     │   └─── Firewall/routing issue? → Check infrastructure
│     │
│     └── VERIFY:
│         Test connectivity from controller manager pod to API server
│         │
│         ├─── Fixed? → GO TO [6] Verification
│         └─── Still failing? → GO TO [5] Advanced Diagnostics
│
│
├─[4C] Resource Issues  
│     │
│     ├── DIAGNOSE:
│     │   $ oc adm top nodes
│     │   $ oc describe pod -n openshift-kube-controller-manager \
│     │       -l app=kube-controller-manager | grep -A 5 "Last State"
│     │
│     ├── CHECK:
│     │   ├─── OOMKilled?
│     │   │    ├─ Master node memory exhausted?
│     │   │    │  └─> Need to scale master nodes (infrastructure change)
│     │   │    └─ Memory leak?
│     │   │       └─> Check for unusual resource consumption
│     │   │
│     │   ├─── CPU throttling?
│     │   │    └─> Check CPU limits and node capacity
│     │   │
│     │   └─── Disk pressure?
│     │        └─> Free up disk space on master nodes
│     │
│     └── ACTION:
│         Resource issues often require infrastructure-level fixes
│         Consider:
│         - Scaling master nodes
│         - Increasing node resources
│         - Investigating resource leaks
│         │
│         └── GO TO [6] Verification after changes
│
│
├─[4D] Configuration Issues
│     │
│     ├── DIAGNOSE:
│     │   $ oc get kubecontrollermanager cluster -o yaml
│     │   $ oc get co kube-controller-manager -o yaml
│     │
│     ├── CHECK:
│     │   ├─── Recent configuration changes?
│     │   │    └─> Review and revert if needed
│     │   │
│     │   ├─── Invalid field values?
│     │   │    └─> Correct or remove invalid fields
│     │   │
│     │   └─── Unsupported configuration?
│     │        └─> Check OpenShift version compatibility
│     │
│     ├── FIX:
│     │   $ oc patch kubecontrollermanager cluster --type=json \
│     │       -p='[{"op": "remove", "path": "/spec/problematicField"}]'
│     │   
│     │   OR restore from backup if available
│     │
│     └── VERIFY:
│         $ watch oc get co kube-controller-manager
│         │
│         ├─── Fixed? → GO TO [6] Verification
│         └─── Still failing? → GO TO [5] Advanced Diagnostics
│
│
├─[4E] Storage/etcd Issues
│     │
│     ├── DIAGNOSE:
│     │   $ oc get pods -n openshift-etcd
│     │   $ oc get etcd -o=jsonpath='{range .items[0].status.conditions[?(@.type=="EtcdMembersAvailable")]}{.status}{"\n"}'
│     │
│     ├── CHECK:
│     │   ├─── etcd pods not healthy?
│     │   │    └─> FIX etcd FIRST (see etcd troubleshooting guide)
│     │   │
│     │   ├─── High latency to etcd?
│     │   │    └─> Check etcd performance metrics
│     │   │        - Disk I/O
│     │   │        - Network latency
│     │   │        - etcd member sync issues
│     │   │
│     │   └─── etcd disk full?
│     │        └─> Free up space, compact etcd
│     │
│     └── ACTION:
│         etcd must be fixed before controller manager will work
│         │
│         └── Return to [1] after fixing etcd
│
│
├─[4F] Webhook Issues
│     │
│     ├── DIAGNOSE:
│     │   $ oc get validatingwebhookconfigurations
│     │   $ oc get mutatingwebhookconfigurations
│     │   
│     │   Identify webhook from error message in logs
│     │
│     ├── CHECK:
│     │   $ oc get validatingwebhookconfiguration <name> -o yaml
│     │   
│     │   Verify webhook service exists and is healthy
│     │
│     ├── FIX (EMERGENCY ONLY):
│     │   $ oc delete validatingwebhookconfiguration <webhook-name>
│     │   
│     │   WARNING: Only for emergency recovery
│     │   Investigate and fix the actual webhook service
│     │
│     └── VERIFY:
│         $ watch oc get pods -n openshift-kube-controller-manager
│         │
│         ├─── Fixed? → GO TO [6] Verification
│         └─── Still failing? → GO TO [5] Advanced Diagnostics
│
│
├─[5] Advanced Diagnostics / Emergency Recovery
│     │
│     ├── COLLECT MORE DATA:
│     │   $ oc adm must-gather
│     │   $ oc adm inspect namespace/openshift-kube-controller-manager
│     │
│     ├── TRY FORCE REGENERATION (SSH to master node):
│     │   $ oc debug node/<master-node>
│     │   # chroot /host
│     │   # mv /etc/kubernetes/manifests/kube-controller-manager-pod.yaml /root/
│     │   (wait 30 seconds)
│     │   # mv /root/kube-controller-manager-pod.yaml /etc/kubernetes/manifests/
│     │
│     ├── CHECK SYSTEM LEVEL ISSUES:
│     │   - Disk space on master nodes
│     │   - System load/memory
│     │   - Network connectivity between masters
│     │   - Time synchronization (NTP)
│     │
│     └── ESCALATION:
│         If issue persists after all troubleshooting steps:
│         │
│         ├─── Collect diagnostics bundle
│         ├─── Document all steps taken
│         ├─── Open Red Hat support case
│         └─── Include must-gather output
│
│
└─[6] VERIFICATION
      │
      ├── CHECK POD STATUS:
      │   $ oc get pods -n openshift-kube-controller-manager
      │   
      │   Pods should be Running with low/stable restart count
      │
      ├── CHECK OPERATOR STATUS:
      │   $ oc get co kube-controller-manager
      │   
      │   Should show:
      │   - AVAILABLE: True
      │   - PROGRESSING: False
      │   - DEGRADED: False
      │
      ├── MONITOR FOR STABILITY:
      │   $ watch oc get pods -n openshift-kube-controller-manager
      │   
      │   Monitor for 10+ minutes with no restarts
      │
      ├── TEST CLUSTER FUNCTIONALITY:
      │   $ oc create deployment test-nginx --image=nginx
      │   $ oc get deployments
      │   $ oc delete deployment test-nginx
      │   
      │   Basic cluster operations should work
      │
      └── SUCCESS!
          Document what fixed the issue for future reference
```

## Quick Reference Table

| Symptom | Most Likely Cause | First Action | Path |
|---------|------------------|--------------|------|
| "x509" or "certificate" in logs | Certificate expired/invalid | Delete certificate secret | [4A] |
| "connection refused" | API server unreachable | Check API server health | [4B] |
| OOMKilled in pod status | Memory exhaustion | Check node resources | [4C] |
| "invalid configuration" | Config error | Review configuration | [4D] |
| "etcd" or "deadline exceeded" | etcd issues | Check etcd health | [4E] |
| Webhook timeout | Webhook unavailable | Check webhook service | [4F] |
| No clear pattern | Multiple issues | Collect must-gather | [5] |

## Time-Based Troubleshooting

### First 5 Minutes
1. Check control plane pod status ([1])
2. Get previous pod logs ([2])
3. Identify error pattern ([3])

### 5-15 Minutes
4. Follow specific path based on error pattern ([4A-4F])
5. Apply initial fix
6. Monitor for recovery

### 15-30 Minutes
7. If not recovered, try advanced diagnostics ([5])
8. Collect comprehensive data
9. Consider emergency procedures

### 30+ Minutes
10. Prepare for escalation
11. Collect must-gather
12. Open support case with all data

## Common Gotchas

1. **Fixing symptoms, not root cause**
   - Always identify why the issue occurred
   - Example: Certificate expired → Why didn't it auto-rotate?

2. **Ignoring dependencies**
   - Controller manager depends on API server depends on etcd
   - Fix from the bottom up

3. **Not waiting for recovery**
   - Certificate regeneration takes 2-5 minutes
   - Operator reconciliation takes time

4. **Making multiple changes at once**
   - Change one thing at a time
   - Verify after each change

5. **Not checking recent changes**
   - Many issues follow configuration changes
   - Check cluster version history

## Success Criteria

✅ **Resolved** when ALL of these are true:
- Pods Running for 10+ minutes with no restarts
- Cluster operator shows Available=True, Degraded=False
- No errors in recent logs
- Basic cluster operations work (create/delete deployments)
- No new crash loops appear

❌ **Not Resolved** if ANY of these are true:
- Pods still crash looping
- Operator shows Degraded=True
- Errors still appearing in logs
- Basic operations fail
- Issue returns after apparent fix


# Quick Reference: API Slowness and Web Console Performance

Fast diagnostic commands and decision tree for OpenShift API/web console slowness issues.

## 🚨 Emergency First Steps (2 Minutes)

```bash
# 1. Measure the problem
time oc get nodes

# 2. Check critical components
oc get co kube-apiserver etcd

# 3. Check for obvious issues
oc get pods -n openshift-kube-apiserver
oc get pods -n openshift-etcd

# 4. Check master node resources
oc adm top nodes -l node-role.kubernetes.io/master=
```

## Quick Decision Tree

```
API/Console Slow?
│
├─ Step 1: Test API Response Time
│  └─ time oc get nodes
│     ├─ <1s → OK, might be console-specific
│     ├─ 1-3s → Degraded, investigate further
│     └─ >3s → Critical, proceed to Step 2
│
├─ Step 2: Check etcd (most common cause)
│  └─ oc get co etcd && oc get pods -n openshift-etcd
│     ├─ Degraded/Not Ready → Fix etcd first
│     └─ Available/Ready → Check Step 3
│
├─ Step 3: Check API Server
│  └─ oc get co kube-apiserver && oc get pods -n openshift-kube-apiserver
│     ├─ Degraded/Pods restarting → Check API server logs
│     └─ Available/Pods stable → Check Step 4
│
├─ Step 4: Check Resources
│  └─ oc adm top nodes -l node-role.kubernetes.io/master=
│     ├─ CPU/Memory >80% → Resource constraints
│     └─ Resources OK → Check Step 5
│
└─ Step 5: Check Object Count
   └─ oc get pods -A --no-headers | wc -l
      ├─ >5000 pods → Too many objects
      └─ <5000 pods → Check advanced diagnostics
```

## Fast Diagnostic Commands

### Measure Performance

```bash
# API response time baseline
time oc get nodes
time oc get pods -A --limit=100
time oc get --raw /api/v1/namespaces

# Expected times (normal cluster):
# oc get nodes: <500ms
# oc get pods: <1s
# API raw call: <200ms
```

### Check Health

```bash
# Overall health
oc get co | grep -E 'kube-apiserver|etcd|authentication|console'

# Critical pods
oc get pods -n openshift-kube-apiserver
oc get pods -n openshift-etcd
oc get pods -n openshift-console

# Quick health check
oc get --raw /healthz && echo "API: OK"
```

### Check Resources

```bash
# Master node resources
oc adm top nodes -l node-role.kubernetes.io/master=

# API server pods
oc adm top pods -n openshift-kube-apiserver

# etcd pods
oc adm top pods -n openshift-etcd

# If metrics not available
oc describe nodes -l node-role.kubernetes.io/master= | grep -A 5 "Allocated resources"
```

### Check Logs for Errors

```bash
# API server errors (last 50 lines)
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=50 | grep -i "error\|timeout\|slow"

# etcd errors
oc logs -n openshift-etcd -l app=etcd --tail=50 | grep -i "error\|timeout\|slow\|latency"

# Console errors (if console-specific)
oc logs -n openshift-console -l app=console --tail=50 | grep -i "error\|timeout"
```

### Check Object Counts

```bash
# Quick count
echo "Pods: $(oc get pods -A --no-headers 2>/dev/null | wc -l)"
echo "Events: $(oc get events -A --no-headers 2>/dev/null | wc -l)"
echo "CSRs: $(oc get csr --no-headers 2>/dev/null | wc -l)"

# Red flags:
# - Events >50,000
# - Pending CSRs >100
# - Completed pods >500
```

## Common Quick Fixes

### Fix #1: Approve Pending CSRs

```bash
# Check for pending CSRs
PENDING=$(oc get csr 2>/dev/null | grep -c Pending)
echo "Pending CSRs: $PENDING"

# If >50, approve them
if [ "$PENDING" -gt 50 ]; then
  oc get csr -o name | xargs oc adm certificate approve
fi
```

### Fix #2: Clean Up Completed Pods

```bash
# Count completed pods
COMPLETED=$(oc get pods -A --field-selector=status.phase=Succeeded 2>/dev/null | wc -l)
FAILED=$(oc get pods -A --field-selector=status.phase=Failed 2>/dev/null | wc -l)

echo "Completed: $COMPLETED, Failed: $FAILED"

# Clean up if >100 combined
if [ $((COMPLETED + FAILED)) -gt 100 ]; then
  oc delete pods -A --field-selector=status.phase=Succeeded
  oc delete pods -A --field-selector=status.phase=Failed
fi
```

### Fix #3: Restart Console Pods

```bash
# If CLI is responsive but console is slow
oc delete pods -n openshift-console -l app=console
oc delete pods -n openshift-console-operator -l app=console-operator

# Wait for restart
oc wait --for=condition=Ready -n openshift-console pod -l app=console --timeout=60s
```

### Fix #4: Restart API Server Pods

```bash
# Force API server pod restart (they'll be recreated)
oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver

# Monitor restart
watch oc get pods -n openshift-kube-apiserver
```

## etcd Quick Checks

```bash
# etcd health
oc get co etcd

# etcd pods
oc get pods -n openshift-etcd

# etcd database size (warning if >8GB)
oc exec -n openshift-etcd \
  $(oc get pods -n openshift-etcd -l app=etcd -o jsonpath='{.items[0].metadata.name}') -- \
  du -sh /var/lib/etcd

# etcd member health (complex command, use carefully)
ETCD_POD=$(oc get pods -n openshift-etcd -l app=etcd -o jsonpath='{.items[0].metadata.name}')
oc exec -n openshift-etcd $ETCD_POD -- etcdctl endpoint health \
  --cluster \
  --cacert=/etc/kubernetes/static-pod-certs/configmaps/etcd-serving-ca/ca-bundle.crt \
  --cert=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-$(echo $ETCD_POD | cut -d- -f2-).crt \
  --key=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-$(echo $ETCD_POD | cut -d- -f2-).key
```

## Network Quick Checks

```bash
# Test API connectivity
time curl -k "$(oc whoami --show-server)/healthz"

# Check API endpoints
oc get endpoints kubernetes -n default

# Test DNS resolution
oc run test-dns --image=registry.access.redhat.com/ubi9/ubi:latest --rm -it --restart=Never -- nslookup kubernetes.default.svc

# Test from pod to API
oc run test-api --image=registry.access.redhat.com/ubi9/ubi:latest --rm -it --restart=Never -- curl -k https://kubernetes.default.svc:443/healthz
```

## Resource Quick Checks

```bash
# Master node disk space
for node in $(oc get nodes -l node-role.kubernetes.io/master= -o name); do
  echo "=== $node ==="
  oc debug $node -- chroot /host df -h | grep -E "Filesystem|/var"
done

# Check for disk pressure
oc get nodes -l node-role.kubernetes.io/master= -o json | \
  jq -r '.items[] | "\(.metadata.name): \(.status.conditions[] | select(.type=="DiskPressure") | .status)"'

# Check for memory pressure
oc get nodes -l node-role.kubernetes.io/master= -o json | \
  jq -r '.items[] | "\(.metadata.name): \(.status.conditions[] | select(.type=="MemoryPressure") | .status)"'
```

## Webhook Quick Checks

```bash
# List all webhooks
echo "=== Validating Webhooks ==="
oc get validatingwebhookconfigurations --no-headers | wc -l

echo "=== Mutating Webhooks ==="
oc get mutatingwebhookconfigurations --no-headers | wc -l

# Check for webhook timeouts in logs
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=100 | \
  grep -i "webhook.*timeout"
```

## Monitoring Script (Copy & Run)

```bash
#!/bin/bash
# Save as: quick-api-check.sh

echo "=== OpenShift API Health Check $(date) ==="

echo -e "\n[1/8] API Response Time"
START=$(date +%s%N)
oc get nodes >/dev/null 2>&1
END=$(date +%s%N)
DURATION=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
echo "→ ${DURATION}s (target: <1s)"
[ $(echo "$DURATION > 1" | bc) -eq 1 ] && echo "⚠️  SLOW!" || echo "✓ OK"

echo -e "\n[2/8] Cluster Operators"
DEGRADED=$(oc get co 2>/dev/null | grep -c "False.*True")
echo "→ Degraded operators: $DEGRADED"
[ $DEGRADED -gt 0 ] && oc get co | grep "False.*True" || echo "✓ All available"

echo -e "\n[3/8] API Server Pods"
NOT_READY=$(oc get pods -n openshift-kube-apiserver 2>/dev/null | grep -cv "Running")
echo "→ Not ready: $NOT_READY"
[ $NOT_READY -gt 1 ] && echo "⚠️  ISSUE!" || echo "✓ OK"

echo -e "\n[4/8] etcd Pods"
ETCD_NOT_READY=$(oc get pods -n openshift-etcd 2>/dev/null | grep -cv "Running")
echo "→ Not ready: $ETCD_NOT_READY"
[ $ETCD_NOT_READY -gt 1 ] && echo "⚠️  ISSUE!" || echo "✓ OK"

echo -e "\n[5/8] Master Node Resources"
oc adm top nodes -l node-role.kubernetes.io/master= 2>/dev/null || echo "Metrics not available"

echo -e "\n[6/8] Object Counts"
PODS=$(oc get pods -A --no-headers 2>/dev/null | wc -l)
EVENTS=$(oc get events -A --no-headers 2>/dev/null | wc -l)
CSRS=$(oc get csr 2>/dev/null | grep -c Pending)
echo "→ Pods: $PODS | Events: $EVENTS | Pending CSRs: $CSRS"
[ $EVENTS -gt 50000 ] && echo "⚠️  Too many events!"
[ $CSRS -gt 50 ] && echo "⚠️  Too many pending CSRs!"

echo -e "\n[7/8] Recent Errors in API Server Logs"
ERRORS=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=100 2>/dev/null | grep -ci error)
echo "→ Error count (last 100 lines): $ERRORS"
[ $ERRORS -gt 10 ] && echo "⚠️  High error rate!" || echo "✓ OK"

echo -e "\n[8/8] etcd Database Size"
ETCD_POD=$(oc get pods -n openshift-etcd -l app=etcd -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$ETCD_POD" ]; then
  SIZE=$(oc exec -n openshift-etcd $ETCD_POD 2>/dev/null -- du -sh /var/lib/etcd 2>/dev/null | cut -f1)
  echo "→ etcd size: $SIZE"
else
  echo "→ Unable to check etcd size"
fi

echo -e "\n=== Summary ==="
if [ $(echo "$DURATION > 2" | bc) -eq 1 ] || [ $DEGRADED -gt 0 ] || [ $NOT_READY -gt 1 ] || [ $ETCD_NOT_READY -gt 1 ]; then
  echo "❌ Issues detected - review warnings above"
  echo "→ Run: ./diagnostic-script.sh for detailed analysis"
else
  echo "✓ No major issues detected"
fi
```

## One-Liner Health Check

```bash
# Super quick health check
echo "API: $(time oc get nodes 2>&1 | grep real | awk '{print $2}') | CO: $(oc get co 2>/dev/null | grep -c 'True.*False.*False') OK / $(oc get co --no-headers 2>/dev/null | wc -l) total | CPU: $(oc adm top nodes -l node-role.kubernetes.io/master= --no-headers 2>/dev/null | awk '{sum+=$3} END {print sum"%"}')"
```

## When to Use Full Diagnostics

Run the full diagnostic script (`./diagnostic-script.sh`) if:

- API response time consistently >2s
- Multiple cluster operators degraded
- Resource usage >80% on masters
- Error logs showing persistent issues
- Quick fixes don't improve performance

## Escalation Decision

Open support case if:

- API response time >5s after fixes
- etcd degraded with no clear cause
- Multiple control plane components failing
- Production impact >1 hour
- Data loss risk

**Before escalating, collect:**
```bash
oc adm must-gather
oc adm inspect namespace/openshift-kube-apiserver
oc adm inspect namespace/openshift-etcd
```

## Specific Error: "Service Account Token Has Expired"

If seeing many of these errors in API server logs:

```bash
# Quick diagnostic
./diagnose-token-expiry.sh

# Count errors
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=1000 | \
  grep -c "service account token has expired"

# Identify affected pods
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=2000 | \
  grep "service account token has expired" | \
  grep -oP 'system:serviceaccount:\K[^"]+' | sort | uniq -c | sort -rn | head -5

# Quick fixes
# 1. Check time sync
for node in $(oc get nodes -o name); do
  echo "${node#node/}: $(oc debug $node -- chroot /host date 2>/dev/null | tail -1)"
done

# 2. Restart affected pods
oc delete pod -n <namespace> <pod-name>

# 3. If widespread, regenerate service CA
oc delete secret -n openshift-service-ca signing-key
```

**See detailed guide:** [SERVICE-ACCOUNT-TOKEN-EXPIRY.md](SERVICE-ACCOUNT-TOKEN-EXPIRY.md)

---

## Specific Error: "Client-Side Throttling"

If seeing throttling delays like "5.25s due to client-side throttling":

```bash
# Quick diagnostic
./diagnose-client-throttling.sh

# Count throttling events
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep -c "client-side throttling"

# Find throttled clients
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep "client-side throttling" | \
  grep -oP 'user="[^"]+' | sed 's/user="//' | \
  sort | uniq -c | sort -rn | head -5

# Quick checks for common causes
# 1. High tokenreview volume?
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep -c "tokenreviews"

# 2. Too many webhooks?
echo "Webhooks: $(( $(oc get validatingwebhookconfigurations --no-headers | wc -l) + $(oc get mutatingwebhookconfigurations --no-headers | wc -l) ))"

# 3. Crashlooping pods amplifying issue?
oc get pods -A | grep -c CrashLoopBackOff

# Quick fixes
# 1. Fix crashloops (reduces churn)
./scale-down-crashloops.sh

# 2. Restart problematic operator/controller
# (Use service account from throttled clients list)
oc get pods -A --field-selector spec.serviceAccountName=<sa-name>
oc delete pod -n <namespace> <pod-name>

# 3. Check and optimize webhook timeouts
oc get validatingwebhookconfigurations -o json | \
  jq -r '.items[] | .webhooks[] | "\(.name) timeout: \(.timeoutSeconds)s"'
```

**See detailed guide:** [CLIENT-SIDE-THROTTLING.md](CLIENT-SIDE-THROTTLING.md)

---

## Related Guides

- [Service Account Token Expiry](SERVICE-ACCOUNT-TOKEN-EXPIRY.md) - Detailed token expiry troubleshooting
- [Main Guide](README.md) - Complete troubleshooting procedures
- [Index](INDEX.md) - Guide navigation
- [Control Plane Kubeconfigs](../control-plane-kubeconfigs/README.md)
- [kube-controller-manager Issues](../kube-controller-manager-crashloop/README.md)

## Tips for Faster Diagnosis

1. **Always measure first**: Use `time` with commands to quantify slowness
2. **Check etcd first**: It's the most common bottleneck
3. **Monitor during testing**: Use `watch` to see real-time changes
4. **Compare before/after**: Baseline metrics help prove improvement
5. **One change at a time**: Apply fixes sequentially to identify what works
6. **Document findings**: Note what you see for pattern recognition

## Copy-Paste Commands for Common Scenarios

### Scenario 1: Console Slow but CLI Works

```bash
# Console-specific issue
oc get pods -n openshift-console
oc logs -n openshift-console -l app=console --tail=50
oc delete pods -n openshift-console -l app=console
# Test: Open console in browser
```

### Scenario 2: Everything Slow

```bash
# Likely etcd or API server issue
oc get co etcd kube-apiserver
oc adm top nodes -l node-role.kubernetes.io/master=
oc logs -n openshift-etcd -l app=etcd --tail=50 | grep -i "slow\|latency"
# Proceed to main guide
```

### Scenario 3: Intermittent Slowness

```bash
# Network or resource spikes
watch -n 5 'time oc get nodes'
oc adm top nodes -l node-role.kubernetes.io/master=
oc get events -A --sort-by='.lastTimestamp' | tail -20
# Monitor for patterns
```

### Scenario 4: Slow After Cluster Changes

```bash
# Check recent changes
oc get clusterversion -o yaml | grep -A 10 history
oc get events -A --sort-by='.lastTimestamp' | tail -50
# Review what changed
```


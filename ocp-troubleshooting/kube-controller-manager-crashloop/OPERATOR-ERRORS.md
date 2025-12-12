# kube-controller-manager-operator Error Analysis

## Scenario: Operator Errors (Not Controller Manager Crashes)

This document addresses errors from the kube-controller-manager-**operator** itself, which is different from the kube-controller-manager crashing.

## Common Operator Errors

### 1. Resource Conflict Error

**Error Message:**
```
E1202 20:06:21.832634       1 base_controller.go:279] "Unhandled Error" 
err="StatusSyncer_kube-controller-manager reconciliation failed: 
Operation cannot be fulfilled on clusteroperators.config.openshift.io \"kube-controller-manager\": 
the object has been modified; please apply your changes to the latest version and try again"
```

**Severity:** LOW - Usually self-healing

**Root Cause:**
- Multiple controllers attempting to update the ClusterOperator status simultaneously
- Kubernetes optimistic concurrency control at work
- Common in operators that frequently update status

**When to Worry:**
- ❌ **Don't worry if:** Occurs occasionally (every few hours)
- ⚠️ **Monitor if:** Occurs frequently (every few minutes) for >30 minutes
- 🚨 **Act if:** Cluster operator shows Degraded=True and this error persists

**Diagnosis:**

```bash
# Check if cluster operator is actually degraded
oc get clusteroperator kube-controller-manager

# Expected healthy output:
# NAME                      VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
# kube-controller-manager   4.14.x    True        False         False      Xh

# Check for multiple concurrent reconciliations
oc get pods -n openshift-kube-controller-manager-operator

# Check operator logs for patterns
oc logs -n openshift-kube-controller-manager-operator \
  deployment/kube-controller-manager-operator \
  --tail=100 | grep -i "operation cannot be fulfilled"
```

**Resolution:**

If the cluster operator is Available=True and Degraded=False:
- **No action needed** - This is normal retry behavior
- The operator will succeed on the next reconciliation

If the cluster operator is Degraded=True:
```bash
# Check what's actually wrong with the operator
oc get clusteroperator kube-controller-manager -o yaml

# Look at the status.conditions for the real issue
oc get co kube-controller-manager -o jsonpath='{.status.conditions[?(@.type=="Degraded")]}{"\n"}' | jq .

# The resource conflict is likely a symptom, not the cause
# Address the underlying degradation
```

---

### 2. Monitoring Stack Connection Refused

**Error Message:**
```
E1202 21:01:21.754129       1 base_controller.go:279] "Unhandled Error" 
err="GarbageCollectorWatcherController reconciliation failed: 
error fetching rules: Get \"https://thanos-querier.openshift-monitoring.svc:9091/api/v1/rules\": 
dial tcp 172.25.164.124:9091: connect: connection refused"
```

**Severity:** MEDIUM - Indicates monitoring stack issues

**Root Cause:**
- Thanos Querier service is not available/responding
- Could be:
  - Monitoring stack pods not running
  - Service endpoint issues
  - Network policy blocking traffic
  - Thanos Querier crashed/degraded

**Impact:**
- Operator cannot clean up stale alerting rules
- Metrics collection may be affected
- Does NOT directly impact kube-controller-manager functionality
- May lead to alert noise or stale alerts

**Diagnosis:**

```bash
# 1. Check monitoring cluster operator
oc get clusteroperator monitoring

# 2. Check Thanos Querier pods specifically
oc get pods -n openshift-monitoring -l app.kubernetes.io/name=thanos-query

# Expected: Pods should be Running
# NAME                              READY   STATUS    RESTARTS   AGE
# thanos-querier-xxxxxxxxxx-xxxxx   6/6     Running   0          Xd

# 3. Check Thanos Querier service
oc get svc thanos-querier -n openshift-monitoring

# 4. Check service endpoints (should have IPs listed)
oc get endpoints thanos-querier -n openshift-monitoring

# 5. Check if service is actually listening
oc exec -n openshift-monitoring \
  $(oc get pod -n openshift-monitoring -l app.kubernetes.io/name=thanos-query -o name | head -1) \
  -c thanos-query -- curl -k https://localhost:9091/api/v1/rules

# 6. Check monitoring operator logs
oc logs -n openshift-monitoring-operator \
  deployment/cluster-monitoring-operator --tail=100

# 7. Check all monitoring stack pods
oc get pods -n openshift-monitoring
```

**Common Causes and Fixes:**

#### Cause 1: Thanos Querier Pods Not Running

```bash
# Check pod status
oc get pods -n openshift-monitoring -l app.kubernetes.io/name=thanos-query

# If pods are not running or CrashLoopBackOff:
oc logs -n openshift-monitoring -l app.kubernetes.io/name=thanos-query --tail=100

# Check for resource issues
oc describe pod -n openshift-monitoring -l app.kubernetes.io/name=thanos-query

# Common fix: Restart the pods
oc delete pod -n openshift-monitoring -l app.kubernetes.io/name=thanos-query

# Monitor recovery
watch oc get pods -n openshift-monitoring -l app.kubernetes.io/name=thanos-query
```

#### Cause 2: Service Endpoints Empty

```bash
# Check endpoints
oc get endpoints thanos-querier -n openshift-monitoring -o yaml

# If no endpoints:
# 1. Check if pods have correct labels
oc get pods -n openshift-monitoring -l app.kubernetes.io/name=thanos-query --show-labels

# 2. Check service selector matches
oc get svc thanos-querier -n openshift-monitoring -o yaml | grep -A 5 selector

# 3. Restart monitoring operator to reconcile
oc delete pod -n openshift-monitoring-operator \
  -l app.kubernetes.io/name=cluster-monitoring-operator
```

#### Cause 3: Monitoring Stack Degraded

```bash
# Check monitoring cluster operator
oc get clusteroperator monitoring -o yaml

# If degraded, check the conditions
oc get co monitoring -o jsonpath='{.status.conditions[?(@.type=="Degraded")]}' | jq .

# Review monitoring configuration
oc get configmap cluster-monitoring-config -n openshift-monitoring -o yaml

# Check for recent changes
oc get events -n openshift-monitoring --sort-by='.lastTimestamp' | tail -20

# Nuclear option: Restart all monitoring components
oc delete pod --all -n openshift-monitoring
# Wait 5-10 minutes for full recovery
```

#### Cause 4: Network Policy Issues

```bash
# Check network policies
oc get networkpolicies -n openshift-monitoring

# Test connectivity from operator namespace
oc run test-curl --image=curlimages/curl -n openshift-kube-controller-manager-operator \
  --rm -it --restart=Never -- \
  curl -k https://thanos-querier.openshift-monitoring.svc:9091/api/v1/rules

# If it fails, check network policies or SDN/OVN issues
```

**Resolution Priority:**

1. **First:** Verify monitoring operator is healthy
   ```bash
   oc get co monitoring
   ```

2. **Second:** Ensure Thanos Querier pods are running
   ```bash
   oc get pods -n openshift-monitoring -l app.kubernetes.io/name=thanos-query
   ```

3. **Third:** Verify service endpoints exist
   ```bash
   oc get endpoints thanos-querier -n openshift-monitoring
   ```

4. **Fourth:** Test connectivity from operator pod
   ```bash
   # Get operator pod name
   OPERATOR_POD=$(oc get pod -n openshift-kube-controller-manager-operator \
     -l app=kube-controller-manager-operator -o name | head -1)
   
   # Test from operator pod
   oc exec -n openshift-kube-controller-manager-operator $OPERATOR_POD -- \
     curl -k -m 5 https://thanos-querier.openshift-monitoring.svc:9091/api/v1/rules
   ```

---

## Decision Matrix

| Cluster Operator Status | Resource Conflict | Monitoring Error | Action Required |
|-------------------------|-------------------|------------------|-----------------|
| Available=True, Degraded=False | Occasional | None | ✅ No action |
| Available=True, Degraded=False | Occasional | Frequent | ⚠️ Fix monitoring |
| Available=True, Degraded=False | Frequent | Any | ⚠️ Monitor closely |
| Available=False or Degraded=True | Any | Any | 🚨 Fix controller manager first |

## Combined Scenario (Your Case)

Given both errors are present:

```bash
# Step 1: Check if controller manager is actually degraded
oc get clusteroperator kube-controller-manager

# Step 2: Check kube-controller-manager pods (the actual component, not operator)
oc get pods -n openshift-kube-controller-manager

# Step 3: If controller manager is healthy, focus on monitoring
oc get clusteroperator monitoring
oc get pods -n openshift-monitoring | grep -i thanos
```

**Recommended Actions (in order):**

1. **Verify kube-controller-manager health:**
   ```bash
   oc get co kube-controller-manager
   oc get pods -n openshift-kube-controller-manager
   ```
   
   If healthy (Available=True, Degraded=False, pods Running):
   - Resource conflict error is cosmetic
   - Move to step 2

2. **Fix monitoring stack:**
   ```bash
   # Quick check
   oc get co monitoring
   oc get pods -n openshift-monitoring -l app.kubernetes.io/name=thanos-query
   
   # If Thanos pods not running:
   oc delete pod -n openshift-monitoring -l app.kubernetes.io/name=thanos-query
   
   # Wait 2-3 minutes and verify
   watch oc get pods -n openshift-monitoring -l app.kubernetes.io/name=thanos-query
   ```

3. **Verify operator errors stop:**
   ```bash
   # Monitor operator logs
   oc logs -n openshift-kube-controller-manager-operator \
     deployment/kube-controller-manager-operator -f
   
   # Should stop seeing "connection refused" after monitoring is fixed
   ```

## Quick Fix Script

```bash
#!/bin/bash

echo "=== Checking kube-controller-manager Cluster Operator ==="
oc get co kube-controller-manager

echo ""
echo "=== Checking kube-controller-manager Pods ==="
oc get pods -n openshift-kube-controller-manager

echo ""
echo "=== Checking Monitoring Cluster Operator ==="
oc get co monitoring

echo ""
echo "=== Checking Thanos Querier Pods ==="
oc get pods -n openshift-monitoring -l app.kubernetes.io/name=thanos-query

echo ""
echo "=== Checking Thanos Querier Service Endpoints ==="
oc get endpoints thanos-querier -n openshift-monitoring

echo ""
read -p "Restart Thanos Querier pods? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Restarting Thanos Querier pods..."
    oc delete pod -n openshift-monitoring -l app.kubernetes.io/name=thanos-query
    echo "Waiting 30 seconds..."
    sleep 30
    echo "New pod status:"
    oc get pods -n openshift-monitoring -l app.kubernetes.io/name=thanos-query
fi

echo ""
echo "=== Monitoring operator logs (last 20 lines) ==="
oc logs -n openshift-kube-controller-manager-operator \
  deployment/kube-controller-manager-operator --tail=20
```

## When to Escalate

Escalate if:
- ✅ kube-controller-manager cluster operator shows Degraded=True
- ✅ Monitoring stack cannot be restored after restarting pods
- ✅ Both monitoring and kube-controller-manager operators are degraded
- ✅ Issues persist for >1 hour after attempted fixes

## Prevention

1. **Monitor the monitoring stack:**
   ```bash
   oc get co monitoring
   ```

2. **Regular health checks:**
   ```bash
   # Add to daily checks
   oc get co | grep -E 'False|Unknown'
   ```

3. **Set up alerts:**
   - Alert when cluster operators become degraded
   - Alert when monitoring pods are not ready

## Related Issues

- If you see actual kube-controller-manager crashes, see [README.md](README.md)
- For monitoring stack troubleshooting, check OpenShift monitoring operator documentation
- For Thanos-specific issues, review Thanos logs and configuration

## Summary

**Your specific case:**
- Resource conflict: Likely harmless if cluster operator is Available
- Monitoring error: Fix Thanos Querier connectivity
- Neither indicates kube-controller-manager is actually crashing

**Most likely fix:**
```bash
# Restart Thanos Querier
oc delete pod -n openshift-monitoring -l app.kubernetes.io/name=thanos-query

# Wait and verify
watch oc get pods -n openshift-monitoring -l app.kubernetes.io/name=thanos-query
```


# Service Account Token Expiry Issues

## Overview

When you see "invalid bearer token: service account token has expired" errors in kube-apiserver logs, it indicates authentication failures that can cause API slowness, application failures, and cluster instability.

## Severity

**HIGH** - Can cause widespread application failures and API performance degradation.

## Symptoms

- "service account token has expired" errors in API server logs
- Pods unable to communicate with API server
- Application authentication failures
- API slowness (due to high volume of failed auth attempts)
- 401 Unauthorized errors in application logs
- Intermittent pod failures

## 🚨 Emergency Quick Checks

```bash
# 1. Count the error frequency
ERROR_COUNT=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=1000 2>/dev/null | grep -c "service account token has expired")
echo "Expired token errors in last 1000 log lines: $ERROR_COUNT"

# 2. Check critical operators
oc get co service-ca kube-controller-manager

# 3. Identify which service accounts are affected
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=2000 | \
  grep "service account token has expired" | \
  grep -oP 'system:serviceaccount:[^"]+' | \
  sort | uniq -c | sort -rn | head -10

# 4. Check for time skew
echo "Checking node times:"
for node in $(oc get nodes -o jsonpath='{.items[*].metadata.name}'); do
  echo -n "$node: "
  oc debug node/$node -- chroot /host date 2>/dev/null | grep -v "Starting pod"
done
```

## Common Root Causes

### 1. Pods Using Stale/Cached Tokens

**Symptoms:**
- Specific pods or namespaces repeatedly appearing in errors
- Errors started after pod creation or restart
- Long-running pods affected

**Diagnosis:**

```bash
# Identify the most affected service accounts
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep "service account token has expired" | \
  grep -oP 'system:serviceaccount:\K[^:]+:[^"]+' | \
  awk -F: '{print $1}' | sort | uniq -c | sort -rn

# Check pods in affected namespaces
AFFECTED_NS="<namespace-from-above>"
oc get pods -n $AFFECTED_NS -o wide

# Check pod age (old pods more likely to have stale tokens)
oc get pods -n $AFFECTED_NS -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.startTime}{"\n"}{end}'
```

**Resolution:**

```bash
# Option 1: Restart specific affected pods
oc delete pod -n <namespace> <pod-name>

# Option 2: Rolling restart of deployment
oc rollout restart deployment -n <namespace> <deployment-name>

# Option 3: Restart all pods in namespace (use with caution)
oc delete pods --all -n <namespace>

# Verify errors stop
watch 'oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=50 | grep "service account token has expired"'
```

### 2. Time Skew Between Nodes

**Symptoms:**
- Errors affect multiple random pods
- Started after node addition or time change
- Errors correlate with specific nodes

**Diagnosis:**

```bash
# Check time on all nodes
echo "=== Checking node times ==="
BASE_TIME=$(date +%s)
echo "Control node time: $(date)"

for node in $(oc get nodes -o name); do
  NODE_NAME=${node#node/}
  echo -e "\n=== $NODE_NAME ==="
  NODE_TIME=$(oc debug $node -- chroot /host date '+%s' 2>/dev/null | grep -v "Starting pod" | tail -1)
  DIFF=$((NODE_TIME - BASE_TIME))
  echo "Time: $(oc debug $node -- chroot /host date 2>/dev/null | grep -v "Starting pod" | tail -1)"
  echo "Diff from control: ${DIFF}s"
  
  if [ ${DIFF#-} -gt 5 ]; then
    echo "⚠️  WARNING: Time skew detected (${DIFF}s)"
  fi
done

# Check NTP/chrony status on nodes
for node in $(oc get nodes -o name); do
  echo "=== ${node#node/} ==="
  oc debug $node -- chroot /host chronyc tracking 2>/dev/null | grep -v "Starting pod"
done

# Check if chrony is syncing
for node in $(oc get nodes -o name); do
  echo "=== ${node#node/} ==="
  oc debug $node -- chroot /host chronyc sources 2>/dev/null | grep -v "Starting pod"
done
```

**Resolution:**

```bash
# Force time sync on affected nodes
AFFECTED_NODE="<node-name>"

# Option 1: Force chrony sync
oc debug node/$AFFECTED_NODE -- chroot /host chronyc makestep

# Option 2: Restart chronyd service
oc debug node/$AFFECTED_NODE -- chroot /host systemctl restart chronyd

# Option 3: If persistent, check chrony configuration
oc debug node/$AFFECTED_NODE -- chroot /host cat /etc/chrony.conf

# Verify sync
oc debug node/$AFFECTED_NODE -- chroot /host chronyc tracking
```

### 3. Service CA Rotation Issues

**Symptoms:**
- Widespread token failures across many namespaces
- Started after certificate rotation
- service-ca-operator degraded

**Diagnosis:**

```bash
# Check service-ca-operator status
oc get co service-ca -o yaml

# Check service CA controller logs
oc logs -n openshift-service-ca-operator -l app=service-ca-operator --tail=200

# Check signing key age
oc get secret -n openshift-service-ca signing-key -o yaml | grep -A 5 metadata.creationTimestamp

# Check if CA is being rotated
oc get configmap -n openshift-service-ca signing-cabundle -o yaml | grep -A 10 "ca-bundle.crt:"

# Check for service CA issues in kube-controller-manager
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=200 | \
  grep -i "service.*ca\|signing"
```

**Resolution:**

```bash
# Force service CA regeneration
oc delete secret -n openshift-service-ca signing-key

# Wait for automatic regeneration (2-5 minutes)
echo "Waiting for signing key regeneration..."
until oc get secret -n openshift-service-ca signing-key &>/dev/null; do
  echo -n "."
  sleep 5
done
echo "Signing key regenerated"

# Check operator status
oc get co service-ca

# Force pods to pick up new CA (rolling restart)
# This may be needed for affected pods
oc get ns --no-headers | awk '{print $1}' | while read ns; do
  echo "Checking namespace: $ns"
  # Only restart if namespace has affected pods
done
```

### 4. Token Controller Issues

**Symptoms:**
- New tokens not being generated
- kube-controller-manager degraded
- ServiceAccount tokens missing from pods

**Diagnosis:**

```bash
# Check kube-controller-manager status
oc get co kube-controller-manager -o yaml

# Check token controller logs
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=500 | \
  grep -i "token\|serviceaccount"

# Check if token controller is running
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=100 | \
  grep "Started service account token"

# Check for token generation errors
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=500 | \
  grep -i "error.*token"

# Verify service account tokens exist in pods
POD_NAME=$(oc get pods -n default -o name | head -1)
if [ -n "$POD_NAME" ]; then
  oc exec -n default $POD_NAME -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/
fi
```

**Resolution:**

```bash
# Restart kube-controller-manager pods
oc delete pods -n openshift-kube-controller-manager -l app=kube-controller-manager

# Wait for pods to be ready
oc wait --for=condition=Ready -n openshift-kube-controller-manager \
  pod -l app=kube-controller-manager --timeout=300s

# Verify token controller is running
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=50 | \
  grep "token"

# Check cluster operator status
watch oc get co kube-controller-manager
```

### 5. BoundServiceAccountTokenVolume Feature Issues

**Symptoms:**
- Errors started after cluster upgrade
- Related to projected volume tokens
- Token refresh not happening

**Diagnosis:**

```bash
# Check if BoundServiceAccountTokenVolume is enabled (it is by default in OCP 4.x)
oc get apiserver cluster -o yaml | grep -A 10 serviceAccountIssuer

# Check token expiry settings
oc get authentication.config.openshift.io cluster -o yaml

# Check for pods using old token volume type vs projected volumes
oc get pods -A -o json | \
  jq -r '.items[] | select(.spec.volumes[]? | select(.name=="kube-api-access" or .name | startswith("kube-api-access"))) | "\(.metadata.namespace)/\(.metadata.name)"' | \
  head -10

# Check projected token expiry
oc get pod -n <namespace> <pod-name> -o yaml | \
  grep -A 10 "projected:\|volumes:" | grep -A 5 "serviceAccountToken"
```

**Resolution:**

```bash
# If pods are using old-style SA tokens, recreate them
# They should use projected volumes with automatic rotation

# Check a sample pod spec
oc get pod -n <namespace> <pod-name> -o yaml | grep -A 20 volumes:

# Force pod recreation to get new projected tokens
oc delete pod -n <namespace> <pod-name>

# For deployments, trigger rollout
oc rollout restart deployment -n <namespace> <deployment-name>
```

### 6. ServiceAccount Deleted or Modified

**Symptoms:**
- Errors for specific service account
- Started after namespace cleanup or SA changes
- Pods unable to authenticate

**Diagnosis:**

```bash
# Extract affected service accounts from logs
AFFECTED_SA=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=1000 | \
  grep "service account token has expired" | \
  grep -oP 'system:serviceaccount:\K[^"]+' | \
  sort -u | head -5)

echo "Affected service accounts:"
echo "$AFFECTED_SA"

# Check if service accounts exist
while IFS=: read -r ns sa; do
  echo "Checking $ns/$sa"
  if oc get sa -n "$ns" "$sa" &>/dev/null; then
    echo "  ✓ Exists"
    # Check secrets
    oc get sa -n "$ns" "$sa" -o yaml | grep -A 5 secrets:
  else
    echo "  ✗ NOT FOUND - Service account deleted!"
  fi
done <<< "$AFFECTED_SA"

# Check pods using deleted service accounts
oc get pods -A -o json | \
  jq -r '.items[] | select(.spec.serviceAccountName=="<sa-name>") | "\(.metadata.namespace)/\(.metadata.name)"'
```

**Resolution:**

```bash
# If service account was deleted, pods need to be recreated
# (They won't automatically get new SA)

# Delete pods using deleted/invalid service account
oc delete pod -n <namespace> <pod-name>

# If SA doesn't exist but should, create it
oc create sa <sa-name> -n <namespace>

# Verify new token secret was created
oc get sa <sa-name> -n <namespace> -o yaml

# Recreate the pods
oc delete pod -n <namespace> <pod-name>
```

## Step-by-Step Troubleshooting

### Step 1: Quantify the Problem

```bash
# Check error frequency over time
echo "Errors in last 5 minutes:"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --since=5m | \
  grep -c "service account token has expired"

# Get rate
for i in {1..5}; do
  COUNT=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --since=1m | \
    grep -c "service account token has expired")
  echo "Minute $i: $COUNT errors"
  sleep 60
done
```

### Step 2: Identify Affected Components

```bash
# Get top 10 affected service accounts
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep "service account token has expired" | \
  grep -oP 'system:serviceaccount:\K[^"]+' | \
  sort | uniq -c | sort -rn | head -10 > affected-sa.txt

cat affected-sa.txt

# Get affected namespaces
cat affected-sa.txt | awk '{print $2}' | cut -d: -f1 | sort -u
```

### Step 3: Check Time Sync

```bash
# Quick time sync check
./check-node-time.sh

# Or manually:
for node in $(oc get nodes -o jsonpath='{.items[*].metadata.name}'); do
  echo "$node: $(oc debug node/$node -- chroot /host date 2>/dev/null | tail -1)"
done
```

### Step 4: Check Service CA and Controllers

```bash
# Health of key components
oc get co service-ca kube-controller-manager

# If degraded, check logs
oc logs -n openshift-service-ca-operator -l app=service-ca-operator --tail=100
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=100 | \
  grep -i "error\|token"
```

### Step 5: Apply Targeted Fix

Based on findings:
- **Specific pods/SA**: Restart those pods
- **Time skew**: Fix NTP on affected nodes
- **service-ca degraded**: Regenerate CA
- **controller degraded**: Restart controller pods
- **Widespread**: Systematic pod restart may be needed

### Step 6: Verify Resolution

```bash
# Monitor for new errors
watch 'oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=20 --since=1m | grep "service account token has expired"'

# Should see decreasing or zero errors

# Verify affected applications working
oc get pods -n <affected-namespace>
oc logs -n <affected-namespace> <pod-name> --tail=20
```

## Automated Diagnostic Script

```bash
#!/bin/bash
# Save as: diagnose-token-expiry.sh

echo "=== Service Account Token Expiry Diagnostic ==="
echo "Started: $(date)"
echo ""

# Error count
echo "1. Error frequency"
COUNT=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | grep -c "service account token has expired")
echo "Errors in last 5000 log lines: $COUNT"

if [ $COUNT -gt 100 ]; then
  echo "⚠️  HIGH: $COUNT errors detected"
elif [ $COUNT -gt 10 ]; then
  echo "⚠️  MODERATE: $COUNT errors detected"
else
  echo "✓ LOW: $COUNT errors"
fi
echo ""

# Affected service accounts
echo "2. Top 10 affected service accounts:"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep "service account token has expired" | \
  grep -oP 'system:serviceaccount:\K[^"]+' | \
  sort | uniq -c | sort -rn | head -10
echo ""

# Operator health
echo "3. Critical operator status:"
oc get co service-ca kube-controller-manager --no-headers 2>/dev/null | \
  awk '{printf "%-30s Available=%-5s Degraded=%-5s\n", $1, $3, $5}'
echo ""

# Time check
echo "4. Node time synchronization:"
BASE_TIME=$(date +%s)
for node in $(oc get nodes -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  NODE_TIME=$(oc debug node/$node -- chroot /host date +%s 2>/dev/null | tail -1)
  DIFF=$((NODE_TIME - BASE_TIME))
  STATUS="✓"
  [ ${DIFF#-} -gt 5 ] && STATUS="⚠️"
  echo "  $STATUS $node: ${DIFF}s difference"
done
echo ""

# Service CA age
echo "5. Service CA signing key age:"
oc get secret -n openshift-service-ca signing-key -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null
echo ""
echo ""

# Recommendations
echo "=== Recommendations ==="
if [ $COUNT -gt 100 ]; then
  echo "URGENT: High volume of token expiry errors detected"
  echo ""
  echo "1. Check time synchronization on all nodes"
  echo "2. Consider service CA regeneration: oc delete secret -n openshift-service-ca signing-key"
  echo "3. Restart affected pods based on service account list above"
elif [ $COUNT -gt 10 ]; then
  echo "Action needed: Moderate token expiry errors"
  echo ""
  echo "1. Restart pods for affected service accounts"
  echo "2. Verify time sync on nodes"
else
  echo "Status: Token errors are low or zero"
  echo "Monitoring recommended but no immediate action needed"
fi

echo ""
echo "=== End of Diagnostic ==="
```

## Prevention

### 1. Monitoring

Set up alerts for:
- Token expiry error rate in API server logs
- service-ca-operator degraded
- kube-controller-manager degraded
- Node time skew >5 seconds

**Example Prometheus query:**
```promql
# Token expiry errors
increase(apiserver_audit_event_total{verb="authentication",status="401"}[5m]) > 100

# Time skew
abs(node_time_seconds - time()) > 5
```

### 2. Regular Checks

```bash
# Weekly check script
cat > /usr/local/bin/check-sa-tokens.sh << 'EOF'
#!/bin/bash
ERROR_COUNT=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | grep -c "service account token has expired")
echo "$(date): Token expiry errors: $ERROR_COUNT" | tee -a /var/log/sa-token-check.log

if [ $ERROR_COUNT -gt 50 ]; then
  echo "WARNING: High token expiry rate detected" | mail -s "Token Expiry Alert" admin@example.com
fi
EOF

chmod +x /usr/local/bin/check-sa-tokens.sh

# Add to cron
echo "0 */4 * * * /usr/local/bin/check-sa-tokens.sh" | crontab -
```

### 3. NTP/Chrony Configuration

Ensure chronyd is properly configured on all nodes:

```bash
# Check chrony config on all nodes
for node in $(oc get nodes -o name); do
  echo "=== ${node#node/} ==="
  oc debug $node -- chroot /host cat /etc/chrony.conf | grep "^server\|^pool"
done

# Verify chrony is enabled
for node in $(oc get nodes -o name); do
  echo "=== ${node#node/} ==="
  oc debug $node -- chroot /host systemctl is-enabled chronyd
done
```

### 4. Token Rotation Best Practices

- Use projected volumes for service account tokens (default in OCP 4.x)
- Don't disable automatic token rotation
- Ensure applications handle token refresh
- Monitor token controller logs regularly

## Related Issues

- See [Certificate Verification Issues](README.md#6-certificate-verification-issues) in main guide
- See [kube-controller-manager Crash Loop](../kube-controller-manager-crashloop/README.md)
- See [Authentication failures](../authentication-failures/README.md) (when created)

## Quick Reference Commands

```bash
# Count errors
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=1000 | \
  grep -c "service account token has expired"

# Identify affected service accounts
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=2000 | \
  grep "service account token has expired" | \
  grep -oP 'system:serviceaccount:\K[^"]+' | sort | uniq -c | sort -rn | head -10

# Check critical components
oc get co service-ca kube-controller-manager

# Check time sync
for node in $(oc get nodes -o name); do
  echo "${node#node/}: $(oc debug $node -- chroot /host date 2>/dev/null | tail -1)"
done

# Restart affected pods
oc delete pod -n <namespace> <pod-name>

# Regenerate service CA (if needed)
oc delete secret -n openshift-service-ca signing-key
```

## Escalation Criteria

Escalate to Red Hat Support if:
- Error rate >1000/hour sustained
- service-ca-operator persistently degraded
- Token controller not generating new tokens
- Time sync cannot be fixed
- Affects critical cluster services
- Root cause unclear after following this guide

**Before escalating, collect:**
```bash
oc adm must-gather
oc adm inspect namespace/openshift-service-ca-operator
oc adm inspect namespace/openshift-kube-controller-manager
./diagnose-token-expiry.sh > token-diagnostic.txt
```

---

**Last Updated**: January 2026  
**Version**: 1.0  
**Compatibility**: OpenShift 4.x


# Client-Side Throttling and Token Review Issues

## Overview

Client-side throttling occurs when Kubernetes clients (pods, controllers, operators) make too many requests to the API server and are rate-limited by their client library before requests even reach the API server. This is different from API Priority and Fairness (server-side throttling).

Common symptoms include log messages like:
```
5.255386325s due to client-side throttling, not priority and fairness, 
request: POST:https://kubernetes.default.svc/apis/authentication.k8s.io/v1/tokenreviews
```

## Severity

**HIGH** - Can cause significant delays in authentication, pod startup, and overall cluster operations.

## Symptoms

- Long delays (seconds) in API requests
- "due to client-side throttling" in logs
- Excessive `tokenreviews` requests
- Slow pod startup and authentication
- Applications timing out on API calls
- Webhook validation delays

## 🚨 Emergency Quick Checks

```bash
# 1. Identify components being throttled
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep "client-side throttling" | wc -l

# 2. Find which clients are being throttled
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep "client-side throttling" | \
  grep -oP 'user="[^"]+' | \
  sed 's/user="//' | \
  sort | uniq -c | sort -rn | head -10

# 3. Check tokenreview request rate
oc get --raw /metrics 2>/dev/null | \
  grep 'apiserver_request_total.*tokenreviews' | \
  grep -v "#"

# 4. Identify service accounts making excessive requests
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep "tokenreviews" | \
  grep -oP 'system:serviceaccount:[^"]+' | \
  sort | uniq -c | sort -rn | head -10
```

## Common Root Causes

### 1. Excessive Webhook Authentication

**Symptoms:**
- High volume of tokenreview requests
- Webhooks validating every request
- Delays on pod operations

**Diagnosis:**

```bash
# Check webhook configurations
oc get validatingwebhookconfigurations -o json | \
  jq -r '.items[] | "\(.metadata.name) Webhooks: \(.webhooks | length)"'

oc get mutatingwebhookconfigurations -o json | \
  jq -r '.items[] | "\(.metadata.name) Webhooks: \(.webhooks | length)"'

# Check which webhooks are being called most
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=2000 | \
  grep "webhook" | \
  grep -oP 'webhook:"[^"]+' | \
  sort | uniq -c | sort -rn

# Check for webhook timeout issues
oc get validatingwebhookconfigurations -o json | \
  jq -r '.items[] | .webhooks[] | "\(.name) timeout: \(.timeoutSeconds)s"'
```

**Resolution:**

```bash
# Increase webhook timeout (if webhooks are slow)
# This reduces retries and thus tokenreview volume

# Example: Update specific webhook timeout
oc patch validatingwebhookconfiguration <webhook-name> --type=json \
  -p='[{"op": "replace", "path": "/webhooks/0/timeoutSeconds", "value": 30}]'

# Or if webhook is not critical, reduce failurePolicy to Ignore
oc patch validatingwebhookconfiguration <webhook-name> --type=json \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value": "Ignore"}]'

# For problematic webhooks, consider temporarily removing
# oc delete validatingwebhookconfiguration <webhook-name>
```

### 2. Operator or Controller in Tight Loop

**Symptoms:**
- Specific service account appearing frequently in logs
- Operator pod with high CPU usage
- Continuous reconciliation loops

**Diagnosis:**

```bash
# Identify the top service accounts making requests
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=10000 | \
  grep -oP 'system:serviceaccount:\K[^"]+' | \
  awk -F: '{print $1":"$2}' | \
  sort | uniq -c | sort -rn | head -20

# For the top offender, find the pods
TOP_SA="namespace:serviceaccount-name"
NAMESPACE=$(echo $TOP_SA | cut -d: -f1)
SA_NAME=$(echo $TOP_SA | cut -d: -f2)

oc get pods -n $NAMESPACE --field-selector spec.serviceAccountName=$SA_NAME

# Check operator/controller logs
oc logs -n $NAMESPACE <pod-name> --tail=200

# Check if it's in a reconciliation loop
oc logs -n $NAMESPACE <pod-name> --tail=1000 | \
  grep -i "reconcil\|error\|retry" | tail -20
```

**Resolution:**

```bash
# Restart the problematic operator/controller
oc delete pod -n <namespace> <pod-name>

# If it's a deployment, check for configuration issues
oc get deployment -n <namespace> <deployment-name> -o yaml | \
  grep -A 10 "env:\|args:"

# Check for resource constraints causing issues
oc get pod -n <namespace> <pod-name> -o json | \
  jq -r '.spec.containers[] | "Resources: \(.resources)"'

# Scale down temporarily if causing cluster issues
oc scale deployment -n <namespace> <deployment-name> --replicas=0
```

### 3. High Pod Churn with Authentication Overhead

**Symptoms:**
- Many pods starting/stopping
- Each pod startup triggers multiple tokenreviews
- CrashLooping pods amplifying the issue

**Diagnosis:**

```bash
# Check pod churn rate
oc get events -A --sort-by='.lastTimestamp' | \
  grep -E "Created|Started|Killing" | \
  tail -50

# Count pods created in last hour
oc get events -A -o json | \
  jq -r '.items[] | 
    select(.reason == "Created" or .reason == "Started") | 
    select(.lastTimestamp | fromdateiso8601 > (now - 3600)) | 
    "\(.involvedObject.namespace)/\(.involvedObject.name)"' | \
  wc -l

# Find crashlooping pods (each restart = more tokenreviews)
oc get pods -A -o json | \
  jq -r '.items[] | 
    select(.status.containerStatuses[]?.restartCount > 10) | 
    "\(.metadata.namespace) \(.metadata.name) Restarts:\(.status.containerStatuses[0].restartCount)"' | \
  sort -t: -k2 -rn | head -20

# Check for deployments with aggressive rollout strategies
oc get deployments -A -o json | \
  jq -r '.items[] | 
    "\(.metadata.namespace)/\(.metadata.name) MaxUnavailable:\(.spec.strategy.rollingUpdate.maxUnavailable // "default") MaxSurge:\(.spec.strategy.rollingUpdate.maxSurge // "default")"'
```

**Resolution:**

```bash
# Fix crashlooping pods first (see scale-down-crashloops.sh)
./scale-down-crashloops.sh

# Slow down aggressive rollouts if needed
oc patch deployment -n <namespace> <deployment> -p '{
  "spec": {
    "strategy": {
      "rollingUpdate": {
        "maxUnavailable": 1,
        "maxSurge": 1
      }
    }
  }
}'

# Add longer startup/readiness probe delays for problematic apps
oc patch deployment -n <namespace> <deployment> --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/readinessProbe/initialDelaySeconds",
    "value": 30
  }
]'
```

### 4. Service Account Token Volume Projection Issues

**Symptoms:**
- Frequent token renewals
- Pods constantly re-validating tokens
- Short token expiry times

**Diagnosis:**

```bash
# Check token volume projection settings
oc get pods -A -o json | \
  jq -r '.items[] | 
    select(.spec.volumes[]? | select(.projected?.sources[]?.serviceAccountToken)) | 
    {
      ns: .metadata.namespace, 
      pod: .metadata.name, 
      expiry: .spec.volumes[] | select(.projected?.sources[]?.serviceAccountToken) | .projected.sources[].serviceAccountToken.expirationSeconds
    }' | head -20

# Check authentication configuration
oc get authentication.config.openshift.io cluster -o yaml | \
  grep -A 10 serviceAccountIssuer

# Check kube-apiserver configuration for token settings
oc get kubeapiserver cluster -o yaml | \
  grep -A 5 "service-account"
```

**Resolution:**

```bash
# If tokens are expiring too quickly, check if this is intentional
# Default is 3600 seconds (1 hour) which should be sufficient

# For specific workloads needing longer tokens, patch the pod spec
# (Usually done at deployment/statefulset level)
oc patch deployment -n <namespace> <deployment> --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/0/projected/sources/0/serviceAccountToken/expirationSeconds",
    "value": 7200
  }
]'

# Note: This requires pod recreation
oc rollout restart deployment -n <namespace> <deployment>
```

### 5. Client Library Outdated or Misconfigured

**Symptoms:**
- Specific applications showing throttling
- Old client-go versions
- Hardcoded low QPS/Burst settings

**Diagnosis:**

```bash
# Check container images for old versions
oc get pods -n <namespace> -o json | \
  jq -r '.items[] | "\(.metadata.name) Image: \(.spec.containers[0].image)"'

# Check operator logs for client configuration
oc logs -n <namespace> <pod-name> | \
  grep -i "qps\|burst\|rate\|throttl"

# Look for environment variables affecting client config
oc get deployment -n <namespace> <deployment> -o json | \
  jq -r '.spec.template.spec.containers[].env[]? | 
    select(.name | test("QPS|BURST|RATE|KUBE")) | 
    "\(.name)=\(.value)"'
```

**Resolution:**

```bash
# Update the application/operator to newer version
oc set image deployment -n <namespace> <deployment> \
  <container>=<new-image:tag>

# If application supports it, increase QPS/Burst via env vars
oc set env deployment -n <namespace> <deployment> \
  KUBE_API_QPS=50 \
  KUBE_API_BURST=100

# For operators, check if there's a config to tune these
oc get deployment -n <namespace> <deployment> -o yaml | \
  grep -A 20 "args:\|command:"
```

### 6. Insufficient API Priority and Fairness Configuration

**Symptoms:**
- Even though message says "not priority and fairness", APF limits can cause clients to self-throttle
- Multiple flows hitting limits
- Workload priority issues

**Diagnosis:**

```bash
# Check current APF configuration
oc get flowschema
oc get prioritylevelconfiguration

# Check which flows are being limited
oc get --raw /metrics | \
  grep apiserver_flowcontrol_rejected_requests_total

# Check current request concurrency
oc get --raw /metrics | \
  grep apiserver_flowcontrol_current_inqueue_requests

# Check for specific user agent or service account hitting limits
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=2000 | \
  grep "429" | \
  grep -oP 'user="[^"]+' | \
  sort | uniq -c | sort -rn
```

**Resolution:**

```bash
# Check priority level configurations
oc get prioritylevelconfiguration -o yaml

# If needed, create custom priority level for specific workloads
cat <<EOF | oc apply -f -
apiVersion: flowcontrol.apiserver.k8s.io/v1beta2
kind: PriorityLevelConfiguration
metadata:
  name: custom-workload-high
spec:
  type: Limited
  limited:
    assuredConcurrencyShares: 50
    limitResponse:
      type: Queue
      queuing:
        queues: 128
        queueLengthLimit: 50
        handSize: 8
EOF

# Create flow schema to use it
cat <<EOF | oc apply -f -
apiVersion: flowcontrol.apiserver.k8s.io/v1beta2
kind: FlowSchema
metadata:
  name: custom-workload-flow
spec:
  priorityLevelConfiguration:
    name: custom-workload-high
  matchingPrecedence: 1000
  distinguisherMethod:
    type: ByUser
  rules:
  - subjects:
    - kind: ServiceAccount
      serviceAccount:
        name: <service-account-name>
        namespace: <namespace>
    nonResourceRules:
    - verbs: ["*"]
      nonResourceURLs: ["*"]
    resourceRules:
    - verbs: ["*"]
      apiGroups: ["*"]
      resources: ["*"]
EOF
```

## Diagnostic Script

```bash
#!/bin/bash
# diagnose-client-throttling.sh

echo "=== Client-Side Throttling Diagnostic ==="
echo ""

# Count throttling occurrences
echo "1. Throttling frequency:"
THROTTLE_COUNT=$(oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep -c "client-side throttling")
echo "   Throttling events in last 5000 lines: $THROTTLE_COUNT"

if [ $THROTTLE_COUNT -gt 100 ]; then
  echo "   ⚠️  HIGH: Significant throttling detected"
elif [ $THROTTLE_COUNT -gt 10 ]; then
  echo "   ⚠️  MODERATE: Some throttling occurring"
else
  echo "   ✓ LOW: Minimal throttling"
fi
echo ""

# Top throttled clients
echo "2. Top throttled clients:"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep "client-side throttling" | \
  grep -oP 'user="[^"]+' | \
  sed 's/user="//' | \
  sort | uniq -c | sort -rn | head -10
echo ""

# TokenReview request volume
echo "3. TokenReview request volume:"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep -c "tokenreviews"
echo ""

# Top service accounts making tokenreview requests
echo "4. Top service accounts (tokenreviews):"
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 2>/dev/null | \
  grep "tokenreviews" | \
  grep -oP 'system:serviceaccount:\K[^"]+' | \
  awk -F: '{print $1":"$2}' | \
  sort | uniq -c | sort -rn | head -10
echo ""

# Webhook count
echo "5. Webhook configurations:"
VALIDATING=$(oc get validatingwebhookconfigurations --no-headers 2>/dev/null | wc -l)
MUTATING=$(oc get mutatingwebhookconfigurations --no-headers 2>/dev/null | wc -l)
echo "   Validating webhooks: $VALIDATING"
echo "   Mutating webhooks: $MUTATING"
echo ""

# CrashLooping pods (contributing to churn)
echo "6. CrashLooping pods:"
CRASHLOOP_COUNT=$(oc get pods -A -o json 2>/dev/null | \
  jq -r '.items[] | 
    select(.status.containerStatuses[]?.state.waiting?.reason == "CrashLoopBackOff") | 
    "\(.metadata.namespace)/\(.metadata.name)"' | wc -l)
echo "   Pods in CrashLoopBackOff: $CRASHLOOP_COUNT"

if [ $CRASHLOOP_COUNT -gt 10 ]; then
  echo "   ⚠️  Many crashlooping pods may be amplifying the issue"
  echo "   Consider running: ./scale-down-crashloops.sh"
fi
echo ""

# API server resource usage
echo "7. API server resource usage:"
oc adm top pods -n openshift-kube-apiserver 2>/dev/null || echo "   Metrics not available"
echo ""

# Recommendations
echo "=== Recommendations ==="
if [ $THROTTLE_COUNT -gt 100 ]; then
  echo "URGENT: High throttling detected"
  echo "1. Review 'Top throttled clients' above"
  echo "2. Check if specific operators/controllers need attention"
  echo "3. Review webhook configurations"
  echo "4. Fix any crashlooping pods"
elif [ $THROTTLE_COUNT -gt 10 ]; then
  echo "Action recommended:"
  echo "1. Investigate top throttled clients"
  echo "2. Consider webhook optimization"
else
  echo "✓ Throttling levels are acceptable"
  echo "Continue monitoring"
fi

echo ""
echo "For detailed troubleshooting: CLIENT-SIDE-THROTTLING.md"
```

## Quick Reference Commands

```bash
# Count throttling events
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep -c "client-side throttling"

# Find throttled clients
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep "client-side throttling" | \
  grep -oP 'user="[^"]+' | sed 's/user="//' | \
  sort | uniq -c | sort -rn | head -10

# Check tokenreview volume
oc get --raw /metrics | grep apiserver_request_total | grep tokenreviews

# List webhooks
oc get validatingwebhookconfigurations
oc get mutatingwebhookconfigurations

# Fix crashlooping pods
./scale-down-crashloops.sh

# Restart problematic operator
oc delete pod -n <namespace> <pod-name>
```

## Prevention

### 1. Monitor Client Request Rates

```bash
# Set up monitoring for client-side throttling
# Add Prometheus alert:

# alert: HighClientSideThrottling
# expr: |
#   increase(apiserver_client_certificate_expiration_seconds_count{job="apiserver"}[5m]) > 100
# for: 10m
# labels:
#   severity: warning
# annotations:
#   summary: High client-side throttling detected
```

### 2. Webhook Best Practices

- Keep webhook count minimal (<10 total)
- Set appropriate timeouts (10-30s)
- Use `failurePolicy: Ignore` for non-critical webhooks
- Implement webhook caching where possible
- Monitor webhook response times

### 3. Operator/Controller Tuning

- Use exponential backoff for retries
- Implement proper rate limiting
- Use informers/caches instead of direct API calls
- Set appropriate resync periods (5-10 minutes)
- Configure client QPS/Burst appropriately

### 4. Application Best Practices

- Use shared informers for watching resources
- Implement caching for authentication results
- Set reasonable QPS/Burst in client configuration
- Use service account token volume projection
- Avoid tight reconciliation loops

## Related Issues

- [Service Account Token Expiry](SERVICE-ACCOUNT-TOKEN-EXPIRY.md) - Token validation issues
- [High API Request Rate](README.md#2-high-api-request-rate) - Server-side request volume
- [Excessive Webhook Calls](README.md#7-excessive-webhook-calls) - Webhook performance

## Escalation Criteria

Escalate to Red Hat Support if:
- Throttling rate >1000 events/hour sustained
- Critical operators affected
- Unable to identify throttled client
- APF configuration changes don't help
- Cluster operations significantly impacted

**Before escalating:**
```bash
oc adm must-gather
./diagnose-client-throttling.sh > throttling-diagnostic.txt
oc get flowschema -o yaml > flowschema.yaml
oc get prioritylevelconfiguration -o yaml > prioritylevel.yaml
```

---

**Last Updated**: January 2026  
**Version**: 1.0  
**Compatibility**: OpenShift 4.x


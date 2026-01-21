# Troubleshooting: OpenShift API Slowness and Web Console Performance

## Overview

The OpenShift web console depends on the Kubernetes/OpenShift API server for all operations. When the API becomes slow or unresponsive, the web console exhibits poor performance, including slow page loads, timeouts, and unresponsive UI elements.

## Severity

**HIGH** - API slowness impacts all cluster operations, including the web console, CLI commands, CI/CD pipelines, and automated deployments.

## Symptoms

- Web console pages loading slowly (>5 seconds)
- Timeout errors in web console
- `oc` commands taking a long time to respond
- "Unable to connect to the server" errors
- API requests timing out
- Delayed pod/deployment status updates in UI
- OAuth/login delays
- Cluster operator showing degraded status

## 🚨 Emergency Quick Checks - Run This First

**If you're experiencing critical API slowness, start here:**

```bash
# 1. Quick health check (30 seconds)
oc get --raw /healthz
oc get co kube-apiserver
oc get pods -n openshift-kube-apiserver

# 2. Check API server responsiveness
time oc get nodes
time oc get pods -A --limit=50

# 3. Check etcd health (API depends on etcd)
oc get co etcd
oc get pods -n openshift-etcd

# 4. Check API server logs for errors
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=50 | grep -i error

# 5. Check control plane node resources
oc adm top nodes -l node-role.kubernetes.io/master=
```

**What to look for:**

- API health endpoint returning errors → See API Server Issues section
- etcd unhealthy → etcd is the bottleneck (see etcd section)
- High CPU/memory on control plane nodes → Resource constraints
- Timeout errors in API logs → etcd latency or network issues
- Certificate errors → Certificate validation failures

**Quick wins to try first:**

```bash
# If many pending CSRs are causing slowness
oc get csr | grep Pending | wc -l
# If count > 50, approve them:
oc get csr -o name | xargs oc adm certificate approve

# If too many events accumulated
oc get events -A | wc -l
# If count > 50000, consider event TTL adjustment

# Restart console pods if console-specific issue
oc delete pods -n openshift-console -l app=console
```

If the quick checks don't resolve the issue, proceed with the detailed diagnosis below.

---

## Quick Diagnosis

### 1. Measure API Response Time

```bash
# Test API server response time
time oc get --raw /api/v1/namespaces

# Test with different resource types
time oc get nodes
time oc get pods -A --limit=100
time oc get events -A --limit=100

# Check specific API groups
time oc get deployments -A
time oc get configmaps -A --limit=100

# Test OAuth/authentication
time oc whoami
```

**Normal response times:**
- `/api/v1/namespaces`: < 200ms
- `oc get nodes`: < 500ms
- `oc get pods -A --limit=100`: < 1s
- `oc whoami`: < 500ms

### 2. Check API Server Health

```bash
# API server health endpoints
oc get --raw /healthz
oc get --raw /readyz
oc get --raw /livez

# Check API server pods
oc get pods -n openshift-kube-apiserver
oc get pods -n openshift-kube-apiserver -o wide

# Check API server cluster operator
oc get co kube-apiserver -o yaml
```

### 3. Check Web Console Specific Components

```bash
# Check console pods
oc get pods -n openshift-console
oc get pods -n openshift-console-operator

# Check console logs
oc logs -n openshift-console -l app=console --tail=100

# Check OAuth pods (required for console login)
oc get pods -n openshift-authentication
oc get pods -n openshift-oauth-apiserver
```

### 4. Check Dependencies

```bash
# etcd health (critical dependency)
oc get pods -n openshift-etcd
oc get co etcd

# Control plane resources
oc adm top nodes -l node-role.kubernetes.io/master=
oc adm top pods -n openshift-kube-apiserver
oc adm top pods -n openshift-etcd

# Check for control plane node issues
oc get nodes -l node-role.kubernetes.io/master=
oc describe nodes -l node-role.kubernetes.io/master= | grep -A 5 "Conditions:"
```

## Common Root Causes

### 1. etcd Performance Issues

**Symptoms:**
- API calls consistently slow (>1s for simple queries)
- "context deadline exceeded" in API server logs
- etcd fsync taking >100ms
- Degraded etcd cluster operator

**Diagnosis:**

```bash
# Check etcd health
oc get co etcd -o yaml

# Check etcd member health
oc exec -n openshift-etcd etcd-$(oc get nodes -l node-role.kubernetes.io/master= -o jsonpath='{.items[0].metadata.name}') -- \
  etcdctl endpoint health \
  --cluster \
  --cacert=/etc/kubernetes/static-pod-certs/configmaps/etcd-serving-ca/ca-bundle.crt \
  --cert=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-$(oc get nodes -l node-role.kubernetes.io/master= -o jsonpath='{.items[0].metadata.name}').crt \
  --key=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-$(oc get nodes -l node-role.kubernetes.io/master= -o jsonpath='{.items[0].metadata.name}').key

# Check etcd metrics for performance
oc exec -n openshift-etcd etcd-$(oc get nodes -l node-role.kubernetes.io/master= -o jsonpath='{.items[0].metadata.name}') -- \
  etcdctl endpoint status \
  --cluster \
  --write-out=table \
  --cacert=/etc/kubernetes/static-pod-certs/configmaps/etcd-serving-ca/ca-bundle.crt \
  --cert=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-$(oc get nodes -l node-role.kubernetes.io/master= -o jsonpath='{.items[0].metadata.name}').crt \
  --key=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-$(oc get nodes -l node-role.kubernetes.io/master= -o jsonpath='{.items[0].metadata.name}').key

# Check etcd logs for slow operations
oc logs -n openshift-etcd -l app=etcd --tail=100 | grep -i "slow\|latency\|timeout"

# Check disk performance (etcd is disk I/O sensitive)
for node in $(oc get nodes -l node-role.kubernetes.io/master= -o name); do
  echo "=== $node ==="
  oc debug $node -- chroot /host sh -c 'iostat -x 1 3 | grep -A 1 Device'
done
```

**Resolution:**

```bash
# Check etcd database size
oc exec -n openshift-etcd etcd-$(oc get nodes -l node-role.kubernetes.io/master= -o jsonpath='{.items[0].metadata.name}') -- \
  du -sh /var/lib/etcd

# If database is large (>8GB), consider defragmentation
# NOTE: Defrag should be done during maintenance window as it can cause brief unavailability

# Defrag each etcd member one at a time
for member in $(oc get pods -n openshift-etcd -l app=etcd -o name); do
  echo "Defragmenting $member"
  oc exec -n openshift-etcd ${member#pod/} -- etcdctl defrag \
    --cacert=/etc/kubernetes/static-pod-certs/configmaps/etcd-serving-ca/ca-bundle.crt \
    --cert=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-$(echo ${member} | cut -d- -f2-).crt \
    --key=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-$(echo ${member} | cut -d- -f2-).key
  sleep 30
done

# Check if storage is slow (SSD required for etcd)
# Verify etcd is on fast storage with low latency
```

### 2. High API Request Rate

**Symptoms:**
- API server CPU usage consistently high (>80%)
- Many requests in API server logs
- Specific clients making excessive requests
- API rate limiting errors

**Diagnosis:**

```bash
# Check API request metrics
oc get --raw /metrics | grep apiserver_request_total | head -20

# Check audit logs for high-volume clients (if audit logging enabled)
oc adm node-logs --role=master --path=kube-apiserver/audit.log | \
  jq -r '.userAgent' | sort | uniq -c | sort -rn | head -20

# Check for watch requests (can be expensive)
oc get --raw /metrics | grep apiserver_current_inflight_requests

# Identify pods making many API calls
oc adm top pods -A --sort-by=cpu | head -20

# Check for runaway controllers or operators
oc get pods -A -o wide | grep -E "CrashLoopBackOff|Error"
```

**Resolution:**

```bash
# Identify and restart problematic operators/controllers
# Example: If a specific operator is making too many requests
oc get pods -n <problematic-namespace>
oc logs -n <problematic-namespace> <pod-name> | grep -i "api\|request"
oc delete pod -n <problematic-namespace> <pod-name>

# Check for excessive watchers
oc get --raw /metrics | grep apiserver_registered_watchers

# If specific service account is problematic, investigate its usage
oc get pods -A -o json | \
  jq -r '.items[] | select(.spec.serviceAccountName=="<sa-name>") | "\(.metadata.namespace)/\(.metadata.name)"'

# Consider adjusting API priority and fairness (APF) if needed
oc get flowschema
oc get prioritylevelconfiguration
```

### 3. Large Number of Objects

**Symptoms:**
- List operations are slow (especially `get pods -A`, `get events -A`)
- API server memory usage is high
- etcd database is large

**Diagnosis:**

```bash
# Count objects in the cluster
oc get all -A --no-headers | wc -l

# Count specific resource types
echo "Pods: $(oc get pods -A --no-headers | wc -l)"
echo "Events: $(oc get events -A --no-headers | wc -l)"
echo "ConfigMaps: $(oc get configmaps -A --no-headers | wc -l)"
echo "Secrets: $(oc get secrets -A --no-headers | wc -l)"
echo "Replicasets: $(oc get replicasets -A --no-headers | wc -l)"

# Check for old completed pods
oc get pods -A --field-selector=status.phase=Succeeded | wc -l
oc get pods -A --field-selector=status.phase=Failed | wc -l

# Check for excessive events
oc get events -A --sort-by='.lastTimestamp' | tail -100

# Check for old replicasets from deployments
oc get replicasets -A | grep "0         0         0"
```

**Resolution:**

```bash
# Clean up completed pods
oc delete pods -A --field-selector=status.phase=Succeeded
oc delete pods -A --field-selector=status.phase=Failed

# Clean up old replicasets (adjust revisionHistoryLimit)
# Check current settings
oc get deployments -A -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name): \(.spec.revisionHistoryLimit // "10 (default)")"'

# Optionally set revisionHistoryLimit to lower value (e.g., 3)
# This only affects new rollouts
# oc patch deployment <name> -n <namespace> -p '{"spec":{"revisionHistoryLimit":3}}'

# Clean up old events (adjust event TTL)
# Events older than 1 hour by default, but accumulation can happen
# Check if you have excessive events and consider cleaning namespace by namespace

# Delete old events (be careful in production)
# oc delete events -n <namespace> --field-selector=lastTimestamp<2024-01-01T00:00:00Z

# Check and clean up excessive configmaps/secrets if safe to do so
oc get configmaps -A | grep -E "release|helm" | head -20
```

### 4. Control Plane Resource Constraints

**Symptoms:**
- High CPU/memory usage on master nodes
- API server pods being throttled or OOMKilled
- Slow response times correlating with high resource usage

**Diagnosis:**

```bash
# Check master node resources
oc adm top nodes -l node-role.kubernetes.io/master=

# Check API server resource usage
oc adm top pods -n openshift-kube-apiserver

# Check for resource limits
oc get pods -n openshift-kube-apiserver -o json | \
  jq -r '.items[].spec.containers[] | select(.name=="kube-apiserver") | .resources'

# Check for memory pressure on nodes
oc describe nodes -l node-role.kubernetes.io/master= | grep -A 10 "Conditions:"

# Check system resource usage on master nodes
for node in $(oc get nodes -l node-role.kubernetes.io/master= -o name); do
  echo "=== $node ==="
  oc debug $node -- chroot /host top -bn1 | head -20
done
```

**Resolution:**

```bash
# If master nodes are undersized, consider scaling up
# Check current master node specs
oc get nodes -l node-role.kubernetes.io/master= -o json | \
  jq -r '.items[] | "\(.metadata.name): \(.status.capacity.cpu) CPUs, \(.status.capacity.memory) memory"'

# Recommended minimum for production:
# - 3 master nodes
# - 8+ vCPUs per master
# - 32+ GB RAM per master
# - Fast SSD storage for etcd

# Check if garbage collection is running
oc get nodes -o json | jq -r '.items[].status.images | length'

# Force image garbage collection if needed
# This is automatic but can be checked
oc adm top images
```

### 5. Network Latency Issues

**Symptoms:**
- Intermittent API slowness
- Higher latency from certain locations
- Load balancer or network issues

**Diagnosis:**

```bash
# Check API server endpoints
oc get endpoints kubernetes -n default -o yaml

# Test connectivity to API server from different locations
# From local machine
time curl -k https://$(oc whoami --show-server)/healthz

# Check for load balancer issues (if external load balancer is used)
# Test each API server directly
for master in $(oc get nodes -l node-role.kubernetes.io/master= -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'); do
  echo "Testing $master:6443"
  time curl -k https://$master:6443/healthz -m 5
done

# Check for network issues in pods
oc run test-net --image=registry.access.redhat.com/ubi9/ubi:latest --rm -it -- bash
# Inside the pod:
# time curl -k https://kubernetes.default.svc:443/healthz

# Check DNS resolution time
oc run test-dns --image=registry.access.redhat.com/ubi9/ubi:latest --rm -it -- bash
# Inside the pod:
# time nslookup kubernetes.default.svc
```

**Resolution:**

```bash
# If load balancer is the issue, check its configuration
# Verify health checks are properly configured
# Check load balancer logs (platform-specific)

# For internal cluster networking issues
oc get network.operator cluster -o yaml

# Check SDN/OVN health
oc get pods -n openshift-sdn  # For SDN
oc get pods -n openshift-ovn-kubernetes  # For OVN

# Check for pod network issues
oc get co network
```

### 6. Certificate Verification Issues

**Symptoms:**
- TLS handshake timeouts
- Certificate verification errors in logs
- Intermittent connection failures

**Diagnosis:**

```bash
# Check API server certificates
oc get secrets -n openshift-kube-apiserver | grep cert

# Check certificate expiration
for secret in $(oc get secrets -n openshift-kube-apiserver -o name | grep cert); do
  echo "=== $secret ==="
  oc get $secret -n openshift-kube-apiserver -o jsonpath='{.data.tls\.crt}' 2>/dev/null | \
    base64 -d | openssl x509 -noout -dates 2>/dev/null
done

# Check for certificate rotation issues
oc get co kube-apiserver -o yaml | grep -A 10 conditions

# Check service CA bundle
oc get cm -n openshift-kube-apiserver | grep ca-bundle
```

**Resolution:**

```bash
# Force certificate rotation if needed
oc delete secret -n openshift-kube-apiserver <cert-secret-name>

# The cluster will automatically regenerate certificates
# Monitor recovery
watch oc get pods -n openshift-kube-apiserver

# Check if service CA needs rotation
oc get clusteroperator service-ca
```

### 7. Excessive Webhook Calls

**Symptoms:**
- API requests timing out at admission phase
- Webhook timeout errors in API server logs
- Specific operations (like pod creation) are slow

**Diagnosis:**

```bash
# List all webhooks
oc get validatingwebhookconfigurations
oc get mutatingwebhookconfigurations

# Check webhook timeout settings
oc get validatingwebhookconfigurations -o yaml | grep -B 5 timeoutSeconds
oc get mutatingwebhookconfigurations -o yaml | grep -B 5 timeoutSeconds

# Check webhook service availability
for webhook in $(oc get validatingwebhookconfigurations -o name); do
  echo "=== $webhook ==="
  oc get $webhook -o yaml | grep -A 5 "service:"
done

# Check API server logs for webhook timeouts
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=200 | grep -i webhook
```

**Resolution:**

```bash
# Identify slow/failing webhook
# Check the webhook service pods
oc get pods -n <webhook-service-namespace>

# Check webhook service logs
oc logs -n <webhook-service-namespace> <webhook-pod>

# Temporary workaround: Increase webhook timeout (not recommended long-term)
# oc patch validatingwebhookconfiguration <name> --type=json \
#   -p='[{"op": "replace", "path": "/webhooks/0/timeoutSeconds", "value": 30}]'

# Better solution: Fix the webhook service
# Scale up webhook if needed
oc scale deployment -n <webhook-namespace> <webhook-deployment> --replicas=3

# Or temporarily remove problematic webhook (EMERGENCY ONLY)
# oc delete validatingwebhookconfiguration <name>
```

### 8. Audit Logging Overhead

**Symptoms:**
- API server high disk I/O
- Audit log files growing rapidly
- API slowness correlating with audit logging

**Diagnosis:**

```bash
# Check if audit logging is enabled
oc get apiserver cluster -o yaml | grep audit

# Check audit log size on master nodes
for node in $(oc get nodes -l node-role.kubernetes.io/master= -o name); do
  echo "=== $node ==="
  oc debug $node -- chroot /host du -sh /var/log/kube-apiserver/
done

# Check audit policy
oc get apiserver cluster -o yaml | grep -A 20 audit:

# Check disk usage on master nodes
for node in $(oc get nodes -l node-role.kubernetes.io/master= -o name); do
  echo "=== $node ==="
  oc debug $node -- chroot /host df -h | grep -E "Filesystem|/var"
done
```

**Resolution:**

```bash
# Adjust audit policy to reduce logging volume
# This requires editing the cluster API server configuration

# Example: Reduce audit verbosity
oc edit apiserver cluster
# Under spec.audit, adjust the policy

# Or disable audit logging if not required (not recommended for production)
# oc patch apiserver cluster --type=json \
#   -p='[{"op": "remove", "path": "/spec/audit"}]'

# Set up log rotation if not already configured
# Check audit log rotation on master nodes
for node in $(oc get nodes -l node-role.kubernetes.io/master= -o name); do
  echo "=== $node ==="
  oc debug $node -- chroot /host ls -lh /var/log/kube-apiserver/
done
```

## Step-by-Step Troubleshooting Process

### Step 1: Initial Assessment

```bash
# Capture baseline metrics
date
time oc get nodes
time oc get pods -A --limit=100
time oc get --raw /api/v1/namespaces

# Check overall cluster health
oc get co
oc get nodes

# Capture state for comparison
oc get co > co-status-$(date +%Y%m%d-%H%M%S).txt
oc adm top nodes > node-resources-$(date +%Y%m%d-%H%M%S).txt
```

### Step 2: Identify the Bottleneck

```bash
# Check API server health
oc get co kube-apiserver -o yaml
oc get pods -n openshift-kube-apiserver

# Check etcd health (most common bottleneck)
oc get co etcd -o yaml
oc get pods -n openshift-etcd

# Check control plane resources
oc adm top nodes -l node-role.kubernetes.io/master=
oc adm top pods -n openshift-kube-apiserver
oc adm top pods -n openshift-etcd
```

### Step 3: Collect Detailed Logs

```bash
# API server logs
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver \
  --tail=500 > apiserver-logs-$(date +%Y%m%d-%H%M%S).log

# etcd logs
oc logs -n openshift-etcd -l app=etcd \
  --tail=500 > etcd-logs-$(date +%Y%m%d-%H%M%S).log

# Console logs (if web console is the issue)
oc logs -n openshift-console -l app=console \
  --tail=200 > console-logs-$(date +%Y%m%d-%H%M%S).log

# OAuth logs (if login is slow)
oc logs -n openshift-authentication -l app=oauth-openshift \
  --tail=200 > oauth-logs-$(date +%Y%m%d-%H%M%S).log
```

### Step 4: Analyze Patterns

Look for these patterns in logs and metrics:

- **etcd**: "slow", "context deadline exceeded", "high latency"
- **API server**: "timeout", "rate limit", "too many requests"
- **Resources**: CPU/memory usage >80% sustained
- **Network**: "connection refused", "timeout", "TLS handshake"
- **Webhooks**: "webhook", "admission", "timeout"

### Step 5: Apply Targeted Fix

Based on the identified root cause, apply the appropriate resolution from the sections above.

### Step 6: Verify Improvement

```bash
# Re-test API response times
time oc get nodes
time oc get pods -A --limit=100
time oc get --raw /api/v1/namespaces

# Compare with baseline from Step 1
# Should see significant improvement (>50% faster)

# Monitor for sustained improvement
watch -n 5 'time oc get nodes'

# Check web console responsiveness
# Open web console in browser and navigate through pages
```

### Step 7: Monitor for Regression

```bash
# Set up continuous monitoring
while true; do
  echo "=== $(date) ==="
  time oc get nodes 2>&1 | head -5
  sleep 60
done

# Check cluster operators remain healthy
watch oc get co
```

## Emergency Recovery Procedures

### Force API Server Restart

```bash
# Delete API server pods (they will be recreated)
oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver

# Wait for pods to restart
watch oc get pods -n openshift-kube-apiserver

# Verify recovery
time oc get nodes
```

### Force etcd Restart (Use with Caution)

```bash
# Only if etcd is the confirmed bottleneck and other fixes haven't worked
# Restart one etcd pod at a time
for pod in $(oc get pods -n openshift-etcd -l app=etcd -o name); do
  echo "Restarting $pod"
  oc delete -n openshift-etcd $pod
  echo "Waiting for pod to be ready..."
  oc wait --for=condition=Ready -n openshift-etcd $pod --timeout=300s
  sleep 30
done
```

### Emergency: Scale Down Workloads

```bash
# If cluster is overwhelmed, temporarily scale down non-critical workloads
# This reduces API load

# Example: Scale down non-essential operators
oc scale deployment <deployment-name> -n <namespace> --replicas=0

# Document what you scaled down for later restoration!
```

### Console-Specific Recovery

```bash
# If only web console is affected (API is responsive via CLI)

# Restart console pods
oc delete pods -n openshift-console -l app=console

# Restart console operator
oc delete pods -n openshift-console-operator -l app=console-operator

# Check console configuration
oc get console cluster -o yaml

# Test OAuth (required for console login)
oc get pods -n openshift-authentication
oc delete pods -n openshift-authentication --all
```

## Data Collection for Support Cases

If opening a Red Hat support case:

```bash
# Generate must-gather (comprehensive diagnostics)
oc adm must-gather

# Collect specific API server data
oc adm inspect namespace/openshift-kube-apiserver \
  --dest-dir=apiserver-inspect-$(date +%Y%m%d-%H%M%S)

# Collect etcd data
oc adm inspect namespace/openshift-etcd \
  --dest-dir=etcd-inspect-$(date +%Y%m%d-%H%M%S)

# Collect console data
oc adm inspect namespace/openshift-console \
  --dest-dir=console-inspect-$(date +%Y%m%d-%H%M%S)

# Collect performance data
cat > perf-data-$(date +%Y%m%d-%H%M%S).txt << EOF
=== Cluster Version ===
$(oc get clusterversion)

=== Cluster Operators ===
$(oc get co)

=== API Response Times ===
$(time oc get nodes 2>&1)
$(time oc get pods -A --limit=100 2>&1)

=== Master Node Resources ===
$(oc adm top nodes -l node-role.kubernetes.io/master=)

=== API Server Pods ===
$(oc get pods -n openshift-kube-apiserver -o wide)

=== etcd Pods ===
$(oc get pods -n openshift-etcd -o wide)

=== Object Counts ===
Pods: $(oc get pods -A --no-headers | wc -l)
Events: $(oc get events -A --no-headers | wc -l)
ConfigMaps: $(oc get configmaps -A --no-headers | wc -l)
Secrets: $(oc get secrets -A --no-headers | wc -l)
EOF
```

## Prevention and Best Practices

### 1. Monitoring and Alerting

Set up alerts for:

- API response time >1s
- etcd fsync duration >100ms
- API server CPU >80%
- etcd database size >8GB
- High API request rate (>1000 req/s sustained)
- Certificate expiration warnings

```bash
# Example: Create a monitoring script
cat > /usr/local/bin/monitor-api-health.sh << 'EOF'
#!/bin/bash

THRESHOLD=2  # seconds

echo "=== API Health Check $(date) ==="

# Test API response time
START=$(date +%s%N)
oc get nodes > /dev/null 2>&1
END=$(date +%s%N)
DURATION=$(echo "scale=3; ($END - $START) / 1000000000" | bc)

echo "API response time: ${DURATION}s"

if (( $(echo "$DURATION > $THRESHOLD" | bc -l) )); then
  echo "WARNING: API response time exceeds threshold!"
  echo "Running diagnostics..."
  
  echo "=== Cluster Operators ==="
  oc get co | grep -E 'kube-apiserver|etcd'
  
  echo "=== Master Node Resources ==="
  oc adm top nodes -l node-role.kubernetes.io/master=
  
  echo "=== API Server Pods ==="
  oc get pods -n openshift-kube-apiserver
  
  echo "=== etcd Pods ==="
  oc get pods -n openshift-etcd
fi
EOF

chmod +x /usr/local/bin/monitor-api-health.sh
```

### 2. Regular Maintenance

```bash
# Weekly checks
# 1. Check etcd database size
oc exec -n openshift-etcd etcd-$(oc get nodes -l node-role.kubernetes.io/master= -o jsonpath='{.items[0].metadata.name}') -- \
  du -sh /var/lib/etcd

# 2. Clean up old completed pods
oc delete pods -A --field-selector=status.phase=Succeeded
oc delete pods -A --field-selector=status.phase=Failed

# 3. Review object counts
echo "Pods: $(oc get pods -A --no-headers | wc -l)"
echo "Events: $(oc get events -A --no-headers | wc -l)"
echo "ReplicaSets: $(oc get replicasets -A --no-headers | wc -l)"

# 4. Check for excessive events
oc get events -A --no-headers | wc -l

# 5. Review resource usage trends
oc adm top nodes -l node-role.kubernetes.io/master=
```

### 3. Capacity Planning

```bash
# Monitor growth trends
# Track these metrics over time:
# - Number of pods
# - Number of namespaces
# - etcd database size
# - API request rate
# - Master node resource usage

# Recommended sizing:
# Small cluster (<50 nodes): 3 masters, 8 vCPU, 32GB RAM each
# Medium cluster (50-250 nodes): 3 masters, 16 vCPU, 64GB RAM each
# Large cluster (250+ nodes): 5 masters, 16+ vCPU, 64GB+ RAM each

# Always use SSD storage for etcd
```

### 4. Configuration Best Practices

```yaml
# Set appropriate revision history limits in deployments
spec:
  revisionHistoryLimit: 3  # Default is 10

# Configure event TTL (default is 1h)
# Events can accumulate and slow down API

# Use namespaces to organize resources
# Easier to manage and query

# Implement resource quotas to prevent runaway resource creation
apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
spec:
  hard:
    pods: "50"
    configmaps: "25"
    secrets: "25"
```

### 5. Network Optimization

```bash
# Ensure low-latency network between masters
# Use dedicated network for etcd if possible
# Optimize load balancer health checks

# Recommended network requirements:
# - Master-to-master latency: <5ms
# - API load balancer timeout: >30s
# - Health check interval: 10-30s
```

## Performance Tuning

### API Server Tuning

```bash
# Check current API server configuration
oc get apiserver cluster -o yaml

# Common tuning parameters (edit with caution)
# oc edit apiserver cluster

# Example configurations:
# - requestTimeout: Adjust based on workload (default 60s)
# - max-requests-inflight: Increase if needed (default 400)
# - max-mutating-requests-inflight: Increase if needed (default 200)
```

### etcd Tuning

```bash
# Check etcd performance parameters
oc get etcd cluster -o yaml

# For better performance:
# - Ensure etcd is on dedicated fast SSD
# - Isolate etcd traffic network if possible
# - Monitor disk I/O latency (<10ms p99)
```

## Related Documentation

- [OpenShift API Server Architecture](https://docs.openshift.com/container-platform/latest/architecture/control-plane.html)
- [etcd Performance Tuning](https://docs.openshift.com/container-platform/latest/scalability_and_performance/recommended-performance-scale-practices/recommended-etcd-practices.html)
- [OpenShift Web Console](https://docs.openshift.com/container-platform/latest/web_console/web-console.html)
- [API Priority and Fairness](https://kubernetes.io/docs/concepts/cluster-administration/flow-control/)
- [Cluster Monitoring](https://docs.openshift.com/container-platform/latest/monitoring/monitoring-overview.html)

## Quick Reference Commands

```bash
# Check API health and response time
time oc get nodes
oc get --raw /healthz

# Check critical components
oc get co kube-apiserver etcd
oc get pods -n openshift-kube-apiserver
oc get pods -n openshift-etcd

# Check resources
oc adm top nodes -l node-role.kubernetes.io/master=
oc adm top pods -n openshift-kube-apiserver
oc adm top pods -n openshift-etcd

# Quick wins
oc get csr | grep Pending | awk '{print $1}' | xargs oc adm certificate approve
oc delete pods -A --field-selector=status.phase=Succeeded
oc delete pods -A --field-selector=status.phase=Failed

# Console restart
oc delete pods -n openshift-console -l app=console

# Collect diagnostics
oc adm must-gather
oc adm inspect namespace/openshift-kube-apiserver
```

## Escalation Criteria

Open a Red Hat support case if:

- API slowness persists after following this guide
- etcd degradation cannot be resolved
- Production workloads are significantly impacted
- API response times >5s consistently
- Multiple control plane components degraded
- Cluster upgrade blocked due to API issues
- Data loss risk identified

Include must-gather output, performance metrics, and all collected logs with the support case.

## See Also

- [etcd Troubleshooting](../etcd-issues/) (when created)
- [Control Plane Kubeconfigs](../control-plane-kubeconfigs/README.md)
- [kube-controller-manager Crash Loop](../kube-controller-manager-crashloop/README.md)


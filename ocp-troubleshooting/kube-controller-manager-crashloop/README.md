# Troubleshooting: kube-controller-manager Crash Loop in OpenShift

## Overview

The kube-controller-manager is a critical control plane component that runs core Kubernetes controllers. When it crash loops, it can prevent cluster operations like node management, pod scheduling, service account creation, and more.

## Severity

**CRITICAL** - This affects core cluster functionality and should be resolved immediately.

## Symptoms

- kube-controller-manager pods repeatedly restarting
- Control plane degradation
- Unable to create or manage workloads
- Cluster operators showing degraded status
- Events not being processed

## 🚨 Emergency Quick Checks - Run This First

**If you're in a crisis, start here:**

```bash
# 1. Check current status (30 seconds)
oc get pods -n openshift-kube-controller-manager
oc get co kube-controller-manager

# 2. Get the error from logs (look for the root cause)
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=50 --previous

# 3. Check dependencies are healthy
oc get pods -n openshift-etcd && oc get pods -n openshift-kube-apiserver

# 4. Most common fix: Certificate issues - try this if you see TLS/x509 errors
oc delete secret kube-controller-manager-client-cert-key -n openshift-kube-controller-manager
# Then wait 2-3 minutes for automatic regeneration
```

**What to look for in logs:**
- `x509` or `certificate` → Certificate issue (run fix in step 4 above)
- `connection refused` or `timeout` → API server connectivity (check dependencies in step 3)
- `OOM` or `killed` → Resource constraints (see Resource Constraints section below)
- `etcd` or `context deadline exceeded` → etcd issues (check etcd health)

**After applying a fix, verify recovery:**
```bash
watch oc get pods -n openshift-kube-controller-manager
# Wait for pods to be Running and no restarts for 5+ minutes
```

If the quick checks don't resolve the issue, proceed with the detailed diagnosis below.

---

## Quick Diagnosis

### 1. Check Pod Status

```bash
# Check the kube-controller-manager pods
oc get pods -n openshift-kube-controller-manager

# Check for recent restarts
oc get pods -n openshift-kube-controller-manager -o wide

# Get pod details including restart count
oc describe pod -n openshift-kube-controller-manager -l app=kube-controller-manager
```

### 2. View Logs

```bash
# Get logs from the current container
oc logs -n openshift-kube-controller-manager \
  -l app=kube-controller-manager \
  --tail=100

# Get logs from the previous crashed container
oc logs -n openshift-kube-controller-manager \
  -l app=kube-controller-manager \
  --previous

# Follow logs in real-time
oc logs -n openshift-kube-controller-manager \
  -l app=kube-controller-manager \
  -f
```

### 3. Check Events

```bash
# View recent events in the namespace
oc get events -n openshift-kube-controller-manager \
  --sort-by='.lastTimestamp'

# Filter for warning/error events
oc get events -n openshift-kube-controller-manager \
  --field-selector type=Warning
```

## Common Root Causes

### 1. Certificate Issues

**Symptoms:**
- Logs show TLS handshake failures
- Certificate validation errors
- "x509: certificate has expired" messages

**Diagnosis:**

```bash
# Check certificate expiry
oc get secrets -n openshift-kube-controller-manager

# Examine certificate details
oc get secret kube-controller-manager-client-cert-key \
  -n openshift-kube-controller-manager \
  -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# Check certificate dates
oc get secret kube-controller-manager-client-cert-key \
  -n openshift-kube-controller-manager \
  -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -dates -noout
```

**Resolution:**

```bash
# Force certificate rotation
oc delete secret kube-controller-manager-client-cert-key \
  -n openshift-kube-controller-manager

# The cluster should regenerate certificates automatically
# Monitor the recovery
watch oc get pods -n openshift-kube-controller-manager
```

### 2. API Server Connectivity Issues

**Symptoms:**
- "connection refused" errors
- Timeout errors connecting to API server
- "unable to reach API server" messages

**Diagnosis:**

```bash
# Check API server health
oc get pods -n openshift-kube-apiserver

# Check API server endpoints
oc get endpoints kubernetes -n default

# Test connectivity from controller manager pod
oc exec -n openshift-kube-controller-manager \
  $(oc get pod -n openshift-kube-controller-manager -l app=kube-controller-manager -o jsonpath='{.items[0].metadata.name}') \
  -- curl -k https://kubernetes.default.svc:443/healthz
```

**Resolution:**

Check etcd and API server health first, as controller manager depends on them.

```bash
# Check etcd status
oc get pods -n openshift-etcd

# Check API server status  
oc get pods -n openshift-kube-apiserver

# Check cluster operators
oc get clusteroperators
```

### 3. Resource Constraints

**Symptoms:**
- OOMKilled in pod status
- Memory or CPU throttling
- Pod eviction events

**Diagnosis:**

```bash
# Check resource usage
oc adm top pods -n openshift-kube-controller-manager

# Check resource limits
oc get pod -n openshift-kube-controller-manager \
  -l app=kube-controller-manager \
  -o jsonpath='{.items[*].spec.containers[*].resources}'

# Check node resources
oc adm top nodes

# Describe pod to see if OOMKilled
oc describe pod -n openshift-kube-controller-manager \
  -l app=kube-controller-manager | grep -A 5 "Last State"
```

**Resolution:**

```bash
# If OOMKilled, check master node capacity
oc get nodes -l node-role.kubernetes.io/master= -o wide

# Consider scaling master nodes if resource constrained
# This requires infrastructure-level changes
```

### 4. Configuration Errors

**Symptoms:**
- "invalid configuration" errors
- Failed to load configuration
- Parse errors in logs

**Diagnosis:**

```bash
# Check the kubecontrollermanager configuration
oc get kubecontrollermanager cluster -o yaml

# Check for recent changes to the configuration
oc get kubecontrollermanager cluster -o yaml | grep generation

# Check cluster version and operator status
oc get clusterversion
oc get clusteroperator kube-controller-manager
```

**Resolution:**

```bash
# Review recent configuration changes
oc get kubecontrollermanager cluster -o yaml > kcm-config.yaml

# If misconfigured, you may need to patch or restore
# Example: Remove invalid configuration
oc patch kubecontrollermanager cluster --type=json \
  -p='[{"op": "remove", "path": "/spec/problematicField"}]'
```

### 5. Storage/etcd Issues

**Symptoms:**
- "etcdserver: request timed out"
- "context deadline exceeded"
- Failed to list resources

**Diagnosis:**

```bash
# Check etcd health
oc get etcd -o=jsonpath='{range .items[0].status.conditions[?(@.type=="EtcdMembersAvailable")]}{.status}{"\n"}'

# Check etcd pods
oc get pods -n openshift-etcd

# Check etcd metrics endpoint
oc exec -n openshift-etcd etcd-master-0 -- etcdctl endpoint health \
  --cluster \
  --cacert=/etc/kubernetes/static-pod-certs/configmaps/etcd-serving-ca/ca-bundle.crt \
  --cert=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-master-0.crt \
  --key=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-master-0.key
```

**Resolution:**

Fix etcd issues first. See etcd-specific troubleshooting guides.

### 6. Webhook Timeout Issues

**Symptoms:**
- Timeouts calling admission webhooks
- "context deadline exceeded" for webhooks
- Specific webhook names in error messages

**Diagnosis:**

```bash
# List all webhooks
oc get validatingwebhookconfigurations
oc get mutatingwebhookconfigurations

# Check webhook endpoint availability
oc get validatingwebhookconfigurations -o yaml | grep -A 5 "service:"
```

**Resolution:**

```bash
# Temporarily disable problematic webhook (emergency only)
oc delete validatingwebhookconfiguration <webhook-name>

# Or investigate and fix the webhook service
oc get pods -n <webhook-namespace>
```

## Step-by-Step Troubleshooting Process

### Step 1: Initial Assessment

```bash
# Capture current state
oc get clusteroperators > co-status.txt
oc get nodes > nodes.txt
oc get pods -n openshift-kube-controller-manager -o wide > kcm-pods.txt
```

### Step 2: Collect Logs

```bash
# Collect current and previous logs
oc logs -n openshift-kube-controller-manager \
  -l app=kube-controller-manager \
  --tail=500 > kcm-current.log

oc logs -n openshift-kube-controller-manager \
  -l app=kube-controller-manager \
  --previous > kcm-previous.log 2>&1
```

### Step 3: Analyze Error Patterns

Look for these patterns in logs:

- **Certificate errors**: "x509", "certificate", "TLS"
- **Connectivity**: "connection refused", "timeout", "unreachable"
- **Resource**: "OOM", "killed", "memory"
- **Configuration**: "invalid", "parse", "failed to load"
- **Storage**: "etcd", "context deadline exceeded"

### Step 4: Check Dependencies

```bash
# Verify all control plane components
oc get pods -n openshift-etcd
oc get pods -n openshift-kube-apiserver
oc get pods -n openshift-kube-scheduler

# Check cluster operators
oc get co | grep -E 'kube-controller-manager|kube-apiserver|etcd'
```

### Step 5: Check Recent Changes

```bash
# Check recent cluster version updates
oc get clusterversion -o yaml | grep -A 10 history

# Check audit logs for configuration changes (if available)
oc adm node-logs --role=master --path=kube-apiserver/audit.log | \
  grep kubecontrollermanager | tail -50
```

### Step 6: Apply Fix

Based on the root cause identified, apply the appropriate resolution from the sections above.

### Step 7: Verify Recovery

```bash
# Monitor pod status
watch oc get pods -n openshift-kube-controller-manager

# Check cluster operator status
watch oc get co kube-controller-manager

# Verify no crash loops for 5+ minutes
oc get pods -n openshift-kube-controller-manager -w
```

## Emergency Recovery Procedures

### Force Static Pod Regeneration

If the controller manager won't start at all:

```bash
# SSH to master node
oc debug node/<master-node-name>
chroot /host

# Check static pod manifest
cat /etc/kubernetes/manifests/kube-controller-manager-pod.yaml

# Backup the manifest
cp /etc/kubernetes/manifests/kube-controller-manager-pod.yaml \
   /root/kcm-backup.yaml

# Move manifest out temporarily (kubelet will stop the pod)
mv /etc/kubernetes/manifests/kube-controller-manager-pod.yaml \
   /root/kcm-pod.yaml

# Wait 30 seconds

# Move it back (kubelet will restart)
mv /root/kcm-pod.yaml \
   /etc/kubernetes/manifests/kube-controller-manager-pod.yaml
```

### Force Certificate Regeneration

```bash
# Delete all controller manager secrets
oc delete secrets -n openshift-kube-controller-manager \
  -l app=kube-controller-manager

# Wait for automatic regeneration (2-5 minutes)
watch oc get secrets -n openshift-kube-controller-manager
```

### Recovery via Machine Config

If all else fails and the cluster is accessible:

```bash
# Check machine config pool status
oc get mcp

# If needed, pause machine config to prevent unwanted updates
oc patch mcp/master --type merge -p \
  '{"spec":{"paused":true}}'

# After fixing the issue, resume
oc patch mcp/master --type merge -p \
  '{"spec":{"paused":false}}'
```

## Data Collection for Support Cases

If opening a Red Hat support case, collect:

```bash
# Generate must-gather
oc adm must-gather

# Collect specific controller manager data
oc adm inspect namespace/openshift-kube-controller-manager

# Get cluster version details
oc get clusterversion -o yaml > clusterversion.yaml

# Get all cluster operators
oc get co -o yaml > clusteroperators.yaml
```

## Prevention and Best Practices

### 1. Monitoring

Set up alerts for:
- Controller manager pod restarts
- Certificate expiration (30 days warning)
- etcd latency
- API server response times

### 2. Regular Health Checks

```bash
# Create a health check script
cat > /usr/local/bin/check-controlplane.sh << 'EOF'
#!/bin/bash
echo "=== Cluster Operators ==="
oc get co | grep -E 'kube-|etcd'

echo "=== Control Plane Pods ==="
oc get pods -n openshift-kube-controller-manager
oc get pods -n openshift-kube-apiserver
oc get pods -n openshift-etcd

echo "=== Certificate Expiry ==="
oc get nodes -o json | \
  jq -r '.items[].status.addresses[] | select(.type=="InternalIP") | .address' | \
  while read node; do
    echo "Node: $node"
    echo "q" | openssl s_client -connect $node:6443 2>/dev/null | \
      openssl x509 -noout -dates 2>/dev/null
  done
EOF

chmod +x /usr/local/bin/check-controlplane.sh
```

### 3. Change Management

- Always test configuration changes in non-production first
- Document all manual changes to control plane
- Use GitOps for cluster configuration when possible
- Keep backups of critical configurations

### 4. Capacity Planning

- Monitor master node resources
- Plan for growth in cluster size
- Consider dedicated master nodes for large clusters
- Regular etcd performance reviews

## Related Documentation

- [OpenShift Control Plane Architecture](https://docs.openshift.com/container-platform/latest/architecture/control-plane.html)
- [Kubernetes Controller Manager](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/)
- [OpenShift Certificate Management](https://docs.openshift.com/container-platform/latest/security/certificate_types_descriptions.html)
- [etcd Troubleshooting](https://docs.openshift.com/container-platform/latest/backup_and_restore/control_plane_backup_and_restore/disaster_recovery/scenario-2-restoring-cluster-state.html)

## Quick Reference Commands

```bash
# Check status
oc get pods -n openshift-kube-controller-manager
oc get co kube-controller-manager

# View logs
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=100
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --previous

# Check certificates
oc get secrets -n openshift-kube-controller-manager

# Check dependencies
oc get pods -n openshift-etcd
oc get pods -n openshift-kube-apiserver

# Emergency restart (on master node)
systemctl restart kubelet

# Collect diagnostics
oc adm must-gather
oc adm inspect namespace/openshift-kube-controller-manager
```

## Escalation Criteria

Open a Red Hat support case if:
- Issue persists after following this guide
- Data loss risk identified
- Production cluster down for >1 hour
- Multiple control plane components affected
- Cluster upgrade blocked by this issue

Include must-gather output and all collected logs with support case.


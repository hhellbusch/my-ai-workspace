# Installation Phase Monitoring

## Overview

This guide focuses on using control plane kubeconfigs during a fresh OpenShift installation to monitor cluster initialization progress.

## Timeline: When Kubeconfigs Become Available

### Phase 1: Bootstrap Node Active (0-15 minutes)

During this phase, the bootstrap node is running and initializing the control plane.

**Available Access**: None yet on control plane nodes
- Bootstrap node is running temporary control plane
- Permanent control plane nodes are being configured
- Kubeconfigs not yet available on control plane nodes

**What to Monitor**: Bootstrap node progress

```bash
# From installation host
./openshift-install wait-for bootstrap-complete --log-level=debug

# Or SSH to bootstrap node
ssh core@<bootstrap-ip>
journalctl -u bootkube.service -f
```

### Phase 2: Control Plane Initializing (15-20 minutes)

Static pods are starting on control plane nodes.

**Available Access**: Kubeconfigs created but API may not respond yet

```bash
# SSH to a control plane node
ssh core@<control-plane-ip>

# Check if kubeconfig exists
ls -la /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/

# Try to access API (may fail initially)
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get nodes
```

**What to Monitor**: Static pod startup

```bash
# Watch static pods starting
sudo crictl pods

# Check for kube-apiserver
sudo crictl pods | grep kube-apiserver

# Test API server health
curl -k https://localhost:6443/healthz
```

### Phase 3: API Server Available (20-25 minutes)

API server is responding, but bootstrap is still active.

**Available Access**: Localhost kubeconfig fully functional

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Should now work
oc get nodes
oc get co
```

**What to Monitor**: Bootstrap completion

```bash
# Watch for control plane to stabilize
watch -n 5 'oc get nodes && echo "" && oc get co'

# From installation host, wait for bootstrap to complete
./openshift-install wait-for bootstrap-complete
```

### Phase 4: Bootstrap Removed (25-30 minutes)

Bootstrap node is destroyed, control plane is fully operational.

**Available Access**: All kubeconfigs functional

```bash
# Localhost kubeconfig
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Load balancer kubeconfig (now that LB only points to control plane)
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-ext.kubeconfig
```

**What to Monitor**: Operator initialization

```bash
# Watch all operators come online
watch -n 5 'oc get co'

# Or use monitoring script
./monitor-cluster.sh 5
```

### Phase 5: Installation Complete (30-45 minutes)

All cluster operators are available and not degraded.

**Success Criteria**:
- All cluster operators show: `Available=True, Progressing=False, Degraded=False`
- All nodes are `Ready`
- Cluster version shows completion

```bash
# From installation host
./openshift-install wait-for install-complete

# Or check from control plane
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get co | grep -v "True.*False.*False" | wc -l  # Should be 0 (only header line)
```

## Monitoring Strategy by Phase

### Early Phase: Before API Available

**Access Method**: SSH to control plane node, check container runtime

```bash
ssh core@<control-plane-ip>

# Check if static pods exist
sudo crictl pods

# Watch for static pods to start
watch 'sudo crictl pods'

# Check etcd specifically
sudo crictl pods | grep etcd

# Check API server logs (once container starts)
sudo crictl logs $(sudo crictl ps --name kube-apiserver -q 2>/dev/null) 2>/dev/null
```

**Expected Timeline**:
- 0-5 min: Ignition config applied, node reboots
- 5-10 min: Static pod manifests created
- 10-15 min: etcd starts
- 15-20 min: API server starts

### Mid Phase: API Available, Operators Initializing

**Access Method**: Use localhost kubeconfig

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Watch operators initialize
watch -n 5 'oc get co'

# Monitor in detail
watch -n 5 'oc get co && echo "" && oc get nodes && echo "" && oc get pods -A | grep -v Running | grep -v Completed'
```

**Expected Operator Order**:

1. **etcd** (First, must be healthy)
2. **kube-apiserver** (Core API)
3. **kube-controller-manager** (Core controllers)
4. **kube-scheduler** (Core scheduling)
5. **openshift-apiserver** (OpenShift API extensions)
6. **openshift-controller-manager** (OpenShift controllers)
7. **service-ca** (Certificate authority for services)
8. **network** (Cluster networking - OVN/SDN)
9. **dns** (Cluster DNS)
10. **image-registry** (Internal registry)
11. **ingress** (Routes and ingress)
12. **console** (Web console)
13. **monitoring** (Prometheus, Grafana)
14. **storage** (Storage classes)
15. **machine-api** (Machine management)
16. **machine-config** (Node configuration)
17. **All others** (Various operators)

### Late Phase: Waiting for All Operators

**Access Method**: Same as mid phase, but monitor for completion

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Count operators by status
echo "=== Operator Status Summary ==="
echo "Available: $(oc get co -o json | jq '[.items[].status.conditions[] | select(.type=="Available" and .status=="True")] | length')"
echo "Degraded: $(oc get co -o json | jq '[.items[].status.conditions[] | select(.type=="Degraded" and .status=="True")] | length')"
echo "Progressing: $(oc get co -o json | jq '[.items[].status.conditions[] | select(.type=="Progressing" and .status=="True")] | length')"
echo "Total: $(oc get co -o json | jq '.items | length')"

# List any problematic operators
echo ""
echo "=== Problematic Operators ==="
oc get co -o json | jq -r '.items[] | select(.status.conditions[] | select((.type=="Available" and .status=="False") or (.type=="Degraded" and .status=="True"))) | .metadata.name' | sort -u
```

## Complete Installation Monitoring Script

```bash
#!/bin/bash
# Run this on a control plane node during installation

KUBECONFIG_PATH="/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig"

echo "=== OpenShift Installation Monitor ==="
echo "Starting at: $(date)"
echo ""

# Phase 1: Wait for kubeconfig
echo "Phase 1: Waiting for kubeconfig to be created..."
while [ ! -f "$KUBECONFIG_PATH" ]; do
    echo "  Kubeconfig not found yet... (checking every 30s)"
    sleep 30
done
echo "✓ Kubeconfig created at $(date)"
echo ""

export KUBECONFIG="$KUBECONFIG_PATH"

# Phase 2: Wait for API server
echo "Phase 2: Waiting for API server to respond..."
while true; do
    if curl -k -s https://localhost:6443/healthz > /dev/null 2>&1; then
        echo "✓ API server responding at $(date)"
        break
    fi
    echo "  API server not responding yet... (checking every 10s)"
    sleep 10
done
echo ""

# Phase 3: Wait for first node
echo "Phase 3: Waiting for first node to register..."
while true; do
    NODE_COUNT=$(oc get nodes --no-headers 2>/dev/null | wc -l)
    if [ "$NODE_COUNT" -gt 0 ]; then
        echo "✓ First node registered at $(date)"
        oc get nodes
        break
    fi
    echo "  No nodes yet... (checking every 10s)"
    sleep 10
done
echo ""

# Phase 4: Monitor operators
echo "Phase 4: Monitoring cluster operators..."
echo "Press Ctrl+C to stop monitoring"
echo ""

while true; do
    clear
    echo "=== Installation Progress - $(date) ==="
    echo ""
    
    # Get operator stats
    TOTAL=$(oc get co -o json 2>/dev/null | jq '.items | length')
    AVAILABLE=$(oc get co -o json 2>/dev/null | jq '[.items[].status.conditions[] | select(.type=="Available" and .status=="True")] | length')
    DEGRADED=$(oc get co -o json 2>/dev/null | jq '[.items[].status.conditions[] | select(.type=="Degraded" and .status=="True")] | length')
    
    echo "Operators: $AVAILABLE/$TOTAL available, $DEGRADED degraded"
    echo ""
    
    # Show all operators
    oc get co
    echo ""
    
    # Show problematic operators if any
    PROBLEMATIC=$(oc get co -o json 2>/dev/null | jq -r '.items[] | select(.status.conditions[] | select((.type=="Available" and .status=="False") or (.type=="Degraded" and .status=="True"))) | .metadata.name' | sort -u)
    
    if [ -n "$PROBLEMATIC" ]; then
        echo "=== Operators Needing Attention ==="
        echo "$PROBLEMATIC"
        echo ""
    fi
    
    # Show nodes
    echo "=== Nodes ==="
    oc get nodes
    echo ""
    
    # Check if installation is complete
    if [ "$AVAILABLE" -eq "$TOTAL" ] && [ "$DEGRADED" -eq 0 ]; then
        echo "==================================="
        echo "✓ INSTALLATION COMPLETE! ✓"
        echo "==================================="
        echo "Completed at: $(date)"
        break
    fi
    
    sleep 10
done
```

## Common Installation Issues

### API Server Not Starting

**Symptoms**:
- Kubeconfig exists but API doesn't respond
- `curl -k https://localhost:6443/healthz` fails

**Checks**:

```bash
# Check if API server container is running
sudo crictl pods | grep kube-apiserver

# Check API server logs
sudo crictl logs $(sudo crictl ps --name kube-apiserver -q)

# Check etcd (API server depends on it)
sudo crictl pods | grep etcd
sudo crictl logs $(sudo crictl ps --name etcd -q)

# Check static pod manifests
ls -la /etc/kubernetes/manifests/
cat /etc/kubernetes/manifests/kube-apiserver-pod.yaml
```

### etcd Not Starting

**Symptoms**:
- etcd operator not available
- API server logs show etcd connection errors

**Checks**:

```bash
# Check etcd pods
sudo crictl pods | grep etcd

# Check etcd logs
sudo crictl logs $(sudo crictl ps --name etcd -q)

# Check etcd member list (from one control plane)
sudo crictl exec $(sudo crictl ps --name etcd -q) etcdctl member list

# Check etcd health
sudo crictl exec $(sudo crictl ps --name etcd -q) etcdctl endpoint health
```

### Operators Stuck Progressing

**Symptoms**:
- Operator shows Available=True but Progressing=True for extended time
- Some operators never complete

**Checks**:

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Get detailed operator status
oc get co <operator-name> -o yaml

# Check operator pods
oc get pods -n openshift-<operator-name>

# Check operator logs
oc logs -n openshift-<operator-name> <pod-name>

# Check for pending CSRs (common issue)
oc get csr

# Check events
oc get events -n openshift-<operator-name> --sort-by='.lastTimestamp'
```

### Bootstrap Never Completes

**Symptoms**:
- `openshift-install wait-for bootstrap-complete` hangs

**Checks from Control Plane**:

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Check which operators are blocking
oc get co

# Check for certificate signing requests
oc get csr | grep Pending

# Check control plane node readiness
oc get nodes

# Check for critical operators
oc get co etcd kube-apiserver kube-controller-manager kube-scheduler
```

## Installation Success Criteria

### Bootstrap Complete

```bash
# All of these must be true:
# 1. etcd operator Available
oc get co etcd | grep True

# 2. kube-apiserver operator Available
oc get co kube-apiserver | grep True

# 3. kube-controller-manager operator Available
oc get co kube-controller-manager | grep True

# 4. kube-scheduler operator Available
oc get co kube-scheduler | grep True

# 5. All control plane nodes Ready
oc get nodes -l node-role.kubernetes.io/master
```

### Installation Complete

```bash
# All cluster operators must be:
# - Available=True
# - Progressing=False
# - Degraded=False

# Check:
oc get co

# Should show no problematic operators
oc get co | grep -v "True.*False.*False" | tail -n +2 | wc -l  # Should be 0

# Cluster version should be available
oc get clusterversion
```

## Tips for Installation Monitoring

1. **Start monitoring early** - SSH to control plane as soon as bootstrap starts
2. **Use localhost kubeconfig** - It's available before external access works
3. **Monitor static pods first** - Before API is available, watch containers
4. **etcd is critical** - Everything depends on it being healthy
5. **Watch operator order** - Some operators depend on others
6. **Be patient** - Initial installation takes 30-45 minutes
7. **Check CSRs** - Pending certificate requests often block progress
8. **Save logs** - If something fails, logs are critical for debugging

## Automation Example

Save this as `monitor-install.sh` on a control plane node:

```bash
#!/bin/bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Wait for API
until curl -k -s https://localhost:6443/healthz > /dev/null 2>&1; do sleep 5; done

# Monitor until complete
while true; do
    TOTAL=$(oc get co -o json 2>/dev/null | jq '.items | length')
    AVAILABLE=$(oc get co -o json 2>/dev/null | jq '[.items[].status.conditions[] | select(.type=="Available" and .status=="True")] | length')
    DEGRADED=$(oc get co -o json 2>/dev/null | jq '[.items[].status.conditions[] | select(.type=="Degraded" and .status=="True")] | length')
    
    echo "[$(date)] Progress: $AVAILABLE/$TOTAL available, $DEGRADED degraded"
    
    if [ "$AVAILABLE" -eq "$TOTAL" ] && [ "$DEGRADED" -eq 0 ]; then
        echo "Installation complete!"
        break
    fi
    
    sleep 30
done
```

## Related Documentation

- [README.md](./README.md) - Complete kubeconfig guide
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Command reference
- [INDEX.md](./INDEX.md) - Documentation index


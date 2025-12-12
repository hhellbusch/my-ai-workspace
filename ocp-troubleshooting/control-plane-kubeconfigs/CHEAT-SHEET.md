# Control Plane Kubeconfig Cheat Sheet

Quick reference card for accessing OpenShift from control plane nodes.

## 📋 The One Command You Need

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get co -w
```

## 🎯 Quick Access Patterns

### Pattern 1: SSH and Watch (Most Common)

```bash
ssh core@<control-plane-ip>
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get co -w
```

### Pattern 2: One-Liner Status Check

```bash
ssh core@<control-plane-ip> "export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig && oc get co"
```

### Pattern 3: Continuous Monitoring

```bash
ssh core@<control-plane-ip>
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
watch -n 5 'oc get co && echo "" && oc get nodes'
```

## 📁 Kubeconfig Locations

```
Localhost (Primary):
/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

Load Balancer:
/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-ext.kubeconfig

Kubelet (View Only):
/etc/kubernetes/kubeconfig
```

## 🔍 Essential Commands

```bash
# Set kubeconfig (do this first!)
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Watch cluster operators
oc get co -w

# Check all operators
oc get co

# Check specific operator
oc get co <name> -o yaml

# List unhealthy operators
oc get co | grep -v "True.*False.*False"

# Check nodes
oc get nodes

# Check cluster version
oc get clusterversion

# Test API health
curl -k https://localhost:6443/healthz
```

## 🚀 Installation Monitoring

```bash
# Early phase: Check static pods
ssh core@<control-plane-ip>
sudo crictl pods | grep -E "kube-apiserver|etcd"

# Once API is available
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
watch -n 5 'oc get co'

# Count available operators
oc get co -o json | jq '[.items[].status.conditions[] | select(.type=="Available" and .status=="True")] | length'
```

## 🛠️ Troubleshooting Quick Checks

```bash
# 1. Is API server running?
curl -k https://localhost:6443/healthz

# 2. Check static pods
sudo crictl pods

# 3. View API server logs
sudo crictl logs $(sudo crictl ps --name kube-apiserver -q)

# 4. Check etcd
sudo crictl pods | grep etcd

# 5. List problematic operators
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get co -o json | jq -r '.items[] | select(.status.conditions[] | select((.type=="Available" and .status=="False") or (.type=="Degraded" and .status=="True"))) | .metadata.name'
```

## 📊 Status at a Glance

```bash
#!/bin/bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

echo "API Health: $(curl -k -s https://localhost:6443/healthz)"
echo "Nodes: $(oc get nodes --no-headers 2>/dev/null | wc -l) total"
echo "Operators Available: $(oc get co -o json 2>/dev/null | jq '[.items[].status.conditions[] | select(.type=="Available" and .status=="True")] | length')/$(oc get co -o json 2>/dev/null | jq '.items | length')"
echo "Operators Degraded: $(oc get co -o json 2>/dev/null | jq '[.items[].status.conditions[] | select(.type=="Degraded" and .status=="True")] | length')"
```

## 🎬 Complete Workflow

### Scenario: New Installation

```bash
# 1. SSH to control plane (wait ~15 min after bootstrap starts)
ssh core@<control-plane-ip>

# 2. Wait for kubeconfig
while [ ! -f /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig ]; do
    echo "Waiting for kubeconfig..."; sleep 30
done

# 3. Set kubeconfig
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# 4. Wait for API
while ! curl -k -s https://localhost:6443/healthz > /dev/null 2>&1; do
    echo "Waiting for API..."; sleep 10
done

# 5. Watch operators
watch -n 5 'oc get co && echo "" && oc get nodes'

# 6. Installation complete when all operators are Available=True, Degraded=False
```

### Scenario: Troubleshooting Access Issues

```bash
# 1. SSH to control plane
ssh core@<control-plane-ip>

# 2. Test API directly
curl -k https://localhost:6443/healthz

# 3. Check if API server is running
sudo crictl pods | grep kube-apiserver

# 4. If API is healthy, use kubeconfig
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get co

# 5. If API not healthy, check logs
sudo crictl logs $(sudo crictl ps --name kube-apiserver -q)
```

### Scenario: Monitor Specific Operator

```bash
# Set kubeconfig
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Get detailed operator status
oc get co <operator-name> -o yaml

# Watch operator
oc get co <operator-name> -w

# Check operator pods
oc get pods -n openshift-<operator-name>

# View operator logs
oc logs -n openshift-<operator-name> <pod-name>

# Check events
oc get events -n openshift-<operator-name> --sort-by='.lastTimestamp'
```

## 💡 Pro Tips

1. **Alias it**: Add to `~/.bashrc` on control plane nodes
   ```bash
   alias k='export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig && oc'
   ```

2. **Screen/Tmux**: Keep monitoring sessions running
   ```bash
   screen -S monitor
   export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
   watch -n 5 'oc get co'
   # Ctrl+A, D to detach
   # screen -r monitor to reattach
   ```

3. **JSON Output**: For scripting, use JSON + jq
   ```bash
   oc get co -o json | jq '.items[].metadata.name'
   ```

4. **Multiple Control Planes**: You can run commands from any control plane node

5. **Security**: Never copy kubeconfigs off the node - they grant cluster-admin access

## 📚 Full Documentation

- **[README.md](./README.md)** - Complete guide with all details
- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - All commands in one place
- **[INSTALL-MONITORING.md](./INSTALL-MONITORING.md)** - Installation-specific guidance
- **[INDEX.md](./INDEX.md)** - Navigation and use cases
- **[monitor-cluster.sh](./monitor-cluster.sh)** - Automated monitoring script

## 🎯 When to Use Each Kubeconfig

| Scenario | Kubeconfig to Use | Why |
|----------|-------------------|-----|
| Normal monitoring | `localhost.kubeconfig` | Direct to local API, most reliable |
| During installation | `localhost.kubeconfig` | Available before external LB works |
| Test LB connectivity | `lb-ext.kubeconfig` | Verifies load balancer routing |
| Understanding kubelet | `kubeconfig` | See node authentication (view only) |
| External access broken | `localhost.kubeconfig` | Bypass external networking issues |

## ⚡ Emergency Quick Reference

```bash
# API not responding from external?
# → SSH to control plane, use localhost kubeconfig

# Installation stuck?
# → SSH to control plane, watch operators with localhost kubeconfig

# Can't run oc commands?
# → Export KUBECONFIG first!

# Operators degraded?
# → oc get co <name> -o yaml for details

# Need continuous monitoring?
# → Use ./monitor-cluster.sh or watch command
```

## 🔗 Copy-Paste Examples

### Example 1: Quick Health Check

```bash
ssh core@<control-plane-ip> << 'EOF'
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
echo "=== API Health ==="
curl -k -s https://localhost:6443/healthz
echo -e "\n=== Cluster Operators ==="
oc get co
echo -e "\n=== Nodes ==="
oc get nodes
EOF
```

### Example 2: Find Problematic Operators

```bash
ssh core@<control-plane-ip> << 'EOF'
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
echo "=== Degraded or Unavailable Operators ==="
oc get co -o json | jq -r '.items[] | select(.status.conditions[] | select((.type=="Available" and .status=="False") or (.type=="Degraded" and .status=="True"))) | "\(.metadata.name): \(.status.conditions[] | select(.type=="Available" or .type=="Degraded") | "\(.type)=\(.status)")"'
EOF
```

### Example 3: Installation Progress

```bash
ssh core@<control-plane-ip> << 'EOF'
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
TOTAL=$(oc get co -o json | jq '.items | length')
AVAILABLE=$(oc get co -o json | jq '[.items[].status.conditions[] | select(.type=="Available" and .status=="True")] | length')
echo "Installation Progress: $AVAILABLE/$TOTAL operators available"
oc get co | grep -v "True.*False.*False" | tail -n +2
EOF
```

---

**Remember**: Always export `KUBECONFIG` before running `oc` commands!


# Control Plane Kubeconfigs - Index

## Overview

Guide for accessing and using kubeconfig files on OpenShift CoreOS control plane nodes to monitor cluster status.

## Files in This Guide

### 📚 Main Documentation

- **[README.md](./README.md)** - Complete guide to all available kubeconfigs
  - Detailed explanation of each kubeconfig location
  - When to use each kubeconfig
  - Security considerations
  - Troubleshooting tips

### ⚡ Quick References

- **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Copy-paste commands
  - One-line commands for common tasks
  - Kubeconfig paths (ready to copy)
  - Essential monitoring commands
  - Filtering and troubleshooting

- **[CHEAT-SHEET.md](./CHEAT-SHEET.md)** - Ultra-condensed reference card
  - The one command you need
  - Quick access patterns
  - Complete workflows
  - Copy-paste examples

### 📦 Installation Specific

- **[INSTALL-MONITORING.md](./INSTALL-MONITORING.md)** - Installation phase monitoring
  - When kubeconfigs become available
  - Installation progress monitoring
  - Bootstrap completion checks
  - Operator initialization order

### 🔧 Tools

- **[monitor-cluster.sh](./monitor-cluster.sh)** - Automated monitoring script
  - Continuous cluster operator monitoring
  - Color-coded status display
  - Automatic problem detection
  - Node and version tracking

## Quick Start

### 1. Access Control Plane Node

```bash
ssh core@<control-plane-ip>
```

### 2. Set Kubeconfig

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
```

### 3. Watch Cluster Operators

```bash
oc get co -w
```

### Or Use the Monitoring Script

```bash
# Copy script to control plane node
scp monitor-cluster.sh core@<control-plane-ip>:~

# SSH to node and run
ssh core@<control-plane-ip>
chmod +x monitor-cluster.sh
./monitor-cluster.sh
```

## Common Use Cases

### During Installation

1. **Monitor bootstrap completion**
   - [INSTALL-MONITORING.md](./INSTALL-MONITORING.md) - Detailed guide
   - Watch for all cluster operators to become available

2. **Check installation progress**
   ```bash
   export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
   watch -n 5 'oc get co && echo "" && oc get nodes'
   ```

### Troubleshooting

1. **When external access is unavailable**
   - Use localhost kubeconfig from control plane node
   - See [README.md](./README.md) for details

2. **When cluster operators are degraded**
   - Check specific operator status: `oc get co <name> -o yaml`
   - View operator logs and events
   - See [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) for commands

3. **API server connectivity issues**
   - Test local API: `curl -k https://localhost:6443/healthz`
   - Check load balancer: Use lb-ext.kubeconfig
   - See troubleshooting section in [README.md](./README.md)

## Available Kubeconfigs Summary

| Kubeconfig | Path | Use Case |
|------------|------|----------|
| **Localhost** | `/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig` | Primary access from control plane |
| **Load Balancer** | `/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-ext.kubeconfig` | Test LB connectivity |
| **Kubelet** | `/etc/kubernetes/kubeconfig` | Kubelet authentication (view only) |

## Key Commands Reference

```bash
# Export kubeconfig
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Watch cluster operators
oc get co -w

# Check nodes
oc get nodes

# Check cluster version
oc get clusterversion

# View specific operator
oc get co <operator-name> -o yaml

# List unhealthy operators
oc get co | grep -v "True.*False.*False"
```

## Installation Order Reference

Operators typically come online in this order:

1. **etcd** - Must be first
2. **kube-apiserver** - Core API server
3. **kube-controller-manager** - Core controller
4. **kube-scheduler** - Core scheduler
5. **Other operators** - Various cluster services

See [INSTALL-MONITORING.md](./INSTALL-MONITORING.md) for detailed installation timeline.

## Troubleshooting Decision Tree

```
Cannot access cluster from external location
├─ SSH to control plane node ──> Use localhost kubeconfig
├─ API server not responding ──> Check API health (curl localhost:6443/healthz)
└─ Need to debug operators ──> oc get co -o yaml <operator>

Installation appears stuck
├─ Check bootstrap completion ──> See INSTALL-MONITORING.md
├─ Monitor operator progress ──> Use monitor-cluster.sh
└─ Check for degraded operators ──> oc get co | grep -v "True.*False.*False"

Specific operator degraded
├─ Get operator details ──> oc get co <name> -o yaml
├─ Check operator logs ──> oc logs -n openshift-<operator> <pod>
└─ Check events ──> oc get events -n openshift-<operator>
```

## Related Guides

- [CSR Management](../csr-management/) - For node certificate approval
- [Bare Metal Node Inspection](../bare-metal-node-inspection-timeout/) - For baremetal installations
- [CoreOS Networking Issues](../coreos-networking-issues/) - For network problems

## Tips

- **Always use localhost kubeconfig** on control plane nodes
- **Monitor during installation** to catch issues early
- **Check operator order** - some depend on others
- **Use the monitoring script** for continuous tracking
- **Never copy kubeconfigs off the node** - security risk

## Additional Resources

- OpenShift documentation: Control plane node access
- OpenShift documentation: Cluster operators
- CoreOS documentation: Node configuration


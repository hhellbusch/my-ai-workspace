# Control Plane Node Kubeconfigs

## Overview

On an OpenShift CoreOS control plane node, there are several kubeconfig files available that allow you to interact with the cluster without needing credentials from outside the node. This is particularly useful during initial installation, troubleshooting, or when external access is unavailable.

## Available Kubeconfigs

### 1. **Localhost Kubeconfig** (Recommended for Control Plane Access)

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
```

- **Location**: `/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig`
- **Purpose**: Connects to the local API server on `https://localhost:6443`
- **Best for**: Direct access to the local API server on the control plane node
- **User**: `system:admin` (cluster admin privileges)

### 2. **Load Balancer Kubeconfig**

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-ext.kubeconfig
```

- **Location**: `/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-ext.kubeconfig`
- **Purpose**: Connects via the external load balancer endpoint
- **Best for**: Testing load balancer connectivity from control plane
- **User**: `system:admin` (cluster admin privileges)

### 3. **Kubelet Kubeconfig**

```bash
# Read-only - used by kubelet service
cat /etc/kubernetes/kubeconfig
```

- **Location**: `/etc/kubernetes/kubeconfig`
- **Purpose**: Used by the kubelet to authenticate to the API server
- **Best for**: Understanding kubelet authentication (not for general use)
- **User**: `system:node:<hostname>`

### 4. **Static Pod Kubeconfigs**

Located in various static pod resource directories:

```bash
# Kube Controller Manager
/etc/kubernetes/static-pod-resources/kube-controller-manager-pod-*/configmaps/controller-manager-kubeconfig/kubeconfig

# Kube Scheduler
/etc/kubernetes/static-pod-resources/kube-scheduler-pod-*/configmaps/scheduler-kubeconfig/kubeconfig

# Cluster Policy Controller
/etc/kubernetes/static-pod-resources/kube-apiserver-pod-*/configmaps/cluster-policy-controller-kubeconfig/kubeconfig
```

These are used by the control plane components themselves.

## Quick Start: Watching Cluster Operators

### Method 1: Using localhost kubeconfig (Recommended)

```bash
# SSH into a control plane node
ssh core@<control-plane-ip>

# Set the kubeconfig
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Watch cluster operators
oc get clusteroperators -w
```

### Method 2: Using oc with inline kubeconfig

```bash
# One-liner to watch cluster operators
oc --kubeconfig=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig get clusteroperators -w
```

## Common Cluster Operator Commands

### Watch All Cluster Operators

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Watch with auto-refresh
oc get co -w

# Alternative: watch command with 2-second refresh
watch -n 2 'oc get co'
```

### Check Specific Cluster Operator Status

```bash
# Get detailed info about a specific operator
oc get co <operator-name> -o yaml

# Example: Check kube-apiserver operator
oc get co kube-apiserver -o yaml
```

### List Operators Not Available or Degraded

```bash
# Show only problematic operators
oc get co | grep -E "False|True.*True|True.*Unknown"

# More detailed view
oc get co -o json | jq -r '.items[] | select(.status.conditions[] | select(.type=="Available" and .status=="False") or select(.type=="Degraded" and .status=="True")) | .metadata.name'
```

### Continuous Monitoring Script

```bash
#!/bin/bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

while true; do
  clear
  echo "=== Cluster Operators Status - $(date) ==="
  oc get co
  echo ""
  echo "=== Problematic Operators ==="
  oc get co | grep -E "False|True.*True|True.*Unknown" || echo "All operators healthy"
  sleep 5
done
```

## Troubleshooting API Server Access

### Check if API Server is Running

```bash
# Check API server pod
crictl pods | grep kube-apiserver

# Check API server logs
crictl logs $(crictl ps --name kube-apiserver -q)
```

### Test API Server Connectivity

```bash
# Test localhost connection
curl -k https://localhost:6443/healthz

# Should return: ok
```

### Verify Kubeconfig File Exists

```bash
# List available kubeconfigs
ls -la /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/

# Check localhost kubeconfig
cat /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
```

## Installation Phase Monitoring

During a new OpenShift installation, you can monitor progress from a control plane node:

### 1. Wait for Bootstrap to Complete

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Watch for bootstrap to complete
oc get nodes -w
```

### 2. Monitor Cluster Operators Coming Online

```bash
# Watch operators initialize
watch -n 5 'oc get co'

# Look for all operators to become Available=True
```

### 3. Check Installation Progress

```bash
# Get cluster version status
oc get clusterversion

# Watch cluster version progress
oc get clusterversion -o json | jq '.items[0].status.conditions'
```

## Key Points

1. **Localhost kubeconfig** is the most reliable during installation and troubleshooting
2. Files are located in **versioned directories** (e.g., `kube-apiserver-pod-7/`), so you may need to check the latest version
3. All these kubeconfigs provide **cluster-admin** level access
4. The API server must be running for these kubeconfigs to work
5. During early installation, the API server may not be available yet

## Directory Structure Notes

The static pod resources are versioned:

```bash
# Find the latest kube-apiserver pod resources
ls -lt /etc/kubernetes/static-pod-resources/ | grep kube-apiserver-pod

# Access the latest kubeconfig (generic approach)
LATEST_APISERVER=$(ls -t /etc/kubernetes/static-pod-resources/ | grep kube-apiserver-pod | head -1)
export KUBECONFIG=/etc/kubernetes/static-pod-resources/${LATEST_APISERVER}/secrets/node-kubeconfigs/localhost.kubeconfig
```

## Security Considerations

- These kubeconfigs grant **full cluster admin access**
- Access to these files requires **root or core user with sudo**
- They should **never be copied off the control plane nodes**
- Use them only for troubleshooting and monitoring from within the control plane

## See Also

- [Cluster Operator Monitoring](./QUICK-REFERENCE.md)
- [Common Installation Issues](./INSTALL-MONITORING.md)
- [API Server Troubleshooting](../kube-controller-manager-crashloop/)


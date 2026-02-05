# OpenShift NetworkAttachmentDefinition (NAD) Guide

## Overview

NetworkAttachmentDefinitions (NADs) enable pods to connect to additional networks beyond the default pod network. This is commonly used to attach pods to VLANs, physical networks, or other network segments using Multus CNI.

## Use Cases

- **VLAN Segmentation** - Isolate traffic for different applications or tenants
- **Physical Network Access** - Connect pods directly to physical network infrastructure
- **Multi-Network Applications** - Applications requiring multiple network interfaces
- **Legacy System Integration** - Connect containerized apps to existing network infrastructure
- **Network Performance** - Bypass overlay networks for high-performance requirements
- **Security Zones** - Separate management, data, and control plane traffic

## Prerequisites

- OpenShift cluster with Multus CNI (enabled by default on OpenShift)
- Network interface available on nodes for VLAN tagging
- Understanding of your VLAN IDs and network configuration
- Cluster admin or sufficient RBAC permissions to create NADs

## Quick Start

### 1. Create a VLAN-based NAD

```bash
cat <<EOF | oc apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: vlan100
  namespace: default
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens3",
      "mode": "bridge",
      "vlan": 100,
      "ipam": {
        "type": "static"
      }
    }
EOF
```

### 2. Create Pod with NAD Attachment

```bash
oc run my-pod \
  --image=registry.redhat.io/ubi10/ubi:latest \
  --annotations='k8s.v1.cni.cncf.io/networks=vlan100'
```

### 3. Verify Attachment

```bash
# Check pod has additional interface
oc exec my-pod -- ip addr show

# Check network status annotation
oc get pod my-pod -o jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/network-status}' | jq .
```

## NetworkAttachmentDefinition Configuration

### Basic VLAN Configuration

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: vlan-production
  namespace: myapp
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens3",
      "mode": "bridge",
      "vlan": 100,
      "ipam": {
        "type": "static"
      }
    }
```

**Key Fields:**
- `type: macvlan` - Creates macvlan interface for VLAN tagging
- `master: ens3` - Physical interface on the node to use
- `mode: bridge` - Bridge mode allows pods on same host to communicate
- `vlan: 100` - VLAN ID to tag traffic with
- `ipam.type: static` - Static IP assignment (configured per pod)

### VLAN with DHCP

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: vlan-dhcp
  namespace: default
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens3",
      "mode": "bridge",
      "vlan": 200,
      "ipam": {
        "type": "dhcp"
      }
    }
```

**Requirements for DHCP:**
- DHCP server must be available on the VLAN
- dhcp-daemon must be running on nodes (usually automatic)
- May require additional security context for DHCP requests

### VLAN with Static IP Pool (whereabouts)

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: vlan-ippool
  namespace: default
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens3",
      "mode": "bridge",
      "vlan": 300,
      "ipam": {
        "type": "whereabouts",
        "range": "192.168.100.0/24",
        "range_start": "192.168.100.10",
        "range_end": "192.168.100.50",
        "gateway": "192.168.100.1",
        "routes": [
          {
            "dst": "0.0.0.0/0",
            "gw": "192.168.100.1"
          }
        ]
      }
    }
```

**Whereabouts IPAM:**
- Manages IP address pool across the cluster
- Automatically assigns IPs from the range
- Tracks assignments to prevent conflicts
- Supports gateway and routing configuration

### Bridge-based Network (No VLAN)

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: physical-network
  namespace: default
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "br-external",
      "ipam": {
        "type": "whereabouts",
        "range": "10.10.10.0/24"
      }
    }
```

### SR-IOV Network

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: sriov-network
  namespace: default
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "sriov",
      "vlan": 400,
      "ipam": {
        "type": "static"
      }
    }
```

## Attaching Pods to NADs

### Method 1: Using oc run

```bash
# Single NAD
oc run my-pod \
  --image=registry.redhat.io/ubi10/ubi:latest \
  --annotations='k8s.v1.cni.cncf.io/networks=vlan100'

# Multiple NADs
oc run my-pod \
  --image=registry.redhat.io/ubi10/ubi:latest \
  --annotations='k8s.v1.cni.cncf.io/networks=vlan100,vlan200'

# NAD in different namespace
oc run my-pod \
  --image=registry.redhat.io/ubi10/ubi:latest \
  --annotations='k8s.v1.cni.cncf.io/networks=other-namespace/vlan100'

# Interactive toolbox with NAD
oc run -it toolbox \
  --image=registry.redhat.io/ubi10/toolbox:10.1 \
  --privileged=true \
  --annotations='k8s.v1.cni.cncf.io/networks=vlan100'
```

### Method 2: Pod YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  annotations:
    k8s.v1.cni.cncf.io/networks: vlan100
spec:
  containers:
  - name: app
    image: registry.redhat.io/ubi10/ubi:latest
```

### Method 3: Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
      annotations:
        k8s.v1.cni.cncf.io/networks: vlan100
    spec:
      containers:
      - name: app
        image: myapp:latest
```

### Method 4: Multiple Networks with Specific Configuration

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-network-pod
  annotations:
    k8s.v1.cni.cncf.io/networks: |
      [
        {
          "name": "vlan100",
          "interface": "eth1"
        },
        {
          "name": "vlan200",
          "interface": "eth2",
          "ips": ["192.168.200.10/24"],
          "gateway": ["192.168.200.1"]
        }
      ]
spec:
  containers:
  - name: app
    image: myapp:latest
```

## Static IP Assignment

When using `static` IPAM type, you must specify IPs in the pod annotation:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-ip-pod
  annotations:
    k8s.v1.cni.cncf.io/networks: |
      [
        {
          "name": "vlan100",
          "interface": "net1",
          "ips": ["192.168.100.50/24"],
          "gateway": ["192.168.100.1"],
          "mac": "02:23:45:67:89:01"
        }
      ]
spec:
  containers:
  - name: app
    image: myapp:latest
```

## Verification and Troubleshooting

### Check NAD Exists

```bash
# List NADs in current namespace
oc get network-attachment-definitions

# List NADs in all namespaces
oc get network-attachment-definitions -A

# View NAD configuration
oc get network-attachment-definition vlan100 -o yaml

# Describe NAD (shows events if any)
oc describe network-attachment-definition vlan100
```

### Verify Pod Network Attachment

```bash
# Check pod annotations
oc get pod my-pod -o yaml | grep -A 10 annotations

# Check network-status annotation
oc get pod my-pod -o jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/network-status}' | jq .

# Check interfaces inside pod
oc exec my-pod -- ip addr show

# Check routes
oc exec my-pod -- ip route show

# Check specific interface details
oc exec my-pod -- ip addr show net1
```

### Test Network Connectivity

```bash
# Test connectivity on additional interface
oc exec my-pod -- ping -I net1 192.168.100.1

# Check if VLAN tagging is working (from node)
oc debug node/<node-name>
chroot /host
tcpdump -i ens3 -e -n vlan 100
```

### Check Multus Status

```bash
# Verify multus pods are running
oc get pods -n openshift-multus

# Check multus logs
oc logs -n openshift-multus <multus-pod> --tail=50

# Verify multus configuration
oc get network.operator.openshift.io cluster -o yaml
```

### Common Issues

#### Issue: Pod fails to start with "error adding network"

**Symptoms:**
```
Error: error adding container to network "vlan100": plugin type "macvlan" failed
```

**Possible Causes:**
1. NAD doesn't exist in the namespace
2. Master interface doesn't exist on the node
3. VLAN configuration conflicts
4. Insufficient permissions

**Debug:**
```bash
# Check NAD exists
oc get network-attachment-definition vlan100

# Check which node pod is scheduled on
oc get pod my-pod -o wide

# Debug the node
oc debug node/<node-name>
chroot /host

# Check if master interface exists
ip link show ens3

# Check for existing VLAN configuration
ip link show | grep vlan
```

#### Issue: No additional interface appears in pod

**Check:**
```bash
# Verify annotation was applied
oc get pod my-pod -o jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/networks}'

# Check pod events
oc describe pod my-pod

# Check multus logs
oc logs -n openshift-multus -l app=multus --tail=50
```

#### Issue: Static IP assignment fails

**Error:**
```
failed to set up pod network: IPAM: failed to assign IP
```

**Fix:**
Ensure IP configuration is in the pod annotation:
```yaml
annotations:
  k8s.v1.cni.cncf.io/networks: |
    [
      {
        "name": "vlan100",
        "ips": ["192.168.100.50/24"]
      }
    ]
```

#### Issue: DHCP not working

**Check:**
```bash
# Check if dhcp-daemon is running on nodes
oc debug node/<node-name>
chroot /host
systemctl status dhcp-daemon

# Check DHCP server is reachable on VLAN
tcpdump -i ens3.100 port 67 or port 68
```

#### Issue: Cannot reach gateway on VLAN

**Debug:**
```bash
# Inside pod
oc exec my-pod -- ip route show

# Should see route via VLAN interface
# If not, may need to add static route

# Test layer 2 connectivity
oc exec my-pod -- arping -I net1 192.168.100.1

# Check from node
oc debug node/<node-name>
chroot /host
tcpdump -i ens3.100 -n
```

## Real-World Examples

### Example 1: Database Pods on Isolated VLAN

**Scenario:** PostgreSQL databases need to be on isolated management VLAN (VLAN 100)

```yaml
# Create NAD
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: db-vlan
  namespace: database
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens3",
      "mode": "bridge",
      "vlan": 100,
      "ipam": {
        "type": "whereabouts",
        "range": "10.100.0.0/24",
        "range_start": "10.100.0.10",
        "range_end": "10.100.0.50",
        "gateway": "10.100.0.1"
      }
    }
---
# Create StatefulSet with NAD
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql
  namespace: database
spec:
  serviceName: postgresql
  replicas: 3
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
      annotations:
        k8s.v1.cni.cncf.io/networks: db-vlan
    spec:
      containers:
      - name: postgresql
        image: registry.redhat.io/rhel9/postgresql-15:latest
        ports:
        - containerPort: 5432
```

### Example 2: Troubleshooting Toolbox on VLAN

**Scenario:** Need to troubleshoot connectivity to servers on VLAN 200

```bash
# Create NAD for VLAN 200
cat <<EOF | oc apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: vlan200
  namespace: default
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens3",
      "mode": "bridge",
      "vlan": 200,
      "ipam": {
        "type": "static"
      }
    }
EOF

# Create toolbox with static IP on VLAN 200
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: vlan-toolbox
  annotations:
    k8s.v1.cni.cncf.io/networks: |
      [
        {
          "name": "vlan200",
          "interface": "net1",
          "ips": ["192.168.200.100/24"],
          "gateway": ["192.168.200.1"]
        }
      ]
spec:
  containers:
  - name: toolbox
    image: registry.redhat.io/ubi10/toolbox:10.1
    command: ["/bin/bash", "-c", "sleep infinity"]
    securityContext:
      privileged: true
EOF

# Wait for pod to be ready
oc wait --for=condition=ready pod/vlan-toolbox --timeout=60s

# Exec into toolbox
oc exec -it vlan-toolbox -- bash

# Inside toolbox - test VLAN connectivity
ip addr show net1
ping -I net1 192.168.200.1
dnf install -y mtr
mtr -s 1472 -I net1 192.168.200.10
```

### Example 3: Application with Multiple VLANs

**Scenario:** Application needs access to both data VLAN (100) and management VLAN (200)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-vlan-app
  annotations:
    k8s.v1.cni.cncf.io/networks: |
      [
        {
          "name": "data-vlan",
          "interface": "data",
          "ips": ["10.100.0.50/24"]
        },
        {
          "name": "mgmt-vlan",
          "interface": "mgmt",
          "ips": ["10.200.0.50/24"]
        }
      ]
spec:
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: DATA_INTERFACE
      value: "data"
    - name: MGMT_INTERFACE
      value: "mgmt"
```

### Example 4: SR-IOV High-Performance Network

**Scenario:** High-throughput application requiring SR-IOV

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: sriov-high-perf
  namespace: default
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "sriov",
      "vlan": 100,
      "vlanQoS": 6,
      "ipam": {
        "type": "whereabouts",
        "range": "192.168.100.0/24"
      }
    }
---
apiVersion: v1
kind: Pod
metadata:
  name: high-perf-app
  annotations:
    k8s.v1.cni.cncf.io/networks: sriov-high-perf
spec:
  containers:
  - name: app
    image: high-perf-app:latest
    resources:
      requests:
        openshift.io/sriov: '1'
      limits:
        openshift.io/sriov: '1'
```

## Best Practices

### 1. NAD Organization

- Create NADs in the same namespace as pods that will use them
- Use descriptive names: `vlan100-production`, `db-network`, etc.
- Document VLAN IDs and IP ranges in NAD descriptions
- Use namespace-specific NADs for isolation

### 2. IPAM Strategy

- **DHCP**: Best for dynamic environments, requires DHCP server
- **Whereabouts**: Best for static pools, automatic assignment
- **Static**: Best for specific IP requirements, manual configuration

### 3. Security

- Use NetworkPolicies in addition to VLAN segmentation
- Limit NAD access using RBAC
- Consider using privileged containers only when necessary
- Monitor network traffic for anomalies

### 4. Testing

- Test NAD configuration with debug pods before deploying applications
- Verify connectivity from pod to gateway
- Test MTU settings if using overlay or tunnel networks
- Document working configurations

### 5. Naming Conventions

```yaml
# Good naming
vlan100-production
vlan200-database
vlan300-management
sriov-high-bandwidth

# Avoid
network1, test, my-network
```

## Reference Commands

See [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) for copy-paste ready commands.

## Related Documentation

- [Debug Toolbox Container](../../ocp-troubleshooting/debug-toolbox-container/README.md) - Using toolbox with NADs
- [AAP SSH MTU Issues](../../ocp-troubleshooting/aap-ssh-mtu-issues/README.md) - MTU testing relevant for VLAN networks
- [CoreOS Networking](../../ocp-troubleshooting/coreos-networking-issues/README.md) - Node-level network configuration

## Additional Resources

- [Multus CNI Documentation](https://github.com/k8snetworkplumbingwg/multus-cni)
- [OpenShift Multiple Networks Documentation](https://docs.openshift.com/container-platform/latest/networking/multiple_networks/understanding-multiple-networks.html)
- [Network Plumbing Working Group](https://github.com/k8snetworkplumbingwg)

---

**AI Disclosure:** This documentation was created with AI assistance to provide comprehensive guidance for OpenShift NetworkAttachmentDefinition configuration.

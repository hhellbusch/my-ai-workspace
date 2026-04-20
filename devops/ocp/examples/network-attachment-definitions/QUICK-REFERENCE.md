# NetworkAttachmentDefinition (NAD) - Quick Reference

Fast command reference for OpenShift NADs and VLAN configuration.

## Create NADs

### Basic VLAN with Static IPAM
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

### VLAN with DHCP
```bash
cat <<EOF | oc apply -f -
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
EOF
```

### VLAN with IP Pool (whereabouts)
```bash
cat <<EOF | oc apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: vlan-pool
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
        "gateway": "192.168.100.1"
      }
    }
EOF
```

## Attach Pods to NADs

### Using oc run

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
  --annotations='k8s.v1.cni.cncf.io/networks=other-ns/vlan100'

# Interactive toolbox with NAD
oc run -it toolbox \
  --image=registry.redhat.io/ubi10/toolbox:10.1 \
  --privileged=true \
  --annotations='k8s.v1.cni.cncf.io/networks=vlan100'
```

### Pod with Static IP
```bash
cat <<EOF | oc apply -f -
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
          "gateway": ["192.168.100.1"]
        }
      ]
spec:
  containers:
  - name: app
    image: registry.redhat.io/ubi10/ubi:latest
EOF
```

### Deployment with NAD
```bash
cat <<EOF | oc apply -f -
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
EOF
```

## Verification Commands

### Check NADs
```bash
# List NADs in current namespace
oc get network-attachment-definitions

# List NADs in all namespaces
oc get network-attachment-definitions -A

# View NAD configuration
oc get net-attach-def vlan100 -o yaml

# Describe NAD
oc describe net-attach-def vlan100
```

### Verify Pod Attachment
```bash
# Check pod annotation
oc get pod my-pod -o jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/networks}'

# Check network status
oc get pod my-pod -o jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/network-status}' | jq .

# Check interfaces
oc exec my-pod -- ip addr show

# Check routes
oc exec my-pod -- ip route show

# Check specific interface
oc exec my-pod -- ip addr show net1
```

### Test Connectivity
```bash
# Ping via specific interface
oc exec my-pod -- ping -I net1 192.168.100.1

# Test with mtr
oc exec my-pod -- mtr -s 1472 -I net1 192.168.100.10

# Check VLAN tagging (from node)
oc debug node/<node-name>
chroot /host
tcpdump -i ens3 -e -n vlan 100
```

## Troubleshooting

### Check Multus
```bash
# Verify multus pods running
oc get pods -n openshift-multus

# Check multus logs
oc logs -n openshift-multus -l app=multus --tail=50

# Verify multus configuration
oc get network.operator.openshift.io cluster -o yaml
```

### Debug Pod Network Issues
```bash
# Check pod events
oc describe pod my-pod

# Check which node pod is on
oc get pod my-pod -o wide

# Debug the node
oc debug node/<node-name>
chroot /host

# Check master interface exists
ip link show ens3

# Check for VLAN interfaces
ip link show | grep vlan

# Monitor network
tcpdump -i ens3 -n
```

### Common Fixes

#### NAD doesn't exist
```bash
# Create NAD first
oc apply -f nad.yaml

# Verify it exists
oc get net-attach-def
```

#### Pod can't find NAD in different namespace
```bash
# Use namespace/name format
oc run my-pod \
  --image=ubi:latest \
  --annotations='k8s.v1.cni.cncf.io/networks=other-namespace/vlan100'
```

#### Static IP assignment fails
```bash
# Must specify IP in pod annotation
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  annotations:
    k8s.v1.cni.cncf.io/networks: |
      [
        {
          "name": "vlan100",
          "ips": ["192.168.100.50/24"]
        }
      ]
spec:
  containers:
  - name: app
    image: ubi:latest
EOF
```

## Quick Debug Toolbox on VLAN

### One-Command Toolbox with Static IP
```bash
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: vlan-toolbox
  annotations:
    k8s.v1.cni.cncf.io/networks: |
      [
        {
          "name": "vlan100",
          "interface": "net1",
          "ips": ["192.168.100.200/24"],
          "gateway": ["192.168.100.1"]
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

# Wait and connect
oc wait --for=condition=ready pod/vlan-toolbox --timeout=60s
oc exec -it vlan-toolbox -- bash

# Inside: install tools and test
dnf install -y mtr traceroute
ip addr show net1
ping -I net1 192.168.100.1
mtr -I net1 192.168.100.10

# Clean up
exit
oc delete pod vlan-toolbox
```

### Toolbox with DHCP
```bash
oc run -it vlan-toolbox \
  --image=registry.redhat.io/ubi10/toolbox:10.1 \
  --privileged=true \
  --annotations='k8s.v1.cni.cncf.io/networks=vlan-dhcp' \
  --rm -- bash

# Inside: check IP assignment
ip addr show net1
```

## Common NAD Templates

### Template: Production VLAN
```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: production-vlan
  namespace: production
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
        "gateway": "10.100.0.1"
      }
    }
```

### Template: Database VLAN
```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: database-vlan
  namespace: database
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens3",
      "mode": "bridge",
      "vlan": 200,
      "ipam": {
        "type": "whereabouts",
        "range": "10.200.0.0/24",
        "range_start": "10.200.0.10",
        "range_end": "10.200.0.100",
        "gateway": "10.200.0.1"
      }
    }
```

### Template: Management VLAN
```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: management-vlan
  namespace: management
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "ens3",
      "mode": "bridge",
      "vlan": 300,
      "ipam": {
        "type": "static"
      }
    }
```

## Interface Naming

| Interface | Description |
|-----------|-------------|
| `eth0` | Default pod network (always present) |
| `net1` | First additional network from NAD |
| `net2` | Second additional network |
| `net3` | Third additional network |
| Custom | Can be specified in pod annotation |

## IPAM Types

| Type | Use Case | Configuration |
|------|----------|---------------|
| `static` | Manually assigned IPs | Must specify in pod annotation |
| `dhcp` | Dynamic from DHCP server | DHCP server must be on VLAN |
| `whereabouts` | Managed IP pool | Range specified in NAD |
| `host-local` | Per-node IP pools | Deprecated, use whereabouts |

## Network Types

| Type | Description | Use Case |
|------|-------------|----------|
| `macvlan` | VLAN tagging, layer 2 | VLANs, physical networks |
| `bridge` | Linux bridge | Simple bridging |
| `sriov` | SR-IOV passthrough | High performance |
| `ipvlan` | IP-based isolation | Alternative to macvlan |

## One-Liners

```bash
# List all NADs with their namespaces
oc get net-attach-def -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,AGE:.metadata.creationTimestamp

# Find all pods using specific NAD
oc get pods -A -o json | jq -r '.items[] | select(.metadata.annotations."k8s.v1.cni.cncf.io/networks" != null) | "\(.metadata.namespace)/\(.metadata.name): \(.metadata.annotations."k8s.v1.cni.cncf.io/networks")"'

# Check network status for all pods in namespace
oc get pods -o json | jq -r '.items[] | "\(.metadata.name): \(.metadata.annotations."k8s.v1.cni.cncf.io/network-status" | fromjson | .[].name)"'

# Create NAD from one-liner
oc create -f - <<EOF
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: quick-vlan
spec:
  config: '{"cniVersion":"0.3.1","type":"macvlan","master":"ens3","mode":"bridge","vlan":100,"ipam":{"type":"static"}}'
EOF
```

---

**See:** [README.md](./README.md) for detailed explanations and examples.

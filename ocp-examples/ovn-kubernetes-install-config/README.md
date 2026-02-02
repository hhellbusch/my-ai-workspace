# OVN-Kubernetes Install-Time Configuration Guide

## Overview

This guide covers how to configure OVN-Kubernetes networking settings at OpenShift install time using the `install-config.yaml` file. These settings **cannot be changed after installation**, so it's critical to configure them correctly before running the installer.

## Table of Contents

- [Quick Start](#quick-start)
- [Configuration Reference](#configuration-reference)
- [Network Subnet Planning](#network-subnet-planning)
- [Common Scenarios](#common-scenarios)
- [Pre-Installation Checklist](#pre-installation-checklist)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Quick Start

For quick copy-paste examples, see [QUICK-REFERENCE.md](./QUICK-REFERENCE.md).

For complete configuration scenarios, see [EXAMPLES.md](./EXAMPLES.md).

For post-install verification, see [VERIFICATION.md](./VERIFICATION.md).

---

## Configuration Reference

### Basic Structure

The `ovnKubernetesConfig` section goes under `networking` in your `install-config.yaml`:

```yaml
apiVersion: v1
baseDomain: example.com
metadata:
  name: my-cluster
networking:
  networkType: OVNKubernetes  # Required for OVN-Kubernetes
  clusterNetwork:
  - cidr: 10.128.0.0/14       # Pod network
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16             # Service network
  machineNetwork:
  - cidr: 10.0.0.0/16         # Physical network
  ovnKubernetesConfig:
    # OVN-Kubernetes specific settings
    mtu: 1400
    genevePort: 6081
    ipv4:
      internalJoinSubnet: 10.245.0.0/16
    gatewayConfig:
      routingViaHost: false
      ipv4:
        internalMasqueradeSubnet: 169.254.0.0/17
        internalTransitSwitchSubnet: 10.246.0.0/16
    ipsecConfig:
      mode: Disabled
    policyAuditConfig:
      destination: "null"
      maxFileSize: 50
      rateLimit: 20
      syslogFacility: local0
```

---

## Configuration Parameters

### Top-Level Parameters

| Parameter | Type | Default | Description | Can Change Post-Install? |
|-----------|------|---------|-------------|--------------------------|
| `mtu` | integer | 1400 | Maximum Transmission Unit for overlay network | ❌ No |
| `genevePort` | integer | 6081 | UDP port for Geneve encapsulation | ❌ No |

### IPv4 Parameters

| Parameter | Type | Default | Description | Can Change Post-Install? |
|-----------|------|---------|-------------|--------------------------|
| `ipv4.internalJoinSubnet` | CIDR | 100.64.0.0/16 | Subnet for node-to-overlay routing (ovn-k8s-mp0 interface) | ❌ No |

### Gateway Config Parameters

| Parameter | Type | Default | Description | Can Change Post-Install? |
|-----------|------|---------|-------------|--------------------------|
| `gatewayConfig.routingViaHost` | boolean | false | Route egress traffic via host network stack | ⚠️ Complex |
| `gatewayConfig.ipv4.internalMasqueradeSubnet` | CIDR | 169.254.169.0/29 | Subnet for masquerading pod-to-external traffic | ❌ No |
| `gatewayConfig.ipv4.internalTransitSwitchSubnet` | CIDR | 100.88.0.0/16 | Transit network between node and OVN gateway | ❌ No |

### IPsec Config Parameters

| Parameter | Type | Default | Description | Can Change Post-Install? |
|-----------|------|---------|-------------|--------------------------|
| `ipsecConfig.mode` | string | Disabled | IPsec encryption mode: `Disabled`, `Full`, or `External` | ✅ Yes (via Network Operator) |

### Policy Audit Config Parameters

| Parameter | Type | Default | Description | Can Change Post-Install? |
|-----------|------|---------|-------------|--------------------------|
| `policyAuditConfig.destination` | string | "null" | Audit log destination: `"null"`, `"libc"`, or `"udp:<host>:<port>"` | ✅ Yes |
| `policyAuditConfig.maxFileSize` | integer | 50 | Max log file size in MB | ✅ Yes |
| `policyAuditConfig.rateLimit` | integer | 20 | Log messages per second | ✅ Yes |
| `policyAuditConfig.syslogFacility` | string | local0 | Syslog facility (local0-local7, kern, user, etc.) | ✅ Yes |

---

## Network Subnet Planning

### Critical Rule: No Overlapping Networks

Ensure these subnets do not overlap with each other or any external networks:

```
clusterNetwork (pods):              10.128.0.0/14
serviceNetwork (services):          172.30.0.0/16
machineNetwork (physical):          10.0.0.0/16

OVN Internal Networks:
├─ internalJoinSubnet:             10.245.0.0/16
├─ internalMasqueradeSubnet:       169.254.0.0/17
└─ internalTransitSwitchSubnet:    10.246.0.0/16
```

### Subnet Purpose and Requirements

#### 1. Internal Join Subnet (`ipv4.internalJoinSubnet`)

**Purpose:** Routing interface between node and OVN overlay network

**Default:** `100.64.0.0/16`

**Requirements:**
- Must not overlap with any other network
- Used for the `ovn-k8s-mp0` interface on each node
- Traffic flows through this interface for pod-to-pod communication

**When to customize:**
- Default conflicts with your existing networks
- You're using RFC 6598 address space (100.64.0.0/10) elsewhere

**Example:**
```yaml
ipv4:
  internalJoinSubnet: 10.245.0.0/16
```

#### 2. Internal Masquerade Subnet (`gatewayConfig.ipv4.internalMasqueradeSubnet`)

**Purpose:** Source NAT (masquerade) addresses for pod traffic to external networks

**Default:** `169.254.169.0/29` (8 addresses)

**Requirements:**
- Link-local address space (169.254.0.0/16)
- Size depends on number of nodes and egress traffic patterns
- Each node's gateway uses addresses from this range

**When to customize:**
- Large clusters requiring more masquerade addresses
- Avoiding conflicts with existing link-local usage

**Example:**
```yaml
gatewayConfig:
  ipv4:
    internalMasqueradeSubnet: 169.254.0.0/17  # 32,768 addresses
```

#### 3. Internal Transit Switch Subnet (`gatewayConfig.ipv4.internalTransitSwitchSubnet`)

**Purpose:** Internal routing between node and OVN gateway router

**Default:** `100.88.0.0/16`

**Requirements:**
- Must not overlap with any other network
- Pure OVN internal routing fabric
- Not directly visible on nodes

**When to customize:**
- Default conflicts with your network addressing

**Example:**
```yaml
gatewayConfig:
  ipv4:
    internalTransitSwitchSubnet: 10.246.0.0/16
```

---

## Common Scenarios

### Scenario 1: Custom Internal Subnets (Your Configuration)

**Use Case:** Default OVN internal subnets conflict with existing infrastructure

**Configuration:**
```yaml
networking:
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16
  machineNetwork:
  - cidr: 10.0.0.0/16
  ovnKubernetesConfig:
    ipv4:
      internalJoinSubnet: 10.245.0.0/16
    gatewayConfig:
      ipv4:
        internalMasqueradeSubnet: 169.254.0.0/17
        internalTransitSwitchSubnet: 10.246.0.0/16
```

**Why:**
- Avoids conflicts with 100.64.0.0/10 (RFC 6598 Carrier-Grade NAT)
- Provides larger masquerade subnet for scaling
- Uses dedicated internal addressing space

### Scenario 2: IPsec Encryption

**Use Case:** Encrypt all pod-to-pod traffic for compliance/security

**Configuration:**
```yaml
ovnKubernetesConfig:
  ipsecConfig:
    mode: Full  # Encrypts all pod-to-pod traffic
```

**Impact:**
- ✅ Encrypts pod-to-pod traffic using IPsec
- ⚠️ Increases CPU utilization (5-15% depending on traffic)
- ⚠️ May reduce network throughput (5-10%)
- ✅ Can be enabled/disabled post-install

### Scenario 3: Jumbo Frames

**Use Case:** High-performance workloads with jumbo frame support

**Configuration:**
```yaml
ovnKubernetesConfig:
  mtu: 9000  # Jumbo frames
```

**Requirements:**
- Physical network must support MTU 9000+
- All switches/routers in path must support jumbo frames
- Must be set at install time (cannot change later)

### Scenario 4: Custom Geneve Port

**Use Case:** Port 6081 conflicts with existing services

**Configuration:**
```yaml
ovnKubernetesConfig:
  genevePort: 6082  # Non-default port
```

**Requirements:**
- Firewall rules must allow UDP traffic on custom port
- Must be set at install time (cannot change later)

### Scenario 5: Dual Stack (IPv4 + IPv6)

**Use Case:** Support both IPv4 and IPv6 pod networking

**Configuration:**
```yaml
networking:
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  - cidr: fd01::/48
    hostPrefix: 64
  serviceNetwork:
  - 172.30.0.0/16
  - fd02::/112
  ovnKubernetesConfig:
    ipv4:
      internalJoinSubnet: 10.245.0.0/16
    ipv6:
      internalJoinSubnet: fd98::/64
    gatewayConfig:
      ipv4:
        internalTransitSwitchSubnet: 10.246.0.0/16
      ipv6:
        internalTransitSwitchSubnet: fd97::/64
```

---

## Pre-Installation Checklist

Before running `openshift-install create cluster`, verify:

### Network Planning
- [ ] All subnets planned and documented
- [ ] No overlapping between cluster, service, machine networks
- [ ] No overlapping with OVN internal networks
- [ ] No overlapping with external networks cluster needs to access

### OVN Configuration
- [ ] `internalJoinSubnet` doesn't conflict with existing networks
- [ ] `internalTransitSwitchSubnet` doesn't conflict with existing networks
- [ ] `internalMasqueradeSubnet` sized appropriately for cluster
- [ ] MTU set correctly (must be ≤ physical network MTU - 100 bytes)
- [ ] Custom Geneve port configured if needed
- [ ] IPsec requirements evaluated

### Bare Metal Specific
- [ ] API VIP is within `machineNetwork` CIDR
- [ ] Ingress VIP is within `machineNetwork` CIDR
- [ ] VIPs do not conflict with DHCP ranges
- [ ] BMC connectivity tested to all hosts
- [ ] Boot MAC addresses verified

### File Management
- [ ] `install-config.yaml` validated with `openshift-install create manifests` (optional)
- [ ] `install-config.yaml` backed up (installer consumes the original)

```bash
# Backup your configuration
cp install-config.yaml install-config.yaml.backup

# Optional: Generate manifests to validate (doesn't create cluster)
openshift-install create manifests --dir=.

# If manifests look good, destroy them and recreate from backup
rm -rf manifests openshift
cp install-config.yaml.backup install-config.yaml

# Run the installation
openshift-install create cluster --dir=. --log-level=info
```

---

## Post-Install Verification

See [VERIFICATION.md](./VERIFICATION.md) for detailed verification steps.

**Quick verification:**
```bash
# Check network configuration
oc get network.config.openshift.io cluster -o yaml

# Verify OVN-Kubernetes is the network type
oc get network.config.openshift.io cluster -o jsonpath='{.spec.networkType}'

# Check OVN configuration
oc get network.operator.openshift.io cluster -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig}' | jq

# Verify OVN pods are running
oc get pods -n openshift-ovn-kubernetes
```

---

## Troubleshooting

### Installation Fails with Network Validation Error

**Symptom:**
```
Error on validating API VIPs and Machine Networks: 
VIP 'X.X.X.X' cannot be found in any machine network
```

**Solution:**
- Ensure `apiVIP` and `ingressVIP` are within `machineNetwork` CIDR
- Fix `install-config.yaml` and restart installation

### OVN Pods CrashLooping After Install

**Symptom:**
```bash
oc get pods -n openshift-ovn-kubernetes
# Shows CrashLoopBackOff
```

**Possible Causes:**
1. MTU mismatch (OVN MTU > physical network MTU)
2. Geneve port blocked by firewall
3. Network overlap causing routing issues

**Investigation:**
```bash
# Check OVN pod logs
oc logs -n openshift-ovn-kubernetes <ovnkube-node-pod> -c ovnkube-controller

# Check for MTU issues
oc debug node/<node-name> -- chroot /host ip link show

# Check Geneve port connectivity
# On a node:
nc -zvu <other-node-ip> 6081
```

### Network Operator Degraded

**Symptom:**
```bash
oc get co network
# Shows Degraded=True
```

**Investigation:**
```bash
# Get detailed status
oc get network.operator cluster -o yaml

# Check operator logs
oc logs -n openshift-network-operator deployment/network-operator

# Common issues:
# - VIP not in machine network range
# - Subnet overlap detected
# - Invalid OVN configuration
```

### Pods Cannot Reach External Network

**Symptom:**
- Pods can communicate with each other
- Pods cannot reach external IPs or internet

**Investigation:**
```bash
# Test from a pod
oc run test-pod --image=registry.access.redhat.com/ubi8/ubi --command -- sleep 3600
oc exec test-pod -- ping -c 3 8.8.8.8

# Check masquerade subnet configuration
oc get network.operator cluster -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.gatewayConfig.ipv4.internalMasqueradeSubnet}'

# Check gateway router status
oc debug node/<node-name>
chroot /host
ovn-nbctl show GR_<node-name>
```

### Cannot Change OVN Settings Post-Install

**Symptom:**
- Need to change internal subnets after installation
- Configuration seems locked

**Reality:**
- Most `ovnKubernetesConfig` settings **cannot** be changed post-install
- These settings are baked into the overlay network during bootstrap

**Options:**
1. **If recently installed:** Destroy and reinstall cluster with correct settings
2. **If production cluster:** Contact Red Hat Support for migration options
3. **Settings that CAN change:** IPsec mode, policy audit config

---

## Additional Resources

- [Red Hat OpenShift Networking Documentation](https://docs.openshift.com/container-platform/latest/networking/ovn_kubernetes_network_provider/about-ovn-kubernetes.html)
- [OVN-Kubernetes GitHub](https://github.com/ovn-org/ovn-kubernetes)
- [OpenShift Install Configuration Reference](https://docs.openshift.com/container-platform/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-bare-metal-config-yaml_installing-bare-metal)

---

## Files in This Guide

- `README.md` (this file) - Complete reference guide
- `QUICK-REFERENCE.md` - Quick copy-paste configurations
- `EXAMPLES.md` - Complete install-config.yaml examples for various scenarios
- `VERIFICATION.md` - Post-install verification procedures
- `install-config-template.yaml` - Template file with comments

---

## Contributing

Found an issue or have improvements? Update the documentation and validate against a test cluster.

**Last Updated:** 2026-02-02


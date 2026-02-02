# OVN-Kubernetes Quick Reference

Quick copy-paste configurations for common scenarios.

## Table of Contents

- [Minimal Configuration](#minimal-configuration)
- [Custom Internal Subnets](#custom-internal-subnets-recommended)
- [IPsec Encryption](#ipsec-encryption)
- [Jumbo Frames](#jumbo-frames)
- [Custom Geneve Port](#custom-geneve-port)
- [Dual Stack IPv4+IPv6](#dual-stack-ipv4ipv6)
- [All Options Combined](#all-options-combined)

---

## Minimal Configuration

Use OVN-Kubernetes with all defaults:

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
```

**Defaults Applied:**
- `mtu: 1400`
- `genevePort: 6081`
- `ipv4.internalJoinSubnet: 100.64.0.0/16`
- `gatewayConfig.ipv4.internalMasqueradeSubnet: 169.254.169.0/29`
- `gatewayConfig.ipv4.internalTransitSwitchSubnet: 100.88.0.0/16`
- `ipsecConfig.mode: Disabled`

---

## Custom Internal Subnets (Recommended)

**Use this if default 100.64.0.0/16 or 100.88.0.0/16 conflicts with your network:**

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

**What this does:**
- Sets join subnet to 10.245.0.0/16 (node-to-overlay interface)
- Expands masquerade subnet to 169.254.0.0/17 (32K addresses)
- Sets transit subnet to 10.246.0.0/16 (internal routing)

---

## IPsec Encryption

**Enable full encryption for pod-to-pod traffic:**

```yaml
networking:
  networkType: OVNKubernetes
  ovnKubernetesConfig:
    ipsecConfig:
      mode: Full
```

**Impact:**
- ✅ Encrypts all pod-to-pod traffic
- ⚠️ Adds CPU overhead (5-15%)
- ⚠️ May reduce throughput (5-10%)

**Can be changed post-install:**
```bash
# Enable IPsec after installation
oc patch networks.operator.openshift.io cluster --type=merge \
  -p '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"ipsecConfig":{"mode":"Full"}}}}}'

# Disable IPsec
oc patch networks.operator.openshift.io cluster --type=merge \
  -p '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"ipsecConfig":{"mode":"Disabled"}}}}}'
```

---

## Jumbo Frames

**For high-performance networking with jumbo frame support:**

```yaml
networking:
  networkType: OVNKubernetes
  ovnKubernetesConfig:
    mtu: 9000
```

**Requirements:**
- Physical network must support MTU 9000+
- All network equipment in path must support jumbo frames
- **Cannot be changed after installation**

**Verification:**
```bash
# Check MTU on overlay interface
oc debug node/<node-name> -- chroot /host ip link show genev_sys_6081

# Expected output should show mtu 9000
```

---

## Custom Geneve Port

**If default port 6081 conflicts:**

```yaml
networking:
  networkType: OVNKubernetes
  ovnKubernetesConfig:
    genevePort: 6082
```

**Requirements:**
- Firewall must allow UDP traffic on custom port
- **Cannot be changed after installation**

**Firewall rules needed:**
```bash
# Between all nodes (replace 6082 with your port)
firewall-cmd --permanent --add-port=6082/udp
firewall-cmd --reload
```

---

## Dual Stack (IPv4+IPv6)

**Enable both IPv4 and IPv6 networking:**

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
  machineNetwork:
  - cidr: 10.0.0.0/16
  - cidr: 2001:db8::/32
  ovnKubernetesConfig:
    ipv4:
      internalJoinSubnet: 10.245.0.0/16
    ipv6:
      internalJoinSubnet: fd98::/64
    gatewayConfig:
      ipv4:
        internalMasqueradeSubnet: 169.254.0.0/17
        internalTransitSwitchSubnet: 10.246.0.0/16
      ipv6:
        internalTransitSwitchSubnet: fd97::/64
```

**Notes:**
- Requires IPv6 support on physical network
- Both IPv4 and IPv6 addresses assigned to pods
- **Cannot be changed after installation**

---

## All Options Combined

**Complete configuration with all common customizations:**

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
      mode: Disabled  # Change to Full for encryption
    policyAuditConfig:
      destination: "null"  # Or "libc" or "udp:<host>:<port>"
      maxFileSize: 50
      rateLimit: 20
      syslogFacility: local0
```

---

## Verification Commands

### Check Network Configuration
```bash
# View complete network config
oc get network.config.openshift.io cluster -o yaml

# Check network type
oc get network.config.openshift.io cluster -o jsonpath='{.spec.networkType}'
# Expected: OVNKubernetes

# View OVN configuration
oc get network.operator.openshift.io cluster -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig}' | jq
```

### Check OVN Pods
```bash
# List all OVN pods
oc get pods -n openshift-ovn-kubernetes

# Expected pods:
# - ovnkube-control-plane-* (one per control plane node)
# - ovnkube-node-* (one per node)
# - ovs-node-* (one per node)

# Check specific pod logs
oc logs -n openshift-ovn-kubernetes <pod-name> -c ovnkube-controller
```

### Check Internal Subnets
```bash
# Check join subnet (ovn-k8s-mp0 interface)
oc debug node/<node-name>
chroot /host
ip addr show ovn-k8s-mp0
# Should show IP from your internalJoinSubnet

# Check MTU
ip link show genev_sys_6081
# Should show your configured MTU
```

### Check IPsec Status
```bash
# If IPsec enabled, check status
oc debug node/<node-name>
chroot /host
ovs-appctl -t ovs-vswitchd fdb/show br-int
```

### Network Operator Status
```bash
# Check if network operator is healthy
oc get co network

# Should show:
# NAME      VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
# network   4.x.x     True        False         False      XXm

# If degraded, check details:
oc get network.operator cluster -o yaml
oc describe co network
```

---

## Common Issues and Quick Fixes

### VIP Not in Machine Network
**Error during install:**
```
Error: VIP 'X.X.X.X' cannot be found in any machine network
```

**Fix:**
Ensure your `apiVIP` and `ingressVIP` are within the `machineNetwork` CIDR:
```yaml
machineNetwork:
- cidr: 10.0.0.0/24    # Your physical network
platform:
  baremetal:
    apiVIP: 10.0.0.10      # Must be in 10.0.0.0/24
    ingressVIP: 10.0.0.11  # Must be in 10.0.0.0/24
```

### Network Operator Degraded After Install
**Symptom:**
```bash
oc get co network
# Shows Degraded=True
```

**Quick check:**
```bash
# View the error message
oc get network.operator cluster -o jsonpath='{.status.conditions[?(@.type=="Degraded")].message}'

# Check for subnet overlaps
oc get network.operator cluster -o yaml | grep -A 50 ovnKubernetesConfig
```

### Pods Cannot Get Network
**Symptom:** Pods stuck in `ContainerCreating`

**Quick check:**
```bash
# Check if OVN pods are running
oc get pods -n openshift-ovn-kubernetes

# Check pod events
oc describe pod <stuck-pod>

# Look for: "network is not ready"
```

**Common causes:**
- OVN pods not running (check logs)
- MTU mismatch (overlay MTU > physical MTU)
- Firewall blocking Geneve port

---

## Pre-Installation Validation

**Run these checks before starting installation:**

```bash
# 1. Validate YAML syntax
yamllint install-config.yaml

# 2. Check for subnet overlaps (manual verification)
# Ensure these don't overlap:
# - clusterNetwork
# - serviceNetwork  
# - machineNetwork
# - internalJoinSubnet
# - internalTransitSwitchSubnet
# - Any external networks

# 3. Verify VIPs are in machine network
# API VIP and Ingress VIP must be within machineNetwork CIDR

# 4. Backup your config
cp install-config.yaml install-config.yaml.backup

# 5. Optional: Generate manifests to validate
openshift-install create manifests --dir=.
# Review generated manifests in manifests/ and openshift/

# 6. If manifests look good, clean up and restore config
rm -rf manifests openshift
cp install-config.yaml.backup install-config.yaml

# 7. Start installation
openshift-install create cluster --dir=. --log-level=info
```

---

## Post-Installation: What Can Be Changed?

All OVN-Kubernetes settings can be changed by patching `network.operator.openshift.io cluster`.

**Prerequisites:**
- `cluster-admin` privileges
- OpenShift CLI (`oc`) installed
- Maintenance window (allow 30-60 minutes)

⏱️ **Timing:** Changes can take **up to 30 minutes** to propagate across the cluster.

### ✅ Can Change Easily (No Disruption)

**IPsec Mode:**
```bash
# Enable IPsec
oc patch networks.operator.openshift.io cluster --type=merge \
  -p '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"ipsecConfig":{"mode":"Full"}}}}}'
```

**Policy Audit Logging:**
```bash
# Enable audit logging to syslog
oc patch networks.operator.openshift.io cluster --type=merge \
  -p '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"policyAuditConfig":{"destination":"libc","rateLimit":50}}}}}'
```

### ⚠️ Can Change with Pod Restart (Brief Disruption)

**Internal Subnets:**
```bash
# Change OVN internal subnets
oc patch networks.operator.openshift.io cluster --type=merge -p '
{
  "spec": {
    "defaultNetwork": {
      "ovnKubernetesConfig": {
        "ipv4": {
          "internalJoinSubnet": "10.245.0.0/16"
        },
        "gatewayConfig": {
          "ipv4": {
            "internalMasqueradeSubnet": "169.254.0.0/17",
            "internalTransitSwitchSubnet": "10.246.0.0/16"
          }
        }
      }
    }
  }
}'
```
**Impact:** OVN pods restart, brief network disruption during maintenance window.

### ⚠️ Can Change with Node Reboot (Full Disruption)

**MTU:**
```bash
# Change MTU (requires node reboot)
oc patch networks.operator.openshift.io cluster --type=merge \
  -p '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"mtu":9000}}}}'
```

**Geneve Port:**
```bash
# Change Geneve port (requires node reboot)
oc patch networks.operator.openshift.io cluster --type=merge \
  -p '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"genevePort":6082}}}}'
```
**Impact:** Nodes must be rebooted for changes to take effect. Plan for maintenance window.

### ❌ Cannot Change After Install

- `networkType` (cannot switch from OVNKubernetes to another CNI)
- Dual stack configuration (cannot add/remove IPv6 after install)

**If you need to change these:** You must destroy and reinstall the cluster.

---

## Quick Network Test

**After installation, verify networking:**

```bash
# 1. Create test pod
oc run test-pod --image=registry.access.redhat.com/ubi8/ubi --command -- sleep 3600

# 2. Wait for pod to be running
oc wait --for=condition=Ready pod/test-pod --timeout=60s

# 3. Test pod-to-pod networking
oc run test-pod-2 --image=registry.access.redhat.com/ubi8/ubi --command -- sleep 3600
oc wait --for=condition=Ready pod/test-pod-2 --timeout=60s

POD1_IP=$(oc get pod test-pod -o jsonpath='{.status.podIP}')
oc exec test-pod-2 -- ping -c 3 $POD1_IP

# 4. Test external connectivity
oc exec test-pod -- ping -c 3 8.8.8.8

# 5. Test DNS
oc exec test-pod -- nslookup kubernetes.default.svc.cluster.local

# 6. Cleanup
oc delete pod test-pod test-pod-2
```

---

## Changing Configuration Post-Install

### View Current Configuration

```bash
# View complete network operator configuration
oc get network.operator.openshift.io cluster -o yaml

# View just OVN configuration
oc get network.operator.openshift.io cluster -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig}' | jq
```

### Patch Configuration

**General Pattern:**
```bash
oc patch networks.operator.openshift.io cluster --type=merge -p '
{
  "spec": {
    "defaultNetwork": {
      "ovnKubernetesConfig": {
        "parameter": "value"
      }
    }
  }
}'
```

**Example - Change All Internal Subnets:**
```bash
oc patch networks.operator.openshift.io cluster --type=merge -p '
{
  "spec": {
    "defaultNetwork": {
      "ovnKubernetesConfig": {
        "ipv4": {
          "internalJoinSubnet": "10.245.0.0/16"
        },
        "gatewayConfig": {
          "ipv4": {
            "internalMasqueradeSubnet": "169.254.0.0/17",
            "internalTransitSwitchSubnet": "10.246.0.0/16"
          }
        }
      }
    }
  }
}'

# Monitor rollout
oc get pods -n openshift-ovn-kubernetes -w

# ⏱️ Note: Changes can take up to 30 minutes to fully propagate
```

**Example - Change MTU (Requires Node Reboot):**
```bash
# Change MTU
oc patch networks.operator.openshift.io cluster --type=merge -p '
{
  "spec": {
    "defaultNetwork": {
      "ovnKubernetesConfig": {
        "mtu": 9000
      }
    }
  }
}'

# Nodes must be rebooted for MTU change to take effect
# Drain and reboot nodes one at a time
oc adm drain <node-name> --ignore-daemonsets --delete-emptydir-data
ssh <node> "sudo systemctl reboot"
# Wait for node to come back
oc adm uncordon <node-name>
```

### Verify Changes

```bash
# Check operator status after change
oc get co network

# Verify new configuration applied
oc get network.operator.openshift.io cluster -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig}' | jq

# Check OVN pods restarted successfully
oc get pods -n openshift-ovn-kubernetes

# Verify on nodes (for internal subnet changes)
oc debug node/<node-name>
chroot /host
ip addr show ovn-k8s-mp0  # Should show new internalJoinSubnet IP
exit
exit
```

---

**For complete documentation, see [README.md](./README.md)**

**Last Updated:** 2026-02-02


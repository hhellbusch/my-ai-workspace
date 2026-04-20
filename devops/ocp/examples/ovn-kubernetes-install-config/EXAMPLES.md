# Complete install-config.yaml Examples

This file contains complete, production-ready `install-config.yaml` examples for various scenarios.

## Table of Contents

- [Example 1: Bare Metal with Custom OVN Subnets](#example-1-bare-metal-with-custom-ovn-subnets)
- [Example 2: Bare Metal with IPsec Encryption](#example-2-bare-metal-with-ipsec-encryption)
- [Example 3: VMware vSphere with Jumbo Frames](#example-3-vmware-vsphere-with-jumbo-frames)
- [Example 4: AWS with Custom OVN Configuration](#example-4-aws-with-custom-ovn-configuration)
- [Example 5: Bare Metal Dual Stack (IPv4+IPv6)](#example-5-bare-metal-dual-stack-ipv4ipv6)
- [Example 6: Bare Metal Compact Cluster (3 Nodes)](#example-6-bare-metal-compact-cluster-3-nodes)

---

## Example 1: Bare Metal with Custom OVN Subnets

**Use Case:** Production bare metal cluster with custom OVN internal subnets to avoid conflicts.

**Cluster Details:**
- 3 control plane nodes
- 3 worker nodes
- Custom OVN internal subnets
- Standard MTU
- No encryption

```yaml
apiVersion: v1
baseDomain: example.com
metadata:
  name: ocp-prod

compute:
- name: worker
  replicas: 3

controlPlane:
  name: master
  replicas: 3
  platform:
    baremetal: {}

networking:
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16
  machineNetwork:
  - cidr: 10.46.124.0/24
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
      mode: Disabled

platform:
  baremetal:
    apiVIP: 10.46.124.10
    ingressVIP: 10.46.124.11
    provisioningNetwork: Disabled
    hosts:
    - name: master-0
      role: master
      bmc:
        address: redfish-virtualmedia://10.46.124.20/redfish/v1/Systems/1
        username: admin
        password: changeme
        disableCertificateVerification: true
      bootMACAddress: 52:54:00:00:00:01
      rootDeviceHints:
        deviceName: /dev/sda
    - name: master-1
      role: master
      bmc:
        address: redfish-virtualmedia://10.46.124.21/redfish/v1/Systems/1
        username: admin
        password: changeme
        disableCertificateVerification: true
      bootMACAddress: 52:54:00:00:00:02
      rootDeviceHints:
        deviceName: /dev/sda
    - name: master-2
      role: master
      bmc:
        address: redfish-virtualmedia://10.46.124.22/redfish/v1/Systems/1
        username: admin
        password: changeme
        disableCertificateVerification: true
      bootMACAddress: 52:54:00:00:00:03
      rootDeviceHints:
        deviceName: /dev/sda
    - name: worker-0
      role: worker
      bmc:
        address: redfish-virtualmedia://10.46.124.30/redfish/v1/Systems/1
        username: admin
        password: changeme
        disableCertificateVerification: true
      bootMACAddress: 52:54:00:00:00:11
      rootDeviceHints:
        deviceName: /dev/sda
    - name: worker-1
      role: worker
      bmc:
        address: redfish-virtualmedia://10.46.124.31/redfish/v1/Systems/1
        username: admin
        password: changeme
        disableCertificateVerification: true
      bootMACAddress: 52:54:00:00:00:12
      rootDeviceHints:
        deviceName: /dev/sda
    - name: worker-2
      role: worker
      bmc:
        address: redfish-virtualmedia://10.46.124.32/redfish/v1/Systems/1
        username: admin
        password: changeme
        disableCertificateVerification: true
      bootMACAddress: 52:54:00:00:00:13
      rootDeviceHints:
        deviceName: /dev/sda

pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"...","email":"user@example.com"}}}'
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... user@example.com'

# Optional: Additional trust bundle for corporate CA
# additionalTrustBundle: |
#   -----BEGIN CERTIFICATE-----
#   ...
#   -----END CERTIFICATE-----

# Optional: Proxy configuration
# proxy:
#   httpProxy: http://proxy.example.com:8080
#   httpsProxy: https://proxy.example.com:8080
#   noProxy: .cluster.local,.svc,10.0.0.0/8,127.0.0.1,172.30.0.0/16
```

**Installation:**
```bash
# Backup configuration
cp install-config.yaml install-config.yaml.backup

# Run installer
openshift-install create cluster --dir=. --log-level=info
```

---

## Example 2: Bare Metal with IPsec Encryption

**Use Case:** Security-sensitive environment requiring encrypted pod-to-pod traffic.

**Cluster Details:**
- IPsec encryption enabled (Full mode)
- Slightly higher resource requirements due to encryption overhead
- All other settings standard

```yaml
apiVersion: v1
baseDomain: secure.example.com
metadata:
  name: ocp-secure

compute:
- name: worker
  replicas: 3

controlPlane:
  name: master
  replicas: 3

networking:
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16
  machineNetwork:
  - cidr: 192.168.10.0/24
  ovnKubernetesConfig:
    mtu: 1400
    genevePort: 6081
    ipv4:
      internalJoinSubnet: 10.245.0.0/16
    gatewayConfig:
      ipv4:
        internalMasqueradeSubnet: 169.254.0.0/17
        internalTransitSwitchSubnet: 10.246.0.0/16
    ipsecConfig:
      mode: Full  # Enables IPsec encryption for all pod-to-pod traffic

platform:
  baremetal:
    apiVIP: 192.168.10.10
    ingressVIP: 192.168.10.11
    provisioningNetwork: Disabled
    hosts:
    - name: master-0
      role: master
      bmc:
        address: redfish-virtualmedia://192.168.10.20/redfish/v1/Systems/1
        username: admin
        password: changeme
        disableCertificateVerification: true
      bootMACAddress: 52:54:00:10:00:01
      rootDeviceHints:
        deviceName: /dev/sda
    # Add remaining hosts...

pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"...","email":"user@example.com"}}}'
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... user@example.com'
```

**Performance Impact:**
- CPU: +5-15% overhead
- Network throughput: -5-10% reduction
- Latency: +0.5-2ms additional latency

**Verification After Install:**
```bash
# Check IPsec status
oc get network.operator cluster -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.ipsecConfig.mode}'
# Expected: Full

# Check IPsec on nodes
oc debug node/<node-name>
chroot /host
ovs-appctl -t ovs-vswitchd fdb/show br-int | grep -i ipsec
```

---

## Example 3: VMware vSphere with Jumbo Frames

**Use Case:** High-performance vSphere cluster with jumbo frame support.

**Cluster Details:**
- VMware vSphere platform
- MTU 9000 (jumbo frames)
- Physical network configured for MTU 9000+
- Higher network throughput for data-intensive workloads

```yaml
apiVersion: v1
baseDomain: vsphere.example.com
metadata:
  name: ocp-vsphere-hpc

compute:
- name: worker
  replicas: 5
  platform:
    vsphere:
      cpus: 16
      coresPerSocket: 8
      memoryMB: 65536
      osDisk:
        diskSizeGB: 500

controlPlane:
  name: master
  replicas: 3
  platform:
    vsphere:
      cpus: 8
      coresPerSocket: 4
      memoryMB: 32768
      osDisk:
        diskSizeGB: 200

networking:
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16
  machineNetwork:
  - cidr: 10.0.0.0/24
  ovnKubernetesConfig:
    mtu: 9000  # Jumbo frames - requires physical network support
    genevePort: 6081
    ipv4:
      internalJoinSubnet: 10.245.0.0/16
    gatewayConfig:
      ipv4:
        internalMasqueradeSubnet: 169.254.0.0/17
        internalTransitSwitchSubnet: 10.246.0.0/16

platform:
  vsphere:
    vcenter: vcenter.example.com
    username: administrator@vsphere.local
    password: changeme
    datacenter: DC1
    defaultDatastore: datastore1
    cluster: Cluster1
    network: VM Network
    apiVIP: 10.0.0.10
    ingressVIP: 10.0.0.11
    folder: /DC1/vm/OpenShift

pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"...","email":"user@example.com"}}}'
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... user@example.com'
```

**Prerequisites for Jumbo Frames:**
1. vSphere distributed virtual switch configured for MTU 9000
2. Physical switches support MTU 9000
3. Storage network supports MTU 9000 (if using NFS/iSCSI)

**Verification:**
```bash
# Check MTU on overlay interface
oc debug node/<node-name>
chroot /host
ip link show genev_sys_6081
# Should show: mtu 9000
```

---

## Example 4: AWS with Custom OVN Configuration

**Use Case:** AWS cluster with custom OVN subnets.

**Cluster Details:**
- AWS platform
- Custom OVN subnets to avoid conflicts with VPC peering
- Standard MTU (AWS doesn't support jumbo frames universally)

```yaml
apiVersion: v1
baseDomain: aws.example.com
metadata:
  name: ocp-aws-prod

compute:
- name: worker
  replicas: 3
  platform:
    aws:
      type: m5.2xlarge
      rootVolume:
        size: 200
        type: gp3

controlPlane:
  name: master
  replicas: 3
  platform:
    aws:
      type: m5.xlarge
      rootVolume:
        size: 200
        type: gp3

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
    mtu: 1400  # Standard for AWS
    genevePort: 6081
    ipv4:
      internalJoinSubnet: 10.245.0.0/16
    gatewayConfig:
      ipv4:
        internalMasqueradeSubnet: 169.254.0.0/17
        internalTransitSwitchSubnet: 10.246.0.0/16

platform:
  aws:
    region: us-east-1
    subnets:
    - subnet-0123456789abcdef0  # Public subnet AZ1
    - subnet-0123456789abcdef1  # Public subnet AZ2
    - subnet-0123456789abcdef2  # Public subnet AZ3
    - subnet-fedcba9876543210a  # Private subnet AZ1
    - subnet-fedcba9876543210b  # Private subnet AZ2
    - subnet-fedcba9876543210c  # Private subnet AZ3

pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"...","email":"user@example.com"}}}'
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... user@example.com'
```

**AWS-Specific Notes:**
- MTU on AWS is typically 1500 for standard instances
- MTU 9001 supported on some instance types (requires testing)
- Security groups automatically configured by installer

---

## Example 5: Bare Metal Dual Stack (IPv4+IPv6)

**Use Case:** Future-proof cluster with both IPv4 and IPv6 support.

**Cluster Details:**
- Dual stack networking (IPv4 and IPv6)
- Pods get both IPv4 and IPv6 addresses
- Services can use both protocols

```yaml
apiVersion: v1
baseDomain: example.com
metadata:
  name: ocp-dualstack

compute:
- name: worker
  replicas: 3

controlPlane:
  name: master
  replicas: 3

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
  - cidr: 10.46.124.0/24
  - cidr: 2001:db8:1234::/64
  ovnKubernetesConfig:
    mtu: 1400
    genevePort: 6081
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

platform:
  baremetal:
    apiVIPs:
    - 10.46.124.10
    - 2001:db8:1234::10
    ingressVIPs:
    - 10.46.124.11
    - 2001:db8:1234::11
    provisioningNetwork: Disabled
    hosts:
    - name: master-0
      role: master
      bmc:
        address: redfish-virtualmedia://10.46.124.20/redfish/v1/Systems/1
        username: admin
        password: changeme
        disableCertificateVerification: true
      bootMACAddress: 52:54:00:00:00:01
      rootDeviceHints:
        deviceName: /dev/sda
    # Add remaining hosts...

pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"...","email":"user@example.com"}}}'
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... user@example.com'
```

**Prerequisites:**
- Physical network supports IPv6
- Router configured with IPv6 routing
- DNS supports AAAA records

**Verification:**
```bash
# Check pod has both IPv4 and IPv6
oc run test-pod --image=registry.access.redhat.com/ubi8/ubi -- sleep 3600
oc exec test-pod -- ip addr show eth0

# Expected: both inet (IPv4) and inet6 (IPv6) addresses
```

---

## Example 6: Bare Metal Compact Cluster (3 Nodes)

**Use Case:** Edge deployment or lab environment with minimal hardware.

**Cluster Details:**
- 3 nodes acting as both control plane and workers
- Compact cluster topology
- Custom OVN subnets

```yaml
apiVersion: v1
baseDomain: edge.example.com
metadata:
  name: ocp-edge

compute:
- name: worker
  replicas: 0  # No dedicated workers

controlPlane:
  name: master
  replicas: 3
  platform:
    baremetal: {}

networking:
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16
  machineNetwork:
  - cidr: 192.168.100.0/24
  ovnKubernetesConfig:
    mtu: 1400
    genevePort: 6081
    ipv4:
      internalJoinSubnet: 10.245.0.0/16
    gatewayConfig:
      ipv4:
        internalMasqueradeSubnet: 169.254.0.0/17
        internalTransitSwitchSubnet: 10.246.0.0/16

platform:
  baremetal:
    apiVIP: 192.168.100.10
    ingressVIP: 192.168.100.11
    provisioningNetwork: Disabled
    hosts:
    - name: master-0
      role: master
      bmc:
        address: redfish-virtualmedia://192.168.100.20/redfish/v1/Systems/1
        username: admin
        password: changeme
        disableCertificateVerification: true
      bootMACAddress: 52:54:00:20:00:01
      rootDeviceHints:
        deviceName: /dev/sda
    - name: master-1
      role: master
      bmc:
        address: redfish-virtualmedia://192.168.100.21/redfish/v1/Systems/1
        username: admin
        password: changeme
        disableCertificateVerification: true
      bootMACAddress: 52:54:00:20:00:02
      rootDeviceHints:
        deviceName: /dev/sda
    - name: master-2
      role: master
      bmc:
        address: redfish-virtualmedia://192.168.100.22/redfish/v1/Systems/1
        username: admin
        password: changeme
        disableCertificateVerification: true
      bootMACAddress: 52:54:00:20:00:03
      rootDeviceHints:
        deviceName: /dev/sda

pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"...","email":"user@example.com"}}}'
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... user@example.com'
```

**Post-Install Configuration:**
```bash
# After install, label masters as workers to allow scheduling
oc label node master-0 node-role.kubernetes.io/worker=
oc label node master-1 node-role.kubernetes.io/worker=
oc label node master-2 node-role.kubernetes.io/worker=

# Verify
oc get nodes
# Should show masters with both control-plane and worker roles
```

**Resource Requirements:**
- Minimum 16 vCPU, 64GB RAM per node
- Recommended 24 vCPU, 96GB RAM per node

---

## Template with All Options

Complete template showing all available options:

```yaml
apiVersion: v1
baseDomain: example.com
metadata:
  name: cluster-name
  
compute:
- name: worker
  replicas: 3
  
controlPlane:
  name: master
  replicas: 3

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
    # MTU for overlay network (default: 1400)
    mtu: 1400
    # UDP port for Geneve encapsulation (default: 6081)
    genevePort: 6081
    # IPv4 configuration
    ipv4:
      # Internal routing subnet (default: 100.64.0.0/16)
      internalJoinSubnet: 10.245.0.0/16
    # Gateway configuration
    gatewayConfig:
      # Route via host network stack (default: false)
      routingViaHost: false
      ipv4:
        # Masquerade subnet (default: 169.254.169.0/29)
        internalMasqueradeSubnet: 169.254.0.0/17
        # Transit switch subnet (default: 100.88.0.0/16)
        internalTransitSwitchSubnet: 10.246.0.0/16
    # IPsec encryption
    ipsecConfig:
      # Disabled, Full, or External (default: Disabled)
      mode: Disabled
    # Network policy audit logging
    policyAuditConfig:
      # "null", "libc", or "udp:<host>:<port>" (default: "null")
      destination: "null"
      # Max log file size in MB (default: 50)
      maxFileSize: 50
      # Messages per second (default: 20)
      rateLimit: 20
      # Syslog facility (default: local0)
      syslogFacility: local0

platform:
  baremetal:
    apiVIP: 10.0.0.10
    ingressVIP: 10.0.0.11
    provisioningNetwork: Disabled
    hosts: []
    
pullSecret: ''
sshKey: ''
```

---

**For more information, see [README.md](./README.md) and [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)**

**Last Updated:** 2026-02-02


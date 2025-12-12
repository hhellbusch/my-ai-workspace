# Destroying Bare Metal OpenShift Cluster Without Metadata

## Overview

Bare metal cluster cleanup is more involved than cloud providers because resources span multiple systems:
- **Compute:** Physical servers or VMs
- **Networking:** Load balancers, DNS, DHCP, VIPs
- **Storage:** NFS shares, local storage, Ceph/OCS
- **Management:** BMC configurations, PXE boot entries

**Complexity:** High - requires access to multiple systems  
**Time Required:** 30-90 minutes  
**Risk Level:** High - easy to affect other systems

---

## Prerequisites

### Information You Need

Before starting, gather:

1. **Cluster name** (or partial name)
   ```bash
   # If cluster is still accessible
   oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}{"\n"}'
   ```

2. **Node information**
   - Node hostnames or IPs
   - BMC IPs (iDRAC, iLO, etc.)
   - MAC addresses (for DHCP cleanup)

3. **Network information**
   - API VIP and Ingress VIP
   - DNS domain (e.g., `cluster.example.com`)
   - Load balancer IP/hostname

4. **Access credentials**
   - BMC credentials (for powering off)
   - Load balancer access (SSH, web UI)
   - DNS server access
   - DHCP server access (if applicable)
   - Hypervisor access (if VMs)

---

## Deployment Types

### Type 1: IPI (Installer Provisioned Infrastructure)

**Characteristics:**
- OpenShift manages nodes via `BareMetalHost` resources
- Uses Metal³ for provisioning
- Nodes defined in `install-config.yaml`
- Automated via BMC/Redfish

**Cleanup approach:** Use Metal³ APIs if cluster is accessible, otherwise BMC directly

### Type 2: UPI (User Provisioned Infrastructure)

**Characteristics:**
- Manually provisioned nodes
- External load balancer
- Manual DNS/DHCP setup
- No Metal³ management

**Cleanup approach:** Fully manual, system by system

### Type 3: Assisted Installer

**Characteristics:**
- Discovery ISO used for installation
- Mix of automated and manual
- May have Metal³ or not

**Cleanup approach:** Depends on how it was set up

---

## Step-by-Step Cleanup

### Step 1: Inventory Your Resources

Run the diagnostic script:

```bash
cd ~/gemini-workspace/ocp-troubleshooting/destroy-cluster-without-metadata
./find-cluster-baremetal.sh <cluster-name>
```

Or manually gather information:

```bash
# If cluster is accessible
oc get nodes -o wide
oc get baremetalhosts -n openshift-machine-api -o wide
oc get infrastructure cluster -o yaml
oc get network cluster -o yaml

# Get API and Ingress VIPs
oc get svc -n openshift-kube-apiserver kubernetes -o jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}'
oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.endpointPublishingStrategy.loadBalancer.scope}{"\n"}'

# Save for later
oc get nodes -o json > /tmp/cluster-nodes.json
oc get baremetalhosts -n openshift-machine-api -o json > /tmp/cluster-bmh.json
```

**Create an inventory file:**

```bash
# cluster-inventory.txt
CLUSTER_NAME=my-cluster
CLUSTER_DOMAIN=example.com
API_VIP=10.0.0.100
INGRESS_VIP=10.0.0.101

# Masters
MASTER_0_HOSTNAME=master-0.my-cluster.example.com
MASTER_0_IP=10.0.0.10
MASTER_0_BMC=10.0.1.10
MASTER_0_MAC=aa:bb:cc:dd:ee:01

MASTER_1_HOSTNAME=master-1.my-cluster.example.com
MASTER_1_IP=10.0.0.11
MASTER_1_BMC=10.0.1.11
MASTER_1_MAC=aa:bb:cc:dd:ee:02

MASTER_2_HOSTNAME=master-2.my-cluster.example.com
MASTER_2_IP=10.0.0.12
MASTER_2_BMC=10.0.1.12
MASTER_2_MAC=aa:bb:cc:dd:ee:03

# Workers
WORKER_0_HOSTNAME=worker-0.my-cluster.example.com
WORKER_0_IP=10.0.0.20
WORKER_0_BMC=10.0.1.20
WORKER_0_MAC=aa:bb:cc:dd:ee:11

# Add more workers as needed...

# Infrastructure
LB_HOST=lb.example.com
LB_IP=10.0.0.5
DNS_SERVER=10.0.0.2
DHCP_SERVER=10.0.0.3  # if applicable

# Hypervisor (if VMs)
HYPERVISOR=hypervisor.example.com
```

---

### Step 2: Power Down Nodes

#### Option A: Via BMC (Recommended)

Using ipmitool:

```bash
# Source your inventory
source cluster-inventory.txt

# Power off via IPMI
for bmc in $MASTER_0_BMC $MASTER_1_BMC $MASTER_2_BMC $WORKER_0_BMC; do
    echo "Powering off $bmc..."
    ipmitool -I lanplus -H "$bmc" -U admin -P 'password' power off
done

# Verify power status
for bmc in $MASTER_0_BMC $MASTER_1_BMC $MASTER_2_BMC $WORKER_0_BMC; do
    echo -n "$bmc: "
    ipmitool -I lanplus -H "$bmc" -U admin -P 'password' power status
done
```

Using Redfish (more modern):

```bash
# Power off via Redfish
for bmc in $MASTER_0_BMC $MASTER_1_BMC $MASTER_2_BMC $WORKER_0_BMC; do
    echo "Powering off $bmc..."
    curl -k -u "admin:password" -X POST \
        "https://$bmc/redfish/v1/Systems/System.Embedded.1/Actions/ComputerSystem.Reset" \
        -H "Content-Type: application/json" \
        -d '{"ResetType": "ForceOff"}'
done

# Check power state
for bmc in $MASTER_0_BMC $MASTER_1_BMC $MASTER_2_BMC $WORKER_0_BMC; do
    echo "Status for $bmc:"
    curl -k -u "admin:password" \
        "https://$bmc/redfish/v1/Systems/System.Embedded.1" | \
        jq -r '.PowerState'
done
```

#### Option B: Via SSH (If Accessible)

```bash
# Shutdown via SSH (requires SSH access)
for host in master-0 master-1 master-2 worker-0; do
    echo "Shutting down $host..."
    ssh core@$host 'sudo shutdown -h now' &
done
wait
```

#### Option C: Via Cluster API (IPI Only)

```bash
# Scale down via BareMetalHost
oc patch baremetalhost -n openshift-machine-api master-0 \
    --type merge -p '{"spec":{"online":false}}'

# For all hosts
for bmh in $(oc get baremetalhost -n openshift-machine-api -o name); do
    oc patch $bmh -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
done
```

---

### Step 3: Clean Up Virtual Machines (If Applicable)

If nodes are VMs on a hypervisor:

#### libvirt/KVM

```bash
# List VMs matching cluster name
virsh list --all | grep $CLUSTER_NAME

# For each VM
VM_LIST="my-cluster-master-0 my-cluster-master-1 my-cluster-master-2 my-cluster-worker-0"

for vm in $VM_LIST; do
    echo "Processing $vm..."
    
    # Destroy (force power off)
    virsh destroy $vm 2>/dev/null || true
    
    # Undefine and remove storage
    virsh undefine $vm --remove-all-storage
done

# Clean up any remaining storage pools
virsh vol-list default | grep $CLUSTER_NAME | awk '{print $1}' | while read vol; do
    virsh vol-delete $vol --pool default
done
```

#### VMware ESXi/vCenter

```bash
# Use govc (see find-cluster-vsphere.sh)
export GOVC_URL='vcenter.example.com'
export GOVC_USERNAME='administrator@vsphere.local'
export GOVC_PASSWORD='password'
export GOVC_INSECURE=1

# Power off
govc vm.power -off "*${CLUSTER_NAME}*"

# Delete VMs
govc vm.destroy "*${CLUSTER_NAME}*"

# Delete folders
govc object.destroy "/${DATACENTER}/vm/${CLUSTER_NAME}"
```

#### Proxmox

```bash
# List VMs
pvesh get /cluster/resources --type vm | grep $CLUSTER_NAME

# For each VM
for vmid in 100 101 102 103; do  # Your VM IDs
    echo "Stopping and deleting VM $vmid..."
    pvesh create /nodes/pve/qemu/$vmid/status/stop
    sleep 5
    pvesh delete /nodes/pve/qemu/$vmid
done
```

---

### Step 4: Clean Up Load Balancer

Your load balancer configuration needs to be removed.

#### HAProxy

```bash
# SSH to load balancer
ssh admin@lb.example.com

# Backup current config
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup-$(date +%Y%m%d)

# Remove cluster-specific config
# Option 1: If you have separate config files
sudo rm /etc/haproxy/conf.d/my-cluster.cfg

# Option 2: Edit main config file
sudo vi /etc/haproxy/haproxy.cfg
# Remove these sections:
#   - frontend api-${CLUSTER_NAME}
#   - frontend ingress-${CLUSTER_NAME}
#   - backend api-${CLUSTER_NAME}
#   - backend ingress-${CLUSTER_NAME}

# Test configuration
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Reload HAProxy
sudo systemctl reload haproxy

# Or restart if needed
sudo systemctl restart haproxy
```

**Example HAProxy config to remove:**

```haproxy
# Remove these sections
frontend api-my-cluster
    bind *:6443
    default_backend api-my-cluster
    mode tcp
    option tcplog

backend api-my-cluster
    balance roundrobin
    mode tcp
    server master-0 10.0.0.10:6443 check
    server master-1 10.0.0.11:6443 check
    server master-2 10.0.0.12:6443 check

frontend ingress-my-cluster-https
    bind *:443
    default_backend ingress-my-cluster-https
    mode tcp

backend ingress-my-cluster-https
    balance roundrobin
    mode tcp
    server worker-0 10.0.0.20:443 check
    server worker-1 10.0.0.21:443 check
```

#### Keepalived (If Using VIPs)

```bash
# SSH to keepalived host(s)
ssh admin@lb.example.com

# Backup config
sudo cp /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.backup-$(date +%Y%m%d)

# Remove cluster VIP configuration
sudo vi /etc/keepalived/keepalived.conf
# Remove vrrp_instance for your cluster

# Restart keepalived
sudo systemctl restart keepalived

# Verify VIPs are released
ip addr show | grep -E '10.0.0.100|10.0.0.101'
```

#### NGINX

```bash
# SSH to NGINX host
ssh admin@lb.example.com

# Remove cluster config
sudo rm /etc/nginx/conf.d/my-cluster.conf
sudo rm /etc/nginx/streams.d/my-cluster.conf  # If using stream module

# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx
```

#### F5 BIG-IP / Hardware Load Balancer

```bash
# Use web UI or tmsh
# 1. Remove virtual servers for cluster
# 2. Remove pools for cluster
# 3. Remove nodes/members
# 4. Save configuration
```

---

### Step 5: Clean Up DNS

Remove DNS records for the cluster:

**Records to remove:**
- `api.<cluster-name>.<domain>` → API VIP
- `api-int.<cluster-name>.<domain>` → API VIP (internal)
- `*.apps.<cluster-name>.<domain>` → Ingress VIP (wildcard)
- Individual node records (if created)
- etcd SRV records (if created)

#### BIND DNS

```bash
# SSH to DNS server
ssh admin@dns.example.com

# Locate zone file
ZONE_FILE="/var/named/${CLUSTER_DOMAIN}.zone"
sudo cp $ZONE_FILE ${ZONE_FILE}.backup-$(date +%Y%m%d)

# Edit zone file
sudo vi $ZONE_FILE

# Remove lines like:
# api.my-cluster          IN  A       10.0.0.100
# api-int.my-cluster      IN  A       10.0.0.100
# *.apps.my-cluster       IN  A       10.0.0.101
# master-0.my-cluster     IN  A       10.0.0.10
# master-1.my-cluster     IN  A       10.0.0.11
# etc...

# Increment serial number in SOA record
# Before: 2024121001
# After:  2024121002

# Check zone file
sudo named-checkzone ${CLUSTER_DOMAIN} $ZONE_FILE

# Reload BIND
sudo rndc reload ${CLUSTER_DOMAIN}

# Verify records are gone
dig @localhost api.my-cluster.${CLUSTER_DOMAIN}
dig @localhost "*.apps.my-cluster.${CLUSTER_DOMAIN}"
```

#### Using nsupdate (Dynamic DNS)

```bash
# If DNS supports dynamic updates
nsupdate -k /etc/Knsupdate.key <<EOF
server ${DNS_SERVER}
update delete api.${CLUSTER_NAME}.${CLUSTER_DOMAIN}. A
update delete api-int.${CLUSTER_NAME}.${CLUSTER_DOMAIN}. A
update delete *.apps.${CLUSTER_NAME}.${CLUSTER_DOMAIN}. A
send
EOF

# For each node
nsupdate -k /etc/Knsupdate.key <<EOF
server ${DNS_SERVER}
update delete ${MASTER_0_HOSTNAME}. A
update delete ${MASTER_1_HOSTNAME}. A
update delete ${MASTER_2_HOSTNAME}. A
update delete ${WORKER_0_HOSTNAME}. A
send
EOF
```

#### dnsmasq

```bash
# Edit dnsmasq config
sudo vi /etc/dnsmasq.conf

# Or separate config file
sudo vi /etc/dnsmasq.d/my-cluster.conf

# Remove lines like:
# address=/api.my-cluster.example.com/10.0.0.100
# address=/api-int.my-cluster.example.com/10.0.0.100
# address=/.apps.my-cluster.example.com/10.0.0.101

# Or remove entire file
sudo rm /etc/dnsmasq.d/my-cluster.conf

# Restart dnsmasq
sudo systemctl restart dnsmasq
```

#### PowerDNS / External DNS Provider

```bash
# Via API or web UI, remove:
# - api.<cluster>.<domain>
# - api-int.<cluster>.<domain>
# - *.apps.<cluster>.<domain>
```

---

### Step 6: Clean Up DHCP (If Applicable)

If you used DHCP for node IPs:

#### ISC DHCP Server

```bash
# SSH to DHCP server
ssh admin@dhcp.example.com

# Backup config
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.backup-$(date +%Y%m%d)

# Edit config
sudo vi /etc/dhcp/dhcpd.conf

# Remove host entries like:
# host master-0 {
#   hardware ethernet aa:bb:cc:dd:ee:01;
#   fixed-address 10.0.0.10;
#   option host-name "master-0.my-cluster.example.com";
# }

# Test config
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf

# Restart DHCP
sudo systemctl restart dhcpd

# Clear leases (optional, if you want to free IPs immediately)
sudo systemctl stop dhcpd
sudo rm /var/lib/dhcpd/dhcpd.leases~
sudo touch /var/lib/dhcpd/dhcpd.leases
sudo systemctl start dhcpd
```

#### dnsmasq DHCP

```bash
# Edit dnsmasq config
sudo vi /etc/dnsmasq.conf

# Remove lines like:
# dhcp-host=aa:bb:cc:dd:ee:01,10.0.0.10,master-0,infinite

# Restart
sudo systemctl restart dnsmasq
```

---

### Step 7: Clean Up PXE Boot (If Used)

If you used PXE for installation:

```bash
# SSH to PXE server
ssh admin@pxe.example.com

# Remove boot files
TFTPBOOT_DIR="/var/lib/tftpboot"

# Remove cluster-specific files
sudo rm -rf ${TFTPBOOT_DIR}/pxelinux.cfg/my-cluster-*
sudo rm -rf ${TFTPBOOT_DIR}/rhcos/my-cluster-*

# Remove HTTP ignition files
HTTP_DIR="/var/www/html/ignition"
sudo rm -rf ${HTTP_DIR}/my-cluster-*

# Remove by MAC address entries (if used)
for mac in aa:bb:cc:dd:ee:01 aa:bb:cc:dd:ee:02 aa:bb:cc:dd:ee:03; do
    mac_filename=$(echo $mac | tr ':' '-' | tr '[:upper:]' '[:lower:]')
    sudo rm -f ${TFTPBOOT_DIR}/pxelinux.cfg/01-${mac_filename}
done
```

---

### Step 8: Clean Up Storage

#### NFS Storage (Registry, PVs)

```bash
# SSH to NFS server
ssh admin@nfs.example.com

# Locate cluster storage
NFS_EXPORT="/exports/ocp"
ls -la ${NFS_EXPORT}/my-cluster-*

# Backup important data (if any)
sudo tar czf /backup/my-cluster-storage-$(date +%Y%m%d).tar.gz ${NFS_EXPORT}/my-cluster-*

# Remove storage
sudo rm -rf ${NFS_EXPORT}/my-cluster-*

# Update /etc/exports if needed
sudo vi /etc/exports
# Remove lines for cluster

# Re-export
sudo exportfs -ra
```

#### Ceph/OCS Storage

```bash
# If using external Ceph
# 1. Remove RBD images
rbd ls -p ocp-pool | grep my-cluster | while read img; do
    rbd rm ocp-pool/$img
done

# 2. Remove CephFS directories
ceph fs ls
# Manually clean up directories for cluster
```

#### Local Storage on Nodes

If nodes used local storage and you're keeping the hardware:

```bash
# Will be cleaned when you reinstall OS or reprovision
# Or boot from live USB and wipe:
for node in master-0 master-1 master-2; do
    ssh core@$node 'sudo wipefs -a /dev/sda && sudo dd if=/dev/zero of=/dev/sda bs=1M count=100'
done
```

---

### Step 9: Clean Up Installation Artifacts

Remove local files from the machine where you ran the installation:

```bash
# Installation directory
rm -rf ~/ocp-install-dir

# Ignition files (if copied elsewhere)
rm -rf /var/www/html/ignition/my-cluster-*

# Any cached ISOs
rm -rf ~/rhcos-*.iso

# SSH keys (if cluster-specific)
# Review before deleting!
rm -f ~/.ssh/my-cluster-*
```

---

### Step 10: Verification

Verify everything is cleaned up:

```bash
# DNS verification
dig api.${CLUSTER_NAME}.${CLUSTER_DOMAIN}
# Should return NXDOMAIN or no answer

dig "*.apps.${CLUSTER_NAME}.${CLUSTER_DOMAIN}"
# Should return NXDOMAIN or no answer

# Network verification (VIPs released)
ping -c 1 ${API_VIP}
# Should be unreachable

ping -c 1 ${INGRESS_VIP}
# Should be unreachable

# Node power status
for bmc in $MASTER_0_BMC $MASTER_1_BMC $MASTER_2_BMC $WORKER_0_BMC; do
    echo -n "$bmc: "
    ipmitool -I lanplus -H "$bmc" -U admin -P 'password' power status
done
# All should show "off"

# VM verification (if applicable)
virsh list --all | grep ${CLUSTER_NAME}
# Should return nothing

# Load balancer verification
curl -k https://${API_VIP}:6443/healthz
# Should be unreachable

# Storage verification
ls -la /exports/ocp/ | grep ${CLUSTER_NAME}
# Should return nothing
```

---

## Automated Cleanup Script

Use the provided script for common tasks:

```bash
./cleanup-baremetal-cluster.sh \
    --cluster-name my-cluster \
    --config cluster-inventory.txt \
    --steps "power-off,dns,lb" \
    --yes
```

---

## Common Bare Metal Scenarios

### Scenario 1: IPI Cluster, Still Accessible

**Best approach:** Use Kubernetes API

```bash
# Scale down cluster
oc scale --replicas=0 deployment/cluster-version-operator -n openshift-cluster-version

# Mark all BMH as not managed
for bmh in $(oc get baremetalhost -n openshift-machine-api -o name); do
    oc patch $bmh -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
done

# Then proceed with manual cleanup
```

### Scenario 2: UPI Cluster, Nodes Need Reprovisioning

**Best approach:** Power off, reprovision OS, no storage cleanup needed

```bash
# Power off all nodes
./power-off-nodes.sh cluster-inventory.txt

# Clean DNS, LB
./cleanup-networking.sh cluster-inventory.txt

# Nodes are ready for next installation
```

### Scenario 3: Lab Environment, Full Teardown

**Best approach:** Destroy everything, including VMs

```bash
# If VMs
for vm in $(virsh list --all | grep my-cluster | awk '{print $2}'); do
    virsh destroy $vm
    virsh undefine $vm --remove-all-storage
done

# Clean all config files
./cleanup-baremetal-cluster.sh --cluster-name my-cluster --full
```

### Scenario 4: Production, Keeping Nodes for Reuse

**Best approach:** Graceful shutdown, preserve BMC configs

```bash
# Graceful node shutdown
for node in $(oc get nodes -o name); do
    oc adm drain $node --ignore-daemonsets --delete-emptydir-data
done

# Shutdown nodes via SSH
for host in master-{0..2} worker-{0..4}; do
    ssh core@$host 'sudo shutdown -h now'
done

# Clean only networking (DNS, LB)
# Keep node OS intact for next install
```

---

## Troubleshooting

### Issue: Can't Access BMCs

**Solutions:**
1. Physical access to power off servers
2. SSH to nodes and shutdown via OS
3. Use hypervisor controls if VMs
4. Last resort: Wait for power cycling window

### Issue: Shared Load Balancer with Multiple Clusters

**Solution:**
```bash
# Carefully edit LB config to remove only your cluster sections
# Do NOT restart LB, only reload:
sudo systemctl reload haproxy  # Graceful reload

# Test from outside
curl -k https://api.other-cluster.example.com:6443/healthz
# Should still work
```

### Issue: DNS Server Shared with Other Services

**Solution:**
```bash
# Only remove cluster-specific records
# Use specific deletes, not wildcards

# Safe
update delete api.my-cluster.example.com. A

# DANGEROUS
update delete *.example.com. A  # DON'T DO THIS
```

### Issue: Can't Find All Node IPs/MACs

**Solution:**
```bash
# Check DHCP leases
sudo grep -i "my-cluster" /var/lib/dhcp/dhcpd.leases

# Check ARP table
arp -a | grep -i master
arp -a | grep -i worker

# Check switch MAC address tables (if access)
# Check DNS records
dig @dns-server axfr example.com | grep my-cluster
```

---

## Safety Checklist

Before starting bare metal cleanup:

- [ ] **Inventory complete** - all nodes, IPs, BMCs documented
- [ ] **Cluster truly dead** - verified not in use
- [ ] **Shared services identified** - LB, DNS not affecting others
- [ ] **Backups complete** - any important data saved
- [ ] **Access verified** - can reach all systems (BMC, LB, DNS, etc.)
- [ ] **Team notified** - others aware of shutdown
- [ ] **Maintenance window** - if shared infrastructure
- [ ] **Rollback plan** - in case of issues with shared services

---

## Time Estimates

| Task | Time (Manual) | Time (Scripted) |
|------|---------------|-----------------|
| Inventory | 10-20 min | 5 min |
| Power down nodes | 5-10 min | 2 min |
| Clean load balancer | 5-15 min | 3 min |
| Clean DNS | 10-20 min | 5 min |
| Clean DHCP | 5-10 min | 3 min |
| Clean storage | 10-30 min | 5 min |
| Verification | 10-15 min | 5 min |
| **Total** | **55-120 min** | **28-38 min** |

---

## Related Documentation

See also:
- `README.md` - General overview and cloud providers
- `QUICK-REFERENCE.md` - Command quick reference
- `../bare-metal-node-inspection-timeout/` - BMH troubleshooting

---

**Document Version:** 1.0  
**Last Updated:** December 2025  
**Applies To:** OpenShift 4.x bare metal deployments




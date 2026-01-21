# Bare Metal Cluster Destruction - Quick Start

**👉 You have a bare metal OpenShift cluster and lost the metadata file.**

This guide will help you destroy it manually.

---

## 🚀 Three-Step Process

### Step 1: Gather Information (5 minutes)

Run the diagnostic script:

```bash
cd ~/gemini-workspace/ocp-troubleshooting/destroy-cluster-without-metadata
./find-cluster-baremetal.sh <your-cluster-name>
```

**This will:**
- Check if cluster is still accessible
- Extract node and BMC information
- Check DNS records
- Generate an inventory file at `/tmp/<cluster-name>-inventory.txt`

**Example:**
```bash
./find-cluster-baremetal.sh my-ocp-cluster
```

---

### Step 2: Complete the Inventory (10 minutes)

Edit the generated inventory file:

```bash
vi /tmp/<cluster-name>-inventory.txt
```

**Fill in values marked with `TODO`:**
- BMC IP addresses (for power management)
- Load balancer details
- DNS server info
- DHCP server (if used)
- Hypervisor info (if VMs)

**Example inventory:**
```bash
CLUSTER_NAME=my-cluster
CLUSTER_DOMAIN=example.com
API_VIP=10.0.0.100
INGRESS_VIP=10.0.0.101

# Masters
MASTER_0_IP=10.0.0.10
MASTER_0_BMC=10.0.1.10

MASTER_1_IP=10.0.0.11
MASTER_1_BMC=10.0.1.11

MASTER_2_IP=10.0.0.12
MASTER_2_BMC=10.0.1.12

# Workers
WORKER_0_IP=10.0.0.20
WORKER_0_BMC=10.0.1.20

# Infrastructure
LB_HOST=lb.example.com
LB_TYPE=haproxy
DNS_SERVER=10.0.0.2
DNS_TYPE=bind

# Credentials
BMC_USER=root
BMC_PASS=calvin
```

---

### Step 3: Run Cleanup (30-60 minutes)

#### Option A: Automated (What It Can Do)

Run the cleanup script:

```bash
# Dry run first (see what it will do)
./cleanup-baremetal-cluster.sh \
    --cluster-name <cluster-name> \
    --config /tmp/<cluster-name>-inventory.txt \
    --dry-run

# Actual cleanup
./cleanup-baremetal-cluster.sh \
    --cluster-name <cluster-name> \
    --config /tmp/<cluster-name>-inventory.txt
```

**The script will:**
- ✅ Power off nodes via BMC
- ✅ Delete VMs (if libvirt)
- ⚠️  Show instructions for load balancer cleanup (manual)
- ⚠️  Show instructions for DNS cleanup (manual)
- ⚠️  Show instructions for DHCP cleanup (manual)
- ✅ Verify cleanup

#### Option B: Step-by-Step (Manual Control)

Run specific steps:

```bash
# Just power off nodes
./cleanup-baremetal-cluster.sh --cluster-name <cluster-name> --config <inventory> --steps power-off

# Just DNS and LB
./cleanup-baremetal-cluster.sh --cluster-name <cluster-name> --config <inventory> --steps dns,lb
```

---

## 📋 What Needs Manual Intervention

Some tasks require manual work (script will show you how):

### 1. Load Balancer (5-15 minutes)

**HAProxy Example:**
```bash
ssh admin@lb-server
sudo vi /etc/haproxy/haproxy.cfg
# Remove sections for your cluster:
#   - frontend api-<cluster>
#   - frontend ingress-<cluster>
#   - backend api-<cluster>
#   - backend ingress-<cluster>

sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl reload haproxy
```

### 2. DNS (10-20 minutes)

**BIND Example:**
```bash
ssh admin@dns-server
sudo vi /var/named/<domain>.zone
# Remove these records:
#   api.<cluster>.<domain>
#   api-int.<cluster>.<domain>
#   *.apps.<cluster>.<domain>
#   master-0.<cluster>.<domain>
#   (and all other node records)

# Increment SOA serial number
# Before: 2024121001
# After:  2024121002

sudo named-checkzone <domain> /var/named/<domain>.zone
sudo rndc reload <domain>
```

### 3. DHCP (5-10 minutes, if used)

```bash
ssh admin@dhcp-server
sudo vi /etc/dhcp/dhcpd.conf
# Remove host entries for cluster nodes

sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf
sudo systemctl restart dhcpd
```

---

## ✅ Verification Checklist

After cleanup, verify:

```bash
# DNS should return nothing
dig api.<cluster>.<domain>
dig *.apps.<cluster>.<domain>

# VIPs should be unreachable
ping <API_VIP>
ping <INGRESS_VIP>

# Nodes should be powered off
ipmitool -I lanplus -H <bmc-ip> -U <user> -P <pass> power status
# Should show: "Chassis Power is off"
```

---

## 🆘 Common Issues

### Issue: No BMC Access

**Solutions:**
1. Power off via SSH to nodes:
   ```bash
   ssh core@<node-ip> 'sudo shutdown -h now'
   ```
2. Physical access to servers
3. Use hypervisor controls if VMs

### Issue: Shared Load Balancer

**Solution:**
- Carefully edit config to remove ONLY your cluster
- Use `reload` not `restart` to avoid downtime
- Test other clusters still work after changes

### Issue: Can't Find Node IPs

**Solutions:**
```bash
# Check DHCP leases
sudo grep -i <cluster> /var/lib/dhcp/dhcpd.leases

# Check DNS
dig @<dns-server> axfr <domain> | grep <cluster>

# Check ARP table
arp -a | grep -i master
```

---

## 📊 Time Breakdown

| Task | Time |
|------|------|
| Run diagnostic | 2-5 min |
| Edit inventory | 5-10 min |
| Power off nodes | 2-5 min |
| Clean load balancer | 5-15 min |
| Clean DNS | 10-20 min |
| Clean DHCP | 5-10 min |
| Verification | 5-10 min |
| **Total** | **34-75 min** |

---

## 📚 Need More Details?

- **Complete procedures:** See [BAREMETAL-GUIDE.md](BAREMETAL-GUIDE.md)
- **Command reference:** See [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- **Troubleshooting:** See [BAREMETAL-GUIDE.md](BAREMETAL-GUIDE.md) → Troubleshooting section

---

## 🎯 Quick Decision Tree

```
Do you have cluster access (oc command works)?
├─ YES → Script will extract all node info automatically
└─ NO → You need to manually fill inventory file

Are nodes VMs or physical?
├─ VMs → Script can delete VMs (libvirt supported)
└─ Physical → Script will power off via BMC

Is load balancer shared?
├─ YES → Be VERY careful with manual cleanup
└─ NO → Simpler, remove entire config

Need help?
└─ See BAREMETAL-GUIDE.md for detailed procedures
```

---

## Example: Complete Workflow

```bash
# 1. Run diagnostic
./find-cluster-baremetal.sh production-ocp

# Output: Created /tmp/production-ocp-inventory.txt

# 2. Edit inventory
vi /tmp/production-ocp-inventory.txt
# Fill in BMC IPs, LB info, etc.

# 3. Test with dry-run
./cleanup-baremetal-cluster.sh \
    --cluster-name production-ocp \
    --config /tmp/production-ocp-inventory.txt \
    --dry-run

# 4. Run actual cleanup
./cleanup-baremetal-cluster.sh \
    --cluster-name production-ocp \
    --config /tmp/production-ocp-inventory.txt

# 5. Follow manual instructions from output
#    - SSH to load balancer, edit config
#    - SSH to DNS server, remove records
#    - etc.

# 6. Verify
dig api.production-ocp.example.com  # Should fail
ping 10.0.0.100  # Should be unreachable
```

---

**🚀 Ready to start? Run the diagnostic script now!**

```bash
cd ~/gemini-workspace/ocp-troubleshooting/destroy-cluster-without-metadata
./find-cluster-baremetal.sh <your-cluster-name>
```

---

**Version:** 1.0  
**Last Updated:** December 2025








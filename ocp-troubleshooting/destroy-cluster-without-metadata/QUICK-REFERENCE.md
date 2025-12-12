# Quick Reference: Destroy Cluster Without Metadata

## Emergency Quick Start

### 1️⃣ What Platform? (Choose One)

```bash
# AWS
cd ~/gemini-workspace/ocp-troubleshooting/destroy-cluster-without-metadata
./find-cluster-aws.sh <cluster-name-or-keyword>

# Azure
./find-cluster-azure.sh <cluster-name-or-keyword>

# vSphere
./find-cluster-vsphere.sh <cluster-name-or-keyword>

# Bare Metal
# See "Bare Metal" section below
```

### 2️⃣ Review Found Resources

The scripts will list all resources. Review carefully!

### 3️⃣ Execute Cleanup

```bash
# AWS
./cleanup-aws-cluster.sh <cluster-name> <region>

# Azure
./cleanup-azure-cluster.sh <resource-group-name>

# vSphere
./cleanup-vsphere-cluster.sh <cluster-name>
```

---

## Platform-Specific Cheat Sheets

### AWS

#### Find Cluster Resources
```bash
# By cluster name
CLUSTER_NAME="my-cluster"
REGION="us-east-1"

aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag:kubernetes.io/cluster/${CLUSTER_NAME},Values=owned" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output table

# All OpenShift clusters in region
aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag-key,Values=kubernetes.io/cluster/*" \
  --query 'Reservations[*].Instances[*].Tags[?Key==`Name`].Value' \
  --output table | sort -u
```

#### Quick Delete (Manual)
```bash
# 1. Terminate instances
aws ec2 terminate-instances --instance-ids i-xxxxx i-yyyyy --region $REGION

# 2. Delete load balancers
aws elbv2 delete-load-balancer --load-balancer-arn <arn> --region $REGION

# 3. Delete volumes
aws ec2 delete-volume --volume-id vol-xxxxx --region $REGION

# 4. Delete VPC
aws ec2 delete-vpc --vpc-id vpc-xxxxx --region $REGION
```

#### Cost Check
```bash
# See running costs
aws ce get-cost-and-usage \
  --time-period Start=2024-12-01,End=2024-12-10 \
  --granularity DAILY \
  --metrics BlendedCost \
  --filter file://filter.json

# filter.json:
{
  "Tags": {
    "Key": "kubernetes.io/cluster/my-cluster",
    "Values": ["owned"]
  }
}
```

---

### Azure

#### Find Resources
```bash
# List resource groups with "ocp" or cluster name
az group list --query "[?contains(name, 'ocp')]" --output table

# List resources in a group
RESOURCE_GROUP="my-cluster-rg"
az resource list --resource-group $RESOURCE_GROUP --output table
```

#### Quick Delete
```bash
# Delete entire resource group (simplest)
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Check deletion status
az group show --name $RESOURCE_GROUP --query "properties.provisioningState"
```

#### Cost Check
```bash
# Resource group costs
az consumption usage list \
  --start-date 2024-12-01 \
  --end-date 2024-12-10 \
  | jq "[.[] | select(.instanceName | contains(\"$RESOURCE_GROUP\"))]"
```

---

### vSphere

#### Find VMs
```bash
# Setup govc
export GOVC_URL='vcenter.example.com'
export GOVC_USERNAME='admin@vsphere.local'
export GOVC_PASSWORD='password'
export GOVC_INSECURE=1

# Find cluster VMs
CLUSTER_NAME="my-cluster"
govc find / -type m -name "*${CLUSTER_NAME}*"

# Get VM details
govc vm.info "*${CLUSTER_NAME}*"
```

#### Quick Delete
```bash
# Power off
govc vm.power -off "*${CLUSTER_NAME}*"

# Delete
govc vm.destroy "*${CLUSTER_NAME}*"

# Delete folders
govc object.destroy "/<datacenter>/vm/${CLUSTER_NAME}"
```

---

### Bare Metal

**📖 Complete Guide:** [BAREMETAL-GUIDE.md](BAREMETAL-GUIDE.md)

#### Quick Start

```bash
# Find cluster resources
./find-cluster-baremetal.sh <cluster-name>

# Edit generated inventory
vi /tmp/<cluster-name>-inventory.txt

# Cleanup (dry-run first)
./cleanup-baremetal-cluster.sh --cluster-name <cluster-name> --config /tmp/<cluster-name>-inventory.txt --dry-run

# Actual cleanup
./cleanup-baremetal-cluster.sh --cluster-name <cluster-name> --config /tmp/<cluster-name>-inventory.txt
```

#### Find Resources

```bash
# 1. If cluster is accessible
oc get nodes -o wide
oc get baremetalhosts -n openshift-machine-api -o wide

# 2. Check running VMs on hypervisor
virsh list --all | grep -i <cluster-name>

# 3. Check DHCP leases
grep -i <cluster-name> /var/lib/dhcp/dhcpd.leases

# 4. Check DNS records
dig @<dns-server> api.<cluster>.<domain>
dig @<dns-server> api-int.<cluster>.<domain>
dig @<dns-server> test.apps.<cluster>.<domain>

# 5. Check load balancer config
grep -r <cluster-name> /etc/haproxy/
grep -r <cluster-name> /etc/keepalived/
grep -r <cluster-name> /etc/nginx/
```

#### Power Off Nodes

```bash
# Via BMC (ipmitool)
for ip in 10.0.1.{10..15}; do
  ipmitool -I lanplus -H $ip -U admin -P password power off
done

# Via BMC (Redfish)
for ip in 10.0.1.{10..15}; do
  curl -k -u "admin:password" -X POST \
    "https://$ip/redfish/v1/Systems/System.Embedded.1/Actions/ComputerSystem.Reset" \
    -H "Content-Type: application/json" \
    -d '{"ResetType": "ForceOff"}'
done

# Via cluster (IPI only)
oc get baremetalhost -n openshift-machine-api -o name | \
  xargs -I {} oc patch {} -n openshift-machine-api \
  --type merge -p '{"spec":{"online":false}}'
```

#### Delete VMs (If Applicable)

```bash
# libvirt/KVM
for vm in $(virsh list --all | grep <cluster> | awk '{print $2}'); do
  virsh destroy $vm
  virsh undefine $vm --remove-all-storage
done

# vSphere (use govc)
export GOVC_URL='vcenter.example.com'
export GOVC_USERNAME='admin@vsphere.local'
export GOVC_PASSWORD='password'
export GOVC_INSECURE=1

govc vm.power -off "*<cluster>*"
govc vm.destroy "*<cluster>*"
```

#### Clean Load Balancer

```bash
# HAProxy
ssh admin@lb-server
sudo vi /etc/haproxy/haproxy.cfg  # Remove cluster sections
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl reload haproxy

# NGINX
ssh admin@lb-server
sudo rm /etc/nginx/conf.d/<cluster>.conf
sudo nginx -t
sudo systemctl reload nginx
```

#### Clean DNS

```bash
# BIND (manual edit)
ssh admin@dns-server
sudo vi /var/named/<domain>.zone  # Remove cluster records
sudo named-checkzone <domain> /var/named/<domain>.zone
sudo rndc reload <domain>

# nsupdate (dynamic)
nsupdate -k /etc/Knsupdate.key <<EOF
server <dns-server>
update delete api.<cluster>.<domain> A
update delete api-int.<cluster>.<domain> A
update delete *.apps.<cluster>.<domain> A
send
EOF

# dnsmasq
ssh admin@dns-server
sudo rm /etc/dnsmasq.d/<cluster>.conf
sudo systemctl restart dnsmasq
```

#### Clean DHCP (If Used)

```bash
# ISC DHCP
ssh admin@dhcp-server
sudo vi /etc/dhcp/dhcpd.conf  # Remove host entries
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf
sudo systemctl restart dhcpd
```

#### Time Estimates

| Task | Manual | Scripted |
|------|--------|----------|
| Power off nodes | 5-10 min | 2 min |
| Clean LB | 5-15 min | 3 min |
| Clean DNS | 10-20 min | 5 min |
| **Total** | **55-120 min** | **28-38 min** |

---

## Recovery Attempts

### Try These First (Before Manual Cleanup)

#### 1. Find Installation Directory
```bash
# Common locations
ls -la ~/ocp-install-dir
ls -la ~/.openshift-install-*
find ~ -name ".openshift_install_state.json" 2>/dev/null
find ~ -name "metadata.json" -path "*/auth/*" -prune -o -type f -print 2>/dev/null
```

#### 2. Check for Terraform State
```bash
# If found, you might be able to use terraform destroy
find ~ -name "terraform.tfstate" 2>/dev/null
```

#### 3. Recreate Metadata (Advanced)

If you have cluster access and remember basic details:

```bash
# Get cluster ID
CLUSTER_ID=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')

# Get platform
PLATFORM=$(oc get infrastructure cluster -o jsonpath='{.status.platform}')

# This won't recreate full metadata, but helps manual cleanup
echo "Cluster ID: $CLUSTER_ID"
echo "Platform: $PLATFORM"

# Use these to search for resources by tag/name
```

---

## Common Issues

### Issue: Don't Know Cluster Name

```bash
# AWS: List all clusters in region
aws ec2 describe-instances \
  --region us-east-1 \
  --filters "Name=tag-key,Values=kubernetes.io/cluster/*" \
  --query 'Reservations[*].Instances[*].Tags[?starts_with(Key, `kubernetes.io/cluster`)].Key' \
  --output text | sed 's/kubernetes.io\/cluster\///g' | sort -u

# Azure: List resource groups with dates
az group list --query "[].{Name:name, Created:tags.createdTime}" --output table

# vSphere: List VMs by creation date
govc find / -type m | while read vm; do
  echo "$vm: $(govc vm.info $vm | grep 'Boot time')"
done | sort -k2
```

### Issue: Multiple Clusters, Not Sure Which

```bash
# AWS: Check instance states
aws ec2 describe-instances \
  --region us-east-1 \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],State.Name,LaunchTime]' \
  --output table

# Azure: Check resource group activity
az monitor activity-log list \
  --resource-group <rg-name> \
  --start-time 2024-12-01 \
  --query "[].{Time:eventTimestamp, Operation:operationName.localizedValue}" \
  --output table
```

### Issue: Resources in Multiple Regions

```bash
# AWS: Check all regions
for region in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  echo "=== $region ==="
  aws ec2 describe-instances \
    --region $region \
    --filters "Name=tag:kubernetes.io/cluster/<cluster-name>,Values=owned" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output table
done
```

### Issue: Can't Delete VPC (Dependencies)

```bash
# AWS: Find what's blocking VPC deletion
VPC_ID="vpc-xxxxx"
REGION="us-east-1"

# Check ENIs
aws ec2 describe-network-interfaces --region $REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'NetworkInterfaces[*].[NetworkInterfaceId,Status,Description]' \
  --output table

# Check NAT Gateways
aws ec2 describe-nat-gateways --region $REGION \
  --filter "Name=vpc-id,Values=$VPC_ID" \
  --query 'NatGateways[*].[NatGatewayId,State]' \
  --output table

# Check VPC endpoints
aws ec2 describe-vpc-endpoints --region $REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'VpcEndpoints[*].[VpcEndpointId,State]' \
  --output table
```

---

## Safety Checks

### Before Deleting Anything

```bash
# 1. Verify cluster is truly dead/unused
oc get nodes 2>/dev/null && echo "⚠️  CLUSTER IS ACCESSIBLE - ARE YOU SURE?"

# 2. Check for production tags
aws ec2 describe-instances --instance-ids <id> \
  --query 'Reservations[*].Instances[*].Tags[?Key==`Environment`].Value' \
  --output text

# 3. List all resources one more time
# (Use platform-specific commands above)

# 4. Take screenshots/save output
aws ec2 describe-instances --instance-ids <ids> > /tmp/pre-delete-state.txt
```

### Double-Check Cluster Name

```bash
# Make sure you're targeting the RIGHT cluster
echo "About to delete cluster: $CLUSTER_NAME"
read -p "Is this correct? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted"
    exit 1
fi
```

---

## Time Estimates

| Platform | Manual Cleanup Time | Automated Script Time |
|----------|--------------------|-----------------------|
| AWS | 30-60 minutes | 10-20 minutes |
| Azure | 20-40 minutes | 5-15 minutes |
| vSphere | 15-30 minutes | 5-10 minutes |
| Bare Metal | 45-90 minutes | 20-40 minutes |

*Times assume no major issues or dependencies*

---

## Emergency Contacts

### When to Get Help

- Unsure which resources belong to cluster
- Resources won't delete due to dependencies
- Concerned about affecting other workloads
- Need to preserve some data/configs

### Where to Get Help

1. **Red Hat Support** (with subscription)
   ```
   https://access.redhat.com/support/cases/
   Priority: Standard (or Higher if impacting prod)
   ```

2. **Cloud Provider Support**
   - AWS: AWS Support Console
   - Azure: Azure Support Portal
   - vSphere: VMware Support

3. **Internal Team**
   - Check with team who originally deployed
   - Review any deployment documentation
   - Check internal wikis/runbooks

---

## Cost Warning

### Typical Daily Costs (If You Wait)

- **Small cluster (3 masters, 2 workers)**: $50-100/day
- **Medium cluster (3 masters, 5 workers)**: $100-200/day
- **Large cluster (3 masters, 10+ workers)**: $200-500/day

**💡 Immediate Actions to Reduce Costs:**

```bash
# AWS: Stop instances (vs terminate)
aws ec2 stop-instances --instance-ids <worker-ids> --region $REGION
# Reduces compute costs by ~75%, still pay for storage

# Azure: Deallocate VMs
az vm deallocate --ids <vm-ids>
# Reduces costs significantly, quick to restart if needed

# vSphere: Power off VMs
govc vm.power -off "*worker*"
# No cloud costs, but uses on-prem resources
```

---

## Quick Decision Tree

```
Do you have the install directory with metadata?
├─ YES → Use: openshift-install destroy cluster --dir=<path>
└─ NO → Continue below

Can you find ANY metadata/terraform.tfstate file?
├─ YES → Copy to temp dir, use openshift-install destroy
└─ NO → Continue below

Is the cluster still accessible (oc get nodes works)?
├─ YES → Get cluster ID: oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}'
│        Use ID to find resources
└─ NO → Continue below

Do you know the exact cluster name?
├─ YES → Use automated cleanup script for your platform
└─ NO → Use find-cluster-<platform>.sh script first

Still stuck?
└─ See README.md for detailed manual procedures
```

---

## Next Steps

1. Determine your platform (AWS/Azure/vSphere/Bare Metal)
2. Run the diagnostic script (`find-cluster-*.sh`)
3. Review the output carefully
4. Run the cleanup script (`cleanup-*.sh`)
5. Verify deletion with post-cleanup checks
6. Document what you learned for next time

---

**Quick Ref Version:** 1.0  
**See Also:** README.md (full documentation)


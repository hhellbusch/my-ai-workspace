# Destroying OpenShift Cluster Without Metadata File

## Overview

The `openshift-install destroy cluster` command requires the metadata file (`.openshift_install_state.json` or `metadata.json`) from the installation directory. If this file is lost or unavailable, you'll need to manually clean up cluster resources.

**⚠️ CRITICAL WARNING:**
- Manual cleanup is **destructive** and **irreversible**
- Always verify resource ownership before deletion
- Document everything before starting
- Consider costs of running resources vs. time to clean up

---

## Quick Assessment

### 1. Check If You Can Recover Metadata

Before manual cleanup, try these recovery options:

```bash
# Check for backup installation directory
ls -la ~/ocp-install-dir*
ls -la ~/.openshift-install-*

# Check for terraform state (IPI installations)
find ~ -name "terraform.tfstate*" -type f 2>/dev/null

# Look for installation logs
find ~ -name ".openshift_install.log" -type f 2>/dev/null

# If you have a backup or find the directory:
cd <install-directory>
ls -la metadata.json .openshift_install_state.json
# If found, you can use: openshift-install destroy cluster --dir=.
```

### 2. Identify Your Platform

Determine which platform your cluster is running on:

```bash
# If you have cluster access
oc get infrastructure cluster -o jsonpath='{.status.platform}{"\n"}'

# Common platforms:
# - AWS
# - Azure  
# - GCP
# - BareMetal
# - VSphere
# - OpenStack
```

**📌 For Bare Metal Clusters:**

Bare metal cleanup is significantly different from cloud providers and requires more manual steps. 

**👉 See [BAREMETAL-GUIDE.md](BAREMETAL-GUIDE.md) for complete bare metal procedures!**

Quick bare metal workflow:
```bash
# 1. Run diagnostic
./find-cluster-baremetal.sh <cluster-name>

# 2. Edit generated inventory file
vi /tmp/<cluster-name>-inventory.txt

# 3. Run cleanup
./cleanup-baremetal-cluster.sh --cluster-name <cluster-name> --config /tmp/<cluster-name>-inventory.txt
```

---

## Platform-Specific Cleanup

### AWS (Most Common IPI)

#### Prerequisites
```bash
# Ensure AWS CLI is configured
aws sts get-caller-identity

# Find your cluster name (if you remember it)
CLUSTER_NAME="my-cluster"
CLUSTER_ID="<infra-id>"  # Usually: ${CLUSTER_NAME}-xxxxx
REGION="us-east-1"
```

#### Find Cluster Resources

```bash
# Method 1: Find by cluster tag
aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag:kubernetes.io/cluster/${CLUSTER_NAME},Values=owned" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output table

# Method 2: Find by naming pattern (if you know infra ID)
aws resourcegroupstaggingapi get-resources \
  --region $REGION \
  --tag-filters Key=kubernetes.io/cluster/${CLUSTER_ID},Values=owned \
  --query 'ResourceTagMappingList[*].[ResourceARN]' \
  --output table
```

#### Automated AWS Cleanup Script

Save this as `cleanup-aws-cluster.sh`:

```bash
#!/bin/bash
set -euo pipefail

# Configuration
CLUSTER_NAME="${1:-}"
REGION="${2:-us-east-1}"

if [ -z "$CLUSTER_NAME" ]; then
    echo "Usage: $0 <cluster-name> [region]"
    echo "Example: $0 my-ocp-cluster us-east-1"
    exit 1
fi

echo "⚠️  WARNING: This will DELETE all resources tagged with cluster: $CLUSTER_NAME"
echo "Region: $REGION"
read -p "Type 'DELETE' to confirm: " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo "Aborted."
    exit 0
fi

# Function to delete resources by tag
delete_by_tag() {
    local service=$1
    local resource_type=$2
    
    echo "🔍 Finding $resource_type..."
    
    case $service in
        ec2-instances)
            INSTANCES=$(aws ec2 describe-instances \
                --region $REGION \
                --filters "Name=tag:kubernetes.io/cluster/${CLUSTER_NAME},Values=owned" \
                          "Name=instance-state-name,Values=running,stopped" \
                --query 'Reservations[*].Instances[*].InstanceId' \
                --output text)
            
            if [ -n "$INSTANCES" ]; then
                echo "🗑️  Terminating instances: $INSTANCES"
                aws ec2 terminate-instances --region $REGION --instance-ids $INSTANCES
            fi
            ;;
            
        load-balancers)
            LBS=$(aws elbv2 describe-load-balancers \
                --region $REGION \
                --query "LoadBalancers[?contains(LoadBalancerName, '${CLUSTER_NAME}')].LoadBalancerArn" \
                --output text)
            
            for lb in $LBS; do
                echo "🗑️  Deleting load balancer: $lb"
                aws elbv2 delete-load-balancer --region $REGION --load-balancer-arn $lb
            done
            ;;
            
        classic-load-balancers)
            CLASSIC_LBS=$(aws elb describe-load-balancers \
                --region $REGION \
                --query "LoadBalancerDescriptions[?contains(LoadBalancerName, '${CLUSTER_NAME}')].LoadBalancerName" \
                --output text)
            
            for lb in $CLASSIC_LBS; do
                echo "🗑️  Deleting classic load balancer: $lb"
                aws elb delete-load-balancer --region $REGION --load-balancer-name $lb
            done
            ;;
            
        target-groups)
            TGS=$(aws elbv2 describe-target-groups \
                --region $REGION \
                --query "TargetGroups[?contains(TargetGroupName, '${CLUSTER_NAME}')].TargetGroupArn" \
                --output text)
            
            # Wait for LBs to be deleted first
            sleep 30
            
            for tg in $TGS; do
                echo "🗑️  Deleting target group: $tg"
                aws elbv2 delete-target-group --region $REGION --target-group-arn $tg || true
            done
            ;;
            
        security-groups)
            # Delete security groups last (after instances are gone)
            sleep 60
            
            SGS=$(aws ec2 describe-security-groups \
                --region $REGION \
                --filters "Name=tag:kubernetes.io/cluster/${CLUSTER_NAME},Values=owned" \
                --query 'SecurityGroups[*].GroupId' \
                --output text)
            
            for sg in $SGS; do
                echo "🗑️  Deleting security group: $sg"
                # First remove all rules
                aws ec2 describe-security-groups --region $REGION --group-ids $sg \
                    --query 'SecurityGroups[0].IpPermissions' \
                    --output json | \
                    xargs -I {} aws ec2 revoke-security-group-ingress --region $REGION --group-id $sg --ip-permissions {} 2>/dev/null || true
                
                aws ec2 delete-security-group --region $REGION --group-id $sg || true
            done
            ;;
            
        volumes)
            VOLS=$(aws ec2 describe-volumes \
                --region $REGION \
                --filters "Name=tag:kubernetes.io/cluster/${CLUSTER_NAME},Values=owned" \
                --query 'Volumes[*].VolumeId' \
                --output text)
            
            for vol in $VOLS; do
                echo "🗑️  Deleting volume: $vol"
                aws ec2 delete-volume --region $REGION --volume-id $vol || true
            done
            ;;
            
        snapshots)
            SNAPS=$(aws ec2 describe-snapshots \
                --region $REGION \
                --owner-ids self \
                --filters "Name=tag:kubernetes.io/cluster/${CLUSTER_NAME},Values=owned" \
                --query 'Snapshots[*].SnapshotId' \
                --output text)
            
            for snap in $SNAPS; do
                echo "🗑️  Deleting snapshot: $snap"
                aws ec2 delete-snapshot --region $REGION --snapshot-id $snap || true
            done
            ;;
            
        network-interfaces)
            ENIS=$(aws ec2 describe-network-interfaces \
                --region $REGION \
                --filters "Name=tag:kubernetes.io/cluster/${CLUSTER_NAME},Values=owned" \
                --query 'NetworkInterfaces[*].NetworkInterfaceId' \
                --output text)
            
            for eni in $ENIS; do
                echo "🗑️  Deleting network interface: $eni"
                aws ec2 delete-network-interface --region $REGION --network-interface-id $eni || true
            done
            ;;
            
        route53)
            # Find hosted zones containing cluster name
            ZONES=$(aws route53 list-hosted-zones \
                --query "HostedZones[?contains(Name, '${CLUSTER_NAME}')].Id" \
                --output text)
            
            for zone in $ZONES; do
                ZONE_ID=$(echo $zone | cut -d'/' -f3)
                echo "🗑️  Deleting Route53 hosted zone: $ZONE_ID"
                
                # Delete all records except NS and SOA
                aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID --query 'ResourceRecordSets[?Type!=`NS` && Type!=`SOA`]' --output json | \
                jq -c '.[]' | while read record; do
                    aws route53 change-resource-record-sets \
                        --hosted-zone-id $ZONE_ID \
                        --change-batch "{\"Changes\":[{\"Action\":\"DELETE\",\"ResourceRecordSet\":$record}]}" || true
                done
                
                # Delete the zone
                aws route53 delete-hosted-zone --id $ZONE_ID || true
            done
            ;;
            
        s3-buckets)
            BUCKETS=$(aws s3api list-buckets \
                --query "Buckets[?contains(Name, '${CLUSTER_NAME}')].Name" \
                --output text)
            
            for bucket in $BUCKETS; do
                echo "🗑️  Emptying and deleting S3 bucket: $bucket"
                aws s3 rm s3://$bucket --recursive --region $REGION || true
                aws s3api delete-bucket --bucket $bucket --region $REGION || true
            done
            ;;
            
        vpc)
            # Find VPC by tag
            VPC_ID=$(aws ec2 describe-vpcs \
                --region $REGION \
                --filters "Name=tag:kubernetes.io/cluster/${CLUSTER_NAME},Values=owned" \
                --query 'Vpcs[0].VpcId' \
                --output text)
            
            if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
                echo "🗑️  Deleting VPC: $VPC_ID"
                
                # Delete NAT gateways
                NATGWS=$(aws ec2 describe-nat-gateways \
                    --region $REGION \
                    --filter "Name=vpc-id,Values=$VPC_ID" \
                    --query 'NatGateways[*].NatGatewayId' \
                    --output text)
                
                for nat in $NATGWS; do
                    echo "  Deleting NAT gateway: $nat"
                    aws ec2 delete-nat-gateway --region $REGION --nat-gateway-id $nat
                done
                
                # Wait for NAT gateways to be deleted
                sleep 60
                
                # Delete Internet Gateway
                IGWS=$(aws ec2 describe-internet-gateways \
                    --region $REGION \
                    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
                    --query 'InternetGateways[*].InternetGatewayId' \
                    --output text)
                
                for igw in $IGWS; do
                    echo "  Detaching and deleting Internet Gateway: $igw"
                    aws ec2 detach-internet-gateway --region $REGION --internet-gateway-id $igw --vpc-id $VPC_ID
                    aws ec2 delete-internet-gateway --region $REGION --internet-gateway-id $igw
                done
                
                # Delete subnets
                SUBNETS=$(aws ec2 describe-subnets \
                    --region $REGION \
                    --filters "Name=vpc-id,Values=$VPC_ID" \
                    --query 'Subnets[*].SubnetId' \
                    --output text)
                
                for subnet in $SUBNETS; do
                    echo "  Deleting subnet: $subnet"
                    aws ec2 delete-subnet --region $REGION --subnet-id $subnet
                done
                
                # Delete route tables (except main)
                RTS=$(aws ec2 describe-route-tables \
                    --region $REGION \
                    --filters "Name=vpc-id,Values=$VPC_ID" \
                    --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' \
                    --output text)
                
                for rt in $RTS; do
                    echo "  Deleting route table: $rt"
                    aws ec2 delete-route-table --region $REGION --route-table-id $rt || true
                done
                
                # Finally delete VPC
                aws ec2 delete-vpc --region $REGION --vpc-id $VPC_ID
            fi
            ;;
    esac
}

# Deletion order (important!)
echo "🚀 Starting cleanup process..."
echo ""

delete_by_tag "ec2-instances" "EC2 Instances"
delete_by_tag "load-balancers" "Application Load Balancers"
delete_by_tag "classic-load-balancers" "Classic Load Balancers"
delete_by_tag "target-groups" "Target Groups"
delete_by_tag "volumes" "EBS Volumes"
delete_by_tag "snapshots" "EBS Snapshots"
delete_by_tag "network-interfaces" "Network Interfaces"
delete_by_tag "route53" "Route53 Zones"
delete_by_tag "s3-buckets" "S3 Buckets"
delete_by_tag "security-groups" "Security Groups"
delete_by_tag "vpc" "VPC and Networking"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "⚠️  Manual verification recommended:"
echo "1. Check AWS Console for any remaining resources"
echo "2. Review CloudFormation stacks: https://console.aws.amazon.com/cloudformation"
echo "3. Check for IAM roles/policies: aws iam list-roles | grep $CLUSTER_NAME"
echo "4. Verify no lingering costs: https://console.aws.amazon.com/billing"
```

Make it executable and run:
```bash
chmod +x cleanup-aws-cluster.sh
./cleanup-aws-cluster.sh <cluster-name> us-east-1
```

---

### Azure

#### Prerequisites
```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "<subscription-id>"

# Find resource group
RESOURCE_GROUP="<cluster-name>-rg"
```

#### Cleanup Script

```bash
#!/bin/bash
# cleanup-azure-cluster.sh

RESOURCE_GROUP="${1:-}"

if [ -z "$RESOURCE_GROUP" ]; then
    echo "Usage: $0 <resource-group-name>"
    echo "Example: $0 my-ocp-cluster-rg"
    exit 1
fi

echo "⚠️  WARNING: This will DELETE resource group: $RESOURCE_GROUP"
echo "and ALL resources within it."
read -p "Type 'DELETE' to confirm: " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo "Aborted."
    exit 0
fi

# Check if resource group exists
if ! az group exists --name $RESOURCE_GROUP | grep -q true; then
    echo "❌ Resource group $RESOURCE_GROUP not found"
    exit 1
fi

# List resources before deletion
echo "📋 Resources in group:"
az resource list --resource-group $RESOURCE_GROUP --output table

echo ""
echo "🗑️  Deleting resource group (this may take 10-30 minutes)..."
az group delete --name $RESOURCE_GROUP --yes --no-wait

echo "✅ Deletion initiated. Monitor progress with:"
echo "   az group show --name $RESOURCE_GROUP"
echo ""
echo "Also check for:"
echo "1. DNS zones: az network dns zone list --output table"
echo "2. Service principals: az ad sp list --display-name $RESOURCE_GROUP"
```

---

### Bare Metal / On-Premise

**⚠️ IMPORTANT: Bare metal cleanup is complex and platform-specific!**

**📖 Complete Guide:** See [BAREMETAL-GUIDE.md](BAREMETAL-GUIDE.md) for:
- Detailed step-by-step procedures
- IPI vs UPI specific instructions
- BMC/Redfish power management
- Load balancer cleanup (HAProxy, NGINX, F5)
- DNS cleanup (BIND, dnsmasq, PowerDNS)
- DHCP cleanup
- Virtual machine deletion (libvirt, vSphere, Proxmox)
- Storage cleanup (NFS, Ceph, local storage)

**Quick Start for Bare Metal:**

```bash
# 1. Run diagnostic to gather information
./find-cluster-baremetal.sh <cluster-name>

# 2. Edit the generated inventory file with your details
vi /tmp/<cluster-name>-inventory.txt

# 3. Run cleanup (with dry-run first to be safe)
./cleanup-baremetal-cluster.sh \
    --cluster-name <cluster-name> \
    --config /tmp/<cluster-name>-inventory.txt \
    --dry-run

# 4. Run actual cleanup
./cleanup-baremetal-cluster.sh \
    --cluster-name <cluster-name> \
    --config /tmp/<cluster-name>-inventory.txt

# 5. Manual steps (load balancer, DNS) - see script output
```

**What Makes Bare Metal Different:**
- No cloud provider APIs for automated deletion
- Multiple infrastructure components (LB, DNS, DHCP, BMC)
- Shared resources (LB, DNS may serve other clusters)
- Manual verification required for each component

**Typical Bare Metal Components to Clean:**
1. **Compute:** Power down via BMC (ipmitool/Redfish) or delete VMs
2. **Load Balancer:** Remove HAProxy/NGINX/F5 backend configs and VIPs
3. **DNS:** Remove api, api-int, *.apps records  
4. **DHCP:** Remove MAC address reservations (if used)
5. **PXE/Boot:** Remove TFTP configs and ignition files (if used)
6. **Storage:** Clean NFS exports, Ceph pools, local storage

**Time Estimate:** 30-90 minutes depending on complexity

---

### vSphere

#### Prerequisites
```bash
# govc CLI tool recommended
export GOVC_URL='vcenter.example.com'
export GOVC_USERNAME='administrator@vsphere.local'
export GOVC_PASSWORD='password'
export GOVC_INSECURE=1  # If using self-signed cert

CLUSTER_NAME="my-ocp-cluster"
```

#### Cleanup Script

```bash
#!/bin/bash
# cleanup-vsphere-cluster.sh

CLUSTER_NAME="${1:-}"
GOVC="${GOVC:-govc}"

if [ -z "$CLUSTER_NAME" ]; then
    echo "Usage: $0 <cluster-name>"
    exit 1
fi

echo "⚠️  WARNING: This will DELETE all VMs with name containing: $CLUSTER_NAME"
read -p "Type 'DELETE' to confirm: " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo "Aborted."
    exit 0
fi

# Find and power off VMs
echo "🔍 Finding VMs..."
VMS=$($GOVC find / -type m -name "*${CLUSTER_NAME}*")

if [ -z "$VMS" ]; then
    echo "❌ No VMs found matching: $CLUSTER_NAME"
    exit 1
fi

echo "Found VMs:"
echo "$VMS"
echo ""

# Power off VMs
for vm in $VMS; do
    echo "⏸️  Powering off: $vm"
    $GOVC vm.power -off "$vm" 2>/dev/null || true
done

sleep 10

# Delete VMs
for vm in $VMS; do
    echo "🗑️  Deleting: $vm"
    $GOVC vm.destroy "$vm"
done

# Find and delete resource pools
echo ""
echo "🔍 Finding resource pools..."
RPS=$($GOVC find / -type p -name "*${CLUSTER_NAME}*")

for rp in $RPS; do
    echo "🗑️  Deleting resource pool: $rp"
    $GOVC pool.destroy "$rp"
done

# Find and delete folders
echo ""
echo "🔍 Finding folders..."
FOLDERS=$($GOVC find / -type f -name "*${CLUSTER_NAME}*")

for folder in $FOLDERS; do
    echo "🗑️  Deleting folder: $folder"
    $GOVC object.destroy "$folder" || true
done

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "⚠️  Manual steps remaining:"
echo "1. Delete load balancer configuration"
echo "2. Remove DNS records (*.apps, api, api-int)"
echo "3. Release DHCP reservations if used"
echo "4. Clean up any storage datastores/folders"
```

---

## Post-Cleanup Verification

### General Verification Checklist

```bash
# 1. Verify DNS cleanup
dig api.<cluster-name>.<domain>
dig *.apps.<cluster-name>.<domain>

# 2. Check for remaining compute resources
# (Platform-specific commands from above)

# 3. Verify load balancer config is removed
# (Check your LB config files)

# 4. Check for lingering storage
# (NFS exports, cloud volumes, etc.)

# 5. Verify IAM/service accounts deleted
# (Cloud provider-specific)
```

### AWS-Specific Verification
```bash
# Check for any resources with cluster tag
aws resourcegroupstaggingapi get-resources \
    --region $REGION \
    --tag-filters Key=kubernetes.io/cluster/${CLUSTER_NAME},Values=owned \
    --output table

# Check CloudFormation stacks
aws cloudformation list-stacks \
    --region $REGION \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query "StackSummaries[?contains(StackName, '${CLUSTER_NAME}')]" \
    --output table

# Check S3 buckets
aws s3 ls | grep $CLUSTER_NAME

# Check IAM roles
aws iam list-roles | jq ".Roles[] | select(.RoleName | contains(\"${CLUSTER_NAME}\"))"
```

### Azure-Specific Verification
```bash
# Verify resource group is gone
az group exists --name $RESOURCE_GROUP

# Check for orphaned resources
az resource list --query "[?contains(name, '${CLUSTER_NAME}')]" --output table

# Check DNS zones
az network dns zone list --query "[?contains(name, '${CLUSTER_NAME}')]" --output table
```

---

## Cost Considerations

### Running Costs by Platform

| Platform | Typical 3-Master Cluster | Per Day Cost (est) |
|----------|-------------------------|---------------------|
| AWS | 3x m5.xlarge masters + workers | $50-200/day |
| Azure | 3x Standard_D4s_v3 + workers | $40-180/day |
| GCP | 3x n1-standard-4 + workers | $45-190/day |

**💡 TIP:** If cleanup will take more than a few hours, consider:
1. Stopping/shutting down instances immediately (reduced cost)
2. Scheduling cleanup during business hours
3. Using cloud provider cost calculators

---

## Troubleshooting Manual Cleanup

### Issue: Resources Won't Delete

```bash
# AWS: Force delete instances
aws ec2 terminate-instances --instance-ids <id> --region $REGION

# AWS: Disable termination protection
aws ec2 modify-instance-attribute \
    --instance-id <id> \
    --no-disable-api-termination \
    --region $REGION

# AWS: Force delete VPC (remove all dependencies first)
# See VPC deletion section in cleanup script above

# Azure: Force delete resource group
az group delete --name $RESOURCE_GROUP --yes --force-deletion-types Microsoft.Compute/virtualMachines
```

### Issue: "Dependency Violation" Errors

**Common dependency chains:**
1. VPC → Subnets → ENIs → Instances
2. Load Balancer → Target Groups → Instances
3. Security Groups → ENIs → Instances

**Solution:** Delete in reverse order:
1. Instances first
2. Load balancers and target groups
3. Network interfaces
4. Security groups
5. Subnets
6. VPC

### Issue: Can't Find Cluster Resources

```bash
# AWS: Search by partial name
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=*ocp*" \
    --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
    --output table

# AWS: Find by creation date
aws ec2 describe-instances \
    --query "Reservations[*].Instances[?LaunchTime>='2024-12-01'].[InstanceId,LaunchTime,Tags[?Key=='Name'].Value|[0]]" \
    --output table

# Azure: List all resource groups
az group list --output table | grep -i ocp

# vSphere: List all VMs
govc find / -type m
```

---

## Prevention: Backup Metadata

### Always Keep These Files

```bash
# Create a backup process
CLUSTER_NAME="my-cluster"
BACKUP_DIR=~/ocp-backups/$CLUSTER_NAME-$(date +%Y%m%d)

mkdir -p $BACKUP_DIR
cd ~/ocp-install-dir

# Backup critical files
cp -r .openshift_install_state.json $BACKUP_DIR/ 2>/dev/null || true
cp -r metadata.json $BACKUP_DIR/ 2>/dev/null || true
cp -r auth/ $BACKUP_DIR/ 2>/dev/null || true
cp -r terraform.tfstate* $BACKUP_DIR/ 2>/dev/null || true
cp install-config.yaml $BACKUP_DIR/ 2>/dev/null || true
cp .openshift_install.log $BACKUP_DIR/ 2>/dev/null || true

# Create a README
cat > $BACKUP_DIR/README.md <<EOF
# Cluster: $CLUSTER_NAME
Created: $(date)
Installation Directory: $(pwd)

## To destroy this cluster:
cd $(pwd)
openshift-install destroy cluster --dir=.

## Or use backup:
cp -r $BACKUP_DIR/* /tmp/restore-$CLUSTER_NAME/
cd /tmp/restore-$CLUSTER_NAME
openshift-install destroy cluster --dir=.
EOF

echo "✅ Backup saved to: $BACKUP_DIR"
```

### Store in Version Control (Encrypted)

```bash
# Using git-crypt or similar
cd ~/ocp-backups
git init
# Add .gitignore for sensitive files or use git-crypt
git add .
git commit -m "Backup metadata for $CLUSTER_NAME"
git push
```

---

## Quick Reference

### Command Summary

```bash
# AWS
./cleanup-aws-cluster.sh <cluster-name> <region>

# Azure  
./cleanup-azure-cluster.sh <resource-group>

# vSphere
./cleanup-vsphere-cluster.sh <cluster-name>

# Bare Metal
# Manual process - see Bare Metal section
```

### Essential Files to Recover/Backup

1. `.openshift_install_state.json` - Primary metadata
2. `metadata.json` - Cluster metadata
3. `terraform.tfstate` - Terraform state (IPI)
4. `auth/kubeconfig` - Cluster access
5. `install-config.yaml` - Installation config

---

## Related Documentation

- [OpenShift Install Documentation](https://docs.openshift.com/container-platform/latest/installing/index.html)
- [AWS Resource Tagging](https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html)
- [Azure Resource Management](https://docs.microsoft.com/en-us/azure/azure-resource-manager/)

---

## Support

If manual cleanup fails or you're unsure about resource ownership:

1. **Red Hat Support** (with subscription)
   - Open a support case
   - Provide: Cluster name, platform, approximate install date
   - They can help identify resources safely

2. **Cloud Provider Support**
   - Contact AWS/Azure/GCP support
   - Ask them to identify resources by tags/labels
   - Request assistance with dependency resolution

3. **Community**
   - OpenShift Users Mailing List
   - Kubernetes Slack #openshift channel
   - Red Hat Customer Portal discussions

---

**Document Version:** 1.0  
**Last Updated:** December 2025  
**Tested On:** OpenShift 4.12-4.15


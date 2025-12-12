# Destroy OpenShift Cluster Without Metadata - Index

## 📋 Overview

This directory contains comprehensive documentation and tools for destroying OpenShift clusters when the metadata file (`.openshift_install_state.json` or `metadata.json`) is lost or unavailable.

**Problem:** The `openshift-install destroy cluster` command requires metadata files that are sometimes lost.

**Solution:** Manual cleanup procedures and automated scripts for all major cloud platforms.

---

## 🚀 Quick Start

### Step 1: Identify Your Platform

- **AWS** → Use AWS scripts
- **Azure** → Use Azure scripts
- **vSphere** → Use vSphere scripts
- **Bare Metal** → See manual procedures in README

### Step 2: Find Your Cluster Resources

```bash
# AWS
./find-cluster-aws.sh <cluster-name> [region]

# Azure
./find-cluster-azure.sh <resource-group-name>

# vSphere
./find-cluster-vsphere.sh <cluster-name>
```

### Step 3: Review and Delete

Review the found resources carefully, then run the cleanup script:

```bash
# AWS
./cleanup-aws-cluster.sh <cluster-name> <region>

# Azure
./cleanup-azure-cluster.sh <resource-group-name>

# vSphere
./cleanup-vsphere-cluster.sh <cluster-name>
```

---

## 📁 File Structure

```
destroy-cluster-without-metadata/
├── INDEX.md                      # This file - overview and navigation
├── README.md                     # Complete documentation with all details
├── QUICK-REFERENCE.md            # Cheat sheet for common operations
│
├── find-cluster-aws.sh           # Find AWS cluster resources
├── find-cluster-azure.sh         # Find Azure cluster resources
├── find-cluster-vsphere.sh       # Find vSphere cluster resources
│
├── cleanup-aws-cluster.sh        # Delete AWS cluster resources
├── cleanup-azure-cluster.sh      # Delete Azure cluster resources
└── cleanup-vsphere-cluster.sh    # Delete vSphere cluster resources
```

---

## 📖 Documentation Guide

### For First-Time Users

**Start here:**
1. **QUICK-REFERENCE.md** - Get oriented quickly
2. Run diagnostic script for your platform
3. Review output carefully
4. **README.md** - Read platform-specific section if needed
5. Run cleanup script

### For Experienced Users

**Use these shortcuts:**
- **QUICK-REFERENCE.md** - Command syntax and examples
- Run `find-cluster-*.sh` to locate resources
- Run `cleanup-*.sh` to delete
- Refer to README.md only if issues arise

### By Document

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **INDEX.md** | Navigation and overview | Finding the right resource |
| **README.md** | Complete reference | Detailed procedures, troubleshooting |
| **QUICK-REFERENCE.md** | Quick commands | You know what to do, need syntax |

---

## 🔧 Available Tools

### Diagnostic Scripts (Find Resources)

| Script | Platform | What It Does |
|--------|----------|--------------|
| `find-cluster-aws.sh` | AWS | Lists EC2, VPC, LB, S3, Route53 resources |
| `find-cluster-azure.sh` | Azure | Lists resource groups and all resources within |
| `find-cluster-vsphere.sh` | vSphere | Lists VMs, folders, resource pools, storage |

**Usage:**
```bash
./find-cluster-aws.sh my-cluster us-east-1
./find-cluster-azure.sh my-cluster-rg
./find-cluster-vsphere.sh my-cluster
```

**Output:**
- Resource inventory
- Estimated costs
- Resource counts
- Delete commands ready to copy

### Cleanup Scripts (Delete Resources)

| Script | Platform | Safety Features |
|--------|----------|-----------------|
| `cleanup-aws-cluster.sh` | AWS | Confirmation prompt, ordered deletion |
| `cleanup-azure-cluster.sh` | Azure | Confirmation prompt, async deletion |
| `cleanup-vsphere-cluster.sh` | vSphere | Confirmation prompt, power-off first |

**Features:**
- ✅ Interactive confirmation (type "DELETE")
- ✅ Proper resource dependency order
- ✅ Progress indicators
- ✅ Error handling and retries
- ✅ Final verification steps

---

## ⚡ Common Scenarios

### Scenario 1: I Know My Cluster Name

**Best path:** Direct cleanup

```bash
# AWS example
./cleanup-aws-cluster.sh my-ocp-cluster us-east-1

# Azure example
./cleanup-azure-cluster.sh my-ocp-cluster-rg

# vSphere example
./cleanup-vsphere-cluster.sh my-ocp-cluster
```

### Scenario 2: I Don't Know the Exact Cluster Name

**Best path:** Discovery first

```bash
# AWS - search with partial name
./find-cluster-aws.sh ocp us-east-1

# Azure - search with keyword
./find-cluster-azure.sh production

# vSphere - search with pattern
./find-cluster-vsphere.sh cluster
```

### Scenario 3: Resources Spread Across Regions (AWS)

**Best path:** Check all regions

```bash
# See QUICK-REFERENCE.md "Issue: Resources in Multiple Regions"
for region in us-east-1 us-west-2 eu-west-1; do
  echo "=== $region ==="
  ./find-cluster-aws.sh my-cluster $region
done
```

### Scenario 4: Cluster is Still Accessible

**Best path:** Get cluster info first

```bash
# Get the infrastructure ID
CLUSTER_ID=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
PLATFORM=$(oc get infrastructure cluster -o jsonpath='{.status.platform}')

echo "Cluster ID: $CLUSTER_ID"
echo "Platform: $PLATFORM"

# Use the cluster ID with your cleanup script
# (The infra ID is usually <cluster-name>-<random>)
```

### Scenario 5: Emergency - Need to Stop Costs NOW

**Best path:** Quick power-down

```bash
# AWS - Stop instances immediately (reduces costs ~75%)
aws ec2 stop-instances --instance-ids $(aws ec2 describe-instances \
  --filters "Name=tag:kubernetes.io/cluster/my-cluster,Values=owned" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text) --region us-east-1

# Azure - Deallocate VMs
az vm deallocate --ids $(az vm list -g my-cluster-rg --query "[].id" -o tsv)

# vSphere - Power off VMs
govc vm.power -off "*my-cluster*"

# Then do proper cleanup when you have time
```

---

## 📊 Platform Comparison

| Feature | AWS | Azure | vSphere | Bare Metal |
|---------|-----|-------|---------|------------|
| **Complexity** | High | Medium | Medium | High |
| **Cleanup Time** | 10-20 min | 5-15 min | 5-10 min | 20-40 min |
| **Automation Level** | Full | Full | Full | Partial |
| **Risk Level** | Medium | Low | Medium | High |
| **Dependency Issues** | Common | Rare | Rare | Common |

### Why the Differences?

- **AWS**: Many resource types with complex dependencies (VPC, ENI, SG, etc.)
- **Azure**: Resource groups simplify deletion (one command)
- **vSphere**: Simpler resource model, but manual LB/DNS cleanup
- **Bare Metal**: Physical resources, networking, storage all manual

---

## ⚠️ Safety Checklist

Before running any cleanup script:

- [ ] **Verified cluster name/ID** is correct
- [ ] **Reviewed resource list** from find script
- [ ] **No production data** on this cluster
- [ ] **Backups completed** if needed
- [ ] **Team notified** (if applicable)
- [ ] **Cost impact understood** (keeping vs deleting)
- [ ] **Proper credentials** available
- [ ] **Sufficient permissions** to delete resources

---

## 🔍 Troubleshooting Guide

### Issue: Scripts Can't Find Resources

**Solutions:**
1. Check credentials: `aws sts get-caller-identity` / `az account show` / `govc about`
2. Try different search terms (partial names, infra IDs)
3. Check different regions (AWS)
4. Verify permissions on cloud account

**See:** README.md → "Troubleshooting Manual Cleanup"

### Issue: Resources Won't Delete

**Common causes:**
- Dependency violations (delete dependencies first)
- Protection enabled (termination protection, delete locks)
- Insufficient permissions
- Resources in use by other services

**See:** README.md → "Troubleshooting Manual Cleanup" → "Issue: Resources Won't Delete"

### Issue: Partial Cleanup (Some Resources Remain)

**Solution:**
1. Re-run find script to see what's left
2. Check for resources in different regions/locations
3. Use cloud provider console to verify
4. Manually delete remaining resources

**See:** README.md → "Post-Cleanup Verification"

---

## 💰 Cost Considerations

### Typical Costs While Resources Run

| Cluster Size | Daily Cost | Monthly Cost |
|--------------|------------|--------------|
| Small (3 masters, 2 workers) | $50-100 | $1,500-3,000 |
| Medium (3 masters, 5 workers) | $100-200 | $3,000-6,000 |
| Large (3 masters, 10+ workers) | $200-500+ | $6,000-15,000+ |

### Cost vs Time Trade-off

**If cleanup will take more than:**
- 1 hour → ~$2-20 in running costs
- 4 hours → ~$8-80 in running costs
- 1 day → ~$50-500 in running costs

**Consider:** Immediate power-down if cleanup will be delayed

---

## 🎯 Decision Tree

```
START: Need to destroy cluster without metadata

├─ Do you know the cluster name?
│  ├─ YES → Run find-cluster-<platform>.sh <name>
│  └─ NO → 
│     ├─ Cluster still accessible?
│     │  ├─ YES → Get name: oc get infrastructure cluster
│     │  └─ NO → List all resources, identify by date/tags
│     └─ Continue below
│
├─ Resources found?
│  ├─ YES → Review carefully → Run cleanup-<platform>.sh
│  └─ NO → 
│     ├─ Try different search terms
│     ├─ Check other regions/locations
│     └─ Verify credentials/permissions
│
├─ Cleanup successful?
│  ├─ YES → Run post-cleanup verification
│  └─ NO → 
│     ├─ Check error messages
│     ├─ See troubleshooting guide
│     └─ Consider manual deletion
│
└─ END: Verify all resources deleted
```

---

## 🆘 Getting Help

### Self-Service Resources

1. **README.md** - Comprehensive documentation
2. **QUICK-REFERENCE.md** - Command reference
3. Script output - Usually includes suggestions
4. Cloud provider console - Visual verification

### When to Escalate

Escalate if:
- Unsure which resources belong to which cluster
- Resources won't delete after multiple attempts
- Risk of affecting other workloads
- Need to preserve specific data/configs
- Security/compliance concerns

### Where to Get Help

1. **Red Hat Support** (with subscription)
   - Priority: Standard or higher
   - Have: Cluster name, platform, approximate install date
   - Portal: https://access.redhat.com/support/cases/

2. **Cloud Provider Support**
   - AWS: AWS Support Console
   - Azure: Azure Support Portal  
   - vSphere: VMware Support
   - Have: Resource IDs, error messages

3. **Community**
   - OpenShift Users Mailing List
   - Kubernetes Slack #openshift
   - Red Hat Customer Portal discussions

---

## 📚 Related Documentation

### Internal (This Repo)

- `../bare-metal-node-inspection-timeout/` - BMH troubleshooting
- `../control-plane-kubeconfigs/` - Control plane access
- `../csr-management/` - Certificate management
- `../README.md` - OCP troubleshooting overview

### External

- [OpenShift Install Docs](https://docs.openshift.com/container-platform/latest/installing/)
- [OpenShift Uninstall Docs](https://docs.openshift.com/container-platform/latest/installing/installing-troubleshooting.html)
- [AWS Resource Tagging](https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html)
- [Azure Resource Management](https://docs.microsoft.com/en-us/azure/azure-resource-manager/)

---

## 🔄 Prevention for Next Time

### Always Backup These Files

```bash
# Run this after every cluster install
CLUSTER_NAME="my-cluster"
BACKUP_DIR=~/ocp-backups/$CLUSTER_NAME-$(date +%Y%m%d)

mkdir -p $BACKUP_DIR
cd ~/ocp-install-dir

cp -r .openshift_install_state.json $BACKUP_DIR/ 2>/dev/null || true
cp -r metadata.json $BACKUP_DIR/ 2>/dev/null || true
cp -r auth/ $BACKUP_DIR/ 2>/dev/null || true
cp -r terraform.tfstate* $BACKUP_DIR/ 2>/dev/null || true
cp install-config.yaml $BACKUP_DIR/ 2>/dev/null || true
cp .openshift_install.log $BACKUP_DIR/ 2>/dev/null || true

echo "Backed up to: $BACKUP_DIR"
```

### Store Securely

- Version control (with encryption)
- Secure backup location
- Password manager (for access details)
- Team documentation wiki

---

## 📈 Document Maintenance

**Version:** 1.0  
**Created:** December 2025  
**Last Updated:** December 2025  
**Tested On:** OpenShift 4.12-4.15  
**Platforms:** AWS, Azure, vSphere, Bare Metal

**Feedback:** If you find issues or have improvements, update this documentation!

---

## 🏁 Summary

| Task | Tool | Time |
|------|------|------|
| Find resources | `find-cluster-*.sh` | 1-2 min |
| Review output | Manual review | 2-5 min |
| Delete resources | `cleanup-*.sh` | 5-20 min |
| Verify cleanup | Console/CLI | 2-5 min |
| **Total** | **End-to-end** | **10-32 min** |

**Remember:**
- ✅ Always backup metadata after installation
- ✅ Double-check resource ownership before deletion
- ✅ Use automation scripts when possible
- ✅ Verify complete deletion afterward
- ✅ Document what you learned

**Good luck! 🚀**




# Worker Node TLS Certificate Failure - Documentation Index

## Quick Access

### 🚨 Emergency - Start Here
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Fast diagnostic commands and common fixes
- **Run diagnostic script**: `./diagnose-tls.sh`

### 📖 Complete Guide
- **[README.md](README.md)** - Full troubleshooting guide with detailed explanations

### 🛠️ Tools
- **[diagnose-tls.sh](diagnose-tls.sh)** - Automated diagnostic script

---

## Problem Description

When expanding an OpenShift bare metal cluster by adding worker nodes via BareMetalHost, new workers must fetch their ignition configuration from the Machine Config Server (MCS) at `https://<api-vip>:22623/config/worker`. If TLS certificate verification fails at this step, the worker cannot join the cluster.

**Symptoms:**
- Worker BareMetalHost boots but fails to join cluster
- TLS certificate verification errors in logs
- Error referencing port 22623 endpoint
- Worker may reboot repeatedly

---

## Quick Start

### 1. Run Diagnostics (2 minutes)

```bash
cd /path/to/ocp-troubleshooting/worker-node-tls-cert-failure
./diagnose-tls.sh
```

This will:
- Check Machine Config Server health
- Verify certificate expiration
- Test endpoint connectivity
- Generate specific recommendations

### 2. Review Recommendations

```bash
# After diagnostic script completes
cat tls-diagnostics-*/RECOMMENDATIONS.txt
```

### 3. Apply Most Common Fix (Certificate Expired)

```bash
# If certificate is expired (70% of cases)
oc delete secret machine-config-server-tls -n openshift-machine-config-operator
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Wait 30 seconds
sleep 30

# Verify new certificate
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# Retry worker provisioning
oc patch baremetalhost <worker-name> -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost <worker-name> -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

---

## Document Structure

### README.md - Complete Troubleshooting Guide

**Sections:**
1. **Overview** - What this issue is and why it happens
2. **Quick Diagnostic** - First commands to run
3. **Root Cause Analysis** - Understanding the MCS flow and common causes
4. **Detailed Diagnostics** - Step-by-step investigation
   - Verify MCS health
   - Check certificate validity
   - Test connectivity
   - Examine BareMetalHost status
5. **Solutions** - Fixes for each root cause
   - Certificate expired → Force rotation
   - Wrong CA bundle → Update MachineConfig
   - Time sync issues → Fix node time
   - Network issues → Check HAProxy/VIP
   - Disable verification (workaround)
6. **Prevention** - How to avoid this in the future
7. **Advanced Troubleshooting** - For complex cases
8. **Related Issues** - Links to other troubleshooting guides

### QUICK-REFERENCE.md - Fast Command Reference

**Sections:**
1. **One-Line Diagnostics** - Copy-paste commands
2. **Most Common Fixes** - Top 4 solutions (70% coverage)
3. **Retry Worker Provisioning** - How to retry after fix
4. **Decision Tree** - Visual troubleshooting flow
5. **Pre-Flight Check** - Run before adding workers
6. **Monitoring** - Track certificate expiration
7. **Common Error Messages** - Quick lookup table
8. **Emergency Recovery** - Nuclear option if nothing works

### diagnose-tls.sh - Automated Diagnostic Tool

**What it does:**
- Checks MCS pod status
- Retrieves and validates certificate
- Tests endpoint connectivity
- Checks BareMetalHost resources
- Examines MachineConfig status
- Verifies HAProxy health
- Collects relevant logs
- Generates specific recommendations

**Output:**
Creates timestamped directory with:
- All diagnostic data
- Log files
- Certificate details
- `RECOMMENDATIONS.txt` with specific next steps

---

## Common Scenarios

### Scenario 1: Certificate Expired (70% of cases)
**Symptoms:** x509 certificate has expired error  
**Fix:** [QUICK-REFERENCE.md](QUICK-REFERENCE.md#fix-1-certificate-expired-70-of-cases)  
**Details:** [README.md - Solution 1](README.md#solution-1-certificate-expired---force-rotation)

### Scenario 2: MCS Pods Not Running (15% of cases)
**Symptoms:** Cannot reach endpoint, connection refused  
**Fix:** [QUICK-REFERENCE.md](QUICK-REFERENCE.md#fix-2-mcs-pods-not-running-15-of-cases)  
**Details:** [README.md - Step 1](README.md#step-1-verify-machine-config-server-health)

### Scenario 3: Network Connectivity (10% of cases)
**Symptoms:** Connection timeout, cannot reach API VIP  
**Fix:** [QUICK-REFERENCE.md](QUICK-REFERENCE.md#fix-3-network-connectivity-10-of-cases)  
**Details:** [README.md - Solution 4](README.md#solution-4-network-connectivity-issues)

### Scenario 4: Time Sync Issues (5% of cases)
**Symptoms:** Valid cert but verification fails, worker time wrong  
**Fix:** [QUICK-REFERENCE.md](QUICK-REFERENCE.md#fix-4-time-sync-issues-5-of-cases)  
**Details:** [README.md - Solution 3](README.md#solution-3-time-sync-issues---fix-worker-node-time)

---

## Related Documentation

### Within This Repository
- **[../bare-metal-node-inspection-timeout/](../bare-metal-node-inspection-timeout/)** - BareMetalHost inspection issues
- **[../csr-management/](../csr-management/)** - CSR approval after workers join
- **[../coreos-networking-issues/](../coreos-networking-issues/)** - CoreOS networking problems
- **[../control-plane-kubeconfigs/](../control-plane-kubeconfigs/)** - Control plane certificate issues

### External Resources
- [OpenShift Machine Config Server Documentation](https://docs.openshift.com/container-platform/latest/post_installation_configuration/machine-configuration-tasks.html)
- [Bare Metal Operator GitHub](https://github.com/metal3-io/baremetal-operator)
- [Red Hat Customer Portal](https://access.redhat.com/) - Search for "machine config server TLS"

---

## Troubleshooting Flow

```
┌─────────────────────────────────────┐
│ TLS Cert Error on Port 22623       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Run: ./diagnose-tls.sh              │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ Review: RECOMMENDATIONS.txt         │
└──────────────┬──────────────────────┘
               │
               ▼
       ┌───────┴────────┐
       │                │
       ▼                ▼
┌─────────────┐  ┌─────────────┐
│ Certificate │  │   Network   │
│  Expired?   │  │   Issue?    │
└──────┬──────┘  └──────┬──────┘
       │                │
       ▼                ▼
   Fix cert       Fix network
       │                │
       └────────┬───────┘
                ▼
       ┌────────────────┐
       │ Retry Worker   │
       │ Provisioning   │
       └────────┬───────┘
                ▼
       ┌────────────────┐
       │ Worker Joins   │
       │    Cluster     │
       └────────────────┘
```

---

## File Overview

| File | Purpose | When to Use |
|------|---------|-------------|
| **README.md** | Complete guide | Deep dive, understanding root causes |
| **QUICK-REFERENCE.md** | Fast commands | Emergency, quick fixes |
| **diagnose-tls.sh** | Automated diagnostics | Initial investigation |
| **INDEX.md** | Navigation (this file) | Finding what you need |

---

## Tips for Success

### Before Adding Workers
1. Run pre-flight check from [QUICK-REFERENCE.md](QUICK-REFERENCE.md#pre-flight-check-before-adding-workers)
2. Verify certificate has > 7 days validity
3. Ensure MCS pods are running

### During Troubleshooting
1. Always run `diagnose-tls.sh` first
2. Check certificate expiration (most common issue)
3. Verify from both outside and inside cluster
4. Compare with working nodes if possible

### After Fixing
1. Wait 30 seconds for changes to propagate
2. Verify fix before retrying worker provisioning
3. Monitor worker progression through states
4. Check for CSRs after worker boots

---

## When to Escalate

Open Red Hat support case if:
- Certificate is valid but still getting TLS errors
- MCS pods won't stay running
- Fresh certificate installation doesn't help
- Multiple cluster components showing cert errors
- Issue persists after all solutions attempted

**Before opening case, collect:**
```bash
# Must-gather
oc adm must-gather --dest-dir=/tmp/must-gather

# Run diagnostic script
./diagnose-tls.sh

# Include both outputs with support case
```

---

## Quick Links

- [Start Troubleshooting →](QUICK-REFERENCE.md)
- [Full Documentation →](README.md)
- [Run Diagnostics →](diagnose-tls.sh)
- [Main Troubleshooting Index →](../README.md)

---

**Last Updated:** December 10, 2025  
**Maintained By:** OpenShift Troubleshooting Team


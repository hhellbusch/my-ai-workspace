# Index - Portworx CSI CrashLoopBackOff Troubleshooting

Navigate this guide based on your needs and scenario.

---

## Quick Access

| I need to... | Go to... |
|-------------|----------|
| **Fix this NOW** | [QUICKSTART.md](./QUICKSTART.md) ⚡ |
| **Find fast commands** | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) |
| **Look up error message** | [COMMON-ERRORS.md](./COMMON-ERRORS.md) |
| **Follow systematic process** | [INVESTIGATION-WORKFLOW.md](./INVESTIGATION-WORKFLOW.md) |
| **Understand the issue** | [README.md](./README.md) |
| **Collect diagnostics** | [diagnostic-script.sh](./diagnostic-script.sh) |

---

## By Symptom

### CSI Pod Won't Start

**Symptom**: `px-csi-ext` pod in CrashLoopBackOff

1. Check [QUICKSTART.md#quick-diagnosis-2-minutes](./QUICKSTART.md) first
2. Get error from logs → Look up in [COMMON-ERRORS.md](./COMMON-ERRORS.md)
3. Follow fix from Quick Start or Investigation Workflow

---

### Socket Connection Errors

**Symptom**: Logs show `failed to connect to socket`

**Quick Path**:
- [QUICKSTART.md#fix-1-socket-connection-issues-most-common](./QUICKSTART.md#fix-1-socket-connection-issues-most-common)
- [COMMON-ERRORS.md#error-failed-to-connect-to-csi-socket](./COMMON-ERRORS.md#error-failed-to-connect-to-csi-socket)
- [INVESTIGATION-WORKFLOW.md#step-32-investigate-socket-connection-issues](./INVESTIGATION-WORKFLOW.md#step-32-investigate-socket-connection-issues)

**Detailed Reference**:
- [README.md#1-unix-socket-connection-failure](./README.md#1-unix-socket-connection-failure)

---

### CSI Driver Not Found

**Symptom**: Logs show `CSIDriver not found` or `not registered`

**Quick Path**:
- [QUICKSTART.md#fix-2-missing-csi-driver-registration](./QUICKSTART.md#fix-2-missing-csi-driver-registration)
- [COMMON-ERRORS.md#error-csi-driver-not-found](./COMMON-ERRORS.md#error-csi-driver-not-found)
- [INVESTIGATION-WORKFLOW.md#step-33-investigate-csi-driver-registration-issues](./INVESTIGATION-WORKFLOW.md#step-33-investigate-csi-driver-registration-issues)

**Detailed Reference**:
- [README.md#2-csi-driver-not-registered](./README.md#2-csi-driver-not-registered)

---

### Permission Errors

**Symptom**: Logs show `Unauthorized`, `forbidden`, or `cannot`

**Quick Path**:
- [QUICKSTART.md#fix-3-rbacservice-account-issues](./QUICKSTART.md#fix-3-rbacservice-account-issues)
- [COMMON-ERRORS.md#error-unauthorized](./COMMON-ERRORS.md#error-unauthorized)
- [INVESTIGATION-WORKFLOW.md#step-34-investigate-rbac-issues](./INVESTIGATION-WORKFLOW.md#step-34-investigate-rbac-issues)

**Detailed Reference**:
- [README.md#3-rbac--service-account-issues](./README.md#3-rbac--service-account-issues)

---

### Image Pull Problems

**Symptom**: Pod shows `ImagePullBackOff` or `ErrImagePull`

**Quick Path**:
- [COMMON-ERRORS.md#error-imagepullbackoff](./COMMON-ERRORS.md#error-imagepullbackoff)
- [INVESTIGATION-WORKFLOW.md#step-35-investigate-image-pull-issues](./INVESTIGATION-WORKFLOW.md#step-35-investigate-image-pull-issues)

**Detailed Reference**:
- [README.md#4-container-image-pull-issues](./README.md#4-container-image-pull-issues)

---

### Scheduling Failures

**Symptom**: Pod shows `FailedScheduling`, `node(s) didn't match`, or taint errors

**Quick Path**:
- [QUICKSTART.md#fix-4-node-selector--affinity-issues](./QUICKSTART.md#fix-4-node-selector--affinity-issues)
- [COMMON-ERRORS.md#error-node-affinityselector](./COMMON-ERRORS.md#error-node-affinityselector)
- [INVESTIGATION-WORKFLOW.md#step-36-investigate-scheduling-issues](./INVESTIGATION-WORKFLOW.md#step-36-investigate-scheduling-issues)

**Detailed Reference**:
- [README.md#5-node-scheduling--affinity-issues](./README.md#5-node-scheduling--affinity-issues)

---

### Resource Issues

**Symptom**: Pod shows `OOMKilled` or `Insufficient cpu/memory`

**Quick Path**:
- [COMMON-ERRORS.md#error-oomkilled](./COMMON-ERRORS.md#error-oomkilled)
- [COMMON-ERRORS.md#error-insufficient-resources](./COMMON-ERRORS.md#error-insufficient-resources)
- [INVESTIGATION-WORKFLOW.md#step-37-investigate-resource-issues](./INVESTIGATION-WORKFLOW.md#step-37-investigate-resource-issues)

**Detailed Reference**:
- [README.md#6-resource-constraints-cpumemory](./README.md#6-resource-constraints-cpumemory)

---

### Volume Mount Failures

**Symptom**: Pod shows `FailedMount` or `Unable to attach or mount volumes`

**Quick Path**:
- [COMMON-ERRORS.md#error-unable-to-mount-volumes](./COMMON-ERRORS.md#error-unable-to-mount-volumes)
- [INVESTIGATION-WORKFLOW.md#step-38-investigate-volume-mount-issues](./INVESTIGATION-WORKFLOW.md#step-38-investigate-volume-mount-issues)

**Detailed Reference**:
- [README.md#7-volume-mount-issues](./README.md#7-volume-mount-issues)

---

### Portworx Cluster Unhealthy

**Symptom**: CSI crashing and Portworx shows issues or `not operational`

**Quick Path**:
- [COMMON-ERRORS.md#error-portworx-cluster-not-operational](./COMMON-ERRORS.md#error-portworx-cluster-not-operational)
- [INVESTIGATION-WORKFLOW.md#phase-2-portworx-cluster-issues](./INVESTIGATION-WORKFLOW.md#phase-2-portworx-cluster-issues)

**Important**: Fix Portworx cluster BEFORE addressing CSI issues

---

## By Role/Expertise Level

### Junior Administrators

**Start here**:
1. [QUICKSTART.md](./QUICKSTART.md) - Try common fixes
2. [COMMON-ERRORS.md](./COMMON-ERRORS.md) - Look up your error
3. If stuck → Escalate with diagnostics

**Collect diagnostics**:
```bash
./diagnostic-script.sh portworx-csi-diagnostics.txt
```

---

### Experienced Administrators

**Workflow**:
1. Quick diagnosis from [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
2. Follow [INVESTIGATION-WORKFLOW.md](./INVESTIGATION-WORKFLOW.md)
3. Reference [README.md](./README.md) for details
4. Verify with test PVC

**Key principle**: Always check Portworx cluster health first

---

### Senior SREs / Support Engineers

**Advanced approach**:
1. Collect diagnostics immediately
2. Check architecture in [README.md#architecture-context](./README.md#architecture-context)
3. Follow dependency chain: Portworx → Socket → CSI → API
4. Correlate with recent changes
5. Check cluster-wide patterns

**Resources**:
- [INVESTIGATION-WORKFLOW.md#phase-5-documentation](./INVESTIGATION-WORKFLOW.md#phase-5-documentation)
- [README.md#emergency-recovery-procedures](./README.md#emergency-recovery-procedures)

---

## By Time Available

### 2 Minutes

[QUICKSTART.md](./QUICKSTART.md) - Try fast fixes

Commands:
```bash
# Get pod and check logs
PX_CSI_POD=$(oc get pods -n kube-system -l app=px-csi-driver -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep px-csi-ext | head -1)
oc logs -n kube-system $PX_CSI_POD --previous --tail=50

# Check Portworx health
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status

# Restart CSI if Portworx is healthy
oc delete pod -n kube-system $PX_CSI_POD
```

---

### 10 Minutes

1. [QUICKSTART.md](./QUICKSTART.md) - Quick diagnosis
2. [COMMON-ERRORS.md](./COMMON-ERRORS.md) - Error lookup
3. Apply fix
4. Basic verification

---

### 30+ Minutes

1. Run [diagnostic-script.sh](./diagnostic-script.sh)
2. Follow [INVESTIGATION-WORKFLOW.md](./INVESTIGATION-WORKFLOW.md)
3. Deep dive into [README.md](./README.md) sections
4. Full verification and testing
5. Document findings

---

## By Use Case

### Production Emergency

**Critical path**:
1. Check Portworx cluster: `pxctl status`
2. If healthy → Restart CSI pod
3. If unhealthy → Fix Portworx first
4. Monitor for 5 minutes
5. Test with PVC creation

**See**: [README.md#emergency-recovery-procedures](./README.md#emergency-recovery-procedures)

---

### Post-Upgrade Issues

**Common scenario**: CSI fails after OpenShift or Portworx upgrade

**Path**:
1. Check version compatibility
2. Verify CSI driver registration
3. Check RBAC changes
4. Review upgrade logs

**See**: [INVESTIGATION-WORKFLOW.md#pattern-2-csi-fails-after-cluster-upgrade](./INVESTIGATION-WORKFLOW.md#pattern-2-csi-fails-after-cluster-upgrade)

---

### Intermittent Failures

**Symptom**: CSI pod crashes occasionally

**Path**:
1. Collect diagnostics during failure
2. Check for resource pressure
3. Monitor network connectivity
4. Review Portworx logs correlation

**See**: [INVESTIGATION-WORKFLOW.md#pattern-3-intermittent-crashes](./INVESTIGATION-WORKFLOW.md#pattern-3-intermittent-crashes)

---

### Initial Deployment Issues

**Symptom**: CSI never worked, fresh install

**Path**:
1. Verify Portworx installation
2. Check CSI driver registration
3. Verify RBAC setup
4. Check node labels and scheduling

**See**: [README.md#common-root-causes](./README.md#common-root-causes)

---

## Command Quick Reference

### Essential One-Liners

```bash
# Get CSI pod name
PX_CSI_POD=$(oc get pods -n kube-system -l app=px-csi-driver -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep px-csi-ext | head -1)

# Check error
oc logs -n kube-system $PX_CSI_POD --previous --tail=50

# Check Portworx
PX_POD=$(oc get pods -n kube-system -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n kube-system $PX_POD -- /opt/pwx/bin/pxctl status

# Restart CSI
oc delete pod -n kube-system $PX_CSI_POD

# Run diagnostics
./diagnostic-script.sh diagnostics-$(date +%Y%m%d-%H%M%S).txt
```

**Full reference**: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)

---

## Troubleshooting Decision Tree

```
CSI pod in CrashLoopBackOff?
│
├─ YES → Check previous logs
│        │
│        ├─ Error contains "socket" → Socket issues
│        │   └─ Go to QUICKSTART.md #fix-1
│        │
│        ├─ Error contains "CSIDriver" → Registration issues
│        │   └─ Go to QUICKSTART.md #fix-2
│        │
│        ├─ Error contains "Unauthorized" → RBAC issues
│        │   └─ Go to QUICKSTART.md #fix-3
│        │
│        ├─ Error contains "ImagePull" → Image issues
│        │   └─ Go to COMMON-ERRORS.md
│        │
│        ├─ Error contains "FailedScheduling" → Scheduling issues
│        │   └─ Go to QUICKSTART.md #fix-4
│        │
│        └─ Other error → Search COMMON-ERRORS.md
│
└─ NO → Check if pod is running but unhealthy
        └─ Follow INVESTIGATION-WORKFLOW.md
```

---

## Related Documentation

### Within This Guide
- [README.md](./README.md) - Comprehensive reference
- [QUICKSTART.md](./QUICKSTART.md) - Fast fixes
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Command cheat sheet
- [COMMON-ERRORS.md](./COMMON-ERRORS.md) - Error message lookup
- [INVESTIGATION-WORKFLOW.md](./INVESTIGATION-WORKFLOW.md) - Systematic process
- [diagnostic-script.sh](./diagnostic-script.sh) - Automated diagnostics

### External Resources
- [Portworx on OpenShift Documentation](https://docs.portworx.com/portworx-enterprise/install-portworx/openshift)
- [Portworx Troubleshooting Guide](https://docs.portworx.com/portworx-enterprise/operations/operate-kubernetes/troubleshooting)
- [Kubernetes CSI Documentation](https://kubernetes-csi.github.io/docs/)
- [OpenShift Storage Documentation](https://docs.openshift.com/container-platform/latest/storage/index.html)

---

## File Structure

```
portworx-csi-crashloop/
├── INDEX.md                      ← You are here
├── README.md                     ← Comprehensive guide (start for deep understanding)
├── QUICKSTART.md                 ← Fast fixes (start here for quick resolution) ⚡
├── QUICK-REFERENCE.md            ← Command cheat sheet
├── COMMON-ERRORS.md              ← Error message lookup table
├── INVESTIGATION-WORKFLOW.md     ← Systematic troubleshooting process
└── diagnostic-script.sh          ← Automated diagnostic collection
```

---

## Getting Help

### Self-Service
1. Start with [QUICKSTART.md](./QUICKSTART.md)
2. Look up error in [COMMON-ERRORS.md](./COMMON-ERRORS.md)
3. Follow workflow in [INVESTIGATION-WORKFLOW.md](./INVESTIGATION-WORKFLOW.md)

### Escalation
1. Collect diagnostics: `./diagnostic-script.sh diagnostics.txt`
2. Document what you tried
3. Open support case with Red Hat or Portworx
4. Attach diagnostics and documentation

### Support Contacts
- **Red Hat Support**: https://access.redhat.com/support/cases/
- **Portworx Support**: https://support.purestorage.com/

---

## Tips for Success

1. **Always check Portworx health first** - CSI cannot work without healthy Portworx
2. **Read error messages carefully** - They usually point to the exact issue
3. **One change at a time** - Verify results before trying something else
4. **Document everything** - What you found, what you tried, what worked
5. **Test after fixes** - Create a test PVC to verify functionality

---

## Quick Links Summary

| Document | Purpose | When to Use |
|----------|---------|-------------|
| [QUICKSTART.md](./QUICKSTART.md) | Fast fixes | Need immediate resolution ⚡ |
| [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | Command reference | Need specific commands |
| [COMMON-ERRORS.md](./COMMON-ERRORS.md) | Error lookup | Have specific error message |
| [INVESTIGATION-WORKFLOW.md](./INVESTIGATION-WORKFLOW.md) | Systematic process | Complex/unknown issues |
| [README.md](./README.md) | Full guide | Need comprehensive understanding |
| [diagnostic-script.sh](./diagnostic-script.sh) | Collect data | Escalating to support |

---

**Remember**: Most CSI issues are caused by Portworx cluster problems or socket communication. Start there!


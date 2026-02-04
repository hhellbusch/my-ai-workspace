# OpenShift Troubleshooting Guides

Comprehensive troubleshooting documentation for common OpenShift (OCP) cluster issues.

## Available Guides

### Control Plane Issues

- **[API Slowness and Web Console Performance](api-slowness-web-console/README.md)** - Comprehensive guide for API slowness and web console performance issues
  - **[Quick Reference](api-slowness-web-console/QUICK-REFERENCE.md)** - Fast diagnostic commands and decision tree for rapid response ⚡
  - [Index](api-slowness-web-console/INDEX.md) - Guide navigation and symptom-based workflows
  - Script: `diagnostic-script.sh` - Automated performance diagnostic tool

- **[Control Plane Kubeconfigs](control-plane-kubeconfigs/README.md)** - Complete guide to kubeconfigs on CoreOS control plane nodes
  - [Quick Reference](control-plane-kubeconfigs/QUICK-REFERENCE.md) - Copy-paste commands for monitoring cluster operators
  - [Installation Monitoring](control-plane-kubeconfigs/INSTALL-MONITORING.md) - Monitor installation progress from control plane nodes
  - [Index](control-plane-kubeconfigs/INDEX.md) - Guide navigation and use cases
  - Script: `monitor-cluster.sh` - Automated cluster operator monitoring

- **[kube-controller-manager Crash Loop](kube-controller-manager-crashloop/README.md)** - Comprehensive guide for diagnosing and fixing controller manager crash loops
  - [Quick Reference](kube-controller-manager-crashloop/QUICK-REFERENCE.md) - Fast command reference and decision tree
  - [Operator Errors](kube-controller-manager-crashloop/OPERATOR-ERRORS.md) - Troubleshooting operator-specific issues

### Bare Metal Provisioning Issues

- **[Bare Metal Node Inspection Timeout](bare-metal-node-inspection-timeout/README.md)** - Complete guide for nodes stuck in inspecting state
  - **[Force Re-Inspection](bare-metal-node-inspection-timeout/FORCE-REINSPECTION.md)** - Quick commands to force a stuck node to re-inspect ⚡
  - [Quick Reference](bare-metal-node-inspection-timeout/QUICK-REFERENCE.md) - Fast BMC troubleshooting commands

- **[Worker Node TLS Certificate Failure](worker-node-tls-cert-failure/README.md)** - Troubleshoot TLS certificate verification failures when adding workers
  - [Quick Reference](worker-node-tls-cert-failure/QUICK-REFERENCE.md) - Fast diagnostic commands and common fixes
  - [Index](worker-node-tls-cert-failure/INDEX.md) - Guide navigation and quick scenarios
  - Script: `diagnose-tls.sh` - Automated TLS/certificate diagnostic tool

### Certificate Management

- **[CSR Management](csr-management/README.md)** - Complete guide for managing Certificate Signing Requests
  - [Quick Reference](csr-management/QUICK-REFERENCE.md) - Essential CSR approval commands
  - [Real-World Examples](csr-management/REAL-WORLD-EXAMPLES.md) - Actual scenarios from field experience
  - Scripts: `approve-all-pending.sh`, `approve-by-node.sh`, `watch-and-approve.sh`

### CoreOS System Issues

- **[CoreOS Networking Issues](coreos-networking-issues/README.md)** - Comprehensive network troubleshooting for CoreOS systems
  - [Quick Reference](coreos-networking-issues/QUICK-REFERENCE.md) - Essential network diagnostic and fix commands
  - [Examples](coreos-networking-issues/EXAMPLES.md) - Real-world output from common network failure scenarios
  - [Index](coreos-networking-issues/INDEX.md) - Guide navigation and workflow
  - Script: `diagnose-network.sh` - Automated network diagnostic tool

### Automation Platform Issues

- **[AAP SSH Connection MTU Issues](aap-ssh-mtu-issues/README.md)** - Complete guide for SSH connection failures from Ansible Automation Platform due to MTU mismatches
  - **[Quick Reference](aap-ssh-mtu-issues/QUICK-REFERENCE.md)** - Fast MTU diagnostics and SSH fixes ⚡
  - [Examples](aap-ssh-mtu-issues/EXAMPLES.md) - 6 detailed real-world scenarios with resolutions
  - [Index](aap-ssh-mtu-issues/INDEX.md) - Guide navigation by symptom and task
  - Script: `diagnose-mtu.sh` - Automated MTU and path discovery diagnostic tool

### Virtualization Issues (KubeVirt)

- **[KubeVirt VM Stuck in Provisioning](kubevirt-vm-stuck-provisioning/README.md)** - Fix VMs blocked by missing OADP/Velero webhook service
  - **[Quick Start](kubevirt-vm-stuck-provisioning/QUICKSTART.md)** - 1-minute fix for VM provisioning issues ⚡
  - [Remove Webhook](kubevirt-vm-stuck-provisioning/REMOVE-WEBHOOK.md) - Quick fix that disables OADP for VMs
  - [Repair Velero Plugin](kubevirt-vm-stuck-provisioning/REPAIR-VELERO-PLUGIN.md) - Proper fix maintaining OADP functionality
  - [Investigation Workflow](kubevirt-vm-stuck-provisioning/INVESTIGATION-WORKFLOW.md) - Systematic troubleshooting for any VM provisioning issue
  - [Verification](kubevirt-vm-stuck-provisioning/VERIFICATION.md) - Post-fix validation steps
  - [Prevention](kubevirt-vm-stuck-provisioning/PREVENTION.md) - Monitoring and best practices to avoid future issues
  - Scripts: `diagnostic-commands.sh`, `fix-velero-webhook.sh` - Automated diagnostic and fix tools

### Namespace Management

- **[Namespace Stuck in Terminating State](namespace-stuck-terminating/README.md)** - Complete guide for fixing namespaces stuck in Terminating state
  - **[Quick Reference](namespace-stuck-terminating/QUICK-REFERENCE.md)** - Fast commands for common finalizer scenarios ⚡
  - [Examples](namespace-stuck-terminating/EXAMPLES.md) - Real-world scenarios including OpenTelemetry, RHACM, and more
  - Scripts: `cleanup-namespace-finalizers.sh`, `investigate-namespace.sh` - Automated investigation and cleanup tools

### Storage Issues

- **[Portworx CSI Pod CrashLoopBackOff](portworx-csi-crashloop/README.md)** - Complete guide for troubleshooting px-csi-ext pod crashes
  - **[Quick Start](portworx-csi-crashloop/QUICKSTART.md)** - Fast fixes for common CSI issues ⚡
  - [Quick Reference](portworx-csi-crashloop/QUICK-REFERENCE.md) - Essential command reference and decision tree
  - [Common Errors](portworx-csi-crashloop/COMMON-ERRORS.md) - Error message lookup table with solutions
  - [Investigation Workflow](portworx-csi-crashloop/INVESTIGATION-WORKFLOW.md) - Systematic troubleshooting process
  - [Index](portworx-csi-crashloop/INDEX.md) - Guide navigation by symptom, role, and time available
  - Script: `diagnostic-script.sh` - Automated diagnostic data collection

## Using These Guides

Each guide follows this structure:

1. **Overview** - What the issue is and why it matters
2. **Quick Diagnosis** - Fast commands to identify the problem
3. **Common Root Causes** - Typical causes with diagnosis and resolution steps
4. **Step-by-Step Process** - Systematic troubleshooting approach
5. **Emergency Procedures** - What to do when things are critical
6. **Prevention** - How to avoid the issue in the future

## Quick Start

1. Navigate to the guide for your issue
2. Run the Quick Diagnosis commands
3. Look for your symptoms in the Common Root Causes section
4. Follow the resolution steps
5. Use Emergency Procedures if needed

## General Troubleshooting Principles

### 1. Check Dependencies First

OpenShift control plane components have dependencies:
```
etcd → API Server → Controller Manager / Scheduler
```
Always fix issues from left to right.

### 2. Collect Before Acting

Always collect diagnostic data before making changes:
```bash
oc adm must-gather
```

### 3. Check Cluster Operators

```bash
oc get clusteroperators
```
This shows overall cluster health at a glance.

### 4. Review Recent Changes

Many issues stem from recent changes:
- Configuration updates
- Cluster upgrades
- Certificate rotations
- Infrastructure changes

### 5. Monitor Recovery

After applying fixes, verify:
- Pods are stable (no restarts for 10+ minutes)
- Cluster operators show Available=True, Degraded=False
- Workloads function normally

## Essential Commands

```bash
# Overall cluster health
oc get clusteroperators
oc get nodes

# Control plane health
oc get pods -n openshift-etcd
oc get pods -n openshift-kube-apiserver
oc get pods -n openshift-kube-controller-manager
oc get pods -n openshift-kube-scheduler

# Collect diagnostics
oc adm must-gather
oc adm inspect ns/<namespace>

# Check recent events
oc get events --all-namespaces --sort-by='.lastTimestamp' | tail -50
```

## Support Resources

- [OpenShift Documentation](https://docs.openshift.com/)
- [Red Hat Customer Portal](https://access.redhat.com/)
- [OpenShift CLI Reference](https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html)

## Contributing

When adding new troubleshooting guides:

1. Use the existing structure as a template
2. Include practical, tested commands
3. Provide clear decision trees
4. Add both comprehensive and quick reference versions
5. Test all command examples

## Future Guides

Planned troubleshooting guides:

- [ ] etcd cluster issues
- [x] API slowness and web console performance - See [API Slowness and Web Console Performance](api-slowness-web-console/README.md)
- [ ] Node NotReady states
- [ ] Networking issues (SDN/OVN) - OpenShift networking layer
- [x] CoreOS base system networking - See [CoreOS Networking Issues](coreos-networking-issues/README.md)
- [x] Storage/PVC problems (Portworx) - See [Portworx CSI Pod CrashLoopBackOff](portworx-csi-crashloop/README.md)
- [ ] Storage/PVC problems (OCS/ODF)
- [ ] Image registry issues
- [ ] Authentication failures
- [ ] Operator degradation patterns
- [ ] Upgrade stuck/failed scenarios
- [ ] Bare metal provisioning failures (post-inspection)
- [ ] Certificate rotation issues
- [ ] Router/Ingress problems
- [x] KubeVirt VM provisioning issues - See [KubeVirt VM Stuck in Provisioning](kubevirt-vm-stuck-provisioning/README.md)
- [x] Namespace stuck in Terminating state - See [Namespace Stuck in Terminating State](namespace-stuck-terminating/README.md)


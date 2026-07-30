---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
---

# OpenShift Troubleshooting Guides

Comprehensive troubleshooting documentation for common OpenShift (OCP) cluster issues.

**Site:** [OCP troubleshooting section](https://hhellbusch.github.io/my-ai-workspace/devops/ocp/troubleshooting/) · **Symptom lookup:** [SYMPTOM-INDEX.md](../../SYMPTOM-INDEX.md)

## Available Guides

### Installation Failures

- **[Failed OCP Install](failed-ocp-install/README.md)** - Step-by-step troubleshooting for installations that did not complete (for installers new to Linux; teaches concepts and commands)
  - **[Quick Reference](failed-ocp-install/QUICK-REFERENCE.md)** - Fast commands and decision tree ⚡
  - [Index](failed-ocp-install/INDEX.md) - Navigate by install phase or symptom
  - Links to CSR, control plane kubeconfigs, apiserver cert, bare metal, worker TLS, and related guides

### Control Plane Issues

- **[API Slowness and Web Console Performance](api-slowness-web-console/README.md)** - Comprehensive guide for API slowness and web console performance issues
  - **[Quick Reference](api-slowness-web-console/QUICK-REFERENCE.md)** - Fast diagnostic commands and decision tree for rapid response ⚡
  - [Index](api-slowness-web-console/INDEX.md) - Guide navigation and symptom-based workflows
  - Script: `diagnostic-script.sh` - Automated performance diagnostic tool

- **[API Server Certificate Deadlock](apiserver-cert-deadlock/README.md)** - Resolve bad apiserver cert when the operator cannot apply a new cert
  - **[Quick Reference](apiserver-cert-deadlock/QUICK-REFERENCE.md)** - Triage decision tree, worker-hop access, and remediation commands ⚡
  - [Index](apiserver-cert-deadlock/INDEX.md) - Navigate by symptom, access constraint, or fix step

- **[Control Plane Kubeconfigs](control-plane-kubeconfigs/README.md)** - Complete guide to kubeconfigs on CoreOS control plane nodes
  - [Quick Reference](control-plane-kubeconfigs/QUICK-REFERENCE.md) - Copy-paste commands for monitoring cluster operators
  - [Installation Monitoring](control-plane-kubeconfigs/INSTALL-MONITORING.md) - Monitor installation progress from control plane nodes
  - [Index](control-plane-kubeconfigs/INDEX.md) - Guide navigation and use cases
  - Script: `monitor-cluster.sh` - Automated cluster operator monitoring

- **[kube-controller-manager Crash Loop](kube-controller-manager-crashloop/README.md)** - Comprehensive guide for diagnosing and fixing controller manager crash loops
  - [Quick Reference](kube-controller-manager-crashloop/QUICK-REFERENCE.md) - Fast command reference and decision tree
  - [Operator Errors](kube-controller-manager-crashloop/OPERATOR-ERRORS.md) - Troubleshooting operator-specific issues

- **[OAuth Server healthz Unavailable](oauth-healthz-unavailable/README.md)** - Authentication CO degraded when OAuth route `/healthz` is unreachable
  - **[Quick Reference](oauth-healthz-unavailable/QUICK-REFERENCE.md)** - Emergency checks and route/DNS triage ⚡

- **[Kafka Broker Stuck in Init — kubernetes Service Unreachable](kafka-broker-init-kubernetes-svc/README.md)** - Confluent/Kafka init cannot reach the in-cluster API (`kubernetes` Service); triage ANP priority, DNS/API egress, admission webhook TLS, and OVN `ovnkube-node` restarts

### Bare Metal Provisioning Issues

- **[Bare Metal Stale Node IP Conflict](bare-metal-stale-node-ip-conflict/README.md)** - Retired hardware powered on with same IPs as new control-plane nodes (ARP/MAC flapping, misleading TLS errors)
  - **[Quick Reference](bare-metal-stale-node-ip-conflict/QUICK-REFERENCE.md)** - MAC flapping test and BMC isolation ⚡
  - [Index](bare-metal-stale-node-ip-conflict/INDEX.md) - Navigate by symptom or isolation task

- **[Bare Metal RHCOS Disk Wipe](bare-metal-rhcos-disk-wipe/README.md)** - Wipe ignition, ostree, and etcd from retired bare-metal nodes before reuse
  - **[Quick Reference](bare-metal-rhcos-disk-wipe/QUICK-REFERENCE.md)** - wipefs, BMC live ISO, iDRAC erase ⚡
  - [Index](bare-metal-rhcos-disk-wipe/INDEX.md) - Decommission and disk wipe tasks

- **[Bare Metal Node Inspection Timeout](bare-metal-node-inspection-timeout/README.md)** - Complete guide for nodes stuck in inspecting state
  - **[Force Re-Inspection](bare-metal-node-inspection-timeout/FORCE-REINSPECTION.md)** - Quick commands to force a stuck node to re-inspect ⚡
  - [Quick Reference](bare-metal-node-inspection-timeout/QUICK-REFERENCE.md) - Fast BMC troubleshooting commands

- **[Worker Node TLS Certificate Failure](worker-node-tls-cert-failure/README.md)** - Troubleshoot TLS certificate verification failures when adding workers
  - [Quick Reference](worker-node-tls-cert-failure/QUICK-REFERENCE.md) - Fast diagnostic commands and common fixes
  - [Index](worker-node-tls-cert-failure/INDEX.md) - Guide navigation and quick scenarios
  - Script: `diagnose-tls.sh` - Automated TLS/certificate diagnostic tool

Bare-metal nodes using NVMe-oF block storage: see [NVMe Host NQN Duplicates](nvme-host-nqn-duplicate/README.md) then [NVMe/TCP Storage Network](nvme-tcp-storage-network/README.md) under Storage Issues (prerequisites before CSI install).

### Cluster Lifecycle

- **[Destroy Cluster Without Metadata](destroy-cluster-without-metadata/README.md)** - Manual cleanup when `openshift-install destroy` metadata is lost
  - **[Quick Reference](destroy-cluster-without-metadata/QUICK-REFERENCE.md)** - Platform-specific find/cleanup commands ⚡
  - [Bare Metal Guide](destroy-cluster-without-metadata/BAREMETAL-GUIDE.md) - Metal3/Ironic/BMH cleanup workflow
  - [Index](destroy-cluster-without-metadata/INDEX.md) - Navigate by platform or task
  - Scripts: `find-cluster-*.sh`, `cleanup-baremetal-cluster.sh`

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
  - **[Quick Reference](kubevirt-vm-stuck-provisioning/QUICK-REFERENCE.md)** - 1-minute fix for VM provisioning issues ⚡
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

### Container Images and Registry Issues

- **[Image Registry Auth and Route Exposure](image-registry-auth/README.md)** - `podman login` failures, 401/403, TLS, and exposing the internal registry route

- **[Image Signature Policy Blocking MCP Rollout](image-signature-policy-mcp-deadlock/README.md)** - Fix signature validation errors causing MachineConfigPool deadlock
  - **[Quick Reference](image-signature-policy-mcp-deadlock/QUICK-REFERENCE.md)** - Fast manual fix to break the deadlock ⚡
  - Script: `manual-fix-signature-policy.sh` - Automated policy fix for all nodes
  - YAML: `signature-policy-machineconfig.yaml` - Permanent MachineConfig solution
  - Includes manual step-by-step for understanding the fix

### Storage Issues

- **[NVMe Host NQN Duplicates](nvme-host-nqn-duplicate/README.md)** - Unique per-node host NQN/hostid for NVMe-oF storage on bare-metal OCP (Dell CSM, Portworx/Pure, HPE CSI)
  - **[Quick Reference](nvme-host-nqn-duplicate/QUICK-REFERENCE.md)** - Verify, apply MachineConfig, confirm uniqueness ⚡
  - [Index](nvme-host-nqn-duplicate/INDEX.md) - Navigate by task
  - YAML: [99-worker-nvme-host-identity.yaml](nvme-host-nqn-duplicate/99-worker-nvme-host-identity.yaml) - systemd oneshot fix (not Ignition static file)

- **[NVMe/TCP Storage Network](nvme-tcp-storage-network/README.md)** - Dual-NIC storage fabric on bare-metal OCP: no bond, NMState, native multipath (after NQN fix)
  - **[Quick Reference](nvme-tcp-storage-network/QUICK-REFERENCE.md)** - Topology decision tree and verify commands ⚡
  - [Index](nvme-tcp-storage-network/INDEX.md) - Navigate by task
  - YAML: [example-nncp-storage-interfaces.yaml](nvme-tcp-storage-network/example-nncp-storage-interfaces.yaml) - NNCP skeleton for two storage NICs

- **[Portworx CSI Pod CrashLoopBackOff](portworx-csi-crashloop/README.md)** - Complete guide for troubleshooting px-csi-ext pod crashes
  - **[Quick Start](portworx-csi-crashloop/QUICKSTART.md)** - Fast fixes for common CSI issues ⚡
  - [Quick Reference](portworx-csi-crashloop/QUICK-REFERENCE.md) - Essential command reference and decision tree
  - [Common Errors](portworx-csi-crashloop/COMMON-ERRORS.md) - Error message lookup table with solutions
  - [Investigation Workflow](portworx-csi-crashloop/INVESTIGATION-WORKFLOW.md) - Systematic troubleshooting process
  - [Index](portworx-csi-crashloop/INDEX.md) - Guide navigation by symptom, role, and time available
  - Script: `diagnostic-script.sh` - Automated diagnostic data collection

- **[NFS Portworx Proxy PVC Slow Ready](nfs-portworx-proxy-pvc-slow-ready/README.md)** - PVC or pod takes 20+ minutes to become ready with NFS proxy volumes
  - **[Quick Reference](nfs-portworx-proxy-pvc-slow-ready/QUICK-REFERENCE.md)** - Pinpoint provisioning vs mount delay and run diagnostics ⚡

- **[Prometheus and Alertmanager storage (StorageClass, stuck PVCs)](prometheus-monitoring-storage/README.md)** - Set `storageClassName` via CMO ConfigMaps; separate PVC Pending vs pod Pending; links to Red Hat monitoring stack docs

### Multi-Cluster Management (RHACM)

- **[MultiClusterObservability Webhook Rejection](multiclusterobservability-webhook-rejection/README.md)** - Fix admission webhook rejections when editing/deleting MCO resources
  - **[Quick Reference](multiclusterobservability-webhook-rejection/QUICK-REFERENCE.md)** - Immediate solutions for webhook blocking operations ⚡
  - [Index](multiclusterobservability-webhook-rejection/INDEX.md) - Guide navigation and common scenarios
  - [Example YAML](multiclusterobservability-webhook-rejection/example-mco.yaml) - Properly formatted MCO configurations
  - Script: `diagnose-webhook-issue.sh` - Automated webhook diagnostic tool

## General Troubleshooting Tools

- **[Debug Toolbox Container](debug-toolbox-container/README.md)** - Use ephemeral debug containers with Red Hat UBI for network troubleshooting
  - **[Quick Reference](debug-toolbox-container/QUICK-REFERENCE.md)** - Fast commands for creating toolbox containers and installing diagnostic tools ⚡
  - Privileged mode for MTU testing, packet captures, and advanced diagnostics
  - Install tools on-demand: `mtr`, `tcpdump`, `traceroute`, `nmap`, `bind-utils`
  - Network testing from pod perspective without modifying production containers

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

## Related Resources

- **[Ansible Troubleshooting](../../ansible/troubleshooting/README.md)** - General Ansible issues not specific to OpenShift (e.g., connection variable failures, gather_facts errors)

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
- [x] NVMe-oF bare metal prep - See [NVMe Host NQN Duplicates](nvme-host-nqn-duplicate/README.md), [NVMe/TCP Storage Network](nvme-tcp-storage-network/README.md)
- [ ] Storage/PVC problems (OCS/ODF)
- [x] Image signature policy rejections - See [Image Signature Policy Blocking MCP Rollout](image-signature-policy-mcp-deadlock/README.md)
- [x] Image registry issues (general) - See [Image Registry Auth](image-registry-auth/README.md)
- [x] Authentication failures (OAuth healthz) - See [OAuth Server healthz Unavailable](oauth-healthz-unavailable/README.md)
- [ ] Operator degradation patterns
- [ ] Upgrade stuck/failed scenarios
- [x] Cluster destroy without metadata - See [Destroy Cluster Without Metadata](destroy-cluster-without-metadata/README.md)
- [ ] Bare metal provisioning failures (post-inspection)
- [ ] Certificate rotation issues — partial: [API Server Certificate Deadlock](apiserver-cert-deadlock/README.md)
- [ ] Router/Ingress problems
- [x] KubeVirt VM provisioning issues - See [KubeVirt VM Stuck in Provisioning](kubevirt-vm-stuck-provisioning/README.md)
- [x] Namespace stuck in Terminating state - See [Namespace Stuck in Terminating State](namespace-stuck-terminating/README.md)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

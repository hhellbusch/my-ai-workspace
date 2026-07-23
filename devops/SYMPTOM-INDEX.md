# DevOps Symptom Index

Machine-generated lookup table: symptom string → troubleshooting guide.
Source: `devops/catalog.yaml` (also staged as [catalog.yaml](catalog.yaml) on the site). Regenerate: `python3 scripts/generate-symptom-index.py`.

*Generated 2026-07-15.*

| Symptom / keyword | Guide | Quick ref |
|-------------------|-------|-----------|
| AAP SSH connection timeout | [AAP SSH Connection MTU Issues](ocp/troubleshooting/aap-ssh-mtu-issues/README.md) | [⚡](ocp/troubleshooting/aap-ssh-mtu-issues/QUICK-REFERENCE.md) |
| SSH works from bastion not from AAP | [AAP SSH Connection MTU Issues](ocp/troubleshooting/aap-ssh-mtu-issues/README.md) | [⚡](ocp/troubleshooting/aap-ssh-mtu-issues/QUICK-REFERENCE.md) |
| MTU mismatch SSH | [AAP SSH Connection MTU Issues](ocp/troubleshooting/aap-ssh-mtu-issues/README.md) | [⚡](ocp/troubleshooting/aap-ssh-mtu-issues/QUICK-REFERENCE.md) |
| BMH stuck inspecting | [Bare Metal Node Inspection Timeout](ocp/troubleshooting/bare-metal-node-inspection-timeout/README.md) | [⚡](ocp/troubleshooting/bare-metal-node-inspection-timeout/QUICK-REFERENCE.md) |
| bare metal node inspection timeout | [Bare Metal Node Inspection Timeout](ocp/troubleshooting/bare-metal-node-inspection-timeout/README.md) | [⚡](ocp/troubleshooting/bare-metal-node-inspection-timeout/QUICK-REFERENCE.md) |
| ironic inspection failed | [Bare Metal Node Inspection Timeout](ocp/troubleshooting/bare-metal-node-inspection-timeout/README.md) | [⚡](ocp/troubleshooting/bare-metal-node-inspection-timeout/QUICK-REFERENCE.md) |
| reuse bare metal node | [Bare Metal RHCOS Disk Wipe](ocp/troubleshooting/bare-metal-rhcos-disk-wipe/README.md) | [⚡](ocp/troubleshooting/bare-metal-rhcos-disk-wipe/QUICK-REFERENCE.md) |
| wipe ignition ostree etcd | [Bare Metal RHCOS Disk Wipe](ocp/troubleshooting/bare-metal-rhcos-disk-wipe/README.md) | [⚡](ocp/troubleshooting/bare-metal-rhcos-disk-wipe/QUICK-REFERENCE.md) |
| decommission RHCOS disk | [Bare Metal RHCOS Disk Wipe](ocp/troubleshooting/bare-metal-rhcos-disk-wipe/README.md) | [⚡](ocp/troubleshooting/bare-metal-rhcos-disk-wipe/QUICK-REFERENCE.md) |
| MAC flapping | [Bare Metal Stale Node IP Conflict](ocp/troubleshooting/bare-metal-stale-node-ip-conflict/README.md) | [⚡](ocp/troubleshooting/bare-metal-stale-node-ip-conflict/QUICK-REFERENCE.md) |
| retired node same IP as new control plane | [Bare Metal Stale Node IP Conflict](ocp/troubleshooting/bare-metal-stale-node-ip-conflict/README.md) | [⚡](ocp/troubleshooting/bare-metal-stale-node-ip-conflict/QUICK-REFERENCE.md) |
| misleading TLS errors bare metal | [Bare Metal Stale Node IP Conflict](ocp/troubleshooting/bare-metal-stale-node-ip-conflict/README.md) | [⚡](ocp/troubleshooting/bare-metal-stale-node-ip-conflict/QUICK-REFERENCE.md) |
| TLS certificate verification failed adding worker | [Worker Node TLS Certificate Failure](ocp/troubleshooting/worker-node-tls-cert-failure/README.md) | [⚡](ocp/troubleshooting/worker-node-tls-cert-failure/QUICK-REFERENCE.md) |
| x509 certificate signed by unknown authority worker | [Worker Node TLS Certificate Failure](ocp/troubleshooting/worker-node-tls-cert-failure/README.md) | [⚡](ocp/troubleshooting/worker-node-tls-cert-failure/QUICK-REFERENCE.md) |
| pending certificate signing request | [CSR Management](ocp/troubleshooting/csr-management/README.md) | [⚡](ocp/troubleshooting/csr-management/QUICK-REFERENCE.md) |
| CSR not approved | [CSR Management](ocp/troubleshooting/csr-management/README.md) | [⚡](ocp/troubleshooting/csr-management/QUICK-REFERENCE.md) |
| nodes not ready pending CSR | [CSR Management](ocp/troubleshooting/csr-management/README.md) | [⚡](ocp/troubleshooting/csr-management/QUICK-REFERENCE.md) |
| apiserver certificate expired | [API Server Certificate Deadlock](ocp/troubleshooting/apiserver-cert-deadlock/README.md) | [⚡](ocp/troubleshooting/apiserver-cert-deadlock/QUICK-REFERENCE.md) |
| kube-apiserver operator cannot apply cert | [API Server Certificate Deadlock](ocp/troubleshooting/apiserver-cert-deadlock/README.md) | [⚡](ocp/troubleshooting/apiserver-cert-deadlock/QUICK-REFERENCE.md) |
| x509 certificate has expired | [API Server Certificate Deadlock](ocp/troubleshooting/apiserver-cert-deadlock/README.md) | [⚡](ocp/troubleshooting/apiserver-cert-deadlock/QUICK-REFERENCE.md) |
| oc commands slow | [API Slowness and Web Console Performance](ocp/troubleshooting/api-slowness-web-console/README.md) | [⚡](ocp/troubleshooting/api-slowness-web-console/QUICK-REFERENCE.md) |
| web console slow | [API Slowness and Web Console Performance](ocp/troubleshooting/api-slowness-web-console/README.md) | [⚡](ocp/troubleshooting/api-slowness-web-console/QUICK-REFERENCE.md) |
| API timeout | [API Slowness and Web Console Performance](ocp/troubleshooting/api-slowness-web-console/README.md) | [⚡](ocp/troubleshooting/api-slowness-web-console/QUICK-REFERENCE.md) |
| etcd latency | [API Slowness and Web Console Performance](ocp/troubleshooting/api-slowness-web-console/README.md) | [⚡](ocp/troubleshooting/api-slowness-web-console/QUICK-REFERENCE.md) |
| monitor cluster operators from control plane node | [Control Plane Kubeconfigs](ocp/troubleshooting/control-plane-kubeconfigs/README.md) | [⚡](ocp/troubleshooting/control-plane-kubeconfigs/QUICK-REFERENCE.md) |
| kubeconfig on CoreOS master | [Control Plane Kubeconfigs](ocp/troubleshooting/control-plane-kubeconfigs/README.md) | [⚡](ocp/troubleshooting/control-plane-kubeconfigs/QUICK-REFERENCE.md) |
| installation monitoring from master | [Control Plane Kubeconfigs](ocp/troubleshooting/control-plane-kubeconfigs/README.md) | [⚡](ocp/troubleshooting/control-plane-kubeconfigs/QUICK-REFERENCE.md) |
| OAuthServerRouteEndpointAccessibleControllerAvailable | [OAuth Server healthz Unavailable](ocp/troubleshooting/oauth-healthz-unavailable/README.md) | [⚡](ocp/troubleshooting/oauth-healthz-unavailable/QUICK-REFERENCE.md) |
| authentication cluster operator degraded | [OAuth Server healthz Unavailable](ocp/troubleshooting/oauth-healthz-unavailable/README.md) | [⚡](ocp/troubleshooting/oauth-healthz-unavailable/QUICK-REFERENCE.md) |
| oauth-openshift.apps healthz connection refused | [OAuth Server healthz Unavailable](ocp/troubleshooting/oauth-healthz-unavailable/README.md) | [⚡](ocp/troubleshooting/oauth-healthz-unavailable/QUICK-REFERENCE.md) |
| oc login fails | [OAuth Server healthz Unavailable](ocp/troubleshooting/oauth-healthz-unavailable/README.md) | [⚡](ocp/troubleshooting/oauth-healthz-unavailable/QUICK-REFERENCE.md) |
| kube-controller-manager CrashLoopBackOff | [kube-controller-manager Crash Loop](ocp/troubleshooting/kube-controller-manager-crashloop/README.md) | [⚡](ocp/troubleshooting/kube-controller-manager-crashloop/QUICK-REFERENCE.md) |
| controller manager pod restarting | [kube-controller-manager Crash Loop](ocp/troubleshooting/kube-controller-manager-crashloop/README.md) | [⚡](ocp/troubleshooting/kube-controller-manager-crashloop/QUICK-REFERENCE.md) |
| openshift install did not complete | [Failed OCP Install](ocp/troubleshooting/failed-ocp-install/README.md) | [⚡](ocp/troubleshooting/failed-ocp-install/QUICK-REFERENCE.md) |
| bootstrap complete but cluster operators not available | [Failed OCP Install](ocp/troubleshooting/failed-ocp-install/README.md) | [⚡](ocp/troubleshooting/failed-ocp-install/QUICK-REFERENCE.md) |
| installation stuck | [Failed OCP Install](ocp/troubleshooting/failed-ocp-install/README.md) | [⚡](ocp/troubleshooting/failed-ocp-install/QUICK-REFERENCE.md) |
| namespace stuck terminating | [Namespace Stuck in Terminating](ocp/troubleshooting/namespace-stuck-terminating/README.md) | [⚡](ocp/troubleshooting/namespace-stuck-terminating/QUICK-REFERENCE.md) |
| namespace finalizer blocking delete | [Namespace Stuck in Terminating](ocp/troubleshooting/namespace-stuck-terminating/README.md) | [⚡](ocp/troubleshooting/namespace-stuck-terminating/QUICK-REFERENCE.md) |
| openshift-install destroy metadata missing | [Destroy Cluster Without Metadata](ocp/troubleshooting/destroy-cluster-without-metadata/README.md) | [⚡](ocp/troubleshooting/destroy-cluster-without-metadata/QUICK-REFERENCE.md) |
| lost metadata.json | [Destroy Cluster Without Metadata](ocp/troubleshooting/destroy-cluster-without-metadata/README.md) | [⚡](ocp/troubleshooting/destroy-cluster-without-metadata/QUICK-REFERENCE.md) |
| manual cluster cleanup | [Destroy Cluster Without Metadata](ocp/troubleshooting/destroy-cluster-without-metadata/README.md) | [⚡](ocp/troubleshooting/destroy-cluster-without-metadata/QUICK-REFERENCE.md) |
| CoreOS no network | [CoreOS Networking Issues](ocp/troubleshooting/coreos-networking-issues/README.md) | [⚡](ocp/troubleshooting/coreos-networking-issues/QUICK-REFERENCE.md) |
| nmstate degraded | [CoreOS Networking Issues](ocp/troubleshooting/coreos-networking-issues/README.md) | [⚡](ocp/troubleshooting/coreos-networking-issues/QUICK-REFERENCE.md) |
| node network not configured | [CoreOS Networking Issues](ocp/troubleshooting/coreos-networking-issues/README.md) | [⚡](ocp/troubleshooting/coreos-networking-issues/QUICK-REFERENCE.md) |
| podman login registry 403 | [Image Registry Auth and Route Exposure](ocp/troubleshooting/image-registry-auth/README.md) | — |
| image registry 401 unauthorized | [Image Registry Auth and Route Exposure](ocp/troubleshooting/image-registry-auth/README.md) | — |
| expose internal image registry route | [Image Registry Auth and Route Exposure](ocp/troubleshooting/image-registry-auth/README.md) | — |
| SignatureValidationFailed | [Image Signature Policy MCP Deadlock](ocp/troubleshooting/image-signature-policy-mcp-deadlock/README.md) | [⚡](ocp/troubleshooting/image-signature-policy-mcp-deadlock/QUICK-REFERENCE.md) |
| MachineConfigPool blocked signature policy | [Image Signature Policy MCP Deadlock](ocp/troubleshooting/image-signature-policy-mcp-deadlock/README.md) | [⚡](ocp/troubleshooting/image-signature-policy-mcp-deadlock/QUICK-REFERENCE.md) |
| policy.json rejecting registry.redhat.io | [Image Signature Policy MCP Deadlock](ocp/troubleshooting/image-signature-policy-mcp-deadlock/README.md) | [⚡](ocp/troubleshooting/image-signature-policy-mcp-deadlock/QUICK-REFERENCE.md) |
| admission webhook denied multiclusterobservability | [MultiClusterObservability Webhook Rejection](ocp/troubleshooting/multiclusterobservability-webhook-rejection/README.md) | [⚡](ocp/troubleshooting/multiclusterobservability-webhook-rejection/QUICK-REFERENCE.md) |
| metadata.name is required MCO | [MultiClusterObservability Webhook Rejection](ocp/troubleshooting/multiclusterobservability-webhook-rejection/README.md) | [⚡](ocp/troubleshooting/multiclusterobservability-webhook-rejection/QUICK-REFERENCE.md) |
| cannot delete multiclusterobservability | [MultiClusterObservability Webhook Rejection](ocp/troubleshooting/multiclusterobservability-webhook-rejection/README.md) | [⚡](ocp/troubleshooting/multiclusterobservability-webhook-rejection/QUICK-REFERENCE.md) |
| PVC slow to bind NFS proxy | [NFS Portworx Proxy PVC Slow Ready](ocp/troubleshooting/nfs-portworx-proxy-pvc-slow-ready/README.md) | [⚡](ocp/troubleshooting/nfs-portworx-proxy-pvc-slow-ready/QUICK-REFERENCE.md) |
| pod 20 minutes to ready portworx nfs | [NFS Portworx Proxy PVC Slow Ready](ocp/troubleshooting/nfs-portworx-proxy-pvc-slow-ready/README.md) | [⚡](ocp/troubleshooting/nfs-portworx-proxy-pvc-slow-ready/QUICK-REFERENCE.md) |
| duplicate NVMe host NQN | [NVMe Host NQN Duplicates](ocp/troubleshooting/nvme-host-nqn-duplicate/README.md) | [⚡](ocp/troubleshooting/nvme-host-nqn-duplicate/QUICK-REFERENCE.md) |
| nvme hostid not unique | [NVMe Host NQN Duplicates](ocp/troubleshooting/nvme-host-nqn-duplicate/README.md) | [⚡](ocp/troubleshooting/nvme-host-nqn-duplicate/QUICK-REFERENCE.md) |
| NVMe-oF bare metal | [NVMe Host NQN Duplicates](ocp/troubleshooting/nvme-host-nqn-duplicate/README.md) | [⚡](ocp/troubleshooting/nvme-host-nqn-duplicate/QUICK-REFERENCE.md) |
| NVMe TCP storage network | [NVMe/TCP Storage Network](ocp/troubleshooting/nvme-tcp-storage-network/README.md) | [⚡](ocp/troubleshooting/nvme-tcp-storage-network/QUICK-REFERENCE.md) |
| dual NIC storage fabric | [NVMe/TCP Storage Network](ocp/troubleshooting/nvme-tcp-storage-network/README.md) | [⚡](ocp/troubleshooting/nvme-tcp-storage-network/QUICK-REFERENCE.md) |
| NNCP storage interfaces | [NVMe/TCP Storage Network](ocp/troubleshooting/nvme-tcp-storage-network/README.md) | [⚡](ocp/troubleshooting/nvme-tcp-storage-network/QUICK-REFERENCE.md) |
| px-csi-ext CrashLoopBackOff | [Portworx CSI Pod CrashLoopBackOff](ocp/troubleshooting/portworx-csi-crashloop/README.md) | [⚡](ocp/troubleshooting/portworx-csi-crashloop/QUICK-REFERENCE.md) |
| Portworx CSI driver not found | [Portworx CSI Pod CrashLoopBackOff](ocp/troubleshooting/portworx-csi-crashloop/README.md) | [⚡](ocp/troubleshooting/portworx-csi-crashloop/QUICK-REFERENCE.md) |
| CSI socket connection refused | [Portworx CSI Pod CrashLoopBackOff](ocp/troubleshooting/portworx-csi-crashloop/README.md) | [⚡](ocp/troubleshooting/portworx-csi-crashloop/QUICK-REFERENCE.md) |
| prometheus PVC pending | [Prometheus and Alertmanager Storage](ocp/troubleshooting/prometheus-monitoring-storage/README.md) | — |
| alertmanager storage class | [Prometheus and Alertmanager Storage](ocp/troubleshooting/prometheus-monitoring-storage/README.md) | — |
| cluster monitoring PVC stuck | [Prometheus and Alertmanager Storage](ocp/troubleshooting/prometheus-monitoring-storage/README.md) | — |
| ephemeral debug container OpenShift | [Debug Toolbox Container](ocp/troubleshooting/debug-toolbox-container/README.md) | [⚡](ocp/troubleshooting/debug-toolbox-container/QUICK-REFERENCE.md) |
| network troubleshoot from pod | [Debug Toolbox Container](ocp/troubleshooting/debug-toolbox-container/README.md) | [⚡](ocp/troubleshooting/debug-toolbox-container/QUICK-REFERENCE.md) |
| privileged toolbox UBI | [Debug Toolbox Container](ocp/troubleshooting/debug-toolbox-container/README.md) | [⚡](ocp/troubleshooting/debug-toolbox-container/QUICK-REFERENCE.md) |
| VM stuck provisioning | [KubeVirt VM Stuck in Provisioning](ocp/troubleshooting/kubevirt-vm-stuck-provisioning/README.md) | [⚡](ocp/troubleshooting/kubevirt-vm-stuck-provisioning/QUICK-REFERENCE.md) |
| kubevirt-velero-annotations-remover webhook not found | [KubeVirt VM Stuck in Provisioning](ocp/troubleshooting/kubevirt-vm-stuck-provisioning/README.md) | [⚡](ocp/troubleshooting/kubevirt-vm-stuck-provisioning/QUICK-REFERENCE.md) |
| virt-launcher pod not created | [KubeVirt VM Stuck in Provisioning](ocp/troubleshooting/kubevirt-vm-stuck-provisioning/README.md) | [⚡](ocp/troubleshooting/kubevirt-vm-stuck-provisioning/QUICK-REFERENCE.md) |

## By category

### Automation

- [AAP SSH Connection MTU Issues](ocp/troubleshooting/aap-ssh-mtu-issues/README.md) — `aap`, `ansible`, `mtu`, `ssh`

### Bare Metal

- [Bare Metal Node Inspection Timeout](ocp/troubleshooting/bare-metal-node-inspection-timeout/README.md) — `bare-metal`, `ironic`, `inspection`
- [Bare Metal RHCOS Disk Wipe](ocp/troubleshooting/bare-metal-rhcos-disk-wipe/README.md) — `bare-metal`, `disk-wipe`, `decommission`
- [Bare Metal Stale Node IP Conflict](ocp/troubleshooting/bare-metal-stale-node-ip-conflict/README.md) — `bare-metal`, `networking`, `ip-conflict`
- [Worker Node TLS Certificate Failure](ocp/troubleshooting/worker-node-tls-cert-failure/README.md) — `bare-metal`, `tls`, `certificates`, `workers`

### Certificates

- [CSR Management](ocp/troubleshooting/csr-management/README.md) — `certificates`, `csr`, `nodes`

### Control Plane

- [API Server Certificate Deadlock](ocp/troubleshooting/apiserver-cert-deadlock/README.md) — `certificates`, `control-plane`, `emergency`
- [API Slowness and Web Console Performance](ocp/troubleshooting/api-slowness-web-console/README.md) — `performance`, `control-plane`, `emergency`
- [Control Plane Kubeconfigs](ocp/troubleshooting/control-plane-kubeconfigs/README.md) — `kubeconfig`, `control-plane`, `installation`
- [OAuth Server healthz Unavailable](ocp/troubleshooting/oauth-healthz-unavailable/README.md) — `authentication`, `oauth`, `control-plane`
- [kube-controller-manager Crash Loop](ocp/troubleshooting/kube-controller-manager-crashloop/README.md) — `control-plane`, `crashloop`

### Installation

- [Failed OCP Install](ocp/troubleshooting/failed-ocp-install/README.md) — `installation`, `bootstrap`, `beginners`

### Kubernetes

- [Namespace Stuck in Terminating](ocp/troubleshooting/namespace-stuck-terminating/README.md) — `namespace`, `finalizers`

### Lifecycle

- [Destroy Cluster Without Metadata](ocp/troubleshooting/destroy-cluster-without-metadata/README.md) — `destroy`, `lifecycle`, `bare-metal`, `cloud`

### Networking

- [CoreOS Networking Issues](ocp/troubleshooting/coreos-networking-issues/README.md) — `coreos`, `networking`, `nmstate`

### Registry

- [Image Registry Auth and Route Exposure](ocp/troubleshooting/image-registry-auth/README.md) — `registry`, `authentication`, `disconnected`
- [Image Signature Policy MCP Deadlock](ocp/troubleshooting/image-signature-policy-mcp-deadlock/README.md) — `registry`, `machineconfig`, `signatures`, `emergency`

### Rhacm

- [MultiClusterObservability Webhook Rejection](ocp/troubleshooting/multiclusterobservability-webhook-rejection/README.md) — `rhacm`, `webhook`, `observability`

### Storage

- [NFS Portworx Proxy PVC Slow Ready](ocp/troubleshooting/nfs-portworx-proxy-pvc-slow-ready/README.md) — `storage`, `portworx`, `nfs`, `pvc`
- [NVMe Host NQN Duplicates](ocp/troubleshooting/nvme-host-nqn-duplicate/README.md) — `storage`, `nvme`, `bare-metal`
- [NVMe/TCP Storage Network](ocp/troubleshooting/nvme-tcp-storage-network/README.md) — `storage`, `nvme`, `networking`
- [Portworx CSI Pod CrashLoopBackOff](ocp/troubleshooting/portworx-csi-crashloop/README.md) — `storage`, `portworx`, `csi`
- [Prometheus and Alertmanager Storage](ocp/troubleshooting/prometheus-monitoring-storage/README.md) — `monitoring`, `prometheus`, `storage`

### Tools

- [Debug Toolbox Container](ocp/troubleshooting/debug-toolbox-container/README.md) — `debug`, `networking`, `toolbox`

### Virtualization

- [KubeVirt VM Stuck in Provisioning](ocp/troubleshooting/kubevirt-vm-stuck-provisioning/README.md) — `kubevirt`, `velero`, `oadp`, `virtualization`


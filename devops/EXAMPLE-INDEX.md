# DevOps Example Index

Machine-generated lookup table: intent / keyword → runnable OCP example.
Source: `devops/catalog.yaml` (`examples:`). Regenerate: `python3 scripts/generate-example-index.py`.

*Generated 2026-07-23.*

| Intent / keyword | Example | Topic | Operators |
|------------------|---------|-------|-----------|
| secondary disk openshift bare metal | [Bare Metal Secondary Disk Offload](ocp/examples/bare-metal/secondary-disk/README.md) | `bare-metal` | — |
| by-path nvme worker disk layout | [Bare Metal Secondary Disk Offload](ocp/examples/bare-metal/secondary-disk/README.md) | `bare-metal` | — |
| offload var log etcd data disk | [Bare Metal Secondary Disk Offload](ocp/examples/bare-metal/secondary-disk/README.md) | `bare-metal` | — |
| rack-aware kafka on openshift bare metal | [Kafka on Bare Metal with Portworx](ocp/examples/messaging/kafka/bare-metal-portworx/README.md) | `messaging/kafka` | cfk, strimzi, amq-streams |
| portworx storage class for kafka | [Kafka on Bare Metal with Portworx](ocp/examples/messaging/kafka/bare-metal-portworx/README.md) | `messaging/kafka` | cfk, strimzi, amq-streams |
| confluent vs strimzi comparison | [Kafka on Bare Metal with Portworx](ocp/examples/messaging/kafka/bare-metal-portworx/README.md) | `messaging/kafka` | cfk, strimzi, amq-streams |
| acm inventory rack labels | [Kafka on Bare Metal with Portworx](ocp/examples/messaging/kafka/bare-metal-portworx/README.md) | `messaging/kafka` | cfk, strimzi, amq-streams |
| network attachment definition multus | [NetworkAttachmentDefinition Examples](ocp/examples/networking/network-attachment-definitions/README.md) | `networking` | — |
| nad vlan sriov openshift | [NetworkAttachmentDefinition Examples](ocp/examples/networking/network-attachment-definitions/README.md) | `networking` | — |
| ovn kubernetes install-config networking | [OVN-Kubernetes Install Config](ocp/examples/networking/ovn-kubernetes-install-config/README.md) | `networking` | — |
| policy audit config network CR | [OVN-Kubernetes Install Config](ocp/examples/networking/ovn-kubernetes-install-config/README.md) | `networking` | — |
| single node openshift kvm lab | [SNO on KVM Lab](ocp/examples/labs/sno-kvm-lab/README.md) | `labs` | — |
| agent install home lab sno | [SNO on KVM Lab](ocp/examples/labs/sno-kvm-lab/README.md) | `labs` | — |
| argocd bootstrap sno lab | [SNO on KVM Lab](ocp/examples/labs/sno-kvm-lab/README.md) | `labs` | — |
| vlan install-config openshift | [VLAN Network Segmentation](ocp/examples/networking/vlan-segmentation.md) | `networking` | — |
| multus vlan day-2 segmentation | [VLAN Network Segmentation](ocp/examples/networking/vlan-segmentation.md) | `networking` | — |
| var log secondary disk openshift | [Var Log on Secondary Disk](ocp/examples/bare-metal/var-log-disk/README.md) | `bare-metal` | — |
| machineconfig var log offload | [Var Log on Secondary Disk](ocp/examples/bare-metal/var-log-disk/README.md) | `bare-metal` | — |

## By topic

### bare-metal

- [Bare Metal Secondary Disk Offload](ocp/examples/bare-metal/secondary-disk/README.md) — `bare-metal`, `storage`, `ignition`, `machineconfig`
  - Companion: [Machine Config Pools](ocp/notes/machine-config-pools.md)
- [Var Log on Secondary Disk](ocp/examples/bare-metal/var-log-disk/README.md) — `bare-metal`, `storage`, `var-log`

### labs

- [SNO on KVM Lab](ocp/examples/labs/sno-kvm-lab/README.md) — `labs`, `sno`, `kvm`, `agent-install`
  - Companion: [Windows Vm On Fedora](kvm/windows-vm-on-fedora.md)

### messaging/kafka

- [Kafka on Bare Metal with Portworx](ocp/examples/messaging/kafka/bare-metal-portworx/README.md) — `kafka`, `portworx`, `bare-metal`, `cfk`, `strimzi`, `kraft`
  - Companion: [Network Policy Observability](ocp/notes/network-policy-observability.md)
  - Companion: [Kafka On Openshift Tenancy](ocp/notes/kafka-on-openshift-tenancy.md)

### networking

- [NetworkAttachmentDefinition Examples](ocp/examples/networking/network-attachment-definitions/README.md) — `networking`, `multus`, `nad`, `sriov`
- [OVN-Kubernetes Install Config](ocp/examples/networking/ovn-kubernetes-install-config/README.md) — `networking`, `ovn`, `install-config`
  - Companion: [Network Policy Observability](ocp/notes/network-policy-observability.md)
- [VLAN Network Segmentation](ocp/examples/networking/vlan-segmentation.md) — `networking`, `vlan`, `multus`, `install-config`


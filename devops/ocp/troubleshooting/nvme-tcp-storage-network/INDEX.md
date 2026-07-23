# NVMe/TCP Storage Network — Index

## Start Here

| I need to… | Go to |
|------------|-------|
| Bond or separate storage NICs? | [README — Bond or not?](README.md#bond-or-not) |
| Quick topology / verify commands | [QUICK-REFERENCE](QUICK-REFERENCE.md) |
| Host NQN first (prerequisite) | [NVMe Host NQN Duplicates](../nvme-host-nqn-duplicate/README.md) |

## By Task

| Task | Section |
|------|---------|
| Target topology diagram | [README — Target topology](README.md#target-topology) |
| Two subnets vs same subnet | [README — L3 layout](README.md#l3-layout-options) |
| Native multipath vs dm-multipath | [README — Native NVMe multipath](README.md#native-nvme-multipath-not-dm-multipath) |
| NMState NNCP on OCP | [README — OpenShift NMState](README.md#openshift-nmstate-for-storage-interfaces) |
| Example NNCP skeleton | [example-nncp-storage-interfaces.yaml](example-nncp-storage-interfaces.yaml) |
| Full prep order (NQN → network → CSI) | [README — Prep checklist](README.md#prep-checklist-order-matters) |

## Related Guides

- [NVMe Host NQN Duplicates](../nvme-host-nqn-duplicate/README.md) — step 1
- [Portworx CSI CrashLoop](../portworx-csi-crashloop/README.md) — step 6
- [Kafka + Portworx bare metal](../../examples/messaging/kafka/bare-metal-portworx/README.md)

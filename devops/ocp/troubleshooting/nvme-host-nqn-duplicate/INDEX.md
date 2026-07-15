# NVMe Host NQN Duplicates — Index

## Start Here

| I need to… | Go to |
|------------|-------|
| Check if nodes have duplicate NQNs | [QUICK-REFERENCE § Verify](QUICK-REFERENCE.md#1-verify-per-node) |
| Validate effective / connected NQN (host → array) | [QUICK-REFERENCE § 1b](QUICK-REFERENCE.md#1b-validate-effective-and-connected-nqn) |
| Apply the MachineConfig fix | [QUICK-REFERENCE § Apply](QUICK-REFERENCE.md#2-apply-fix) |
| Understand why Ignition `data:,$(cat...)` fails | [README — Anti-pattern](README.md#anti-pattern-ignition-static-file-with-shell) |
| Red Hat KBA diagnostic | [README — KBA diagnostic](README.md#red-hat-kba-diagnostic-kcs-7073579) |
| What the array sees (Discover/Connect) | [README — Effective and connected NQN](README.md#effective-and-connected-nqn-what-the-array-sees) |
| Compare Dell / HPE / Pure fixes to ours | [README — Provider fixes compared](README.md#provider-fixes-compared) |
| Next: storage network (dual NIC) | [NVMe/TCP Storage Network](../nvme-tcp-storage-network/README.md) |
| Full context and array registration | [README](README.md) |

## By Task

| Task | Section |
|------|---------|
| What is host NQN / when it matters | [README — Overview](README.md#overview) |
| Symptom → duplicate NQN CSI error | [README — Symptoms](README.md#symptoms) |
| Why RHCOS duplicates these files | [README — Root Cause](README.md#root-cause) |
| MachineConfig manifest | [99-worker-nvme-host-identity.yaml](99-worker-nvme-host-identity.yaml) |
| Dell / HPE / Pure vs this repo | [README — Provider fixes compared](README.md#provider-fixes-compared) |
| Dell CSM / Portworx registration | [README — Step 3](README.md#step-3-register-hosts-on-the-storage-array) |
| Pre-install vs post-install timing | [README — Timing](README.md#timing-pre-install-vs-post-install) |
| iSCSI initiator same bug class | [README — iSCSI](README.md#iscsi-initiator-same-class-of-bug) |

## Related Guides

- [Portworx CSI CrashLoop](../portworx-csi-crashloop/README.md) — CSI failures after storage prep
- [Kafka + Portworx bare metal](../../examples/kafka-bare-metal-portworx/README.md) — rack-aware Portworx example
- [Bare Metal Node Inspection Timeout](../bare-metal-node-inspection-timeout/README.md) — pre-storage provisioning issues

# Bare Metal RHCOS Disk Wipe — Index

## Start Here

| I need to… | Go to |
|------------|-------|
| Wipe commands now | [QUICK-REFERENCE.md](QUICK-REFERENCE.md) |
| Full procedure | [README.md](README.md) |
| Retired host fighting for same IP | [Stale Node IP Conflict](../bare-metal-stale-node-ip-conflict/README.md) first |

## By Task

| Task | Section |
|------|---------|
| Confirm serial before wipe | [Step 1](README.md#step-1-confirm-the-target-host) |
| Delete Node / BareMetalHost | [Step 3](README.md#step-3-remove-cluster-objects) |
| Wipe via SSH | [Step 4 Option A](README.md#option-a-ssh-to-the-retired-host) |
| Wipe via BMC live ISO | [Step 4 Option B](README.md#option-b-bmc-virtual-media--live-iso) |
| iDRAC / PERC erase | [Step 4 Option C](README.md#option-c-raid-controller--idrac-storage-erase-dell-and-similar) |
| BMC Stay Off / boot policy | [Step 5](README.md#step-5-prevent-return-on-power-on) |

## Related Guides

- [Bare Metal Stale Node IP Conflict](../bare-metal-stale-node-ip-conflict/README.md) — MAC flapping when old and new hardware share IPs
- [Destroy Cluster Without Metadata — Bare Metal](../destroy-cluster-without-metadata/BAREMETAL-GUIDE.md) — Full cluster teardown
- [Bare Metal Node Inspection Timeout](../bare-metal-node-inspection-timeout/README.md) — Provisioning active hosts

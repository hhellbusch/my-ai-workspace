# Ansible: NVMe discover via `oc debug`

> **Audience:** Platform engineers verifying NVMe/TCP fabric reachability on bare-metal OpenShift workers.
> **Purpose:** Run `nvme discover` on a node list through the API (`oc debug` + `chroot /host`) — no SSH — to catch cabling / L3 path problems before CSI.

## Why `oc debug`

Debug pods for nodes share the **host network namespace** and mount the host root.
`chroot /host nvme discover ...` therefore exercises the same storage NICs and routes the CSI stack will use.

Always `chroot /host` — same pitfall as the [host NQN guide](../nvme-host-nqn-duplicate/README.md).

## Prerequisites

- `oc` logged into the target cluster (`KUBECONFIG` or current context)
- Permission to create debug pods (`oc auth can-i create pods`)
- `nvme-cli` on the node (RHCOS typically has `/usr/sbin/nvme`)
- Discovery controller IPs reachable on the **storage** network (not the OVN primary only)
- Unique host NQN per node — [nvme-host-nqn-duplicate](../nvme-host-nqn-duplicate/README.md)

## Quick start

```bash
cd devops/ocp/troubleshooting/nvme-tcp-storage-network/ansible
cp vars.example.yml vars.yml
# edit ocp_nodes + nvme_discovery_targets (set host_iface for dual fabric)

ansible-playbook nvme-discover.yml -e @vars.yml
# optional parallelism (each fork = concurrent oc debug pods)
ansible-playbook nvme-discover.yml -e @vars.yml --forks 8
```

`vars.yml` is gitignored — keep site IPs out of the repo.

## What “good” looks like

For each node × target:

- `rc == 0`
- stdout contains a discovery log page / subsystem NQN listing from the array

**Fail** usually means: wrong cable/switch, storage NIC down or wrong IP, MTU mismatch, ACL/zoning, or discovery listener not up on that controller IP.

Binding `-w <host_iface>` (set `host_iface` in vars) is the stronger cabling check — unbound discover can succeed via the “wrong” NIC if L3 still routes.

## Manual one-liner (same semantics)

```bash
oc debug node/worker-0 --quiet -- chroot /host \
  nvme discover -t tcp -a 10.100.1.10 -s 4420 -w ens1f0
```

## Related

- [QUICK-REFERENCE](../QUICK-REFERENCE.md) — topology and host-side checks
- [README](../README.md) — dual-NIC / no-bond design
- [vars.example.yml](vars.example.yml)

# Quick Reference: NVMe Host NQN Duplicates

Unique host NQN per node for NVMe-oF storage on OpenShift (Dell CSM, Portworx/Pure, HPE CSI, etc.).

## Decision Tree

```
Deploying NVMe-oF storage (CSI) on bare-metal OCP?
│
├─ Check NQNs on every storage node
│  ssh core@<node> 'cat /etc/nvme/hostnqn'
│
├─ All unique and match dmidecode system-uuid?
│  ├─ yes → proceed with CSI / array registration
│  └─ no → apply MachineConfig fix (below), wait for MCO reboot
│
├─ File contains literal "$(cat ...)"?
│  └─ yes → Ignition anti-pattern active; replace with systemd fix
│
└─ After fix → re-verify → install/restart CSI → register on array if manual
```

---

## 1. Verify (per node)

```bash
cat /etc/nvme/hostnqn
cat /etc/nvme/hostid
dmidecode -s system-uuid
```

Across all workers:

```bash
for h in worker-0 worker-1 worker-2; do
  echo -n "$h: "
  ssh core@"$h" 'cat /etc/nvme/hostnqn'
done
```

| Result | Action |
|--------|--------|
| Same NQN on 2+ nodes | Apply fix below |
| NQN contains `$(cat` | Anti-pattern MC — replace with systemd fix |
| Each NQN unique, UUID matches DMI | OK — proceed to storage install |

---

## 2. Apply fix

```bash
# Match ignition.version to your cluster (4.20+ often 3.5.0)
oc get mc 00-worker -o jsonpath='{.spec.config.ignition.version}{"\n"}'

oc apply -f 99-worker-nvme-host-identity.yaml
oc get mcp worker -w   # wait for UPDATED=True, UPDATING=False
```

Repeat for `master` pool if masters use NVMe-oF (change role label and MCP name). See [MachineConfig pools](../../notes/machine-config-pools.md#same-config-on-master-and-worker).

---

## 3. Confirm after MCO rollout

```bash
for h in worker-0 worker-1 worker-2; do
  echo "=== $h ==="
  ssh core@"$h" 'cat /etc/nvme/hostnqn; cat /etc/nvme/hostid; dmidecode -s system-uuid'
done
```

Expected: unique `hostnqn` per node; UUID in NQN matches `dmidecode` on that node.

---

## 4. Collect NQNs for array registration (manual backends)

```bash
for h in worker-0 worker-1 worker-2; do
  printf "%-12s %s\n" "$h" "$(ssh core@$h cat /etc/nvme/hostnqn)"
done
```

---

## Do / Don't

| Do | Don't |
|----|-------|
| systemd oneshot via MachineConfig | Ignition `data:,...$(cat ...)` — shell never runs |
| Set both `hostnqn` and `hostid` | Set only `hostnqn` |
| Verify before CSI install | Assume RHCOS auto-unique per node |
| Use `nvme gen-hostnqn` | Hardcode one NQN in a shared MC file |

---

## Related

- [Full guide](README.md)
- [MachineConfig example](99-worker-nvme-host-identity.yaml)
- [Portworx CSI CrashLoop](../portworx-csi-crashloop/README.md)

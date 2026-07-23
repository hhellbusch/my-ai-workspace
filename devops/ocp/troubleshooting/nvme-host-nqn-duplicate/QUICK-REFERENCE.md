# Quick Reference: NVMe Host NQN Duplicates

Unique host NQN per node for NVMe-oF storage on OpenShift (Dell CSM, Portworx/Pure, HPE CSI, etc.).

## Decision Tree

```
Deploying NVMe-oF storage (CSI) on bare-metal OCP?
│
├─ Using oc debug? → chroot /host first (else /etc/nvme looks missing)
│
├─ KBA check: gen-hostnqn vs file on disk (on host)
│  ssh core@<node> 'echo expected: $(nvme gen-hostnqn); echo on-disk: $(cat /etc/nvme/hostnqn)'
│  or: oc debug node/<node> -- chroot /host sh -c 'nvme gen-hostnqn; cat /etc/nvme/hostnqn'
│  differ → baked-in wrong NQN
│
├─ Check NQNs unique across all storage nodes
│  ssh core@<node> 'cat /etc/nvme/hostnqn'
│
├─ All unique and match dmidecode system-uuid?
│  ├─ yes → NVMe/TCP network prep → ../nvme-tcp-storage-network/
│  └─ no → apply MachineConfig fix (below), wait for MCO reboot
│
├─ CSI connected but array sees wrong NQN?
│  §1b: compare file vs nvme show-hostnqn vs sysfs hostnqn vs array live sessions
│
├─ File contains literal "$(cat ...)"?
│  └─ yes → Ignition anti-pattern active; replace with systemd fix
│
└─ After fix → re-verify → install/restart CSI → register on array if manual
```

---

## 1. Verify (per node)

Host paths only. With `oc debug node/<node>`, run `chroot /host` first (or use `-- chroot /host` on the command).

```bash
# Red Hat KBA: expected vs on-disk
nvme gen-hostnqn
cat /etc/nvme/hostnqn
cat /etc/nvme/hostid
dmidecode -s system-uuid
```

One-liner via debug:

```bash
oc debug node/<node> -- chroot /host sh -c 'nvme gen-hostnqn; cat /etc/nvme/hostnqn; cat /etc/nvme/hostid'
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
| `/etc/nvme` missing in `oc debug` shell | `chroot /host` and re-check — likely false positive |
| `/etc/nvme` missing after `chroot /host` | Rare host edge case — MC creates dir; see §2b emergency mkdir |
| `gen-hostnqn` ≠ `cat hostnqn` | Baked-in wrong file — apply fix below |
| Same NQN on 2+ nodes | Apply fix below |
| NQN contains `$(cat` | Anti-pattern MC — replace with systemd fix |
| MC applied, files still missing on host | `chroot /host systemctl status nvme-gen-host-identity.service` |
| Each NQN unique, UUID matches DMI | OK — [NVMe/TCP network prep](../nvme-tcp-storage-network/QUICK-REFERENCE.md) |

---

## 1b. Validate effective and connected NQN

Arrays do **not** read `/etc/nvme/` off the node. `nvme-cli` / `libnvme` (and CSI drivers that call them) send **Host NQN** and **Host ID** in NVMe-oF **Discover** and **Connect** commands. The array matches that identity to host objects and ACLs.

### Pre-connect — what libnvme will use

On the host (`chroot /host` if using `oc debug`):

```bash
nvme show-hostnqn          # resolved Host NQN libnvme will present
cat /etc/nvme/hostnqn      # on-disk value (wins if present)
nvme gen-hostnqn           # DMI-derived value if file were absent
```

**Pass:** `show-hostnqn` matches `cat /etc/nvme/hostnqn`, and that string is unique per node.

Resolution order: CLI `--hostnqn` / `--hostid` → `/etc/nvme/hostnqn` + `hostid` → auto-generate from DMI (with warning).

### Post-connect — what the kernel actually sent

After CSI has connected volumes (or a manual `nvme connect`):

```bash
# Host NQN used per connected NVMe-oF controller
for f in /sys/class/nvme/nvme*/hostnqn; do
  [ -f "$f" ] && echo "$(dirname $f | xargs basename): $(cat $f)"
done

nvme list-subsys
nvme list
```

**Pass:** every `hostnqn` under sysfs matches `/etc/nvme/hostnqn` on that node.

No `hostnqn` sysfs files yet → CSI has not connected, or connect failed before controllers appeared.

### Array side — what the target recorded

| Backend | Where to look |
|---------|----------------|
| **Manual registration** | Array UI/CLI **host object** NQN vs **live initiator / connection** list |
| **Pure FlashArray** | `purehost list` — host object; check active connections for presented NQN |
| **Dell CSM** | CSM registers from node NQN automatically — confirm host objects in PowerStore/PowerMax UI |
| **HPE CSI** | `oc get hpenodeinfos -A` — NQN the driver read from the node at startup |

Registered host NQN and live session NQN can differ if the on-disk file was wrong when CSI started — fix the node identity, restart CSI node pods, then reconcile array host objects.

Debug one-liner (post-connect, via `oc debug`):

```bash
oc debug node/<node> -- chroot /host sh -c 'echo file: $(cat /etc/nvme/hostnqn); echo show: $(nvme show-hostnqn); for f in /sys/class/nvme/nvme*/hostnqn; do [ -f "$f" ] && echo connected: $(cat $f); done'
```

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

## 2b. Manual emergency fix (one node, host only)

Only if `/etc/nvme` is still missing **after** `chroot /host` (rare). Use `chroot /host` or SSH as `core@`.

```bash
mkdir -p /etc/nvme
/usr/sbin/nvme gen-hostnqn > /etc/nvme/hostnqn
dmidecode -s system-uuid > /etc/nvme/hostid
```

Use only to validate; apply MachineConfig for cluster-wide persistence.

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
| `chroot /host` when using `oc debug node` | Check `/etc/nvme` from the debug pod without chroot |
| systemd oneshot via MachineConfig | Ignition `data:,...$(cat ...)` — shell never runs |
| Set both `hostnqn` and `hostid` | Set only `hostnqn` |
| Verify before CSI install | Assume RHCOS auto-unique per node |
| Compare file, `show-hostnqn`, and sysfs `hostnqn` after connect | Assume array reads `/etc/nvme` off the node |
| Use `nvme gen-hostnqn` | Hardcode one NQN in a shared MC file |

---

## Related

- [Full guide](README.md)
- [MachineConfig example](99-worker-nvme-host-identity.yaml)
- [NVMe/TCP storage network](../nvme-tcp-storage-network/README.md) — next step after NQN fix
- [Portworx CSI CrashLoop](../portworx-csi-crashloop/README.md)

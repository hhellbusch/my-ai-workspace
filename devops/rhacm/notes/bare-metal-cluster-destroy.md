# Bare Metal Cluster Destroy (RHACM / MCE)

Operational reference: what **Destroy** vs **Detach** does for bare-metal clusters provisioned or managed through RHACM / multicluster engine (MCE), and how to reach a **full decommission** including disk wipe.

**Reader:** Platform admin decommissioning an ACM-provisioned bare-metal spoke.  
**Decision:** Choose destroy vs detach, know what automation stops at, and wire disk wipe before hardware reuse.

---

## Destroy vs Detach

| Action | Cluster keeps running? | Hub objects | Typical use |
|--------|------------------------|-------------|-------------|
| **Detach** | Yes | `ManagedCluster` removed; namespace may be deleted | Temporarily remove from fleet; re-import later |
| **Destroy** | No (for MCE-provisioned clusters) | `ClusterDeployment` deleted; cluster namespace removed | Permanent teardown of a hub-provisioned cluster |

Console: **Infrastructure → Clusters → Destroy cluster** or **Detach cluster**.

CLI (hub):

```bash
# Destroy a hub-provisioned cluster (Hive teardown)
oc delete clusterdeployment <cluster-name> -n <cluster-namespace>

# Detach only (cluster may still run)
oc delete managedcluster <cluster-name>
```

**Detach** removes management; it does **not** decommission hardware.  
**Destroy** triggers Hive deletion for clusters **created by MCE** — but bare-metal teardown is incomplete without additional steps (below).

To **keep** the spoke cluster running when removing hub objects, set `spec.preserveOnDelete: true` on the `ClusterDeployment` before detach/destroy workflows that would otherwise tear down the spoke.

---

## What Destroy Does on Bare Metal

Hive runs automated deprovision jobs for **cloud** platforms (`openshift-install destroy` / `hiveutil deprovision`).

For **bare metal**, Hive **does not** run that path — there is no cloud API to drive cleanup. The `baremetal` platform also does **not** support `openshift-install destroy cluster` in the installer.

**RHACM/MCE destroy on bare metal therefore:**

- Deletes hub-side lifecycle objects (`ClusterDeployment`, cluster namespace, install secrets, agents/BMH CRs depending on install model)
- Does **not** guarantee powered-off hosts, wiped disks, or BMC lock-down
- Does **not** prevent old RHCOS nodes from booting again if disks are intact

If retired hardware can still power on with the old OS, see [Bare Metal Stale Node IP Conflict](../../ocp/troubleshooting/bare-metal-stale-node-ip-conflict/README.md).

---

## BMO Deprovision ≠ Full Disk Wipe

Hosts managed by `BareMetalHost` (installer-provisioned, agent/CIM, or hub Metal3) may enter **`deprovisioning`** when released. Ironic cleaning behavior depends on configuration — it is **not** the same as retiring hardware.

| `automatedCleaningMode` | Effect |
|-------------------------|--------|
| `disabled` | No automated cleaning (common in ACM agent-install examples) |
| `metadata` | Metadata-focused clean |
| (enabled cleaning) | Ironic clean before `available` — still oriented toward **reprovision**, not retirement |

BMO deprovision returns a host toward **`available`** / discovery — ready to be provisioned again — not “wiped and retired.”

Standard BMO host removal (OpenShift docs): cordon/drain → BMH deprovisioning → delete BMH → delete `Node`. That removes the host from the cluster; it does not replace a full disk wipe when hardware leaves service.

---

## Full Destroy: Recommended Stack

RHACM has **no single built-in action** for bare metal that equals: destroy cluster + wipe all disks + BMC lock-down. Use a layered approach:

```
1. MCE: Destroy cluster (not detach)
      oc delete clusterdeployment <name> -n <namespace>

2. Confirm BMH / Agent lifecycle on hub (agent/CIM) or spoke (IPI)
      oc get baremetalhost -n openshift-machine-api
      oc get agents -n <cluster-namespace>   # if agent-based

3. Disk wipe + BMC lock-down (manual or automated)
      → devops/ocp/troubleshooting/bare-metal-rhcos-disk-wipe/

4. If duplicate IPs were involved
      → devops/ocp/troubleshooting/bare-metal-stale-node-ip-conflict/
```

For **imported** bare-metal clusters (not hub-provisioned), destroy/detach only affects hub management — decommission is entirely manual on the spoke and hardware.

---

## Automating Disk Wipe with ClusterCurator

`ClusterCurator` supports `spec.desiredCuration: destroy` with `destroy.prehook` / `destroy.posthook` Ansible jobs (requires AAP / Ansible Automation Platform Resource Operator). Example pattern:

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: ClusterCurator
metadata:
  name: <cluster-name>
  namespace: <cluster-namespace>
spec:
  desiredCuration: destroy
  destroy:
    prehook:
      - name: backup-etcd
      - name: notify-decommission
    posthook:
      - name: wipe-bare-metal-disks    # custom AAP job — see disk wipe guide
      - name: release-ip-reservations
      - name: remove-cmdb-record
  towerAuthSecret: aap-credentials
```

Design notes for a **wipe posthook** playbook:

- Drive wipe from **hub + BMC serial inventory**, not only from the dying cluster API (API may be gone during destroy).
- Confirm serial before destructive commands — never wipe by IP alone.
- Run [disk wipe commands](../../ocp/troubleshooting/bare-metal-rhcos-disk-wipe/QUICK-REFERENCE.md) per host; power off BMC; AC recovery → Stay Off.

**Version caveat:** Install and upgrade hooks are the best-documented ClusterCurator paths. Validate destroy/scale hook support for your ACM/MCE version before relying on this in production. See [agent-install-preflight.md](./agent-install-preflight.md) (ClusterCurator scope note) and [cluster-curator README](../examples/ocm-subscription-automation/cluster-curator/README.md).

---

## By Install Model

| Model | RHACM destroy | Disk wipe |
|-------|---------------|-----------|
| MCE-provisioned bare metal / agent (CIM) | Hub CD + related CRs deleted; hosts may deprovision | Manual or ClusterCurator posthook |
| Imported bare-metal spoke | Hub management removed only | Manual on each node + BMC |
| Cloud (AWS, Azure, …) | Automated Hive deprovision | Cloud provider handles disks |
| Hosted control planes (agent) | `hcp destroy cluster agent` — separate flow | Machine resources; manual cleanup if destroy stalls |

---

## Quick Checks

```bash
# Hub: cluster still provisioned?
oc get clusterdeployment -A
oc get managedcluster

# BMH state after destroy (hub or spoke depending on model)
oc get baremetalhost -n openshift-machine-api -o wide

# Prevent accidental spoke teardown when moving hub management
oc get clusterdeployment <name> -n <ns> -o jsonpath='{.spec.preserveOnDelete}{"\n"}'
```

---

## See Also

- [Bare Metal RHCOS Disk Wipe](../../ocp/troubleshooting/bare-metal-rhcos-disk-wipe/README.md) — Wipe procedures and BMC lock-down
- [Bare Metal Stale Node IP Conflict](../../ocp/troubleshooting/bare-metal-stale-node-ip-conflict/README.md) — When retired hardware fights new nodes for IPs
- [Destroy Cluster Without Metadata — Bare Metal](../../ocp/troubleshooting/destroy-cluster-without-metadata/BAREMETAL-GUIDE.md) — Full cluster teardown without install metadata
- [ClusterCurator examples](../examples/ocm-subscription-automation/cluster-curator/README.md) — Lifecycle hooks including destroy
- [BARE-METAL-OPERATOR-INTEGRATION](../examples/BARE-METAL-OPERATOR-INTEGRATION.md) — BMH provisioning states including `deprovisioning`
- [MCE — Removing a cluster from management](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/clusters/index#removing-a-cluster-from-management) — Official destroy vs detach
